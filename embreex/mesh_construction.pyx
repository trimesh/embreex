# distutils: language=c++

cimport numpy as np
from cython cimport floating
cimport rtcore as rtc
# These are now all unified under rtcore_geometry
# cimport rtcore_ray as rtcr
# cimport rtcore_scene as rtcs
# cimport rtcore_geometry as rtcg
# cimport rtcore_geometry_user as rtcgu
from rtcore cimport Vertex, Triangle, Vec3f  # Import directly from rtcore


cdef extern from "mesh_construction.h":
    int triangulate_hex[12][3]
    int triangulate_tetra[4][3]

cdef class TriangleMesh:
    r'''
    This class constructs a polygon mesh with triangular elements and
    adds it to the scene.

    Parameters
    ----------

    scene : EmbreeScene
        This is the scene to which the constructed polygons will be
        added.
    vertices : a np.ndarray of floats.
        This specifies the x, y, and z coordinates of the vertices in
        the polygon mesh. This should either have the shape
        (num_triangles, 3, 3), or the shape (num_vertices, 3), depending
        on the value of the `indices` parameter.
    indices : either None, or a np.ndarray of ints
        If None, then vertices must have the shape (num_triangles, 3, 3).
        In this case, `vertices` specifices the coordinates of each
        vertex of each triangle in the mesh, with vertices being
        duplicated if they are shared between triangles. For example,
        if indices is None, then vertices[2][1][0] should give you
        the x-coordinate of the 2nd vertex of the 3rd triangle.
        If indices is a np.ndarray, then it must have the shape
        (num_triangles, 3), and `vertices` must have the shape
        (num_vertices, 3). In this case, indices[2][1] tells you
        the index of the 2nd vertex of the 3rd triangle in `indices`,
        while vertices[5][2] tells you the z-coordinate of the 6th
        vertex in the mesh. Note that the indexing is assumed to be
        zero-based. In this setup, vertices can be shared between
        triangles, and the number of vertices can be less than 3 times
        the number of triangles.

    '''

    cdef Vertex * vertices
    cdef Triangle * indices
    # cdef unsigned int mesh # Embree 3
    cdef rtc.RTCGeometry mesh  # Embree 4 Geometry Handle

    def __init__(self, rtc.EmbreeScene scene,
                 np.ndarray[floating, ndim=2] vertices,
                 np.ndarray[np.int32_t, ndim=2] indices = None):

        if indices is None:
            self._build_from_flat(scene, vertices)
        else:
            self._build_from_indices(scene, vertices, indices)

    def __dealloc__(self):
        if self.mesh is not NULL:  # Check if mesh was initialized
            rtc.rtcReleaseGeometry(self.mesh)  # release in dealloc

    cdef void _build_from_flat(self, rtc.EmbreeScene scene,
                               np.ndarray[floating, ndim=3] tri_vertices) except +:
        cdef int i, j
        cdef int nt = tri_vertices.shape[0]
        # In this scheme, we don't share any vertices.  This leads to cracks,
        # but also means we have exactly three times as many vertices as
        # triangles.

        # Embree 4: Create a triangle mesh geometry
        cdef rtc.RTCGeometry mesh = rtc.rtcNewGeometry(scene.device.device, rtc.RTC_GEOMETRY_TYPE_TRIANGLE)

        # Embree 4:  Use rtcSetSharedBuffer instead of Map/Unmap
        cdef Vertex * vertices = <Vertex *> rtc.rtcSetNewBuffer(mesh,
                                                                rtc.RTC_BUFFER_TYPE_VERTEX, 0, rtc.RTC_FORMAT_FLOAT3,
                                                                sizeof(Vertex), nt * 3)

        for i in range(nt):
            for j in range(3):
                vertices[i * 3 + j].x = tri_vertices[i, j, 0]
                vertices[i * 3 + j].y = tri_vertices[i, j, 1]
                vertices[i * 3 + j].z = tri_vertices[i, j, 2]

        cdef Triangle * triangles = <Triangle *> rtc.rtcSetNewBuffer(mesh,
                                                                     rtc.RTC_BUFFER_TYPE_INDEX, 0, rtc.RTC_FORMAT_UINT3,
                                                                     sizeof(Triangle), nt)
        for i in range(nt):
            triangles[i].v0 = i * 3 + 0
            triangles[i].v1 = i * 3 + 1
            triangles[i].v2 = i * 3 + 2

        self.vertices = vertices
        self.indices = triangles
        self.mesh = mesh
        rtc.rtcCommitGeometry(self.mesh)
        rtc.rtcAttachGeometry(scene.scene_i, self.mesh)

    cdef void _build_from_indices(self, rtc.EmbreeScene scene,
                                  np.ndarray[floating, ndim=2] tri_vertices,
                                  np.ndarray[np.int32_t, ndim=2] tri_indices) except +:
        cdef int i
        cdef int nv = tri_vertices.shape[0]
        cdef int nt = tri_indices.shape[0]

        # Embree 4 geometry creation
        cdef rtc.RTCGeometry mesh = rtc.rtcNewGeometry(scene.device.device, rtc.RTC_GEOMETRY_TYPE_TRIANGLE)

        # set up vertex and triangle arrays. In this case, we just read
        # them directly from the inputs
        cdef Vertex * vertices = <Vertex *> rtc.rtcSetNewBuffer(mesh,
                                                                rtc.RTC_BUFFER_TYPE_VERTEX, 0, rtc.RTC_FORMAT_FLOAT3,
                                                                sizeof(Vertex), nv)

        for i in range(nv):
            vertices[i].x = tri_vertices[i, 0]
            vertices[i].y = tri_vertices[i, 1]
            vertices[i].z = tri_vertices[i, 2]

        cdef Triangle * triangles = <Triangle *> rtc.rtcSetNewBuffer(mesh,
                                                                     rtc.RTC_BUFFER_TYPE_INDEX, 0, rtc.RTC_FORMAT_UINT3,
                                                                     sizeof(Triangle), nt)

        for i in range(nt):
            triangles[i].v0 = tri_indices[i][0]
            triangles[i].v1 = tri_indices[i][1]
            triangles[i].v2 = tri_indices[i][2]

        self.vertices = vertices
        self.indices = triangles
        self.mesh = mesh
        rtc.rtcCommitGeometry(self.mesh)  # Commit geometry
        rtc.rtcAttachGeometry(scene.scene_i, self.mesh)  #Attach geometry

cdef class ElementMesh(TriangleMesh):
    r'''

    Currently, we handle non-triangular mesh types by converting them
    to triangular meshes. This class performs this transformation.
    Currently, this is implemented for hexahedral and tetrahedral
    meshes.

    Parameters
    ----------

    scene : EmbreeScene
        This is the scene to which the constructed polygons will be
        added.
    vertices : a np.ndarray of floats.
        This specifies the x, y, and z coordinates of the vertices in
        the polygon mesh. This should either have the shape
        (num_vertices, 3). For example, vertices[2][1] should give the
        y-coordinate of the 3rd vertex in the mesh.
    indices : a np.ndarray of ints
        This should either have the shape (num_elements, 4) or
        (num_elements, 8) for tetrahedral and hexahedral meshes,
        respectively. For tetrahedral meshes, each element will
        be represented by four triangles in the scene. For hex meshes,
        each element will be represented by 12 triangles, 2 for each
        face. For hex meshes, we assume that the node ordering is as
        defined here:
        http://homepages.cae.wisc.edu/~tautges/papers/cnmev3.pdf

    '''

    def __init__(self, rtc.EmbreeScene scene,
                 np.ndarray[floating, ndim=2] vertices,
                 np.ndarray[np.int32_t, ndim=2] indices):
        # We need now to figure out if we've been handed quads or tetrahedra.
        # If it's quads, we can build the mesh slightly differently.
        # http://stackoverflow.com/questions/23723993/converting-quadriladerals-in-an-obj-file-into-triangles
        if indices.shape[1] == 8:
            self._build_from_hexahedra(scene, vertices, indices)
        elif indices.shape[1] == 4:
            self._build_from_tetrahedra(scene, vertices, indices)
        else:
            raise NotImplementedError

    cdef void _build_from_hexahedra(self, rtc.EmbreeScene scene,
                                    np.ndarray[floating, ndim=2] quad_vertices,
                                    np.ndarray[np.int32_t, ndim=2] quad_indices) except +:

        cdef int i, j
        cdef int nv = quad_vertices.shape[0]
        cdef int ne = quad_indices.shape[0]

        # There are six faces for every quad.  Each of those will be divided
        # into two triangles.
        cdef int nt = 6 * 2 * ne

        # Embree 4 geometry creation
        cdef rtc.RTCGeometry mesh = rtc.rtcNewGeometry(scene.device.device, rtc.RTC_GEOMETRY_TYPE_TRIANGLE)

        # first just copy over the vertices
        cdef Vertex * vertices = <Vertex *> rtc.rtcSetNewBuffer(mesh, rtc.RTC_BUFFER_TYPE_VERTEX, 0,
                                                                rtc.RTC_FORMAT_FLOAT3, sizeof(Vertex), nv)

        for i in range(nv):
            vertices[i].x = quad_vertices[i, 0]
            vertices[i].y = quad_vertices[i, 1]
            vertices[i].z = quad_vertices[i, 2]

        # now build up the triangles
        cdef Triangle * triangles = <Triangle *> rtc.rtcSetNewBuffer(
            mesh, rtc.RTC_BUFFER_TYPE_INDEX, 0, rtc.RTC_FORMAT_UINT3, sizeof(Triangle), nt
        )

        for i in range(ne):
            for j in range(12):
                triangles[12 * i + j].v0 = quad_indices[i][triangulate_hex[j][0]]
                triangles[12 * i + j].v1 = quad_indices[i][triangulate_hex[j][1]]
                triangles[12 * i + j].v2 = quad_indices[i][triangulate_hex[j][2]]

        self.vertices = vertices
        self.indices = triangles
        self.mesh = mesh
        rtc.rtcCommitGeometry(self.mesh)
        rtc.rtcAttachGeometry(scene.scene_i, self.mesh)

    cdef void _build_from_tetrahedra(self, rtc.EmbreeScene scene,
                                     np.ndarray[floating, ndim=2] tetra_vertices,
                                     np.ndarray[np.int32_t, ndim=2] tetra_indices) except +:

        cdef int i, j
        cdef int nv = tetra_vertices.shape[0]
        cdef int ne = tetra_indices.shape[0]

        # There are four triangle faces for each tetrahedron.
        cdef int nt = 4 * ne

        cdef rtc.RTCGeometry mesh = rtc.rtcNewGeometry(scene.device.device, rtc.RTC_GEOMETRY_TYPE_TRIANGLE)

        # Just copy over the vertices
        cdef Vertex * vertices = <Vertex *> rtc.rtcSetNewBuffer(
            mesh, rtc.RTC_BUFFER_TYPE_VERTEX, 0, rtc.RTC_FORMAT_FLOAT3, sizeof(Vertex), nv
        )

        for i in range(nv):
            vertices[i].x = tetra_vertices[i, 0]
            vertices[i].y = tetra_vertices[i, 1]
            vertices[i].z = tetra_vertices[i, 2]

        # Now build up the triangles
        cdef Triangle * triangles = <Triangle *> rtc.rtcSetNewBuffer(
            mesh, rtc.RTC_BUFFER_TYPE_INDEX, 0, rtc.RTC_FORMAT_UINT3, sizeof(Triangle), nt
        )
        for i in range(ne):
            for j in range(4):
                triangles[4 * i + j].v0 = tetra_indices[i][triangulate_tetra[j][0]]
                triangles[4 * i + j].v1 = tetra_indices[i][triangulate_tetra[j][1]]
                triangles[4 * i + j].v2 = tetra_indices[i][triangulate_tetra[j][2]]

        self.vertices = vertices
        self.indices = triangles
        self.mesh = mesh
        rtc.rtcCommitGeometry(self.mesh)
        rtc.rtcAttachGeometry(scene.scene_i, self.mesh)