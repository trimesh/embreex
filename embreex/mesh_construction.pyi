import numpy.typing as npt

from .rtcore_scene import EmbreeScene

class TriangleMesh:
    def __init__(
        self,
        scene: EmbreeScene,
        vertices: npt.NDArray,
        indices: npt.NDArray | None = None,
    ) -> None: ...

class ElementMesh(TriangleMesh):
    def __init__(
        self,
        scene: EmbreeScene,
        vertices: npt.NDArray,
        indices: npt.NDArray,
    ) -> None: ...
