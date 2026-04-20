# rtcore_geometry wrapper
#
# Only triangle geometry is used. Other geometry types, filter/displacement
# callbacks, user data, instancing, and the full enum surfaces are documented
# in embree4/include/embree4/rtcore_geometry.h.

from .rtcore_scene cimport RTCScene
from . cimport rtcore as rtc
cimport cython
cimport numpy as np

cdef extern from "embree4/rtcore_geometry.h":

    cdef enum RTCBufferType:
        RTC_BUFFER_TYPE_INDEX
        RTC_BUFFER_TYPE_VERTEX

    cdef enum RTCFormat:
        RTC_FORMAT_UINT3
        RTC_FORMAT_FLOAT3

    cdef enum RTCGeometryType:
        RTC_GEOMETRY_TYPE_TRIANGLE

    ctypedef void* RTCGeometry

    RTCGeometry rtcNewGeometry(rtc.RTCDevice device, RTCGeometryType type)
    void rtcCommitGeometry(RTCGeometry geometry)
    void rtcReleaseGeometry(RTCGeometry geometry)
    void* rtcSetNewGeometryBuffer(RTCGeometry geometry,
                                  RTCBufferType type,
                                  unsigned int slot,
                                  RTCFormat format,
                                  size_t byteStride,
                                  size_t itemCount)
    unsigned int rtcAttachGeometry(RTCScene scene, RTCGeometry geometry)
