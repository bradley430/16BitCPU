module CPU #(
    MEM_SPACE = 256
) (
    input logic clk, reset
);

    logic [15:0] instruction, PC;
    logic [3:0] ALUFlags;
    logic [2:0] ALUFunction;
    logic [1:0] regSrc, writeReg, shiftFunction;
    logic branch, shiftOp, memToReg, push, pop, registerWrite, memoryWrite, flagWrite, halt, linkReturn;

    instructionMemory imem(.address(PC), .instruction(instruction));

    controlUnit controller(.clk(clk), .reset(reset), .instr(instruction), .flags(ALUFlags), .branch(branch), .shiftOp(shiftOp), .memToReg(memToReg), .push(push), .pop(pop), .registerWrite(registerWrite), .memoryWrite(memoryWrite), .flagWrite(flagWrite), .halt(halt), .linkReturn(linkReturn), .regSrc(regSrc), .writeReg(writeReg), .shiftFunction(shiftFunction), .aluFunction(ALUFunction));

    datapath #(MEM_SPACE) dp(.clk(clk), .reset(reset), .branch(branch), .shiftOp(shiftOp), .memToReg(memToReg), .push(push), .pop(pop), .registerWrite(registerWrite), .memoryWrite(memoryWrite), .halt(halt), .linkReturn(linkReturn), .regSrc(regSrc), .writeReg(writeReg), .shiftFunction(shiftFunction), .aluFunction(ALUFunction), .instruction(instruction), .PC(PC), .ALUFlags(ALUFlags));
    
endmodule

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

module datapath #(
    MEM_SPACE = 256
) (
    input logic clk, reset,
    branch, shiftOp, memToReg, push, pop, registerWrite, memoryWrite, halt, linkReturn,
    input logic [1:0] regSrc, writeReg, shiftFunction,
    input logic [2:0] aluFunction,
    input logic [15:0] instruction,
    output logic [15:0] PC, 
    output logic [3:0] ALUFlags
);

    logic [15:0] ALUResult, memToRegResult, PCSrc, PCPlus1;

    logic PCOverflow;

    //PC logic 
    adder pcAdd(.a(PC), .b(16'b1), .cin(0), .sum(PCPlus1), .cout(PCOverflow));
    mux2 pcSrc(.a(memToRegResult), .b(PCPlus1), .selected(PCSrc), .s(branch | linkReturn));
    PCReg pcReg(.nextPC(PCSrc), .clk(clk), .reset(reset), .halt(halt), .PC(PC));


    logic[15:0] writeData, rd1, rd2, rd3, spPush;

    logic [2:0] addr1, writeAddr;

    //register file logic
    mux2 #(.WIDTH(3)) addr1Mux (.a(3'b111), .b(instruction[5:3]), .s(branch), .selected(addr1));
    mux3 #(.WIDTH(3)) writeAddrMux (.a(instruction[5:3]), .b(instruction[8:6]), .c(3'b110), .s(regSrc), .selected(writeAddr));
    mux3 writeDataMux(.a(memToRegResult), .b(spPush), .c(PCPlus1), .s(writeReg), .selected(writeData));
    regFile regfile(.address1(addr1), .address2(instruction[2:0]), .writeAddress(writeAddr), .writeData(writeData), .r7(PCPlus1), .clk(clk), .reset(reset), .registerWrite(registerWrite), .read1(rd1), .read2(rd2), .read3(rd3));
    
    logic [15:0] extenderResult;

    //extender logic
    extend extender(.offset(instruction[8:0]), .extenderResult(extenderResult));

    logic[15:0] read2MuxResult;

    //ALU logic
    mux2 read2Mux(.a(extenderResult), .b(rd2), .s(branch), .selected(read2MuxResult));
    alu ALU(.a(rd1), .b(read2MuxResult), .ALUControl(aluFunction), .ALUFlags(ALUFlags), .ALUResult(ALUResult));

    logic[15:0] shifterResult, ALUInput;

    //shifter and ALUResult logic
    shifter Shifter(.val(rd1), .shamt(rd2), .shiftFunction(shiftFunction), .shifterResult(shifterResult));
    mux2 shiftMux(.a(shifterResult), .b(ALUResult), .s(shiftOp), .selected(ALUInput));

    logic[15:0] spPushPop, PUSH, POP, SP;

    logic pushOverflow, popOverflow;

    //SP logic
    mux2 pushMux(.a(16'b1111111111111111), .b(16'b0), .s(push), .selected(PUSH));
    adder pushAdder(.a(PUSH), .b(SP), .cin(16'b0), .sum(spPush), .cout(pushOverflow));
    mux2 popMux(.a(16'b1), .b(16'b0), .s(pop), .selected(POP));
    adder popAdder(.a(POP), .b(spPush), .cin(16'b0), .sum(spPushPop), .cout(popOverflow));
    spReg #(MEM_SPACE) SPReg(.nextSP(spPushPop), .clk(clk), .reset(reset), .SP(SP));

    logic[15:0] memAddress, memRead;

    //memory logic
    mux2 memAddrMux(.a(spPush), .b(ALUResult), .s(push | pop), .selected(memAddress));
    
    dataMemory #(MEM_SPACE) memory(.address(memAddress), .writeData(rd3), .clk(clk), .memoryWrite(memoryWrite), .read(memRead));
    
    mux2 memToRegMux(.a(memRead), .b(ALUInput), .s(memToReg), .selected(memToRegResult));

endmodule

module PCReg (
    input logic [15:0] nextPC,
    input logic clk, reset, halt,
    output logic [15:0] PC
);

    always_ff @( posedge clk ) begin : PCRegister

        if(reset) PC <= 0;

        else if (~halt) PC <= nextPC;
        
    end
    
endmodule

module spReg #(
    SPACE = 256
) (
    input logic [15:0] nextSP,
    input logic clk, reset,
    output logic [15:0] SP
);

    always_ff @( posedge clk ) begin : SPRegister

        if(reset) SP <= SPACE;

        else SP <= nextSP;
        
    end
    
endmodule

module regFile (
    input logic [2:0] address1, address2, writeAddress,
    input logic [15:0] writeData, r7,
    input logic clk, registerWrite, reset,
    output logic [15:0] read1, read2, read3
);
    logic[15:0] R7, rf[6:0];
    assign R7 = r7;

    always_ff @(posedge clk) begin : Write

        if(reset) for(int i = 0; i < 7; i++) rf[i] <= 16'b0;

        else if(registerWrite & writeAddress != 3'b111) rf[writeAddress] <= writeData;
        
    end
    
    assign read1 = (address1 == 3'b111) ? R7 : rf[address1];
    assign read2 = (address2 == 3'b111) ? R7 : rf[address2];
    assign read3 = (writeAddress == 3'b111) ? R7 : rf[writeAddress];

endmodule

module dataMemory #(
    SPACE = 256
) (
    input logic[15:0] address, writeData,
    input logic clk, memoryWrite,
    output logic[15:0] read
);

    logic[15:0] RAM[SPACE - 1:0];

    assign read = RAM[address];

    always_ff @(posedge clk) begin : Write

        if(memoryWrite) RAM[address] <= writeData;
        
    end
    
endmodule

module enfflopr #(
    WIDTH = 16
) (
    input logic [WIDTH - 1:0] d,
    input logic clk, reset, en,
    output logic [WIDTH - 1:0] q
);

    always_ff @(posedge clk) begin : FlipFlop

        if(reset) q <= 0;

        else if(en) q <= d;
        
    end
    
endmodule

module instructionMemory (
    input logic[15:0] address,
    output logic [15:0] instruction
);

    logic[15:0] MEM[65535:0];

    initial $readmemh("memfile.dat", MEM);

    assign instruction = MEM[address];
    
endmodule

module alu(input logic [15:0] a, b,
           input logic [2:0] ALUControl,
           output logic [15:0] ALUResult,
           output logic [3:0] ALUFlags
);

    logic [15:0] adderResult, condb;
    logic negative, zero, carry, overflow, rawCarry;

    assign condb = (ALUControl == 3'b001) ? ~b : b;

    adder add(.a(a), .b(condb), .cin((ALUControl == 3'b001)), .sum(adderResult), .cout(rawCarry));

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
    assign overflow = (ALUControl[2:1] == 2'b00) & (a[15] ^ ALUResult[15]) & !(a[15] ^ b[15] ^ ALUControl[0]);

    assign ALUFlags = {negative, zero, carry, overflow};
        
endmodule

module extend(input logic [8:0] offset,
              output logic [15:0] extenderResult
);

    assign extenderResult = {{7{offset[8]}}, offset};

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

module adder(input logic [15:0] a, b,
             input logic cin,
             output logic [15:0] sum,
             output logic cout
);

    assign {cout, sum} = a + b + cin;

endmodule

module mux2 #(
    WIDTH = 16
) (
    input logic [WIDTH - 1:0] a, b,
    input logic s,
    output logic [WIDTH - 1:0] selected
);

    assign selected = s ? a : b; 
    //takes a if s, takes b if not s
    
endmodule

module mux3 #(
    WIDTH = 16
)(
    input logic [WIDTH - 1:0] a, b, c,
    input logic [1:0] s,
    output logic [WIDTH - 1:0] selected
);

    always_comb begin : mux3

        case (s)
            2'b00: selected = a;
            2'b01: selected = b;
            2'b10: selected = c;
            default: selected = a;
        endcase

    end
    
endmodule