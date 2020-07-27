------------------------------------------------------------------------------------------
-- Filename:
--     user_digital.mod
--
-- The following routines are application specific, and are used to provide a standard
-- method to set up the fx1 digital functionality.
--
-- Routines

--    Dig_pin_connect(FX1_plist)
--    Dig_pin_disconnect(FX1_plist)
--    Define_captures(DOUT_pin)
--    Clear_sync_bus
------------------------------------------------------------------------------------------

------------------------------------------------------------------------------------------
--DEPENDENCIES:
--  Both Dig_pin_connect and Dig_pin_disconnect use constant "MAX_DP_PINS" defined in 
--  user_globals.mod file
------------------------------------------------------------------------------------------

use module "./user_globals.mod"
use module "./SERDES_Pins.mod"
static
 
    
end_static
 



procedure Dig_pin_connect(FX1_plist)

in pin list[MAX_DP_PINS] : FX1_plist  

-------------------------------------------------------------------------------------------------
--  This routine will initialize and connect the FX1 channels used for the application  
-------------------------------------------------------------------------------------------------
 
 
body

    -- If pinlist is NOT empty set, then run: 
    
    if dp_ptc(FX1_plist) <> <::> then
        set digital pin FX1_plist fx1 driver static tristate          
        connect digital pin FX1_plist to dcl
    end_if

end_body

 
 
procedure Dig_pin_disconnect(FX1_plist)

in pin list[MAX_DP_PINS] : FX1_plist

--------------------------------------------------------------------------------
-- Description:
--  This routine will reset and disconnect the FX1 pins passed in.
--     
-- History:
--  12/07/2011  PLA      -- Corrected typo in pinlist variable of 2nd disconnect statement
--
-- Operator variables:
--     None
--
-- Globals:
--     None

--------------------------------------------------------------------------------
 
body

    -- If pinlist is NOT empty set, then run: 
    
    if dp_ptc(FX1_plist) <> <::> then 
        set digital pin FX1_plist fx1 driver static tristate 
 
        disconnect digital pin FX1_plist from dcl 
        disconnect digital pin FX1_plist fx1 from all relays 
    end_if
    
end_body
 

procedure Clear_sync_bus

--------------------------------------------------------------------------------
-- Description:
--  This routine places sync_bus in a known state by clearing all syncs and triggers from the bus.  This routine 
--  is called during OnInit_Connect in the OnInitFlow.
--     
-- History:
--  03/19/2010  PLA      -- Initial Version 
--  12/07/2011  PLA      -- Added check for instruments in cage1 before running code that affects them
--
-- Operator variables:
--     None
--
-- Globals:
--     None

--------------------------------------------------------------------------------
local

boolean:    cage1_has_ovi

end_local


body

    initialize cx sync

    ----- This makes sure SSBI doesn't drive all sync clock lines with 33MHz -----
    disconnect cx cpu trigger from sync1
    disconnect cx cpu trigger from sync2
    disconnect cx cpu trigger from sync3
    disconnect cx cpu trigger from sync4
    disconnect cx cpu trigger from sync5
    disconnect cx cpu trigger from sync6
    disconnect cx cpu trigger from sync7
    disconnect cx cpu trigger from sync8
    ------------------------------------------------------------------------------
    disconnect cx cage0 dut line from system sync1
    disconnect cx cage0 dut line from system sync2
    disconnect cx cage0 dut line from system sync3
    disconnect cx cage0 dut line from system sync4
    disconnect cx cage0 dut line from system sync5
    disconnect cx cage0 dut line from system sync6
    disconnect cx cage0 dut line from system sync7
    disconnect cx cage0 dut line from system sync8

    cage1_has_ovi = iu_present("ovi", [65])

    if cage1_has_ovi then  -- are there cards in cage1?
        disconnect cx cage1 dut line from system sync1
        disconnect cx cage1 dut line from system sync2
        disconnect cx cage1 dut line from system sync3
        disconnect cx cage1 dut line from system sync4
        disconnect cx cage1 dut line from system sync5
        disconnect cx cage1 dut line from system sync6
        disconnect cx cage1 dut line from system sync7
        disconnect cx cage1 dut line from system sync8
    end_if
     
    disconnect cx system sync1
    disconnect cx system sync2
    disconnect cx system sync3
    disconnect cx system sync4
    disconnect cx system sync5
    disconnect cx system sync6
    disconnect cx system sync7
    disconnect cx system sync8

end_body



procedure Define_captures(DOUT_pin)
--------------------------------------------------------------------------------
--  
in pin		: DOUT_pin

-------------------------------------------------------------------------------------------------
--  This routine is a placeholder for defining digital capture waveforms.  It will clear memory 
--  allocations, then allocate memory space for each defined waveform.
--
--  This procedure is called during OnLoad flow in Define_Capture_WF flow node.
-------------------------------------------------------------------------------------------------
 
local

end_local

body
    clear digital capture all waveforms

--***************************************************************
-- DEFINE DSP CAPTURE WAVEFORMS HERE
--***************************************************************

-- Example:
--  define digital capture waveform "READ_CURRENT_DATA_CHAN_AIN1" on DOUT_pin for 1 vectors serial msb mode 12 bits


-- For AUX I2C Bus (Programable Oscillators)
   define digital reg_send fx1 waveform "OSC_I2C_WRITE"    on SER_X2_AUXSDA              for 8  vectors serial msb mode 8 bits    
   define digital capture  fx1 waveform "OSC_I2C_READ"     on SER_X2_AUXSDA              for 6  vectors serial msb mode 8 bits
   
-- For Port Expander
   define digital reg_send fx1 waveform "PORTEXP_I2C_WRITE"    on SER_X2_AUXSDA          for 2  vectors serial msb mode 8 bits    
   define digital capture  fx1 waveform "PORTEXP_I2C_READ"     on SER_X2_AUXSDA          for 1  vectors serial msb mode 8 bits
   
   
-- FPGA
   define digital capture fx1 waveform  "FPGA_SRC_RD"       on  FPGA_SDOUT                  for 1  vectors serial msb mode 32 bits
   define digital reg_send fx1 waveform "FPGA_SRC_WR"       on  FPGA_SDIN                   for 2 vectors  serial msb mode 32 bits

 
-- For Link StartUp Time and PowerUp time  
--     define digital capture fx1 waveform  "Link_Cap"     on SER_TXSCL_MFP10    for 750  vectors serial msb mode 4 bits               
--     define digital capture fx1 waveform  "PwrUp_Cap"    on SER_TXSCL_MFP10    for 1000 vectors serial msb mode 8 bits     
   
--     define digital capture fx1 waveform "cap_0p30" on SER_RXSDA_MFP9+SER_TXSCL_MFP10  for 256 vectors parallel mode 
--     define digital capture fx1 waveform "cap_0p70" on SER_RXSDA_MFP9+SER_TXSCL_MFP10  for 256 vectors parallel mode
   
    
---------------------- from HS87 for 16 bits UART/I2C communitcation --------------------------------------------------   
  -- Serializer
  define digital reg_send fx1 waveform "SER_I2C_WRITE"    on SER_GPIO19_RXSDA      for 8  vectors serial msb mode 8 bits 
  define digital capture  fx1 waveform "SER_I2C_READ"     on SER_GPIO19_RXSDA      for 1  vectors serial msb mode 8 bits     
  define digital capture  fx1 waveform "SER_I2C_READ1"    on SER_GPIO19_RXSDA      for 1  vectors serial msb mode 8 bits
  define digital capture  fx1 waveform "SER_I2C_READ2"    on SER_GPIO19_RXSDA      for 2  vectors serial msb mode 8 bits
  define digital capture  fx1 waveform "SER_I2C_READ3"    on SER_GPIO19_RXSDA      for 3  vectors serial msb mode 8 bits
  define digital capture  fx1 waveform "SER_I2C_READ4"    on SER_GPIO19_RXSDA      for 4  vectors serial msb mode 8 bits
  define digital capture  fx1 waveform "SER_I2C_READ5"    on SER_GPIO19_RXSDA      for 5  vectors serial msb mode 8 bits
  define digital capture  fx1 waveform "SER_I2C_READ6"    on SER_GPIO19_RXSDA      for 6  vectors serial msb mode 8 bits
  define digital capture  fx1 waveform "SER_I2C_READ7"    on SER_GPIO19_RXSDA      for 7  vectors serial msb mode 8 bits
  define digital capture  fx1 waveform "SER_I2C_READ8"    on SER_GPIO19_RXSDA      for 8  vectors serial msb mode 8 bits
  
  define digital reg_send fx1 waveform "SER_UART_WRITE"          on SER_GPIO19_RXSDA     for 8 vectors serial lsb mode 9 bits
  define digital capture fx1 waveform "SER_UART_WRITE_CAPTURE"   on SER_GPIO20_TXSCL     for 30 vectors serial msb mode 4 bits
  define digital capture fx1 waveform "SER_UART_READ_CAPTURE1"   on SER_GPIO20_TXSCL     for 64 vectors serial msb mode 4 bits
  define digital capture fx1 waveform "SER_UART_READ_CAPTURE2"   on SER_GPIO20_TXSCL     for 76 vectors serial msb mode 4 bits
  define digital capture fx1 waveform "SER_UART_READ_CAPTURE3"   on SER_GPIO20_TXSCL     for 90 vectors serial msb mode 4 bits
  define digital capture fx1 waveform "SER_UART_READ_CAPTURE4"   on SER_GPIO20_TXSCL     for 102 vectors serial msb mode 4 bits
  define digital capture fx1 waveform "SER_UART_READ_CAPTURE5"   on SER_GPIO20_TXSCL     for 114 vectors serial msb mode 4 bits
  define digital capture fx1 waveform "SER_UART_READ_CAPTURE6"   on SER_GPIO20_TXSCL     for 126 vectors serial msb mode 4 bits
  define digital capture fx1 waveform "SER_UART_READ_CAPTURE7"   on SER_GPIO20_TXSCL     for 138 vectors serial msb mode 4 bits
  define digital capture fx1 waveform "SER_UART_READ_CAPTURE8"   on SER_GPIO20_TXSCL     for 150 vectors serial msb mode 4 bits
  
  -- Deserializer
  define digital reg_send fx1 waveform "DES_I2C_WRITE"    on DES_RXSDA     for 8  vectors serial msb mode 8 bits 
  define digital capture  fx1 waveform "DES_I2C_READ"     on DES_RXSDA     for 1  vectors serial msb mode 8 bits     
  define digital capture  fx1 waveform "DES_I2C_READ1"    on DES_RXSDA     for 1  vectors serial msb mode 8 bits
  define digital capture  fx1 waveform "DES_I2C_READ2"    on DES_RXSDA     for 2  vectors serial msb mode 8 bits
  define digital capture  fx1 waveform "DES_I2C_READ3"    on DES_RXSDA     for 3  vectors serial msb mode 8 bits
  define digital capture  fx1 waveform "DES_I2C_READ4"    on DES_RXSDA     for 4  vectors serial msb mode 8 bits
  define digital capture  fx1 waveform "DES_I2C_READ5"    on DES_RXSDA     for 5  vectors serial msb mode 8 bits
  define digital capture  fx1 waveform "DES_I2C_READ6"    on DES_RXSDA     for 6  vectors serial msb mode 8 bits
  define digital capture  fx1 waveform "DES_I2C_READ7"    on DES_RXSDA     for 7  vectors serial msb mode 8 bits
  define digital capture  fx1 waveform "DES_I2C_READ8"    on DES_RXSDA     for 8  vectors serial msb mode 8 bits

  define digital reg_send fx1 waveform "DES_UART_WRITE"          on DES_RXSDA     for 8 vectors serial lsb mode 9 bits
  define digital capture fx1 waveform "DES_UART_WRITE_CAPTURE"   on DES_TXSCL     for 30 vectors serial msb mode 4 bits
  define digital capture fx1 waveform "DES_UART_READ_CAPTURE1"   on DES_TXSCL     for 64 vectors serial msb mode 4 bits
  define digital capture fx1 waveform "DES_UART_READ_CAPTURE2"   on DES_TXSCL     for 76 vectors serial msb mode 4 bits
  define digital capture fx1 waveform "DES_UART_READ_CAPTURE3"   on DES_TXSCL     for 90 vectors serial msb mode 4 bits
  define digital capture fx1 waveform "DES_UART_READ_CAPTURE4"   on DES_TXSCL     for 102 vectors serial msb mode 4 bits
  define digital capture fx1 waveform "DES_UART_READ_CAPTURE5"   on DES_TXSCL     for 114 vectors serial msb mode 4 bits
  define digital capture fx1 waveform "DES_UART_READ_CAPTURE6"   on DES_TXSCL     for 126 vectors serial msb mode 4 bits
  define digital capture fx1 waveform "DES_UART_READ_CAPTURE7"   on DES_TXSCL     for 138 vectors serial msb mode 4 bits
  define digital capture fx1 waveform "DES_UART_READ_CAPTURE8"   on DES_TXSCL     for 150 vectors serial msb mode 4 bits


----OTP----  
  define digital reg_send fx1 waveform "OTP_SEND"                   on  SER_GPIO19_RXSDA     for 12 vectors serial lsb mode 9 bits
  define digital capture fx1 waveform "OTP_CAPTURE1"                on SER_GPIO20_TXSCL     for 32 vectors serial msb mode 4 bits
  define digital capture fx1 waveform "OTP_CAPTURE2"                on SER_GPIO20_TXSCL     for 44 vectors serial msb mode 4 bits
  define digital capture fx1 waveform "OTP_CAPTURE3"                on SER_GPIO20_TXSCL     for 56 vectors serial msb mode 4 bits
  define digital capture fx1 waveform "OTP_CAPTURE4"                on SER_GPIO20_TXSCL     for 68 vectors serial msb mode 4 bits

  define digital reg_send fx1 waveform "OTP_WRITE_SEND"             on  SER_GPIO19_RXSDA    for 2061 vectors serial lsb mode 9 bits     -----2592
  define digital reg_send fx1 waveform "OTP_WRITE_READ_SEND_HDMI2X" on SER_GPIO19_RXSDA  for 1824 vectors serial lsb mode 9 bits ----
--  define digital reg_send fx1 waveform "OTP_WRITE_READ_SEND"        on  SER_GPIO19_RXSDA    for 616 vectors serial lsb mode 9 bits
  define digital capture fx1 waveform  "OTP_CAPTURE_READ_BURST"     on SER_GPIO20_TXSCL     for 136 vectors serial msb mode 4 bits  ----2x68
--  define digital capture fx1 waveform  "OTP_CAPTURE_READ_BURST_ALL" on SER_GPIO20_TXSCL     for 5100 vectors serial msb mode 4 bits  ----75x68

  define digital capture fx1 waveform  "OTP_CAPTURE_READ_BURST_ALL_GMSL1_HDMI1X" on  SER_GPIO20_TXSCL   for 5304 vectors serial msb mode 4 bits  ----78x68
  define digital capture fx1 waveform  "OTP_CAPTURE_READ_BURST_ALL_HDMI2X" on  SER_GPIO20_TXSCL   for 15504 vectors serial msb mode 4 bits  ----228x68

-----fall and rise time
    define digital capture fx1 waveform "cap_0p30" on SER_GPIO19_RXSDA + SER_GPIO20_TXSCL for 256 vectors parallel mode 
    define digital capture fx1 waveform "cap_0p70" on SER_GPIO19_RXSDA + SER_GPIO20_TXSCL    for 256 vectors parallel mode

end_body

