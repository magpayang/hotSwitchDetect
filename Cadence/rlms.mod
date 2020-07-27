
--RLMS coefficient datalogging program
--Matt Wachsmuth 9-27-2019

--Instructions for Use:

--1.  Add "use module "rlms.mod" to your .tp file
--2.  Add 4 pattern files to your program: dut_i2c_rlms_read, dut_uart_rlms_read, dnut_i2c_rlms_read, dnut_uart_rlms_read.  These patterns assume your pins are DP_SDA/DP_SCL and DP_AUX_SDA, DP_AUX_SCL.  
--3.  add the defines below to your digital capture/reg_send Define_captures procedure 
--4.  Make sure the devices you will be measuring are in the PopulateDeviceTable procedure in rlms.mod
--5.  Put PopulateDeviceTable in your on load, for example in Global_SW_Init after your pins are loaded
--6.  update user modules below if needed.  This function only needs to access your reg_access, pin file, and possibly global variables
--7.  In the test function where you want to datalog the RLMS coefficients, create a test.  You can call the test whatever you want, I use RLMS_Values
--8.  In the comment of the test add in the link rate and link type, for example "GMSL2_6_15_COAX" or "GMSL3_12_187_STP", etc
--9.  In the test code, run the DlogCoefficients with the appropriate pass parameters, more info in that procedure


    --DEFINES TO ADD TO Define_captures PROCEDURE:
    --RLMS capture   -- updated from 21 to 26 to reflect new register reads. Pattern also updated.
    --define digital reg_send fx1 waveform "DNUT_UART_RLMS_WRITE"     on DP_AUX_SDA     for 5*26 vectors serial lsb mode 9 bits  
    --define digital capture fx1 waveform "DNUT_UART_RLMS_WRITE_CAPTURE"   on DP_AUX_SCL     for 26*32 vectors serial msb mode 4 bits  
    --define digital reg_send fx1 waveform "DUT_UART_RLMS_WRITE"          on DP_SDA     for 5*26 vectors serial lsb mode 9 bits
    --define digital capture fx1 waveform "DUT_UART_RLMS_WRITE_CAPTURE"   on DP_SCL     for 26*32 vectors serial msb mode 4 bits
    --define digital reg_send fx1 waveform "DUT_I2C_RLMS_WRITE"    on DP_SDA      for 4*26  vectors serial msb mode 8 bits
    --define digital capture  fx1 waveform "DUT_I2C_RLMS_READ"    on DP_SDA      for 26  vectors serial msb mode 8 bits
    --define digital reg_send fx1 waveform "DNUT_I2C_RLMS_WRITE"    on DP_AUX_SDA      for 4*26  vectors serial msb mode 8 bits
    --define digital capture  fx1 waveform "DNUT_I2C_RLMS_READ"    on DP_AUX_SDA      for 26  vectors serial msb mode 8 bits
    

-- example: DlogCoefficients("HS88_A", "DUT", RLMS_Values, Vdd18, "")

-- The code will parse the string values for all the information it needs to proceed.


use module "user_globals.mod"
use module "reg_access.mod"
use module "SERDES_Pins.mod"
use module "HS87.tp"
use module "utility_functions.mod"



static
    
    string[10]  :   Serializers[100]
    string[10]  :   Deserializers[100]
    word        :   SerializerRLMS[100]
    word        :   DeserializerRLMS[100]

end_static


procedure DlogCoefficents(DEV_ID, Device, DUT_OR_DNUT, UART_OR_I2C, TestStruct,  Vdd18,  CommentStr, QaFtStr)

--this function datalogs the appropriate RLMS values
--Variables--
--DEV_ID:  The I2C/UART address of the device to read from
--Device:  String with underscore PHY.  Program will figure out which RLMS register to write to from this, and whether it's a GMSL2 or 3 Datalog. USE ALL CAPS!!!
--DUT_OR_DNUT: string which tells the program to either call the pattern on your DP_SDA/DP_SCL pins (DUT) or DP_AUX_SDA/DP_AUX_SCL (DNUT)
--UART_OR_I2C:  string which tells  the program what format to use for reading
--TestStruct: This tells the function which test name in the test tool to datalog under. 
--Vdd18:  This is an input which lets this function know which supply you are running at
--CommentStr: This is an additional comment which will be added to the datalog
--QaFtStr: This allows ability to guardband the coefficients. "QA" will have wide-open limits, anything else will be datalogged to tighter limits. LeviB 10/16/2019


in string[5]   : DUT_OR_DNUT, UART_OR_I2C, QaFtStr
in string[10]   : Device
in_out integer_test  : TestStruct
in float             : Vdd18
in string[16]        : CommentStr
in word              : DEV_ID

local
  multisite word    : RLMS_Read[26]
  multisite word   :  VthSspValue,  VthSs0Value, VthSsnValue, VthSspOffsetValue, VthSs0OffsetValue, VthSsnOffsetValue, VosEsValue 
  multisite integer : Dfe6IValue, LFBIValue, ErrChPhPriIValue, VthSspIValue,  VthSs0IValue, VthSsnIValue, VthSspOffsetIValue, VthSs0OffsetIValue, VthSsnOffsetIValue, VosEsIValue 
  multisite integer : LinkResValue, MarginValue, AgcIValue, OsnIValue, BstIValue, Dfe5IValue, Dfe4IValue, Dfe3IValue, Dfe2IValue, Dfe1IValue
  multisite word: Reg6A, Reg6B, Reg69, Reg68, RegD9, RegDA
  word              : csite, sIdx, sites
  word list[MAX_SITES] : active_sites
  string[8]            : SupplyStr, SER_OR_DES, SioChannel, GMSL2_GMSL3
  string[25]           : pattern_name
  integer: i, TestCnt
  word  :   RLMS_Register

  multisite integer : TuneCapIValue, TuneAmpIValue, NoiseIValue, OffsetCalIValue, LinkErrorIValue

end_local

body
 
  active_sites = get_active_sites()
  sites = word(len(active_sites))
  
  DUT_OR_DNUT = Ucase(DUT_OR_DNUT)
  Device = Ucase(Device)
  UART_OR_I2C = Ucase(UART_OR_I2C)
  

  
  --this is the base number that will be added to the datalog test number for each test, added onto the TestStruct test you passed in
  TestCnt = 40000 
  
  GetSerDesInfo(Device, SER_OR_DES, SioChannel, GMSL2_GMSL3, RLMS_Register)
  
  if DUT_OR_DNUT = "DUT" and UART_OR_I2C = "I2C" then
    pattern_name = "dut_i2c_rlms_read"
  elseif DUT_OR_DNUT = "DUT" and UART_OR_I2C = "UART" then
    pattern_name = "dut_uart_rlms_read"  
  elseif DUT_OR_DNUT = "DNUT" and UART_OR_I2C = "I2C" then
    pattern_name = "dnut_i2c_rlms_read"
  else
    pattern_name = "dnut_uart_rlms_read"
  end_if
  

   RLMS_Read = RlmsRead(DEV_ID,RLMS_Register, pattern_name)
   
   
   for sIdx = 1 to sites do
        csite = active_sites[sIdx]

        AgcIValue[csite] = integer(RLMS_Read[csite, 1])
        BstIValue[csite] = integer(RLMS_Read[csite, 2])
        OsnIValue[csite] = integer(RLMS_Read[csite, 3])
        Dfe1IValue[csite]  = SignedMagnitude(RLMS_Read[csite,4], 6)
        Dfe2IValue[csite]  = SignedMagnitude(RLMS_Read[csite,5], 6)
        Dfe3IValue[csite]  = SignedMagnitude(RLMS_Read[csite,6], 6)
        Dfe4IValue[csite]  = SignedMagnitude(RLMS_Read[csite,7], 6)
        Dfe5IValue[csite]  = SignedMagnitude(RLMS_Read[csite,8], 6)
        Dfe6IValue[csite]  = SignedMagnitude(RLMS_Read[csite,9], 6)
        LFBIValue[csite]  = SignedMagnitude(RLMS_Read[csite,10], 6)
        ErrChPhPriIValue[csite]  = integer(RLMS_Read[csite,11])
        
        VthSspValue[csite] = ((RLMS_Read[csite,15] & 0x1) << 8) | RLMS_Read[csite,12]
        VthSs0Value[csite] = ((RLMS_Read[csite,15] & 0x2) << 7) | RLMS_Read[csite,13]
        VthSsnValue[csite] = ((RLMS_Read[csite,15] & 0x4) << 6) | RLMS_Read[csite,14]  
        VthSspIValue[csite] = SignedMagnitude(VthSspValue[csite], 8)
        VthSs0IValue[csite] = SignedMagnitude(VthSs0Value[csite], 8)
        VthSsnIValue[csite] = SignedMagnitude(VthSsnValue[csite], 8)  
        
        Reg6A[csite] = RLMS_Read[csite,16]
        Reg6B[csite] = RLMS_Read[csite,17]
        Reg69[csite] = RLMS_Read[csite,18]
        Reg68[csite] = RLMS_Read[csite,19]
        RegD9[csite] = RLMS_Read[csite,20]
        RegDA[csite] = RLMS_Read[csite,21]


        -- LeviB: Add additional readbacks per Alexei
        TuneCapIValue[csite] = integer( RLMS_Read[csite,22] & 0x1E)  
        TuneAmpIValue[csite] = integer( RLMS_Read[csite,23] )
        NoiseIValue[csite] = integer( (RLMS_Read[csite,25] & 0xF)*256 + RLMS_Read[csite,26])
        OffsetCalIValue[csite] = integer(RLMS_Read[csite,24] & 0x3F)

        
        RegD9[csite] = ConvertGrayCode(RegD9[csite] & 0xFF)
        
        VthSspOffsetValue[csite] = ((Reg6B[csite] & 2#111) << 6) | ((Reg6A[csite] & 2#11111100) >> 2)
        VthSs0OffsetValue[csite] = ((Reg6A[csite] & 2#11) << 7) | ((Reg69[csite] & 2#11111110) >> 1)
        VthSsnOffsetValue[csite] = ((Reg69[csite] & 2#1) << 8) | ((Reg68[csite] & 2#11111111) >> 0)
        VosEsValue[csite] = ((RegDA[csite] & 2#1) << 8) | ((RegD9[csite] & 2#11111111) >> 0)
        
        VthSspOffsetIValue[csite] = SignedMagnitude(VthSspOffsetValue[csite], 8)
        VthSs0OffsetIValue[csite] = SignedMagnitude(VthSs0OffsetValue[csite], 8)
        VthSsnOffsetIValue[csite] = SignedMagnitude(VthSsnOffsetValue[csite], 8)
        VosEsIValue[csite] = SignedMagnitude(VosEsValue[csite], 8)
    
    end_for
   




  if Vdd18 < 1.75 then
    SupplyStr = "_VMIN"
  elseif Vdd18 < 1.82 then
    SupplyStr = "_VNOM"
  else
    SupplyStr = "_VMAX"
  endif
 
 
  if len(CommentStr) > 0 then
    CommentStr = "_" + CommentStr
  endif
  
  
  -- Datalog GMSL Status and adapter Coefficient values 
  if QaFtStr = "QA" then
      test_value AgcIValue  lo   0 hi 255 test (TestStruct.minor_id + TestCnt + 0000) fail_bin TestStruct.fail_bin comment "AGC_"  + SER_OR_DES + "_" +  SioChannel + "_" + TestStruct.test_text + SupplyStr + CommentStr
      test_value BstIValue  lo   0 hi  40 test (TestStruct.minor_id + TestCnt + 0050) fail_bin TestStruct.fail_bin comment "BST_"  + SER_OR_DES + "_" +  SioChannel + "_" + TestStruct.test_text + SupplyStr + CommentStr  -- max = 0x32 per Alexei S. 2020_02_05
      test_value OsnIValue  lo   0 hi  63 test (TestStruct.minor_id + TestCnt + 0100) fail_bin TestStruct.fail_bin comment "OSN_"  + SER_OR_DES + "_" +  SioChannel + "_" + TestStruct.test_text + SupplyStr + CommentStr
      test_value Dfe1IValue lo -63 hi  63 test (TestStruct.minor_id + TestCnt + 0150) fail_bin TestStruct.fail_bin comment "DFE1_" + SER_OR_DES + "_" +  SioChannel + "_" + TestStruct.test_text + SupplyStr + CommentStr
      test_value Dfe2IValue lo -63 hi  63 test (TestStruct.minor_id + TestCnt + 0200) fail_bin TestStruct.fail_bin comment "DFE2_" + SER_OR_DES + "_" +  SioChannel + "_" + TestStruct.test_text + SupplyStr + CommentStr
      test_value Dfe3IValue lo -63 hi  63 test (TestStruct.minor_id + TestCnt + 0250) fail_bin TestStruct.fail_bin comment "DFE3_" + SER_OR_DES + "_" +  SioChannel + "_" + TestStruct.test_text + SupplyStr + CommentStr

      test_value TuneCapIValue   lo 0 hi 255      test (TestStruct.minor_id + TestCnt + 0300) fail_bin TestStruct.fail_bin comment "TCAP_"       + SER_OR_DES + "_" +  SioChannel + "_" + TestStruct.test_text + SupplyStr + CommentStr
      test_value TuneAmpIValue   lo 0 hi (170+10) test (TestStruct.minor_id + TestCnt + 0350) fail_bin TestStruct.fail_bin comment "TAMP_"       + SER_OR_DES + "_" +  SioChannel + "_" + TestStruct.test_text + SupplyStr + CommentStr
      test_value NoiseIValue     lo 0 hi (512+10) test (TestStruct.minor_id + TestCnt + 0400) fail_bin TestStruct.fail_bin comment "NOISE_"      + SER_OR_DES + "_" +  SioChannel + "_" + TestStruct.test_text + SupplyStr + CommentStr
      test_value OffsetCalIValue lo 0 hi 255      test (TestStruct.minor_id + TestCnt + 0450) fail_bin TestStruct.fail_bin comment "OFFSET_CAL_" + SER_OR_DES + "_" +  SioChannel + "_" + TestStruct.test_text + SupplyStr + CommentStr

  else
      test_value AgcIValue  lo  10 hi 245 test (TestStruct.minor_id + TestCnt + 0000) fail_bin TestStruct.fail_bin comment "AGC_"  + SER_OR_DES + "_" +  SioChannel + "_" + TestStruct.test_text + SupplyStr + CommentStr
-- MODIFIED LIMIT   the limit below has been loosened to prevent excessive fallout at production test.  Un-comment the line below to NOT screen for rejects
--test_value AgcIValue  lo  0 hi 245 test (TestStruct.minor_id + TestCnt + 0000) fail_bin TestStruct.fail_bin comment "AGC_"  + SER_OR_DES + "_" +  SioChannel + "_" + TestStruct.test_text + SupplyStr + CommentStr
      test_value BstIValue  lo   0 hi  32 test (TestStruct.minor_id + TestCnt + 0050) fail_bin TestStruct.fail_bin comment "BST_"  + SER_OR_DES + "_" +  SioChannel + "_" + TestStruct.test_text + SupplyStr + CommentStr
      test_value OsnIValue  lo   0 hi  63 test (TestStruct.minor_id + TestCnt + 0100) fail_bin TestStruct.fail_bin comment "OSN_"  + SER_OR_DES + "_" +  SioChannel + "_" + TestStruct.test_text + SupplyStr + CommentStr
      test_value Dfe1IValue lo -63 hi  63 test (TestStruct.minor_id + TestCnt + 0150) fail_bin TestStruct.fail_bin comment "DFE1_" + SER_OR_DES + "_" +  SioChannel + "_" + TestStruct.test_text + SupplyStr + CommentStr
      test_value Dfe2IValue lo -63 hi  63 test (TestStruct.minor_id + TestCnt + 0200) fail_bin TestStruct.fail_bin comment "DFE2_" + SER_OR_DES + "_" +  SioChannel + "_" + TestStruct.test_text + SupplyStr + CommentStr
      test_value Dfe3IValue lo -63 hi  63 test (TestStruct.minor_id + TestCnt + 0250) fail_bin TestStruct.fail_bin comment "DFE3_" + SER_OR_DES + "_" +  SioChannel + "_" + TestStruct.test_text + SupplyStr + CommentStr

      test_value TuneCapIValue   lo 0 hi 255 test (TestStruct.minor_id + TestCnt + 0300) fail_bin TestStruct.fail_bin comment "TCAP_"       + SER_OR_DES + "_" +  SioChannel + "_" + TestStruct.test_text + SupplyStr + CommentStr
      test_value TuneAmpIValue   lo 0 hi 170 test (TestStruct.minor_id + TestCnt + 0350) fail_bin TestStruct.fail_bin comment "TAMP_"       + SER_OR_DES + "_" +  SioChannel + "_" + TestStruct.test_text + SupplyStr + CommentStr
      test_value NoiseIValue     lo 0 hi 512 test (TestStruct.minor_id + TestCnt + 0400) fail_bin TestStruct.fail_bin comment "NOISE_"      + SER_OR_DES + "_" +  SioChannel + "_" + TestStruct.test_text + SupplyStr + CommentStr
      test_value OffsetCalIValue lo 0 hi 255 test (TestStruct.minor_id + TestCnt + 0450) fail_bin TestStruct.fail_bin comment "OFFSET_CAL_" + SER_OR_DES + "_" +  SioChannel + "_" + TestStruct.test_text + SupplyStr + CommentStr

  endif
  
  if SER_OR_DES = "DES" then
    test_value Dfe4IValue lo -63 hi 63 test (TestStruct.minor_id + TestCnt + 0300) fail_bin TestStruct.fail_bin comment "DFE4_" + SER_OR_DES + "_" +  SioChannel + "_" + TestStruct.test_text + SupplyStr + CommentStr
    test_value Dfe5IValue lo -63 hi 63 test (TestStruct.minor_id + TestCnt + 0350) fail_bin TestStruct.fail_bin comment "DFE5_" + SER_OR_DES + "_" +  SioChannel + "_" + TestStruct.test_text + SupplyStr + CommentStr
  end_if

  if SER_OR_DES = "DES" and GMSL2_GMSL3 = "GMSL3" then
    test_value Dfe6IValue lo -63 hi 63 test (TestStruct.minor_id + TestCnt +  0400) fail_bin TestStruct.fail_bin comment  "DFE6_" + SER_OR_DES + "_" +  SioChannel + "_" + TestStruct.test_text  + SupplyStr + CommentStr
    test_value LFBIValue lo 0 hi 15 test (TestStruct.minor_id + TestCnt +  0450) fail_bin TestStruct.fail_bin comment  "LFB_" + SER_OR_DES + "_" +  SioChannel + "_" + TestStruct.test_text  + SupplyStr + CommentStr
    test_value ErrChPhPriIValue lo 0 hi 127 test (TestStruct.minor_id + TestCnt +  0500) fail_bin TestStruct.fail_bin comment  "ErrChPhPri_" + SER_OR_DES + "_" +  SioChannel + "_" + TestStruct.test_text  + SupplyStr + CommentStr
    test_value VthSspIValue lo -255 hi 255 test (TestStruct.minor_id + TestCnt +  0550) fail_bin TestStruct.fail_bin comment  "VthsSsp_" + SER_OR_DES + "_" +  SioChannel + "_" + TestStruct.test_text  + SupplyStr + CommentStr
    test_value VthSs0IValue lo -255 hi 255 test (TestStruct.minor_id + TestCnt +  0600) fail_bin TestStruct.fail_bin comment  "VthSs0_" + SER_OR_DES + "_" +  SioChannel + "_" + TestStruct.test_text  + SupplyStr + CommentStr
    test_value VthSsnIValue lo -255 hi 255 test (TestStruct.minor_id + TestCnt +  0650) fail_bin TestStruct.fail_bin comment  "VthSsn_" + SER_OR_DES + "_" +  SioChannel + "_" + TestStruct.test_text  + SupplyStr + CommentStr
    test_value VthSspOffsetIValue lo -255 hi 255 test (TestStruct.minor_id + TestCnt +  0700) fail_bin TestStruct.fail_bin comment  "VthSspOffset_" + SER_OR_DES + "_" +  SioChannel + "_" + TestStruct.test_text  + SupplyStr + CommentStr
    test_value VthSs0OffsetIValue lo -255 hi 255 test (TestStruct.minor_id + TestCnt +  0750) fail_bin TestStruct.fail_bin comment  "VthSs0Offset_" + SER_OR_DES + "_" +  SioChannel + "_" + TestStruct.test_text  + SupplyStr + CommentStr
    test_value VthSsnOffsetIValue lo -255 hi 255 test (TestStruct.minor_id + TestCnt +  0800) fail_bin TestStruct.fail_bin comment  "VTHSsnOffset_" + SER_OR_DES + "_" +  SioChannel + "_" + TestStruct.test_text  + SupplyStr + CommentStr
    test_value VosEsIValue lo -255 hi 255 test (TestStruct.minor_id + TestCnt +  0850) fail_bin TestStruct.fail_bin comment  "VOS-ES_" + SER_OR_DES + "_" +  SioChannel + "_" + TestStruct.test_text  + SupplyStr + CommentStr
    
  
  end_if


end_body



procedure XXX_OBSOLETE_DlogCoefficents(DEV_ID, Device, DUT_OR_DNUT, UART_OR_I2C, TestStruct,  Vdd18,  CommentStr)

--this function datalogs the appopriate RLMS values
--Variables--
--DEV_ID:  The I2C/UART address of the device to read from
--Device:  String with underscore PHY.  Program will figure out which RLMS register to write to from this, and whether it's a GMSL2 or 3 Datalog. USE ALL CAPS!!!
--DUT_OR_DNUT: string which tells the program to either call the pattern on your DP_SDA/DP_SCL pins (DUT) or DP_AUX_SDA/DP_AUX_SCL (DNUT)
--UART_OR_I2C:  string which tells  the program what format to use for reading
--TestStruct: This tells the function which test name in the test tool to datalog under. 
--Vdd18:  This is an input which lets this function know which supply you are running at
--CommentStr: This is an additional comment which will be added to the datalog

in string[5]   : DUT_OR_DNUT, UART_OR_I2C
in string[10]   : Device
in_out integer_test  : TestStruct
in float             : Vdd18
in string[16]        : CommentStr
in word              : DEV_ID

local
  multisite word    : RLMS_Read[26]
  multisite word   :  VthSspValue,  VthSs0Value, VthSsnValue, VthSspOffsetValue, VthSs0OffsetValue, VthSsnOffsetValue, VosEsValue 
  multisite integer : Dfe6IValue, LFBIValue, ErrChPhPriIValue, VthSspIValue,  VthSs0IValue, VthSsnIValue, VthSspOffsetIValue, VthSs0OffsetIValue, VthSsnOffsetIValue, VosEsIValue 
  multisite integer : LinkResValue, MarginValue, AgcIValue, OsnIValue, BstIValue, Dfe5IValue, Dfe4IValue, Dfe3IValue, Dfe2IValue, Dfe1IValue
  multisite word: Reg6A, Reg6B, Reg69, Reg68, RegD9, RegDA
  word              : csite, sIdx, sites
  word list[MAX_SITES] : active_sites
  string[8]            : SupplyStr, SER_OR_DES, SioChannel, GMSL2_GMSL3
  string[25]           : pattern_name
  integer: i, TestCnt
  word  :   RLMS_Register
end_local

body
 
  active_sites = get_active_sites()
  sites = word(len(active_sites))
  
  DUT_OR_DNUT = Ucase(DUT_OR_DNUT)
  Device = Ucase(Device)
  UART_OR_I2C = Ucase(UART_OR_I2C)
  

  
  --this is the base number that will be added to the datalog test number for each test, added onto the TestStruct test you passed in
  TestCnt = 40000 
  
  GetSerDesInfo(Device, SER_OR_DES, SioChannel, GMSL2_GMSL3, RLMS_Register)
  
  if DUT_OR_DNUT = "DUT" and UART_OR_I2C = "I2C" then
    pattern_name = "dut_i2c_rlms_read"
  elseif DUT_OR_DNUT = "DUT" and UART_OR_I2C = "UART" then
    pattern_name = "dut_uart_rlms_read"  
  elseif DUT_OR_DNUT = "DNUT" and UART_OR_I2C = "I2C" then
    pattern_name = "dnut_i2c_rlms_read"
  else
    pattern_name = "dnut_uart_rlms_read"
  end_if
  

   RLMS_Read = RlmsRead(DEV_ID,RLMS_Register, pattern_name)
   
   
   for sIdx = 1 to sites do
        csite = active_sites[sIdx]

        AgcIValue[csite] = integer(RLMS_Read[csite, 1])
        BstIValue[csite] = integer(RLMS_Read[csite, 2])
        OsnIValue[csite] = integer(RLMS_Read[csite, 3])
        Dfe1IValue[csite]  = SignedMagnitude(RLMS_Read[csite,4], 6)
        Dfe2IValue[csite]  = SignedMagnitude(RLMS_Read[csite,5], 6)
        Dfe3IValue[csite]  = SignedMagnitude(RLMS_Read[csite,6], 6)
        Dfe4IValue[csite]  = SignedMagnitude(RLMS_Read[csite,7], 6)
        Dfe5IValue[csite]  = SignedMagnitude(RLMS_Read[csite,8], 6)
        Dfe6IValue[csite]  = SignedMagnitude(RLMS_Read[csite,9], 6)
        LFBIValue[csite]  = SignedMagnitude(RLMS_Read[csite,10], 6)
        ErrChPhPriIValue[csite]  = integer(RLMS_Read[csite,11])
        
        VthSspValue[csite] = ((RLMS_Read[csite,15] & 0x1) << 8) | RLMS_Read[csite,12]
        VthSs0Value[csite] = ((RLMS_Read[csite,15] & 0x2) << 7) | RLMS_Read[csite,13]
        VthSsnValue[csite] = ((RLMS_Read[csite,15] & 0x4) << 6) | RLMS_Read[csite,14]  
        VthSspIValue[csite] = SignedMagnitude(VthSspValue[csite], 8)
        VthSs0IValue[csite] = SignedMagnitude(VthSs0Value[csite], 8)
        VthSsnIValue[csite] = SignedMagnitude(VthSsnValue[csite], 8)  
        
        Reg6A[csite] = RLMS_Read[csite,16]
        Reg6B[csite] = RLMS_Read[csite,17]
        Reg69[csite] = RLMS_Read[csite,18]
        Reg68[csite] = RLMS_Read[csite,19]
        RegD9[csite] = RLMS_Read[csite,20]
        RegDA[csite] = RLMS_Read[csite,21]
        
        RegD9[csite] = ConvertGrayCode(RegD9[csite] & 0xFF)
        
        VthSspOffsetValue[csite] = ((Reg6B[csite] & 2#111) << 6) | ((Reg6A[csite] & 2#11111100) >> 2)
        VthSs0OffsetValue[csite] = ((Reg6A[csite] & 2#11) << 7) | ((Reg69[csite] & 2#11111110) >> 1)
        VthSsnOffsetValue[csite] = ((Reg69[csite] & 2#1) << 8) | ((Reg68[csite] & 2#11111111) >> 0)
        VosEsValue[csite] = ((RegDA[csite] & 2#1) << 8) | ((RegD9[csite] & 2#11111111) >> 0)
        
        VthSspOffsetIValue[csite] = SignedMagnitude(VthSspOffsetValue[csite], 8)
        VthSs0OffsetIValue[csite] = SignedMagnitude(VthSs0OffsetValue[csite], 8)
        VthSsnOffsetIValue[csite] = SignedMagnitude(VthSsnOffsetValue[csite], 8)
        VosEsIValue[csite] = SignedMagnitude(VosEsValue[csite], 8)
    
    end_for
   




  if Vdd18 < 1.75 then
    SupplyStr = "_VMIN"
  elseif Vdd18 < 1.82 then
    SupplyStr = "_VNOM"
  else
    SupplyStr = "_VMAX"
  endif
 
 
  if len(CommentStr) > 0 then
    CommentStr = "_" + CommentStr
  endif
  
  
  -- Datalog GMSL Status and adapter Coefficent values 
  test_value AgcIValue lo 0 hi 255 test (TestStruct.minor_id + TestCnt +  0000) fail_bin TestStruct.fail_bin comment  "AGC_" + SER_OR_DES + "_" +  SioChannel + "_" + TestStruct.test_text  + SupplyStr + CommentStr
  test_value BstIValue lo 0 hi 127  test (TestStruct.minor_id + TestCnt + 0050) fail_bin TestStruct.fail_bin comment "BST_" + SER_OR_DES + "_" +  SioChannel + "_" + TestStruct.test_text  + SupplyStr + CommentStr
  test_value OsnIValue lo 0 hi 63 test (TestStruct.minor_id + TestCnt +  0100) fail_bin TestStruct.fail_bin comment "OSN_" + SER_OR_DES + "_" +  SioChannel + "_" + TestStruct.test_text  + SupplyStr + CommentStr
  test_value Dfe1IValue lo -63 hi 63 test (TestStruct.minor_id + TestCnt + 0150) fail_bin TestStruct.fail_bin comment "DFE1_" + SER_OR_DES + "_" +  SioChannel + "_" + TestStruct.test_text  + SupplyStr + CommentStr
  test_value Dfe2IValue lo -63 hi 63 test (TestStruct.minor_id + TestCnt + 0200) fail_bin TestStruct.fail_bin comment "DFE2_" + SER_OR_DES + "_" +  SioChannel + "_" + TestStruct.test_text + SupplyStr + CommentStr
  test_value Dfe3IValue lo -63 hi 63 test (TestStruct.minor_id + TestCnt + 0250) fail_bin TestStruct.fail_bin comment "DFE3_" + SER_OR_DES + "_" +  SioChannel + "_" + TestStruct.test_text + SupplyStr + CommentStr
  
  if SER_OR_DES = "DES" then
    test_value Dfe4IValue lo -63 hi 63 test (TestStruct.minor_id + TestCnt + 0300) fail_bin TestStruct.fail_bin comment "DFE4_" + SER_OR_DES + "_" +  SioChannel + "_" + TestStruct.test_text + SupplyStr + CommentStr
    test_value Dfe5IValue lo -63 hi 63 test (TestStruct.minor_id + TestCnt + 0350) fail_bin TestStruct.fail_bin comment "DFE5_" + SER_OR_DES + "_" +  SioChannel + "_" + TestStruct.test_text + SupplyStr + CommentStr
  end_if

  if SER_OR_DES = "DES" and GMSL2_GMSL3 = "GMSL3" then
    test_value Dfe6IValue lo -63 hi 63 test (TestStruct.minor_id + TestCnt +  0400) fail_bin TestStruct.fail_bin comment  "DFE6_" + SER_OR_DES + "_" +  SioChannel + "_" + TestStruct.test_text  + SupplyStr + CommentStr
    test_value LFBIValue lo 0 hi 15 test (TestStruct.minor_id + TestCnt +  0450) fail_bin TestStruct.fail_bin comment  "LFB_" + SER_OR_DES + "_" +  SioChannel + "_" + TestStruct.test_text  + SupplyStr + CommentStr
    test_value ErrChPhPriIValue lo 0 hi 127 test (TestStruct.minor_id + TestCnt +  0500) fail_bin TestStruct.fail_bin comment  "ErrChPhPri_" + SER_OR_DES + "_" +  SioChannel + "_" + TestStruct.test_text  + SupplyStr + CommentStr
    test_value VthSspIValue lo -255 hi 255 test (TestStruct.minor_id + TestCnt +  0550) fail_bin TestStruct.fail_bin comment  "VthsSsp_" + SER_OR_DES + "_" +  SioChannel + "_" + TestStruct.test_text  + SupplyStr + CommentStr
    test_value VthSs0IValue lo -255 hi 255 test (TestStruct.minor_id + TestCnt +  0600) fail_bin TestStruct.fail_bin comment  "VthSs0_" + SER_OR_DES + "_" +  SioChannel + "_" + TestStruct.test_text  + SupplyStr + CommentStr
    test_value VthSsnIValue lo -255 hi 255 test (TestStruct.minor_id + TestCnt +  0650) fail_bin TestStruct.fail_bin comment  "VthSsn_" + SER_OR_DES + "_" +  SioChannel + "_" + TestStruct.test_text  + SupplyStr + CommentStr
    test_value VthSspOffsetIValue lo -255 hi 255 test (TestStruct.minor_id + TestCnt +  0700) fail_bin TestStruct.fail_bin comment  "VthSspOffset_" + SER_OR_DES + "_" +  SioChannel + "_" + TestStruct.test_text  + SupplyStr + CommentStr
    test_value VthSs0OffsetIValue lo -255 hi 255 test (TestStruct.minor_id + TestCnt +  0750) fail_bin TestStruct.fail_bin comment  "VthSs0Offset_" + SER_OR_DES + "_" +  SioChannel + "_" + TestStruct.test_text  + SupplyStr + CommentStr
    test_value VthSsnOffsetIValue lo -255 hi 255 test (TestStruct.minor_id + TestCnt +  0800) fail_bin TestStruct.fail_bin comment  "VTHSsnOffset_" + SER_OR_DES + "_" +  SioChannel + "_" + TestStruct.test_text  + SupplyStr + CommentStr
    test_value VosEsIValue lo -255 hi 255 test (TestStruct.minor_id + TestCnt +  0850) fail_bin TestStruct.fail_bin comment  "VOS-ES_" + SER_OR_DES + "_" +  SioChannel + "_" + TestStruct.test_text  + SupplyStr + CommentStr
    
  
  end_if


end_body



procedure GetSerDesInfo(Device, SER_OR_DES, SioChannel, GMSL2_GMSL3, RLMS_Register)
--------------------------------------------------------------------------------
-- please use capital letters only



in string[10] : Device
in_out string: SER_OR_DES, SioChannel, GMSL2_GMSL3 
out word    :   RLMS_Register

local

    integer : name_length, devices, count
    string[10]  : Die_Type
end_local

body


    name_length = len(Device)
    
    --first determine if GMSL2 or GMSL3 part
    --this logic assumes that all HSXX products except for the HS96/97 are legacy GMSL2 products
    --even though GMSL3 products support GMSL2 mode, they still have additional registers to check.
    if Device[1:2] = "HS" and Device[3:4] <> "96" and Device[3:4] <> "97" then
        GMSL2_GMSL3 = "GMSL2"
    else
        GMSL2_GMSL3 = "GMSL3"
    end_if


    --now find whether it's a ser or deser using the table in the PopulateDeviceTable procedure
    --this also finds the base RLMS register address (put in same table)
    Die_Type = Device[1:4]
    
    for devices = 1 to 100 by 1 do
        if Die_Type = Serializers[devices] then
            SER_OR_DES = "SER"
            RLMS_Register = SerializerRLMS[devices]
            devices = 200
        else_if Die_Type = Deserializers[devices] then
            SER_OR_DES = "DES"
            RLMS_Register = DeserializerRLMS[devices]
            devices = 300
        end_if
     end_for
     
     --now find PHY
    SioChannel = Device[name_length]
    
    if SioChannel = "A" then
        --do nothing
    else_if SioChannel = "B" then
        RLMS_Register = RLMS_Register + 0x100
    else_if SioChannel = "B" then
        RLMS_Register = RLMS_Register + 0x200
    else_if SioChannel = "B" then
        RLMS_Register = RLMS_Register + 0x300
    end_if

end_body

procedure PopulateDeviceTable
--------------------------------------------------------------------------------
--  update this table as necessary.  the RLMS address is the base address (RLMS0) of PHYA, AKA RLLMS__A_RLMS0
--  Place this function somewhere in your onload so it only runs once

local

end_local

body

--SERIALIZERS

Serializers[1] = "HS97"
SerializerRLMS[1] = 0x1400
Serializers[2] = "HS87"
SerializerRLMS[2] = 0x400
Serializers[3] = "HS95"
SerializerRLMS[3] = 0x400
Serializers[4] = "GM03"
SerializerRLMS[4] = 0x1400
Serializers[5] = "HS89"
SerializerRLMS[5] = 0x1400

--DESERIALIZERS

Deserializers[1] = "HS96"
DeserializerRLMS[1] = 0x1400
Deserializers[2] = "HS88"
DeserializerRLMS[2] = 0x1400
Deserializers[3] = "GM04"
DeserializerRLMS[3] = 0x400
Deserializers[4] = "HS84"
DeserializerRLMS[4] = 0x400
Deserializers[5] = "HS92"
DeserializerRLMS[5] = 0x1400


end_body

function SignedMagnitude(InputData, bits) :    integer
--------------------------------------------------------------------------------
--  Function converts input lword into signed  integer.  
-- Input data  = data where   the MSB is the sign bit
-- bits = # of data bits, NOT bits + sign bit.  IE a 7-bit signed intger should have bits =6

in  word: InputData
in word  : bits

local

    integer   : output_value   
    word   : check_value, mask_value

end_local

body


    
    check_value = 0x1 << bits
    mask_value = 2^bits - 1
    
 
        if (InputData & check_value) >> bits = 1 then
            output_value = integer(InputData & mask_value) * -1
        else
            output_value= integer(InputData & mask_value)    
        end_if



    return(output_value)

end_body


procedure DlogCoefficents_NonPattern(DEV_ID, Device, DUT_OR_DNUT, UART_OR_I2C, TestStruct,  Vdd18,  CommentStr)

--this function datalogs the appopriate RLMS values
--Variables--
--DEV_ID:  The I2C/UART address of the device to read from
--Device:  String with underscore PHY.  Program will figure out which RLMS register to write to from this, and whether it's a GMSL2 or 3 Datalog. USE ALL CAPS!!!
--DUT_OR_DNUT: string which tells the program to either call the pattern on your DP_SDA/DP_SCL pins (DUT) or DP_AUX_SDA/DP_AUX_SCL (DNUT)
--UART_OR_I2C:  string which tells  the program what format to use for reading
--TestStruct: This tells the function which test name in the test tool to datalog under. 
--Vdd18:  This is an input which lets this function know which supply you are running at
--CommentStr: This is an additional comment which will be added to the datalog

in string[5]   : DUT_OR_DNUT, UART_OR_I2C
in string[10]   : Device
in_out integer_test  : TestStruct
in float             : Vdd18
in string[16]        : CommentStr
in word              : DEV_ID

local
  multisite lword   : AgcValue, OsnValue, BstValue, Dfe5Value, Dfe4Value, Dfe3Value, Dfe2Value, Dfe1Value
  multisite lword   : Dfe6Value, LFBValue, ErrChPhPriValue, VthSspValue,  VthSs0Value, VthSsnValue, VthSspOffsetValue, VthSs0OffsetValue, VthSsnOffsetValue, VosEsValue 
  multisite integer : Dfe6IValue, LFBIValue, ErrChPhPriIValue, VthSspIValue,  VthSs0IValue, VthSsnIValue, VthSspOffsetIValue, VthSs0OffsetIValue, VthSsnOffsetIValue, VosEsIValue 
  multisite integer : LinkResValue, MarginValue, AgcIValue, OsnIValue, BstIValue, Dfe5IValue, Dfe4IValue, Dfe3IValue, Dfe2IValue, Dfe1IValue
  multisite lword: Reg6A, Reg6B, Reg69, Reg68, RegD9, RegDA
  word              : csite, sIdx, sites
  word list[MAX_SITES] : active_sites
  string[8]            : SupplyStr, SER_OR_DES, SioChannel, GMSL2_GMSL3
  string[15]           : pattern_string
  integer: i, TestCnt
  word  :   RLMS_Register
end_local

body
 
  active_sites = get_active_sites()
  sites = word(len(active_sites))


  
  --this is the base number that will be added to the datalog test number for each test, added onto the TestStruct test you passed in
  TestCnt = 40000 
  
  GetSerDesInfo(Device, SER_OR_DES, SioChannel, GMSL2_GMSL3, RLMS_Register)

  if SER_OR_DES = "SER" and UART_OR_I2C = "I2C" then
    pattern_string = "dut_i2c_read"
  else_if SER_OR_DES = "SER" and UART_OR_I2C = "UART" then
    pattern_string = "dut_uart_read"
  else_if SER_OR_DES = "DES" and UART_OR_I2C = "I2C" then
    pattern_string = "dnut_i2c_read"
  else
    pattern_string = "dnut_uart_read"
  end_if   
  
  if Vdd18 < 1.75 then
    SupplyStr = "_VMIN"
  elseif Vdd18 < 1.82 then
    SupplyStr = "_VNOM"
  else
    SupplyStr = "_VMAX"
  endif

--************* code to verify pattern works  
  if SER_OR_DES = "DES" then
  
    RegRead(DEV_ID, GM04_RLMS__A_RLMS10, 1, RdWordUpper, AgcValue, pattern_string)  
    AgcIValue = integer(AgcValue)  
    RegRead(DEV_ID, GM04_RLMS__A_RLMS11, 1, RdWordUpper, BstValue, pattern_string)
    BstIValue = integer(BstValue)
    RegRead(DEV_ID, GM04_RLMS__A_RLMS2E, 1, RdWordUpper, OsnValue, pattern_string)
    OsnIValue = integer(OsnValue)
    RegRead(DEV_ID, GM04_RLMS__A_RLMS13, 1, RdWordUpper, Dfe5Value, pattern_string)
    Dfe5IValue = SignedMagnitudeMsite(Dfe5Value, 6)
    RegRead(DEV_ID, GM04_RLMS__A_RLMSC, 1, RdWordUpper,  Dfe4Value, pattern_string)
    Dfe4IValue = SignedMagnitudeMsite(Dfe4Value, 6)
    RegRead(DEV_ID, GM04_RLMS__A_RLMSD, 1, RdWordUpper,  Dfe3Value, pattern_string)
    Dfe3IValue = SignedMagnitudeMsite(Dfe3Value, 6)
    RegRead(DEV_ID, GM04_RLMS__A_RLMSE, 1, RdWordUpper,  Dfe2Value, pattern_string)
    Dfe2IValue = SignedMagnitudeMsite(Dfe2Value, 6)
    RegRead(DEV_ID, GM04_RLMS__A_RLMSF, 1, RdWordUpper,  Dfe1Value, pattern_string)
    Dfe1IValue = SignedMagnitudeMsite(Dfe1Value, 6)
    RegRead(DEV_ID, GM04_RLMS__A_RLMS2C, 1, RdWordUpper, Dfe6Value, pattern_string)
    Dfe6IValue = SignedMagnitudeMsite(Dfe6Value, 6)
    RegRead(DEV_ID, GM04_RLMS__A_RLMS2D, 1, RdWordUpper, LFBValue, pattern_string)
    LFBIValue = integer(LFBValue)
    RegRead(DEV_ID, GM04_RLMS__A_RLMSEB, 1, RdWordUpper, ErrChPhPriValue, pattern_string)
    ErrChPhPriIValue = integer(ErrChPhPriValue)
    RegRead(DEV_ID, GM04_RLMS__A_RLMSF4, 1, RdWordUpper, VthSspValue, pattern_string)
    RegRead(DEV_ID, GM04_RLMS__A_RLMSF5, 1, RdWordUpper, VthSs0Value, pattern_string)
    RegRead(DEV_ID, GM04_RLMS__A_RLMSF6, 1, RdWordUpper, VthSsnValue, pattern_string)
    RegRead(DEV_ID, GM04_RLMS__A_RLMSF7, 1, RdWordUpper, RdWordLower, pattern_string)
    
    for sIdx = 1 to sites do
        csite = active_sites[sIdx]
        VthSspValue[csite] = ((RdWordLower[csite] & 0x1) << 8) | VthSspValue[csite]
        VthSs0Value[csite] = ((RdWordLower[csite] & 0x2) << 7) | VthSs0Value[csite]
        VthSsnValue[csite] = ((RdWordLower[csite] & 0x4) << 6) | VthSsnValue[csite]    
    end_for
    
    VthSspIValue = SignedMagnitudeMsite(VthSspValue, 8)
    VthSs0IValue = SignedMagnitudeMsite(VthSs0Value, 8)
    VthSsnIValue = SignedMagnitudeMsite(VthSsnValue, 8)
    
    RegRead(DEV_ID, GM04_RLMS__A_RLMS6B, 1, RdWordUpper, Reg6B, pattern_string)
    RegRead(DEV_ID, GM04_RLMS__A_RLMS68, 1, RdWordUpper, Reg68, pattern_string)
    RegRead(DEV_ID, GM04_RLMS__A_RLMS6A, 1, RdWordUpper, Reg6A, pattern_string)
    RegRead(DEV_ID, GM04_RLMS__A_RLMS69, 1, RdWordUpper, Reg69, pattern_string)
    RegRead(DEV_ID, GM04_RLMS__A_RLMSD9, 1, RdWordUpper, RegD9, pattern_string)
    RegRead(DEV_ID, GM04_RLMS__A_RLMSDA, 1, RdWordUpper, RegDA, pattern_string)
    
    RegD9 = ConvertGrayCodeMsite(RegD9 & 0xFF)
    
    for sIdx = 1 to sites do
        csite = active_sites[sIdx]
        VthSspOffsetValue[csite] = ((Reg6B[csite] & 2#111) << 6) | ((Reg6A[csite] & 2#11111100) >> 2)
        VthSs0OffsetValue[csite] = ((Reg6A[csite] & 2#11) << 7) | ((Reg69[csite] & 2#11111110) >> 1)
        VthSsnOffsetValue[csite] = ((Reg69[csite] & 2#1) << 8) | ((Reg68[csite] & 2#11111111) >> 0)
        VosEsValue[csite] = ((RegDA[csite] & 2#1) << 8) | ((RegD9[csite] & 2#11111111) >> 0)
    end_for
    
    VthSspOffsetIValue = SignedMagnitudeMsite(VthSspOffsetValue, 8)
    VthSs0OffsetIValue = SignedMagnitudeMsite(VthSs0OffsetValue, 8)
    VthSsnOffsetIValue = SignedMagnitudeMsite(VthSsnOffsetValue, 8)
    VosEsIValue = SignedMagnitudeMsite(VosEsValue, 8)
    
    
    
    
    
    
  else
    RegRead(DEV_ID, GM03_RLMS__A_RLMS10, 1, RdWordUpper, AgcValue, pattern_string)    
    RegRead(DEV_ID, GM03_RLMS__A_RLMS11, 1, RdWordUpper, BstValue, pattern_string)
    RegRead(DEV_ID, GM03_RLMS__A_RLMS2E, 1, RdWordUpper, OsnValue, pattern_string)
    RegRead(DEV_ID, GM03_RLMS__A_RLMSD, 1, RdWordUpper,  Dfe3Value, pattern_string)
    RegRead(DEV_ID, GM03_RLMS__A_RLMSE, 1, RdWordUpper,  Dfe2Value, pattern_string)
    RegRead(DEV_ID, GM03_RLMS__A_RLMSF, 1, RdWordUpper,  Dfe1Value, pattern_string)
    AgcIValue = integer(AgcValue)  
    BstIValue = integer(BstValue)
    OsnIValue = integer(OsnValue)
    Dfe1IValue = SignedMagnitudeMsite(Dfe1Value, 6)
    Dfe3IValue = SignedMagnitudeMsite(Dfe3Value, 6)
    Dfe2IValue = SignedMagnitudeMsite(Dfe2Value, 6)
    
  end_if
  
 
  if len(CommentStr) > 0 then
    CommentStr = "_" + CommentStr
  endif
  
  
  -- Datalog GMSL Status and adapter Coefficent values 
  test_value AgcIValue lo 0 hi 255 test (TestStruct.minor_id + TestCnt +  0000) fail_bin TestStruct.fail_bin comment  "AGC_" + SER_OR_DES + "_" +  SioChannel + "_" + TestStruct.test_text  + SupplyStr + CommentStr
  test_value BstIValue lo 0 hi 127  test (TestStruct.minor_id + TestCnt + 0001) fail_bin TestStruct.fail_bin comment "BST_" + SER_OR_DES + "_" +  SioChannel + "_" + TestStruct.test_text  + SupplyStr + CommentStr
  test_value OsnIValue lo 0 hi 63 test (TestStruct.minor_id + TestCnt +  0002) fail_bin TestStruct.fail_bin comment "OSN_" + SER_OR_DES + "_" +  SioChannel + "_" + TestStruct.test_text  + SupplyStr + CommentStr
  test_value Dfe1IValue lo -63 hi 63 test (TestStruct.minor_id + TestCnt + 0003) fail_bin TestStruct.fail_bin comment "DFE1_" + SER_OR_DES + "_" +  SioChannel + "_" + TestStruct.test_text  + SupplyStr + CommentStr
  test_value Dfe2IValue lo -63 hi 63 test (TestStruct.minor_id + TestCnt + 0004) fail_bin TestStruct.fail_bin comment "DFE2_" + SER_OR_DES + "_" +  SioChannel + "_" + TestStruct.test_text + SupplyStr + CommentStr
  test_value Dfe3IValue lo -63 hi 63 test (TestStruct.minor_id + TestCnt + 0005) fail_bin TestStruct.fail_bin comment "DFE3_" + SER_OR_DES + "_" +  SioChannel + "_" + TestStruct.test_text + SupplyStr + CommentStr
  
  if SER_OR_DES = "DES" then
    test_value Dfe4IValue lo -63 hi 63 test (TestStruct.minor_id + TestCnt + 0006) fail_bin TestStruct.fail_bin comment "DFE4_" + SER_OR_DES + "_" +  SioChannel + "_" + TestStruct.test_text + SupplyStr + CommentStr
    test_value Dfe5IValue lo -63 hi 63 test (TestStruct.minor_id + TestCnt + 0007) fail_bin TestStruct.fail_bin comment "DFE5_" + SER_OR_DES + "_" +  SioChannel + "_" + TestStruct.test_text + SupplyStr + CommentStr
  end_if

  if SER_OR_DES = "DES" and GMSL2_GMSL3 = "GMSL3" then
    test_value Dfe6IValue lo -63 hi 63 test (TestStruct.minor_id + TestCnt +  0008) fail_bin TestStruct.fail_bin comment  "DFE6_" + SER_OR_DES + "_" +  SioChannel + "_" + TestStruct.test_text  + SupplyStr + CommentStr
    test_value LFBIValue lo 0 hi 15 test (TestStruct.minor_id + TestCnt +  0008) fail_bin TestStruct.fail_bin comment  "LFB_" + SER_OR_DES + "_" +  SioChannel + "_" + TestStruct.test_text  + SupplyStr + CommentStr
    test_value ErrChPhPriIValue lo 0 hi 127 test (TestStruct.minor_id + TestCnt +  0008) fail_bin TestStruct.fail_bin comment  "ErrChPhPri_" + SER_OR_DES + "_" +  SioChannel + "_" + TestStruct.test_text  + SupplyStr + CommentStr
    test_value VthSspIValue lo -255 hi 255 test (TestStruct.minor_id + TestCnt +  0008) fail_bin TestStruct.fail_bin comment  "VthsSsp_" + SER_OR_DES + "_" +  SioChannel + "_" + TestStruct.test_text  + SupplyStr + CommentStr
    test_value VthSs0IValue lo -255 hi 255 test (TestStruct.minor_id + TestCnt +  0008) fail_bin TestStruct.fail_bin comment  "VthSs0_" + SER_OR_DES + "_" +  SioChannel + "_" + TestStruct.test_text  + SupplyStr + CommentStr
    test_value VthSsnIValue lo -255 hi 255 test (TestStruct.minor_id + TestCnt +  0008) fail_bin TestStruct.fail_bin comment  "VthSsn_" + SER_OR_DES + "_" +  SioChannel + "_" + TestStruct.test_text  + SupplyStr + CommentStr
    test_value VthSspOffsetIValue lo -255 hi 255 test (TestStruct.minor_id + TestCnt +  0008) fail_bin TestStruct.fail_bin comment  "VthSspOffset_" + SER_OR_DES + "_" +  SioChannel + "_" + TestStruct.test_text  + SupplyStr + CommentStr
    test_value VthSs0OffsetIValue lo -255 hi 255 test (TestStruct.minor_id + TestCnt +  0008) fail_bin TestStruct.fail_bin comment  "VthSs0Offset_" + SER_OR_DES + "_" +  SioChannel + "_" + TestStruct.test_text  + SupplyStr + CommentStr
    test_value VthSsnOffsetIValue lo -255 hi 255 test (TestStruct.minor_id + TestCnt +  0008) fail_bin TestStruct.fail_bin comment  "VTHSsnOffset_" + SER_OR_DES + "_" +  SioChannel + "_" + TestStruct.test_text  + SupplyStr + CommentStr
    test_value VosEsIValue lo -255 hi 255 test (TestStruct.minor_id + TestCnt +  0008) fail_bin TestStruct.fail_bin comment  "VOS-ES_" + SER_OR_DES + "_" +  SioChannel + "_" + TestStruct.test_text  + SupplyStr + CommentStr
    
  
  end_if


end_body

function RlmsRead( DevId , RLMS_Register, PatternName ) : multisite word[26]
--------------------------------------------------------------------------------
--
in word                   : DevId
in string[50]             : PatternName   -- pattern to run
in word                  : RLMS_Register

local
    
   multisite word        : RLMS_Output [rlms_bytes]
   word list[MAX_SITES]   : active_sites_local
   word                   : site , siteidx, idx, sites_local, csite, reg_msb, reg_lsb[26], lsb_count, ByteOffset
   word                   : send_word[200]   -- change to lword for dsp_send
   multisite word         : cap_data[32*26+50]   --- ,  cap_data[32*21+50]
   multisite word         : reg_read[(rlms_bytes)+1]
   string[30]             : cap_waveform    -- regsend capture waveform
   string[8]              : response
   word                   : byte_count, data_bit
   multisite lword : fail_count_lw
   multisite float : return_float
   multisite boolean      : pattern_fail
end_local

const
    rlms_bytes = 26
end_const

body

   active_sites_local = get_active_sites()
   sites_local = word(len(active_sites_local))
   
   --setup reg_lsb numbers
   reg_lsb[1] = 0x10
   reg_lsb[2] = 0x11
   reg_lsb[3] = 0x2E
   reg_lsb[4] = 0x0F
   reg_lsb[5] = 0x0E
   reg_lsb[6] = 0x0D
   reg_lsb[7] = 0x0C
   reg_lsb[8] = 0x13
   reg_lsb[9] = 0x2C
   reg_lsb[10] = 0x2D
   reg_lsb[11] = 0xEB
   reg_lsb[12] = 0xF4
   reg_lsb[13] = 0xF5
   reg_lsb[14] = 0xF6
   reg_lsb[15] = 0xF7
   reg_lsb[16] = 0x6A
   reg_lsb[17] = 0x6B
   reg_lsb[18] = 0x69
   reg_lsb[19] = 0x68
   reg_lsb[20] = 0xD9
   reg_lsb[21] = 0xDA

   -- LeviB: Add additional readbacks per Alexei   
   reg_lsb[22] = 0x88
   reg_lsb[23] = 0x89
   reg_lsb[24] = 0x8A
   reg_lsb[25] = 0xA3
   reg_lsb[26] = 0xA2
   
 
 
  if pos("uart", PatternName) > 1 then
  
    
    reg_msb = ((RLMS_Register & 16#FF00) >> 8)
    lsb_count = 1
    for byte_count = 1 to (rlms_bytes*5) by 5 do 
        send_word[byte_count] = 2#1_01111001   --synch frame 0x79h, with parity bit as MSB
        send_word[byte_count+1] = add_parity_bit(DevId+1)
        send_word[byte_count+2] = add_parity_bit(reg_msb)
        send_word[byte_count+3] = add_parity_bit(reg_lsb[lsb_count])
        lsb_count = lsb_count+1
        send_word[byte_count+4] = add_parity_bit(1)
    end_for 
    --the next byte written is hardcoded RLMS address in the pattern

    if PatternName = "dut_uart_rlms_read" then
      cap_waveform = "DUT_UART_RLMS_WRITE_CAPTURE"
      load     digital reg_send fx1 waveform "DUT_UART_RLMS_WRITE" with send_word
      enable   digital reg_send fx1 waveform "DUT_UART_RLMS_WRITE"
      enable   digital capture  fx1 waveform cap_waveform
    else_if PatternName = "dnut_uart_rlms_read" then
      cap_waveform = "DNUT_UART_RLMS_WRITE_CAPTURE" 
      load     digital reg_send fx1 waveform "DNUT_UART_RLMS_WRITE" with send_word
      enable   digital reg_send fx1 waveform "DNUT_UART_RLMS_WRITE"
      enable   digital capture  fx1 waveform cap_waveform
    end_if

    execute  digital pattern  PatternName  run to end wait
    wait for digital capture  fx1 waveform cap_waveform
    read     digital capture  fx1 waveform cap_waveform into cap_data


    --- Process the data read back ------
    for siteidx=1 to sites_local do
      csite = active_sites_local[siteidx]
      byte_count = 1
      for data_bit = 1 to 11 do
        reg_read[csite] = Analyze_Read_M(cap_data[csite, byte_count:byte_count+31], 1)
        RLMS_Output[csite, data_bit] = reg_read[csite, 1]
        byte_count = byte_count + 32
      end_for
      --due to some shifting, need to make this  start point bigger
      byte_count = 359
      for data_bit = 12 to rlms_bytes do
            reg_read[csite] = Analyze_Read_M(cap_data[csite, byte_count:byte_count+31], 1)
            RLMS_Output[csite, data_bit] = reg_read[csite, 1]
            byte_count = byte_count + 32
      end_for
    end_for
  else     -- Access Type is I2C

    
    reg_msb = ((RLMS_Register & 16#FF00) >> 8)
    lsb_count = 1
    for byte_count = 1 to (rlms_bytes*4) by 4 do
        send_word[byte_count] = DevId
        send_word[byte_count+1] = reg_msb
        send_word[byte_count+2] = reg_lsb[lsb_count]
        send_word[byte_count+3] = DevId + 1
        lsb_count = lsb_count+1
    end_for



    if   pos("dnut_", PatternName) == 1 then
      ------------------------------------------------------------
      set digital pin DNUT_SDA modes to driver on comparator enable all fails load normal
      ------------------------------------------------------------
      load   digital reg_send fx1 waveform "DNUT_I2C_RLMS_WRITE" with send_word
      enable digital reg_send fx1 waveform "DNUT_I2C_RLMS_WRITE"
      enable digital capture  fx1 waveform "DNUT_I2C_RLMS_READ" 
      execute  digital pattern  PatternName   run to end wait
      wait for digital capture  fx1 waveform "DNUT_I2C_RLMS_READ" 
      read  digital capture  fx1 waveform "DNUT_I2C_RLMS_READ" into RLMS_Output
      -- Convert site long word to site boolean
      for siteidx = 1 to sites_local do
          site = active_sites_local[siteidx]
      return_float [ site ] = float ( fail_count_lw [ site ] )
    end_for
    elseif pos("dut_", PatternName) == 1 then
      load   digital reg_send fx1 waveform "DUT_I2C_RLMS_WRITE" with send_word
      enable digital reg_send fx1 waveform "DUT_I2C_RLMS_WRITE"
      enable digital capture  fx1 waveform "DUT_I2C_RLMS_READ" 
      execute  digital pattern  PatternName  run to end wait  into pattern_fail
      wait for digital capture  fx1 waveform "DUT_I2C_RLMS_READ" 
      read  digital capture  fx1 waveform "DUT_I2C_RLMS_READ" into RLMS_Output
   endif

end_if

  return ( RLMS_Output)
end_body

function SignedMagnitudeMsite(InputData, bits) :   multisite integer
--------------------------------------------------------------------------------
--  Function converts input lword into signed  integer.  
-- Input data  = data where   the MSB is the sign bit
-- bits = # of data bits, NOT bits + sign bit.  IE a 7-bit signed intger should have bits =6

in multisite lword: InputData
in lword  : bits

local

    multisite integer   : output_value
    word              : csite, sIdx, sites
    word list[MAX_SITES] : active_sites    
    lword   : check_value, mask_value

end_local

body

    active_sites = get_active_sites()
    sites = word(len(active_sites))
    
    check_value = 0x1 << bits
    mask_value = 2^bits - 1
    
    for sIdx = 1 to sites do
        csite = active_sites[sIdx]  
        if (InputData[csite] & check_value) >> bits = 1 then
            output_value[csite] = integer(InputData[csite] & mask_value) * -1
        else
            output_value[csite] = integer(InputData[csite] & mask_value)    
        end_if
    end_for


    return(output_value)

end_body

function Ucase_Delme (UsrStr) :   string[132]
  in string[132]: UsrStr

local
  string[132]: UcaseStr
  integer    : Sidx, StrLen
end_local

body
  StrLen = len(UsrStr)
  for Sidx = 1 to StrLen do
    if asc(UsrStr[Sidx]) > 96 and asc(UsrStr[Sidx]) < 123 then
      UcaseStr = UcaseStr + chr(asc(UsrStr[Sidx]) - 32)
    else
      UcaseStr = UcaseStr + UsrStr[Sidx]
    endif
  endfor

  return(UcaseStr)
end_body

