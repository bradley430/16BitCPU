module adder(input logic [15:0] a, b,
             input logic cin,
             output logic [15:0] sum,
             output logic cout
);

    assign {cout, sum} = a + b + cin;

endmodule

module alu(input logic [15:0] a, b,
           input logic [2:0] ALUControl,
           output logic [15:0] ALUResult,
           output logic [3:0] ALUFlags
);

    logic [15:0] adderResult, condb;
    logic negative, zero, carry, overflow, rawCarry;

    assign condb = (ALUControl == 3'b001) ? ~b : b;

    adder add(a, condb, (ALUControl == 3'b001) ? 1 : 0, adderResult, rawCarry);

    always_comb begin : ALU
        
        case (ALUControl)
            3'b000: ALUResult = adderResult;
            3'b001: ALUResult = adderResult;
            3'b010: ALUResult = a & b;
            3'b011: ALUResult = a | b;
            3'b100: ALUResult = a ^ b;
            3'b101: ALUResult = ~b;
            3'b110: ALUResult = b;
            default: ALUResult = adderResult;      

        endcase

    end

    assign negative = ALUResult[15];
    assign zero = (ALUResult[15:0] == 0);
    assign carry = (ALUControl[2:1] == 2'b00) & rawCarry;
    assign overflow = (ALUControl[2:1] == 2'b00) & (a[15] ^ ALUresult[15]) & !(a[15] ^ b[15] ^ ALUControl[0]);

    assign ALUFlags = {negative, zero, carry, overflow};
        
endmodule

module extend(input logic [8:0] offset,
              output logic [15:0] extended
);

    assign extended = {7{offset[8]}, offset};

endmodule

module shifter(input logic signed [15:0] val, 
               input logic [15:0] shamt,
               input logic [1:0] shiftFunction,
               output logic [15:0] shifterResult
);

    always_comb begin : Shifter

        case(shiftFunction)

            2'b00: shifterResult = val << shamt;
            2'b01: shifterResult = val >> shamt;
            2'b10: shifterResult = val >>> shamt;
            2'b11: shifterResult = (val >> shamt) | (val << (5'b10000 - shamt));
            default: shifterResult = val;

        endcase
        
    end

endmodule

module mux2 (
    input logic [15:0] a, b,
    input logic s,
    output logic [15:0] selected
);

    assign selected = s ? a : b; //take a if s, take b if not s
    
endmodule

module regFile (
    input logic [2:0] address1, address2, writeAddress,
    input logic [15:0] writeData, r7,
    input logic clk, registerWrite, reset,
    output logic [15:0] read1, read2, read3
);
    logic[15:0] rf[6:0];
    logic [15:0] R7 = r7;

    always_ff @(posedge clk) begin : Write

        if(reset) for(int i = 0; i < 7; i++) rf[i] <= 16'b0;

        else if(registerWrite & writeAddress != 3'b111) rf[writeAddress] <= writeData;
        
    end
    
    assign read1 = (address1 == 3'b111) ? R7 : rf[address1];
    assign read2 = (address2 == 3'b111) ? R7 : rf[address2];
    assign read3 = rf[writeAddress];

endmodule

module instructionMemory (
    input logic[15:0] address,
    output logic [15:0] instruction
);

    logic[15:0] MEM[65535:0];

    initial $readmemh("memfile.dat", MEM);

    assign instruction = MEM[address];
    
endmodule

module dataMemory (
    input logic[15:0] address, writeData,
    input logic clk, memoryWrite,
    output logic[15:0] read
);

    logic[15:0] RAM[65535:0];

    assign read = RAM[address];

    always_ff @(posedge clk) begin : Write

        if(memoryWrite) RAM[address] <= writeData;
        
    end
    
endmodule

module fflop #(
    WIDTH = 16
) (
    input logic [15:0] d,
    input logic clk, reset, 
    output logic [15:0] q
);

    always_ff @(posedge clk) begin : FlipFlop

        if(reset) q <= 0;

        else if(en) q <= d;
        
    end
    
endmodule

module pcRegister (
    input logic clk, reset,
    input logic [15:0] nextPC,
    output logic [15:0] PC
);

    fflop#(16) pcReg(nextPC, clk, reset, PC);
    
endmodule

module spRegister (
    input logic clk, reset, 
    input logic [15:0] nextSP,
    output logic [15:0] SP
);

    fflop#(16) spReg(nextSP, clk, reset, SP);
    
endmodule

module controlUnit (
    input logic clk, reset,
    input logic [15:0] instr,
    input logic [3:0] flags,
    output logic branch, shiftOp, memToReg, push, pop, registerWrite, memoryWrite, flagWrite, halt, linkReturn,
    output logic [1:0] regSrc, writeReg, shiftFunction, 
    output logic [2:0] aluFunction
);
    


endmodule

module decoder (
    input logic [1:0] opCode, functSpecial,
    input logic [3:0] functDP, 
    input logic [2:0] destinationReg, sourceReg,
    input logic memory, link, 
    output logic pbranch, pshiftOp, pmemToReg, ppush, ppop, pregisterWrite, pmemoryWrite, pflagWrite, phalt, plinkReturn,
    output logic [1:0] pregSrc, pwriteReg, pshiftFunction,
    output logic [2:0] aluFunction
);

    logic [17:0] controls;

    //linkReturn is handled separately because it depends on destination and source registers
    //control order is branch:regSrc:shiftop:memtoreg:writereg:push:pop:registerwrite:memorywrite:flagwrite:shiftfunction:halt:alufunction

    always_comb begin : decoder

        if(opCode == 2'b00) begin

            case (functDP)

                4'b0000: controls = 18'b000000000100000000;
                4'b0001: controls = 18'b000000000100000001;
                4'b0010: controls = 18'b000000000100000010;
                4'b0011: controls = 18'b000000000100000011;
                4'b0100: controls = 18'b000000000100000100;
                4'b0101: controls = 18'b000000000100000101;
                4'b0110: controls = 18'b000000000001000001;
                4'b0111: controls = 18'b000100000100000000;
                4'b1000: controls = 18'b000100000100010000;
                4'b1001: controls = 18'b000100000100100000;
                4'b1010: controls = 18'b000100000100110000;
                4'b1011: controls = 18'b000000000100000110;
                4'b1100: controls = 18'b000000000101000000;
                4'b1101: controls = 18'b000000000101000001;
                4'b1110: controls = 18'b000000100100000000;

                default: controls = 18'b000000000000000000;
            endcase

        end else if (opCode == 2'b01) begin

            case (memory)
                
                1'b0: controls = 18'b001010000100000000;
                1'b1: controls = 18'b001000000010000000;

                default: controls = 18'b000000000000000000;
            endcase
            
        end else if(opCode == 2'b10) begin

            case (link)
                
                1'b0: controls = 18'b100000000000000000;
                1'b1: controls = 18'b110001000100000000;

                default: controls = 18'b000000000000000000;
            endcase

        end else begin

            case (functSpecial)
                
                2'b00: controls = 18'b000000000000001000;
                2'b01: controls = 18'b000000000000000000;
                2'b10: controls = 18'b000000010010000000;
                2'b11: controls = 18'b000010001100000000;

                default: controls = 18'b000000000000000000;
            endcase

        end
        
        plinkReturn = ({opCode, functDP, destinationReg, sourceReg} == 12'b001011111110);

        {pbranch, pregSrc, pshiftOp, pmemToReg, pwriteReg, ppush, ppop, pregisterWrite, pmemoryWrite, pflagWrite, pshiftFunction, phalt, aluFunction} = controls;

    end

endmodule


