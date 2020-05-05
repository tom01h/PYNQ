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
$ PYTHONPATH=../ python3 train_convnet.py
```

とりあえず、Convolution forward だけ、`simple_convnet.py` の構成固定で RTL 化ができました。

メモリの量も大きすぎる気もするし、計算自体は real 使っているしで、シミュレーションしかできない RTL です。

現状、すべての計算の期待値を求めて、誤差の計算をしていますが、そこそこ大きな誤差が出ている模様…

#### 参考

[Pythonで浮動小数点数floatと16進数表現の文字列を相互に変換](https://note.nkmk.me/python-float-hex/)

[python - CでPy_Noneを返す前にPy_INCREF(Py_None)が必要なのはなぜですか？](https://ja.coder.work/so/python/200081)

Verilog で wire と real を変換  $realtobits $realtobits