# 1 PL 上の BRAM に DMA アクセスする

PL に作った BRAM  に DMA を使ってアクセスします。

BRAM は mem モジュール内のオフセット 0x400 から始まる 1KB に配置しています。

- 0番地に0を書くとメモリマップアクセスができます
- 0番地に1、4番地に転送ワード数を書くと、ストリームデータの書き込みができます
- 0番地に2、4番地に転送ワード数を書くと、ストリームデータの読み出しができます

DMA は Xilinx の AXI DMA IP を使います。

### ブロックデザインを作る

[NahiViva](https://github.com/tokuden/NahiViva) で再現できるようにしました。説明は [こっち](http://nahitafu.cocolog-nifty.com/nahitafu/2019/05/post-2cfa5c.html) を見た方が良いかも。  
必要なファイルをダウンロードして、`open_project_gui.cmd` 実行でプロジェクトが再現されます。

#### 手動でやるなら

1. Vivado でソースファイル （`mem.v` ）を開く
2. ブロックデザインの中に ```mem``` を RTLモジュールとして追加する
3. ほかの部品を ```design_1.pdf``` を参考に追加して結線する
4. PL のクロックは 100MHz
5. **PS の HPC0 のバス幅を 128bit に設定しないと正しく動きません**

### ファイルを転送する

FPGA の Linux に 1_dma ディレクトリを作成し、以下のファイルをコピーする

- test.py

FPGA の Linux に 1_dma/bit ディレクトリを作成し、以下のファイルをリネームしてコピーする

`project_1\project_1.gen\sources_1\bd\design_1\hw_handoff` から

- design_1.hwh を dma.hwh にリネームしてコピー

- design_1bd.tcl を dma.tcl にリネームしてコピー

`project_1\project_1.runs\impl_1` から

- design_1_wrapper.bit を dma.bit にリネームしてコピー

### 実行する

先ほど作成した 1_dma ディレクトリにて、

```
xilinx@pynq:~/1_dma$ sudo -E python3 test.py
```
