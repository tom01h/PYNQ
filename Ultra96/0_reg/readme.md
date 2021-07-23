# 0 64bit レジスタアクセスお試し

PYNQ は 64bit アクセスを 32bit 2回に分割してるっぽいので試した 

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

