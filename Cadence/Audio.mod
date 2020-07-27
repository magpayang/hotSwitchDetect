use module "./SERDES_Pins.mod"
use module "./FPGA.mod"
use module "./user_globals.mod"
use module "./functional.mod"
use module "./reg_access.mod"
use module "./tester_cbits.mod"
--use module "./HS87.tp"
use module "./gen_calls2.mod"
use module "./general_calls.mod"






function audio_pattern_address(Address) : lword
--------------------------------------------------------------------------------
--  This function determines the address of the specified pattern
in string[20]      :  Address

local lword        :  addr

body

    if(Address == "I2S_32") then
       addr = AUD_I2S_32
    else_if(Address == "TDM_8CH") then
       addr = AUD_8ch_TDM
    else
       addr = 0
    endif

    
    return(addr)

end_body


procedure wait_for_audio_pattern(Frequency, patsize, repeat_count)
--------------------------------------------------------------------------------
--  This functions calculates a wait time for pattern to finish transmitting

in  float     : Frequency
in  lword     : patsize
in  lword     : repeat_count

local  float  : temp


body

    temp = float(patsize * repeat_count)
    temp = temp / Frequency
    
    wait(temp)

end_body

procedure I2S_Audio_Timing_Char(OscFreq, SD_tsu_ft, WS_tsu_ft, SD_thd_ft, WS_thd_ft) 
--------------------------------------------------------------------------------
--  
in_out  float_test       : OscFreq
in_out  float_test       : SD_tsu_ft      -- SD setup time
in_out  float_test       : WS_tsu_ft      -- WS setup time
in_out  float_test       : SD_thd_ft      -- SD hold time
in_out  float_test       : WS_thd_ft      -- WS hold time

local
  multisite float        : osc_freq
  multisite lword        : data
  lword                  : PAT_ADDR
  lword                  : PAT_SIZE
  lword                  : RPT_CNT   -- Transmit repeat count
  lword                  : CMP_CNT   -- compare repeat count
  multisite float        : sd_su_time
  multisite float        : ws_su_time
  multisite float        : sd_hd_time
  multisite float        : ws_hd_time
  pin list[1]            : SCK_PIN, SD_PIN, WS_PIN
  string[3]              : Dev  = "DES" -- Capture Audio on "SER" or "DES"

end_local

body

-- define pins here
   SCK_PIN = SER_GPIO8_SCK
   SD_PIN  = SER_GPIO9_SD
   WS_PIN  = SER_GPIO7_WS



-- Connect DUT Audio Inputs to tester digital pins
   open cbit MFP_LT_RELAY
   wait(1ms)


-- Set Audio Clock Frequency
    FS7140SetFrequency(PROG_OSC, 6.25MHz)
    data = fpga_read_register("FPGA1", OSC1FREQ)
    osc_freq = float(data) * 1.0e5                                  -- Oscillator Frequency



-- On the FPGA side, Enable Audio & configure for audio Transmission from DES to SER.
-- Audio will come from the tester, but the FPGA needs to "think" it is sending the audio to the DES in order to capture the audio from the SER.
   fpga_write_register("FPGA1", GPIO_CONTROL, mslw(AUD_ENABLE))     -- Enable Audio
   fpga_write_register("FGPA1", CONFIG, mslw(0x01))                 --  0x01 -> Xmit on SER (Forward Audio) , 0x02 -> Xmit on DES (Reverse Audio)
   

-- Set the starting Audio pattern address, the size of the audio pattern, & the audio pattern repeat count.
-- The starting address is somewhat arbitrary and purposely chosen where there is no data stored in memory.
-- We need the FPGA to think it is sending the audio, but audio will actually come from the tester digital pins. 
   PAT_ADDR = 1400    
   PAT_SIZE = 16*2   -- 16 bits * 2 channels
   RPT_CNT  = 1760   -- chosen by experiment to ensure enough audio data is captured.
   CMP_CNT  = 14000 / (2 * 16)   -- compare 14000 sck cycles of audio


   fpga_audio_pattern_setup("FPGA1", PAT_ADDR, PAT_SIZE, RPT_CNT)

   
    
-- SD Setup Time
    sd_su_time = I2S_Bin_Search(SD_PIN, "data", "I2S_Write_TS", 1ns, 90.0ns, "I2S_16bit_Write", AUD_I2S_16, CMP_CNT, Dev)
    sd_su_time = 80ns - sd_su_time
    
-- WS Setup Time
    Move_Edge(SD_PIN, "data", "I2S_Write_TS", 1ns)    -- reset SD timing
    ws_su_time = I2S_Bin_Search(WS_PIN, "data", "I2S_Write_TS", 1ns, 90.0ns, "I2S_16bit_Write", AUD_I2S_16, CMP_CNT, Dev)
    ws_su_time = 80ns - ws_su_time
  
-- SD Hold Time
    Move_Edge(WS_PIN, "data", "I2S_Write_TS", 1ns)    -- reset WS timing
    sd_hd_time = I2S_Bin_Search(SD_PIN, "data", "I2S_Write_TS", 100ns, 18.0ns, "I2S_16bit_Write", AUD_I2S_16_HOLD, CMP_CNT, Dev)
    sd_hd_time = sd_hd_time - 80ns
  
  
-- WS Hold Time
    Move_Edge(SD_PIN, "data", "I2S_Write_TS", 1ns)    -- reset SD timing
    ws_hd_time = I2S_Bin_Search(WS_PIN, "data", "I2S_Write_TS", 100ns, 18.0ns, "I2S_16bit_Write_Hold", AUD_I2S_16, CMP_CNT, Dev)
    ws_hd_time = ws_hd_time - 80ns
    

    Move_Edge(WS_PIN, "data", "I2S_Write_TS", 1ns)  -- reset WS edge
    
 
    
-------------------------------------
----- POWER DOWN --------------------
-------------------------------------
  fpga_write_register("FPGA1", GPIO_CONTROL, mslw(0x00))  -- disable audio
  
  
  if(TRUE) then
        set digital pin ALL_PATTERN_PINS  - FPGA_CSB-FPGA_SCLK-FPGA_SDIN-FPGA_SDOUT levels to vil 0V vih 200mV iol 0uA ioh 0uA vref 0V            
        powerdown_device(TRUE) -- (POWERDOWN)
        open cbit  DNUT_RXTX_RELAY + MFP_LT_K12_RELAY
        open cbit  MFP_LT_RELAY  + I2C_LT_CB

        open cbit CB2_SLDC                 --OVI_RELAYS 
        open cbit COAXB_M_RELAY            --OVI_RELAYS
        open cbit  FB_RELAY
        wait(5ms)
   end_if


  test_value osc_freq           with OscFreq
  test_value sd_su_time         with SD_tsu_ft
  test_value ws_su_time         with WS_tsu_ft
  test_value sd_hd_time         with SD_thd_ft
  test_value ws_hd_time         with WS_thd_ft


end_body

function I2S_Bin_Search(pinn, move_edge, tset, startv, stopv, write_pat, compare_addr, repeat_cnt, Dev) :   multisite float
--------------------------------------------------------------------------------
--  This function does a binary search for some I2S parameters
in pin list[1]     : pinn          -- pin under test
in string[9]       : move_edge     -- edge to move (data or return)
in string[20]      : tset          -- name of timeset to change
in float           : startv        -- search starting edge value
in float           : stopv         -- search stop edge value
in string[40]      : write_pat     -- name of write pattern to run
in lword           : compare_addr  -- beginning address of the compare pattern
in lword           : repeat_cnt    -- Repeat count. Number of times pattern will be looped for compare purposes.
in string[3]       : Dev           -- This will be "SER" or "DES". It indicates which side Audio is captured from



local

word               : sites_local, csite
word               : idx
word list[16]      : active_sites_local
float              : bound1, bound2              -- binary search boundaries
float              : increment
multisite float    : current_value
multisite float    : last_passing, last_failing
multisite float    : result
multisite boolean  : patres
multisite lword    : data

end_local


body

    active_sites_local = get_active_sites
    sites_local = word(len(active_sites_local))
    
    increment = (stopv - startv)/4.0   -- set initial binary search increment  
    bound1 = startv                    -- lower boundary
    bound2 = stopv                     -- upper boundary

    
    if startv > stopv then
       bound1 = stopv
       bound2 = startv
    end_if
 
    
--------------- Begin search ----------------------------------------    
    current_value = (startv+stopv)/2.0
    
    while (current_value > bound1 AND current_value < bound2) do
    
       Move_Edge_multi(pinn, move_edge, tset, current_value)  -- change edge timing

       
     -- Run Audio Pattern
       I2S_Pattern_Execution(write_pat)   -- send I2S pattern

     -- Compare Captured Audio Data
       data = fpga_compare_audio_pattern("FPGA1", 0, repeat_cnt, compare_addr, Dev)

       
       for idx =1 to sites_local do
           csite = active_sites_local[idx]	  
           if data[csite] == 7 then
	      last_passing[csite]  = current_value[csite]
	      current_value[csite] = current_value[csite] + increment
           else
	      last_failing[csite]  = current_value[csite]
              current_value[csite] = current_value[csite] - increment
           end_if
       end_for
       
       if abs(increment) < 50.0ps then
          break     -- exit loop
       end_if
       
       increment = increment/2.0
    
               
    end_while
    
    
    for idx =1 to sites_local do
        csite = active_sites_local[idx]
        result[csite] = last_passing[csite]
    end_for

    return(result)
    
end_body


procedure Move_Edge(pinn, moveedge, tset, value)
--------------------------------------------------------------------------------
-- 
in pin list[1]      : pinn        -- pin under test
in string[9]        : moveedge    -- drive edge to be changed (start or return)
in string[20]       : tset        -- name of timeset to change
in float            : value       -- value to set for drive edge


body

   if moveedge == "data" then
      set digital pin pinn msdi drive data value for tset
   end_if
      
   if moveedge == "return" then
      set digital pin pinn msdi drive return value for tset
   end_if
   
   if moveedge == "compare" then
      set digital pin pinn msdi compare data value for tset
   end_if
      
      
end_body

procedure I2S_Pattern_Execution(pat)
--------------------------------------------------------------------------------
-- Function is to simulate running an audio pattern so that FPGA will
-- enable capture of audio data. This is needed because audio
-- data will come from DPINs

in  string[30]        :  pat     -- pattern to execute

local word            :  dword[4]


body
 
      dword[1] = CTRLREG
      dword[2] = 0
      dword[3] = 0
      dword[4] = APATXMIT
      
 -- Load the data to memory     
      load   digital reg_send fx1 waveform "FPGA_SRC_WR" with dword
      enable digital reg_send fx1 waveform "FPGA_SRC_WR"

 -- Run Pattern      
      execute digital pattern pat run to end wait
      wait(0ms)
    
end_body

procedure I2S_Audio_Timing_FT(POWERDOWN, sutime, hdtime, OscFreq, I2S1_bt, I2S2_bt, I2S3_bt, I2S4_bt)
--------------------------------------------------------------------------------
--  
in boolean               : POWERDOWN
in float                 : sutime, hdtime

in_out float_test        : OscFreq
in_out integer_test      : I2S1_bt
in_out integer_test      : I2S2_bt
in_out integer_test      : I2S3_bt
in_out integer_test      : I2S4_bt

local
  multisite float        : osc_freq
  multisite lword        : data
  multisite lword        : data1, data2, data3, data4
  multisite integer      : rslt1, rslt2, rslt3, rslt4
  lword                  : PAT_ADDR
  lword                  : PAT_SIZE
  lword                  : RPT_CNT   -- Transmit repeat count
  lword                  : CMP_CNT   -- compare repeat count
  pin list[1]            : SCK_PIN, SD_PIN, WS_PIN
  string[3]              : Dev  = "DES" -- Capture Audio on "SER" or "DES"

end_local

body

-- define pins here
   SCK_PIN = SER_GPIO8_SCK
   SD_PIN  = SER_GPIO9_SD
   WS_PIN  = SER_GPIO7_WS



-- Connect DUT Audio Inputs to tester digital pins
   open cbit MFP_LT_RELAY
   wait(1ms)


-- Set Audio Clock Frequency
   FS7140SetFrequency(PROG_OSC, 6.25MHz)
   data = fpga_read_register("FPGA1", OSC1FREQ)
   osc_freq = float(data) * 1.0e5                                   -- Oscillator Frequency



-- On the FPGA side, Enable Audio & configure for audio Transmission from DES to SER.
-- Audio will come from the tester, but the FPGA needs to "think" it is sending the audio to the DES in order to capture the audio from the SER.
   fpga_write_register("FPGA1", GPIO_CONTROL, mslw(AUD_ENABLE))     -- Enable Audio
   fpga_write_register("FGPA1", CONFIG, mslw(0x01))                 --  0x01 -> Xmit on SER (Forward Audio) , 0x02 -> Xmit on DES (Reverse Audio)
   

-- Set the starting Audio pattern address, the size of the audio pattern, & the audio pattern repeat count.
-- The starting address is somewhat arbitrary and purposely chosen where there is no data stored in memory.
-- We need the FPGA to think it is sending the audio, but audio will actually come from the tester digital pins. 
   PAT_ADDR = 1400    
   PAT_SIZE = 16*2   -- 16 bits * 2 channels
   RPT_CNT  = 1760   -- chosen by experiment to ensure enough audio data is captured.
   CMP_CNT  = 14000 / (2 * 16)   -- compare 14000 sck cycles of audio
   
   fpga_audio_pattern_setup("FPGA1", PAT_ADDR, PAT_SIZE, RPT_CNT)

   
------ I2S SD setup time  ------------------------------
-- Move_Edge(pinn, moveedge, tset, value) 
   Move_Edge(SD_PIN, "data", "I2S_Write_TS", (80ns-sutime))

   I2S_Pattern_Execution("I2S_16bit_Write")   -- send I2S pattern
   data1 = fpga_compare_audio_pattern("FPGA1", 0, CMP_CNT, AUD_I2S_16, Dev)
   
   
------ I2S WS setup time --------------------------
   Move_Edge(SD_PIN, "data", "I2S_Write_TS", 1ns)  -- reset SD edge
   Move_Edge(WS_PIN, "data", "I2S_Write_TS", (80ns-sutime))
   
   I2S_Pattern_Execution("I2S_16bit_Write")   -- send I2S pattern
   data2 = fpga_compare_audio_pattern("FPGA1", 0, CMP_CNT, AUD_I2S_16, Dev)
   
   
------ I2S SD hold time -----------------------
   Move_Edge(WS_PIN,  "data", "I2S_Write_TS", 1ns)  -- reset WS edge
   Move_Edge(SD_PIN,  "data", "I2S_Write_TS", (80ns+hdtime))
   
   I2S_Pattern_Execution("I2S_16bit_Write")   -- send I2S pattern
   data3 = fpga_compare_audio_pattern("FPGA1", 0, CMP_CNT, AUD_I2S_16_HOLD, Dev)
   
   
-----  I2S WS hold time -------------------
   Move_Edge(SD_PIN,  "data", "I2S_Write_TS", 1ns)   -- reset SD edge
   Move_Edge(WS_PIN, "data", "I2S_Write_TS", (80ns+hdtime))
   
   I2S_Pattern_Execution("I2S_16bit_Write_Hold")   -- send I2S pattern
   data4 = fpga_compare_audio_pattern("FPGA1", 0, CMP_CNT, AUD_I2S_16, Dev)
   
    
-------------------------------------
----- POWER DOWN --------------------
-------------------------------------
   Move_Edge(WS_PIN, "data", "I2S_Write_TS", 1ns)     -- reset WS edge
 
   fpga_write_register("FPGA1", GPIO_CONTROL, mslw(0x00))     -- Disable Audio
   
   
  if(POWERDOWN) then
        set digital pin ALL_PATTERN_PINS  - FPGA_CSB-FPGA_SCLK-FPGA_SDIN-FPGA_SDOUT levels to vil 0V vih 200mV iol 0uA ioh 0uA vref 0V            
        powerdown_device(TRUE) -- (POWERDOWN)
        open cbit  DNUT_RXTX_RELAY + MFP_LT_K12_RELAY
        open cbit  MFP_LT_RELAY  + I2C_LT_CB

        open cbit CB2_SLDC                 --OVI_RELAYS 
        open cbit COAXB_M_RELAY            --OVI_RELAYS
        open cbit  FB_RELAY
        wait(5ms)
   end_if
  
  
  ----- Datalog ---
   rslt1 = integer(data1)
   rslt2 = integer(data2)
   rslt3 = integer(data3)
   rslt4 = integer(data4)
   
   test_value osc_freq  with OscFreq
   test_value rslt1     with I2S1_bt
   test_value rslt2     with I2S2_bt
   test_value rslt3     with I2S3_bt
   test_value rslt4     with I2S4_bt


end_body


procedure Audio_Func(Vdd, Vddio, Vdd18, POWERUP, POWERDOWN, TP_COAX, TX_SPD, RX_SPD, ser_lock_it, Link_Lock_dly, Audio_Start_Addr, SCK_Freq, bits, test_audio1, test_audio2)
--------------------------------------------------------------------------------
in float              : Vdd, Vddio, Vdd18
in boolean            : POWERUP,POWERDOWN
in string[20]         : TP_COAX
in float              : TX_SPD, RX_SPD, Link_Lock_dly
in string[20]         : Audio_Start_Addr
in float              : SCK_Freq       -- Frequency of audio clock (SCK)
in lword              : bits           -- number of audio bits per channel

in_out  integer_test  : ser_lock_it
in_out integer_test   : test_audio1
in_out integer_test   : test_audio2



local
  multisite lword     : lock_status
  word                : CurSite
  multisite lword     : data
  multisite integer   : result1, result2,lock_status_integer
  float               : ttime
  lword               : reg
  lword               : PAT_ADDR
  lword               : PAT_SIZE
  lword               : RPT_CNT   -- Transmit repeat count
  lword               : CMP_CNT   -- compare repeat count
  
--   word LIST[MAX_SITES] : local_active_sites
--   word                 : local_sites
end_local


body
--   local_active_sites = get_active_sites()
--   local_sites = word(len(local_active_sites))
  
  

    disconnect hvvi chan SER_RSVD    -- need to float RSVD, important!!
    close cbit X1X2_POSC
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
     lock_status = Configure_And_Link(TP_COAX, TX_SPD, RX_SPD, Link_Lock_dly)
   ---------------------------------------------------------------------------
  
-- Connect Audio pins to FPGA
   -- already done above

-- Set direction of Level Translators
    SetPortExpander(PORT_EXP, 0x3D)  --
    wait(0ms)

  
-- Set Audio Clock Frequency
    FS7140SetFrequency(PROG_OSC, SCK_Freq)
    data = fpga_read_register("FPGA1", OSC1FREQ)

    
-- Disable SER GPIOs 7 thru 12
    reg = SR_GPIO_A_7
    for idx = 7 to 12 do
        fpga_UART_Write("FPGA1","SER", SER_ID, reg, 1, 0x81 )
        reg = reg + 3
    endfor
    
-- Disable DES GPIOs 6 thru 9, 16 & 17
    fpga_UART_Write("FPGA1","DES",DESA_ID, DR_GPIO_A_6, 1, 0x81 )
    fpga_UART_Write("FPGA1","DES",DESA_ID, DR_GPIO_A_7, 1, 0x81 )
    fpga_UART_Write("FPGA1","DES",DESA_ID, DR_GPIO_A_8, 1, 0x81 )
    fpga_UART_Write("FPGA1","DES",DESA_ID, DR_GPIO_A_9, 1, 0x81 )
    fpga_UART_Write("FPGA1","DES",DESA_ID, DR_GPIO_A_16, 1, 0x81 )
    fpga_UART_Write("FPGA1","DES",DESA_ID, DR_GPIO_A_17, 1, 0x81 )

    
    fpga_UART_Write("FPGA1","SER", SER_ID,  SR_REG2,      1, 0x57 )    -- Enable SER to transmit Audio
    fpga_UART_Write("FPGA1","SER", SER_ID,  SR_AUDIO_RX1, 1, 0x21 )    -- Enable SER to receive Audio
    fpga_UART_Write("FPGA1","DES", DESA_ID, 0x158,        1, 0x21 )    -- Enable DES to receive Audio
    fpga_UART_Write("FPGA1","DES", DESA_ID, DR_REG2,      1, 0xF7 )    -- Enable DES to transmit Audio


   
-- Enable Audio and select which side to trasmit audio from (SER or DES)
    fpga_write_register("FPGA1", GPIO_CONTROL, mslw(AUD_ENABLE))
    fpga_write_register("FGPA1", CONFIG, mslw(0x01))    --  0x01 -> Xmit on SER (Forward Audio) , 0x02 -> Xmit on DES (Reverse Audio)


--------------------------------------------------------------------------------------------------------
----  Send Audio Pattern
--------------------------------------------------------------------------------------------------------
   PAT_ADDR = audio_pattern_address(Audio_Start_Addr)
   PAT_SIZE = audio_pattern_size(Audio_Start_Addr, bits)
   RPT_CNT  = audio_repeat_count(SCK_Freq, PAT_SIZE, bits) -- 1050   -- 1050 for 32bit 192KHz, 550 for 8ch TDM, 1760 for 16bit 192
   CMP_CNT  = 15000 / PAT_SIZE 
   
   
   -- fpga_send_audio_pattern(startAddr, xlimit, RptCnt)
   fpga_send_audio_pattern("FPGA1", PAT_ADDR, PAT_SIZE, RPT_CNT)
   wait_for_audio_pattern(SCK_Freq, PAT_SIZE, RPT_CNT)
--   fpga_send_audio_pattern("FPGA1", PAT_ADDR, PAT_SIZE, LOOP_MODE)
--   fpga_stop_audio_pattern


--------------------------------------------------------------------------------------------------------
----  Compare Captured Audio Pattern
--------------------------------------------------------------------------------------------------------
 --fpga_compare_audio_pattern(capture_addr, repeat_cnt, compare_addr)
   data = fpga_compare_audio_pattern("FPGA1", 0, CMP_CNT, PAT_ADDR, "DES")
   result1 = integer(data)

   ----------------------------------------------------------------
   --------- DEBUG DEBUG ------------------------------------------
   --FPGA_Read_Audio_Capture_Memory("FPGA1", 0, 400, 1, "DES")
   --FPGA_Read_Audio_Xmit_Memory("FPGA1", 0, 32, 1)
   --data = fpga_read_register("FPGA1", AVCOUNT_DES)
    wait(0ms)
   ----------------------------------------------------------------

   
--------------------------------------------------------------------------------------------------------
-- Send Audio from DES to SER
--------------------------------------------------------------------------------------------------------

   fpga_write_register("FGPA1", CONFIG, mslw(0x02))    --  0x01 -> Xmit on SER (Forward Audio) , 0x02 -> Xmit on DES (Reverse Audio)
   fpga_send_audio_pattern("FPGA1", PAT_ADDR, PAT_SIZE, RPT_CNT)
   wait_for_audio_pattern(SCK_Freq, PAT_SIZE, RPT_CNT)
   
--------------------------------------------------------------------------------------------------------
----  Compare Captured Audio Pattern
--------------------------------------------------------------------------------------------------------
 --fpga_compare_audio_pattern(capture_addr, repeat_cnt, compare_addr)
   data = fpga_compare_audio_pattern("FPGA1", 0, CMP_CNT, PAT_ADDR, "SER")
   result2 = integer(data)

   --------------------------------------------------------------------
   ----------------- DEBUG DEBUG --------------------------------------
   --   FPGA_Read_Audio_Capture_Memory("FPGA1", 0, 100, 1, "SER")
   --   data = fpga_read_register("FPGA1", AVCOUNT_SER)
   --------------------------------------------------------------------


   
-------------------------------------
----- POWER DOWN --------------------
-------------------------------------
  fpga_write_register("FPGA1", GPIO_CONTROL, mslw(0x00))   -- disable audio function within FPGA
  
-- Set direction of Level Translators
   SetPortExpander(PORT_EXP, 0x3F)  --   -- All SER GPIOs to FPGA
   wait(0ms)


  if(TRUE) then
        set digital pin ALL_PATTERN_PINS  - FPGA_CSB-FPGA_SCLK-FPGA_SDIN-FPGA_SDOUT levels to vil 0V vih 200mV iol 0uA ioh 0uA vref 0V            
        powerdown_device(TRUE) -- (POWERDOWN)
        open cbit  DNUT_RXTX_RELAY + MFP_LT_K12_RELAY
        open cbit  MFP_LT_RELAY  + I2C_LT_CB

        open cbit CB2_SLDC                 --OVI_RELAYS 
        open cbit COAXB_M_RELAY            --OVI_RELAYS
        open cbit  FB_RELAY
        wait(5ms)
    end_if
  lock_status_integer =integer(lock_status)
  test_value lock_status_integer with ser_lock_it
  test_value result1     with test_audio1
  test_value result2     with test_audio2


end_body


function audio_pattern_size(Address, numbits) : lword
--------------------------------------------------------------------------------
--  This function determines the size (number of vectors) in one WS period
in string[20]      :  Address
in lword           :  numbits

local lword        :  size

body

    if(Address[1:3] == "I2S") then
       size = 2 * numbits
    else_if(Address[1:3] == "TDM") then
       size = 8 * numbits
    else
       size = 2 * numbits
    endif

    
    return(size)

end_body

function audio_repeat_count(Freq, patsize, numbits) : lword
--------------------------------------------------------------------------------
--  RptCnt specifies how many cycles of WS to transmit
--  The RptCnt is set by experiment such that we can capture at least 15,000 
--  audio clock cycles

in float           :  Freq
in lword           :  patsize
in lword           :  numbits

local float        :  WSFreq
local lword        :  NumChan
local lword        :  RptCnt

body

    WSFreq  = Freq / float(patsize)    -- WS Frequency
    NumChan = patsize / numbits        -- number of audio channels

------------------------------------------------------------
--- Two Channel Audio --------------------------------------
    if NumChan == 2 then
       if WSFreq > 190KHz then
          if numbits == 32 then
             RptCnt = 1070
          elseif numbits = 16 then
             RptCnt = 1760
          else
             RptCnt = 1000
          endif
       else
          RptCnt = 500
       endif

------------------------------------------------------------
---- Eight Channel Audio -----------------------------------       
    elseif NumChan == 8 then
       if WSFreq > 190KHz then
          if numbits == 32 then
             RptCnt = 550
          elseif numbits == 16 then
             RptCnt = 600
          else
             RptCnt = 100
          endif
       else
          RptCnt = 10
       endif
    endif

    
    return(RptCnt)

end_body

procedure Audio_Debug(Vdd, Vddio, Vdd18, POWERUP, POWERDOWN, TP_COAX, TX_SPD, RX_SPD, ser_lock_it, Link_Lock_dly)
--------------------------------------------------------------------------------
in float                        : Vdd, Vddio, Vdd18
in_out  integer_test            : ser_lock_it

in boolean                      : POWERUP,POWERDOWN
in string[20]                   : TP_COAX--, CSI_MODE                          -----TP_COAX : TP or COAX mode, CSI_MODE --- 1x4,2x4,1x2...
in float                        : TX_SPD, RX_SPD, Link_Lock_dly 


local multisite lword           : lock_status
local multisite lword           : data

body

    disconnect hvvi chan SER_RSVD    -- need to float RSVD, important!!
    close cbit X1X2_POSC
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
     data  = fpga_UART_Read("FPGA1", "SER", SER_ID, 0, 1)


-- Establish Link Lock
     lock_status = Configure_And_Link(TP_COAX, TX_SPD, RX_SPD, Link_Lock_dly)

     
-- Set Audio Clock Frequency
    FS7140SetFrequency(PROG_OSC, 6.144MHz)
    data = fpga_read_register("FPGA1", OSC1FREQ)
    
    
    SetPortExpander(PORT_EXP, 0x3D)  --
    wait(0ms)
    

    
-------------- Power Down --------------------------- 
       
--    if (POWERDOWN) then
      if(TRUE) then
        set digital pin ALL_PATTERN_PINS  - FPGA_CSB-FPGA_SCLK-FPGA_SDIN-FPGA_SDOUT levels to vil 0V vih 200mV iol 0uA ioh 0uA vref 0V            
        powerdown_device(TRUE) -- (POWERDOWN)
        open cbit  DNUT_RXTX_RELAY + MFP_LT_K12_RELAY
        open cbit MFP_LT_RELAY  + I2C_LT_CB

        open cbit CB2_SLDC                 --OVI_RELAYS 
        open cbit COAXB_M_RELAY            --OVI_RELAYS
        open cbit  FB_RELAY
        wait(5ms)
    end_if


end_body

procedure DutPowerLinked(Vdd, Vddio, Vdd18, POWERUP, TP_COAX, TX_SPD, RX_SPD, SerLock_it, DesLock_it)
--------------------------------------------------------------------------------
--  
in float                : Vdd, Vddio, Vdd18
in boolean              : POWERUP
in string[20]           : TP_COAX
in float                : TX_SPD, RX_SPD

in_out integer_test     : SerLock_it
in_out integer_test     : DesLock_it

local multisite lword   : lock_result
local multisite integer : SerLock, DesLock


body

    disconnect hvvi chan SER_RSVD    -- need to float RSVD, important!!
    close cbit X1X2_POSC
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
     lock_result = Configure_And_Link2(TP_COAX, TX_SPD, RX_SPD)
     
     SerLock = integer((lock_result & 0xFF00) >> 8)
     DesLock = integer(lock_result & 0xFF)
     
     test_value SerLock with SerLock_it
     test_value SerLock with DesLock_it

end_body

function Configure_And_Link2(TP_COAX, TX_SPD, RX_SPD) : multisite lword
--------------------------------------------------------------------------------
--  
in string[6]           : TP_COAX
in float               : TX_SPD, RX_SPD



local lword            : ser_tx_speed, ser_rx_speed
local lword            : des_tx_speed, des_rx_speed
local lword            : ser_link_speed_code
local lword            : des_link_speed_code
local multisite lword  : SerLock, DesLock
local multisite lword  : lock_result
local word             : site, ii


body

 ----Set SER and DES for coax or tp mode
    if TP_COAX = "TP" then           
        fpga_UART_Write("FPGA1","SER", SER_ID, SR_CTRL1, 1, 0x0A)                  ---- TP mode SR_CTRL1  =0X11
        fpga_UART_Write("FPGA1","DES", DESA_ID, DR_CTRL1, 1, 0x0A)                 ---- TP mode   DR_CTRL1 = 0x11       
    else
        fpga_UART_Write("FPGA1","SER", SER_ID, SR_CTRL1, 1, 0x0F)                  ---- coax mode SR_CTRL1  =0X11            
        fpga_UART_Write("FPGA1","DES", DESA_ID, DR_CTRL1, 1, 0x0F)                 ---- coax mode   DR_CTRL1 = 0x11      
    end_if 


-------Set GMSL link forward and backward speed.

    if TX_SPD = 6GHz then
       ser_tx_speed = 0x8
       des_rx_speed = 0x2
    elseif      TX_SPD = 3GHz then
       ser_tx_speed = 0x4
       des_rx_speed = 0x1            
    elseif      TX_SPD = 1.5GHz then    ----need rev  = 0.1875GHz
       ser_tx_speed = 0x0
       des_rx_speed = 0x0                     
    end_if  


   if RX_SPD = 1.5GHz then
       ser_rx_speed = 0x3
       des_tx_speed = 0xC
   elseif      RX_SPD = 0.75GHz then
       ser_rx_speed = 0x2
       des_tx_speed = 0x8      
      
   elseif   RX_SPD = 0.375GHz then
       ser_rx_speed = 0x1
       des_tx_speed = 0x4          
   elseif   RX_SPD = 0.1875GHz then
       ser_rx_speed = 0x0
       des_tx_speed = 0x0               
   end_if 
   
   ser_link_speed_code = ser_rx_speed + ser_tx_speed
   des_link_speed_code = des_rx_speed + des_tx_speed
-----TP only work up to 3GHz
    if TP_COAX = "TP" and TX_SPD >3GHz then
        
        ----put print statement on screen to notify engineer ---- do this later
        ser_link_speed_code   = 0   ---fail part
        des_link_speed_code   = 0
    end_if 
----Program link rate
    fpga_UART_Write("FPGA1","DES", DESA_ID, DR_REG1, 1,des_link_speed_code  )             ---- DES GMSL link speed
    fpga_UART_Write("FPGA1","SER", SER_ID, SR_REG1, 1, ser_link_speed_code  )             ---- SER GMSL link speed
    
-- Diable VDDCMP Errors
    fpga_UART_Write("FPGA1","SER", SER_ID, SR_INTR6, 1, 0x63  )
-----Write to reg10 to update link speed setting 

    fpga_UART_Write("FPGA1","DES", DESA_ID, DR_CTRL0 , 1, 16#01  )
    wait(15ms)
    fpga_UART_Write("FPGA1","SER", SER_ID, SR_CTRL0 , 1, 16#21  )           ---Set auto link config and one shot; auto link will select both links for HS89

--------------Check for lock, error bit
----Currently, HS89 rev 1.5G error bit always on.
----at fwd_speed = 6.0G, REV_SPEED = 0.75 then no error.
----at fwd_speed = 3.0G, REV_SPEED = 0.375 then no error.
---------------------------------------------------------------------------------------------------------------------------------------------

   wait(30ms) 
   
   SerLock  = fpga_UART_Read("FPGA1", "SER", SER_ID, 0x13, 1)
   DesLock  = fpga_UART_Read("FPGA1", "DES", DESA_ID, 0x13, 1)
   
   
   active_sites = get_active_sites
   sites = word(len(active_sites))  
 
   for idx = 1 to sites do
     site = active_sites[idx]
     if (SerLock[site] < 0xFF)  AND ((SerLock[site] & 0xDA) <> 0xDA) then    
        for ii = 1 to 100 do
           SerLock = fpga_UART_Read("FPGA1", "SER", SER_ID,  0x13, 1)        -- 0xDA: Lock
           DesLock = fpga_UART_Read("FPGA1", "DES", DESA_ID, 0x13, 1)        -- 0xDA: Lock
           wait(1ms)
           if (SerLock[site] < 0xFF)  AND ((SerLock[site] & 0xDA) == 0xDA) then
              break
           endif
        endfor
     endif 
   end_for

   lock_result = (SerLock << 8) + DesLock
   return(lock_result)


end_body

procedure Audio_Func2(POWERDOWN, Audio_Start_Addr, SCK_Freq, bits, OscFreq, test_audio1, test_audio2)
--------------------------------------------------------------------------------
in boolean            : POWERDOWN
in string[20]         : Audio_Start_Addr
in float              : SCK_Freq       -- Frequency of audio clock (SCK)
in lword              : bits           -- number of audio bits per channel

in_out float_test     : OscFreq
in_out integer_test   : test_audio1
in_out integer_test   : test_audio2



local
  multisite float     : osc_freq
  multisite lword     : data
  multisite integer   : result1, result2
  float               : ttime
  lword               : reg
  lword               : PAT_ADDR
  lword               : PAT_SIZE
  lword               : RPT_CNT   -- Transmit repeat count
  lword               : CMP_CNT   -- compare repeat count
  
end_local


body

  
-- Connect Audio pins to FPGA
   -- already done

-- Set direction of Level Translators
    SetPortExpander(PORT_EXP, 0x3D)  --
    wait(0ms)
    
-- Increase I2S edge rate    
    if vdd_global[1] < 2.0V then
       fpga_UART_Write("FPGA1","SER", SER_ID,  SR_CMU4,  1, 0xA7 )
    else
       fpga_UART_Write("FPGA1","SER", SER_ID,  SR_CMU4,  1, 0xAB )
    endif

  
-- Set Audio Clock Frequency
    FS7140SetFrequency(PROG_OSC, SCK_Freq)
    data = fpga_read_register("FPGA1", OSC1FREQ)
    osc_freq = float(data) * 1.0e5                                     -- Oscillator Frequency

    
    fpga_UART_Write("FPGA1","SER", SER_ID,  SR_REG2,      1, 0x57 )    -- Enable SER to transmit Audio
    fpga_UART_Write("FPGA1","SER", SER_ID,  SR_AUDIO_RX1, 1, 0x21 )    -- Enable SER to receive Audio
    fpga_UART_Write("FPGA1","DES", DESA_ID, 0x158,        1, 0x21 )    -- Enable DES to receive Audio
    fpga_UART_Write("FPGA1","DES", DESA_ID, DR_REG2,      1, 0xF7 )    -- Enable DES to transmit Audio


   
-- Enable Audio and select which side to trasmit audio from (SER or DES)
    fpga_write_register("FPGA1", GPIO_CONTROL, mslw(AUD_ENABLE))
    fpga_write_register("FGPA1", CONFIG, mslw(0x01))    --  0x01 -> Xmit on SER (Forward Audio) , 0x02 -> Xmit on DES (Reverse Audio)


--------------------------------------------------------------------------------------------------------
----  Send Audio Pattern
--------------------------------------------------------------------------------------------------------
   PAT_ADDR = audio_pattern_address(Audio_Start_Addr)
   PAT_SIZE = audio_pattern_size(Audio_Start_Addr, bits)
   RPT_CNT  = audio_repeat_count(SCK_Freq, PAT_SIZE, bits) -- 1050   -- 1050 for 32bit 192KHz, 550 for 8ch TDM, 1760 for 16bit 192
   CMP_CNT  = 15000 / PAT_SIZE 
   
   
   -- fpga_send_audio_pattern(startAddr, xlimit, RptCnt)
   fpga_send_audio_pattern("FPGA1", PAT_ADDR, PAT_SIZE, RPT_CNT)
   wait_for_audio_pattern(SCK_Freq, PAT_SIZE, RPT_CNT)
--   fpga_send_audio_pattern("FPGA1", PAT_ADDR, PAT_SIZE, LOOP_MODE)
--   fpga_stop_audio_pattern


--------------------------------------------------------------------------------------------------------
----  Compare Captured Audio Pattern
--------------------------------------------------------------------------------------------------------
 --fpga_compare_audio_pattern(capture_addr, repeat_cnt, compare_addr)
   data = fpga_compare_audio_pattern("FPGA1", 0, CMP_CNT, PAT_ADDR, "DES")
   result1 = integer(data)

   ----------------------------------------------------------------
   --------- DEBUG DEBUG ------------------------------------------
   --FPGA_Read_Audio_Capture_Memory("FPGA1", 0, 400, 1, "DES")
   --FPGA_Read_Audio_Xmit_Memory("FPGA1", 0, 32, 1)
   --data = fpga_read_register("FPGA1", AVCOUNT_DES)
    wait(0ms)
   ----------------------------------------------------------------

   
--------------------------------------------------------------------------------------------------------
-- Send Audio from DES to SER
--------------------------------------------------------------------------------------------------------

   fpga_write_register("FGPA1", CONFIG, mslw(0x02))    --  0x01 -> Xmit on SER (Forward Audio) , 0x02 -> Xmit on DES (Reverse Audio)
   fpga_send_audio_pattern("FPGA1", PAT_ADDR, PAT_SIZE, RPT_CNT)
   wait_for_audio_pattern(SCK_Freq, PAT_SIZE, RPT_CNT)
   
--------------------------------------------------------------------------------------------------------
----  Compare Captured Audio Pattern
--------------------------------------------------------------------------------------------------------
 --fpga_compare_audio_pattern(capture_addr, repeat_cnt, compare_addr)
   data = fpga_compare_audio_pattern("FPGA1", 0, CMP_CNT, PAT_ADDR, "SER")
   result2 = integer(data)

   --------------------------------------------------------------------
   ----------------- DEBUG DEBUG --------------------------------------
   --   FPGA_Read_Audio_Capture_Memory("FPGA1", 0, 100, 1, "SER")
   --   data = fpga_read_register("FPGA1", AVCOUNT_SER)
   --------------------------------------------------------------------


   
-------------------------------------
----- POWER DOWN --------------------
-------------------------------------
  fpga_write_register("FPGA1", GPIO_CONTROL, mslw(0x00))   -- disable audio function within FPGA
  
-- Set direction of Level Translators
   SetPortExpander(PORT_EXP, 0x3F)  --   -- All SER GPIOs to FPGA
   wait(0ms)


  if(POWERDOWN) then
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

  test_value osc_freq    with OscFreq
  test_value result1     with test_audio1
  test_value result2     with test_audio2


end_body



procedure Move_Edge_multi(pinn, moveedge, tset, value)
--------------------------------------------------------------------------------
-- 
in pin list[1]      : pinn        -- pin under test
in string[9]        : moveedge    -- drive edge to be changed (start or return)
in string[20]       : tset        -- name of timeset to change
in multisite float  : value       -- value to set for drive edge


body

   if moveedge == "data" then
      set digital pin pinn msdi drive data value for tset
   end_if
      
   if moveedge == "return" then
      set digital pin pinn msdi drive return value for tset
   end_if
   
   if moveedge == "compare" then
      set digital pin pinn msdi compare data value for tset
   end_if
      
      
end_body

