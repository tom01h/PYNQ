from pynq import Overlay
from pynq import MMIO
import pynq.lib.dma

class _Fpga(object):
    def __init__(self, bit_file = "./bit/gemm1.bit"):
        self._overlay = Overlay(bit_file)

        gemm_address = self._overlay.ip_dict['top_0']['phys_addr']
        gemm_range = self._overlay.ip_dict['top_0']['addr_range']
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
