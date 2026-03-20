module fifo_sync
  #( parameter FIFO_DEPTH = 8,      // Total number of entries in FIFO
     parameter DATA_WIDTH = 32      // Bit-width of each data element
   )
  ( input clk,                      // System clock
    input rst_n,                    // Active-low asynchronous reset
    input cs,                       // Chip select (enables FIFO operations)
    input wr_en,                    // Write enable signal
    input rd_en,                    // Read enable signal
    input [DATA_WIDTH-1:0] data_in, // Input data to be written into FIFO
    output reg [DATA_WIDTH-1:0] data_out, // Output data read from FIFO
    output empty,                  // High when FIFO is empty
    output full,                   // High when FIFO is full
    output reg overflow, underflow, // Error flags for invalid write/read
    output almost_full, almost_empty // Threshold indicators
  );
  
  // Number of bits required to index FIFO_DEPTH locations
  localparam FIFO_DEPTH_LOG = $clog2(FIFO_DEPTH);  
  
  // Memory array to store FIFO data
  reg [DATA_WIDTH-1:0] fifo [0:FIFO_DEPTH-1]; 
  
  // Write and Read pointers (extra MSB used for full/empty detection)
  // fifo_count keeps track of number of elements currently in FIFO
  reg [FIFO_DEPTH_LOG : 0] write_pointer, read_pointer, fifo_count; 
  
  // ---------------- WRITE LOGIC ----------------
  // Handles data insertion into FIFO
  always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin 
      write_pointer <= 0;   // Reset write pointer
      overflow <= 0;        // Clear overflow flag
    end
    else if(cs && wr_en) begin
      if(!full) begin
        // Write data and increment pointer
        fifo[write_pointer[FIFO_DEPTH_LOG-1:0]] <= data_in;
        write_pointer <= write_pointer + 1'b1;
        overflow <= 0;
      end 
      else begin
        // Write attempted when FIFO is full
        overflow <= 1;
      end
    end
    else begin
      overflow <= 0; // Default: no overflow
    end
  end
  
  // ---------------- READ LOGIC ----------------
  // Handles data retrieval from FIFO
  always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin 
      read_pointer <= 0;    // Reset read pointer
      data_out <= 0;        // Clear output data
      underflow <= 0;       // Clear underflow flag
    end
    else if (cs && rd_en) begin
      if(!empty) begin
        // Read data and increment pointer
        data_out <= fifo[read_pointer[FIFO_DEPTH_LOG-1:0]];
        read_pointer <= read_pointer + 1'b1;
        underflow <= 0;
      end 
      else begin
        // Read attempted when FIFO is empty
        underflow <= 1;
      end
    end  
    else begin
      underflow <= 0; // Default: no underflow
    end
  end
  
  // ---------------- FIFO COUNT LOGIC ----------------
  // Tracks number of elements in FIFO
  always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin 
      fifo_count <= 0;
    end
    else begin
      case({cs && wr_en && !full, cs && rd_en && !empty})
        2'b10 : fifo_count <= fifo_count + 1; // Only write
        2'b01 : fifo_count <= fifo_count - 1; // Only read
        2'b11 : fifo_count <= fifo_count;     // Simultaneous read & write
        default : fifo_count <= fifo_count;   // No operation
      endcase
    end 
  end
  
  // ---------------- STATUS FLAGS ----------------
  
  // FIFO is empty when both pointers are equal
  assign empty = (read_pointer == write_pointer);
  
  // FIFO is full when MSBs differ but lower bits are equal
  assign full = (read_pointer[FIFO_DEPTH_LOG] != write_pointer[FIFO_DEPTH_LOG]) && 
                (read_pointer[FIFO_DEPTH_LOG-1:0] == write_pointer[FIFO_DEPTH_LOG-1:0]);
  
  // Threshold indicators
  assign almost_full  = (fifo_count == FIFO_DEPTH - 1);
  assign almost_empty = (fifo_count == 1);

endmodule
