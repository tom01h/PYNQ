# ゼロから作るディープラーニング 7章 畳み込みニューラルネットワーク

## シミュレーションを実行する

以下の準備が必要な場合があります。

```
$ sudo apt install python3-pip
$ pip3 install numpy
$ pip3 install matplotlib
```

実行は↓。画面にグラフが出る代わりに、`figure.png` が保存されます。

```
$ make
$ PYTHONPATH=../lib/ python3 train_convnet.py
```

ウェイトとデータを bfloat16 で入力して、独自のデータ型を中間データとして行列乗算を実行し、float32 の形式で結果を出力します。

入力データの float32 → bfloat16 変換は IP 内部で行っているため、転送バンド幅を無駄に使っているかも…

シミュレーションには結構な時間がかかるので、real 型を使ってシミュレーションをするために、`hoge_bf16.sv` を別のファイルとして準備しました。real で実行する場合は _bf16 のないファイルを使ってください。

現状、すべての計算の期待値を求めて、誤差の比較をしていますが、そこそこ大きな誤差が出ている模様…

## FPGA で実行する

すごく遅いけど…

### ブロックデザインを作る

[NahiViva](https://github.com/tokuden/NahiViva) で再現できるようにしました。説明は [こっち](http://nahitafu.cocolog-nifty.com/nahitafu/2019/05/post-2cfa5c.html) を見た方が良いかも。  
必要なファイルをダウンロードして、`open_project_gui.cmd` 実行でプロジェクトが再現されます。

### ファイルを転送する

deep-learning-from-scratch/ 以下を PYNQ を実行している FPGA ボードにコピーする

ch07/bit/ ディレクトリを準備して次のファイルをコピーする

`project_1\project_1.srcs\sources_1\bd\design_1\hw_handoff` から

- design_1.hwh を design_1.hwh にリネームしてコピー

- design_1_bd.tcl を design_1.tcl にリネームしてコピー

`project_1\project_1.runs\impl_1` から

- design_1_wrapper.bit を design_1.bit にリネームしてコピー

### 実行する

deep-learning-from-scratch/ch07 で 

```
$ sudo PYTHONPATH=./lib/ python3 train_convnet.py
```

#### 参考

[Pythonで浮動小数点数floatと16進数表現の文字列を相互に変換](https://note.nkmk.me/python-float-hex/)

[python - CでPy_Noneを返す前にPy_INCREF(Py_None)が必要なのはなぜですか？](https://ja.coder.work/so/python/200081)

Verilog で wire と real を変換  $realtobits $realtobits