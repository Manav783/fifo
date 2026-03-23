# Asynchronous FIFO (Clock Domain Crossing)

## Overview
This project implements a **parameterized Asynchronous FIFO** in Verilog. Unlike a synchronous FIFO, this design allows data to be written in one clock domain (`wr_clk`) and read in another, completely independent clock domain (`rd_clk`). 

This is a critical component for **Clock Domain Crossing (CDC)**, preventing metastability and ensuring data integrity when transferring data between asynchronous interfaces.

---

## Objectives
* Design a **dual-clock FIFO** with independent read and write domains.
* Implement **Gray Code pointer conversion** to safely cross clock boundaries.
* Use **Multi-stage Synchronizers** to mitigate metastability.
* Detect **Full** and **Empty** conditions across asynchronous domains.
* Verify robustness using a **latency-aware self-checking testbench**.

---

## Parameters
| Parameter    | Description                               |
| ------------ | ----------------------------------------- |
| `FIFO_DEPTH` | Number of elements (Must be power of 2)   |
| `DATA_WIDTH` | Bit-width of each data element            |
| `ADDR_WIDTH` | Calculated as $log_2(\text{FIFO\_DEPTH})$ |

---

## Internal Architecture

### 1. Dual-Port Memory
* A memory array that allows simultaneous access from two different clock domains.
* Write operations are synchronous to `wr_clk`.
* Read operations are synchronous to `rd_clk`.

### 2. Gray Code Pointers
To safely pass pointers between domains, binary counters are converted to **Gray Code**.
* **Why Gray Code?** Only **one bit changes** at a time. This prevents "bus skew" where a multi-bit binary change (e.g., `0111` to `1000`) could be sampled incorrectly by the destination clock if bits arrive at slightly different times.



### 3. 2-Stage Synchronizers
* Used to sample the Gray-coded pointer from the "opposite" domain.
* Two flip-flops in series allow metastable signals to settle before they reach the comparison logic.

---

## Working Principle

### Write Domain (`wr_clk`)
1. Increments the binary `wr_ptr`.
2. Converts `wr_ptr` to `wr_ptr_gray`.
3. Samples the `rd_ptr_gray` through a 2-stage synchronizer.
4. Compares local `wr_ptr_gray` with synchronized `rd_ptr_gray` to generate the **Full** flag.

### Read Domain (`rd_clk`)
1. Increments the binary `rd_ptr`.
2. Converts `rd_ptr` to `rd_ptr_gray`.
3. Samples the `wr_ptr_gray` through a 2-stage synchronizer.
4. Compares local `rd_ptr_gray` with synchronized `wr_ptr_gray` to generate the **Empty** flag.

---

## Flag Logic (Gray Code Comparison)

| Condition | Logic Definition |
| --------- | ---------------- |
| **Empty** | `rd_ptr_gray == wr_ptr_sync_gray` |
| **Full** | `wr_ptr_gray == {~rd_ptr_sync_gray[MSB:MSB-1], rd_ptr_sync_gray[MSB-2:0]}` |

> **Note:** The Full condition in Gray code requires inverting the top two bits of the synchronized read pointer while the remaining bits match.

---

## Status & Error Signals
* **Full / Empty:** Primary flow control signals.
* **Valid:** Asserted when data on `rdata` is stable and was successfully read.
* **Overflow / Underflow:** Error flags triggered when functional bounds are exceeded.

---

## Verification Strategy
The design is verified using a high-fidelity testbench in **Aldec Riviera-PRO**, featuring:
* **Asynchronous Clock Generation:** Independent frequencies for `wr_clk` (100MHz) and `rd_clk` (40MHz).
* **Latency Modeling:** Accounts for the 3–4 cycle delay required for pointer synchronization.
* **Timeout Protection:** Safety mechanisms to prevent simulation hangs during CDC failures.
* **Self-Checking Monitor:** Automatic data comparison against a SystemVerilog reference queue.

---

## Key Features
* **Meta-stability hardened** with 2-stage synchronization.
* **Parameterized** width and depth for modular reuse.
* **Independent clock domains** supporting Fast-to-Slow and Slow-to-Fast transitions.
* **Self-checking** verification environment.

---

## Summary
This Asynchronous FIFO implementation provides a robust solution for data transfer between mismatched clock domains. By utilizing Gray code encoding and multi-stage synchronization, it effectively eliminates the risks of data corruption and meta-stability in complex digital systems.
