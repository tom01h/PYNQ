# Arty Z7 20 で PYNQ

[本家](http://www.pynq.io/) から引用

```
PYNQは、ザイリンクスプラットフォームの使用を容易にするザイリンクスのオープンソースプロジェクトです。
設計者は、Python言語とライブラリを使用して、プログラマブルロジックとマイクロプロセッサの利点を活用し、より機能的で刺激的な電子システムを構築できます。
```

つまり、Python から PL を簡単に制御するための仕組みってことかな。

Zynq の場合は PS 上で Linux と Python が動きます (Alveo は知らない)。

## セットアップとサンプルを実行

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

#### btns_leds

まずは `base/board/board_btns_leds.ipynb` を開いてみます。出来ることは上のほうに書いてある通り。

`In[1]` も近くをクリックして、青の枠で囲まれている状態で、上にある Run ボタンを押します。

しばらくすると、ボード上の Done LED が一瞬消えて、LED0-3 が点灯します。

BTN0-3 を押すと、上のほうに書いてある通りの動作をします。

#### usb_webcam

次に `common/usb_webcam.ipynb` を試してみます。

ロジクール ウェブカメラ C270 が手元にあったので繋いでみました。いとも簡単に動きました。

でも、C270 はもう売っていないですねぇ。

## PYNQ Workshop を試す

<!--[PYNQ_Workshop](https://github.com/Xilinx/PYNQ_Workshop) をいくつか試してみます。-->

### <!--ファイル転送-->

<!--エクスプローラーのアドレスバー(？) に `\\192.168.0.106\xilinx` を入力するとファイルのアクセスができます。-->

<!--先の github からダウンロードしてきたファイルを転送します。-->

### <!--サンプルを実行する-->

#### <!--mmio-->

<!--Session_4/3_mmio.ipynb-->

#### <!--Memory Allocation-->

<!--Session_4/4_basic_xlnk_example.ipynb-->

#### <!--DMA tutorial-->

<!--Session_4/6_dma_tutorial.ipynb-->

#### <!--今はやらないけど MicroBlaze program-->

<!--MicroBlaze のプログラムを送り込んで実行することもできそう-->

<!--Session_4/5_xlnk_with_pl_master_example.ipynb-->

## PL デザインを自作する

<!--PL 上の BRAM に DMA を使ってアクセスする-->

<!--PL 上の 行列乗算器(1)を使う-->

<!--PL 上の 行列乗算器(4)を使う-->