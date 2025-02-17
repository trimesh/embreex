# distutils: language=c++

cimport cython
cimport numpy as np
import numpy as np
import logging
import numbers
cimport rtcore as rtc  # Use the unified rtcore module
#cimport rtcore_ray as rtcr  # No longer needed
#cimport rtcore_geometry as rtcg # No longer needed


log = logging.getLogger('embreex')

cdef void error_printer(void* userPtr, const rtc.RTCError code, const char *_str) noexcept:
    """
    error_printer function depends on embree version
    Embree 2.14.1
    -> cdef void error_printer(const rtc.RTCError code, const char *_str):
    Embree 2.17.1
    -> cdef void error_printer(void* userPtr, const rtc.RTCError code, const char *_str):
    """
    log.error("ERROR CAUGHT IN EMBREE")
    rtc.print_error(code)
    if _str: # Check that the string is not null
      log.error("ERROR MESSAGE: %s", _str.decode('utf-8', 'replace')) # Decode to a Python string

cdef class EmbreeScene:
    cdef rtc.RTCScene scene_i
    # Optional device used if not given, it should be as input of EmbreeScene
    cdef public int is_committed
    cdef rtc.EmbreeDevice device

    def __init__(self, rtc.EmbreeDevice device=None, robust=False):
        if device is None:
            # We store the embree device inside EmbreeScene to avoid premature deletion
            self.device = rtc.EmbreeDevice()
            device = self.device
        else:
            #Keep a reference to device
            self.device = device

        # Embree 4: Create scene using the device.
        self.scene_i = rtc.rtcNewScene(device.device)  # All scenes created from device
        if self.scene_i is NULL:
            raise RuntimeError(f"Failed to create Embree scene: {rtc.rtcGetError()}")

        #flags = rtc.RTC_SCENE_FLAG_STATIC # Removed in Embree 4
        flags = rtc.RTC_SCENE_FLAG_NONE # Start with no flags
        if robust:
            # bitwise-or the robust flag
            #flags |= rtc.RTC_SCENE_FLAG_ROBUST # Removed in Embree4
              flags |= rtc.RTC_SCENE_FLAG_ROBUST # Use new flags
        rtc.rtcSetSceneFlags(self.scene_i, flags) # Embree 4
        #rtc.rtcDeviceSetErrorFunction(device.device, error_printer) # Replaced in Embree4
        rtc.rtcSetDeviceErrorFunction2(device.device, error_printer, <void*>self)
        #self.scene_i = rtc.rtcDeviceNewScene(device.device, flags, rtc.RTC_INTERSECT1) # Old API, takes flags.
        self.is_committed = 0


    def run(self, np.ndarray[np.float32_t, ndim=2] vec_origins,
                  np.ndarray[np.float32_t, ndim=2] vec_directions,
                  dists=None,query='INTERSECT',output=None):

        if self.is_committed == 0:
            #rtcCommit(self.scene_i) # Replaced
            rtc.rtcCommitScene(self.scene_i) # Use new function
            self.is_committed = 1

        cdef int nv = vec_origins.shape[0]
        cdef int vo_i, vd_i, vd_step
        cdef np.ndarray[np.int32_t, ndim=1] intersect_ids
        cdef np.ndarray[np.float32_t, ndim=1] tfars
        cdef rtc.rayQueryType query_type # Now use rtcore types

        if query == 'INTERSECT':
            query_type = rtc.intersect
        elif query == 'OCCLUDED':
            query_type = rtc.occluded
        elif query == 'DISTANCE':
            query_type = rtc.distance

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
            u = np.empty(nv, dtype="float32")
            v = np.empty(nv, dtype="float32")
            Ng = np.empty((nv, 3), dtype="float32")
            primID = np.empty(nv, dtype="int32")
            geomID = np.empty(nv, dtype="int32")
        else:
            intersect_ids = np.empty(nv, dtype="int32")

        #cdef rtcr.RTCRay ray # Old ray struct.
        cdef rtc.RTCRayHit rayhit # Use combined ray/hit struct
        cdef rtc.RTCRay ray #Define ray to easily fill the struct.
        vd_i = 0
        vd_step = 1
        # If vec_directions is 1 long, we won't be updating it.
        if vec_directions.shape[0] == 1: vd_step = 0

        # Set up the intersection arguments (Embree 4)
        cdef rtc.RTCIntersectArguments args
        rtc.rtcInitIntersectArguments(&args) # Initialize the args struct

        # Set up the occlusion arguments (Embree 4)
        cdef rtc.RTCOccludedArguments oargs
        rtc.rtcInitOccludedArguments(&oargs) # Initialize the args struct

        for i in range(nv):
            # Fill Ray struct and then copy to RTCRayHit
            ray.org_x = vec_origins[i, 0]  # Use explicit members
            ray.org_y = vec_origins[i, 1]
            ray.org_z = vec_origins[i, 2]
            ray.dir_x = vec_directions[vd_i, 0]
            ray.dir_y = vec_directions[vd_i, 1]
            ray.dir_z = vec_directions[vd_i, 2]
            ray.tnear = 0.0
            ray.tfar = tfars[i]
            ray.mask = -1  # Enable all geometries
            ray.time = 0.0
            # Initialize hit information
            rayhit.hit.geomID = rtc.RTC_INVALID_GEOMETRY_ID
            rayhit.hit.primID = rtc.RTC_INVALID_GEOMETRY_ID
            rayhit.hit.instID[0] = rtc.RTC_INVALID_GEOMETRY_ID  # Just the first instID

            #Copy ray to rayhit
            rayhit.ray = ray

            vd_i += vd_step

            if query_type == rtc.intersect or query_type == rtc.distance:
                rtc.rtcIntersect1(self.scene_i, &rayhit, &args) # Pass args struct
                if not output:
                    if query_type == rtc.intersect:
                        intersect_ids[i] = rayhit.hit.primID # Access hit info from .hit
                    else:
                        tfars[i] = rayhit.ray.tfar
                else:
                    primID[i] = rayhit.hit.primID
                    geomID[i] = rayhit.hit.geomID
                    u[i] = rayhit.hit.u
                    v[i] = rayhit.hit.v
                    tfars[i] = rayhit.ray.tfar #Access tfar from .ray
                    for j in range(3):
                        Ng[i, j] = rayhit.hit.Ng_x #Access Ng from .hit
                        if j == 1:
                            Ng[i, j] = rayhit.hit.Ng_y
                        elif j==2:
                            Ng[i, j] = rayhit.hit.Ng_z
            else:
                rtc.rtcOccluded1(self.scene_i, &rayhit, &oargs) # Pass args struct.
                intersect_ids[i] = rayhit.hit.geomID # Access geomID from hit

        if output:
            return {'u':u, 'v':v, 'Ng': Ng, 'tfar': tfars, 'primID': primID, 'geomID': geomID}
        else:
            if query_type == rtc.distance:
                return tfars
            else:
                return intersect_ids

    def __dealloc__(self):
        if self.scene_i is not NULL:
            rtc.rtcReleaseScene(self.scene_i)