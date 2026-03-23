module fifo_async #(
    parameter DATA_WIDTH = 32,
    parameter FIFO_DEPTH = 8 // Must be a power of 2
)(
    input wr_en, rd_en,
    input wr_clk, rd_clk,
    input rst,
    input [DATA_WIDTH-1:0] wdata,
    output reg [DATA_WIDTH-1:0] rdata,
    output full, empty,
    output reg overflow, underflow,
    output almost_full, almost_empty,
    output reg valid
);

    localparam ADDRESS_SIZE = $clog2(FIFO_DEPTH);

    // Pointers
    reg [ADDRESS_SIZE:0] wr_pointer_bin, rd_pointer_bin;
    reg [ADDRESS_SIZE:0] wr_pointer_g, rd_pointer_g;

    // Synchronizers
    reg [ADDRESS_SIZE:0] wr_ptr_g_sync1, wr_ptr_g_sync2;
    reg [ADDRESS_SIZE:0] rd_ptr_g_sync1, rd_ptr_g_sync2;

    // Memory
    reg [DATA_WIDTH-1:0] mem [0:FIFO_DEPTH-1];

    // Write
    always @(posedge wr_clk or posedge rst) begin
        if (rst) begin
            wr_pointer_bin <= 0;
            wr_pointer_g   <= 0;
            overflow       <= 0;
        end else begin
            if (wr_en && !full) begin
                mem[wr_pointer_bin[ADDRESS_SIZE-1:0]] <= wdata;
                wr_pointer_bin <= wr_pointer_bin + 1;
                wr_pointer_g <= (wr_pointer_bin + 1) ^ ((wr_pointer_bin + 1) >> 1);                 // Register Gray code to prevent glitches in sync
            end
            overflow <= wr_en && full;
        end
    end

    // Read
    always @(posedge rd_clk or posedge rst) begin
        if (rst) begin
            rd_pointer_bin <= 0;
            rd_pointer_g   <= 0;
            rdata          <= 0;
            underflow      <= 0;
            valid          <= 0;
        end else begin
            if (rd_en && !empty) begin
                rdata <= mem[rd_pointer_bin[ADDRESS_SIZE-1:0]];
                rd_pointer_bin <= rd_pointer_bin + 1;
                rd_pointer_g   <= (rd_pointer_bin + 1) ^ ((rd_pointer_bin + 1) >> 1);
                valid <= 1;
            end else begin
                valid <= 0;
            end
            underflow <= rd_en && empty;
        end
    end

    // Synchronizers : Sync wr_ptr to rd_clk
    always @(posedge rd_clk or posedge rst) begin
        if (rst) {wr_ptr_g_sync1, wr_ptr_g_sync2} <= 0;
        else     {wr_ptr_g_sync2, wr_ptr_g_sync1} <= {wr_ptr_g_sync1, wr_pointer_g};
    end

    // Synchronizers : Sync rd_ptr to wr_clk
    always @(posedge wr_clk or posedge rst) begin
        if (rst) {rd_ptr_g_sync1, rd_ptr_g_sync2} <= 0;
        else     {rd_ptr_g_sync2, rd_ptr_g_sync1} <= {rd_ptr_g_sync1, rd_pointer_g};
    end

    // Empty & Full Logic
    assign empty = (rd_pointer_g == wr_ptr_g_sync2);
    assign full  = (wr_pointer_g == {~rd_ptr_g_sync2[ADDRESS_SIZE:ADDRESS_SIZE-1], rd_ptr_g_sync2[ADDRESS_SIZE-2:0]});

    // Almost Flags

    // 1. Convert synced RD pointer to binary (in WR clock domain)
    reg [ADDRESS_SIZE:0] rd_ptr_bin_sync_wr;
    integer i;
    always @(*) begin
        rd_ptr_bin_sync_wr[ADDRESS_SIZE] = rd_ptr_g_sync2[ADDRESS_SIZE];
        for (i = ADDRESS_SIZE-1; i >= 0; i = i - 1)
            rd_ptr_bin_sync_wr[i] = rd_ptr_bin_sync_wr[i+1] ^ rd_ptr_g_sync2[i];
    end

    // 2. Convert synced WR pointer to binary (in RD clock domain)
    reg [ADDRESS_SIZE:0] wr_ptr_bin_sync_rd;
    integer j;
    always @(*) begin
        wr_ptr_bin_sync_rd[ADDRESS_SIZE] = wr_ptr_g_sync2[ADDRESS_SIZE]; // Use synchronized version
        for (j = ADDRESS_SIZE-1; j >= 0; j = j - 1)
            wr_ptr_bin_sync_rd[j] = wr_ptr_bin_sync_rd[j+1] ^ wr_ptr_g_sync2[j];
    end

    // 3. Flag Assignments
    assign almost_full  = (wr_pointer_bin - rd_ptr_bin_sync_wr) >= (FIFO_DEPTH - 1);
    assign almost_empty = (wr_ptr_bin_sync_rd - rd_pointer_bin) <= 1;

endmodule
