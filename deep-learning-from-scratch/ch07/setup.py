from setuptools import setup, Extension
setup(name='top',
        version='1.0',
        ext_modules=[Extension('top', ['top.cpp', 'sim/Vtop__ALLcls.cpp', 'sim/Vtop__ALLsup.cpp', 'verilated.cpp', 'verilated_vcd_c.cpp'])]
)
