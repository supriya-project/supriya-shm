import contextlib
import socket
import subprocess
from collections.abc import Generator

import pytest

from supriya_shm import ServerSHM


@pytest.fixture
def port() -> int:
    with contextlib.closing(socket.socket(socket.AF_INET, socket.SOCK_DGRAM)) as s:
        s.bind(("", 0))
        s.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
        return s.getsockname()[1]


@pytest.fixture(params=["scsynth", "supernova"])
def server(request, port: int) -> Generator[int, None, None]:
    with subprocess.Popen(
        [request.param, "-u", str(port), "-c", "1024"],
        stdout=subprocess.PIPE,
        stderr=subprocess.STDOUT,
        text=True,
    ) as process:
        if process.stdout:
            for line in process.stdout:
                if line.startswith(("SuperCollider 3 server ready", "Supernova ready")):
                    break
        yield port
        process.kill()


def test_ServerSHM(server: int) -> None:
    shm = ServerSHM(server, 1024)
    # Read
    assert shm[0] == 0.0
    assert shm[0:4] == [0.0, 0.0, 0.0, 0.0]
    assert shm[512:516] == [0.0, 0.0, 0.0, 0.0]
    # Write
    shm[512] = -0.75
    shm[1:3] = [0.5, 7.25]
    # Read again
    assert shm[0:4] == [0.0, 0.5, 7.25, 0.0]
    assert shm[512:516] == [-0.75, 0.0, 0.0, 0.0]
