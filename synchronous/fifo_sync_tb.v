`timescale 1ns/1ps

module fifo_sync_tb;

  parameter FIFO_DEPTH = 8;
  parameter DATA_WIDTH = 32;

  reg clk;
  reg rst_n;
  reg cs;
  reg wr_en;
  reg rd_en;
  reg [DATA_WIDTH-1:0] data_in;

  wire [DATA_WIDTH-1:0] data_out;
  wire empty, full;
  wire overflow, underflow;
  wire almost_full, almost_empty;

  // DUT
  fifo_sync #(
    .FIFO_DEPTH(FIFO_DEPTH),
    .DATA_WIDTH(DATA_WIDTH)
  ) dut (
    .clk(clk),
    .rst_n(rst_n),
    .cs(cs),
    .wr_en(wr_en),
    .rd_en(rd_en),
    .data_in(data_in),
    .data_out(data_out),
    .empty(empty),
    .full(full),
    .overflow(overflow),
    .underflow(underflow),
    .almost_full(almost_full),
    .almost_empty(almost_empty)
  );

  // Clock
  always #5 clk = ~clk;

  // ---------------- REFERENCE MODEL ----------------
  integer ref_queue [$];  // dynamic queue

  // ---------------- TASKS ----------------

  task reset_fifo;
    begin
      rst_n = 0;
      cs = 0;
      wr_en = 0;
      rd_en = 0;
      data_in = 0;
      #10;
      rst_n = 1;
      cs = 1;
      $display("RESET DONE");
    end
  endtask

  task write_fifo(input integer n);
    integer i;
    begin
      $display("WRITE %0d elements", n);
      for(i = 0; i < n; i = i + 1) begin
        @(posedge clk);
        wr_en = 1;
        rd_en = 0;
        data_in = i + 1;

        if (!full) begin
          ref_queue.push_back(data_in);
        end
      end
      @(posedge clk);
      wr_en = 0;
    end
  endtask

  task read_fifo(input integer n);
    integer i;
    reg [DATA_WIDTH-1:0] expected;
    begin
      $display("READ %0d elements", n);
      for(i = 0; i < n; i = i + 1) begin
        @(posedge clk);
        wr_en = 0;
        rd_en = 1;

        if (!empty) begin
          expected = ref_queue.pop_front();

          @(posedge clk); // wait for data_out

          if (data_out !== expected) begin
            $display("ERROR: Expected %0d, Got %0d at time %0t",
                      expected, data_out, $time);
          end
          else begin
            $display("PASS: %0d", data_out);
          end
        end
      end
      @(posedge clk);
      rd_en = 0;
    end
  endtask

  task simultaneous_rw(input integer n);
    integer i;
    reg [DATA_WIDTH-1:0] expected;
    begin
      $display("SIMULTANEOUS READ & WRITE");

      for(i = 0; i < n; i = i + 1) begin
        @(posedge clk);
        wr_en = 1;
        rd_en = 1;
        data_in = $random;

        if (!full) begin
          ref_queue.push_back(data_in);
        end

        if (!empty) begin
          expected = ref_queue.pop_front();

          @(posedge clk);

          if (data_out !== expected) begin
            $display("ERROR: Expected %0d, Got %0d", expected, data_out);
          end
        end
      end

      @(posedge clk);
      wr_en = 0;
      rd_en = 0;
    end
  endtask

  task random_test(input integer n);
    integer i;
    reg [DATA_WIDTH-1:0] expected;
    begin
      $display("RANDOM TEST");

      for(i = 0; i < n; i = i + 1) begin
        @(posedge clk);

        wr_en = $random % 2;
        rd_en = $random % 2;
        data_in = $random;

        if (wr_en && !full) begin
          ref_queue.push_back(data_in);
        end

        if (rd_en && !empty) begin
          expected = ref_queue.pop_front();

          @(posedge clk);

          if (data_out !== expected) begin
            $display("ERROR: Expected %0d, Got %0d", expected, data_out);
          end
        end
      end

      wr_en = 0;
      rd_en = 0;
    end
  endtask

  // ---------------- TEST SEQUENCE ----------------

  initial begin
    clk = 0;

    // VCD dump
    $dumpfile("fifo.vcd");
    $dumpvars(0, fifo_tb);

    // 1. Reset
    reset_fifo();

    // 2. Sequential Write + Read
    write_fifo(FIFO_DEPTH);
    read_fifo(FIFO_DEPTH);

    // 3. Overflow Test
    write_fifo(FIFO_DEPTH + 2);

    // 4. Underflow Test
    read_fifo(FIFO_DEPTH + 2);

    // 5. Simultaneous Read/Write
    write_fifo(4);
    simultaneous_rw(10);

    // 6. Random Stress Test
    random_test(20);

    #100;
    $finish;
  end

endmodule
