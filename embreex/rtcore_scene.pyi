from typing import Dict, Literal, Union, overload

import numpy as np
import numpy.typing as npt

from .rtcore import EmbreeDevice

class EmbreeScene:
    is_committed: int
    device: EmbreeDevice

    def __init__(self, device: EmbreeDevice | None = None, robust: bool = True) -> None: ...
    @overload
    def run(
        self,
        vec_origins: npt.NDArray[np.float32],
        vec_directions: npt.NDArray[np.float32],
        dists: float | npt.NDArray[np.float32] | None = None,
        query: Literal["DISTANCE"] = "DISTANCE",
        output: Literal[False, 0, None] = None,
    ) -> npt.NDArray[np.float32]: ...
    @overload
    def run(
        self,
        vec_origins: npt.NDArray[np.float32],
        vec_directions: npt.NDArray[np.float32],
        dists: float | npt.NDArray[np.float32] | None = None,
        query: Literal["INTERSECT", "OCCLUDED"] = "INTERSECT",
        output: Literal[False, 0, None] = None,
    ) -> npt.NDArray[np.int32]: ...
    @overload
    def run(
        self,
        vec_origins: npt.NDArray[np.float32],
        vec_directions: npt.NDArray[np.float32],
        dists: float | npt.NDArray[np.float32] | None = None,
        query: Literal["INTERSECT", "OCCLUDED", "DISTANCE"] = "INTERSECT",
        *,
        output: Literal[True, 1],
    ) -> Dict[str, npt.NDArray]: ...
    @overload
    def run(
        self,
        vec_origins: npt.NDArray[np.float32],
        vec_directions: npt.NDArray[np.float32],
        dists: float | npt.NDArray[np.float32] | None = None,
        query: str = "INTERSECT",
        output: bool | int | None = None,
    ) -> Union[npt.NDArray, Dict[str, npt.NDArray]]: ...
