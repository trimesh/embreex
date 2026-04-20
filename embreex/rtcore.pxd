# rtcore.pxd wrapper
#
# Only declarations actually used by this package are exposed here.
# To expose more of the Embree API, see embree4/include/embree4/rtcore.h.

cimport cython
cimport numpy as np


cdef extern from "embree4/rtcore.h":
    cdef int RTC_VERSION_MAJOR
    cdef int RTC_VERSION_MINOR
    cdef int RTC_VERSION_PATCH

    cdef enum RTCError:
        RTC_ERROR_NONE
        RTC_ERROR_UNKNOWN
        RTC_ERROR_INVALID_ARGUMENT
        RTC_ERROR_INVALID_OPERATION
        RTC_ERROR_OUT_OF_MEMORY
        RTC_ERROR_UNSUPPORTED_CPU
        RTC_ERROR_CANCELLED

    ctypedef void* RTCDevice

    RTCDevice rtcNewDevice(const char* cfg)
    void rtcReleaseDevice(RTCDevice device)

    ctypedef void (*RTCErrorFunc)(void* userPtr, RTCError code, const char* str)
    void rtcSetDeviceErrorFunction(RTCDevice device, RTCErrorFunc func, void* userPtr)


cdef struct Vertex:
    float x, y, z, r

cdef struct Triangle:
    int v0, v1, v2

cdef struct Vec3f:
    float x, y, z

cdef void print_error(RTCError code)

cdef class EmbreeDevice:
    cdef RTCDevice device
