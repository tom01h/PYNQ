import numpy as np
import random
from lib.fpga import _Fpga
from lib.lib  import alloc

print("Load bit-file")

fpga = _Fpga("./bit/gemm1.bit")

print("--- Set Matrix ---");
matrix = alloc(shape=(4,8), dtype=np.uint32)
for j in range(4):
    for i in range(8):
        matrix[j][i] = random.randrange(255)

print(matrix)

fpga.write(0, 1)
fpga.send(matrix)
fpga.send_wait()
fpga.write(0, 0)

#run
fpga.write(0, 2)

in_data  = alloc(shape=(4,8), dtype=np.uint32)
out_data = alloc(shape=(4,4), dtype=np.uint32)

for n in range(2):
    print("--- Sample", n, "Input ---")
    for j in range(4):
        for i in range(8):
            in_data[j][i] = random.randrange(255)
    print(in_data)

    fpga.recv(out_data)
    fpga.send(in_data)
    fpga.send_wait()
    fpga.recv_wait()

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

fpga.write(0, 0)
del matrix, in_data, out_data
fpga.fin()
