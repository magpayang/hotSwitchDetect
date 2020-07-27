use module "./user_globals.mod"
use module "./lib/lib_common.mod"
use module "./SERDES_Pins.mod"
use module "./reg_access.mod"
use module "./general_calls.mod"
use module "./FPGA.mod"
use module "./I2CTIMING_TEST.mod"
use module "./HDCP.mod"
use module "./Audio.mod"
use module "./gen_calls2.mod"
use module "./rlms.mod"
use module "./HS89.tp"
procedure MbistTest(vcore, vio, v18, devid_it, Mbdone , MbPassFail, POWERUP,POWERDOWN)
--------------------------------------------------------------------------------

    in boolean              : POWERUP,POWERDOWN
    in float                : vcore, vio, v18
    in_out integer_test     : Mbdone
    in_out integer_test     : MbPassFail
    in_out integer_test     : devid_it

-- in_out array of float_test : MbistDone
-- in_out array of float_test : MbistPassFail


local

  PIN LIST[1]       : MbFail, MbDone, MbistEn,MbistRst,MB_Sel_0, MB_Sel_1, MB_Sel_2, MB_Sel_3, MB_Sel_4
  PIN LIST[6]       : MbistSel

  multisite lword   : LowerRdWord, UpperRdWord
  word              : logic_setting
  multisite float   : mbist_done_ppmu[1] , mbist_fail_ppmu[1]
  
  multisite float   : mbdone, mbfail 
  multisite integer : MBDONE, MBFAIL
  float             : Vconf0, Vconf1
  multisite lword   : lowword, upperword, des_read0, des_read1, des_read2, reg_val20, reg_val21

  multisite integer : reg_val, reg_val0, reg_val1,ireg_val0
  word              : sites, idx, site
  integer           : idxs

  multisite lword   : hizdel_reg_val, oreg_reg_val
  lword             : data
  multisite float   : mbist_done_dlog[32] , mbist_fail_dlog[32]
  multisite lword   : reg_val_des


  --word    : Cs
  --boolean : FailFlag = false
  --string[80] : DieType, ErrStr
  --string[1] : Response
  --multisite float   : MbistPassFail_datalog_array[64] , MbistDone_datalog_array[64]  
 
 end_local


body
  
  MbistRst  =  SER_GPIO0_MS_LOCK
  MbistEn   =  SER_GPIO1_LFLTB_ERRB
  MbDone    =  SER_GPIO2_GPO_SCLK
  MbFail    =  SER_GPIO3_RCLKOUT
  MbistSel  =  SER_GPIO7_WS + SER_GPIO8_SCK + SER_GPIO9_SD + SER_GPIO10_CNTL0_WSOR_SDA2 + SER_GPIO11_CNTL1_SCKOR_SCL2
  MB_Sel_0  = SER_GPIO7_WS
  MB_Sel_1  = SER_GPIO8_SCK
  MB_Sel_2  = SER_GPIO9_SD
  MB_Sel_3  = SER_GPIO10_CNTL0_WSOR_SDA2
  MB_Sel_4  = SER_GPIO11_CNTL1_SCKOR_SCL2
  mbdone =0.0
  
  mbfail =00.0


    active_sites = get_active_sites
    sites = word(len(active_sites))  

    --POWER_CONNECT    -- need this for reseting device
    
--     -- can take out later but keep for now to make sure all MFP pins connected to DPs
--     open cbit MFP_LT_RELAY   
-- 
-- 
--     --make sure RSVD pin float (HVVI disconnect)
--     disconnect hvvi chan SER_RSVD    -- need to float RSVD, important!!
--     connect digital pin ALL_PATTERN_PINS to dcl
--     disconnect digital pin SER_CAPVDD from dcl                 -- need to float CAP_VDD pin  
--     wait(3ms) 
--         
--     -- reset levels 
--     set digital pin ALL_PATTERN_PINS levels to vil 0V vih 0.2V vol 0V voh 0V iol 0mA ioh 0mA vref 0V
--     set digital pin ALL_PATTERN_PINS modes to driver pattern     -- Do not delete !!! 
--     wait(1ms)
--   
--     execute digital pattern "PowerUp" at label "ALL_ZERO" wait   -- Do not delete in order to reset all pins to vil level !!!
--     wait(1ms)        
--     
-- 
--     --The function below is for setting DUT supplies ONLY, change Voltage if Required  
--     Set_SER_Voltages(vio, vcore, v18)
--     wait (10ms) -- trial for 47uF cap on SER_VDD
--     
--     
--     Vconf0 = 0.11 * vio
--     Vconf1 = 0.16 * vio
--         
--     set digital pin SER_GPO4_CFG0  + SER_GPO6_CFG2 levels to vil Vconf0 vih vio   -- TP/UART mode with DEV_ID = 0x80
--     set digital pin  SER_GPO5_CFG1 levels to vil Vconf1 vih vio                    ---GMSL2 mode 
--  --   set digital pin  SER_GPO5_CFG1 levels to vil Vconf0 vih vio                    ---GMSL1 mode 
--     --set digital pin ALL_PATTERN_PINS modes to comparator enable all fails    
--     wait(1ms)
--  
--         
--   -------- Set PWDN =1 to power up DUT --------
--     execute digital pattern "PowerUp" at label "TP" run to end wait
--     wait(6ms) 
--  --   RegRead(SER_ID, 0x18, 1, upperword, lowword,"SER_UART_Read")
-- --     RegWrite(SER_ID, 0x18, 1, 0xE0, 0xe0, "SER_UART_Write") 
    
 ---Power up   
    DutPowerUp(vio, v18, vcore, "UART", "TP_GMSL2",POWERUP)   

    RegRead(SER_ID, SR_REG0, 1, upperword, lowword,"SER_UART_Read")     -- device ID, to make sure we test the correct device, to comply with check list
    wait(200us)
    
    for idxs = 1 to len(active_sites) do
      site = active_sites[idxs]
      reg_val[site]  = integer(lowword[site])        
    end_for 

    
  ------Setup HS92  to provide PCLK. Some MBIST need PCLK in order to test
  -----Setup commnunication speed for DES
    fpga_set_I2C_Frequency("FPGA1", 1MHz)     -- only need this once, unless want to change freq 
    fpga_set_UART_Frequency("FPGA1", 1MHz)
    wait(0ms)
    
----Power up DNUT
    
    powerup_dnut_vdd_vterm (1.2V,1.2V) ---turn on VDD and VTERM for DNUT

  --fpga_Set_DNUT_Pins("FPGA1", CFG2, CFG1, CFG0, PWDN, latch)
    fpga_Set_DNUT_Pins("FPGA1", 0 ,0, 1, 1, TRUE)  -- UART/TP/GMSL2=1/RATE=0(6 Gig link)               

---Close relay to connect FPGA to control TX/RX on DNUT
    close cbit  DNUT_RXTX_RELAY   ----FPGA to control communication instead of dps
    close digital cbit FB_RELAY ----connect feedback loop. Connect DNUT CSI pins to DUT CSI pins
    wait(1ms)   -----6ms

    reg_val_des  = fpga_UART_Read("FPGA1", "DES", DESA_ID, 0, 1)      -- UART read expect data = 0x90   
    --wait(200us)
    for idxs = 1 to len(active_sites) do
      site = active_sites[idxs]
      ireg_val0[site]  = integer(reg_val_des[site]) 
    end_for 

-----   fpga_UART_Write("FPGA1","DNUT", DESA_ID, 16#0330, 1, 0x84)          -- Force to send out MIPI clocks from DES HS78 0x84; need move to after testmode MT otherwise not work 8/2017
    reg_val_des  = fpga_UART_Read("FPGA1", "DES", DESA_ID, 0x0330, 1)    -- verify   
   fpga_UART_Write("FPGA1","DES",DESA_ID, 0x320 , 1, 0x2F )
   fpga_UART_Write("FPGA1","DES",DESA_ID, 0x323 , 1, 0x2F )

   wait(1ms)    -- needed, to initialize mipi blocks to go out of sleep mode 
   
   RegWrite( SER_ID, 0x330, 1,0x00, 0x86, "SER_UART_Write")
RegRead(SER_ID,0x6 , 1, upperword, lowword,"SER_UART_Read")


  --enter TM D 
  SetTestMode(13, False, "SER_UART_Write")
----Use this for debug test mode MT-------------------------
--   --RegWrite(DevId, RegAddr, ByteCnt, DataUpperWord, DataLowerWord, PatternName)
--   RegWrite(SER_ID, 63, 1, 16#A0, 16#A0, "SER_UART_Write")    -- testkey = ACCA, first four bits for testkey select (63 or 16#3F)
--   --wait(200us)  
--   RegRead(SER_ID, 16#3F, 1, upperword, lowword,"SER_UART_Read")     
--   --wait(200us) 
--   RegWrite(SER_ID, 63, 1, 16#C0, 16#C0, "SER_UART_Write")    -- testkey = ACCA, first four bits for testkey select (63 or 16#3F)
--   --wait(200us)  
--   RegRead(SER_ID, 16#3F, 1, upperword, lowword,"SER_UART_Read")     
--   --wait(200us)  
--   RegWrite(SER_ID, 63, 1, 16#CF, 16#CF, "SER_UART_Write")    -- testkey = ACCA, first four bits for testkey select (63 or 16#3F)
--   --wait(200us)  
--   RegRead(SER_ID, 16#3F, 1, upperword, lowword,"SER_UART_Read")     
--   --wait(200us)  
--   RegWrite(SER_ID, 63, 1, 16#AF, 16#AF, "SER_UART_Write")    -- testkey = ACCA, first four bits for testkey select (63 or 16#3F)
--   --wait(200us)  
--   RegRead(SER_ID, 16#3F, 1, upperword, lowword,"SER_UART_Read")     
--   --wait(200us)  
--   
--   RegWrite(SER_ID, 63, 1, 16#AD, 16#AD, "SER_UART_Write")    -- TM D(13), last four bits for TM select   
--   --wait(200us)  
----------------------------------------------------
  wait(1ms)
  fpga_UART_Write("FPGA1","DES", DESA_ID, 16#0330, 1, 0x84)          -- Force to send out MIPI clocks from DES HS78 0x84 ( Moved from down there)

  -- Initialize DEBUG_MODE=0
  --RegWrite( 16#90 , DUT_HS92_DES_TEST0 , 1 , 0 , 16#00 , "des_i2c_write" , true , false )    -- DEBUG_MODE=0
  RegWrite(SER_ID, 16#3E, 1, 16#00, 16#00, "SER_UART_Write")     -- DEBUG_MODE=0  
  wait(1ms)

  -- Reset the MBIST circuitry and hold enable low.
  set digital pin MbistRst modes to load drive low no loads
  set digital pin MbistEn  modes to load drive low no loads
  wait(1ms)
  set digital pin MbistRst modes to load drive high no loads
  wait(1ms)


  -- Setup DEBUG_MODE (following sequence used in simulation file)  
  RegWrite(SER_ID, 16#3E, 1, 16#01, 16#01, "SER_UART_Write")     -- DEBUG_MODE=1  
  wait(1ms)
  set digital pin  MbistEn modes to load drive high no loads
  wait(1ms)
  RegWrite(SER_ID, 16#3E, 1, 16#03, 16#03, "SER_UART_Write")     -- DEBUG_MODE=3  
  wait(1ms)
  RegWrite(SER_ID, 16#3E, 1, 16#07, 16#07, "SER_UART_Write")     -- DEBUG_MODE=7  
  wait(1ms)
--------- setup to measure Mbdone and Mbfail         
---For HS89 8x8 package, MIPI clock set after testmode otherwise MBIST will be failed.
--  fpga_UART_Write("FPGA1","DNUT", DESA_ID, 16#0330, 1, 0x04)          -- Force to send out MIPI clocks from DES HS78 0x84  
-- (move this line to up)  fpga_UART_Write("FPGA1","DES", DESA_ID, 16#0330, 1, 0x84)          -- Force to send out MIPI clocks from DES HS78 0x84  
  disconnect digital pin  MbDone + MbFail from dcl
  connect digital pin MbDone + MbFail to ppmu
  set digital ppmu  MbDone + MbFail to fi 0.1ua imax 2mA measure v max 4V 
-----
  for logic_setting = 0 to 31 do
      -- MBIST_SEL_0
        if ( logic_setting & 16#1 > 0 ) Then
            set digital pin  MB_Sel_0    fx1 driver static high  -- MBIST_SEL_0
        else
            set digital pin  MB_Sel_0    fx1 driver static low  -- MBIST_SEL_0
        endif
        
        -- MBIST_SEL_1
        if ( logic_setting & 16#2 > 0 ) Then
            set digital pin   MB_Sel_1   fx1 driver static high  -- MBIST_SEL_1
        else
            set digital pin   MB_Sel_1   fx1 driver static low  -- MBIST_SEL_1
        endif
        
        -- MBIST_SEL_2
        if ( logic_setting & 16#4 > 0 ) Then
            set digital pin   MB_Sel_2    fx1 driver static high  -- MBIST_SEL_2
        else
            set digital pin   MB_Sel_2   fx1 driver static low  -- MBIST_SEL_2
        endif
        
        -- MBIST_SEL_3
        if ( logic_setting & 16#8 > 0 ) Then
            set digital pin   MB_Sel_3    fx1 driver static high  -- MBIST_SEL_3
        else
            set digital pin   MB_Sel_3   fx1 driver static low  -- MBIST_SEL_3
        endif
        
        -- MBIST_SEL_4
        if ( logic_setting & 16#10 > 0 ) Then
            set digital pin   MB_Sel_4   fx1 driver static high  -- MBIST_SEL_4
        else
            set digital pin   MB_Sel_4    fx1 driver static low  -- MBIST_SEL_4
        endif
       
--         -- MBIST_SEL_5
--         if ( logic_setting & 16#20 > 0 ) Then
--             set digital pin   DES_GPI10_SDA1   fx1 driver static high  -- MBIST_SEL_5
--         else
--             set digital pin   DES_GPI10_SDA1   fx1 driver static low  -- MBIST_SEL_5
--         endif

        measure digital ppmu MbDone voltage average 5 delay 10us into mbist_done_ppmu
        measure digital ppmu MbFail voltage average 5 delay 10us into mbist_fail_ppmu
        wait(1us)
       
        for idx=1 to sites do
           site = active_sites[idx]
           if mbist_done_ppmu[site] < vcore -0.1 then---3.2V then
              mbdone[site] = mbdone[site] + 2.0^float(logic_setting)
           endif
           if mbist_fail_ppmu[site] >1.0V then
              mbfail[site] = mbfail[site] + 2.0^float(logic_setting)
           endif
 ----           
            mbist_done_dlog[site,logic_setting+1] = mbist_done_ppmu[site,1]
            mbist_fail_dlog[site,logic_setting+1] = mbist_fail_ppmu[site,1]
         endfor
         
       
        -- Save measureed data into datalogging arrays
--         msite_Ar_Of_Fl_Tst_AR ( double ( mbist_done_ppmu ) , MbistDone_datalog_array ,     integer ( logic_setting+1 ) , MbistDone )
--         msite_Ar_Of_Fl_Tst_AR ( double ( mbist_fail_ppmu ) , MbistPassFail_datalog_array , integer ( logic_setting+1 ) , MbistPassFail )

  endfor
  
  for idx=1 to sites do
       site = active_sites[idx]
       if mbdone[site] >0.0   then  -- Need daughtercard to fully test MBIST
           MBDONE[site] = 0
       else
           MBDONE[site] = 1
       endif
       if mbfail[site] >0.0 then 
           MBFAIL[site] = 0
       else
           MBFAIL[site] = 1
       endif
    endfor  
      
   -- turn off MIPI clocks from DES   
--    fpga_UART_Write("FPGA1","DNUT", DESA_ID, 16#0330, 1, 0x04)    -- correct           
--    des_read2  = fpga_UART_Read("FPGA1", "DNUT", DESA_ID, 0x0330, 1)    -- verify  
--    -- control FPGA cbits 2#0000  (cb4, cb3, cb2, cb1), to open FB loop on LB relays    
--    fpga_cbit_control("FPGA1", 2#0000)      

-------------- Power Down ---------------------------

--   powerup_dnut_vdd_vterm (0V,0V) ---turn on VDD and VTERM for DNUT

  --fpga_Set_DNUT_Pins("FPGA1", CFG2, CFG1, CFG0, PWDN, latch)
    fpga_Set_DNUT_Pins("FPGA1", 0 ,0, 0, 0, TRUE)  -- UART/TP/GMSL2=1/RATE=0(6 Gig link)      --- if not turn off CFG tesat    

 RegRead(SER_ID, SR_REG0, 1, upperword, lowword,"SER_UART_Read")     -- device ID, to make sure we test the correct device, to comply with check list

  disconnect digital pin  MbDone + MbFail from ppmu
  connect digital pin MbDone + MbFail to dcl

--   set digital pin ALL_PATTERN_PINS levels to vil 0V vih 200mV iol 0uA ioh 0uA vref 0V
--   set  digital  pin ALL_PATTERN_PINS fx1 driver  preset low       
  set digital pin ALL_PATTERN_PINS modes to driver pattern
  wait(500us)
    open cbit  DNUT_RXTX_RELAY   ----FPGA to control communication instead of dps
    open digital cbit FB_RELAY ----connect feedback loop. Connect DNUT CSI pins to DUT CSI pins  
  
    powerdown_device(POWERDOWN)

-- 
--   set hcovi SER_VDD + SER_VDD18 to fv 0V vmax 4V clamp imax 600mA imin -600mA         
--   set hcovi SER_VDDIO to fv 0V   vmax 4V clamp imax 600mA imin -600mA
--   
--  	  
--   wait(10ms)     -- extra for 47uF cap on SER_VDD        
-- 
--   -- Initialize for set_SER_Voltages(vio, vcore, v18) routine
--   vdd_global[1] = 0V   --SER_VDDIO
--   vdd_global[2] = 0V   --SER_VDD  
--   vdd_global[3] = 0V   --SER_VDDA(VDD18)


    
   -- Datalog
--     test_value MbistDone_datalog_array with MbistDone
--     test_value MbistPassFail_datalog_array with MbistPassFail

    test_value reg_val with devid_it 
    test_value MBDONE  with Mbdone
    test_value MBFAIL  with MbPassFail

 
 end_body



procedure Scan_Test(vcore, vio, v18, vscan_core, devid_it, safNoncpresschain,saftop0,saftop1,sbftop0,sbftop1,sbftop2, tdftop0,tdftop1,tdftop2,tdftop3,tdftop4,tdftop5,tdftop6,tdftop7,tdftop8,tdftop9,tdftop10,tdftop11,tdftop12,tdftop13,tdflowfreq,hld_t_compr_top,pd_compr_top,POWERUP,POWERDOWN)
--------------------------------------------------------------------------------
--  
in float                :   vcore, vio, v18, vscan_core
in_out integer_test     :   devid_it
--in_out boolean_test     :   safNonecpresschain,saftop0,saftop1,sbftop0,sbftop1,sbftop2
in_out boolean_test     :   safNoncpresschain,saftop0,saftop1,sbftop0,sbftop1,sbftop2

in_out boolean_test     :    tdftop0,tdftop1,tdftop2,tdftop3,tdftop4,tdftop5,tdftop6,tdftop7,tdftop8
in_out boolean_test     :   tdftop9,tdftop10,tdftop11,tdftop12,tdftop13,tdflowfreq
in_out boolean_test     :   hld_t_compr_top, pd_compr_top
in boolean              : POWERUP,POWERDOWN

-- in_out boolean_test     : scan1_bt
-- in_out boolean_test     : scan2_bt
-- in_out boolean_test     : scan3_bt
-- in_out boolean_test     : scan4_bt
-- in_out boolean_test     : scan5_bt
-- in_out boolean_test     : scan6_bt
-- in_out boolean_test     : scan7_bt
-- in_out boolean_test     : scan8_bt


local
    word list[16]       :  active_sites
    word                :  sites, idx, site

    multisite word      :  reg_read
    multisite lword     :  lowword, upperword, cap_fails[200],cap_data[200], cap_cycles, scan_count
    
    float               :  Vconf0, Vconf1
    integer             :  idxs    
    multisite integer   : reg_val, reg_val0, reg_val1 
    float               :  time_meas
end_local

body

    get_expr("TestProgData.Device", DEVICE)  

    active_sites = get_active_sites
    sites = word(len(active_sites))  

    --POWER_CONNECT    -- need this for reseting device
    
    -- can take out later but keep for now to make sure all MFP pins connected to DPs
      open cbit MFP_LT_RELAY  

    --make sure RSVD pin float (HVVI disconnect)
    disconnect hvvi chan SER_RSVD    -- need to float RSVD, important!!
--     connect digital pin ALL_PATTERN_PINS to dcl
--     disconnect digital pin SER_CAPVDD from dcl                 -- need to float CAP_VDD pin  
--     wait(3ms) 
--         
--     -- reset levels 
--     set digital pin ALL_PATTERN_PINS levels to vil 0V vih 0.2V vol 0V voh 0V iol 0mA ioh 0mA vref 0V
--     set digital pin ALL_PATTERN_PINS modes to driver pattern     -- Do not delete !!! 
--     wait(1ms)
--   
--     execute digital pattern "PowerUp" at label "ALL_ZERO" wait   -- Do not delete in order to reset all pins to vil level !!!
--     wait(1ms)        
--     
-- 
--     --The function below is for setting DUT supplies ONLY, change Voltage if Required  
--     Set_SER_Voltages(vio, vcore, v18)
--     wait (10ms) -- trial for 47uF cap on SER_VDD
--         
--     Vconf0 = 0.11 * vio   -- UART    
--     Vconf1 = 0.16 * vio
--     set digital pin SER_GPO4_CFG0  + SER_GPO6_CFG2 levels to vil Vconf0 vih vio   -- TP/UART mode with DEV_ID = 0x80
--     set digital pin  SER_GPO5_CFG1 levels to vil Vconf1 vih vio                    ---GMSL2 mode         
-- 
--     wait(1ms)
--     
--         
--   -------- Set PWDN =1 to power up device --------
--     execute digital pattern "PowerUp" at label "TP" run to end wait
--     wait(6ms) 
--     
    DutPowerUp(vio, v18, vcore, "UART", "TP_GMSL2",POWERUP)
    RegRead(SER_ID, 16#00, 1, upperword, lowword,"SER_UART_Read")     -- device ID, to make sure we test the correct device, to comply with check list
    wait(500us)   --- used to be 200uS

    for idxs = 1 to len(active_sites) do
      site = active_sites[idxs]
      reg_val[site]  = integer(lowword[site])        
    end_for 
    
    test_value reg_val with devid_it    
    

   
    
------------ Enter TestMode 3 for SCAN test -----------------
  SetTestMode(3, False, "SER_UART_Write")
-----This section is for debug   MT ----------
   --RegWrite(DevId, RegAddr, ByteCnt, DataUpperWord, DataLowerWord, PatternName)
--   RegWrite(SER_ID, 63, 1, 16#A0, 16#A0, "SER_UART_Write")    -- testkey = ACCA, first four bits for testkey select (63 or 16#3F)
--   wait(200us)  
--   RegRead(SER_ID, 16#3F, 1, upperword, lowword,"SER_UART_Read")     
--   wait(200us) 
--   RegWrite(SER_ID, 63, 1, 16#C0, 16#C0, "SER_UART_Write")    -- testkey = ACCA, first four bits for testkey select (63 or 16#3F)
--   wait(200us)  
--   RegRead(SER_ID, 16#3F, 1, upperword, lowword,"SER_UART_Read")     
--   wait(200us)  
--   RegWrite(SER_ID, 63, 1, 16#CF, 16#CF, "SER_UART_Write")    -- testkey = ACCA, first four bits for testkey select (63 or 16#3F)
--   wait(200us)  
--   RegRead(SER_ID, 16#3F, 1, upperword, lowword,"SER_UART_Read")     
--   wait(200us)  
--   RegWrite(SER_ID, 63, 1, 16#AF, 16#AF, "SER_UART_Write")    -- testkey = ACCA, first four bits for testkey select (63 or 16#3F)
--   wait(200us)  
--   RegRead(SER_ID, 16#3F, 1, upperword, lowword,"SER_UART_Read")     
--   wait(200us)  
--   
--   RegWrite(SER_ID, 63, 1, 16#A3, 16#A3, "SER_UART_Write")    -- TM 3 for Scan, last four bits for TM select   
--   wait(200us)  
  --RegRead(SER_ID, 16#3F, 1, upperword, lowword,"SER_UART_Read")   -- in TM3, cannot read back anymore    
  --wait(200us)  
---------------------------------------------------------------------    
 
--DE request that SER_VDD to <= 1.05V for Scan tests to turn off internal regulator here !!!!!! 

  set hcovi SER_VDD to fv vscan_core    vmax 2V clamp imax 600mA imin -600mA
  vdd_global[2] = vscan_core 
  wait(1ms)   -- trial for 47uF cap on SER_VDD
  

  -- OPEN DRAIN PINS NEED PULL UP
  -- (SER_CONF0_MFP1+SER_CONF1_MFP2) = SCAN_OUTPUTS 

  set digital pin SER_GPO4_CFG0 + SER_GPO5_CFG1 levels to vil 0V vih vio vol ((vio/2.0)-0.1V) voh ((vio/2.0)+0.1V) iol 2mA ioh -2mA vref vio    
  set digital pin SER_GPO4_CFG0 + SER_GPO5_CFG1 modes to comparator enable all fails
  wait(500us)
  wait(3ms)

start_timer()
------Execute scan patterns:   
----Saf 
    execute digital pattern "hs89_saf_nocompression_rst_top_up" run to end wait with  safNoncpresschain  -- required pre-run 
    execute digital pattern "hs89_saf_comp_t56_persist_top_up_0" run to end wait with saftop0
wait(3ms)
    execute digital pattern "hs89_saf_comp_t56_persist_top_up_1" run to end wait with  saftop1  -- required pre-run 

    execute digital pattern "hs89_sbf_comp_t56_persist_top_up_0" run to end wait with sbftop0
    execute digital pattern "hs89_sbf_comp_t56_persist_top_up_1" run to end wait with sbftop1
     execute digital pattern "hs89_sbf_comp_t56_persist_top_up_2" run to end wait with sbftop2


----Tdf
    execute digital pattern "hs89_tdf_comp_t56_tmax1_0" run to end wait with  tdftop0
    execute digital pattern "hs89_tdf_comp_t56_tmax1_1" run to end wait with  tdftop1
    execute digital pattern "hs89_tdf_comp_t56_tmax1_2" run to end wait with  tdftop2
    execute digital pattern "hs89_tdf_comp_t56_tmax1_3" run to end wait with  tdftop3  
    execute digital pattern "hs89_tdf_comp_t56_tmax1_4" run to end wait with  tdftop4
    execute digital pattern "hs89_tdf_comp_t56_tmax1_5" run to end wait with  tdftop5
    execute digital pattern "hs89_tdf_comp_t56_tmax1_6" run to end wait with  tdftop6
    execute digital pattern "hs89_tdf_comp_t56_tmax1_7" run to end wait with  tdftop7  
    execute digital pattern "hs89_tdf_comp_t56_tmax1_8" run to end wait with  tdftop8
    execute digital pattern "hs89_tdf_comp_t56_tmax1_9" run to end wait with  tdftop9
    execute digital pattern "hs89_tdf_comp_t56_tmax1_10" run to end wait with  tdftop10
    execute digital pattern "hs89_tdf_comp_t56_tmax1_11" run to end wait with  tdftop11
    execute digital pattern "hs89_tdf_comp_t56_tmax1_12" run to end wait with  tdftop12
    execute digital pattern "hs89_tdf_comp_t56_tmax1_13" run to end wait with  tdftop13
    execute digital pattern "hs89_tdf_low_freq_compression" run to end wait with  tdflowfreq
    
    execute digital pattern "hs89_hold_time_compression_top" run to end wait with  hld_t_compr_top
    execute digital pattern "hs89_pd_compression_top" run to end wait with  pd_compr_top

--    execute digital pattern "hs89_saf_compression_top_clksel1_3001_6000" run to end wait with saftop3001         
--    execute digital pattern "hs89_saf_compression_top_clksel1_6001_9000" run to end wait with saftop6001  
--    execute digital pattern "hs89_saf_compression_top_clksel1_9001_12000" run to end wait with saftop9001  
--    execute digital pattern "hs89_saf_compression_top_clksel1_12001_15000" run to end wait with saftop12001  
--    execute digital pattern "hs89_saf_compression_top_clksel1_15001_18000" run to end wait with saftop15001  
--    execute digital pattern "hs89_saf_compression_top_clksel1_18001_21000" run to end wait with saftop18001  
--    execute digital pattern "hs89_saf_compression_top_clksel1_21001_24000" run to end wait with saftop21001    
--    execute digital pattern "hs89_saf_compression_top_clksel1_24001_27546" run to end wait with saftop24001
-- ----tdf
--    execute digital pattern "hs89_tdf_compression_chain" run to end wait with  tdfcpresschain
--    execute digital pattern "hs89_tdf_compression_top_0_3000" run to end wait with  tdftop0
--    execute digital pattern "hs89_tdf_compression_top_3001_6000" run to end wait with  tdftop3001
--    execute digital pattern "hs89_tdf_compression_top_6001_9000" run to end wait with  tdftop6001
--    execute digital pattern "hs89_tdf_compression_top_9001_12000" run to end wait with  tdftop9001  
--    execute digital pattern "hs89_tdf_compression_top_12001_15000" run to end wait with  tdftop12001
--    execute digital pattern "hs89_tdf_compression_top_15001_18000" run to end wait with  tdftop15001
--    execute digital pattern "hs89_tdf_compression_top_18001_21000" run to end wait with  tdftop18001
--    execute digital pattern "hs89_tdf_compression_top_21001_24000" run to end wait with  tdftop21001
--    execute digital pattern "hs89_tdf_compression_top_24001_27000" run to end wait with  tdftop24001
--    execute digital pattern "hs89_tdf_compression_top_27001_30000" run to end wait with  tdftop27001
--    execute digital pattern "hs89_tdf_compression_top_30001_33000" run to end wait with  tdftop30001
--    execute digital pattern "hs89_tdf_compression_top_33000_36000" run to end wait with  tdftop33001
--    execute digital pattern "hs89_tdf_compression_top_36001_39000" run to end wait with  tdftop36001
--    execute digital pattern "hs89_tdf_compression_top_39001_42000" run to end wait with  tdftop39001
--    execute digital pattern "hs89_tdf_compression_top_42001_45000" run to end wait with  tdftop42001
--    execute digital pattern "hs89_tdf_compression_top_45001_48000" run to end wait with  tdftop45001
--    execute digital pattern "hs89_tdf_compression_top_48001_51000" run to end wait with  tdftop48001
--    execute digital pattern "hs89_tdf_compression_top_51001_54000" run to end wait with  tdftop51001
--    execute digital pattern "hs89_tdf_compression_top_54001_57000" run to end wait with  tdftop54001
--    execute digital pattern "hs89_tdf_compression_top_57001_60116" run to end wait with  tdftop57001

-- 
--    execute digital pattern "hs89_tdf_compression_top_12001_15000" run to end wait with  tdftop12001
--    execute digital pattern "hs89_tdf_compression_top_15001_18000" run to end wait with  tdftop15001
--    execute digital pattern "hs89_tdf_compression_top_18001_21000" run to end wait with  tdftop18001
--    execute digital pattern "hs89_tdf_compression_top_21001_24000" run to end wait with  tdftop21001
--    execute digital pattern "hs89_tdf_compression_top_24001_27000" run to end wait with  tdftop24001
--    execute digital pattern "hs89_tdf_compression_top_27001_30000" run to end wait with  tdftop27001   
--    execute digital pattern "hs89_tdf_compression_top_30001_33000" run to end wait with  tdftop30001    
--    execute digital pattern "hs89_tdf_compression_top_33001_36000" run to end wait with  tdftop33001   
--    execute digital pattern "hs89_tdf_compression_top_36001_39000" run to end wait with  tdftop36001      
--    execute digital pattern "hs89_tdf_compression_top_39001_42000" run to end wait with  tdftop39001      
--    execute digital pattern "hs89_tdf_compression_top_42001_45000" run to end wait with  tdftop42001        
--    execute digital pattern "hs89_tdf_compression_top_45001_48000" run to end wait with  tdftop45001   
--    execute digital pattern "hs89_tdf_compression_top_48001_50056" run to end wait with  tdftop48001      
--    
   time_meas =stop_timer()
   wait(0us)


------ Power Off ----
  set digital pin ALL_PATTERN_PINS levels to vil 0V vih 200mV iol 0uA ioh 0uA vref 0V
  wait(100us)
  
  set digital pin ALL_PATTERN_PINS modes to comparator enable all fails
  set hcovi SER_VDD+SER_VDDIO +SER_VDD18 to fv 0V vmax 4V clamp imax 600mA imin -600mA   

  wait(3ms) 
  wait(3ms)     -- extra for 47uF cap on SER_VDD    
  -- Initialize for set_SER_Voltages(vio, vcore, v18) routine
  vdd_global[1] = 0V   --SER_VDDIO
  vdd_global[2] = 0V   --SER_VDD  
  vdd_global[3] = 0V   --SER_VDDA(VDD18)




end_body


procedure TmonTest(Vdd, Vddio, Vdd18, devid_it,POWERUP, vstart,vstop,vstep, Tmon_abus0,Tmon_abus1,DeltaTmon,Td_abus3,Td_abus1,DeltaTd,THRESHOLD_125,THRESHOLD_130,THRESHOLD_135,THRESHOLD_140,Tdiode,Tmon2,TempTripH,TempTripLow,TripHyst,ThrhldGnG,fpga_fwrev_reg_test)
--------------------------------------------------------------------------------
in float                    : Vddio, Vdd18, Vdd ---- vcore, vio, v18
in_out float_test           : Tmon_abus0,Tmon_abus1,DeltaTmon,Td_abus3,Td_abus1,DeltaTd,Tdiode,Tmon2
in float                    : vstart,vstop,vstep
in_out array of float_test   : THRESHOLD_125,THRESHOLD_130,THRESHOLD_135,THRESHOLD_140
in boolean                  : POWERUP
in_out integer_test         : devid_it,ThrhldGnG
in_out integer_test         : fpga_fwrev_reg_test

in_out array of float_test  : TempTripH,TempTripLow,TripHyst
local

  multisite lword   : LowerRdWord, UpperRdWord

  multisite float   : mbist_done_ppmu[1] , mbist_fail_ppmu[1]

  float             : Vconf0, Vconf1,temp
  multisite lword   : lowword, upperword,lowword1--, des_read0, des_read1, des_read2, reg_val20, reg_val21

  multisite integer : reg_val, reg_val0, reg_val1 , fpga_fwrev_check
  word              : sites, idx, site,i
  integer           : idxs

  multisite lword   : hizdel_reg_val, oreg_reg_val

  multisite float   : TMON_BUS0, TMON_BUS1,DELTA_TMON, TD_BUS1, TD_BUS3,DELTA_TD,DELTA_TMON_1,Temp_Tmon1,Temp_Tmon2,Temp_Tdiode

  multisite float   :  Vthreshold_140[2],Vthreshold_135[2],Vthreshold_130[2],Vthreshold_125[2], temptriphigh[4], temptriplow[4],TmonTripHyst[4]
    boolean           : CHAR
  float             : Thrhold_125_max,  Thrhold_130_max,  Thrhold_135_max,  Thrhold_140_max
  float             : Thrhold_125_min,  Thrhold_130_min,  Thrhold_135_min,  Thrhold_140_min
  multisite integer   :GoNGo_pass
  multisite lword   : fpga_fwrev_reg_val

end_local


body
---Get threshold value from spec for go no go test mt 2/2019   from lg limit, Umut set all min has same value 
     get_expr("TN43010009.Max",Thrhold_125_max )
     get_expr("TN43010009.Min",Thrhold_125_min )

     get_expr("TN43010011.Max",Thrhold_130_max )

     get_expr("TN43010013.Max",Thrhold_135_max )

     get_expr("TN43010015.Max",Thrhold_140_max )

    GoNGo_pass = 0
    active_sites = get_active_sites
    sites = word(len(active_sites))  
    get_expr("OpVar_Char", CHAR)
----Delete this after deglitch. use this to check MIPI glitch to 1.35V max
--   connect hvvi chan SER_XRES remote
--   set hvvi chan  SER_XRES to fv 1.7 max r5v  ----2/2019

-----

    --POWER_CONNECT    -- need this for reseting device
    
     --make sure RSVD pin float (HVVI disconnect)
    disconnect hvvi chan SER_RSVD    -- need to float RSVD, important!!
    connect digital pin ALL_PATTERN_PINS to dcl
    disconnect digital pin SER_CAPVDD from dcl                 -- need to float CAP_VDD pin  
    wait(3ms) 
        

-----Dut power up function
   DutPowerUp(Vddio, Vdd18, Vdd, "UART", "TP_GMSL2",POWERUP)

----Added by MT  because when close relay for uart communication then no longer connect ABUSes to MFPs-- need hardware mod
    fpga_set_I2C_Frequency("FPGA1", 1MHz)     -- only need this once, unless want to change freq 
    fpga_set_UART_Frequency("FPGA1", 1MHz)
---Close relay to connect FPGA to control TX/RX on DNUT
    close cbit  DNUT_RXTX_RELAY+ RXTX_K1
    wait(0ms)

-- --------powerup_dnut_vdd_vterm(VDD_SET, VTERM_SET)
     powerup_dnut_vdd_vterm(1.2,1.2)    
-----To here
   fpga_Set_DNUT_Pins("FPGA1", 0,0, 1, 1, TRUE)  -- UART/TP/GMSL2=1/RATE=0(6 Gig link)               
    wait(6ms)


--   -------- Set PWDN =1 to power up DUT --------
--     execute digital pattern "PowerUp" at label "TP" run to end wait
--     wait(6ms) 
     
    RegRead(SER_ID, SR_REG0, 1, upperword, lowword,"SER_UART_Read")     -- device ID, to make sure we test the correct device, to comply with check list
    wait(200us)
--    upperword= fpga_UART_Read("FPGA1", "DES", SER_ID, 0, 1)      -- UART read 
--     upperword= fpga_UART_Read("FPGA1", "DES", SER_ID, 0, 1)      -- UART read 
 
    hizdel_reg_val = fpga_read_register("FPGA1", HIZDEL_REG)       -- should read back decimal 6000 if FPGA working OK
    wait(0ms)
    
    fpga_fwrev_reg_val = fpga_read_register("FPGA1", FWREV_REG)    -- this checks FPGA firmware version
    wait(0ms)
    
    for idxs = 1 to len(active_sites) do
      
      site = active_sites[idxs]
      reg_val[site]  = integer(lowword[site]) 
      fpga_fwrev_check[site]  = integer(fpga_fwrev_reg_val[site])   -- fpga firmware check integer     
    
    end_for

    for idxs = 1 to len(active_sites) do
      site = active_sites[idxs]
      reg_val[site]  = integer(lowword[site])        
    end_for 


  --------done with latching, set up CFG0/1/2 to meas 
--   disconnect digital pin  SER_GPO4_CFG0 + SER_GPO5_CFG1 + SER_GPO6_CFG2  + SER_GPIO3_RCLKOUT from dcl
--   connect digital pin SER_GPO4_CFG0 + SER_GPO5_CFG1 + SER_GPO6_CFG2 to ppmu
--   connect digital ppmu SER_GPO4_CFG0 + SER_GPO5_CFG1 + SER_GPO6_CFG2 to fi 10nA imax 20uA measure v max 3.5V
--   disconnect digital pin  SER_GPO4_CFG0 + SER_GPO5_CFG1 + SER_GPO6_CFG2  + SER_GPIO3_RCLKOUT from ppmu




----------------TMON TEST--------------------------
----- 1. Put part in test mode 11
------2. Select ABUS Power Page, page address = 1111( REG TEST0 = 0x0F)
----- 3. Observe differential voltage between ABUS0 and ABUS1, it varies positively with temperature
------4. Tmon: Temp(C) = 313.1* Tmon - 229.1   -------- Change it to HS87 slope MT 2/2019
------5. Force 100uA into ABUS2
------6. Measure differential voltage between ABUS3 and ABUS1, it varies negatively with temperature

----------------------------------------------------------------------------------------------------

  --enter TM D 

  SetTestMode(11, False, "SER_UART_Write")-----for ABUS
 
  RegRead(SER_ID, SR_REG0, 1, upperword, lowword,"SER_UART_Read")    
  RegWrite(SER_ID, 16#3E, 1, 0x00, 16#0F, "SER_UART_Write")     -- ABUS Power Page 
    
--  RegRead(SER_ID, 16#3E, 1, upperword, lowword,"SER_UART_Read")


---- close relay to connect ABUS0 and ABUS1 to VI16 and to DUT
    close digital cbit    ABUS_RELAY+  MFP_LT_RELAY + RXTX_K1
--wait(5ms) 
    connect vi16 chan  SER_ABUS0 + SER_ABUS1+ SER_ABUS2+ SER_ABUS3 remote
    set vi16 chan SER_ABUS0  + SER_ABUS1 +  SER_ABUS2+ SER_ABUS3 to fi 0.01ua  measure V max 2v clamp vmax 2v vmin -0.1v  

   wait(5ms) ----1 might be ok

----Measure Tmons voltage at ABUS0 and ABUS1
    measure vi16 v on chan  SER_ABUS0 for 20 samples every 10us averaged into TMON_BUS0
    measure vi16 v on chan  SER_ABUS1 for 20 samples every 10us averaged into TMON_BUS1

    DELTA_TMON = TMON_BUS0 - TMON_BUS1   
--    Temp_Tmon1 =  313.1*DELTA_TMON - 229.1
    Temp_Tmon2 =  ( DELTA_TMON - 0.7484586)/0.00311146 + 3.5  ----3.5 is  offset from mt board a
--    Temp_Tmon2 = -1.0* (    DELTA_TMON - 1.5291)/0.032


----Measure TDIODE

    set vi16 chan SER_ABUS2 to fi 100ua max 500uA measure V max 2v clamp vmax 2v vmin -0.1v    ----need scope here. It takes to long for settling 
    wait(10ms) ----1 might be ok
    measure vi16 v on chan  SER_ABUS3 for 20 samples every 10us averaged into TD_BUS3
    measure vi16 v on chan  SER_ABUS1 for 20 samples every 10us averaged into TD_BUS1

    DELTA_TD = TD_BUS3 - TD_BUS1    

    Temp_Tdiode  = (DELTA_TD   - 1.583631)/-0.00335456   -- from Bill H hs87. check with thermal meter it correlates well to 0.3deg at room MT 10/2018
    set vi16 chan SER_ABUS2 to fi 0ua  measure V max 2v clamp vmax 2v vmin -0.1v  
    wait(1ms)
---Check overtemp
-- -----for some reason it needs 40ms for fpga to read correctly for now only site 2
--     for i = 1 to 100 do
--         upperword= fpga_UART_Read("FPGA1", "DES", SER_ID,0x0 , 1)      -- UART read 
--         if upperword[2] = 0x80 then
--             break
--         else
--             wait(1ms)
--         end_if
--     end_for

---For now I only do this for char. Later on I might to do produciton test MT 2/2019
    if CHAR then
----Search trip points
        fpga_UART_Write("FPGA1","DES", SER_ID, 0x0306, 1, 0x00)     --- set trip temp = 125
        wait(1ms)
    
        Vthreshold_125 =find_Tmon_threshold (vstart,vstop,vstep)
----Set temperature trip to 130
        fpga_UART_Write("FPGA1","DES", SER_ID, 0x0306, 1, 0x40)     --- set trip temp = 130
        Vthreshold_130 =find_Tmon_threshold (vstart,vstop,vstep)

----Set temperature trip to 135
        fpga_UART_Write("FPGA1","DES", SER_ID, 0x0306, 1, 0x80)     --- set trip temp = 135
        Vthreshold_135 =find_Tmon_threshold (vstart,vstop,vstep)

----Set temperature trip to 140
        fpga_UART_Write("FPGA1","DES", SER_ID, 0x0306, 1, 0xc0)     --- set trip temp = 135
        Vthreshold_140 =find_Tmon_threshold (vstart,vstop,vstep)
        wait(0)

---per Eric to calculate trip temperature 
        for idx = 1 to sites do
            site = active_sites[idx]
--              temptriphigh[site,1] =  313.1*Vthreshold_125[site,1] - 229.1            -----125
--              temptriplow[site,1] =  313.1*Vthreshold_125[site,2] - 229.1
--              temptriphigh[site,2] =  313.1*Vthreshold_130[site,1] - 229.1            -----130
--              temptriplow[site,2] =  313.1*Vthreshold_130[site,2] - 229.1
--              temptriphigh[site,3] =  313.1*Vthreshold_135[site,1] - 229.1            -----135
--              temptriplow[site,3] =  313.1*Vthreshold_135[site,2] - 229.1
--              temptriphigh[site,4] =  313.1*Vthreshold_140[site,1] - 229.1            -----135
--              temptriplow[site,4] =  313.1*Vthreshold_140[site,2] - 229.1
--              TmonTripHyst[site,1]  = Vthreshold_125[site,1] -Vthreshold_125[site,2]
--              TmonTripHyst[site,2]  = Vthreshold_130[site,1] -Vthreshold_130[site,2]
--              TmonTripHyst[site,3]  = Vthreshold_135[site,1] -Vthreshold_135[site,2]
--              TmonTripHyst[site,4]  = Vthreshold_140[site,1] -Vthreshold_140[site,2]        

                temptriphigh[site,1] =  ( Vthreshold_125[site,1] - 0.7484586)/0.00311146 + 3.5    --  313.1*Vthreshold_125[site,1] - 229.1            -----125
                temptriplow[site,1] =  (Vthreshold_125[site,2] - 0.7484586)/0.00311146 + 3.5
                temptriphigh[site,2] =  (Vthreshold_130[site,1] - 0.7484586)/0.00311146 + 3.5            -----130
                temptriplow[site,2] =  (Vthreshold_130[site,2] - 0.7484586)/0.00311146 + 3.5
                temptriphigh[site,3] =  (Vthreshold_135[site,1] - 0.7484586)/0.00311146 + 3.5           -----135
                temptriplow[site,3] =  (Vthreshold_135[site,2] - 0.7484586)/0.00311146 + 3.5
                temptriphigh[site,4] =  (Vthreshold_140[site,1]  - 0.7484586)/0.00311146 + 3.5          -----135
                temptriplow[site,4] =  (Vthreshold_140[site,2] - 0.7484586)/0.00311146 + 3.5
                TmonTripHyst[site,1]  = Vthreshold_125[site,1] -Vthreshold_125[site,2]
                TmonTripHyst[site,2]  = Vthreshold_130[site,1] -Vthreshold_130[site,2]
                TmonTripHyst[site,3]  = Vthreshold_135[site,1] -Vthreshold_135[site,2]
                TmonTripHyst[site,4]  = Vthreshold_140[site,1] -Vthreshold_140[site,2]        

            end_for
    else
    ----Search trip points
--        fpga_UART_Write("FPGA1","DES", SER_ID, 0x0306, 1, 0x00)     --- set trip temp = 125
        RegWrite(SER_ID, 0x306, 1, 0x00, 0x0, "SER_UART_Write")     --- set trip temp = 125
        set vi16 chan SER_ABUS0 to fv  Thrhold_125_max measure V max 3v  i max  300ua clamp imax 500uA  imin -10uA
        wait(200uS)    
        RegRead(SER_ID, 0x9, 1, upperword, lowword,"SER_UART_Read")    
        set vi16 chan SER_ABUS0 to fv  Thrhold_125_min measure V max 3v  i max  300ua clamp imax 500uA  imin -10uA
        wait(1ms)
         RegRead(SER_ID, 0x9, 1, upperword, lowword1,"SER_UART_Read")  
      ----  prepare data log
      for idx = 1 to sites do
            site = active_sites[idx]
            if (lowword[site] >> 7 = 1 and lowword1[site] >> 7 = 0) then
                GoNGo_pass[site] =1
             else
               GoNGo_pass[site] =0
            end_if   
      end_for      
----Set temperature trip to 130
        RegWrite(SER_ID, 0x306, 1, 0x00, 0x40, "SER_UART_Write")     --- set trip temp = 130
        set vi16 chan SER_ABUS0 to fv  Thrhold_130_max measure V max 3v  i max  300ua clamp imax 500uA  imin -10uA
        wait(200uS)    
        RegRead(SER_ID, 0x9, 1, upperword, lowword,"SER_UART_Read")    
        set vi16 chan SER_ABUS0 to fv  Thrhold_125_min measure V max 3v  i max  300ua clamp imax 500uA  imin -10uA
        wait(1ms)
        RegRead(SER_ID, 0x9, 1, upperword, lowword1,"SER_UART_Read")  
      for idx = 1 to sites do
            site = active_sites[idx]
            if (lowword[site] >> 7 = 1 and lowword1[site] >> 7 = 0 and GoNGo_pass[site] =1) then   ---- only check if go no go passed 
                GoNGo_pass[site] =1
             else
               GoNGo_pass[site] =0
            end_if   
       end_for            
----Set temperature trip to 135
        RegWrite(SER_ID, 0x306, 1, 0x00, 0x80, "SER_UART_Write")     --- set trip temp = 135
        set vi16 chan SER_ABUS0 to fv  Thrhold_135_max measure V max 3v  i max  300ua clamp imax 500uA  imin -10uA
        wait(200uS)    
        RegRead(SER_ID, 0x9, 1, upperword, lowword,"SER_UART_Read")    
        set vi16 chan SER_ABUS0 to fv  Thrhold_125_min measure V max 3v  i max  300ua clamp imax 500uA  imin -10uA
        wait(1ms)
        RegRead(SER_ID, 0x9, 1, upperword, lowword1,"SER_UART_Read")  
      for idx = 1 to sites do
            site = active_sites[idx]
            if (lowword[site] >> 7 = 1 and lowword1[site] >> 7 = 0 and GoNGo_pass[site] =1) then   ---- only check if go no go passed 
                GoNGo_pass[site] =1
             else
               GoNGo_pass[site] =0
            end_if   
       end_for                
----Set temperature trip to 140
        RegWrite(SER_ID, 0x306, 1, 0x00, 0xC0, "SER_UART_Write")     --- set trip temp = 140
        set vi16 chan SER_ABUS0 to fv  Thrhold_140_max measure V max 3v  i max  300ua clamp imax 500uA  imin -10uA
        wait(200uS)    
        RegRead(SER_ID, 0x9, 1, upperword, lowword,"SER_UART_Read")    
        set vi16 chan SER_ABUS0 to fv  Thrhold_125_min measure V max 3v  i max  300ua clamp imax 500uA  imin -10uA
--        set vi16 chan SER_ABUS0 to fv  500mv measure V max 3v  i max  300ua clamp imax 500uA  imin -10uA

        wait(1ms)
        RegRead(SER_ID, 0x9, 1, upperword, lowword1,"SER_UART_Read")  
---for data log

       for idx = 1 to sites do
            site = active_sites[idx]
            if (lowword[site] >> 7 = 1 and lowword1[site] >> 7 = 0 and GoNGo_pass[site] =1) then   ---- only check if go no go passed 
                GoNGo_pass[site] =1
             else
               GoNGo_pass[site] =0
            end_if   
       end_for      
       wait(1ms)

    end_if----Char
-------------- Power Down ---------------------------
  set digital pin ALL_PATTERN_PINS levels to vil 0V vih 100mV iol 0uA ioh 0uA vref 0V
--  set  digital  pin ALL_PATTERN_PINS fx1 driver  preset low       
  wait(500us)
  connect digital pin  SER_GPO4_CFG0 + SER_GPO5_CFG1 + SER_GPO6_CFG2  + SER_GPIO3_RCLKOUT to dcl
  
  set hcovi SER_VDD + SER_VDD18 to fv 0V vmax 4V clamp imax 600mA imin -600mA         
  set hcovi SER_VDDIO to fv 0V   vmax 4V clamp imax 600mA imin -600mA
  open  cbit    ABUS_RELAY + DCTM_K1+ DCTM_K2 + MFP_LT_RELAY+ RXTX_K1
  open cbit  DNUT_RXTX_RELAY 	  
  wait(10ms)     -- extra for 47uF cap on SER_VDD        

  -- Initialize for set_SER_Voltages(vio, vcore, v18) routine
  vdd_global[1] = 0V   --SER_VDDIO
  vdd_global[2] = 0V   --SER_VDD  
  vdd_global[3] = 0V   --SER_VDDA(VDD18)

   fpga_Set_DNUT_Pins("FPGA1", 0,0, 0, 0, TRUE)  -- UART/TP/GMSL2=1/RATE=0(6 Gig link)      
    powerup_dnut_vdd_vterm(0.0,0.0)      
   -- Datalog
--     test_value MbistDone_datalog_array with MbistDone
--     test_value MbistPassFail_datalog_array with MbistPassFail

    test_value reg_val with devid_it 
    test_value TMON_BUS0  with Tmon_abus0
    test_value TMON_BUS1  with Tmon_abus1
    test_value DELTA_TMON  with DeltaTmon
    test_value TD_BUS3  with Td_abus3
    test_value TD_BUS1  with Td_abus1
    test_value DELTA_TD  with DeltaTd
        test_value Temp_Tdiode  with Tdiode
        test_value Temp_Tmon2  with Tmon2

    if CHAR  then
        test_value Vthreshold_125  with THRESHOLD_125
        test_value Vthreshold_130  with THRESHOLD_130
        test_value Vthreshold_135  with THRESHOLD_135
        test_value Vthreshold_140  with THRESHOLD_140
--         test_value Temp_Tdiode  with Tdiode
--         test_value Temp_Tmon2  with Tmon2
        test_value temptriphigh  with TempTripH
        test_value temptriplow  with TempTripLow
        test_value TmonTripHyst  with TripHyst
    else    
    test_value GoNGo_pass with ThrhldGnG
    end_if
    
    test_value fpga_fwrev_check with fpga_fwrev_reg_test    -- fpga firmware version check

 end_body



procedure TestClock(vcore, vio, v18, rword, osc_freq0,osc_freq1,osc_freq2,osc_freq3,osc_freq4,osc_freq5,osc_freq6,osc_freq7,RWORD,POWERUP,POWERDOWN)
--------------------------------------------------------------------------------
in float            : vcore, vio, v18
in_out float_test   : osc_freq0,osc_freq1,osc_freq2,osc_freq3,osc_freq4,osc_freq5,osc_freq6,osc_freq7

in_out integer_test : rword
in boolean          : POWERUP,POWERDOWN
in lword            :   RWORD
local   
    word                : sites, idx, site, idxs
--    integer             : idxs
    boolean             : CHAR
    multisite lword     : lowword, upperword
    multisite integer   : reg_val
    lword               : value_to_write, i
    boolean             :tmu_present, timed_out
    multisite float     : freq,freq0,freq1, freq2,freq3, freq4,freq5, freq6,freq7
    multisite double    : freq_meas[1],array_freq[8]
    
end_local   

body
    get_expr("OpVar_Char", CHAR)
    active_sites = get_active_sites
    sites = word(len(active_sites))  

    --POWER_CONNECT    -- need this for reseting device
    --make sure RSVD pin float (HVVI disconnect)
--    CHAR = TRUE
    disconnect hvvi chan SER_RSVD    -- need to float RSVD, important!!

-----Dut power up function
fpga_Set_DNUT_Pins("FPGA1", 0,0, 1, 0, TRUE)  -- UART/TP/GMSL2=1/RATE=0(6 Gig link)  
   close cbit XRES_RELAY -- zin revb LB
   DutPowerUp(vio, v18, vcore, "UART", "TP_GMSL1",POWERUP)------------- DutPowerUp(vio, v18, vcore, "UART", "TP_GMSL1",POWERUP)

 --   RegRead(SER_ID, SR_REG0 , 1, upperword, lowword,"SER_UART_Read")     -- device ID, to make sure we test the correct device turn on for debug
--    wait(200us)


-----Code from here
----Read back RWORD-----------------------------------------------------

  --enter TM D 
-----    SetTestMode(11, False, "SER_UART_Write")-----for ABUS Do we need this?????

    RegRead(SER_ID, SR_REG6 , 1,upperword, lowword , "SER_UART_Read")   

    RegWrite(SER_ID, SR_CMU4, 1, 0, 0x00 ,"SER_UART_Write" )   -----For production rev, need to program Fast edge otherwise not working 6/2018

    wait(0)


---enter debug mode to bring osc out at MFP1 pin    
    SetTestMode(5 , False , "SER_UART_Write" )
    value_to_write = 16#06
    RegWrite(SER_ID, SR_TEST0, 1, 0, value_to_write ,"SER_UART_Write" )

-----
---OSC_1=0------------------

--------------------Program 0x0544 OSC_0
    set digital pin SER_GPIO1_LFLTB_ERRB modes to driver off load off
    
    if RWORD = 0 then                                                       --- use XRES default calibration value        
        RegRead(SER_ID, SR_OSC_0 , 1,upperword, lowword , "SER_UART_Read") 
    else                                                                    --- User input code from 20 to 100    
        value_to_write = 16#80 | RWORD
        RegWrite(SER_ID, SR_OSC_0, 1, 0,  value_to_write ,"SER_UART_Write" ) 
        RegRead(SER_ID, SR_OSC_0 , 1,upperword, lowword , "SER_UART_Read")
    end_if  
    
    for idxs = 1 to sites do ---- setup read value for data log 
      site = active_sites[idxs]
      reg_val[site]  = integer(lowword[site]) &0x7F       
    end_for 

----Changing OSC_1 value from 0 to 7 and measure osc
    for i = 0 to 7 do    
        value_to_write = i + 0x40  ------- Need this turn enable to change freq different from MPW5. MT 6/2018
        RegWrite(SER_ID, SR_OSC_1, 1, 0, value_to_write ,"SER_UART_Write" ) 
        measure digital pin SER_GPIO1_LFLTB_ERRB  frequency interval 100.0e6 sample size count_legacy asynchronous into freq_meas
        for idxs = 1 to sites do
            site = active_sites[idxs]
            array_freq[site,i+1] = freq_meas[site,1]
        end_for
    end_for
    wait(0)

    --initialize digital tmu fx1
----This below code use tmu to measure  freq for to compare with value use direct dp measure. Did not see much difference Man Tran 7/ 2017
------ just dedug for single site    
--      for idx = 1 to sites do
--          site = active_sites[idx]
--         set digital tmu SER_GPIO1_LFLTB_ERRB on site site fx1 to measure frequency from rising edge average 500 prescaler 4  
--         set digital tmu  fx1 to arm on SER_GPIO1_LFLTB_ERRB on site site rising edge
--         start digital tmu fx1
--         wait for digital tmu fx1 timeout 1.0 into timed_out
--         read digital tmu SER_GPIO1_LFLTB_ERRB on site site fx1 measurements into freq
--         disconnect digital tmu  SER_GPIO1_LFLTB_ERRB fx1
--      end_for

----  Prepare for data log

        for idxs = 1 to sites do
            site = active_sites[idxs]
                freq0[site] = float(array_freq[site,1]) 
                freq1[site] = float(array_freq[site,2]) 
                freq2[site] = float(array_freq[site,3]) 
                freq3[site] = float(array_freq[site,4])                
                freq4[site] = float(array_freq[site,5]) 
                freq5[site] = float(array_freq[site,6])                
                freq6[site] = float(array_freq[site,7]) 
                freq7[site] = float(array_freq[site,8])                
        end_for


-------------- Power Down ---------------------------
     set digital pin SER_GPIO1_LFLTB_ERRB modes to driver pattern
      open cbit XRES_RELAY -- zin revb LB
      powerdown_device(POWERDOWN)  


---Data log out 

    test_value reg_val with rword

    test_value freq0 with osc_freq0
    test_value freq1 with osc_freq1
    test_value freq2 with osc_freq2
    test_value freq3 with osc_freq3
    test_value freq4 with osc_freq4
    test_value freq5 with osc_freq5    
    test_value freq6 with osc_freq6
    test_value freq7 with osc_freq7
end_body
procedure ADC_test(Vdd,Vdd18,Vddio, ext_Vref, adc_dly, devid_it, dnutid_it, ser_lock_it, des_lock_it, gpio0_div1, gpio0_div2, gpio0_div3, gpio0_div4, gpio1_div1, gpio1_div2, gpio1_div3, gpio1_div4, gpio2_div1, gpio2_div2, gpio2_div3, gpio2_div4, vddio_div4, vdd18_div2, vdd_div2, tmon, tmon_ext,POWERUP,POWERDOWN )
--------------------------------------------------------------------------------
in float            : Vdd,Vdd18,Vddio, ext_Vref, adc_dly
in_out float_test   : gpio0_div1, gpio0_div2, gpio0_div3, gpio0_div4
in_out float_test   : gpio1_div1, gpio1_div2, gpio1_div3, gpio1_div4
in_out float_test   : gpio2_div1, gpio2_div2, gpio2_div3, gpio2_div4
in_out float_test   : vddio_div4, vdd18_div2, vdd_div2, tmon, tmon_ext

in_out integer_test : devid_it, dnutid_it, ser_lock_it, des_lock_it
in boolean          : POWERUP, POWERDOWN

local
   multisite lword   : LowerRdWord, UpperRdWord
    word              : site, idx ,i
    word list[MAX_SITES]   : active_sites

  float             : Vconf0, Vconf1
  float             : Ain, DIV, VREF, Adc_scale, ADC_REFSCL, V_tmon, lsb
  multisite lword   : lowword, upperword, reg_val_adc0, reg_val_adc1, des_read, reg_val_rst 
  multisite float   : V_adc_gpio0_div1, V_adc_gpio0_div2, V_adc_gpio0_div3, V_adc_gpio0_div4
  multisite float   : V_adc_gpio1_div1, V_adc_gpio1_div2, V_adc_gpio1_div3, V_adc_gpio1_div4
  multisite float   : V_adc_gpio2_div1, V_adc_gpio2_div2, V_adc_gpio2_div3, V_adc_gpio2_div4
  multisite float   : V_adc_vddio_div4, V_adc_vddio_div2, V_adc_vdd18_div2, V_adc_vdd_div2, V_adc_tmon, V_adc_tmon_ext, values
    
  multisite lword   : reg_val, reg_val0, reg_val1, reg_val15
  multisite integer : ireg_val, ireg_val0, ireg_val1, ireg_val15, ireg_val_rst
  multisite lword   : hizdel_reg_val, oreg_reg_val
  lword             : data

end_local

body  

    active_sites = get_active_sites
    sites = word(len(active_sites))
    Ain   = 1.0
    DIV   = 1.0
    VREF  = 1.22  -- using internal Vref
    Adc_scale   = 1.0
    ADC_REFSCL  = 1.0
    V_tmon      = 25.0
    lsb = VREF/1024.0
    
   --POWER_CONNECT    -- need this for reseting device
    --make sure RSVD pin float (HVVI disconnect)
    disconnect hvvi chan SER_RSVD    -- need to float RSVD, important!!

-----Dut power up function
    DutPowerUp(Vddio, Vdd18, Vdd, "UART", "TP_GMSL2",POWERUP)
 
    RegRead(SER_ID, SR_REG0, 1, upperword, lowword,"SER_UART_Read")     -- device ID, to make sure we test the correct device, to comply with check list
    wait(200us)    
    for idx = 1 to sites do
      site = active_sites[idx]
      ireg_val[site]  = integer(lowword[site]) 
    end_for  
-----These setup for daughter card.
--     hizdel_reg_val = fpga_read_register("FPGA1", HIZDEL_REG)       -- should read back decimal 6000 if FPGA working OK
--     wait(0ms)
--     
--     fpga_set_I2C_Frequency("FPGA1", 1MHz)     -- only need this once, unless want to change freq 
--     fpga_set_UART_Frequency("FPGA1", 1MHz)
--     wait(0ms)   
---DNUT power need it later when daughtercard available
 --    set ovi chan DES_VDD_OVI to fv 1.2V measure i max 500mA clamp imax 500mA imin -500mA   
--     set ovi chan DES_VTERM_OVI to fv 1.2V measure i max 500mA clamp imax 500mA imin -500mA
--     wait(1ms)
--     connect ovi chan  DES_VDD_OVI remote
--     connect ovi chan  DES_VTERM_OVI remote
--     wait(3ms)
--     gate ovi chan DES_VDD_OVI on
--     gate ovi chan DES_VTERM_OVI on
--     wait(3ms)
--    fpga_Set_DNUT_Pins("FPGA1", 0, 0, 1, TRUE)  -- UART/TP/GMSL2=1/RATE=0(6 Gig link)               
--     wait(6ms)
--     
--     oreg_reg_val = fpga_read_register("FPGA1", OREG)    -- status of CFG1, CFG0, PWDN reg
--     wait(0ms)
--       
--     reg_val0  = fpga_UART_Read("FPGA1", "DNUT", DESA_ID, 0, 1)      -- UART read    
--     wait(200us)
--     for idxs = 1 to len(active_sites) do
--       site = active_sites[idxs]
--       ireg_val0[site]  = integer(reg_val0[site]) 
--     end_for  
--     -- now setup SER/DES link to 3G in TP mode -------
--     RegWrite(SER_ID, 16#01, 1, 16#04, 16#04, "SER_UART_Write")
--     wait(200us)         
--     fpga_UART_Write("FPGA1","DNUT", DESA_ID, 16#01, 1, 0x01)
--     wait(200us)  
--       
--     --RegRead(SER_ID, 16#01, 1, upperword, lowword,"SER_UART_Read")      -- verify write above before updated, 0x04      
--     --des_read =  fpga_UART_Read("FPGA1", "DNUT", DESA_ID, 0x01, 1)      -- verify write above before updated, 0x01    
--                
--     -- write Reg0x10 to update link speed to 3G
--     RegWrite(SER_ID, 16#10, 1, 16#21, 16#21, "SER_UART_Write")
--     wait(200us)        
--     RegRead(SER_ID, 16#10, 1, upperword, lowword,"SER_UART_Read")      -- self adjust back to 0x01(default)
--     fpga_UART_Write("FPGA1","DNUT", DESA_ID, 16#10, 1, 0x21)
--     wait(200us)
--     des_read =  fpga_UART_Read("FPGA1", "DNUT", DESA_ID, 0x10, 1)      -- self adjust back to 0x01(default)
-- 
--    wait(80ms)   --NEEDED to see LOCK bits on both SER/DES at 3G serial links !!!
-- 
--    RegRead(SER_ID, 16#13, 1, upperword, lowword,"SER_UART_Read")    -- for SER lock bit, good if 0xDA          
--    reg_val15  = fpga_UART_Read("FPGA1", "DNUT", DESA_ID, 0x13, 1)   -- DES lock bit, 0xDA expected   
--    wait(0ms)
--    
--    for idx = 1 to sites do
--       site = active_sites[idx]
--       ireg_val1[site]  = integer(lowword[site])
--       ireg_val15[site] = integer(reg_val15[site])      
--    end_for

--    -------------------------DO NOT DELETE, DEBUGGING-------------------------
--    -- try to read across the link to SER from DNUT using FPGA, FPGA timeout for read back is hardcode to 128uS
--    des_read =  fpga_UART_Read("FPGA1", "DNUT", SER_ID, 0x00, 1)      -- SER_ID read from DNUT UART mode, expect 0x80
--    wait(0ms)
--    --fpga_set_UART_Frequency("FPGA1", 100KHz)
--    --wait(0ms)
--    --RegWrite(SER_ID, 16#06, 1, 16#9F, 16#9F, "SER_UART_Write")      --  for I2C mode if want using
--    --fpga_UART_Write("FPGA1","DNUT", DESA_ID, 16#06, 1, 16#9E)
--    --des_read =  fpga_I2C_Read("FPGA1", "DNUT", SER_ID, 0x00, 1)     -- SER_ID read from DNUT I2C mode, expect 0x80.  I2C accross link works OK
--    -------------------------------------------------------------------------
-----Done with setp Des set up

  -- setup SER for ADC test here
   
  -- RegWrite(DevId, RegAddr, ByteCnt, DataUpperWord, DataLowerWord, PatternName)
  
  -- B/   Configure  RSVD, MFP3/5/6 to ADC inputs by Reg write (which Regs and values? Might not needed)  

  -- power up ADC
  
  RegWrite(SER_ID, 16#0534, 1, 16#80, 16#80, "SER_UART_Write")    -- ?? 
  RegWrite(SER_ID, 16#11  , 1, 16#0F, 16#0F, "SER_UART_Write")    -- ??
   
  RegWrite(SER_ID, 16#0502, 1, 16#00, 16#00, "SER_UART_Write")	-- disable channel multiplexer  
  RegWrite(SER_ID, 16#0503, 1, 16#A0, 16#A0, "SER_UART_Write")	-- delay 10us minimum with 2.5MHz ADC clk, default value is A0    
  
  RegWrite(SER_ID, 16#0501, 1, 16#08, 16#08, "SER_UART_Write")	-- Enable ADC clock
  RegWrite(SER_ID, 16#050C, 1, 16#02, 16#02, "SER_UART_Write")	-- Enable ADC ready interrupt
  RegRead(SER_ID, 16#0510, 1, upperword, lowword,"SER_UART_Read")	-- Read to Clear ADC ready interrupt bit, bit 1
  -- step 4 insert here if needed to connect external reference
  RegWrite(SER_ID, 16#0500, 1, 16#1E, 16#1E, "SER_UART_Write")	-- Power up the ADC, ADC reference buffer, ADC internal buffer
  wait(1ms)	-- Wait for Ready interrupt to be asserted

  RegWrite(SER_ID, 16#050C, 1, 16#00, 16#00, "SER_UART_Write")	-- interupt sources disabled, default value is 0  
  --RegRead(SER_ID, 16#0510, 1, upperword, lowword,"SER_UART_Read")	-- Read to Clear ADC ready interrupt bit, bit 1


  -- D/   Now apply 1V to GPIO0(MFP0) and wait 1ms
  disconnect digital pin SER_GPIO0_MS_LOCK  +  SER_GPIO1_LFLTB_ERRB + SER_GPIO2_GPO_SCLK  from dcl
  connect digital ppmu  SER_GPIO0_MS_LOCK  +  SER_GPIO1_LFLTB_ERRB + SER_GPIO2_GPO_SCLK  to fv 0.0V vmax 4V measure i max 2mA
  set ppmu SER_GPIO0_MS_LOCK to fv 1.0
  set ppmu SER_GPIO1_LFLTB_ERRB + SER_GPIO2_GPO_SCLK  to fv 0.0
  wait(3ms)
  -- Register Control Conversion Process
  RegWrite(SER_ID, 16#053E, 1, 16#01, 16#01, "SER_UART_Write")  -- Bit 0 for GPIO0, bit 1 for GPIO1, bit 2 for GPIO2 (Diana)
  RegWrite(SER_ID, 16#0534, 1, 16#00, 16#00, "SER_UART_Write")	-- Hold Round Robin, manual ADC control
  
  RegWrite(SER_ID, 16#0535, 1, 16#80, 16#80, "SER_UART_Write")	-- Program the trim register control(MPW3), will change for next REV***
     
  RegWrite(SER_ID, 16#0502, 1, 16#01, 16#01, "SER_UART_Write")	-- Enable channel multiplexer with divider by 1  
  RegWrite(SER_ID, 16#0501, 1, 16#08, 16#08, "SER_UART_Write")	-- Program input channel GPIO0, enable ADC clock and Normal scales
  
  -- step 5, Set channel limits as needed here
--   RegWrite(SER_ID, 16#0331, 1, 16#00, 16#00, "SER_UART_Write")
--   RegWrite(SER_ID, 16#0332, 1, 16#00, 16#00, "SER_UART_Write")
--   RegWrite(SER_ID, 16#0333, 1, 16#00, 16#00, "SER_UART_Write")
--   RegWrite(SER_ID, 16#0334, 1, 16#00, 16#00, "SER_UART_Write")
--   RegWrite(SER_ID, 16#0335, 1, 16#00, 16#00, "SER_UART_Write")
--   RegWrite(SER_ID, 16#0336, 1, 16#00, 16#00, "SER_UART_Write")
--   RegWrite(SER_ID, 16#0337, 1, 16#00, 16#00, "SER_UART_Write")  
--   RegWrite(SER_ID, 16#0338, 1, 16#00, 16#00, "SER_UART_Write")
--   RegWrite(SER_ID, 16#0339, 1, 16#00, 16#00, "SER_UART_Write")
  
  RegWrite(SER_ID, 16#0330, 1, 16#00, 16#00, "SER_UART_Write")	-- 
  RegWrite(SER_ID, 16#03F3, 1, 16#00, 16#00, "SER_UART_Write")	-- 
  RegWrite(SER_ID, 16#02C7, 1, 16#81, 16#81, "SER_UART_Write")	-- 
  RegWrite(SER_ID, 16#02CD, 1, 16#81, 16#81, "SER_UART_Write")	-- 
  RegWrite(SER_ID, 16#02D0, 1, 16#91, 16#91, "SER_UART_Write")	-- 

  RegWrite(SER_ID, 16#5, 1, 16#00, 16#00, "SER_UART_Write")	        -- disable LOCK and ERROR outs, needed.  

  RegWrite(SER_ID, 16#050C, 1, 16#01, 16#01, "SER_UART_Write")	        -- Enable ADC Done interrupt

  RegRead(SER_ID, 16#0510, 1, upperword, lowword,"SER_UART_Read")	-- Read to Clear ADC interrupt
  RegRead(SER_ID, 16#0511, 1, upperword, lowword,"SER_UART_Read")	-- Read to Clear ADC interrupt
  RegRead(SER_ID, 16#0512, 1, upperword, lowword,"SER_UART_Read")	-- Read to Clear ADC interrupt

  RegWrite(SER_ID, 16#0500, 1, 16#1F, 16#1F, "SER_UART_Write")	        -- Start ADC conversion, Register bit 0 is self clearing for next rev
  wait(adc_dly) -- needed but need to check later
  RegWrite(SER_ID, 16#0500, 1, 16#1E, 16#1E, "SER_UART_Write")	        -- needed for this rev(MPW3), but not next rev***

  -- ***
  --RegRead(SER_ID, 16#0510, 1, upperword, lowword,"SER_UART_Read")	-- Wait for ADC to assert interrupt flag, ADC_INTR_0.adc_done_if at bit0
                                                                        -- Read to Clear ADC interrupt, bit 0 should be high then self clear after read?

  reg_val_adc0 = 0
  reg_val_adc1 = 0
  reg_val      = 0
  DIV          = 1.0

  RegRead(SER_ID, 16#0508, 1, upperword, lowword,"SER_UART_Read")	-- Read ADC_DATA0.adc_datal[7:0], 8 bits		
  for idx = 1 to sites do
      site = active_sites[idx]
      reg_val_adc0[site]  = lowword[site]       
  end_for 	
	
  RegRead(SER_ID, 16#0509, 1, upperword, lowword,"SER_UART_Read")	-- Read ADC_DATA1.adc_datah[1:0], 2 bits
  for idx = 1 to sites do
    site = active_sites[idx]
    reg_val_adc1[site]  = lowword[site]      
  end_for

  for idx = 1 to sites do
      site = active_sites[idx]      
      reg_val_rst[site]   = (reg_val_adc1[site] << 8) | (reg_val_adc0[site])       -- RESULT 10bits
      ireg_val_rst[site]  = integer(reg_val_rst[site])
      
      V_adc_gpio0_div1[site] = (float(ireg_val_rst[site])/1023.0) * (VREF/(2.0^ADC_REFSCL)) * (DIV*(2.0^Adc_scale))
  
  end_for
  
  for i = 1 to 3 do
 
    if (i=1) then
     -- Now apply 1.8V to GPIO0(MFP3) to test divider by 2
        DIV = 2.0
        RegWrite(SER_ID, 16#0502, 1, 16#05, 16#05, "SER_UART_Write")	        -- Enable channel multiplexer with divide by 2                 
        set ppmu SER_GPIO0_MS_LOCK to fv 1.8
    end_if

    if (i=2) then
     -- Now apply 3.0V to GPIO0(MFP3) to test divider by 3
        DIV = 3.0
        RegWrite(SER_ID, 16#0502, 1, 16#09, 16#09, "SER_UART_Write")	        -- Enable channel multiplexer with divide by 3          
        set ppmu SER_GPIO0_MS_LOCK to fv 3.0
    end_if

    if (i=3) then
     -- Now apply 3.6V to GPIO0(MFP3) to test divider by 4
        DIV = 4.0
        RegWrite(SER_ID, 16#0502, 1, 16#0D, 16#0D, "SER_UART_Write")	        -- Enable channel multiplexer with divide by 4          
        set ppmu SER_GPIO0_MS_LOCK to fv 3.6
    end_if
    wait(3ms)  -- need to check this later
   

    RegWrite(SER_ID, 16#0500, 1, 16#1F, 16#1F, "SER_UART_Write")	        -- Start ADC conversion, Register bit 0 is self clearing for next rev
    wait(adc_dly) -- needed but need to check later
    RegWrite(SER_ID, 16#0500, 1, 16#1E, 16#1E, "SER_UART_Write")	        -- needed for this rev(MPW3), but not next rev***  

    reg_val_adc0 = 0
    reg_val_adc1 = 0
    reg_val      = 0
  
    RegRead(SER_ID, 16#0508, 1, upperword, lowword,"SER_UART_Read")	-- Read ADC_DATA0.adc_datal[7:0], 8 bits		
        for idx = 1 to sites do
            site = active_sites[idx]
            reg_val_adc0[site]  = lowword[site]       
        end_for 	
	
    RegRead(SER_ID, 16#0509, 1, upperword, lowword,"SER_UART_Read")	-- Read ADC_DATA1.adc_datah[1:0], 2 bits
        for idx = 1 to sites do
            site = active_sites[idx]
            reg_val_adc1[site]  = lowword[site]      
        end_for


        for idx = 1 to sites do
            site = active_sites[idx]      
            reg_val_rst[site]   = (reg_val_adc1[site] << 8) | (reg_val_adc0[site])       -- RESULT 10bits
            ireg_val_rst[site]  = integer(reg_val_rst[site])
      
            if (i=1) then
                V_adc_gpio0_div2[site] = (float(ireg_val_rst[site])/1023.0) * (VREF/(2.0^ADC_REFSCL)) * (DIV*(2.0^Adc_scale))
            end_if

            if (i=2) then
                V_adc_gpio0_div3[site] = (float(ireg_val_rst[site])/1023.0) * (VREF/(2.0^ADC_REFSCL)) * (DIV*(2.0^Adc_scale))
            end_if
      
            if (i=3) then
                V_adc_gpio0_div4[site] = (float(ireg_val_rst[site])/1023.0) * (VREF/(2.0^ADC_REFSCL)) * (DIV*(2.0^Adc_scale))
                end_if  
         end_for

    end_for   ---to here

    set ppmu SER_GPIO0_MS_LOCK to fv 0.0
    wait(1ms)
    RegWrite(SER_ID, 16#0502, 1, 16#00, 16#00, "SER_UART_Write")	-- Open Input Multiplexer


--*********** GPIO1 testing ************
---- Register Control Conversion Process
    RegWrite(SER_ID, 16#053E, 1, 16#02, 16#02, "SER_UART_Write")  -- Bit 0 for GPIO0, bit 1 for GPIO1, bit 2 for GPIO2 (Diana)
     
    RegWrite(SER_ID, 16#0502, 1, 16#01, 16#01, "SER_UART_Write")	-- Enable channel multiplexer with divider by 1
    RegWrite(SER_ID, 16#0501, 1, 16#18, 16#18, "SER_UART_Write")	-- Program input channel GPIO1, enable ADC clock and Normal scales
  
  -- step 5, Set channel limits as needed here
--    RegWrite(SER_ID, 16#0330, 1, 16#00, 16#00, "SER_UART_Write")	-- 
--    RegWrite(SER_ID, 16#0331, 1, 16#00, 16#00, "SER_UART_Write")	-- 
--    
--   RegWrite(SER_ID, 16#03F3, 1, 16#00, 16#00, "SER_UART_Write")	-- 
--   RegWrite(SER_ID, 16#02C7, 1, 16#81, 16#81, "SER_UART_Write")	-- 
--   RegWrite(SER_ID, 16#02CD, 1, 16#81, 16#81, "SER_UART_Write")	-- 
--   RegWrite(SER_ID, 16#02D0, 1, 16#91, 16#91, "SER_UART_Write")	-- 

  --RegWrite(SER_ID, 16#5, 1, 16#00, 16#00, "SER_UART_Write")	        -- disable LOCK and ERROR outs, needed.
  --might need to disable LMN internal circuits here  
  --RegWrite(SER_ID, 16#050C, 1, 16#01, 16#01, "SER_UART_Write")	-- Enable ADC Done interrupt
  --RegRead(SER_ID, 16#0510, 1, upperword, lowword,"SER_UART_Read")	-- Read to Clear ADC interrupt
  --RegRead(SER_ID, 16#0511, 1, upperword, lowword,"SER_UART_Read")	-- Read to Clear ADC interrupt
  --RegRead(SER_ID, 16#0512, 1, upperword, lowword,"SER_UART_Read")	-- Read to Clear ADC interrupt
        
    set ppmu SER_GPIO1_LFLTB_ERRB to fv 1.0
    set ppmu SER_GPIO0_MS_LOCK + SER_GPIO2_GPO_SCLK to fv 0.0
    wait(3ms)
  
    RegWrite(SER_ID, 16#0500, 1, 16#1F, 16#1F, "SER_UART_Write")	        -- Start ADC conversion, Register bit 0 is self clearing for next rev
    wait(adc_dly)    -- needed but need to check later
    RegWrite(SER_ID, 16#0500, 1, 16#1E, 16#1E, "SER_UART_Write")	        -- needed for this rev(MPW3), but not next rev***

    reg_val_adc0 = 0
    reg_val_adc1 = 0
    reg_val      = 0
    DIV          = 1.0

    RegRead(SER_ID, 16#0508, 1, upperword, lowword,"SER_UART_Read")	-- Read ADC_DATA0.adc_datal[7:0], 8 bits		
    for idx = 1 to sites do
        site = active_sites[idx]
        reg_val_adc0[site]  = lowword[site]       
    end_for 	
	
    RegRead(SER_ID, 16#0509, 1, upperword, lowword,"SER_UART_Read")	-- Read ADC_DATA1.adc_datah[1:0], 2 bits
    for idx = 1 to site do
        site = active_sites[idx]
        reg_val_adc1[site]  = lowword[site]      
    end_for

    for idx = 1 to sites do
        site = active_sites[idx]      
            reg_val_rst[site]   = (reg_val_adc1[site] << 8) | (reg_val_adc0[site])       -- RESULT 10bits
            ireg_val_rst[site]  = integer(reg_val_rst[site])
      
            V_adc_gpio1_div1[site] = (float(ireg_val_rst[site])/1023.0) * (VREF/(2.0^ADC_REFSCL)) * (DIV*(2.0^Adc_scale))
  
    end_for
    
    for i = 1 to 3 do
        if (i=1) then
--------- Now apply 1.8V to GPIO1(MFP5) to test divider by 2
            DIV = 2.0
            RegWrite(SER_ID, 16#0502, 1, 16#05, 16#05, "SER_UART_Write")	        -- Enable channel multiplexer with divide by 2                 
            set ppmu SER_GPIO1_LFLTB_ERRB to fv 1.8
        end_if

        if (i=2) then
     -- Now apply 3V to GPIO1(MFP5) to test divider by 3
            DIV = 3.0
            RegWrite(SER_ID, 16#0502, 1, 16#09, 16#09, "SER_UART_Write")	        -- Enable channel multiplexer with divide by 3          
            set ppmu SER_GPIO1_LFLTB_ERRB to fv 3.0
        end_if

        if (i=3) then
     -- Now apply 3.6V to GPIO1(MFP5) to test divider by 4
            DIV = 4.0
            RegWrite(SER_ID, 16#0502, 1, 16#0D, 16#0D, "SER_UART_Write")	        -- Enable channel multiplexer with divide by 4          
            set ppmu SER_GPIO1_LFLTB_ERRB to fv 3.6
        end_if
        wait(3ms)  -- need to check this later
   

        RegWrite(SER_ID, 16#0500, 1, 16#1F, 16#1F, "SER_UART_Write")	        -- Start ADC conversion, Register bit 0 is self clearing for next rev
        wait(adc_dly) -- needed but need to check later
        RegWrite(SER_ID, 16#0500, 1, 16#1E, 16#1E, "SER_UART_Write")	        -- needed for this rev(MPW3), but not next rev***  

        reg_val_adc0 = 0
        reg_val_adc1 = 0
        reg_val      = 0
  
        RegRead(SER_ID, 16#0508, 1, upperword, lowword,"SER_UART_Read")	-- Read ADC_DATA0.adc_datal[7:0], 8 bits		
        for idx = 1 to sites do
            site = active_sites[idx]
            reg_val_adc0[site]  = lowword[site]       
        end_for 	
	
        RegRead(SER_ID, 16#0509, 1, upperword, lowword,"SER_UART_Read")	-- Read ADC_DATA1.adc_datah[1:0], 2 bits
        for idx = 1 to sites do
            site = active_sites[idx]
            reg_val_adc1[site]  = lowword[site]      
         end_for


        for idx = 1 to sites do
            site = active_sites[idx]      
            reg_val_rst[site]   = (reg_val_adc1[site] << 8) | (reg_val_adc0[site])       -- RESULT 10bits
            ireg_val_rst[site]  = integer(reg_val_rst[site])
      
            if (i=1) then
                V_adc_gpio1_div2[site] = (float(ireg_val_rst[site])/1023.0) * (VREF/(2.0^ADC_REFSCL)) * (DIV*(2.0^Adc_scale))
            end_if

            if (i=2) then
                V_adc_gpio1_div3[site] = (float(ireg_val_rst[site])/1023.0) * (VREF/(2.0^ADC_REFSCL)) * (DIV*(2.0^Adc_scale))
            end_if
      
            if (i=3) then
                V_adc_gpio1_div4[site] = (float(ireg_val_rst[site])/1023.0) * (VREF/(2.0^ADC_REFSCL)) * (DIV*(2.0^Adc_scale))
            end_if  
        end_for

    end_for---Loop i = 3

    set ppmu SER_GPIO1_LFLTB_ERRB to fv 0.0
    wait(1ms)
    RegWrite(SER_ID, 16#0502, 1, 16#00, 16#00, "SER_UART_Write")	-- Open Input Multiplexer



--*********** GPIO2 testing ************
  -- Register Control Conversion Process
    RegWrite(SER_ID, 16#053E, 1, 16#04, 16#04, "SER_UART_Write")  -- Bit 0 for GPIO0, bit 1 for GPIO1, bit 2 for GPIO2 (Diana)
     
    RegWrite(SER_ID, 16#0502, 1, 16#01, 16#01, "SER_UART_Write")	-- Enable channel multiplexer with divider by 1
    RegWrite(SER_ID, 16#0501, 1, 16#28, 16#28, "SER_UART_Write")	-- Program input channel GPIO2, enable ADC clock and Normal scales
  
  -- step 5, Set channel limits as needed here
--   RegWrite(SER_ID, 16#0330, 1, 16#00, 16#00, "SER_UART_Write")	-- 
--   RegWrite(SER_ID, 16#03F3, 1, 16#00, 16#00, "SER_UART_Write")	-- 
--   RegWrite(SER_ID, 16#02C7, 1, 16#81, 16#81, "SER_UART_Write")	-- 
--   RegWrite(SER_ID, 16#02CD, 1, 16#81, 16#81, "SER_UART_Write")	-- 
--   RegWrite(SER_ID, 16#02D0, 1, 16#91, 16#91, "SER_UART_Write")	-- 

    RegWrite(SER_ID, 16#5, 1, 16#00, 16#00, "SER_UART_Write")	        -- disable LOCK and ERROR outs, needed.
  --might need to disable LMN internal circuits here  
  --RegWrite(SER_ID, 16#050C, 1, 16#01, 16#01, "SER_UART_Write")	-- Enable ADC Done interrupt
  --RegRead(SER_ID, 16#0510, 1, upperword, lowword,"SER_UART_Read")	-- Read to Clear ADC interrupt
  --RegRead(SER_ID, 16#0511, 1, upperword, lowword,"SER_UART_Read")	-- Read to Clear ADC interrupt
  --RegRead(SER_ID, 16#0512, 1, upperword, lowword,"SER_UART_Read")	-- Read to Clear ADC interrupt
        
    set ppmu SER_GPIO2_GPO_SCLK to fv 1.0
    set ppmu SER_GPIO0_MS_LOCK + SER_GPIO1_LFLTB_ERRB to fv 0.0
    wait(3ms)
  
    RegWrite(SER_ID, 16#0500, 1, 16#1F, 16#1F, "SER_UART_Write")	        -- Start ADC conversion, Register bit 0 is self clearing for next rev
    wait(adc_dly)    -- needed but need to check later
    RegWrite(SER_ID, 16#0500, 1, 16#1E, 16#1E, "SER_UART_Write")	        -- needed for this rev(MPW3), but not next rev***

    reg_val_adc0 = 0
    reg_val_adc1 = 0
    reg_val      = 0
    DIV          = 1.0

    RegRead(SER_ID, 16#0508, 1, upperword, lowword,"SER_UART_Read")	-- Read ADC_DATA0.adc_datal[7:0], 8 bits		
    for idx = 1 to sites do
        site = active_sites[idx]
        reg_val_adc0[site]  = lowword[site]       
    end_for 	
	
    RegRead(SER_ID, 16#0509, 1, upperword, lowword,"SER_UART_Read")	-- Read ADC_DATA1.adc_datah[1:0], 2 bits
    for idx = 1 to sites do
        site = active_sites[idx]
        reg_val_adc1[site]  = lowword[site]      
    end_for

    for idx = 1 to sites do
        site = active_sites[idx]      
        reg_val_rst[site]   = (reg_val_adc1[site] << 8) | (reg_val_adc0[site])       -- RESULT 10bits
        ireg_val_rst[site]  = integer(reg_val_rst[site])
      
        V_adc_gpio2_div1[site] = (float(ireg_val_rst[site])/1023.0) * (VREF/(2.0^ADC_REFSCL)) * (DIV*(2.0^Adc_scale))
  
    end_for
    
    for i = 1 to 3 do
 
        if (i=1) then
     -- Now apply 1.8V to GPIO2(MFP6) to test divider by 2
            DIV = 2.0
            RegWrite(SER_ID, 16#0502, 1, 16#05, 16#05, "SER_UART_Write")	        -- Enable channel multiplexer with divide by 2                 
            set ppmu SER_GPIO2_GPO_SCLK to fv 1.8
        end_if

        if (i=2) then
     -- Now apply 3.0V to GPIO2(MFP6) to test divider by 3
            DIV = 3.0
            RegWrite(SER_ID, 16#0502, 1, 16#09, 16#09, "SER_UART_Write")	        -- Enable channel multiplexer with divide by 3          
            set ppmu SER_GPIO2_GPO_SCLK to fv 3.0
        end_if

        if (i=3) then
     -- Now apply 3.6V to GPIO2(MFP6) to test divider by 4
            DIV = 4.0
            RegWrite(SER_ID, 16#0502, 1, 16#0D, 16#0D, "SER_UART_Write")	        -- Enable channel multiplexer with divide by 4          
            set ppmu SER_GPIO2_GPO_SCLK to fv 3.6
        end_if
        wait(3ms)  -- need to check this later
   

        RegWrite(SER_ID, 16#0500, 1, 16#1F, 16#1F, "SER_UART_Write")	        -- Start ADC conversion, Register bit 0 is self clearing for next rev
        wait(adc_dly) -- needed but need to check later
        RegWrite(SER_ID, 16#0500, 1, 16#1E, 16#1E, "SER_UART_Write")	        -- needed for this rev(MPW3), but not next rev***  

        reg_val_adc0 = 0
        reg_val_adc1 = 0
        reg_val      = 0
  
        RegRead(SER_ID, 16#0508, 1, upperword, lowword,"SER_UART_Read")	-- Read ADC_DATA0.adc_datal[7:0], 8 bits		
        for idx = 1 to sites do
            site = active_sites[idx]
            reg_val_adc0[site]  = lowword[site]       
            end_for 	
	
        RegRead(SER_ID, 16#0509, 1, upperword, lowword,"SER_UART_Read")	-- Read ADC_DATA1.adc_datah[1:0], 2 bits
        for idx = 1 to sites do
            site = active_sites[idx]
            reg_val_adc1[site]  = lowword[site]      
        end_for


        for idx = 1 to sites do
            site = active_sites[idx]      
            reg_val_rst[site]   = (reg_val_adc1[site] << 8) | (reg_val_adc0[site])       -- RESULT 10bits
            ireg_val_rst[site]  = integer(reg_val_rst[site])
      
            if (i=1) then
                V_adc_gpio2_div2[site] = (float(ireg_val_rst[site])/1023.0) * (VREF/(2.0^ADC_REFSCL)) * (DIV*(2.0^Adc_scale))
            end_if

            if (i=2) then
                V_adc_gpio2_div3[site] = (float(ireg_val_rst[site])/1023.0) * (VREF/(2.0^ADC_REFSCL)) * (DIV*(2.0^Adc_scale))
            end_if
      
            if (i=3) then
                V_adc_gpio2_div4[site] = (float(ireg_val_rst[site])/1023.0) * (VREF/(2.0^ADC_REFSCL)) * (DIV*(2.0^Adc_scale))
            end_if  
        end_for

    end_for---Loop i = 3

    set ppmu SER_GPIO2_GPO_SCLK to fv 0.0  
  -- Now remove voltage on all GPIOs 
    disconnect digital ppmu   SER_GPIO0_MS_LOCK + SER_GPIO1_LFLTB_ERRB + SER_GPIO2_GPO_SCLK from fv 0.0V vmax 4V measure i max 2mA
  -- connect digital pin SER_GPIO0_MS_LOCK + SER_GPIO1_LFLTB_ERRB + SER_GPIO2_GPO_SCLK to dcl
    RegWrite(SER_ID, 16#0502, 1, 16#00, 16#00, "SER_UART_Write")	-- Open Input Multiplexer       
    wait(3ms)  -- not to short gpio with vddio next test



--*********** VDDIO testing ************
  -- Register Control Conversion Process
  --RegWrite(SER_ID, 16#053E, 1, 16#04, 16#04, "SER_UART_Write")  -- Bit 0 for GPIO0, bit 1 for GPIO1, bit 2 for GPIO2 (Diana)
  
    RegWrite(SER_ID, 16#0501, 1, 16#88, 16#88, "SER_UART_Write")	  -- Program input channel vddio, enable ADC clock and Normal scales       
    RegWrite(SER_ID, 16#0502, 1, 16#0D, 16#0D, "SER_UART_Write")	  -- Enable channel multiplexer with divide by 4          

  
  -- step 5, Set channel limits as needed here
--   RegWrite(SER_ID, 16#0330, 1, 16#00, 16#00, "SER_UART_Write")	-- 
--   RegWrite(SER_ID, 16#03F3, 1, 16#00, 16#00, "SER_UART_Write")	-- 
--   RegWrite(SER_ID, 16#02C7, 1, 16#81, 16#81, "SER_UART_Write")	-- 
--   RegWrite(SER_ID, 16#02CD, 1, 16#81, 16#81, "SER_UART_Write")	-- 
--   RegWrite(SER_ID, 16#02D0, 1, 16#91, 16#91, "SER_UART_Write")	-- 

  --RegWrite(SER_ID, 16#5, 1, 16#00, 16#00, "SER_UART_Write")	        -- disable LOCK and ERROR outs, needed.
  --might need to disable LMN internal circuits here  
  --RegWrite(SER_ID, 16#050C, 1, 16#01, 16#01, "SER_UART_Write")	-- Enable ADC Done interrupt
  --RegRead(SER_ID, 16#0510, 1, upperword, lowword,"SER_UART_Read")	-- Read to Clear ADC interrupt
  --RegRead(SER_ID, 16#0511, 1, upperword, lowword,"SER_UART_Read")	-- Read to Clear ADC interrupt
  --RegRead(SER_ID, 16#0512, 1, upperword, lowword,"SER_UART_Read")	-- Read to Clear ADC interrupt
        

    wait(1ms)  
    RegWrite(SER_ID, 16#0500, 1, 16#1F, 16#1F, "SER_UART_Write")	        -- Start ADC conversion, Register bit 0 is self clearing for next rev
    wait(adc_dly)    -- needed but need to check later
    RegWrite(SER_ID, 16#0500, 1, 16#1E, 16#1E, "SER_UART_Write")	        -- needed for this rev(MPW3), but not next rev***

    reg_val_adc0 = 0
    reg_val_adc1 = 0
    reg_val      = 0
    DIV          = 4.0
    VREF         = 1.22
    Adc_scale    = 0.0
    ADC_REFSCL   = 0.0  

    RegRead(SER_ID, 16#0508, 1, upperword, lowword,"SER_UART_Read")	-- Read ADC_DATA0.adc_datal[7:0], 8 bits		
        for idx = 1 to sites do
            site = active_sites[idx]
            reg_val_adc0[site]  = lowword[site]       
            end_for 	
	
    RegRead(SER_ID, 16#0509, 1, upperword, lowword,"SER_UART_Read")	-- Read ADC_DATA1.adc_datah[1:0], 2 bits
    for idx = 1 to sites do
        site = active_sites[idx]
        reg_val_adc1[site]  = lowword[site]      
    end_for

    for idx = 1 to sites do
        site = active_sites[idx]      
        reg_val_rst[site]   = (reg_val_adc1[site] << 8) | (reg_val_adc0[site])       -- RESULT 10bits
        ireg_val_rst[site]  = integer(reg_val_rst[site])
      
        V_adc_vddio_div4[site] = (float(ireg_val_rst[site])/1023.0) * (VREF/(2.0^ADC_REFSCL)) * (DIV*(2.0^Adc_scale))
  
    end_for
    
    RegWrite(SER_ID, 16#0502, 1, 16#00, 16#00, "SER_UART_Write")	-- Open Input Multiplexer
    wait(3ms)   -- not to short vddio with vdd18 next test
  
  
--*********** VDD18 testing ************
  -- Register Control Conversion Process
  
    RegWrite(SER_ID, 16#0501, 1, 16#98, 16#98, "SER_UART_Write")	  -- Program input channel vdd18, enable ADC clock and Normal scales       
    RegWrite(SER_ID, 16#0502, 1, 16#05, 16#05, "SER_UART_Write")	  -- Enable channel multiplexer with divide by 2          

  
  -- step 5, Set channel limits as needed here
--   RegWrite(SER_ID, 16#0330, 1, 16#00, 16#00, "SER_UART_Write")	-- 
--   RegWrite(SER_ID, 16#03F3, 1, 16#00, 16#00, "SER_UART_Write")	-- 
--   RegWrite(SER_ID, 16#02C7, 1, 16#81, 16#81, "SER_UART_Write")	-- 
--   RegWrite(SER_ID, 16#02CD, 1, 16#81, 16#81, "SER_UART_Write")	-- 
--   RegWrite(SER_ID, 16#02D0, 1, 16#91, 16#91, "SER_UART_Write")	-- 

  --RegWrite(SER_ID, 16#5, 1, 16#00, 16#00, "SER_UART_Write")	        -- disable LOCK and ERROR outs, needed.
  --might need to disable LMN internal circuits here  
  --RegWrite(SER_ID, 16#050C, 1, 16#01, 16#01, "SER_UART_Write")	-- Enable ADC Done interrupt
  --RegRead(SER_ID, 16#0510, 1, upperword, lowword,"SER_UART_Read")	-- Read to Clear ADC interrupt
  --RegRead(SER_ID, 16#0511, 1, upperword, lowword,"SER_UART_Read")	-- Read to Clear ADC interrupt
  --RegRead(SER_ID, 16#0512, 1, upperword, lowword,"SER_UART_Read")	-- Read to Clear ADC interrupt
        

    wait(1ms)  
    RegWrite(SER_ID, 16#0500, 1, 16#1F, 16#1F, "SER_UART_Write")	        -- Start ADC conversion, Register bit 0 is self clearing for next rev
    wait(adc_dly)    -- needed but need to check later
    RegWrite(SER_ID, 16#0500, 1, 16#1E, 16#1E, "SER_UART_Write")	        -- needed for this rev(MPW3), but not next rev***

    reg_val_adc0 = 0
    reg_val_adc1 = 0
    reg_val      = 0
    DIV          = 2.0
    VREF         = 1.22
    Adc_scale    = 0.0
    ADC_REFSCL   = 0.0  

    RegRead(SER_ID, 16#0508, 1, upperword, lowword,"SER_UART_Read")	-- Read ADC_DATA0.adc_datal[7:0], 8 bits		
    for idx = 1 to sites do
        site = active_sites[idx]
        reg_val_adc0[site]  = lowword[site]       
    end_for 	
	
    RegRead(SER_ID, 16#0509, 1, upperword, lowword,"SER_UART_Read")	-- Read ADC_DATA1.adc_datah[1:0], 2 bits
    for idx = 1 to sites do
        site = active_sites[idx]
        reg_val_adc1[site]  = lowword[site]      
    end_for

    for idx = 1 to sites do
        site = active_sites[idx]      
        reg_val_rst[site]   = (reg_val_adc1[site] << 8) | (reg_val_adc0[site])       -- RESULT 10bits
        ireg_val_rst[site]  = integer(reg_val_rst[site])
      
        V_adc_vdd18_div2[site] = (float(ireg_val_rst[site])/1023.0) * (VREF/(2.0^ADC_REFSCL)) * (DIV*(2.0^Adc_scale))
  
    end_for
    
    RegWrite(SER_ID, 16#0502, 1, 16#00, 16#00, "SER_UART_Write")	-- Open Input Multiplexer
    wait(3ms)   -- not to short vdd18 with vdd(vcore) next test  
  
  
--*********** VDD(Vcore) testing ************
  -- Register Control Conversion Process
  
    RegWrite(SER_ID, 16#0501, 1, 16#A8, 16#A8, "SER_UART_Write")	  -- Program input channel vdd(vcore), enable ADC clock and Normal scales       
    RegWrite(SER_ID, 16#0502, 1, 16#05, 16#05, "SER_UART_Write")	  -- Enable channel multiplexer with divide by 2          

  
  -- step 5, Set channel limits as needed here
--   RegWrite(SER_ID, 16#0330, 1, 16#00, 16#00, "SER_UART_Write")	-- 
--   RegWrite(SER_ID, 16#03F3, 1, 16#00, 16#00, "SER_UART_Write")	-- 
--   RegWrite(SER_ID, 16#02C7, 1, 16#81, 16#81, "SER_UART_Write")	-- 
--   RegWrite(SER_ID, 16#02CD, 1, 16#81, 16#81, "SER_UART_Write")	-- 
--   RegWrite(SER_ID, 16#02D0, 1, 16#91, 16#91, "SER_UART_Write")	-- 

  --RegWrite(SER_ID, 16#5, 1, 16#00, 16#00, "SER_UART_Write")	        -- disable LOCK and ERROR outs, needed.
  --might need to disable LMN internal circuits here  
  --RegWrite(SER_ID, 16#050C, 1, 16#01, 16#01, "SER_UART_Write")	-- Enable ADC Done interrupt
  --RegRead(SER_ID, 16#0510, 1, upperword, lowword,"SER_UART_Read")	-- Read to Clear ADC interrupt
  --RegRead(SER_ID, 16#0511, 1, upperword, lowword,"SER_UART_Read")	-- Read to Clear ADC interrupt
  --RegRead(SER_ID, 16#0512, 1, upperword, lowword,"SER_UART_Read")	-- Read to Clear ADC interrupt
        

    wait(1ms)  
    RegWrite(SER_ID, 16#0500, 1, 16#1F, 16#1F, "SER_UART_Write")	        -- Start ADC conversion, Register bit 0 is self clearing for next rev
    wait(adc_dly)    -- needed but need to check later
    RegWrite(SER_ID, 16#0500, 1, 16#1E, 16#1E, "SER_UART_Write")	        -- needed for this rev(MPW3), but not next rev***

    reg_val_adc0 = 0
    reg_val_adc1 = 0
    reg_val      = 0
    DIV          = 2.0
    VREF         = 1.22
    Adc_scale    = 0.0
    ADC_REFSCL   = 0.0  

    RegRead(SER_ID, 16#0508, 1, upperword, lowword,"SER_UART_Read")	-- Read ADC_DATA0.adc_datal[7:0], 8 bits		
    for idx = 1 to sites do
        site = active_sites[idx]
        reg_val_adc0[site]  = lowword[site]       
    end_for 	
	
    RegRead(SER_ID, 16#0509, 1, upperword, lowword,"SER_UART_Read")	-- Read ADC_DATA1.adc_datah[1:0], 2 bits
    for idx = 1 to sites do
        site = active_sites[idx]
        reg_val_adc1[site]  = lowword[site]      
    end_for

    for idx = 1 to sites do
        site = active_sites[idx]      
        reg_val_rst[site]   = (reg_val_adc1[site] << 8) | (reg_val_adc0[site])       -- RESULT 10bits
        ireg_val_rst[site]  = integer(reg_val_rst[site])
      
        V_adc_vdd_div2[site] = (float(ireg_val_rst[site])/1023.0) * (VREF/(2.0^ADC_REFSCL)) * (DIV*(2.0^Adc_scale))
  
    end_for
    
    RegWrite(SER_ID, 16#0502, 1, 16#00, 16#00, "SER_UART_Write")	-- Open Input Multiplexer
     wait(3ms)   -- not to short vdd with tmon next test  



--*********** TMON testing ************
  -- Register Control Conversion Process
  
    RegWrite(SER_ID, 16#0501, 1, 16#B8, 16#B8, "SER_UART_Write")	  -- Program input channel tmon, enable ADC clock and Normal scales       
    RegWrite(SER_ID, 16#0502, 1, 16#01, 16#01, "SER_UART_Write")	  -- Enable channel multiplexer with divide by 1          

  
  -- step 5, Set channel limits as needed here
--   RegWrite(SER_ID, 16#0330, 1, 16#00, 16#00, "SER_UART_Write")	-- 
--   RegWrite(SER_ID, 16#03F3, 1, 16#00, 16#00, "SER_UART_Write")	-- 
--   RegWrite(SER_ID, 16#02C7, 1, 16#81, 16#81, "SER_UART_Write")	-- 
--   RegWrite(SER_ID, 16#02CD, 1, 16#81, 16#81, "SER_UART_Write")	-- 
--   RegWrite(SER_ID, 16#02D0, 1, 16#91, 16#91, "SER_UART_Write")	-- 

  --RegWrite(SER_ID, 16#5, 1, 16#00, 16#00, "SER_UART_Write")	        -- disable LOCK and ERROR outs, needed.
  --might need to disable LMN internal circuits here  
  --RegWrite(SER_ID, 16#050C, 1, 16#01, 16#01, "SER_UART_Write")	-- Enable ADC Done interrupt
  --RegRead(SER_ID, 16#0510, 1, upperword, lowword,"SER_UART_Read")	-- Read to Clear ADC interrupt
  --RegRead(SER_ID, 16#0511, 1, upperword, lowword,"SER_UART_Read")	-- Read to Clear ADC interrupt
  --RegRead(SER_ID, 16#0512, 1, upperword, lowword,"SER_UART_Read")	-- Read to Clear ADC interrupt
        

    wait(1ms)  
     RegWrite(SER_ID, 16#0500, 1, 16#1F, 16#1F, "SER_UART_Write")	        -- Start ADC conversion, Register bit 0 is self clearing for next rev
    wait(adc_dly)    -- needed but need to check later
    RegWrite(SER_ID, 16#0500, 1, 16#1E, 16#1E, "SER_UART_Write")	        -- needed for this rev(MPW3), but not next rev***

    reg_val_adc0 = 0
    reg_val_adc1 = 0
    reg_val      = 0
    DIV          = 1.0
    VREF         = 1.22
    Adc_scale    = 0.0
    ADC_REFSCL   = 0.0  

    RegRead(SER_ID, 16#0508, 1, upperword, lowword,"SER_UART_Read")	-- Read ADC_DATA0.adc_datal[7:0], 8 bits		
    for idx = 1 to sites do
        site = active_sites[idx]
        reg_val_adc0[site]  = lowword[site]       
    end_for 	
	
    RegRead(SER_ID, 16#0509, 1, upperword, lowword,"SER_UART_Read")	-- Read ADC_DATA1.adc_datah[1:0], 2 bits
    for idx = 1 to sites do
        site = active_sites[idx]
        reg_val_adc1[site]  = lowword[site]      
    end_for

    for idx = 1 to sites do
        site = active_sites[idx]      
        reg_val_rst[site]   = (reg_val_adc1[site] << 8) | (reg_val_adc0[site])       -- RESULT 10bits
        ireg_val_rst[site]  = integer(reg_val_rst[site])
      
        V_adc_tmon[site] = (float(ireg_val_rst[site])/1023.0) * (VREF/(2.0^ADC_REFSCL)) * (DIV*(2.0^Adc_scale))
  
    end_for
    
    RegWrite(SER_ID, 16#0502, 1, 16#00, 16#00, "SER_UART_Write")	-- Open Input Multiplexer
    wait(3ms)   



--need to set SER_RSVD here to 0V using HVVI
   set hvvi chan SER_RSVD irange to r50ma iclamps percent to imax 100.0 imin 100.0
   set hvvi chan SER_RSVD to fv 0V max r5v 
   gate hvvi chan SER_RSVD on    --off hiz 
   connect hvvi chan SER_RSVD remote
   --disconnect hvvi chan SER_RSVD
   wait(1ms)

   set hvvi chan SER_RSVD to fv ext_Vref max r5v   -- Set external VREF for ADC here !!!   
   wait(3ms)
   -- measure RSVD current here if needed after changing irange to smaller range
   --measure hvvi on chan SER_RSVD for 20 samples  every 10us into values   
   --wait(3ms)


--*********** TMON testing using RSVD pin as external VREF ************
  -- Register Control Conversion Process
    RegWrite(SER_ID, 16#11, 1, 16#4F, 16#4F, "SER_UART_Write")	  -- needed, not working if don't write this reg **
    
    RegWrite(SER_ID, 16#0500, 1, 16#16, 16#16, "SER_UART_Write")	  -- adc ref buffer off(bit 3), others on **
     
    RegWrite(SER_ID, 16#0501, 1, 16#B8, 16#B8, "SER_UART_Write")	  -- Program input channel tmon, enable ADC clock and Normal scales       
    RegWrite(SER_ID, 16#0502, 1, 16#03, 16#03, "SER_UART_Write")	  -- Enable channel multiplexer with divide by 1 and using external Vref          

  
  -- step 5, Set channel limits as needed here
--   RegWrite(SER_ID, 16#0330, 1, 16#00, 16#00, "SER_UART_Write")	-- 
--   RegWrite(SER_ID, 16#03F3, 1, 16#00, 16#00, "SER_UART_Write")	-- 
--   RegWrite(SER_ID, 16#02C7, 1, 16#81, 16#81, "SER_UART_Write")	-- 
--   RegWrite(SER_ID, 16#02CD, 1, 16#81, 16#81, "SER_UART_Write")	-- 
--   RegWrite(SER_ID, 16#02D0, 1, 16#91, 16#91, "SER_UART_Write")	-- 

  --RegWrite(SER_ID, 16#5, 1, 16#00, 16#00, "SER_UART_Write")	        -- disable LOCK and ERROR outs, needed.
  --might need to disable LMN internal circuits here  
  --RegWrite(SER_ID, 16#050C, 1, 16#01, 16#01, "SER_UART_Write")	-- Enable ADC Done interrupt
  --RegRead(SER_ID, 16#0510, 1, upperword, lowword,"SER_UART_Read")	-- Read to Clear ADC interrupt
  --RegRead(SER_ID, 16#0511, 1, upperword, lowword,"SER_UART_Read")	-- Read to Clear ADC interrupt
  --RegRead(SER_ID, 16#0512, 1, upperword, lowword,"SER_UART_Read")	-- Read to Clear ADC interrupt
        

    wait(1ms)  
    RegWrite(SER_ID, 16#0500, 1, 16#17, 16#17, "SER_UART_Write")	        -- Start ADC conversion, Register bit 0 is self clearing for next rev
    wait(adc_dly)    -- needed but need to check later
    RegWrite(SER_ID, 16#0500, 1, 16#16, 16#16, "SER_UART_Write")	        -- needed for this rev(MPW3), but not next rev***

    reg_val_adc0 = 0
    reg_val_adc1 = 0
    reg_val      = 0
    DIV          = 1.0
    VREF         = ext_Vref
    Adc_scale    = 0.0
    ADC_REFSCL   = 0.0  

    RegRead(SER_ID, 16#0508, 1, upperword, lowword,"SER_UART_Read")	-- Read ADC_DATA0.adc_datal[7:0], 8 bits		
    for idx = 1 to sites do
        site = active_sites[idx]
        reg_val_adc0[site]  = lowword[site]       
    end_for 	
	
    RegRead(SER_ID, 16#0509, 1, upperword, lowword,"SER_UART_Read")	-- Read ADC_DATA1.adc_datah[1:0], 2 bits
    for idx = 1 to sites do
        site = active_sites[idx]
        reg_val_adc1[site]  = lowword[site]      
    end_for

    for idx = 1 to sites do
        site = active_sites[idx]      
        reg_val_rst[site]   = (reg_val_adc1[site] << 8) | (reg_val_adc0[site])       -- RESULT 10bits
        ireg_val_rst[site]  = integer(reg_val_rst[site])
      
        V_adc_tmon_ext[site] = (float(ireg_val_rst[site])/1023.0) * (VREF/(2.0^ADC_REFSCL)) * (DIV*(2.0^Adc_scale))
  
    end_for
    
    RegWrite(SER_ID, 16#0502, 1, 16#00, 16#00, "SER_UART_Write")	-- Open Input Multiplexer
    wait(3ms)   




     

  RegWrite(SER_ID, 16#0502, 1, 16#00, 16#00, "SER_UART_Write")	-- Open Input Multiplexer

  -- Power ADC down
  RegWrite(SER_ID, 16#0500, 1, 16#00, 16#00, "SER_UART_Write")	-- Power down ADC



-- disconnect digital ppmu   SER_GPIO0_MS_LOCK + SER_GPIO1_LFLTB_ERRB + SER_GPIO2_GPO_SCLK from fv 0.0V vmax 4V measure i max 2mA
   connect digital pin SER_GPIO0_MS_LOCK + SER_GPIO1_LFLTB_ERRB + SER_GPIO2_GPO_SCLK to dcl
   set hvvi chan SER_RSVD to fv 0V max r5v 
   disconnect hvvi chan SER_RSVD  
   wait(1ms)

----Power down
 
   
    powerdown_device(POWERDOWN)
    wait(4ms)     
    


   -- turn off MIPI clocks from DES
   -- fpga_UART_Write("FPGA1","DNUT", DESA_ID, 16#0330, 1, 0x04)            
   -- reg_val23  = fpga_UART_Read("FPGA1", "DNUT", DESA_ID, 0x0330, 1)
   -- loop back relays on LB opened
   -- fpga_cbit_control("FPGA1", 2#0000)      -- control FPGA cbits 2#0000  (cb4, cb3, cb2, cb1)   


      

    test_value ireg_val  with devid_it 
    test_value ireg_val0 with dnutid_it
    test_value ireg_val1 with ser_lock_it
    test_value ireg_val15 with des_lock_it        
    test_value V_adc_gpio0_div1  with gpio0_div1
    test_value V_adc_gpio0_div2  with gpio0_div2 
    test_value V_adc_gpio0_div3  with gpio0_div3
    test_value V_adc_gpio0_div4  with gpio0_div4
    test_value V_adc_gpio1_div1  with gpio1_div1
    test_value V_adc_gpio1_div2  with gpio1_div2 
    test_value V_adc_gpio1_div3  with gpio1_div3
    test_value V_adc_gpio1_div4  with gpio1_div4
    test_value V_adc_gpio2_div1  with gpio2_div1
    test_value V_adc_gpio2_div2  with gpio2_div2 
    test_value V_adc_gpio2_div3  with gpio2_div3
    test_value V_adc_gpio2_div4  with gpio2_div4 
     
    test_value V_adc_vddio_div4  with vddio_div4  
    test_value V_adc_vdd18_div2  with vdd18_div2  
    test_value V_adc_vdd_div2    with vdd_div2  
    test_value V_adc_tmon        with tmon  
    test_value V_adc_tmon_ext    with tmon_ext  
      
    
         
 end_body

        

procedure Scan_Test_mipi_mpw3(vcore, vio, v18, vscan_core, MIPIscan1_bt, MIPIscan2_bt, MIPIscan3_bt, MIPIscan4_bt, MIPIscan1_tdf_bt, MIPIscan2_tdf_bt, MIPIscan3_tdf_bt, MIPIscan4_tdf_bt, DPll_TDF, DPLL_SBF, DPLL_SAF, DPLL_DBF, DPll_TDF2, DPLL_SBF2, DPLL_SAF2, DPLL_DBF2, POWERUP,POWERDOWN)
--------------------------------------------------------------------------------
--  
in boolean              : POWERUP,POWERDOWN
in float                : vcore, vio, v18, vscan_core
--in_out integer_test     : devid_it
in_out boolean_test     : MIPIscan1_bt                --mipi test mode 4
in_out boolean_test     : MIPIscan2_bt               --mipi test mode 5
in_out boolean_test     : MIPIscan3_bt               --mipi test mode 6
in_out boolean_test     : MIPIscan4_bt               --mipi test mode 7
in_out boolean_test     : MIPIscan1_tdf_bt                --mipi test mode 4
in_out boolean_test     : MIPIscan2_tdf_bt               --mipi test mode 5
in_out boolean_test     : MIPIscan3_tdf_bt               --mipi test mode 6
in_out boolean_test     : MIPIscan4_tdf_bt               --mipi test mode 7
in_out boolean_test     : DPll_TDF                   --dpll test mode 1
in_out boolean_test     : DPLL_SBF                   --dpll test mode 1
in_out boolean_test     : DPLL_SAF                   --dpll test mode 1
in_out boolean_test     : DPLL_DBF                   --dpll test mode 1
in_out boolean_test     : DPll_TDF2                   --dpll test mode 2
in_out boolean_test     : DPLL_SBF2                   --dpll test mode 2
in_out boolean_test     : DPLL_SAF2                   --dpll test mode 2
in_out boolean_test     : DPLL_DBF2                   --dpll test mode 2

local
    word list[16]       :  active_sites
    word                :  sites, idx, site

    multisite word      :  reg_read
    multisite lword     :  lowword, upperword, scan1_count, scan2_count, scan3_count, scan4_count, scan5_count, scan6_count
    
    float               :  Vconf0, Vconf1
    integer             :  idxs    
    multisite integer   : reg_val, reg_val0, reg_val1 


end_local

body

    get_expr("TestProgData.Device", DEVICE)  

    active_sites = get_active_sites
    sites = word(len(active_sites))  


----Dut power up function
--   DutPowerUp(Vddio, Vdd18, Vdd, "UART", "TP_GMSL2",POWERUP)

   DutPowerUp(vio, v18, vcore, "UART", "TP_GMSL2",POWERUP)
   RegRead(SER_ID, 16#00, 1, upperword, lowword,"SER_UART_Read")

----------- Enter TestMode 12 for SCAN mipi rx and DPLL test -----------------

  SetTestMode(12, False, "SER_UART_Write")


--DE request that SER_VDD to <= 1.05V for Scan tests to turn off internal regulator here !!!!!! 

  set hcovi SER_VDD to fv vscan_core    vmax 2V clamp imax 600mA imin -600mA
  vdd_global[2] = vscan_core 
  wait(1ms)   -- trial for 47uF cap on SER_VDD 10ms
  
  set digital pin SER_GPO4_CFG0 + SER_GPO5_CFG1 levels to vil 0V vih vio vol (vio/2.0)  voh ((vio/2.0)) iol 2mA ioh -2mA vref vio    
--  set digital pin SER_GPO4_CFG0 + SER_GPO5_CFG1 modes to comparator enable all fails
  set digital pin SER_GPO4_CFG0 modes to comparator enable all fails
  wait(500us)


----For now comment these MIPI RX test out so we can test DPLL pattern. Need talked to Mu 12/2017
-- 
-- MIPI RX tests 

-- saf
 --   
--   read digital clock msdi period t0 into T0 error into E1 for  "Scan_TS"
--   set digital clock msdi period t0 to 20ns  for "Scan_TS"




-----Need to program CMU4 register 0x304 to 0x00 otherwise has to run slower clock <25MHz at vddio =1.7. Mt 6/2018.
----This only happen to production rev devices------
---    RegRead(SER_ID, 16#0304, 1, upperword, lowword,"SER_UART_Read")
    RegWrite(SER_ID,SR_CMU4 , 1, 16#00, 16#00, "SER_UART_Write")     
    RegWrite(SER_ID, 16#3E, 1, 16#04, 16#04, "SER_UART_Write")     -- DEBUG_MODE=4  
--    wait(1ms)    
      execute digital pattern "hs89_dphy_saf" run to end wait with  MIPIscan1_bt     
    
    RegWrite(SER_ID, 16#3E, 1, 16#05, 16#05, "SER_UART_Write")     -- DEBUG_MODE=5  
--    wait(1ms)    
    execute digital pattern "hs89_dphy_saf" run to end wait with  MIPIscan2_bt 
    RegWrite(SER_ID, 16#3E, 1, 16#06, 16#06, "SER_UART_Write")     -- DEBUG_MODE=6  
--    wait(1ms)    
    execute digital pattern "hs89_dphy_saf" run to end wait with  MIPIscan3_bt 
    RegWrite(SER_ID, 16#3E, 1, 16#07, 16#07, "SER_UART_Write")     -- DEBUG_MODE=7  
--    wait(1ms)    
    execute digital pattern "hs89_dphy_saf" run to end wait with  MIPIscan4_bt 
    
-- tdf
       
    RegWrite(SER_ID, 16#3E, 1, 16#04, 16#04, "SER_UART_Write")     -- DEBUG_MODE=4  
--    wait(1ms)    
    execute digital pattern "hs89_dphy_tdf" run to end wait with  MIPIscan1_tdf_bt     
    RegWrite(SER_ID, 16#3E, 1, 16#05, 16#05, "SER_UART_Write")     -- DEBUG_MODE=5  
--    wait(1ms)    
    execute digital pattern "hs89_dphy_tdf" run to end wait with  MIPIscan2_tdf_bt 
    RegWrite(SER_ID, 16#3E, 1, 16#06, 16#06, "SER_UART_Write")     -- DEBUG_MODE=6  
--    wait(1ms)    
    execute digital pattern "hs89_dphy_tdf" run to end wait with  MIPIscan3_tdf_bt 
    RegWrite(SER_ID, 16#3E, 1, 16#07, 16#07, "SER_UART_Write")     -- DEBUG_MODE=7  
--    wait(1ms)    
    execute digital pattern "hs89_dphy_tdf" run to end wait with  MIPIscan4_tdf_bt 


-- 
--------------------------------To here

------------------------
     RegWrite(SER_ID, SR_CTRL0, 1, 16#00, 16#21, "SER_UART_Write") ------    Requested by Levent for MPW5 12/2017. Set RESET_ONESHOT to 1;Auto_Link to 0 and LINK_CFG to 1

-- DPLL tests     
    RegWrite(SER_ID, 16#3E, 1, 16#00, 16#01, "SER_UART_Write")     -- DEBUG_MODE=1  
 --   wait(1ms)  

    execute digital pattern "hs89_dpll_wrapper_tdf" run to end wait with  DPll_TDF     
    execute digital pattern "hs89_dpll_wrapper_sbf" run to end wait with  DPLL_SBF 
    execute digital pattern "hs89_dpll_wrapper_saf" run to end wait with  DPLL_SAF 

--           
-- --per Chandra, no need to test dbf b/c of low test coverage and high test time     
----    execute digital pattern "hs89_dpll_wrapper_dbf" run to end wait with   DPLL_DBF  --only pass <48Mhz from PA       
 

    RegWrite(SER_ID, 16#3E, 1, 16#00, 16#02, "SER_UART_Write")     -- DEBUG_MODE=2  
    execute digital pattern "hs89_dpll_wrapper_tdf" run to end wait with  DPll_TDF2     
    execute digital pattern "hs89_dpll_wrapper_sbf" run to end wait with  DPLL_SBF2 
    execute digital pattern "hs89_dpll_wrapper_saf" run to end wait with  DPLL_SAF2 

--           
-- --per Chandra, no need to test dbf b/c of low test coverage and high test time     
----    execute digital pattern "hs89_dpll_wrapper_dbf" run to end wait with   DPLL_DBF  --only pass <48Mhz from PA       


------ Power Off ----
--   set digital pin ALL_PATTERN_PINS levels to vil 0V vih 200mV iol 0uA ioh 0uA vref 0V
--   wait(100us)
  
      set digital pin ALL_PATTERN_PINS modes to comparator enable all fails
      powerdown_device(POWERDOWN)
--   set hcovi SER_VDD+SER_VDDIO +SER_VDD18 to fv 0V vmax 4V clamp imax 600mA imin -600mA   
-- 
--   wait(3ms) 
--   wait(3ms)     -- extra for 47uF cap on SER_VDD    
--   -- Initialize for set_SER_Voltages(vio, vcore, v18) routine
--   vdd_global[1] = 0V   --SER_VDDIO
--   vdd_global[2] = 0V   --SER_VDD  
--   vdd_global[3] = 0V   --SER_VDDA(VDD18)




end_body

procedure ABUS_tests(vcore, vio, v18, PwrBlk_Lim , GmslBlk_Lim , BiasBlk_Lim , AudBlk_Lim ,  VidBlk_Lim , CSI_Blk_Lim , CharTstLim,POWERUP,POWERDOWN,Repop_A,Repon_A,DelRepA ,Repop_B,Repon_B,DelRepB)
--------------------------------------------------------------------------------
--  DESCRIPTION
--  Measure ABUS test points using PPMU.
--
--
--  PASS PARAMETERS:
--  Vdd                 -- VDD supply level
--  Vddio               -- VDDIO supply level
--  Vdd18               -- VDD18 supply level
--  PwrBlk_Lim          -- Power Block test limits
--  GmslBlk_Lim         -- GMSL2 Block test limits
--  AudBlk_Lim          -- AUDPLL Block test limits
--  VidBlk_Lim          -- VIDPLL Block test limits
--  CharTstLim          -- Characterization test limits  

in boolean          : POWERUP,POWERDOWN
in float                : vcore, vio, v18

--in_out float_test     : adc_abus2, adc_abus0

in_out array of float_test  : PwrBlk_Lim, GmslBlk_Lim , AudBlk_Lim , VidBlk_Lim , CharTstLim, BiasBlk_Lim, CSI_Blk_Lim
in_out float_test     :Repop_A,Repon_A,DelRepA ,Repop_B,Repon_B,DelRepB

local
    word list[16]       :  active_sites
    word                :  sites, idx, site

    multisite word      :  reg_read
    multisite lword     :  lowword, upperword
    float               :  Vconf0, Vconf1
    integer             :  idxs    
    multisite integer   :  reg_val, reg_val0, reg_val1 
    
    boolean                 : CHAR
    multisite float         : meas_v[4]         -- ABUS3 = [1], ABUS0 = [2], ABUS2 = [3], ABUS1 = [4]
    multisite float         : meas_i, delta
    multisite float         : meas_v3[3] , meas_v1 , RepopA,ReponA, RepopB,ReponB, RepDeltaA,RepDeltaB
    multisite float         : TdiodeMeas , TvssMeas , TdiodeTemp , TmonMeas , TmonTemp 
    multisite float         : dlog0[7] , dlog2[4], dlog4[1], dlog5[1], dlog1[2], dlog_csi[8]
    multisite float         : char_dlog[20], char_bias_abus[14], char_power_abus[14]
    
    pin                     : abus0, abus1, abus2, abus3
    
end_local

const
    TdiodeOffset    = 1.5794
    TdiodeSlope     =  -0.00335456-----------  -0.0027
    TmonOffset      = 0.78561
    TmonSlope       = 0.00250
end_const


body

    --****** Pin map ******
    ------------------Index
    -- ABUS0    MFP0    2
    -- ABUS1    MFP1    4
    -- ABUS2    MFP5    3
    -- ABUS3    MFP6    1
    abus0 = SER_GPO5_CFG1[1]                       --------SER_PCLKIN_MFP0[1]
    abus1 = SER_GPO4_CFG0[1]                         --------SER_CONF0_MFP1[1]
    abus2 = SER_GPIO3_RCLKOUT[1]                      -------SER_DIN02_LMN0_MFP5[1]
    abus3 = SER_GPO6_CFG2[1]                                      --------SER_DIN03_LMN1_MFP6[1]   
    
    get_expr("TestProgData.Device", DEVICE)
    get_expr("OpVar_Char", CHAR)
--    CHAR=TRUE      

    active_sites = get_active_sites
    sites = word(len(active_sites))
      
        disconnect hvvi chan SER_RSVD    -- need to float RSVD, important!!


-----Dut power up function
   DutPowerUp(vio, v18, vcore, "UART", "TP_GMSL2",POWERUP)------------- DutPowerUp(vio, v18, vcore, "UART", "TP_GMSL1",POWERUP)
---for debug checking read write ok
--    RegRead(SER_ID, 16#00, 1, upperword, lowword,"SER_UART_Read")     -- device ID, to make sure we test the correct device, to comply with check list
-------
    
 -------------SER_DIN03_LMN1_MFP6+SER_PCLKIN_MFP0+SER_DIN02_LMN0_MFP5+SER_CONF0_MFP      
   -- Setup MFP/ABUS pins to FVMI (pre-charge to 0V)    
      
   disconnect digital pin ABUS_DP_pl  from dcl
   connect digital ppmu ABUS_DP_pl  to fv 0V vmax 2V measure i max 2mA                    ------abus0 + abus1 + abus2 + abus3
  
     
------------ Enter TestMode 11 for test -----------------
    SetTestMode( 11 , False , "SER_UART_Write" )

    RegWrite(SER_ID, SR_TEST0, 1, 0x00, 0x00, "SER_UART_Write")     -- abus_power_page = 0x00,  HIZ
    wait(1ms)



-- *****************************************************
    -- Measure VDDD and VDDA
    -- Power ABUS Block (0) - ABUS Page 9
    -- *****************************************************
    --RegWrite(SER_ID, 0x3E, 1, 0x09, 0x09, "SER_UART_Write")     
    --wait(1ms)
 
    meas_v = meas_ABUS_SE_V ( 1ms , 0x09 )
    -- Set test mode
--     set digital ppmu ABUS_DP_pl to fi 0.001uA measure v max 2V            ---4
--   RegWrite(SER_ID, SR_TEST0, 1, 0x00, 0x9, "SER_UART_Write")      -- abus_blk = #, abus_page = #    SR_TEST0 = 0x3E
--  measure digital ppmu ABUS_DP_pl voltage average 20 delay 10us into meas_v
--         set hcovi SER_VDD  to fv 1.145 vmax 2.0V measure i max 600ma clamp imax 900mA imin -900mA

    scatter_1d( gather_1d(meas_v, 1) , dlog0 , 3 )          -- VDDD_sw, ABUS0? no need to test but test it anyway
        
    if CHAR then
        scatter_1d( gather_1d(meas_v, 3) , char_dlog , 1 )  -- VDDA_sw, ABUS2
        scatter_1d( gather_1d(meas_v, 3) , char_power_abus , 1 )  -- VDDA_sw, ABUS2
    end_if

    -- *****************************************************
    -- Measure vbgtst, v1p2_obsv and v0p6_obsv
    -- Power ABUS Block (0) - ABUS Page 4
    -- *****************************************************
    
--    meas_v = meas_ABUS_SE_V ( 1ms , 0x04 )
    meas_v = meas_ABUS_SE_V_Vbg( 1ms , 0x04,v18,vcore )-----Some parts failed Vbg at Vmax with Hot Option. Reduce supplies would fix it MT 1/2020

    scatter_1d( gather_1d(meas_v, 3) , dlog0 , 1 )       -- v1p2_obsv
    scatter_1d( gather_1d(meas_v, 2) , dlog0 , 2 )       -- vbgtst

    if CHAR then
        scatter_1d( gather_1d(meas_v, 4) , char_dlog , 2 )   -- v0p6_obsv
        scatter_1d( gather_1d(meas_v, 4) , char_power_abus , 2 )   -- v0p6_obsv
    end_if

    if CHAR then

        -- *****************************************************
        -- Measure VDD18_OTP_sw 
        -- Power ABUS Block (0) - ABUS Page 10
        -- *****************************************************

        meas_v = meas_ABUS_SE_V ( 1ms , 0x0A )
        scatter_1d( gather_1d(meas_v, 3) , char_dlog , 3 )         -- VDD18_OTP_sw
        scatter_1d( gather_1d(meas_v, 3) , char_power_abus , 3 )   -- VDD18_OTP_sw

        -- *****************************************************
        -- Measure VDD18_DPLL_sw 
        -- Power ABUS Block (0) - ABUS Page 11
        -- *****************************************************

        meas_v = meas_ABUS_SE_V ( 1ms , 0x0B )
        scatter_1d( gather_1d(meas_v, 3) , char_dlog , 4 )         -- VDD18_sw
        scatter_1d( gather_1d(meas_v, 3) , char_power_abus , 4 )   -- VDD18_sw
        -- *****************************************************
        -- Measure VDD18_PA_sw  and VDD18_PB_sw
        -- Power ABUS Block (0) - ABUS Page 12
        ----Need to turn on PHY TX power by program bit 0 of RLMS48 to 1 for both a and b  for MPW5( Bill L 1/2018)
        -- *****************************************************
        RegWrite(SER_ID, SR_RLMS48_A, 1,0x00, 0x01, "SER_UART_Write")
        RegWrite(SER_ID, SR_RLMS48_B, 1,0x00, 0x01, "SER_UART_Write")
        meas_v = meas_ABUS_SE_V ( 1ms , 0x0C )
        scatter_1d( gather_1d(meas_v, 3) , char_dlog , 5 )    -- VDD18_PA_sw
        scatter_1d( gather_1d(meas_v, 2) , char_dlog , 6 )    -- VDD18_PB_sw
        scatter_1d( gather_1d(meas_v, 3) , char_power_abus , 5 )   -- VDD18_PA_sw
        scatter_1d( gather_1d(meas_v, 2) , char_power_abus , 6 )   -- VDD18_PB_sw     
        
    end_if

    -- *****************************************************
    -- MeasureTMON and TDIODE
    -- Power ABUS Block (0) - ABUS Page 15
    -- *****************************************************

    meas_v = meas_ABUS_SE_V ( 1ms , 0x0F )
--meas_v = meas_ABUS_SE_V ( 1ms , 0x0F )
    TvssMeas    = gather_1d(meas_v, 2)
    TdiodeMeas  = gather_1d(meas_v, 4) - TvssMeas   -- Since we are using two different resources to measure the voltage on a kelvin connection we need to take the difference
    TmonMeas    = gather_1d(meas_v, 1) - TvssMeas   -- Since we are using two different resources to measure the voltage on a kelvin connection we need to take the difference

    TdiodeTemp  = ((TdiodeMeas/TdiodeSlope) - (TdiodeOffset/TdiodeSlope))
--    TmonTemp    = ((TmonMeas/TmonSlope) - (TmonOffset/TmonSlope))
TmonTemp    = 313.1*TmonMeas -229.1                     ----MT 3/2018
    scatter_1d( TdiodeMeas , dlog0 , 4 )
    scatter_1d( TmonMeas   , dlog0 , 5 )
    scatter_1d( TdiodeTemp , dlog0 , 6 )
    scatter_1d( TmonTemp   , dlog0 , 7 )
    
    -- ABUS0    MFP1    2
    -- ABUS1    MFP3    4
    -- ABUS2    MFP2    3
    -- ABUS3    MFP0    1


    -- *****************************************************
    -- Measure VREG_VCO , VREG_PDDDIV
    -- GMSL2c Block (1) - ABUS Page 1  Measure Vdd_Vco
    -- GMSL2c Block (2) - ABUS Page 2  Measure VREG_VCO , VREG_PDDDIV and VDD18_XTAL
    -- *****************************************************
    
    meas_v = meas_ABUS_SE_V ( 1ms , 0x21 )                  ----measure Vdd_Vco
    scatter_1d( gather_1d(meas_v, 1) , dlog2 , 1 )          ----------HS89 failed this measure about 0v
    meas_v = meas_ABUS_SE_V ( 1ms , 0x22 )                                      

    scatter_1d( gather_1d(meas_v, 4) , dlog2 , 2 )         ---VREG_VCO  
    scatter_1d( gather_1d(meas_v, 2) , dlog2 , 3 )         ---VREG_PDDDIV      
    scatter_1d( gather_1d(meas_v, 1) , dlog2 , 4 )         ---VDD18_XTAL  

    -- ******************************************************************************
    -- Measure I40_1U , vbg_1u , vbg_1u_senseN , vbg_1u_senseP , vbg_1u_differntial
    -- BIAS Block (1) - ABUS Page 4
    -- ******************************************************************************

    set digital ppmu abus3 to fv 0V measure i max 200uA   -- Measure ABUS3

    -- Set test mode
    RegWrite( SER_ID , SR_TEST0, 1 , 0x00 , 0x14 , "SER_UART_Write" )    -- abus_blk = #, abus_page = #
    wait(1ms)

    measure digital ppmu abus3 current imax 200uA average 10 into meas_i
    meas_i = meas_i * -1.0  -- change sign
    scatter_1d(meas_i , dlog1 , 1)                          -- I40_1U   ABUS 3
    if CHAR then
        ---Per Umut, we need to short Abus3 to abus2 since HW does not capable to short them. I simulate by drawing 40uA from Abus2. Data are Ok and Umut approved it. 9/2018        
        set digital ppmu SER_GPIO3_RCLKOUT to fi meas_i measure v max 4V  ---Per Umut, we need to short Abus3 to abus2 since HW does not capable to short them. 
        set digital ppmu SER_GPO5_CFG1+SER_GPO4_CFG0 to fi 0uA measure v max 4V    ---- Abus0,Abus1

--        set digital ppmu SER_GPO5_CFG1 + SER_GPO4_CFG0 + SER_GPIO3_RCLKOUT to fi 40uA measure v max 4V
        wait(1ms)
        measure digital ppmu SER_GPO5_CFG1 + SER_GPO4_CFG0 + SER_GPIO3_RCLKOUT voltage vmax 2V average into meas_v3

        delta = gather_1d(meas_v3 ,1) - gather_1d(meas_v3 ,2)
        scatter_1d(gather_1d(meas_v3 ,3), char_dlog , 7)    -- vbg_1u   ABUS 2
        scatter_1d(gather_1d(meas_v3 ,2), char_dlog , 8)    -- vbg_1u_senseN    ABUS 1
        scatter_1d(gather_1d(meas_v3 ,1), char_dlog , 9)    -- vbg_1u_senseP    ABUS 0
        scatter_1d(delta, char_dlog , 10)                   -- vbg_1u_differential
---Put in char_bias_abus[12]
        scatter_1d(gather_1d(meas_v3 ,3), char_bias_abus , 1)    -- vbg_1u   ABUS 2 
        scatter_1d(gather_1d(meas_v3 ,2), char_bias_abus , 2)     -- vbg_1u_senseN   ABUS 1
        scatter_1d(gather_1d(meas_v3 ,1), char_bias_abus , 3)    -- vbg_1u_senseP    ABUS 0 
        scatter_1d(delta,  char_bias_abus , 4)                       -- vbg_1u_differential
    end_if

    set digital ppmu ABUS_DP_pl to fi 0mA measure v max 4V

    -- ******************************************************************************
    -- Measure I40_3U , vbg_3u , vbg_3u_senseN , vbg_3u_senseP , vbg_3u_differntial
    -- BIAS Block (1) - ABUS Page 5
    -- ******************************************************************************

    set digital ppmu abus3  to fv 0V measure i max 200uA     --  ABUS3

    -- Set test mode
    RegWrite( SER_ID , SR_TEST0 , 1 , 0x00 , 0x15 , "SER_UART_Write" )    -- abus_blk = #, abus_page = #
    wait(1ms)

    measure digital ppmu abus3 current imax 200uA average 10 into meas_i
    meas_i = meas_i * -1.0  -- change sign
    scatter_1d(meas_i , dlog1 , 2)                      -- I40_3U   ABUS 3

    if CHAR then
        ---Per Umut, we need to short Abus3 to abus2 since HW does not capable to short them. I simulate by drawing 40uA from Abus2. Data are Ok and Umut approved it. 9/2018        
        set digital ppmu SER_GPIO3_RCLKOUT to fi  meas_i  measure v max 4V  ---Per Umut, we need to short Abus3 to abus2 since HW does not capable to short them. 
        set digital ppmu SER_GPO5_CFG1+SER_GPO4_CFG0 to fi 0uA measure v max 4V    ---- Abus0,Abus1
--        set digital ppmu SER_GPO5_CFG1+SER_GPIO3_RCLKOUT+SER_GPO4_CFG0 to fi 40uA measure v max 4V    ---- Abus0,Abus2,Abus1
        wait(1ms)
        measure digital ppmu  SER_GPO5_CFG1+SER_GPIO3_RCLKOUT+SER_GPO4_CFG0 voltage vmax 2V average into meas_v3

        delta = gather_1d(meas_v3 ,1) - gather_1d(meas_v3 ,3)
        scatter_1d(gather_1d(meas_v3 ,2), char_dlog , 11)   -- vbg_3u   ABUS 2
        scatter_1d(gather_1d(meas_v3 ,3), char_dlog , 12)   -- vbg_3u_senseN    ABUS 1
        scatter_1d(gather_1d(meas_v3 ,1), char_dlog , 13)   -- vbg_3u_senseP    ABUS 0
        scatter_1d(delta, char_dlog , 14)                   -- vbg_3u_differential
---Put in char_bias_abus[12]
        scatter_1d(gather_1d(meas_v3 ,2), char_bias_abus , 5)    -- vbg_3u  ABUS 2 
        scatter_1d(gather_1d(meas_v3 ,3), char_bias_abus , 6)     -- vbg_3u_senseN   ABUS 1
        scatter_1d(gather_1d(meas_v3 ,1), char_bias_abus , 7)    -- vbg_4u_senseP    ABUS 0 
        scatter_1d(delta,  char_bias_abus , 8)                       -- vbg_4u_differential
        set digital ppmu ABUS_DP_pl to fi 0mA measure v max 4V

        -- ******************************************************************************
        -- Measure i160u_dpll , i20u_rescal
        -- BIAS Block (1) - ABUS Page 2
        -- ******************************************************************************

        -- Set test mode
        RegWrite( SER_ID , SR_TEST0 , 1 , 0x00 , 0x12 , "SER_UART_Write" )    -- abus_blk = #, abus_page = #
        set digital ppmu abus2 to fv 0V   measure i max 200uA     -- Measure ABUS2
        set digital ppmu abus3 to fv 1.5V measure i max 200uA     -- Measure ABUS3
        wait(1ms)
    
        measure digital ppmu abus3 current imax 200uA average 10 into meas_i  --i160u_dpll ABUS3
        scatter_1d(meas_i , char_dlog , 15)
        scatter_1d(meas_i , char_bias_abus , 9 )                                --i160u_dpll ABUS3
        measure digital ppmu abus2 current imax 200uA average 10 into meas_i           --i20u_rescal ABUS2
        meas_i = meas_i * -1.0      -- change sign
        scatter_1d(meas_i , char_dlog , 16)
        scatter_1d(meas_i , char_bias_abus , 10 )                                --i20u_rescal ABUS2

--         measure digital ppmu abus1 voltage average 10 into meas_v1
--         scatter_1d(meas_v1 , char_dlog , 17)
-- 
--         measure digital ppmu abus0 voltage average 10 into meas_v1         ------VREG_RNG
       
        set digital ppmu ABUS_DP_pl to fi 0mA measure v max 4V

        -- ******************************************************************************
        -- Measure i80u_spc i80u_clbr cml_rescal_bot cml_res_cal_top
        -- BIAS Block (1) - ABUS Page 3
        -- ******************************************************************************

        -- Set test mode
        RegWrite( SER_ID , SR_TEST0 , 1 , 0x00 , 0x13 , "SER_UART_Write" )    -- abus_blk = #, abus_page = #
        set digital ppmu abus2  to fv vcore measure i max 200uA     -- Measure ABUS2
        set digital ppmu abus3 to fv vcore measure i max 200uA     -- Measure ABUS3
        wait(5ms)

        measure digital ppmu abus3 current imax 200uA average 10 into meas_i  --i80u_spc ABUS3
        scatter_1d(meas_i , char_dlog , 18)
        scatter_1d(meas_i , char_bias_abus , 11 )                             --i80u_spc ABUS3
        measure digital ppmu abus2 current imax 200uA average 10 into meas_i  --i80u_clbr ABUS2
        scatter_1d(meas_i , char_dlog , 19)
        scatter_1d(meas_i , char_bias_abus , 12 )                             --i80u_clbr ABUS2        
        
 -----per Bill Leake and Umut need to power up  RESCAL before measurement
----------------------------------        
        RegRead(SER_ID, SR_CTRL5, 1, upperword, lowword,"SER_UART_Read")   ----Read RESCAL value
        lowword = (lowword | 0x80)
        upperword = 0x0
        RegWriteMultisite( SER_ID ,SR_CTRL5  , 1 , lowword ,0 , upperword)    ----Create this base on opt_write function for multsite data write; lowword can be different site to site
-----------
        measure digital ppmu abus1 voltage average 10 into meas_v1            --cml_rescal_bot

        scatter_1d(meas_v1 , char_dlog , 17)        
        scatter_1d(meas_v1 , char_bias_abus , 13 )                             --cml_rescal_bot

        set digital ppmu abus0 to fi 0.1uA measure v max 4V
        wait(20mS)
        set digital ppmu abus0 to fi 0.0uA measure v max 4V 
        wait(5mS)
        measure digital ppmu abus0 voltage average 10 into meas_v1            --cml_rescal_top

        scatter_1d(meas_v1 , char_dlog , 17)        
        scatter_1d(meas_v1 , char_bias_abus , 14 )                             --cml_rescal_top
    end_if

    -- *****************************************************
    -- Measure VDD_VCO_AUDPLL
    -- AUDPLL Block (4) - ABUS Page 1
    -- *****************************************************

    meas_v = meas_ABUS_SE_V ( 1ms , 0x41 )
    scatter_1d( gather_1d(meas_v, 1) , dlog4 , 1 )
----Added to measure Replica
        set digital ppmu abus2  to fi 0.1uA measure v max 4V
        set digital ppmu abus3 to fi 0.1uA measure v max 4V
        wait(2mS)
--         set digital ppmu abus2 to fi 0.0uA measure v max 4V 
--         set digital ppmu abus3 to fi 0.0uA measure v max 4V
--         wait(5mS)
RegWrite( SER_ID , 0x06 , 1 , 0x00 , 0x8B , "SER_UART_Write" )   ---Disable RCLKen
RegWrite( SER_ID , 0x14A7 , 1 , 0x00 , 0xA1 , "SER_UART_Write" )  ---#Enable manual control
RegWrite( SER_ID , 0x01 , 1 , 0x00 , 0x18 , "SER_UART_Write" )  ---#disable remote control channel
RegWrite( SER_ID , 0x17 , 1 , 0x00 , 0xBD , "SER_UART_Write" )   -----# Set FW_CTRL_EN; Set_FW_PHY_EN; Set FW_LOCK
RegWrite( SER_ID , 0x1448 , 1 , 0x00 , 0x29 , "SER_UART_Write" ) -----# PHY A Force TxD High
RegWrite( SER_ID , 0x14C1 , 1 , 0x00 , 0x40 , "SER_UART_Write" )----# PHY A Replica Output to ABUS
RegWrite( SER_ID , 0x3E , 1 , 0x00 , 0x88 , "SER_UART_Write" )
        wait(1ms)
        measure digital ppmu abus3 voltage average 10 into RepopA   --     -- *****************************************************
        measure digital ppmu abus2 voltage average 10 into ReponA  
RegWrite( SER_ID , 0x3E , 1 , 0x00 , 0x00 , "SER_UART_Write" )
----PHY B
RegWrite( SER_ID , 0x1448 , 1 , 0x00 , 0x28 , "SER_UART_Write" )
RegWrite( SER_ID , 0x14C1 , 1 , 0x00 , 0x0 , "SER_UART_Write" )

RegWrite( SER_ID , 0x15A7 , 1 , 0x00 , 0xA1 , "SER_UART_Write" )
RegWrite( SER_ID , 0x17 , 1 , 0x00 , 0xDE , "SER_UART_Write" )
 RegWrite( SER_ID , 0x1548 , 1 , 0x00 , 0x29 , "SER_UART_Write" ) -----# PHY B Force TxD High
RegWrite( SER_ID , 0x15C1 , 1 , 0x00 , 0x40 , "SER_UART_Write" )----# PHY B Replica Output to ABUS
RegWrite( SER_ID , 0x3E , 1 , 0x00 , 0x98 , "SER_UART_Write" )
        wait(1ms)
        measure digital ppmu abus3 voltage average 10 into RepopB   --     -- *****************************************************
        measure digital ppmu abus2 voltage average 10 into ReponB  
    RepDeltaA = RepopA -ReponA 
    RepDeltaB = RepopB -ReponB     


wait(0)
--     -- *****************************************************
--     -- Measure VDD_VCO_AUDPLL
--     -- VIDPLL Block (5) - ABUS Page 1
--     -- *****************************************************
-- 
--     meas_v = meas_ABUS_SE_V ( 1ms , 0x51 )                                      ------No Test Man Tran. Did not specify in analog test mode. 
-- --    scatter_1d( gather_1d(meas_v, 4) , dlog5 , 1 )                          
--       dlog5  = 99.0                                                             -----Hardcode for now


----   NOT REQUIRED to test HS89 CSI PHY section base on HS9489)analog_test_modes-2.xlsx from Bill Leake 10/2017    
--     -- *****************************************************
--     -- Measure MIPI CSI2 PHY0
--     -- Power CSI PHY 0 Block (A) - ABUS Page 1
--     -- *****************************************************
-- 
--     meas_v = meas_ABUS_SE_V (1ms , 0xA1 )
--     scatter_1d( gather_1d(meas_v, 2) , dlog_csi , 1 )   --V_N_VDD18
--     scatter_1d( gather_1d(meas_v, 1) , dlog_csi , 2 )   --V_P_VDD18
-- 
--     -- *****************************************************
--     -- Measure MIPI CSI2 PHY1
--     -- Power CSI PHY 1 Block (B) - ABUS Page 1
--     -- *****************************************************
-- 
--     meas_v = meas_ABUS_SE_V ( 1ms , 0xB1 )
--     scatter_1d( gather_1d(meas_v, 2) , dlog_csi , 3 )   --V_N_VDD18
--     scatter_1d( gather_1d(meas_v, 1) , dlog_csi , 4 )   --V_P_VDD18
-- 
--     -- *****************************************************
--     -- Measure MIPI CSI2 PHY2
--     -- Power CSI PHY 2 Block (C) - ABUS Page 1
--     -- *****************************************************
-- 
--     meas_v = meas_ABUS_SE_V ( 1ms , 0xC1 )
--     scatter_1d( gather_1d(meas_v, 2) , dlog_csi , 5 )   --V_N_VDD18
--     scatter_1d( gather_1d(meas_v, 1) , dlog_csi , 6 )   --V_P_VDD18
-- 
--     -- *****************************************************
--     -- Measure MIPI CSI2 PHY3
--     -- Power CSI PHY 3 Block (D) - ABUS Page 1
--     -- *****************************************************
--     meas_v = meas_ABUS_SE_V ( 1ms , 0xD1 )
--     scatter_1d( gather_1d(meas_v, 2) , dlog_csi , 7 )   --V_N_VDD18
--     scatter_1d( gather_1d(meas_v, 1) , dlog_csi , 8 )   --V_P_VDD18
-- 
--   NOT REQUIRED to test above section base on HS9489)analog_test_modes-2.xlsx from Bill Leake 10/2017            
    disconnect digital pin ABUS_DP_pl from ppmu
    connect digital pin ABUS_DP_pl to dcl
  


------ Power Off ----
        powerdown_device(POWERDOWN)

    -- report results
    test_value dlog0 with PwrBlk_Lim
    test_value dlog2 with GmslBlk_Lim
    test_value dlog1 with BiasBlk_Lim
    test_value dlog4 with AudBlk_Lim
--    test_value dlog5 with VidBlk_Lim
--    test_value dlog_csi with CSI_Blk_Lim
    
    if CHAR then
        for i = 1 to 6 do
            scatter_1d( gather_1d(char_power_abus, i) , char_dlog , i )    -- power abus block char  
        end_for
        for i = 1 to 14 do
            scatter_1d( gather_1d(char_bias_abus, i) , char_dlog , i+ 6 )    --ibias abus block char  
        end_for    

        test_value char_dlog with CharTstLim
    end_if    
---Datalog Replica Test 11/2019 Repop_A,Repon_A,DelRepA ,Repop_B,Repon_B,DelRepB
    test_value RepopA    with Repop_A
    test_value ReponA    with Repon_A
    test_value RepDeltaA with  DelRepA
    test_value RepopB    with Repop_B
    test_value ReponB    with Repon_B
    test_value RepDeltaB with  DelRepB
  
end_body
procedure TEST_AbusDfeSlicer(Vdd, Vdd18, Vddio, Vterm, POWERUP,POWERDOWN, abus_lim)
--------------------------------------------------------------------------------------------------------------------------------
-- Measures the various Equalizer DACs via the ABUS
--  DFE1-DFE5, OSN, AGC, VTH, and Error Slicer
in float                                : Vdd, Vdd18, Vddio, Vterm
in_out array of float_test              : abus_lim
in boolean                              : POWERUP,POWERDOWN
--------------------------------------------------------------------------------------------------------------------------------
local
    multisite float                     : abus_dlog[128]
    multisite float                     : vmeas[4] , vdiff
    multisite word                      : Status
    multisite lword                     : fpga_write_data , ser_read_data , des_read_data
    word                                : CurSite, siteidx
    string[50]                          : dummy
    float                               : t0
    integer                             : b, sw
    boolean                             : CHAR = false
    integer                             : DEBUG = 0     -- 0:off; 1:show results; 2:show reg; 3:'fifo'-equivalent
    word                                : reg_offs[2] 
    lword                               : phy_block[2] , sweep[32]
    string[2]                           : bstr="AB"
end_local
body

    active_sites = get_active_sites()
    sites = word(len(active_sites))

    get_expr("OpVar_Char", CHAR)
    CHAR = TRUE
----Move this to on load later MT `0/2017
    gate vi16 chan ABUS_VI_PINS     off
    set  vi16 chan  ABUS_VI_PINS    to fi 0uA max 200uA measure v max 4V clamp vmax 4V vmin -1V
    gate vi16  chan  ABUS_VI_PINS    on
    connect vi16 chan ABUS_VI_PINS  vm

--------------
    -- setup VI_ABUS* first, then power up, to allow time for settling

----Power up 
-----Dut power up function
   DutPowerUp(Vddio, Vdd18, Vdd, "UART", "TP_GMSL2",POWERUP)------------- DutPowerUp(vio, v18, vcore, "UART", "TP_GMSL1",POWERUP)

---Close relay to connect DUT to VI16 Need hw modification because when these relay connected it open SDA and SCL there for no communication.
--     SetRelays("DutAbusToVI")
--     wait(5ms)

------------ Enter TestMode 11 for test -----------------
    SetTestMode( 11 , False , "SER_UART_Write" ) 

    RegWrite(SER_ID, SR_TEST0, 1, 0, 16#80,  "SER_UART_Write" )                                                   -- Select the PHYA Block / Tristate page
    wait(1ms)

    --------------------------------
    -- PHYA/B Block, Page2 (DFE, OSN, AGC) & Page1 (VTH, Slicer)
    --------------------------------
    -- the register values Designer listed are 266-425 (0x10A-0x1A9), but the RLMS A are in the range 0x1400-0x14CF and B 0x1500-0x15CF, so need to add 0x1300 or 0x1400 for A or B
    reg_offs[1] = 0x1300    -- 0x1300 + 0x10A:0x1A9 = 0x140A:0x14A9
    reg_offs[2] = 0x1400    -- 0x1400 + 0x10A:0x1A9 = 0x150A:0x15A9
    phy_block[1] = 0x80 -- PHY A
    phy_block[2] = 0x90 -- PHY B
    for b = 1 to 1 do
        if DEBUG >= 1 then
            println(stdout)
        end_if
        --------------------------------
        -- PHYA/B Block, Page2
        --------------------------------
        abus_set_blockpage( phy_block[b] | 2 , DEBUG )
        wait(1ms)
        if DEBUG >= 1 then
            println(stdout)
            println(stdout, sprint("DEBUG TEST_AbusDfeSlicer() ", bstr[b]:-1):-32, "dut1.abus0":12, "dut1.abus1":12, "dut1.abus2":12, "dut1.abus3":12, " | ", "dut2.abus0":12, "dut2.abus1":12, "dut2.abus2":12, "dut2.abus3":12, " | ", "timestamp":12)
            println(stdout, sprint(""):-32, "Qtst+":12, "Qtst-":12, "n/a":12, "n/a":12, " | ", "Qtst+":12, "Qtst-":12, "n/a":12, "n/a":12, " | ", "":12)
        end_if
        wait(5ms)

        -- DFE setup
        RegWrite( SER_ID , 0x150 + reg_offs[b] , 1 , 0x00 , 0x01 , "SER_UART_Write" )  -- timer tst
        RegWrite( SER_ID , 0x116 + reg_offs[b] , 1 , 0x00 , 0x02 , "SER_UART_Write" )  -- adp set dly
        RegWrite( SER_ID , 0x115 + reg_offs[b] , 1 , 0x00 , 0x20 , "SER_UART_Write" )  -- adp act dly
        RegWrite( SER_ID , 0x10B + reg_offs[b] , 1 , 0x00 , 0x00 , "SER_UART_Write" )  -- ctf adp dly
        RegWrite( SER_ID , 0x10A + reg_offs[b] , 1 , 0x00 , 0x02 , "SER_UART_Write" )  -- dfe adp dly
        RegWrite( SER_ID , 0x13C + reg_offs[b] , 1 , 0x00 , 0x08 , "SER_UART_Write" )  -- los vth
        RegWrite( SER_ID , 0x13F + reg_offs[b] , 1 , 0x00 , 0x74 , "SER_UART_Write" )  -- err ch ph pri
        RegWrite( SER_ID , 0x13E + reg_offs[b] , 1 , 0x00 , 0x34 , "SER_UART_Write" )  -- err ch ph sec
        RegWrite( SER_ID , 0x11F + reg_offs[b] , 1 , 0x00 , 0x80 , "SER_UART_Write" )  -- AGC init
        RegWrite( SER_ID , 0x123 + reg_offs[b] , 1 , 0x00 , 0x00 , "SER_UART_Write" )  -- bst init
        RegWrite( SER_ID , 0x12B + reg_offs[b] , 1 , 0x00 , 0x00 , "SER_UART_Write" )  -- dfe1 init
        RegWrite( SER_ID , 0x12A + reg_offs[b] , 1 , 0x00 , 0x00 , "SER_UART_Write" )  -- dfe2 init
        RegWrite( SER_ID , 0x129 + reg_offs[b] , 1 , 0x00 , 0x00 , "SER_UART_Write" )  -- dfe3 init
        RegWrite( SER_ID , 0x128 + reg_offs[b] , 1 , 0x00 , 0x00 , "SER_UART_Write" )  -- dfe4 init
        RegWrite( SER_ID , 0x127 + reg_offs[b] , 1 , 0x00 , 0x00 , "SER_UART_Write" )  -- dfe5 init
        RegWrite( SER_ID , 0x190 + reg_offs[b] , 1 , 0x00 , 0x80 , "SER_UART_Write" )  -- cal amp agc
        RegWrite( SER_ID , 0x145 + reg_offs[b] , 1 , 0x00 , 0x00 , "SER_UART_Write" )  -- crussc mode
        RegWrite( SER_ID , 0x1A8 + reg_offs[b] , 1 , 0x00 , 0xE0 , "SER_UART_Write" )  -- firmware phy override:   1110_0000
        RegWrite( SER_ID , 0x1A9 + reg_offs[b] , 1 , 0x00 , 0xB8 , "SER_UART_Write" )  -- more override:           1011_1000
        RegWrite( SER_ID , 0x1A8 + reg_offs[b] , 1 , 0x00 , 0xE0 , "SER_UART_Write" )  -- repeat of above?                     |
        wait(1ms)
        RegWrite( SER_ID , 0x1A8 + reg_offs[b] , 1 , 0x00 , 0xC0 , "SER_UART_Write" )  -- 1100_0000: just change one bit
        --gWrite( SER_ID , 0x1A9 + reg_offs[b] , 1 , 0x00 , 0x20 , "SER_UART_Write" )  -- 1011_1000 => 0010_0000: change three bits (bulk?)
        RegWrite( SER_ID , 0x1A9 + reg_offs[b] , 1 , 0x00 , 0x38 , "SER_UART_Write" )  -- 1011_1000 => 0011_1000: change three bits (one at a time?)
        RegWrite( SER_ID , 0x1A9 + reg_offs[b] , 1 , 0x00 , 0x28 , "SER_UART_Write" )  --           => 0010_1000: change three bits (one at a time?)
        RegWrite( SER_ID , 0x1A9 + reg_offs[b] , 1 , 0x00 , 0x20 , "SER_UART_Write" )  --           => 0010_0000: change three bits (one at a time?)
        wait(1ms)
        RegWrite( SER_ID , 0x1A8 + reg_offs[b] , 1 , 0x00 , 0xE0 , "SER_UART_Write" )  -- 1110_0000: just change one bit
        --gWrite( SER_ID , 0x1A9 + reg_offs[b] , 1 , 0x00 , 0xB8 , "SER_UART_Write" )  -- 0010_0000 => 1011_1000: change three bits (bulk?)
        RegWrite( SER_ID , 0x1A9 + reg_offs[b] , 1 , 0x00 , 0xA0 , "SER_UART_Write" )  -- 0010_0000 => 1010_0000: change three bits (one at a time?)
        RegWrite( SER_ID , 0x1A9 + reg_offs[b] , 1 , 0x00 , 0xB0 , "SER_UART_Write" )  --           => 1011_0000: change three bits (one at a time?)
        RegWrite( SER_ID , 0x1A9 + reg_offs[b] , 1 , 0x00 , 0xB8 , "SER_UART_Write" )  --           => 1011_1000: change three bits (one at a time?)
        wait(1ms)
        
        -- Guess: AdaptCtrl.xxxUpd might be the RMLS4E xxxInt coefficient interrupt bits.               0x144E-0x1300=0x14E = 334
        RegWrite( SER_ID , 0x14E + reg_offs[b] , 1 , 0x00 , 0xFF , "SER_UART_Write" )  -- set all Int bits to 1
        
        -- Guess: ReSeedMan is in RLMS57, which might be the "ReSeed" bit; so try toggling that.        0x1457-0x1300=0x157 = 343
        RegWrite( SER_ID , 0x157 + reg_offs[b] , 1 , 0x00 , 0x01 , "SER_UART_Write" )  
        wait(1ms)
        RegWrite( SER_ID , 0x157 + reg_offs[b] , 1 , 0x00 , 0x00 , "SER_UART_Write" )

        -- DFE1-5 tests
        RegWrite( SER_ID , 0x11F + reg_offs[b] , 1 , 0x00 , 0x60 , "SER_UART_Write" )  -- agc init
        RegWrite( SER_ID , 0x133 + reg_offs[b] , 1 , 0x00 , 0x10 , "SER_UART_Write" )  -- OSN init
        awrite(sweep[1:5], 0x00, 0x0F, 0x1F, 0x2F, 0x3F)

        -- DFE1
        for sw = 1 to 5 do
            RegWrite( SER_ID , 0x12B + reg_offs[b] , 1 , 0x00 , sweep[sw] , "SER_UART_Write" ) -- DFE1 init
            vmeas = abus_meas_v( 20 , 1ms , 0 )
            if DEBUG >= 1 then
                println(stdout, sprint("ABUS PHY", bstr[b]:-1, " DFE1: 0x", sweep[sw]!Hz:2):-32, vmeas[2]!fu=V:12:3 , " | ", vmeas[3]!fu=V:12:3 , " | ", snap_timer()-t0!fu=ms:12:3 )
            end_if
        end_for -- sw
        RegWrite( SER_ID , 0x12B + reg_offs[b] , 1 , 0x00 , 0x00 , "SER_UART_Write" )

        -- DFE2
        for sw = 1 to 5 do
            RegWrite( SER_ID , 0x12A + reg_offs[b] , 1 , 0x00 , sweep[sw] , "SER_UART_Write" ) -- DFE2 init
            vmeas = abus_meas_v( 20 , 1ms , 0 )
            if DEBUG >= 1 then
                println(stdout, sprint("ABUS PHY", bstr[b]:-1, " DFE2: 0x", sweep[sw]!Hz:2):-32, vmeas[2]!fu=V:12:3 , " | ", vmeas[3]!fu=V:12:3 , " | ", snap_timer()-t0!fu=ms:12:3 )
            end_if
        end_for -- sw
        RegWrite( SER_ID , 0x12A + reg_offs[b] , 1 , 0x00 , 0x00 , "SER_UART_Write" )

        -- DFE3
        for sw = 1 to 5 do
            RegWrite( SER_ID , 0x129 + reg_offs[b] , 1 , 0x00 , sweep[sw] , "SER_UART_Write" ) -- DFE3 init
            vmeas = abus_meas_v( 20 , 1ms , 0 )
            if DEBUG >= 1 then
                println(stdout, sprint("ABUS PHY", bstr[b]:-1, " DFE3: 0x", sweep[sw]!Hz:2):-32, vmeas[2]!fu=V:12:3 , " | ", vmeas[3]!fu=V:12:3 , " | ", snap_timer()-t0!fu=ms:12:3 )
            end_if
        end_for -- sw
        RegWrite( SER_ID , 0x129 + reg_offs[b] , 1 , 0x00 , 0x00 , "SER_UART_Write" )

        -- DFE4
        for sw = 1 to 5 do
            RegWrite( SER_ID , 0x128 + reg_offs[b] , 1 , 0x00 , sweep[sw] , "SER_UART_Write" ) -- DFE4 init
            vmeas = abus_meas_v( 20 , 1ms , 0 )
            if DEBUG >= 1 then
                println(stdout, sprint("ABUS PHY", bstr[b]:-1, " DFE4: 0x", sweep[sw]!Hz:2):-32, vmeas[2]!fu=V:12:3 , " | ", vmeas[3]!fu=V:12:3 , " | ", snap_timer()-t0!fu=ms:12:3 )
            end_if
        end_for -- sw
        RegWrite( SER_ID , 0x128 + reg_offs[b] , 1 , 0x00 , 0x00 , "SER_UART_Write" )

        -- DFE5
        for sw = 1 to 5 do
            RegWrite( SER_ID , 0x127 + reg_offs[b] , 1 , 0x00 , sweep[sw] , "SER_UART_Write" ) -- DFE5 init
            vmeas = abus_meas_v( 20 , 1ms , 0 )
            if DEBUG >= 1 then
                println(stdout, sprint("ABUS PHY", bstr[b]:-1, " DFE5: 0x", sweep[sw]!Hz:2):-32, vmeas[2]!fu=V:12:3 , " | ", vmeas[3]!fu=V:12:3 , " | ", snap_timer()-t0!fu=ms:12:3 )
            end_if
        end_for -- sw
        RegWrite( SER_ID , 0x127 + reg_offs[b] , 1 , 0x00 , 0x00 , "SER_UART_Write" )

        -- main setup
        RegWrite( SER_ID , 0x150 + reg_offs[b] , 1 , 0x00 , 0x01 , "SER_UART_Write" )  -- timer tst                             
        RegWrite( SER_ID , 0x116 + reg_offs[b] , 1 , 0x00 , 0x02 , "SER_UART_Write" )  -- adp set dly                           
        RegWrite( SER_ID , 0x115 + reg_offs[b] , 1 , 0x00 , 0x20 , "SER_UART_Write" )  -- adp act dly                           
        RegWrite( SER_ID , 0x10B + reg_offs[b] , 1 , 0x00 , 0x00 , "SER_UART_Write" )  -- ctf adp dly                           
        RegWrite( SER_ID , 0x10A + reg_offs[b] , 1 , 0x00 , 0x02 , "SER_UART_Write" )  -- dfe adp dly                           
        RegWrite( SER_ID , 0x13C + reg_offs[b] , 1 , 0x00 , 0x08 , "SER_UART_Write" )  -- los vth                               
        RegWrite( SER_ID , 0x13F + reg_offs[b] , 1 , 0x00 , 0x74 , "SER_UART_Write" )  -- err ch ph pri                         
        RegWrite( SER_ID , 0x13E + reg_offs[b] , 1 , 0x00 , 0x34 , "SER_UART_Write" )  -- err ch ph sec                         
        RegWrite( SER_ID , 0x11F + reg_offs[b] , 1 , 0x00 , 0x80 , "SER_UART_Write" )  -- AGC init                              
        RegWrite( SER_ID , 0x123 + reg_offs[b] , 1 , 0x00 , 0x00 , "SER_UART_Write" )  -- bst init                              
        RegWrite( SER_ID , 0x12B + reg_offs[b] , 1 , 0x00 , 0x01 , "SER_UART_Write" )  -- dfe1 init                             
        RegWrite( SER_ID , 0x12A + reg_offs[b] , 1 , 0x00 , 0x41 , "SER_UART_Write" )  -- dfe2 init                             
        RegWrite( SER_ID , 0x129 + reg_offs[b] , 1 , 0x00 , 0x41 , "SER_UART_Write" )  -- dfe3 init                             
        RegWrite( SER_ID , 0x128 + reg_offs[b] , 1 , 0x00 , 0x41 , "SER_UART_Write" )  -- dfe4 init                             
        RegWrite( SER_ID , 0x127 + reg_offs[b] , 1 , 0x00 , 0x01 , "SER_UART_Write" )  -- dfe5 init                             
        RegWrite( SER_ID , 0x190 + reg_offs[b] , 1 , 0x00 , 0x80 , "SER_UART_Write" )  -- cal amp agc                           
        RegWrite( SER_ID , 0x145 + reg_offs[b] , 1 , 0x00 , 0x00 , "SER_UART_Write" )  -- crussc mode                           
        RegWrite( SER_ID , 0x1A8 + reg_offs[b] , 1 , 0x00 , 0xE0 , "SER_UART_Write" )  -- firmware phy override:   1110_0000    
        RegWrite( SER_ID , 0x1A9 + reg_offs[b] , 1 , 0x00 , 0xB8 , "SER_UART_Write" )  -- more override:           1011_1000    
        RegWrite( SER_ID , 0x1A8 + reg_offs[b] , 1 , 0x00 , 0xE0 , "SER_UART_Write" )  -- repeat of above?                     |
        wait(1ms)          
        RegWrite( SER_ID , 0x1A8 + reg_offs[b] , 1 , 0x00 , 0xC0 , "SER_UART_Write" )  -- 1100_0000: just change one bit
        --gWrite( SER_ID , 0x1A9 + reg_offs[b] , 1 , 0x00 , 0x20 , "SER_UART_Write" )  -- 1011_1000 => 0010_0000: change three bits (bulk?)
        RegWrite( SER_ID , 0x1A9 + reg_offs[b] , 1 , 0x00 , 0x38 , "SER_UART_Write" )  -- 1011_1000 => 0011_1000: change three bits (one at a time?)
        RegWrite( SER_ID , 0x1A9 + reg_offs[b] , 1 , 0x00 , 0x28 , "SER_UART_Write" )  --           => 0010_1000: change three bits (one at a time?)
        RegWrite( SER_ID , 0x1A9 + reg_offs[b] , 1 , 0x00 , 0x20 , "SER_UART_Write" )  --           => 0010_0000: change three bits (one at a time?)
        wait(1ms)               
        RegWrite( SER_ID , 0x1A8 + reg_offs[b] , 1 , 0x00 , 0xE0 , "SER_UART_Write" )  -- 1110_0000: just change one bit
        --gWrite( SER_ID , 0x1A9 + reg_offs[b] , 1 , 0x00 , 0xB8 , "SER_UART_Write" )  -- 0010_0000 => 1011_1000: change three bits (bulk?)
        RegWrite( SER_ID , 0x1A9 + reg_offs[b] , 1 , 0x00 , 0xA0 , "SER_UART_Write" )  -- 0010_0000 => 1010_0000: change three bits (one at a time?)
        RegWrite( SER_ID , 0x1A9 + reg_offs[b] , 1 , 0x00 , 0xB0 , "SER_UART_Write" )  --           => 1011_0000: change three bits (one at a time?)
        RegWrite( SER_ID , 0x1A9 + reg_offs[b] , 1 , 0x00 , 0xB8 , "SER_UART_Write" )  --           => 1011_1000: change three bits (one at a time?)
                           
        -- Guess: AdaptCtrl.xxxUpd might be the RMLS4E xxxInt coefficient interrupt bits.               0x144E-0x1300=0x14E = 334
        RegWrite( SER_ID , 0x14E + reg_offs[b] , 1 , 0x00 , 0xFF , "SER_UART_Write" )  -- set all Int bits to 1
        
        -- Guess: ReSeedMan is in RLMS57, which might be the "ReSeed" bit; so try toggling that.        0x1457-0x1300=0x157 = 343
        RegWrite( SER_ID , 0x157 + reg_offs[b] , 1 , 0x00 , 0x01 , "SER_UART_Write" )  
        wait(1ms)
        RegWrite( SER_ID , 0x157 + reg_offs[b] , 1 , 0x00 , 0x00 , "SER_UART_Write" )

        -- OSN test
        if DEBUG >= 1 then
            println(stdout)
            println(stdout, sprint("DEBUG TEST_AbusDfeSlicer() ", bstr[b]:-1):-32, "dut1.abus0":12, "dut1.abus1":12, "dut1.abus2":12, "dut1.abus3":12, " | ", "dut2.abus0":12, "dut2.abus1":12, "dut2.abus2":12, "dut2.abus3":12, " | ", "timestamp":12)
            println(stdout, sprint(""):-32, "Qtst+":12, "Qtst-":12, "n/a":12, "n/a":12, " | ", "Qtst+":12, "Qtst-":12, "n/a":12, "n/a":12, " | ", "":12)
        end_if
        RegWrite( SER_ID , 0x11F + reg_offs[b] , 1 , 0x00 , 0x80 , "SER_UART_Write" )              -- agc init
        awrite(sweep[1:8], 0x00, 0x07, 0x0F, 0x17, 0x27, 0x2F, 0x37, 0x3F)
        for sw = 1 to 8 do
            RegWrite( SER_ID , 0x133 + reg_offs[b] , 1 , 0x00 , sweep[sw] , "SER_UART_Write" )     -- osn init
            vmeas = abus_meas_v( 20 , 1ms , 0 )
            if DEBUG >= 1 then
                println(stdout, sprint("ABUS PHY", bstr[b]:-1, " OSN: 0x", sweep[sw]!Hz:2):-32, vmeas[2]!fu=V:12:3 , " | ", vmeas[3]!fu=V:12:3 , " | ", snap_timer()-t0!fu=ms:12:3 )
            end_if
        end_for -- sw
            RegWrite( SER_ID , 0x133 + reg_offs[b] , 1 , 0x00 , 0x1F , "SER_UART_Write" )     -- osn init

        -- Guess: AdaptCtrl.xxxUpd might be the RMLS4E xxxInt coefficient interrupt bits.               0x144E-0x1300=0x14E = 334
        RegWrite( SER_ID , 0x14E + reg_offs[b] , 1 , 0x00 , 0xFF , "SER_UART_Write" )  -- set all Int bits to 1
        
        -- Guess: ReSeedMan is in RLMS57, which might be the "ReSeed" bit; so try toggling that.        0x1457-0x1300=0x157 = 343
        RegWrite( SER_ID , 0x157 + reg_offs[b] , 1 , 0x00 , 0x01 , "SER_UART_Write" )  
        wait(1ms)
        RegWrite( SER_ID , 0x157 + reg_offs[b] , 1 , 0x00 , 0x00 , "SER_UART_Write" )

        -- AGC test
        if DEBUG >= 1 then
            println(stdout)
            println(stdout, sprint("DEBUG TEST_AbusDfeSlicer() ", bstr[b]:-1):-32, "dut1.abus0":12, "dut1.abus1":12, "dut1.abus2":12, "dut1.abus3":12, " | ", "dut2.abus0":12, "dut2.abus1":12, "dut2.abus2":12, "dut2.abus3":12, " | ", "timestamp":12)
            println(stdout, sprint(""):-32, "Qtst+":12, "Qtst-":12, "n/a":12, "n/a":12, " | ", "Qtst+":12, "Qtst-":12, "n/a":12, "n/a":12, " | ", "":12)
        end_if
        RegWrite( SER_ID , 0x133 + reg_offs[b] , 1 , 0x00 , 0x08 , "SER_UART_Write" )              -- osn init
        awrite(sweep[1:9], 0x00, 0x0F, 0x1F, 0x2F, 0x3F, 0x4F, 0x5F, 0x6F, 0x7F)
        for sw = 1 to 9 do
            RegWrite( SER_ID , 0x11F + reg_offs[b] , 1 , 0x00 , sweep[sw] , "SER_UART_Write" )     -- agc init
            vmeas = abus_meas_v( 20 , 1ms , 0 )
            if DEBUG >= 1 then
                println(stdout, sprint("ABUS PHY", bstr[b]:-1, " AGC: 0x", sweep[sw]!Hz:2):-32, vmeas[2]!fu=V:12:3 , " | ", vmeas[3]!fu=V:12:3 , " | ", snap_timer()-t0!fu=ms:12:3 )
            end_if
        end_for -- sw
        RegWrite( SER_ID , 0x11F + reg_offs[b] , 1 , 0x00 , 0x00 , "SER_UART_Write" )
            RegWrite( SER_ID , 0x11F + reg_offs[b] , 1 , 0x00 , 0x80 , "SER_UART_Write" )     -- agc init

        --------------------------------
        -- PHYA/B Block, Page1
        --------------------------------
        RegWrite(SER_ID, REG92DES_TCTRL_TEST0, 1, 0, phy_block[b] | 1 , "SER_UART_Write")                                                  -- Select the PHY_X Block / PAGE 1 (VTH / Slicer)
        wait(1ms)
        if DEBUG >= 1 then
            RegRead( SER_ID , REG92DES_TCTRL_TEST0 , 1 , RdWordUpper , RdWordLower , "des_i2c_read" )
            println(stdout)
            println(stdout, "DEBUG TEST_AbusDfeSlicer() TEST0:":-32, 0xFF&RdWordLower[1:NUM_SITES]!h:4, "@t", "Block & Page: 0x", phy_block[b] | 1!hz:2 )
            println(stdout, sprint("DEBUG TEST_AbusDfeSlicer() ", bstr[b]:-1):-32, "dut1.abus0":12, "dut1.abus1":12, "dut1.abus2":12, "dut1.abus3":12, " | ", "dut2.abus0":12, "dut2.abus1":12, "dut2.abus2":12, "dut2.abus3":12, " | ", "timestamp":12)
            println(stdout, sprint(""):-32, "Etst+":12, "Etst-":12, "VTtst+":12, "VTtst-":12, " | ", "Etst+":12, "Etst-":12, "VTtst+":12, "VTtst-":12, " | ", "":12)
        end_if
        wait(5ms)

        -- VTH test
        RegWrite( SER_ID , 0x114 + reg_offs[b] , 1 , 0x00 , 0x00 , "SER_UART_Write" )  -- adp ctrl auto en
        RegWrite( SER_ID , 0x159 + reg_offs[b] , 1 , 0x00 , 0x00 , "SER_UART_Write" )  -- err ch vth0
        RegWrite( SER_ID , 0x11F + reg_offs[b] , 1 , 0x00 , 0x60 , "SER_UART_Write" )  -- agc init
        RegWrite( SER_ID , 0x133 + reg_offs[b] , 1 , 0x00 , 0x10 , "SER_UART_Write" )  -- osn init
        awrite(sweep[1:4], 0x0F, 0x1F, 0x2F, 0x3F)
        for sw = 1 to 4 do
            RegWrite( SER_ID , 0x158 + reg_offs[b] , 1 , 0x00 , sweep[sw] , "SER_UART_Write" )     -- er ch vth1
            vmeas = abus_meas_v( 20 , 1ms , 0 )
            if DEBUG >= 1 then
                println(stdout, sprint("ABUS PHY", bstr[b]:-1, " VTH: 0x", sweep[sw]!Hz:2):-32, vmeas[2]!fu=V:12:3 , " | ", vmeas[3]!fu=V:12:3 , " | ", snap_timer()-t0!fu=ms:12:3 )
            end_if
        end_for -- sw
            RegWrite( SER_ID , 0x158 + reg_offs[b] , 1 , 0x00 , 0x18 , "SER_UART_Write" )     -- er ch vth1

        -- Guess: AdaptCtrl.xxxUpd might be the RMLS4E xxxInt coefficient interrupt bits.               0x144E-0x1300=0x14E = 334
        RegWrite( SER_ID , 0x14E + reg_offs[b] , 1 , 0x00 , 0xFF , "SER_UART_Write" )  -- set all Int bits to 1
        
        -- Guess: ReSeedMan is in RLMS57, which might be the "ReSeed" bit; so try toggling that.        0x1457-0x1300=0x157 = 343
        RegWrite( SER_ID , 0x157 + reg_offs[b] , 1 , 0x00 , 0x01 , "SER_UART_Write" )  
        wait(1ms)
        RegWrite( SER_ID , 0x157 + reg_offs[b] , 1 , 0x00 , 0x00 , "SER_UART_Write" )

        -- Slicer test
        if DEBUG >= 1 then
            println(stdout)
            println(stdout, sprint("DEBUG TEST_AbusDfeSlicer() ", bstr[b]:-1):-32, "dut1.abus0":12, "dut1.abus1":12, "dut1.abus2":12, "dut1.abus3":12, " | ", "dut2.abus0":12, "dut2.abus1":12, "dut2.abus2":12, "dut2.abus3":12, " | ", "timestamp":12)
            println(stdout, sprint(""):-32, "Etst+":12, "Etst-":12, "VTtst+":12, "VTtst-":12, " | ", "Etst+":12, "Etst-":12, "VTtst+":12, "VTtst-":12, " | ", "":12)
        end_if
        RegWrite( SER_ID , 0x114 + reg_offs[b] , 1 , 0x00 , 0x00 , "SER_UART_Write" )  -- adp ctrl auto en
        RegWrite( SER_ID , 0x159 + reg_offs[b] , 1 , 0x00 , 0x00 , "SER_UART_Write" )  -- err ch vth0
        RegWrite( SER_ID , 0x11F + reg_offs[b] , 1 , 0x00 , 0x10 , "SER_UART_Write" )  -- agc init   
        RegWrite( SER_ID , 0x133 + reg_offs[b] , 1 , 0x00 , 0x10 , "SER_UART_Write" )  -- osn init
        awrite(sweep[1:4], 0x1F, 0x3F, 0x2F, 0x3F)
        for sw = 1 to 4 do
            RegWrite( SER_ID , 0x158 + reg_offs[b] , 1 , 0x00 , 0x1F , "SER_UART_Write" )  -- err ch vth1
            vmeas = abus_meas_v( 20 , 1ms , 0 )
            if DEBUG >= 1 then
                println(stdout, sprint("ABUS PHY", bstr[b]:-1, " Slicer: 0x", sweep[sw]!Hz:2):-32, vmeas[2]!fu=V:12:3 , " | ", vmeas[3]!fu=V:12:3 , " | ", snap_timer()-t0!fu=ms:12:3 )
            end_if
        end_for -- sw
            RegWrite( SER_ID , 0x158 + reg_offs[b] , 1 , 0x00 , 0x18 , "SER_UART_Write" )     -- er ch vth1

    end_for -- block: PHYA / PHY B

    --------------------------------
    -- Cleanup
    --------------------------------
    RegWrite(SER_ID, REG92DES_TCTRL_TEST0, 1, 0, 16#00, "SER_UART_Write" )                                                   -- Select the PowerBlock / Tristate page
    wait(1ms)
    RegRead( SER_ID , REG92DES_TCTRL_TEST0 , 1 , RdWordUpper , RdWordLower , "des_i2c_read" )
    if DEBUG >= 1 then
        println(stdout)
        println(stdout, "DEBUG TEST_AbusDfeSlicer() TEST0:":-32, 0xFF&RdWordLower[1:NUM_SITES]!h:4, "@t", "Block & Page: 0x00" )
    end_if

    disconnect vi16 chan dut_vi_abus_vi16
    disconnect ovi  chan dut_vi_abus_ovi
    set vi16 chan dut_vi_abus_vi16 to fv 0V max 5V measure i max 100mA clamp imax 100mA imin -100mA
    set ovi  chan dut_vi_abus_ovi                   to fv 0V measure i max 100mA clamp imax 100mA imin -100mA
    gate vi16 chan dut_vi_abus_vi16 off
    gate ovi  chan dut_vi_abus_ovi off

    SetRelays( "AllDpX1Crystal" )

end_body


procedure SER_DESA_Reg_Func(vcore, vio, v18, TX_SPD_it, RX_SPD_it, link_type_it, Freq_it,iser_read_reg1_it,iser_read_reg2_it,ides_read_reg1_it, ides_read_reg2_it, TP_COAX,TX_SPD,RX_SPD,Freq,value1,value2, Link_Lock_dly,POWERUP,POWERDOWN,LinkRset)
--------------------------------------------------------------------------------
in float            : vcore, vio, v18
--in_out integer_test : devid_it, dnutid_it, ser_lock_it, des_lock_it,iser_read_reg1_it,iser_read_reg2_it, link_type_it
in_out integer_test :  iser_read_reg1_it, iser_read_reg2_it, link_type_it,ides_read_reg1_it, ides_read_reg2_it
in_out float_test   : TX_SPD_it, RX_SPD_it, Freq_it

in string[20]       : TP_COAX
in float            : TX_SPD, RX_SPD, Freq, Link_Lock_dly
in lword            : value1, value2           -- values to write to SER & DESA FPGA internal EEPROM across link

in boolean          : POWERUP,POWERDOWN,LinkRset
local

  multisite lword   : LowerRdWord, UpperRdWord, serdata, desdata
   
  float             : Vconf0, Vconf1
  multisite lword   : lowword, upperword, des_read0, des_read1, des_read2, des_read, ser_read, ser_local_read, ser_read_reg, ser_read_reg1, ser_read_reg2, des_read_reg1, des_read_reg2

  multisite lword   : reg_val, reg_val0, reg_val1, reg_val_ser, reg_val_des
  multisite integer : ireg_val, ireg_val0, ireg_val1, ireg_val_ser, ireg_val_des, ireg_val15, iser_read_reg, iser_read_reg1, iser_read_reg2, link_type, ides_read_reg1, ides_read_reg2
  word              : sites, idx, site
  integer           : idxs
  
  multisite lword   : hizdel_reg_val, oreg_reg_val
  lword             : data
  
  multisite lword   : reg_val11,reg_val12,reg_val13,reg_val14,reg_val15
  lword             : ser_link_speed_code, des_link_speed_code, ser_tx_speed, ser_rx_speed, des_tx_speed, des_rx_speed
  lword             : number_of_lane, des_csi_mode,des_numb_lane,mipi_speed, ser_csi_mode
  float             : TX_SPD_rate, RX_SPD_rate, Freq_com, w_r_delay 
   boolean         : loopcont
    multisite boolean : SiteCheck
    word            :sitecount,count
  
end_local


body
  
    TX_SPD_rate = TX_SPD
    RX_SPD_rate = RX_SPD
    Freq_com    = Freq
   loopcont  = true
   SiteCheck  = false 

    active_sites = get_active_sites
    sites = word(len(active_sites))  

-----Dut power up function
   DutPowerUp(vio, v18, vcore, "UART", "TP_GMSL2",POWERUP)------------- DutPowerUp(vio, v18, vcore, "UART", "TP_GMSL1",POWERUP)


--------powerup_dnut_vdd_vterm(VDD_SET, VTERM_SET)
   if   POWERUP then
        powerup_dnut_vdd_vterm(1.2,1.2)
-----------  --fpga_Set_DNUT_Pins("FPGA1", CFG1, CFG0, PWDN, latch)
--        fpga_Set_DNUT_Pins("FPGA1", 0,0, 0, 0, TRUE)  -- UART/TP/GMSL2=1/RATE=0(6 Gig link)               
--wait(6ms)
        fpga_Set_DNUT_Pins("FPGA1", 0,0, 1, 1, TRUE)  -- UART/TP/GMSL2=1/RATE=0(6 Gig link)     MPW5 and up            

        wait(6ms)
   end_if   
    if LinkRset then 

-------Connect TX/RX of Dut and DNUT to FPGA
        close  cbit MFP_LT_RELAY + DNUT_RXTX_RELAY + I2C_LT_CB + MFP_LT_K12_RELAY   ----MFP_LT_K12 is for switch fpga control rxsda txscl  Mt. only with rev b hardware.
        wait(4ms)
        fpga_set_UART_Frequency("FPGA1", Freq)
--- Set SER and DES for coax or tp mode using FPGA
        if TP_COAX[1:2] = "TP" then
            fpga_UART_Write("FPGA1","SER", SER_ID, 16#11, 1, 0x0A)                      ---- TP mode 0x11                            
            fpga_UART_Write("FPGA1","DES", DESA_ID, 16#11, 1, 0x0A)                    ---- TP mode 0x11        
            link_type = 1 
        -- open termination relay at negative SL
            open cbit    CB2_SLDC            --FX_RELAYS 
            open cbit COAXB_M_RELAY             --OVI_RELAYS
            wait(5ms)                
        else
            fpga_UART_Write("FPGA1","SER", SER_ID, 16#11, 1, 0x0F)                      ---- coax mode 0x11                    
            fpga_UART_Write("FPGA1","DES", DESA_ID, 16#11, 1, 0x0F)                    ---- coax mode 0x11
            link_type = 0                
            -- close termination relay at negative SL
            close  cbit CB2_SLDC                     --OVI_RELAYS
            close cbit COAXB_M_RELAY                --OVI_RELAYS
         wait(5ms)               
        end_if 

-- ------ Set GMSL link forward and backward speed.

        if TX_SPD = 6GHz then
            ser_tx_speed = 0x8
            des_rx_speed = 0x2
        elseif      TX_SPD = 3GHz then
            ser_tx_speed = 0x4
            des_rx_speed = 0x1            
        elseif      TX_SPD = 1.5GHz then 
            ser_tx_speed = 0x0
            des_rx_speed = 0x0                      
       end_if  

       if RX_SPD = 1.5GHz then
            ser_rx_speed = 0x3
            des_tx_speed = 0xC
       elseif      RX_SPD = 0.75GHz then
            ser_rx_speed = 0x2
            des_tx_speed = 0x8      
      
       elseif      RX_SPD = 0.375GHz then
            ser_rx_speed = 0x1
            des_tx_speed = 0x4          
       elseif      RX_SPD = 0.1875GHz then
            ser_rx_speed = 0x0
            des_tx_speed = 0x0               
       end_if 
       
        ser_link_speed_code = ser_rx_speed + ser_tx_speed
        des_link_speed_code = des_rx_speed + des_tx_speed
    
    
--- Program link rate
        fpga_UART_Write("FPGA1","SER", SER_ID, 16#01, 1, ser_link_speed_code  )               ---- SER GMSL link speed    
        fpga_UART_Write("FPGA1","DES", DESA_ID, 16#01, 1, des_link_speed_code  )             ---- DES GMSL link speed
        wait(20ms)
--- Write to reg10 to update link speed setting     
    -- write Reg0x10 to update to COAX mode
        fpga_UART_Write("FPGA1","DES", DESA_ID, 16#10, 1, 0x00)
        fpga_UART_Write("FPGA1","SER", SER_ID, 16#10, 1, 0x30)             -- Set auto link config and one shot
        ser_read =  fpga_UART_Read("FPGA1", "SER", SER_ID, 0x10, 1)        -- self adjust back to 0x01    
    end_if  ----If link reset

--         ser_local_read =  fpga_UART_Read("FPGA1", "SER", SER_ID, 0x13, 1)      -- for SER lock bit, good if 0xDA               
--         site = active_sites[1]   ---- only check 1 site should be good enough
--         for i = 1 to 300 do
--             reg_val15      =  fpga_UART_Read("FPGA1", "DES", DESA_ID, 0x13, 1)      -- DES lock bit, 0xDA expected   
--             if reg_val15[site] = 0xCA  or reg_val15[site] = 0xCE then
--                 break
--             else
--                 wait(2ms)
--             end_if
--         end_for         
--         wait(0ms)
--         ser_local_read =  fpga_UART_Read("FPGA1", "SER", SER_ID, 0x13, 1)      -- for SER lock bit, good if 0xDA         

   lowword =  fpga_UART_Read("FPGA1", "SER", SER_ID, 0x13, 1)      -- for SER lock bit, good if 0xDA 
   reg_val15  = fpga_UART_Read("FPGA1", "DES", DESA_ID, 0x13, 1)   -- DES lock bit, 0xCA expected   

    while( loopcont) do
        for idx = 1 to sites do 
            site = active_sites[idx]
                if  (lowword[site] = 0xde  OR lowword[site] =0xda  OR lowword[site] =0xCa OR lowword[site] =0xCE OR lowword[site] =0xEa OR lowword[site] =0xEE) and not SiteCheck[site] then
                    sitecount = sitecount + 1
                    SiteCheck[site] = true     
                end_if
                if sitecount = sites then
                    loopcont = false
                end_if     
            count = count + 1
            if count > 200 then
                loopcont  = false
            end_if
            if loopcont  then
                wait(1ms)
                lowword =  fpga_UART_Read("FPGA1", "SER", SER_ID, 0x13, 1)      -- for SER lock bit, good if 0xDA 
            end_if
            
        end_for            
 
    end_while
     ser_local_read =  fpga_UART_Read("FPGA1", "SER", SER_ID, 0x13, 1)      -- for SER lock bit, good if 0xDA  
     reg_val15  = fpga_UART_Read("FPGA1", "DES", DESA_ID, 0x13, 1)   -- DES lock bit, 0xCA expected 


        for idxs = 1 to len(active_sites) do
            site = active_sites[idxs]
            ireg_val1[site]  = integer(ser_local_read[site])
            ireg_val15[site] = integer(reg_val15[site])      
         end_for    

        fpga_set_UART_Frequency("FPGA1", Freq)
        wait(3ms)    

        ser_read = 0x00        -- initialization needed.
        ser_read_reg1 = 0x00
        ser_read_reg2 = 0xFF
         

----------Read from ser to Des
w_r_delay = 200uS
        fpga_UART_Write("FPGA1","SER", DESA_ID, 16#01C0, 1, 16#7F)             -- write 0x7F to reg, inverted all bits except bit7(can't change)
        wait(w_r_delay)           
        ser_read_reg1 =  fpga_UART_Read("FPGA1", "SER", DESA_ID, 16#01C0, 1)   -- FPGA read regs from SER across link after write 
        wait(w_r_delay)    
        fpga_UART_Write("FPGA1","SER", DESA_ID, 16#01C0, 1, 16#00)             -- reset to default value to prepare for next test
        wait(w_r_delay)        
        ser_read_reg2 =  fpga_UART_Read("FPGA1", "SER", DESA_ID, 16#01C0, 1)   -- FPGA read regs from SER across link after write reset      
        wait(w_r_delay)      

----------Read from DES to SER
      fpga_UART_Write("FPGA1","DES", SER_ID, 16#01C0, 1, 16#7F)             -- write 0x7F to reg, inverted all bits except bit7(can't change)
      wait(w_r_delay)        
      des_read_reg1 =  fpga_UART_Read("FPGA1", "DES", SER_ID, 16#01C0, 1)   -- FPGA read regs from DES across link after write 
      wait(w_r_delay)    
      fpga_UART_Write("FPGA1","DES", SER_ID, 16#01C0, 1, 16#00)             -- reset to default value to prepare for next test
      wait(w_r_delay)      
      des_read_reg2 =  fpga_UART_Read("FPGA1", "DES", SER_ID, 16#01C0, 1)   -- FPGA read regs from DES across link after write reset      
      wait(w_r_delay)      
-- ------------------------
  
    if POWERDOWN then   
         
--        powerdown_device(POWERDOWN)
--          powerup_dnut_vdd_vterm(0.0,0.0)
-----------  --fpga_Set_DNUT_Pins("FPGA1", CFG1, CFG0, PWDN, latch)
        fpga_Set_DNUT_Pins("FPGA1", 0,0, 0, 0, TRUE)  -- UART/TP/GMSL2=1/RATE=0(6 Gig link)               
        wait(1ms)         
        open  cbit MFP_LT_RELAY + DNUT_RXTX_RELAY + I2C_LT_CB  + MFP_LT_K12_RELAY  ------for now
        open  cbit CB2_SLDC                     --OVI_RELAYS
        open cbit COAXB_M_RELAY                --OVI_RELAYS
        wait(5ms) 
        powerdown_device(POWERDOWN)   
    end_if
   for idxs = 1 to len(active_sites) do
     site = active_sites[idxs]
     --ireg_val_ser[site]  = integer(ser_read[site])
     iser_read_reg1[site]  = integer(ser_read_reg1[site])
     iser_read_reg2[site]  = integer(ser_read_reg2[site])                
     ides_read_reg1[site]  = integer(des_read_reg1[site])
     ides_read_reg2[site]  = integer(des_read_reg2[site])                

   end_for
   
   
   test_value msfloat(TX_SPD_rate)  with TX_SPD_it 
   test_value msfloat(RX_SPD_rate)  with RX_SPD_it
   test_value link_type  with link_type_it    
  
   test_value msfloat(Freq_com) with Freq_it           
   test_value iser_read_reg1 with iser_read_reg1_it
   test_value iser_read_reg2 with iser_read_reg2_it

 
 end_body




procedure SER_DESA_Reg_I2C_PT_Func (vcore, vio, v18, TX_SPD_it, RX_SPD_it, link_type_it, Freq_it,DesPT,SerPT,DesPT1,SerPT1,DesPT2,SerPT2, TP_COAX,TX_SPD,RX_SPD,Freq,value1,value2, Link_Lock_dly,POWERUP,POWERDOWN,LinkRset)
--------------------------------------------------------------------------------
in float            : vcore, vio, v18
--in_out integer_test : devid_it, dnutid_it, ser_lock_it, des_lock_it,iser_read_reg1_it,iser_read_reg2_it, link_type_it
in_out integer_test :  link_type_it,DesPT,SerPT,DesPT1,SerPT1,DesPT2,SerPT2
in_out float_test   : TX_SPD_it, RX_SPD_it, Freq_it

in string[20]       : TP_COAX
in float            : TX_SPD, RX_SPD, Freq, Link_Lock_dly
in lword            : value1, value2           -- values to write to SER & DESA FPGA internal EEPROM across link
in boolean          : POWERUP,POWERDOWN,LinkRset

local

  multisite lword   : LowerRdWord, UpperRdWord
   
  float             : Vconf0, Vconf1
  multisite lword   : lowword, upperword, des_read0, des_read1, des_read2, des_read, ser_read, ser_local_read, ser_read_reg, ser_read_reg1, ser_read_reg2

  multisite lword   : reg_val, reg_val0, reg_val1, reg_val_ser, reg_val_des
  multisite integer : ireg_val, ireg_val0, ireg_val1, ireg_val_ser, ireg_val_des, ireg_val15, iser_read_reg, iser_read_reg1, iser_read_reg2, link_type
  word              : sites, idx, site
  integer           : idxs
  
  multisite lword   : hizdel_reg_val, oreg_reg_val
  lword             : data
  
  multisite lword   : reg_val11,reg_val12,reg_val13,reg_val14,reg_val15
  lword             : ser_link_speed_code, des_link_speed_code, ser_tx_speed, ser_rx_speed, des_tx_speed, des_rx_speed
  lword             : number_of_lane, des_csi_mode,des_numb_lane,mipi_speed, ser_csi_mode
  float             : TX_SPD_rate, RX_SPD_rate, Freq_com, w_r_delay 
  multisite lword   : serdata, desdata,  serdataPT1, desdataPT1 ,  serdataPT2, desdataPT2

  multisite integer : ISerData,IDesData,ISerDataPT1,IDesDataPT1,ISerDataPT2,IDesDataPT2
   boolean         : loopcont
    multisite boolean : SiteCheck
    word            :sitecount,count  


end_local

body
  
    TX_SPD_rate = TX_SPD
    RX_SPD_rate = RX_SPD
    Freq_com    = Freq

    active_sites = get_active_sites
    sites = word(len(active_sites))  

    TX_SPD_rate = TX_SPD
    RX_SPD_rate = RX_SPD
    Freq_com    = Freq
   loopcont  = true
   SiteCheck  = false 
    active_sites = get_active_sites
    sites = word(len(active_sites))  

-----Dut power up function
   DutPowerUp(vio, v18, vcore, "I2C", "TP_GMSL2",POWERUP)------------- DutPowerUp(vio, v18, vcore, "UART", "TP_GMSL1",POWERUP)

--------powerup_dnut_vdd_vterm(VDD_SET, VTERM_SET)
   if   POWERUP then
        powerup_dnut_vdd_vterm(1.2,1.2)

-------Connect TX/RX of Dut and DNUT to FPGA
        close  cbit MFP_LT_RELAY + DNUT_RXTX_RELAY + I2C_LT_CB + MFP_LT_K12_RELAY
        close  cbit DNUT_RXTX_RELAY
-- --For checking I2C pass through      
        close  cbit  I2C1_LT_CB + I2C2_FT2_LT_CB
        fpga_Set_DNUT_Pins("FPGA1", 0,0, 1, 1, TRUE)  -- UART/TP/GMSL2=1/RATE=0(6 Gig link)               
        wait(6ms)
        fpga_set_UART_Frequency("FPGA1", Freq)
        fpga_set_I2C_Frequency("FPGA1", Freq)
        fpga_UART_Write("FPGA1","DES", DESA_ID, DR_REG6, 1, 16#CB)--9B  need to write to 0xCB first otherwise cannot communication after change to I2C mode
        fpga_UART_Write("FPGA1","DES", DESA_ID, DR_REG6, 1, 16#DB)--9B

   end_if  
 

    if LinkRset then 
-------Connect TX/RX of Dut and DNUT to FPGA
        close  cbit MFP_LT_RELAY + DNUT_RXTX_RELAY + I2C_LT_CB+ MFP_LT_K12_RELAY
        close  cbit DNUT_RXTX_RELAY
-- --For checking I2C pass through      
        close  cbit  I2C1_LT_CB + I2C2_FT2_LT_CB

        wait(4ms)
----Make sure both are in i2c mode
        fpga_set_UART_Frequency("FPGA1", Freq)
        fpga_set_I2C_Frequency("FPGA1", Freq)
 
        fpga_UART_Write("FPGA1","SER", SER_ID, DR_REG6, 1, 16#DB) -------9b
        fpga_UART_Write("FPGA1","DES", DESA_ID, DR_REG6, 1, 16#DB)-------9b
        fpga_I2C_Write("FPGA1","SER", SER_ID, DR_REG6, 1, 16#DB)-------9b
        fpga_I2C_Write("FPGA1","DES", DESA_ID, DR_REG6, 1, 16#DB)-------9b
--         fpga_set_UART_Frequency("FPGA1", Freq)
--         fpga_set_I2C_Frequency("FPGA1", Freq)

--- Set SER and DES for coax or tp mode using FPGA
        if TP_COAX[1:2] = "TP" then
            fpga_I2C_Write("FPGA1","SER", SER_ID, 16#11, 1, 0x0A)                      ---- TP mode 0x11                            
            fpga_I2C_Write("FPGA1","DES", DESA_ID, 16#11, 1, 0x0A)                    ---- TP mode 0x11        
            link_type = 1 
        -- open termination relay at negative SL
            open cbit    CB2_SLDC            --FX_RELAYS 
            open cbit COAXB_M_RELAY             --OVI_RELAYS
            wait(5ms)                
        else
            fpga_I2C_Write("FPGA1","SER", SER_ID, 16#11, 1, 0x0F)                      ---- coax mode 0x11                    
            fpga_I2C_Write("FPGA1","DES", DESA_ID, 16#11, 1, 0x0F)                    ---- coax mode 0x11
            link_type = 0                
            -- close termination relay at negative SL
            close  cbit CB2_SLDC                     --OVI_RELAYS
            close cbit COAXB_M_RELAY                --OVI_RELAYS
         wait(5ms)               
        end_if 

-- ------ Set GMSL link forward and backward speed.

        if TX_SPD = 6GHz then
            ser_tx_speed = 0x8
            des_rx_speed = 0x2
        elseif      TX_SPD = 3GHz then
            ser_tx_speed = 0x4
            des_rx_speed = 0x1            
        elseif      TX_SPD = 1.5GHz then 
            ser_tx_speed = 0x0
            des_rx_speed = 0x0                      
       end_if  

       if RX_SPD = 1.5GHz then
            ser_rx_speed = 0x3
            des_tx_speed = 0xC
       elseif      RX_SPD = 0.75GHz then
            ser_rx_speed = 0x2
            des_tx_speed = 0x8      
      
       elseif      RX_SPD = 0.375GHz then
            ser_rx_speed = 0x1
            des_tx_speed = 0x4          
       elseif      RX_SPD = 0.1875GHz then
            ser_rx_speed = 0x0
            des_tx_speed = 0x0               
       end_if 
       
        ser_link_speed_code = ser_rx_speed + ser_tx_speed
        des_link_speed_code = des_rx_speed + des_tx_speed
    
    
--- Program link rate
        fpga_I2C_Write("FPGA1","SER", SER_ID, 16#01, 1, ser_link_speed_code  )               ---- SER GMSL link speed    
        fpga_I2C_Write("FPGA1","DES", DESA_ID, 16#01, 1, des_link_speed_code  )             ---- DES GMSL link speed
        wait(20mS)
--- Write to reg10 to update link speed setting     
    -- write Reg0x10 to update to COAX mode
        fpga_I2C_Write("FPGA1","DES", DESA_ID, 16#10, 1, 0x00)             -- Set auto link config and one shot
        fpga_I2C_Write("FPGA1","SER", SER_ID, 16#10, 1, 0x30)             -- Set auto link config and one shot
        ser_read =  fpga_I2C_Read("FPGA1", "SER", SER_ID, 0x10, 1)        -- self adjust back to 0x01    
    end_if

--  ser_local_read =  fpga_I2C_Read("FPGA1", "SER", SER_ID, 0, 1)      -- for SER lock bit, good if 0xDA    
--  ser_local_read =  fpga_I2C_Read("FPGA1", "DES", DESA_ID, 0, 1)      -- for SER lock bit, good if 0xDA    
--    fpga_set_I2C_Frequency("FPGA1", 100KHz)

 --   ser_local_read =  fpga_I2C_Read("FPGA1", "SER", SER_ID, SR_CTRL3, 1)      -- for SER lock bit, good if 0xDA               
--     site = active_sites[1]
--     for i = 1 to 500 do
--             reg_val15      =  fpga_I2C_Read("FPGA1", "DES", DESA_ID, DR_CTRL3, 1)      -- DES lock bit, 0xDA expected   
--             if reg_val15[site] = 0xCA or reg_val15[site] = 0xCE then
--                 break
--             else
--                 wait(2ms)
--             end_if
--    end_for         
--    wait(0ms)
--    ser_local_read =  fpga_I2C_Read("FPGA1", "SER", SER_ID, SR_CTRL3 , 1)      -- for SER lock bit, good if 0xDA         
   lowword =  fpga_I2C_Read("FPGA1", "SER", SER_ID, 0x13, 1)      -- for SER lock bit, good if 0xDA 
   reg_val15  = fpga_I2C_Read("FPGA1", "DES", DESA_ID, 0x13, 1)   -- DES lock bit, 0xCA expected   

    while( loopcont) do
        for idx = 1 to sites do 
            site = active_sites[idx]
                if  (lowword[site] = 0xde  OR lowword[site] =0xda  OR lowword[site] =0xCa OR lowword[site] =0xCE OR lowword[site] =0xEa OR lowword[site] =0xEE) and not SiteCheck[site] then
                    sitecount = sitecount + 1
                    SiteCheck[site] = true     
                end_if
                if sitecount = sites then
                    loopcont = false
                end_if     
            count = count + 1
            if count > 200 then
                loopcont  = false
            end_if
            if loopcont  then
                wait(1ms)
                lowword =  fpga_I2C_Read("FPGA1", "SER", SER_ID, 0x13, 1)      -- for SER lock bit, good if 0xDA 
            end_if
            
        end_for            
 
    end_while
     ser_local_read =  fpga_I2C_Read("FPGA1", "SER", SER_ID, 0x13, 1)      -- for SER lock bit, good if 0xDA  
     reg_val15  = fpga_I2C_Read("FPGA1", "DES", DESA_ID, 0x13, 1)   -- DES lock bit, 0xCA expected 




   for idxs = 1 to len(active_sites) do
      site = active_sites[idxs]
      ireg_val1[site]  = integer(ser_local_read[site])
      ireg_val15[site] = integer(reg_val15[site])      
   end_for    


 
     fpga_set_I2C_Frequency("FPGA1", Freq)
   
    wait(3ms)    

   ser_read = 0x00        -- initialization needed.
   ser_read_reg1 = 0x00
   ser_read_reg2 = 0xFF
         
    w_r_delay = 200us

      wait(w_r_delay)  

 
------------Turn on I2C pass through chan 1 and 2
     fpga_I2C_Write( "FPGA1" , "DES"   , DESA_ID  , DR_REG5, 1, 16#0)
-- 
-- 
  fpga_I2C_Write( "FPGA1" , "DES"   , DESA_ID  , DR_GPIO_A_14, 1, 0x81)
  fpga_I2C_Write( "FPGA1" , "DES"   , DESA_ID  , DR_GPIO_A_15, 1, 0x81)
--   fpga_I2C_Write( "FPGA1" , "DES"   ,SER_ID, SR_GPIO_A_17, 1, 0x81)
--   fpga_I2C_Write( "FPGA1" , "DES"   ,SER_ID, SR_GPIO_A_18, 1, 0x81)
-- 
-- 
--   oreg_reg_val =0 
--    fpga_write_register("FPGA1", 0x76,oreg_reg_val )
   fpga_I2C_Write("FPGA1", "DES", DESA_ID, 0x03, 1, 0x0)  ----- Has to be before turn on i2c pt
   fpga_I2C_Write("FPGA1", "SER", SER_ID, SR_REG1, 1, 0xC8)---CB  
   fpga_I2C_Write("FPGA1", "DES", DESA_ID, DR_REG1, 1, 0xC2)----CE 

----Check pass through main channel
   fpga_I2C_Write("FPGA1", "SER", 0xA4, 0x01, 1, 0x55)                        ----Ser program 0x55 to remote main channel
   desdata =  fpga_I2C_Read("FPGA1", "SER", 0xA4, 0x01, 1)                     ----Ser read back 0x55 from remote device
   fpga_I2C_Write("FPGA1", "DES", 0xA2, 0x01, 1, 0xAA)                      ----Des Program 0xAA to remote 
   serdata =  fpga_I2C_Read("FPGA1", "DES", 0xA2, 0x01, 1)                  ----Des read back 0x55 from remote device main channel
 

--------PT1
  fpga_I2C_Write("FPGA1", "SER_PT1", 0xA8, 0x00, 1, 0x55)                   ----Ser program 0x55 to remote  PT1
  desdataPT1 =  fpga_I2C_Read("FPGA1", "SER_PT1", 0xA8, 0x00, 1)             ----Ser read back 0x55 from remote device PT1

  fpga_I2C_Write("FPGA1", "DES_PT1", 0xA6, 0x01, 1, 0xAA)                   ----Des Program 0xAA to remote  PT1
  serdataPT1 =  fpga_I2C_Read("FPGA1", "DES_PT1", 0xA6, 0x01, 1)            ----Des read back 0xAA from remote device PT1
-----PT2 
  fpga_I2C_Write("FPGA1", "SER_PT2", 0xAC, 0x01, 1, 0x55)                   ----Ser program 0x55 to remote  PT1
  desdataPT2 =  fpga_I2C_Read("FPGA1", "SER_PT2", 0xAC, 0x01, 1)             ----Ser read back 0x55 from remote device PT1
    
  fpga_I2C_Write("FPGA1", "DES_PT2", 0xAA, 0x01, 1, 0xAA)                 ----Des Program 0xAA to remote  PT2
  serdataPT2 =  fpga_I2C_Read("FPGA1", "DES_PT2", 0xAA, 0x01, 1)             ----Des read back 0xAA from remote device PT2  

----reset all to 0
  fpga_I2C_Write("FPGA1", "SER", 0xA4, 0x01, 1, 0x0)
  fpga_I2C_Write("FPGA1", "DES", 0xA2, 0x01, 1, 0x0)  
  fpga_I2C_Write("FPGA1", "SER_PT1", 0xA8, 0x01, 1, 0x0)
  fpga_I2C_Write("FPGA1", "DES_PT1", 0xA6, 0x01, 1, 0x0)
  fpga_I2C_Write("FPGA1", "SER_PT2", 0xAC, 0x01, 1, 0x0) 
  fpga_I2C_Write("FPGA1", "DES_PT2", 0xAA, 0x01, 1, 0x0 )     
  
-- ------------------------





    if POWERDOWN then   
--        powerdown_device(POWERDOWN)
        open  cbit MFP_LT_RELAY + DNUT_RXTX_RELAY + I2C_LT_CB + MFP_LT_K12_RELAY------for now
        open  cbit CB2_SLDC                     --OVI_RELAYS
        open cbit COAXB_M_RELAY                --OVI_RELAYS
        open  cbit  I2C1_LT_CB + I2C2_FT2_LT_CB    
        wait(5ms)
--         powerup_dnut_vdd_vterm(0.0,0.0)
-----------  --fpga_Set_DNUT_Pins("FPGA1", CFG1, CFG0, PWDN, latch)
        fpga_Set_DNUT_Pins("FPGA1", 0,0, 0, 0, TRUE)  -- UART/TP/GMSL2=1/RATE=0(6 Gig link)               
                         
        powerdown_device(POWERDOWN)

    end_if
   for idxs = 1 to len(active_sites) do
     site = active_sites[idxs]
     --ireg_val_ser[site]  = integer(ser_read[site])
     ISerData[site]  = integer(serdata[site])
     ISerDataPT1[site]  = integer(serdataPT1[site])                
     ISerDataPT2[site]  = integer(serdataPT2[site]) 
     IDesData[site]  = integer(desdata[site])
     IDesDataPT1[site]  = integer(desdataPT1[site])
     IDesDataPT2[site]  = integer(desdataPT2[site])
   end_for


   test_value msfloat(TX_SPD_rate)  with TX_SPD_it 
   test_value msfloat(RX_SPD_rate)  with RX_SPD_it
   test_value link_type  with link_type_it    
--    test_value ireg_val1 with ser_lock_it
--    test_value ireg_val15 with des_lock_it 
--DesPT,SerPT,DesPT1,SerPT1,DesP2,SerPT2   
   test_value msfloat(Freq_com) with Freq_it           

   test_value IDesData with DesPT
   test_value ISerData with SerPT
   test_value IDesDataPT1 with DesPT1
   test_value ISerDataPT1 with SerPT1
   test_value IDesDataPT2 with DesPT2
   test_value ISerDataPT2 with SerPT2 
 end_body

procedure DES_SER_Reg_Func(vcore, vio, v18, TX_SPD_it, RX_SPD_it, link_type_it, Freq_it,iser_read_reg1_it,iser_read_reg2_it, TP_COAX,TX_SPD,RX_SPD,Freq,value1,value2, Link_Lock_dly,POWERUP,POWERDOWN,LinkRset)
--------------------------------------------------------------------------------
in float            : vcore, vio, v18
--in_out integer_test : devid_it, dnutid_it, ser_lock_it, des_lock_it,iser_read_reg1_it,iser_read_reg2_it, link_type_it
in_out integer_test :  iser_read_reg1_it, iser_read_reg2_it, link_type_it
in_out float_test   : TX_SPD_it, RX_SPD_it, Freq_it

in string[20]       : TP_COAX
in float            : TX_SPD, RX_SPD, Freq, Link_Lock_dly
in lword            : value1, value2           -- values to write to SER & DESA FPGA internal EEPROM across link
in boolean          : POWERUP,POWERDOWN,LinkRset

local

  multisite lword   : LowerRdWord, UpperRdWord
   
  float             : Vconf0, Vconf1
  multisite lword   : lowword, upperword, des_read0, des_read1, des_read2, des_read, ser_read, ser_local_read, ser_read_reg, ser_read_reg1, ser_read_reg2

  multisite lword   : reg_val, reg_val0, reg_val1, reg_val_ser, reg_val_des
  multisite integer : ireg_val, ireg_val0, ireg_val1, ireg_val_ser, ireg_val_des, ireg_val15, iser_read_reg, iser_read_reg1, iser_read_reg2, link_type
  word              : sites, idx, site
  integer           : idxs
  
  multisite lword   : hizdel_reg_val, oreg_reg_val
  lword             : data
  
  multisite lword   : reg_val11,reg_val12,reg_val13,reg_val14,reg_val15
  lword             : ser_link_speed_code, des_link_speed_code, ser_tx_speed, ser_rx_speed, des_tx_speed, des_rx_speed
  lword             : number_of_lane, des_csi_mode,des_numb_lane,mipi_speed, ser_csi_mode
  float             : TX_SPD_rate, RX_SPD_rate, Freq_com, w_r_delay 
   boolean         : loopcont
    multisite boolean : SiteCheck
    word            :sitecount,count  
end_local

body
  
    TX_SPD_rate = TX_SPD
    RX_SPD_rate = RX_SPD
    Freq_com    = Freq

    active_sites = get_active_sites
    sites = word(len(active_sites))  

    TX_SPD_rate = TX_SPD
    RX_SPD_rate = RX_SPD
    Freq_com    = Freq

   loopcont  = true
   SiteCheck  = false 

    active_sites = get_active_sites
    sites = word(len(active_sites))  

-----Dut power up function
   DutPowerUp(vio, v18, vcore, "UART", "TP_GMSL2",POWERUP)------------- DutPowerUp(vio, v18, vcore, "UART", "TP_GMSL1",POWERUP)


--------powerup_dnut_vdd_vterm(VDD_SET, VTERM_SET)
   if   POWERUP then
        powerup_dnut_vdd_vterm(1.2,1.2)
        fpga_Set_DNUT_Pins("FPGA1", 0,0, 1, 1, TRUE)  -- UART/TP/GMSL2=1/RATE=0(6 Gig link)          ----MPW5 and up        
        wait(6ms)
   end_if   
    if LinkRset then 
-----------  --fpga_Set_DNUT_Pins("FPGA1", CFG1, CFG0, PWDN, latch)




-------Connect TX/RX of Dut and DNUT to FPGA
        close  cbit MFP_LT_RELAY + DNUT_RXTX_RELAY + I2C_LT_CB + MFP_LT_K12_RELAY   ----MFP_LT_K12 is for switch fpga control rxsda txscl  Mt. only with rev b hardware.
        wait(4ms)

--         if (Freq = 100KHz) then
--     
--             fpga_set_UART_Frequency("FPGA1", 100KHz)
--         elseif (Freq = 400KHz) then
--             fpga_set_I2C_Frequency("FPGA1", 400KHz)
--         elseif (Freq = 1MHz) then
--             fpga_set_UART_Frequency("FPGA1", 1MHz)
--         else
--             fpga_set_UART_Frequency("FPGA1", 2MHz)
--         end_if
--         wait(1ms)    
        fpga_set_UART_Frequency("FPGA1", Freq)
--- Set SER and DES for coax or tp mode using FPGA
        if TP_COAX[1:2] = "TP" then
            fpga_UART_Write("FPGA1","SER", SER_ID, 16#11, 1, 0x0A)                      ---- TP mode 0x11                            
            fpga_UART_Write("FPGA1","DES", DESA_ID, 16#11, 1, 0x0A)                    ---- TP mode 0x11        
            link_type = 1 
        -- open termination relay at negative SL
            open cbit    CB2_SLDC            --FX_RELAYS 
            open cbit COAXB_M_RELAY             --OVI_RELAYS
            wait(5ms)                
        else
            fpga_UART_Write("FPGA1","SER", SER_ID, 16#11, 1, 0x0F)                      ---- coax mode 0x11                    
            fpga_UART_Write("FPGA1","DES", DESA_ID, 16#11, 1, 0x0F)                    ---- coax mode 0x11
            link_type = 0                
            -- close termination relay at negative SL
            close  cbit CB2_SLDC                     --OVI_RELAYS
            close cbit COAXB_M_RELAY                --OVI_RELAYS
         wait(5ms)               
        end_if 

-- ------ Set GMSL link forward and backward speed.

        if TX_SPD = 6GHz then
            ser_tx_speed = 0x8
            des_rx_speed = 0x2
        elseif      TX_SPD = 3GHz then
            ser_tx_speed = 0x4
            des_rx_speed = 0x1            
        elseif      TX_SPD = 1.5GHz then 
            ser_tx_speed = 0x0
            des_rx_speed = 0x0                      
       end_if  

       if RX_SPD = 1.5GHz then
            ser_rx_speed = 0x3
            des_tx_speed = 0xC
       elseif      RX_SPD = 0.75GHz then
            ser_rx_speed = 0x2
            des_tx_speed = 0x8      
      
       elseif      RX_SPD = 0.375GHz then
            ser_rx_speed = 0x1
            des_tx_speed = 0x4          
       elseif      RX_SPD = 0.1875GHz then
            ser_rx_speed = 0x0
            des_tx_speed = 0x0               
       end_if 
       
        ser_link_speed_code = ser_rx_speed + ser_tx_speed
        des_link_speed_code = des_rx_speed + des_tx_speed
    
    
--- Program link rate
        fpga_UART_Write("FPGA1","SER", SER_ID, 16#01, 1, ser_link_speed_code  )               ---- SER GMSL link speed    
        fpga_UART_Write("FPGA1","DES", DESA_ID, 16#01, 1, des_link_speed_code  )             ---- DES GMSL link speed
        wait(10mS)
--- Write to reg10 to update link speed setting     
    -- write Reg0x10 to update to COAX mode
        fpga_UART_Write("FPGA1","DES", DESA_ID, DR_CTRL0, 1, 0x20)
        fpga_UART_Write("FPGA1","SER", SER_ID, SR_CTRL0, 1, 0x30)             -- Set auto link config and one shot
        ser_read =  fpga_UART_Read("FPGA1", "SER", SER_ID,SR_CTRL0 , 1)        -- self adjust back to 0x01    
    end_if




--    ser_local_read =  fpga_UART_Read("FPGA1", "SER", SER_ID, 0x13, 1)      -- for SER lock bit, good if 0xDA               
--     site = active_sites[1]
--     for i = 1 to 300 do
--             reg_val15      =  fpga_UART_Read("FPGA1", "DES", DESA_ID, 0x13, 1)      -- DES lock bit, 0xDA expected   
--             if reg_val15[site] = 0xCA  or reg_val15[site] = 0xCE then
--                 break
--             else
--                 wait(2ms)
--             end_if
--    end_for         
   lowword =  fpga_UART_Read("FPGA1", "SER", SER_ID, 0x13, 1)      -- for SER lock bit, good if 0xDA 
   reg_val15  = fpga_UART_Read("FPGA1", "DES", DESA_ID, 0x13, 1)   -- DES lock bit, 0xCA expected   

    while( loopcont) do
        for idx = 1 to sites do 
            site = active_sites[idx]
                if  (lowword[site] = 0xde  OR lowword[site] =0xda  OR lowword[site] =0xCa OR lowword[site] =0xCE OR lowword[site] =0xEa OR lowword[site] =0xEE) and not SiteCheck[site] then
                    sitecount = sitecount + 1
                    SiteCheck[site] = true     
                end_if
                if sitecount = sites then
                    loopcont = false
                end_if     
            count = count + 1
            if count > 200 then
                loopcont  = false
            end_if
            if loopcont  then
                wait(1ms)
                lowword =  fpga_UART_Read("FPGA1", "SER", SER_ID, 0x13, 1)      -- for SER lock bit, good if 0xDA 
            end_if
            
        end_for            
 
    end_while
     ser_local_read =  fpga_UART_Read("FPGA1", "SER", SER_ID, 0x13, 1)      -- for SER lock bit, good if 0xDA  
     reg_val15  = fpga_UART_Read("FPGA1", "DES", DESA_ID, 0x13, 1)   -- DES lock bit, 0xCA expected 

   for idxs = 1 to len(active_sites) do
      site = active_sites[idxs]
      ireg_val1[site]  = integer(ser_local_read[site])
      ireg_val15[site] = integer(reg_val15[site])      
   end_for    


    fpga_set_UART_Frequency("FPGA1", Freq)
    wait(3ms)    

   ser_read = 0x00        -- initialization needed.
   ser_read_reg1 = 0x00
   ser_read_reg2 = 0xFF
         
--       if (Freq = 100KHz) then
--          w_r_delay = 5ms
--       else
--          w_r_delay = 5ms                
--       end_if
    w_r_delay = 200us
      --ser_read_reg =  fpga_UART_Read("FPGA1", "SER", DESA_ID, 16#01C0, 1)  -- FPGA read regs from SER across link before write 
      --wait(w_r_delay)
      fpga_UART_Write("FPGA1","DES", SER_ID, 16#01C0, 1, 16#7F)             -- write 0x7F to reg, inverted all bits except bit7(can't change)
      wait(w_r_delay) 
      --ser_read_reg1 =  fpga_UART_Read("FPGA1", "SER", DESA_ID, 16#01C0, 1)   -- need to read twice at 100KHz, check with Aldo why???            
      ser_read_reg1 =  fpga_UART_Read("FPGA1", "DES", SER_ID, 16#01C0, 1)   -- FPGA read regs from DES across link after write 
      wait(w_r_delay)    
      fpga_UART_Write("FPGA1","DES", SER_ID, 16#01C0, 1, 16#00)             -- reset to default value to prepare for next test
      wait(w_r_delay)      
      ser_read_reg2 =  fpga_UART_Read("FPGA1", "DES", SER_ID, 16#01C0, 1)   -- FPGA read regs from DES across link after write reset      
      wait(w_r_delay)      


    if POWERDOWN then   
        powerdown_device(POWERDOWN)
        
         powerup_dnut_vdd_vterm(0.0,0.0)
-----------  --fpga_Set_DNUT_Pins("FPGA1", CFG1, CFG0, PWDN, latch)
        fpga_Set_DNUT_Pins("FPGA1", 0,0, 0, 0, TRUE)  -- UART/TP/GMSL2=1/RATE=0(6 Gig link)               
        wait(6ms)                 
        open digital cbit MFP_LT_RELAY + DNUT_RXTX_RELAY + I2C_LT_CB ------for now
        open  cbit CB2_SLDC                     --OVI_RELAYS
        open cbit COAXB_M_RELAY                --OVI_RELAYS
    
    end_if
   for idxs = 1 to len(active_sites) do
     site = active_sites[idxs]
     --ireg_val_ser[site]  = integer(ser_read[site])
     iser_read_reg1[site]  = integer(ser_read_reg1[site])
     iser_read_reg2[site]  = integer(ser_read_reg2[site])                
   end_for


   test_value msfloat(TX_SPD_rate)  with TX_SPD_it 
   test_value msfloat(RX_SPD_rate)  with RX_SPD_it
   test_value link_type  with link_type_it    
 --   test_value ireg_val1 with ser_lock_it
--    test_value ireg_val15 with des_lock_it 
   
   test_value msfloat(Freq_com) with Freq_it           
   test_value iser_read_reg1 with iser_read_reg1_it
   test_value iser_read_reg2 with iser_read_reg2_it
 
 end_body

procedure SER_DESA_I2C_Func (vcore, vio, v18, TX_SPD_it, RX_SPD_it, link_type_it, Freq_it,iser_read_reg1_it,iser_read_reg2_it,ides_read_reg1_it, ides_read_reg2_it, TP_COAX,TX_SPD,RX_SPD,Freq,value1,value2, Link_Lock_dly,POWERUP,POWERDOWN,LinkRset)
--------------------------------------------------------------------------------
in float            : vcore, vio, v18
--in_out integer_test : devid_it, dnutid_it, ser_lock_it, des_lock_it,iser_read_reg1_it,iser_read_reg2_it, link_type_it
in_out integer_test : iser_read_reg1_it, iser_read_reg2_it, link_type_it,ides_read_reg1_it, ides_read_reg2_it
in_out float_test   : TX_SPD_it, RX_SPD_it, Freq_it

in string[20]       : TP_COAX
in float            : TX_SPD, RX_SPD, Freq, Link_Lock_dly
in lword            : value1, value2           -- values to write to SER & DESA FPGA internal EEPROM across link
in boolean          : POWERUP,POWERDOWN,LinkRset

local

  multisite lword   : LowerRdWord, UpperRdWord
   
  float             : Vconf0, Vconf1
  multisite lword   : lowword, upperword, des_read0, des_read1, des_read2, des_read, ser_read, ser_local_read, ser_read_reg, ser_read_reg1, ser_read_reg2, des_read_reg1, des_read_reg2

  multisite lword   : reg_val, reg_val0, reg_val1, reg_val_ser, reg_val_des
  multisite integer : ireg_val, ireg_val0, ireg_val1, ireg_val_ser, ireg_val_des, ireg_val15, iser_read_reg, iser_read_reg1, iser_read_reg2, link_type, ides_read_reg1, ides_read_reg2
  word              : sites, idx, site
  integer           : idxs
  
  multisite lword   : hizdel_reg_val, oreg_reg_val
  lword             : data
  
  multisite lword   : reg_val11,reg_val12,reg_val13,reg_val14,reg_val15
  lword             : ser_link_speed_code, des_link_speed_code, ser_tx_speed, ser_rx_speed, des_tx_speed, des_rx_speed
  lword             : number_of_lane, des_csi_mode,des_numb_lane,mipi_speed, ser_csi_mode
  float             : TX_SPD_rate, RX_SPD_rate, Freq_com, w_r_delay 
   boolean         : loopcont
    multisite boolean : SiteCheck
    word            :sitecount,count  
end_local

body
  
    TX_SPD_rate = TX_SPD
    RX_SPD_rate = RX_SPD
    Freq_com    = Freq

    active_sites = get_active_sites
    sites = word(len(active_sites))  

    TX_SPD_rate = TX_SPD
    RX_SPD_rate = RX_SPD
    Freq_com    = Freq
   loopcont  = true
   SiteCheck  = false 
    active_sites = get_active_sites
    sites = word(len(active_sites))  

-----Dut power up function
   DutPowerUp(vio, v18, vcore, "I2C", "TP_GMSL2",POWERUP)------------- DutPowerUp(vio, v18, vcore, "UART", "TP_GMSL1",POWERUP)
        fpga_set_UART_Frequency("FPGA1", Freq)
        fpga_set_I2C_Frequency("FPGA1", Freq)


--------powerup_dnut_vdd_vterm(VDD_SET, VTERM_SET)
   if   POWERUP then
        powerup_dnut_vdd_vterm(1.2,1.2)

-------Connect TX/RX of Dut and DNUT to FPGA
        close cbit MFP_LT_RELAY + DNUT_RXTX_RELAY + I2C_LT_CB + MFP_LT_K12_RELAY   ----MFP_LT_K12 is for switch fpga control rxsda txscl  Mt. only with rev b hardware.
        close cbit DNUT_RXTX_RELAY
-- --For checking I2C pass through      
        close cbit  I2C1_LT_CB + I2C2_FT2_LT_CB
        fpga_Set_DNUT_Pins("FPGA1", 0, 0, 1, 1, TRUE)  -- UART/TP/GMSL2=1/RATE=0(6 Gig link)               
        wait(6ms)
ser_read =  fpga_UART_Read("FPGA1", "DES", DESA_ID,DR_REG6 , 1) 
--        fpga_UART_Write("FPGA1","DES", DESA_ID, 1, 1, 16#12)  ------------in production rev has to disable link control first otherwise after change to I2C mode, can not commnicate to part. 
        fpga_UART_Write("FPGA1","DES", DESA_ID, DR_REG6, 1, 16#CB)--9B  need to write to 0xCB first otherwise cannot communication after change to I2C mode
        fpga_UART_Write("FPGA1","DES", DESA_ID, DR_REG6, 1, 16#DB)--9B
        wait(1ms)
ser_read =  fpga_I2C_Read("FPGA1", "DES", DESA_ID, 0x0, 1)        

   end_if  

    if LinkRset then 
-------Connect TX/RX of Dut and DNUT to FPGA
        close digital cbit MFP_LT_RELAY + DNUT_RXTX_RELAY + I2C_LT_CB + MFP_LT_K12_RELAY   ----MFP_LT_K12 is for switch fpga control rxsda txscl  Mt. only with rev b hardware.
        close digital cbit DNUT_RXTX_RELAY
-- --For checking I2C pass through      
        close digital cbit  I2C1_LT_CB + I2C2_FT2_LT_CB

        wait(4ms)
----Make sure both are in i2c mode
        fpga_UART_Write("FPGA1","SER", SER_ID, DR_REG6, 1, 16#DB)
        fpga_UART_Write("FPGA1","DES", DESA_ID, DR_REG6, 1, 16#DB)
        fpga_I2C_Write("FPGA1","SER", SER_ID, DR_REG6, 1, 16#DB)
        fpga_I2C_Write("FPGA1","DES", DESA_ID, DR_REG6, 1, 16#DB)
        fpga_set_UART_Frequency("FPGA1", Freq)
        fpga_set_I2C_Frequency("FPGA1", Freq)

--- Set SER and DES for coax or tp mode using FPGA
        if TP_COAX[1:2] = "TP" then
            fpga_I2C_Write("FPGA1","SER", SER_ID, 16#11, 1, 0x0A)                      ---- TP mode 0x11                            
            fpga_I2C_Write("FPGA1","DES", DESA_ID, 16#11, 1, 0x0A)                    ---- TP mode 0x11        
            link_type = 1 
        -- open termination relay at negative SL
            open cbit    CB2_SLDC            --FX_RELAYS 
            open cbit COAXB_M_RELAY             --OVI_RELAYS
            wait(5ms)                
        else
            fpga_I2C_Write("FPGA1","SER", SER_ID, 16#11, 1, 0x0F)                      ---- coax mode 0x11                    
            fpga_I2C_Write("FPGA1","DES", DESA_ID, 16#11, 1, 0x0F)                    ---- coax mode 0x11
            link_type = 0                
            -- close termination relay at negative SL
            close  cbit CB2_SLDC                     --OVI_RELAYS
            close cbit COAXB_M_RELAY                --OVI_RELAYS
         wait(5ms)               
        end_if 

-- ------ Set GMSL link forward and backward speed.

        if TX_SPD = 6GHz then
            ser_tx_speed = 0x8
            des_rx_speed = 0x2
        elseif      TX_SPD = 3GHz then
            ser_tx_speed = 0x4
            des_rx_speed = 0x1            
        elseif      TX_SPD = 1.5GHz then 
            ser_tx_speed = 0x0
            des_rx_speed = 0x0                      
       end_if  

       if RX_SPD = 1.5GHz then
            ser_rx_speed = 0x3
            des_tx_speed = 0xC
       elseif      RX_SPD = 0.75GHz then
            ser_rx_speed = 0x2
            des_tx_speed = 0x8      
      
       elseif      RX_SPD = 0.375GHz then
            ser_rx_speed = 0x1
            des_tx_speed = 0x4          
       elseif      RX_SPD = 0.1875GHz then
            ser_rx_speed = 0x0
            des_tx_speed = 0x0               
       end_if 
       
        ser_link_speed_code = ser_rx_speed + ser_tx_speed
        des_link_speed_code = des_rx_speed + des_tx_speed
    
    
--- Program link rate
        fpga_I2C_Write("FPGA1","SER", SER_ID, 16#01, 1, ser_link_speed_code  )               ---- SER GMSL link speed    
        fpga_I2C_Write("FPGA1","DES", DESA_ID, 16#01, 1, des_link_speed_code  )             ---- DES GMSL link speed
        wait(2mS)
--- Write to reg10 to update link speed setting     
    -- write Reg0x10 to update to COAX mode

        fpga_I2C_Write("FPGA1","DES", DESA_ID, 16#10, 1, 0x00)             -- Set auto link config and one shot 
        fpga_I2C_Write("FPGA1","SER", SER_ID,  16#10, 1, 0x30)             -- Set auto link config and one shot

--        ser_read =  fpga_I2C_Read("FPGA1", "SER", SER_ID, 0x10, 1)        -- self adjust back to 0x01    
    end_if

-- 
-- 
--    ser_local_read =  fpga_I2C_Read("FPGA1", "SER", SER_ID, SR_CTRL3, 1)      -- for SER lock bit, good if 0xDA               
--     site = active_sites[1]
--     for i = 1 to 300 do
--             reg_val15      =  fpga_I2C_Read("FPGA1", "DES", DESA_ID, DR_CTRL3, 1)      -- DES lock bit, 0xDA expected   
--             if reg_val15[site] = 0xCA  or reg_val15[site] = 0xCE then
--                 break
--             else
--                 wait(2ms)
--             end_if
--    end_for         
   lowword =  fpga_I2C_Read("FPGA1", "SER", SER_ID, 0x13, 1)      -- for SER lock bit, good if 0xDA 
   reg_val15  = fpga_I2C_Read("FPGA1", "DES", DESA_ID, 0x13, 1)   -- DES lock bit, 0xCA expected   

    while( loopcont) do
        for idx = 1 to sites do 
            site = active_sites[idx]
                if  (lowword[site] = 0xde  OR lowword[site] =0xda  OR lowword[site] =0xCa OR lowword[site] =0xCE OR lowword[site] =0xEa OR lowword[site] =0xEE) and not SiteCheck[site] then
                    sitecount = sitecount + 1
                    SiteCheck[site] = true     
                end_if
                if sitecount = sites then
                    loopcont = false
                end_if     
            count = count + 1
            if count > 200 then
                loopcont  = false
            end_if
            if loopcont  then
                wait(1ms)
                lowword =  fpga_I2C_Read("FPGA1", "SER", SER_ID, 0x13, 1)      -- for SER lock bit, good if 0xDA 
            end_if
            
        end_for            
 
    end_while
     ser_local_read =  fpga_I2C_Read("FPGA1", "SER", SER_ID, 0x13, 1)      -- for SER lock bit, good if 0xDA  
     reg_val15  = fpga_I2C_Read("FPGA1", "DES", DESA_ID, 0x13, 1)   -- DES lock bit, 0xCA expected 


   wait(0ms)
   ser_local_read =  fpga_I2C_Read("FPGA1", "SER", SER_ID, SR_CTRL3 , 1)      -- for SER lock bit, good if 0xDA         
   for idxs = 1 to len(active_sites) do
      site = active_sites[idxs]
      ireg_val1[site]  = integer(ser_local_read[site])
      ireg_val15[site] = integer(reg_val15[site])      
   end_for    


    fpga_set_UART_Frequency("FPGA1", Freq)
    fpga_set_I2C_Frequency("FPGA1", Freq)

    wait(3ms)    

   ser_read = 0x00        -- initialization needed.
   ser_read_reg1 = 0x00
   ser_read_reg2 = 0xFF
         
 --      if (Freq = 100KHz) then
--          w_r_delay = 5ms
--       else
--          w_r_delay = 5ms                
--       end_if
w_r_delay = 200us
 
      fpga_I2C_Write("FPGA1","SER", DESA_ID, 16#01C0, 1, 16#7F)             -- write 0x7F to reg, inverted all bits except bit7(can't change)
      wait(w_r_delay) 
----read from ser to des          
      ser_read_reg1 =  fpga_I2C_Read("FPGA1", "SER", DESA_ID, 16#01C0, 1)   -- FPGA read regs from SER across link after write 
      wait(w_r_delay)    
      fpga_I2C_Write("FPGA1","SER", DESA_ID, 16#01C0, 1, 16#00)             -- reset to default value to prepare for next test
      wait(w_r_delay)      
      ser_read_reg2 =  fpga_I2C_Read("FPGA1", "SER", DESA_ID, 16#01C0, 1)   -- FPGA read regs from SER across link after write reset      
      wait(w_r_delay)      

      fpga_I2C_Write("FPGA1","DES", SER_ID, 16#01C0, 1, 16#7F)             -- write 0x7F to reg, inverted all bits except bit7(can't change)
      wait(w_r_delay) 
 ----Read from des to ser         
      des_read_reg1 =  fpga_I2C_Read("FPGA1", "DES", SER_ID, 16#01C0, 1)   -- FPGA read regs from DES across link after write 
      wait(w_r_delay)    
      fpga_I2C_Write("FPGA1","DES", SER_ID, 16#01C0, 1, 16#00)             -- reset to default value to prepare for next test
      wait(w_r_delay)      
      des_read_reg2 =  fpga_I2C_Read("FPGA1", "DES", SER_ID, 16#01C0, 1)   -- FPGA read regs from DES across link after write reset      
      wait(w_r_delay)      


    if POWERDOWN then   

--        powerdown_device(POWERDOWN)
        open cbit MFP_LT_RELAY + DNUT_RXTX_RELAY + I2C_LT_CB ------for now
        open  cbit CB2_SLDC                     --OVI_RELAYS
        open cbit COAXB_M_RELAY                --OVI_RELAYS
        open  cbit  I2C1_LT_CB + I2C2_FT2_LT_CB    + MFP_LT_K12_RELAY   ----MFP_LT_K12 is for switch fpga control rxsda txscl  Mt. only with rev b hardware.
        wait(5ms)     
--         powerup_dnut_vdd_vterm(0.0,0.0)
-----------  --fpga_Set_DNUT_Pins("FPGA1", CFG1, CFG0, PWDN, latch)
        fpga_Set_DNUT_Pins("FPGA1", 0,0, 0, 0, TRUE)  -- UART/TP/GMSL2=1/RATE=0(6 Gig link)               
        wait(5ms)         
        powerdown_device(POWERDOWN)
    end_if
   for idxs = 1 to len(active_sites) do
     site = active_sites[idxs]
     --ireg_val_ser[site]  = integer(ser_read[site])
     iser_read_reg1[site]  = integer(ser_read_reg1[site])
     iser_read_reg2[site]  = integer(ser_read_reg2[site])                
     ides_read_reg1[site]  = integer(des_read_reg1[site])
     ides_read_reg2[site]  = integer(des_read_reg2[site])  

   end_for


   test_value msfloat(TX_SPD_rate)  with TX_SPD_it 
   test_value msfloat(RX_SPD_rate)  with RX_SPD_it
   test_value link_type  with link_type_it    
--    test_value ireg_val1 with ser_lock_it
--    test_value ireg_val15 with des_lock_it 
   
   test_value msfloat(Freq_com) with Freq_it           
   test_value iser_read_reg1 with iser_read_reg1_it
   test_value iser_read_reg2 with iser_read_reg2_it
 
 end_body

procedure DES_SER_I2C_Func (vcore, vio, v18, TX_SPD_it, RX_SPD_it, link_type_it, Freq_it,iser_read_reg1_it,iser_read_reg2_it, TP_COAX,TX_SPD,RX_SPD,Freq,value1,value2, Link_Lock_dly,POWERUP,POWERDOWN,LinkRset)
--------------------------------------------------------------------------------
in float            : vcore, vio, v18
--in_out integer_test : devid_it, dnutid_it, ser_lock_it, des_lock_it,iser_read_reg1_it,iser_read_reg2_it, link_type_it
in_out integer_test : iser_read_reg1_it, iser_read_reg2_it, link_type_it
in_out float_test   : TX_SPD_it, RX_SPD_it, Freq_it

in string[20]       : TP_COAX
in float            : TX_SPD, RX_SPD, Freq, Link_Lock_dly
in lword            : value1, value2           -- values to write to SER & DESA FPGA internal EEPROM across link
in boolean          : POWERUP,POWERDOWN,LinkRset

local

  multisite lword   : LowerRdWord, UpperRdWord
   
  float             : Vconf0, Vconf1
  multisite lword   : lowword, upperword, des_read0, des_read1, des_read2, des_read, ser_read, ser_local_read, ser_read_reg, ser_read_reg1, ser_read_reg2

  multisite lword   : reg_val, reg_val0, reg_val1, reg_val_ser, reg_val_des
  multisite integer : ireg_val, ireg_val0, ireg_val1, ireg_val_ser, ireg_val_des, ireg_val15, iser_read_reg, iser_read_reg1, iser_read_reg2, link_type
  word              : sites, idx, site
  integer           : idxs
  
  multisite lword   : hizdel_reg_val, oreg_reg_val
  lword             : data
  
  multisite lword   : reg_val11,reg_val12,reg_val13,reg_val14,reg_val15
  lword             : ser_link_speed_code, des_link_speed_code, ser_tx_speed, ser_rx_speed, des_tx_speed, des_rx_speed
  lword             : number_of_lane, des_csi_mode,des_numb_lane,mipi_speed, ser_csi_mode
  float             : TX_SPD_rate, RX_SPD_rate, Freq_com, w_r_delay 
     boolean         : loopcont
    multisite boolean : SiteCheck
    word            :sitecount,count
end_local

body
  
    TX_SPD_rate = TX_SPD
    RX_SPD_rate = RX_SPD
    Freq_com    = Freq

   loopcont  = true
   SiteCheck  = false 
    active_sites = get_active_sites
    sites = word(len(active_sites))  

    TX_SPD_rate = TX_SPD
    RX_SPD_rate = RX_SPD
    Freq_com    = Freq

    active_sites = get_active_sites
    sites = word(len(active_sites))  

-----Dut power up function
   DutPowerUp(vio, v18, vcore, "I2C", "TP_GMSL2",POWERUP)------------- DutPowerUp(vio, v18, vcore, "UART", "TP_GMSL1",POWERUP)


--------powerup_dnut_vdd_vterm(VDD_SET, VTERM_SET)
   if   POWERUP then
        powerup_dnut_vdd_vterm(1.2,1.2)

-------Connect TX/RX of Dut and DNUT to FPGA
        close  cbit MFP_LT_RELAY + DNUT_RXTX_RELAY + I2C_LT_CB + MFP_LT_K12_RELAY   ----MFP_LT_K12 is for switch fpga control rxsda txscl  Mt. only with rev b hardware.

-- --For checking I2C pass through      
        close  cbit  I2C1_LT_CB + I2C2_FT2_LT_CB
        fpga_Set_DNUT_Pins("FPGA1", 0,0, 1, 1, TRUE)  -- UART/TP/GMSL2=1/RATE=0(6 Gig link)               
        wait(6ms)
        fpga_UART_Write("FPGA1","DES", DESA_ID, DR_REG6, 1, 16#CB)--9B  need to write to 0xCB first otherwise cannot communication after change to I2C mode
        fpga_UART_Write("FPGA1","DES", DESA_ID, DR_REG6, 1, 16#DB)--9B
--        fpga_UART_Write("FPGA1","DES", DESA_ID, DR_REG6, 1, 16#9B)

   end_if  
 

    if LinkRset then 
-------Connect TX/RX of Dut and DNUT to FPGA
        close  cbit MFP_LT_RELAY + DNUT_RXTX_RELAY + I2C_LT_CB+ MFP_LT_K12_RELAY
        
-- --For checking I2C pass through      
        close  cbit  I2C1_LT_CB + I2C2_FT2_LT_CB

        wait(4ms)
----Make sure both are in i2c mode
        fpga_UART_Write("FPGA1","SER", SER_ID, DR_REG6, 1, 16#DB) -------9b
        fpga_UART_Write("FPGA1","DES", DESA_ID, DR_REG6, 1, 16#DB)-------9b
        fpga_I2C_Write("FPGA1","SER", SER_ID, DR_REG6, 1, 16#DB)-------9b
        fpga_I2C_Write("FPGA1","DES", DESA_ID, DR_REG6, 1, 16#DB)-------9b
        fpga_set_UART_Frequency("FPGA1", Freq)
--- Set SER and DES for coax or tp mode using FPGA
        if TP_COAX[1:2] = "TP" then
            fpga_I2C_Write("FPGA1","SER", SER_ID, 16#11, 1, 0x0A)                      ---- TP mode 0x11                            
            fpga_I2C_Write("FPGA1","DES", DESA_ID, 16#11, 1, 0x0A)                    ---- TP mode 0x11        
            link_type = 1 
        -- open termination relay at negative SL
            open cbit    CB2_SLDC            --FX_RELAYS 
            open cbit COAXB_M_RELAY             --OVI_RELAYS
            wait(5ms)                
        else
            fpga_I2C_Write("FPGA1","SER", SER_ID, 16#11, 1, 0x0F)                      ---- coax mode 0x11                    
            fpga_I2C_Write("FPGA1","DES", DESA_ID, 16#11, 1, 0x0F)                    ---- coax mode 0x11
            link_type = 0                
            -- close termination relay at negative SL
            close  cbit CB2_SLDC                     --OVI_RELAYS
            close cbit COAXB_M_RELAY                --OVI_RELAYS
         wait(5ms)               
        end_if 

-- ------ Set GMSL link forward and backward speed.

        if TX_SPD = 6GHz then
            ser_tx_speed = 0x8
            des_rx_speed = 0x2
        elseif      TX_SPD = 3GHz then
            ser_tx_speed = 0x4
            des_rx_speed = 0x1            
        elseif      TX_SPD = 1.5GHz then 
            ser_tx_speed = 0x0
            des_rx_speed = 0x0                      
       end_if  

       if RX_SPD = 1.5GHz then
            ser_rx_speed = 0x3
            des_tx_speed = 0xC
       elseif      RX_SPD = 0.75GHz then
            ser_rx_speed = 0x2
            des_tx_speed = 0x8      
      
       elseif      RX_SPD = 0.375GHz then
            ser_rx_speed = 0x1
            des_tx_speed = 0x4          
       elseif      RX_SPD = 0.1875GHz then
            ser_rx_speed = 0x0
            des_tx_speed = 0x0               
       end_if 
       
        ser_link_speed_code = ser_rx_speed + ser_tx_speed
        des_link_speed_code = des_rx_speed + des_tx_speed
    
    
--- Program link rate
        fpga_I2C_Write("FPGA1","SER", SER_ID, 16#01, 1, ser_link_speed_code  )               ---- SER GMSL link speed    
        fpga_I2C_Write("FPGA1","DES", DESA_ID, 16#01, 1, des_link_speed_code  )             ---- DES GMSL link speed
        wait(20mS)
--- Write to reg10 to update link speed setting     
    -- write Reg0x10 to update to COAX mode
        fpga_I2C_Write("FPGA1","DES", DESA_ID, 16#10, 1, 0x00)    
        fpga_I2C_Write("FPGA1","SER", SER_ID, 16#10, 1, 0x30)             -- Set auto link config and one shot
        ser_read =  fpga_I2C_Read("FPGA1", "SER", SER_ID, 0x10, 1)        -- self adjust back to 0x01    
    end_if



--   ser_local_read =  fpga_I2C_Read("FPGA1", "DES", DESA_ID, 0x0, 1)      -- for SER lock bit, good if 0xDA     

--    ser_local_read =  fpga_I2C_Read("FPGA1", "SER", SER_ID, 0x13, 1)      -- for SER lock bit, good if 0xDA     
--              
--     site = active_sites[1]
--     for i = 1 to 300 do
--             reg_val15      =  fpga_I2C_Read("FPGA1", "DES", DESA_ID, 0x13, 1)      -- DES lock bit, 0xDA expected   
--             if reg_val15[site] = 0xCA or reg_val15[site] = 0xCE then
--                 break
--             else
--                 wait(2ms)
--             end_if
--    end_for         
   lowword =  fpga_I2C_Read("FPGA1", "SER", SER_ID, 0x13, 1)      -- for SER lock bit, good if 0xDA 
   reg_val15  = fpga_I2C_Read("FPGA1", "DES", DESA_ID, 0x13, 1)   -- DES lock bit, 0xCA expected   

    while( loopcont) do
        for idx = 1 to sites do 
            site = active_sites[idx]
                if  (lowword[site] = 0xde  OR lowword[site] =0xda  OR lowword[site] =0xCa OR lowword[site] =0xCE OR lowword[site] =0xEa OR lowword[site] =0xEE) and not SiteCheck[site] then
                    sitecount = sitecount + 1
                    SiteCheck[site] = true     
                end_if
                if sitecount = sites then
                    loopcont = false
                end_if     
            count = count + 1
            if count > 200 then
                loopcont  = false
            end_if
            if loopcont  then
                wait(1ms)
                lowword =  fpga_I2C_Read("FPGA1", "SER", SER_ID, 0x13, 1)      -- for SER lock bit, good if 0xDA 
            end_if
            
        end_for            
 
    end_while
     ser_local_read =  fpga_I2C_Read("FPGA1", "SER", SER_ID, 0x13, 1)      -- for SER lock bit, good if 0xDA  
     reg_val15  = fpga_I2C_Read("FPGA1", "DES", DESA_ID, 0x13, 1)   -- DES lock bit, 0xCA expected 


   for idxs = 1 to len(active_sites) do
      site = active_sites[idxs]
      ireg_val1[site]  = integer(ser_local_read[site])
      ireg_val15[site] = integer(reg_val15[site])      
   end_for    


    fpga_set_UART_Frequency("FPGA1", Freq)
    fpga_set_I2C_Frequency("FPGA1", Freq)

    wait(3ms)    

   ser_read = 0x00        -- initialization needed.
   ser_read_reg1 = 0x00
   ser_read_reg2 = 0xFF
         
  
      fpga_I2C_Write("FPGA1","DES", SER_ID, 16#01C0, 1, 16#7F)             -- write 0x7F to reg, inverted all bits except bit7(can't change)
      wait(w_r_delay) 
         
      ser_read_reg1 =  fpga_I2C_Read("FPGA1", "DES", SER_ID, 16#01C0, 1)   -- FPGA read regs from DES across link after write 
      wait(w_r_delay)    
      fpga_I2C_Write("FPGA1","DES", SER_ID, 16#01C0, 1, 16#00)             -- reset to default value to prepare for next test
      wait(w_r_delay)      
      ser_read_reg2 =  fpga_I2C_Read("FPGA1", "DES", SER_ID, 16#01C0, 1)   -- FPGA read regs from DES across link after write reset      
      wait(w_r_delay)      


    if POWERDOWN then   
        powerdown_device(POWERDOWN)
        open  cbit MFP_LT_RELAY + DNUT_RXTX_RELAY + I2C_LT_CB + MFP_LT_K12_RELAY------for now
        open  cbit CB2_SLDC                     --OVI_RELAYS
        open cbit COAXB_M_RELAY                --OVI_RELAYS
        open  cbit  I2C1_LT_CB + I2C2_FT2_LT_CB    
        
          powerup_dnut_vdd_vterm(0.0,0.0)
-----------  --fpga_Set_DNUT_Pins("FPGA1", CFG1, CFG0, PWDN, latch)
        fpga_Set_DNUT_Pins("FPGA1", 0,0, 0, 0, TRUE)  -- UART/TP/GMSL2=1/RATE=0(6 Gig link)               
        wait(6ms)                
    end_if
   for idxs = 1 to len(active_sites) do
     site = active_sites[idxs]
     --ireg_val_ser[site]  = integer(ser_read[site])
     iser_read_reg1[site]  = integer(ser_read_reg1[site])
     iser_read_reg2[site]  = integer(ser_read_reg2[site])                
   end_for


   test_value msfloat(TX_SPD_rate)  with TX_SPD_it 
   test_value msfloat(RX_SPD_rate)  with RX_SPD_it
   test_value link_type  with link_type_it    
--    test_value ireg_val1 with ser_lock_it
--    test_value ireg_val15 with des_lock_it 
   
   test_value msfloat(Freq_com) with Freq_it           
   test_value iser_read_reg1 with iser_read_reg1_it
   test_value iser_read_reg2 with iser_read_reg2_it
 
 end_body

procedure SPI_Timing_Func (vcore, vio, v18, TX_SPD_it, RX_SPD_it, link_type_it, SPIFrq,TSETUP,THOLD,SCLKPulseHi,SCLKPulseLo,  ReadTsetup,ReadThold,GnGTSetup,GnGTHold,GnGTSetupFt,GnGTHoldFt,TP_COAX,TX_SPD,RX_SPD,Freq,SPI_FREQ, Link_Lock_dly,POWERUP,POWERDOWN,LinkRset)
--------------------------------------------------------------------------------
in float            : vcore, vio, v18
--in_out integer_test : devid_it, dnutid_it, ser_lock_it, des_lock_it,iser_read_reg1_it,iser_read_reg2_it, link_type_it
in_out integer_test :   link_type_it, ReadTsetup,ReadThold
in_out float_test   : TX_SPD_it, RX_SPD_it, SPIFrq
in_out float_test   : TSETUP,THOLD,SCLKPulseHi,SCLKPulseLo,GnGTSetupFt,GnGTHoldFt


in string[20]       : TP_COAX
in float            : TX_SPD, RX_SPD, Freq, Link_Lock_dly,SPI_FREQ,GnGTSetup,GnGTHold
--in lword            : value1, value2           -- values to write to SER & DESA FPGA internal EEPROM across link

in boolean          : POWERUP,POWERDOWN,LinkRset
local

  multisite lword   : LowerRdWord, UpperRdWord, serdata, desdata
   
  float             : spi_freq, spi_period
  multisite lword   : lowword, upperword, des_read0, des_read1, des_read2, des_read, ser_read, ser_local_read, ser_read_reg, ser_read_reg1, ser_read_reg2

  multisite lword   : reg_val, reg_val0, reg_val1, reg_val_ser, reg_val_des
  multisite integer : ireg_val, ireg_val0, ireg_val1, ireg_val_ser, ireg_val_des, ireg_val15, iser_read_reg, iser_read_reg1, iser_read_reg2, link_type,TsetupReadSS1,THoldReadSS1
  word              : sites, idx, site
  integer           : idxs
  
  multisite lword   : hizdel_reg_val, oreg_reg_val
  lword             : data
  
  multisite lword   : reg_val11,reg_val12,reg_val13,reg_val14,reg_val15
  lword             : ser_link_speed_code, des_link_speed_code, ser_tx_speed, ser_rx_speed, des_tx_speed, des_rx_speed
  lword             : number_of_lane, des_csi_mode,des_numb_lane,mipi_speed, ser_csi_mode
  multisite  float             : TX_SPD_rate, RX_SPD_rate, Freq_com, w_r_delay , GnGTSetup_ft,GnGTHold_ft
    multisite float : TSetup , THold ,TSclkHighMin ,TSclkHighMax
   boolean           : char
   boolean         : loopcont
    multisite boolean : SiteCheck
    word            :sitecount,count 
end_local


body
  
    TX_SPD_rate = TX_SPD
    RX_SPD_rate = RX_SPD
    Freq_com    = Freq
   loopcont  = true
   SiteCheck  = false 


    GnGTSetup_ft  = GnGTSetup
    GnGTHold_ft   = GnGTHold
    active_sites = get_active_sites
    sites = word(len(active_sites))  
   get_expr("OpVar_Char", char)
-----Dut power up function
   DutPowerUp(vio, v18, vcore, "UART", "TP_GMSL2",POWERUP)------------- DutPowerUp(vio, v18, vcore, "UART", "TP_GMSL1",POWERUP)


--------powerup_dnut_vdd_vterm(VDD_SET, VTERM_SET)
   if   POWERUP then
        powerup_dnut_vdd_vterm(0.0V,0.0V)   --- reset otherwise at hot not work
        wait(5ms)
        powerup_dnut_vdd_vterm(1.2,1.2)
-----------  --fpga_Set_DNUT_Pins("FPGA1", CFG1, CFG0, PWDN, latch)
        fpga_Set_DNUT_Pins("FPGA1", 0,0, 1, 1, TRUE)  -- UART/TP/GMSL2=1/RATE=0(6 Gig link)               
        wait(6ms)
   end_if   
    if LinkRset then 

-------Connect TX/RX of Dut and DNUT to FPGA
        close  cbit MFP_LT_RELAY + DNUT_RXTX_RELAY + I2C_LT_CB+ MFP_LT_K12_RELAY
        close digital cbit DNUT_RXTX_RELAY
        wait(4ms)

        fpga_set_UART_Frequency("FPGA1", Freq)

--- Set SER and DES for coax or tp mode using FPGA
        if TP_COAX[1:2] = "TP" then
            fpga_UART_Write("FPGA1","SER", SER_ID, 16#11, 1, 0x0A)                      ---- TP mode 0x11                            
            fpga_UART_Write("FPGA1","DES", DESA_ID, 16#11, 1, 0x0A)                    ---- TP mode 0x11        
            link_type = 1 
        -- open termination relay at negative SL
            open cbit    CB2_SLDC            --FX_RELAYS 
            open cbit COAXB_M_RELAY             --OVI_RELAYS
            wait(5ms)                
        else
            fpga_UART_Write("FPGA1","SER", SER_ID, 16#11, 1, 0x0F)                      ---- coax mode 0x11                    
            fpga_UART_Write("FPGA1","DES", DESA_ID, 16#11, 1, 0x0F)                    ---- coax mode 0x11
            link_type = 0                
            -- close termination relay at negative SL
            close  cbit CB2_SLDC                     --OVI_RELAYS
            close cbit COAXB_M_RELAY                --OVI_RELAYS
         wait(5ms)               
        end_if 

-- ------ Set GMSL link forward and backward speed.

        if TX_SPD = 6GHz then
            ser_tx_speed = 0x8
            des_rx_speed = 0x2
        elseif      TX_SPD = 3GHz then
            ser_tx_speed = 0x4
            des_rx_speed = 0x1            
        elseif      TX_SPD = 1.5GHz then 
            ser_tx_speed = 0x0
            des_rx_speed = 0x0                      
       end_if  

       if RX_SPD = 1.5GHz then
            ser_rx_speed = 0x3
            des_tx_speed = 0xC
       elseif      RX_SPD = 0.75GHz then
            ser_rx_speed = 0x2
            des_tx_speed = 0x8      
      
       elseif      RX_SPD = 0.375GHz then
            ser_rx_speed = 0x1
            des_tx_speed = 0x4          
       elseif      RX_SPD = 0.1875GHz then
            ser_rx_speed = 0x0
            des_tx_speed = 0x0               
       end_if 
       
        ser_link_speed_code = ser_rx_speed + ser_tx_speed
        des_link_speed_code = des_rx_speed + des_tx_speed
    
    
--- Program link rate
        fpga_UART_Write("FPGA1","SER", SER_ID, 16#01, 1, ser_link_speed_code  )               ---- SER GMSL link speed    
        fpga_UART_Write("FPGA1","DES", DESA_ID, 16#01, 1, des_link_speed_code  )             ---- DES GMSL link speed
        wait(10mS)  ---needed
--- Write to reg10 to update link speed setting     
    -- write Reg0x10 to update to COAX mode
        fpga_UART_Write("FPGA1","DES", DESA_ID, 16#10, 1, 0x00)
        wait(2ms)
        fpga_UART_Write("FPGA1","SER", SER_ID, 16#10, 1, 0x30)             -- Set auto link config and one shot
--        ser_read =  fpga_UART_Read("FPGA1", "SER", SER_ID, 0x10, 1)        -- self adjust back to 0x01    
    end_if


--        ser_local_read =  fpga_UART_Read("FPGA1", "SER", SER_ID, 0x13, 1)      -- for SER lock bit, good if 0xDA               
    lowword =  fpga_UART_Read("FPGA1", "SER", SER_ID, 0x13, 1)      -- for SER lock bit, good if 0xCA 
    while( loopcont) do
        for idx = 1 to sites do 
            site = active_sites[idx]
                if  (lowword[site] = 0xde  OR lowword[site] =0xda  OR lowword[site] =0xCa OR lowword[site] =0xCE OR lowword[site] =0xEa OR lowword[site] =0xEE) and not SiteCheck[site] then
                    sitecount = sitecount + 1
                    SiteCheck[site] = true     
                end_if
                if sitecount = sites then
                    loopcont = false
                end_if     
            count = count + 1
            if count > 200 then
                loopcont  = false
            end_if
            if loopcont  then
                wait(1ms)
                lowword =  fpga_UART_Read("FPGA1", "SER", SER_ID, 0x13, 1)      -- for SER lock bit, good if 0xDA 
            end_if
            
        end_for            
 
    end_while

-- 
-- 
--         for i = 1 to 500 do
--             reg_val15      =  fpga_UART_Read("FPGA1", "DES", DESA_ID, 0x13, 1)      -- DES lock bit, 0xDA expected   
--             if reg_val15[active_sites[1]] <> 0xCA then
--                 wait(2ms)
--             else
--                 break
--             end_if
--         end_for         
--         wait(0ms)
        ser_local_read =  fpga_UART_Read("FPGA1", "SER", SER_ID, 0x13, 1)      -- for SER lock bit, good if 0xDA         
        for idxs = 1 to len(active_sites) do
            site = active_sites[idxs]
            ireg_val1[site]  = integer(ser_local_read[site])
            ireg_val15[site] = integer(reg_val15[site])      
         end_for    

        fpga_set_UART_Frequency("FPGA1", Freq)
        wait(3ms)    

        ser_read = 0x00        -- initialization needed.
        ser_read_reg1 = 0x00
        ser_read_reg2 = 0xFF
         
--         if (Freq = 100KHz) then
--             w_r_delay = 5ms
--         else
--             w_r_delay = 5ms                
--         end_if
 w_r_delay = 200us 
 ---------------Top section establish link     
-------------------------add from here for spi timing  clean up procedure later MT 1/2018
----Connect sparepin to fpga for debug
--    connect digital pin SER_DP_RESERVE to dcl
--    set digital pin SER_DP_RESERVE  levels to vil 0V vih 3.3 vol 1.0V voh 1.2V iol 0uA ioh 0uA vref 0V
    wait(0)

---Setup Spi slave on SER device
        fpga_UART_Write("FPGA1","SER", SER_ID, SR_SPI_0, 1, 16#09)    ------ Set SPI_EN=1
        fpga_UART_Write("FPGA1","SER", SER_ID, SR_SPI_1, 1, 16#E1)    ------ Set SPI_LOC_N[7:2]=0x28 and SPI_BASE_PRIO[1:0]=0x1
        fpga_UART_Write("FPGA1","SER", SER_ID, SR_SPI_2, 1, 16#00)    ------ Set SPIM_SS2_ACT_H=SPIM_SS1_ACT_H=0     
        fpga_UART_Write("FPGA1","SER", SER_ID, SR_SPI_3, 1, 16#01)    ------ Set number of 300MHz clocks to delay to be 1       
        fpga_UART_Write("FPGA1","SER", SER_ID, SR_SPI_4, 1, 16#3)    ------ Set number of 300MHz clocks for SCK Low time = 150    ----Spi speed about 1MHz      
        fpga_UART_Write("FPGA1","SER", SER_ID, SR_SPI_5, 1, 16#3)    ------ Set number of 300MHz clocks for SCK high time = 150         
        fpga_UART_Write("FPGA1","SER", SER_ID, SR_SPI_6, 1, 16#03)    ------ Set BNE_IO_EN=RWN_IO_EN=1 for Slave
        fpga_UART_Write("FPGA1","SER", SER_ID, SR_SPI_7, 1, 16#00)    ------ Read Only Register for RX and TX overflow and Byte CNT
        fpga_UART_Write("FPGA1","SER", SER_ID, SR_SPI_8, 1, 16#00)    ------ No request hold off timeout delay
--        fpga_UART_Write("FPGA1","SER", SER_ID, SR_SPI_0, 1, 16#09)    ------ Set SPI_EN=1
---Setup Spi master  on DES device

        fpga_UART_Write("FPGA1", "DES", DESA_ID, DR_SPI_0, 1, 16#0b )    ------ Set MST_SLVN=SPI_EN=1
        fpga_UART_Write("FPGA1", "DES", DESA_ID, DR_SPI_1, 1, 16#E2 )    ------ Set SPI_LOC_N[7:2]=0x28 and SPI_BASE_PRIO[1:0]=0x2        
        fpga_UART_Write("FPGA1", "DES", DESA_ID, DR_SPI_2, 1, 16#00 )    ------ Set SPIM_SS2_ACT_H=SPIM_SS1_ACT_H=0
        fpga_UART_Write("FPGA1", "DES", DESA_ID, DR_SPI_3, 1, 16#01 )    ------ Set number of 300MHz clocks to delay to be 1    
        fpga_UART_Write("FPGA1", "DES", DESA_ID, DR_SPI_4, 1, 16#3 )    ------ Set number of 300MHz clocks for SCK Low time = 150              
        fpga_UART_Write("FPGA1", "DES", DESA_ID, DR_SPI_5, 1, 16#3 )    ------ Set number of 300MHz clocks for SCK High time = 150        
        fpga_UART_Write("FPGA1", "DES", DESA_ID, DR_SPI_6, 1, 16#0C )    ------ Set SS_IO_EN_2=SS_IO_EN_1=1 for Master        
        fpga_UART_Write("FPGA1", "DES", DESA_ID, DR_SPI_7, 1, 16#00 )    ------ Read Only Register for RX and TX overflow and Byte CNT       
        fpga_UART_Write("FPGA1", "DES", DESA_ID, DR_SPI_8, 1, 16#00 )    ------ No request hold off timeout delay    
 

--------------------do the timing         

    open digital cbit MFP_LT_RELAY
    wait(4ms)
-------------------------- 
 
    spi_freq = SPI_FREQ
    spi_period = 1.0/spi_freq
----Set freq for spi 
   set digital clock msdi frequency t0 to double(spi_freq)  c0 to double(spi_freq)  for  "SPI_TS"
    Move_Edge1(SER_GPIO2_GPO_SCLK, "data", "SPI_TS", 0.25*spi_period)                         -- set SCK rising edge to 5ns
    Move_Edge1(SER_GPIO2_GPO_SCLK, "return", "SPI_TS", 0.75*spi_period)                        -- set SCK falling edge to 15ns at 50MHz
   set digital clock msdi frequency t0 to double(spi_freq)  c0 to double(spi_freq)  for  "SPI_Search_TS"



    execute digital pattern "SPI_Pat" at label "A6_RO_1_Rset" run to end
    ser_local_read  = fpga_read_register("FPGA1",SERDES_STATUS)

    Move_Edge1(SER_GPIO2_GPO_SCLK, "data", "SPI_Search_TS", 0.25*spi_period)                         -- set SCK rising edge to 5ns
    Move_Edge1(SER_GPIO2_GPO_SCLK, "return", "SPI_Search_TS", 0.75*spi_period)                        -- set SCK falling edge to 15ns at 50MHz
----Mod by MT for go and no go 10/2018
    if char then
        Move_Edge1(SER_GPIO17_CNTL2_SDA1_MOSI, "data", "SPI_Search_TS", 0ns)                 -- Reset edge back to 0ns
        Move_Edge1(SER_GPIO17_CNTL2_SDA1_MOSI, "return", "SPI_Search_TS", 0.75*spi_period + 4ns)                 -- Reset falling edge back to 18ns at 50MHz
        execute digital pattern "SPI_Pat" at label "A6_RO_1" run to end
        TSetup = SPI_Bin_Search(SER_GPIO17_CNTL2_SDA1_MOSI, "data", "SPI_Search_TS",  0.25*spi_period - 2ns,  0.25*spi_period +7ns, SERDES_STATUS,"SPI_Pat" )                ------------ 2ns to 7ns
        TSetup = 0.25*spi_period -TSetup  
        Move_Edge1(SER_GPIO17_CNTL2_SDA1_MOSI, "data", "SPI_Search_TS", 0ns)                 -- Reset edge back to 0ns
        wait(0)
-----Next  measure spi hold time
        Move_Edge1(SER_GPIO17_CNTL2_SDA1_MOSI, "return", "SPI_Search_TS",0.75*spi_period + 4ns )                 -- Reset edge back to 19ns

        THold = SPI_Bin_Search(SER_GPIO17_CNTL2_SDA1_MOSI, "return", "SPI_Search_TS", 0.75*spi_period + 4ns , 0.25*spi_period - 2ns, SERDES_STATUS,"SPI_Pat" )                           ---------20ns,4ns
        THold = THold -0.25*spi_period 
        wait(0)
   
   
        execute digital pattern "SPI_Pat" at label "A6_RO_1_Rset" run to end

--    Move_Edge(SER_GPIO2_GPO_SCLK, "data", "SPI_Search_TS",0.25*spi_period )                         -- set SCK rising edge to 5ns
        Move_Edge1(SER_GPIO2_GPO_SCLK, "data", "SPI_Search_TS",2ns )                         -- set SCK rising edge to 2ns
        Move_Edge1(SER_GPIO2_GPO_SCLK, "return", "SPI_Search_TS", 0.75*spi_period)   

        Move_Edge1(SER_GPIO17_CNTL2_SDA1_MOSI, "data", "SPI_Search_TS",0ns )
        Move_Edge1(SER_GPIO17_CNTL2_SDA1_MOSI, "return", "SPI_Search_TS",0.9*spi_period )                 -- Reset edge back to 19ns


        execute digital pattern "SPI_Pat" at label "A6_RO_1" run to end

        TSclkHighMax = SPI_Bin_Search(SER_GPIO2_GPO_SCLK, "return", "SPI_Search_TS", 0.75*spi_period ,spi_period , SERDES_STATUS,"SPI_Pat" )    
        TSclkHighMax =   TSclkHighMax -2ns
    
        Move_Edge1(SER_GPIO2_GPO_SCLK, "data", "SPI_Search_TS", 0.25*spi_period)                         -- set SCK rising edge to 5ns
        Move_Edge1(SER_GPIO2_GPO_SCLK, "return", "SPI_Search_TS", 0.75*spi_period)
        TSclkHighMin = SPI_Bin_Search(SER_GPIO2_GPO_SCLK, "data", "SPI_Search_TS",0.25*spi_period , 0.75*spi_period, SERDES_STATUS,"SPI_Pat" )    
        TSclkHighMin = 0.75* spi_period - TSclkHighMin 
    else
        Move_Edge1(SER_GPIO2_GPO_SCLK, "data", "SPI_Search_TS", 0.25*spi_period)                         -- set SCK rising edge to 5ns
        Move_Edge1(SER_GPIO2_GPO_SCLK, "return", "SPI_Search_TS", 0.75*spi_period)
        Move_Edge1(SER_GPIO17_CNTL2_SDA1_MOSI, "data"  , "SPI_Search_TS", 0ns)                                   -- Reset edge back to 0ns
        Move_Edge1(SER_GPIO17_CNTL2_SDA1_MOSI, "return", "SPI_Search_TS", 0.75*spi_period + 4ns)                 -- Reset falling edge back to 18ns at 50MHz


----Test go no go for Tsetup       
        Move_Edge1(SER_GPIO17_CNTL2_SDA1_MOSI, "data"  , "SPI_Search_TS",0.25*spi_period -GnGTSetup)    
        execute digital pattern "SPI_Pat" at label "A4_RO_11" run to end    
        TsetupReadSS1 = integer(fpga_read_register("FPGA1", SERDES_STATUS)) >> 8      ----report bit 8 and 9 only expect 2
        Move_Edge1(SER_GPIO17_CNTL2_SDA1_MOSI, "data"  , "SPI_Search_TS",0ns)   ---- reset back to 0ns
        execute digital pattern "SPI_Pat" at label "A6_RO_1_Rset" run to end            ----reset SS1 and SS2    
----Test Thold time 
        Move_Edge1(SER_GPIO17_CNTL2_SDA1_MOSI, "return", "SPI_Search_TS", 0.25*spi_period + GnGTHold) 
        execute digital pattern "SPI_Pat" at label "A4_RO_11" run to end    
        THoldReadSS1 = integer(fpga_read_register("FPGA1", SERDES_STATUS)) >> 8      ----report bit 8 and 9 only expect 2
        Move_Edge1(SER_GPIO17_CNTL2_SDA1_MOSI, "return", "SPI_Search_TS", 0.75*spi_period)
        execute digital pattern "SPI_Pat" at label "A6_RO_1_Rset" run to end            ----reset SS1 and SS2
    
    end_if


    if POWERDOWN then   
--         powerdown_device(POWERDOWN)
        open cbit MFP_LT_RELAY + DNUT_RXTX_RELAY + I2C_LT_CB + MFP_LT_K12_RELAY------for now
        open  cbit CB2_SLDC                     --OVI_RELAYS
        open cbit COAXB_M_RELAY                --OVI_RELAYS
        wait(5ms) 
--         powerup_dnut_vdd_vterm(0.0,0.0)
-----------  --fpga_Set_DNUT_Pins("FPGA1", CFG1, CFG0, PWDN, latch)
        fpga_Set_DNUT_Pins("FPGA1", 0,0, 0, 0, TRUE)  -- UART/TP/GMSL2=1/RATE=0(6 Gig link)               
        wait(1ms)             
         powerdown_device(POWERDOWN)
    end_if
   for idxs = 1 to len(active_sites) do
     site = active_sites[idxs]
     --ireg_val_ser[site]  = integer(ser_read[site])
     iser_read_reg1[site]  = integer(ser_read_reg1[site])
     iser_read_reg2[site]  = integer(ser_read_reg2[site])                
   end_for
   
   
   test_value (TX_SPD_rate)  with TX_SPD_it 
   test_value (RX_SPD_rate)  with RX_SPD_it
   test_value link_type  with link_type_it    
--    test_value ireg_val1 with ser_lock_it
--    test_value ireg_val15 with des_lock_it 
   if char then
        test_value msfloat(spi_freq) with   SPIFrq      
        test_value TSetup with TSETUP
        test_value THold with THOLD
        test_value TSclkHighMax with SCLKPulseHi
        test_value TSclkHighMin with  SCLKPulseLo
    else
        test_value    TsetupReadSS1       with ReadTsetup
        test_value    THoldReadSS1        with ReadThold
        test_value    GnGTSetup_ft      with  GnGTSetupFt
        test_value    GnGTHold_ft       with  GnGTHoldFt
    
    end_if
 
 end_body



procedure VDD_SW_18_tests(Vdd, Vddio, Vdd18,VddSWRegOnGoNoGo,CapVddRegOnGoNoGo,VddGoNoGo, VddSW0p95,VddSW1p365,CapVdd0p95,CapVdd1p365,VddRegOnChar,VddSWRegOnChar,CapVddChar,POWERUP,POWERDOWN,VddRegOn)
--------------------------------------------------------------------------------
--  DESCRIPTION
--  Measure ABUS test points using PPMU.
--
--
--  PASS PARAMETERS:
--  Vdd                 -- VDD supply level
--  Vddio               -- VDDIO supply level
--  Vdd18               -- VDD18 supply level
--  PwrBlk_Lim          -- Power Block test limits
--  GmslBlk_Lim         -- GMSL2 Block test limits
--  AudBlk_Lim          -- AUDPLL Block test limits
--  VidBlk_Lim          -- VIDPLL Block test limits
--  CharTstLim          -- Characterization test limits  

in boolean          : POWERUP,POWERDOWN
in float                : Vdd, Vddio, Vdd18 ,VddRegOn

in_out float_test  : VddSW0p95,VddSW1p365,VddSWRegOnGoNoGo,VddSWRegOnChar,CapVdd0p95,CapVdd1p365,CapVddRegOnGoNoGo,VddRegOnChar,VddGoNoGo,CapVddChar

local
    word list[16]       :  active_sites
    word                :  sites, idx, site

    multisite word      :  reg_read
    multisite lword     :  lowword, upperword
--    float               :  Vconf0, Vconf1
    integer             :  idxs    
    multisite integer   :  reg_val, reg_val0, reg_val1 
    
    boolean                 : CHAR
    multisite float         : meas_v3[3] , vdd_sw , previous_vdd_sw,measv[1], previous_capvdd
    multisite float         : TdiodeMeas , TvssMeas , TdiodeTemp , TmonMeas , TmonTemp 
    multisite float         : dlog0[7] , dlog2[4], dlog4[1], dlog5[1], dlog1[2], dlog_csi[8],temp[120],temp1[120],temp2[120]
    multisite float         : char_dlog[20], char_bias_abus[14], char_power_abus[14]
    float                   :    Vdd_Set
    pin                     : abus0, abus1, abus2, abus3
 
    multisite float         :  SetVdd,Vdd_SW_Trip 
    integer                 : sitecount,i
    multisite boolean         : SiteDoneFlag
    multisite float         :  vdd_sw_0p95,vdd_sw_1p365,vdd_sw_RegOn,CapVdd_0p95[1],CapVdd_1p365[1],CapVdd_RegOn[1],CapVdd_Trip,VddSetGoNoGo

end_local

const
    TdiodeOffset    = 1.5794
    TdiodeSlope     = -0.0027
    TmonOffset      = 0.78561
    TmonSlope       = 0.00250
end_const


body

    --****** Pin map ******
    ------------------Index
    -- ABUS0    MFP0    2
    -- ABUS1    MFP1    4
    -- ABUS2    MFP5    3
    -- ABUS3    MFP6    1
    abus0 = SER_GPO5_CFG1[1]                       --------SER_PCLKIN_MFP0[1]
    abus1 = SER_GPO4_CFG0[1]                         --------SER_CONF0_MFP1[1]
    abus2 = SER_GPIO3_RCLKOUT[1]                      -------SER_DIN02_LMN0_MFP5[1]
    abus3 = SER_GPO6_CFG2[1]                                      --------SER_DIN03_LMN1_MFP6[1]   
    
    get_expr("TestProgData.Device", DEVICE)
    get_expr("OpVar_Char", CHAR)
--    CHAR=TRUE      

    active_sites = get_active_sites
    sites = word(len(active_sites))
      
    disconnect hvvi chan SER_RSVD    -- need to float RSVD, important!!
    sitecount =0 
    VddSetGoNoGo =  VddRegOn                    ---require by Eric for datalog level setting
        previous_vdd_sw = 0.0   ----initialize
        i=1
-----Dut power up function
   DutPowerUp(Vddio, Vdd18, Vdd, "UART", "TP_GMSL2",POWERUP)------------- DutPowerUp(vio, v18, vcore, "UART", "TP_GMSL1",POWERUP)
--   DutPowerUp(Vddio, Vdd18, 0.95, "UART", "TP_GMSL2",POWERUP)------------- DutPowerUp(vio, v18, vcore, "UART", "TP_GMSL1",POWERUP)

 -------------SER_DIN03_LMN1_MFP6+SER_PCLKIN_MFP0+SER_DIN02_LMN0_MFP5+SER_CONF0_MFP      
   -- Setup MFP/ABUS pins to FVMI (pre-charge to 0V)    
      
   disconnect digital pin ABUS_DP_pl  from dcl
   connect digital ppmu ABUS_DP_pl  to fv 0V vmax 2V measure i max 2mA                    ------abus0 + abus1 + abus2 + abus3
  
   wait(5ms)  
------------ Enter TestMode 11 for test -----------------
    SetTestMode( 11 , False , "SER_UART_Write" )

    RegWrite(SER_ID, SR_TEST0, 1, 0x00, 0x00, "SER_UART_Write")     -- abus_power_page = 0x00,  HIZ
    wait(5ms)



-- *****************************************************
    -- Measure VDDD and VDDA
    -- Power ABUS Block (0) - ABUS Page 9
    -- *****************************************************
    --RegWrite(SER_ID, 0x3E, 1, 0x09, 0x09, "SER_UART_Write")     
    --wait(1ms)
 
--    meas_v = meas_ABUS_SE_V ( 1ms , 0x09 )
    -- Set test mode

----Use Vi pin to measure on ABUS
    connect vi16 chan  SER_ABUS0 + SER_ABUS1+ SER_ABUS2+ SER_ABUS3 remote
    set vi16 chan SER_ABUS0  + SER_ABUS1 +  SER_ABUS2+ SER_ABUS3 to fi 0.5ua  measure V max 2v clamp vmax 2v vmin -0.5v  
    RegWrite(SER_ID, SR_TEST0, 1, 0x00, 0x9, "SER_UART_Write")      -- abus_blk = #, abus_page = #    SR_TEST0 = 0x3E
    wait(3ms)------
----Setup to measure on capvdd pin  =======MT
--    set hcovi SER_VDD  to fv 1.0 vmax 2.0V measure i max 600ma clamp imax 900mA imin -900mA      ------- 
    set digital ppmu SER_CAPVDD to fi 1uA measure v max 2V
    connect digital pin  SER_CAPVDD to ppmu

----Use Vi pin to measure on ABUS
    close digital cbit MFP_LT_RELAY       ------next hw revision revb seperate TX and RX dps from this MFP_LT_Relay  MT
    close digital cbit ABUS_RELAY
    wait(10ms)---4
    measure vi16 v on chan  SER_ABUS2 for 20 samples every 10us averaged into  vdd_sw

    if CHAR then
        if Vdd > 1.2V then 
            set hcovi SER_VDD  to fv 1.2 vmax 2.0V measure i max 600ma clamp imax 900mA imin -900mA      -------  Reduce VDD to 1V before searching
            wait(3ms)
           set hcovi SER_VDD  to fv 1.1 vmax 2.0V measure i max 600ma clamp imax 900mA imin -900mA      -------  Reduce VDD to 1V before searching
            wait(3ms)
        end_if 
        for Vdd_Set = 1.02 to 1.365  by 2mV do 
            set hcovi SER_VDD  to fv Vdd_Set vmax 2.0V measure i max 600ma clamp imax 900mA imin -900mA    
            wait(7ms)
--            measure vi16 v on chan  SER_ABUS2 for 30 samples every 10us averaged into  vdd_sw
            measure digital ppmu SER_CAPVDD voltage average 20 delay 10us into measv
            measure vi16 v on chan  SER_ABUS2 for 30 samples every 10us averaged into  vdd_sw
            for idx = 1 to sites do
                site = active_sites[idx]            
                if((( previous_capvdd[site] - measv[site] > 50mV) or (measv[site] < 1.02 and Vdd_Set > 1.2 )) and not( SiteDoneFlag[site]))  then 
                    SetVdd[site] =  Vdd_Set + 3mV --- add 3mv during char see note below
                    Vdd_SW_Trip[site]  = vdd_sw[site]
                    CapVdd_Trip[site]  = measv[site,1]
                    sitecount = sitecount+ 1
                    SiteDoneFlag[site] = true
                else
                    previous_capvdd[site] = measv[site,1]
                end_if
            end_for
            if word(sitecount) = sites then
                break
            end_if
        end_for
    -----Added during char seeing when vdd reaching to switching level, output is osc, it causes yield.  Add 3mV above trip point and make sure it solid trip
    --\           
    for idx = 1 to sites do
        site = active_sites[idx]
        set hcovi  SER_VDD  to fv SetVdd   vmax 2.0V measure i max 600ma clamp imax 900mA imin -900mA 
        wait(20ms)
        measure digital ppmu SER_CAPVDD voltage average 20 delay 10us into measv
        measure vi16 v on chan  SER_ABUS2 for 30 samples every 10us averaged into  vdd_sw
        Vdd_SW_Trip[site]  = vdd_sw[site]
        CapVdd_Trip[site]  = measv[site,1]
        if SetVdd[2]>1.2 then
            wait(0)
         end_if
    end_for      
-- if  vdd_sw[2] < 0.8  then
--     wait(0)
-- end_if
    end_if   -----Production mode
 
----Set Vdd to point where regulater on for go and no go test
        set hcovi SER_VDD  to fv VddRegOn vmax 2.0V measure i max 600ma clamp imax 900mA imin -900mA     
        wait(1ms)
        
        RegWrite(SER_ID, SR_CTRL0, 1, 0, 16#15, "SER_UART_Write")   -- hcu 03/09/2020 mtran and emanalo vdd reg repeatability improvement
        RegWrite(SER_ID, SR_CTRL2, 1, 0, 16#14, "SER_UART_Write")   -- hcu 03/09/2020 mtran and emanalo vdd reg repeatability improvement
        
        measure vi16 v on chan  SER_ABUS2 for 20 samples every 10us averaged into vdd_sw_RegOn            
        measure digital ppmu SER_CAPVDD voltage average 20 delay 10us into CapVdd_RegOn

----Might now need  these value. for now, leave them there
----- force VDD to 0.95 measure again
--     open digital cbit MFP_LT_RELAY       ------next hw revision revb seperate TX and RX dps from this MFP_LT_Relay  MT
--     open digital cbit ABUS_RELAY
--     wait(4ms)
--  RegRead(SER_ID, 16#00, 1, upperword, lowword,"SER_UART_Read")   -- sleep reg before set sleep mode     
--      close digital cbit MFP_LT_RELAY       ------next hw revision revb seperate TX and RX dps from this MFP_LT_Relay  MT
--     close digital cbit ABUS_RELAY
--     wait(4ms)
------------------------- at hot need slowly reduce supply otherwise it reset part and fail 

        set hcovi SER_VDD  to fv 1.15v vmax 2.0V measure i max 600ma clamp imax 600mA imin -600mA    --- reduce
        wait(4ms)
        set hcovi SER_VDD  to fv 1.10v vmax 2.0V measure i max 600ma clamp imax 600mA imin -600mA    --- reduce
        wait(3ms)
        set hcovi SER_VDD  to fv 1.05v vmax 2.0V measure i max 600ma clamp imax 600mA imin -600mA    --- reduce
        wait(3ms)
        set hcovi SER_VDD  to fv 1.00v vmax 2.0V measure i max 600ma clamp imax 600mA imin -600mA    --- reduce
        wait(3ms)

         set hcovi SER_VDD  to fv 0.97v vmax 2.0V measure i max 600ma clamp imax 600mA imin -600mA    --- reduce
        wait(3ms)
       set hcovi SER_VDD  to fv 0.95 vmax 2.0V measure i max 600ma clamp imax 600mA imin -600mA     
        wait(1ms)
        measure vi16 v on chan  SER_ABUS2 for 20 samples every 10us averaged into vdd_sw_0p95            
        measure digital ppmu SER_CAPVDD voltage average 20 delay 10us into CapVdd_0p95
----- force VDD to 1.365 measure again
        set hcovi SER_VDD  to fv 1.365 vmax 2.0V measure i max 600ma clamp imax 900mA imin -900mA     
        wait(1ms)
        measure vi16 v on chan  SER_ABUS2 for 20 samples every 10us averaged into vdd_sw_1p365            
        measure digital ppmu SER_CAPVDD voltage average 20 delay 10us into CapVdd_1p365
    if vdd_sw_0p95[2]> 1.5 then
        wait(0)
    end_if
    disconnect digital pin ABUS_DP_pl from ppmu
    connect digital pin ABUS_DP_pl to dcl
  


------ Power Off ----
  --      powerdown_device(POWERDOWN)
    open digital cbit MFP_LT_RELAY
    open digital cbit ABUS_RELAY
    powerdown_device(POWERDOWN)

--    wait(5ms)
    -- report results

    test_value vdd_sw_RegOn with VddSWRegOnGoNoGo
    test_value CapVdd_RegOn with CapVddRegOnGoNoGo
    test_value VddSetGoNoGo with VddGoNoGo
    test_value vdd_sw_0p95 with VddSW0p95
    test_value vdd_sw_1p365 with VddSW1p365
    test_value CapVdd_0p95 with CapVdd0p95
    test_value CapVdd_1p365 with CapVdd1p365
    if CHAR then
        test_value SetVdd with VddRegOnChar 
        test_value Vdd_SW_Trip with VddSWRegOnChar
        test_value CapVdd_Trip with CapVddChar
    end_if    
    

end_body

procedure CMPTrip_tests(Vdd, Vddio, Vdd18,VddSWRegOnGoNoGo,CapVddRegOnGoNoGo,VddGoNoGo, VddSW0p95,VddSW1p365,CapVdd0p95,CapVdd1p365,VddRegOnChar,VddSWRegOnChar,CapVddChar,POWERUP,POWERDOWN,VddRegOn)
--------------------------------------------------------------------------------
--  DESCRIPTION
--  Measure ABUS test points using PPMU.
--
--
--  PASS PARAMETERS:
--  Vdd                 -- VDD supply level
--  Vddio               -- VDDIO supply level
--  Vdd18               -- VDD18 supply level
--  PwrBlk_Lim          -- Power Block test limits
--  GmslBlk_Lim         -- GMSL2 Block test limits
--  AudBlk_Lim          -- AUDPLL Block test limits
--  VidBlk_Lim          -- VIDPLL Block test limits
--  CharTstLim          -- Characterization test limits  

in boolean          : POWERUP,POWERDOWN
in float                : Vdd, Vddio, Vdd18 ,VddRegOn

in_out float_test  : VddSW0p95,VddSW1p365,VddSWRegOnGoNoGo,VddSWRegOnChar,CapVdd0p95,CapVdd1p365,CapVddRegOnGoNoGo,VddRegOnChar,VddGoNoGo,CapVddChar

local
    word list[16]       :  active_sites
    word                :  sites, idx, site

    multisite word      :  reg_read
    multisite lword     :  lowword, upperword

    integer             :  idxs    
    multisite integer   :  reg_val, reg_val0, reg_val1 
    
    boolean                 : CHAR
    multisite float         : meas_v3[3] , vdd_sw , previous_vdd_sw,measv[1]
    multisite float         : dlog0[7] , dlog2[4], dlog4[1], dlog5[1], dlog1[2], dlog_csi[8],temp[50],temp1[50],temp2[50]
    multisite float         : char_dlog[20], char_bias_abus[14], char_power_abus[14]
    float                   :    Vdd_Set
    pin list[1]             : PSEQD0,PSEQD1,PSEQD2,PSEQD3,PSEQZ0,PSEQZ1,PSEQZ2,PSEQZ3
 
    multisite float         :  SetVdd,Vdd_SW_Trip 
    integer                 : sitecount,i
    multisite boolean         : SiteDoneFlag
    multisite float         :  vdd_sw_0p95,vdd_sw_1p365,vdd_sw_RegOn,CapVdd_0p95[1],CapVdd_1p365[1],CapVdd_RegOn[1],CapVdd_Trip,VddSetGoNoGo
    multisite float         : PSEQZ3_low[1], ReturnValueUp[2], ReturnValueDown[2],VddUp,VddDown,VddUp1,VddDown1
    multisite float         : CapVddUp,CapVddDown    

end_local


  
body

    --****** Pin map ******
    ------------------Index
    -- ABUS0    MFP0    2
    -- ABUS1    MFP1    4
    -- ABUS2    MFP5    3
    -- ABUS3    MFP6    1
    PSEQD0[1] = SER_GPIO11_CNTL1_SCKOR_SCL2[1]                       --------SER_PCLKIN_MFP0[1]
    PSEQD1[1] = SER_GPIO12_MS1_SDOR[1]
    PSEQD2 [1]= SER_GPIO10_CNTL0_WSOR_SDA2[1]
    PSEQD3[1] = SER_GPIO14_LMN1[1]

    PSEQZ0[1] = SER_GPIO13_LMN0[1]
    PSEQZ1[1] = SER_GPIO7_WS[1]
    PSEQZ2[1] = SER_GPIO8_SCK[1]
    PSEQZ3[1] = SER_GPIO9_SD[1]
    
    
    get_expr("TestProgData.Device", DEVICE)
    get_expr("OpVar_Char", CHAR)
--    CHAR=TRUE      

    active_sites = get_active_sites
    sites = word(len(active_sites))
      
    disconnect hvvi chan SER_RSVD    -- need to float RSVD, important!!

-----Dut power up function
   DutPowerUp(Vddio, Vdd18, Vdd, "UART", "TP_GMSL2",POWERUP)------------- DutPowerUp(vio, v18, vcore, "UART", "TP_GMSL1",POWERUP)

------------ Enter TestMode 14 for PowerSequence test -----------------
    SetTestMode( 14 , False , "SER_UART_Write" )

    RegWrite(SER_ID, SR_PWR2, 1, 0x00, 0x40, "SER_UART_Write")     -- set EN_PSEQ_MODE=1
    wait(1ms)

---------- Setup PSEQD and PSEQZ pins
   disconnect digital pin PSEQD0+ PSEQD1+PSEQD2+ PSEQD3 from dcl
   disconnect digital pin PSEQZ0+ PSEQZ1+ PSEQZ2+ PSEQZ3 from dcl

   connect digital pin PSEQD0+ PSEQD1+PSEQD2+ PSEQD3   to ppmu
   connect digital pin  PSEQZ0+ PSEQZ1+ PSEQZ2+ PSEQZ3 to ppmu
   set digital ppmu PSEQZ0+ PSEQZ1+ PSEQZ2+ PSEQZ3 to fi 1uA measure v max Vddio  clamps to vmax Vddio   
   set digital ppmu  PSEQD0+ PSEQD1+PSEQD2+ PSEQD3 to fv 0.0v measure i max 100uA   
-------------1V compartor testing   
----------Set PSEQD[3:0]=1001 Bank 9 ramp Vdd from 1V until  PSEQZ[3] change from 0 to 1. Record Vdd value 
   set digital ppmu PSEQD0 + PSEQD3 to fv Vddio measure i max 100uA 
   wait(1ms)
   measure digital ppmu PSEQZ3 voltage average 20 delay 10us into PSEQZ3_low   ---expect low
-----Now searching to find trip level.
    ReturnValueUp =  RampVdd( Vddio,PSEQZ3, 1.0,1.2, 1mv) 
    ReturnValueDown =  RampVdd( Vddio,PSEQZ3, 1.2 ,1.0, 1mv) 
    for idx = 1 to sites do
        site = active_sites[idx]
        VddUp[site] = ReturnValueUp[site,1]
        VddDown[site] = ReturnValueDown[site,1]
    
    end_for
-----Now switch to VDD_SW 
    ReturnValueUp =  RampVdd( Vddio,PSEQZ2, 1.05,1.2, 1mv) 
    ReturnValueDown =  RampVdd( Vddio,PSEQZ2, 1.2 ,1.00, 1mv) 
    for idx = 1 to sites do
        site = active_sites[idx]
        VddUp1[site] = ReturnValueUp[site,1]
        VddDown1[site] = ReturnValueDown[site,1]
        CapVddUp[site] = ReturnValueUp[site,2] 
        CapVddDown[site] = ReturnValueDown[site,2]
    end_for

----------------------------------



------ Power Off ----
        powerdown_device(POWERDOWN)
 
   disconnect digital pin PSEQD0 + PSEQD1 + PSEQD2 + PSEQD3 from ppmu
   disconnect digital pin PSEQZ0 + PSEQZ1 + PSEQZ2 + PSEQZ3 from ppmu

   connect digital pin PSEQD0 + PSEQD1 + PSEQD2 + PSEQD3 to  dcl
   connect digital pin  PSEQZ0 + PSEQZ1 + PSEQZ2 + PSEQZ3  to dcl

    -- report results

    test_value vdd_sw_RegOn with VddSWRegOnGoNoGo
    test_value CapVdd_RegOn with CapVddRegOnGoNoGo
    test_value VddSetGoNoGo with VddGoNoGo
    test_value vdd_sw_0p95 with VddSW0p95
    test_value vdd_sw_1p365 with VddSW1p365
    test_value CapVdd_0p95 with CapVdd0p95
    test_value CapVdd_1p365 with CapVdd1p365
    if CHAR then
        test_value SetVdd with VddRegOnChar 
        test_value Vdd_SW_Trip with VddSWRegOnChar
        test_value CapVdd_Trip with CapVddChar
    end_if    
    

end_body

 procedure SPI_Timing_PT (Vdd, Vddio, Vdd18,POWERUP,POWERDOWN,TP_COAX,TX_SPD,RX_SPD, ser_lock_it,Link_Lock_dly,ss1_1m_ser, ss2_1m_ser, ss1_10m_ser, ss2_10m_ser, ss1_25m_ser, ss2_25m_ser, ss1_0p588m_ser, ss2_0p588m_ser,ss1_1m_des,  ss2_1m_des, ss1_10m_des, ss2_10m_des, ss1_25m_des, ss2_25m_des, ss1_0p588m_des, ss2_0p588m_des,ss1_50m_ser, ss2_50m_ser,ss1_50m_des, ss2_50m_des)

--------------------------------------------------------------------------------
in float                        : Vdd, Vddio, Vdd18
in_out  integer_test            : ser_lock_it

in boolean                      : POWERUP,POWERDOWN
in string[20]                   : TP_COAX--,CSI_MODE                          -----TP_COAX : TP or COAX mode, CSI_MODE --- 1x4,2x4,1x2...
in float                        : TX_SPD,RX_SPD,Link_Lock_dly 
in_out integer_test             : ss1_1m_ser, ss2_1m_ser, ss1_10m_ser, ss2_10m_ser, ss1_25m_ser, ss2_25m_ser, ss1_0p588m_ser, ss2_0p588m_ser, ss1_50m_ser, ss2_50m_ser
in_out integer_test             :ss1_1m_des,  ss2_1m_des, ss1_10m_des, ss2_10m_des, ss1_25m_des, ss2_25m_des, ss1_0p588m_des, ss2_0p588m_des, ss1_50m_des, ss2_50m_des   
local



  multisite lword   : LowerRdWord, UpperRdWord
  float             : Vconf0, Vconf1
  multisite lword   : lowword, upperword, des_read0, des_read1, des_read2, des_read,reg_val15,FailLockCount[1]

  multisite   double : clock_ts, error_ts
  word              : sites, idx, site
  integer           : idxs
  
  multisite lword   : hizdel_reg_val, oreg_reg_val
  lword             : data
  

    lword           : ser_link_speed_code, des_link_speed_code, ser_tx_speed, ser_rx_speed, des_tx_speed, des_rx_speed
    lword           : number_of_lane, des_csi_mode,des_numb_lane,mipi_speed, ser_csi_mode

    multisite float : LockTime
     multisite integer   :    ireg_val1

  multisite lword   : ss1_1_des, ss2_1_des, ss1_10_des, ss2_10_des, ss1_25_des, ss2_25_des, ss1_0p588_des, ss2_0p588_des, ss1_50_des, ss2_50_des
  multisite lword   : ss1_1_ser, ss2_1_ser, ss1_10_ser, ss2_10_ser, ss1_25_ser, ss2_25_ser, ss1_0p588_ser, ss2_0p588_ser, ss1_50_ser, ss2_50_ser
  lword             : SPI_COMMAND_REG_DATA
  float              : spi_freq
  lword              : data1
   boolean         : loopcont
    multisite boolean : SiteCheck
    word            :sitecount,count  
    boolean           : CHAR
end_local


body
  


    active_sites = get_active_sites
    sites = word(len(active_sites))  
   loopcont  = true
   SiteCheck  = false 
    get_expr("OpVar_Char", CHAR)   


    disconnect hvvi chan SER_RSVD    -- need to float RSVD, important!!
    close cbit X1X2_POSC
-----Dut power up function
    if POWERUP then
        DutPowerUp(Vddio, Vdd18, Vdd, "UART", "TP_GMSL2",POWERUP)
---Close relay to connect FPGA to control TX/RX on DNUT
        close cbit  DNUT_RXTX_RELAY
        close  cbit MFP_LT_RELAY  + I2C_LT_CB + MFP_LT_K12_RELAY
        wait(6ms)
--------powerup_dnut_vdd_vterm(VDD_SET, VTERM_SET)
        powerup_dnut_vdd_vterm(1.2,1.2)
        wait(6ms)
  --fpga_Set_DNUT_Pins("FPGA1", CFG1, CFG0, PWDN, latch)
        fpga_Set_DNUT_Pins("FPGA1", 0,0, 1, 1, TRUE)  -- UART/TP/GMSL2=1/RATE=0(6 Gig link)               
        wait(6ms)    
        oreg_reg_val = fpga_read_register("FPGA1", OREG)    -- status of CFG1, CFG0, PWDN reg
        wait(0ms)
    else
        Set_SER_Voltages(Vddio, Vdd, Vdd18)
    end_if
   
     fpga_set_UART_Frequency("FPGA1", 1MHz)
     wait(1ms)


 ----Set SER and DES for coax or tp mode
    if TP_COAX = "TP" then
--        RegWrite(SER_ID, SR_CTRL1, 1, 16#0F, 16#0A, "SER_UART_Write")               ---- TP mode SR_CTRL1  =0X11            
        fpga_UART_Write("FPGA1","SER", SER_ID, SR_CTRL1, 1, 0x0A)                 ----TP mode SR_CTRL1  =0X11
        fpga_UART_Write("FPGA1","DES", DESA_ID, DR_CTRL1, 1, 0x0A)                 ---- TP mode   DR_CTRL1 = 0x11       
    else
--        RegWrite(SER_ID, SR_CTRL1, 1, 16#0F, 16#0F, "SER_UART_Write")               ---- coax mode SR_CTRL1  =0X11    
        fpga_UART_Write("FPGA1","SER", SER_ID, SR_CTRL1, 1, 0x0F)                      ---- coax mode SR_CTRL1  =0X11            
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
      
      elseif      RX_SPD = 0.375GHz then
            ser_rx_speed = 0x1
            des_tx_speed = 0x4          
       elseif      RX_SPD = 0.1875GHz then
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
    wait(10ms)   --NEEDED 100
-----Write to reg10 to update link speed setting 

--    RegWrite(SER_ID, SR_CTRL0, 1, 16#30, 16#30, "SER_UART_Write")                           ---Set auto link config and one shot; auto link will select both links for HS89
    fpga_UART_Write("FPGA1","DES", DESA_ID, SR_CTRL0, 1, 16#00)
    wait(2ms)
    fpga_UART_Write("FPGA1","SER", SER_ID, SR_CTRL0 , 1, 16#30  )
    wait(1ms)        
--    RegRead(SER_ID,SR_CTRL0 , 1, upperword, lowword,"SER_UART_Read")      -- self adjust back to 0x01(default)
--    lowword = fpga_UART_Read("FPGA1", "SER", SER_ID,SR_CTRL0 , 1)
--------------Check for lock, error bit
----Currently, HS89 rev 1.5G error bit always on.
----at fwd_speed = 6.0G, REV_SPEED = 0.75 then no error.
----at fwd_speed = 3.0G, REV_SPEED = 0.375 then no error.
---------------------------------------------------------------------------------------------------------------------------------------------

   wait(Link_Lock_dly)   --NEEDED to see LOCK bits on both SER/DES at 3G serial links !!!        
   lowword =  fpga_UART_Read("FPGA1", "SER", SER_ID, 0x13, 1)      -- for SER lock bit, good if 0xDA 
   reg_val15  = fpga_UART_Read("FPGA1", "DES", DESA_ID, 0x13, 1)   -- DES lock bit, 0xCA expected   

    while( loopcont) do
        for idx = 1 to sites do 
            site = active_sites[idx]
                if  (lowword[site] = 0xde  OR lowword[site] =0xda  OR lowword[site] =0xCa OR lowword[site] =0xCE OR lowword[site] =0xEa OR lowword[site] =0xEE) and not SiteCheck[site] then
                    sitecount = sitecount + 1
                    SiteCheck[site] = true     
                end_if
                if sitecount = sites then
                    loopcont = false
                end_if     
            count = count + 1
            if count > 200 then
                loopcont  = false
            end_if
            if loopcont  then
                wait(1ms)
                lowword =  fpga_UART_Read("FPGA1", "SER", SER_ID, 0x13, 1)      -- for SER lock bit, good if 0xDA 
            end_if
            
        end_for            
 
    end_while
--     ser_local_read =  fpga_UART_Read("FPGA1", "SER", SER_ID, 0x13, 1)      -- for SER lock bit, good if 0xDA  
     reg_val15  = fpga_UART_Read("FPGA1", "DES", DESA_ID, 0x13, 1)   -- DES lock bit, 0xCA expected 





   wait(0ms)
   for idxs = 1 to len(active_sites) do
     site = active_sites[idxs]
     --ireg_val_ser[site]  = integer(ser_read[site])
     ireg_val1[site]  = integer(reg_val15[site])
             
   end_for

-----For now play with lock timing spi Pt
 lowword = fpga_UART_Read("FPGA1", "SER", SER_ID, 0x304, 1)
    if Vddio < 2.0V then
        fpga_UART_Write("FPGA1","SER", SER_ID, SR_CMU4, 1,0x6B  )
       
    else
        fpga_UART_Write("FPGA1","SER", SER_ID, SR_CMU4, 1,0xAB  )
    end_if      

   spi_master("SER")

-- Set direction of Level Translators
   set digital pin SER_X1_AUXSCL + SER_X2_AUXSDA levels to vil 100mv vih 2.0v vol 2.7v/2.0 voh 2.7v/2.0
   SetPortExpander(PORT_EXP, 0x14)  -------Set  SCLK, mosi and RO and input

-----Pass-through = 1MHz
   spi_freq = 1MHz
    SetSPIClock(spi_freq, 0,"SER")
    data1 = lword(100MHz/(2.0*spi_freq) - 1.0)
    SPI_COMMAND_REG_DATA = 0x80600000 |( data1 <<12)
   wait(1ms)
   
   spi_master("SER") --CEF032119:Apparently Fixes 1MHz-related SPI Fails
   spi_write(SPI_COMMAND_REG_DATA+0x1A5, 0x21, 0x22, 0x23)                                --- Assert SS2 of targeted far-side (DES) and 3 byte data                                       
   ss2_1_des = fpga_read_spi("FPGA1",SPI_COMMAND_REG_DATA +0x1A6, SPI_STATUS)       
   spi_write(SPI_COMMAND_REG_DATA +0x1A4, 0x13, 0x14, 0x15)                                --- Assert SS1 of targeted far-side (DES) and 3 byte data                           
   ss1_1_des = fpga_read_spi("FPGA1", SPI_COMMAND_REG_DATA+0x1A6, SPI_STATUS)    

-----Pass-through = 10MHz
   if CHAR then          ----Production no need to test 10Mhz MT 1/2019
        spi_freq  = 10MHz    
        SetSPIClock(spi_freq, 0,"SER")
        data1 = lword(100MHz/(2.0*spi_freq) - 1.0)
        SPI_COMMAND_REG_DATA  = 0x80600000 |( data1 <<12)    
                                                    
        spi_write(SPI_COMMAND_REG_DATA + 0x1A5, 0x41, 0x42, 0x43)                                --- Assert SS2 of targeted far-side (DES) and 3 byte data                                       
        ss2_10_des = fpga_read_spi("FPGA1", SPI_COMMAND_REG_DATA +0x1A6, SPI_STATUS)       
        spi_write(SPI_COMMAND_REG_DATA + 0x1A4, 0x33, 0x34, 0x35)                                --- Assert SS1 of targeted far-side (DES) and 3 byte data                           
        ss1_10_des = fpga_read_spi("FPGA1", SPI_COMMAND_REG_DATA +0x1A6, SPI_STATUS)    
    end_if
-----Pass-through = 25MHz
    spi_freq  = 25MHz
    SetSPIClock(spi_freq, 0, "SER")
    data1 = lword(100MHz/(2.0*spi_freq) - 1.0)
    SPI_COMMAND_REG_DATA  = 0x82600000 |( data1 <<12)
                                                        
    wait(2ms)
    spi_write(SPI_COMMAND_REG_DATA + 0x1A5, 0x61, 0x62, 0x63)                                --- Assert SS2 of targeted far-side (DES) and 3 byte data        6447456                               
    ss2_25_des = fpga_read_spi("FPGA1",SPI_COMMAND_REG_DATA +0x1A6, SPI_STATUS)       
    spi_write( SPI_COMMAND_REG_DATA + 0x1A4, 0x53, 0x54, 0x55)                                --- Assert SS1 of targeted far-side (DES) and 3 byte data         5657940 
    ss1_25_des = fpga_read_spi("FPGA1",SPI_COMMAND_REG_DATA  +0x1A6, SPI_STATUS)    

    --------------- add 50MHz -----------------------------------------------------
    spi_freq  = 50MHz      
    fpga_UART_Write("FPGA1","SER", SER_ID, SR_CMU4, 1,0x0B  ) 
    fpga_UART_Write("FPGA1","SER", SER_ID, SR_SPI_2, 1,0x13  )
    
    SetSPIClock(spi_freq, 1, "SER")
    data1 = lword(100MHz/(2.0*spi_freq) - 1.0)
   
    SPI_COMMAND_REG_DATA  = 0x82600000 |( data1 <<12)   --z                                                      
    wait(2ms)
    spi_write(SPI_COMMAND_REG_DATA + 0x1A5, 0x61, 0x62, 0x63)                                --- Assert SS2 of targeted far-side (DES) and 3 byte data        6447456                               
    ss2_50_des = fpga_read_spi("FPGA1",SPI_COMMAND_REG_DATA +0x1A6, SPI_STATUS)       
    spi_write( SPI_COMMAND_REG_DATA + 0x1A4, 0x53, 0x54, 0x55)                                --- Assert SS1 of targeted far-side (DES) and 3 byte data         5657940                  
    ss1_50_des = fpga_read_spi("FPGA1",SPI_COMMAND_REG_DATA  +0x1A6, SPI_STATUS)   
-----Pass-through = 0.588MHz
    if CHAR then          ----Production no need to test 0.5Mhz MT 1/2019
        spi_freq  = 0.588MHz    -----Current revb hardware only works up to 16MHz at room. didnot check at hot/cold.
        SetSPIClock(spi_freq, 1, "SER")
        data1 = lword(100MHz/(2.0*spi_freq) - 1.0)
        SPI_COMMAND_REG_DATA  = 0x80600000 |( data1 <<12)    
                                                       --- 50Mhz                                                        
        spi_write(SPI_COMMAND_REG_DATA+0x1A5, 0x81, 0x82, 0x83)                                --- Assert SS2 of targeted far-side (DES) and 3 byte data          8552832                             
        ss2_0p588_des = fpga_read_spi("FPGA1", SPI_COMMAND_REG_DATA  +0x1A6, SPI_STATUS)       
        spi_write(SPI_COMMAND_REG_DATA +0x1A4, 0x73, 0x74, 0x75)                                --- Assert SS1 of targeted far-side (DES) and 3 byte data          7763316                 
        ss1_0p588_des = fpga_read_spi("FPGA1", SPI_COMMAND_REG_DATA +0x1A6 , SPI_STATUS)    
-- 
    end_if
   ---------------------------------------------------------------
   -- disable SPI on DES and SER
   fpga_write_register("FPGA1", SPI_COMMAND_REG, mslw(0x00000000))    
   fpga_I2C_Write("FPGA1", "SER", SER_ID, SR_SPI_0, 1, 16#08)	  
   fpga_I2C_Write("FPGA1", "DES", DESA_ID, DR_SPI_0, 1, 16#0A)	
   

   spi_master("DES")   
-- Set direction of Level Translators
   SetPortExpander(PORT_EXP, 0x11)  --  -------Set  SCLK, mosi and RO and output and BNE as input

   fpga_write_register("FPGA1", SPI_COMMAND_REG, mslw(0x00000000)) 
     
------1MHz
   spi_master("DES")   
   fpga_write_register("FPGA1", SPI_COMMAND_REG, mslw(0x00000000)) 
   spi_freq  = 1MHz
   SetSPIClock(spi_freq, 0, "DES")
   data1 = lword(100MHz/(2.0*spi_freq) - 1.0)
   SPI_COMMAND_REG_DATA  = 0x80200000 |( data1 <<12) 
                                                      --- 1Mhz     
   spi_master("DES") --CEF032119:Apparently Fixes 1MHz-related SPI Fails
   spi_write(SPI_COMMAND_REG_DATA +0x1A5, 0x24, 0x25, 0x26)                                --- Assert SS2 of targeted far-side (SER) and 3 byte data     2434083                                  
   ss2_1_ser = fpga_read_spi("FPGA1", SPI_COMMAND_REG_DATA +0x1A6, SPI_STATUS)         
   spi_write(SPI_COMMAND_REG_DATA +0x1A4, 0x16, 0x17, 0x18)                                --- Assert SS1 of targeted far-side (SER) and 3 byte data     1644567                                  
   ss1_1_ser = fpga_read_spi("FPGA1", SPI_COMMAND_REG_DATA +0x1A6, SPI_STATUS)       
--------------10MHz   
   if CHAR then          ----Production no need to test 10Mhz MT 1/2019
        spi_freq  = 10MHz
        SetSPIClock(spi_freq, 0, "DES")
        data1 = lword(100MHz/(2.0*spi_freq) - 1.0)
        SPI_COMMAND_REG_DATA  = 0x80200000 |( data1 <<12)  

        spi_write(SPI_COMMAND_REG_DATA +0x1A5, 0x44, 0x45, 0x46)                                --- Assert SS2 of targeted far-side (SER) and 3 byte data       4539459                                
        ss2_10_ser = fpga_read_spi("FPGA1", SPI_COMMAND_REG_DATA +0x1A6, SPI_STATUS)         
        spi_write(SPI_COMMAND_REG_DATA +0x1A4, 0x36, 0x37, 0x38)                                --- Assert SS1 of targeted far-side (SER) and 3 byte data     3749943                                  
        ss1_10_ser = fpga_read_spi("FPGA1", SPI_COMMAND_REG_DATA +0x1A6, SPI_STATUS)       
    end_if
--------------25MHz   
   spi_freq  = 25MHz
   
   SetSPIClock(spi_freq,0, "DES")
   data1 = lword(100MHz/(2.0*spi_freq) - 1.0)
   SPI_COMMAND_REG_DATA  = 0x80200000 |( data1 <<12)     

   spi_write(SPI_COMMAND_REG_DATA +0x1A5, 0x24, 0x25, 0x26)                                --- Assert SS2 of targeted far-side (SER) and 3 byte data     2434083                                  
   ss2_25_ser = fpga_read_spi("FPGA1", SPI_COMMAND_REG_DATA +0x1A6, SPI_STATUS)         
   spi_write(SPI_COMMAND_REG_DATA +0x1A4, 0x16, 0x17, 0x18)                                --- Assert SS1 of targeted far-side (SER) and 3 byte data     1644567                                  
   ss1_25_ser = fpga_read_spi("FPGA1", SPI_COMMAND_REG_DATA +0x1A6, SPI_STATUS)
   
   -------------- add 50MHz --------------------------------------------------------------   
   spi_freq  = 50MHz 
   SetSPIClock(spi_freq, 1, "DES")
   data1 = lword(100MHz/(2.0*spi_freq) - 1.0)
   SPI_COMMAND_REG_DATA  = 0x81200000 |( data1 <<12)   

   spi_write(SPI_COMMAND_REG_DATA +0x1A5, 0x24, 0x25, 0x26)                                --- Assert SS2 of targeted far-side (SER) and 3 byte data     2434083                                  
   ss2_50_ser = fpga_read_spi("FPGA1", SPI_COMMAND_REG_DATA +0x1A6, SPI_STATUS)         
   spi_write(SPI_COMMAND_REG_DATA +0x1A4, 0x16, 0x17, 0x18)                                --- Assert SS1 of targeted far-side (SER) and 3 byte data     1644567              
   ss1_50_ser = fpga_read_spi("FPGA1", SPI_COMMAND_REG_DATA +0x1A6, SPI_STATUS)

------ 0.588Mhz 
    if CHAR then          ----Production no need to test 0.5Mhz MT 1/2019
        spi_freq  = 0.588MHz
        SetSPIClock(spi_freq, 0, "DES")
        data1 = lword(100MHz/(2.0*spi_freq) - 1.0)
        SPI_COMMAND_REG_DATA  = 0x80200000 |( data1 <<12)      
        spi_write(SPI_COMMAND_REG_DATA +0x1A5, 0x44, 0x45, 0x46)                                --- Assert SS2 of targeted far-side (SER) and 3 byte data        4539459                                
        ss2_0p588_ser = fpga_read_spi("FPGA1", SPI_COMMAND_REG_DATA +0x1A6, SPI_STATUS)         
        spi_write(SPI_COMMAND_REG_DATA +0x1A4, 0x36, 0x37, 0x38)                                --- Assert SS1 of targeted far-side (SER) and 3 byte data     3749943                                  
        ss1_0p588_ser = fpga_read_spi("FPGA1", SPI_COMMAND_REG_DATA +0x1A6, SPI_STATUS)       
    end_if 

  fpga_write_register("FPGA1", SPI_COMMAND_REG, mslw(0x00))

-----End here for debug timing



-------------- Power Down --------------------------- 

      set digital pin SER_X1_AUXSCL + SER_X2_AUXSDA levels to vil 100mv vih 0.3v vol Vddio/2.0 voh Vddio/2.0
    if (POWERDOWN) then
        fpga_Set_DNUT_Pins("FPGA1", 0 ,0, 0, 0, TRUE)  -- UART/TP/GMSL2=1/RATE=0(6 Gig link)
        set digital pin ALL_PATTERN_PINS  - FPGA_CSB-FPGA_SCLK-FPGA_SDIN-FPGA_SDOUT levels to vil 0V vih 200mV iol 0uA ioh 0uA vref 0V            
--        powerdown_device(POWERDOWN)
        open cbit  DNUT_RXTX_RELAY
        open cbit MFP_LT_RELAY  + I2C_LT_CB + MFP_LT_K12_RELAY

        open cbit CB2_SLDC                 --OVI_RELAYS 
        open cbit COAXB_M_RELAY            --OVI_RELAYS
        open cbit  FB_RELAY
        open cbit X1X2_POSC
        wait(5ms)
        powerdown_device(POWERDOWN)
    end_if


------------Data log 
  test_value ireg_val1 with ser_lock_it

   test_value msi(ss1_1_ser )   with ss1_1m_ser  
   test_value msi(ss2_1_ser )   with ss2_1m_ser  
    if CHAR then          ----Production no need to test 10Mhz MT 1/2019    
        test_value msi(ss1_10_ser )  with ss1_10m_ser  
        test_value msi(ss2_10_ser )  with ss2_10m_ser  
    end_if   
   test_value msi(ss1_25_ser )  with ss1_25m_ser  
   test_value msi(ss2_25_ser )  with ss2_25m_ser
    if CHAR then          ----Production no need to test 0.5Mhz MT 1/2019      
        test_value msi(ss1_0p588_ser )  with ss1_0p588m_ser   
        test_value msi(ss2_0p588_ser )  with ss2_0p588m_ser
    end_if    
   
   test_value msi(ss1_1_des )   with ss1_1m_des  
   test_value msi(ss2_1_des )   with ss2_1m_des  
    if CHAR then          ----Production no need to test 10Mhz MT 1/2019          
        test_value msi(ss1_10_des )  with ss1_10m_des  
        test_value msi(ss2_10_des )  with ss2_10m_des  
    end_if   
   test_value msi(ss1_25_des )  with ss1_25m_des  
   test_value msi(ss2_25_des )  with ss2_25m_des
    if CHAR then          ----Production no need to test 0.5Mhz MT 1/2019          
        test_value msi(ss1_0p588_des )  with ss1_0p588m_des    
        test_value msi(ss2_0p588_des )  with ss2_0p588m_des   
    end_if
    
    test_value msi(ss1_50_ser )  with ss1_50m_ser  
    test_value msi(ss2_50_ser )  with ss2_50m_ser
    test_value msi(ss1_50_des )  with ss1_50m_des  
    test_value msi(ss2_50_des )  with ss2_50m_des
    
 end_body



procedure SER_DESA_Reg_UART_PT_Func (vcore, vio, v18, TX_SPD_it, RX_SPD_it, link_type_it, Freq_it,DesPT1,SerPT1,DesPT2,SerPT2, TP_COAX,TX_SPD,RX_SPD,Freq,value1,value2, Link_Lock_dly,POWERUP,POWERDOWN,LinkRset)
--------------------------------------------------------------------------------
in float            : vcore, vio, v18
--in_out integer_test : devid_it, dnutid_it, ser_lock_it, des_lock_it,iser_read_reg1_it,iser_read_reg2_it, link_type_it
in_out integer_test :  link_type_it,DesPT1,SerPT1,DesPT2,SerPT2
in_out float_test   : TX_SPD_it, RX_SPD_it, Freq_it

in string[20]       : TP_COAX
in float            : TX_SPD, RX_SPD, Freq, Link_Lock_dly
in lword            : value1, value2           -- values to write to SER & DESA FPGA internal EEPROM across link
in boolean          : POWERUP,POWERDOWN,LinkRset

local

  multisite lword   : LowerRdWord, UpperRdWord
   
  float             : Vconf0, Vconf1
  multisite lword   : lowword, upperword, des_read0, des_read1, des_read2, des_read, ser_read, ser_local_read, ser_read_reg, ser_read_reg1, ser_read_reg2, data_write

--  multisite lword   : reg_val, reg_val0, reg_val1, reg_val_ser, reg_val_des
  multisite integer : ireg_val, ireg_val0, ireg_val1, ireg_val_ser, ireg_val_des, ireg_val15, iser_read_reg, iser_read_reg1, iser_read_reg2, link_type
  word              : sites, idx, site
  integer           : idxs
  
  multisite lword   : hizdel_reg_val, oreg_reg_val
  lword             : data
  
  multisite lword   : reg_val11,reg_val12,reg_val13,reg_val14,reg_val15
  lword             : ser_link_speed_code, des_link_speed_code, ser_tx_speed, ser_rx_speed, des_tx_speed, des_rx_speed
  lword             : number_of_lane, des_csi_mode,des_numb_lane,mipi_speed, ser_csi_mode
  float             : w_r_delay
  multisite float             : TX_SPD_rate, RX_SPD_rate, Freq_com 
  multisite lword   : serdata, desdata,  serdataPT1, desdataPT1 ,  serdataPT2, desdataPT2

  multisite integer : ISerData,IDesData,ISerDataPT1,IDesDataPT1,ISerDataPT2,IDesDataPT2
   boolean         : loopcont
    multisite boolean : SiteCheck
    word            :sitecount,count  
end_local

body
  
 

    TX_SPD_rate = TX_SPD
    RX_SPD_rate = RX_SPD
    Freq_com    = Freq

    active_sites = get_active_sites
    sites = word(len(active_sites))  
   loopcont  = true
   SiteCheck  = false 
-----Dut power up function
   DutPowerUp(vio, v18, vcore, "UART", "TP_GMSL2",POWERUP)------------- DutPowerUp(vio, v18, vcore, "UART", "TP_GMSL1",POWERUP)


--------powerup_dnut_vdd_vterm(VDD_SET, VTERM_SET)
   if   POWERUP then
        powerup_dnut_vdd_vterm(1.2,1.2)

-------Connect TX/RX of Dut and DNUT to FPGA
        close cbit MFP_LT_RELAY + DNUT_RXTX_RELAY + I2C_LT_CB+I2C1_LT_CB + I2C2_FT2_LT_CB
        close  cbit DNUT_RXTX_RELAY+ MFP_LT_K12_RELAY
        fpga_Set_DNUT_Pins("FPGA1", 0,0, 1, 1, TRUE)  -- UART/TP/GMSL2=1/RATE=0(6 Gig link)               
        wait(6ms)

   end_if  
 

    if LinkRset then 
-------Connect TX/RX of Dut and DNUT to FPGA
        close  cbit MFP_LT_RELAY + DNUT_RXTX_RELAY + I2C_LT_CB +I2C1_LT_CB + I2C2_FT2_LT_CB
        close digital cbit DNUT_RXTX_RELAY+ MFP_LT_K12_RELAY
        wait(4ms)

        fpga_set_UART_Frequency("FPGA1", Freq)
--- Set SER and DES for coax or tp mode using FPGA
        if TP_COAX[1:2] = "TP" then
            fpga_UART_Write("FPGA1","SER", SER_ID, 16#11, 1, 0x0A)                      ---- TP mode 0x11                                    
            link_type = 1 
        -- open termination relay at negative SL
            open cbit    CB2_SLDC            --FX_RELAYS 
            open cbit COAXB_M_RELAY             --OVI_RELAYS
            wait(5ms)                
        else
            fpga_UART_Write("FPGA1","SER", SER_ID, 16#11, 1, 0x0F)                      ---- coax mode 0x11                    
            fpga_UART_Write("FPGA1","DES", DESA_ID, 16#11, 1, 0x0F)                    ---- coax mode 0x11
            link_type = 0                
            -- close termination relay at negative SL
            close  cbit CB2_SLDC                     --OVI_RELAYS
            close cbit COAXB_M_RELAY                --OVI_RELAYS
         wait(5ms)               
        end_if 

-- ------ Set GMSL link forward and backward speed.

        if TX_SPD = 6GHz then
            ser_tx_speed = 0x8
            des_rx_speed = 0x2
        elseif      TX_SPD = 3GHz then
            ser_tx_speed = 0x4
            des_rx_speed = 0x1            
        elseif      TX_SPD = 1.5GHz then 
            ser_tx_speed = 0x0
            des_rx_speed = 0x0                      
       end_if  

       if RX_SPD = 1.5GHz then
            ser_rx_speed = 0x3
            des_tx_speed = 0xC
       elseif      RX_SPD = 0.75GHz then
            ser_rx_speed = 0x2
            des_tx_speed = 0x8      
      
       elseif      RX_SPD = 0.375GHz then
            ser_rx_speed = 0x1
            des_tx_speed = 0x4          
       elseif      RX_SPD = 0.1875GHz then
            ser_rx_speed = 0x0
            des_tx_speed = 0x0               
       end_if 
       
        ser_link_speed_code = ser_rx_speed + ser_tx_speed
        des_link_speed_code = des_rx_speed + des_tx_speed
    
    
--- Program link rate
        fpga_UART_Write("FPGA1","SER", SER_ID, 16#01, 1, ser_link_speed_code  )               ---- SER GMSL link speed    
        fpga_UART_Write("FPGA1","DES", DESA_ID, 16#01, 1, des_link_speed_code  )             ---- DES GMSL link speed
        wait(10mS)  ----Needed 
--- Write to reg10 to update link speed setting     
    -- write Reg0x10 to update to COAX mode
        fpga_UART_Write("FPGA1","DES", DESA_ID, 16#10, 1, 0x00)
        wait(2ms)
        fpga_UART_Write("FPGA1","SER", SER_ID, 16#10, 1, 0x30)             -- Set auto link config and one shot
 --       ser_read =  fpga_UART_Read("FPGA1", "SER", SER_ID, 0x10, 1)        -- self adjust back to 0x01    

--    ser_local_read =  fpga_UART_Read("FPGA1", "SER", SER_ID, SR_CTRL3, 1)      -- for SER lock bit, good if 0xDA               
--     site = active_sites[1]
--     for i = 1 to 500 do
--             reg_val15      =  fpga_UART_Read("FPGA1", "DES", DESA_ID, DR_CTRL3, 1)      -- DES lock bit, 0xDA expected   
--             if reg_val15[site] = 0xCA or reg_val15[site] = 0xCE then
--                 break
--             else
--                 wait(2ms)
--             end_if
--    end_for         
   lowword =  fpga_UART_Read("FPGA1", "SER", SER_ID, 0x13, 1)      -- for SER lock bit, good if 0xDA 
--   reg_val15  = fpga_UART_Read("FPGA1", "DES", DESA_ID, 0x13, 1)   -- DES lock bit, 0xCA expected   

    while( loopcont) do
        for idx = 1 to sites do 
            site = active_sites[idx]
                if  (lowword[site] = 0xde  OR lowword[site] =0xda  OR lowword[site] =0xCa OR lowword[site] =0xCE OR lowword[site] =0xEa OR lowword[site] =0xEE) and not SiteCheck[site] then
                    sitecount = sitecount + 1
                    SiteCheck[site] = true     
                end_if
                if sitecount = sites then
                    loopcont = false
                end_if     
            count = count + 1
            if count > 200 then
                loopcont  = false
            end_if
            if loopcont  then
                wait(1ms)
                lowword =  fpga_UART_Read("FPGA1", "SER", SER_ID, 0x13, 1)      -- for SER lock bit, good if 0xDA 
            end_if
            
        end_for            
 
    end_while
     ser_local_read =  fpga_UART_Read("FPGA1", "SER", SER_ID, 0x13, 1)      -- for SER lock bit, good if 0xDA  
     reg_val15  = fpga_UART_Read("FPGA1", "DES", DESA_ID, 0x13, 1)   -- DES lock bit, 0xCA expected 




----Enable uart pass through
   fpga_UART_Write("FPGA1", "SER", SER_ID, SR_REG3, 1, 0x30)        
   fpga_UART_Write("FPGA1", "DES", DESA_ID, DR_REG3, 1,0x30 )         

-------
   fpga_UART_Write("FPGA1", "SER", SER_ID, SR_UART_PT_0_4F, 1, 0x88)                           -- Custom UART bit rate in pass-thru UART PT1 and PT2
   fpga_UART_Write("FPGA1", "DES", DESA_ID, DR_UART_PT_0_4F , 1, 0x88)

------------------
   for i = 0 to 19 do 
      if i >4 then 
         fpga_UART_Write("FPGA1", "DES", DESA_ID, (DR_GPIO_A_0+(lword(i)*3)), 1, 0x81)                --- disable GPIO0 to GPIO19     
      endif
         fpga_UART_Write("FPGA1", "SER", SER_ID, ((SR_GPIO_A_0+(lword(i)*3))), 1, 0x81)          --- disable GPIO0 to GPIO19     
    endfor   



    end_if

        ser_local_read =  fpga_UART_Read("FPGA1", "SER", SER_ID, SR_CTRL3 , 1)      -- for SER lock bit, good if 0xDA         
     for idxs = 1 to len(active_sites) do
        site = active_sites[idxs]
        ireg_val1[site]  = integer(ser_local_read[site])
        ireg_val15[site] = integer(reg_val15[site])      
     end_for    


    fpga_set_UART_Frequency("FPGA1", Freq)
    wait(1ms)---3ms    

   ser_read = 0x00        -- initialization needed.
   ser_read_reg1 = 0x00
   ser_read_reg2 = 0xFF
         

    w_r_delay = 200us

      wait(w_r_delay)  

    UART_BITLEN_PT(double(Freq))                          ---Set freq for pass through

--------PT1
   data_write = 0x04
   fpga_write_register("FPGA1", UART_PT_CTRL_REG, data_write)                     ---Connect UART_PT1 from Des to main uart port by FPGA 

   fpga_UART_Write("FPGA1", "SER_PT1", DESA_ID, 0x180, 1, 0x55)                   ----Des Program 0xAA to remote  PT1  to RGMII reg
   desdataPT1 =  fpga_UART_Read("FPGA1", "SER_PT1",DESA_ID , 0x180, 1)             ----Ser read back 0xAA from remote device PT1
   
   fpga_UART_Write("FPGA1", "SER_PT1", DESA_ID, 0x180, 1, 0x00)                 ---reset to 0

--     desdataPT1 =fpga_read_register("FPGA1",127)

   data_write = 0x06                ----write read from Des pt1
   fpga_write_register("FPGA1", UART_PT_CTRL_REG, data_write) 
  fpga_UART_Write("FPGA1", "DES_PT1", SER_ID, 0x180 , 1, 0xAA)                   ----Des Program 0x55 to remote  PT1  to RGMII reg
  serdataPT1 =  fpga_UART_Read("FPGA1", "DES_PT1", SER_ID, 0x180 , 1)            ----Des read back 0x55 from remote device PT1
  fpga_UART_Write("FPGA1", "DES_PT1", SER_ID, 0x180 , 1, 0x00)                ---reset to 0

--------PT2
   data_write = 0x05
   fpga_write_register("FPGA1", UART_PT_CTRL_REG, data_write)                     ---Connect UART_PT1 from Des to main uart port by FPGA 
   fpga_UART_Write("FPGA1", "SER_PT2", DESA_ID, 0x180, 1, 0x55)                   ----Des Program 0x55 to remote  PT1  to RGMII    
   desdataPT2 =  fpga_UART_Read("FPGA1", "SER_PT2",DESA_ID , 0x180, 1)             ----Ser read back 0x55 from remote device PT1
   fpga_UART_Write("FPGA1", "SER_PT2", DESA_ID, 0x180, 1, 0x00)                 ---reset to 0
   data_write = 0x07
   fpga_write_register("FPGA1", UART_PT_CTRL_REG, data_write)                     ---Connect UART_PT1 from Des to main uart port by FPGA 

   fpga_UART_Write("FPGA1", "DES_PT2", SER_ID, 0x180, 1, 0xAA)                   ----Des Program 0xaa to remote  PT1  to RGMII 
   serdataPT2 =  fpga_UART_Read("FPGA1", "DES_PT2",SER_ID , 0x180, 1)             ----Ser read back 0xaa from remote device PT1
   fpga_UART_Write("FPGA1", "DES_PT2", SER_ID, 0x180, 1, 0x00)                    ---reset to 0


   data_write = 0x00
   fpga_write_register("FPGA1", UART_PT_CTRL_REG, data_write) 




    if POWERDOWN then   
--        powerdown_device(POWERDOWN)
        open cbit MFP_LT_RELAY + DNUT_RXTX_RELAY + I2C_LT_CB ------for now
        open  cbit CB2_SLDC                     --OVI_RELAYS
        open cbit COAXB_M_RELAY                --OVI_RELAYS
        open  cbit  I2C1_LT_CB + I2C2_FT2_LT_CB    + MFP_LT_K12_RELAY
        wait(5ms)   
--         powerup_dnut_vdd_vterm(0.0,0.0)
-----------  --fpga_Set_DNUT_Pins("FPGA1", CFG1, CFG0, PWDN, latch)
        fpga_Set_DNUT_Pins("FPGA1", 0,0, 0, 0, TRUE)  -- UART/TP/GMSL2=1/RATE=0(6 Gig link)               
        wait(1ms)                 
        powerdown_device(POWERDOWN)

    end_if
   for idxs = 1 to len(active_sites) do
     site = active_sites[idxs]
     --ireg_val_ser[site]  = integer(ser_read[site])
     ISerData[site]  = integer(serdata[site])
     ISerDataPT1[site]  = integer(serdataPT1[site])                
     ISerDataPT2[site]  = integer(serdataPT2[site]) 
     IDesData[site]  = integer(desdata[site])
     IDesDataPT1[site]  = integer(desdataPT1[site])
     IDesDataPT2[site]  = integer(desdataPT2[site])
   end_for


   test_value TX_SPD_rate  with TX_SPD_it 
   test_value RX_SPD_rate  with RX_SPD_it
   test_value link_type  with link_type_it    
--    test_value ireg_val1 with ser_lock_it
--    test_value ireg_val15 with des_lock_it 
--DesPT,SerPT,DesPT1,SerPT1,DesP2,SerPT2   
   test_value Freq_com with Freq_it           

 --   test_value IDesData with DesPT
--    test_value ISerData with SerPT
   test_value IDesDataPT1 with DesPT1
   test_value ISerDataPT1 with SerPT1
   test_value IDesDataPT2 with DesPT2
   test_value ISerDataPT2 with SerPT2 
 end_body

procedure TestClock_Trim(vcore, vio, v18, rword, OTP_FAIL_PIN,OTP_DONE_PIN, PreTrimFreq,PostTrimFreq,TrimCode,InitialTrimCheck510, InitialTrimCheck511, OTP_Enhancement_Check, trimok, RWORD,POWERUP,POWERDOWN)
--------------------------------------------------------------------------------
in float            : vcore, vio, v18
in PIN LIST[1]      : OTP_FAIL_PIN,OTP_DONE_PIN
in_out float_test   : PreTrimFreq,PostTrimFreq
in_out integer_test : trimok

in_out integer_test : rword,TrimCode
in_out integer_test : InitialTrimCheck510, InitialTrimCheck511 , OTP_Enhancement_Check
in boolean          : POWERUP,POWERDOWN
in lword            :   RWORD
local   
    word                : sites, idx, site, idxs, numbersites
--    integer             : idxs
    boolean             : CHAR
    multisite lword     : lowword, upperword
    multisite integer   : reg_val
    lword               : value_to_write, i
    boolean             :tmu_present, timed_out
    multisite float     : freq,freq0,freq1, freq2,freq3, freq4,freq5, freq6,freq7
    multisite double    : freq_meas[1],array_freq[8]
    multisite lword     :  otp_addr    
    lword               : addr
    multisite lword     : reg_data
    integer             : NEED_PROGRAM = 0
    word                : siteidx, thissite    
    word list[MAX_SITES]   : current_active_sites,    active_sites
    multisite float     : PreTrim,PostTrim
    float               : TrimTarget
    multisite lword     :trimcode
    string[6]           :TestType, TestTemp
    string[6]           :  OTP_TEMP = "HOT"
    
     multisite lword     : tempdata,tempdata1
     multisite lword      : reg_data84Min,reg_data85Min ,reg_data86Min  ,reg_data84Max,reg_data85Max,reg_data86Max

    multisite lword      : reg_data81Min,reg_data511Min,reg_data81Max,reg_data511Max, reg_data510Max, reg_data_510_TrimCheck,  reg_data_511_TrimCheck
    multisite integer    : DataMinMaxNotEq
    multisite integer    : TrimmedCheck510fail, TrimmedCheck511fail,  trimcheck_enhancement, OTP8_PgmFail_Check, OTP8_PgmDone_Check
    multisite integer    : Reg15ValInt, Reg13ValInt, Reg15ValOk,Loc511Data,OTPLock
    word list[16]       : OTP_active_sites
    multisite boolean    : DonePinHigh,PrgFailPin,PartFail
     multisite boolean   : otp_fail
     multisite lword     : otp_data,otp_data510
     boolean              : PrgLoc511
     multisite integer   : prog_ok,otp_blank_test
     multisite lword     : temp_write_data[6]
     
end_local   

body
    get_expr("OpVar_Char", CHAR)
    active_sites = get_active_sites
    sites = word(len(active_sites))  
    current_active_sites = get_active_sites
    TrimTarget  = 75MHz
    
     get_expr("OpVar_TestTemp", TestTemp )
     get_expr("OpVar_TestType", TestType )
    
    
  TrimmedCheck510fail = 0 
  TrimmedCheck511fail = 0
  trimcheck_enhancement = 0
  otp_fail = FALSE
  PrgLoc511 = FALSE

    disconnect hvvi chan SER_RSVD    -- need to float RSVD, important!!

    fpga_Set_DNUT_Pins("FPGA1", 0,0, 0, 0, TRUE)  -- UART/TP/GMSL2=1/RATE=0(6 Gig link)     
    lowword  = fpga_UART_Read("FPGA1", "DES", DESA_ID, 0, 1)      -- UART read  
-----Dut power up function

----   close cbit XRES_RELAY -- zin revb LB move to on init
   DutPowerUp(vio, v18, vcore, "UART", "TP_GMSL1",POWERUP)------------- DutPowerUp(vio, v18, vcore, "UART", "TP_GMSL1",POWERUP)

-----Code from here
  
    RegRead(SER_ID, SR_REG6 , 1,upperword, lowword , "SER_UART_Read")   

    RegWrite(SER_ID, SR_CMU4, 1, 0, 0x00 ,"SER_UART_Write" )   -----For production rev, need to program Fast edge otherwise not working 6/2018

    wait(0)

    get_expr("OpVar_TestType", TestType)  -- determine test type, QA or FT
    get_expr("OpVar_TestTemp", TestTemp)  -- determine test temperature, (ROOM, HOT, COLD)


       
 ---enter debug mode to bring osc out at MFP1 pin    
        SetTestMode(5 , False , "SER_UART_Write" )
        value_to_write = 16#06
        RegWrite(SER_ID, SR_TEST0, 1, 0, value_to_write ,"SER_UART_Write" )
--------------------Program 0x0544 OSC_0
        set digital pin SER_GPIO1_LFLTB_ERRB modes to driver off load off
    
        value_to_write =  0x00--0x40
        RegWrite(SER_ID, SR_OSC_1, 1, 0, value_to_write ,"SER_UART_Write" ) 
        measure digital pin SER_GPIO1_LFLTB_ERRB  frequency interval 100.0e6 sample size count_legacy asynchronous into freq_meas
        for idxs = 1 to sites do ---- setup read value for data log 
            site = active_sites[idxs]
             PreTrim[site] = float(freq_meas[site,1])
             PostTrim[site] = PreTrim[site] 
        end_for         
     
    ------------------------------------- TestTemp ="HOT" -- force it to trim at room  need to remove it Zin 

    if TestType = "FT" and TestTemp = "HOT" then
-------------Check memory
        OTP_Reg_Write(SER_ID, OTP0,1, mlw(0x00), 0, mlw(0x00))---disable program
        OTP_Reg_Write(SER_ID,OTP0 ,1, mlw(0x40), 0, mlw(0x00))---enable read
    -----Readback memory location to see whether part has been trim or not
    ---- Also Check Crc Locations 510 and 511 for BAD data
           ----Read location 510 to see Pre Trim Status
        otp_addr =  32*510	   
        OTP_Reg_Write(SER_ID, OTP2,2, otp_addr, 0,mlw(0x00) )---set address to read from   
        tempdata1 = OTP_Reg_Read(SER_ID, OTP14, 4)    
         reg_data_510_TrimCheck = tempdata1
       
       
        ----Read location 511 to see Pre Trim Status
        otp_addr =  32*511	   
        OTP_Reg_Write(SER_ID, OTP2,2, otp_addr, 0,mlw(0x00) )---set address to read from   
        tempdata1 = OTP_Reg_Read(SER_ID, OTP14, 4)    
        reg_data_511_TrimCheck = tempdata1
        
               ----Read the lock bit -----------------------------------------------------------------------------------------------------------------------------------
        
        RegRead(SER_ID, 0x1808 , 1,  upperword,lowword, "SER_UART_Read")      ---Check memory lock bit. Make sure it is high
        OTPLock =   integer(lowword)   -- OTP RD DONE and OTP LOCK  1000 1000 (0x88)  
    
        for siteidx = 1 to sites do
            thissite = current_active_sites[siteidx]   
            OTPLock[thissite] =   (integer(lowword[thissite]) &0x8) >> 3            
                       
            if  reg_data_510_TrimCheck[thissite] = 16#FEFEFEFE then
                TrimmedCheck510fail[thissite] = 1
            end_if
            
            if  reg_data_511_TrimCheck[thissite] = 16#EFEFEFEF then
                TrimmedCheck511fail[thissite] = 1
            end_if
        end_for
        
   
        
    -- ---OTP read memory--------------------------------------------------------------
        for  addr =0x84  to  0x84 do ---- This location store traceability of part   
        
            otp_addr =  32*(addr)	   
            OTP_Reg_Write(SER_ID, 16#1802,2, otp_addr, 0,mlw(0x00) )---set address to read from

            reg_data = OTP_Reg_Read(SER_ID, 16#1814, 4)
            for siteidx = 1 to sites do  
                thissite =current_active_sites [siteidx]                   
                if reg_data[thissite] = 0 then --- part not trimmed yet
                    NEED_PROGRAM = NEED_PROGRAM+1
                else 
                    deactivate site thissite  --- already trimmed no need to
                end_if
            end_for    
        end_for
        if NEED_PROGRAM >0 then  ----need trim part 
-----Check how many sites need to be trimmed
            current_active_sites = get_active_sites
            numbersites = word(len(current_active_sites))
            value_to_write = 0x40
            OTP_Reg_Write(SER_ID,SR_OSC_1 ,1, mlw(value_to_write), 0,mlw(0))

--            RegWrite(SER_ID, SR_OSC_1, 1, 1, value_to_write+1 ,"SER_UART_Write" ) 
            measure digital pin SER_GPIO1_LFLTB_ERRB  frequency interval 100.0e6 sample size count_legacy asynchronous into freq_meas

            for idx = 1 to numbersites do 
                site = current_active_sites[idx]
                if float(freq_meas[site,1]) >= TrimTarget then  --- need trimdown                    
                    trimcode[site] = lword(( PreTrim[site]-TrimTarget)/TrimTarget/0.05 + 0.5)                 
                else
                    trimcode[site] = lword((abs( PreTrim[site]-TrimTarget)/TrimTarget/0.05 + 0.5)) | 0x4 --- turn on bit 2 to shift up
                endif
                
            end_for

---------------------------- OTP Programming 
-----Modify procedure to  the newest require by DE. Trim at Vddio = 2.75V, Vdd18 =2.1V, and Vdd = 0.95
        reg_data = OTP_Reg_Read(SER_ID, SR_CTRL0, 1) 
        OTP_Reg_Write(SER_ID, SR_CTRL0,1, (reg_data | 0x40), 0,mlw(0x00) )--------Turn off GMLS phy for trim because with this rev Vdd18 = 2.1V to trim it is higher then abmax spec 9/2018

---       Set_SER_Voltages(vio, vdd, vdd18)
        Set_SER_Voltages(2.75, 0.95, 2.1 )


            OTP_Reg_Write(SER_ID, OTP0,1, mlw(0x00), 0,mlw(0))---disable read OTP0 =0X1800 FOR HS89
            OTP_Reg_Write(SER_ID, OTP1,1, mlw(0x02), 0, mlw(0))---enable  OTP_PGM_DONE and OTP_PGM_FAIL to GPIO15  and GPIO14  and select GMSL section OTP1 = 0X1801
---OTP Write 
            OTP_Reg_Write(SER_ID, OTP0,1, mlw(0x20), 0, mlw(0))---enable write 
            
        set digital pin OTP_DONE_PIN + OTP_FAIL_PIN modes to driver pattern comparator enable all fails
        set digital pin  OTP_DONE_PIN + OTP_FAIL_PIN levels to vih 0.9*vio vil 0.1*vio vol 0.5*vio voh 0.5*vio iol 0mA ioh 0mA vref 0V

            trimcode =  trimcode << 15
            otp_addr  = 0x83 * 32
            OTP_Reg_Write(SER_ID, 16#1802,2, otp_addr, 4, trimcode )---Write data to address
            wait(10ms) --- will work this out time wait for otp done/fail

               --z read digital pin OTP_DONE_PIN state compare to high into DonePinHigh   ----expect high MT 1/2020
               --z read digital pin OTP_FAIL_PIN  state compare to low into PrgFailPin    ---expect low 
                
                -- Reading OTP8 to check OTP_PGM_DONE and OTP_PGM_FAIL
       
                RegRead(SER_ID, 0x1808 , 1,  upperword,lowword, "SER_UART_Read")      ---Check OTP8 bit4 to check OTP_PGM_FAIL status
                OTPLock =   integer(lowword)   -- OTP RD DONE and OTP LOCK  1000 1000 (0x88) 
        
                otp_data = 0     -- initialize
                otp_data510 = 0  -- initialize 
                
                for siteidx =1 to numbersites do    -- hcu 03/10/2020 change sites to numbersites variable for fresh units only
	            thissite = current_active_sites[siteidx]
	       
	           OTP8_PgmFail_Check[thissite] = OTPLock[thissite] & 0x10 >> 4
	           OTP8_PgmDone_Check[thissite] = OTPLock[thissite] & 0x20 >> 5	           
	                	       	       
	           if ( OTP8_PgmDone_Check[thissite] = 0 or (OTP8_PgmFail_Check[thissite] = 1) ) then	       
	          
	               trimcheck_enhancement [thissite] = 1  -- program fail
	               PartFail[thissite] = TRUE
	               
	               otp_data[thissite] = 0xEFEFEFEF
                       otp_data510[thissite] = 0xFEFEFEFE
	               PrgLoc511   = TRUE
	           end_if
	       
	       end_for  
	       
	 if  PrgLoc511  then   
	       
	       otp_addr = 511*32
               OTP_Reg_Write(SER_ID, 16#1802,2,otp_addr , 4, otp_data )---Write data to address
               wait(10ms) --- will work this out time wait for otp done/fail 
               otp_addr = 510*32
               OTP_Reg_Write(SER_ID, 16#1802,2,otp_addr , 4, otp_data510 )---Write data to address
               wait(10ms) --- will work this out time wait for otp done/fail 
	  
	  end_if  
	  
	  
	  --------------------- verify ---------------------------------------------------------------------------------
	  
	  
	 DutPowerUp(vio, v18, vcore, "UART", "TP_GMSL2",POWERUP)
        
        ---Change supply to 1.7 as requested by DE
        if TestType = "QA" then
            Set_SER_Voltages(1.7, 0.95, 1.7)
        else
            if OTP_TEMP = "COLD" then
                Set_SER_Voltages(1.7, 0.95, 1.58) -------- FT flow  cold
            else
                Set_SER_Voltages(1.7, 0.95, 1.68) -------- FT flow
            end_if   
        end_if   
     

        wait(5ms)
---- ---Change supply back to normal
--        Set_SER_Voltages(1.7, vdd, 1.7 )
--        OTP_Reg_Write(DEV_ID, DR_CTRL0,1, (reg_data), 0,mlw(0x00) )--------Turn on GMLS phy for trim because with this rev Vdd18 < 2.0V 
      
       OTP_Reg_Write(SER_ID, OTP0,1, mlw(0x00), 0, mlw(0x00))---disable program
       OTP_Reg_Write(SER_ID,OTP0 ,1, mlw(0x40), 0, mlw(0x00))---enable read
       prog_ok =0 ---reset fail_count variable 

       
        otp_addr  = 0x83 * 32	   
        OTP_Reg_Write(SER_ID, 16#1802,2, otp_addr, 0,mlw(0x00) )---set address to read from             
        reg_data = OTP_Reg_Read(SER_ID, 16#1814, 4)
        
        for siteidx = 1 to numbersites do  -- hcu 03/10/2020 change sites to numbersites variable for fresh units only
            thissite = current_active_sites [siteidx]                   
            
            if (reg_data[thissite] <> trimcode[thissite]) or PartFail[thissite]  then
                  prog_ok[thissite] = prog_ok[thissite] + 1
            end_if
        end_for   
        
       -----------------Need addition condition for max read back
       Set_SER_Voltages(3.6, 1.05, 1.9) -- Vmax for both QA and FT 
       
	otp_addr  = 0x83 * 32	   
        OTP_Reg_Write(SER_ID, 16#1802,2, otp_addr, 0,mlw(0x00) )---set address to read from             
        reg_data = OTP_Reg_Read(SER_ID, 16#1814, 4)
        
        for siteidx = 1 to numbersites do  -- hcu 03/10/2020 change sites to numbersites variable for fresh units only
            thissite = current_active_sites [siteidx]                   
            
            if (reg_data[thissite] <> trimcode[thissite]) or PartFail[thissite]  then
                  prog_ok[thissite] = prog_ok[thissite] + 1
            end_if
        end_for 
        
       
       
       ------------------------- end of verify ------------------------------------------------------------------------------------------------------  
	  
	 	  
	  
	  
	  
        --------------------------------------------------------------------------------------------------------------------    

        --------------------Need power cycle to measure post trim
            set digital pin SER_GPIO1_LFLTB_ERRB modes to driver pattern
            powerdown_device(TRUE) 
            DutPowerUp(vio, v18, vcore, "UART", "TP_GMSL1",TRUE)------          
            
            
            RegWrite(SER_ID, SR_CMU4, 1, 0, 0x00 ,"SER_UART_Write" )   
-------enter debug mode to bring osc out at MFP1 pin    
            SetTestMode(5 , False , "SER_UART_Write" )
            value_to_write = 16#06
            RegWrite(SER_ID, SR_TEST0, 1, 0, value_to_write ,"SER_UART_Write" )
--------------------Program 0x0544 OSC_0
            set digital pin SER_GPIO1_LFLTB_ERRB modes to driver off load off            
            value_to_write =  0x00--0x40
            RegWrite(SER_ID, SR_OSC_1, 1, 1, value_to_write ,"SER_UART_Write" ) 
            measure digital pin SER_GPIO1_LFLTB_ERRB  frequency interval 100.0e6 sample size count_legacy asynchronous into freq_meas
            for idxs = 1 to sites do ---- setup read value for data log 
                site = active_sites[idxs]
                PostTrim[site] = float(freq_meas[site,1])
            end_for                               
        end_if   ----If NEED_PROGRAM

    else  ---- no need to trim 

    end_if


    activate site active_sites


-------------- Power Down ---------------------------
      set digital pin SER_GPIO1_LFLTB_ERRB modes to driver pattern
      powerdown_device(POWERDOWN)  


---Data log out 

    test_value reg_val with rword

    test_value PreTrim with PreTrimFreq
    test_value PostTrim with PostTrimFreq
    test_value msi(trimcode>>15) with TrimCode
    
    test_value TrimmedCheck510fail with InitialTrimCheck510
    test_value TrimmedCheck511fail with InitialTrimCheck511
    test_value TrimmedCheck511fail with InitialTrimCheck511
    
    if NEED_PROGRAM > 0 then  ----data log trim 
        test_value TrimmedCheck511fail with InitialTrimCheck511
        test_value  prog_ok with trimok
    end_if 

end_body

procedure Dpll_Rclkout( vcore, vio, v18,POWERUP,POWERDOWN,freq_meas_it, freq_meas_xtal1_it, freq_meas_xtal2_it, freq_meas_75_it, freq_meas_37_it, freq_meas_27_it, freq_meas_19p2_it, freq_meas_alt1_it,freq_meas_alt2_it,freq_meas_alt3_it,freq_meas_alt4_it)
--------------------------------------------------------------------------------
in float            : vcore, vio, v18
--in_out float_test   : PreTrimFreq,PostTrimFreq
in_out float_test   : freq_meas_it, freq_meas_xtal1_it, freq_meas_xtal2_it, freq_meas_75_it, freq_meas_37_it, freq_meas_27_it, freq_meas_19p2_it
in_out float_test   : freq_meas_alt1_it,freq_meas_alt2_it,freq_meas_alt3_it,freq_meas_alt4_it

--in_out integer_test : rword,TrimCode
in boolean          : POWERUP,POWERDOWN
--in lword            :   RWORD
local   
    word                : sites, idx, site, idxs, numbersites
--    integer             : idxs
    boolean             : CHAR
    multisite lword     : lowword, upperword
    multisite integer   : reg_val
    boolean             :tmu_present, timed_out
    multisite lword     : reg_data
    word                : siteidx, thissite    
    word list[MAX_SITES]   : current_active_sites,    active_sites

    string[6]           :TestType, TestTemp
    multisite double    : freq_meas_PU[1], freq_meas_xtal1[1],freq_meas_xtal2[1], freq_meas_75[1], freq_meas_37[1], freq_meas_27[1], freq_meas_19p2[1]
    multisite double    : freq_meas_alt1[1],freq_meas_alt2[1],freq_meas_alt3[1],freq_meas_alt4[1]

end_local   

body
    get_expr("OpVar_Char", CHAR)
    active_sites = get_active_sites
    sites = word(len(active_sites))  
    current_active_sites = get_active_sites


    disconnect hvvi chan SER_RSVD    -- need to float RSVD, important!!
    close cbit COAXB_P_RELAY + COAXB_M_RELAY  ---Connecto DC circuit  MT 11/2018
-----Dut power up function
   DutPowerUp(vio, v18, vcore, "UART", "TP_GMSL1",POWERUP)------------- DutPowerUp(vio, v18, vcore, "UART", "TP_GMSL1",POWERUP)

-----Code from here

  --  RegRead(SER_ID, SR_REG6 , 1,upperword, lowword , "SER_UART_Read")   
 --RegRead(SER_ID, 0 , 1,upperword, lowword , "SER_UART_Read")  


    RegWrite(SER_ID, SR_CMU4, 1, 0, 0x00 ,"SER_UART_Write" )   -----For production rev, need to program Fast edge otherwise not working 6/2018

    wait(0)
--   set digital pin SER_GPIO3_RCLKOUT modes to driver pattern load off   ---- cause glitch
   RegWrite(SER_ID, SR_REG6, 1, 0, 16#Ab ,"SER_UART_Write" )         -- enable RCLKOUT
set digital pin  SER_GPIO3_RCLKOUT  levels to vol vio/2.0 voh vio/2.0+50mV iol 0uA ioh 0uA vref 0V

   -- XTAL to RCLKOUT by default
   RegWrite(SER_ID, SR_REG3, 1, 0, 16#00 ,"SER_UART_Write" )
   measure digital pin SER_GPIO3_RCLKOUT frequency interval 100.0e6 sample size count_legacy asynchronous into freq_meas_PU
   RegWrite(SER_ID, SR_REG3, 1, 0, 16#01 ,"SER_UART_Write" )
   measure digital pin SER_GPIO3_RCLKOUT frequency interval 100.0e6 sample size count_legacy asynchronous into freq_meas_xtal1
    RegWrite(SER_ID, SR_REG3, 1, 0, 16#02 ,"SER_UART_Write" )
   measure digital pin SER_GPIO3_RCLKOUT frequency interval 100.0e6 sample size count_legacy asynchronous into freq_meas_xtal2


----Switch to PLL  
   RegWrite(SER_ID,SR_REG3 , 1, 0, 16#03 ,"SER_UART_Write" )         -- PLL to RCLKOUT selected 

   RegWrite(SER_ID, SR_REF_VTG0, 1, 0, 16#71 ,"SER_UART_Write" )       -- PLL divider ratio, 75MHZ
   RegRead(SER_ID, SR_REF_VTG0 , 1,upperword, lowword , "SER_UART_Read")   
   measure digital pin SER_GPIO3_RCLKOUT frequency interval 100.0e6 sample size count_legacy asynchronous into freq_meas_75
   
   RegWrite(SER_ID, SR_REF_VTG0, 1, 0, 16#61 ,"SER_UART_Write" )       -- PLL divider ratio, 37MHZ)       
   measure digital pin SER_GPIO3_RCLKOUT frequency interval 100.0e6 sample size count_legacy asynchronous into freq_meas_37
   
   RegWrite(SER_ID, SR_REF_VTG0, 1, 0, 16#51 ,"SER_UART_Write" )       -- PLL divider ratio, 27MHZ     
   measure digital pin SER_GPIO3_RCLKOUT frequency interval 100.0e6 sample size count_legacy asynchronous into freq_meas_27
   
   RegWrite(SER_ID, SR_REF_VTG0, 1, 0, 16#41 ,"SER_UART_Write" )       -- PLL divider ratio, 19.2MHZ       
   measure digital pin SER_GPIO3_RCLKOUT frequency interval 100.0e6 sample size count_legacy asynchronous into freq_meas_19p2
      
-- -----Alternative
--    RegWrite(SER_ID,SR_REF_VTG0 , 1, 0, 16#79 ,"SER_UART_Write" )       -- PLL divider ratio, alternative     
--    measure digital pin SER_GPIO3_RCLKOUT frequency interval 100.0e6 sample size count_legacy asynchronous into freq_meas_alt1
--    
--    RegWrite(SER_ID,SR_REF_VTG0 , 1, 0, 16#69 ,"SER_UART_Write" )       -- PLL divider ratio, alternative       
--    measure digital pin SER_GPIO3_RCLKOUT frequency interval 100.0e6 sample size count_legacy asynchronous into freq_meas_alt2
--      
--    RegWrite(SER_ID,SR_REF_VTG0 , 1, 0, 16#59 ,"SER_UART_Write" )       -- PLL divider ratio, alternative       
--    measure digital pin SER_GPIO3_RCLKOUT frequency interval 100.0e6 sample size count_legacy asynchronous into freq_meas_alt3
-- 
--    RegWrite(SER_ID,SR_REF_VTG0 , 1, 0, 16#49 ,"SER_UART_Write" )       -- PLL divider ratio, alternative       
--    measure digital pin SER_GPIO3_RCLKOUT frequency interval 100.0e6 sample size count_legacy asynchronous into freq_meas_alt4
-- 
-- 
-- wait(1ms)   
   
   
   
   
     
-------------- Power Down ---------------------------
--      set digital pin SER_GPIO1_LFLTB_ERRB modes to driver pattern
      set digital pin SER_GPIO3_RCLKOUT modes to driver  pattern --load off
--      powerdown_device(POWERDOWN)  
       open cbit COAXB_P_RELAY + COAXB_M_RELAY  ---Connecto DC circuit  MT 11/2018
      powerdown_device(POWERDOWN)  
---Data log out 

--    test_value reg_val with rword

     test_value freq_meas_PU with freq_meas_it
     test_value freq_meas_xtal1 with freq_meas_xtal1_it
     test_value freq_meas_xtal2 with freq_meas_xtal2_it
          
     test_value freq_meas_75 with freq_meas_75_it
     test_value freq_meas_37 with freq_meas_37_it
     test_value freq_meas_27 with freq_meas_27_it
     test_value freq_meas_19p2 with freq_meas_19p2_it

--      test_value freq_meas_alt1 with freq_meas_alt1_it
--      test_value freq_meas_alt2 with freq_meas_alt2_it
--      test_value freq_meas_alt3 with freq_meas_alt3_it
--      test_value freq_meas_alt4 with freq_meas_alt4_it



end_body








procedure GmslOsnMargin2_HS89(Vdd, Vdd18, Vddio, SioChannel, FwTxRate, RevTxRate, LinkStatTest, EsVt24Test, EsVt40Test, TestCoeff, LockGainTest, LockOffsetTest, M6dbGainTest, M6dbGainCodeTest, M6dbOffsetTest, DefGainTest, DefOffsetTest, SampleTest, ConvTest, Ctle128_SampleTest, InitTest, VgaTest, VosEsTest1p8, AgcGainTest, AgcGainCodeTest, VosRETest, VosFETest, VosESTest, VosInCancelTest, VosQpQnTest, VosReMFeMEsTest, VosReMQpQnMEsTest, VsigInitTest, LeomvTest, LeomvFeTest, CombVosTest, HazyDsTest, HazyDsQpQnTest, GainLoopsTest_0p5, GainLoopsTest_1p8, AgcSearchTest, GainSearchTest,m6dB_GainTarget, ErrorSlicerGainTarget,LinkAgcDeltaTest_m6dB,LinkAgcDeltaTest_1p8)
in float            : Vdd, Vdd18, Vddio, FwTxRate, RevTxRate, ErrorSlicerGainTarget, m6dB_GainTarget
in string[8]        : SioChannel
in_out integer_test : TestCoeff, AgcGainCodeTest, M6dbGainCodeTest, GainLoopsTest_0p5, GainLoopsTest_1p8, LinkStatTest, LinkAgcDeltaTest_m6dB, LinkAgcDeltaTest_1p8
in_out float_test   : LockGainTest, LockOffsetTest, EsVt24Test, EsVt40Test, M6dbOffsetTest, M6dbGainTest
in_out float_test   : DefGainTest, DefOffsetTest, VosEsTest1p8, AgcGainTest, VosRETest, VosFETest, VosESTest, SampleTest, ConvTest, InitTest, VgaTest, Ctle128_SampleTest
in_out float_test   : VosInCancelTest, VosQpQnTest, VosReMFeMEsTest, VosReMQpQnMEsTest, LeomvTest,  LeomvFeTest, CombVosTest, HazyDsTest, HazyDsQpQnTest
in_out array of float_test : VsigInitTest, GainSearchTest
in_out array of integer_test : AgcSearchTest

local
  multisite integer    : GmslStatus, GmslStatusDlog, M6dbGainCodeRes, G1p8GainCodeRes, GainLoops_0p5, GainLoops_1p8, AgcSearchArray[20], LinkAgcDelta_m6dB, LinkAgcDelta_1p8
  multisite lword      : OsnLock, AgcLock, NewAgcInitCode, AgcOffset, AgcCode1, AgcCode2, StartingAgcCode
  multisite float      : VosQv, PrevVosQv, AgcCode, dx, dy, slope, Vos_0, Vos_63
  multisite float      : REavg, FEavg, ESavg
  multisite float      : LockGainRes, LockVosRes, DefGainRes, DefVosRes, G1p8GainRes, G1p8VosRes, M6dbGainRes, M6dbVosRes, CombVosRes, Gain1, Gain2, GainSlope, GainIntercept, Ctle128_Sample
  multisite float      : SampleRes, ConvergeRes, InitRes, VgaRes, VosHazyFeRes, VosHazyQpQnRes
  multisite float      : EsVt24Res, EsVt40Res, EsVthrIdealOffset, IdealEsVthr, VosInRes, VosQpQnRes, LeomvQpQnRes, LeomvFeRes, VosReMFeMEsRes, VosReMQpQnMEsRes, DacOsn
  multisite float      : VosReInitRes, VosFeInitRes, VosEsInitRes, VsigReInitRes, VsigFeInitRes, VsigEsInitRes, VsigInit, VsigArrRes[6], GainSearchArray[20]
  multisite float      : DCapSwitch, ECapSwitch, XCapSwitch, Ea, Ea0, Gc, CombinedRes
  string[8]            : SupplyCornerStr, QaFt, TestTemp, Device
  word list[MAX_SITES] : ActiveSites, LoopSites


  word                 : sIdx, Cs, Sites, RO, LpCnt, TstCnt, TxCode, GainCtr
  lword                : TmRo, OsnCodePre = 20, OsnCodePost = 40
  float                : TadjGainVal, Xpre, Xpost, TestFreq, TestPrd, GainTarget
  
  float                : GCa2 = 0.0, GCa1 = 1.0, GCa0 = 0.0, MeanAGC = 117.25, GCs = 1.5, VGAGCw = 0.0, SampleGCw = 0.0, ConvergeGCw = 0.0, InitGCw = 0.0
  boolean              : LossyPath = FALSE, DebugGainSearch=TRUE
  word                 : CoaxTpVal = 0

  lword                : AgcCodeSweep, LoopCounter = 0
  lword                : AgcInitCode_m6dB, count, AgcInitDelta_m6dB, AgcInitDelta_1p8
  multisite lword      : Read1, Read2, Read3, Read4, Xcap, Ecap, Dcap, TrainDone
  multisite float      : CtleMeas
  multisite boolean    : Reached_Agc0  
  
end_local

body
  ActiveSites = get_active_sites()
  Sites = word(len(ActiveSites))

  start_timer
  
  get_expr("OpVar_TestType", QaFt)
  get_expr("OpVar_TestTemp", TestTemp)
  if TestTemp == "HOT" then
    TxCode = 36
    TadjGainVal = 0.55
    MeanAGC = 114.7
    IdealEsVthr = 186mV
    --AgcInitCode_m6dB = 150 --167  -- Recentered for -2dB MRQ LeviB_20200302. 
    AgcInitDelta_m6dB = 14
    AgcInitDelta_1p8 = -9
  elseif TestTemp == "ROOM" then
    TxCode = 35
    TadjGainVal = 0.65
    MeanAGC = 117.25
    IdealEsVthr = 188mV
    --AgcInitCode_m6dB = 158 --172 -- Recentered for -2dB MRQ LeviB_20200302.
    AgcInitDelta_m6dB = 9
    AgcInitDelta_1p8 = -20
  else
    TxCode = 34
    TadjGainVal = 0.75
    MeanAGC = 119.9
    IdealEsVthr = 190mV
    AgcInitCode_m6dB = 164 --169 --178 -- Recentered for -2dB MRQ LeviB_20200311.
    AgcInitDelta_m6dB = 6
    AgcInitDelta_1p8 = -17
  endif

  if QaFt == "QA" then
    TxCode = TxCode + 2
  endif
  
  SioChannel = Ucase(SioChannel)
  if SioChannel == "AP" OR SioChannel == "AN" then
    RO = 0x0                                    -- Determine the RLMS register offset based on PHY-A or PHY-B
    TmRo = 0x0
    Device = "HS87_A"
  elseif  SioChannel == "BP" OR SioChannel == "BN" then
    RO = 0x100
    TmRo = 0x10
    Device = "HS87_B"
  else
    Print_banner_message("PARAMETER ERROR: GmslEyeTest : SioChannel ", "Allowable Parameters Are 'AP', 'AN', 'BP', or 'BN'", "")
    halt
  endif

  if Vdd18 < 1.75 then
    SupplyCornerStr = "MIN"
  elseif Vdd18 > 1.85 then
    SupplyCornerStr = "MAX"
  else
    SupplyCornerStr = "NOM"
  endif


  disconnect digital pin DUT_XRES+DUT_CMU_CAP from dcl         -- Ensure that the XRES and CMU_CAP do not have any tester resources connected as it may intefere with the testing

  LoopSites = get_active_sites()
  Sites = word(len(LoopSites))

  while Sites > 0 and LpCnt < 3 do                                           -- Loop was added due to some connectivity issues requiring restart on a small percentage of devices
    --GmslStatus =   DutPowerupAndLink(Vdd, Vdda, Vdd18, Vddio, Vdd25, true, FALSE, SEL_COAX, SEL_I2C, SioChannel, "F", TxCode, 0, FwTxRate, RevTxRate, 0.0, false, 5ms, false, false, false, 0, LinkErrorIValue)  
    CoaxTpVal = 1
    GmslStatus = DutPowerupAndLockDevices_Custom1(Vdd, VddA, Vdd18, Vddio, Vddio25, Vdd33, SioChannel, LossyPath, Word(CoaxTpVal), FwTxRate, RevTxRate, 1, 0.0, true)    
    wait(125 ms)    -- 20200318 LeviB_20200311: 125ms is conservative. Need at least (128ms+10ms) delay for 187M mode to converge, lock routine has 15ms delay plus I2C read/write times.
    RegWrite(DUT_ID, SR_RLMSA4_A+RO, 1, 0x0, 0x0, "dut_i2c_write")          -- disable periodic adapt

    for sIdx = 1 to Sites do
      Cs = LoopSites[sIdx]
      if GmslStatus[Cs] == 15 then
        GmslStatusDlog[Cs] = GmslStatus[Cs]
        deactivate site Cs
      endif
    endfor
    LoopSites = get_active_sites()
    Sites = word(len(LoopSites))
    if Sites > 0 then
      LpCnt = LpCnt + 1
    endif
  endwhile  

  activate sites ActiveSites
  Sites = word(len(ActiveSites))



--  RegRead(DUT_ID, SR_RLMS10_A+RO, 1, RdWordUpper, AgcLock, "dut_i2c_read")             -- Read and store the AGC value from the link operation
--RegWrite(DUT_ID, SR_RLMS4_A+RO, 1, 0x0, 0x38, "dut_i2c_write")                       -- disable eom   HS84 default is 0x39
  RegWrite(DUT_ID, SR_RLMS4_A+RO, 1, 0x0, 0x4A, "dut_i2c_write")                       -- disable eom   HS87 default is 0x4B HS95 default is 0x4B, so use 0x4A to disable eom
  RegWrite(DUT_ID, SR_RLMS3_A+RO, 1, 0x0, 0x0A, "dut_i2c_write")                       -- disable eom  -- this is the HS87 register's default value, & does not appear to include any EOM fields

  --DlogEqualizerCoeff(SioChannel, GmslStatus, Sites, ActiveSites, 10000, 1, TxCode, SupplyCornerStr, TestCoeff, "GMSL_OFFSET_LINK", true, true, "360_MV")

  test_value GmslStatusDlog with LinkStatTest
  DlogCoefficents(DUT_ID, Device, "DUT", "I2C", TestCoeff,  Vdd18,  "", QaFt)

  RegRead(DUT_ID, SR_RLMS10_A+RO, 1, RdWordUpper, AgcLock, "dut_i2c_read")             -- Read and store the AGC value from the link operation
  RegRead(DUT_ID, SR_RLMS2E_A+RO, 1, RdWordUpper, OsnLock, "dut_i2c_read")             -- Read and store the OSN value from the link operation

  --*******************************************************************************************************************************************
  --* Set HS84 test program timing to run at 800KHz and program the dut / dnut to expect 1MHz data rates on the I2C paths                     *
  --* Note: The HS84 has too many issues when linking up at frequencies beyond 400KHz so the link lock is performed at 400KHz and then        *
  --*       the tester timing is modified to execute patterns at 800KHz.  Frequencies beyond 800KHz work but are not as repeatable and        *
  --*       cause issues with the data collection. This is more than likely limited to the HS84 test program and should not be required       *
  --*       for other devices.                                                                                                                *
  --*******************************************************************************************************************************************
  TestFreq = 800KHz                                                                  
  TestPrd = 1.0/(TestFreq*4.0)
  RegWrite(DUT_ID,   SR_INTR1, 1, 0, 0,    "dut_i2c_write")
  RegWrite(DNUT1_ID, DR_INTR1, 1, 0, 0,    "dnut_i2c_write")
  RegWrite(DUT_ID,   SR_I2C_0, 1, 0, 0x06, "dut_i2c_write")
  RegWrite(DUT_ID,   SR_I2C_1, 1, 0, 0x76, "dut_i2c_write")
  RegWrite(DNUT1_ID, DR_I2C_0, 1, 0, 0x07, "dnut_i2c_write")
  RegWrite(DNUT1_ID, DR_I2C_1, 1, 0, 0x76, "dnut_i2c_write")
  set digital clock msdi period t0 to double(TestPrd) c0 to double(TestPrd) for "REGSEND_TS"
  set digital pin DUT_SCL_TX+DNUT_SCL msdi drive on 0.0s data 0.0s for "REGSEND_TS"
  set digital pin DUT_SDA_RX+DNUT_SDA msdi drive on 0.0s data 0.0s for "REGSEND_TS"
  set digital pin DUT_SDA_RX+DNUT_SDA msdi compare off 0.0s data TestPrd*0.5 for "REGSEND_TS"

  --**************************************************************************************************
  --* Setup DC configuration                                                                         *
  --**************************************************************************************************
--  RegWrite(DNUT1_ID, DR_CTRL0, 1, 0, 0x40, "dnut_i2c_write")                                       -- Place HS84 GMSL link into reset mode  --LeviB_20191001: This link reset causes issues with the gain converging to -6dB. Originally added to HS84 to make EsVt24Res and EsVt40Res more repeatable.
--  RegWrite(DUT_ID,   SR_CTRL0, 1, 0, 0x40, "dut_i2c_write")                                        -- Place HS87 GMSL link into reset mode 

  SetRelays("SioAllTerm")                                                                        -- Terminate all SIO pins  Note: Location important for repeatability do not move later in code BD 2019/08/28
  DCTM_Init(DUT_GPIO16_ABUS2_DCTM, DUT_GPIO17_ABUS3_DCTM, 11V, 17, 100KHz)                       -- initialize the DCTM

  RegRead(DUT_ID,   SR_RLMS32_A+RO,  1, RdWordUpper, RdWordLower, "dut_i2c_read")                -- Disable OSN adapt
  mRegWrite(DUT_ID, SR_RLMS32_A+RO,  1, mslw(0x0), RdWordLower & 0xBF, "dut_i2c_write")           
  RegWrite(DUT_ID,  SR_RLMS27_A+RO,  3, 0x0, 0x0, "dut_i2c_write")                               -- Set DFE5-3 init value = 0
  RegWrite(DUT_ID,  SR_RLMS12A_A+RO, 2, 0x0, 0x0, "dut_i2c_write")                               -- Set DFE2-1 init value = 0
--  RegWrite(DUT_ID,  SR_RLMS58_A+RO,  2, 0x0, 0x0, "dut_i2c_write")                               -- Set Vth to zero volts
  RegWrite(DUT_ID, SR_RLMSA8_A+RO, 2, 0x0, 0xB8E0, "dut_i2c_write")                              -- enable firmware control mode
  RegWrite(DUT_ID, SR_RLMSC1_A+RO, 1, 0x0, 0x20, "dut_i2c_write")                                -- disable replica
  RegWrite(DUT_ID, SR_RLMS49_A+RO, 1, 0x0, 0x75, "dut_i2c_write")                                -- power up error channel
  RegWrite(DUT_ID, SR_RLMS17_A+RO, 1, 0x0, 0x03, "dut_i2c_write")                                -- Disable DFE adapt
  RegWrite(DUT_ID, SR_RLMS58_A+RO, 2, 0x0, 0x18, "dut_i2c_write")                                -- Set Vth to d24
  RegWrite(DUT_ID, SR_RLMS3_A+RO, 1, 0x0, 0x8A, "dut_i2c_write")                                 -- Enable global adapt
  wait(20ms)                                                                                     -- Wait for adapt (calibration) to complete
  RegWrite(DUT_ID, SR_RLMS3_A+RO, 1, 0x0, 0x0A, "dut_i2c_write")                                 -- disable global adapt
  
  SetTestMode(11, False, "dut_i2c_write")                                                        -- Set TESMODE to ABUS
  RegWrite(DUT_ID, SR_TEST0, 1, 0x0, 0x0, "dut_i2c_write")                                       -- Set the ABUS to tristatate
  wait(5ms)                                                                                      

  open  cbit K65_K66_HDMI_ABUS__VI16                                                             -- Disconnect VI16 from Abus pins
  close cbit K6_K51_GPIO14_GPIO15_GPIO16_GPIO17__DP_VI                                           -- Connect the ABUS GPIO to the DCTM resources
  close cbit K73_ABUS2_ABUS3__VI_DCTM                                                            -- Connect the ABUS 3/2 signals the DCTM resourses
  open cbit K75_ABUS0_ABUS1__VI_DCTM                                                             -- Disconnect the ABUS 1/0 signals from the DCTM resources
  RegWrite(DUT_ID, SR_RLMS40_A+RO, 1, 0x0, 0x1, "dut_i2c_write")                                 -- Start data capture (allow ES, RE, FE capture registers to accumulate)

  --**************************************************************************************************
  --* Set the Vth eye height and measure the error slicer voltage                                    *
  --**************************************************************************************************
  RegWrite(DUT_ID, SR_TEST0, 1, 0x0, 0x81+TmRo, "dut_i2c_write")                                 -- Set the ABUS to gmsl2_phy(AorB)_abus_block, page 1 (Error Slicer)
  RegWrite(DUT_ID, SR_RLMS58_A+RO, 2, 0x0, 0x18, "dut_i2c_write")                                -- Set Vth to d24
  wait(1ms)
  EsVt24Res = DCTM_MeasDiff(DUT_GPIO16_ABUS2_DCTM, DUT_GPIO17_ABUS3_DCTM, 11V, 17, 100KHz)

  RegWrite(DUT_ID, SR_RLMS58_A+RO, 2, 0x0, 0x28, "dut_i2c_write")                                -- Set Vth to d40
  wait(1ms)
  EsVt40Res = DCTM_MeasDiff(DUT_GPIO16_ABUS2_DCTM, DUT_GPIO17_ABUS3_DCTM, 11V, 17, 100KHz)
  RegWrite(DUT_ID, SR_RLMS58_A+RO, 2, 0x0, 0x0, "dut_i2c_write")                                 -- Set Vth back to zero volts

  --**************************************************************************************************
  --* Calculate Gain and Offset with AGC at the link / lock value                                    *
  --**************************************************************************************************
  Xpre = float(OsnCodePre)*1.15mV                                                                -- Normalize the X2 value to mV (1.15mV is ideal design value per OSN code) used in all Gain / Offset calculations below
  Xpost = float(OsnCodePost) * 1.15mV                                                            -- Normalize the X2 value to mV (1.15mV is ideal design value per OSN code) used in all Gain / Offset calculations below
  open cbit K73_ABUS2_ABUS3__VI_DCTM                                                             -- disconnect the ABUS 3/2 from the DCTM resourses
  close cbit K75_ABUS0_ABUS1__VI_DCTM                                                            -- Connect the ABUS 1/0 signals to the DCTM resources
  DCTM_Init(DUT_GPIO14_ABUS0_DCTM, DUT_GPIO15_ABUS1_DCTM, 11V, 17, 100KHz)                                   -- initialize the DCTM

  mRegWrite(DUT_ID, SR_RLMS1F_A+RO, 1, mslw(0x0), AgcLock, "dut_i2c_write")                      -- force the AGC init value to obtain the new calculated target gain
  mRegWrite(DUT_ID, SR_RLMS33_A+RO, 1, mslw(0x0), OsnLock, "dut_i2c_write")                      -- force the OSN init value to obtain the new calculated target gain
  RegWrite(DUT_ID,  SR_RLMS40_A+RO, 1, 0x0, 0x1, "dut_i2c_write")                                 -- Start data capture
  RegWrite(DUT_ID,  SR_TEST0, 1, 0x0, 0x0, "dut_i2c_write")                                       -- Set the ABUS to tristatate
  wait(1ms)                                                                                      
  RegWrite(DUT_ID,  SR_TEST0, 1, 0x0, 0x82+TmRo, "dut_i2c_write")                                 -- Set the ABUS to gmsl2_phy(AorB)_abus_block, page 2

  GmslOffsetMeasureCtle(mslw(OsnCodePre), "NONE", RO, PrevVosQv)                                 -- Test and store the VosQv (Y1) for the X1,Y1 point X1 = 20 * 1.15mV
  GmslOffsetMeasureCtle(mslw(OsnCodePost), "NONE", RO, VosQv)                                    -- Test and store the VosQv (Y2) for the X2,Y2 point X2 = 40 * 1.15mV  
  
  for sIdx = 1 to Sites do
    Cs = ActiveSites[sIdx]
    LockGainRes[Cs] = abs(VosQv[Cs] - PrevVosQv[Cs]) / (Xpost-Xpre)                              -- Calculate the gain using values all normalized to mV

    dy[Cs] = VosQv[Cs] - PrevVosQv[Cs]
    slope[Cs] = dy[Cs] / (Xpost-Xpre)                                                            -- Calculate the slope (slope is negative, Gain is calculated as an absolute value)
    LockVosRes[Cs] = Xpre - (PrevVosQv[Cs] / slope[Cs])                                          -- Find the intercept location
    LockVosRes[Cs] = -((31.0*1.15mV) - LockVosRes[Cs])                                           -- Store offset from expected default value (31.0 * 1.15mV)  --LeviB_20200225: Invert sign per Lionel
  endfor




    --  O----------------------------------------------O
    --  |  Sweep Gain codes to understand gain slopes  | 
    --  O----------------------------------------------O

    if false then
        -- For DEBUG ONLY
        LoopSites = get_active_sites()
        Sites = word(len(LoopSites))

        -- Print header line
        println(stdout, "")                                                                         -- Blank Line
        println(stdout, "Link", SioChannel)
        println(stdout, "Site,AgcCode,GainRes,VosQv,PrevVosQv") 

        for AgcCodeSweep = 0 to 255 do
            RegWrite(DUT_ID, SR_RLMS1F_A+RO, 1, 0, AgcCodeSweep, "dut_i2c_write")                   -- force the AGC init value 
            GmslOffsetMeasureCtle(mslw(OsnCodePre), "NONE", RO, PrevVosQv)                          -- Test and store the VosQv (Y1) for the X1,Y1 point X1 = 20 * 1.15mV
            GmslOffsetMeasureCtle(mslw(OsnCodePost), "NONE", RO, VosQv)                             -- Test and store the VosQv (Y2) for the X2,Y2 point X2 = 40 * 1.15mV

            for sIdx = 1 to Sites do
                Cs = LoopSites[sIdx]
                M6dbGainRes[Cs] = abs(VosQv[Cs] - PrevVosQv[Cs]) / (Xpost-Xpre)                                    -- Calculate the gain (Xpost-Xpre are the OSN codes normalized to mV)
                println(stdout, Cs, ",", AgcCodeSweep, ",", M6dbGainRes[Cs]!f:6:6, ",", VosQv[Cs]!f:6:6, ",", PrevVosQv[Cs]!f:6:6)
            endfor    
        endfor

        println(stdout, "")                                                                         -- Blank Line

    endif


    --***********************************************************************************
    --* Calculate and determine code required to get -6db (0.5) gain value.             *
    --* LeviB_20200225: Gain Target changed to -2dB for 1.5G and 0dB for 187M           *
    --***********************************************************************************
    -- LeviB_20200317: This code will do 1 round of interpolation to try to find the gain target, after that it will increase/decrease by 1 AGC code
    if DebugGainSearch then
        println(stdout, "Gain, GainCtr, Site, AgcCode, Gain")
    endif

    GainTarget = m6dB_GainTarget

    LoopSites = get_active_sites()
    Sites = word(len(LoopSites))

    GainLoops_0p5=0
    GainCtr = 0
    --NewAgcInitCode = 172 - 4 
    --NewAgcInitCode = AgcInitCode_m6dB

    -- Initialize starting AGC code based on the converged AGC code at initial link
    for sIdx = 1 to Sites do
        Cs = LoopSites[sIdx]
        AgcCode1[Cs] = AgcLock[Cs]                                                               -- Save for interpolation calculation
        Gain1[Cs] = LockGainRes[Cs]
        NewAgcInitCode[Cs] = AgcLock[Cs] + AgcInitDelta_m6dB
    end_for

    while GainCtr < 20 and Sites > 0 do
        mRegWrite(DUT_ID, SR_RLMS1F_A+RO, 1, mslw(0x0), (NewAgcInitCode), "dut_i2c_write")                   -- force the AGC init value and re-test on sites that had an initial gain < 0.47 or > 0.53
        GmslOffsetMeasureCtle(mslw(OsnCodePre), "NONE", RO, PrevVosQv)                                       -- Test and store the VosQv (Y1) for the X1,Y1 point X1 = 20 * 1.15mV
        GmslOffsetMeasureCtle(mslw(OsnCodePost), "NONE", RO, VosQv)                                          -- Test and store the VosQv (Y2) for the X2,Y2 point X2 = 40 * 1.15mV
        for sIdx = 1 to Sites do
            Cs = LoopSites[sIdx]
            GainLoops_0p5[Cs] = GainLoops_0p5[Cs] + 1       
            M6dbGainRes[Cs] = abs(VosQv[Cs] - PrevVosQv[Cs]) / (Xpost-Xpre)                                    -- Calculate the gain and normalize input codes to mV
            M6dbGainCodeRes[Cs] = integer(NewAgcInitCode[Cs])
            LinkAgcDelta_m6dB[Cs] = integer(NewAgcInitCode[Cs] - AgcLock[Cs])
            if DebugGainSearch then
                println(stdout, GainTarget, ",   ", GainCtr, ",    ", Cs,  ",  ", NewAgcInitCode[Cs], ",   ", M6dbGainRes[Cs]!f:3:3)
                AgcSearchArray[Cs, GainCtr+1] = integer(NewAgcInitCode[Cs])
                GainSearchArray[Cs, GainCtr+1] = M6dbGainRes[Cs]
            endif

            if M6dbGainRes[Cs] > (GainTarget - 0.025) and M6dbGainRes[Cs] < (GainTarget + 0.025) then                                      -- The gain is in the correct range.  Store the gain and VOS (offset from expected)
                dy[Cs] = VosQv[Cs] - PrevVosQv[Cs]    
                slope[Cs] = dy[Cs] / (Xpost-Xpre)
                M6dbVosRes[Cs] = Xpre - (PrevVosQv[Cs] / slope[Cs])
                M6dbVosRes[Cs] =  -((31.0*1.15mV) - M6dbVosRes[Cs])                                             --LeviB_20200225: Invert sign per Lionel                                           
                deactivate site Cs
            elseif GainCtr = 0 then
                AgcCode2[Cs]       = NewAgcInitCode[Cs]
                Gain2[Cs]          = M6dbGainRes[Cs]
                dy[Cs]             = abs(Gain2[Cs] - Gain1[Cs])
                
                if dy[Cs] > 0.01 then                                                                               -- Interpolation will fail if the delta gain is too small
                    GainSlope[Cs]      = (Gain2[Cs] - Gain1[Cs]) / (float(AgcCode2[Cs]) - float(AgcCode1[Cs]))
                    GainIntercept[Cs]  = Gain2[Cs] - (GainSlope[Cs] * float(AgcCode2[Cs]))
                    NewAgcInitCode[Cs] = lword((GainTarget - GainIntercept[Cs]) / (GainSlope[Cs]))
                else
                    if M6dbGainRes[Cs] < GainTarget then
                        NewAgcInitCode[Cs] = NewAgcInitCode[Cs] - 1
                    else
                        NewAgcInitCode[Cs] = NewAgcInitCode[Cs] + 1
                    endif
                endif

                AgcCode1[Cs] = AgcCode2[Cs]                                                                        -- Save the latest gain/code for the next calculation
                Gain1[Cs]    = Gain2[Cs]        
            else
                if M6dbGainRes[Cs] < GainTarget then
                    NewAgcInitCode[Cs] = NewAgcInitCode[Cs] - 1
                else
                    NewAgcInitCode[Cs] = NewAgcInitCode[Cs] + 1
                endif
            endif    

            -- Make sure new AGC value is within range. LeviB_20200224
            if NewAgcInitCode[Cs] > 255 then
                NewAgcInitCode[Cs] = 255
            elseif NewAgcInitCode[Cs] < 0 then
                NewAgcInitCode[Cs] = 0
            endif    
        

        endfor
    
        LoopSites = get_active_sites()
        Sites = word(len(LoopSites))

        GainCtr = GainCtr + 1
    endwhile

  activate sites ActiveSites
  Sites = word(len(ActiveSites))


  if GainCtr = 20 then
    wait(0.0)   --debug trap
  endif



  --*******************************************************************************************************************************************************************************************
  --* Calculate and Set AGC to achieve a Gain of ~= 2.2 (for hot/room), or 2.5 (for cold), Calculate gain and zero crossing offset for 2.2/2.5 and default 0x80 AGC codes *
  --*******************************************************************************************************************************************************************************************

  GainTarget = ErrorSlicerGainTarget

  if DebugGainSearch then
      println(stdout, "Gain, GainCtr, Site, AgcCode, Gain")
  endif

  LoopSites = get_active_sites()
  Sites = word(len(LoopSites))
  GainLoops_1p8 = 0

  GainCtr = 0
  NewAgcInitCode = 0x80                                                                                  -- Set the initial AGC value to default = 0x80
  while GainCtr < 20 and Sites > 0 do
    mRegWrite(DUT_ID, SR_RLMS1F_A+RO, 1, mslw(0x0), (NewAgcInitCode), "dut_i2c_write")                   -- force the AGC init value and re-test on sites that had an initial gain < 0.47 or > 0.53
    GmslOffsetMeasureCtle(mslw(OsnCodePre), "NONE", RO, PrevVosQv)                                       -- Test and store the VosQv (Y1) for the X1,Y1 point X1 = 20 * 1.15mV
    GmslOffsetMeasureCtle(mslw(OsnCodePost), "NONE", RO, VosQv)                                          -- Test and store the VosQv (Y2) for the X2,Y2 point X2 = 40 * 1.15mV

    for sIdx = 1 to Sites do
      Cs = LoopSites[sIdx]
      GainLoops_1p8[Cs] = GainLoops_1p8[Cs] + 1
      G1p8GainRes[Cs] = abs(VosQv[Cs] - PrevVosQv[Cs]) / (Xpost-Xpre)                                    -- Calculate the gain and normalize input codes to mV
      G1p8GainCodeRes[Cs] = integer(NewAgcInitCode[Cs])                                                  -- Store the AGC code for datalogging
      AgcCode[Cs] = float(NewAgcInitCode[Cs])                                                            -- Store as a float for use as a parameter for the check function
      LinkAgcDelta_1p8[Cs] = integer( NewAgcInitCode[Cs] - AgcLock[Cs] )
      if DebugGainSearch then
          println(stdout, GainTarget, ",   ", GainCtr, ",    ", Cs,  ",  ", NewAgcInitCode[Cs], ",   ", G1p8GainRes[Cs]!f:3:3)
      endif

      if GainCtr == 0 then
        dy[Cs] = VosQv[Cs] - PrevVosQv[Cs]    
        slope[Cs] = dy[Cs] / (Xpost-Xpre)
        DefGainRes[Cs] = G1p8GainRes[Cs]                                                                   -- Store gain at default AGC 0x80 for datalogging
        DefVosRes[Cs] = Xpre - (PrevVosQv[Cs] / slope[Cs])                                                 -- Store the Gain Offset for default AGC code 0x80
        DefVosRes[Cs] =  -((31.0*1.15mV) - DefVosRes[Cs])                                                  --LeviB_20200225: Invert sign per Lionel
      endif

      if G1p8GainRes[Cs] >= (GainTarget - 0.15) and G1p8GainRes[Cs] <= (GainTarget + 0.15) then            -- The gain is in the correct range.  Store the gain and VOS (offset from expected)
        dy[Cs] = VosQv[Cs] - PrevVosQv[Cs]    
        slope[Cs] = dy[Cs] / (Xpost-Xpre)
        G1p8VosRes[Cs] = Xpre - (PrevVosQv[Cs] / slope[Cs])
        G1p8VosRes[Cs] =  -((31.0*1.15mV) - G1p8VosRes[Cs])                                               --LeviB_20200225: Invert sign per Lionel
        deactivate site Cs
      elseif GainCtr = 0 then
        AgcCode1[Cs] = AgcLock[Cs]                                                                         -- Save for interpolation calculation
        Gain1[Cs] = LockGainRes[Cs]  
        NewAgcInitCode[Cs] = AgcLock[Cs] + AgcInitDelta_1p8
      elseif GainCtr = 1 then
        AgcCode2[Cs]  = NewAgcInitCode[Cs]
        Gain2[Cs] = G1p8GainRes[Cs]
        GainSlope[Cs] = (Gain2[Cs] - Gain1[Cs]) / (float(AgcCode2[Cs]) - float(AgcCode1[Cs]))                   -- Calcluate the next AGC value using interpolation
        GainIntercept[Cs] = Gain2[Cs] - (GainSlope[Cs] * float(AgcCode2[Cs]))
        NewAgcInitCode[Cs] = lword((GainTarget - GainIntercept[Cs]) / (GainSlope[Cs]))

        AgcCode1[Cs] = AgcCode2[Cs]                                                          -- Save the latest gain/code for the next calculation
        Gain1[Cs] = Gain2[Cs]        
      else
        AgcCode2[Cs]  = NewAgcInitCode[Cs]
        Gain2[Cs] = G1p8GainRes[Cs]
        GainSlope[Cs] = (Gain2[Cs] - Gain1[Cs]) / (float(AgcCode2[Cs]) - float(AgcCode1[Cs]))                       -- Calcluate the next AGC value using interpolation
        GainIntercept[Cs] = Gain2[Cs] - (GainSlope[Cs] * float(AgcCode2[Cs]))

        if Gain2[Cs] < GainTarget AND GainSlope[Cs] < 0.0  then
            NewAgcInitCode[Cs] = NewAgcInitCode[Cs] - 1
        elseif Gain2[Cs] > GainTarget AND GainSlope[Cs] > 0.0  then
            NewAgcInitCode[Cs] = NewAgcInitCode[Cs] - 1
        elseif Gain2[Cs] > GainTarget AND GainSlope[Cs] < 0.0  then
            NewAgcInitCode[Cs] = NewAgcInitCode[Cs] + 1
        else
            NewAgcInitCode[Cs] = NewAgcInitCode[Cs] + 1
        endif
        
        AgcCode1[Cs] = AgcCode2[Cs]                                                                        -- Save the latest gain/code for the next calculation
        Gain1[Cs] = Gain2[Cs]        


      endif

      -- Make sure new AGC value is within range. LeviB_20200224
      if NewAgcInitCode[Cs] > 255 then
        NewAgcInitCode[Cs] = 255
      elseif NewAgcInitCode[Cs] < 0 then
        NewAgcInitCode[Cs] = 0
      endif

    endfor
    
    LoopSites = get_active_sites()
    Sites = word(len(LoopSites))

    GainCtr = GainCtr + 1
  endwhile

  activate sites ActiveSites
  Sites = word(len(ActiveSites))

  --**************************************************************************************************
  --* Determine flipflop transition points (OSN Code) and measure CTLE voltage at transition codes   *
  --**************************************************************************************************
    
    -- Sweep the OSN code for characterization. LeviB_20191213
    if false then
        for sIdx = 1 to Sites do
            Cs = ActiveSites[sIdx]
            -- Print the header
            println(stdout,"")
            println(stdout,"")
            println(stdout, "Phy_", SioChannel, ",Site", Cs)
            println(stdout,"")
            println(stdout, "TrainDone,Reg_RLMS40[Hex],RLMS41[Hex],RLMS42[Hex],RLMS43[Hex],,OSN_code,Xcap,Ecap,Dcap,Ctle[V]")

            -- Sweep OSN code
            for count = 0 to 63 do
                RegWrite(DUT_ID, SR_RLMS33_A+RO, 1, 0x0, lword(count), "dut_i2c_write") 
                RegWrite(DUT_ID, SR_RLMS57_A+RO, 1, 0x0,          0x1, "dut_i2c_write") 
                RegWrite(DUT_ID, SR_RLMS40_A+RO, 1, 0x0,          0x1, "dut_i2c_write") 
                wait(1ms)
                RegRead(DUT_ID,  SR_RLMS40_A+RO,  1, RdWordUpper, Read1, "dut_i2c_read")
                RegRead(DUT_ID,  SR_RLMS41_A+RO,  1, RdWordUpper, Read2, "dut_i2c_read")
                RegRead(DUT_ID,  SR_RLMS42_A+RO,  1, RdWordUpper, Read3, "dut_i2c_read")
                RegRead(DUT_ID,  SR_RLMS43_A+RO,  1, RdWordUpper, Read4, "dut_i2c_read")

                CtleMeas = DCTM_MeasDiff(DUT_GPIO14_ABUS0_DCTM, DUT_GPIO15_ABUS1_DCTM, 11V, 17, 100KHz) * 2.0

                Xcap[Cs] =  Read1[Cs]
                Ecap[Cs] =  (Read2[Cs] >> 2) & 0x3
                Dcap[Cs] =  (Read4[Cs] << 12) | (Read3[Cs] << 4) | (Read2[Cs] >> 4)
                TrainDone[Cs] = Read2[Cs] & 0x1

                println(stdout, TrainDone[Cs], ",", Read1[Cs]!H:2, ",", Read2[Cs]!H:2, ",", Read3[Cs]!H:2, ",", Read4[Cs]!H:2, ",,", count, ",", Xcap[Cs], ",", Ecap[Cs], ",", Dcap[Cs], ",", CtleMeas[Cs]!f:3:3)
                wait(1us)

            endfor        
        endfor            
    endif



  Capture_Offset_Codes(SioChannel, DCapSwitch, ECapSwitch, XCapSwitch, 10)                                   -- Capture the OSN codes that contain the EC, FE and RE flip flop transitions (execute 10 times and average the OSN code) 


  -->>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
  -- If no transition found,increase gain until a transition is found
  if false then

  OsnCodePre = 25
  OsnCodePost = 35
  Xpre = float(OsnCodePre)*1.15mV                                                                -- Normalize the X2 value to mV (1.15mV is ideal design value per OSN code) used in all Gain / Offset calculations below
  Xpost = float(OsnCodePost) * 1.15mV                                                            -- Normalize the X2 value to mV (1.15mV is ideal design value per OSN code) used in all Gain / Offset calculations below


    LoopCounter = 0
    --NewAgcInitCode =255
    
    LoopSites = get_active_sites()
    Sites = word(len(LoopSites))

    for sIdx = 1 to Sites do
        Cs = LoopSites[sIdx]
        StartingAgcCode[Cs] = NewAgcInitCode[Cs]
        Reached_Agc0[Cs] = false
    end_for


    println(stdout, "LoopCounter,Site,DCap,ECap,XCap,NewAgcInitCode,Gain,VosQv_25,VosQv_35,VosQv_0,VosQv_63")
    while Sites > 0 do
        
        LoopCounter = LoopCounter + 1

        --Deactivate any site where transition is already found
        for sIdx = 1 to Sites do
            Cs = LoopSites[sIdx]
            println(stdout, LoopCounter, ",", Cs, ",", DCapSwitch[Cs], ",", ECapSwitch[Cs], ",",XCapSwitch[Cs], ",", NewAgcInitCode[Cs], ",", G1p8GainRes[Cs], PrevVosQv[Cs], VosQv[Cs], Vos_0[Cs], Vos_63[Cs])
            if NewAgcInitCode[Cs]=0 and not Reached_Agc0[Cs] then
                --Transition was not found by decreasing AGC code, try increasing it
                Reached_Agc0[Cs] = true
                NewAgcInitCode[Cs] = StartingAgcCode[Cs] + 1
            elseif  NewAgcInitCode[Cs] = 255 then         --(DCapSwitch[Cs] > 0.0 and ECapSwitch[Cs] > 0.0 and XCapSwitch[Cs] > 0.0) Or NewAgcInitCode[Cs]=0 Or NewAgcInitCode[Cs] = 255 then
                deactivate site Cs
            elseif NewAgcInitCode[Cs] > 0 and not Reached_Agc0[Cs] then
                NewAgcInitCode[Cs] = NewAgcInitCode[Cs] - 1
            else
                NewAgcInitCode[Cs] = NewAgcInitCode[Cs] + 1
            endif
        end_for

        LoopSites = get_active_sites()
        Sites = word(len(LoopSites))

        if Sites > 0 then

            mRegWrite(DUT_ID, SR_RLMS1F_A+RO, 1, mslw(0x0), (NewAgcInitCode), "dut_i2c_write")                   -- force the AGC init value and re-test on sites that had an initial gain < 0.47 or > 0.53
            GmslOffsetMeasureCtle(mslw(OsnCodePre), "NONE", RO, PrevVosQv)                                       -- Test and store the VosQv (Y1) for the X1,Y1 point X1 = 20 * 1.15mV
            GmslOffsetMeasureCtle(mslw(OsnCodePost), "NONE", RO, VosQv)                                          -- Test and store the VosQv (Y2) for the X2,Y2 point X2 = 40 * 1.15mV

            GmslOffsetMeasureCtle(mslw(0), "NONE", RO, Vos_0)                                       -- Test and store the VosQv (Y1) for the X1,Y1 point X1 = 20 * 1.15mV
            GmslOffsetMeasureCtle(mslw(63), "NONE", RO, Vos_63)                                          -- Test and store the VosQv (Y2) for the X2,Y2 point X2 = 40 * 1.15mV

            for sIdx = 1 to Sites do
                Cs = LoopSites[sIdx]
                GainLoops_1p8[Cs] = GainLoops_1p8[Cs] + 1
                G1p8GainRes[Cs] = abs(VosQv[Cs] - PrevVosQv[Cs]) / (Xpost-Xpre)                                    -- Calculate the gain and normalize input codes to mV
                G1p8GainCodeRes[Cs] = integer(NewAgcInitCode[Cs])                                                  -- Store the AGC code for datalogging
                AgcCode[Cs] = float(NewAgcInitCode[Cs])                                                            -- Store as a float for use as a parameter for the check function

                dy[Cs] = VosQv[Cs] - PrevVosQv[Cs]    
                slope[Cs] = dy[Cs] / (Xpost-Xpre)
                G1p8VosRes[Cs] = Xpre - (PrevVosQv[Cs] / slope[Cs])
                G1p8VosRes[Cs] =  ((31.0*1.15mV) - G1p8VosRes[Cs])                                               
            endfor

            Capture_Offset_Codes(SioChannel, DCapSwitch, ECapSwitch, XCapSwitch, 10)                                   -- Capture the OSN codes that contain the EC, FE and RE flip flop transitions (execute 10 times and average the OSN code) 
        endif

    end_while

    --Re-enable all active sites
    activate sites ActiveSites
    Sites = word(len(ActiveSites))

  endif
  -- If no transition found,increase gain until a transistion is found
  --<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<


  REavg = MeasureCtle(SioChannel, DCapSwitch)                                                                -- Measure the CTLE voltage for each of the FF transition points
  FEavg = MeasureCtle(SioChannel, XCapSwitch)
  ESavg = MeasureCtle(SioChannel, ECapSwitch)

  --**************************************************************************************************
  --* Return the I2C test program timing to program default (400KHz timing used)  (HS84)             *
  --**************************************************************************************************
  RegWrite(DUT_ID,   SR_I2C_0, 1, 0, 0x16, "dut_i2c_write")                                                     -- Return the dut / dnut I2C timing back to FAST 400Khz
  RegWrite(DUT_ID,   SR_I2C_1, 1, 0, 0x56, "dut_i2c_write")
  RegWrite(DNUT1_ID, DR_I2C_0, 1, 0, 0x16, "dnut_i2c_write")
  RegWrite(DNUT1_ID, DR_I2C_1, 1, 0, 0x56, "dnut_i2c_write")
  TestFreq = 250KHz                                                                                           -- Reset the tester timing of the current timing module to 400KHz 
  TestPrd = 1.0/(TestFreq*4.0)
  set digital clock msdi period t0 to double(TestPrd) c0 to double(TestPrd) for "REGSEND_TS"
  set digital pin DUT_SCL_TX+DNUT_SCL msdi drive on 0.0s data 0.0s for "REGSEND_TS"
  set digital pin DUT_SDA_RX+DNUT_SDA msdi drive on 0.0s data 0.0s for "REGSEND_TS"
  set digital pin DUT_SDA_RX+DNUT_SDA msdi compare off 0.0s data TestPrd*0.125 for "REGSEND_TS"
 
  RegWrite(DUT_ID, SR_TEST0, 1, 0x0, 0x0, "dut_i2c_write")                                                    -- Set the ABUS to tristatate
  --open cbit K4_5_ABUS_DP_OR_DC+K73_GP12_13_VI16_OR_DCTM+K75_LOCK_11_VI16_OR_DCTM                              -- disconnect the DCTM / VI16 resources from the ABUS device pins

  --**************************************************************************************************
  --* Use the offset and gain information from above to perform different evaluations the help       *
  --* determine the health of the receiver.                                                          *
  --**************************************************************************************************
  -- Steve's Calculations without the VOS CTLE and GAIN Factors (per Alexei)
  -- NOTE: All *GCw values set to zero per Alexei and Steve Simmons.  Calculations left in place per Steve's request 
  for sIdx = 1 to Sites do                                                                    
    Cs = ActiveSites[sIdx]
    Ea[Cs] = AgcCode[Cs] - log(G1p8GainRes[Cs]) / 0.7
    Ea0[Cs] = MeanAGC - GCs
    Gc[Cs] = GCa2 * (Ea[Cs]-Ea0[Cs]) * abs(Ea[Cs]-Ea0[Cs]) + GCa1 *(Ea[Cs]-Ea0[Cs])+GCa0
    VgaRes[Cs] = abs(abs(G1p8VosRes[Cs])) + VGAGCw * Gc[Cs]
  endfor

  SampleRes = (REavg - FEavg) + SampleGCw * Gc[Cs]
  ConvergeRes = (ESavg - FEavg) + ConvergeGCw * Gc[Cs]
  InitRes = (REavg - ESavg) + InitGCw * Gc[Cs]

  Ctle128_Sample = DefVosRes + SampleRes  -- LeviB_20191216: New figure-of-merit added per Alexei
 

  -- Alexei's procedural calculations to obtain a "hazy" data slicer value  
  DacOsn = 40mV
  EsVthrIdealOffset = EsVt40Res - IdealEsVthr
  VosInRes = FEavg / M6dbGainRes + M6dbVosRes
  
  for sIdx = 1 to Sites do
    Cs = ActiveSites[sIdx]
    if abs(VosInRes[Cs]) > DacOsn[Cs] then
      VosQpQnRes[Cs] = -(M6dbVosRes[Cs] - float(sgn(VosInRes[Cs]))*DacOsn[Cs]) * M6dbGainRes[Cs]
    else
      VosQpQnRes[Cs] = FEavg[Cs]
    endif
    VosReMFeMEsRes[Cs]   = (REavg[Cs] - FEavg[Cs]) - (EsVthrIdealOffset[Cs] * float(sgn(REavg[Cs] - FEavg[Cs])))
    VosReMQpQnMEsRes[Cs] = REavg[Cs] - VosQpQnRes[Cs] - (EsVthrIdealOffset[Cs] * float(sgn(REavg[Cs] - VosQpQnRes[Cs])))
  endfor

  VosReInitRes = REavg + (DefVosRes * DefGainRes)
  VosFeInitRes = FEavg + (DefVosRes * DefGainRes)
  VosEsInitRes = ESavg + (DefVosRes * DefGainRes)


  VsigInit = (0.2 * DefGainRes) / 1.4  

  for sIdx = 1 to Sites do
    Cs = ActiveSites[sIdx]
    CombVosRes[Cs] = abs(REavg[Cs] - FEavg[Cs]) + abs(ESavg[Cs] - FEavg[Cs])
    VsigReInitRes[Cs] = VsigInit[Cs] - abs(VosReInitRes[Cs])
    VsigFeInitRes[Cs] = VsigInit[Cs] - abs(VosFeInitRes[Cs])
    VsigEsInitRes[Cs] = VsigInit[Cs] - abs(VosEsInitRes[Cs])
  endfor
  
  scatter_1d(VosReInitRes, VsigArrRes, 1)
  scatter_1d(VosFeInitRes, VsigArrRes, 2)
  scatter_1d(VosEsInitRes, VsigArrRes, 3)
  scatter_1d(VsigReInitRes, VsigArrRes, 4)
  scatter_1d(VsigFeInitRes, VsigArrRes, 5)
  scatter_1d(VsigEsInitRes, VsigArrRes, 6)

  for sIdx = 1 to Sites do
    Cs = ActiveSites[sIdx]
    if abs((ESavg[Cs] - VosQpQnRes[Cs]) - (EsVthrIdealOffset[Cs]*float(sgn(ESavg[Cs] - VosQpQnRes[Cs])))) > DacOsn[Cs] then  
      LeomvQpQnRes[Cs] = abs(abs((ESavg[Cs] - VosQpQnRes[Cs]) - (EsVthrIdealOffset[Cs]*float(sgn(ESavg[Cs] - VosQpQnRes[Cs])))) - DacOsn[Cs]) / 2.0   
    else
      LeomvQpQnRes[Cs] = 0.0      
    endif

    if abs((ESavg[Cs] - FEavg[Cs]) - (EsVthrIdealOffset[Cs]*float(sgn(ESavg[Cs] - FEavg[Cs])))) > DacOsn[Cs] then  
      LeomvFeRes[Cs] = abs(abs((ESavg[Cs] - FEavg[Cs]) - (EsVthrIdealOffset[Cs]*float(sgn(ESavg[Cs] - FEavg[Cs])))) - DacOsn[Cs]) / 2.0   
    else
      LeomvFeRes[Cs] = 0.0      
    endif

    if VosReMFeMEsRes[Cs] > 0.0 then                         -- Hazy DS test
      VosHazyFeRes[Cs] = VosReMFeMEsRes[Cs] + LeomvFeRes[Cs]
    else
      VosHazyFeRes[Cs] = VosReMFeMEsRes[Cs] - LeomvFeRes[Cs]
    end_if

    if VosReMQpQnMEsRes[Cs] > 0.0 then                       -- Hazy DS test
      VosHazyQpQnRes[Cs] = VosReMQpQnMEsRes[Cs] + LeomvQpQnRes[Cs]
    else
      VosHazyQpQnRes[Cs] = VosReMQpQnMEsRes[Cs] - LeomvQpQnRes[Cs]
    end_if
  endfor


  --Power Down
  DutPowerDown
  SetRelays("AllOpen")


  -- Datalog Results
  test_value EsVt24Res with EsVt24Test
  test_value EsVt40Res with EsVt40Test
  test_value LockGainRes with LockGainTest
  test_value LockVosRes with LockOffsetTest
  test_value DefGainRes with DefGainTest
  test_value DefVosRes with DefOffsetTest
  test_value M6dbGainRes with M6dbGainTest
  test_value M6dbGainCodeRes with M6dbGainCodeTest
  test_value M6dbVosRes with M6dbOffsetTest
  test_value G1p8VosRes with VosEsTest1p8
  test_value G1p8GainRes with AgcGainTest
  test_value G1p8GainCodeRes with AgcGainCodeTest

  -- datalog the FF test information
  test_value REavg with VosRETest
  test_value FEavg with VosFETest
  test_value ESavg with VosESTest
  test_value SampleRes with SampleTest
  test_value ConvergeRes with ConvTest
  test_value Ctle128_Sample with Ctle128_SampleTest
  test_value InitRes with InitTest
  test_value VgaRes with VgaTest
  
  test_value VsigArrRes with VsigInitTest
  test_value VosInRes with VosInCancelTest
  test_value VosQpQnRes with VosQpQnTest
  test_value LeomvFeRes   with LeomvFeTest
  test_value LeomvQpQnRes with LeomvTest
  test_value CombVosRes with CombVosTest
  test_value VosReMFeMEsRes with VosReMFeMEsTest
  test_value VosReMQpQnMEsRes with VosReMQpQnMEsTest
  test_value VosHazyFeRes with HazyDsTest
  test_value VosHazyQpQnRes with HazyDsQpQnTest

  test_value GainLoops_0p5 with GainLoopsTest_0p5
  test_value GainLoops_1p8 with GainLoopsTest_1p8

  if DebugGainSearch then
    test_value AgcSearchArray with AgcSearchTest
    test_value GainSearchArray with GainSearchTest
  endif

  test_value LinkAgcDelta_m6dB with LinkAgcDeltaTest_m6dB
  test_value LinkAgcDelta_1p8 with LinkAgcDeltaTest_1p8

  
  wait(10ms)
  
--   println(stdout, "GmslOsnMargin2 Time: ", stop_timer()!f:6:6, " s")
end_body   --  GmslOsnMargin2








function DlogEqualizerCoeff(SioChannel, LnkStatus, SiteCnt, DlogSites, TestCnt, LpCnt, TestCode, SupplyCorner, TestChar, TestNamePrefix, ReadNewValues, Datalog, TxAmpStr) :   multisite integer
  in string[8]            : SioChannel
  in multisite integer    : LnkStatus
  in word                 : SiteCnt
  in word list[MAX_SITES] : DlogSites
  in integer              : TestCnt, LpCnt
  in word                 : TestCode
  in string[8]            : SupplyCorner
  in_out integer_test     : TestChar
  in string[32]           : TestNamePrefix
  in boolean              : ReadNewValues
  in boolean              : Datalog
  in string[32]           : TxAmpStr
  
local
  multisite lword   : AgcValue, OsnValue, BstValue, Dfe5Value, Dfe4Value, Dfe3Value, Dfe2Value, Dfe1Value, TuneCapValue, TuneAmpValue, NoiseA3Value, NoiseA2Value, OffsetCalValue, LinkErrorReg
  word              : RO, sIdx, Cs
  boolean           : CHAR
  integer           : MinLStat, MaxLStat
end_local

static 
  multisite integer : GmslStatus, MarginValue, AgcIValue, OsnIValue, BstIValue, Dfe5IValue, Dfe4IValue, Dfe3IValue, Dfe2IValue, Dfe1IValue, TuneCapIValue, TuneAmpIValue, NoiseIValue
  multisite integer : OffsetCalIValue, LinkErrorIValue
end_static

body
        get_expr("OpVar_FChar", CHAR)
        if CHAR then
          MinLStat = 0
          MaxLStat = 500
        else
          MinLStat = 15
          MaxLStat = 15
        endif
        
        if SioChannel == "AP" OR SioChannel == "AN" then
          RO = 0x0
        else
          RO = 0x100
        endif

        if ReadNewValues then
          RegRead(DUT_ID, SR_RLMS10_A+RO, 1, RdWordUpper, AgcValue,       "dut_i2c_read")                -- Read each individual coefficient register to report for each transmit level test
          RegRead(DUT_ID, SR_RLMS11_A+RO, 1, RdWordUpper, BstValue,       "dut_i2c_read")
          RegRead(DUT_ID, SR_RLMS2E_A+RO, 1, RdWordUpper, OsnValue,       "dut_i2c_read")
          RegRead(DUT_ID, SR_RLMS13_A+RO, 1, RdWordUpper, Dfe5Value,      "dut_i2c_read")
          RegRead(DUT_ID, SR_RLMSC_A+RO, 1,  RdWordUpper, Dfe4Value,      "dut_i2c_read")
          RegRead(DUT_ID, SR_RLMSD_A+RO, 1,  RdWordUpper, Dfe3Value,      "dut_i2c_read")
          RegRead(DUT_ID, SR_RLMSE_A+RO, 1,  RdWordUpper, Dfe2Value,      "dut_i2c_read")
          RegRead(DUT_ID, SR_RLMSF_A+RO, 1,  RdWordUpper, Dfe1Value,      "dut_i2c_read")
          RegRead(DUT_ID, SR_RLMS88_A+RO, 1, RdWordUpper, TuneCapValue,   "dut_i2c_read")
          RegRead(DUT_ID, SR_RLMS89_A+RO, 1, RdWordUpper, TuneAmpValue,   "dut_i2c_read")
          RegRead(DUT_ID, SR_RLMS8A_A+RO, 1, RdWordUpper, OffsetCalValue, "dut_i2c_read")
          RegRead(DUT_ID, SR_RLMSA3_A+RO, 1, RdWordUpper, NoiseA3Value,   "dut_i2c_read")
          RegRead(DUT_ID, SR_RLMSA2_A+RO, 1, RdWordUpper, NoiseA2Value,   "dut_i2c_read")
          
          for sIdx = 1 to SiteCnt do                                                                  -- Calculate test values from register reads above for datalogging
            Cs = DlogSites[sIdx]
            GmslStatus = LnkStatus
            AgcIValue[Cs] = integer(AgcValue[Cs])  
            BstIValue[Cs] = integer(BstValue[Cs])  
            OsnIValue[Cs] = integer(OsnValue[Cs])  
            Dfe5IValue[Cs] = integer(Dfe5Value[Cs] & 0x7F)  
            Dfe4IValue[Cs] = integer(Dfe4Value[Cs] & 0x7F)  
            Dfe3IValue[Cs] = integer(Dfe3Value[Cs] & 0x7F)  
            Dfe2IValue[Cs] = integer(Dfe2Value[Cs] & 0x7F)  
            Dfe1IValue[Cs] = integer(Dfe1Value[Cs] & 0x7F)  
            TuneCapIValue[Cs] = integer(TuneCapValue[Cs] & 0x1E)  
            TuneAmpIValue[Cs] = integer(TuneAmpValue[Cs])
            NoiseIValue[Cs] = integer( (NoiseA3Value[Cs] & 0xF)*256 + NoiseA2Value[Cs])
            OffsetCalIValue[Cs] = integer(OffsetCalValue[Cs] & 0x3F)
          endfor
        endif
        
        if Datalog then
          
          -- Datalog GMSL Status and adapter Coefficent values 
          test_value GmslStatus lo MinLStat hi MaxLStat test (TestChar.minor_id + TestCnt) fail_bin TestChar.fail_bin comment TestNamePrefix + "_LSTAT_" + SioChannel + "_" + TestChar.test_text + "_AT_" + TxAmpStr + "_" + SupplyCorner
          test_value AgcIValue lo TestChar.low_limit hi TestChar.high_limit test (TestChar.minor_id + TestCnt+1) fail_bin TestChar.fail_bin comment TestNamePrefix + "_AGC_" + SioChannel + "_" + TestChar.test_text + "_AT_" + TxAmpStr + "_" + SupplyCorner
          test_value BstIValue lo TestChar.low_limit hi TestChar.high_limit test (TestChar.minor_id + TestCnt+2) fail_bin TestChar.fail_bin comment TestNamePrefix + "_BST_" + SioChannel + "_" + TestChar.test_text + "_AT_" + TxAmpStr + "_" + SupplyCorner
          test_value OsnIValue lo 1 hi 62 test (TestChar.minor_id + TestCnt+3) fail_bin TestChar.fail_bin comment TestNamePrefix + "_OSN_" + SioChannel + "_" + TestChar.test_text + "_AT_" + TxAmpStr + "_" + SupplyCorner
          --test_value Dfe5IValue lo TestChar.low_limit hi TestChar.high_limit test (TestChar.minor_id + TestCnt+4) fail_bin TestChar.fail_bin comment TestNamePrefix + "_DFE5_" + SioChannel + "_" + TestChar.test_text + "_AT_" + TxAmpStr + "_" +  SupplyCorner
          --test_value Dfe4IValue lo TestChar.low_limit hi TestChar.high_limit test (TestChar.minor_id + TestCnt+5) fail_bin TestChar.fail_bin comment TestNamePrefix + "_DFE4_" + SioChannel + "_" + TestChar.test_text + "_AT_" + TxAmpStr + "_" + SupplyCorner
          test_value Dfe3IValue lo TestChar.low_limit hi TestChar.high_limit test (TestChar.minor_id + TestCnt+6) fail_bin TestChar.fail_bin comment TestNamePrefix + "_DFE3_" + SioChannel + "_" + TestChar.test_text + "_AT_" + TxAmpStr + "_" +  SupplyCorner
          test_value Dfe2IValue lo TestChar.low_limit hi TestChar.high_limit test (TestChar.minor_id + TestCnt+7) fail_bin TestChar.fail_bin comment TestNamePrefix + "_DFE2_" + SioChannel + "_" + TestChar.test_text + "_AT_" + TxAmpStr + "_" +  SupplyCorner
          test_value Dfe1IValue lo TestChar.low_limit hi TestChar.high_limit test (TestChar.minor_id + TestCnt+8) fail_bin TestChar.fail_bin comment TestNamePrefix + "_DFE1_" + SioChannel + "_" + TestChar.test_text + "_AT_" + TxAmpStr + "_" + SupplyCorner
          test_value TuneCapIValue lo TestChar.low_limit hi TestChar.high_limit test (TestChar.minor_id + TestCnt+9) fail_bin TestChar.fail_bin comment TestNamePrefix + "_TCAP_" + SioChannel + "_" + TestChar.test_text + "_AT_" + TxAmpStr + "_" + SupplyCorner
          test_value TuneAmpIValue lo TestChar.low_limit hi TestChar.high_limit test (TestChar.minor_id + TestCnt+10) fail_bin TestChar.fail_bin comment TestNamePrefix + "_TAMP_" + SioChannel + "_" + TestChar.test_text + "_AT_" + TxAmpStr + "_" + SupplyCorner
          test_value NoiseIValue lo TestChar.low_limit hi TestChar.high_limit test (TestChar.minor_id + TestCnt+11) fail_bin TestChar.fail_bin comment TestNamePrefix + "_NOISE_" + SioChannel + "_" + TestChar.test_text + "_AT_" + TxAmpStr + "_" + SupplyCorner
          test_value OffsetCalIValue lo TestChar.low_limit hi TestChar.high_limit test (TestChar.minor_id + TestCnt+12) fail_bin TestChar.fail_bin comment TestNamePrefix + "_OFFSET_CAL_" + SioChannel + "_" + TestChar.test_text + "_AT_" + TxAmpStr + "_" + SupplyCorner
        endif
    return(OsnIValue)
end_body   --  DlogEqualizerCoeff








function TestOsnMarginState(OsnValue, TestType, RO, SiteArr, Sites, EcapVltg, XcapVltg, DcapVltg, ZcVltg, CtleVal) : integer
--************************************************************************************************************
--* This function sets the OSN value, measures the Q voltage and reads the ES, FE and RE ff register values. *
--* The function can also detect if all ff states are in a pre or post toggle state and return a result for  *
--* each site.  The ff arrays are also encoded and returned to allow analysis of the state of each ff at the *
--* tested OSN code.                                                                                         *
--* Encoding: -99 = index not tested, -100mV = index at pre-state, < 100mV = index at post-state             *
--************************************************************************************************************

in multisite lword      : OsnValue
in string[8]            : TestType
in word                 : RO
in word list[MAX_SITES] : SiteArr
in word                 : Sites
in_out multisite float  : EcapVltg[64], XcapVltg[64], DcapVltg[64], ZcVltg[64]
in_out multisite float  : CtleVal


local
  multisite lword       : Rlms40Reg, Rlms41Reg, Rlms42Reg, EcapVal, XcapVal, DcapVal
  word                  : sIdx, Cs
  integer               : TestRes                                                             -- Used to notify if all sites have met the proper criteriea for Fe, Re and Es states
end_local

body
  TestRes = 0

  mRegWrite(DUT_ID, SR_RLMS33_A+RO, 1, mslw(0x0), OsnValue, "dut_i2c_write")                   -- Set OSN value
  RegWrite(DUT_ID,  SR_RLMS57_A+RO, 1, 0x0, 0x1, "dut_i2c_write")                               -- reseed the coefficients
  RegWrite(DUT_ID,  SR_RLMS40_A+RO, 1, 0x0, 0x1, "dut_i2c_write")                               -- Start data capture
  wait(2ms)
  RegRead(DUT_ID, SR_RLMS40_A+RO, 1, RdWordUpper, Rlms40Reg, "dut_i2c_read")                   -- Read the Captured value
  RegRead(DUT_ID, SR_RLMS41_A+RO, 1, RdWordUpper, Rlms41Reg, "dut_i2c_read")                   -- Read the Captured value
  RegRead(DUT_ID, SR_RLMS42_A+RO, 2, RdWordUpper, Rlms42Reg, "dut_i2c_read")                   -- Read the Captured value
                                                                                                 
  EcapVal = ((Rlms41Reg & 0xC) >> 2)
  XcapVal = (Rlms40Reg & 0x3F)
  DcapVal = ((Rlms42Reg << 4) + ((Rlms41Reg & 0xF0) >> 4))
   
  -- measure vi16 v on chan abus0_pins+abus1_pins for 17 samples every 10us averaged into TmpFltArr
  CtleVal = DCTM_MeasDiff(DUT_GPIO14_ABUS0_DCTM, DUT_GPIO15_ABUS1_DCTM, 11V, 17, 100KHz) * 2.0

  TestRes = 1
  for sIdx = 1 to Sites do
    Cs = SiteArr[sIdx]
    
    if Ucase(TestType) = "TESTPRE" then                                                      -- Test to see if any of the values are not in their required initial condition
      if EcapVal[Cs] > 0 or XcapVal[Cs] < 63 or DcapVal[Cs] < 1048575 then
        TestRes = 0
      endif
    elseif Ucase(TestType) == "TESTPOST" then                                                -- Test to see if all of the values are in their required post condition
      if EcapVal[Cs] <> 3 or XcapVal[Cs] > 0 or DcapVal[Cs] > 0 then
        TestRes = 0
      endif
    elseif Ucase(TestType) == "NONE" then
      TestRes = -1
    else
      Print_banner_message("ETEST->Cadence Parameter Error: TestOsnMarginState : TestType", "The Test Type must be TESTPRE, TESTPOST, NONE", "Halting Test Program")
      halt
    endif

    ZcVltg[Cs, integer(OsnValue[Cs])] = CtleVal[Cs]
    if EcapVal[Cs] == 3 then
      EcapVltg[Cs, integer(OsnValue[Cs])] = CtleVal[Cs]
    else
      EcapVltg[Cs, integer(OsnValue[Cs])] = -100.0mV
    endif
    if DcapVal[Cs] == 0 then
      DcapVltg[Cs, integer(OsnValue[Cs])] = CtleVal[Cs]
    else
      DcapVltg[Cs, integer(OsnValue[Cs])] = -100.0mV
    endif
    if XcapVal[Cs] == 0 then
      XcapVltg[Cs, integer(OsnValue[Cs])] = CtleVal[Cs]
    else
      XcapVltg[Cs, integer(OsnValue[Cs])] = -100.0mV
    endif
    
--    println(stdout, "Site ", Cs, "  OSN Code = ", OsnValue[Cs]:02, "   CTLE = ", CtleVal[Cs]!f:6:3, "    ES = ", EcapVal[Cs]:3, "  FE = ", XcapVal[Cs]:3, "    RE = ",  DcapVal[Cs])
  endfor
  
  return (TestRes)
end_body   --  TestOsnMarginState







procedure GmslOffsetMeasureCtle(OsnValue, TestType, RO, CtleVal)
in multisite lword      : OsnValue
in string[8]            : TestType
in word                 : RO
in_out multisite float  : CtleVal

body

  mRegWrite(DUT_ID, SR_RLMS33_A+RO, 1, mslw(0x0), OsnValue, "dut_i2c_write")                   -- Set OSN value
  RegWrite(DUT_ID,  SR_RLMS57_A+RO, 1, 0x0,       0x1,      "dut_i2c_write")                   -- reseed the coefficients
  RegWrite(DUT_ID,  SR_RLMS40_A+RO, 1, 0x0,       0x1,      "dut_i2c_write")                   -- Start data capture
  wait(2ms)

  -- measure vi16 v on chan abus0_pins+abus1_pins for 17 samples every 10us averaged into TmpFltArr
  --CtleVal = DCTM_MeasDiff(DUT_GPIO16_ABUS2_DCTM, DUT_GPIO17_ABUS3_DCTM, 11V, 17, 100KHz) * 2.0
  CtleVal = DCTM_MeasDiff(DUT_GPIO14_ABUS0_DCTM, DUT_GPIO15_ABUS1_DCTM, 11V, 17, 100KHz) * 2.0

end_body   --  GmslOffsetMeasureCtle














procedure Capture_Offset_Codes(PHY, DCapSwitch, ECapSwitch, XCapSwitch, NumAverages)
--  sweeps OSN value and captures DCAP/ECAP/XCAP, averages up to 100x 

out multisite float: DCapSwitch, ECapSwitch, XCapSwitch
in word: NumAverages
in String[8]: PHY

local
  word: send_word[65], count, average
  multisite lword: dcap[100, 64], ecap[100, 64], xcap[100,64]
  multisite word: dswitch[100], eswitch[100], xswitch[100]
  multisite lword: capture_array[65]
  multisite boolean: d_found, e_found, x_found
  multisite float : d_found_count, e_found_count, x_found_count
  word            :   sites, idx, csite
  word list[MAX_SITES]   : ActiveSites
  float   : timez
end_local

body

  ActiveSites = get_active_sites()
  sites = word(len(ActiveSites))
  
  send_word[1] = 0xFF
  for count = 1 to 64 by 1 do
      send_word[count+1]  = count - 1
  end_for
    
  load digital reg_send fx1 waveform "OFFSET_WRITE" with send_word
  enable digital reg_send fx1 waveform "OFFSET_WRITE"
  
  for average = 1 to NumAverages do
    d_found = FALSE
    e_found = FALSE
    x_found = FALSE
    enable   digital capture  fx1 waveform "OFFSET_CAPTURE"
     
    if PHY = "AP" or PHY = "AN" then 
        execute  digital pattern "phya_osn_loop" run to end 
    else
        execute  digital pattern "phyb_osn_loop" run to end 
    end_if
    wait for digital capture  fx1 waveform "OFFSET_CAPTURE"
    read     digital capture  fx1 waveform "OFFSET_CAPTURE" into capture_array 
    
    --now format data
    for idx = 1 to sites do
      csite = ActiveSites[idx]
      for count = 1 to 64 do
        dcap[csite, average, count] = (capture_array[csite, count+1] & 0x0000FFFF)  + ((capture_array[csite, count+1] & 0x00F00000) >> 4)
        if count > 1 and not d_found[csite] then
          if dcap[csite, average, count] = 0 and dcap[csite, average, count-1] <> 0 then
            dswitch[csite, average] = count - 1  --capture OSN code at which dcap switched 
            d_found[csite] = TRUE
            d_found_count[csite] = d_found_count[csite] + 1.0
          end_if
        end_if
        xcap[csite, average, count] = (capture_array[csite, count+1] & 0x3F000000) >> 24
        if count > 1 and not x_found[csite] then
          if xcap[csite, average, count] = 0 and xcap[csite, average, count-1] <> 0 then
            xswitch[csite, average] = count - 1  --capture OSN code at which dcap switched \
            x_found[csite] = TRUE
            x_found_count[csite] = x_found_count[csite] + 1.0
          end_if
        end_if    
        ecap[csite, average, count] = (((capture_array[csite, count+1])& 0x000C0000) >> 18) & 0x3
        if count > 1 and not e_found[csite] then
          if ecap[csite, average, count] == 3 and ecap[csite, average, count-1] <> 3 then
            eswitch[csite, average] = count - 1  --capture OSN code at which dcap switched 
            e_found[csite] = TRUE
            e_found_count[csite] = e_found_count[csite] + 1.0
          end_if
        end_if
      end_for
    end_for
  end_for   
  
  for idx = 1 to sites do
    csite = ActiveSites[idx]
    DCapSwitch[csite] = 0.0
    XCapSwitch[csite] = 0.0
    ECapSwitch[csite] = 0.0
    for count = 1 to NumAverages by 1 do
      DCapSwitch[csite] = DCapSwitch[csite] + float(dswitch[csite, count])
      XCapSwitch[csite] = XCapSwitch[csite] + float(xswitch[csite, count])
      ECapSwitch[csite] = ECapSwitch[csite] + float(eswitch[csite, count])
    end_for
    if d_found_count[csite] > float(NumAverages / 2) then
      DCapSwitch[csite] = float(DCapSwitch[csite]) / d_found_count[csite]
    else
      DCapSwitch[csite] = 0.0
    endif
    if x_found_count[csite] > float(NumAverages / 2) then
      XCapSwitch[csite] = float(XCapSwitch[csite]) / x_found_count[csite]
    else
      XCapSwitch[csite] = 0.0
    endif
    if e_found_count[csite] > float(NumAverages / 2) then
      ECapSwitch[csite] = float(ECapSwitch[csite]) / e_found_count[csite]
    else
      ECapSwitch[csite] = 0.0
    endif
  end_for 
  
  wait(0s)
end_body   --  Capture_Offset_Codes






function MeasureCtle(SioChannel, OsnCode) :   multisite float
in string[8] : SioChannel
in multisite float: OsnCode

local
  multisite float: RetVal, Ctle1, Ctle2
  word           : RO, Cs, sIdx, Sites
  word list[4]   : ActiveSites
end_local

body
  ActiveSites = get_active_sites()
  Sites = word(len(ActiveSites))

  if SioChannel == "AP" OR SioChannel == "AN" then
    RO = 0
  else
    RO = 0x100
  endif

  mRegWrite(DUT_ID, SR_RLMS33_A+RO, 1, mslw(0x0), lword(OsnCode), "dut_i2c_write") 
  RegWrite(DUT_ID,  SR_RLMS57_A+RO, 1, 0x0, 0x1, "dut_i2c_write") 
  Ctle1 = DCTM_MeasDiff(DUT_GPIO14_ABUS0_DCTM, DUT_GPIO15_ABUS1_DCTM, 11V, 17, 100KHz) * 2.0

  mRegWrite(DUT_ID, SR_RLMS33_A+RO, 1, mslw(0x0), lword(OsnCode+1.0), "dut_i2c_write") 
  RegWrite(DUT_ID,  SR_RLMS57_A+RO, 1, 0x0, 0x1, "dut_i2c_write") 
  Ctle2 = DCTM_MeasDiff(DUT_GPIO14_ABUS0_DCTM, DUT_GPIO15_ABUS1_DCTM, 11V, 17, 100KHz) * 2.0
  
  RetVal = (Ctle2 - Ctle1) * (OsnCode - float(lword(OsnCode))) + Ctle1

  for sIdx = 1 to Sites do    --Add for loop to set RetVal = 999 for any site with OSN code == 0 (did not find a transition location
    Cs = ActiveSites[sIdx]
    if OsnCode[Cs] == 0.0 then
      RetVal[Cs] = 999.0
    endif  
  endfor

  return (RetVal)
end_body   --  MeasureCtle








procedure Gmsl_Link_Sensitivity_HS89 (Vdd, Vdd18, Vddio, LinkDirection, FwTxRate, RevTxRate, SioChannel, CharSweep, GNG_TestCode,  RLMS, Threshold, ECP_Offset,  TestSensitivity, TestMargin, TestLock, TestRxDpLock, TestDecodingErrors, TestRetryLoops, TdiodeTempTest, TmonTempTest, TdiodeVTest, TmonVTest, TvssVTest,CfTest)
  in float             : Vdd, Vdd18, Vddio                 -- Power supply voltages
  in string[12]        : LinkDirection                     -- "F" = forward 87->84,  "R" = reverse 87 <- 84, "FR" = both directions
  in float             : FwTxRate, RevTxRate               -- Transmit Rates (Gb) Forward = 1.5, 3.0, 6.0  Reverse = 0.1875, 0.375, 0.750, 1.5
  in integer           : GNG_TestCode                      -- Go/NoGo test level, multiply this by 10mV to get the GNG test voltage
  in boolean           : CharSweep                         -- If this is true it will sweep the voltage (code) until it fails.
  in integer           :  Threshold, ECP_Offset
  in boolean           : RLMS  --enabled or disabled
  in string[12]        : SioChannel                        -- SIO channels to test "A" or "B"
  in_out integer_test  : TestMargin, TestSensitivity, TestLock, TestRxDpLock, TestDecodingErrors, TestRetryLoops, CfTest
  in_out float_test    : TdiodeTempTest, TmonTempTest, TdiodeVTest, TmonVTest, TvssVTest
  
local
  multisite lword   : AgcValue, OsnValue, BstValue, Dfe5Value, Dfe4Value, Dfe3Value, Dfe2Value, Dfe1Value, TuneCapValue, TuneAmpValue, NoiseA3Value, NoiseA2Value, OffsetCalValue, LinkErrorReg
  multisite integer : GmslStatus, MarginValue, SensitivityValue, AgcIValue, OsnIValue, BstIValue, Dfe5IValue, Dfe4IValue, Dfe3IValue, Dfe2IValue, Dfe1IValue, TuneCapIValue, TuneAmpIValue, NoiseIValue, OffsetCalIValue, LinkErrorIValue, DecodingErrors, Locked, RxDpLock, RetryLoops
  float             : InitialValue, TestDwellTime
  lword             : RegCtrl0, RegCtrl0_Pre, LpCnt
  integer           : TestCnt
  word              : CurSite, InitCode, MinCode, TestCode, StepCode = 1, RO = 0
  boolean           : PowerUp = true, TestAdaptOnly = true, EnHiRateAssist = false, NeedRevMargin = false, MeasTemp=true
  string[2]         : USioChannel
  word              :   sites, idx
  word list[MAX_SITES]   : active_sites
  word list[MAX_SITES]   : current_active_sites
  integer                : CoaxMode = 1
  multisite float        :   TdiodeMeas[1], TvssMeas[1], TdiodeTemp[1], TmonMeas[1], TmonTemp[1]

  word                   : CorrectionFactor  -- Account for differences between board revisions.
  multisite integer      : iCorrectionFactor -- for datalog
  string[32]             : response

end_local

body
    active_sites = get_active_sites()
    sites = word(len(active_sites))

    SioChannel = Ucase(SioChannel)
    LinkDirection = Ucase(LinkDirection)

    MarginValue = 0
    SensitivityValue = 0

--     -- Setup the HW correction factor. LeviB_20200109
--     if Stored_HardwareName = opvarHWName then
--         CorrectionFactor = 0
--     elseif Stored_HardwareName = opvarHWName_2 and PACKAGE = "MRQ" and SioChannel = "AP" and RevTxRate = 1.5 then
--         CorrectionFactor = 3
--     elseif Stored_HardwareName = opvarHWName_2 and PACKAGE = "MRQ" and SioChannel = "BP" and RevTxRate = 1.5 then
--         CorrectionFactor = 4
--     elseif Stored_HardwareName = opvarHWName_2 and PACKAGE = "MRQ" and SioChannel = "AP" and RevTxRate = 0.1875 then
--         CorrectionFactor = 2
--     elseif Stored_HardwareName = opvarHWName_2 and PACKAGE = "MRQ" and SioChannel = "BP" and RevTxRate = 0.1875 then
--         CorrectionFactor = 1
--     elseif Stored_HardwareName = opvarHWName_2 then
--         CorrectionFactor = 0   -- Need to gage TQFN HW for this value
--     else
--       Print_banner_message("Error", "Test_Gmsl_Link_Sensitivity correction factor is not valid!", "Press 'Enter' to Continue")
--       input(stdin, response !L)    
--     endif            



    -- Set the char sweep initial value or the GNG reference value
    if LinkDirection = "F" then
        InitCode = 41                                            -- Default transmit code for all forward transmit rates
    elseif LinkDirection = "R" AND RevTxRate = 1.5 then
        InitCode = 37                                            -- Rev transmit code for all 1.5G reverse rates
    else
        InitCode = 25                                            -- Rev transmit code for all other reverse rates
    endif

    MinCode = 1

 
    current_active_sites = get_active_sites()
    sites = word(len(current_active_sites)) 


    if CharSweep then
        TestCode = InitCode
    else
        TestCode = word(GNG_TestCode)
        MeasTemp = false
        StepCode = 0
    endif

    TestDwellTime = 100ms       
    --TestDwellTime = 2s       
    

    TestCnt = 0
    while sites > 0 and TestCode > MinCode  do  
     
     if TestCnt = 0 then 
         --GmslStatus = DutPowerupAndLockDevices2_LinkTest(Vdd, VddA, Vdd18, Vddio, Vddio25, Vdd33, SioChannel, Word(CoaxMode), FwTxRate, RevTxRate, 1, 0.0, LinkDirection, TestCode-CorrectionFactor, TestDwellTime, lword(Threshold), lword(ECP_Offset), LinkErrorIValue, DecodingErrors, RetryLoops, TRUE)    
         DutPowerUp(Vddio, Vdd18, Vdd, "I2C", "COAX_GMSL2",TRUE)
     else
         GmslStatus = DutPowerupAndLockDevices2_LinkTest(Vdd, VddA, Vdd18, Vddio, Vddio25, Vdd33, SioChannel, Word(CoaxMode), FwTxRate, RevTxRate, 1, 0.0, LinkDirection, TestCode-CorrectionFactor, TestDwellTime, lword(Threshold), lword(ECP_Offset), LinkErrorIValue, DecodingErrors, RetryLoops, FALSE)    
     endif


      for idx = 1 to sites do                                                
        CurSite = current_active_sites[idx]
        
        Locked[CurSite] = ( LinkErrorIValue[CurSite] >> 3 ) & 0x01
        RxDpLock[CurSite] = ( LinkErrorIValue[CurSite] >> 6 ) & 0x01

        if (LinkErrorIValue[CurSite] <> 0xCA or TestCode <= 2 or DecodingErrors[CurSite] > 0)  then            -- If a site fails to link or the search gets to TXAMP = 20mV store the value and deactivate the site
          if Not CharSweep then
            SensitivityValue[CurSite] = -1                                                                     --GNG Fail Flag
            MarginValue[CurSite]    =  0
          elseif TestCode == InitCode then
            SensitivityValue[CurSite] = integer(TestCode)*10
            MarginValue[CurSite] = 0
          else
            SensitivityValue[CurSite] = integer(TestCode)*10
            MarginValue[CurSite] = integer(InitCode - TestCode)*10                                             -- Store the margin value based on the previous TestCode to be datalogged at end of test
          endif
          deactivate site CurSite             
        elseif Not CharSweep then
            SensitivityValue[CurSite] = integer(TestCode)*10
            MarginValue[CurSite] = integer(InitCode - TestCode)*10
            deactivate site CurSite             
        endif
      endfor 
       
      current_active_sites = get_active_sites()
      sites = word(len(current_active_sites)) 
      
      if StepCode > 0 then                                                                                     -- If StepCode equals zero then we only want a single execution
        if StepCode > TestCode then
          TestCode = 0
        else
          TestCode = TestCode - StepCode
        endif
      else
        TestCode = MinCode - 1
      endif
     TestCnt = TestCnt + 1

    endwhile

   
  activate site active_sites
  sites = word(len(active_sites))


    -- Check die temp to aid with correlation
    if MeasTemp then
        MeasureTemperature(TdiodeMeas, TvssMeas, TdiodeTemp, TmonMeas, TmonTemp)    
    endif

    --Power Down
    DutPowerDown
    SetRelays("AllOpen")

    test_value SensitivityValue with TestSensitivity
    test_value MarginValue with TestMargin
    test_value Locked with TestLock
    test_value RxDpLock with TestRxDpLock
    test_value DecodingErrors with TestDecodingErrors
    test_value RetryLoops with TestRetryLoops

    iCorrectionFactor = integer(CorrectionFactor)*10
    test_value iCorrectionFactor with CfTest

    -- Datalog die temp
    if MeasTemp then
        test_value TdiodeTemp with TdiodeTempTest
        test_value TmonTemp with TmonTempTest
        test_value TdiodeMeas with TdiodeVTest
        test_value TmonMeas with TmonVTest
        test_value TvssMeas with TvssVTest
    endif


    Print_timer("Test_Gmsl_Link_Sensitivity")

end_body
procedure OsnReplicaGain_HS89(Vdd, Vdd18, Vddio, vdiff_lim, gain_lim )
--------------------------------------------------------------------------------
--  This procedure implements Alexei's 2019-Oct-31 quick algorithm for
--      looking at the replica gain
--
-- PARAMETERS:
in float                                                    : Vdd, Vdd18, Vddio
in_out array of float_test                                  : vdiff_lim, gain_lim
--------------------------------------------------------------------------------
local
    multisite float                                         : vmeas, vdiff[2], vabs[2], gain[2]
    word                                                    : sidx, stn, nsites
    word list[MAX_SITES]                                    : actv
    
    word                                                    : RO[2], phy
    lword                                                   : BlkPg[2], fw[2]
    
end_local
body
    actv = get_active_sites()
    nsites = word(len(actv))

    DutPowerUp(Vdd, Vdd18, Vddio, "I2C", "COAX_GMSL2", TRUE) -- Lhial: VDD18 input argument was constant "1.9V" from HS95 original code. Changed to variable "Vdd18". Return back to constant if needed.
    wait(10ms)
--     set hcovi DUT_VDD18 to fv Vdd18 vmax 3V measure i max 1A clamp imax 800mA imin -800mA    -- Related to above change. Uncomment if needed.
--     wait(10ms) 


    RO[1] = 0x000
    RO[2] = 0x100
    fw[1] = 0xBD
    fw[2] = 0xDE
    BlkPg[1] = 0x88
    BlkPg[2] = 0x98

    --**************************************************************************************************
    --* Setup ABUS and DCTM for ABUS measurements                                                      *
    --**************************************************************************************************
    SetTestMode(14, False , "dut_i2c_write")                                                                -- Set TESMODE to ABUS
    RegWrite(SER_ID, SR_TEST0, 1, 0x0, 0x00, "dut_i2c_write")                                       -- Set the ABUS to tristatate
    --RegWrite(DUT_ID, REG92DES_DEV_IO_CHK1, 1, 0x0, 0x04 ,           "des_i2c_write")                                       -- required to enable analog test bus
    close cbit K6_K51_GPIO14_GPIO15_GPIO16_GPIO17__DP_VI+K73_ABUS2_ABUS3__VI_DCTM
    wait(5ms)

    DCTM_Init(DUT_GPIO16_ABUS2_DCTM, DUT_GPIO16_ABUS2_DCTM, 11V, 17, 100KHz)

        -- -- dummy to prove that DCTM and ABUS are working
        -- RegWrite(DES_ID, REG92DES_TCTRL_TEST0, 1, 0x0, 0x04, "des_i2c_write")                                                 -- should be power page, v0.6 - v1.2
        -- vmeas = DCTM_MeasDiff(DCTM_ABUS23_MH, DCTM_ABUS23_ML, 11V, 17, 100KHz)
        -- println(stdout, "vmeas(ABUS23, 0x04): 1.2v-0.6v = ", vmeas[1:4]!fu=mV:16:1, "power blk, page 4: <3>:v0p6, <2>:v1p2" )

    for phy = 1 to 2 do
        -- Enable PHY X
        --      A:  0x90,0x10,0x01
        --      B:  0x90,0x10,0x02
        RegWrite( DUT_ID , SR_CTRL0 , 1 , 0x0 , lword(phy) , "dut_i2c_write")

        -- Manual control mode PHY A 
        --      A: 0x90,0x4A7,0xE1
        --      B: 0x90,0x5A7,0xE1
        RegWrite( DUT_ID , SR_RLMSA7_A | RO[phy] , 1 , 0x0 , 0xE1 , "dut_i2c_write")

        --  Disable all Remote Control Channels,,
        --      *: 0x90,0x01,0x57
        RegWrite( DUT_ID , SR_REG2 , 1 , 0x0 , 0x57 , "dut_i2c_write")

        --  firmware control mode PHY A - Force CTRL_EN, PHY_EN, LOCK",,
        --      A: 0x90,0x17,0xBD                                                       
        --      B: 0x90,0x17,0xDE   -- debug note: Per Alexei, 0xDE instead of 0x7D     
        RegWrite( DUT_ID , SR_CTRL7 , 1 , 0x0 , fw[phy] , "dut_i2c_write")
        
        -- Force TxD High on PHY-A
        --      A: 0x90,0x1448,0x29
        --      B: 0x90,0x1548,0x29
        RegWrite( DUT_ID , SR_RLMS48_A | RO[phy] , 1 , 0x0 , 0x29 , "dut_i2c_write")

        --
        --
        --

        -- Replica Output to ABUS on PHY-A
        --      A: 0x90,0x14C1,0x40
        --      B: 0x90,0x15C1,0x40
        RegWrite( DUT_ID , SR_RLMSC1_A | RO[phy] , 1 , 0x0 , 0x40 , "dut_i2c_write")
        
        -- Set Manual TuneAmp PHY-A
        --      A: 0x90,0x1485,0xBB
        --      B: 0x90,0x1585,0xBB
        RegWrite( DUT_ID , SR_RLMS85_A | RO[phy] , 1 , 0x0 , 0xBB , "dut_i2c_write")

        -- Set Test Mode Entry Key (above)
        --      0x90,0x3F,0x0E
        -- Set Test Mode: page 8 of block 8/9 Entry Key (above)
        --      A: 0x90,0x3E,0x?8
        --      B: 0x90,0x3E,0x?8
        RegWrite(DUT_ID, SR_TEST0, 1, 0x0, BlkPg[phy], "dut_i2c_write")    -- Set the ABUS to gmsl2_phy(AorB)_abus_block, page 8
        wait(5ms)

        -- measure differential voltage: need to datalog ABUS3-ABUS2, but the DCTM sign is ABUS2-ABUS3 that, so -1.0*dctm_diff
        vmeas = -1.0*DCTM_MeasDiff(DUT_GPIO16_ABUS2_DCTM, DUT_GPIO16_ABUS2_DCTM, 11V, 17, 100KHz)
        scatter_1d( vmeas , vdiff , phy )

    end_for -- phy a/b loop

    for sidx = 1 to nsites do
        stn = actv[sidx]
        for phy = 1 to 2 do
            gain[stn,phy] = abs(vdiff[stn,phy]) / 410mV
        end_for
    end_for
    
    test_value vdiff with vdiff_lim
    test_value gain with gain_lim

    DutPowerDown()
    SetRelays("AllOpen")

end_body



