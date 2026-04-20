# distutils: language=c++

cimport cython
cimport numpy as np
import numpy as np
import logging
import numbers
cimport rtcore as rtc
cimport rtcore_ray as rtcr
cimport rtcore_geometry as rtcg


log = logging.getLogger('embreex')

cdef void error_printer(void* userPtr, const rtc.RTCError code, const char *_str) noexcept:
    """
    error_printer function for Embree 4.x
    """
    log.error("ERROR CAUGHT IN EMBREE")
    rtc.print_error(code)
    log.error("ERROR MESSAGE: %s" % _str)


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

    @cython.boundscheck(False)
    @cython.wraparound(False)
    def run(self, np.ndarray[np.float32_t, ndim=2] vec_origins,
                  np.ndarray[np.float32_t, ndim=2] vec_directions,
                  dists=None,query='INTERSECT',output=None):

        if self.is_committed == 0:
            rtcCommitScene(self.scene_i)
            self.is_committed = 1

        cdef int nv = vec_origins.shape[0]
        cdef int i, vd_i, vd_step
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

        cdef rtcr.RTCRayHit rayhit
        cdef unsigned int INVALID_GEOMETRY_ID = 0xFFFFFFFF
        vd_i = 0
        vd_step = 1
        # If vec_directions is 1 long, we won't be updating it.
        if vec_directions.shape[0] == 1: vd_step = 0

        for i in range(nv):
            rayhit.ray.org_x = vec_origins[i, 0]
            rayhit.ray.org_y = vec_origins[i, 1]
            rayhit.ray.org_z = vec_origins[i, 2]
            rayhit.ray.dir_x = vec_directions[vd_i, 0]
            rayhit.ray.dir_y = vec_directions[vd_i, 1]
            rayhit.ray.dir_z = vec_directions[vd_i, 2]
            rayhit.ray.tnear = 0.0
            rayhit.ray.tfar = tfars[i]
            rayhit.hit.geomID = INVALID_GEOMETRY_ID
            rayhit.hit.primID = INVALID_GEOMETRY_ID
            rayhit.hit.instID[0] = INVALID_GEOMETRY_ID
            rayhit.ray.mask = 0xFFFFFFFF
            rayhit.ray.time = 0.0
            rayhit.ray.flags = 0
            vd_i += vd_step

            if query_type == intersect or query_type == distance:
                rtcIntersect1(self.scene_i, &rayhit, NULL)
                if not output:
                    if query_type == intersect:
                        # Convert unsigned INVALID_GEOMETRY_ID to signed -1 for compatibility
                        intersect_ids[i] = -1 if rayhit.hit.primID == INVALID_GEOMETRY_ID else <int>rayhit.hit.primID
                    else:
                        tfars[i] = rayhit.ray.tfar
                else:
                    # Convert unsigned INVALID_GEOMETRY_ID to signed -1 for compatibility
                    primID_arr[i] = -1 if rayhit.hit.primID == INVALID_GEOMETRY_ID else <int>rayhit.hit.primID
                    geomID_arr[i] = -1 if rayhit.hit.geomID == INVALID_GEOMETRY_ID else <int>rayhit.hit.geomID
                    u_arr[i] = rayhit.hit.u
                    v_arr[i] = rayhit.hit.v
                    tfars[i] = rayhit.ray.tfar
                    Ng_arr[i, 0] = rayhit.hit.Ng_x
                    Ng_arr[i, 1] = rayhit.hit.Ng_y
                    Ng_arr[i, 2] = rayhit.hit.Ng_z
            else:
                rtcOccluded1(self.scene_i, &rayhit.ray, NULL)
                # In Embree 4, occlusion is signaled by setting ray.tfar to -inf
                intersect_ids[i] = 0 if rayhit.ray.tfar < 0 else -1

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
