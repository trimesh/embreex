# rtcore.pxd wrapper

cimport cython
from cython cimport bint, ssize_t
cimport numpy as np


cdef extern from "embree4/rtcore.h":
    #  Embree 4 API changes from v3
    #  - rtcInit and rtcExit are removed.
    #  - rtcDevice retained/released
    #  - RTCErrorFunc2, userPtr
    #  - RTCMemoryMonitorFunc

    # void rtcInit(const char* cfg) # REMOVED in Embree 4
    # void rtcExit()               # REMOVED in Embree 4

    cdef enum RTCError:
        RTC_ERROR_NONE
        RTC_ERROR_UNKNOWN
        RTC_ERROR_INVALID_ARGUMENT
        RTC_ERROR_INVALID_OPERATION
        RTC_ERROR_OUT_OF_MEMORY
        RTC_ERROR_UNSUPPORTED_CPU
        RTC_ERROR_CANCELLED
        # Embree 4.3.3 - New error type
        RTC_ERROR_LEVEL_ZERO_RAYTRACING_SUPPORT_MISSING

    # typedef struct __RTCDevice {}* RTCDevice;  # No longer an opaque pointer.
    ctypedef void * RTCDevice

    RTCDevice rtcNewDevice(const char * cfg)
    # Embree 4 added retain/release
    void rtcRetainDevice(RTCDevice device)
    void rtcReleaseDevice(RTCDevice device)

    RTCError rtcGetError()
    # Embree 4 uses a single error function with a user pointer.
    ctypedef void (*RTCErrorFunc2)(void * userPtr, const RTCError code, const char * str)
    void rtcSetDeviceErrorFunction2(RTCDevice device, RTCErrorFunc2 func, void * userPtr)
    #void rtcSetErrorFunction(RTCErrorFunc func)   # REMOVED

    ctypedef bint (*RTCMemoryMonitorFunc)(void * userPtr, ssize_t bytes, bint post)  # Added userPtr
    bint rtcSetDeviceMemoryMonitorFunction(RTCDevice device, RTCMemoryMonitorFunc func,
                                           void * userPtr)  # Added device arg
    # void rtcSetMemoryMonitorFunction(RTCMemoryMonitorFunc func) # REMOVED

    # Embree 4.3.3 New functions
    const char * rtcGetDeviceLastErrorMessage(RTCDevice device)
    const char * rtcGetErrorString(RTCError code)

cdef extern from "embree4/rtcore_ray.h":
    # RTCORE_ALIGN(16)  # Macro no longer needed (assume alignment)

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
    * args, const
    struct RTCFilterFunctionNArguments
    * filterArgs
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


cdef extern from "embree4/rtcore_geometry.h":
    # RTCBufferType definitions
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
        RTC_BUFFER_TYPE_TRANSFORM  # Embree 4 Instance Array transform buffer

    ctypedef enum RTCFormat:  # For buffer data types
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
        RTC_FORMAT_GRID  # Special type for Grid meshes.
        RTC_FORMAT_QUATERNION_DECOMPOSITION  # For quaternion motion blur

    ctypedef enum RTCGeometryType:  # New in Embree 4
        RTC_GEOMETRY_TYPE_TRIANGLE
        RTC_GEOMETRY_TYPE_QUAD
        RTC_GEOMETRY_TYPE_GRID
        RTC_GEOMETRY_TYPE_SUBDIVISION
        RTC_GEOMETRY_TYPE_CURVE  # Generic curve type.
        RTC_GEOMETRY_TYPE_POINT  # Generic point type.

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

        RTC_GEOMETRY_TYPE_CONE_LINEAR_CURVE  # New in Embree 3.11.0

        RTC_GEOMETRY_TYPE_SPHERE_POINT
        RTC_GEOMETRY_TYPE_DISC_POINT
        RTC_GEOMETRY_TYPE_ORIENTED_DISC_POINT

        RTC_GEOMETRY_TYPE_USER
        RTC_GEOMETRY_TYPE_INSTANCE
        RTC_GEOMETRY_TYPE_INSTANCE_ARRAY  # Embree 4 Instance Array

    ctypedef enum RTCCurveBasis:
        RTC_CURVE_BASIS_LINEAR
        RTC_CURVE_BASIS_BEZIER
        RTC_CURVE_BASIS_BSPLINE
        RTC_CURVE_BASIS_HERMITE
        RTC_CURVE_BASIS_CATMULL_ROM

    ctypedef enum RTCRayQueryLevel:  # New in Embree 4
        RTC_RAY_QUERY_LEVEL_INSTANCE
        RTC_RAY_QUERY_LEVEL_TOP_LEVEL

    # Type for geometry/scene handles is now consistent.
    #typedef struct RTCScene {}* RTCScene;
    ctypedef void * RTCGeometry;

    # No more flags or numTimeSteps - use rtcNewGeometry
    #unsigned rtcNewTriangleMesh(RTCScene scene, RTCGeometryFlags flags,
    #                            size_t numTriangles, size_t numVertices,
    #                            size_t numTimeSteps)
    RTCGeometry rtcNewGeometry(RTCDevice device, RTCGeometryType type)

    # Simplified buffer management:  rtcSetNewBuffer, rtcSetSharedBuffer, rtcGetBufferData
    void * rtcSetNewBuffer(RTCGeometry geometry, RTCBufferType type, unsigned int slot, RTCFormat format,
                           size_t byteStride, size_t itemCount)
    void  rtcSetSharedBuffer(RTCGeometry geometry, RTCBufferType type, unsigned int slot, RTCFormat format,
                             const void * ptr, size_t byteOffset, size_t byteStride, size_t itemCount)
    void * rtcGetGeometryBufferData(RTCGeometry geometry, RTCBufferType type, unsigned int slot)

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
    void rtcSetGeometrySubdivisionMode(RTCGeometry geometry, unsigned int topologyID, enum RTCSubdivisionMode
    mode
    )

    void rtcSetGeometryVertexAttributeTopology(RTCGeometry geometry, unsigned int vertexAttributeID,
                                               unsigned int topologyID)
    void rtcSetGeometryDisplacementFunction(RTCGeometry geometry,
                                            RTCDisplacementFunctionN func)  # Just accept RTCDisplacementFunctionN

    void rtcSetGeometryTimeStepCount(RTCGeometry geometry, unsigned int timeStepCount)  # Embree 4 uses this
    void rtcSetGeometryTimeRange(RTCGeometry geometry, float startTime, float endTime)  # Added in Embree 3.3.0

    void rtcSetGeometryMask(RTCGeometry geometry, int mask)
    void rtcSetGeometryBuildQuality(RTCGeometry geometry, enum RTCBuildQuality
    quality
    )

    # New in Embree 3.2.0
    void rtcSetGeometryMaxRadiusScale(RTCGeometry geometry, float maxRadiusScale)

    # Subdivision related functions
    float rtcGetGeometryTessellationRate(RTCGeometry geometry, unsigned int edge)
    void  rtcSetGeometryTessellationRate(RTCGeometry geometry, float tessellationRate)

    void  rtcSetGeometryTopologyCount(RTCGeometry geometry, unsigned int topologyCount)

    # New functions to work with curves (flags buffer)
    ctypedef enum RTCCurveFlags: unsigned
    char
    RTC_CURVE_FLAG_NEIGHBOR_LEFT = 1 << 0
    RTC_CURVE_FLAG_NEIGHBOR_RIGHT = 1 << 1

# New in Embree 4 - User data passed through scene, not geometry
void * rtcGetGeometryUserDataFromScene(RTCScene
scene, unsigned
int
geomID)

# New Instance API
void
rtcSetGeometryInstancedScene(RTCGeometry
geometry, RTCScene
scene)
void
rtcSetGeometryInstancedScenes(RTCGeometry
geometry, RTCScene * scenes, size_t
numScenes)  # Embree 4 Instance Arrays

# Matrix layout for transforms
ctypedef enum
RTCMatrixLayout:
RTC_MATRIX_ROW_MAJOR
RTC_MATRIX_COLUMN_MAJOR
RTC_MATRIX_COLUMN_MAJOR_ALIGNED16

void
rtcSetGeometryTransform(RTCGeometry
geometry, unsigned
int
timeStep, RTCFormat
format, const
float * xfm)

# New Instance API (Quaternion motion blur)
ctypedef struct
RTCQuaternionDecomposition
float
scale_x
float
scale_y
float
scale_z
float
skew_xy
float
skew_xz
float
skew_yz
float
shift_x
float
shift_y
float
shift_z
float
quaternion_r
float
quaternion_i
float
quaternion_j
float
quaternion_k
float
translation_x
float
translation_y
float
translation_z

void
rtcInitQuaternionDecomposition(struct
RTCQuaternionDecomposition * qd)

void
rtcSetGeometryTransformQuaternion(RTCGeometry
geometry, unsigned
int
timeStep, const
struct
RTCQuaternionDecomposition * qd)

# Simplified getting user data
void * rtcGetGeometryUserData(RTCGeometry
geometry)

# New functions for getting geometry information:
unsigned
int
rtcGetGeometryFirstHalfEdge(RTCGeometry
geometry, unsigned
int
faceID)
unsigned
int
rtcGetGeometryFace(RTCGeometry
geometry, unsigned
int
edgeID)
unsigned
int
rtcGetGeometryNextHalfEdge(RTCGeometry
geometry, unsigned
int
edgeID)
unsigned
int
rtcGetGeometryPreviousHalfEdge(RTCGeometry
geometry, unsigned
int
edgeID)
unsigned
int
rtcGetGeometryOppositeHalfEdge(RTCGeometry
geometry, unsigned
int
topologyID, unsigned
int
edgeID)

# For instancing
void
rtcGetGeometryTransform(RTCGeometry
geometry, float
time, RTCFormat
format, void * xfm)
void
rtcGetGeometryTransformEx(RTCGeometry
geometry, unsigned
int
instPrimID, float
time, RTCFormat
format, void * xfm)  # Embree 4 extended version
void * rtcGetGeometryTransformFromScene(RTCScene
scene, unsigned
int
geomID, float
time, RTCFormat
format, void * xfm)  # Embree4
void
rtcSetGeometryUserPrimitiveCount(RTCGeometry
geometry, size_t
numPrimitives)

# Interpolation functions
void
rtcInterpolate(const
struct
RTCInterpolateArguments * args)
void
rtcInterpolateN(const
struct
RTCInterpolateNArguments * args)

#New filter functions
void
rtcSetGeometryIntersectFilterFunction(RTCGeometry
geometry, RTCFilterFunctionN
filter)
void
rtcSetGeometryOccludedFilterFunction(RTCGeometry
geometry, RTCFilterFunctionN
filter)

# Embree 4 filter functions
void
rtcSetGeometryEnableFilterFunctionFromArguments(RTCGeometry
geometry, bint
enable)

# New API function in Embree 4
ctypedef struct
RTCBounds:
float
lower_x, lower_y, lower_z, align0
float
upper_x, upper_y, upper_z, align1

ctypedef void (*RTCBoundsFunction)(const struct RTCBoundsFunctionArguments
*args )

ctypedef struct
RTCBoundsFunctionArguments:
void * geometryUserPtr
unsigned
int
primID
unsigned
int
timeStep
RTCBounds * bounds_o  # Output bounds

void
rtcSetGeometryBoundsFunction(RTCGeometry
geometry, RTCBoundsFunction
bounds, void * userPtr)

# For compatibility, keep old function names.
#ctypedef RTCBoundsFunc RTCBoundsFunc2

# New functions in Embree 4.
RTCGeometry
rtcGetGeometry(RTCScene
scene, unsigned
int
geomID)  # Now returns RTCGeometry
RTCGeometry
rtcGetGeometryThreadSafe(RTCScene
scene, unsigned
int
geomID)  # Now returns RTCGeometry

# For instance array support
void
rtcSetGeometryInstancedScenes(RTCGeometry
geometry, RTCScene * scenes, size_t
numScenes)

cdef extern
from

"embree4/rtcore_geometry_user.h":

ctypedef struct RTCPointQueryFunctionArguments:
    #const struct RTCPointQuery* query # The original query
    #void* userPtr # User data
    #unsigned int primID
    #unsigned int geomID
    #struct RTCPointQueryContext* context # required to access the current instance
    #float similarityScale
    pass  # Cython has problems if this is a substruct.  Access from Python.

ctypedef bint (*RTCPointQueryFunc)(struct RTCPointQueryFunctionArguments
*args)

# point query related functions
void
rtcSetGeometryPointQueryFunction(RTCGeometry
geometry, RTCPointQueryFunc
queryFunc)

cdef extern from "embree4/rtcore_scene.h":
    # ctypedef void* RTCDevice # Already defined
    ctypedef void * RTCScene

    RTCScene rtcNewScene(RTCDevice device)  # device instead of flags, aflags

    # device functions
    RTCScene  rtcDeviceNewScene(RTCDevice device, RTCSceneFlags flags, RTCAlgorithmFlags aflags)  # Old API

    # No longer need progress monitor function
    #void rtcSetProgressMonitorFunction(RTCScene scene, RTCProgressMonitorFunc func, void* ptr)

    void rtcCommitScene(RTCScene scene)  # Instead of rtcCommit
    void rtcJoinCommitScene(RTCScene scene)

    # Ray tracing functions.  Accept RTCRayHit
    void rtcIntersect1(RTCScene scene, struct RTCRayHit
    * rayhit, struct
    RTCIntersectArguments * args
    )  # Embree4 adds args struct
    void rtcOccluded1(RTCScene scene, struct RTCRayHit
    * rayhit, struct
    RTCOccludedArguments * args
    )  # Embree4 adds args struct

    void rtcIntersect4(const void * valid, RTCScene scene, struct RTCRayHit4
    * rayhit, struct
    RTCIntersectArguments * args
    )  # Embree4
    void rtcOccluded4(const void * valid, RTCScene scene, struct RTCRayHit4
    * rayhit, struct
    RTCOccludedArguments * args
    )  # Embree4

    void rtcIntersect8(const void * valid, RTCScene scene, struct RTCRayHit8
    * rayhit, struct
    RTCIntersectArguments * args
    )  # Embree4
    void rtcOccluded8(const void * valid, RTCScene scene, struct RTCRayHit8
    * rayhit, struct
    RTCOccludedArguments * args
    )  # Embree4

    void rtcIntersect16(const void * valid, RTCScene scene, struct RTCRayHit16
    * rayhit, struct
    RTCIntersectArguments * args
    )  # Embree4
    void rtcOccluded16(const void * valid, RTCScene scene, struct RTCRayHit16
    * rayhit, struct
    RTCOccludedArguments * args
    )  # Embree4

    # New function in Embree 4 for forwarding rays
    void rtcForwardIntersect1(const struct RTCIntersectFunctionNArguments
    * args, RTCScene
    scene, struct
    RTCRay * ray, unsigned
    int instID
    )
    void rtcForwardOccluded1(const struct RTCOccludedFunctionNArguments
    * args, RTCScene
    scene, struct
    RTCRay * ray, unsigned
    int instID
    )
    # New extended functions in Embree 4 for forwarding rays (for instance arrays)
    void rtcForwardIntersect1Ex(const struct RTCIntersectFunctionNArguments
    * args, RTCScene
    scene, struct
    RTCRay * ray, unsigned
    int instID, unsigned
    int instPrimID
    )
    void rtcForwardOccluded1Ex(const struct RTCOccludedFunctionNArguments
    * args, RTCScene
    scene, struct
    RTCRay * ray, unsigned
    int instID, unsigned
    int instPrimID
    )

    void rtcForwardIntersect4(void * valid, const struct RTCIntersectFunctionNArguments
    * args, RTCScene
    scene, struct
    RTCRay4 * ray, unsigned
    int instID
    )
    void rtcForwardOccluded4(void * valid, const struct RTCOccludedFunctionNArguments
    * args, RTCScene
    scene, struct
    RTCRay4 * ray, unsigned
    int instID
    )
    void rtcForwardIntersect8(void * valid, const struct RTCIntersectFunctionNArguments
    * args, RTCScene
    scene, struct
    RTCRay8 * ray, unsigned
    int instID
    )
    void rtcForwardOccluded8(void * valid, const struct RTCOccludedFunctionNArguments
    * args, RTCScene
    scene, struct
    RTCRay8 * ray, unsigned
    int instID
    )
    void rtcForwardIntersect16(void * valid, const struct RTCIntersectFunctionNArguments
    * args, RTCScene
    scene, struct
    RTCRay16 * ray, unsigned
    int instID
    )
    void rtcForwardOccluded16(void * valid, const struct RTCOccludedFunctionNArguments
    * args, RTCScene
    scene, struct
    RTCRay16 * ray, unsigned
    int instID
    )

    void rtcDeleteScene(RTCScene scene)
    # Use retain/release
    void rtcRetainScene(RTCScene scene)
    void rtcReleaseScene(RTCScene scene)

    # Scene flags:
    cdef enum RTCSceneFlags:
        RTC_SCENE_FLAG_NONE
        RTC_SCENE_FLAG_DYNAMIC
        RTC_SCENE_FLAG_COMPACT
        RTC_SCENE_FLAG_ROBUST
        # New in Embree 4
        RTC_SCENE_FLAG_FILTER_FUNCTION_IN_ARGUMENTS  # Enable passing filter function as argument.

    RTCSceneFlags rtcGetSceneFlags(RTCScene scene)
    void          rtcSetSceneFlags(RTCScene scene, RTCSceneFlags flags)

    # New functions in Embree 4 - scene bounds
    ctypedef struct RTCLinearBounds:
        RTCBounds bounds0
        RTCBounds bounds1
    void rtcGetSceneBounds(RTCScene scene, RTCBounds * bounds_o)
    void rtcGetSceneLinearBounds(RTCScene scene, RTCLinearBounds * bounds_o)

    RTCDevice rtcGetSceneDevice(RTCScene scene)

    # New in Embree 4
    ctypedef enum RTCAlgorithmFlags:
        RTC_INTERSECT1  # No longer really flags.  Just one at a time.
        RTC_INTERSECT4
        RTC_INTERSECT8
        RTC_INTERSECT16

cdef class EmbreeDevice:
    cdef RTCDevice device

cdef void print_error(rtc.RTCError code) except +  # Use Embree 4 error codes.