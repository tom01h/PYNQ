import numpy as np
import top as top

class _Fpga(object):
    def __init__(self, bit_file):
        self._send_data = {}

    def _evaluate(self):
        if len(self._send_data) > 0:
            send_data = self._send_data.pop(0)
            top.send(send_data)
        self._recv_list = {}
        top.evaluate()

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
                data_flat[i] = recv_data
                i += 1
            self._evaluate()
        top.recv_fin()
        self._evaluate()

    def fin(self):
        top.fin()




