This repository contains implementation of FIFO Architecture for Digital Designs in Verilog. 

## Repo Structure 
- Synchronous
- Asynchrnous

## Highlights
- Parameterized FIFO design
- Full, Empty, Almost Full/Empty flags
- Overflow & Underflow handling
- Self-checking testbench
- Random stress testing

## Difference between Sync. and Async. FIFO 
**Synchronous FIFO** uses a single clock for both read and write operations.  
It is simpler to design and does not require clock domain crossing logic.  
Suitable when both producer and consumer operate at the same clock speed.  

**Asynchronous FIFO** uses separate clocks for read and write operations.  
Requires special techniques like Gray code and synchronizers to avoid metastability.  
More complex but essential when data is transferred between different clock domains.
