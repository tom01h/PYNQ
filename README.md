# Arty Z7 20 で PYNQ

[本家](http://www.pynq.io/) から引用

```
PYNQは、ザイリンクスプラットフォームの使用を容易にするザイリンクスのオープンソースプロジェクトです。
設計者は、Python言語とライブラリを使用して、プログラマブルロジックとマイクロプロセッサの利点を活用し、
より機能的で刺激的な電子システムを構築できます。
```

つまり、Python から PL を簡単に制御するための仕組みってことかな。

Zynq の場合は PS 上で Linux と Python が動きます (Alveo は知らない)。

Arty Z7 20 と PYNQ Z1 は電源スイッチの有無以外に差はないらしく、Arty Z7 20 でも PYNQ が実行できるとのことです。

## セットアップとサンプルの実行

### ダウンロードと SD カードへの書き込み

[公式ダウンロードページ](http://www.pynq.io/board.html) から `PYNQ-Z1 v2.5 PYNQ image` をダウンロード。

ZIP ファイルから `pynq_z1_v2.5.img` を取り出す。

ここから先は RaspberryPi で実行しましたが、dd が使えれば何でもよいはず。

ダウンロードパス と、MicroSD のマウントポイント `/dev/sdbN` は適宜書き換え。

```
$ sudo sudo umount /dev/sdbN
$ sudo dd bs=16M if=/${ダウンロードパス}/pynq_z1_v2.5.img of=/dev/sdb
```

### 起動

[公式ページの説明](https://pynq.readthedocs.io/en/latest/getting_started/pynq_z1_setup.html#board-setup) を参考にして起動。ちなみに Arty Z7 には電源スイッチがないので、1,2,3,5,4 の順で実行します。

USB 接続した PC 上では TeraTerm などを使うことでコンソールが使えます。すると…

起動画面がつらつら流れて行ったあとで自動ログインしていました。

ユーザ名・パスワードともに `xilinx` に設定されているようです。

まずは IP アドレスを調べます。

```
xilinx@pynq:~$ ifconfig eth0
eth0: flags=4163<UP,BROADCAST,RUNNING,MULTICAST>  mtu 1500
        inet 192.168.0.106  netmask 255.255.255.0  broadcast 192.168.0.255
```

時刻表示が気になったので設定しておきました。

```
$ sudo ln -fs /usr/share/zoneinfo/Asia/Tokyo /etc/localtime
```

resize2fs でパーティションの拡張をする必要はないみたいでした。

### Jupyter Notebook を開く

ブラウザを選ぶとのことですが、とりあえず、ChromiumEdge では出来ました。

アドレスバーに先ほど調べたアドレスを参考に `http://192.168.0.106:9090/` を入力します。

ソースコードを見るだけなら、PYNQ をインストールしなくても [ここ(board)](https://github.com/Xilinx/PYNQ/tree/master/boards/Pynq-Z1/base/notebooks/board) か [ここ(common)](https://github.com/Xilinx/PYNQ/tree/master/pynq/notebooks/common) から見れます。

#### btns_leds

まずは `base/board/board_btns_leds.ipynb` を開いてみます。出来ることは上のほうに書いてある通り。

`In[1]` の近くをクリックして、青の枠で囲まれている状態で、上にある Run ボタンを押します。

しばらくすると、ボード上の Done LED が一瞬消えて、LED0-3 が点灯します。

BTN0-3 を押すと、上のほうに書いてある通りの動作をします。

#### usb_webcam

次に `common/usb_webcam.ipynb` を試してみます。

ロジクール ウェブカメラ C270 が手元にあったので繋いでみました。いとも簡単に動きました。

でも、C270 はもう売っていないですねぇ。

## PYNQ Workshop を試す

[PYNQ_Workshop](https://github.com/Xilinx/PYNQ_Workshop) をいくつか試してみます。

### ダウンロード

FPGA 上で jupyter_notebooks/ ディレクトリに github からダウンロードする。

```
xilinx@pynq:~$ cd jupyter_notebooks/
xilinx@pynq:~/jupyter_notebooks$ git clone https://github.com/Xilinx/PYNQ_Workshop
Cloning into 'PYNQ_Workshop'...
略
```

### サンプルを実行する

[Petalinux と DMA を使うサンプル実装](https://github.com/tom01h/TIL/tree/master/petalinux_dma) の時と比較しながら実行していきます。

再度 Jupyter Notebook を開いて、

#### mmio

最初に `PYNQ_Workshop/Session_4/3_mmio.ipynb` を試します。

PL GPIO を読み書きするサンプル。

uio を使ってやっていたことを、MMIO class を使ってやるような感じだと思います。

IP のインスタンス名からアドレスを調べて、そのアドレスの GPIO レジスタの値を読み書きできます。

read() に引数ないけど、デフォルト 0 なんでしょうね。

引数を 4 にしたら、書いたはずの ffffffff の実際にレジスタが存在する下位数ビット以外は0として読みだせました。

#### Memory Allocation

つぎは `PYNQ_Workshop/Session_4/4_basic_xlnk_example.ipynb` を試します。

udmabuf 相当のものと思われます。

ここではバッファを確保して、そのアドレスを調べているだけです。

#### DMA tutorial

つぎは `PYNQ_Workshop/Session_4/6_dma_tutorial.ipynb` を試します。

PL DMA を使って、DRAM から FIFO(BRAM) への転送と、 FIFO(BRAM) から DRAM へのデータ転送をします。

FIFO の入出力は AXI STREAM です。

とりあえず実行してそのあとに…

out_buffer のアドレスを調べる (ノートブック上で)

```
print(hex(output_buffer.physical_address))
0x1804a000
```

devmem2 でメモリの内容を調べる (コマンドライン上で)

```
$ sudo apt install devmem2
$ sudo devmem2 0x1804a000
略
Value at address 0x1804A000 (0xb6f90000): 0xCAFE0000
$ sudo devmem2 0x1804a008
略
Value at address 0x1804A008 (0xb6fa0008): 0xCAFE0002
```

まぁ、思った通りに動いていそうです。

ただ、AXI DMA はリードとライトで別々にインスタンスする必要があるのかな？

#### MicroBlaze program (今はやらないけど)

MicroBlaze のプログラムを送り込んで実行することもできるみたいです。

`PYNQ_Workshop/Session_4/5_xlnk_with_pl_master_example.ipynb`

## PL デザインを自作する

[Petalinux と DMA を使うサンプル実装](https://github.com/tom01h/TIL/tree/master/petalinux_dma) の時と同じことを試していきます。

ただし、AXI DMA はリードとライトで別々にインスタンスしたほうが面倒に巻き込まれないで済みそうです。

あと、PYNQ v2.5 を使用するには、Vivado 2019.1 を使うのが良いと思います。

以降、Jupyter Notebook は使いません。

### ファイル転送 (参考)

エクスプローラーのアドレスバー(？) に先ほど調べたアドレスを参考に `\\192.168.0.106\xilinx` を入力するとファイルのアクセスができます。

### 1 PL 上の BRAM に DMA を使ってアクセスする

PL に作った BRAM  に DMA を使ってアクセスします。

先の DMA tutorial とあまり変わりませんが、メモリマップアクセスと、DMA と使ったストリームアクセスのどちらでもアクセスできるメモリを作成して使用しています。

詳細は、`PYNQ/ArtyZ7/1_dma` を参照ください。

<!--PL 上の 行列乗算器(1)を使う-->

<!--PL 上の 行列乗算器(4)を使う-->

## <!--ゼロから作る Deep Lerning 7章-->

<!--[Ultra96 でやってみた人](https://www8281uo.sakura.ne.jp/blog/?p=739)-->