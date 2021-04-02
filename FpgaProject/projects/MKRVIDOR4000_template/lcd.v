/*
Sending bytes:
    LCD_RW low

    LCD_RS high (chr) or low (cmd)

    LCD_EN high
    LCD_Data upper
    delay
    LCD_EN low
    delay

    LCD_EN high
    LCD_Data lower
    delay
    LCD_EN low
    delay

    LCD_RW high

Initialising sequence (4-bit mode)
    0x33
    0x32
    0x28
    0x06
    0x0C
*/


module lcd #(
    parameter CLOCK_RATE = 48000000
)(
    input CLOCK,
    input SYNC_RST,
    input REFRESH,
    output reg LCD_RS,
    output reg LCD_EN,
    output reg LCD_RW,
    output reg [3:0] LCD_DATA,
    input reg [16*8:0] LCD_LINE1,
    input reg [16*8:0] LCD_LINE2
);
    
    parameter STATE_UPPER_DATA = 0; // Initialization state
    parameter STATE_UPPER_CLOCK = 1; // Loading instruction state
    parameter STATE_LOWER_DATA = 2;  // Pushing instruction state
    parameter STATE_LOWER_CLOCK = 3; // Standby state
    parameter STATE_NEXT_INSTRUCTION = 4;
    
    parameter END_OF_INDEX = 256;
   
    parameter DELAY_CYCLES_CMD = CLOCK_RATE / 1000000 * 300; // 300 microseconds
    parameter DELAY_CYCLES_CHR = CLOCK_RATE / 1000000 * 40; // 40 microseconds
    
    // Delay for each byte transfer (Commands require a longer delay than chars)
    wire [23:0] delay_cycles = (instruction[8] == 1'b1) ? DELAY_CYCLES_CHR : DELAY_CYCLES_CMD;
    
    
    reg [8:0] instruction = 0;
    reg [9:0] index = 0;
    reg [3:0] state = STATE_UPPER_DATA;
    reg [23:0] delay = 0;
   
    always @(posedge CLOCK) begin
        if (!SYNC_RST) begin
            index <= 0;
            state <= STATE_UPPER_DATA;
            delay <= 0;
        end else begin
            case (state)
                STATE_UPPER_DATA: begin
                    LCD_RW <= 1'b0;
                    LCD_EN <= 1'b1;
                    LCD_RS <= instruction[8];
                    LCD_DATA[3:0] <= instruction[7:4];
                    state <= STATE_UPPER_CLOCK;
                    delay <= 0;
                end
                STATE_UPPER_CLOCK: begin
                    if (delay < delay_cycles) begin
                            delay <= delay + 1;
                        if ((delay_cycles/2) < delay) begin
                                LCD_EN <= 1'b0;
                        end
                    end else begin
                        state <= STATE_LOWER_DATA;
                        delay <= 0;
                    end
                end
                STATE_LOWER_DATA: begin
                    LCD_EN <= 1'b1;
                    LCD_RS <= instruction[8];
                    LCD_DATA[3:0] <= instruction[3:0];
                    state <= STATE_LOWER_CLOCK;
                    delay <= 0;
                end
                STATE_LOWER_CLOCK: begin
                    if (delay < delay_cycles) begin
                            delay <= delay + 1;
                        if ((delay_cycles/2) < delay) begin
                                LCD_EN <= 1'b0;
                        end
                    end else begin
                        state <= STATE_NEXT_INSTRUCTION;
                        delay <= 0;
                    end
                end
                STATE_NEXT_INSTRUCTION: begin
                    LCD_RW <= 1'b1;
                    if (delay < delay_cycles) begin
                            delay <= delay + 1;
                    end else begin
                        if (index < END_OF_INDEX) begin
                            // Continue on to the next instruction index
                            index <= index + 1;
                            state <= STATE_UPPER_DATA;
                        end else if (REFRESH == 1'b1) begin
                            // Once reached the end of instructions, a refresh can be done
                            index <= 10;
                            state <= STATE_UPPER_DATA;
                        end
                    end
                end
                default: begin
                    index <= 0;
                    state <= STATE_UPPER_DATA;
                    delay <= 0;
                end
            endcase
        end
    end
   
    always @(*) begin
        case (index)
            0: instruction <= {1'b0, 8'h33}; // Cmd: Reset display
            1: instruction <= {1'b0, 8'h32}; // Cmd: Init 4-bit mode
            2: instruction <= {1'b0, 8'h28}; // Cmd: Function set - 4 bit mode, 2 lines, 5x7 font
            3: instruction <= {1'b0, 8'h06}; // Cmd: Entry mode set - Move cursor to the right every time a character is written
            4: instruction <= {1'b0, 8'h0C}; // Cmd: Display control - Displau on, No cursor, No cursor blink
            5: instruction <= {1'b0, 8'h01}; // Cmd: Clear display
            // no operation in between
            9: instruction <= {1'b0, 8'h01}; // Cmd: Clear display
            10: instruction <= {1'b0, 8'h80}; // Cmd: Set cursor to Line 1
            11: instruction <= {1'b1, LCD_LINE1[15*8+7:15*8]}; // Chr
            12: instruction <= {1'b1, LCD_LINE1[14*8+7:14*8]}; // Chr
            13: instruction <= {1'b1, LCD_LINE1[13*8+7:13*8]}; // Chr
            14: instruction <= {1'b1, LCD_LINE1[12*8+7:12*8]}; // Chr
            15: instruction <= {1'b1, LCD_LINE1[11*8+7:11*8]}; // Chr
            16: instruction <= {1'b1, LCD_LINE1[10*8+7:10*8]}; // Chr
            17: instruction <= {1'b1, LCD_LINE1[9*8+7:9*8]}; // Chr
            18: instruction <= {1'b1, LCD_LINE1[8*8+7:8*8]}; // Chr
            19: instruction <= {1'b1, LCD_LINE1[7*8+7:7*8]}; // Chr
            20: instruction <= {1'b1, LCD_LINE1[6*8+7:6*8]}; // Chr
            21: instruction <= {1'b1, LCD_LINE1[5*8+7:5*8]}; // Chr
            22: instruction <= {1'b1, LCD_LINE1[4*8+7:4*8]}; // Chr
            23: instruction <= {1'b1, LCD_LINE1[3*8+7:3*8]}; // Chr
            24: instruction <= {1'b1, LCD_LINE1[2*8+7:2*8]}; // Chr
            25: instruction <= {1'b1, LCD_LINE1[1*8+7:1*8]}; // Chr
            26: instruction <= {1'b1, LCD_LINE1[0*8+7:0*8]}; // Chr
            // no operation in between
            30: instruction <= {1'b0, 8'hC0}; // Cmd: Set cursor to Line 2
            31: instruction <= {1'b1, LCD_LINE2[15*8+7:15*8]}; // Chr
            32: instruction <= {1'b1, LCD_LINE2[14*8+7:14*8]}; // Chr
            33: instruction <= {1'b1, LCD_LINE2[13*8+7:13*8]}; // Chr
            34: instruction <= {1'b1, LCD_LINE2[12*8+7:12*8]}; // Chr
            35: instruction <= {1'b1, LCD_LINE2[11*8+7:11*8]}; // Chr
            36: instruction <= {1'b1, LCD_LINE2[10*8+7:10*8]}; // Chr
            37: instruction <= {1'b1, LCD_LINE2[9*8+7:9*8]}; // Chr
            38: instruction <= {1'b1, LCD_LINE2[8*8+7:8*8]}; // Chr
            39: instruction <= {1'b1, LCD_LINE2[7*8+7:7*8]}; // Chr
            40: instruction <= {1'b1, LCD_LINE2[6*8+7:6*8]}; // Chr
            41: instruction <= {1'b1, LCD_LINE2[5*8+7:5*8]}; // Chr
            42: instruction <= {1'b1, LCD_LINE2[4*8+7:4*8]}; // Chr
            43: instruction <= {1'b1, LCD_LINE2[3*8+7:3*8]}; // Chr
            44: instruction <= {1'b1, LCD_LINE2[2*8+7:2*8]}; // Chr
            45: instruction <= {1'b1, LCD_LINE2[1*8+7:1*8]}; // Chr
            46: instruction <= {1'b1, LCD_LINE2[0*8+7:0*8]}; // Chr
            // no operation in between
            default: instruction <= {1'b0, 1'h00}; // No operation
        endcase 
    end
endmodule