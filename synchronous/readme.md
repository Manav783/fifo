# Synchronous FIFO 

## Overview

This project implements a **Synchronous FIFO (First-In First-Out)** memory in Verilog.
A FIFO is a data structure where the **first data written is the first one to be read**, similar to a queue.

In a **synchronous FIFO**, both read and write operations happen using the **same clock**, making the design simpler and easier to control.

---

## Objectives

* Design a **parameterized FIFO**
* Handle **read and write operations safely**
* Detect and signal **overflow and underflow conditions**
* Provide **status flags** like full, empty, almost full, almost empty
* Verify correctness using a **self-checking testbench**

---

## Parameters

| Parameter    | Description                       |
| ------------ | --------------------------------- |
| `FIFO_DEPTH` | Number of elements FIFO can store |
| `DATA_WIDTH` | Bit-width of each data element    |

---

## Internal Architecture

### 1. Memory Array

```verilog
reg [DATA_WIDTH-1:0] fifo [0:FIFO_DEPTH-1];
```

* Stores the actual data
* Acts like a circular buffer

---

### 2. Pointers

* **Write Pointer (`write_pointer`)**

  * Points to location where next data will be written

* **Read Pointer (`read_pointer`)**

  * Points to location from where data will be read

* Both pointers have **one extra MSB bit**

  * Used to differentiate between **full and empty conditions**

---

### 3. FIFO Counter (`fifo_count`)

Tracks how many elements are currently inside the FIFO.

| Operation    | Effect    |
| ------------ | --------- |
| Write only   | +1        |
| Read only    | -1        |
| Read + Write | No change |

---

## Working of FIFO

### Write Operation

* Happens when:

  ```verilog
  cs && wr_en && !full
  ```
* Data is written into memory
* Write pointer increments

### Read Operation

* Happens when:

  ```verilog
  cs && rd_en && !empty
  ```
* Data is read from memory
* Read pointer increments

---

## Error Conditions

### Overflow

* Occurs when writing while FIFO is full
* Data is **not written**
* `overflow` signal is set

### Underflow

* Occurs when reading while FIFO is empty
* No valid data is read
* `underflow` signal is set

---

## Status Signals

### Empty

```verilog
read_pointer == write_pointer
```

* No data available to read

---

### Full

```verilog
MSB differs && lower bits equal
```

* FIFO is completely filled

---

### Almost Full

```verilog
fifo_count == FIFO_DEPTH - 1
```

* FIFO is about to become full

---

### Almost Empty

```verilog
fifo_count == 1
```

* FIFO is about to become empty

---

## Simultaneous Read & Write

* FIFO supports **reading and writing in the same clock cycle**
* In this case:

  * One element is added
  * One element is removed
  * `fifo_count` remains unchanged

---

## Testbench Strategy

The FIFO is verified using a **self-checking testbench**, which includes:

* Sequential writes and reads
* Overflow and underflow testing
* Simultaneous read/write operations
* Randomized stress testing
* Automatic result validation

---

## Waveform Analysis

Waveforms are used to verify:

* Correct data ordering (FIFO behavior)
* Proper assertion of flags
* Correct pointer movement

---

## Key Features

* Fully **parameterized design**
* Supports **simultaneous operations**
* Includes **error detection**
* Implements **threshold indicators**
* Verified using **self-checking methodology**

---

## Applications

* Buffers in communication systems
* Data transfer between modules
* Pipeline architectures
* Hardware queues

---

## Summary

This project demonstrates how to design and verify a robust synchronous FIFO.
It covers both **functional correctness** and **edge-case handling**, making it a strong foundation for understanding more advanced designs like **asynchronous FIFOs**.

---
