# rtcore_scene.pxd wrapper
#
# Single-ray intersect/occluded API only. Packet variants (Intersect4/8/16,
# Occluded4/8/16), progress monitors, and join-commit live in
# embree4/include/embree4/rtcore_scene.h.

cimport cython
cimport numpy as np
from . cimport rtcore as rtc
from . cimport rtcore_ray as rtcr

cdef extern from "embree4/rtcore_scene.h":

    cdef enum RTCSceneFlags:
        RTC_SCENE_FLAG_NONE
        RTC_SCENE_FLAG_ROBUST

    ctypedef void* RTCScene

    RTCScene rtcNewScene(rtc.RTCDevice device)

    void rtcCommitScene(RTCScene scene)

    void rtcIntersect1(RTCScene scene, rtcr.RTCRayHit* rayhit, void* args) nogil

    void rtcOccluded1(RTCScene scene, rtcr.RTCRay* ray, void* args) nogil

    void rtcReleaseScene(RTCScene scene)

    void rtcSetSceneFlags(RTCScene scene, RTCSceneFlags flags)

cdef class EmbreeScene:
    cdef RTCScene scene_i
    # Optional device used if not given, it should be as input of EmbreeScene
    cdef public int is_committed
    cdef rtc.EmbreeDevice device

cdef enum rayQueryType:
    intersect,
    occluded,
    distance
