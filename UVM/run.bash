#!/usr/bin/env bash
set -euo pipefail

LOG="riviera.log"

rm -rf work
rm -f "${LOG}"
rm -f dump.vcd

# Toda la salida posterior se guarda únicamente en riviera.log:
# exec >"${LOG}" 2>&1

vlib work

vlog \
    -sv \
    -timescale 1ns/1ns \
    +incdir+"$RIVIERA_HOME/vlib/uvm-1.2/src" \
    -l uvm_1_2 \
    -err VCP2947 W9 \
    -err VCP2974 W9 \
    -err VCP3003 W9 \
    -err VCP5417 W9 \
    -err VCP6120 W9 \
    -err VCP7862 W9 \
    -err VCP2129 W9 \
    design.sv \
    testbench.sv

vsim -c -do \
    "vsim +access+r +UVM_VERBOSITY=UVM_MEDIUM work.tb_top; run -all; exit"