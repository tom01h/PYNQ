import numpy as np
import top as top

import struct

def float_to_int(f):
    return struct.unpack('>I', struct.pack('>f', f))[0]

def int_to_float(i):
    return struct.unpack('>f', struct.pack('>I', i))[0]

class _Fpga(object):
    def __init__(self, bit_file):
        self._send_data = {}
        self._bus_size = top.bus_size()

    def _evaluate(self):
        if len(self._send_data) > 0:
            send_data = 0
            for i in range(self._bus_size):
                send_data += float_to_int(self._send_data.pop(0))<<(32*i)
            if send_data >= 1<<63:
                send_data -= 1<<64
            top.send(send_data)
        self._recv_list = {}
        top.evaluate()

    def alloc(self, shape, dtype):
        pass
        
    def write(self, address, value):
        top.write(address, value)

    def send(self, data):
        top.send_start()
        self._send_data = data.flatten().tolist()

    def send_wait(self):
        while len(self._send_data) > 0:
            self._evaluate()
        top.send_fin()
        self._evaluate()

    def recv(self, data):
        top.recv_start()
        self._recv_data = data
        self._recv_size = len(data.flatten().tolist())
        self._recv_list = {}

    def recv_wait(self):
        data_flat = self._recv_data.ravel()
        i = 0
        while i < len(data_flat):
            recv_data = top.recv()
            if not recv_data == None:
                for j in range(self._bus_size):
                    data_flat[i] = int_to_float(recv_data%(1<<32))
                    recv_data >>= 32
                    i += 1
            self._evaluate()
        top.recv_fin()
        self._evaluate()

    def fin(self):
        top.fin()
