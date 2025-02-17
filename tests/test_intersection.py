import time
import numpy as np

from embreex import rtcore as rtc  # Use the unified rtcore module
from embreex.mesh_construction import TriangleMesh

N = 4


def xplane(x):
    return [
        [[x, -1.0, -1.0], [x, +1.0, -1.0], [x, -1.0, +1.0]],
        [[x, +1.0, -1.0], [x, +1.0, +1.0], [x, -1.0, +1.0]],
    ]


triangles = xplane(7.0)
triangles = np.array(triangles, "float32")

# Embree 4: Create a device first
device = rtc.EmbreeDevice()
scene = rtc.EmbreeScene(device)  # Pass the device to the scene

mesh = TriangleMesh(scene, triangles)

origins = np.zeros((N, 3), dtype="float32")
origins[:, 0] = 0.1
origins[0, 1] = -0.2
origins[1, 1] = +0.2
origins[2, 1] = +0.3
origins[3, 1] = -8.2

dirs = np.zeros((N, 3), dtype="float32")
dirs[:, 0] = 1.0

t1 = time.time()
res = scene.run(origins, dirs, output=True) #output=True is equivalent to output=1
t2 = time.time()
print("Ran in {0:.3f} s".format(t2 - t1))

print(
    "Output is a dict containing Embree results with id of intersected dimensionless coordinates"
)
print(res)

ray_inter = res["geomID"] >= 0
print("{0} rays intersect geometry (over {1})".format(sum(ray_inter), N))
print("Intersection coordinates")
primID = res["primID"][ray_inter]
u = res["u"][ray_inter]
v = res["v"][ray_inter]
w = 1 - u - v
inters = (
    np.vstack(w) * triangles[primID][:, 0, :]
    + np.vstack(u) * triangles[primID][:, 1, :]
    + np.vstack(v) * triangles[primID][:, 2, :]
)
print(inters)