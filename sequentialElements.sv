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