`default_nettype none   //do not allow undeclared wires

module mmcm_reconfig (
    input  wire       clk,
    output wire [4:0] led,
    output wire [3:0] debug,
    output wire       clkout
    );

    wire pll_feedback;
    wire pll_clk;
    wire mmcm_clk;
    wire locked;

    PLLE2_ADV #(
        .CLKFBOUT_MULT(8'd20),
        .CLKIN1_PERIOD(20.0),
        .CLKOUT0_DIVIDE(8'd20),
        .CLKOUT0_PHASE(1'd0),
        .DIVCLK_DIVIDE(1'd1),
        .REF_JITTER1(0.01),
        .STARTUP_WAIT("FALSE")
    ) pll_inst (
        .CLKFBIN(pll_feedback),
        .CLKIN1(clk),
        .PWRDWN(1'b0),
        .RST(1'b0),
        .CLKFBOUT(pll_feedback),
        .CLKOUT0(pll_clk),
        .LOCKED(locked)
    );

    wire reconfig_ready;
    wire reconfig_done;
    reg  start_reconfig;
    reg  [5:0] half_period;
    wire mmcm_locked;
    wire [3:0] mmcm_debug;

    xilinx7_reconfig reconfig (
        .refclk(pll_clk),
        .rst(~locked),
        .outclk_0(mmcm_clk),
        .locked(mmcm_locked),
        .debug(mmcm_debug),

        // CLKOUT0
        .CLKOUT0_HIGH_TIME  (half_period),
        .CLKOUT0_LOW_TIME   (half_period),
        .CLKOUT0_PHASE_MUX  (3'd0),
        .CLKOUT0_FRAC       (3'd0),
        .CLKOUT0_FRAC_EN    (1'b0),
        .CLKOUT0_WF_R       (1'b0),
        .CLKOUT0_EDGE       (1'b0),
        .CLKOUT0_NO_COUNT   (1'b0),
        .CLKOUT0_DELAY_TIME (6'b0),

        // CLKFBOUT
        .CLKFBOUT_HIGH_TIME  (6'd10),
        .CLKFBOUT_LOW_TIME   (6'd10),
        .CLKFBOUT_PHASE_MUX  (3'd0),
        .CLKFBOUT_FRAC       (3'd0),
        .CLKFBOUT_FRAC_EN    (1'b0),
        .CLKFBOUT_WF_R       (1'b0),
        .CLKFBOUT_EDGE       (1'b0),
        .CLKFBOUT_NO_COUNT   (1'b0),
        .CLKFBOUT_DELAY_TIME (6'b0),

        // DIVCLK
        .DIVCLK_HIGH_TIME (6'b1),
        .DIVCLK_LOW_TIME  (6'b1),
        .DIVCLK_EDGE      (1'b0),
        .DIVCLK_NO_COUNT  (1'b1),

        // activation
        .ready(reconfig_ready),
        .start_reconfig(start_reconfig),
        .reconfig_done(reconfig_done)
    );

    assign clkout = mmcm_clk;
    reg [25:0] count   = 0;
    reg [24:0] r_count = 0;

    always @(posedge(pll_clk)) begin
        count <= count + 1;

        if (~locked) half_period <= 6'd10;
        else if (reconfig_ready & (count == 25'hffffff)) begin
            half_period <= half_period + 1;
        end

        start_reconfig <= reconfig_ready & (count == 26'h2000000);
    end

    assign led[1] = ~r_count[24];
    assign led[2] = ~start_reconfig;
    assign led[3] = ~mmcm_locked;
    assign led[4] = ~reconfig_ready;
    
    assign led[0] = ~count[25];
    assign debug = mmcm_debug;

    always @(posedge(mmcm_clk)) r_count <= r_count + 1;

endmodule
