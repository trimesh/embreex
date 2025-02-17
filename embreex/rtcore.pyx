# distutils: language=c++

import logging
import warnings

cimport rtcore as rtc  # Import the updated rtcore module

log = logging.getLogger('embreex')

cdef void print_error(rtc.RTCError code) except +:  # Use Embree 4 error codes, and handle exceptions
    if code == rtc.RTC_ERROR_NONE:
        return  # No error, return (don't log "ERROR: No error")
    elif code == rtc.RTC_ERROR_UNKNOWN:
        log.error("ERROR: Unknown error")
    elif code == rtc.RTC_ERROR_INVALID_ARGUMENT:
        log.error("ERROR: Invalid argument")
    elif code == rtc.RTC_ERROR_INVALID_OPERATION:
        log.error("ERROR: Invalid operation")
    elif code == rtc.RTC_ERROR_OUT_OF_MEMORY:
        log.error("ERROR: Out of memory")
    elif code == rtc.RTC_ERROR_UNSUPPORTED_CPU:
        log.error("ERROR: Unsupported CPU")
    elif code == rtc.RTC_ERROR_CANCELLED:
        log.error("ERROR: Cancelled")
    elif code == rtc.RTC_ERROR_LEVEL_ZERO_RAYTRACING_SUPPORT_MISSING: #Embree 4.3.3
        log.error("ERROR: Level Zero Raytracing support missing. Check GPU drivers")
    else:
        raise RuntimeError(f"Unknown Embree error code: {code}")

cdef void error_printer(void* userPtr, const rtc.RTCError code, const char *_str) noexcept:
    """
    error_printer function depends on embree version
    Embree 2.14.1
    -> cdef void error_printer(const rtc.RTCError code, const char *_str):
    Embree 2.17.1
    -> cdef void error_printer(void* userPtr, const rtc.RTCError code, const char *_str):
    """
    log.error("ERROR CAUGHT IN EMBREE")
    print_error(code)
    if _str: # Check that the string is not null
      log.error("ERROR MESSAGE: %s", _str.decode('utf-8', 'replace')) # Decode to a Python string


cdef class EmbreeDevice:
    def __init__(self):
        self.device = rtc.rtcNewDevice(NULL)
        if self.device == NULL: #Check if device creation was successful
            error_code = rtc.rtcGetError()
            print_error(error_code) #print error
            raise RuntimeError(f"Embree device creation failed. {rtc.rtcGetErrorString(error_code).decode()}") #Raise error as python exception
        rtc.rtcSetDeviceErrorFunction2(self.device, error_printer, <void*>self) # Pass self as user data

    def __dealloc__(self):
        if self.device is not NULL: # Avoid double-free
            rtc.rtcReleaseDevice(self.device)  # Use rtcReleaseDevice

    def __repr__(self):
         # Embree 4 doesn't have version numbers in rtcore.h
        return "Embree Device"