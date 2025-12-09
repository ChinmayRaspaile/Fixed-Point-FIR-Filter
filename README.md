# High-Throughput 16-Tap Fixed-Point FIR Filter (SystemVerilog | Artix-7)

This project implements a fully pipelined 16-tap FIR filter in SystemVerilog using fixed-point Q1.15 arithmetic. The design achieves one output sample per clock cycle after pipeline fill and is verified through a self-checking golden-model testbench. An FPGA top module and constraints for the Nexys 4 DDR (XC7A100T-CSG324-1) are included for hardware testing.

---

## Features

* 16-tap FIR filter with Q1.15 fixed-point math
* Parallel multiplier stage (16 multipliers)
* Four-level pipelined adder tree
* Throughput: one output per clock
* Latency: ~20 cycles
* Streaming interface (`in_valid`, `in_sample`, `out_valid`, `out_sample`)
* Golden model verification inside the testbench
* FPGA demo using Nexys 4 DDR (LED0 brightness follows filter output)

---

## Repository Structure

```
FIR_Filter/
│
├── fir16_core.sv          # Main 16-tap FIR datapath
├── fpga_fir_top.sv        # FPGA demo top-level
├── tb_fir16.sv            # Testbench with golden model
├── nexys4ddr_fir.xdc      # Board constraints
└── README.md              # Documentation
```

---

## Design Overview

### FIR Equation

```
y[n] = Σ ( h[k] * x[n - k] ),  k = 0…15
```

### Pipeline Stages

* Input shift register
* 16 parallel multipliers (x[i] × coeff[i])
* 4-stage pipelined adder tree (16→8→4→2→1)
* Output truncation to Q1.15
* Valid signal pipelining for latency alignment

### Latency

~20 clock cycles

### Throughput

One output per clock cycle

---

## Simulation (Vivado 2025.x)

1. Add SystemVerilog sources to a new Vivado project.
2. Set `tb_fir16` as **simulation top**.
3. Run Behavioral Simulation.
4. You should see DUT and golden model outputs match:

```
OK @ 42: DUT=1234  GOLD=1234
OK @ 43: DUT=1210  GOLD=1210
```

---

## FPGA Demo (Nexys 4 DDR)

`fpga_fir_top.sv`:

* Generates a slow ramp
* Feeds it to the FIR filter
* Drives LED0 based on filtered output (PWM-style brightness)

### XDC Snippet

```
## Clock (100 MHz)
set_property PACKAGE_PIN E3 [get_ports { clk_in }]
create_clock -period 10.000 [get_ports clk_in]

## Reset (BTN_C)
set_property PACKAGE_PIN U18 [get_ports { rst_btn }]

## LED0
set_property PACKAGE_PIN T8 [get_ports { led0 }]
```

---

## Verification Summary

Testbench validates functionality through:

* Impulse response test
* Random input sequences
* Golden FIR model
* Cycle-accurate comparison of DUT vs reference

**Result:** Perfect match for all test samples.

---

## Possible Extensions

* Replace coefficients with real LPF/HPF/BPF values
* Add AXI-Stream interfaces
* Add AXI-Lite programmable coefficient memory
* Increase tap count (32/64)
* Optimize for DSP48 slices

---

