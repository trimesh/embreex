import logging
from typing import TypeAlias as _TypeAlias, Dict, Literal, Union, overload
import numpy.typing as npt

import numpy as np

from . import rtcore as rtc

RTCSceneFlags: _TypeAlias = int
rayQueryType: _TypeAlias = int

class EmbreeScene:
    is_committed: int
    device: rtc.EmbreeDevice

    def __init__(self, device: rtc.EmbreeDevice | None = None, robust: bool = True) -> None:
        ...

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

    def __dealloc__(self):
        ...
log = logging.getLogger('embreex')