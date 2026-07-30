module adder(input logic [15:0] a, b,
             input logic cin,
             output logic [15:0] sum,
             output logic cout);

    assign {cout, sum} = a + b + cin;

endmodule

module alu(input logic [15:0] a, b,
           input logic [2:0] ALUControl,
           output logic [15:0] ALUResult,
           output logic [3:0] ALUFlags);

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
              output logic [15:0] extended);

    assign extended = {7{offset[8]}, offset};

endmodule

module shifter(input logic signed [15:0] val, 
               input logic [15:0] shamt,
               input logic [1:0] shiftFunction,
               output logic [15:0] shifterResult);

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
