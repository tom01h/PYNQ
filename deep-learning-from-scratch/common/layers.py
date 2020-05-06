# coding: utf-8
import numpy as np
from common.functions import *
from common.util import im2col, col2im

from lib.fpga import _Fpga
from lib.lib  import alloc
from lib.fpga import float_to_hex
from lib.fpga import int_to_float

class Relu:
    def __init__(self):
        self.mask = None

    def forward(self, x):
        self.mask = (x <= 0)
        out = x.copy()
        out[self.mask] = 0

        return out

    def backward(self, dout):
        dout[self.mask] = 0
        dx = dout

        return dx


class Sigmoid:
    def __init__(self):
        self.out = None

    def forward(self, x):
        out = sigmoid(x)
        self.out = out
        return out

    def backward(self, dout):
        dx = dout * (1.0 - self.out) * self.out

        return dx


class Affine:
    def __init__(self, W, b):
        self.W =W
        self.b = b
        
        self.x = None
        self.original_x_shape = None
        # 重み・バイアスパラメータの微分
        self.dW = None
        self.db = None

    def forward(self, x):
        # テンソル対応
        self.original_x_shape = x.shape
        x = x.reshape(x.shape[0], -1)
        self.x = x

        out = np.dot(self.x, self.W) + self.b

        return out

    def backward(self, dout):
        dx = np.dot(dout, self.W.T)
        self.dW = np.dot(self.x.T, dout)
        self.db = np.sum(dout, axis=0)
        
        dx = dx.reshape(*self.original_x_shape)  # 入力データの形状に戻す（テンソル対応）
        return dx


class SoftmaxWithLoss:
    def __init__(self):
        self.loss = None
        self.y = None # softmaxの出力
        self.t = None # 教師データ

    def forward(self, x, t):
        self.t = t
        self.y = softmax(x)
        self.loss = cross_entropy_error(self.y, self.t)
        
        return self.loss

    def backward(self, dout=1):
        batch_size = self.t.shape[0]
        if self.t.size == self.y.size: # 教師データがone-hot-vectorの場合
            dx = (self.y - self.t) / batch_size
        else:
            dx = self.y.copy()
            dx[np.arange(batch_size), self.t] -= 1
            dx = dx / batch_size
        
        return dx


class Dropout:
    """
    http://arxiv.org/abs/1207.0580
    """
    def __init__(self, dropout_ratio=0.5):
        self.dropout_ratio = dropout_ratio
        self.mask = None

    def forward(self, x, train_flg=True):
        if train_flg:
            self.mask = np.random.rand(*x.shape) > self.dropout_ratio
            return x * self.mask
        else:
            return x * (1.0 - self.dropout_ratio)

    def backward(self, dout):
        return dout * self.mask


class BatchNormalization:
    """
    http://arxiv.org/abs/1502.03167
    """
    def __init__(self, gamma, beta, momentum=0.9, running_mean=None, running_var=None):
        self.gamma = gamma
        self.beta = beta
        self.momentum = momentum
        self.input_shape = None # Conv層の場合は4次元、全結合層の場合は2次元  

        # テスト時に使用する平均と分散
        self.running_mean = running_mean
        self.running_var = running_var  
        
        # backward時に使用する中間データ
        self.batch_size = None
        self.xc = None
        self.std = None
        self.dgamma = None
        self.dbeta = None

    def forward(self, x, train_flg=True):
        self.input_shape = x.shape
        if x.ndim != 2:
            N, C, H, W = x.shape
            x = x.reshape(N, -1)

        out = self.__forward(x, train_flg)
        
        return out.reshape(*self.input_shape)
            
    def __forward(self, x, train_flg):
        if self.running_mean is None:
            N, D = x.shape
            self.running_mean = np.zeros(D)
            self.running_var = np.zeros(D)
                        
        if train_flg:
            mu = x.mean(axis=0)
            xc = x - mu
            var = np.mean(xc**2, axis=0)
            std = np.sqrt(var + 10e-7)
            xn = xc / std
            
            self.batch_size = x.shape[0]
            self.xc = xc
            self.xn = xn
            self.std = std
            self.running_mean = self.momentum * self.running_mean + (1-self.momentum) * mu
            self.running_var = self.momentum * self.running_var + (1-self.momentum) * var            
        else:
            xc = x - self.running_mean
            xn = xc / ((np.sqrt(self.running_var + 10e-7)))
            
        out = self.gamma * xn + self.beta 
        return out

    def backward(self, dout):
        if dout.ndim != 2:
            N, C, H, W = dout.shape
            dout = dout.reshape(N, -1)

        dx = self.__backward(dout)

        dx = dx.reshape(*self.input_shape)
        return dx

    def __backward(self, dout):
        dbeta = dout.sum(axis=0)
        dgamma = np.sum(self.xn * dout, axis=0)
        dxn = self.gamma * dout
        dxc = dxn / self.std
        dstd = -np.sum((dxn * self.xc) / (self.std * self.std), axis=0)
        dvar = 0.5 * dstd / self.std
        dxc += (2.0 / self.batch_size) * self.xc * dvar
        dmu = np.sum(dxc, axis=0)
        dx = dxc - dmu / self.batch_size
        
        self.dgamma = dgamma
        self.dbeta = dbeta
        
        return dx


class Convolution:
    def __init__(self, W, b, stride=1, pad=0, fpga=None):
        self.W = W
        self.b = b
        self.stride = stride
        self.pad = pad
        
        # 中間データ（backward時に使用）
        self.x = None   
        self.col = None
        self.col_W = None
        
        # 重み・バイアスパラメータの勾配
        self.dW = None
        self.db = None

        self.init_f = True
        self.init_b = True
        self.init_p = True

        self._fpga = fpga

    def forward(self, x):
        FN, C, FH, FW = self.W.shape
        N, C, H, W = x.shape
        out_h = 1 + int((H + 2*self.pad - FH) / self.stride)
        out_w = 1 + int((W + 2*self.pad - FW) / self.stride)

        col = im2col(x, FH, FW, self.stride, self.pad)
        col_W = self.W.reshape(FN, -1).T

        out = np.dot(col, col_W) + self.b
        if self.init_f:
            print("Conv forward Weight", col_W.shape)
            print("Conv forward In Data", col.shape)
            print("Conv forward Out Data", out.shape)
            print("")
            self.init_f = False

        sample = 30
        kernel = C*FH*FW
        out_ch = FN
        self._fpga.write(int('0x04', 16), int(sample-1))
        self._fpga.write(int('0x08', 16), int(out_ch-1))
        self._fpga.write(int('0x0c', 16), int(kernel-1))
        self._fpga.write(int('0x10', 16), int(kernel*sample/2-1))
        self._fpga.write(int('0x14', 16), int(out_ch*sample/2-1))

        # set matrix
        self._fpga.write(0, 1)
        self._fpga.send(col_W)
        self._fpga.send_wait()
        self._fpga.write(0, 0)

        # run
        out_data = alloc(shape=(sample,out_ch), dtype=np.uint32)
        self._fpga.write(0, 2)

        # 0 input
        self._fpga.send(col[0:sample])
        self._fpga.send_wait()

        loop_num = int(col.shape[0]/sample)
        for n in range(loop_num):
            if n != 0:
                # n-1 output
                self._fpga.recv_wait()

                for i in range(sample):
                    for j in range(out_ch):
                        fl = int_to_float(out_data[i][j]) + self.b[j]
                        ou = out[i+(n-1)*sample][j]
                        if (fl - ou) == 0 or ou == 0 and fl == 0:
                            pass
                        elif abs((fl - ou)/ou) < 0.01:
                            pass
                        else:
                            print("Error: ", n-1,i,j,abs((fl - ou)/ou),fl,ou)
                        out[i+(n-1)*sample][j] = fl

            self._fpga.recv(out_data)

            # n+1 input
            if n+1 != loop_num:
                self._fpga.send(col[(n+1)*sample:(n+2)*sample])
                self._fpga.send_wait()
            else:
                self._fpga.write(0, 6)

        # loop_num-1 output
        self._fpga.recv_wait()

        for i in range(sample):
            for j in range(out_ch):
                fl = int_to_float(out_data[i][j]) + self.b[j]
                ou = out[i+(loop_num-1)*sample][j]
                if (fl - ou) == 0 or ou == 0 and fl == 0:
                    pass
                elif abs((fl - ou)/ou) < 0.01:
                    pass
                else:
                    print("Error: ", loop_num-1,i,j,abs((fl - ou)/ou),fl,ou)
                out[i+(loop_num-1)*sample][j] = fl

        self.x = x
        self.col = col
        self.col_W = col_W

        out = out.reshape(N, out_h, out_w, -1).transpose(0, 3, 1, 2)
        return out

    def backward(self, dout):
        FN, C, FH, FW = self.W.shape
        dout = dout.transpose(0,2,3,1).reshape(-1, FN)

        self.db = np.sum(dout, axis=0)
        self.dW = np.dot(self.col.T, dout)
        dcol = np.dot(dout, self.col_W.T)

        if self.init_b:
            print("Conv backward Out Data", dout.shape)
            print("Conv backward In Data", self.col.T.shape)
            print("Conv backward delta W", self.dW.shape)
            print("")
            print("Conv backward Weight", self.col_W.T.shape)
            print("Conv backward Out Data", dout.shape)
            print("Conv backward delta In", dcol.shape)
            print("")
            self.init_b = False

        sample = 30
        kernel = FN
        out_ch = C*FH*FW
        self._fpga.write(int('0x04', 16), int(sample-1))
        self._fpga.write(int('0x08', 16), int(out_ch-1))
        self._fpga.write(int('0x0c', 16), int(kernel-1))
        self._fpga.write(int('0x10', 16), int(kernel*sample/2-1))
        self._fpga.write(int('0x14', 16), int(out_ch*sample/2-1))

        # set matrix
        self._fpga.write(0, 1)
        self._fpga.send(self.col_W.T)
        self._fpga.send_wait()
        self._fpga.write(0, 0)

        # run
        out_data = alloc(shape=(sample,out_ch), dtype=np.uint32)
        self._fpga.write(0, 2)

        # 0 input
        self._fpga.send(dout[0:sample])
        self._fpga.send_wait()

        loop_num = int(dout.shape[0]/sample)
        for n in range(loop_num):
            if n != 0:
                # n-1 output
                self._fpga.recv_wait()

                for i in range(sample):
                    for j in range(out_ch):
                        fl = int_to_float(out_data[i][j])
                        dc = dcol[i+(n-1)*sample][j]
                        if (fl - dc) == 0 or dc == 0 and fl == 0:
                            pass
                        elif abs((fl - dc)/dc) < 0.01:
                            pass
                        else:
                            print("Error: ", n-1,i,j,abs((fl - dc)/dc),fl,dc)
                        dcol[i+(n-1)*sample][j] = fl

            self._fpga.recv(out_data)

            # n+1 input
            if n+1 != loop_num:
                self._fpga.send(dout[(n+1)*sample:(n+2)*sample])
                self._fpga.send_wait()
            else:
                self._fpga.write(0, 6)

        # loop_num-1 output
        self._fpga.recv_wait()

        for i in range(sample):
            for j in range(out_ch):
                fl = int_to_float(out_data[i][j])
                dc = dcol[i+(loop_num-1)*sample][j]
                if (fl - dc) == 0 or dc == 0 and fl == 0:
                    pass
                elif abs((fl - dc)/dc) < 0.01:
                    pass
                else:
                    print("Error: ", loop_num-1,i,j,abs((fl - dc)/dc),fl,dc)
                dcol[i+(loop_num-1)*sample][j] = fl

        self.dW = self.dW.transpose(1, 0).reshape(FN, C, FH, FW)
        dx = col2im(dcol, self.x.shape, FH, FW, self.stride, self.pad)

        return dx


class Pooling:
    def __init__(self, pool_h, pool_w, stride=1, pad=0):
        self.pool_h = pool_h
        self.pool_w = pool_w
        self.stride = stride
        self.pad = pad
        
        self.x = None
        self.arg_max = None

    def forward(self, x):
        N, C, H, W = x.shape
        out_h = int(1 + (H - self.pool_h) / self.stride)
        out_w = int(1 + (W - self.pool_w) / self.stride)

        col = im2col(x, self.pool_h, self.pool_w, self.stride, self.pad)
        col = col.reshape(-1, self.pool_h*self.pool_w)

        arg_max = np.argmax(col, axis=1)
        out = np.max(col, axis=1)
        out = out.reshape(N, out_h, out_w, C).transpose(0, 3, 1, 2)

        self.x = x
        self.arg_max = arg_max

        return out

    def backward(self, dout):
        dout = dout.transpose(0, 2, 3, 1)
        
        pool_size = self.pool_h * self.pool_w
        dmax = np.zeros((dout.size, pool_size))
        dmax[np.arange(self.arg_max.size), self.arg_max.flatten()] = dout.flatten()
        dmax = dmax.reshape(dout.shape + (pool_size,)) 
        
        dcol = dmax.reshape(dmax.shape[0] * dmax.shape[1] * dmax.shape[2], -1)
        dx = col2im(dcol, self.x.shape, self.pool_h, self.pool_w, self.stride, self.pad)
        
        return dx
