#include "sim/Vtop.h"
#include "verilated.h"
#include "verilated_vcd_c.h"
#include <Python.h>

vluint64_t vcdstart = 0;
vluint64_t vcdend = vcdstart + 100000;
vluint64_t main_time;
VerilatedVcdC* tfp;
Vtop* verilator_top;

void eval()
{
  // negedge clk /////////////////////////////
  verilator_top->S_AXI_ACLK = 0;
  verilator_top->AXIS_ACLK = 0;

  verilator_top->eval();

  if((main_time>=vcdstart)&((main_time<vcdend)|(vcdend==0)))
    tfp->dump(main_time);
  main_time += 5;

  // posegedge clk /////////////////////////////
  verilator_top->S_AXI_ACLK = 1;
  verilator_top->AXIS_ACLK = 1;

  verilator_top->eval();

  if((main_time>=vcdstart)&((main_time<vcdend)|(vcdend==0)))
    tfp->dump(main_time);
  main_time += 5;

  return;
}

static PyObject *
bus_size (PyObject *self, PyObject *args) {

  return Py_BuildValue("i", 2);
}

static PyObject *
fin (PyObject *self, PyObject *args) {

  delete verilator_top;
  tfp->close();

  Py_INCREF(Py_None);
  return Py_None;
}

static PyObject *
write (PyObject *self, PyObject *args) {
  long address, data;
  // 送られてきた値をパース
  if(!PyArg_ParseTuple(args, "ll",&address, &data))
    return NULL;

  verilator_top->S_AXI_AWADDR = address;
  verilator_top->S_AXI_WDATA = data;
  verilator_top->S_AXI_AWVALID = 1;
  verilator_top->S_AXI_WVALID = 1;
  eval();
  verilator_top->S_AXI_AWVALID = 0;
  verilator_top->S_AXI_WVALID = 0;
  eval();eval();

  Py_INCREF(Py_None);
  return Py_None;
}

static PyObject *
evaluate (PyObject *self, PyObject *args) {

  eval();

  Py_INCREF(Py_None);
  return Py_None;
}

static PyObject *
send (PyObject *self, PyObject *args) {
  long data;
  // 送られてきた値をパース
  if(!PyArg_ParseTuple(args, "l", &data))
    return NULL;

  verilator_top->S_AXIS_TDATA = data;

  Py_INCREF(Py_None);
  return Py_None;
}

static PyObject *
send_start (PyObject *self, PyObject *args) {

  verilator_top->S_AXIS_TVALID = 1;

  Py_INCREF(Py_None);
  return Py_None;
}

static PyObject *
send_fin (PyObject *self, PyObject *args) {

  verilator_top->S_AXIS_TVALID = 0;

  Py_INCREF(Py_None);
  return Py_None;
}

static PyObject *
recv (PyObject *self, PyObject *args) {
  if(verilator_top->M_AXIS_TVALID){
    return Py_BuildValue("l", verilator_top->M_AXIS_TDATA);
  }else{
    Py_INCREF(Py_None);
    return Py_None;
  }
}

static PyObject *
recv_start (PyObject *self, PyObject *args) {

  verilator_top->M_AXIS_TREADY = 1;

  Py_INCREF(Py_None);
  return Py_None;
}

static PyObject *
recv_fin (PyObject *self, PyObject *args) {

  verilator_top->M_AXIS_TREADY = 0;

  Py_INCREF(Py_None);
  return Py_None;
}

// メソッドの定義
static PyMethodDef TopMethods[] = {
  {"bus_size",   (PyCFunction)bus_size,   METH_NOARGS,  "top1:  bus_size"},
  {"fin",        (PyCFunction)fin,        METH_NOARGS,  "top2:  fin"},
  {"write",      (PyCFunction)write,      METH_VARARGS, "top3:  write"},
  {"evaluate",   (PyCFunction)evaluate,   METH_NOARGS,  "top4:  evaluate"},
  {"send",       (PyCFunction)send,       METH_VARARGS, "top5:  send"},
  {"send_start", (PyCFunction)send_start, METH_NOARGS,  "top6:  send_start"},
  {"send_fin",   (PyCFunction)send_fin,   METH_NOARGS,  "top7:  send_fin"},
  {"recv",       (PyCFunction)recv,       METH_NOARGS,  "top8:  recv"},
  {"recv_start", (PyCFunction)recv_start, METH_NOARGS,  "top9:  recv_start"},
  {"recv_fin",   (PyCFunction)recv_fin,   METH_NOARGS,  "top10: recv_fin"},
  // 終了を示す
  {NULL, NULL, 0, NULL}
};

//モジュールの定義
static struct PyModuleDef toptmodule = {
  PyModuleDef_HEAD_INIT,
  "top",
  NULL,
  -1,
  TopMethods
};

// メソッドの初期化
PyMODINIT_FUNC PyInit_top (void) {
  //  Verilated::commandArgs(argc,argv);
  Verilated::traceEverOn(true);
  main_time = 0;
  tfp = new VerilatedVcdC;
  verilator_top = new Vtop;
  verilator_top->trace(tfp, 99); // requires explicit max levels param
  tfp->open("tmp.vcd");

  main_time = 0;

  // initial begin /////////////////////////////
  verilator_top->S_AXI_BREADY = 1;
  verilator_top->S_AXI_WSTRB = 15;
  verilator_top->S_AXI_RREADY = 1;
  verilator_top->S_AXIS_TSTRB = 15;
  verilator_top->S_AXIS_TLAST = 0;
  verilator_top->M_AXIS_TREADY = 0;

  verilator_top->S_AXI_ARESETN = 0;
  verilator_top->S_AXI_ACLK = 1;
  verilator_top->AXIS_ARESETN = 0;
  verilator_top->AXIS_ACLK = 1;
  verilator_top->S_AXI_ARVALID = 0;
  verilator_top->S_AXI_AWVALID = 0;
  verilator_top->S_AXI_WVALID = 0;
  verilator_top->S_AXIS_TVALID = 0;
  verilator_top->eval();

  main_time += 5;

  eval();eval();
  verilator_top->S_AXI_ARESETN = 1;
  verilator_top->AXIS_ARESETN = 1;
  eval();eval();

  return PyModule_Create(&toptmodule);
}
