from pynq import Overlay
from pynq import MMIO
import pynq.lib.dma

import struct

def float_to_int(f):
    return struct.unpack('>I', struct.pack('>f', f))[0]

def float_to_hex(f):
    return hex(struct.unpack('>I', struct.pack('>f', f))[0])

def int_to_float(i):
    return struct.unpack('>f', struct.pack('>I', i))[0]

class _Fpga(object):
    def __init__(self, bit_file = "./bit/design_1_wrapper.bit"):
        self._overlay = Overlay(bit_file)

        gemm_address = self._overlay.ip_dict['top_0/S_AXI']['phys_addr']
        gemm_range = self._overlay.ip_dict['top_0/S_AXI']['addr_range']
        self._gemm = MMIO(gemm_address, gemm_range)

        self._dma_send = self._overlay.axi_dma_0
        self._dma_recv = self._overlay.axi_dma_1

    def write(self, address, value):
        self._gemm.write(address, value)

    def send(self, data):
        self._dma_send.sendchannel.transfer(data)

    def send_wait(self):
        self._dma_send.sendchannel.wait()

    def recv(self, data):
        self._dma_recv.recvchannel.transfer(data)

    def recv_wait(self):
        self._dma_recv.recvchannel.wait()

    def fin(self):
        pass
