# Supported Vector Instructions (CVE2 Decoder)

This document describes the vector and custom vector instructions **currently supported**
by the `cve2_rvx`, based strictly on enabled decode paths.
It supports a subset of RVV 1.0 plus some additional custom vector instruction.

Descriptions are intentionally concise and implementation-focused.

---

## 1. Vector Configuration Instructions (RV32VX)

| Instruction | Description |
|------------|-------------|
| `vsetvli` | Set vector length and vector type from scalar registers |
| `vsetivli` | Set vector length/type using immediate |
| `vsetvl` | Set vector length using rs1/rs2 |
| `vsetvlmax` | Set `vl = VLMAX` |
| `vsetvlkeep` | Keep current `vl` |

---

## 2. Vector Load Instructions

### Standard Vector Loads

| Instruction | Description |
|------------|-------------|
| `vle.v` | Unit-stride vector load |
| `vlse.v` | Constant-stride vector load |

**Supported EEW**
- 8-bit
- 16-bit
- 32-bit

---

### Custom Vector Loads (`VX`)

| Instruction | Description |
|------------|-------------|
| `vxle.v` | Custom unit-stride vector load |

> Only unit-stride is supported; no indexed or segmented loads.

---

## 3. Vector Store Instructions

### Standard Vector Stores

| Instruction | Description |
|------------|-------------|
| `vse.v` | Unit-stride vector store |
| `vsse.v` | Constant-stride vector store |

**Supported EEW**
- 8-bit
- 16-bit
- 32-bit

---

### Custom Vector Stores (`VX`)

| Instruction | Description |
|------------|-------------|
| `vxse.v` | Custom unit-stride vector store |

---

## 4. Vector Integer Arithmetic

### Addition / Subtraction

| Instruction | Description |
|------------|-------------|
| `vadd.vv` | Vector + vector |
| `vadd.vx` | Vector + scalar |
| `vadd.vi` | Vector + immediate |
| `vsub.vv` | Vector − vector |
| `vsub.vx` | Vector − scalar |

---

### Multiplication

| Instruction | Description |
|------------|-------------|
| `vmul.vv` | Vector × vector |
| `vmul.vx` | Vector × scalar |

---

## 5. Vector Logical Instructions

| Instruction | Description |
|------------|-------------|
| `vand.vv / vx / vi` | Bitwise AND |
| `vor.vv / vx / vi` | Bitwise OR |
| `vxor.vv / vx / vi` | Bitwise XOR |

---

## 6. Vector Min / Max

| Instruction | Description |
|------------|-------------|
| `vmin.vv / vx` | Signed minimum |
| `vminu.vv / vx` | Unsigned minimum |
| `vmax.vv / vx` | Signed maximum |
| `vmaxu.vv / vx` | Unsigned maximum |

---

## 7. Vector Multiply-Accumulate (Partial)

| Instruction | Description |
|------------|-------------|
| `vmacc.vv` | Multiply-accumulate (vector) |
| `vmacc.vx` | Multiply-accumulate (scalar) |

**Decoded but not implemented**
- `vnmsac`
- `vmadd`
- `vnmsub`

---

## 8. Vector Move / Merge

| Instruction | Description |
|------------|-------------|
| `vmv.v.v` | Vector move |
| `vmv.v.x` | Scalar → vector |
| `vmv.v.i` | Immediate → vector |
| `vmerge.vvm` | Masked merge |
| `vmerge.vxm` | Masked merge |
| `vmerge.vim` | Masked merge |

---

## 9. Vector Slide Instructions

| Instruction | Description |
|------------|-------------|
| `vslideup.vx` | Slide vector up |
| `vslideup.vi` | Slide up (immediate) |
| `vslidedown.vx` | Slide vector down |
| `vslidedown.vi` | Slide down (immediate) |

---

## 10. Custom Vector Instructions (`VX`)

The `VX` instruction set provides **custom-encoded vector operations** that reuse
scalar instruction formats instead of standard RVV encodings.

---

### 10.1 Motivation for Custom Vector Instructions

Custom vector instructions are introduced to support vector execution while:

- Avoiding the complexity of RVV 1.0 instruction encoding
- Reusing existing scalar decode and pipeline infrastructure
- Preserving a fixed 32-bit instruction width
- Minimizing hardware and decoder overhead

This design choice makes the vector extension **lightweight and implementation-driven**,
rather than architecturally RVV-compliant.

---

### 10.2 Operand Encoding Strategy

Unlike RVV, **vector register indices are not encoded in the instruction itself**.

Instead:
- The instruction is identified as a vector operation via `vx_instr`
- Vector register indices are stored **inside a scalar register**
- The scalar register `rs2` (`rf_rdata_b`) carries all vector operand indices

---

### 10.3 Vector Register Address Extraction

When `vx_instr` is asserted, vector register addresses are derived as follows:

```systemverilog
assign vrf_raddr_a  = (vx_instr) ? rf_rdata_b[20:16] : rf_raddr_a;
assign vrf_raddr_b  = (vx_instr) ? rf_rdata_b[12:8]  : rf_raddr_b;
assign vrf_waddr_wb = (vx_instr) ? rf_rdata_b[4:0]   : rf_waddr_wb;
