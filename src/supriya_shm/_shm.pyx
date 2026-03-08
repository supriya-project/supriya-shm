# cython: language_level=3
# distutils: language=c++

from ._shm cimport server_shared_memory_client


cdef class ServerSHM:
    """
    A SuperCollider server shared memory interface.

    ::

        >>> from supriya_shm import ServerSHM
        >>> shm = ServerSHM(57110, 1024)

    """
    cdef server_shared_memory_client* client
    cdef unsigned int bus_count

    def __cinit__(self, unsigned int port_number, unsigned int bus_count) -> None:
        self.bus_count = bus_count
        self.client = new server_shared_memory_client(port_number)

    def __dealloc__(self) -> None:
        del self.client

    def __getitem__(self, item: int | slice) -> float | list[float]:
        if isinstance(item, int):
            if item < 0 or item >= self.bus_count:
                raise ValueError("index out of bounds")
            return self.client.get_control_busses()[item]
        elif isinstance(item, slice):
            result = []
            for bus_index in range(*item.indices(self.bus_count)):
                result.append(self.client.get_control_busses()[bus_index])
            return result
        raise ValueError(item)

    def __setitem__(self, item: int | slice, value: float | list[float]) -> None:
        if isinstance(item, int):
            if item < 0 or item >= self.bus_count:
                raise ValueError("index out of bounds")
            self.client.set_control_bus(item, float(value))
            return
        elif isinstance(item, slice):
            for value_index, bus_index in enumerate(range(*item.indices(self.bus_count))):
                value_ = float(value[value_index])
                self.client.set_control_bus(bus_index, value_)
            return
        raise ValueError(item, value)

    def describe_scope_buffer(self, unsigned int index) -> tuple[int, int]:
        reader = self.client.get_scope_buffer_reader(index)
        if not reader.valid():
            raise RuntimeError
        return reader.channels(), reader.max_frames()

    def read_scope_buffer(self, unsigned int index) -> tuple[int, list[float]]:
        reader = self.client.get_scope_buffer_reader(index)
        if not reader.valid():
            raise RuntimeError
        cdef unsigned int available_frames = 0
        reader.pull(available_frames)
        data = reader.data()
        pydata = []
        for i in range(8192):
            pydata.append(data[i])
        return available_frames, pydata
