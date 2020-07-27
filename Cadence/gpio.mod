use module "./SERDES_Pins.mod"
use module "./FPGA.mod"
use module "./user_globals.mod"
use module "./reg_access.mod"
use module "./lib/lib_common.mod"
use module "./general_calls.mod"
use module "./gen_calls2.mod"
use module "./Audio.mod"

procedure fpga_write_gpio_source_memory(FPGA, reg, mem_length , offsets , data)
--------------------------------------------------------------------------------
-- For an FPGA "memory" register (like a RAM block or the source and capture matrix tables),
--  do a loop of the "memory offsets" (offsets[1:mem_length]), writing the data into the
--  FPGA memory referenced by that register, at the given memory-offsets
--
in string[5]                            : FPGA          -- "FPGA1" or "FPGA2"
in word                                 : reg           -- FPGA register to write to
in word                                 : mem_length    -- how many data elements to write into memory
in lword                                : offsets[?]    -- array of memory-offsets
in lword                                : data[?]       -- array of data (same data gets sent to every site)
local word                              : dev , imem , offs
local multisite lword                   : msdata
body

    if FPGA == "FPGA1" then
        dev = 0x00
    elseif FPGA == "FPGA2" then
        dev = 0x40
    endif

    if mem_length > word(dimsize(offsets,1)) or mem_length > word(dimsize(data,1)) then
        Print_banner_message( sprint("fpga_write_memory(", mem_length:-1, ",", dimsize(offsets,1):-1, ",", dimsize(data,1):-1), "TestEngineer needs to fix the size of the offsets and/or data arrays", "")
        halt
    end_if

    for imem = 1 to mem_length do
        msdata = data[imem]
        offs = word( offsets[imem] )
        fpga_rw_datapair(FPGA_SRC_WR , dev , reg , offs , msdata )
    end_for

end_body

procedure fpga_read_gpio_capture_memory(FPGA, startAdd, endAdd, pinmask)
--------------------------------------------------------------------------------
-- This procedure reads out captured gpio data and prints to the screen
-- Data is masked before printing
--
in string[5]                            : FPGA          -- "FPGA1" or "FPGA2"
in word                                 : startAdd, endAdd
in multisite lword                      : pinmask

local word                              : dev , imem
local multisite lword                   : msdata

body

    if FPGA == "FPGA1" then
        dev = 0x00
    elseif FPGA == "FPGA2" then
        dev = 0x40
    endif

    println(stdout,"":-21, "SITE1":12,  "SITE2":12, "SITE3":12,  "SITE4":12)

    for imem = startAdd to endAdd do
        fpga_rw_datapair(FPGA_SRC_RD , dev , GPIO_CAPTURE_RAM_READBACK , imem , msdata )
        msdata = msdata & pinmask
        
        print(stdout,"Data at address ", imem!z:4," is")
        print(stdout,"0x":4, msdata[1]!hz:8, "0x":4, msdata[2]!hz:8)
        print(stdout,"0x":4, msdata[3]!hz:8, "0x":4, msdata[4]!hz:8)
        println(stdout,"")
    end_for


end_body


procedure fpga_compose_gpio_BRAM_patterns
--------------------------------------------------------------------------------
--  This procedure composes and loads GPIO source patterns

local lword  : offsets[32]
local lword  : data[32]

local word   : idx

body


-- Pattern for SER GPIOs 0-18
    for idx = 1 to 16 do
        offsets[idx] = lword(idx) | 0x8000  -- Set bit[15] = 1 to enable loading
    endfor
    
    awrite(data, 0x00001, 0x20202, 0x54004, 0x3A70B, 0x75884, 0x2A70B, 0x55884, 0x2A70B, 0x55884, 0x2A70B, 0x55884, 0x2A70B, 0x55884, 0x2A70B, 0x55884, 0x00000)
    fpga_write_gpio_source_memory("FPGA1", GPIO_SOURCE_RAM_DATA, 16, offsets, data)
    

 
-- Pattern for SER GPIOs 0-18    
    for idx = 1 to 16 do
        offsets[idx] = lword(idx + 19) | 0x8000  -- Set bit[15] = 1 to enable loading
    endfor
    
    awrite(data, 0x00100, 0x00303, 0x54004, 0x3A70B, 0x75884, 0x2A70B, 0x2A70B, 0x55884, 0x55884, 0x2A70B, 0x55884, 0x2A70B, 0x55884, 0x2A70B, 0x55884, 0x00000)
    fpga_write_gpio_source_memory("FPGA1", GPIO_SOURCE_RAM_DATA, 16, offsets, data) 


    
-- Pattern for DES GPIOs 0-22
    for idx = 1 to 16 do
        offsets[idx] = lword(idx + 39) | 0x8000  -- Set bit[15] = 1 to enable loading
    endfor
    
    awrite(data, 0x0400502, 0x1B17EC3, 0x080B020, 0x190E641, 0x1E1FDA2, 0x03082E0, 0x1614DA2, 0x0019A01, 0x07005E2, 0x1D1E743, 0x0803020, 0x1D0E743, 0x1A178A0, 0x0109643, 0x161CDA2, 0x000000) 
    fpga_write_gpio_source_memory("FPGA1", GPIO_SOURCE_RAM_DATA, 16, offsets, data)

    
-- Pattern for DES GPIOs 0-22
    for idx = 1 to 16 do
        offsets[idx] = lword(idx + 59) | 0x8000  -- Set bit[15] = 1 to enable loading
    endfor
    
    awrite(data, 0x0000030, 0x1B17EC3, 0x080B020, 0x190E641, 0x1E1FDA2, 0x03082E0, 0x1614DA2, 0x07005E2, 0x0019A01, 0x1D1E743, 0x0803020, 0x1D0E743, 0x1A178A0, 0x0109643, 0x161CDA2, 0x000000)
    fpga_write_gpio_source_memory("FPGA1", GPIO_SOURCE_RAM_DATA, 16, offsets, data)

end_body

procedure fpga_write_memory(FPGA, reg, mem_length , offsets , data)
--------------------------------------------------------------------------------
-- For an FPGA "memory" register (like a RAM block or the source and capture matrix tables),
--  do a loop of the "memory offsets" (offsets[1:mem_length]), writing the data into the
--  FPGA memory referenced by that register, at the given memory-offsets
--
in string[5]                            : FPGA          -- "FPGA1" or "FPGA2"
in word                                 : reg           -- FPGA register to write to
in word                                 : mem_length    -- how many data elements to write into memory
in lword                                : offsets[?]    -- array of memory-offsets
in lword                                : data[?]       -- array of data (same data gets sent to every site)
local word                              : dev , imem , offs
local multisite lword                   : msdata
body

    if FPGA == "FPGA1" then
        dev = 0x00
    elseif FPGA == "FPGA2" then
        dev = 0x40
    endif

    if mem_length > word(dimsize(offsets,1)) or mem_length > word(dimsize(data,1)) then
        Print_banner_message( sprint("fpga_write_memory(", mem_length:-1, ",", dimsize(offsets,1):-1, ",", dimsize(data,1):-1), "TestEngineer needs to fix the size of the offsets and/or data arrays", "")
        halt
    end_if

    for imem = 1 to mem_length do
        msdata = data[imem]
        offs = word( offsets[imem] )
        fpga_rw_datapair(FPGA_SRC_WR , dev , reg , offs , msdata )
    end_for

end_body



procedure SetGpioDataRate( gpio_rate )
--------------------------------------------------------------------------------
--  Program the FPGA for specified GPIO data rate

in float              : gpio_rate

local multisite lword : writeVal

body

      writeVal = lword( 100MHz / (gpio_rate * 2.0) )
      
      fpga_write_register( "FPGA1" , GPIO_CLOCK_DIVIDER , writeVal )


end_body

procedure SetGpioCaptureDelay(cap_delay)
--------------------------------------------------------------------------------
--  Sets the delay before the first sample is captured
--  The delay is from the time the FPGA sends the first GPIO vector till the first
--  sample is captured. Subsequent captures are spaced according to the GPIO transmit rate.

in float              : cap_delay

local multisite lword : writeVal

body

       -- Delay is in multiples of 10ns. For example, a value of 100 gives a 1us delay (100*10ns = 1us)
       writeVal = lword(cap_delay/10ns)

       fpga_write_register( "FPGA1" , GPIO_CLK_DELAY , writeVal )

end_body

procedure GpioFunc(Vdd, Vddio, Vdd18, POWERUP, POWERDOWN, TP_COAX, TX_SPD, RX_SPD, SerLock_it, DesLock_it, gng_lim )
--------------------------------------------------------------------------------------------------------------------------------
-- GPIO Functionality: use FPGA to send/receive GPIO data across the link
--
--
--
in float                                : Vdd, Vddio, Vdd18
in boolean                              : POWERUP,POWERDOWN
in string[20]                           : TP_COAX
in float                                : TX_SPD, RX_SPD
in_out  integer_test                    : SerLock_it, DesLock_it
in_out array of integer_test            : gng_lim


local

    multisite lword                     : lock_status
    multisite integer                   : SerLock, DesLock
    lword                               : offs[32] , vals[32]
    multisite integer                   : dlog[18] , fpga_read_int

    multisite lword                     : fpga_write_data, gpio_mask
    boolean                             : DEBUG = false

    word                                : CxTpVal
    multisite integer                   : GmslStatus
 
end_local

body
 
  
    disconnect hvvi chan SER_RSVD    -- need to float RSVD, important!!
    close cbit X1X2_POSC             -- connects DPs to Port Expander
-----Dut power up function
    if POWERUP then
        DutPowerUp(Vddio, Vdd18, Vdd, "UART", "TP_GMSL2", POWERUP)
        set digital pin AUX_PINS levels to vil 0mV vih 3.3V iol 2mA ioh -2mA vref 3.3V
---Close relay to connect FPGA to control TX/RX on DNUT
        close cbit  DNUT_RXTX_RELAY + MFP_LT_K12_RELAY
        close cbit MFP_LT_RELAY  + I2C_LT_CB
        wait(0ms)
--------powerup_dnut_vdd_vterm(VDD_SET, VTERM_SET)
        powerup_dnut_vdd_vterm(1.2,1.2)
        wait(3ms)
  --fpga_Set_DNUT_Pins("FPGA1", CFG1, CFG0, PWDN, latch)
        fpga_Set_DNUT_Pins("FPGA1", 0, 0, 1, 1, TRUE)  -- UART/COAX/GMSL2=1/RATE=0(6 Gig link)               
        wait(6ms)    
    else
        Set_SER_Voltages(Vddio, Vdd, Vdd18)
        set digital pin AUX_PINS levels to vil 0mV vih 3.3V iol 2mA ioh -2mA vref 3.3V
    end_if
   

-- Set FPGA UART Speed     
     fpga_set_UART_Frequency("FPGA1", 1MHz)


-- Establish Link Lock
     lock_status = Configure_And_Link2(TP_COAX, TX_SPD, RX_SPD)
     
     SerLock = integer ((lock_status & 0xFF00) >> 8)
     DesLock = integer (lock_status & 0xFF)
   ---------------------------------------------------------------------------


    
---- Set the LT direction SER -> FPGA
    SetPortExpander(PORT_EXP, 0x3F)  -- SER drives FPGA

   
-- Connect GPIOs to FPGA
    -- Already Done above
    
 
    
--  Disable Audio Transmission
   -- Already disabled by default
    
--  Disable Audio Receive
   -- Already disabled by default
   

-- Disable Lock & ERR functions
    lock_status = fpga_UART_Read("FPGA1", "SER", DESA_ID, 3, 1)
    fpga_UART_Write("FPGA1","SER", SER_ID,  SR_REG5, 1, 0x00)
    fpga_UART_Write("FPGA1","SER", DESA_ID, DR_REG5, 1, 0x00)
    
-- Disable UART1 PT Function
    fpga_UART_Write("FPGA1","SER", DESA_ID, DR_REG3, 1, 0x00)


    --######################################################
    --######################################################
    --## FPGA->HS89-LINK->HS94->FPGA  Uncompensated Mode
    --## GPIO 0  -->    GPIO 0
    --## GPIO 1  -->    GPIO 1
    --## GPIO 2  -->    GPO  2
    --## GPIO 3  -->    GPO  3
    --## GPIO 7  -->    GPIO 7
    --## GPIO 8  -->    GPIO 8
    --## GPIO 9  -->    GPIO 9
    --## GPIO 10 -->    GPIO 10
    --## GPIO 11 -->    GPIO 11
    --## GPIO 12 -->    GPIO 12
    --## GPIO 13 -->    GPIO 13
    --## GPIO 14 -->    GPIO 14
    --## GPIO 15 -->    GPIO 15
    --## GPIO 16 -->    GPIO 16
    --## GPIO 17 -->    GPO  4
    --## GPIO 18 -->    GPIO 5
    --######################################################

    --###################################################################
    --## Setup SER/DES for FPGA->SER->DES->FPGA    in UnCompenated Mode
    --###################################################################
    --### SER/HS89
    fpga_UART_Write( "FPGA1" , "SER" , SER_ID , SR_GPIO_A_0 ,  3 , 0x40A043 )    -- # GPIO_0  GPIO_A/B/C
    fpga_UART_Write( "FPGA1" , "SER" , SER_ID , SR_GPIO_A_1 ,  3 , 0x41A143 )    -- # GPIO_1  GPIO_A/B/C
    fpga_UART_Write( "FPGA1" , "SER" , SER_ID , SR_GPIO_A_2 ,  3 , 0x42A243 )    -- # GPIO_2  GPIO_A/B/C
    fpga_UART_Write( "FPGA1" , "SER" , SER_ID , SR_GPIO_A_3 ,  3 , 0x43A343 )    -- # GPIO_3  GPIO_A/B/C
    fpga_UART_Write( "FPGA1" , "SER" , SER_ID , SR_GPIO_A_7 ,  3 , 0x47A743 )    -- # GPIO_7  GPIO_A/B/C
    fpga_UART_Write( "FPGA1" , "SER" , SER_ID , SR_GPIO_A_8 ,  3 , 0x48A843 )    -- # GPIO_8  GPIO_A/B/C
    fpga_UART_Write( "FPGA1" , "SER" , SER_ID , SR_GPIO_A_9 ,  3 , 0x49A943 )    -- # GPIO_9  GPIO_A/B/C
    fpga_UART_Write( "FPGA1" , "SER" , SER_ID , SR_GPIO_A_10 , 3 , 0x4AAA43 )    -- # GPIO_10 GPIO_A/B/C
    fpga_UART_Write( "FPGA1" , "SER" , SER_ID , SR_GPIO_A_11 , 3 , 0x4BAB43 )    -- # GPIO_11 GPIO_A/B/C
    fpga_UART_Write( "FPGA1" , "SER" , SER_ID , SR_GPIO_A_12 , 3 , 0x4CAC43 )    -- # GPIO_12 GPIO_A/B/C
    fpga_UART_Write( "FPGA1" , "SER" , SER_ID , SR_GPIO_A_13 , 3 , 0x4DAD43 )    -- # GPIO_13 GPIO_A/B/C
    fpga_UART_Write( "FPGA1" , "SER" , SER_ID , SR_GPIO_A_14 , 3 , 0x4EAE43 )    -- # GPIO_14 GPIO_A/B/C
    fpga_UART_Write( "FPGA1" , "SER" , SER_ID , SR_GPIO_A_15 , 3 , 0x4FAF43 )    -- # GPIO_15 GPIO_A/B/C
    fpga_UART_Write( "FPGA1" , "SER" , SER_ID , SR_GPIO_A_16 , 3 , 0x50B043 )    -- # GPIO_16 GPIO_A/B/C
    fpga_UART_Write( "FPGA1" , "SER" , SER_ID , SR_GPIO_A_17 , 3 , 0x51B143 )    -- # GPIO_17 GPIO_A/B/C
    fpga_UART_Write( "FPGA1" , "SER" , SER_ID , SR_GPIO_A_18 , 3 , 0x52B243 )    -- # GPIO_18 GPIO_A/B/C

    
    -- ### DES/HS92
    fpga_UART_Write( "FPGA1" , "DES" , DESA_ID , DR_GPIO_A_0 ,  3 , 0x40A044 )    -- # GPIO_0  GPIO_A/B/C
    fpga_UART_Write( "FPGA1" , "DES" , DESA_ID , DR_GPIO_A_1 ,  3 , 0x41A144 )    -- # GPIO_1  GPIO_A/B/C   
    fpga_UART_Write( "FPGA1" , "DES" , DESA_ID , DR_GPIO_A_2 ,  3 , 0x42A244 )    -- # GPIO_2  GPIO_A/B/C
    fpga_UART_Write( "FPGA1" , "DES" , DESA_ID , DR_GPIO_A_3 ,  3 , 0x43A344 )    -- # GPIO_3  GPIO_A/B/C
    fpga_UART_Write( "FPGA1" , "DES" , DESA_ID , DR_GPIO_A_4 ,  3 , 0x51A444 )    -- # GPIO_4  GPIO_A/B/C
    fpga_UART_Write( "FPGA1" , "DES" , DESA_ID , DR_GPIO_A_5 ,  3 , 0x52A544 )    -- # GPIO_5  GPIO_A/B/C
    fpga_UART_Write( "FPGA1" , "DES" , DESA_ID , DR_GPIO_A_7 ,  3 , 0x47A744 )    -- # GPI0_7  GPIO_A/B/C
    fpga_UART_Write( "FPGA1" , "DES" , DESA_ID , DR_GPIO_A_8 ,  3 , 0x48A844 )    -- # GPI0_8  GPIO_A/B/C
    fpga_UART_Write( "FPGA1" , "DES" , DESA_ID , DR_GPIO_A_9 ,  3 , 0x49A944 )    -- # GPI0_9  GPIO_A/B/C
    fpga_UART_Write( "FPGA1" , "DES" , DESA_ID , DR_GPIO_A_10 , 3 , 0x4AAA44 )    -- # GPI0_10 GPIO_A/B/C
    fpga_UART_Write( "FPGA1" , "DES" , DESA_ID , DR_GPIO_A_11 , 3 , 0x4BAB44 )    -- # GPI0_11 GPIO_A/B/C
    fpga_UART_Write( "FPGA1" , "DES" , DESA_ID , DR_GPIO_A_12 , 3 , 0x4CAC44 )    -- # GPI0_12 GPIO_A/B/C
    fpga_UART_Write( "FPGA1" , "DES" , DESA_ID , DR_GPIO_A_13 , 3 , 0x4DAD44 )    -- # GPI0_13 GPIO_A/B/C
    fpga_UART_Write( "FPGA1" , "DES" , DESA_ID , DR_GPIO_A_14 , 3 , 0x4EAE44 )    -- # GPI0_14 GPIO_A/B/C
    fpga_UART_Write( "FPGA1" , "DES" , DESA_ID , DR_GPIO_A_15 , 3 , 0x4FAF44 )    -- # GPIO_15 GPIO_A/B/C
    fpga_UART_Write( "FPGA1" , "DES" , DESA_ID , DR_GPIO_A_16 , 3 , 0x50B044 )    -- # GPIO_16 GPIO_A/B/C
--    fpga_UART_Write( "FPGA1" , "DES" , DESA_ID , DR_GPIO_A_17 , 3 , 0x40B144 )    -- # GPIO_17 GPIO_A/B/C
--    fpga_UART_Write( "FPGA1" , "DES" , DESA_ID , DR_GPIO_A_18 , 3 , 0x52B244 )    -- # GPIO_18 GPIO_A/B/C


---- Set the LT direction FPGA -> SER
    SetPortExpander(PORT_EXP, 0x00)  -- FPGA drives SER GPIOs

-- --Reload FPGA GPIO send memory address 0
-- 	fpga_write_data = 0x00000001
-- 	fpga_rw_datapair( FPGA_SRC_WR , 0 , GPIO_SOURCE_RAM_DATA, 0x8000 , fpga_write_data )

    -- #####################################
    -- ## Load source RAM
    -- #####################################
    -- # GPIO_BRAM_DATA[31:0]=SrcRamData, PATOSADDR[7:0]=SrcRamAddr, PATOSADDR[15]=SrcRamWEA
--    awrite(offs , 0x8000, 0x8001, 0x8002, 0x8003, 0x8004, 0x8005, 0x8006, 0x8007, 0x8008, 0x8009, 0x800A, 0x800B, 0x800C, 0x800D )
--    awrite(vals , 0x0001, 0x0002, 0x0004, 0x0008, 0x0010, 0x0020, 0x0040, 0x0080, 0x01C5, 0x01C3, 0x0187, 0x0147, 0x00C7, 0x01C6 )
--    fpga_write_gpio_source_memory( "FPGA1" , GPIO_SOURCE_RAM_DATA , 14 , offs, vals )
    -- *******************************************************************************************************************
    -- ************  Moved Loading of GPIO BRAM DATA to ON_INIT FLow *****************************************************
    -- *******************************************************************************************************************
    
    -- ###########################################################################################################
    -- Setup CAP matrix   (i.e. tell FPGA to move captured GP04/5 up to GPIO17/18 before storing in memory
    -- ###########################################################################################################
    -- # GPIO_BRAM_DATA[31:0]=SrcRamData, PATOSADDR[7:0]=SrcRamAddr, PATOSADDR[15]=SrcRamWEA
    awrite(offs , 17, 18)
    awrite(vals ,  4,  5)
    fpga_write_memory( "FPGA1" , GPIO_CAP_MATRIX_SETUP , 2 , offs, vals )

    -- # Setup mask
    gpio_mask = 2#111_1111_1111_1000_1111
    fpga_write_register( "FPGA1" , GPIO_MASK , gpio_mask )

    -- # Setup source start/stop address
    fpga_write_data = 0x00100001
    fpga_write_register( "FPGA1" , GPIO_CAPTURE_CONTROL , fpga_write_data )

    -- # Set data rate for GPIO
    SetGpioDataRate(400KHz)

    -- # Set delay before capturing first GPIO sample at the remote side
    SetGpioCaptureDelay(1.25us)

    -- ####################################
    -- ## Run GPIO pattern
    -- ####################################
    -- # Start state machine
    -- # GPIO_CONTROL_REG[9]=Start, GPIO_CONTROL_REG[1]=Enable Internal Loopback
    -- # GPIO_CONTROL_REG[0]=TestDirection (0=DES->SER, 1=SER->DES)


    fpga_write_data = 0x00000201
    fpga_write_register( "FPGA1" , GPIO_CONTROL_REG , fpga_write_data )
    fpga_write_register( "FPGA1" , GPIO_CONTROL_REG , fpga_write_data )
    wait(0ms)

    
    -- # GPIO_TEST_RESULTS[3]=Internal Loopback Used, [2]=GpioTestActive, [1]=testCompleted, [0]=testPassed
    fpga_read_int = integer( fpga_read_register( "FPGA1" , GPIO_TEST_RESULTS ) )    
    scatter_1d( fpga_read_int , dlog , 1 )

    
    --   # GPIO_NUM_CAPS_CAPTURED
    fpga_read_int = integer( fpga_read_register( "FPGA1" , GPIO_NUM_CAPS_CAPTURED ) )
    scatter_1d( fpga_read_int , dlog , 2 )
    
    
    --   # GPIO_NUM_FAILING_VECTORS
    fpga_read_int = integer( fpga_read_register( "FPGA1" , GPIO_NUM_FAILING_VECTORS ) )
    scatter_1d( fpga_read_int , dlog , 3 )


    if DEBUG then
        println(stdout, "SER->DES Uncompensated Mode: actual")
        println(stdout, "GPIO_TEST_RESULTS":-40,        "0x":4, dlog[1,1]!Hz:8, "0x":4, dlog[2,1]!Hz:8, "0x":4, dlog[3,1]!Hz:8, "0x":4, dlog[4,1]!Hz:8 )
        println(stdout, "GPIO_NUM_CAPS_CAPTURED":-40,   "0x":4, dlog[1,2]!Hz:8, "0x":4, dlog[2,2]!Hz:8, "0x":4, dlog[3,2]!Hz:8, "0x":4, dlog[4,2]!Hz:8 )
        println(stdout, "GPIO_NUM_FAILING_VECTORS":-40, "0x":4, dlog[1,3]!Hz:8, "0x":4, dlog[2,3]!Hz:8, "0x":4, dlog[3,3]!Hz:8, "0x":4, dlog[4,3]!Hz:8 )
        fpga_read_gpio_capture_memory( "FPGA1" , 0 , 15 , gpio_mask)
    end_if
    
    if GPIO_Debug then
       Debug_GPIO_Consecutive_Fail(dlog, "SER->DES Uncompensated Mode: actual", TRUE, FALSE, 1, 1, 16, gpio_mask)
    endif
    
    
    --###################################################################
    --## Setup SER/DES for FPGA->SER->DES->FPGA    in  Compenated Mode
    --## GPIO 0  -->    GPIO 0
    --## GPIO 1  -->    GPIO 1
    --## GPIO 2  -->    GPO  2
    --## GPIO 3  -->    GPO  3
    --## GPOI 7  -->    GPIO 7
    --## GPOI 8  -->    GPIO 8
    --## GPIO 9  -->    GPIO 9
    --## GPIO 10 -->    GPIO 10
    --## GPIO 11 -->    GPIO 11
    --## GPIO 12 -->    GPIO 12
    --## GPIO 13 -->    GPIO 13
    --## GPIO 14 -->    GPIO 14
    --## GPIO 15 -->    GPIO 15
    --## GPIO 16 -->    GPIO 16
    --## GPIO 17 -->    GPO  4
    --## GPIO 18 -->    GPIO 5
    --###################################################################
    --### SER/HS89
    fpga_UART_Write( "FPGA1" , "SER" , SER_ID , SR_GPIO_A_0 ,  1 , 0x63 )    -- # GPIO_0  GPIO_A/B/C
    fpga_UART_Write( "FPGA1" , "SER" , SER_ID , SR_GPIO_A_1 ,  1 , 0x63 )    -- # GPIO_1  GPIO_A/B/C
    fpga_UART_Write( "FPGA1" , "SER" , SER_ID , SR_GPIO_A_2 ,  1 , 0x63 )    -- # GPIO_2  GPIO_A/B/C
    fpga_UART_Write( "FPGA1" , "SER" , SER_ID , SR_GPIO_A_3 ,  1 , 0x63 )    -- # GPIO_3  GPIO_A/B/C
    fpga_UART_Write( "FPGA1" , "SER" , SER_ID , SR_GPIO_A_7 ,  1 , 0x63 )    -- # GPIO_7  GPIO_A/B/C
    fpga_UART_Write( "FPGA1" , "SER" , SER_ID , SR_GPIO_A_8 ,  1 , 0x63 )    -- # GPIO_8  GPIO_A/B/C
    fpga_UART_Write( "FPGA1" , "SER" , SER_ID , SR_GPIO_A_9 ,  1 , 0x63 )    -- # GPIO_9  GPIO_A/B/C
    fpga_UART_Write( "FPGA1" , "SER" , SER_ID , SR_GPIO_A_10 , 1 , 0x63 )    -- # GPIO_10 GPIO_A/B/C
    fpga_UART_Write( "FPGA1" , "SER" , SER_ID , SR_GPIO_A_11 , 1 , 0x63 )    -- # GPIO_11 GPIO_A/B/C
    fpga_UART_Write( "FPGA1" , "SER" , SER_ID , SR_GPIO_A_12 , 1 , 0x63 )    -- # GPIO_12 GPIO_A/B/C
    fpga_UART_Write( "FPGA1" , "SER" , SER_ID , SR_GPIO_A_13 , 1 , 0x63 )    -- # GPIO_13 GPIO_A/B/C
    fpga_UART_Write( "FPGA1" , "SER" , SER_ID , SR_GPIO_A_14 , 1 , 0x63 )    -- # GPIO_14 GPIO_A/B/C
    fpga_UART_Write( "FPGA1" , "SER" , SER_ID , SR_GPIO_A_15 , 1 , 0x63 )    -- # GPIO_15 GPIO_A/B/C
    fpga_UART_Write( "FPGA1" , "SER" , SER_ID , SR_GPIO_A_16 , 1 , 0x63 )    -- # GPIO_16 GPIO_A/B/C
    fpga_UART_Write( "FPGA1" , "SER" , SER_ID , SR_GPIO_A_17 , 1 , 0x63 )    -- # GPIO_17 GPIO_A/B/C
    fpga_UART_Write( "FPGA1" , "SER" , SER_ID , SR_GPIO_A_18 , 1 , 0x63 )    -- # GPIO_18 GPIO_A/B/C

  -- Disable SER GPIOs 4/5/6
    fpga_UART_Write( "FPGA1" , "SER" , SER_ID , SR_GPIO_A_4 ,  1 , 0x81 )    -- # GPIO_4  GPIO_A/B/C
    fpga_UART_Write( "FPGA1" , "SER" , SER_ID , SR_GPIO_A_5 ,  1 , 0x81 )    -- # GPIO_5  GPIO_A/B/C
    fpga_UART_Write( "FPGA1" , "SER" , SER_ID , SR_GPIO_A_6 ,  1 , 0x81 )    -- # GPIO_6  GPIO_A/B/C


 

    -- # Setup mask
    gpio_mask = 2#111_1111_1111_1000_1111
    fpga_write_register( "FPGA1" , GPIO_MASK , gpio_mask )

    -- # Setup source start/stop address
    fpga_write_data = 0x00230014          -- 20 to 35
    fpga_write_register( "FPGA1" , GPIO_CAPTURE_CONTROL , fpga_write_data )
    
    -- # Set data rate for GPIO
    SetGpioDataRate(400KHz)
    
    -- # Set delay before capturing first GPIO sample at the remote side
    SetGpioCaptureDelay(1.25us)


    -- # Start state machine
    -- # GPIO_CONTROL_REG[9]=Start, GPIO_CONTROL_REG[1]=Enable Internal Loopback
    -- # GPIO_CONTROL_REG[0]=TestDirection (0=DES->SER, 1=SER->DES)

    fpga_write_data = 0x00000201
    fpga_write_register( "FPGA1" , GPIO_CONTROL_REG , fpga_write_data )

    
    -- # GPIO_TEST_RESULTS[3]=Internal Loopback Used, [2]=GpioTestActive, [1]=testCompleted, [0]=testPassed
    fpga_read_int = integer( fpga_read_register( "FPGA1" , GPIO_TEST_RESULTS ) )    
    scatter_1d( fpga_read_int , dlog , 4 )

    
    --   # GPIO_NUM_CAPS_CAPTURED
    fpga_read_int = integer( fpga_read_register( "FPGA1" , GPIO_NUM_CAPS_CAPTURED ) )
    scatter_1d( fpga_read_int , dlog , 5 )

    
    --   # GPIO_NUM_FAILING_VECTORS
    fpga_read_int = integer( fpga_read_register( "FPGA1" , GPIO_NUM_FAILING_VECTORS ) )
    scatter_1d( fpga_read_int , dlog , 6 )
   

    if DEBUG then
        println(stdout, "SER->DES Compensated Mode: actual")
        println(stdout, "GPIO_TEST_RESULTS":-40,        "0x":4, dlog[1,4]!Hz:8, "0x":4, dlog[2,4]!Hz:8, "0x":4, dlog[3,4]!Hz:8, "0x":4, dlog[4,4]!Hz:8 )
        println(stdout, "GPIO_NUM_CAPS_CAPTURED":-40,   "0x":4, dlog[1,5]!Hz:8, "0x":4, dlog[2,5]!Hz:8, "0x":4, dlog[3,5]!Hz:8, "0x":4, dlog[4,5]!Hz:8 )
        println(stdout, "GPIO_NUM_FAILING_VECTORS":-40, "0x":4, dlog[1,6]!Hz:8, "0x":4, dlog[2,6]!Hz:8, "0x":4, dlog[3,6]!Hz:8, "0x":4, dlog[4,6]!Hz:8 )
        fpga_read_gpio_capture_memory( "FPGA1" , 0 , 15 , gpio_mask )
    end_if    
    
    if GPIO_Debug then
       Debug_GPIO_Consecutive_Fail(dlog, "SER->DES Compensated Mode: actual", FALSE, FALSE, 4, 20, 35, gpio_mask)
    endif

     
-- turn off the FPGA GPIO functional block
    fpga_write_data = 0x00000000
    fpga_write_register( "FPGA1" , GPIO_CONTROL_REG , fpga_write_data )
 
    
---- Set the LT direction SER -> FPGA
    SetPortExpander(PORT_EXP, 0x3F)  -- SER GPIOs drive FPGA
      


    -- ##################################################
    -- ##################################################
    -- ## FPGA->HS92-LINK->HS89->FPGA  (DES->SER)
    -- ##################################################
    -- ##Uncompensated Mode
    --## GPIO 0  -->    GPIO 0
    --## GPIO 1  -->    GPIO 1
    --## GPIO 6  -->    GPIO 2   -- GPIO 6  maps to both GPIO 2 & 6
    --## GPIO 7  -->    GPIO 3   -- GPIO 7  maps to both GPIO 3 & 7
    --## GPIO 8  -->    GPO  4   -- GPIO 8  maps to both GPIO 4 & 8
    --## GPIO 5  -->    GPO  5
    --## GPIO 6  -->    GPO  6
    --## GPIO 7  -->    GPIO 7
    --## GPIO 8  -->    GPIO 8
    --## GPIO 9  -->    GPIO 9
    --## GPIO 10 -->    GPIO 10
    --## GPIO 11 -->    GPIO 11
    --## GPIO 12 -->    GPIO 12
    --## GPIO 13 -->    GPIO 13
    --## GPIO 14 -->    GPIO 14
    --## GPIO 15 -->    GPIO 15
    --## GPIO 16 -->    GPIO 16
    --## GPIO 13 -->    GPIO 17  -- GPIO 13  maps to both GPIO 13 & 17
    --## GPIO 14 -->    GPIO 18  -- GPIO 14  maps to both GPIO 14 & 18
    -- ##################################################
    -- ##################################################


    -- #####################################
    -- ## Setup SER/DES for FPGA->DES->SER->FPGA   in Uncompensated Mode
    -- #####################################    
    --### SER/HS89
    fpga_UART_Write( "FPGA1" , "SER" , SER_ID , SR_GPIO_A_0 ,  3 , 0x40A044 )    -- # GPIO_0  GPIO_A/B/C
    fpga_UART_Write( "FPGA1" , "SER" , SER_ID , SR_GPIO_A_1 ,  3 , 0x41A144 )    -- # GPIO_1  GPIO_A/B/C   
    fpga_UART_Write( "FPGA1" , "SER" , SER_ID , SR_GPIO_A_5 ,  3 , 0x45A544 )    -- # GPIO_5  GPIO_A/B/C
    fpga_UART_Write( "FPGA1" , "SER" , SER_ID , SR_GPIO_A_6 ,  3 , 0x46A644 )    -- # GPIO_6  GPIO_A/B/C
    fpga_UART_Write( "FPGA1" , "SER" , SER_ID , SR_GPIO_A_7 ,  3 , 0x47A744 )    -- # GPIO_7  GPIO_A/B/C
    fpga_UART_Write( "FPGA1" , "SER" , SER_ID , SR_GPIO_A_8 ,  3 , 0x48A844 )    -- # GPIO_8  GPIO_A/B/C
    fpga_UART_Write( "FPGA1" , "SER" , SER_ID , SR_GPIO_A_9 ,  3 , 0x49A944 )    -- # GPIO_9  GPIO_A/B/C
    fpga_UART_Write( "FPGA1" , "SER" , SER_ID , SR_GPIO_A_10 , 3 , 0x4AAA44 )    -- # GPIO_10 GPIO_A/B/C
    fpga_UART_Write( "FPGA1" , "SER" , SER_ID , SR_GPIO_A_11 , 3 , 0x4BAB44 )    -- # GPIO_11 GPIO_A/B/C
    fpga_UART_Write( "FPGA1" , "SER" , SER_ID , SR_GPIO_A_12 , 3 , 0x4CAC44 )    -- # GPIO_12 GPIO_A/B/C
    fpga_UART_Write( "FPGA1" , "SER" , SER_ID , SR_GPIO_A_13 , 3 , 0x4DAD44 )    -- # GPIO_13 GPIO_A/B/C
    fpga_UART_Write( "FPGA1" , "SER" , SER_ID , SR_GPIO_A_14 , 3 , 0x4EAE44 )    -- # GPIO_14 GPIO_A/B/C
    fpga_UART_Write( "FPGA1" , "SER" , SER_ID , SR_GPIO_A_15 , 3 , 0x4FAF44 )    -- # GPIO_15 GPIO_A/B/C
    fpga_UART_Write( "FPGA1" , "SER" , SER_ID , SR_GPIO_A_16 , 3 , 0x50B044 )    -- # GPIO_16 GPIO_A/B/C
    fpga_UART_Write( "FPGA1" , "SER" , SER_ID , SR_GPIO_A_17 , 3 , 0x4DB144 )    -- # GPIO_17 GPIO_A/B/C
    fpga_UART_Write( "FPGA1" , "SER" , SER_ID , SR_GPIO_A_18 , 3 , 0x4EB244 )    -- # GPIO_18 GPIO_A/B/C  -- receives from GPIO14
    
    fpga_UART_Write( "FPGA1" , "SER" , SER_ID , SR_GPIO_A_2 ,  3 , 0x46A244 )    -- # GPIO_2  GPIO_A/B/C  -- receives from GPIO6
    fpga_UART_Write( "FPGA1" , "SER" , SER_ID , SR_GPIO_A_3 ,  3 , 0x47A344 )    -- # GPIO_3  GPIO_A/B/C  -- receives from GPIO7
    fpga_UART_Write( "FPGA1" , "SER" , SER_ID , SR_GPIO_A_4 ,  3 , 0x48A444 )    -- # GPIO_4  GPIO_A/B/C  -- receives from GPIO8

    
    -- ### DES/HS92
    fpga_UART_Write( "FPGA1" , "DES" , DESA_ID , DR_GPIO_A_0 ,  3 , 0x40A043 )    -- # GPIO_0  GPIO_A/B/C
    fpga_UART_Write( "FPGA1" , "DES" , DESA_ID , DR_GPIO_A_1 ,  3 , 0x41A143 )    -- # GPIO_1  GPIO_A/B/C   
    fpga_UART_Write( "FPGA1" , "DES" , DESA_ID , DR_GPIO_A_2 ,  3 , 0x42A243 )    -- # GPIO_2  GPIO_A/B/C
    fpga_UART_Write( "FPGA1" , "DES" , DESA_ID , DR_GPIO_A_3 ,  3 , 0x43A343 )    -- # GPIO_3  GPIO_A/B/C
    fpga_UART_Write( "FPGA1" , "DES" , DESA_ID , DR_GPIO_A_4 ,  3 , 0x44A443 )    -- # GPIO_4  GPIO_A/B/C
    fpga_UART_Write( "FPGA1" , "DES" , DESA_ID , DR_GPIO_A_5 ,  3 , 0x45A543 )    -- # GPIO_5  GPIO_A/B/C
    fpga_UART_Write( "FPGA1" , "DES" , DESA_ID , DR_GPIO_A_6 ,  3 , 0x46A643 )    -- # GPIO_6  GPIO_A/B/C
    fpga_UART_Write( "FPGA1" , "DES" , DESA_ID , DR_GPIO_A_7 ,  3 , 0x47A743 )    -- # GPI0_7  GPIO_A/B/C
    fpga_UART_Write( "FPGA1" , "DES" , DESA_ID , DR_GPIO_A_8 ,  3 , 0x48A843 )    -- # GPI0_8  GPIO_A/B/C
    fpga_UART_Write( "FPGA1" , "DES" , DESA_ID , DR_GPIO_A_9 ,  3 , 0x49A943 )    -- # GPI0_9  GPIO_A/B/C
    fpga_UART_Write( "FPGA1" , "DES" , DESA_ID , DR_GPIO_A_10 , 3 , 0x4AAA43 )    -- # GPI0_10 GPIO_A/B/C
    fpga_UART_Write( "FPGA1" , "DES" , DESA_ID , DR_GPIO_A_11 , 3 , 0x4BAB43 )    -- # GPIO_11 GPIO_A/B/C
    fpga_UART_Write( "FPGA1" , "DES" , DESA_ID , DR_GPIO_A_12 , 3 , 0x4CAC43 )    -- # GPIO_12 GPIO_A/B/C
    fpga_UART_Write( "FPGA1" , "DES" , DESA_ID , DR_GPIO_A_13 , 3 , 0x4DAD43 )    -- # GPIO_13 GPIO_A/B/C
    fpga_UART_Write( "FPGA1" , "DES" , DESA_ID , DR_GPIO_A_14 , 3 , 0x4EAE43 )    -- # GPIO_14 GPIO_A/B/C
    fpga_UART_Write( "FPGA1" , "DES" , DESA_ID , DR_GPIO_A_15 , 3 , 0x4FAF43 )    -- # GPIO_15 GPIO_A/B/C
    fpga_UART_Write( "FPGA1" , "DES" , DESA_ID , DR_GPIO_A_16 , 3 , 0x50B043 )    -- # GPIO_16 GPIO_A/B/C
    fpga_UART_Write( "FPGA1" , "DES" , DESA_ID , DR_GPIO_A_17 , 3 , 0x51B143 )    -- # GPIO_17 GPIO_A/B/C



    -- #####################################
    -- ## Setup CAP matrix
    -- #####################################
    -- # GPIO_BRAM_DATA[31:0]=SrcRamData, PATOSADDR[7:0]=SrcRamAddr, PATOSADDR[15]=SrcRamWEA
    -- Reset CAP matrix to default one-to-one mapping
    fpga_reset("FPGA1")
    
    -- ###########################################################################################################
    -- Setup CAP matrix   (i.e. tell FPGA to move captured GPIO2/3/4/17/18 up to GPIO20/21/22/23/24 before storing
    -- in memory.
    -- Make the source pattern include data for GPIO 20/21/22/23/24 (ghost gpios). Data for GPIO 20/21/22/23/24
    -- are just a copy of data for GPIO2/3/4/13/14.
    -- ###########################################################################################################
    -- # GPIO_BRAM_DATA[31:0]=SrcRamData, PATOSADDR[7:0]=SrcRamAddr, PATOSADDR[15]=SrcRamWEA
    awrite(offs , 20,  21,  22,  23,  24)
    awrite(vals , 2 ,   3,   4,  17,  18)
    fpga_write_memory( "FPGA1" , GPIO_CAP_MATRIX_SETUP , 5 , offs, vals )

    -- # Setup mask: bits
    gpio_mask = 2#1_1111_0001_1111_1111_1110_0011
    fpga_write_register( "FPGA1" , GPIO_MASK , gpio_mask )

    -- # Setup source start/stop address
    fpga_write_data = 0x00370028   -- 40 to 55
    fpga_write_register( "FPGA1" , GPIO_CAPTURE_CONTROL , fpga_write_data )

    -- # Set data rate for GPIO
    SetGpioDataRate(100KHz)

    -- # Set delay before capturing GPIO inputs
    SetGpioCaptureDelay(5us)


    -- ####################################
    -- ## Run GPIO pattern
    -- ####################################
    -- # Start state machine
    -- # GPIO_CONTROL_REG[9]=Start, GPIO_CONTROL_REG[1]=Enable Internal Loopback
    -- # GPIO_CONTROL_REG[0]=TestDirection (0=DUT->DNUT, 1=DNUT->DUT)

    fpga_write_data = 0x00000200
    fpga_write_register( "FPGA1" , GPIO_CONTROL_REG , fpga_write_data )
    fpga_write_register( "FPGA1" , GPIO_CONTROL_REG , fpga_write_data )
    wait(0ms)

    -- # Readback status
    -- # GPIO_TEST_RESULTS[3]=Internal Loopback Used, [2]=GpioTestActive, [1]=testCompleted, [0]=testPassed
    fpga_read_int = integer( fpga_read_register( "FPGA1" , GPIO_TEST_RESULTS ) )
    scatter_1d( fpga_read_int , dlog , 7 )

    --   # GPIO_NUM_CAPS_CAPTURED
    fpga_read_int = integer( fpga_read_register( "FPGA1" , GPIO_NUM_CAPS_CAPTURED ) )
    scatter_1d( fpga_read_int , dlog , 8 )

    --   # GPIO_NUM_FAILING_VECTORS
    fpga_read_int = integer( fpga_read_register( "FPGA1" , GPIO_NUM_FAILING_VECTORS ) )
    scatter_1d( fpga_read_int , dlog , 9 )



    if DEBUG then
        println(stdout, "DES->SER: Uncompensated Mode actual")
        println(stdout, "GPIO_TEST_RESULTS":-40,        "0x":4, dlog[1,7]!Hz:8, "0x":4, dlog[2,7]!Hz:8, "0x":4, dlog[3,7]!Hz:8, "0x":4, dlog[4,7]!Hz:8 )
	println(stdout, "GPIO_NUM_CAPS_CAPTURED":-40,   "0x":4, dlog[1,8]!Hz:8, "0x":4, dlog[2,8]!Hz:8, "0x":4, dlog[3,8]!Hz:8, "0x":4, dlog[4,8]!Hz:8 )
	println(stdout, "GPIO_NUM_FAILING_VECTORS":-40, "0x":4, dlog[1,9]!Hz:8, "0x":4, dlog[2,9]!Hz:8, "0x":4, dlog[3,9]!Hz:8, "0x":4, dlog[4,9]!Hz:8 )
        fpga_read_gpio_capture_memory( "FPGA1" , 0 , 15 , gpio_mask )
    end_if
    
    if GPIO_Debug then
       Debug_GPIO_Consecutive_Fail(dlog, "DES->SER: Uncompensated Mode actual", FALSE, FALSE, 7, 40, 55, gpio_mask)
    endif



    -- ##################################################
    -- ##################################################
    -- ## FPGA->HS92-LINK->HS89->FPGA  (DES->SER)
    -- ##################################################
    --## Compensated Mode
    --## GPIO 0  -->    GPIO 0
    --## GPIO 1  -->    GPIO 1
    --## GPIO 6  -->    GPIO 2   -- GPIO 6  maps to both GPIO 2 & 6
    --## GPIO 7  -->    GPIO 3   -- GPIO 7  maps to both GPIO 3 & 7
    --## GPIO 8  -->    GPO  4   -- GPIO 8  maps to both GPIO 4 & 8
    --## GPIO 5  -->    GPO  5
    --## GPIO 6  -->    GPO  6
    --## GPIO 7  -->    GPIO 7
    --## GPIO 8  -->    GPIO 8
    --## GPIO 9  -->    GPIO 9
    --## GPIO 10 -->    GPIO 10
    --## GPIO 11 -->    GPIO 11
    --## GPIO 12 -->    GPIO 12
    --## GPIO 13 -->    GPIO 13
    --## GPIO 14 -->    GPIO 14
    --## GPIO 15 -->    GPIO 15
    --## GPIO 16 -->    GPIO 16
    --## GPIO 13 -->    GPIO 17  -- GPIO 13  maps to both GPIO 13 & 17
    --## GPIO 14 -->    GPIO 18  -- GPIO 14  maps to both GPIO 14 & 18
    -- ##################################################
    -- ##################################################


    -- #####################################
    -- ## Setup SER/DES for FPGA->DES->SER->FPGA   in Compensated Mode
    -- #####################################    

    
    -- ### DES/HS92
    fpga_UART_Write( "FPGA1" , "DES" , DESA_ID , DR_GPIO_A_0 , 1 , 0x63 )    -- # GPIO_0  GPIO_A/B/C
    fpga_UART_Write( "FPGA1" , "DES" , DESA_ID , DR_GPIO_A_1 , 1 , 0x63 )    -- # GPIO_1  GPIO_A/B/C   
    fpga_UART_Write( "FPGA1" , "DES" , DESA_ID , DR_GPIO_A_2 , 1 , 0x63 )    -- # GPIO_2  GPIO_A/B/C
    fpga_UART_Write( "FPGA1" , "DES" , DESA_ID , DR_GPIO_A_3 , 1 , 0x63 )    -- # GPIO_3  GPIO_A/B/C
    fpga_UART_Write( "FPGA1" , "DES" , DESA_ID , DR_GPIO_A_4 , 1 , 0x63 )    -- # GPIO_4  GPIO_A/B/C
    fpga_UART_Write( "FPGA1" , "DES" , DESA_ID , DR_GPIO_A_5 , 1 , 0x63 )    -- # GPIO_5  GPIO_A/B/C
    fpga_UART_Write( "FPGA1" , "DES" , DESA_ID , DR_GPIO_A_6 , 1 , 0x63 )    -- # GPIO_6  GPIO_A/B/C
    fpga_UART_Write( "FPGA1" , "DES" , DESA_ID , DR_GPIO_A_7 , 1 , 0x63 )    -- # GPI0_7  GPIO_A/B/C
    fpga_UART_Write( "FPGA1" , "DES" , DESA_ID , DR_GPIO_A_8 , 1 , 0x63 )    -- # GPI0_8  GPIO_A/B/C
    fpga_UART_Write( "FPGA1" , "DES" , DESA_ID , DR_GPIO_A_9 , 1 , 0x63 )    -- # GPI0_9  GPIO_A/B/C
    fpga_UART_Write( "FPGA1" , "DES" , DESA_ID , DR_GPIO_A_10 , 1 , 0x63 )    -- # GPI0_10 GPIO_A/B/C
    fpga_UART_Write( "FPGA1" , "DES" , DESA_ID , DR_GPIO_A_11 , 1 , 0x63 )    -- # GPIO_11 GPIO_A/B/C
    fpga_UART_Write( "FPGA1" , "DES" , DESA_ID , DR_GPIO_A_12 , 1 , 0x63 )    -- # GPIO_12 GPIO_A/B/C
    fpga_UART_Write( "FPGA1" , "DES" , DESA_ID , DR_GPIO_A_13 , 1 , 0x63 )    -- # GPIO_13 GPIO_A/B/C
    fpga_UART_Write( "FPGA1" , "DES" , DESA_ID , DR_GPIO_A_14 , 1 , 0x63 )    -- # GPIO_14 GPIO_A/B/C
    fpga_UART_Write( "FPGA1" , "DES" , DESA_ID , DR_GPIO_A_15 , 1 , 0x63 )    -- # GPIO_15 GPIO_A/B/C
    fpga_UART_Write( "FPGA1" , "DES" , DESA_ID , DR_GPIO_A_16 , 1 , 0x63 )    -- # GPIO_16 GPIO_A/B/C
    fpga_UART_Write( "FPGA1" , "DES" , DESA_ID , DR_GPIO_A_17 , 1 , 0x63 )    -- # GPIO_17 GPIO_A/B/C


    -- # Setup source start/stop address
    fpga_write_data = 0x004b003C   -- 60 to 75
    fpga_write_register( "FPGA1" , GPIO_CAPTURE_CONTROL , fpga_write_data )


    -- # Set data rate for GPIO
    SetGpioDataRate(200KHz)

    -- # Set delay before capturing GPIO inputs (Typically set to same value as divider)
    SetGpioCaptureDelay(2.5us)


    -- # GPIO_CONTROL_REG[9]=Start, GPIO_CONTROL_REG[1]=Enable Internal Loopback
    -- # GPIO_CONTROL_REG[0]=TestDirection (0=DUT->DNUT, 1=DNUT->DUT)

    fpga_write_data = 0x00000200
    fpga_write_register( "FPGA1" , GPIO_CONTROL_REG , fpga_write_data )


    -- # Readback status
    -- # GPIO_TEST_RESULTS[3]=Internal Loopback Used, [2]=GpioTestActive, [1]=testCompleted, [0]=testPassed
    fpga_read_int = integer( fpga_read_register( "FPGA1" , GPIO_TEST_RESULTS ) )
    scatter_1d( fpga_read_int , dlog , 10 )

    --   # GPIO_NUM_CAPS_CAPTURED
    fpga_read_int = integer( fpga_read_register( "FPGA1" , GPIO_NUM_CAPS_CAPTURED ) )
    scatter_1d( fpga_read_int , dlog , 11 )

    --   # GPIO_NUM_FAILING_VECTORS
    fpga_read_int = integer( fpga_read_register( "FPGA1" , GPIO_NUM_FAILING_VECTORS ) )
    scatter_1d( fpga_read_int , dlog , 12 )



    if DEBUG then
        println(stdout, "DES->SER: Compensated Mode actual")
        println(stdout, "GPIO_TEST_RESULTS":-40,        "0x":4, dlog[1,10]!Hz:8, "0x":4, dlog[2,10]!Hz:8, "0x":4, dlog[3,10]!Hz:8, "0x":4, dlog[4,10]!Hz:8 )
	println(stdout, "GPIO_NUM_CAPS_CAPTURED":-40,   "0x":4, dlog[1,11]!Hz:8, "0x":4, dlog[2,11]!Hz:8, "0x":4, dlog[3,11]!Hz:8, "0x":4, dlog[4,11]!Hz:8 )
	println(stdout, "GPIO_NUM_FAILING_VECTORS":-40, "0x":4, dlog[1,12]!Hz:8, "0x":4, dlog[2,12]!Hz:8, "0x":4, dlog[3,12]!Hz:8, "0x":4, dlog[4,12]!Hz:8 )
        fpga_read_gpio_capture_memory( "FPGA1" , 0 , 15 , gpio_mask )
    end_if
    
    if GPIO_Debug then
       Debug_GPIO_Consecutive_Fail(dlog, "DES->SER: Compensated Mode actual", FALSE, TRUE, 10, 60, 75, gpio_mask)
    endif



    ----------------------------------------------------------------
    -- datalog
    ----------------------------------------------------------------
    test_value  SerLock with SerLock_it
    test_value  DesLock with DesLock_it
    test_value  dlog    with gng_lim

    ----------------------------------------------------------------
    -- cleanup
    ----------------------------------------------------------------
    -- turn off the FPGA GPIO functional block
    fpga_write_data = 0x00000000
    fpga_write_register( "FPGA1" , GPIO_CONTROL_REG , fpga_write_data )
    
 -- Set direction of Level Translators
    SetPortExpander(PORT_EXP, 0x3F)  --   -- All SER GPIOs to FPGA
    wait(0ms)


    if(TRUE) then
        fpga_Set_DNUT_Pins("FPGA1", 0 ,0, 0, 0, TRUE)  -- UART/TP/GMSL2=1/RATE=0(6 Gig link)
        set digital pin ALL_PATTERN_PINS  - FPGA_CSB-FPGA_SCLK-FPGA_SDIN-FPGA_SDOUT levels to vil 0V vih 200mV iol 0uA ioh 0uA vref 0V            
        powerdown_device(TRUE) -- (POWERDOWN)
        open cbit  DNUT_RXTX_RELAY + MFP_LT_K12_RELAY
        open cbit  MFP_LT_RELAY  + I2C_LT_CB

        open cbit CB2_SLDC                 --OVI_RELAYS 
        open cbit COAXB_M_RELAY            --OVI_RELAYS
        open cbit  FB_RELAY
        wait(5ms)
    end_if


end_body




procedure KeepTrackOfBinResults
--------------------------------------------------------------------------------
-- This procedure checks the bin result for each site
-- If a site fails bin73 (4) consecutive times, the GPIO patterns will be reloaded

local multisite integer : bin_result

local word              : csite, numsites
local word list[5]      : bins
local word list[8]      : asites

body

    asites   = get_active_sites()
    numsites = word(len(asites))
    bin_result = get_swbins()  -- record per site bin results

    bins = <:73:>  -- GPIO_Func

    
    for idx = 1 to numsites do
        csite = asites[idx]

        if word(bin_result[csite]) in bins then
           bin73cnt[csite] = bin73cnt[csite] + 1
        elseif bin_result[csite] == 1 then
           bin73cnt[csite] = 0
        endif
        
        if bin73cnt[csite] == 3 then
           GPIO_Debug = TRUE
        elseif bin73cnt[csite] > 3 then
           GPIO_Debug = FALSE
           Reload_GPIO_Patterns = TRUE
           bin73cnt[csite] = 0
        endif
        
    endfor


end_body


procedure Debug_GPIO_Consecutive_Fail(dlog, mssg, OPEN_FILE, CLOSE_FILE, ii, stAdd, endAdd, pinmask)
--------------------------------------------------------------------------------
--  
in multisite integer       : dlog[18]
in string[80]              : mssg
in boolean                 : OPEN_FILE
in boolean                 : CLOSE_FILE
in word                    : ii
in word                    : stAdd, endAdd
in multisite lword         : pinmask

local integer              : output_file
local integer              : script_file
local string[50]           : LotID
local string[25]           : Temp
local string[25]           : device
local string[50]           : eva_name
local string[40]           : test_program
local multisite lword      : fpga_rev
local multisite lword      : ADC_code
local multisite float      : fpga_die_temp

body


if OPEN_FILE then
    get_expr("TestProgData.LotId",        LotID)
    get_expr("TestProgData.LotDesc",      Temp)
    get_expr("TestProgData.ProgFileName", eva_name)
    get_expr("TestProgData.ObjName",      test_program)
    get_expr("TestProgData.Device",       device)
    fpga_rev = fpga_read_register("FPGA1", FWREV_REG)
    ADC_code = fpga_read_register("FPGA1", FPGA_DIE_TEMP)              -- register d'119 contains the FPGA die temperature.  T =  [(ADC code * 503.975) / 4096] - 273.15
    fpga_die_temp = ((float(ADC_code) * 503.975) / 4096.0) - 273.15

-- Delete any existing files
    wait_for_nic_shell_command("rm GPIO_Func.txt")
    wait_for_nic_shell_command("rm sfile")

    
    open(output_file, "/tmp/GPIO_Func.txt", "w")

    
    print(output_file, "@n")
    println(output_file, "Lot Number        : ", LotID)
    println(output_file, "Test Step         : ", Temp)
    println(output_file, "Eva File Name     : ", eva_name)
    println(output_file, "Test Program      : ", test_program)
    println(output_file, "Device            : ", device)
    println(output_file, "FPGA Revision     : ", fpga_rev[1], "   ", fpga_rev[2],  "   ", fpga_rev[3],  "   ", fpga_rev[4])
    println(output_file, "FPGA Temperature  : ", fpga_die_temp[1], "C   ", fpga_die_temp[2],  "C   ", fpga_die_temp[3],  "C   ", fpga_die_temp[4],"C")
    
    
    print(output_file, "@n@n")

else
    open(output_file, "/tmp/GPIO_Func.txt", "a")
endif


    println(output_file, "GPIO Transmitt Pattern Memory =============================================")
    fpga_read_gpio_xmit_memory_to_file("FPGA1", output_file, stAdd, endAdd, pinmask)
    print(output_file, "@n")
    
    println(output_file, mssg)
    println(output_file, "GPIO_TEST_RESULTS":-40,        "0x":4, dlog[1,ii]!Hz:8,   "0x":4, dlog[2,ii]!Hz:8,   "0x":4, dlog[3,ii]!Hz:8,   "0x":4, dlog[4,ii]!Hz:8 )
    println(output_file, "GPIO_NUM_CAPS_CAPTURED":-40,   "0x":4, dlog[1,ii+1]!Hz:8, "0x":4, dlog[2,ii+1]!Hz:8, "0x":4, dlog[3,ii+1]!Hz:8, "0x":4, dlog[4,ii+1]!Hz:8 )
    println(output_file, "GPIO_NUM_FAILING_VECTORS":-40, "0x":4, dlog[1,ii+2]!Hz:8, "0x":4, dlog[2,ii+2]!Hz:8, "0x":4, dlog[3,ii+1]!Hz:8, "0x":4, dlog[4,ii+1]!Hz:8 )
    fpga_read_gpio_capture_memory_to_file( "FPGA1" , output_file, 0 , 15 , pinmask)
    print(output_file, "@n@n@n")
    
    

    

if CLOSE_FILE then
    close(output_file)

    GPIO_Debug = FALSE
    open(script_file, "/tmp/sfile", "w")
    chmod("/tmp/sfile", "755")
    println(script_file,"#!/bin/bash")
    println(script_file, "echo @"hs89 GPIO debug@" | mutt -a /tmp/GPIO_Func.txt -s @"hs89 consecutive GPIO fail debug@" aldo.rodriguez@@maximintegrated.com")
    close(script_file)
    wait_for_nic_shell_command("./sfile")
    
endif
    
end_body



procedure fpga_read_gpio_xmit_memory_to_file(FPGA, out_file, startAdd, endAdd, pinmask)
--------------------------------------------------------------------------------
-- This procedure reads out xmit gpio data and prints to a file
-- Data is masked before printing
--
in string[5]                            : FPGA          -- "FPGA1" or "FPGA2"
in integer                              : out_file
in word                                 : startAdd, endAdd
in multisite lword                      : pinmask

local word                              : dev , imem
local multisite lword                   : msdata

body

    if FPGA == "FPGA1" then
        dev = 0x00
    elseif FPGA == "FPGA2" then
        dev = 0x40
    endif

    println(out_file,"":-21, "SITE1":12,  "SITE2":12, "SITE3":12,  "SITE4":12)

    for imem = startAdd to endAdd do
        fpga_rw_datapair(FPGA_SRC_RD , dev , GPIO_SOURCE_RAM_READBACK , imem , msdata )
        msdata = msdata & pinmask
        
        print(out_file,"Data at address ", imem!z:4," is")
        print(out_file,"0x":4, msdata[1]!hz:8, "0x":4, msdata[2]!hz:8)
        print(out_file,"0x":4, msdata[3]!hz:8, "0x":4, msdata[4]!hz:8)
        println(out_file,"")
    end_for


end_body





procedure fpga_read_gpio_capture_memory_to_file(FPGA, out_file, startAdd, endAdd, pinmask)
--------------------------------------------------------------------------------
-- This procedure reads out captured gpio data and prints to a file
-- Data is masked before printing
--
in string[5]                            : FPGA          -- "FPGA1" or "FPGA2"
in integer                              : out_file
in word                                 : startAdd, endAdd
in multisite lword                      : pinmask

local word                              : dev , imem
local multisite lword                   : msdata

body

    if FPGA == "FPGA1" then
        dev = 0x00
    elseif FPGA == "FPGA2" then
        dev = 0x40
    endif

    println(out_file,"":-21, "SITE1":12,  "SITE2":12, "SITE3":12,  "SITE4":12)

    for imem = startAdd to endAdd do
        fpga_rw_datapair(FPGA_SRC_RD , dev , GPIO_CAPTURE_RAM_READBACK , imem , msdata )
        msdata = msdata & pinmask
        
        print(out_file,"Data at address ", imem!z:4," is")
        print(out_file,"0x":4, msdata[1]!hz:8, "0x":4, msdata[2]!hz:8)
        print(out_file,"0x":4, msdata[3]!hz:8, "0x":4, msdata[4]!hz:8)
        println(out_file,"")
    end_for


end_body




