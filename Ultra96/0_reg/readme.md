# 0 64bit レジスタアクセスお試し

PYNQ は 64bit アクセスを 32bit 2回に分割してるっぽいので試した 

### ブロックデザインを作る

[NahiViva](https://github.com/tokuden/NahiViva) で再現できるようにしました。説明は [こっち](http://nahitafu.cocolog-nifty.com/nahitafu/2019/05/post-2cfa5c.html) を見た方が良いかも。  
必要なファイルをダウンロードして、`open_project_gui.cmd` 実行でプロジェクトが再現されます。

### ファイルを転送する

FPGA の Linux に以下のファイルをコピーする

- test.py

FPGA の Linux に ~/bit ディレクトリを作成し、以下のファイルをリネームしてコピーする

`PYNQ/Ultra96/0_reg/sensors96b/sensors96b.srcs/sources_1/bd/sensors96b/hw_handoff/` から

- sensors96b.hwh を regs.hwh にリネームしてコピー

- sensors96b_bd.tcl を regs.tcl にリネームしてコピー

`PYNQ/Ultra96/0_reg/sensors96b/sensors96b.runs/impl_1/` から

- sensors96b_wrapper.bit を regs.bit にリネームしてコピー

### 実行する

0_reg ディレクトリにて、

```
xilinx@pynq:~$ sudo python3 test.py
bit ファイル読み込み
IP 初期設定
レジスタアクセス
wdata 0x8d9d1a2dced55cc0
rdata 0x8d9d1a2dced55cc0
wstrb 0xf0
lower 0xced55cc0
upper 0x8d9d1a2d
```

