module div #(parameter WIDTH=8) (
    input wire logic clk,
    input wire logic start,          // start signal
    input wire logic rst,           //Reset Signal
    output     reg busy,           // Flag to show when to check for result in simulation
    output     reg valid,          // quotient and remainder are valid
    output     reg dbz,            // divide by zero flag
    input wire logic [WIDTH-1:0] dividend,  // dividend
    input wire logic [WIDTH-1:0] y,  // divisor
    output reg [3:0] Anode_Activate, // anode signals of the 7-segment LED display
    output reg [6:0] LED_out
//    output     reg [WIDTH-1:0] q,  // quotient
//    output     reg [WIDTH-1:0] r   // remainder
    );
    logic [7:0] q,r;
    logic [WIDTH-1:0] y1;            // copy of divisor
    logic [WIDTH-1:0] q1, q1_next;   // intermediate quotient
    logic [WIDTH:0] ac, ac_next;     // accumulator (1 bit wider)
    logic [$clog2(WIDTH)-1:0] i;     // iteration counter
  Seven_segment_LED_Display_Controller disp(.clock_100Mhz(clk), .reset(rst), .Anode_Activate(Anode_Activate), .LED_out(LED_out), .quotient(q), .remainder(r));  
//Combinatorial operations
    always_comb begin
        if (ac >= {1'b0,y1}) begin
            ac_next = ac - y1;
            {ac_next, q1_next} = {ac_next[WIDTH-1:0], q1, 1'b1};
        end else begin
            {ac_next, q1_next} = {ac, q1} << 1;
        end
    end
//Time bound clock based operations: Sequential
    always_ff @(posedge clk or posedge rst) begin
        //Initialising the division process, loading accumulator with Dividend (Number being divided) and setting necessary flags
        if (rst) begin
        busy <= 1'b0;
        valid <= 1'b0;
        dbz <= 1'b0;
        q <= {WIDTH{1'b0}};
        r <= {WIDTH{1'b0}};
        end
        else if (start) begin
            valid <= 0;
            i <= 0;
            if (y == 0) begin  // catch divide by zero
                busy <= 0;
                dbz <= 1;
            end else begin  // initialize values
                busy <= 1;
                dbz <= 0;
                y1 <= y;
                {ac, q1} <= {{WIDTH{1'b0}}, dividend, 1'b0};
            end
        //None initial cycle behavior
        end else if (busy) begin
            if (i == WIDTH-1) begin  // Calculation done
                busy <= 0;
                valid <= 1;
                q <= q1_next;
                r <= ac_next[WIDTH:1];  // undo final shift already done in Combinatorial block
            end else begin  // next iteration
                i <= i + 1;
                ac <= ac_next;
                q1 <= q1_next;
            end
        end
    end
endmodule