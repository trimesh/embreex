# distutils: language=c++

import logging


log = logging.getLogger('embreex')

cdef void print_error(RTCError code):
    if code == RTC_ERROR_NONE:
        log.error("ERROR: No error")
    elif code == RTC_ERROR_UNKNOWN:
        log.error("ERROR: Unknown error")
    elif code == RTC_ERROR_INVALID_ARGUMENT:
        log.error("ERROR: Invalid argument")
    elif code == RTC_ERROR_INVALID_OPERATION:
        log.error("ERROR: Invalid operation")
    elif code == RTC_ERROR_OUT_OF_MEMORY:
        log.error("ERROR: Out of memory")
    elif code == RTC_ERROR_UNSUPPORTED_CPU:
        log.error("ERROR: Unsupported CPU")
    elif code == RTC_ERROR_CANCELLED:
        log.error("ERROR: Cancelled")
    else:
        raise RuntimeError


cdef class EmbreeDevice:
    def __init__(self):
        self.device = rtcNewDevice(NULL)

    def __dealloc__(self):
        rtcReleaseDevice(self.device)

    def __repr__(self):
        return 'Embree version:  {0}.{1}.{2}'.format(RTC_VERSION_MAJOR,
                                                     RTC_VERSION_MINOR,
                                                     RTC_VERSION_PATCH)
