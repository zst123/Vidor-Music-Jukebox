// Your code goes here:
parameter iCLK_frequency = 48000000;

/******************************** LED Blinking on A6 ********************************/

// Make an up-counter
reg [31:0] counter = 0;
always @(posedge iCLK) begin
    if (!rRESETCNT[5]) begin // Power on reset
        counter <= 0;
    end else begin
        counter <= counter + 1; // Increment
    end
end

// Connect an LED on Arduino A6, it will flash
// at a frequency of 48 MHz / 2 / (2^22) = 5.72 Hz
assign bMKR_A[6] = counter[22];

/******************************** LED Fading on A5 ********************************/

// Holds state of the pwm fade in/out
reg [15:0] pwm_threshold = 0;
reg pwm_direction = 0;

// Connect an LED on Arduino A6, it has a fade cycle
// with a frequency of 48 MHz / 2 / 65536 / (2^10) = 0.357 Hz
wire pwm_clock = counter[10];
wire pwm_fading = counter[15:0] < pwm_threshold;
assign bMKR_A[5] = pwm_fading;

always @(posedge pwm_clock) begin
    if (!rRESETCNT[5]) begin // Power on reset
        pwm_threshold <= 0;
        pwm_direction <= 0;
    end else begin
        if (pwm_direction == 0) begin
            if (pwm_threshold == 16'hFFFF) begin
                pwm_direction <= 1; // Swap directions when at the end
            end else begin
                pwm_threshold <= pwm_threshold + 1; // Increment
            end
        end else begin
            if (pwm_threshold == 16'h0000) begin
                pwm_direction <= 0; // Swap directions when at the end
            end else begin
                pwm_threshold <= pwm_threshold - 1; // Decrement
            end
        end
    end
end

/******************************** Music Tone on A4 ********************************/

reg [31:0] music_counter = 0;
reg [31:0] music_divisor;
reg [31:0] music_frequency;

// Divide clock down by the divisor
always @(posedge iCLK) begin
    if (!rRESETCNT[5]) begin // Power on reset
        music_counter <= 0;
    end else begin
        music_divisor <= iCLK_frequency / music_frequency;
        if (music_counter < (music_divisor-1)) begin
            music_counter <= music_counter + 1;
        end else begin
            music_counter <= 32'd0;
        end
    end
end

// Connect buzzer to Arduino A4
wire music_tone = music_frequency > 10 ? // if music frequency is valid/large enough
                    ((music_counter < (music_divisor/2)) ? 1'b1 : 1'b0) : // then do the pwm, roughly 50% duty cycle
                    (1'b0); // else turn off the buzzer

assign bMKR_A[4] = music_tone;

/******************************** LCD Display ********************************/

// control signals
wire       lcd_reset_n = 1;
wire       lcd_refresh = counter[24];
wire [3:0] lcd_counter = counter[28:25];

// 16-byte character array
reg [15*8+7:0] lcd_line1 = "                ";
reg [15*8+7:0] lcd_line2 = "                ";
reg [15*8+7:0] lcd_line1_noscroll = " [Hello World!] ";
reg [15*8+7:0] lcd_line2_noscroll = "---------------X";

always @(posedge lcd_refresh) begin     
    // Scroll line1 to the left, line2 to the right
    lcd_line1 <= lcd_line1_noscroll << 8*lcd_counter | lcd_line1_noscroll >> 8*(16-lcd_counter);
    lcd_line2 <= lcd_line2_noscroll >> 8*lcd_counter | lcd_line2_noscroll << 8*(16-lcd_counter);
end

// Connect up the wires for the LCD module
wire lcd_rs, lcd_rw, lcd_en;
wire [3:0] lcd_data;

assign bMKR_A[0] = lcd_rs;
assign bMKR_A[1] = lcd_en;
assign bMKR_D[5:2] = lcd_data;

lcd #(
    .CLOCK_RATE(iCLK_frequency)
)(
    .CLOCK(iCLK),
    .SYNC_RST(lcd_reset_n),
    .REFRESH(lcd_refresh),
    .LCD_RS(lcd_rs),
    .LCD_EN(lcd_en),
    .LCD_RW(lcd_rw),
    .LCD_DATA(lcd_data),
    .LCD_LINE1(lcd_line1),
    .LCD_LINE2(lcd_line2)
);

/******************************** UART RX ********************************/

wire [7:0] uart_data;
wire       uart_ready;
wire       uart_rx = bMKR_D[13]; // SAM D13 (RX)

uart_rx #(
    .CLOCK_RATE(iCLK_frequency),
    .BAUD_RATE(9600)
)(
    .i_CLK(iCLK),
    .i_RX(uart_rx),
    .o_READY(uart_ready),
    .o_DATA(uart_data)
);

/******************************** Music Jukebox ********************************/

// Include the music note parameters
`include "music_notes.vh"

reg [15:0] jukebox_index = 0;
reg [31:0] jukebox_counter = 0;
reg [31:0] jukebox_frequency = 0;

// Length of one note
parameter MUSIC_NOTE = iCLK_frequency / 1000 * 250; // 250 milliseconds
parameter MUSIC_REST = iCLK_frequency / 1000 * 50; // 50 milliseconds
parameter MUSIC_DELAY = MUSIC_NOTE + MUSIC_REST;

// Music Indices
parameter MUSIC_NONE = 0;
parameter MUSIC_0 = 1; // Do, Re, Mi
parameter MUSIC_1 = MUSIC_0+9;  // Mary Had A Little Lamb
parameter MUSIC_2 = MUSIC_1+30; // Twinkle Twinkle Little Star
parameter MUSIC_3 = MUSIC_2+50; // Old MacDonald Had A Farm
parameter MUSIC_4 = MUSIC_3+30; // ?

always @(posedge iCLK) begin
    // Delay before acting
    if (jukebox_counter < MUSIC_DELAY) begin
        jukebox_counter <= jukebox_counter + 1;
        
        if (jukebox_counter < MUSIC_NOTE) begin
            // Play notes
            music_frequency <= jukebox_frequency;
        end else begin
            // Rest between notes
            music_frequency <= NOTE_REST;
        end
    end else begin
        jukebox_counter <= 0;
        
        // Select next note using UART data
        // Change to next index after every delay.
        case (uart_data)
            "A": if (jukebox_index < MUSIC_0 || MUSIC_1 <= jukebox_index) jukebox_index <= MUSIC_0; else jukebox_index <= jukebox_index + 1;
            "B": if (jukebox_index < MUSIC_1 || MUSIC_2 <= jukebox_index) jukebox_index <= MUSIC_1; else jukebox_index <= jukebox_index + 1;
            "C": if (jukebox_index < MUSIC_2 || MUSIC_3 <= jukebox_index) jukebox_index <= MUSIC_2; else jukebox_index <= jukebox_index + 1;
            "D": if (jukebox_index < MUSIC_3 || MUSIC_4 <= jukebox_index) jukebox_index <= MUSIC_3; else jukebox_index <= jukebox_index + 1;
            default: jukebox_index <= MUSIC_NONE;
        endcase
        
        // Set text to be shown
        lcd_line1_noscroll <= "[Music Jukebox] ";

        case (uart_data)
            "A": lcd_line2_noscroll <= "Do, Re, Mi...   ";
            "B": lcd_line2_noscroll <= "Little Lamb     ";
            "C": lcd_line2_noscroll <= "Twinkle Twinkle ";
            "D": lcd_line2_noscroll <= "Old MacDonald   ";
            default: lcd_line2_noscroll <= {"---------------", uart_data};
        endcase
    end

    // Music Lookup Table
    case (jukebox_index)
        // -- Do, Re, Mi ---
        MUSIC_0+0: jukebox_frequency <= NOTE_C4;
        MUSIC_0+1: jukebox_frequency <= NOTE_D4;
        MUSIC_0+2: jukebox_frequency <= NOTE_E4;
        MUSIC_0+3: jukebox_frequency <= NOTE_F4;
        MUSIC_0+4: jukebox_frequency <= NOTE_G4;
        MUSIC_0+5: jukebox_frequency <= NOTE_A4;
        MUSIC_0+6: jukebox_frequency <= NOTE_B4;
        MUSIC_0+7: jukebox_frequency <= NOTE_C5;
        MUSIC_0+8: jukebox_index <= 0;
        
        // --- Mary Had A Little Lamb ---
        // EDCDEEE
        MUSIC_1+0: jukebox_frequency <= NOTE_E4;
        MUSIC_1+1: jukebox_frequency <= NOTE_D4;
        MUSIC_1+2: jukebox_frequency <= NOTE_C4;
        MUSIC_1+3: jukebox_frequency <= NOTE_D4;
        MUSIC_1+4: jukebox_frequency <= NOTE_E4;
        MUSIC_1+5: jukebox_frequency <= NOTE_E4;
        MUSIC_1+6: jukebox_frequency <= NOTE_E4;
        MUSIC_1+7: jukebox_frequency <= NOTE_REST;
        // DDDEEE_
        MUSIC_1+8: jukebox_frequency <= NOTE_D4;
        MUSIC_1+9: jukebox_frequency <= NOTE_D4;
        MUSIC_1+10: jukebox_frequency <= NOTE_D4;
        MUSIC_1+11: jukebox_frequency <= NOTE_E4;
        MUSIC_1+12: jukebox_frequency <= NOTE_E4;
        MUSIC_1+13: jukebox_frequency <= NOTE_E4;
        MUSIC_1+14: jukebox_frequency <= NOTE_REST;
        // EDCDEEE
        MUSIC_1+15: jukebox_frequency <= NOTE_E4;
        MUSIC_1+16: jukebox_frequency <= NOTE_D4;
        MUSIC_1+17: jukebox_frequency <= NOTE_C4;
        MUSIC_1+18: jukebox_frequency <= NOTE_D4;
        MUSIC_1+19: jukebox_frequency <= NOTE_E4;
        MUSIC_1+20: jukebox_frequency <= NOTE_E4;
        MUSIC_1+21: jukebox_frequency <= NOTE_E4;
        // EDDEDC_
        MUSIC_1+22: jukebox_frequency <= NOTE_E4;
        MUSIC_1+23: jukebox_frequency <= NOTE_D4;
        MUSIC_1+24: jukebox_frequency <= NOTE_D4;
        MUSIC_1+25: jukebox_frequency <= NOTE_E4;
        MUSIC_1+26: jukebox_frequency <= NOTE_D4;
        MUSIC_1+27: jukebox_frequency <= NOTE_C4;
        MUSIC_1+28: jukebox_frequency <= NOTE_REST;
        // End
        MUSIC_1+29: jukebox_index <= 0;
        
        // --- Twinkle Twinkle Little Star ---
        // CCGGAAG_
        MUSIC_2+0: jukebox_frequency <= NOTE_C4;
        MUSIC_2+1: jukebox_frequency <= NOTE_C4;
        MUSIC_2+2: jukebox_frequency <= NOTE_G4;
        MUSIC_2+3: jukebox_frequency <= NOTE_G4;
        MUSIC_2+4: jukebox_frequency <= NOTE_A4;
        MUSIC_2+5: jukebox_frequency <= NOTE_A4;
        MUSIC_2+6: jukebox_frequency <= NOTE_G4;
        MUSIC_2+7: jukebox_frequency <= NOTE_REST;
        // FFEEDDC_
        MUSIC_2+8: jukebox_frequency <= NOTE_F4;
        MUSIC_2+9: jukebox_frequency <= NOTE_F4;
        MUSIC_2+10: jukebox_frequency <= NOTE_E4;
        MUSIC_2+11: jukebox_frequency <= NOTE_E4;
        MUSIC_2+12: jukebox_frequency <= NOTE_D4;
        MUSIC_2+13: jukebox_frequency <= NOTE_D4;
        MUSIC_2+14: jukebox_frequency <= NOTE_C4;
        MUSIC_2+15: jukebox_frequency <= NOTE_REST;
        // GGFFEED_
        MUSIC_2+16: jukebox_frequency <= NOTE_G4;
        MUSIC_2+17: jukebox_frequency <= NOTE_G4;
        MUSIC_2+18: jukebox_frequency <= NOTE_F4;
        MUSIC_2+19: jukebox_frequency <= NOTE_F4;
        MUSIC_2+20: jukebox_frequency <= NOTE_E4;
        MUSIC_2+21: jukebox_frequency <= NOTE_E4;
        MUSIC_2+22: jukebox_frequency <= NOTE_D4;
        MUSIC_2+23: jukebox_frequency <= NOTE_REST;
        // GGFFEED_
        MUSIC_2+24: jukebox_frequency <= NOTE_G4;
        MUSIC_2+25: jukebox_frequency <= NOTE_G4;
        MUSIC_2+26: jukebox_frequency <= NOTE_F4;
        MUSIC_2+27: jukebox_frequency <= NOTE_F4;
        MUSIC_2+28: jukebox_frequency <= NOTE_E4;
        MUSIC_2+29: jukebox_frequency <= NOTE_E4;
        MUSIC_2+30: jukebox_frequency <= NOTE_D4;
        MUSIC_2+31: jukebox_frequency <= NOTE_REST;
        // CCGGAAG_
        MUSIC_2+32: jukebox_frequency <= NOTE_C4;
        MUSIC_2+33: jukebox_frequency <= NOTE_C4;
        MUSIC_2+34: jukebox_frequency <= NOTE_G4;
        MUSIC_2+35: jukebox_frequency <= NOTE_G4;
        MUSIC_2+36: jukebox_frequency <= NOTE_A4;
        MUSIC_2+37: jukebox_frequency <= NOTE_A4;
        MUSIC_2+38: jukebox_frequency <= NOTE_G4;
        MUSIC_2+39: jukebox_frequency <= NOTE_REST;
        // FFEEDDC_
        MUSIC_2+40: jukebox_frequency <= NOTE_F4;
        MUSIC_2+41: jukebox_frequency <= NOTE_F4;
        MUSIC_2+42: jukebox_frequency <= NOTE_E4;
        MUSIC_2+43: jukebox_frequency <= NOTE_E4;
        MUSIC_2+44: jukebox_frequency <= NOTE_D4;
        MUSIC_2+45: jukebox_frequency <= NOTE_D4;
        MUSIC_2+46: jukebox_frequency <= NOTE_C4;
        MUSIC_2+47: jukebox_frequency <= NOTE_REST;
        // End
        MUSIC_2+48: jukebox_index <= 0;
        
        // --- Old MacDonald Had A Farm ---
        // GGGDEED-
        MUSIC_3+0: jukebox_frequency <= NOTE_G4;
        MUSIC_3+1: jukebox_frequency <= NOTE_G4;
        MUSIC_3+2: jukebox_frequency <= NOTE_G4;
        MUSIC_3+3: jukebox_frequency <= NOTE_D4;
        MUSIC_3+4: jukebox_frequency <= NOTE_E4;
        MUSIC_3+5: jukebox_frequency <= NOTE_E4;
        MUSIC_3+6: jukebox_frequency <= NOTE_D4;
        MUSIC_3+7: jukebox_frequency <= NOTE_REST;
        // BBAAG-
        MUSIC_3+8: jukebox_frequency <= NOTE_B4;
        MUSIC_3+9: jukebox_frequency <= NOTE_B4;
        MUSIC_3+10: jukebox_frequency <= NOTE_A4;
        MUSIC_3+11: jukebox_frequency <= NOTE_A4;
        MUSIC_3+12: jukebox_frequency <= NOTE_G4;
        MUSIC_3+13: jukebox_frequency <= NOTE_REST;
        // DGGGDEED-
        MUSIC_3+14: jukebox_frequency <= NOTE_D4;
        MUSIC_3+15: jukebox_frequency <= NOTE_G4;
        MUSIC_3+16: jukebox_frequency <= NOTE_G4;
        MUSIC_3+17: jukebox_frequency <= NOTE_G4;
        MUSIC_3+18: jukebox_frequency <= NOTE_D4;
        MUSIC_3+19: jukebox_frequency <= NOTE_E4;
        MUSIC_3+20: jukebox_frequency <= NOTE_E4;
        MUSIC_3+21: jukebox_frequency <= NOTE_D4;
        MUSIC_3+22: jukebox_frequency <= NOTE_REST;
        // BBAAG-
        MUSIC_3+23: jukebox_frequency <= NOTE_B4;
        MUSIC_3+24: jukebox_frequency <= NOTE_B4;
        MUSIC_3+25: jukebox_frequency <= NOTE_A4;
        MUSIC_3+26: jukebox_frequency <= NOTE_A4;
        MUSIC_3+27: jukebox_frequency <= NOTE_G4;
        MUSIC_3+28: jukebox_frequency <= NOTE_REST;
        // End
        MUSIC_3+29: jukebox_index <= 0;
        
        // Quiet
        default: jukebox_frequency <= NOTE_REST;
        
    endcase
    
end

// Periodically change the tone roughly every second
/*
always @(posedge counter[25]) begin
    if (!rRESETCNT[5]) begin // Power on reset
        music_frequency <= 0; // Reset to beginning
    end else begin
        if (music_frequency == 261) begin
            music_frequency <= 293; // D4
        end else if (music_frequency == 293) begin
            music_frequency <= 329; // E4
        end else if (music_frequency == 329) begin
            music_frequency <= 349; // F4
        end else if (music_frequency == 349) begin
            music_frequency <= 392; // G4
        end else if (music_frequency == 392) begin
            music_frequency <= 440; // A4
        end else if (music_frequency == 440) begin
            music_frequency <= 493; // B4
        end else if (music_frequency == 493) begin
            music_frequency <= 523; // C5
        end else begin
            music_frequency <= 261; // C4
        end
        
    end
end
*/

/******************************** WIFI NINA ********************************/

/*
// NINA signals
#define FPGA_NINA_TX         ( 0)
#define FPGA_NINA_RX         ( 1)

#define FPGA_NINA_MISO       (10)
#define FPGA_NINA_SCK        ( 9)
#define FPGA_NINA_MOSI       ( 8)

#define FPGA_NINA_GPIO0      ( 7) // WM_PIO27 -> NiNa GPIO0 -> FPGA N9
#define FPGA_SPIWIFI_RESET   ( 6) // WM_RESET -> NiNa RESETN -> FPGA R1
#define FPGA_SPIWIFI_ACK     ( 5) // WM_PIO7  -> NiNa GPIO33 -> FPGA P6
#define FPGA_SPIWIFI_SS      ( 4) // WM_PIO28 -> NiNa GPIO5 -> FPGA N11

// NINA Control Pins
assign bWM_PIO27 = bMKR_D[7];    // SAM D7 -> bWM_PIO27  (NINA_GPIO0)
assign oWM_RESET = bMKR_D[6];    // SAM D6 -> oWM_RESET  (SPIWIFI_RESET)
assign bWM_PIO7  = bMKR_D[5];    // SAM D5 -> bWM_PIO7   (SPIWIFI_ACK)
assign bWM_PIO28 = bMKR_D[4];    // SAM D4 -> bWM_PIO28  (SPIWIFI_SS)

// NINA SPI Pins
assign bMKR_D[10] = bWM_PIO21;    // SAM D10 (MISO) <- bWM_PIO21 (NINA_MISO)
assign bWM_PIO29 = bMKR_D[9];    // SAM D9 (SCK)   -> bWM_PIO29 (NINA_SCK)
assign bWM_PIO1 = bMKR_D[8];     // SAM D8 (MOSI)  -> bWM_PIO1 (NINA_MOSI)

// NINA UART Pins
//assign bMKR_D[13] = iWM_TX;      // SAM D13 (Serial1 RX) <- iWM_TX (NINA_TX)
//assign oWM_RX = bMKR_D[14];      // SAM D14 (Serial1 TX) -> oWM_RX (NINA_RX)
assign bMKR_D[1] = iWM_TX;      // SAM D1 (SERCOM3 RX) <- iWM_TX (NINA_TX)
assign oWM_RX = bMKR_D[0];      // SAM D0 (SERCOM3 TX) -> oWM_RX (NINA_RX)
*/

