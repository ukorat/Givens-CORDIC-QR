`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 05/26/2016 04:31:46 PM
// Design Name: 
// Module Name: QRSolver_Parametric
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module QRSolver_Parametric
#(parameter intLenIn = 5,
            fracLenIn = 19,
            intLenOut = 5,
            fracLenOut = 19,
            noIteration = 10,
            matrixSize = 4,
            KnInt = 1,
            KnFrac = 15,
            addrWidthKnLUT = 4)
 
 (input clk,nRst,
// input startQRDecomp,
 input inputValid,
 input [KnInt+KnFrac-1:0] valueKn,
 input [matrixSize*(intLenIn + fracLenIn) - 1 :0] inputRowR,
 input [matrixSize*(intLenIn + fracLenIn) - 1 :0] inputColumnQ,
 output reg qrCoreStarted,
 output transferValid,
 output reg qrDecompDone,//);
 output reg [matrixSize*(intLenIn + fracLenIn) - 1 :0] outputRowR,
 output reg [matrixSize*(intLenIn + fracLenIn) - 1 :0] outputColumnQ);

//integer row,column,

localparam stateBitWidth = 3;
localparam addrWidth = clogb2(matrixSize);
//wire [KnInt+KnFrac-1:0] LUTvalueKn;

reg [addrWidth-1:0] rd_addr;
reg [addrWidth-1:0] row;
reg [addrWidth-1:0] column;
reg [addrWidth-1:0] addrIndex;

reg [stateBitWidth - 1:0] state;

localparam storeData = 0 ;
localparam getData = 1 ;
localparam processData = 2;
localparam scaledData = 3;
localparam putData = 4;
localparam dataTransfer = 5;

//reg [stateBitWidth - 1:0] storeData = 3'b000 ;
//reg [stateBitWidth - 1:0] getData = 3'b001 ;
//reg [stateBitWidth - 1:0] processData = 3'b010;
//reg [stateBitWidth - 1:0] scaledData = 3'b011;
//reg [stateBitWidth - 1:0] putData = 3'b100;
//reg [stateBitWidth - 1:0] dataTransfer = 3'b101;

//reg [KnInt+KnFrac-1:0] valueKn = 24'b010011011011101001110110;

reg startQRDecomp;
reg dataValid;
//reg readEnable;
reg processStarted;
reg transferStarted;
reg transferFinished;
reg [1:0] waitFor3Clockcycle;
reg [addrWidthKnLUT-1:0] addr;

reg [matrixSize-1:0] disableCore;
reg [matrixSize-1:0] signDictator;

// Inputs for givensCordic QR
reg signed [matrixSize*(intLenIn + fracLenIn) - 1 :0] inputX;
reg signed [matrixSize*(intLenIn + fracLenIn) - 1 :0] inputY;
reg signed [matrixSize*(intLenIn + fracLenIn) - 1 :0] inputU;
reg signed [matrixSize*(intLenIn + fracLenIn) - 1 :0] inputV;

//Inputs for Multiplier Core
reg inputValid_Kn;
reg signed [matrixSize*(intLenIn + fracLenIn) - 1 :0] mulInputX;
reg signed [matrixSize*(intLenIn + fracLenIn) - 1 :0] mulInputY;
reg signed [matrixSize*(intLenIn + fracLenIn) - 1 :0] mulInputU;
reg signed [matrixSize*(intLenIn + fracLenIn) - 1 :0] mulInputV;

//Outputs from givensCprdic QR
wire processDone;
wire signed [matrixSize*(intLenIn + fracLenIn) - 1 :0] outputX;
wire signed [matrixSize*(intLenIn + fracLenIn) - 1 :0] outputY;
wire signed [matrixSize*(intLenIn + fracLenIn) - 1 :0] outputU;
wire signed [matrixSize*(intLenIn + fracLenIn) - 1 :0] outputV;

//Outputs from Multiplier Core
wire outValid_Kn;
wire signed [matrixSize*(intLenIn + fracLenIn) - 1 :0] mulOutputX;
wire signed [matrixSize*(intLenIn + fracLenIn) - 1 :0] mulOutputY;
wire signed [matrixSize*(intLenIn + fracLenIn) - 1 :0] mulOutputU;
wire signed [matrixSize*(intLenIn + fracLenIn) - 1 :0] mulOutputV;

reg [matrixSize*(intLenIn + fracLenIn) - 1 :0] inputMatrix [0:matrixSize-1];
reg [matrixSize*(intLenIn + fracLenIn) - 1 :0] matrixQ [0:matrixSize-1];

//initial begin
//$readmemb("inputMatrix.txt",inputMatrix);
//$readmemb("qMatrix.txt",matrixQ);
//end

// Cordic Engine
GivensCordicQR_Parametric
#(.intLenIn(intLenIn),
  .fracLenIn(fracLenIn),
  .intLenOut(intLenOut),
  .fracLenOut(fracLenOut),
  .noIteration(noIteration),
  .matrixSize(matrixSize))
   GivensCordicQRCore00
(.clk(clk),
 .nRst(nRst),
 .disableCore(disableCore),
 .dataValid(dataValid),
 .signDictator(signDictator),
 .inputVectorX(inputX),
 .inputVectorY(inputY),
 .inputVectorU(inputU),
 .inputVectorV(inputV),
 
 .processDone(processDone),
 .outputVectorX(outputX),
 .outputVectorY(outputY),
 .outputVectorU(outputU),
 .outputVectorV(outputV));  
 
 // Multiplier Core
 //(* keep_hierarchy = "yes" *)
 KnMultiplierCore_Parametric
 #(.intLen(intLenIn),
   .fracLen(fracLenIn),
   .noIteration(noIteration),
   .matrixSize(matrixSize),
   .KnInt(KnInt),
   .KnFrac(KnFrac))
   KnMultiplierCore00
 (.clk(clk),
  .nRst(nRst),
  .inputValid(inputValid_Kn),
  .valueKn(valueKn),
  .inputX(mulInputX),
  .inputY(mulInputY),
  .inputU(mulInputU),
  .inputV(mulInputV),
	.outValid(outValid_Kn),
  .outputX(mulOutputX),
  .outputY(mulOutputY),
  .outputU(mulOutputU),
  .outputV(mulOutputV));
 
 //
// KnValueROM
// #(.KnInt(KnInt),
//   .KnFrac(KnFrac))
//   KnValueROMCore00
// (.clk(clk),
//  .nRst(nRst),
//  .readEnable(readEnable),
//  .addr(addr),
//  .valueKn(LUTvalueKn));
  
//KnValueLUT
// #(.KnInt(KnInt),
//  .KnFrac(KnFrac))
//   KnValueLUTCore00
//  (.addr(noIteration[3:0]),
//  .valueKn(LUTvalueKn));
  
//assign qrDecompStarted = processStarted;
assign transferValid = transferStarted;

  always @(posedge clk) begin
    if (!nRst) begin
        dataValid <= 1'b0;
        processStarted <= 1'b0;
        qrDecompDone <= 1'b0;
        disableCore <= {(matrixSize){1'b0}};
        waitFor3Clockcycle <= 2'b00;
        row <= {(addrWidth){1'b0}};
        column <= {{(addrWidth-1){1'b0}}, 1'b1};
        rd_addr <= 0;
//        addr <= 4'b0000;
//        readEnable <= 1'b0;
				qrCoreStarted <= 1'b0;
				startQRDecomp <= 1'b0;
        signDictator <= {(matrixSize){1'b0}};
        addrIndex <= 0;
				inputValid_Kn <= 1'b0;
        state <= storeData;
    end
    else begin
			case (state)
 				storeData: begin :putInputInMemory
 					transferFinished <= 1'b0;
 					qrDecompDone <= 1'b0;
 					if (addrIndex < matrixSize) begin
 						if (inputValid && !startQRDecomp) begin
 							qrCoreStarted <= 1'b1;
							addrIndex <= addrIndex + 1'b1;
						end
						state <= storeData;
					end
					else begin
						addrIndex	<= 0;
						startQRDecomp <= 1'b1;
						state <= getData;
					end
				end		
        getData: begin :fetchInput
        	if (startQRDecomp && !processStarted) begin
          	dataValid <= 1'b1;
            processStarted <= 1'b1;
            disableCore <= {(matrixSize){1'b0}};
            signDictator <= {{(matrixSize-1){1'b0}},1'b1};
//            readEnable <= 1'b1;
//            addr <= noIteration[3:0];
						startQRDecomp <= 1'b0;
            state <= processData;
          end
          else if (processStarted && !startQRDecomp) begin
          	if (row < matrixSize-1) begin
            	dataValid <= 1'b1;
              addr <= 4'b0000;
//              readEnable <= 1'b0;
              state <= processData;
            end
            else begin
            	dataValid <= 1'b0;
              processStarted <= 1'b0;
              disableCore <= {(matrixSize){1'b0}};
              signDictator <= {{(matrixSize-1){1'b0}},1'b1};
              row <= {(addrWidth){1'b0}};
              column <= {{(addrWidth-1){1'b0}}, 1'b1};
//                      qrDecompDone <= 1'b1;
              state <= dataTransfer;
//                      state <= storeData;
            end
          end
          else begin
            dataValid <= 1'b0;
            qrDecompDone <= 1'b0;
            row <= {(addrWidth){1'b0}};
            column <= {{(addrWidth-1){1'b0}}, 1'b1};
            state <= getData;
            qrDecompDone <= qrDecompDone;
            transferFinished <= 1'b0;
  				end
        end
        processData: begin: processingInput
        	if (!processDone) begin
          	dataValid <= 0;
            state <= processData;
          end
          else begin
          	state <= scaledData;
          end
        end
        scaledData: begin: scalingOfOutput
					if (!inputValid_Kn) begin
						inputValid_Kn <= 1'b1;
					end
					else begin
						state <= putData;
						inputValid_Kn <= 1'b0;
					end

        end          
        putData: begin :putOutput
					if (outValid_Kn) begin
						if (column == matrixSize-1) begin
							disableCore <= (disableCore << 1) + 1'b1;
							signDictator <= signDictator << 1;
							row <= row + 1'b1;
							column <= row + 2'b10;
						end
						else begin
							column <= column+1;
						end
						state <= getData;
					end
					else begin
						state <= putData;
					end
				end
        dataTransfer : begin
        	if (rd_addr < matrixSize) begin
          	rd_addr <= rd_addr + 1'b1;
            state <= dataTransfer;
          end
          else begin
            state <= storeData;
            rd_addr <= 0;
            qrDecompDone <= 1'b1;
            transferFinished <= 1'b1;
            qrCoreStarted <= 1'b0;
          end
        end
        default : state <= storeData;          
      endcase       
    end
	end
  
  always @(posedge clk) begin
    if (~nRst) begin
        inputX <= {(matrixSize*(intLenIn + fracLenIn)){1'b0}};
        inputY <= {(matrixSize*(intLenIn + fracLenIn)){1'b0}};
        inputU <= {(matrixSize*(intLenIn + fracLenIn)){1'b0}};
        inputV <= {(matrixSize*(intLenIn + fracLenIn)){1'b0}};
    end
    else begin
    	if (state == storeData && inputValid) begin
    		inputMatrix[addrIndex] <= inputRowR;
    		matrixQ[addrIndex] <= inputColumnQ;
    	end 
      else if (state == getData && startQRDecomp) begin
        inputX <= inputMatrix[row];
        inputY <= inputMatrix[column];
        inputU <= matrixQ[row];
        inputV <= matrixQ[column];
      end
      else if (state == getData && processStarted) begin
            if (column < matrixSize) begin
                inputX <= inputMatrix[row];
                inputY <= inputMatrix[column];
                inputU <= matrixQ[row];
                inputV <= matrixQ[column];
            end
            else begin
                inputX <= {(matrixSize*(intLenIn + fracLenIn)){1'b0}};
                inputY <= {(matrixSize*(intLenIn + fracLenIn)){1'b0}};
                inputU <= {(matrixSize*(intLenIn + fracLenIn)){1'b0}};
                inputV <= {(matrixSize*(intLenIn + fracLenIn)){1'b0}};
            end
        end
        else if (state == scaledData) begin
            mulInputX <= outputX;
            mulInputY <= outputY;
            mulInputU <= outputU;
            mulInputV <= outputV;
        end
        else if (state == putData && outValid_Kn) begin
            inputMatrix[row] <= mulOutputX;
            inputMatrix[column] <= mulOutputY;
             matrixQ[row] <= mulOutputU;
             matrixQ[column] <= mulOutputV;
        end
        else begin
            inputX <= {(matrixSize*(intLenIn + fracLenIn)){1'b0}};
            inputY <= {(matrixSize*(intLenIn + fracLenIn)){1'b0}};
            inputU <= {(matrixSize*(intLenIn + fracLenIn)){1'b0}};
            inputV <= {(matrixSize*(intLenIn + fracLenIn)){1'b0}};
            mulInputX <= {(matrixSize*(intLenIn + fracLenIn)){1'b0}};
            mulInputY <= {(matrixSize*(intLenIn + fracLenIn)){1'b0}};
            mulInputU <= {(matrixSize*(intLenIn + fracLenIn)){1'b0}};
            mulInputV <= {(matrixSize*(intLenIn + fracLenIn)){1'b0}};
        end
    end              
  end
  
  always @(posedge clk) begin
    if (~nRst) begin
        outputRowR <= {(matrixSize*(intLenIn + fracLenIn)){1'b0}};
        outputColumnQ <= {(matrixSize*(intLenIn + fracLenIn)){1'b0}};
        transferStarted <= 1'b0;
    end
    else begin
        if (state == dataTransfer) begin
            if (rd_addr < matrixSize) begin
                transferStarted <= 1'b1;
                outputRowR <= inputMatrix[rd_addr]; 
                outputColumnQ <= matrixQ[rd_addr];
            end
            else begin
                transferStarted <= 1'b0;
                outputRowR <= {(matrixSize*(intLenIn + fracLenIn)){1'b0}};
                outputColumnQ <= {(matrixSize*(intLenIn + fracLenIn)){1'b0}};
            end
        end
        else begin
            transferStarted <= transferStarted;
            outputRowR <= outputRowR;
            outputColumnQ <= outputColumnQ;
        end
     end
  end
	
function integer clogb2;
  input [31:0] value;
    begin
			for (clogb2 = 0; value > 0; clogb2 = clogb2 + 1) begin
        value = value >> 1;
      end
    end
endfunction

endmodule
