**`16 Bit CPU Project`**  
`Bradley Yao`

**`Instruction Set Architecture (ISA)`**

**`8 Registers, 2-Operand Format`**

- **`15-12`**`: Condition bits`  
  - `Identical to ARM condition set`  
- **`11-10`**`: Operation code bits`  
  - **`00`** `- Data processing`  
  - **`01`** `- Memory`  
  - **`10`** `- Branch`  
  - **`11`** `- Special`  
- **`9-0`**`: Class specific bits`

**`Data Processing Bits`**

- **`9-6`**`: Function`   
- **`5-3`**`: Destination Register/First Operand (Rd)`  
- **`2-0`**`: Second Operand (Rm)`


  
**`Memory Bits`**

- **`9`**`: Load/Store Bit`  
  - **`0`**`: Load (LDR)`  
  - **`1`**`: Store (STR)`  
- **`8-6`**`: Destination Register (Rd)`  
- **`5-3`**`: Source Register (Rm)`  
- **`2-0`**`: Offset Register (Roff)`  
  - `Interpreted as two’s complement (signed)`

**`Branch Bits`**

- **`9`**`: B/BL Bit`  
  - **`0`**`: Branch (B)`  
  - **`1`**`: Branch and Link (BL)`  
- **`8-0`**`: Offset`  
  - `Interpreted as two’s complement (signed)`  
  - `PC-relative`

**`Special Bits`**

- **`9-8`**`: Function`  
- **`7-6`**`: XX`  
- **`5-3`**`: Destination/Source Register (Rd)`  
- **`2-0`**`: XXX`

