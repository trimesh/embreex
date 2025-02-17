# distutils: language=c++

cimport numpy as np
cimport rtcore as rtc
#cimport rtcore_ray as rtcr # Removed
#cimport rtcore_scene as rtcs # Removed
#cimport rtcore_geometry as rtcg # Removed
#cimport rtcore_geometry_user as rtcgu # Removed
from rtcore cimport Vertex, Triangle, Vec3f  # Use new unified rtcore module
from libc.stdlib cimport malloc, free

# typedef removed in Embree 4.
#ctypedef Vec3f (*renderPixelFunc)(float x, float y,
#                const Vec3f &vx, const Vec3f &vy, const Vec3f &vz,
#                const Vec3f &p)

def run_triangles():
    pass

cdef rtc.RTCGeometry addCube(rtc.EmbreeScene scene_i): #Return RTCGeometry and receive EmbreeScene
    # Use rtcNewGeometry for all geometry creation.
    cdef rtc.RTCGeometry mesh = rtc.rtcNewGeometry(scene_i.device.device, rtc.RTC_GEOMETRY_TYPE_TRIANGLE)

    # Use rtcSetNewBuffer instead of rtcMapBuffer/rtcUnmapBuffer
    cdef Vertex* vertices = <Vertex*> rtc.rtcSetNewBuffer(mesh, rtc.RTC_BUFFER_TYPE_VERTEX, 0, rtc.RTC_FORMAT_FLOAT3, sizeof(Vertex), 8)
    vertices[0].x = -1
    vertices[0].y = -1
    vertices[0].z = -1

    vertices[1].x = -1
    vertices[1].y = -1
    vertices[1].z = +1

    vertices[2].x = -1
    vertices[2].y = +1
    vertices[2].z = -1

    vertices[3].x = -1
    vertices[3].y = +1
    vertices[3].z = +1

    vertices[4].x = +1
    vertices[4].y = -1
    vertices[4].z = -1

    vertices[5].x = +1
    vertices[5].y = -1
    vertices[5].z = +1

    vertices[6].x = +1
    vertices[6].y = +1
    vertices[6].z = -1

    vertices[7].x = +1
    vertices[7].y = +1
    vertices[7].z = +1

    # rtcg.rtcUnmapBuffer(scene_i, mesh, rtcg.RTC_VERTEX_BUFFER) # No longer needed

    # Example of how you *could* share vertex data, if you wanted to.
    # colors = <Vec3f*> rtc.rtcSetSharedBuffer(mesh, rtc.RTC_BUFFER_TYPE_VERTEX, 1, rtc.RTC_FORMAT_FLOAT3, colors_np, 0, sizeof(Vec3f), 12)
    cdef Vec3f *colors = <Vec3f*> malloc(12*sizeof(Vec3f)) # Not really necessary in this example, could be a stack variable

    cdef int tri = 0
    cdef Triangle* triangles = <Triangle*> rtc.rtcSetNewBuffer(mesh, rtc.RTC_BUFFER_TYPE_INDEX, 0, rtc.RTC_FORMAT_UINT3, sizeof(Triangle), 12)

    # left side
    colors[tri].x = 1.0
    colors[tri].y = 0.0
    colors[tri].z = 0.0
    triangles[tri].v0 = 0
    triangles[tri].v1 = 2
    triangles[tri].v2 = 1
    tri += 1
    colors[tri].x = 1.0
    colors[tri].y = 0.0
    colors[tri].z = 0.0
    triangles[tri].v0 = 1
    triangles[tri].v1 = 2
    triangles[tri].v2 = 3
    tri += 1

    # right side
    colors[tri].x = 0.0
    colors[tri].y = 1.0
    colors[tri].z = 0.0
    triangles[tri].v0 = 4
    triangles[tri].v1 = 5
    triangles[tri].v2 = 6
    tri += 1
    colors[tri].x = 0.0
    colors[tri].y = 1.0
    colors[tri].z = 0.0
    triangles[tri].v0 = 5
    triangles[tri].v1 = 7
    triangles[tri].v2 = 6
    tri += 1

    # bottom side
    colors[tri].x = 0.5
    colors[tri].y = 0.5
    colors[tri].z = 0.5
    triangles[tri].v0 = 0
    triangles[tri].v1 = 1
    triangles[tri].v2 = 4
    tri += 1
    colors[tri].x = 0.5
    colors[tri].y = 0.5
    colors[tri].z = 0.5
    triangles[tri].v0 = 1
    triangles[tri].v1 = 5
    triangles[tri].v2 = 4
    tri += 1

    # top side
    colors[tri].x = 1.0
    colors[tri].y = 1.0
    colors[tri].z = 1.0
    triangles[tri].v0 = 2
    triangles[tri].v1 = 6
    triangles[tri].v2 = 3
    tri += 1
    colors[tri].x = 1.0
    colors[tri].y = 1.0
    colors[tri].z = 1.0
    triangles[tri].v0 = 3
    triangles[tri].v1 = 6
    triangles[tri].v2 = 7
    tri += 1

    # front side
    colors[tri].x = 0.0
    colors[tri].y = 0.0
    colors[tri].z = 1.0
    triangles[tri].v0 = 0
    triangles[tri].v1 = 4
    triangles[tri].v2 = 2
    tri += 1
    colors[tri].x = 0.0
    colors[tri].y = 0.0
    colors[tri].z = 1.0
    triangles[tri].v0 = 2
    triangles[tri].v1 = 4
    triangles[tri].v2 = 6
    tri += 1

    # back side
    colors[tri].x = 1.0
    colors[tri].y = 1.0
    colors[tri].z = 0.0
    triangles[tri].v0 = 1
    triangles[tri].v1 = 3
    triangles[tri].v2 = 5
    tri += 1
    colors[tri].x = 1.0
    colors[tri].y = 1.0
    colors[tri].z = 0.0
    triangles[tri].v0 = 3
    triangles[tri].v1 = 7
    triangles[tri].v2 = 5
    tri += 1

    # rtcg.rtcUnmapBuffer(scene_i, mesh, rtcg.RTC_INDEX_BUFFER) # No longer needed
    rtc.rtcCommitGeometry(mesh)  # Commit the *geometry*, not the scene
    rtc.rtcAttachGeometry(scene_i.scene_i, mesh) # Attach geometry and increment reference count
    free(colors) #Free colors
    return mesh


cdef rtc.RTCGeometry addGroundPlane (rtc.EmbreeScene scene_i): #Return RTCGeometry
    #cdef unsigned int mesh = rtcg.rtcNewTriangleMesh (scene_i, rtcg.RTC_GEOMETRY_STATIC, 2, 4, 1) # Removed in Embree4
    cdef rtc.RTCGeometry mesh = rtc.rtcNewGeometry(scene_i.device.device, rtc.RTC_GEOMETRY_TYPE_TRIANGLE)

    #cdef Vertex* vertices = <Vertex*> rtcg.rtcMapBuffer(scene_i, mesh, rtcg.RTC_VERTEX_BUFFER) # Removed in Embree 4
    cdef Vertex* vertices = <Vertex*> rtc.rtcSetNewBuffer(mesh, rtc.RTC_BUFFER_TYPE_VERTEX, 0, rtc.RTC_FORMAT_FLOAT3, sizeof(Vertex), 4)
    vertices[0].x = -10
    vertices[0].y = -2
    vertices[0].z = -10

    vertices[1].x = -10
    vertices[1].y = -2
    vertices[1].z = +10

    vertices[2].x = +10
    vertices[2].y = -2
    vertices[2].z = -10

    vertices[3].x = +10
    vertices[3].y = -2
    vertices[3].z = +10
    # rtcg.rtcUnmapBuffer(scene_i, mesh, rtcg.RTC_VERTEX_BUFFER) # No longer needed

    #cdef Triangle* triangles = <Triangle*> rtcg.rtcMapBuffer(scene_i, mesh, rtcg.RTC_INDEX_BUFFER) # Removed in Embree 4
    cdef Triangle* triangles = <Triangle*> rtc.rtcSetNewBuffer(mesh, rtc.RTC_BUFFER_TYPE_INDEX, 0, rtc.RTC_FORMAT_UINT3, sizeof(Triangle), 2)
    triangles[0].v0 = 0
    triangles[0].v1 = 2
    triangles[0].v2 = 1
    triangles[1].v0 = 1
    triangles[1].v1 = 2
    triangles[1].v2 = 3

    # rtcg.rtcUnmapBuffer(scene_i, mesh, rtcg.RTC_INDEX_BUFFER) # No longer needed
    rtc.rtcCommitGeometry(mesh) # Commit *geometry*
    rtc.rtcAttachGeometry(scene_i.scene_i, mesh) # Attach geometry
    return mesh