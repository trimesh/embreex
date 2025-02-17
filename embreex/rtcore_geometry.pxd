# rtcore_geometry wrapper

#from .rtcore_ray cimport RTCRay, RTCRay4, RTCRay8, RTCRay16 #Removed in Embree4
#from .rtcore_scene cimport RTCScene #Removed in Embree4
import rtcore as rtc #Embree 4
cimport cython
cimport numpy as np

cdef extern from "embree4/rtcore_geometry.h":
    #cdef unsigned int RTC_INVALID_GEOMETRY_ID  # Now a constant, not an enum.  Access via rtcore

    ctypedef enum RTCBufferType:
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
        RTC_BUFFER_TYPE_TRANSFORM # Embree 4 Instance Array transform buffer

    ctypedef enum RTCFormat: # For buffer data types
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
        RTC_FORMAT_FLOAT5
        RTC_FORMAT_FLOAT6
        RTC_FORMAT_FLOAT7
        RTC_FORMAT_FLOAT8
        RTC_FORMAT_FLOAT9
        RTC_FORMAT_FLOAT10
        RTC_FORMAT_FLOAT11
        RTC_FORMAT_FLOAT12
        RTC_FORMAT_FLOAT13
        RTC_FORMAT_FLOAT14
        RTC_FORMAT_FLOAT15
        RTC_FORMAT_FLOAT16
        RTC_FORMAT_FLOAT3X4_ROW_MAJOR
        RTC_FORMAT_FLOAT4X4_ROW_MAJOR
        RTC_FORMAT_FLOAT3X4_COLUMN_MAJOR
        RTC_FORMAT_FLOAT4X4_COLUMN_MAJOR
        RTC_FORMAT_GRID # Special type for Grid meshes.
        RTC_FORMAT_QUATERNION_DECOMPOSITION # For quaternion motion blur

    ctypedef enum RTCGeometryType:  # New in Embree 4
        RTC_GEOMETRY_TYPE_TRIANGLE
        RTC_GEOMETRY_TYPE_QUAD
        RTC_GEOMETRY_TYPE_GRID
        RTC_GEOMETRY_TYPE_SUBDIVISION
        RTC_GEOMETRY_TYPE_CURVE # Generic curve type.
        RTC_GEOMETRY_TYPE_POINT # Generic point type.

        RTC_GEOMETRY_TYPE_FLAT_LINEAR_CURVE
        RTC_GEOMETRY_TYPE_FLAT_BEZIER_CURVE
        RTC_GEOMETRY_TYPE_FLAT_BSPLINE_CURVE
        RTC_GEOMETRY_TYPE_FLAT_HERMITE_CURVE
        RTC_GEOMETRY_TYPE_FLAT_CATMULL_ROM_CURVE

        RTC_GEOMETRY_TYPE_ROUND_LINEAR_CURVE
        RTC_GEOMETRY_TYPE_ROUND_BEZIER_CURVE
        RTC_GEOMETRY_TYPE_ROUND_BSPLINE_CURVE
        RTC_GEOMETRY_TYPE_ROUND_HERMITE_CURVE
        RTC_GEOMETRY_TYPE_ROUND_CATMULL_ROM_CURVE

        RTC_GEOMETRY_TYPE_NORMAL_ORIENTED_BEZIER_CURVE
        RTC_GEOMETRY_TYPE_NORMAL_ORIENTED_BSPLINE_CURVE
        RTC_GEOMETRY_TYPE_NORMAL_ORIENTED_HERMITE_CURVE
        RTC_GEOMETRY_TYPE_NORMAL_ORIENTED_CATMULL_ROM_CURVE

        RTC_GEOMETRY_TYPE_CONE_LINEAR_CURVE # New in Embree 3.11.0

        RTC_GEOMETRY_TYPE_SPHERE_POINT
        RTC_GEOMETRY_TYPE_DISC_POINT
        RTC_GEOMETRY_TYPE_ORIENTED_DISC_POINT

        RTC_GEOMETRY_TYPE_USER
        RTC_GEOMETRY_TYPE_INSTANCE
        RTC_GEOMETRY_TYPE_INSTANCE_ARRAY # Embree 4 Instance Array

    ctypedef enum RTCCurveBasis:
        RTC_CURVE_BASIS_LINEAR
        RTC_CURVE_BASIS_BEZIER
        RTC_CURVE_BASIS_BSPLINE
        RTC_CURVE_BASIS_HERMITE
        RTC_CURVE_BASIS_CATMULL_ROM

    ctypedef enum RTCRayQueryLevel: # New in Embree 4
        RTC_RAY_QUERY_LEVEL_INSTANCE
        RTC_RAY_QUERY_LEVEL_TOP_LEVEL

    # Type for geometry/scene handles is now consistent.
    #typedef struct RTCScene {}* RTCScene;
    ctypedef void* RTCGeometry;


    # No more flags or numTimeSteps - use rtcNewGeometry
    #unsigned rtcNewTriangleMesh(RTCScene scene, RTCGeometryFlags flags,
    #                            size_t numTriangles, size_t numVertices,
    #                            size_t numTimeSteps)
    RTCGeometry rtcNewGeometry(rtc.RTCDevice device, RTCGeometryType type)


    # Simplified buffer management:  rtcSetNewBuffer, rtcSetSharedBuffer, rtcGetBufferData
    void* rtcSetNewBuffer(RTCGeometry geometry, RTCBufferType type, unsigned int slot, RTCFormat format, size_t byteStride, size_t itemCount)
    void  rtcSetSharedBuffer(RTCGeometry geometry, RTCBufferType type, unsigned int slot, RTCFormat format, const void* ptr, size_t byteOffset, size_t byteStride, size_t itemCount)
    void* rtcGetGeometryBufferData(RTCGeometry geometry, RTCBufferType type, unsigned int slot)

    # Simplified updating:
    void rtcUpdateGeometryBuffer(RTCGeometry geometry, RTCBufferType type, unsigned int slot)

    # Simplified enable/disable
    void rtcEnableGeometry(RTCGeometry geometry)
    void rtcDisableGeometry(RTCGeometry geometry)

    # Simplified Commit
    void rtcCommitGeometry(RTCGeometry geometry)

    # Key API differences:
    #  - rtcMapBuffer/rtcUnmapBuffer are REMOVED
    #  - Use rtcSetNewBuffer, rtcSetSharedBuffer, rtcGetBufferData
    #  - Use rtcNewGeometry for ALL geometry types.
    #  - Use a single RTCGeometry handle, not unsigned int.


    # New functions for setting parameters:

    # Subdivision mode:
    ctypedef enum RTCSubdivisionMode:
        RTC_SUBDIVISION_MODE_NO_BOUNDARY
        RTC_SUBDIVISION_MODE_SMOOTH_BOUNDARY
        RTC_SUBDIVISION_MODE_PIN_CORNERS
        RTC_SUBDIVISION_MODE_PIN_BOUNDARY
        RTC_SUBDIVISION_MODE_PIN_ALL
    void rtcSetGeometrySubdivisionMode(RTCGeometry geometry, unsigned int topologyID, enum RTCSubdivisionMode mode)

    void rtcSetGeometryVertexAttributeTopology(RTCGeometry geometry, unsigned int vertexAttributeID, unsigned int topologyID)
    void rtcSetGeometryDisplacementFunction (RTCGeometry geometry, rtc.RTCDisplacementFunctionN func) # Just accept RTCDisplacementFunctionN

    void rtcSetGeometryTimeStepCount(RTCGeometry geometry, unsigned int timeStepCount) # Embree 4 uses this
    void rtcSetGeometryTimeRange(RTCGeometry geometry, float startTime, float endTime) # Added in Embree 3.3.0

    void rtcSetGeometryMask(RTCGeometry geometry, int mask)
    void rtcSetGeometryBuildQuality(RTCGeometry geometry, enum RTCBuildQuality quality)

    # New in Embree 3.2.0
    void rtcSetGeometryMaxRadiusScale(RTCGeometry geometry, float maxRadiusScale)

    # Subdivision related functions
    float rtcGetGeometryTessellationRate(RTCGeometry geometry, unsigned int edge)
    void  rtcSetGeometryTessellationRate(RTCGeometry geometry, float tessellationRate)

    void  rtcSetGeometryTopologyCount(RTCGeometry geometry, unsigned int topologyCount)

    # New functions to work with curves (flags buffer)
    ctypedef enum RTCCurveFlags : unsigned char
      RTC_CURVE_FLAG_NEIGHBOR_LEFT = 1 << 0
      RTC_CURVE_FLAG_NEIGHBOR_RIGHT = 1 << 1

    # New in Embree 4 - User data passed through scene, not geometry
    void* rtcGetGeometryUserDataFromScene (rtc.RTCScene scene, unsigned int geomID)

    # New Instance API
    void rtcSetGeometryInstancedScene(RTCGeometry geometry, rtc.RTCScene scene)
    void rtcSetGeometryInstancedScenes(RTCGeometry geometry, rtc.RTCScene* scenes, size_t numScenes) # Embree 4 Instance Arrays

    # Matrix layout for transforms
    ctypedef enum RTCMatrixLayout:
        RTC_MATRIX_ROW_MAJOR
        RTC_MATRIX_COLUMN_MAJOR
        RTC_MATRIX_COLUMN_MAJOR_ALIGNED16

    void rtcSetGeometryTransform(RTCGeometry geometry, unsigned int timeStep, RTCFormat format, const float* xfm)

    # New Instance API (Quaternion motion blur)
    ctypedef struct RTCQuaternionDecomposition:
      float scale_x
      float scale_y
      float scale_z
      float skew_xy
      float skew_xz
      float skew_yz
      float shift_x
      float shift_y
      float shift_z
      float quaternion_r
      float quaternion_i
      float quaternion_j
      float quaternion_k
      float translation_x
      float translation_y
      float translation_z

    void rtcInitQuaternionDecomposition(struct RTCQuaternionDecomposition* qd)

    void rtcSetGeometryTransformQuaternion(RTCGeometry geometry, unsigned int timeStep, const struct RTCQuaternionDecomposition* qd)

    # Simplified getting user data
    void* rtcGetGeometryUserData (RTCGeometry geometry)

    # New functions for getting geometry information:
    unsigned int rtcGetGeometryFirstHalfEdge(RTCGeometry geometry, unsigned int faceID)
    unsigned int rtcGetGeometryFace(RTCGeometry geometry, unsigned int edgeID)
    unsigned int rtcGetGeometryNextHalfEdge(RTCGeometry geometry, unsigned int edgeID)
    unsigned int rtcGetGeometryPreviousHalfEdge(RTCGeometry geometry, unsigned int edgeID)
    unsigned int rtcGetGeometryOppositeHalfEdge(RTCGeometry geometry, unsigned int topologyID, unsigned int edgeID)

    # For instancing
    void rtcGetGeometryTransform(RTCGeometry geometry, float time, RTCFormat format, void* xfm)
    void rtcGetGeometryTransformEx(RTCGeometry geometry, unsigned int instPrimID, float time, RTCFormat format, void* xfm) # Embree 4 extended version
    void* rtcGetGeometryTransformFromScene (rtc.RTCScene scene, unsigned int geomID, float time, RTCFormat format, void* xfm) # Embree4
    void rtcSetGeometryUserPrimitiveCount (RTCGeometry geometry, size_t numPrimitives)

    # Interpolation functions
    void rtcInterpolate(const struct rtc.RTCInterpolateArguments* args)
    void rtcInterpolateN(const struct rtc.RTCInterpolateNArguments* args)

    #New filter functions
    void rtcSetGeometryIntersectFilterFunction (RTCGeometry geometry, rtc.RTCFilterFunctionN filter)
    void rtcSetGeometryOccludedFilterFunction (RTCGeometry geometry, rtc.RTCFilterFunctionN filter)

    # Embree 4 filter functions
    void rtcSetGeometryEnableFilterFunctionFromArguments (RTCGeometry geometry, bint enable)

    # New API function in Embree 4
    ctypedef struct RTCBounds:
        float lower_x, lower_y, lower_z, align0
        float upper_x, upper_y, upper_z, align1

    ctypedef void (*RTCBoundsFunction)( const struct rtc.RTCBoundsFunctionArguments* args )

    ctypedef struct RTCBoundsFunctionArguments:
        void* geometryUserPtr
        unsigned int primID
        unsigned int timeStep
        RTCBounds* bounds_o # Output bounds

    void rtcSetGeometryBoundsFunction (RTCGeometry geometry, RTCBoundsFunction bounds, void* userPtr)

    # For compatibility, keep old function names.
    #ctypedef RTCBoundsFunc RTCBoundsFunc2

    # New functions in Embree 4.
    RTCGeometry rtcGetGeometry(rtc.RTCScene scene, unsigned int geomID) # Now returns RTCGeometry
    RTCGeometry rtcGetGeometryThreadSafe(rtc.RTCScene scene, unsigned int geomID) # Now returns RTCGeometry

    # For instance array support
    void rtcSetGeometryInstancedScenes(RTCGeometry geometry, rtc.RTCScene* scenes, size_t numScenes)

cdef extern from "embree4/rtcore_geometry_user.h":

    ctypedef struct RTCPointQueryFunctionArguments:
        #const struct RTCPointQuery* query # The original query
        #void* userPtr # User data
        #unsigned int primID
        #unsigned int geomID
        #struct RTCPointQueryContext* context # required to access the current instance
        #float similarityScale
        pass # Cython has problems if this is a substruct.  Access from Python.

    ctypedef bint (*RTCPointQueryFunc)(struct RTCPointQueryFunctionArguments* args)

    # point query related functions
    void rtcSetGeometryPointQueryFunction(RTCGeometry geometry, RTCPointQueryFunc queryFunc)