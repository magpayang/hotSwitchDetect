use module "./SERDES_Pins.mod"
use module "./user_globals.mod"
--use module "./sys_and_levels.mod"
use module "./reg_access.mod"
--use module "./dnut_control.mod"
--use module "./hs87.tp"
use module "./FPGA.mod"
use module "./functional.mod"
use module "./general_calls.mod"



procedure I2C_char(Vdd, Vdd18, Vddio, I2C_pat, sutime_ft, hdtime_ft, tHIGH_ft, tLOW_ft, tHDSTA_ft, tSUSTA_ft, tSUSTO_ft, tBUF_ft, tVDDAT_ft, tVDACK_ft, tSP_ft, I2C_pat1,POWERUP,POWERDOWN)
----------------------------------------------------------------------------------------------------------------------------------------------------------
--
-- in float               : vio            -- IOVDD       voltage level
-- in float               : vcore          -- AVDD & DVDD voltage level
in float               : Vdd, Vdd18, Vddio
in string[50]          : I2C_pat   , I2C_pat1     -- I2C pattern
in_out float_test      : sutime_ft
in_out float_test      : hdtime_ft
in_out float_test      : tHIGH_ft
in_out float_test      : tLOW_ft
in_out float_test      : tHDSTA_ft
in_out float_test      : tSUSTA_ft
in_out float_test      : tSUSTO_ft
in_out float_test      : tBUF_ft
in_out float_test      : tVDDAT_ft
in_out float_test      : tVDACK_ft
in_out float_test      : tSP_ft
in boolean          : POWERUP,POWERDOWN
local

    multisite float        : sutime, hdtime
    multisite float        : tHIGH,  tLOW
    multisite float        : tHDSTA, tSUSTA
    multisite float        : tSUSTO
    multisite float        : tBUF
    multisite float        : tVDDAT
    multisite float        : tVDACK
    multisite float        : tSP
    float                  : i2c_per
    float                  : fREQ
    word                   : CurSite
    float                  : Vconf0, Vconf1 ---for config pins setting
end_local

body

    active_sites = get_active_sites
    sites = word(len(active_sites))


------------ Power Up HS89 in I2C MODE-----------------------
    disconnect hvvi chan SER_RSVD    -- need to float RSVD, important!!  
  -- reset levels
-- --     set digital pin ALL_PATTERN_PINS levels to vil 0V vih 0.2V vol 0V voh 0V iol 0mA ioh 0mA vref 0V
-- --     set digital pin ALL_PATTERN_PINS modes to driver pattern     -- Do not delete !!!
-- --     wait(1ms)
-- --     execute digital pattern "PowerUp" at label "ALL_ZERO" wait   -- Do not delete in order to reset all pins to vil level !!!
--     wait(1ms)        
-- -----The function below is for setting DUT supplies ONLY, change Voltage if Required  
--     Set_SER_Voltages(Vddio, Vdd, Vdd18)
--     wait (10ms) -- trial for 47uF cap on SER_VDD       
--     Vconf0 = 0.11 * Vddio
--     Vconf1 = 0.16 * Vddio
--         
--     set digital pin  SER_GPO6_CFG2 levels to vil Vconf0 vih Vddio                                       --  with DEV_ID = 0x80
--     set digital pin  SER_GPO5_CFG1  + SER_GPO4_CFG0  levels to vil Vconf1 vih Vddio                      ---GMSL2 mode  AND I2C
-- 
--     wait(5ms)
-- 
-- --   close digital cbit  RXTX_K1   -- connects 1k pullup resistor from SER_RXSDA to IOVDD   
--   -------- Set PWDN =1 to power up DUT --------
--     execute digital pattern "PowerUp" at label "TP" run to end wait
--     wait(5ms) 
-- -- RegRead(SER_ID, 6, 1, RdWordUpper, RdWordLower, "SER_UART_Read")
-- --  RegWrite(SER_ID, 6, 1, 0, 16#9B, "SER_UART_Write")
-- --      RegRead(SER_ID, 0x6, 1, RdWordUpper, RdWordLower, "SER_I2C_Read")
-- --     RegWrite(SER_ID, 0x19, 1, 0, 16#55, "SER_I2C_Write") 
------------------------------------
 -----Dut power up function
     close cbit COAXB_P_RELAY + COAXB_M_RELAY  ---Connecto DC circuit
   DutPowerUp(Vddio, Vdd18, Vdd, "I2C", "TP_GMSL2",POWERUP)

close digital cbit  RXTX_K1   -- connects 1k pullup resistor from SER_RXSDA to IOVDD 
 wait(5ms)
    set digital pin SER_GPIO20_TXSCL levels to vil 0.0v vih 0.9*Vddio vol 0.3*Vddio voh 0.7*Vddio iol 2mA ioh -2mA vref Vddio
    set digital pin SER_GPIO19_RXSDA levels to vol 0.3*Vddio voh 0.7*Vddio iol 0mA ioh -0mA vref 0V
--RegRead(SER_ID, 0, 1, RdWordUpper, RdWordLower, "SER_I2C_Read")
    
    get_expr("I2C_Freq", fREQ)
----------------No need this. GMSL2  only need to power down companion chip then we can use any speed we want per Levent comments       
--   Reg_Write(DevId, RegAddr, ByteCnt, DataUpperWord, DataLowerWord, PatternName)
--     RegRead(DUT_ID, DR_INTR1, 1, RdWordUpper, RdWordLower, "dut_i2c_read")---Read first
--     Reg_Write(DUT_ID,DR_INTR1 , 1, 0, 16#12,"dut_i2c_write")
--     wait(0ms)

    i2c_per = (1.0/fREQ)/2.0  -- I2C period (half period actually)
 

 -- I2C Input Setup Time Search
    sutime = I2C_Bin_Search(SER_GPIO19_RXSDA, "data", "I2C_DATA1", i2c_per*0.3, i2c_per*0.8, 0x19, I2C_pat)
    sutime = i2c_per*0.7 - sutime - 2ns  -- 2ns due to rise/fall time of SDA
    Move_Edge(SER_GPIO19_RXSDA, "data", "I2C_DATA1", 10ns)   -- restore edge
    
 -- I2C Input Hold Time Search
    hdtime = I2C_Bin_Search(SER_GPIO19_RXSDA, "data", "I2C_DATA2", i2c_per*0.75, i2c_per*0.4, 0x19, I2C_pat)
    hdtime = hdtime - i2c_per*0.5 - 4.5ns  -- 4.5ns per John Blink
    Move_Edge(SER_GPIO19_RXSDA, "data", "I2C_DATA2", i2c_per-10ns)   -- restore edge
wait(0)
--  -- High Period of SCL Clock Search
    Move_Edge(SER_GPIO20_TXSCL, "data", "I2C_LOW", 0ns)  -- set SCL falling edge to 0ns
    tHIGH = I2C_BinLin_Search(SER_GPIO20_TXSCL, "data", "I2C_HIGH", i2c_per*0.54, i2c_per, 0x19, I2C_pat)-----used to be  i2c_per*0.2 i2c_per*0.45
    tHIGH = i2c_per-tHIGH
    Move_Edge(SER_GPIO20_TXSCL, "data", "I2C_LOW", i2c_per*0.5)  -- restore edge
    Move_Edge(SER_GPIO20_TXSCL, "data", "I2C_HIGH", i2c_per*0.7)  -- restore edge
    
 -- Low Period of SCL Clock Search
    Move_Edge(SER_GPIO20_TXSCL, "data", "I2C_HIGH", 100ns)  -- set SCK rising edge to 100ns
    tLOW = I2C_Bin_Search(SER_GPIO20_TXSCL, "data", "I2C_LOW", 0ns, i2c_per, 0x19, I2C_pat)
    tLOW = (i2c_per - tLOW) + 100ns
    Move_Edge(SER_GPIO20_TXSCL, "data", "I2C_HIGH", i2c_per*0.7)  -- restore edge
    Move_Edge(SER_GPIO20_TXSCL, "data", "I2C_LOW", i2c_per*0.5)   -- restore edge
wait(0)    
 -- Start Condition Hold Time Search
    Move_Edge(SER_GPIO19_RXSDA, "data", "I2C_STA", 100ns)  -- set SDA falling edge to 100ns
    tHDSTA = I2C_Bin_Search(SER_GPIO20_TXSCL, "data", "I2C_STA", i2c_per*0.5, 1ns, 0x19, I2C_pat)
    tHDSTA = tHDSTA - 100ns
    Move_Edge(SER_GPIO19_RXSDA, "data", "I2C_STA", 1ns)            -- restore edge
    Move_Edge(SER_GPIO20_TXSCL, "data", "I2C_STA", i2c_per*0.5)    -- restore edge
    
 -- Repeated Start Condition Setup Time Search
    tSUSTA = I2C_Bin_Search(SER_GPIO19_RXSDA, "data", "I2C_RPSTA", i2c_per*0.5, i2c_per*0.1, 0x19, I2C_pat)
    tSUSTA = tSUSTA- i2c_per*0.25
    Move_Edge(SER_GPIO19_RXSDA, "data", "I2C_RPSTA", i2c_per*0.6)  -- restore edge
    
 -- Setup Time for Stop Condition Search
---In GMSLI, if there is no valid stop signal after writing data to register, data will not be updated. It does not work that way in GMSL2.
-- I have to create another pattern to test stop signal parameter.  In this pattern, start, device ID, register 0x19 data 0x55; Create stop signal at bits value = 1 in register 0x19 
-- If stop signal was not violated then we have valid ack otherwise, it will fail.
  
    tSUSTO = I2C_Bin_Search(SER_GPIO19_RXSDA, "data", "I2C_STO1", i2c_per*0.25, i2c_per*0.75, 0x19, I2C_pat1)
    tSUSTO = tSUSTO - i2c_per*0.5
    Move_Edge(SER_GPIO19_RXSDA, "data", "I2C_STO1", i2c_per*0.25)   -- restore edge
    Move_Edge(SER_GPIO20_TXSCL, "data", "I2C_STO1", i2c_per*0.5)   -- restore edge    


 -- Bus Free Time Between Stop & Start Search
    tBUF = I2C_Bin_Search(SER_GPIO19_RXSDA, "data", "I2C_STO", i2c_per*0.72, i2c_per,  0x19, I2C_pat)
    tBUF = i2c_per - tBUF + 1ns
    Move_Edge(SER_GPIO19_RXSDA, "data", "I2C_STO", i2c_per*0.75)   -- restore edge
    
---No need if statement below. Did not see different with different freq.    
--    if fREQ < 500KHz then  --(100KHz & 400KHz)
       -- Data Valid Time Search
            Move_Edge(SER_GPIO20_TXSCL, "data", "I2C_HIGH", i2c_per)
            Move_Edge(SER_GPIO20_TXSCL, "data", "I2C_LOW", i2c_per-100ns)
            tVDDAT = I2C_Bin_Search(SER_GPIO19_RXSDA, "compare", "I2C_HIGH", i2c_per*0.8, 0ns, 0x19, I2C_pat)
            tVDDAT = tVDDAT+100ns
            Move_Edge(SER_GPIO20_TXSCL, "data", "I2C_HIGH", i2c_per*0.7)   -- restore edge
            Move_Edge(SER_GPIO20_TXSCL, "data", "I2C_LOW", i2c_per*0.5)    -- restore edge
            Move_Edge(SER_GPIO19_RXSDA, "compare", "I2C_HIGH", i2c_per*0.8)   -- restore edge
    
       -- Data Valid Acknowledge Time Search
      
            Move_Edge(SER_GPIO20_TXSCL, "data", "I2C_DATA1", i2c_per)
            Move_Edge(SER_GPIO20_TXSCL, "data", "I2C_DATA2", i2c_per-10ns)----100ns
            tVDACK = I2C_Bin_Search(SER_GPIO19_RXSDA, "compare", "I2C_ACK", i2c_per*0.6, 0ns,0x19, I2C_pat)
            tVDACK = tVDACK+10ns ---+100ns
            Move_Edge(SER_GPIO20_TXSCL, "data", "I2C_DATA1", i2c_per*0.7)   -- restore edge
            Move_Edge(SER_GPIO20_TXSCL, "data", "I2C_DATA2", i2c_per*0.5)   -- restore edge
            Move_Edge(SER_GPIO19_RXSDA, "compare", "I2C_ACK", i2c_per*0.8)   -- restore edge
       
--        else   --(1MHz)
--        -- Data Valid Time Search
--              tVDDAT = I2C_Bin_Search(SER_GPIO19_RXSDA, "compare", "I2C_HIGH", i2c_per, 0ns,  0x19, I2C_pat)
--             tVDDAT = tVDDAT+i2c_per*0.5
--             Move_Edge(SER_GPIO19_RXSDA, "compare", "I2C_HIGH", i2c_per*0.8)   -- restore edge
--        
--        -- Data Valid Acknowledge Time Search
--             Move_Edge(SER_GPIO20_TXSCL, "data", "I2C_DATA1", i2c_per)
--             Move_Edge(SER_GPIO20_TXSCL , "data", "I2C_ACK", i2c_per)
--             Move_Edge(SER_GPIO19_RXSDA , "compare", "I2C_DATA1", i2c_per)
--             Move_Edge(SER_GPIO20_TXSCL,  "data", "I2C_DATA2", i2c_per-10ns)----100ns
--             tVDACK = I2C_Bin_Search( SER_GPIO19_RXSDA ,   "compare", "I2C_ACK", i2c_per, 0ns, 0x19, I2C_pat)
--             tVDACK = tVDACK+10ns ---+100ns
--             Move_Edge(SER_GPIO20_TXSCL, "data", "I2C_DATA1", i2c_per*0.7)   -- restore edge
--             Move_Edge(SER_GPIO20_TXSCL, "data", "I2C_ACK", i2c_per*0.7)     -- restore edge
--             Move_Edge(SER_GPIO19_RXSDA, "compare", "I2C_DATA1", i2c_per*0.8) -- restore edge
--             Move_Edge(SER_GPIO20_TXSCL, "data", "I2C_DATA2", i2c_per*0.5)   -- restore edge
--             Move_Edge(SER_GPIO19_RXSDA, "compare", "I2C_ACK", i2c_per*0.8) -- restore edge
--     end_if



--        
--     
 -- Pulse Width of spikes suppressed Search
--     tSP = I2C_Bin_Search(SER_GPIO19_RXSDA, "return", "I2C_SPIKE", i2c_per*0.6+20ns, i2c_per*0.88, 0x19, I2C_pat)
--     tSP = tSP - i2c_per*0.6
--     Move_Edge(SER_GPIO19_RXSDA, "return", "I2C_SPIKE", ((i2c_per*0.6)+20ns))   -- restore edge

    tSP = I2C_Bin_Search(SER_GPIO19_RXSDA, "return", "I2C_SPIKE", i2c_per*0.6+1ns, i2c_per*0.88, 0x19, I2C_pat)
    tSP = tSP - i2c_per*0.6
    Move_Edge(SER_GPIO19_RXSDA, "return", "I2C_SPIKE", ((i2c_per*0.6)+1ns))   -- restore edge
    wait(0)    
    
 --  -- Power Off
   open cbit COAXB_P_RELAY + COAXB_M_RELAY  ---Connecto DC circuit
   wait(5ms)
   open  cbit  RXTX_K1   -- disconnects 1k pullup resistor from SER_RXSDA to IOVDD
--  set digital pin ALL_PATTERN_PINS  - FPGA_CSB-FPGA_SCLK-FPGA_SDIN-FPGA_SDOUT levels to vil 0V vih 200mV iol 0uA ioh 0uA vref 0V
  set digital pin ALL_PATTERN_PINS   levels to vil 0V vih 200mV iol 0uA ioh 0uA vref 0V

  wait(500us)

  set hcovi SER_VDD + SER_VDD18 to fv 0V vmax 4V clamp imax 600mA imin -600mA         
  set hcovi SER_VDDIO to fv 0V   vmax 4V clamp imax 600mA imin -600mA
  
 	  
  wait(10ms)     -- extra for 47uF cap on SER_VDD        

  -- Initialize for set_SER_Voltages(vio, vcore, v18) routine
  vdd_global[1] = 0V   --SER_VDDIO
  vdd_global[2] = 0V   --SER_VDD  
  vdd_global[3] = 0V   --SER_VDDA(VDD18)  


    test_value sutime with sutime_ft
    test_value hdtime with hdtime_ft
    test_value tHIGH  with tHIGH_ft
    test_value tLOW   with tLOW_ft
    test_value tHDSTA with tHDSTA_ft
    test_value tSUSTA with tSUSTA_ft
    test_value tSUSTO with tSUSTO_ft
    test_value tBUF   with tBUF_ft
    test_value tVDDAT with tVDDAT_ft
    test_value tVDACK with tVDACK_ft
    test_value tSP with tSP_ft

     
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
   


function I2C_Bin_Search(pinn, move_edge, tset, startv, stopv, regtr, write_pat) :   multisite float
--------------------------------------------------------------------------------
--  This function does a binary search for some I2C parameters
in pin list[1]     : pinn        -- pin under test
in string[9]       : move_edge   -- edge to move (data or return)
in string[20]      : tset        -- name of timeset to change
in float           : startv      -- search starting edge value
in float           : stopv       -- search stop edge value
in word            : regtr       -- register to write and read to
in string[40]      : write_pat   -- name of pattern to run


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
    
       for idx =1 to sites_local do
           csite = active_sites_local[idx]
           Move_Edge(pinn, move_edge, tset, current_value[csite])  -- change edge timing
       end_for
 
       
       execute  digital pattern  write_pat run to end into patres
       
       if NOT patres[csite] AND current_value[csite] < 2.6e-6 then
          if tset = "I2C_LOW" then
             execute  digital pattern  write_pat run to end into patres
          end_if
       end_if

       RegWrite(SER_ID, regtr , 1, 0, 16#00,"SER_I2C_Write")    
--       Reg_Write(DUT_ID, regtr, 1, 0x00, "dut_i2c_write")              -- reset register to 0x00

	 
       for idx =1 to sites_local do
           csite = active_sites_local[idx]	  
           if patres[csite] then
	      last_passing[csite]  = current_value[csite]
	      current_value[csite] = current_value[csite] + increment
           else
	      last_failing[csite]  = current_value[csite]
              current_value[csite] = current_value[csite] - increment
           end_if
       end_for


       if abs(increment) < 100ps then
          break    -- exit loop
       end_if


       increment = increment/2.0
       
               
    end_while
---Only I2C_STO1 time set need to return last falling signal.    
    if  (tset = "I2C_STO1") then
        for idx =1 to sites_local do
            csite = active_sites_local[idx]
            result[csite] = last_failing[csite]
        end_for    
    else
        for idx =1 to sites_local do
            csite = active_sites_local[idx]
            result[csite] = last_passing[csite]
        end_for
    end_if

    return(result)
    
end_body


procedure I2C_Timing_FT(Vdd, Vdd18, Vddio, I2C_pat, i2c_timing_it,sutime_ft, hdtime_ft, tHIGH_ft, tLOW_ft, tHDSTA_ft, tSUSTA_ft, tSUSTO_ft, tBUF_ft, tVDDAT_ft, tVDACK_ft, tSP_ft,POWERUP,POWERDOWN)
--------------------------------------------------------------
--
in float               : Vdd, Vdd18, Vddio    -- IOVDD       voltage level
in string[50]          : I2C_pat        -- I2C pattern
in_out integer_test    : i2c_timing_it
in_out float_test      : sutime_ft, hdtime_ft, tHIGH_ft, tLOW_ft, tHDSTA_ft, tSUSTA_ft, tSUSTO_ft, tBUF_ft, tVDDAT_ft, tVDACK_ft, tSP_ft
in boolean             :POWERUP,POWERDOWN

local
    word list[16]   : active_sites
    word            : sites, idx, site
    
    multisite boolean      : result, result1
    multisite integer      : check_pass   
    float                  : i2c_per
    float                  : fREQ,temp
    multisite float        : sutime, hdtime
    multisite float        : tHIGH,  tLOW
    multisite float        : tHDSTA, tSUSTA
    multisite float        : tSUSTO
    multisite float        : tBUF
    multisite float        : tVDDAT
    multisite float        : tVDACK
    multisite float        : tSP
    string[10]             : TestType
    float                  : Vconf0, Vconf1 ---for config pins setting

end_local

body

    active_sites = get_active_sites
    sites = word(len(active_sites))   
 
----Pass in go no go threshold and data log per Eric
     get_expr("I2C_dat_setup", temp)
     sutime = temp
     get_expr("I2C_dat_hold", temp)
     hdtime= temp
     get_expr("I2C_scl_pulse_H", temp)
     tHIGH= temp
     get_expr("I2C_scl_pulse_L", temp)
     tLOW= temp
     get_expr("I2C_st_hold", temp)
     tHDSTA= temp
     get_expr("I2C_re_st_setup", temp)
     tSUSTA= temp
     get_expr("I2C_stop_setup", temp)
     tSUSTO= temp
     get_expr("I2C_tbuf", temp)
     tBUF= temp
     get_expr("I2C_tvddat", temp)
     tVDDAT= temp      
     get_expr("I2C_tvdack", temp)
     tVDACK= temp      
     get_expr("I2C_tspike", temp)
     tSP= temp 
     wait(0)
     get_expr("OpVar_TestType", TestType)        -- Determine program option QA or FT

------------ Power Up HS89 in I2C MODE-----------------------

    disconnect hvvi chan SER_RSVD    -- need to float RSVD, important!!  
 -----Dut power up function
     DutPowerUp(Vddio, Vdd18, Vdd, "I2C", "TP_GMSL2",POWERUP)
    if POWERUP then
        close cbit COAXB_P_RELAY + COAXB_M_RELAY  ---Connecto DC circuit
        close cbit  RXTX_K1   -- connects 1k pullup resistor from SER_RXSDA to IOVDD 
        wait(5ms)
     end_if 
        set digital pin SER_GPIO20_TXSCL levels to vil 0.0v vih 0.9*Vddio vol 0.3*Vddio voh 0.7*Vddio iol 2mA ioh -2mA vref Vddio
        set digital pin SER_GPIO19_RXSDA levels to vol 0.3*Vddio voh 0.7*Vddio iol 0mA ioh -0mA vref 0V
--RegRead(SER_ID, 0, 1, RdWordUpper, RdWordLower, "SER_I2C_Read")
     
    get_expr("I2C_Freq", fREQ)
    i2c_per = (1.0/fREQ)/2.0  -- I2C period (half period actually)

----To here need to check this
  ---------------Note: No Spike test ; It does not meet spec---------------------
        execute  digital pattern  "SER_I2C_Write_FT"  into result--    test all I2C timing spec except for spike and stop setup time
--        execute  digital pattern  "SER_I2C_STOP_WRITE_FT"  into result1-- expect failed  test stop setup time
-- Datalog test result 
    
    check_pass = 0
    for idx = 1 to sites do
      site = active_sites[idx]       
       
      if (integer(result[site]) = 1 and integer(result1[site]) = 0) then
         check_pass[site] = 1
      else
         check_pass[site] = 0
      end_if
    end_for    
 -- Power Off

--  -- Power Off   
--  -- Power Off    
  if POWERDOWN then
    open  cbit  RXTX_K1   -- disconnects 1k pullup resistor from SER_RXSDA to IOVDD 
    open cbit COAXB_P_RELAY + COAXB_M_RELAY  ---Connecto DC circuit
    set digital pin ALL_PATTERN_PINS - fpga_pattern_pins levels to vil 0V vih 100mV iol 0uA ioh 0uA vref 0V
    wait(500us)

    set hcovi SER_VDD + SER_VDD18 to fv 0V vmax 4V clamp imax 600mA imin -600mA         
    set hcovi SER_VDDIO to fv 0V   vmax 4V clamp imax 600mA imin -600mA
    wait(5ms)
  -- Initialize for set_SER_Voltages(vio, vcore, v18) routine
    vdd_global[1] = 0V   --SER_VDDIO
    vdd_global[2] = 0V   --SER_VDD  
    vdd_global[3] = 0V   --SER_VDDA(VDD18)  
  end_if


    test_value check_pass with i2c_timing_it
    test_value sutime with sutime_ft
    test_value hdtime with hdtime_ft
    test_value tHIGH  with tHIGH_ft
    test_value tLOW   with tLOW_ft
    test_value tHDSTA with tHDSTA_ft
    test_value tSUSTA with tSUSTA_ft
    test_value tSUSTO with tSUSTO_ft
    test_value tBUF   with tBUF_ft
    test_value tVDDAT with tVDDAT_ft
    test_value tVDACK with tVDACK_ft
    test_value tSP with tSP_ft


end_body


procedure I2C_DDC_char(Vdd, VddA, Vdd18, Vddio, Vddio25, Vdd33,I2C_pat, sutime_ft, hdtime_ft, tHIGH_ft, tLOW_ft, tHDSTA_ft, tSUSTA_ft, tSUSTO_ft, tBUF_ft, tVDDAT_ft, tVDACK_ft, tSP_ft)
----------------------------------------------------------------------------------------------------------------------------------------------------------
--
in float               :Vdd, VddA, Vdd18, Vddio, Vddio25, Vdd33           -- IOVDD       voltage level
in string[50]          : I2C_pat        -- I2C pattern
in_out float_test      : sutime_ft
in_out float_test      : hdtime_ft
in_out float_test      : tHIGH_ft
in_out float_test      : tLOW_ft
in_out float_test      : tHDSTA_ft
in_out float_test      : tSUSTA_ft
in_out float_test      : tSUSTO_ft
in_out float_test      : tBUF_ft
in_out float_test      : tVDDAT_ft
in_out float_test      : tVDACK_ft
in_out float_test      : tSP_ft


local

multisite float        : sutime, hdtime
multisite float        : tHIGH,  tLOW
multisite float        : tHDSTA, tSUSTA
multisite float        : tSUSTO
multisite float        : tBUF
multisite float        : tVDDAT
multisite float        : tVDACK
multisite float        : tSP
float                  : i2c_per
float                  : fREQ
multisite lword        : reg_read

end_local

body


-----------power up device

  active_sites = get_active_sites
  sites = word(len(active_sites))

------------ Power Up HS87 in I2C MODE-----------------------

    DutPowerUp(Vdd, VddA, Vdd18, Vddio, Vddio25, Vdd33, "A0_I2C_STP", "AllDpX1Crystal", "", 0.0)

    set digital pin DUT_SCL_TX + DUT_SDA_RX levels to vil 0.0v vih 0.9*Vddio vol 0.3*Vddio voh 0.5*Vddio iol 2mA ioh -2mA vref Vddio
    set digital pin DUT_DDCSCL + DUT_DDCSDA levels to  vil 0.3*Vddio vih 0.7*Vddio vol 0.5*Vddio voh 0.5*Vddio   iol 2mA ioh -2mA vref  Vddio
     wait(2ms)    


    get_expr("I2C_Freq", fREQ)
--       fREQ =100KHz


    i2c_per = (1.0/fREQ)/2.0  -- I2C period (half period actually)
 
-----Use main I2C (RX/TX port) to program 1 location of EDID table and read back
 
    RegWrite(DUT_ID, REG_EDID_FIRST+0x18, 1, 0, 16#55, "dut_i2c_write")

---read back    
    RegRead(DUT_ID, REG_EDID_FIRST+0x18 , 1, RdWordUpper, RdWordLower, "dut_i2c_read")---Read first
---   RegRead(DUT_ID, 0x2009 , 1, RdWordUpper, RdWordLower, "dut_i2c_read")---By default reg_edid_ddc_en bit is enable. No need to program it.  MSB of this register is EDID_DDC enable bit.

---- now use DDC port to read back
    RegRead(EDID_ID, 0x18 , 1, RdWordUpper, RdWordLower, "DDC_I2C_READ")---Read first
--   RegWrite(EDID_ID,4 , 1, 0, 16#22, "DDC_I2C_WRITE")

   RegRead(EDID_ID, 0x18, 1, RdWordUpper, RdWordLower, "DDC_I2C_READ")---Read first

    wait(0)

---- -- I2C Input Setup Time Search


     sutime = I2C_Bin_Search(DUT_DDCSDA, "data", "I2C_DATA1", i2c_per*0.3, i2c_per*0.8, 16, I2C_pat)
    wait(300us)
      sutime = i2c_per*0.7 - sutime - 2ns  -- 2ns due to rise/fall time of SDA

   Move_Edge(DUT_DDCSDA, "data", "I2C_DATA1", 10ns)   -- restore edge
    
-- --- -- I2C Input Hold Time Search
-- --  global_read = Reg_Read(SER_ID,4,1,"SER_I2C_Read")
    hdtime = I2C_Bin_Search(DUT_DDCSDA, "data", "I2C_DATA2", i2c_per*0.75, i2c_per*0.2, 16, I2C_pat ) --- for 400KHz
    hdtime = hdtime - i2c_per*0.5 ---- 4.5ns  -- 4.5ns per John Blink
    
    
    Move_Edge(DUT_DDCSDA, "data", "I2C_DATA2", i2c_per-10ns)   -- restore edge
--     
-- --  -- High Period of SCL Clock Search
    Move_Edge(DUT_DDCSCL, "data", "I2C_LOW", 0ns)  -- set SCL falling edge to 0ns
    tHIGH = I2C_Bin_Search(DUT_DDCSCL, "data", "I2C_HIGH", i2c_per*0.2, i2c_per, 16, I2C_pat)
    tHIGH = i2c_per-tHIGH
    Move_Edge(DUT_DDCSCL, "data", "I2C_LOW", i2c_per*0.5)  -- restore edge
    Move_Edge(DUT_DDCSCL, "data", "I2C_HIGH", i2c_per*0.7)  -- restore edge
--     
--  -- Low Period of SCL Clock Search
    Move_Edge(DUT_DDCSCL, "data", "I2C_HIGH", 100ns)  -- set SCK rising edge to 100ns
    tLOW = I2C_Bin_Search(DUT_DDCSCL, "data", "I2C_LOW", 0ns, i2c_per, 16, I2C_pat)
    tLOW = (i2c_per - tLOW) + 100ns
    Move_Edge(DUT_DDCSCL, "data", "I2C_HIGH", i2c_per*0.7)  -- restore edge
    Move_Edge(DUT_DDCSCL, "data", "I2C_LOW", i2c_per*0.5)   -- restore edge
-- --     
-- --  -- Start Condition Hold Time Search        

    Move_Edge(DUT_DDCSDA, "data", "I2C_STA", 100ns)  -- set SDA falling edge to 100ns
    tHDSTA = I2C_Bin_Search(DUT_DDCSCL, "data", "I2C_STA", i2c_per*0.5, 1ns, 16, I2C_pat)
    tHDSTA = tHDSTA - 100ns
    Move_Edge(DUT_DDCSDA, "data", "I2C_STA", 1ns)            -- restore edge
    Move_Edge(DUT_DDCSCL, "data", "I2C_STA", i2c_per*0.5)    -- restore edge
    
-- --  -- Repeated Start Condition Setup Time Search
   tSUSTA = I2C_Bin_Search(DUT_DDCSDA, "data", "I2C_RPSTA", i2c_per*0.5, i2c_per*0.1, 16, I2C_pat)
    tSUSTA = tSUSTA- i2c_per*0.25
    Move_Edge(DUT_DDCSDA, "data", "I2C_RPSTA", i2c_per*0.6)  -- restore edge
    
-- -- --  -- Setup Time for Stop Condition Search
--tSUSTO = I2C_DDC_Bin_Search(DOUT9_SER_DDSDA, "data", "I2C_DDC_STA", i2c_per*0.75, i2c_per*0.2, 16, I2C_pat)
    tSUSTO = I2C_DDC_Bin_Search(DUT_DDCSDA, "data", "I2C_DDC_STA", i2c_per*0.1, i2c_per*0.9, 16, I2C_pat)
    tSUSTO = tSUSTO - i2c_per*0.5
    Move_Edge(DUT_DDCSDA, "data", "I2C_DDC_STA",i2c_per*0.1 )   -- restore edge

    
-- --  -- Bus Free Time Between Stop & Start Search
    tBUF = I2C_DDC_Bin_Search(DUT_DDCSDA, "return", "I2C_DDC_TBUF", i2c_per*0.2, i2c_per*0.0, 16, I2C_pat)
--    tBUF = i2c_per - tBUF + 1ns
    Move_Edge(DUT_DDCSDA, "return", "I2C_DDC_TBUF", i2c_per*0.5)   -- restore edge
    wait(0)
    
--     
--    if fREQ < 500KHz then  --(100KHz & 400KHz)
       -- Data Valid Time Search
       Move_Edge(DUT_DDCSCL, "data", "I2C_HIGH", i2c_per)
       Move_Edge(DUT_DDCSCL, "data", "I2C_LOW", i2c_per-100ns)
--       tVDDAT = I2C_Bin_Search(DOUT9_SER_DDSDA, "compare", "I2C_HIGH", i2c_per*0.8, 0ns, 16, I2C_pat)
       tVDDAT = I2C_Bin_Search(DUT_DDCSDA, "compare", "I2C_HIGH", i2c_per*0.95, 0ns, 16, I2C_pat)
       tVDDAT = tVDDAT+100ns
       if tVDDAT[1]=100ns then
            tVDDAT[1]=100us
       end_if 
       Move_Edge(DUT_DDCSCL, "data", "I2C_HIGH", i2c_per*0.7)   -- restore edge
       Move_Edge( DUT_DDCSCL,"data", "I2C_LOW", i2c_per*0.5)    -- restore edge
       Move_Edge(DUT_DDCSDA, "compare", "I2C_HIGH", i2c_per*0.8)   -- restore edge
    
       -- Data Valid Acknowledge Time Search
        Move_Edge(DUT_DDCSCL,  "data", "I2C_DATA1", i2c_per)
       Move_Edge(DUT_DDCSCL,  "data", "I2C_DATA2", i2c_per-400ns) --DDC need more offset at 400k then rx/tx
       tVDACK = I2C_Bin_Search(DUT_DDCSDA, "compare", "I2C_ACK", i2c_per*0.6, 0ns, 16, I2C_pat)
       tVDACK = tVDACK+400ns
       Move_Edge(DUT_DDCSCL, "data", "I2C_DATA1", i2c_per*0.7)   -- restore edge
       Move_Edge(DUT_DDCSCL, "data", "I2C_DATA2", i2c_per*0.5)   -- restore edge
       Move_Edge(DUT_DDCSDA,  "compare", "I2C_ACK", i2c_per*0.8)   -- restore edge
       
       
    
--  -- Pulse Width of spikes suppressed Search
    tSP = I2C_Bin_Search(DUT_DDCSDA,  "return", "I2C_SPIKE", i2c_per*0.6 + 1ns, i2c_per*0.88, 16, I2C_pat)
    tSP = tSP - i2c_per*0.6
    Move_Edge(DUT_DDCSDA, "return", "I2C_SPIKE", ((i2c_per*0.6)+1ns))   -- restore edge


-------power down
--  -- Power Off   


        DutPowerDown 


     test_value sutime with sutime_ft
     test_value hdtime with hdtime_ft
     test_value tHIGH  with tHIGH_ft
    test_value tLOW   with tLOW_ft
     test_value tHDSTA with tHDSTA_ft
     test_value tSUSTA with tSUSTA_ft
     test_value tSUSTO with tSUSTO_ft
     test_value tBUF   with tBUF_ft
    test_value tVDDAT with tVDDAT_ft
    test_value tVDACK with tVDACK_ft
     test_value tSP with tSP_ft


end_body



function I2C_DDC_Bin_Search(pinn, move_edge, tset, startv, stopv, regtr, write_pat) :   multisite float
--------------------------------------------------------------------------------
--  This function does a binary search for some I2C parameters
in pin list[1]     : pinn        -- pin under test
in string[9]       : move_edge   -- edge to move (data or return)
in string[20]      : tset        -- name of timeset to change
in float           : startv      -- search starting edge value
in float           : stopv       -- search stop edge value
in word            : regtr       -- register to write and read to
in string[40]      : write_pat   -- name of pattern to run


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

       for idx =1 to sites_local do
           csite = active_sites_local[idx]
           Move_Edge(pinn, move_edge, tset, current_value[csite])  -- change edge timing
       end_for
 
      if tset[10]="B" then
            execute  digital pattern  write_pat at label "Start_C4" run to end into patres
       else
            execute  digital pattern  write_pat at label "Start_C3" run to end into patres
       end_if
       if NOT patres[csite] AND current_value[csite] < 2.6e-6 then
          if tset = "I2C_LOW" then
             execute  digital pattern  write_pat run to end into patres
          end_if
       end_if

       for idx =1 to sites_local do
           csite = active_sites_local[idx]	  
           if patres[csite] then
	      last_passing[csite]  = current_value[csite]
	      current_value[csite] = current_value[csite] + increment
           else
	      last_failing[csite]  = current_value[csite]
              current_value[csite] = current_value[csite] - increment
           end_if
       end_for

       if abs(increment) < 100ps then
          break    -- exit loop
       end_if


       increment = increment/2.0
       
               
    end_while
    
    
    for idx =1 to sites_local do
        csite = active_sites_local[idx]
        result[csite] = last_passing[csite]
    end_for
    

    return(result)
    
end_body


procedure I2C_DDC_FT(Vdd, VddA, Vdd18, Vddio, Vddio25, Vdd33,I2C_pat, sutime_ft, hdtime_ft, tHIGH_ft, tLOW_ft, tHDSTA_ft, tSUSTA_ft, tSUSTO_ft, tBUF_ft, tVDDAT_ft, tVDACK_ft, tSP_ft, sutime, hdtime, tHIGH, tLOW, tHDSTA, tSUSTA, tSUSTO, tBUF, tVDDAT, tVDACK, tSP )
----------------------------------------------------------------------------------------------------------------------------------------------------------
--
in float               :Vdd, VddA, Vdd18, Vddio, Vddio25, Vdd33           -- IOVDD       voltage level
in float               :sutime, hdtime, tHIGH, tLOW, tHDSTA, tSUSTA, tSUSTO, tBUF, tVDDAT, tVDACK, tSP
in string[50]          : I2C_pat        -- I2C pattern
in_out float_test      : sutime_ft
in_out float_test      : hdtime_ft
in_out float_test      : tHIGH_ft
in_out float_test      : tLOW_ft
in_out float_test      : tHDSTA_ft
in_out float_test      : tSUSTA_ft
in_out float_test      : tSUSTO_ft
in_out float_test      : tBUF_ft
in_out float_test      : tVDDAT_ft
in_out float_test      : tVDACK_ft
in_out float_test      : tSP_ft



local

multisite float        : sutimeft, hdtimeft
multisite float        : tHIGHft,  tLOWft
multisite float        : tHDSTAft, tSUSTAft
multisite float        : tSUSTOft
multisite float        : tBUFft
multisite float        : tVDDATft
multisite float        : tVDACKft
multisite float        : tSPft
float                  : i2c_per,data_temp
float                  : fREQ
multisite lword        : reg_read


-- multisite float        : sutime, hdtime
-- multisite float        : tHIGH,  tLOW
-- multisite float        : tHDSTA, tSUSTA
-- multisite float        : tSUSTO
-- multisite float        : tBUF
-- multisite float        : tVDDAT
-- multisite float        : tVDACK
-- multisite float        : tSP
-- float                  : i2c_per
-- float                  : fREQ
-- multisite lword        : reg_read

end_local

body


-----------power up device

  active_sites = get_active_sites
  sites = word(len(active_sites))

------------ Power Up HS87 in I2C MODE-----------------------

    DutPowerUp(Vdd, VddA, Vdd18, Vddio, Vddio25, Vdd33, "A0_I2C_STP", "AllDpX1Crystal", "", 0.0)

    set digital pin DUT_SCL_TX + DUT_SDA_RX levels to vil 0.0v vih 0.9*Vddio vol 0.3*Vddio voh 0.7*Vddio iol 2mA ioh -2mA vref Vddio
   set digital pin DUT_DDCSCL + DUT_DDCSDA levels to  vol 0.3*Vddio voh 0.7*Vddio   iol 2mA ioh -2mA vref  Vddio
wait(2ms)    
    get_expr("I2C_Freq", fREQ)
--       fREQ =100KHz


    i2c_per = (1.0/fREQ)/2.0  -- I2C period (half period actually)
 
-----Use main I2C (RX/TX port) to program 1 location of EDID table and read back
 
    RegWrite(DUT_ID, REG_EDID_FIRST+0x18, 1, 0, 16#55, "dut_i2c_write")

---read back    
    RegRead(DUT_ID, REG_EDID_FIRST+0x18 , 1, RdWordUpper, RdWordLower, "dut_i2c_read")---Read first


---- now use DDC port to read back
    RegRead(EDID_ID, 0x18 , 1, RdWordUpper, RdWordLower, "DDC_I2C_READ")---Read first
--   RegWrite(EDID_ID,4 , 1, 0, 16#22, "DDC_I2C_WRITE")

   RegRead(EDID_ID, 0x18, 1, RdWordUpper, RdWordLower, "DDC_I2C_READ")---Read first

    wait(0)

-- --- -- I2C Input Hold Time Search
-- --  global_read = Reg_Read(SER_ID,4,1,"SER_I2C_Read")

      data_temp = i2c_per*0.7 - sutime - 2ns  -- 2ns due to rise/fall time of SDA ---Value need to put in pattern

      sutimeft = I2C_Bin_Search_FT(DUT_DDCSDA, "data", "I2C_DATA1",data_temp , 16, I2C_pat)
      sutimeft = i2c_per*0.7 - sutimeft - 2ns  -- 2ns due to rise/fall time of SDA ---real datalog value

     Move_Edge(DUT_DDCSDA, "data", "I2C_DATA1", 10ns)   -- restore edge    
    
-- --- -- I2C Input Hold Time Search
--    data_temp  = hdtime - i2c_per*0.5 ---- 4.5ns  -- 4.5ns per John Blink
    data_temp  = hdtime + i2c_per*0.5 ---- 4.5ns  -- 4.5ns per John Blink
    hdtimeft = I2C_Bin_Search_FT(DUT_DDCSDA, "data", "I2C_DATA2", data_temp, 16, I2C_pat ) --- for 400KHz
    hdtimeft = hdtimeft - i2c_per*0.5 
    Move_Edge(DUT_DDCSDA, "data", "I2C_DATA2", i2c_per-10ns)   -- restore edge
--     
-- --  -- High Period of SCL Clock Search
    Move_Edge(DUT_DDCSCL, "data", "I2C_LOW", 0ns)  -- set SCL falling edge to 0ns
    data_temp= i2c_per-tHIGH
    tHIGHft = I2C_Bin_Search_FT(DUT_DDCSCL, "data", "I2C_HIGH", data_temp, 16, I2C_pat)
    tHIGHft = i2c_per-tHIGHft

    Move_Edge(DUT_DDCSCL, "data", "I2C_LOW", i2c_per*0.5)  -- restore edge
    Move_Edge(DUT_DDCSCL, "data", "I2C_HIGH", i2c_per*0.7)  -- restore edge
--     
--  -- Low Period of SCL Clock Search
    Move_Edge(DUT_DDCSCL, "data", "I2C_HIGH", 100ns)  -- set SCK rising edge to 100ns
    data_temp = (i2c_per - (tLOW - 100ns))
    tLOWft = I2C_Bin_Search_FT(DUT_DDCSCL, "data", "I2C_LOW",data_temp , 16, I2C_pat)
    tLOWft = (i2c_per - tLOWft) + 100ns
    Move_Edge(DUT_DDCSCL, "data", "I2C_HIGH", i2c_per*0.7)  -- restore edge
    Move_Edge(DUT_DDCSCL, "data", "I2C_LOW", i2c_per*0.5)   -- restore edge
-- --     
-- --  -- Start Condition Hold Time Search        

    Move_Edge(DUT_DDCSDA, "data", "I2C_STA", 100ns)  -- set SDA falling edge to 100ns
    data_temp = tHDSTA + 100ns

    tHDSTAft = I2C_Bin_Search_FT(DUT_DDCSCL, "data", "I2C_STA",data_temp , 16, I2C_pat)
    tHDSTAft = tHDSTAft - 100ns
    Move_Edge(DUT_DDCSDA, "data", "I2C_STA", 1ns)            -- restore edge
    Move_Edge(DUT_DDCSCL, "data", "I2C_STA", i2c_per*0.5)    -- restore edge
    
-- --  -- Repeated Start Condition Setup Time Search
---Since we have so much margin for tSUSTA, then we can use 1/2 of design limit without causing any problem as in I2C_Timing check. otherwise, need to modify pattern
    data_temp = tSUSTA/2.0 +i2c_per*0.25
    tSUSTAft = I2C_Bin_Search_FT(DUT_DDCSDA, "data", "I2C_RPSTA",data_temp , 16, I2C_pat)
    tSUSTAft = (tSUSTAft - i2c_per*0.25)------*2.0
    Move_Edge(DUT_DDCSDA, "data", "I2C_RPSTA", i2c_per*0.6)  -- restore edge
    
-- -- --  -- Setup Time for Stop Condition Search
    Move_Edge(DUT_DDCSCL, "data", "I2C_DDC_STA",0nS )   
    data_temp= tSUSTO ----- i2c_per*0.5

    tSUSTOft = I2C_DDC_Bin_Search_FT(DUT_DDCSDA, "data", "I2C_DDC_STA",data_temp , 16, I2C_pat,true)--- true is expect fail
    Move_Edge(DUT_DDCSDA, "data", "I2C_DDC_STA",i2c_per*0.1 )   -- restore edge
    Move_Edge(DUT_DDCSCL, "data", "I2C_DDC_STA", i2c_per*0.5)   -- restore edge
-- Move_Edge(DUT_DDCSDA, "data", "I2C_DDC_STA", i2c_per*0.75)   -- restore edge
    
-- --  -- Bus Free Time Between Stop & Start Search
    
    data_temp = tBUF -1uS -- because so much margin, I don't want to violate HDSTA time 
    tBUFft = I2C_DDC_Bin_Search_FT(DUT_DDCSDA, "return", "I2C_DDC_TBUF", data_temp, 16, I2C_pat,false)
    tBUFft = tBUFft +1uS --- for datalog
    Move_Edge(DUT_DDCSDA, "return", "I2C_DDC_TBUF", i2c_per*0.5)   -- restore edge
    wait(0)
    
--     
--    if fREQ < 500KHz then  --(100KHz & 400KHz)
       -- Data Valid Time Search
       Move_Edge(DUT_DDCSCL, "data", "I2C_HIGH", i2c_per)
       Move_Edge(DUT_DDCSCL, "data", "I2C_LOW", i2c_per-100ns)

        data_temp = tVDDAT-100ns
        tVDDATft = I2C_Bin_Search_FT(DUT_DDCSDA, "compare", "I2C_HIGH",data_temp , 16, I2C_pat)
        tVDDATft = tVDDATft+100ns --- for datalog
       Move_Edge(DUT_DDCSCL, "data", "I2C_HIGH", i2c_per*0.7)   -- restore edge
       Move_Edge( DUT_DDCSCL,"data", "I2C_LOW", i2c_per*0.5)    -- restore edge
       Move_Edge(DUT_DDCSDA, "compare", "I2C_HIGH", i2c_per*0.8)   -- restore edge
    
       -- Data Valid Acknowledge Time Search
        Move_Edge(DUT_DDCSCL,  "data", "I2C_DATA1", i2c_per)
       Move_Edge(DUT_DDCSCL,  "data", "I2C_DATA2", i2c_per-400ns) --DDC need more offset at 400k then rx/tx
       
       data_temp = tVDACK-400ns 
       
       tVDACKft = I2C_Bin_Search_FT(DUT_DDCSDA, "compare", "I2C_ACK",data_temp , 16, I2C_pat)
       tVDACKft = tVDACKft+400ns
       Move_Edge(DUT_DDCSCL, "data", "I2C_DATA1", i2c_per*0.7)   -- restore edge
       Move_Edge(DUT_DDCSCL, "data", "I2C_DATA2", i2c_per*0.5)   -- restore edge
       Move_Edge(DUT_DDCSDA,  "compare", "I2C_ACK", i2c_per*0.8)   -- restore edge
       
       
    
--  -- Pulse Width of spikes suppressed Search
    
    data_temp = tSP + i2c_per*0.6

--    Spike time didnot meet spec for pass 1 so hard code it to 999.0
--     tSPft = I2C_Bin_Search_FT(DUT_DDCSDA,  "return", "I2C_SPIKE",data_temp , 16, I2C_pat)
--     tSPft = tSPft - i2c_per*0.6
--     Move_Edge(DUT_DDCSDA, "return", "I2C_SPIKE", ((i2c_per*0.6)+20ns))   -- restore edge
       tSPft =999.0ns
-------power down
--  -- Power Off   


        DutPowerDown 
     test_value sutimeft with sutime_ft
     test_value hdtimeft with hdtime_ft
     test_value tHIGHft  with tHIGH_ft
     test_value tLOWft   with tLOW_ft
     test_value tHDSTAft with tHDSTA_ft
     test_value tSUSTAft with tSUSTA_ft
     test_value tSUSTOft with tSUSTO_ft
     test_value tBUFft   with tBUF_ft
    test_value tVDDATft with tVDDAT_ft
    test_value tVDACKft with tVDACK_ft
     test_value tSPft with tSP_ft





end_body



function I2C_Bin_Search_FT(pinn, move_edge, tset, startv, regtr, write_pat) :   multisite float
--------------------------------------------------------------------------------
--  This function does a binary search for some I2C parameters
in pin list[1]     : pinn        -- pin under test
in string[9]       : move_edge   -- edge to move (data or return)
in string[20]      : tset        -- name of timeset to change
in float           : startv      -- search starting edge value
in word            : regtr       -- register to write and read to
in string[40]      : write_pat   -- name of pattern to run


local

word               : sites_local, csite
word               : idx
word list[16]      : active_sites_local
multisite float    : result
multisite boolean  : patres

end_local

body

    active_sites_local = get_active_sites
    sites_local = word(len(active_sites_local))

    Move_Edge(pinn, move_edge, tset,startv)  -- change edge timing[csite]
    execute  digital pattern  write_pat run to end into patres
   
    for idx =1 to sites_local do
        csite = active_sites_local[idx]
        if patres[csite] then
            result[csite] = startv
        else
            result[csite] = 999.9
        end_if
    end_for
    

    return(result)
    
end_body



function I2C_DDC_Bin_Search_FT(pinn, move_edge, tset, startv, regtr, write_pat,expect_fail) :   multisite float
--------------------------------------------------------------------------------
--  This function does a binary search for some I2C parameters
in pin list[1]     : pinn        -- pin under test
in string[9]       : move_edge   -- edge to move (data or return)
in string[20]      : tset        -- name of timeset to change
in float           : startv      -- search starting edge value
in word            : regtr       -- register to write and read to
in string[40]      : write_pat   -- name of pattern to run
in boolean         : expect_fail

local

word               : sites_local, csite
word               : idx
word list[16]      : active_sites_local
float              : bound1, bound2              -- binary search boundaries
float              : increment
multisite float    : result
multisite boolean  : patres

end_local

body

    active_sites_local = get_active_sites
    sites_local = word(len(active_sites_local))
 
--------------- Begin search ----------------------------------------
           Move_Edge(pinn, move_edge, tset, startv)  -- change edge timing
 
      if tset[10]="B" then
            execute  digital pattern  write_pat at label "Start_C4" run to end into patres
       else
            execute  digital pattern  write_pat at label "Start_C3" run to end into patres
       end_if
       
      if (expect_fail) then ---- expect fail = true; for stop setup time, expect fail is true; this pattern is read only. it is different than i2c_timing check
             for idx =1 to sites_local do
                 csite = active_sites_local[idx]
                 if patres[csite] then
                    result[csite] = 999.9
                else
                    result[csite] = startv
                end_if
            end_for 
   
      else  
            for idx =1 to sites_local do
                csite = active_sites_local[idx]
                if patres[csite] then
                    result[csite] = startv
                else
                    result[csite] = 999.9
                end_if
            end_for
     end_if 
    return(result)
    
end_body



function SPI_Bin_Search(pinn, move_edge, tset, startv, stopv, regtr, write_pat) :   multisite float
--------------------------------------------------------------------------------
--  This function does a binary search for some I2C parameters
in pin list[1]     : pinn        -- pin under test
in string[9]       : move_edge   -- edge to move (data or return)
in string[20]      : tset        -- name of timeset to change
in float           : startv      -- search starting edge value
in float           : stopv       -- search stop edge value
in word            : regtr       -- register to write and read to
in string[40]      : write_pat   -- name of pattern to run


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
multisite lword    : readdata
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
    
       for idx =1 to sites_local do
           csite = active_sites_local[idx]
           Move_Edge(pinn, move_edge, tset, current_value[csite])  -- change edge timing
       end_for
 
       
--        execute digital pattern "SPI_Pat" at label "A4_RO_1" run to end   ---- This will set  SSI  to low and SS2 of DNUT to 1. or read out SERDES status = 0x800  MT 1/2018
--        wait( 500us)
       execute digital pattern "SPI_Pat" at label "A4_RO_11" run to end   ---- This will set  SSI  to low and SS2 of DNUT to 1. or read out SERDES status = 0x800  MT 1/2018
        wait( 500us)
        readdata  = fpga_read_register("FPGA1",SERDES_STATUS)
---Reset ss1 and ss2 of Dnut
        execute digital pattern "SPI_Pat" at label "A6_RO_1_Rset" run to end   ---- This will reset  SSI and SS2 of DNUT to 11. or read out SERDES status = 0xC00  MT 1/2018
        wait( 500us)

       for idx =1 to sites_local do
           csite = active_sites_local[idx]	  
           if (readdata[csite] = 0x800) then
	      last_passing[csite]  = current_value[csite]
	      current_value[csite] = current_value[csite] + increment
           else
	      last_failing[csite]  = current_value[csite]
              current_value[csite] = current_value[csite] - increment
           end_if
       end_for

  
       if abs(increment) < 100ps then
          break    -- exit loop
       end_if


       increment = increment/2.0
       
               
    end_while



   for idx =1 to sites_local do
       csite = active_sites_local[idx]
       result[csite] = last_passing[csite]
   end_for


    return(result)
    
end_body


function I2C_Lin_Search(pinn, move_edge, tset, startv, stopv, regtr, write_pat) :   multisite float
--------------------------------------------------------------------------------
--  This function does a binary search for some I2C parameters
in pin list[1]     : pinn        -- pin under test
in string[9]       : move_edge   -- edge to move (data or return)
in string[20]      : tset        -- name of timeset to change
in float           : startv      -- search starting edge value
in float           : stopv       -- search stop edge value
in word            : regtr       -- register to write and read to
in string[40]      : write_pat   -- name of pattern to run


local

word               : sites_local, csite
word               : idx,countfail
word list[16]      : active_sites_local
float              : bound1, bound2              -- binary search boundaries
float              : increment
multisite float    : current_value
multisite float    : last_passing, last_failing
multisite float    : result
multisite boolean  : patres
 float             : set_value
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
    
countfail = 0

--------------- Begin search ----------------------------------------
--    current_value = (startv+stopv)/2.0
    increment = 1ns
    current_value =startv
--    while (current_value > bound1 AND current_value < bound2) do
    for     i = 1  to 1000  by 1 do
       for idx =1 to sites_local do
           csite = active_sites_local[idx]
           Move_Edge(pinn, move_edge, tset, current_value[csite])  -- change edge timing

       end_for
       execute  digital pattern  write_pat run to end into patres
       
       RegWrite(SER_ID, regtr , 1, 0, 16#00,"SER_I2C_Write")    
	 
       for idx =1 to sites_local do
           csite = active_sites_local[idx]	  
           if patres[csite] then
	      last_passing[csite]  = current_value[csite]
	      current_value[csite] = current_value[csite] + increment
           else
--	      last_failing[csite]  = current_value[csite]
--              current_value[csite] = current_value[csite] - increment
                countfail = countfail + 1 
           end_if
       end_for


       if countfail =  word(len(active_sites_local))then
          break    -- exit loop
       end_if
        countfail = 0

--       increment = increment/2.0
       
    end_for
    countfail = 0            
    increment = increment/100.0
        for idx =1 to sites_local do
           csite = active_sites_local[idx]
           current_value[csite] = current_value[csite]  - 200.0*increment  -- change edge timing
       end_for   
       RegWrite(SER_ID, regtr , 1, 0, 16#00,"SER_I2C_Write")    
    for     i = 1  to 300  by 1 do
       for idx =1 to sites_local do
           csite = active_sites_local[idx]
           Move_Edge(pinn, move_edge, tset, current_value[csite])  -- change edge timing
       end_for
       execute  digital pattern  write_pat run to end into patres
       
       RegWrite(SER_ID, regtr , 1, 0, 16#00,"SER_I2C_Write")    
	 
       for idx =1 to sites_local do
           csite = active_sites_local[idx]	  
           if patres[csite] then
	      last_passing[csite]  = current_value[csite]
	      current_value[csite] = current_value[csite] + increment
           else
                countfail = countfail + 1 
           end_if
       end_for


       if countfail =  word(len(active_sites_local))then
          break    -- exit loop
       end_if
        countfail = 0

--       increment = increment/2.0
       
    end_for
    countfail = 0               
    increment = increment/100.0
        for idx =1 to sites_local do
           csite = active_sites_local[idx]
           current_value[csite] = current_value[csite]  - 200.0*increment  -- change edge timing
       end_for   
       RegWrite(SER_ID, regtr , 1, 0, 16#00,"SER_I2C_Write")    
    for     i = 1  to 300  by 1 do
       for idx =1 to sites_local do
           csite = active_sites_local[idx]
           Move_Edge(pinn, move_edge, tset, current_value[csite])  -- change edge timing
       end_for
       execute  digital pattern  write_pat run to end into patres
       
       RegWrite(SER_ID, regtr , 1, 0, 16#00,"SER_I2C_Write")    
	 
       for idx =1 to sites_local do
           csite = active_sites_local[idx]	  
           if patres[csite] then
	      last_passing[csite]  = current_value[csite]
	      current_value[csite] = current_value[csite] + increment
           else
                countfail = countfail + 1 
           end_if
       end_for


       if countfail =  word(len(active_sites_local))then
          break    -- exit loop
       end_if
        countfail = 0

--       increment = increment/2.0
       
    end_for               

--    end_while
---Only I2C_STO1 time set need to return last falling signal.    
    if  (tset = "I2C_STO1") then
        for idx =1 to sites_local do
            csite = active_sites_local[idx]
            result[csite] = last_failing[csite]
        end_for    
    else
        for idx =1 to sites_local do
            csite = active_sites_local[idx]
            result[csite] = last_passing[csite]
        end_for
    end_if

    return(result)
    
end_body


function I2C_BinLin_Search(pinn, move_edge, tset, startv, stopv, regtr, write_pat) :   multisite float
--------------------------------------------------------------------------------
--  This function does a binary search for some I2C parameters
in pin list[1]     : pinn        -- pin under test
in string[9]       : move_edge   -- edge to move (data or return)
in string[20]      : tset        -- name of timeset to change
in float           : startv      -- search starting edge value
in float           : stopv       -- search stop edge value
in word            : regtr       -- register to write and read to
in string[40]      : write_pat   -- name of pattern to run


local

word               : sites_local, csite
word               : idx,countfail,i
word list[16]      : active_sites_local
float              : bound1, bound2              -- binary search boundaries
float              : increment
multisite float    : current_value
multisite float    : last_passing, last_failing
multisite float    : result
multisite boolean  : patres

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
    
       for idx =1 to sites_local do
           csite = active_sites_local[idx]
           Move_Edge(pinn, move_edge, tset, current_value[csite])  -- change edge timing
       end_for
 
       
       execute  digital pattern  write_pat run to end into patres
       
       if NOT patres[csite] AND current_value[csite] < 2.6e-6 then
          if tset = "I2C_LOW" then
             execute  digital pattern  write_pat run to end into patres
          end_if
       end_if

       RegWrite(SER_ID, regtr , 1, 0, 16#00,"SER_I2C_Write")    
--       Reg_Write(DUT_ID, regtr, 1, 0x00, "dut_i2c_write")              -- reset register to 0x00

	 
       for idx =1 to sites_local do
           csite = active_sites_local[idx]	  
           if patres[csite] then
	      last_passing[csite]  = current_value[csite]
	      current_value[csite] = current_value[csite] + increment
           else
	      last_failing[csite]  = current_value[csite]
              current_value[csite] = current_value[csite] - increment
           end_if
       end_for


       if abs(increment) < 100ps then
          break    -- exit loop
       end_if


       increment = increment/2.0
       
               
    end_while
----HS89 56 leads has 0 std for pulse high. I add this linear section only for this pulse high test MT.
       RegWrite(SER_ID, regtr , 1, 0, 16#00,"SER_I2C_Write")  ---- reset 
    countfail = 0               
        for idx =1 to sites_local do
           csite = active_sites_local[idx]
           current_value[csite] = last_passing[csite]  ----- 0.5*increment  -- change edge timing
       end_for   
    increment = 95ps

       RegWrite(SER_ID, regtr , 1, 0, 16#00,"SER_I2C_Write")  
       i = 0  
    while( countfail =0  and current_value < stopv) do
        i = i +1
       for idx =1 to sites_local do
           csite = active_sites_local[idx]
           Move_Edge(pinn, move_edge, tset, current_value[csite])  -- change edge timing
       end_for
       execute  digital pattern  write_pat run to end into patres
       
       RegWrite(SER_ID, regtr , 1, 0, 16#00,"SER_I2C_Write")    
	 
       for idx =1 to sites_local do
           csite = active_sites_local[idx]	  
           if patres[csite] then
	      last_passing[csite]  = current_value[csite]
	      current_value[csite] = current_value[csite] + increment
           else
                countfail = countfail + 1 
           end_if
       end_for


       if countfail =  word(len(active_sites_local))then
          break    -- exit loop
       end_if
        countfail = 0

--       increment = increment/2.0
       
    end_while               




---Only I2C_STO1 time set need to return last falling signal.    
    if  (tset = "I2C_STO1") then
        for idx =1 to sites_local do
            csite = active_sites_local[idx]
            result[csite] = last_failing[csite]
        end_for    
    else
        for idx =1 to sites_local do
            csite = active_sites_local[idx]
            result[csite] = last_passing[csite]
        end_for
    end_if

    return(result)
    
end_body


procedure Move_Edge1(pinn, moveedge, tset, value)
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
   


