from unittest import TestCase
import numpy as np
from embreex import rtcore as rtc
from embreex import rtcore_scene as rtcs
from embreex.mesh_construction import TriangleMesh
from embreex.mesh_construction import ElementMesh


def xplane(x):
    return [
        [[x, -1.0, -1.0], [x, +1.0, -1.0], [x, -1.0, +1.0]],
        [[x, +1.0, -1.0], [x, +1.0, +1.0], [x, -1.0, +1.0]],
    ]


def xplane_only_points(x):
    # Indices are [[0, 1, 2], [1, 3, 2]]
    return [[x, -1.0, -1.0], [x, +1.0, -1.0], [x, -1.0, +1.0], [x, +1.0, +1.0]]


def define_rays_origins_and_directions():
    N = 4
    origins = np.zeros((N, 3), dtype="float32")
    origins[:, 0] = 0.1
    origins[0, 1] = -0.2
    origins[1, 1] = +0.2
    origins[2, 1] = +0.3
    origins[3, 1] = -8.2

    dirs = np.zeros((N, 3), dtype="float32")
    dirs[:, 0] = 1.0
    return origins, dirs


class Testembreex(TestCase):
    def test_embreex_should_be_able_to_display_embree_version(self):
        embreeDevice = rtc.EmbreeDevice()
        print(embreeDevice)

    def test_embreex_should_be_able_to_create_a_scene(self):
        embreeDevice = rtc.EmbreeDevice()
        rtcs.EmbreeScene(embreeDevice)

    def test_embreex_should_be_able_to_create_several_scenes(self):
        embreeDevice = rtc.EmbreeDevice()
        rtcs.EmbreeScene(embreeDevice)
        rtcs.EmbreeScene(embreeDevice)

    def test_embreex_should_be_able_to_create_a_device_if_not_provided(self):
        rtcs.EmbreeScene()


class TestIntersectionTriangles(TestCase):
    def setUp(self):
        """Initialisation"""
        triangles = xplane(7.0)
        triangles = np.array(triangles, "float32")

        self.embreeDevice = rtc.EmbreeDevice()
        self.scene = rtcs.EmbreeScene(self.embreeDevice)
        TriangleMesh(self.scene, triangles)

        origins, dirs = define_rays_origins_and_directions()
        self.origins = origins
        self.dirs = dirs

    def test_intersect_simple(self):
        res = self.scene.run(self.origins, self.dirs)
        self.assertTrue([0, 1, 1, -1], res)

    def test_intersect_distance(self):
        res = self.scene.run(self.origins, self.dirs, query="DISTANCE")
        self.assertTrue(np.allclose([6.9, 6.9, 6.9, 1e37], res))

    def test_intersect(self):
        res = self.scene.run(self.origins, self.dirs, output=1, dists=100)

        self.assertTrue([0, 0, 0, -1], res["geomID"])
        ray_inter = res["geomID"] >= 0
        primID = res["primID"][ray_inter]
        u = res["u"][ray_inter]
        v = res["v"][ray_inter]
        tfar = res["tfar"]
        self.assertTrue([0, 1, 1], primID)
        self.assertTrue(np.allclose([6.9, 6.9, 6.9, 100], tfar))
        self.assertTrue(np.allclose([0.4, 0.1, 0.15], u))
        self.assertTrue(np.allclose([0.5, 0.4, 0.35], v))


class TestIntersectionTrianglesFromIndices(TestCase):
    def setUp(self):
        """Initialisation"""
        points = xplane_only_points(7.0)
        points = np.array(points, "float32")
        indices = np.array([[0, 1, 2], [1, 3, 2]], "uint32")

        self.embreeDevice = rtc.EmbreeDevice()
        self.scene = rtcs.EmbreeScene(self.embreeDevice)
        TriangleMesh(self.scene, points, indices)

        origins, dirs = define_rays_origins_and_directions()
        self.origins = origins
        self.dirs = dirs

    def test_intersect_simple(self):
        res = self.scene.run(self.origins, self.dirs)
        self.assertTrue([0, 1, 1, -1], res)

    def test_intersect(self):
        res = self.scene.run(self.origins, self.dirs, output=1)

        self.assertTrue([0, 0, 0, -1], res["geomID"])

        ray_inter = res["geomID"] >= 0
        primID = res["primID"][ray_inter]
        u = res["u"][ray_inter]
        v = res["v"][ray_inter]
        tfar = res["tfar"][ray_inter]
        self.assertTrue([0, 1, 1], primID)
        self.assertTrue(np.allclose([6.9, 6.9, 6.9], tfar))
        self.assertTrue(np.allclose([0.4, 0.1, 0.15], u))
        self.assertTrue(np.allclose([0.5, 0.4, 0.35], v))


class TestIntersectionTetrahedron(TestCase):
    def setUp(self):
        """Initialisation"""
        vertices = [(0.0, 0.0, 0.0), (1.0, 0.0, 0.0), (0.0, 1.0, 0.0), (0.0, 0.0, 1.0)]
        vertices = np.array(vertices, "float32")
        indices = np.array([[0, 1, 2, 3]], "uint32")
        self.embreeDevice = rtc.EmbreeDevice()
        self.scene = rtcs.EmbreeScene(self.embreeDevice)
        ElementMesh(self.scene, vertices, indices)

        N = 2
        self.origins = np.zeros((N, 3), dtype="float32")
        self.origins[0, :] = (-0.1, +0.1, +0.1)
        self.origins[1, :] = (-0.1, +0.2, +0.2)
        self.dirs = np.zeros((N, 3), dtype="float32")
        self.dirs[:, 0] = 1.0

    def test_intersect_simple(self):
        res = self.scene.run(self.origins, self.dirs)
        self.assertTrue([1, 1], res)

    def test_intersect(self):
        res = self.scene.run(self.origins, self.dirs, output=1)

        self.assertTrue([0, 0], res["geomID"])

        ray_inter = res["geomID"] >= 0
        primID = res["primID"][ray_inter]
        u = res["u"][ray_inter]
        v = res["v"][ray_inter]
        tfar = res["tfar"][ray_inter]
        self.assertTrue([0, 1], primID)
        self.assertTrue(np.allclose([0.1, 0.1], tfar))
        self.assertTrue(np.allclose([0.1, 0.2], u))
        self.assertTrue(np.allclose([0.1, 0.2], v))


class TestIntersectionHexahedron(TestCase):
    def setUp(self):
        """Initialisation"""
        vertices = [
            (1.0, 0.0, 0.0),
            (1.0, 1.0, 0.0),
            (0.0, 1.0, 0.0),
            (0.0, 0.0, 0.0),
            (1.0, 0.0, 1.0),
            (1.0, 1.0, 1.0),
            (0.0, 1.0, 1.0),
            (0.0, 0.0, 1.0),
        ]
        vertices = np.array(vertices, "float32")
        indices = np.array([[0, 1, 2, 3, 4, 5, 6, 7]], "uint32")
        self.embreeDevice = rtc.EmbreeDevice()
        self.scene = rtcs.EmbreeScene(self.embreeDevice)
        ElementMesh(self.scene, vertices, indices)

        N = 2
        self.origins = np.zeros((N, 3), dtype="float32")
        self.origins[0, :] = (-0.1, +0.9, +0.1)
        self.origins[1, :] = (-0.1, +0.8, +0.2)
        self.dirs = np.zeros((N, 3), dtype="float32")
        self.dirs[:, 0] = 1.0

    def test_intersect_simple(self):
        res = self.scene.run(self.origins, self.dirs)
        self.assertTrue([1, 1], res)

    def test_intersect(self):
        res = self.scene.run(self.origins, self.dirs, output=1)

        self.assertTrue([0, 0], res["geomID"])

        ray_inter = res["geomID"] >= 0
        primID = res["primID"][ray_inter]
        u = res["u"][ray_inter]
        v = res["v"][ray_inter]
        tfar = res["tfar"][ray_inter]
        self.assertTrue([0, 1], primID)
        self.assertTrue(np.allclose([0.1, 0.1], tfar))
        self.assertTrue(np.allclose([0.1, 0.2], u))
        self.assertTrue(np.allclose([0.8, 0.6], v))


class TestOccludedQuery(TestCase):
    def test_occluded(self):
        """Occluded query: hits return >= 0, misses return -1."""
        triangles = np.array(xplane(7.0), "float32")
        scene = rtcs.EmbreeScene()
        TriangleMesh(scene, triangles)
        origins, dirs = define_rays_origins_and_directions()
        res = scene.run(origins, dirs, query="OCCLUDED")
        # First 3 rays hit the plane, 4th misses (y=-8.2 outside)
        self.assertTrue(np.all(res[:3] >= 0))
        self.assertEqual(res[3], -1)


class TestThreadedQueries(TestCase):
    """Parity tests across Open3D-style thread counts (0 = automatic)."""

    def setUp(self):
        rng = np.random.default_rng(0)
        scene = rtcs.EmbreeScene()
        TriangleMesh(scene, np.array(xplane(7.0), "float32"))
        self.scene = scene
        n = 20_000
        self.origins = np.zeros((n, 3), dtype="float32")
        self.origins[:, 0] = 0.1
        # Include both hits and misses across multiple chunks.
        self.origins[:, 1] = rng.uniform(-3.0, 3.0, n).astype("float32")
        self.origins[:, 2] = rng.uniform(-3.0, 3.0, n).astype("float32")
        self.dirs = np.zeros((n, 3), dtype="float32")
        self.dirs[:, 0] = 1.0

    def test_threads_match_serial(self):
        for query in ("INTERSECT", "OCCLUDED", "DISTANCE"):
            ref = self.scene.run(self.origins, self.dirs, query=query, threads=1)
            for threads in (0, -1, -2, 2, 3, 8):
                got = self.scene.run(
                    self.origins, self.dirs, query=query, threads=threads
                )
                np.testing.assert_array_equal(ref, got, err_msg=f"{query} t={threads}")

    def test_threads_match_serial_output_dict(self):
        ref = self.scene.run(self.origins, self.dirs, output=True, threads=1)
        hit = ref["primID"] != -1
        # Guard against a fixture that exercises only one output branch.
        self.assertTrue(hit.any() and not hit.all())
        for threads in (0, -1, -2, 2, 3, 8):
            got = self.scene.run(
                self.origins, self.dirs, output=True, threads=threads
            )
            for key in ("primID", "geomID", "tfar", "u", "v", "Ng"):
                np.testing.assert_array_equal(
                    ref[key], got[key], err_msg=f"{key} t={threads}"
                )

    def test_threads_output_dict_is_repeatable(self):
        a = self.scene.run(self.origins, self.dirs, output=True, threads=8)
        b = self.scene.run(self.origins, self.dirs, output=True, threads=8)
        for key in ("primID", "geomID", "tfar", "u", "v", "Ng"):
            np.testing.assert_array_equal(a[key], b[key], err_msg=key)

    def test_threads_broadcast_direction(self):
        repeated_dirs = np.tile(self.dirs[:1], (len(self.origins), 1))
        ref = self.scene.run(self.origins, repeated_dirs, threads=1)
        broadcast = self.scene.run(self.origins, self.dirs[:1], threads=1)
        threaded = self.scene.run(self.origins, self.dirs[:1], threads=8)
        np.testing.assert_array_equal(ref, broadcast)
        np.testing.assert_array_equal(ref, threaded)

    def test_threads_non_contiguous_input(self):
        origins = self.origins[::3]
        directions = self.dirs[::3]
        ref = self.scene.run(
            np.ascontiguousarray(origins),
            np.ascontiguousarray(directions),
            threads=1,
        )
        np.testing.assert_array_equal(
            ref, self.scene.run(origins, directions, threads=1)
        )
        np.testing.assert_array_equal(
            ref, self.scene.run(origins, directions, threads=8)
        )

    def test_threads_degenerate_sizes(self):
        for n in (0, 1, 2, 1023, 1024, 1025):
            origins, directions = self.origins[:n], self.dirs[:n]
            np.testing.assert_array_equal(
                self.scene.run(origins, directions, threads=1),
                self.scene.run(origins, directions, threads=8),
                err_msg=str(n),
            )

    def test_threads_dists_written_in_place(self):
        ref = np.full(len(self.origins), 20.0, dtype="float32")
        got = ref.copy()
        self.scene.run(self.origins, self.dirs, dists=ref, query="DISTANCE", threads=1)
        self.scene.run(self.origins, self.dirs, dists=got, query="DISTANCE", threads=8)
        np.testing.assert_array_equal(ref, got)

    def test_threads_non_contiguous_dists(self):
        dists = np.full(len(self.origins) * 2, 20.0, dtype="float32")[::2]
        expected = dists.copy()
        self.scene.run(
            self.origins, self.dirs, dists=expected, query="DISTANCE", threads=1
        )
        work = dists.copy()
        self.scene.run(self.origins, self.dirs, dists=work, query="DISTANCE", threads=8)
        np.testing.assert_array_equal(expected, work)

    def test_threads_non_integer_raises(self):
        for value in (-0.5, 1.9, "3"):
            with self.assertRaises(TypeError):
                self.scene.run(self.origins, self.dirs, threads=value)

    def test_invalid_threads_leaves_scene_usable(self):
        scene = rtcs.EmbreeScene()
        empty = np.empty((0, 3), dtype="float32")
        with self.assertRaises(TypeError):
            scene.run(empty, empty, threads=1.5)
        TriangleMesh(scene, np.array(xplane(7.0), "float32"))
        origins = np.array([[0.1, 0.0, 0.0]], dtype="float32")
        directions = np.array([[1.0, 0.0, 0.0]], dtype="float32")
        np.testing.assert_array_equal(scene.run(origins, directions), [0])

    def test_threads_overlapping_dists_rejected(self):
        dists = np.broadcast_to(np.array([20.0], dtype="float32"), (2,))
        with self.assertRaises(ValueError):
            self.scene.run(
                self.origins[:2],
                self.dirs[:2],
                dists=dists,
                query="DISTANCE",
                threads=2,
            )

    def test_threads_mismatched_dists_length_rejected(self):
        dists = np.array([20.0], dtype="float32")
        with self.assertRaises(ValueError):
            self.scene.run(
                self.origins[:2],
                self.dirs[:2],
                dists=dists,
                query="DISTANCE",
                threads=2,
            )

    def test_threads_from_python_threads(self):
        """Concurrent `run()` calls on one scene must not interfere."""
        from concurrent.futures import ThreadPoolExecutor

        ref = self.scene.run(self.origins, self.dirs)
        with ThreadPoolExecutor(4) as pool:
            got = list(
                pool.map(
                    lambda _: self.scene.run(self.origins, self.dirs, threads=4),
                    range(8),
                )
            )
        for i, g in enumerate(got):
            np.testing.assert_array_equal(ref, g, err_msg=str(i))


if __name__ == "__main__":
    from unittest import main

    main()
