use module "./SERDES_Pins.mod"
use module "./user_globals.mod"
use module "./gpio.mod"

const

    -- FPGA RegSend/label constants
    FPGA_SRC_WR         = "srcf_wr"
    FPGA_SRC_RD         = "srcf_rd"
    FPGA_SRC_RST        = "srcf_rst"
    
    FPGA_DUMMY_SECONDWORD = 0x00000000
    gs_FPGA_Pattern     = "FPGA"
    LOOP_MODE           = 16#8000_0000

    
    KNOWN_DATA          = 2#11
    LAST_RAM_LOCATION   = 2147
    
    VCAPEN              = 0x1
    VPATCMP             = 0x40
    APATXMIT            = 0x02
    AUD_ENABLE          = 0x20
    APATCMPSER          = 0x80
    APATCMPDES          = 0x100
    
    
    AUD_I2S_16          = 0
    AUD_I2S_32          = 40
    AUD_I2S_16_HOLD     = 110
    AUD_I2S_32_CLEAR    = 1000
    AUD_8ch_TDM         = 200
    
    GRAD_PAT_ADDR       = 2200


end_const

global

----------------------- FPGA Registers -------------------------------------------
   word   :  VPSA_REG                    = 1
   word   :  VRES_REG                    = 2
   word   :  VH_REG                      = 3
   word   :  VV_REG                      = 4
   word   :  VRPT_REG                    = 5
   word   :  VBRAM_WRITE_REG             = 6
   word   :  VBRAM_READ_REG              = 7
   word   :  VFRAME_DEL_REG              = 8
   word   :  oLDI_PORT_EN                = 10
   word   :  BIT_MASK_REG                = 11         -- compare bit mask register
   word   :  CTRLREG                     = 12
   word   :  CONFIG                      = 13
   word   :  CBIT                        = 14
   word   :  OREG                        = 17         -- IO Register (for controlling DNUT inputs)
   word   :  DDR_WR_DATA                 = 18
   word   :  DDR_RD_DATA                 = 19
   word   :  DDR_ADDR                    = 20

   word   :  BAUDGENINC                  = 21         -- Sets the UART communication Speed
   word   :  SER_UART_SEND_DATA          = 22
   word   :  SER_UART_ARB                = 23
   word   :  SER_UART_IN_DATA            = 24
   word   :  DES_UART_SEND_DATA          = 25
   word   :  DES_UART_ARB                = 26
   word   :  DES_UART_IN_DATA            = 27
   word   :  I2C_DIVIDER                 = 28       -- Sets I2C Frequency
   word   :  SER_I2C_SEND_DATA           = 29
   word   :  SER_I2C_ARB                 = 30
   word   :  SER_I2C_IN_DATA             = 31
   word   :  DES_I2C_SEND_DATA           = 32
   word   :  DES_I2C_ARB                 = 33
   word   :  DES_I2C_IN_DATA             = 34
   
   word   :  SERDES_STATUS               = 36
   
   word   :  GPIO_CONTROL                = 37       -- [9]=1 Start Gpio Src Capture, [8]=1 Transmit OSC frequency on DNUT_RG_RXC, 
                                              -- [7]=1 Transmit OSC frequency on DNUT_GPIO4, [7:6] = 3 Transmit OSCx2 frequency on DNUT_GPIO4
   
   word   :  oLDI_RSLT1_REG              = 38
   word   :  oLDI_FRMCNT1                = 39
   word   :  oLDI_LINECNT1               = 40
   word   :  oLDI_PIXELCNT1              = 41
   word   :  oLDI_FRMSTADDR1             = 42
   word   :  oLDI_TOTPIXCNT1             = 43
   word   :  oLDI_BITFAIL1               = 44
   word   :  oLDI_FAILADDR1              = 45
   word   :  oLDI_RSLT2_REG              = 46
   word   :  oLDI_FRMCNT2                = 47
   word   :  oLDI_LINECNT2               = 48
   word   :  oLDI_PIXELCNT2              = 49
   word   :  oLDI_FRMSTADDR2             = 50
   word   :  oLDI_TOTPIXCNT2             = 51
   word   :  oLDI_BITFAIL2               = 52
   word   :  oLDI_FAILADDR2              = 53
   word   :  VCMPRPT_REG                 = 56       -- Number of frames to compare
   word   :  oLDI_COMP_MODE              = 57
   word   :  oLDIA_FREQ                  = 60       -- oLDI Frequency of oLDI port A
   word   :  OSC1FREQ                    = 61
   word   :  HIZDEL_REG                  = 62       -- Delay (in usec) for inputs to go HIZ after PWDN rising edge
   word   :  APSA_REG                    = 64
   word   :  ATPLIM_REG                  = 65
   word   :  ARPT_REG                    = 66
   word   :  ABRAM_WRITE_REG             = 67
   word   :  ABRAM_READ_REG              = 68
   word   :  ACMPSA_REG                  = 69
   word   :  ACMPRPT_REG                 = 70
   word   :  ACAPBRAM_SER_READ_REG       = 71
   word   :  ACAPBRAM_DES_READ_REG       = 72
   word   :  ARESULT_SER                 = 73
   word   :  AVCOUNT_SER                 = 74
   word   :  ARESULT_DES                 = 75
   word   :  AVCOUNT_DES                 = 76
   word   :  GPIO_SOURCE_RAM_DATA        = 77
   word   :  GPIO_MASK                   = 78
   word   :  GPIO_CAPTURE_CONTROL        = 79
   word   :  GPIO_CONTROL_REG            = 80
   word   :  GPIO_CLOCK_DIVIDER          = 81
   word   :  GPIO_CLK_DELAY              = 82
   word   :  GPIO_NUM_CAPS_CAPTURED      = 83
   word   :  GPIO_NUM_FAILING_VECTORS    = 84
   word   :  GPIO_TEST_RESULTS           = 85
   word   :  GPIO_CAP_MATRIX_SETUP       = 86
   word   :  GPIO_SOURCE_MATRIX_SETUP    = 87
   word   :  GPIO_LOOPBACK_MATRIX_SETUP  = 88
   word   :  GPIO_CAPTURE_RAM_READBACK   = 89
   word   :  GPIO_SOURCE_RAM_READBACK    = 90
   word   :  SER_PT1_I2C_SEND_DATA       = 92
   word   :  SER_PT1_I2C_ARB             = 93
   word   :  SER_PT1_I2C_IN_DATA         = 94
   word   :  SER_PT1_UART_SEND_DATA      = 95
   word   :  SER_PT1_UART_ARB            = 96
   word   :  SER_PT1_UART_IN_DATA        = 97
   word   :  DES_PT1_I2C_SEND_DATA       = 98
   word   :  DES_PT1_I2C_ARB             = 99
   word   :  DES_PT1_I2C_IN_DATA         = 100
   word   :  DES_PT1_UART_SEND_DATA      = 101
   word   :  DES_PT1_UART_ARB            = 102
   word   :  DES_PT1_UART_IN_DATA        = 103
   word   :  SER_PT2_I2C_SEND_DATA       = 104
   word   :  SER_PT2_I2C_ARB             = 105
   word   :  SER_PT2_I2C_IN_DATA         = 106
   word   :  SER_PT2_UART_SEND_DATA      = 107
   word   :  SER_PT2_UART_ARB            = 108
   word   :  SER_PT2_UART_IN_DATA        = 109
   word   :  DES_PT2_I2C_SEND_DATA       = 110
   word   :  DES_PT2_I2C_ARB             = 111
   word   :  DES_PT2_I2C_IN_DATA         = 112
   word   :  DES_PT2_UART_SEND_DATA      = 113
   word   :  DES_PT2_UART_ARB            = 114
   word   :  DES_PT2_UART_IN_DATA        = 115
   word   :  SPI_COMMAND_REG             = 116
   word   :  SPI_STATUS                  = 117
   word   :  UART_PT_CTRL_REG            = 118      ----3BITS BIT2 ENABLE BIT1 AND BIT0 IS FOR SER OR DES. b100: mux DES_PT1 mux to Des main channel control
                                                    ----3BITS BIT2 ENABLE BIT1 AND BIT0 IS FOR SER OR DES. b101: mux DES_PT2 mux to Des main channel control
                                                    ----3BITS BIT2 ENABLE BIT1 AND BIT0 IS FOR SER OR DES. b110: mux SER_PT1 mux to SER main channel control
                                                    ----3BITS BIT2 ENABLE BIT1 AND BIT0 IS FOR SER OR DES. b110: mux SER_PT2 mux to SER main channel control                                                   


   word   :  FPGA_DIE_TEMP               = 119
   word   :  oLDI_BIT_RATE               = 123
   word   :  FWREV_REG                   = 127       -- FirmWare Revision
   word   :  OREG2                       = 133       -- IO Register (for controlling DNUT (HS84) inputs)
   word   :  HS84DES_UART_SEND_DATA      = 134
   word   :  HS84DES_UART_ARB            = 135
   word   :  HS84DES_UART_IN_DATA        = 136

 ------------------------------------------------------------------------------------------
    

end_global


procedure fpga_rw_datapair(FpgaName, OpCode, RegAddr, PatOffs, SecondWord)
--------------------------------------------------------------------------------
--  Writes a pair of 32-bit words to the SourceFPGA
--      Reads back the second word, if FpgaName is FPGA_*_RD ("*_rd")
--
in string[20]:          FpgaName        -- use the constants FPGA_SRC_WR, FPGA_SRC_RD between read or write
in word:                OpCode          -- 8bit FPGA OpCode
in word:                RegAddr         -- 8bit FPGA Register Address
in word:                PatOffs         -- 12bit Pattern Offset value
in_out multisite lword: SecondWord      -- 32bit Word to write as the second word, or read back during second word
--
--------------------------------------------------------------------------------

local
    multisite word:     msw[4]          -- two 32-bit data-words encoded into 4 16bit cadence-regsend-words
    multisite word:     tmp
    multisite lword:    capt32[1]       -- holds the digital capture vector
    boolean:            pat_ok          -- wait for digital ...: true if pattern finished/captured; false if timed out
    boolean:            readback=false  -- if set true, run 'digital capture' to grab data back
    
    string[20]:         FpgaRead = "FPGA_SRC_RD"
    string[20]:         FpgaWrite = "FPGA_SRC_WR"
    
end_local

body

    -- initialize data array to all 0s
    msw = 0x0000

    ----------------------------------------------------------------
    -- Determine if Read or Write from the register
    ----------------------------------------------------------------
    -- parse FpgaName to see if its _rd or _wr
    if FpgaName[5:7] ="_rd" then
        readback = true
    else
        readback = false
    end_if


    ----------------------------------------------------------------------------
    -- Build the Control Register 32-bit word from OpCode, RegAddr, and PatOffs
    ----------------------------------------------------------------------------
    -- MostSignificantWord of Control register ( [OpCode][RegAddr] ) goes in msw[site, 1]
    tmp = 0x0000
    tmp = tmp | ( (OpCode  & 0xFF) << 8 )
    tmp = tmp | ( (RegAddr & 0xFF) << 0 )
    if readback then
        tmp = tmp | 0x0100      -- set the read bit in lsb of the address byte for readback
    end_if
    scatter_1d(tmp, msw, 1) -- msw[site,1] = tmp[site], for all sites
    
    -- LeastSignificantWord of Control register ( [PatOffs] ) goes in msw[site, 2]
    tmp = PatOffs
    scatter_1d(tmp, msw, 2) -- msw[site,2] = tmp[site], for all sites

    ----------------------------------------------------------------
    -- Build the data value 32-bit word from SecondWord
    ----------------------------------------------------------------
    -- If readback, SecondWord is dummy 0s, else use parameter
    if readback then
        SecondWord = FPGA_DUMMY_SECONDWORD
    end_if

    -- MostSigWord of ValueToWrite goes in msw[site,3]
    tmp = word( (SecondWord>>16) & 0xFFFF )
    scatter_1d(tmp, msw, 3)
    
    -- LeastSigWord of ValueToWrite goes in msw[site,4]
    tmp = word( (SecondWord>> 0) & 0xFFFF )
    scatter_1d(tmp, msw, 4)

    ----------------------------------------------------------------
    -- RegSend the data to the FPGA
    ----------------------------------------------------------------
    load digital reg_send fx1 waveform FpgaWrite with msw
    enable digital reg_send fx1 waveform FpgaWrite
    if readback then
        enable digital capture fx1 waveform FpgaRead
    end_if

    execute digital pattern gs_FPGA_Pattern at label FpgaName run to end wait
    
    ----------------------------------------------------------------
    -- 'digital capture' the data from the FPGA SDOUT if readback
    ----------------------------------------------------------------
    if  readback then
        wait for digital capture waveform FpgaRead timeout 5ms into pat_ok     -- true if not timed out; false if timed out

        if pat_ok then
            read digital capture waveform FpgaRead into capt32
        else
            capt32 = 0xFEEDF00D
  --          hwcheck_PrintBannerMessage("TIMEOUT in fpga_rw_datapair()", "Digital Capture @""+FpgaRead+"@" timed out", "If this happens with KGU, ask TestEngineer for help")
        end_if
        SecondWord = gather_1d(capt32, 1) -- SecondWord[site] = capt32[site,1]

    end_if


end_body




procedure fpga_reset(FPGA)
--------------------------------------------------------------------------------
-- This function resets the FPGA SPI bus state machine and clears the registers
-- It does not clear BRAM (pattern) memory
in string[5]   : FPGA

body

    execute digital pattern gs_FPGA_Pattern at label FPGA_SRC_RST wait
    
end_body


procedure fpga_enable_site(action)
--------------------------------------------------------------------------------
-- This function enables clock and data from the FPGA
in string [3]    : action

local multisite   lword : data

body

    if(action == "ON") then
       data = 1
    else
       data = 0
    endif
    
    fpga_write_register(SITE_EN_REG, data)
    
end_body



procedure Check_FPGA(force_load)
--------------------------------------------------------------------------------
--  This function checks a register in the FPGA
--  If the contents of this register has not changed then 
--  it is assumed power has not been lost and that the patterns in the RAM chip
--  are ok as well.
--  If data has changed, patterns are re-loaded
in boolean             : force_load

local multisite lword  : data, wval
local word             : site, idx

body

   current_active_sites = get_active_sites()
   sites = word(len(current_active_sites))

   set digital pin fpga_pattern_pins levels to vil 0mV vih 2.7V vol 500mV voh 1.4V  -- vih 3.2 b4 zin
--   set digital pin FPGA_PINS levels to vil 0mV vih 3.2V vol 500mV voh 2.7V
   
-- Reset FPGA
   fpga_reset("FPGA1")
   


-- Read data from the last Audio BRAM location
   wval = LAST_RAM_LOCATION
   fpga_write_register("FPGA1", APSA_REG, wval)
   data = fpga_read_register("FPGA1", ABRAM_READ_REG)


-- Reload patterns if data is not as expected   
   for idx = 1 to sites do  
       site = current_active_sites[idx]
       if((data[site] <> KNOWN_DATA)  OR force_load)then
         load_fpga_patterns
         fpga_compose_gpio_BRAM_patterns
         Reload_GPIO_Patterns = FALSE
         break
       end_if
   endfor
   
   
-- Reload GPIO Patterns if GPIO fails consecutively  (see procedure KeepTrackOfBinResults in gpio.mod)
   if Reload_GPIO_Patterns then
      fpga_compose_gpio_BRAM_patterns
      Reload_GPIO_Patterns  = FALSE
   endif
   
   
end_body




procedure fpga_write_register(FPGA, reg, data)
--------------------------------------------------------------------------------
--
in string[5]          : FPGA   -- "FPGA1" or "FPGA2"
in word               : reg    -- FPGA register to write to
in multisite lword    : data   -- data to be written to register

local word            : dev


body

     if FPGA == "FPGA1" then
        dev = 0x00
     elseif FPGA == "FPGA2" then
        dev = 0x40
     endif
     
     fpga_rw_datapair(FPGA_SRC_WR, dev, reg, 0x00, data)
       

end_body

function fpga_read_register(FPGA, reg) : multisite lword
--------------------------------------------------------------------------------
--  
in string[5]          : FPGA   -- "FPGA1" or "FPGA2"
in word               : reg    -- FPGA register to read from

local multisite lword : writeVal
local word            : dev

body

     if FPGA == "FPGA1" then
        dev = 0x00
     elseif FPGA == "FPGA2" then
        dev = 0x40
     endif

    fpga_rw_datapair(FPGA_SRC_RD, dev, reg, 0x00, writeVal)
    return(writeVal)

end_body









procedure fpga_debug(data, failsites)
--------------------------------------------------------------------------------
--  Prints the result of failing sites to the screen
--  Also prints 10 vectors to the screen, 5 before and 5 after failing vector
in multisite lword     : data
in word list[8]        : failsites         -- failing sites


local integer          : idx
local multisite lword  : data2, data3, data4
local word             : csite
local lword            : stadd, endadd


body


    if( len(failsites) > 0) then
        data2 = fpga_read_register(VMATCHCNT_REG)
        data3 = fpga_read_register(VVCOUNT_REG)
        data4 = fpga_read_register(BITFAIL_REG)

        
        for idx= 1 to len(failsites) do
            csite = failsites[idx]
            println(stdout, "Site:", failsites[idx], "  Result =", data[csite])
            
            if(data2[csite] < 290 ) then
               println(stdout, "Match found at address =" ,data2[csite]-1)
               println(stdout, "Pattern Compare failed at SDRAM address ", data2[csite]+data3[csite]-1)
               println(stdout, "Failing bits are                         ", data4[csite]!b!z:16)
            else
               println(stdout, "No Match Found")
            endif
               

            
            
            if(data2[csite] < 290) then    -- if match was found display 5 vectors before and after first failure
               stadd  = data2[csite] + data3[csite] - 5
               endadd = data2[csite] + data3[csite] + 5
            else
               stadd = 0
               endadd = 49
            endif
            
            FPGA_Read_SDRAM_Memory(stadd, endadd, csite,"bin")

        endfor
    endif


end_body



procedure fpga_Set_DNUT_Pins(FPGA, CFG2, CFG1, CFG0, PWDN, latch)
--------------------------------------------------------------------------------
-- This function is used to drive the DNUT pins. The DNUT pins are driven by an FPGA
-- The FPGA contains a register with the mapping : 
-- CFG2[3], CFG1[2], CFG0[1], PWDN[0]

in string[5]           : FPGA      -- "FPGA1" or "FPGA2"
in word                : CFG2      --  0 or 1
in word                : CFG1      --  0 or 1
in word                : CFG0      --  0 or 1
in word                : PWDN      --  0 or 1
in boolean             : latch     -- true or false


local multisite  lword : data
local multisite  word  : temp


body


   -- CFG1[2], CFG0[1], PWDN[0]
   temp = (CFG2<<3) + (CFG1<<2) + (CFG0<<1)
   data = lword(temp)
   
   if latch then
      fpga_write_register(FPGA, OREG, data)  -- power down pin go to low
   endif
     
 -- Add PWDN value
    temp = temp + (PWDN<<0)
    data = lword(temp)
    fpga_write_register(FPGA, OREG, data)

   
end_body





procedure fpga_set_I2C_Frequency(FPGA, I2C_Freq)
--------------------------------------------------------------------------------
-- This procedure sets the I2C Frequency of the I2C Master within the FPGA
-- SYS_CLK is defined in user_globals.mod and is 150MHz

in string[5]   : FPGA         -- "FPGA1" or "FPGA2"
in  float      : I2C_Freq

local multisite lword : divider
local word            : dev

body

     divider = lword (SYS_CLK / (4.0 * I2C_Freq))          
     fpga_write_register(FPGA, I2C_DIVIDER, divider)
     I2C_FREQ = I2C_Freq


end_body

procedure fpga_I2C_Write(FPGA, source, destination_i2c_id, reg, bytes, data)
--------------------------------------------------------------------------------
-- This function will initiate an I2C Write transaction on the I2C pins connected to
-- "source". Up to three bytes can be written with this function. I2C Frequency must
-- be previously set with the fpga_set_I2C_Frequency procedure.

in string[5] : FPGA            -- "FPGA1" or "FPGA2"
in string[8] : source          -- "SER", "DES", "SER_PT1", "SER_PT2", "DES_PT1", or "DES_PT2"  (FPGA sends I2C transaction here)
in lword     : destination_i2c_id    -- I2C slave device ID to write to (this is the destination i2c device)
in lword     : reg          -- starting register address
in lword     : bytes        -- number of bytes to read (1,2, or 3)
in lword     : data         -- data to write

local multisite lword : id_reg
local multisite lword : i2c_data

body

     id_reg   = destination_i2c_id + (reg << 8) + (bytes << 24)
     i2c_data = data
     

     if source = "SER" then
        fpga_write_register(FPGA, SER_I2C_SEND_DATA, i2c_data)       -- this must be first
        fpga_write_register(FPGA, SER_I2C_ARB, id_reg)               -- then this
	       
     elseif source = "DES" then
        fpga_write_register(FPGA, DES_I2C_SEND_DATA, i2c_data)       -- this must be first
        fpga_write_register(FPGA, DES_I2C_ARB, id_reg)               -- then this
	
     elseif source = "SER_PT1" then
        id_reg = id_reg | (1<<31)   -- force 8 bit address mode
        fpga_write_register(FPGA, SER_PT1_I2C_SEND_DATA, i2c_data)   -- this must be first
        fpga_write_register(FPGA, SER_PT1_I2C_ARB, id_reg)           -- then this
     
     elseif source = "SER_PT2" then
        id_reg = id_reg | (1<<31)   -- force 8 bit address mode
        fpga_write_register(FPGA, SER_PT2_I2C_SEND_DATA, i2c_data)   -- this must be first
        fpga_write_register(FPGA, SER_PT2_I2C_ARB, id_reg)           -- then this
	
     elseif source = "DES_PT1" then
        id_reg = id_reg | (1<<31)   -- force 8 bit address mode
        fpga_write_register(FPGA, DES_PT1_I2C_SEND_DATA, i2c_data)   -- this must be first
        fpga_write_register(FPGA, DES_PT1_I2C_ARB, id_reg)           -- then this
	
     elseif source = "DES_PT2" then
        id_reg = id_reg | (1<<31)   -- force 8 bit address mode
        fpga_write_register(FPGA, DES_PT2_I2C_SEND_DATA, i2c_data)   -- this must be first
        fpga_write_register(FPGA, DES_PT2_I2C_ARB, id_reg)           -- then this
     endif


end_body

function fpga_I2C_Read(FPGA, source, destination_i2c_id, reg, bytes) : multisite lword
--------------------------------------------------------------------------------
-- This function will initiate an I2C Read transaction on the I2C pins connected to
-- "source". Up to three bytes can be read with this function. I2C Frequency must
-- be previously set with the fpga_set_I2C_Frequency procedure.

in string[5] : FPGA            -- "FPGA1" or "FPGA2"
in string[8] : source          -- "SER", "DES", "SER_PT1", "SER_PT2", "DES_PT1", or "DES_PT2"  (FPGA sends I2C transaction here)
in lword     : destination_i2c_id    -- I2C slave device ID
in lword     : reg          -- starting register address
in lword     : bytes        -- number of bytes to read (1,2, or 3)

local multisite lword : id_reg
local multisite lword : i2c_data
local word            : fpga_reg1, fpga_reg2

body

     destination_i2c_id = destination_i2c_id + 1            -- set read bit
     id_reg             = destination_i2c_id + (reg << 8) + (bytes << 24)
     
     if source = "SER" then
        fpga_reg1 = SER_I2C_ARB
        fpga_reg2 = SER_I2C_IN_DATA
     elseif source = "DES" then
        fpga_reg1 = DES_I2C_ARB
        fpga_reg2 = DES_I2C_IN_DATA
     elseif source = "SER_PT1" then
        id_reg = id_reg | (1<<31)   -- force 8 bit address mode
        fpga_reg1 = SER_PT1_I2C_ARB
        fpga_reg2 = SER_PT1_I2C_IN_DATA
     elseif source = "SER_PT2" then
        id_reg = id_reg | (1<<31)   -- force 8 bit address mode
        fpga_reg1 = SER_PT2_I2C_ARB
        fpga_reg2 = SER_PT2_I2C_IN_DATA
     elseif source = "DES_PT1" then
        id_reg = id_reg | (1<<31)   -- force 8 bit address mode
        fpga_reg1 = DES_PT1_I2C_ARB
        fpga_reg2 = DES_PT1_I2C_IN_DATA
     elseif source = "DES_PT2" then
        id_reg = id_reg | (1<<31)   -- force 8 bit address mode
        fpga_reg1 = DES_PT2_I2C_ARB
        fpga_reg2 = DES_PT2_I2C_IN_DATA
     endif 
 
 
     fpga_write_register(FPGA, fpga_reg1, id_reg) -- initiates I2C transaction
     


-- Read Captured I2C data
     I2C_wait(bytes)
     i2c_data = fpga_read_register(FPGA, fpga_reg2)
     return(i2c_data)

end_body







procedure fpga_set_UART_Frequency(FPGA, UART_Freq)
--------------------------------------------------------------------------------
-- This procedure sets the I2C Frequency of the I2C Master within the FPGA
-- SYS_CLK is defined in user_globals.mod and is 150MHz

in string[5]  : FPGA         -- "FPGA1" or "FPGA2"
in  float     : UART_Freq


local multisite lword : baudgeninc
local multisite float : temp

body

     temp = 2^16.0 * (UART_Freq/SYS_CLK) + 0.5
     baudgeninc = lword (temp)
     fpga_write_register(FPGA, BAUDGENINC, baudgeninc)
     UART_FREQ = UART_Freq


end_body

procedure fpga_UART_Write(FPGA, source, destination_id, reg, bytes, data)
--------------------------------------------------------------------------------
-- This function will initiate a UART Write transaction on the UART pins connected to
-- the "source". Up to four bytes can be written with this function. UART Frequency must
-- be previously set with the fpga_set_UART_Frequency procedure.

in string[5] : FPGA         -- "FPGA1" or "FPGA2"
in string[8] : source       -- "SER", "DES", "SER_PT1", "SER_PT2", "DES_PT1", or "DES_PT2"  (FPGA sends UART transaction here)
in lword     : destination_id   -- UART slave device ID to Write to
in lword     : reg          -- starting register address
in lword     : bytes        -- number of bytes to read (1,2, or 3)
in lword     : data         -- data to write

local multisite lword : id_reg
local multisite lword : uart_data

body

     id_reg     = destination_id + (reg << 8) + (bytes << 24)
     uart_data  = data


     if source = "SER" then
        fpga_write_register(FPGA, SER_UART_SEND_DATA, uart_data)      -- this must be first
        fpga_write_register(FPGA, SER_UART_ARB, id_reg)               -- then this
        
     elseif source = "DES" then
        fpga_write_register(FPGA, DES_UART_SEND_DATA, uart_data)      -- this must be first
        fpga_write_register(FPGA, DES_UART_ARB, id_reg)               -- then this
	
     elseif source = "SER_PT1" then
        fpga_write_register(FPGA, SER_PT1_UART_SEND_DATA, uart_data)  -- this must be first
        fpga_write_register(FPGA, SER_PT1_UART_ARB, id_reg)           -- then this
	
     elseif source = "SER_PT2" then
        fpga_write_register(FPGA, SER_PT2_UART_SEND_DATA, uart_data)  -- this must be first
        fpga_write_register(FPGA, SER_PT2_UART_ARB, id_reg)           -- then this
	
     elseif source = "DES_PT1" then
        fpga_write_register(FPGA, DES_PT1_UART_SEND_DATA, uart_data)  -- this must be first
        fpga_write_register(FPGA, DES_PT1_UART_ARB, id_reg)           -- then this
	
     elseif source = "DES_PT2" then
        fpga_write_register(FPGA, DES_PT2_UART_SEND_DATA, uart_data)  -- this must be first
        fpga_write_register(FPGA, DES_PT2_UART_ARB, id_reg)           -- then this
     endif


     UART_wait(bytes)


end_body

function fpga_UART_Read(FPGA, source, destination_id, reg, bytes) : multisite lword
--------------------------------------------------------------------------------
-- This function will initiate an UART Read transaction on the UART pins connected to
-- the "source". Up to four bytes can be read with this function. UART Frequency must
-- be previously set with the fpga_set_UART_Frequency procedure.

in string[5] : FPGA         -- "FPGA1" or "FPGA2"
in string[8] : source       -- "SER", "DES", "SER_PT1", "SER_PT2", "DES_PT1", or "DES_PT2"  (FPGA sends UART transaction here)
in lword     : destination_id   -- UART slave device ID to Read from
in lword     : reg          -- starting register address
in lword     : bytes        -- number of bytes to read (1,2, or 3)

local multisite lword : id_reg
local multisite lword : uart_data
local word            : fpga_reg1, fpga_reg2

body

     destination_id = destination_id + 1            -- set read bit
     id_reg         = destination_id + (reg << 8) + (bytes << 24)

     
     if source = "SER" then
        fpga_reg1 = SER_UART_ARB
        fpga_reg2 = SER_UART_IN_DATA
     elseif source = "DES" then
        fpga_reg1 = DES_UART_ARB
        fpga_reg2 = DES_UART_IN_DATA
     elseif source = "SER_PT1" then
        fpga_reg1 = SER_PT1_UART_ARB
        fpga_reg2 = SER_PT1_UART_IN_DATA
     elseif source = "SER_PT2" then
        fpga_reg1 = SER_PT2_UART_ARB
        fpga_reg2 = SER_PT2_UART_IN_DATA
     elseif source = "DES_PT1" then
        fpga_reg1 = DES_PT1_UART_ARB
        fpga_reg2 = DES_PT1_UART_IN_DATA
     elseif source = "DES_PT2" then
        fpga_reg1 = DES_PT2_UART_ARB
        fpga_reg2 = DES_PT2_UART_IN_DATA
     endif


     fpga_write_register(FPGA, fpga_reg1, id_reg) -- initiates UART transaction



-- Read captured UART data
     UART_wait(bytes)
     uart_data = fpga_read_register(FPGA, fpga_reg2) & (2^(8*bytes)-1)  -- mask out unused upper bytes
     return(uart_data)

end_body

procedure UART_wait(bytes)
--------------------------------------------------------------------------------
--  
in   lword    : bytes

local lword   : vectors
local float   : wait_time

body


     vectors = 66 + bytes * 11
     wait_time = float(vectors) / UART_FREQ
     
     if UART_FREQ < 32KHz then
        wait_time = wait_time + 50.0/UART_FREQ
     endif
     
     if wait_time > 300us then
        wait(wait_time)
     endif


end_body

procedure I2C_wait(bytes)
--------------------------------------------------------------------------------
--  
in   lword    : bytes

local lword   : vectors
local float   : wait_time

body


     vectors = (4 + bytes) * 9
     wait_time = float(vectors) / I2C_FREQ
     
     if I2C_FREQ < 20KHz then
        wait_time = wait_time * 1.1
     endif
     
     if wait_time > 300us then
        wait(wait_time)
     endif


end_body

procedure load_fpga_patterns
--------------------------------------------------------------------------------
--  This procedure loads patterns into FPGA RAM memory

local multisite lword   :  writeVal

body

   
    fpga_reset("FPGA1")
    
  -- Load Audio Patterns
    fpga_compose_audio_16bit_pattern
    fpga_compose_audio_32bit_pattern
    fpga_compose_audio_32bit_clear_pattern
    fpga_compose_audio_16bit_hold_pattern
    fpga_compose_audio_8ch_TDM_pattern
    
 -- Load Video Pattern
    fpga_compose_video_gradient_pattern
   
      
   -- Write known data to the last Audio BRAM location.
   -- This will be checked in "Check_FPGA" procedure
    writeVal = LAST_RAM_LOCATION
    fpga_write_register("FPGA1", APSA_REG, writeVal)
    writeVal = KNOWN_DATA
    fpga_write_register("FPGA1", ABRAM_WRITE_REG, writeVal)
    wait(0ms)

end_body

procedure fpga_compose_audio_32bit_pattern
--------------------------------------------------------------------------
--
local
    lword              : PatternStartAddress
    lword              : PatternXLimit
    lword              : data[64]
    word               : idx
end_local
   
body
    

    println(stdout, "Loading FPGA 32 bit Audio Pattern")


    --    WS SD

    for idx=1 to 32 by 2 do
     data[idx+0]      = 2#00
     data[idx+1]      = 2#01
    end_for

    
    for idx=33 to 64 by 2 do
     data[idx+0]      = 2#11
     data[idx+1]      = 2#10
    end_for

    

-- Load pattern into FPGA for transmit & compare purposes
    PatternStartAddress = AUD_I2S_32
    PatternXLimit = 64
    fpga_load_audio_transmit_pattern("FPGA1",PatternStartAddress, PatternXLimit, data)


end_body

procedure fpga_load_audio_transmit_pattern(FPGA, startAddr, xlimit, data)
--------------------------------------------------------------------------------
-- This function loads an audio pattern into the FPGA.
-- This pattern can be used to transmit & compare.

in string [8]         : FPGA        -- "FPGA1" or "FPGA2"
in lword              : startAddr   -- starting address for pattern load
in lword              : xlimit      -- size of pattern
in lword              : data[?]     -- audio pattern data


local word            :             offs        -- pattern address offset
local multisite lword :  writeVal    -- value to write to the RAM address
local word            : dev


body
 
    -- Write to pattern start address register
    writeVal = startAddr
    fpga_write_register(FPGA, APSA_REG, writeVal)

    
    if FPGA == "FPGA1" then  
        dev = 0x00
    elseif FPGA == "FPGA2" then
        dev = 0x40
    endif


    -- load pattern
    for offs = 0 to word(xlimit-1) do
        writeVal = data[offs+1]
	fpga_rw_datapair(FPGA_SRC_WR, dev, ABRAM_WRITE_REG, offs, writeVal)
    end_for


end_body

procedure fpga_send_audio_pattern(FPGA, startAddr, xlimit, RptCnt)
--------------------------------------------------------------------------------
-- This functions sends an audio pattern to the SER.
-- It takes the starting address and size of the pattern
-- to transmit. RptCnt indicates how many times the pattern should be repeated.
in string[5]          : FPGA        -- "FPGA1" or "FPGA2"
in lword              : startAddr   -- value to go in APSA_REG register of FPGA
in lword              : xlimit      -- size of pattern
in lword              : RptCnt      -- Pattern Repeat Count


local multisite lword : writeVal
local multisite lword : data
local word            : dev

body


    writeVal = startAddr
    fpga_write_register(FPGA, APSA_REG, writeVal)
    writeVal = xlimit
    fpga_write_register(FPGA, ATPLIM_REG, writeVal)
    writeVal = RptCnt
    fpga_write_register(FPGA, ARPT_REG, writeVal)

    
    if FPGA == "FPGA1" then
        dev = 0x00
    elseif FPGA == "FPGA2" then
        dev = 0x40
    endif
    

    data = APATXMIT
    fpga_rw_datapair(FPGA_SRC_WR, dev, CTRLREG, 0x00, data)  -- sets APATXMIT bit to 1
    wait(0ms)
    
end_body

procedure FPGA_Read_Audio_Xmit_Memory(FPGA, startAdd, endAdd, _site)
---------------------------------------------------------------------------------
-- This procedure reads pattern data loaded in FPGA memory

in string[5]          :  FPGA      -- "FPGA1" or "FPGA2"
in word               : startAdd, endAdd
in word               : _site

local multisite lword : writeVal
local word            : dev
local word            : idx

body

      if FPGA == "FPGA1" then
        dev = 0x00
      elseif FPGA == "FPGA2" then
        dev = 0x40
      endif

      writeVal = lword(startAdd)
      fpga_write_register(FPGA, APSA_REG, writeVal)

      
      for idx = startAdd to endAdd do
          fpga_rw_datapair(FPGA_SRC_RD, dev, ABRAM_READ_REG, (idx-startAdd), writeVal)
	  println(stdout,"Data at address",idx," is",writeVal[_site]!b)
      end_for

end_body

function fpga_compare_audio_pattern(FPGA, capture_addr, repeat_cnt, compare_addr, DevToCompare) : multisite lword
--------------------------------------------------------------------------------
--  This procedure begins pattern compare of the captured data
--  This procedure assumes the patsize has already been set when pattern was transmitted

in string[5]   :  FPGA            -- "FPGA1" or "FPGA2"
in lword       :  capture_addr    -- beginning address of captured data (usually 0 unless changed to something else)
in lword       :  repeat_cnt      -- Repeat count. Number of times pattern will be looped for compare purposes.
in lword       :  compare_addr    -- beginning address of the compare pattern
in string[8]   :  DevToCompare    -- Compare captured audio on "DUT" or "DNUT"


local multisite lword : writeVal
local word            : dev
local multisite lword : data
local multisite lword : rslt
local word            : reg

body


    writeVal = capture_addr
    fpga_write_register(FPGA, APSA_REG, writeVal)

    writeVal = repeat_cnt
    fpga_write_register(FPGA, ACMPRPT_REG, writeVal)
    
    writeVal = compare_addr
    fpga_write_register(FPGA, ACMPSA_REG, writeVal)
    

    if FPGA == "FPGA1" then
        dev = 0x00
    elseif FPGA == "FPGA2" then
        dev = 0x40
    endif

   
    if DevToCompare == "SER" then
       data = APATCMPSER
       reg  = ARESULT_SER
    elseif DevToCompare == "DES" then
       data = APATCMPDES
       reg  = ARESULT_DES
    endif

-- Execute audio pattern compare     
    fpga_write_register("FPGA1", CTRLREG, data)
    
-- Read Result
    rslt = fpga_read_register(FPGA, reg)
    return(rslt)

end_body

procedure FPGA_Read_Audio_Capture_Memory(FPGA, startAdd, endAdd, _site, Device)
---------------------------------------------------------------------------------
-- This procedure reads pattern data loaded in FPGA memory

in string[5]          :  FPGA      -- "FPGA1" or "FPGA2"
in word               : startAdd, endAdd
in word               : _site
in string[8]          : Device

local multisite lword : writeVal
local word            : dev
local word            : reg
local word            : idx

body

      if FPGA == "FPGA1" then
        dev = 0x00
      elseif FPGA == "FPGA2" then
        dev = 0x40
      endif

      
      if Device == "SER" then
         reg = ACAPBRAM_SER_READ_REG
      elseif Device == "DES" then
         reg = ACAPBRAM_DES_READ_REG
      endif


      writeVal = lword(startAdd)
      fpga_write_register(FPGA, APSA_REG, writeVal)

      
      for idx = startAdd to endAdd do
          fpga_rw_datapair(FPGA_SRC_RD, dev, reg, (idx-startAdd+1), writeVal)
	  println(stdout,"Data at address ",idx!z:4," is ",writeVal[_site]!bz:2)
      end_for

end_body

procedure fpga_stop_audio_pattern
--------------------------------------------------------------------------------
-- This procedure stops a continous audio pattern by clearing the CONT bit

local multisite lword:  writeVal


body

    writeVal = 0x0
    fpga_write_register("FPGA1",ARPT_REG, writeVal)
    wait(0ms)
    
end_body

procedure fpga_compose_audio_32bit_clear_pattern
--------------------------------------------------------------------------
--
local
    lword              : PatternStartAddress
    lword              : PatternXLimit
    lword              : data[64]
    word               : idx
end_local
   
body
    

    println(stdout, "Loading FPGA 32 bit Audio Clear Pattern")


    --    WS SD

    for idx=1 to 32 by 2 do
     data[idx+0]      = 2#00
     data[idx+1]      = 2#00
    end_for

    
    for idx=33 to 64 by 2 do
     data[idx+0]      = 2#10
     data[idx+1]      = 2#10
    end_for

    

-- Load pattern into FPGA for transmit & compare purposes
    PatternStartAddress = AUD_I2S_32_CLEAR
    PatternXLimit = 64
    fpga_load_audio_transmit_pattern("FPGA1",PatternStartAddress, PatternXLimit, data)


end_body

procedure fpga_compose_audio_8ch_TDM_pattern
--------------------------------------------------------------------------
--
local
    lword              : PatternStartAddress
    lword              : PatternXLimit
    lword              : data[256]
    word               : idx
end_local
   
body
    

    println(stdout, "Loading FPGA 8 ch TDM Audio Pattern")


    --    WS SD

    for idx=1 to 32 by 2 do
     data[idx+0]      = 2#00
     data[idx+1]      = 2#01
    end_for

        
    data[33]      = 2#01
    data[34]      = 2#00
    data[35]      = 2#00
    data[36]      = 2#01
    data[37]      = 2#00
    data[38]      = 2#01
    data[39]      = 2#01
    data[40]      = 2#01

    
    for idx=41 to 64 by 2 do
      data[idx+0]      = 2#00
      data[idx+1]      = 2#01
    end_for
    
    for idx=65 to 95 by 4 do
      data[idx+0]      = 2#00
      data[idx+1]      = 2#00
      data[idx+2]      = 2#01
      data[idx+3]      = 2#01
    endfor
    
    for idx=97 to 127 by 4 do
      data[idx+0]      = 2#00
      data[idx+1]      = 2#00
      data[idx+2]      = 2#01
      data[idx+3]      = 2#01
    endfor
    
    for idx=129 to 156 by 2 do
      data[idx+0]      = 2#11
      data[idx+1]      = 2#10
    end_for
    
    for idx=157 to 192 by 2 do
      data[idx+0]      = 2#10
      data[idx+1]      = 2#11
    end_for
    
    data[193] = 2#11
    data[194] = 2#10
    data[195] = 2#11
    data[196] = 2#11
    data[197] = 2#11
    data[198] = 2#10
    data[199] = 2#10
    data[200] = 2#11
    data[201] = 2#10
    data[202] = 2#10
    data[203] = 2#11
    data[204] = 2#11
    data[205] = 2#10
    data[206] = 2#11
    data[207] = 2#11
    data[208] = 2#10
    data[209] = 2#11
    data[210] = 2#11
    data[211] = 2#10
    data[212] = 2#10
    data[213] = 2#10
    data[214] = 2#11
    data[215] = 2#10
    data[216] = 2#10
    data[217] = 2#11
    data[218] = 2#11
    data[219] = 2#11
    data[220] = 2#10
    data[221] = 2#10
    data[222] = 2#11
    data[223] = 2#10
    data[224] = 2#11
    data[225] = 2#11
    data[226] = 2#11
    
    for idx=227 to 256 by 2 do
      data[idx+0]      = 2#10
      data[idx+1]      = 2#11
    end_for

-- Load pattern into FPGA for transmit & compare purposes
    PatternStartAddress = AUD_8ch_TDM
    PatternXLimit = 256
    fpga_load_audio_transmit_pattern("FPGA1",PatternStartAddress, PatternXLimit, data)


end_body

procedure fpga_audio_pattern_setup(FPGA, startAddr, xlimit, RptCnt)
--------------------------------------------------------------------------------
-- This functions sets up the FPGA for audio Xmit but does not begin sending the pattern.
-- It takes the starting address and size of the pattern
-- to transmit. RptCnt indicates how many times the pattern should be repeated.
in string[5]          : FPGA        -- "FPGA1" or "FPGA2"
in lword              : startAddr   -- value to go in APSA_REG register of FPGA
in lword              : xlimit      -- size of pattern
in lword              : RptCnt      -- Pattern Repeat Count


local multisite lword : writeVal
local multisite lword : data
local word            : dev

body


    writeVal = startAddr
    fpga_write_register(FPGA, APSA_REG, writeVal)
    writeVal = xlimit
    fpga_write_register(FPGA, ATPLIM_REG, writeVal)
    writeVal = RptCnt
    fpga_write_register(FPGA, ARPT_REG, writeVal)


    wait(0ms)
    
end_body

procedure fpga_compose_audio_16bit_hold_pattern
--------------------------------------------------------------------------
--
local
    lword              : PatternStartAddress
    lword              : PatternXLimit
    lword              : data[64]
    word               : idx
end_local
   
body
    

    println(stdout, "Loading FPGA 16 bit Audio Hold Pattern")


    --    WS SD
    
    data[1]      = 2#00
    data[2]      = 2#00

    for idx=3 to 16 by 2 do
     data[idx+0]      = 2#01
     data[idx+1]      = 2#00
    end_for
    
    data[17]      = 2#11
    data[18]      = 2#11

    
    for idx=19 to 32 by 2 do
     data[idx+0]      = 2#10
     data[idx+1]      = 2#11
    end_for

    

-- Load pattern into FPGA for transmit & compare purposes
    PatternStartAddress = AUD_I2S_16_HOLD
    PatternXLimit = 32
    fpga_load_audio_transmit_pattern("FPGA1",PatternStartAddress, PatternXLimit, data)


end_body

procedure fpga_compose_audio_16bit_pattern
--------------------------------------------------------------------------
--
local
    lword              : PatternStartAddress
    lword              : PatternXLimit
    lword              : data[32]
    word               : idx
end_local
   
body
    

    println(stdout, "Loading FPGA 16 bit Audio Pattern")


    --    WS SD

    for idx=1 to 16 by 2 do
     data[idx+0]      = 2#00
     data[idx+1]      = 2#01
    end_for

    
    for idx=17 to 32 by 2 do
     data[idx+0]      = 2#11
     data[idx+1]      = 2#10
    end_for

    

-- Load pattern into FPGA for transmit & compare purposes
    PatternStartAddress = AUD_I2S_16
    PatternXLimit = 32
    fpga_load_audio_transmit_pattern("FPGA1",PatternStartAddress, PatternXLimit, data)


end_body
function Read_FPGA_DIE_Temperature : multisite float
--------------------------------------------------------------------------------
--  This function returns the temperature of the FPGA
--  Reading the FPGA register returns an ADC code
--  The transfer function is:
--  Temp (C) = (ADC_Code x 503.975)/4096  - 273.15

local multisite lword    : ADC_code
local multisite float    : FPGA_temp

body

    ADC_code = fpga_read_register("FPGA1", FPGA_DIE_TEMP)
    
    FPGA_temp = (float(ADC_code) * 503.975) / 4096.0  - 273.15
    
    return (FPGA_temp)

end_body

procedure fpga_compose_video_gradient_pattern
--------------------------------------------------------------------------

local
    lword              : PatternStartAddress
    lword              : PatternSize
    lword              : data[1920]
    word               : idx
end_local
   
body

    println(stdout, "Loading FPGA Video Gradient Pattern")

-- Compose a checkerboard pattern, 128 pixels wide
    for idx=1 to 256 do
       data[idx+0]    = lword(idx-1)
       data[idx+256]  = lword(idx - 1) << 8
       data[idx+512]  = lword(idx - 1) << 16
       data[idx+768]  = lword(idx - 1) << 8 + lword(idx-1) + (lword(idx - 1) << 16)
       data[idx+1024] = lword(idx-1)
       data[idx+1280] = lword(idx - 1) << 8
       data[idx+1536] = lword(idx - 1) << 16
    end_for
    
    for idx=1 to 128 do
       data[idx+1792] = lword(idx - 1) << 8 + lword(idx-1) + (lword(idx - 1) << 16)
    endfor

    

    PatternStartAddress = GRAD_PAT_ADDR
    PatternSize = 1920
    
    fpga_load_video_pattern(PatternStartAddress, PatternSize, data)



end_body  -- procedure fpga_compose_video_pattern


procedure fpga_load_video_pattern(startAddr, xlimit, data)
--------------------------------------------------------------------------------
--
--
in lword:               startAddr   -- value to go in ADDR register of FPGAs
in lword:               xlimit      -- size of pattern (i.e. number of vectors)
in lword:               data[?]
--
local word:             offs        -- pattern address offset
local multisite lword:  writeVal    -- value to write to the RAM address


body

    writeVal = startAddr
    fpga_write_register("FPGA1", VPSA_REG, writeVal)
    
    
    -- load pattern
    for offs = 0 to word(xlimit-1) do
        writeVal = data[offs+1]
	fpga_rw_datapair(FPGA_SRC_WR, 0, VBRAM_WRITE_REG, offs, writeVal)
    end_for


end_body


