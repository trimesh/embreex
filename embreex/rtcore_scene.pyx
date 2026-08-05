# cython: boundscheck=False, wraparound=False, cdivision=True, initializedcheck=False, language_level=3
# distutils: language=c++

cimport cython
cimport numpy as np
import numpy as np
import logging
import numbers
from . cimport rtcore as rtc
from . cimport rtcore_ray as rtcr
from . cimport rtcore_geometry as rtcg


log = logging.getLogger('embreex')

cdef void error_printer(void* userPtr, const rtc.RTCError code, const char *_str) noexcept:
    """
    error_printer function for Embree 4.x
    """
    log.error("ERROR CAUGHT IN EMBREE")
    rtc.print_error(code)
    log.error("ERROR MESSAGE: %s" % _str)


# Raw buffers and byte strides let workers traverse strided inputs without
# accessing Python objects; outputs are contiguous.
cdef struct RayJob:
    RTCScene scene
    char* org
    Py_ssize_t org_s0
    Py_ssize_t org_s1
    char* dir
    Py_ssize_t dir_s0
    Py_ssize_t dir_s1
    int direction_row_step
    char* tfar
    Py_ssize_t tfar_s0
    int* intersect_ids
    float* u_arr
    float* v_arr
    float* Ng_arr
    int* primID_arr
    int* geomID_arr
    int query_type
    bint use_output


cdef void _cast_range(void* ctx, size_t begin, size_t end) noexcept nogil:
    """Trace rays in the half-open range [begin, end)."""
    cdef RayJob* j = <RayJob*>ctx
    cdef rtcr.RTCRayHit rayhit
    cdef unsigned int INVALID_GEOMETRY_ID = 0xFFFFFFFF
    cdef size_t i
    cdef Py_ssize_t vd_i
    cdef char* origin_ptr
    cdef char* direction_ptr
    cdef char* distance_ptr

    for i in range(begin, end):
        origin_ptr = j.org + <Py_ssize_t>i * j.org_s0
        # Broadcast a single direction row across all origins.
        vd_i = <Py_ssize_t>i * j.direction_row_step
        direction_ptr = j.dir + vd_i * j.dir_s0
        distance_ptr = j.tfar + <Py_ssize_t>i * j.tfar_s0

        rayhit.ray.org_x = (<float*>origin_ptr)[0]
        rayhit.ray.org_y = (<float*>(origin_ptr + j.org_s1))[0]
        rayhit.ray.org_z = (<float*>(origin_ptr + 2 * j.org_s1))[0]
        rayhit.ray.dir_x = (<float*>direction_ptr)[0]
        rayhit.ray.dir_y = (<float*>(direction_ptr + j.dir_s1))[0]
        rayhit.ray.dir_z = (<float*>(direction_ptr + 2 * j.dir_s1))[0]
        rayhit.ray.tnear = 0.0
        rayhit.ray.tfar = (<float*>distance_ptr)[0]
        rayhit.hit.geomID = INVALID_GEOMETRY_ID
        rayhit.hit.primID = INVALID_GEOMETRY_ID
        rayhit.hit.instID[0] = INVALID_GEOMETRY_ID
        rayhit.ray.mask = 0xFFFFFFFF
        rayhit.ray.time = 0.0
        rayhit.ray.flags = 0

        if j.query_type == <int>intersect or j.query_type == <int>distance:
            rtcIntersect1(j.scene, &rayhit, NULL)
            if not j.use_output:
                if j.query_type == <int>intersect:
                    j.intersect_ids[i] = -1 if rayhit.hit.primID == INVALID_GEOMETRY_ID else <int>rayhit.hit.primID
                else:
                    (<float*>distance_ptr)[0] = rayhit.ray.tfar
            else:
                j.primID_arr[i] = -1 if rayhit.hit.primID == INVALID_GEOMETRY_ID else <int>rayhit.hit.primID
                j.geomID_arr[i] = -1 if rayhit.hit.geomID == INVALID_GEOMETRY_ID else <int>rayhit.hit.geomID
                j.u_arr[i] = rayhit.hit.u
                j.v_arr[i] = rayhit.hit.v
                (<float*>distance_ptr)[0] = rayhit.ray.tfar
                j.Ng_arr[3 * i + 0] = rayhit.hit.Ng_x
                j.Ng_arr[3 * i + 1] = rayhit.hit.Ng_y
                j.Ng_arr[3 * i + 2] = rayhit.hit.Ng_z
        else:
            rtcOccluded1(j.scene, &rayhit.ray, NULL)
            # In Embree 4, occlusion is signaled by setting ray.tfar to -inf
            j.intersect_ids[i] = 0 if rayhit.ray.tfar < 0 else -1


cdef class EmbreeScene:
    def __init__(self, rtc.EmbreeDevice device=None, robust=True):
        if device is None:
            device = rtc.EmbreeDevice()
        # We store the embree device inside EmbreeScene to avoid premature deletion
        self.device = device
        rtc.rtcSetDeviceErrorFunction(device.device, error_printer, NULL)
        self.scene_i = rtcNewScene(device.device)
        flags = RTC_SCENE_FLAG_NONE
        if robust:
            # bitwise-or the robust flag
            flags |= RTC_SCENE_FLAG_ROBUST
        rtcSetSceneFlags(self.scene_i, flags)
        self.is_committed = 0

    def run(self, np.ndarray[np.float32_t, ndim=2] vec_origins,
                  np.ndarray[np.float32_t, ndim=2] vec_directions,
                  dists=None, query='INTERSECT', output=None):

        if self.is_committed == 0:
            rtcCommitScene(self.scene_i)
            self.is_committed = 1

        cdef int nv = vec_origins.shape[0]
        cdef np.ndarray[np.int32_t, ndim=1] intersect_ids
        cdef np.ndarray[np.float32_t, ndim=1] tfars
        cdef np.ndarray[np.float32_t, ndim=1] u_arr, v_arr
        cdef np.ndarray[np.float32_t, ndim=2] Ng_arr
        cdef np.ndarray[np.int32_t, ndim=1] primID_arr, geomID_arr
        cdef rayQueryType query_type

        if query == 'INTERSECT':
            query_type = intersect
        elif query == 'OCCLUDED':
            query_type = occluded
        elif query == 'DISTANCE':
            query_type = distance
        else:
            raise ValueError("Embree ray query type %s not recognized."
                "\nAccepted types are (INTERSECT,OCCLUDED,DISTANCE)" % (query))

        if dists is None:
            tfars = np.empty(nv, 'float32')
            tfars.fill(1e37)
        elif isinstance(dists, numbers.Number):
            tfars = np.empty(nv, 'float32')
            tfars.fill(dists)
        else:
            tfars = dists

        if output:
            u_arr = np.empty(nv, dtype="float32")
            v_arr = np.empty(nv, dtype="float32")
            Ng_arr = np.empty((nv, 3), dtype="float32")
            primID_arr = np.empty(nv, dtype="int32")
            geomID_arr = np.empty(nv, dtype="int32")
        # Occluded writes to intersect_ids regardless of output, so always
        # allocate when that branch is possible.
        if not output or query_type == occluded:
            intersect_ids = np.empty(nv, dtype="int32")

        cdef RayJob job
        job.scene = self.scene_i
        job.org = <char*>np.PyArray_DATA(vec_origins)
        job.org_s0 = np.PyArray_STRIDES(vec_origins)[0]
        job.org_s1 = np.PyArray_STRIDES(vec_origins)[1]
        job.dir = <char*>np.PyArray_DATA(vec_directions)
        job.dir_s0 = np.PyArray_STRIDES(vec_directions)[0]
        job.dir_s1 = np.PyArray_STRIDES(vec_directions)[1]
        job.direction_row_step = 0 if vec_directions.shape[0] == 1 else 1
        job.tfar = <char*>np.PyArray_DATA(tfars)
        job.tfar_s0 = np.PyArray_STRIDES(tfars)[0]
        job.query_type = <int>query_type
        job.use_output = bool(output)
        job.intersect_ids = <int*>np.PyArray_DATA(intersect_ids) if (not output or query_type == occluded) else NULL
        if output:
            job.u_arr = <float*>np.PyArray_DATA(u_arr)
            job.v_arr = <float*>np.PyArray_DATA(v_arr)
            job.Ng_arr = <float*>np.PyArray_DATA(Ng_arr)
            job.primID_arr = <int*>np.PyArray_DATA(primID_arr)
            job.geomID_arr = <int*>np.PyArray_DATA(geomID_arr)
        else:
            job.u_arr = NULL
            job.v_arr = NULL
            job.Ng_arr = NULL
            job.primID_arr = NULL
            job.geomID_arr = NULL

        with nogil:
            _cast_range(<void*>&job, 0, <size_t>nv)

        if output:
            return {'u': u_arr, 'v': v_arr, 'Ng': Ng_arr, 'tfar': tfars,
                    'primID': primID_arr, 'geomID': geomID_arr}
        else:
            if query_type == distance:
                return tfars
            else:
                return intersect_ids

    def __dealloc__(self):
        rtcReleaseScene(self.scene_i)
