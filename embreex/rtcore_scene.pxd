# rtcore_scene.pxd wrapper

cimport cython
cimport numpy as np
cimport rtcore as rtc
#cimport rtcore_ray as rtcr # Removed in Embree 4

cdef extern from "embree4/rtcore_scene.h":
    # ctypedef struct RTCRay {} RTCRay  # Already defined in rtcore_ray.pxd  REMOVED
    # ctypedef struct RTCRay4 {} RTCRay4
    # ctypedef struct RTCRay8 {} RTCRay8
    # ctypedef struct RTCRay16 {} RTCRay16
    ctypedef struct RTCRay
    ctypedef struct RTCRay4
    ctypedef struct RTCRay8
    ctypedef struct RTCRay16

    cdef enum RTCSceneFlags:
        RTC_SCENE_FLAG_NONE  # Embree 4 adds a NONE option.
        RTC_SCENE_FLAG_DYNAMIC
        RTC_SCENE_FLAG_COMPACT
        RTC_SCENE_FLAG_ROBUST
        # These are removed in Embree 4
        #RTC_SCENE_COHERENT
        #RTC_SCENE_INCOHERENT
        #RTC_SCENE_HIGH_QUALITY
        # New in Embree 4
        RTC_SCENE_FLAG_FILTER_FUNCTION_IN_ARGUMENTS  # Enable passing filter function as argument.

    # New in Embree 4
    cdef enum RTCAlgorithmFlags:
        RTC_INTERSECT1  # No longer really flags.  Just one at a time.
        RTC_INTERSECT4
        RTC_INTERSECT8
        RTC_INTERSECT16

    # ctypedef void* RTCDevice  # Already defined in rtcore.pxd
    ctypedef void * RTCScene

    #RTCScene rtcNewScene(RTCSceneFlags flags, RTCAlgorithmFlags aflags) # OLD API, takes flags.
    RTCScene rtcNewScene(rtc.RTCDevice device)  # Embree 4 version - takes device.

    # device functions
    RTCScene  rtcDeviceNewScene(rtc.RTCDevice device, RTCSceneFlags flags, RTCAlgorithmFlags aflags)  # Old API

    #ctypedef bint (*RTCProgressMonitorFunc)(void* ptr, const double n) # No longer needed

    #void rtcSetProgressMonitorFunction(RTCScene scene, RTCProgressMonitorFunc func, void* ptr) # Removed in Embree4

    #void rtcCommit(RTCScene scene)  # REMOVED, replaced by rtcCommitScene
    void rtcCommitScene(RTCScene scene)  # New in Embree 4
    void rtcJoinCommitScene(RTCScene scene)

    #void rtcCommitThread(RTCScene scene, unsigned int threadID, unsigned int numThreads) # REMOVED

    # Use new Embree 4 ray/hit structs
    #void rtcIntersect(RTCScene scene, RTCRay& ray)
    void rtcIntersect1(rtc.RTCScene scene, rtc.RTCRayHit * rayhit, rtc.RTCIntersectArguments * args)  # Embree4
    #void rtcIntersect4(const void* valid, RTCScene scene, RTCRay4& ray)
    void rtcIntersect4(const void * valid, rtc.RTCScene scene, rtc.RTCRayHit4 * rayhit,
                       rtc.RTCIntersectArguments * args)  # Embree4
    #void rtcIntersect8(const void* valid, RTCScene scene, RTCRay8& ray)
    void rtcIntersect8(const void * valid, rtc.RTCScene scene, rtc.RTCRayHit8 * rayhit,
                       rtc.RTCIntersectArguments * args)  # Embree4
    #void rtcIntersect16(const void* valid, RTCScene scene, RTCRay16& ray)
    void rtcIntersect16(const void * valid, rtc.RTCScene scene, rtc.RTCRayHit16 * rayhit,
                        rtc.RTCIntersectArguments * args)  # Embree4

    #void rtcOccluded(RTCScene scene, RTCRay& ray)
    void rtcOccluded1(rtc.RTCScene scene, rtc.RTCRayHit * rayhit, rtc.RTCOccludedArguments * args)  # Embree4
    #void rtcOccluded4(const void* valid, RTCScene scene, RTCRay4& ray)
    void rtcOccluded4(const void * valid, rtc.RTCScene scene, rtc.RTCRayHit4 * rayhit,
                      rtc.RTCOccludedArguments * args)  # Embree4
    #void rtcOccluded8(const void* valid, RTCScene scene, RTCRay8& ray)
    void rtcOccluded8(const void * valid, rtc.RTCScene scene, rtc.RTCRayHit8 * rayhit,
                      rtc.RTCOccludedArguments * args)  # Embree4
    #void rtcOccluded16(const void* valid, RTCScene scene, RTCRay16& ray)
    void rtcOccluded16(const void * valid, rtc.RTCScene scene, rtc.RTCRayHit16 * rayhit,
                       rtc.RTCOccludedArguments * args)  # Embree4

    # New function in Embree 4 for forwarding rays
    void rtcForwardIntersect1(const struct rtc
    .RTCIntersectFunctionNArguments
    * args, RTCScene
    scene, struct
    RTCRay * ray, unsigned
    int instID
    )
    void rtcForwardOccluded1(const struct rtc
    .RTCOccludedFunctionNArguments
    * args, RTCScene
    scene, struct
    RTCRay * ray, unsigned
    int instID
    )
    # New extended functions in Embree 4 for forwarding rays (for instance arrays)
    void rtcForwardIntersect1Ex(const struct rtc
    .RTCIntersectFunctionNArguments
    * args, RTCScene
    scene, struct
    RTCRay * ray, unsigned
    int instID, unsigned
    int instPrimID
    )
    void rtcForwardOccluded1Ex(const struct rtc
    .RTCOccludedFunctionNArguments
    * args, RTCScene
    scene, struct
    RTCRay * ray, unsigned
    int instID, unsigned
    int instPrimID
    )

    void rtcForwardIntersect4(void * valid, const struct rtc
    .RTCIntersectFunctionNArguments
    * args, RTCScene
    scene, struct
    RTCRay4 * ray, unsigned
    int instID
    )
    void rtcForwardOccluded4(void * valid, const struct rtc
    .RTCOccludedFunctionNArguments
    * args, RTCScene
    scene, struct
    RTCRay4 * ray, unsigned
    int instID
    )
    void rtcForwardIntersect8(void * valid, const struct rtc
    .RTCIntersectFunctionNArguments
    * args, RTCScene
    scene, struct
    RTCRay8 * ray, unsigned
    int instID
    )
    void rtcForwardOccluded8(void * valid, const struct rtc
    .RTCOccludedFunctionNArguments
    * args, RTCScene
    scene, struct
    RTCRay8 * ray, unsigned
    int instID
    )
    void rtcForwardIntersect16(void * valid, const struct rtc
    .RTCIntersectFunctionNArguments
    * args, RTCScene
    scene, struct
    RTCRay16 * ray, unsigned
    int instID
    )
    void rtcForwardOccluded16(void * valid, const struct rtc
    .RTCOccludedFunctionNArguments
    * args, RTCScene
    scene, struct
    RTCRay16 * ray, unsigned
    int instID
    )

    void rtcDeleteScene(RTCScene scene)
    # Use retain/release
    void rtcRetainScene(RTCScene scene)
    void rtcReleaseScene(RTCScene scene)

    # New functions in Embree 4 - scene bounds
    ctypedef struct RTCLinearBounds:
        rtc.RTCBounds bounds0
        rtc.RTCBounds bounds1
    void rtcGetSceneBounds(rtc.RTCScene scene, rtc.RTCBounds * bounds_o)
    void rtcGetSceneLinearBounds(rtc.RTCScene scene, RTCLinearBounds * bounds_o)

    rtc.RTCDevice rtcGetSceneDevice(rtc.RTCScene scene)

    #New functions in Embree 4
    RTCSceneFlags rtcGetSceneFlags(rtc.RTCScene scene)
    void          rtcSetSceneFlags(rtc.RTCScene scene, RTCSceneFlags flags)
    void          rtcSetSceneProgressMonitorFunction(rtc.RTCScene scene, rtc.RTCProgressMonitorFunc func, void * ptr)
    void          rtcSetSceneBuildQuality(rtc.RTCScene scene, enum RTCBuildQuality
    quality
    )


cdef class EmbreeScene:
    cdef rtc.RTCScene scene_i
    # Optional device used if not given, it should be as input of EmbreeScene
    cdef public int is_committed
    cdef rtc.EmbreeDevice device

cdef enum rayQueryType:
    intersect,
    occluded,
    distance