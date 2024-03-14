"""Logging wrappers"""

import logging

from functools import wraps
from typing import Callable

from time import perf_counter

logging.basicConfig(
    filename="etyviz.log",
    encoding="utf-8",
    level=logging.DEBUG,
    format="%(levelname)s %(asctime)s %(message)s",
    datefmt="%Y-%m-%d %H:%M:%S",
)


def log_gen(f: Callable):
    @wraps(f)
    def wrapper(*args, **kwargs):
        name = f.__qualname__
        logging.info("Started %s (%s, %s)", name, args, kwargs)
        start = perf_counter()
        yield from f(*args, **kwargs)
        duration = perf_counter() - start
        logging.info("Finished %s in %i seconds", name, duration)

    return wrapper


def log(f: Callable):
    @wraps(f)
    def wrapper(*args, **kwargs):
        name = f.__qualname__
        logging.info("Started %s (%s, %s)", name, args, kwargs)
        start = perf_counter()
        res = f(*args, **kwargs)
        duration = perf_counter() - start
        logging.info("Finished %s in %i seconds", name, duration)
        return res

    return wrapper
