from pynq import Overlay
from pynq import MMIO
from pynq import allocate
import pynq.lib.dma

import numpy as np

def alloc(shape, dtype):
    return allocate(shape, dtype)

class _Fpga(object):
    def __init__(self, bit_file = "./bit/gemm1.bit"):
        self._overlay = Overlay(bit_file)

        gemm_address = self._overlay.ip_dict['top_0/S_AXI']['phys_addr']
        gemm_range = self._overlay.ip_dict['top_0/S_AXI']['addr_range']
        self._gemm = MMIO(gemm_address, gemm_range)

        dma1_address = self._overlay.ip_dict['axi_dma_1']['phys_addr']
        dma1_range = self._overlay.ip_dict['axi_dma_1']['addr_range']
        self._dma1 = MMIO(dma1_address, dma1_range)

        dma0_address = self._overlay.ip_dict['axi_dma_0']['phys_addr']
        dma0_range = self._overlay.ip_dict['axi_dma_0']['addr_range']
        self._dma0 = MMIO(dma0_address, dma0_range)

        self._dma_send = self._overlay.axi_dma_0
        self._dma_recv = self._overlay.axi_dma_1

    def write(self, address, value):
        self._gemm.write(address, value)

    def send(self, data):
        self._dma0.write(0x00,4)
        self._dma_send.sendchannel.start()
        self._dma_send.sendchannel.transfer(data)
        self._dma_send.sendchannel.wait()

    def recv_reset(self):
        self._dma1.write(0x30,4)
        self._dma_recv.recvchannel.start()

    def recv_transfer(self, data):
        self._dma_recv.recvchannel.transfer(data)

    def recv_wait(self):
        pass # TODO
