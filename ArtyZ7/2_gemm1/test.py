print("ライブラリ読み込み")

from pynq import Overlay
from pynq import allocate
from pynq import MMIO
import pynq.lib.dma
import numpy as np
import random

print("bit ファイル読み込み")

overlay = Overlay("./bit/gemm1.bit")

print("MEM IP 初期設定")

dma_send = overlay.axi_dma_0
dma_recv = overlay.axi_dma_1

gemm_address = overlay.ip_dict['top_0/S_AXI']['phys_addr']
gemm_range = overlay.ip_dict['top_0/S_AXI']['addr_range']
gemm = MMIO(gemm_address, gemm_range)

dma1_address = overlay.ip_dict['axi_dma_1']['phys_addr']
dma1_range = overlay.ip_dict['axi_dma_1']['addr_range']
dma1 = MMIO(dma1_address, dma1_range)

dma0_address = overlay.ip_dict['axi_dma_0']['phys_addr']
dma0_range = overlay.ip_dict['axi_dma_0']['addr_range']
dma0 = MMIO(dma0_address, dma0_range)

print("--- Set Matrix ---");
matrix = allocate(shape=(4,8), dtype=np.uint32)
for j in range(4):
    for i in range(8):
        matrix[j][i] = random.randrange(255)

print(matrix)

gemm.write(0, 1)
dma_send.sendchannel.transfer(matrix)
gemm.write(0, 0)

#run
gemm.write(0, 2)

in_data  = allocate(shape=(4,8), dtype=np.uint32)
out_data = allocate(shape=(4,4), dtype=np.uint32)

for n in range(2):
    print("--- Sample", n, "Input ---")
    for j in range(4):
        for i in range(8):
            in_data[j][i] = random.randrange(255)
    print(in_data)

    # DAM Reset & Restart
    dma0.write(0x00,4)
    dma1.write(0x30,4)
    dma_send.sendchannel.start()
    dma_recv.recvchannel.start()

    dma_send.sendchannel.transfer(in_data)
    dma_recv.recvchannel.transfer(out_data)

    print("--- Sample", n, "Output ---")
    for j in range(4):
        sum=[0]*4
        for k in range(8):
            for i in range(4):
                sum[i] += matrix[i][k] * in_data[j][k]

        print(out_data[j])
        for i in range(4):
            if out_data[j][i] != sum[i]:
                print("(Error Expecetd =", i, sum[i], ") ")

gemm.write(0, 0)
del matrix, in_data, out_data
