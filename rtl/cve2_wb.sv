// Copyright (c) 2025 Eclipse Foundation
// Copyright lowRISC contributors.
// Licensed under the Apache License, Version 2.0, see LICENSE for details.
// SPDX-License-Identifier: Apache-2.0

/**
 * Writeback passthrough
 *
 * The writeback stage is not present therefore this module acts as
 * a simple passthrough to write data direct to the register file.
 */

`include "prim_assert.sv"
`include "dv_fcov_macros.svh"

module cve2_wb #(
  parameter bit RV32VX = 1'b0
) (
  input  logic                     clk_i,
  input  logic                     rst_ni,
  input  logic                     en_wb_i,

  input  logic                     instr_is_compressed_id_i,
  input  logic                     instr_perf_count_id_i,

  output logic                     perf_instr_ret_wb_o,
  output logic                     perf_instr_ret_compressed_wb_o,

  input  logic [4:0]               rf_waddr_id_i,
  input  logic [31:0]              rf_wdata_id_i,
  input  logic                     rf_we_id_i,

  input  logic [31:0]              rf_wdata_lsu_i,
  input  logic                     rf_we_lsu_i,

  output logic [4:0]               rf_waddr_wb_o,
  output logic [31:0]              rf_wdata_wb_o,
  output logic                     rf_we_wb_o,
  
  // Vector extension
  //input logic                      vrf_we_id_i,
  input logic [31:0]               vrf_wdata_id_i,
  input logic [31:0]               vrf_wdata_lsu_i,
  input logic                      vrf_is_mem_i,
  //output logic                     vrf_we_wb_o,
  output logic [31:0]              vrf_wdata_wb_o,
  // write data for vset{i}vl{i}
  input logic [31:0]               vl_wdata_i,
  input logic                      vl_we_i,

  input logic                      lsu_resp_valid_i,
  input logic                      lsu_resp_err_i
);

  import cve2_pkg::*;

  // 0 == RF write from ID
  // 1 == RF write from LSU
  // 2 == RF write from VL (RV32VX only)
  logic [31:0] rf_wdata_wb_mux    [3]; // idx 2 only used for RV32VX
  logic [2:0]  rf_wdata_wb_mux_we;

    // without writeback stage just pass through register write signals
    assign rf_waddr_wb_o         = rf_waddr_id_i;
    assign rf_wdata_wb_mux[0]    = rf_wdata_id_i;
    assign rf_wdata_wb_mux_we[0] = rf_we_id_i;

    // Increment instruction retire counters for valid instructions which are not lsu errors.
    assign perf_instr_ret_wb_o                 = instr_perf_count_id_i & en_wb_i &
                                                 ~(lsu_resp_valid_i & lsu_resp_err_i);
    assign perf_instr_ret_compressed_wb_o      = perf_instr_ret_wb_o & instr_is_compressed_id_i;

  assign rf_wdata_wb_mux[1]    = rf_wdata_lsu_i;

  if (RV32VX) begin : rv32vx_wb_block
    // Write data for vset{i}vl{i}
    assign rf_wdata_wb_mux[2]    = vl_wdata_i;
    assign rf_wdata_wb_mux_we[2] = vl_we_i;

    // Vector extension
    // later I will extend it with a multiplexer for load data (similar to the RF one above)
    //assign vrf_we_wb_o    = vrf_we_id_i;
    assign vrf_wdata_wb_o = vrf_is_mem_i ? vrf_wdata_lsu_i : vrf_wdata_id_i;
    assign rf_wdata_wb_mux_we[1] = rf_we_lsu_i & ~vrf_is_mem_i;

  end else begin : no_rv32vx_wb_block
    assign rf_wdata_wb_mux[2]    = 32'b0;
    assign rf_wdata_wb_mux_we[2] = 1'b0;

    //assign vrf_we_wb_o    = 1'b0;
    assign vrf_wdata_wb_o = 32'b0;
    assign rf_wdata_wb_mux_we[1] = rf_we_lsu_i;
  end

  // RF write data can come from ID results (all RF writes that aren't because of loads will come
  // from here) or the LSU (RF writes for load data)
  assign rf_wdata_wb_o = ({32{rf_wdata_wb_mux_we[0]}} & rf_wdata_wb_mux[0]) |
                         ({32{rf_wdata_wb_mux_we[1]}} & rf_wdata_wb_mux[1]) |
                         ({32{rf_wdata_wb_mux_we[2]}} & rf_wdata_wb_mux[2]);
  assign rf_we_wb_o    = |rf_wdata_wb_mux_we;

  `ASSERT(RFWriteFromOneSourceOnly, $onehot0(rf_wdata_wb_mux_we))
endmodule
