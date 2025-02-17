# rtcore_ray.pxd wrapper

cimport cython
cimport numpy as np

cdef extern from "embree4/rtcore_ray.h":
    # RTCORE_ALIGN(16)  # This macro is no longer needed.  Assume alignment.

    # This is for a *single* ray
    cdef struct RTCRay:
        # Ray data
        float org_x  # Embree4 uses explicit members
        float org_y
        float org_z
        #float align0  # No longer needed

        float dir_x  # Explicit members
        float dir_y
        float dir_z
        #float align1

        float tnear
        float tfar

        float time
        unsigned int mask  # Changed to unsigned int

        # Hit data
        float Ng_x  # Explicit members, and grouped with u,v
        float Ng_y
        float Ng_z
        #float align2

        float u  # Now directly in RTCRay
        float v

        int geomID  # Now int, not unsigned int
        int primID
        int instID[1]  #  Just the first instance ID.  instID[RTC_MAX_INSTANCE_LEVEL_COUNT] if needed.

    # This is for a packet of 4 rays
    cdef struct RTCRay4:
        # Ray data
        float orgx[4]
        float orgy[4]
        float orgz[4]
        #float align0  # No longer needed

        float dirx[4]
        float diry[4]
        float dirz[4]

        float tnear[4]
        float tfar[4]

        float time[4]
        int mask[4]  # still int in RTCRay4/8/16

        # Hit data
        float Ngx[4]
        float Ngy[4]
        float Ngz[4]

        float u[4]
        float v[4]

        int geomID[4]
        int primID[4]
        int instID[4]

    # This is for a packet of 8 rays
    cdef struct RTCRay8:
        # Ray data
        float orgx[8]
        float orgy[8]
        float orgz[8]
        #float align0  # No longer needed

        float dirx[8]
        float diry[8]
        float dirz[8]

        float tnear[8]
        float tfar[8]

        float time[8]
        int mask[8]

        # Hit data
        float Ngx[8]
        float Ngy[8]
        float Ngz[8]

        float u[8]
        float v[8]

        int geomID[8]
        int primID[8]
        int instID[8]

    # This is for a packet of 16 rays
    cdef struct RTCRay16:
        # Ray data
        float orgx[16]
        float orgy[16]
        float orgz[16]
        #float align0   # No longer needed

        float dirx[16]
        float diry[16]
        float dirz[16]

        float tnear[16]
        float tfar[16]

        float time[16]
        int mask[16]

        # Hit data
        float Ngx[16]
        float Ngy[16]
        float Ngz[16]

        float u[16]
        float v[16]

        int geomID[16]
        int primID[16]
        int instID[16]

    # Combined Ray/Hit Structures (Embree 4)
    cdef struct RTCRayHit:
        RTCRay ray
        RTCHit hit  # Contains u,v,Ng,geomID,primID,instID

    cdef struct RTCHit:  # New in Embree 4 - contains hit information
        float Ng_x
        float Ng_y
        float Ng_z
        float u
        float v
        int geomID
        int primID
        int instID[1]  # Just the top level instance ID


cdef extern from *:  # Hack for struct forward decls
    ctypedef struct RTCIntersectArguments
    ctypedef struct RTCOccludedArguments


# Combined intersect/occluded arguments (Embree 4 API)
cdef extern from "embree4/rtcore_ray.h":
    # New enum for ray query flags
    cdef enum RTCRayQueryFlags:
        RTC_RAY_QUERY_FLAG_NONE
        RTC_RAY_QUERY_FLAG_INCOHERENT
        RTC_RAY_QUERY_FLAG_COHERENT
        RTC_RAY_QUERY_FLAG_INVOKE_ARGUMENT_FILTER

    cdef enum RTCFeatureFlags:  # New in Embree4
        RTC_FEATURE_FLAG_NONE
        RTC_FEATURE_FLAG_MOTION_BLUR
        RTC_FEATURE_FLAG_TRIANGLE
        RTC_FEATURE_FLAG_QUAD
        RTC_FEATURE_FLAG_GRID
        RTC_FEATURE_FLAG_SUBDIVISION
        RTC_FEATURE_FLAG_POINT
        RTC_FEATURE_FLAG_CURVES
        RTC_FEATURE_FLAG_CONE_LINEAR_CURVE
        RTC_FEATURE_FLAG_ROUND_LINEAR_CURVE
        RTC_FEATURE_FLAG_FLAT_LINEAR_CURVE
        RTC_FEATURE_FLAG_ROUND_BEZIER_CURVE
        RTC_FEATURE_FLAG_FLAT_BEZIER_CURVE
        RTC_FEATURE_FLAG_NORMAL_ORIENTED_BEZIER_CURVE
        RTC_FEATURE_FLAG_ROUND_BSPLINE_CURVE
        RTC_FEATURE_FLAG_FLAT_BSPLINE_CURVE
        RTC_FEATURE_FLAG_NORMAL_ORIENTED_BSPLINE_CURVE
        RTC_FEATURE_FLAG_ROUND_HERMITE_CURVE
        RTC_FEATURE_FLAG_FLAT_HERMITE_CURVE
        RTC_FEATURE_FLAG_NORMAL_ORIENTED_HERMITE_CURVE
        RTC_FEATURE_FLAG_ROUND_CATMULL_ROM_CURVE
        RTC_FEATURE_FLAG_FLAT_CATMULL_ROM_CURVE
        RTC_FEATURE_FLAG_NORMAL_ORIENTED_CATMULL_ROM_CURVE
        RTC_FEATURE_FLAG_SPHERE_POINT
        RTC_FEATURE_FLAG_DISC_POINT
        RTC_FEATURE_FLAG_ORIENTED_DISC_POINT
        RTC_FEATURE_FLAG_ROUND_CURVES
        RTC_FEATURE_FLAG_FLAT_CURVES
        RTC_FEATURE_FLAG_NORMAL_ORIENTED_CURVES
        RTC_FEATURE_FLAG_LINEAR_CURVES
        RTC_FEATURE_FLAG_BEZIER_CURVES
        RTC_FEATURE_FLAG_BSPLINE_CURVES
        RTC_FEATURE_FLAG_HERMITE_CURVES
        RTC_FEATURE_FLAG_INSTANCE
        RTC_FEATURE_FLAG_FILTER_FUNCTION_IN_ARGUMENTS
        RTC_FEATURE_FLAG_FILTER_FUNCTION_IN_GEOMETRY
        RTC_FEATURE_FLAG_FILTER_FUNCTION
        RTC_FEATURE_FLAG_USER_GEOMETRY_CALLBACK_IN_ARGUMENTS
        RTC_FEATURE_FLAG_USER_GEOMETRY_CALLBACK_IN_GEOMETRY
        RTC_FEATURE_FLAG_USER_GEOMETRY
        RTC_FEATURE_FLAG_32_BIT_RAY_MASK
        RTC_FEATURE_FLAG_ALL

    ctypedef void (*RTCFilterFunctionN)(const struct RTCFilterFunctionNArguments
    * args
    )

    ctypedef struct RTCFilterFunctionNArguments:
        int * valid
        void * geometryUserPtr
        const struct RTCRayQueryContext
        * context
        struct RTCRayN
        * ray
        struct RTCHitN
        * hit
        unsigned int N

    ctypedef void (*RTCIntersectFunctionN)(const struct RTCIntersectFunctionNArguments
    * args
    )

    ctypedef struct RTCIntersectFunctionNArguments:
        int * valid
        void * geometryUserPtr
        unsigned int primID
        struct RTCRayQueryContext
        * context
        struct RTCRayHitN
        * rayhit
        unsigned int N
        unsigned int geomID

    ctypedef void (*RTCOccludedFunctionN)(const struct RTCOccludedFunctionNArguments
    * args
    )

    ctypedef struct RTCOccludedFunctionNArguments:
        int * valid
        void * geometryUserPtr
        unsigned int primID
        struct RTCRayQueryContext
        * context
        struct RTCRayN
        * ray
        unsigned int N
        unsigned int geomID

    ctypedef struct RTCIntersectArguments:
        RTCRayQueryFlags flags
        RTCFeatureFlags feature_mask
        struct RTCRayQueryContext
        * context  # Renamed in Embree 4
        RTCFilterFunctionN filter
        RTCIntersectFunctionN intersect  # New in Embree 4

    ctypedef struct RTCOccludedArguments:
        RTCRayQueryFlags flags
        RTCFeatureFlags feature_mask
        struct RTCRayQueryContext
        * context  # Renamed in Embree 4
        RTCFilterFunctionN filter
        RTCOccludedFunctionN occluded  # New in Embree 4

    # New functions to invoke filter functions from geometry callbacks
    void rtcInvokeIntersectFilterFromGeometry(const struct RTCIntersectFunctionNArguments
    * args, conststruct
    RTCFilterFunctionNArguments * filterArgsa
    )
    void rtcInvokeOccludedFilterFromGeometry(const struct RTCOccludedFunctionNArguments
    * args, const
    struct RTCFilterFunctionNArguments
    * filterArgs
    )

    # Ray query context (renamed from RTCIntersectContext)
    ctypedef struct RTCRayQueryContext:
        #unsigned int instID[RTC_MAX_INSTANCE_LEVEL_COUNT] # Now in RTCHit
        pass  # Simplified - other fields not directly needed here.

    void rtcInitIntersectArguments(RTCIntersectArguments * args)
    void rtcInitOccludedArguments(RTCOccludedArguments * args)
    void rtcInitRayQueryContext(RTCRayQueryContext * context)
