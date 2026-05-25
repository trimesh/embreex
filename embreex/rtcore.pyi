import logging
from typing import TypeAlias as _TypeAlias

RTCError: _TypeAlias = int

class EmbreeDevice:

    def __init__(self) -> None:
        ...

    def __dealloc__(self):
        ...

    def __repr__(self) -> str:
        ...
log = logging.getLogger('embreex')