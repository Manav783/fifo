`timescale 1ns/1ps

module fifo_async_tb;
  parameter FIFO_DEPTH = 8;
  parameter DATA_WIDTH = 32;

  reg wr_clk, rd_clk, rst;
  reg wr_en, rd_en;
  reg  [DATA_WIDTH-1:0] wdata;
  wire [DATA_WIDTH-1:0] rdata;
  wire empty, full, valid;

  // DUT Instance
  fifo_async #(FIFO_DEPTH, DATA_WIDTH) dut (.*);

  // 1. Clock Generation (Mismatched Frequencies)
  initial wr_clk = 0;
  always #5 wr_clk = ~wr_clk; // 100MHz

  initial rd_clk = 0;
  always #12.5 rd_clk = ~rd_clk; // 40MHz

  // 2. Reference Model (Using bit for unsigned 32-bit matching)
  bit [DATA_WIDTH-1:0] ref_queue [$]; 

  // 3. Robust Monitor
  initial begin
    forever begin
      @(posedge rd_clk);
      if (valid && !rst) begin
        if (ref_queue.size() > 0) begin
          automatic bit [DATA_WIDTH-1:0] expected = ref_queue.pop_front();
          if (rdata !== expected)
            $display("[ERROR] %0t | Expected: %h, Got: %h", $time, expected, rdata);
          else
            $display("[PASS]  %0t | Data: %h matched", $time, rdata);
        end
      end
    end
  end

  // 4. Improved Write Task
  task write_fifo(input int n);
    for(int i = 0; i < n; i++) begin
      @(posedge wr_clk);
      if (!full) begin
        wr_en = 1;
        wdata = $urandom_range(0, 2**DATA_WIDTH-1);
        ref_queue.push_back(wdata);
      end else begin
        wr_en = 0;
        $display("[WR] FIFO Full - Skipping write %0d", i);
      end
    end
    @(posedge wr_clk) wr_en = 0;
  endtask

  // 5. Improved Read Task with Sync Patience
  task read_fifo(input int n);
    int timeout;
    for(int i = 0; i < n; i++) begin
      timeout = 0;
      while (empty && timeout < 150) begin // Increased timeout for sync
        rd_en = 0;
        @(posedge rd_clk);
        timeout++;
      end
      
      if (timeout >= 150) begin
        $display("[FATAL] Deadlock: Empty flag stuck high at %0t", $time);
        $finish;
      end
      
      rd_en = 1;
      @(posedge rd_clk);
      rd_en = 0;
    end
  endtask

  // 6. Main Test Sequence
  initial begin
    $dumpfile("fifo_async.vcd");
    $dumpvars(0, fifo_async_tb);
    
    // Reset
    rst = 1; #100; rst = 0; #100;

    $display("--- Test 1: Full/Empty Sequence ---");
    write_fifo(FIFO_DEPTH);
    repeat(10) @(posedge rd_clk); // Wait for sync
    read_fifo(FIFO_DEPTH);

    $display("--- Test 2: Simultaneous Stress ---");
    fork
      write_fifo(100);
      read_fifo(100);
    join

    #500;
    $display("--- FINAL: %0d items left in queue ---", ref_queue.size());
    $finish;
  end
endmodule
