SHELL = /bin/bash

SIM_DIR = sim
VERILATOR = verilator
TOP       = top
PREFIX    = V$(TOP)

VERILATOR_OPTS = \
	-Wall \
	-Wno-WIDTH \
	-Wno-UNUSED \
	-Wno-BLKSEQ \
	--cc \
	+1364-2005ext+v \
	+1800-2017ext+sv \
	-Wno-fatal \
	--Mdir $(SIM_DIR) \
	--top-module $(TOP) \
	--prefix $(PREFIX) \
	--trace \
	--trace-params \
	--trace-structs \
	--trace-underscore \

VERILATOR_MAKE_OPTS = OPT_FAST="-O2"

DESIGN_SRCS = \
top.v \
buf.sv \
control.sv \
core.sv \
ex_ctl.sv \
loop_lib.sv \

VERILATOR_CPP_TB = top.cpp

default: $(SIM_DIR)/$(PREFIX)

sim: $(SIM_DIR)/$(PREFIX)

$(SIM_DIR)/Vtop: $(DESIGN_SRCS) $(VERILATOR_CPP_TB)
	$(VERILATOR) $(VERILATOR_OPTS) $(DESIGN_SRCS) --exe ../$(VERILATOR_CPP_TB)
	cp /usr/local/share/verilator/include/verilated.cpp .
	cp /usr/local/share/verilator/include/verilated_vcd_c.cpp .
	python3 setup_trace.py build_ext -I/usr/local/share/verilator/include -i

clean:
	rm -rf build/ sim/ tmp.vcd *.so cp verilated.cpp verilated_vcd_c.cpp

.PHONY:
