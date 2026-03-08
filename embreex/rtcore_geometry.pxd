# rtcore_geometry wrapper

from .rtcore_ray cimport RTCRay, RTCRay4, RTCRay8, RTCRay16
from .rtcore_scene cimport RTCScene
from . cimport rtcore as rtc
cimport cython
cimport numpy as np

cdef extern from "embree4/rtcore_geometry.h":
    cdef unsigned int RTC_INVALID_GEOMETRY_ID

    cdef enum RTCBufferType:
        RTC_BUFFER_TYPE_INDEX
        RTC_BUFFER_TYPE_VERTEX
        RTC_BUFFER_TYPE_VERTEX_ATTRIBUTE
        RTC_BUFFER_TYPE_NORMAL
        RTC_BUFFER_TYPE_TANGENT
        RTC_BUFFER_TYPE_NORMAL_DERIVATIVE
        RTC_BUFFER_TYPE_GRID
        RTC_BUFFER_TYPE_FACE
        RTC_BUFFER_TYPE_LEVEL
        RTC_BUFFER_TYPE_EDGE_CREASE_INDEX
        RTC_BUFFER_TYPE_EDGE_CREASE_WEIGHT
        RTC_BUFFER_TYPE_VERTEX_CREASE_INDEX
        RTC_BUFFER_TYPE_VERTEX_CREASE_WEIGHT
        RTC_BUFFER_TYPE_HOLE
        RTC_BUFFER_TYPE_TRANSFORM
        RTC_BUFFER_TYPE_FLAGS          

    cdef enum RTCFormat:
        RTC_FORMAT_UNDEFINED
        RTC_FORMAT_UCHAR
        RTC_FORMAT_UCHAR2
        RTC_FORMAT_UCHAR3
        RTC_FORMAT_UCHAR4
        RTC_FORMAT_CHAR
        RTC_FORMAT_CHAR2
        RTC_FORMAT_CHAR3
        RTC_FORMAT_CHAR4
        RTC_FORMAT_USHORT
        RTC_FORMAT_USHORT2
        RTC_FORMAT_USHORT3
        RTC_FORMAT_USHORT4
        RTC_FORMAT_SHORT
        RTC_FORMAT_SHORT2
        RTC_FORMAT_SHORT3
        RTC_FORMAT_SHORT4
        RTC_FORMAT_UINT
        RTC_FORMAT_UINT2
        RTC_FORMAT_UINT3
        RTC_FORMAT_UINT4
        RTC_FORMAT_INT
        RTC_FORMAT_INT2
        RTC_FORMAT_INT3
        RTC_FORMAT_INT4
        RTC_FORMAT_FLOAT
        RTC_FORMAT_FLOAT2
        RTC_FORMAT_FLOAT3
        RTC_FORMAT_FLOAT4

    cdef enum RTCGeometryType:
        RTC_GEOMETRY_TYPE_TRIANGLE
        RTC_GEOMETRY_TYPE_QUAD
        RTC_GEOMETRY_TYPE_GRID
        RTC_GEOMETRY_TYPE_SUBDIVISION
        RTC_GEOMETRY_TYPE_USER
        RTC_GEOMETRY_TYPE_INSTANCE

    cdef struct RTCBounds:
        float lower_x, lower_y, lower_z, align0
        float upper_x, upper_y, upper_z, align1

    ctypedef void (*RTCFilterFunc)(void* ptr, RTCRay& ray)
    ctypedef void (*RTCFilterFunc4)(void* ptr, RTCRay4& ray)
    ctypedef void (*RTCFilterFunc8)(void* ptr, RTCRay8& ray)
    ctypedef void (*RTCFilterFunc16)(void* ptr, RTCRay16& ray)

    ctypedef void (*RTCDisplacementFunc)(void* ptr, unsigned geomID, unsigned primID,
                                         const float* u, const float* v,
                                         const float* nx, const float* ny, const float* nz,
                                         float* px, float* py, float* pz, size_t N)

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
    void rtcSetGeometryUserData(RTCGeometry geometry, void* ptr)
    void* rtcGetGeometryUserData(RTCGeometry geometry)
    void rtcSetGeometryMask(RTCGeometry geometry, unsigned int mask)
    unsigned int rtcAttachGeometry(RTCScene scene, RTCGeometry geometry)
    void rtcAttachGeometryByID(RTCScene scene, RTCGeometry geometry, unsigned int geomID)
    void rtcDetachGeometry(RTCScene scene, unsigned int geomID)
    RTCGeometry rtcGetGeometry(RTCScene scene, unsigned int geomID)
    void rtcSetGeometryInstancedScene(RTCGeometry geometry, RTCScene scene)

