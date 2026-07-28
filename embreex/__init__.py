def __getattr__(name: str):
    global __version__

    if name == "__version__":
        from importlib.metadata import version as _get_version

        __version__ = _get_version("embreex")  # cache in module dict
        return __version__
    raise AttributeError(name)
