# rtcore_geometry_user wrapper

#from libc.stdint cimport ssize_t, size_t  # No longer needed, Cython handles this
#from .rtcore_ray cimport RTCRay, RTCRay4, RTCRay8, RTCRay16 # Removed in Embree 4
#from .rtcore_geometry cimport RTCBounds # Removed in Embree 4
from .rtcore cimport EmbreeScene, RTCGeometry, RTCRayHitN, RTCRayQueryContext # Embree 4
from cython cimport bint
cimport cython
cimport numpy as np

cdef extern from "embree4/rtcore_geometry_user.h":
    # These typedefs have changed significantly. We now have unified callbacks
    # that accept a struct containing ALL arguments (ray, hit, context, etc.)
    # The valid pointer indicates which rays in a packet are active.

    # Use the new Embree 4 structs and function pointer types from rtcore.pxd

    #ctypedef void (*RTCBoundsFunc)(void* ptr, size_t item, RTCBounds& bounds_o) # Replaced in Embree4

    # Use new function definition.
    ctypedef void (*RTCBoundsFunction)( const struct rtc.RTCBoundsFunctionArguments* args )

    # Replaced by RTCIntersectFunctionN and RTCOccludedFunctionN in Embree 4
    #ctypedef void (*RTCIntersectFunc)(void* ptr, RTCRay& ray, size_t item)
    #ctypedef void (*RTCIntersectFunc4)(const void* valid, void* ptr, RTCRay4& ray, size_t item)
    #ctypedef void (*RTCIntersectFunc8)(const void* valid, void* ptr, RTCRay8& ray, size_t item)
    #ctypedef void (*RTCIntersectFunc16)(const void* valid, void* ptr, RTCRay16& ray, size_t item)
    #ctypedef void (*RTCOccludedFunc)(void* ptr, RTCRay& ray, size_t item)
    #ctypedef void (*RTCOccludedFunc4)(const void* valid, void* ptr, RTCRay4& ray, size_t item)
    #ctypedef void (*RTCOccludedFunc8)(const void* valid, void* ptr, RTCRay8& ray, size_t item)
    #ctypedef void (*RTCOccludedFunc16)(const void* valid, void* ptr, RTCRay16& ray, size_t item)

    #unsigned rtcNewUserGeometry(RTCScene scene, size_t numGeometries) # Removed in Embree4 use rtcNewGeometry

    # Use new function definition. Note: scene -> geometry, unsigned int -> RTCGeometry
    void rtcSetBoundsFunction(RTCGeometry geometry, unsigned geomID, rtc.RTCBoundsFunction bounds) #unsigned geomID is not used

    # The following functions are REMOVED. Use rtcSetGeometryIntersectFunction/rtcSetGeometryOccludedFunction
    # and pass the appropriate function pointer (RTCIntersectFunctionN or RTCOccludedFunctionN).
    #void rtcSetIntersectFunction(RTCScene scene, unsigned geomID, RTCIntersectFunc intersect)
    #void rtcSetIntersectFunction4(RTCScene scene, unsigned geomID, RTCIntersectFunc4 intersect4)
    #void rtcSetIntersectFunction8(RTCScene scene, unsigned geomID, RTCIntersectFunc8 intersect8)
    #void rtcSetIntersectFunction16(RTCScene scene, unsigned geomID, RTCIntersectFunc16 intersect16)
    #void rtcSetOccludedFunction(RTCScene scene, unsigned geomID, RTCOccludedFunc occluded)
    #void rtcSetOccludedFunction4(RTCScene scene, unsigned geomID, RTCOccludedFunc4 occluded4)
    #void rtcSetOccludedFunction8(RTCScene scene, unsigned geomID, RTCOccludedFunc8 occluded8)
    #void rtcSetOccludedFunction16(RTCScene scene, unsigned geomID, RTCOccludedFunc16 occluded16)

    # New functions
    void rtcSetIntersectFunction(RTCGeometry geometry, rtc.RTCIntersectFunctionN intersect)
    void rtcSetOccludedFunction (RTCGeometry geometry, rtc.RTCOccludedFunctionN  occluded)