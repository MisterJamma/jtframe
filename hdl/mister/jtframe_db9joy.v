//============================================================================
//  JTFRAME by Jose Tejada Gomez. Twitter: @topapate
//
//  This program is free software; you can redistribute it and/or modify it
//  under the terms of the GNU General Public License as published by the Free
//  Software Foundation; either version 2 of the License, or (at your option)
//  any later version.
//
//  This program is distributed in the hope that it will be useful, but WITHOUT
//  ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
//  FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License for
//  more details.
//
//  You should have received a copy of the GNU General Public License along
//  with this program; if not, write to the Free Software Foundation, Inc.,
//  51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA.
//============================================================================

// This code comes from the DB9 team. I have only refactored it and renamed a couple of things.

module jtframe_db9joy(
    input               clk,

    input        [ 2:0] JOY_FLAG,
    input        [31:0] Joystick_0_USB,
    input        [31:0] Joystick_1_USB,

    output reg   [31:0] joystick_0,
    output reg   [31:0] joystick_1,
    output reg   [ 5:0] joy_raw,

    output reg          USER_OSD,
    output       [ 1:0] USER_MODE,
    input        [ 7:0] USER_IN,
    output       [ 7:0] USER_OUT
);

wire  [15:0] JOYDB9MD_1, JOYDB9MD_2, JOYDB15_1, JOYDB15_2;
wire         JOY_CLK, JOY_LOAD, JOY_SPLIT, JOY_MDSEL;
wire  [ 5:0] JOY_MDIN  = JOY_FLAG[2] ? {USER_IN[6],USER_IN[3],USER_IN[5],USER_IN[7],USER_IN[1],USER_IN[2]} : ~5'd0;
wire         JOY_DATA  = JOY_FLAG[1] ? USER_IN[5] : 1'd1;
assign       USER_OUT  = JOY_FLAG[2] ? {3'b111,JOY_SPLIT,3'b111,JOY_MDSEL} : JOY_FLAG[1] ? {6'b111111,JOY_CLK,JOY_LOAD} : ~8'd0;
assign       USER_MODE = JOY_FLAG[2:1];

// Sample: 2 fire buttons + Start 1/2 players + Coin
// CO S2 S1 F2 F1 U D L R

reg  [15:0] joydb_1, joydb_2;
reg         joydb_1ena, joydb_2ena;

always @(posedge clk) begin
    USER_OSD   <= joydb_1[10] & joydb_1[6];
    joy_raw    <= joydb_1[5:0] | joydb_2[5:0];
    joydb_1    <= JOY_FLAG[2] ? JOYDB9MD_1 : JOY_FLAG[1] ? JOYDB15_1 : 16'd0;
    joydb_2    <= JOY_FLAG[2] ? JOYDB9MD_2 : JOY_FLAG[1] ? JOYDB15_2 : 16'd0;
    joydb_1ena <= |JOY_FLAG[2:1];
    joydb_2ena <= |JOY_FLAG[2:1] & JOY_FLAG[0];
    joystick_0 <= joydb_1ena ? {joydb_1[11]|(joydb_1[10]&joydb_1[5]),joydb_1[9],joydb_1[10],joydb_1[5:0]} : Joystick_0_USB;
    joystick_1 <= joydb_2ena ? {joydb_2[11]|(joydb_2[10]&joydb_2[5]),joydb_2[10],joydb_2[9],joydb_2[5:0]} : joydb_1ena ? Joystick_0_USB : Joystick_1_USB;
end

//----BA 9876543210
//----MS ZYXCBAUDLR
joy_db9md joy_db9md
(
  .clk       ( clk        ), //40-50MHz
  .joy_split ( JOY_SPLIT  ),
  .joy_mdsel ( JOY_MDSEL  ),
  .joy_in    ( JOY_MDIN   ),
  .joystick1 ( JOYDB9MD_1 ),
  .joystick2 ( JOYDB9MD_2 )
);

//----BA 9876543210
//----LS FEDCBAUDLR
joy_db15 joy_db15
(
  .clk       ( clk       ), //48MHz
  .JOY_CLK   ( JOY_CLK   ),
  .JOY_DATA  ( JOY_DATA  ),
  .JOY_LOAD  ( JOY_LOAD  ),
  .joystick1 ( JOYDB15_1 ),
  .joystick2 ( JOYDB15_2 )
);

endmodule