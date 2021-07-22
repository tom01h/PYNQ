print("ライブラリ読み込み")

from pynq import Overlay
from pynq import allocate
from pynq import MMIO
import pynq.lib.dma
import numpy as np

print("bit ファイル読み込み")

overlay = Overlay("./bit/dma.bit")

print("MEM IP 初期設定")

dma_send = overlay.axi_dma_0
dma_recv = overlay.axi_dma_1

data_size = 256

mem_address = overlay.ip_dict['mem_0/S_AXI']['phys_addr']
mem_range = overlay.ip_dict['mem_0/S_AXI']['addr_range']

mm_mem = MMIO(mem_address, mem_range)

print("MEM IP DMA Write Mode")

mm_mem.write(0, 1)
mm_mem.write(4, data_size)

print("DMA Write 実行")

input_buffer = allocate(shape=(data_size,), dtype=np.uint32)

for i in range(data_size):
    input_buffer[i] = i + 0xcafe0000

for i in range(10):
    print(hex(input_buffer[i]))

dma_send.sendchannel.transfer(input_buffer)

print("MEM IP MM Mode")

mm_mem.write(0, 0)

print("MEM IP MM Read")

for i in range(10):
    print(hex(mm_mem.read(0x400+i*4)))

print("MEM IP MM Write")

for i in range(data_size):
    mm_mem.write(0x400+i*4, i + 0xbabe0000)

print("MEM IP MM Read")

for i in range(10):
    print(hex(mm_mem.read(0x400+i*4)))

print("MEM IP DMA Read Mode")

mm_mem.write(0, 2)
mm_mem.write(4, data_size)


print("DMA Read 実行")

output_buffer = allocate(shape=(data_size,), dtype=np.uint32)

dma_recv.recvchannel.transfer(output_buffer)

for i in range(10):
    print('0x' + format(output_buffer[i], '02x'))

del input_buffer, output_buffer
