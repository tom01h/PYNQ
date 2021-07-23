from pynq import Overlay
from pynq import MMIO

import random
import numpy as np

print("bit ファイル読み込み")

overlay = Overlay("./bit/regs.bit")

print("IP 初期設定")

mem_address = overlay.ip_dict['regs_0/S_AXI']['phys_addr']
mem_range = overlay.ip_dict['regs_0/S_AXI']['addr_range']

mm_mem = MMIO(mem_address, mem_range)

print("レジスタアクセス")

wdata = random.randrange(1<<64)
print('wdata', hex(wdata))

mm_mem.write_mm(0x0, wdata.to_bytes(8, byteorder='little'))

rdata = mm_mem.read(0, 8, 'little')
wstrb = mm_mem.read(8, 4)

print('rdata', hex(rdata))
print('wstrb', hex(wstrb))

rdata = mm_mem.read(0x10, 4)
print('lower', hex(rdata))
rdata = mm_mem.read(0x18, 4)
print('upper', hex(rdata))