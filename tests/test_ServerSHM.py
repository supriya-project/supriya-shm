import traceback

from supriya_shm import ServerSHM


def test_ServerSHM() -> None:
    try:
        ServerSHM(57110, 1024)
    except RuntimeError:
        traceback.print_exc()

