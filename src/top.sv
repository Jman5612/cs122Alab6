module top (
    input  CLK,

    output LCD_CLK,
    output LCD_DEN,
    output [4:0] LCD_R,
    output [5:0] LCD_G,
    output [4:0] LCD_B,

    input  SPI_CS,
    input  SPI_SCLK,
    input  SPI_MOSI
);


    
    localparam H_ACTIVE = 480;
    localparam H_TOTAL  = 525;
    localparam V_ACTIVE = 272;
    localparam V_TOTAL  = 285;

    
    reg [9:0] x_value;
    reg [8:0] y_value;

    always @(posedge CLK) begin
        if (x_value == H_TOTAL - 1) begin
            x_value <= 0;
            if (y_value == V_TOTAL - 1)
                y_value <= 0;
            else
                y_value <= y_value + 1;
        end else begin
            x_value <= x_value + 1;
        end
    end


    
    assign LCD_CLK = CLK;
    wire active = (x_value < H_ACTIVE) && (y_value < V_ACTIVE);
    assign LCD_DEN = active;


wire [9:0] x_next = (x_value == H_TOTAL - 1) ? 10'd0 : x_value + 10'd1;
    wire [8:0] y_next = (x_value == H_TOTAL - 1) ?
                            ((y_value == V_TOTAL - 1) ? 9'd0 : y_value + 9'd1)
                            : y_value;
    wire [7:0] raddr = {y_next[3:0], x_next[3:0]};



    logic sclk_r1, sclk_r2;
    logic mosi_r1, mosi_r2;
    logic cs_r1,   cs_r2;

    always_ff @(posedge CLK) begin
        sclk_r1 <= SPI_SCLK; sclk_r2 <= sclk_r1;
        mosi_r1 <= SPI_MOSI; mosi_r2 <= mosi_r1;
        cs_r1   <= SPI_CS;   cs_r2   <= cs_r1;
    end

    wire sclk_rising = (sclk_r1 && !sclk_r2);
    wire cs_active   = !cs_r2;

    logic [3:0]  bit_count;
    logic [15:0] shift_reg;
    logic        we;
    logic [7:0]  waddr;
    logic [15:0] wdata;

    always_ff @(posedge CLK) begin
        we <= 0;  

        if (!cs_active) begin
            bit_count <= 0;
            shift_reg <= 0;
        end else if (sclk_rising) begin
            shift_reg <= {shift_reg[14:0], mosi_r2};
            bit_count <= bit_count + 1;

            if (bit_count == 15) begin
                wdata     <= {shift_reg[14:0], mosi_r2};
                we        <= 1;
                waddr     <= waddr + 1;
                bit_count <= 0;
            end
        end
    end

    
    wire [15:0] pixel;

    dp_buffer sprite_mem (
        .clk   (CLK),
        .we    (we),
        .waddr (waddr),
        .wdata (wdata),
        .raddr (raddr),
        .rdata (pixel)
    );


    assign LCD_R = active ? pixel[15:11] : 5'd0;
    assign LCD_G = active ? pixel[10:5]  : 6'd0;
    assign LCD_B = active ? pixel[4:0]   : 5'd0;















endmodule