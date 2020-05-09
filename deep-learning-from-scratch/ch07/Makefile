SHELL = /bin/bash

SIM_DIR = sim

VERILATOR = verilator

VERILATOR_OPTS = \
	-Wall \
	-Wno-WIDTH \
	-Wno-UNUSED \
	-Wno-BLKSEQ \
	--cc \
	+1364-2001ext+v \
	-Wno-fatal \
	--Mdir sim \
	--trace \

VERILATOR_MAKE_OPTS = OPT_FAST="-O3"

DESIGN_SRCS = \
top_bf16.v \
buf_bf16.sv \
control.sv \
core_bf16.sv \
ex_ctl.sv \
loop_lib.sv \

VERILATOR_CPP_TB = tb.cpp

default: $(SIM_DIR)/Vtop

sim: $(SIM_DIR)/Vtop

$(SIM_DIR)/Vtop: $(DESIGN_SRCS) $(VERILATOR_CPP_TB)
	$(VERILATOR) $(VERILATOR_OPTS) $(DESIGN_SRCS) --exe ../$(VERILATOR_CPP_TB)
	cd sim; make $(VERILATOR_MAKE_OPTS) -f Vtop.mk Vtop__ALL.a
	cp /usr/local/share/verilator/include/verilated.cpp .
	cp /usr/local/share/verilator/include/verilated_vcd_c.cpp .
	python3 setup.py build_ext -I/usr/local/share/verilator/include -i

clean:
	rm -rf build/ sim/ tmp.vcd *.so cp verilated.cpp verilated_vcd_c.cpp

.PHONY:
