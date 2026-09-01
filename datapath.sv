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
    mux4 writeDataMux(.a(memToRegResult), .b(spPush), .c(PCPlus1), .d(16'b1), .s(writeReg), .selected(writeData));
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