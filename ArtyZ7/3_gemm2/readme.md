# 3 PL 上の 行列乗算器(2)を使う

PL に作った行列乗算器を使って計算します。

IP は 行列メモリ、入力データバッファ、出力データバッファを持ち、それぞれ dma を使ってアクセスします。

IP の行列乗算機能は前回と同じです。

以下の高速化の工夫を追加します。詳しくは [ここ](https://github.com/tom01h/TIL/tree/master/petalinux_dma) の 5~7回目を見るとよいかも。

疑似コードを書くとこんな感じですが、`k` のループと `oa` のループがパイプライン動作するようになりました。

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
      for(int oa=0; oa<4; oa++){
        out_buf[j][oa] = sum[oa];
      }
    }
```

データ転送を 2ワード(=64bit)/サイクル として、データ転送時間を半減しました。  

データ転送(`src_v,dst_v`)と演算(`exec`)をパイプライン動作させました。

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

FPGA の Linux に 3_gemm2 ディレクトリを作成し、以下のファイルをコピーする

- test.py

FPGA の Linux に 3_gemm2/bit ディレクトリを作成し、以下のファイルをリネームしてコピーする

`PYNQ\ArtyZ7\3_gemm2\project_1\project_1.srcs\sources_1\bd\design_1\hw_handoff` から

- design_1.hwh を gemm2.hwh にリネームしてコピー

- design_1_bd.tcl を gemm2.tcl にリネームしてコピー

`PYNQ\ArtyZ7\3_gemm2\project_1\project_1.runs\impl_1` から

- design_1_wrapper.bit を gemm2.bit にリネームしてコピー

### 実行する

先ほど作成した 3_gemm2ディレクトリにて、

```
xilinx@pynq:~/3_gemm2$ sudo PYTHONPATH=~ python3 test.py
```

