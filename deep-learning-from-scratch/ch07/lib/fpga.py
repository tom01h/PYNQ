from pynq import Overlay
from pynq import MMIO
from pynq import allocate
import pynq.lib.dma

class _Fpga(object):
    def __init__(self, bit_file = "./bit/design_1_wrapper.bit"):
        self._overlay = Overlay(bit_file)

        gemm_address = self._overlay.ip_dict['top_0/S_AXI']['phys_addr']
        gemm_range = self._overlay.ip_dict['top_0/S_AXI']['addr_range']
        self._gemm = MMIO(gemm_address, gemm_range)

        self._dma_send = self._overlay.axi_dma_0
        self._dma_recv = self._overlay.axi_dma_1

    def alloc(self, shape, dtype):
        self._send_buf = allocate(shape, dtype)
    
    def write(self, address, value):
        self._gemm.write(address, value)

    def send(self, data):
        self._send_buf[:] = data.tolist()
        self._send_buf.flush()
        self._dma_send.sendchannel.transfer(self._send_buf)

    def send_wait(self):
        self._dma_send.sendchannel.wait()

    def recv(self, data):
        self._recv_buf = data
        self._dma_recv.recvchannel.transfer(data)

    def recv_wait(self):
        self._dma_recv.recvchannel.wait()
        self._recv_buf.invalidate()

    def fin(self):
        pass
