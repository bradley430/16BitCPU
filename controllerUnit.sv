module controlUnit (
    input logic clk, reset,
    input logic [15:0] instr,
    input logic [3:0] flags,
    output logic branch, shiftOp, memToReg, push, pop, registerWrite, memoryWrite, flagWrite, halt, linkReturn,
    output logic [1:0] regSrc, writeReg, shiftFunction, 
    output logic [2:0] aluFunction
);
    
    logic [3:0] cond;
    logic [1:0] opCode;

    assign cond = instr[15:12];
    assign opCode = instr[11:10];

    logic pbranch, ppush, ppop, pregisterWrite, pmemoryWrite, pflagWrite, phalt, plinkReturn;

    decoder dec (.opCode(opCode), .functSpecial(instr[9:8]), .functDP(instr[9:6]), .destinationReg(instr[5:3]), .sourceReg(instr[2:0]), .memory(instr[9]), .link(instr[9]), 
                 .plinkReturn(plinkReturn), .pbranch(pbranch), .shiftOp(shiftOp), .memToReg(memToReg), .ppush(ppush), .ppop(ppop), .pregisterWrite(pregisterWrite), .pmemoryWrite(pmemoryWrite), .pflagWrite(pflagWrite), .phalt(phalt),
                 .regSrc(regSrc), .writeReg(writeReg), .shiftFunction(shiftFunction), .aluFunction(aluFunction));

    condLogic conditionals (.clk(clk), .reset(reset), .plinkReturn(plinkReturn), .pregisterWrite(pregisterWrite), .pmemoryWrite(pmemoryWrite), .phalt(phalt), .ppush(ppush), .ppop(ppop), .pflagWrite(pflagWrite), .pbranch(pbranch), 
                            .ALUFlags(flags), .cond(cond), .linkReturn(linkReturn), .registerWrite(registerWrite), .memoryWrite(memoryWrite), .halt(halt), .push(push), .pop(pop), .flagWrite(flagWrite), .branch(branch));

endmodule

module decoder (
    input logic [1:0] opCode, functSpecial,
    input logic [3:0] functDP, 
    input logic [2:0] destinationReg, sourceReg,
    input logic memory, link, 
    output logic plinkReturn,
    output logic pbranch, shiftOp, memToReg, ppush, ppop, pregisterWrite, pmemoryWrite, pflagWrite, phalt,
    output logic [1:0] regSrc, writeReg, shiftFunction,
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

        {pbranch, regSrc, shiftOp, memToReg, writeReg, ppush, ppop, pregisterWrite, pmemoryWrite, pflagWrite, shiftFunction, phalt, aluFunction} = controls;

    end

endmodule

module condCheck (
    input logic [3:0] cond, flags,
    output logic condEx
);

    logic negative, zero, carry, overflow;
    assign {negative, zero, carry, overflow} = flags;

    always_comb begin : Conditionals

        case (cond)
            4'b0000: condEx = zero;
            4'b0001: condEx = ~zero;
            4'b0010: condEx = carry;
            4'b0011: condEx = ~carry;
            4'b0100: condEx = negative;
            4'b0101: condEx = ~negative; 
            4'b0110: condEx = overflow;
            4'b0111: condEx = ~overflow;
            4'b1000: condEx = ~zero & carry;
            4'b1001: condEx = zero | ~carry;
            4'b1010: condEx = ~(negative ^ overflow);
            4'b1011: condEx = (negative ^ overflow);
            4'b1100: condEx = ~zero & ~(negative ^ overflow);
            4'b1101: condEx = zero | (negative ^ overflow);
            4'b1110: condEx = 1'b1;

            default: condEx = 1'b0;
        endcase

    end
    
endmodule

module condLogic (
    input logic clk, reset,
    input logic plinkReturn, pregisterWrite, pmemoryWrite, phalt, ppush, ppop, pflagWrite, pbranch,
    input logic [3:0] ALUFlags, cond,
    output logic linkReturn, registerWrite, memoryWrite, halt, push, pop, flagWrite, branch
);

    logic condEx;
    logic [3:0] flags;

    enfflopr #(4) flagRegister (.d(ALUFlags), .clk(clk), .reset(reset), .en(flagWrite), .q(flags));

    condCheck conditions (.cond(cond), .flags(flags), .condEx(condEx));

    assign flagWrite = pflagWrite & condEx;
    assign branch = pbranch & condEx;
    assign pop = ppop & condEx;
    assign push = ppush & condEx;
    assign halt = phalt & condEx;
    assign memoryWrite = pmemoryWrite & condEx;
    assign registerWrite = pregisterWrite & condEx;
    assign linkReturn = plinkReturn & condEx;

endmodule