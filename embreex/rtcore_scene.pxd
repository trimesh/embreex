# rtcore_scene.pxd wrapper

cimport cython
cimport numpy as np
cimport rtcore as rtc
cimport rtcore_ray as rtcr

cdef extern from "embree4/rtcore_scene.h":

    ctypedef struct RTCRay
    ctypedef struct RTCRay4
    ctypedef struct RTCRay8
    ctypedef struct RTCRay16
    ctypedef struct RTCRayHit
    ctypedef struct RTCRayHit4
    ctypedef struct RTCRayHit8
    ctypedef struct RTCRayHit16

    cdef enum RTCSceneFlags:
        RTC_SCENE_FLAG_NONE
        RTC_SCENE_FLAG_DYNAMIC
        RTC_SCENE_FLAG_COMPACT
        RTC_SCENE_FLAG_ROBUST
        RTC_SCENE_FLAG_FILTER_FUNCTION_IN_ARGUMENTS

    # ctypedef void* RTCDevice
    ctypedef void* RTCScene

    RTCScene rtcNewScene(rtc.RTCDevice device)

    ctypedef bint (*RTCProgressMonitorFunc)(void* ptr, const double n)

    void rtcSetSceneProgressMonitorFunction(RTCScene scene, RTCProgressMonitorFunc func, void* ptr)

    void rtcCommitScene(RTCScene scene)

    void rtcJoinCommitScene(RTCScene scene)

    void rtcIntersect1(RTCScene scene, RTCRayHit* rayhit, void* args)

    void rtcIntersect4(const void* valid, RTCScene scene, RTCRayHit4* rayhit, void* args)

    void rtcIntersect8(const void* valid, RTCScene scene, RTCRayHit8* rayhit, void* args)

    void rtcIntersect16(const void* valid, RTCScene scene, RTCRayHit16* rayhit, void* args)

    void rtcOccluded1(RTCScene scene, RTCRay* ray, void* args)

    void rtcOccluded4(const void* valid, RTCScene scene, RTCRay4* ray, void* args)

    void rtcOccluded8(const void* valid, RTCScene scene, RTCRay8* ray, void* args)

    void rtcOccluded16(const void* valid, RTCScene scene, RTCRay16* ray, void* args)

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
