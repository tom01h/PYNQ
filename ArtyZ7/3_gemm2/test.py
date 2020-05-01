import numpy as np
import random
from lib.fpga import _Fpga
from lib.fpga import alloc

print("Load bit-file")

fpga = _Fpga("./bit/gemm2.bit")

print("--- Set Matrix ---");
matrix = alloc(shape=(4,8,2), dtype=np.uint32)
for j in range(4):
    for i in range(8):
        matrix[j][i][0] = random.randrange(255)
        matrix[j][i][1] = matrix[j][i][0]

print(matrix.transpose(2,0,1)[0])

fpga.write(0, 1)
fpga.send(matrix)
fpga.write(0, 0)

#run
fpga.write(0, 2)

in_data  = alloc(shape=(4,8), dtype=np.uint32)
out_data = alloc(shape=(4,4), dtype=np.uint32)

print("--- Sample", 0, "Input ---")
for j in range(4):
    for i in range(8):
        in_data[j][i] = random.randrange(255)

print(in_data)

fpga.send(in_data)

result=[0]*4*4

for n in range(3):
    if n != 0:
        fpga.recv_wait()

        print("--- Sample", n-1, "Output ---")
        for j in range(4):
            print(out_data[j])
            for i in range(4):
                if out_data[j][i] != result[j][i]:
                    print("(Error Expecetd =", i, result[j][i], ") ")

    # DAM recv
    fpga.recv_reset()
    fpga.recv_transfer(out_data)

    if n+1 != 3:
        for j in range(4):
            sum=[0]*4
            for k in range(8):
                for i in range(4):
                    sum[i] += matrix[i][k][0] * in_data[j][k]

            result[j] = sum

        print("--- Sample", n+1, "Input ---")
        for j in range(4):
            for i in range(8):
                in_data[j][i] = random.randrange(255)

        print(in_data)

        fpga.send(in_data)

    else:
        fpga.write(0, 6)

print("--- Sample", 2, "Output ---")
for j in range(4):
    sum=[0]*4
    for k in range(8):
        for i in range(4):
            sum[i] += matrix[i][k][0] * in_data[j][k]

    result[j] = sum
    print(out_data[j])
    for i in range(4):
        if out_data[j][i] != result[j][i]:
            print("(Error Expecetd =", i, result[j][i], ") ")

fpga.write(0, 0)
