// SPDX-FileCopyrightText: 2020 Efabless Corporation
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//      http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
// SPDX-License-Identifier: Apache-2.0


/*
 *-------------------------------------------------------------
 *
 * user_proj_example
 *
 * This is an example of a (trivially simple) user project,
 * showing how the user project can connect to the logic
 * analyzer, the wishbone bus, and the I/O pads.
 *
 * This project generates an integer count, which is output
 * on the user area GPIO pads (digital output only).  The
 * wishbone connection allows the project to be controlled
 * (start and stop) from the management SoC program.
 *
 * See the testbenches in directory "mprj_counter" for the
 * example programs that drive this user project.  The three
 * testbenches are "io_ports", "la_test1", and "la_test2".
 *
 *-------------------------------------------------------------
 */

module user_proj_example #(
    parameter BITS = 32,
    parameter DELAYS=10
)(
`ifdef USE_POWER_PINS
    inout vccd1,	// User area 1 1.8V supply
    inout vssd1,	// User area 1 digital ground
`endif

    // Wishbone Slave ports (WB MI A)
    input wb_clk_i,
    input wb_rst_i,
    input wbs_stb_i,
    input wbs_cyc_i,
    input wbs_we_i,
    input [3:0] wbs_sel_i,
    input [31:0] wbs_dat_i,
    input [31:0] wbs_adr_i,
    output wbs_ack_o,
    output [31:0] wbs_dat_o,

    // Logic Analyzer Signals
    input  [127:0] la_data_in,
    output [127:0] la_data_out,
    input  [127:0] la_oenb,

    // IOs
    input  [`MPRJ_IO_PADS-1:0] io_in,
    output [`MPRJ_IO_PADS-1:0] io_out,
    output [`MPRJ_IO_PADS-1:0] io_oeb,

    // IRQ
    output [2:0] irq
);
    wire clk;
    wire rst;

    wire [`MPRJ_IO_PADS-1:0] io_in;
    wire [`MPRJ_IO_PADS-1:0] io_out;
    wire [`MPRJ_IO_PADS-1:0] io_oeb;
    reg [3:0] delay_cnt;
    wire Access_BRAM_Flag;

    //clk & rst
    assign clk = wb_clk_i;
    assign rst = wb_rst_i;
    //Block RAM
    wire [3:0] BRAM_WE;
    wire [31:0] BRAM_Di0;
    wire [31:0] BRAM_Do0;
    wire [31:0] BRAM_A0;
    wire BRAM_EN0;

    //Address Decoding
    assign Access_BRAM_Flag = wbs_adr_i >= 32'h3800_0000 && wbs_adr_i <= 32'h3840_0000;
    assign BRAM_A0 = (Access_BRAM_Flag) ? ((wbs_adr_i - 32'h3800_0000) >> 2): 0;
    assign BRAM_WE = (Access_BRAM_Flag && wbs_we_i && wbs_stb_i) ? 4'b1111 : 4'b0000;
    assign BRAM_Di0 = wbs_dat_i;
    assign BRAM_EN0 = wbs_stb_i && wbs_cyc_i;
    //Wishbone output
    always@(posedge clk or posedge rst) begin
        if(rst)
            delay_cnt <= 0;
        else if(delay_cnt == 10)
            delay_cnt <= 0;
        else if(wbs_stb_i && wbs_cyc_i && !wbs_we_i) //read operation
            delay_cnt <= delay_cnt + 1;
    end

    assign wbs_ack_o = (wbs_stb_i && wbs_cyc_i && wbs_we_i)? 1'b1: (delay_cnt == 10) ? 1'b1 : 1'b0;
    assign wbs_dat_o = Access_BRAM_Flag ? BRAM_Do0 : 32'd0;
    

    bram user_bram (
        .CLK(clk),
        .WE0(BRAM_WE),
        .EN0(BRAM_EN0),
        .Di0(BRAM_Di0),
        .Do0(BRAM_Do0),
        .A0(BRAM_A0)
    );

endmodule



`default_nettype wire
