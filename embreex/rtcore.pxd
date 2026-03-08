# rtcore.pxd wrapper

cimport cython
cimport numpy as np


cdef extern from "embree4/rtcore.h":
    cdef int RTC_VERSION_MAJOR
    cdef int RTC_VERSION_MINOR
    cdef int RTC_VERSION_PATCH

    void rtcInit(const char* cfg)
    void rtcExit()

    cdef enum RTCError:
        RTC_ERROR_NONE
        RTC_ERROR_UNKNOWN
        RTC_ERROR_INVALID_ARGUMENT
        RTC_ERROR_INVALID_OPERATION
        RTC_ERROR_OUT_OF_MEMORY
        RTC_ERROR_UNSUPPORTED_CPU
        RTC_ERROR_CANCELLED

    # typedef struct __RTCDevice {}* RTCDevice;
    ctypedef void* RTCDevice

    RTCDevice rtcNewDevice(const char* cfg)
    void rtcReleaseDevice(RTCDevice device)

    RTCError rtcGetDeviceError(RTCDevice device)
    ctypedef void (*RTCErrorFunc)(void* userPtr, RTCError code, const char* str)
    void rtcSetDeviceErrorFunction(RTCDevice device, RTCErrorFunc func, void* userPtr)

    ctypedef bint RTCMemoryMonitorFunc(const ssize_t _bytes, const bint post)
    void rtcSetMemoryMonitorFunction(RTCMemoryMonitorFunc func)

cdef extern from "embree4/rtcore_ray.h":
    pass

cdef struct Vertex:
    float x, y, z, r

cdef struct Triangle:
    int v0, v1, v2

cdef struct Vec3f:
    float x, y, z

cdef void print_error(RTCError code)

cdef class EmbreeDevice:
    cdef RTCDevice device
