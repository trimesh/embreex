# rtcore_ray.pxd wrapper
#
# Only the single-ray types are bound; packet types (RTCRay4/8/16,
# RTCRayHit4/8/16) are declared in embree4/include/embree4/rtcore_ray.h
# and can be added here if batched traversal is ever wired up.

cimport cython
cimport numpy as np

cdef extern from "embree4/rtcore_ray.h":
    cdef struct RTCRay:
        float org_x
        float org_y
        float org_z
        float tnear

        float dir_x
        float dir_y
        float dir_z
        float time

        float tfar
        unsigned int mask
        unsigned int id
        unsigned int flags

    cdef struct RTCHit:
        float Ng_x
        float Ng_y
        float Ng_z

        float u
        float v

        unsigned int primID
        unsigned int geomID
        unsigned int instID[1]  # RTC_MAX_INSTANCE_LEVEL_COUNT

    cdef struct RTCRayHit:
        RTCRay ray
        RTCHit hit
