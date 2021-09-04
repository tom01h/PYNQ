# 2 PL 上の 行列乗算器(1)を使う

PL に作った行列乗算器を使って計算します。  
IP は 行列メモリ、入力データバッファ、出力データバッファを持ち、それぞれ dma を使ってアクセスします。

アドレス0のレジスタのビット0に1を書くと行列メモリ書き込みモードに入ります。  
このモードで AXIストリームからデータを入力して行列メモリに書き込みます。  
書き込める行列のサイズは4行8列固定で、列→行の順にデータを送ります。

アドレス0のレジスタのビット1に1を書くと行列乗算モードに入ります。  
データ入力→行列乗算→結果出力の順に実行します。  
入力データは8行4列固定で、行→列の順にデータを送ります。  
AXI ストリームからデータを入力し終わると行列乗算を開始し、計算が終わると AXI ストリームから結果を出力します。  
4行4列の乗算結果の出力が終わると、次の入力データ待ち状態となります。

IP の行列乗算機能は疑似コードを書くとこんな感じ。

```
    for(int j=0; j<4; j++){
      int sum[4] = {};
      for(int k=0; k<8; k++){
      	int d = in_buf[j][k];
# parallel for
        for(int i=0; i<4; i++){
          sum[i] += matrix[i][k] * d;
        }
      }
      for(int i=0; i<4; i++){
        out_buf[j][i] = sum[i];
      }
    }
```

データの入出力には Xilinx の AXI DMA IP を使います。  
行列乗算モジュールの実装はかなりいい加減なので流用することはあまり考えないでください。

## RTL シミュレーションを実行する

ホストマシン側の準備として、numpy をインストールします。

```
$ sudo apt install python3-pip
$ pip3 install numpy
```

RTL から Python モジュールをコンパイルします。

コンパイルには Python3 と Verilator が必要です。

```
$ make
```

シミュレーションを実行すると、波形ファイル `tmp.vcd` ができます。

```
$ PYTHONPATH=../../ python3 test.py
```

## FPGA で実行する

### ブロックデザインを作る

[NahiViva](https://github.com/tokuden/NahiViva) で再現できるようにしました。説明は [こっち](http://nahitafu.cocolog-nifty.com/nahitafu/2019/05/post-2cfa5c.html) を見た方が良いかも。  
必要なファイルをダウンロードして、```open_project_gui.cmd``` 実行でプロジェクトが再現されます。

#### 手動でやるなら

1. Vivado でソースファイル （`top.v, buf.sv, control.sv, core.sv, ex_ctl.sv, loop_lib.sv` ）を開く
2. ブロックデザインの中に `top` を RTLモジュールとして追加する
3. ほかの部品を `design_1.pdf` を参考に追加して結線する
4. PL のクロックは 100MHz

### ファイルを転送する

FPGA の Linux にlib ディレクトリを作成し、../lib から以下のファイルをコピーする

- fpga.py
- lib.py

FPGA の Linux に 2_gemm1 ディレクトリを作成し、以下のファイルをコピーする

- test.py

FPGA の Linux に 2_gemm1/bit ディレクトリを作成し、以下のファイルをリネームしてコピーする

`PYNQ\ArtyZ7\2_gemm1\project_1\project_1.srcs\sources_1\bd\design_1\hw_handoff` から

- design_1.hwh を gemm1.hwh にリネームしてコピー

- design_1_bd.tcl を gemm1.tcl にリネームしてコピー

`PYNQ\ArtyZ7\2_gemm1\project_1\project_1.runs\impl_1` から

- design_1_wrapper.bit を gemm1.bit にリネームしてコピー

### 実行する

先ほど作成した 2_gemm1 ディレクトリにて、

```
xilinx@pynq:~/2_gemm1$ sudo PYTHONPATH=~ python3 test.py
```

### ~~TODO~~

以下の問題は、AXI Stream の TLAST をアサートすることで解決しました (a21ab76)

PL to PS の DMA が 1回の転送が終わると、Running が False になってアクセス不能になる。

今は無理やり DMA リセットをしているが正しくはどうすべきなんだろうか？

```
    dma0.write(0x00,4)
    dma_send.sendchannel.start()

    dma1.write(0x30,4)
    dma_recv.recvchannel.start()
```

