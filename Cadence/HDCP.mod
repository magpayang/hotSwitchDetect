use module "./SERDES_Pins.mod"
use module "./user_globals.mod"
use module "./reg_access.mod"
use module "./lib/lib_common.mod"
use module "./general_calls.mod"

global
  multisite boolean   : fetched_HDCP_key
  multisite integer   : HDCP_key_server_code
  multisite lword     : keyID
  multisite float     : key_time
end_global

static

  integer             : dalWrapperObjectHandle = -1
  boolean             : c_library_is_open   = FALSE
  boolean             : Key_Pool_Refreshed  = FALSE 
  lword               : numKeys = 1         -- number of keys in key pool, set to 1 for single site
  string[10]          : Key_Type = "DES_PRX01"  -- Type of key to get. 
                                 -- "PRX01" for Receiver (Deserializer) "Test" key
                                 -- "PTX01" for Transmitter (Serializer) "Test" key
				 -- "DES_PRX01" for Receiver (Deserializer) "Real" key
                                 -- "SER_PTX01" for Transmitter (Serializer) "Real" key
				 
  string[80] : CLib_Path  = "/home/ltx/software/engtools/GHS/dalWrapper/dalWrapperLib.so"  -- dalWrapper Library path


end_static

  global lword      : CrcTable[256]
  global boolean    : NeedDoubleProgram  = true






procedure OTP_TRIM_SERIAL_NUMB_REV2(vdd, vdd18, vio, vterm, start_serial_number, OTP_FAIL, OTP_DONE, TRIM_FAIL_COUNT,FIRST_FAIL_LOC )
--------------------------------------------------------------------------------
--  
in float            : vdd, vdd18, vio, vterm
--in string[20]       : KEY_TYPE1, KEY_TYPE2  , KEY_TYPE3     -- SER_PTX01 (Tx), DES_PRX01 (Rx)
in lword            : start_serial_number  --start serial number

in_out integer_test : TRIM_FAIL_COUNT,FIRST_FAIL_LOC
in_out float_test   : OTP_FAIL, OTP_DONE

-- in_out float_test   : key_time_ft
-- in_out integer_test : wrong_device_it, HDMI_1X_PGM, GMSL_1X_PGM,GMSL_1X_FAIL_LOC,HDMI_1X_FAIL_LOC,GMSL_1X_LOCK,HDMI_1X_LOCK

local

-----This function only use to trim serialized number for Characterized and Qual
word list[16]       : OTP_active_sites, LOCAL_ACTIVE_SITE
lword               : addr, bit
word                : logical_addr
integer             : idx,q
word                : siteidx, thissite
multisite integer   : soak_flag
integer             : NEED_PROGRAM = 0
integer             : output_file
--multisite lword     : otp_write_data_gmsl1X[130],otp_write_data_hdmi1X[130],otp_write_data_hdmi2X[900]
multisite lword     : otp_data
multisite lword     : reg_data
multisite integer   : regvalue
multisite lword     : tempdata
multisite lword     : otp_read_data[512]
multisite lword     : otp_fail_data[512]
multisite lword     : otp_expected_data
multisite boolean   : otp_fail
multisite boolean   : ALREADY_PROGRAMMED
multisite lword     : soak_data
multisite lword     : comp_data

multisite boolean   :  DEV_FAILED
lword               :  NUM_OF_KEYS = 0
word list[4]        :  key_failure_sites = <::>
string[6]           :  OTP_TEMP = "HOT"

-- multisite integer   :  wrong_device
multisite lword     : data1,data2,otp_add
multisite float     : pgm_done_bit[1],pgm_fail_bit[1]
boolean             : need_delay
word                : sites, fail_count
multisite lword     : reg_data_gmsl

integer             : hour,minute,second,year,month,day, number_site_trim, array_index
lword               : burned_date,burned_time
multisite boolean   : need_program
multisite lword     : serial_number,readback_data[712]
word                : local_sites
multisite integer     : date1,date2,date3,time1,time2,time3,device_no_1,device_no_2,device_no_3,device_no_4,device_no_5,device_no_6,device_no_7,device_no_8,device_no_9,device_no_10
lword               : trim_fail_count, first_fail_loc

end_local

body


  otp_fail = FALSE
 
  current_active_sites = get_active_sites()
  OTP_active_sites = get_active_sites()
  sites = word(len(current_active_sites))



------------ Power Up HS87 -----------------------
  DutPowerUp(vio, vdd18, vdd, vterm, 0MHz,"UART", "TP",TRUE)  

  ------------ Set Pin Levels ----------------------

  
---Disconnect digital pin ADD1 and ADD2  from DCL and connect to PPMU for measure GPIO15,GPIO14( OTP_PGM_DONE, OTP_PGM_FAIL)
--      disconnect digital pin DES_GPIO0_MS_SCLK + DES_GPIO1_LOCK_SS2_RO from dcl
--     connect digital pin DES_GPIO0_MS_SCLK + DES_GPIO1_LOCK_SS2_RO to ppmu
--     connect digital ppmu DES_GPIO0_MS_SCLK + DES_GPIO1_LOCK_SS2_RO to fi 0ua imax 1ua measure v max 2.5v clamps to  vmin -0.1v vmax 3.0v
--     measure digital ppmu DES_GPIO0_MS_SCLK voltage vmax 3.0v average 20 delay 10us into pgm_done_bit
--     measure digital ppmu DES_GPIO1_LOCK_SS2_RO voltage vmax 3.0v average 20 delay 10us into pgm_fail_bit


-- ---OTP read memory at location 15 if it has data mean part already trimmed
   reg_data = OTP_Reg_Read(DES_ID, 16#0100, 1)
   OTP_Reg_Write(DES_ID, 16#1800,1, mlw(0x40), 0, mlw(0))---enable read
   otp_add = 1*32
   OTP_Reg_Write(DES_ID, 16#1802,2, otp_add, 0, mlw(0))---set address to read from
   reg_data = OTP_Reg_Read(DES_ID, 16#1814, 4)

  -- Determine which sites have already been OTP'ed

  for siteidx=1 to sites do
     thissite = current_active_sites[siteidx]
---Since there is problem with trim for revision1, If data readback from add 0 is not 0 then part already trim
    if (reg_data[thissite] = 0x00) then  
        need_program[thissite] = TRUE
        number_site_trim = number_site_trim + 1
    end_if     
 end_for
-----Now findout which site need trim and which one is not
    if number_site_trim > 0 then ---- do the trim( at least 1 site need trim)
    
 --        for siteidx = 1 to sites do
--             thissite = current_active_sites[siteidx]   
--             if  need_program[thissite] then
--                 serial_number[thissite] = Device_Number
--                 Device_Number = Device_Number + 1   ---- increase by 1
--             else 
--                 deactivate site thissite            
--             end_if 
--         
--         end_for

---total sites 

        LOCAL_ACTIVE_SITE = get_active_sites()
        local_sites =   word(len(LOCAL_ACTIVE_SITE))
 -----
        OTP_Reg_Write(DES_ID, 16#1800,1, mlw(0x00), 0,mlw(0))---disable read
        OTP_Reg_Write(DES_ID, 16#1801,1, mlw(0x02), 0, mlw(0))---enable  OTP_PGM_DONE and OTP_PGM_FAIL to GPIO15  and GPIO14  and select GMSL section
---OTP Write 
        OTP_Reg_Write(DES_ID, 16#1800,1, mlw(0x20), 0, mlw(0))---enable write 
 
    set digital pin DES_GPIO0_MS_SCLK + DES_GPIO1_LOCK_SS2_RO modes to driver pattern comparator enable all fails
       for addr = 0 to 511 do     
            otp_data = addr ---- program addr to mem loc
            otp_add = addr * 32
            if addr = 0x81 then
                otp_data = 0x30F
            end_if    
            
            
--         disconnect digital pin DES_GPIO0_MS_SCLK on site 1 from dcl
 
        set digital pin  DES_GPIO0_MS_SCLK + DES_GPIO1_LOCK_SS2_RO levels to vih 0.9*vio vil 0.1*vio vol 0.5*vio voh 0.5*vio iol 0mA ioh 0mA vref 0V
        set digital pin  DES_GPIO0_MS_SCLK  on site 2 driver low 
        OTP_Reg_Write_Matchloop(DES_ID, 16#1802,2, otp_add, 4, otp_data )---Write data to address

wait(0)

--           OTP_Reg_Write(DES_ID, 16#1802,2, otp_add, 4, otp_data )---Write data to address
----Use program done and fail to check for otp done
--            measure digital ppmu DES_GPIO0_MS_SCLK voltage vmax 3.0v average 20 delay 10us into pgm_done_bit
--            measure digital ppmu DES_GPIO1_LOCK_SS2_RO voltage vmax 3.0v average 20 delay 10us into pgm_fail_bit
--             if   pgm_done_bit[2,1] > vio/2.0  then---done
--  
--                  measure digital ppmu DES_GPIO1_LOCK_SS2_RO voltage vmax 3.0v average 20 delay 10us into pgm_fail_bit
--  
--             else           
--                  wait(10ms)--- There is problem with pass 1 design can not use OTP_FAIL_BIT and OTP_DONE_BIT to check when memory burn is done. Use 10ms for default. It should be long enough
--                  measure digital ppmu DES_GPIO1_LOCK_SS2_RO voltage vmax 3.0v average 20 delay 10us into pgm_fail_bit
--             end_if
--             if pgm_fail_bit[2] > 1.0V then
--             
--                 wait(0)
--             end_if
           
       end_for 
   end_if 
----------Finish burnning

----Activate all the sites back
    activate site OTP_active_sites
    sites = word(len(current_active_sites))

---verify what opt memory contain make sure it match with write in data.
---OTP read memory----
       OTP_Reg_Write(DES_ID, 16#1800,1, mlw(0x00), 0, mlw(0x00))---disable program
       OTP_Reg_Write(DES_ID, 16#1800,1, mlw(0x40), 0, mlw(0x00))---enable read
       fail_count =0 ---reset fail_count variable 

Set_DES_Voltages(1.7, vdd18, vdd, vterm)

       for  addr = 0 to  511 do        
            otp_add =  32*(addr)	   
            OTP_Reg_Write(DES_ID, 16#1802,2, otp_add, 0,mlw(0x00) )---set address to read from
           array_index = array_index + 1 
            reg_data = OTP_Reg_Read(DES_ID, 16#1814, 4)
            for siteidx = 1 to sites do  
                thissite =OTP_active_sites [siteidx]    
                readback_data[thissite,array_index] = reg_data[thissite]
            end_for    
            if addr = 0x81 then
               if reg_data <> 0xFF0F then----x20 then
                 trim_fail_count = trim_fail_count + 1
               end_if  
            else 
                if reg_data <> (addr)  then
                    trim_fail_count = trim_fail_count + 1
                end_if
            end_if     
        end_for
wait(0)

----Turn off for now
-- ----------Change to OTP lock for GMSL
--             OTP_Reg_Write(DES_ID, 16#1800,1, mlw(0x00), 0, mlw(0x00))---disable read WRITE
--             OTP_Reg_Write(DES_ID, 16#1801,1, mlw(0x02), 0, mlw(0x00))---Select GMSL OTP 
--             OTP_Reg_Write(DES_ID, 16#1800,1, mlw(0x10), 0, mlw(0x00))---Set LOCK OTP
--             wait(20uS)
--             reg_data_gmsl = OTP_Reg_Read(DES_ID, 16#1808, 1)

-------- 
   activate site current_active_sites

---------------- Power Off -------------------
--  set digital pin SER_ALL_PINS levels to vil 0V vih 100mV vol 400mV voh 1V iol 0uA ioh 0uA vref 0V
  disconnect digital pin DES_GPIO0_MS_SCLK + DES_GPIO1_LOCK_SS2_RO from ppmu
  connect digital pin DES_GPIO0_MS_SCLK + DES_GPIO1_LOCK_SS2_RO to dcl
  wait(200us)
  DutPowerDown
 


-----data log
  test_value pgm_fail_bit with OTP_FAIL
  test_value pgm_done_bit with OTP_DONE
--  test_value integer(trim_fail_count) with TRIM_FAIL_COUNT
if trim_fail_count > 0 then
    test_value integer(first_fail_loc) with FIRST_FAIL_LOC
end_if



end_body
procedure DAL_Populate_Key_Pool(nkeys, otp_temp, keytype)
--------------------------------------------------------------------------------
-- This procedure obtains keys and stores them in the "pool"

in lword              : nkeys     -- number of keys to request
in string[6]          : otp_temp  -- Temperature at which HDCP key is to be trimmed.
in string[10]         : keytype   -- (SER_PTX01 or DES_PRX01)

local integer         : status
local string[4]       : TestType
local string[6]       : TestTemp


body

  -- Populate key pool if HDCP was used
  --if(fetched_HDCP_key) then 
  --   status = call_c_library("dalPopulatePool_wrapper", Key_Type, numKeys)
  --   Key_Pool_Refreshed = TRUE
  --end_if
  
  get_expr("OpVar_TestType", TestType)  -- determine test type, QA or FT
  get_expr("OpVar_TestTemp", TestTemp)  -- determine test temperature, (ROOM, HOT, COLD)
  
  Key_Type = keytype
  
  if TestType == "FT" AND TestTemp == otp_temp then
     numKeys = nkeys
     start_timer
     status = call_c_library("dalPopulatePool_wrapper", Key_Type, numKeys)
     key_time = stop_timer
  end_if


end_body


procedure DAL_wrapper_cleanup(OTP_Fail_Bin)
--------------------------------------------------------------------------------
--  This function is called on OnPowerDown
--  This function sends log information back to key server

in integer :  OTP_Fail_Bin



local

  integer      : status
  integer      : dks_disposition
  integer      : curr_bin[MAX_SITES]
  string[250]  : buffer[MAX_SITES]
  string[20]   : DeviceName
  string[20]   : LotNum
  integer      : time_h, time_m, time_s
  integer      : date_m, date_d, date_y
  string[20]   : current_time, current_date
  integer      : siteidx

end_local

body

-- clean up

 -- execute the following only if key was requested

   for siteidx =1 to MAX_SITES do
       if(fetched_HDCP_key[siteidx]) then
          curr_bin = get_swbins
      
          get_expr("TestProgData.LotId", LotNum)       -- get Lot Number information
          get_expr("TestProgData.Device", DeviceName)  -- get Product information
      
          time(time_h, time_m, time_s)     -- get time
          date(date_m, date_d, date_y)     -- get date
      
          current_time = sprint(time_h!z:2,":",time_m!z:2,":",time_s!z:2)   -- format the time
          current_date = sprint(date_m!z:2,"/",date_d!z:2,"/",date_y:4)     -- format the date
      
      
          buffer[siteidx] = current_date + "   " + current_time + "   "
      
      
          buffer[siteidx] = buffer[siteidx] + "Lot No: "+LotNum+ "   Device: " + DeviceName + "   Site: " + string(siteidx)
          buffer[siteidx] = buffer[siteidx] + "   Key Type: "  + Key_Type + "   Key ID: "  + string(keyID[siteidx])
      

          if curr_bin[siteidx] == 1 then
             buffer[siteidx] = buffer[siteidx]+ "    SUCCESS, Device Passed."
             dks_disposition = 0
          else_if curr_bin[siteidx] == -1 then
             buffer[siteidx] = buffer[siteidx]+ "    ERROR, Unknown test result."
             dks_disposition = -1
          else_if curr_bin[siteidx] == OTP_Fail_Bin then
             buffer[siteidx] = buffer[siteidx]+ "    FAILED, HDCP key trim failed."
             dks_disposition = 1
          else
             buffer[siteidx] = buffer[siteidx]+ "    FAILED, HDCP key trimmed correctly but device failed."
             dks_disposition = 2
          end_if
       
      
          status = call_c_library("dalLogSingleKey_wrapper", dks_disposition, buffer[siteidx], keyID[siteidx])
       end_if
   end_for

   
 -- Reset Global Variables  
   fetched_HDCP_key      = FALSE
   HDCP_key_server_code  = 0
   set_expr("GRABBED_HDCP_KEY.Meas",FALSE)  -- used for binning


end_body



function Establish_SSL_Connection : integer
--------------------------------------------------------------------------------
--  This function is called on ON_LOAD


local

    integer      : status
    string[4]    : QAorFT
    string[6]    : TestTemp
    integer      : input_file
    string[150]  : var1
    integer     : stringpos
end_local

body
  
   get_expr("OpVar_TestType", QAorFT)   -- determine if QA or FT is selected
   get_expr("OpVar_TestTemp", TestTemp) -- determine test temperature


-- Initialize Global Variables   
   fetched_HDCP_key      = FALSE
   HDCP_key_server_code  = 0
   
-- Check Environment variable to determine Green Hills Library Path
-- Store path in temporary file, then read file
   wait_for_nic_shell_command("echo $LD_LIBRARY_PATH >/tmp/tempfile.txt") 
   open(input_file, "/tmp/tempfile.txt", "r")
   input(input_file, var1)
   close(input_file)
   wait_for_nic_shell_command("rm /tmp/tempfile.txt")


-- Other paths are being appended (not sure why?) so strip out other paths   
   stringpos = pos(":", var1) - 1
   if stringpos > 0 then
      var1 = var1[1:stringpos] + "/dalWrapperLib.so"
   else
      var1 = var1 + "/dalWrapperLib.so"
   endif


-- Call dalInitialize_wrapper only if FT option is selected   
   if( QAorFT =="FT") then
   println(stdout, "Green Hills Library Path: ", var1)
   dalWrapperObjectHandle = open_c_library(var1)
   status = call_c_library("dalInitialize_wrapper")
   c_library_is_open   = TRUE 
   end_if
   
  
   return (status)
   

end_body



function Format_Keys(hdcp_key_array, die_rev) : lword[134]

--------------------------------------------------------------------------------
-- The HDCP keys returned by the key server are in a certain order according to  
-- the "HDCP Signing Facility User's Guide"
-- The KSV occupies the first 8 bytes. The most significant 3 bytes are filled with zeros.
-- The next 280 bytes are the device keys (Key0 - Key39). Each device key is 7 bytes long.
-- They are stored in little-endian format, such that the least significant byte is the
-- first byte of the sequence, followed by bytes of increasing significance until the
-- last byte which is the most significant byte.

in lword : hdcp_key_array[312]  -- this is the array in the format as described above.
                                -- this function will format it so it is ready to be OTP'ed
				-- into the device.

in lword  : die_rev             -- Die Revision
                        
local

  lword   : formatted_keys[134] -- formatted hdcp keys ready to be OTP'ed
  lword   : idx, jjj


end_local

body
  


-- Place KSV in location 0x80 and 0x81
   for idx =1 to 4 do
       formatted_keys[0x80] = formatted_keys[0x80] | (hdcp_key_array[idx]<<(8*(idx-1)))
   end_for
   
-- Program Device byte1, device byte2, OTP byte and KSV in location  0x81  
--   formatted_keys[123] = hdcp_key_array[5] | 16#00110300   -- 4th digit from left is revision #

   die_rev = 0xF & die_rev  -- use only lower four bits
   die_rev = die_rev << 16  -- shift die rev bits

--   formatted_keys[0x81] = hdcp_key_array[5] | 16#EF000200 | die_rev  -- 4th digit from left is revision #   
   formatted_keys[0x81] = hdcp_key_array[5] | 16#00000000 | die_rev  -- 4th digit from left is revision #,for now no scamble and disable trimmed and no other info    
-- Place device keys (Key0 - Key39) in array locations 4-73
   jjj=5
   
   for idx =9 to 288 by 4 do
       formatted_keys[jjj] = formatted_keys[jjj] |  hdcp_key_array[idx]
       formatted_keys[jjj] = formatted_keys[jjj] | (hdcp_key_array[idx+1] <<(8*1))
       formatted_keys[jjj] = formatted_keys[jjj] | (hdcp_key_array[idx+2] <<(8*2))
       formatted_keys[jjj] = formatted_keys[jjj] | (hdcp_key_array[idx+3] <<(8*3))   
       jjj = jjj+1
   end_for



   return(formatted_keys)


end_body
function OTP_Real_Key(otp_temp, sitenum, die_rev) : lword[130]

--------------------------------------------------------------------------------
--  
in string[6] : otp_temp  -- Temperature at which HDCP key is to be trimmed.
                         -- Should be "ROOM" or "HOT"
in word      : sitenum   -- site requesting HDCP key
in lword     : die_rev   -- Die Revision (0 = pass 1), (1 = pass 2), etc


local 

    integer         : status = -2
    lword           : hdcp_bytes[312]
    lword           : real_keys[130]
    string[4]       : TestType
    string[6]       : TestTemp
    string[8]       : response
    float           : ttime

end_local


body

   get_expr("OpVar_TestType", TestType)  -- determine test type, QA or FT
   get_expr("OpVar_TestTemp", TestTemp)  -- determine test temperature, (ROOM, HOT, COLD)
   
   hdcp_bytes = 0   -- redundant assignment to make sure arrays are set to 0
   real_keys = 0    -- redundant assignment to make sure arrays are set to 0
   
   HDCP_key_server_code[sitenum] = 0  -- reset variable
 
 
-- Get an HDCP key only during final test (FT) and for temperature selected by otp_temp
   if TestType == "FT" AND TestTemp == otp_temp then

--       start_timer
--       if Not Key_Pool_Refreshed then
--          status = call_c_library("dalPopulatePool_wrapper", Key_Type, numKeys)
--       end_if
      

      status = call_c_library("dalGetSingleKey_wrapper", hdcp_bytes, Key_Type, &keyID[sitenum])               

      Key_Pool_Refreshed = FALSE
--      key_time[sitenum] = stop_timer
   end_if
   

-- Set or Clear the Global Flag fetched_HDCP_key which is used to determine if an HDCP key was succesfully fetched   
   if status ==0 then
      fetched_HDCP_key[sitenum] = TRUE
      set_expr("GRABBED_HDCP_KEY.Meas",TRUE)  -- used for binning
      
      real_keys = Format_Keys(hdcp_bytes, die_rev)  -- format keys for OTP      
   else
      fetched_HDCP_key[sitenum] = FALSE
   end_if
   

-- Print message if HDCP key SHA1 hash check fails
   if status == -1 then
      Print_banner_message("HDCP key SHA1 hash check error!","","")
   end_if
   
   
-- Print message if there is an error obtaining an HDCP key from the server   
   if status > 0 then
      Print_banner_message("HDCP KEY SERVER ERROR","Please notify test engineer if problem persists","Press 'Enter' to Continue")
      input(stdin, response!L)
      HDCP_key_server_code[sitenum] = status   -- HDCP_key_server_code will be datalogged to indicate HDCP key server errors
   end_if
   


-- return the fetched key     
    return (real_keys)


end_body



procedure Reset_HDCP_Global_Variables
--------------------------------------------------------------------------------
--  
-- This function is called on OnReset


body

 -- Reset Global Variables  
    fetched_HDCP_key      = FALSE
    HDCP_key_server_code  = 0
    set_expr("GRABBED_HDCP_KEY.Meas",FALSE)  -- used for binning

end_body




procedure Terminate_HDCP_key_Wrapper
--------------------------------------------------------------------------------
--  
-- This function is called on ON_UNLOAD

local

   integer : status

end_local

body

   if c_library_is_open then
      status = call_c_library("dalTerminate_wrapper")
      close_c_library(dalWrapperObjectHandle)
   end_if

end_body



procedure Program_HDCP_keys(vdd, vdd18, vio, vterm, DEVICE_ADDR_ID, OTP_FAIL_PIN,OTP_DONE_PIN,KEY_TYPE, REG13_ID, SPEED_GRADE_TRIM, DIE_REV, trimmed_it, server_code_it,trimok, otp_trim_it, key_time_ft,OTP_READ_VERIFY,SERIAL_NUMBER,SITETRIM,TIMETRIM,POWERUP,POWERDOWN,YrTrim,MonthTrim,DayTrim,Crc1p7dlog,Crc1p9dlog,OTPLOCK,SpeedLimit)
--------------------------------------------------------------------------------
--  
in float            : vdd, vdd18, vio, vterm

in string[20]       : KEY_TYPE       -- SER_PTX01 (Tx), DES_PRX01 (Rx) --- Key_Type = "SER_PTX01"  -- Type of key to get. 
                                                                                   -- "PRX01" for Receiver (Deserializer) "Test" key
in boolean        : POWERUP,POWERDOWN                                                                                   -- "PTX01" for Transmitter (Serializer) "Test" key
				                                                   -- "DES_PRX01" for Receiver (Deserializer) "Real" key
                                                                                   -- "SER_PTX01" for Transmitter (Serializer) "Real" key
in lword            : REG13_ID  -- Expected  values for HDCP trimmed device
--in string[3]        : DEV_TYPE       -- Device Type (SER or DES)
in lword            : DIE_REV        -- 0 (pass 1), 1(pass 2), 2(pass 3), etc (die revision)
in word             : DEVICE_ADDR_ID      -- SER_ID or DES_ID
in_out integer_test : trimmed_it, server_code_it,otp_trim_it,OTP_READ_VERIFY,trimok,SERIAL_NUMBER,SITETRIM,TIMETRIM,YrTrim,MonthTrim,DayTrim

in_out float_test   : key_time_ft

in_out integer_test : Crc1p7dlog,Crc1p9dlog,OTPLOCK,SpeedLimit

in PIN LIST[1]       : OTP_FAIL_PIN,OTP_DONE_PIN
in lword             : SPEED_GRADE_TRIM           -- ONLY needed for hs87,89,94 up to this time. 

local

word list[16]       : OTP_active_sites
lword               : addr, bit
word                : logical_addr
integer             : idx,q,trim_fail_count
word                : siteidx, thissite
multisite integer   : soak_flagtrim_fail_count
integer             : NEED_PROGRAM = 0
integer             : mem_offset
multisite lword     : otp_write_data[134]
multisite lword     : otp_data
multisite lword     : reg_data,reg_data1
multisite integer   : regvalue
 multisite lword     : tempdata, tempdata1
-- multisite lword     : otp_read_data[512]
-- multisite lword     : otp_fail_data[512]
-- multisite lword     : otp_expected_data
 multisite boolean   : otp_fail
 multisite boolean   : ALREADY_PROGRAMMED
-- multisite lword     : soak_data
-- multisite lword     : comp_data

multisite boolean   :  DEV_FAILED ,otp_prog_ok
lword               :  NUM_OF_KEYS = 0
word list[4]        :  key_failure_sites = <::>
string[6]           :  OTP_TEMP  , Test_Type
word                :  DEV_ID 
multisite lword     :  otp_addr
multisite lword     :  first_fail_loc
multisite lword     : readback_data[712], read_data_burst[78]
integer             : array_index
float               : time_meas
float               :  Vconf0, Vconf1
multisite integer   : prog_ok,otp_blank_test
multisite lword     :  lowword, upperword
word                :  sites, site, begin_sites,fail_count
multisite integer   : reg_val,  serial_num, sitetrim,time_trim,year_trim,month_trim,day_trim
multisite integer   : gmsl_1X_addr_fail, gmsl_1X_addr_fail1p9
multisite boolean   : gmsl_1X_site_fail,  gmsl_1X_site_fail1p9
multisite lword     : OtpRdWordValues[288]
multisite lword     : CrcValue, CrcValueRb1p7, CrcValueRb1p9, CrcValue1p9,CrcValue1p7
multisite integer   : Crc1p7,Crc1p9,speedgrade

multisite integer   : OTP_DevBytesOtpByte_dlog, OtpLockScramble
multisite integer    : TrimmedCheck510fail, TrimmedCheck511fail
multisite lword     :  reg_data81Min,reg_data511Min,reg_data81Max,reg_data511Max, reg_data510Max, reg_data_510_TrimCheck,  reg_data_511_TrimCheck
multisite integer    : Reg15ValInt, Reg13ValInt, Reg15ValOk,Loc511Data,OTPLock
multisite boolean    :  DonePinHigh,PrgFailPin,PartFail





end_local

body

static    lword     : serial_number = 0

  otp_fail = FALSE
  DEV_ID = DEVICE_ADDR_ID
  
  TrimmedCheck510fail = 0 
  TrimmedCheck511fail = 0

  current_active_sites = get_active_sites()
  sites = word(len(current_active_sites))


------------ Power Up HS89 -----------------------
-- 
--     active_sites = get_active_sites
--     sites = word(len(active_sites))  

    --POWER_CONNECT    -- need this for reseting device
    
    -- can take out later but keep for now to make sure all MFP pins connected to DPs
      open cbit MFP_LT_RELAY  


-----Dut power up function
   DutPowerUp(vio, vdd18, vdd, "UART", "TP_GMSL2",POWERUP)
   
   OTP_Reg_Write(DEV_ID, OTP0,1, mlw(0x40), 0,mlw(0))---Enable OPT read 
   OTP_Reg_Write(DEV_ID, OTP1,1, mlw(0x00), 0, mlw(0))---Select GMSL section  
   
  ------------------ Deternmine if a part has been trimmed or not by reading CRC locations and lock  zin 2/19/2020 -------------------------
       
  ----Read location 0x510 to see if part failed Prog or done bit during trim. If it is failed then data = 0xBAD  MT 1/2020
        otp_addr =  32*(0x510)	   
        OTP_Reg_Write(DEV_ID, OTP2,2, otp_addr, 0,mlw(0x00) )---set address to read from   
        tempdata1 = OTP_Reg_Read(DEV_ID, OTP14, 4)    
         reg_data_510_TrimCheck = tempdata1
       
       
  ----Read location 0x511 to see if part failed Prog or done bit during trim. If it is failed then data = 0xBAD  MT 1/2020
        otp_addr =  32*(0x511)	   
        OTP_Reg_Write(DEV_ID, OTP2,2, otp_addr, 0,mlw(0x00) )---set address to read from   
        tempdata1 = OTP_Reg_Read(DEV_ID, OTP14, 4)    
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


  ----------- Register 13 & 15 to determine if device is already trimmed  -------------
  ----------- Check for HDCP capable bit and device ID --------------------------------
    reg_data = OTP_Reg_Read(SER_ID, REG13, 1)       -- DevID No Trim MAX96755 (REG13 = 155) , MAX96755F Trimmed (REG13 = 155) , MAX96757 Trimmed  (REG13 = 156), MAX96757F Trimmed  (REG13 = 156)
    regvalue = integer(reg_data)
    reg_data1 = OTP_Reg_Read(SER_ID, REG15, 1)      -- (Trimed Capability) No Trim MAX96755 (REG15 = 0) , Trimmed Part will read REG15 > 0 , MAX96755F REG15 = 32 (0x20) , MAX96757 REG15 = 1 (0x01), MAX96757F REG15 = 33 (0x21) 
    RegRead(SER_ID, 0x1808 , 1,  upperword,lowword, "SER_UART_Read")      ---Check memory lock bit. Make sure it is high
    OTPLock =   integer(lowword)   -- OTP RD DONE and OTP LOCK  1000 1000 (0x88)     
    
    for siteidx = 1 to sites do
        thissite = current_active_sites[siteidx]   
        OTPLock[thissite] =   (integer(lowword[thissite]) &0x8) >> 3
    end_for

--  test_value regvalue with trimmed_it

  
  ----------------- Determine which sites have already been OTP'ed
    for siteidx=1 to sites do
        thissite = current_active_sites[siteidx]
        reg_data[thissite] = reg_data[thissite] 
        if ((reg_data[thissite] == REG13_ID) or  (reg_data1[thissite] == 0x7F)) then  ---reason check for reg_data1 because HS94, MPW3 doesnot update reg13 as HS89. DE said nex rev
            ALREADY_PROGRAMMED[thissite] = TRUE
        else
            ALREADY_PROGRAMMED[thissite] = FALSE
        end_if
    end_for
   
------- Check if device has already failed or not. This is needed in case Run to End mode
------ is selected. Do not get a key and do not trim if device has already failed.
  
    DEV_FAILED = NOT(get_boolean_passing_sites)

  -- Determine how many keys are needed  
    for siteidx = 1 to sites do
        thissite = current_active_sites[siteidx]
        if( NOT ALREADY_PROGRAMMED[thissite] AND NOT DEV_FAILED[thissite]) then
            NUM_OF_KEYS = NUM_OF_KEYS + 1
        end_if
    end_for

 
    OTP_TEMP  ="ROOM"

----Grab key   
    if NUM_OF_KEYS > 0 then
        DAL_Populate_Key_Pool(NUM_OF_KEYS, OTP_TEMP, KEY_TYPE)
    end_if
----- If device has already been OTP'ed or has already failed, deactivate site
----- Get a Key for sites that need to be trimmed
    for siteidx=1 to sites do
        thissite = current_active_sites[siteidx]
            if not ALREADY_PROGRAMMED[thissite] AND not DEV_FAILED[thissite] then
                serial_number = serial_number + 1 ----Per Eric's requirment we need to program serial number for tracability
--	        otp_write_data[thissite] = OTP_Real_Key_mod(OTP_TEMP,thissite,DIE_REV,thissite,serial_number)   -- get an HDCP key when testing at HOT (105C)
	        otp_write_data[thissite] = OTP_Real_Key_gmsl_1X(OTP_TEMP,thissite,SPEED_GRADE_TRIM,KEY_TYPE,serial_number)   -- get an HDCP key when testing at HOT (105C)
	        if fetched_HDCP_key[thissite] then
	           NEED_PROGRAM = NEED_PROGRAM+1
	        else
	           key_failure_sites = key_failure_sites + <:thissite:>
	       end_if      
            else
                deactivate site thissite
            end_if
   end_for


  -- Datalog if at least one site has not been trimmed
    if NEED_PROGRAM > 0 then
------      test_value HDCP_key_server_code with server_code_it
------      test_value key_time with key_time_ft
    end_if
    
    deactivate site key_failure_sites
  
    if (NEED_PROGRAM >=1) then  -- If at least one site needs to be OTP'ed, execute block
        
        OTP_active_sites = get_active_sites()  -- sites active for OTP trim
        sites = word(len(OTP_active_sites))

---------------------------- OTP Programming -------------------------------------------------

-------
        reg_data = OTP_Reg_Read(DEV_ID, SR_CTRL0, 1)
        OTP_Reg_Write(DEV_ID, DR_CTRL0,1, (reg_data | 0x40), 0,mlw(0x00) )--------Turn off GMLS phy for trim because with this rev Vdd18 = 2.1V to trim it is higher then abmax spec 9/2018
--------------------DE requests to trim part at Vdd =0.95V, Vdd18 =2.1V and Vddio =2.75V other supplies don't care can by at type.... 9/2018 MT.
----------- Set_SER_Voltages(vio, vcore, v18)
        Set_SER_Voltages(2.75, 0.95V, 2.1)

---------------------------- OTP Programming -------------------------------------------------
        OTP_Reg_Write(DEV_ID, OTP0,1, mlw(0x00), 0,mlw(0))---disable read OTP0 =0X1800 FOR HS89
        OTP_Reg_Write(DEV_ID, OTP1,1, mlw(0x02), 0, mlw(0))---enable  OTP_PGM_DONE and OTP_PGM_FAIL to GPIO15  and GPIO14  and select GMSL section OTP1 = 0X1801

---OTP Write 
        OTP_Reg_Write(DEV_ID, OTP0,1, mlw(0x20), 0, mlw(0))---enable write 
 
        set digital pin OTP_DONE_PIN + OTP_FAIL_PIN modes to driver pattern comparator enable all fails
        set digital pin  OTP_DONE_PIN + OTP_FAIL_PIN levels to vih 0.9*vio vil 0.1*vio vol 0.5*vio voh 0.5*vio iol 0mA ioh 0mA vref 0V


---------------------------------------------------------------------------------
start_timer

--zin play data
 -- otp_write_data[1,100] = 0x55
--  otp_write_data[1,101] = 0x00
--   otp_write_data[1,102] = 0x55
--  otp_write_data[1,103] = 0x00
--   otp_write_data[1,104] = 0xFF
--  otp_write_data[1,105] = 0x00
--   otp_write_data[1,106] = 0x55
--  otp_write_data[1,107] = 0x00
--   otp_write_data[1,108] = 0x55
--  otp_write_data[1,109] = 0x00
 
 

        otp_prog_ok = OTP_Reg_Write_Matchloop_Burst(DEV_ID, OTP2, otp_write_data, 5,0x86,0x4B,0x80,"GMSL1_HDMI1X",0 )-------Program whole memory in burst mode
------Prepare for datalog
        for siteidx = 1 to sites do 
            thissite = OTP_active_sites[siteidx]
            if otp_prog_ok[thissite] then
                prog_ok[thissite] = 0 ---passed
            else
                prog_ok[thissite] = 1 ---failed
            end_if        
        end_for 
        
       read digital pin OTP_DONE_PIN state compare to high into DonePinHigh   ----expect high MT 1/2020
       read digital pin OTP_FAIL_PIN  state compare to low into PrgFailPin    ---expect low  
        
           
 time_meas = stop_timer     

  
----------
--verify what opt memory contain make sure it match with write in data.
---OTP read memory----
       OTP_Reg_Write(DEV_ID, OTP0,1, mlw(0x00), 0, mlw(0x00))---disable program
       OTP_Reg_Write(DEV_ID,OTP0 ,1, mlw(0x40), 0, mlw(0x00))---enable read
       fail_count =0 ---reset fail_count variable 

---DE require verify read back at different supply    
    Set_SER_Voltages(1.7, vdd, vdd18)
        if Test_Type = "FT"  then
          if OTP_TEMP = "COLD" then
              Set_SER_Voltages(1.7, 0.95, 1.58)                               --- # DE require verify read back at different supply   VDDIO= 1.7V VDD18= 1.58V, VDDD=0.95V   
          else
              Set_SER_Voltages(1.7, 0.95, 1.68)     ---Hot and Room                          --- # DE require verify read back at different supply   VDDIO= 1.7V VDD18= 1.68V, VDDD=0.95V   
          end_if
        else
            Set_SER_Voltages(1.7, 0.95, 1.7)    
        end_if    



-----------------------------------------------------------------------
 ----Read whole memeroy at once MT
       read_data_burst = OTP_Reg_Read_burst(DEV_ID, OTP2, OTP14,   5    ,   0x86    ,    0x4B    ,   0x80       ,    -1, "GMSL1_HDMI1X")

       mem_offset = 0----initialize
       trim_fail_count = 0
---------Verify data read correctly
        for  i = 1 to  75 do
             if i >= 71 then   
                addr = 0x80 + lword(mem_offset)
                mem_offset = mem_offset + 1
             else
                addr = lword(i) + 4-----opt write data start at index 5
            end_if   
            
            for siteidx = 1 to sites do
                thissite =OTP_active_sites [siteidx]
                if (read_data_burst[thissite,i]  <> otp_write_data[thissite,addr]) and not(gmsl_1X_site_fail[thissite]) then
                   gmsl_1X_addr_fail[thissite] = integer(addr)
                   gmsl_1X_site_fail[thissite] = true
                   fail_count = fail_count +1   
                   if fail_count = sites then
                        addr = 1000 --- no need to compare
                    end_if                    
                end_if

            end_for          
       end_for 
wait(0)
-------------------per De read again at higher supplies
-------------------------VDDIO= 3.6V VDD18= 1.9V, VDDD=1.05V---------------

        Set_SER_Voltages(3.6, 1.05,1.9)

        fail_count = 0                                                  --- # reset all flags
        gmsl_1X_site_fail = false 
        
---- Read whole memeroy at once MT
        read_data_burst = OTP_Reg_Read_burst(DEV_ID, DR_OTP2, DR_OTP14, 5, 0x86, 0x4B, 0x80,  -1, "GMSL1_HDMI1X")
        mem_offset = 0                                                  --- # initialize

        for  i = 1 to  75 do                                            --- # Verify data read correctly
            if i >= 71 then   
                addr = 0x80 + lword(mem_offset)
                mem_offset = mem_offset + 1
            else
                addr = lword(i) + 4                                     --- # opt write data start at index 5
            end_if     
            for siteidx = 1 to sites do
                thissite =OTP_active_sites [siteidx]
                if (read_data_burst[thissite,i]  <> otp_write_data[thissite,addr]) and not(gmsl_1X_site_fail1p9[thissite]) then
                    gmsl_1X_addr_fail1p9[thissite] = integer(addr)
                    gmsl_1X_site_fail1p9[thissite] = true
                    fail_count = fail_count +1   
                    if fail_count = sites then
                        i = 1000 --- no need to compare
                    end_if                    
                end_if
            end_for        
        end_for 
        wait(0)        

--------------------------Now need power cycle for buring CRC     

        DutPowerUp(vio, vdd18, vdd, "UART", "TP_GMSL2",POWERUP)
        wait(2ms)
        Set_SER_Voltages(3.6, 1.05, 1.9)
        wait(2ms)
        OTP_Reg_Write(DEV_ID, OTP0,1, mlw(0x00), 0, mlw(0x00))           --- # disable program
        OTP_Reg_Write(DEV_ID, OTP0,1, mlw(0x40), 0, mlw(0x00))           --- # enable read

---- Read whole memeroy at once MT
        read_data_burst = OTP_Reg_Read_burst(DEV_ID, OTP2, OTP14, 5, 0x86, 0x4B, 0x80,  -1, "GMSL1_HDMI1X")
        OtpRdWordValues =  OTP_Return_OneWord(read_data_burst)
---Calulate CRC base on HS84
        CrcValue = Crc32Calculate(OtpRdWordValues, 288, true)    ---need check in debug mt

-----Only program CrcValue if part pass reading verification otherwise as it is retested we might encounter mix-bin rejects. MT
        for siteidx = 1 to sites do
            thissite =OTP_active_sites [siteidx]
            if gmsl_1X_site_fail[thissite] or gmsl_1X_site_fail1p9[thissite] then
                CrcValue[thissite] = 0          
            end_if
         end_for   

-----Disable GMSL phy again
        reg_data = OTP_Reg_Read(DEV_ID, DR_CTRL0, 1)
        OTP_Reg_Write(DEV_ID, SR_CTRL0,1, (reg_data | 0x40), 0,mlw(0x00) )--------Turn off GMLS phy for trim because with this rev Vdd18 = 2.1V to trim it is higher then abmax spec 9/2018
        Set_SER_Voltages(2.75, 0.95V, 2.1)                           -----Change to supplies to requested values
        wait(1ms)

----Burn CRC into memory location 511
        OTP_Reg_Write(DEV_ID, OTP0,1, mlw(0x00), 0, mlw(0))              --- # 16#1800: disable read OTP0 =0X1800 FOR HS89
        OTP_Reg_Write(DEV_ID, OTP1,1, mlw(0x02), 0, mlw(0))              --- # 16#1801: enable  OTP_PGM_DONE and OTP_PGM_FAIL to GPIO15  and GPIO14  and select GMSL section OTP1 = 0X1801
        OTP_Reg_Write(DEV_ID, OTP0,1, mlw(0x20), 0, mlw(0))              --- # Enable write 
        otp_addr   =   511*32                                               ----- set otp address to burn CRC value                
        OTP_Reg_Write(DEV_ID, 16#1802,2,otp_addr , 4, CrcValue )---Write data to address
        wait(10mS)
----Burn again
        OTP_Reg_Write(DEV_ID, 16#1802,2,otp_addr , 4, CrcValue )---Write data to address
        wait(10mS)
       
----------------OTP LOCK 

       OTP_Reg_Write(DEV_ID, OTP0, 1, mlw(0x00), 0, mlw(0)) ---disable read/write
       OTP_Reg_Write(DEV_ID, OTP1, 1, mlw(0x02), 0, mlw(0)) ---enable  OTP_PGM_DONE and OTP_PGM_FAIL to GPIO15  and GPIO14  and select GMSL section

--       OTP_Reg_Write(DEV_ID, DR_OTPF,1  ,mlw(0xFF) , 0,  mlw(0) ) ---Mu Li removes this and add loop of 4 times program
---OTP Write 
       for i = 1 to 4 do 
            OTP_Reg_Write(DEV_ID,  OTP0, 1, mlw(0x10), 0, mlw(0))--- lock
            wait(1ms)        
       end_for
 --       reg_data = OTP_Reg_Read(DEV_ID, DR_CTRL0, 1)



        Set_SER_Voltages(1.7,  0.95V,1.7)    ---Change supplies to normal range MT
       
--         reg_data = OTP_Reg_Read(DEV_ID, DR_OTP8, 1)  ----Readback Lock status bit                                                  
--         OTP_Reg_Write(DEV_ID, DR_OTP0, 1, mlw(0x00), 0, mlw(0)) ---disable read/write
                       
    end_if
--------------------------------end of verify  

    activate site current_active_sites
    sites = word(len(current_active_sites)) --- get number of sites at begining

--------------------------Now need power cycle after buring CRC        
  
   DutPowerUp(vio, vdd18, vdd, "UART", "TP_GMSL2",POWERUP)
    
--------------------------------
 -----Read memory location 0x84 and 85; serial number and date trimmed 
       OTP_Reg_Write(DEV_ID, OTP0,1, mlw(0x40), 0,mlw(0))---Enable OPT read 
       OTP_Reg_Write(DEV_ID, OTP1,1, mlw(0x00), 0, mlw(0))---Select GMSL section

      otp_addr =  32*(0x84)	   
      OTP_Reg_Write(DEV_ID, OTP2,2, otp_addr, 0,mlw(0x00) )---set address to read from   
      reg_data = OTP_Reg_Read(DEV_ID, OTP14, 4)


      otp_addr =  32*(0x85)	   
      OTP_Reg_Write(DEV_ID, OTP2,2, otp_addr, 0,mlw(0x00) )---set address to read from   
      tempdata = OTP_Reg_Read(DEV_ID, OTP14, 4)
      otp_addr =  32*(0x86)
      OTP_Reg_Write(DEV_ID, OTP2,2, otp_addr, 0,mlw(0x00) )---set address to read from   
     tempdata1 = OTP_Reg_Read(DEV_ID, OTP14, 4)
      for siteidx = 1 to sites do
          thissite = current_active_sites[siteidx]  
          sitetrim[thissite] = integer(reg_data[thissite] & 0xFFFFFF)>> 20
          serial_num[thissite] = integer(reg_data[thissite]) & 0xFFFF
          time_trim[thissite] = integer(tempdata[thissite]) & 0xFFFFFF ---Datalog out minute and second 
          year_trim[thissite] = integer(tempdata1[thissite]) >> 16
          month_trim[thissite] = integer((tempdata1[thissite]) >> 8) & 0xFF
          day_trim[thissite] = integer(tempdata1[thissite])  & 0xFF
          

      end_for
--       for siteidx = 1 to sites do
--           thissite = current_active_sites[siteidx]  
--           sitetrim[thissite] = integer(reg_data[thissite] & 0xFFFFFF)>> 20
--           serial_num[thissite] = integer(reg_data[thissite]) & 0xFFFF
--           time_trim[thissite] = integer(tempdata[thissite]) & 0xFFFFFF ---Datalog out minute and second 
-- 
-- 
-- 
--       end_for

---Read programed Crc at mem location 511
        otp_addr =  32*511	   
        OTP_Reg_Write(DEV_ID, OTP2, 2, otp_addr, 0,mlw(0x00) ) ---set address to read from   
        CrcValueRb1p9 = OTP_Reg_Read(DEV_ID, OTP14, 4)

----Read whole memory to check CrcValue
---- Read whole memeroy at once MT
        read_data_burst = OTP_Reg_Read_burst(DEV_ID, OTP2, OTP14, 5, 0x86, 0x4B, 0x80,  -1, "GMSL1_HDMI1X")
        OtpRdWordValues =  OTP_Return_OneWord(read_data_burst)
---Calulate CRC base on HS84
        CrcValue1p9 = Crc32Calculate(OtpRdWordValues, 288, true)   
---Change supply to 1.7 as requested by DE
        if Test_Type = "QA" then
            Set_SER_Voltages(1.7, 0.95, 1.7)
        else
            if OTP_TEMP = "COLD" then
                Set_SER_Voltages(1.7, 0.95, 1.58) -------- FT flow  cold
            else
                Set_SER_Voltages(1.7, 0.95, 1.68) -------- FT flow
            end_if   
        end_if
        
---Read programed Crc at mem location 511
        otp_addr =  32*511	   
        OTP_Reg_Write(DEV_ID, OTP2, 2, otp_addr, 0,mlw(0x00) ) ---set address to read from   
        CrcValueRb1p7 = OTP_Reg_Read(DEV_ID, OTP14, 4)

---Read programed Speedlimit or not  at mem location 0x81
        otp_addr =  32*0x81	   
        OTP_Reg_Write(DEV_ID, OTP2, 2, otp_addr, 0,mlw(0x00) ) ---set address to read from   
        tempdata1 = OTP_Reg_Read(DEV_ID, OTP14, 4)
      for siteidx = 1 to sites do
          thissite = current_active_sites[siteidx]   
          if  ( (tempdata1[thissite]&0x20000000) == 0x20000000)  then
                speedgrade[thissite] = 1
          else
                speedgrade[thissite] = 0
          end_if
   
    end_for

----Read whole memory to check CrcValue
---- Read whole memeroy at once MT
        read_data_burst = OTP_Reg_Read_burst(DEV_ID, OTP2, OTP14, 5, 0x86, 0x4B, 0x80,  -1, "GMSL1_HDMI1X")
        OtpRdWordValues =  OTP_Return_OneWord(read_data_burst)
---Calulate CRC base on HS84
        CrcValue1p7 = Crc32Calculate(OtpRdWordValues, 288, true)           
        
        for siteidx = 1 to sites do
            thissite = current_active_sites[siteidx]  
            if CrcValueRb1p7[thissite] = 0 then
                Crc1p7[thissite] = 1                                   ---------Readback data failed during trim
            elseif CrcValue1p7[thissite] <> CrcValueRb1p7[thissite] then
               Crc1p7[thissite] = 2                                    ---------Data flipped
            else
                Crc1p7[thissite] = 0
            endif
            if CrcValueRb1p9[thissite] = 0 then
                Crc1p9[thissite] = 1                                  ---------Readback data failed during trim
            elseif CrcValue1p9[thissite] <> CrcValueRb1p9[thissite] then
               Crc1p9[thissite] = 2                                   ---------Data flipped
            else
                Crc1p9[thissite] = 0    
            endif

        end_for    
----readlock
        reg_data = OTP_Reg_Read(DEV_ID, DR_OTP8, 1)  ----Readback Lock status bit and scramble
        OtpLockScramble = integer(reg_data ) & 0x0C

---------------- Power Off -------------------
  disconnect digital pin OTP_FAIL_PIN + OTP_DONE_PIN from ppmu
  connect digital pin OTP_FAIL_PIN + OTP_DONE_PIN to dcl
  wait(200us)
--------  DutPowerDown
 ------ Power Off ----
  set digital pin ALL_PATTERN_PINS  levels to vil 0V vih 200mV iol 0uA ioh 0uA vref 0V
  wait(100us)
  
  set digital pin ALL_PATTERN_PINS modes to comparator enable all fails
  set hcovi SER_VDD+SER_VDDIO +SER_VDD18 to fv 0V vmax 4V clamp imax 600mA imin -600mA   

  wait(3ms)     -- extra for 47uF cap on SER_VDD    
  -- Initialize for set_SER_Voltages(vio, vcore, v18) routine
  vdd_global[1] = 0V   --SER_VDDIO
  vdd_global[2] = 0V   --SER_VDD  
  vdd_global[3] = 0V   --SER_VDDA(VDD18)

----Datalog out
     
      test_value regvalue with trimmed_it-----check DEVICE_ID( not device address) For HS89 8x8 tqfn none hdcp = 0x9B, HDCP = 0x9C

  if NEED_PROGRAM > 0 then  ----data log trim 
     test_value HDCP_key_server_code with server_code_it
     test_value key_time with key_time_ft
     test_value prog_ok with trimok
     test_value trim_fail_count with OTP_READ_VERIFY
  end_if

     test_value serial_num with SERIAL_NUMBER
     test_value sitetrim with SITETRIM
     test_value time_trim with TIMETRIM
     test_value year_trim with YrTrim
     test_value month_trim with MonthTrim
     test_value day_trim with DayTrim
     test_value Crc1p7 with Crc1p7dlog
     test_value Crc1p9 with Crc1p9dlog
     test_value OtpLockScramble with OTPLOCK
     test_value speedgrade   with SpeedLimit


end_body

function OTP_Real_Key_mod(otp_temp, sitenum, die_rev,trimsite,serial_n) : lword[134]

--------------------------------------------------------------------------------
--  
in string[6] : otp_temp  -- Temperature at which HDCP key is to be trimmed.
                         -- Should be "ROOM" or "HOT"
in word      : sitenum   -- site requesting HDCP key
in lword     : die_rev   -- Die Revision (0 = pass 1), (1 = pass 2), etc
in lword     : serial_n
in word       : trimsite
local 

    integer         : status = -2
    lword           : hdcp_bytes[2052]------[312]  for server which can obtain for GMSL2 keys need change to 2052 bytes. Old GH server then 312.
    lword           : real_keys[134]
    string[4]       : TestType
    string[6]       : TestTemp
    string[8]       : response
    float           : ttime

end_local


body
    
   get_expr("OpVar_TestType", TestType)  -- determine test type, QA or FT
   get_expr("OpVar_TestTemp", TestTemp)  -- determine test temperature, (ROOM, HOT, COLD)
   
   hdcp_bytes = 0   -- redundant assignment to make sure arrays are set to 0
   real_keys = 0    -- redundant assignment to make sure arrays are set to 0
   
   HDCP_key_server_code[sitenum] = 0  -- reset variable
 
 
-- Get an HDCP key only during final test (FT) and for temperature selected by otp_temp
   if TestType == "FT" AND TestTemp == otp_temp then

--       start_timer
--       if Not Key_Pool_Refreshed then
--          status = call_c_library("dalPopulatePool_wrapper", Key_Type, numKeys)
--       end_if
      

      status = call_c_library("dalGetSingleKey_wrapper", hdcp_bytes, Key_Type, &keyID[sitenum])               

      Key_Pool_Refreshed = FALSE
--      key_time[sitenum] = stop_timer
   end_if
   

-- Set or Clear the Global Flag fetched_HDCP_key which is used to determine if an HDCP key was succesfully fetched   
   if status ==0 then
      fetched_HDCP_key[sitenum] = TRUE
      set_expr("GRABBED_HDCP_KEY.Meas",TRUE)  -- used for binning
      
      real_keys = Format_Keys_mod(hdcp_bytes, die_rev,trimsite,serial_n)  -- format keys for OTP      
   else
      fetched_HDCP_key[sitenum] = FALSE
   end_if
   

-- Print message if HDCP key SHA1 hash check fails
   if status == -1 then
      Print_banner_message("HDCP key SHA1 hash check error!","","")
   end_if
   
   
-- Print message if there is an error obtaining an HDCP key from the server   
   if status > 0 then
      Print_banner_message("HDCP KEY SERVER ERROR","Please notify test engineer if problem persists","Press 'Enter' to Continue")
      input(stdin, response!L)
      HDCP_key_server_code[sitenum] = status   -- HDCP_key_server_code will be datalogged to indicate HDCP key server errors
   end_if
   


-- return the fetched key     
    return (real_keys)


end_body





function Format_Keys_mod(hdcp_key_array, die_rev,trimsite,serialnumber) : lword[134]

--------------------------------------------------------------------------------
-- The HDCP keys returned by the key server are in a certain order according to  
-- the "HDCP Signing Facility User's Guide"
-- The KSV occupies the first 8 bytes. The most significant 3 bytes are filled with zeros.
-- The next 280 bytes are the device keys (Key0 - Key39). Each device key is 7 bytes long.
-- They are stored in little-endian format, such that the least significant byte is the
-- first byte of the sequence, followed by bytes of increasing significance until the
-- last byte which is the most significant byte.

in lword : hdcp_key_array[2052]-----[312]  -- this is the array in the format as described above.
                                -- this function will format it so it is ready to be OTP'ed
				-- into the device.

in lword  : die_rev             -- Die Revision
in lword  : serialnumber   ---- serial number
in word   : trimsite
local

  lword   : formatted_keys[134] -- formatted hdcp keys ready to be OTP'ed
  lword   : idx, jjj
  integer      : time_h, time_m, time_s
  integer      : date_m, date_d, date_y

end_local

body
  
           time(time_h, time_m, time_s)     -- get time
           date(date_m, date_d, date_y)     -- get date

----Mu and Eric Wu asked to move away from address 0x82.
--- 0x82 and 0x83 may be used for some internal trim
--0x84 to 0x8b can be used for tracability
--0x8C to 0x511 will be used for HDCP2X in the future.   -----MT 09/28/2017
---Place serial number to the last 2 bytes and site to the third byte at address 0x82

  formatted_keys[0x83] = (lword(trimsite) << 20 )| serialnumber
  formatted_keys[0x84] = (lword(time_h) << 16 )| (lword(time_m) << 8 )| (lword(time_s)  )-----Program time this device was trimed
   formatted_keys[0x85] = (lword(date_y) << 16 )| (lword(date_m) << 8 )| (lword(date_m)  )-----Program time this device was trimed

-- Place KSV in location 0x80 and 0x81
   for idx =1 to 4 do
       formatted_keys[0x80] = formatted_keys[0x80] | (hdcp_key_array[idx]<<(8*(idx-1)))
   end_for
   
-- Program Device byte1, device byte2, OTP byte and KSV in location  0x81  
--   formatted_keys[123] = hdcp_key_array[5] | 16#00110300   -- 4th digit from left is revision #
---No longer need program die revision per Levent

--    die_rev = 0xF & die_rev  -- use only lower four bits
--    die_rev = die_rev << 16  -- shift die rev bits
    
 
   formatted_keys[0x81] = hdcp_key_array[5] | 16#01000300       --------| die_rev  -- 4th digit from left is revision #, scramble and disable trimmed      nolonger need die rev
-- Place device keys (Key0 - Key39) in array locations 4-73
   jjj=5
   
   for idx =9 to 288 by 4 do
       formatted_keys[jjj] = formatted_keys[jjj] |  hdcp_key_array[idx]
       formatted_keys[jjj] = formatted_keys[jjj] | (hdcp_key_array[idx+1] <<(8*1))
       formatted_keys[jjj] = formatted_keys[jjj] | (hdcp_key_array[idx+2] <<(8*2))
       formatted_keys[jjj] = formatted_keys[jjj] | (hdcp_key_array[idx+3] <<(8*3))   
       jjj = jjj+1
   end_for



   return(formatted_keys)


end_body

function OTP_Reg_Read(device_id, register, bytes): multisite lword
--------------------------------------------------------------------------------
--  
in word               : device_id, register, bytes

local


word list[MAX_SITES]  : active_sites_local
word                  : siteidx, idx, sites_local
word                  : csite

word                  : send_word[30]
multisite word        : cap_data[64]
multisite word        : reg_read[22]
multisite lword       : rread
string[30]           : cap_waveform    -- regsend capture waveform
string[3]              : plab     -- pattern label
end_local

body

    active_sites_local = get_active_sites()
    sites_local = word(len(active_sites_local))
    
    plab = "S"+string(bytes)
    
    if bytes > 4 then   --can't have more than 4 bytes in an LWORD
        bytes = 4
    end_if
 

    send_word[1] = 2#101111001   --synch frame 0x79h
    send_word[2] = add_parity_bit(device_id+1)
    send_word[3] = add_parity_bit((register & 16#FF00) >> 8)
    send_word[4] = add_parity_bit(register & 16#FF)
    send_word[5] = add_parity_bit(bytes)
  
    cap_waveform = "OTP_CAPTURE" + string(bytes)

    load     digital reg_send fx1 waveform "OTP_SEND" with send_word
    enable   digital reg_send fx1 waveform "OTP_SEND"

    enable digital capture fx1 waveform cap_waveform
    execute digital pattern "OTP_Read" at label plab run to end wait
    wait for digital capture fx1 waveform cap_waveform

    read digital capture fx1 waveform cap_waveform into cap_data
    
--- Process the data read back ------
    for siteidx=1 to sites_local do
       csite = active_sites_local[siteidx]
       reg_read[csite] = Analyze_Read_M(cap_data[csite],bytes)
    

       for idx=0 to (bytes-1) do
          rread[csite] = (lword(reg_read[csite,idx+1]))<<lword(8*idx) + rread[csite]
       end_for
       
    end_for
    
    return (rread)


end_body


procedure OTP_Reg_Write(device_id, register, bytes1, data1, bytes2, data2)
--------------------------------------------------------------------------------
--  
in word               : device_id, register, bytes1, bytes2
in multisite lword     : data1, data2

local

word list[MAX_SITES]  : active_sites_local
word                  : siteidx, idx, sites_local
word                  : csite

multisite word        : send_word[30]
multisite word        : mdata
string[3]             : lab

end_local

body

    active_sites_local = get_active_sites()
    sites_local = word(len(active_sites_local))

    lab = "S"+string(bytes1+bytes2)
    
    for siteidx = 1 to sites_local do
        csite = active_sites_local[siteidx]
        send_word[csite,1] = 2#101111001   --synch frame 0x79h
        send_word[csite,2] = add_parity_bit(device_id)
        send_word[csite,3] = add_parity_bit((register & 16#FF00) >> 8)
        send_word[csite,4] = add_parity_bit(register & 16#FF)
        send_word[csite,5] = add_parity_bit(bytes1+bytes2)

       
        for idx=1 to bytes1 do
            mdata[csite] = word( (data1[csite]>>(8*lword(idx-1))) & 16#FF)
            send_word[csite,idx+5] = add_parity_bit(mdata[csite])
        end_for
    
    
        if bytes2 > 0 then
           for idx=1 to bytes2 do
             mdata[csite] = word( (data2[csite]>>(8*lword(idx-1))) & 16#FF)
             send_word[csite,idx+5+bytes1] = add_parity_bit(mdata[csite])
           end_for
        end_if
	
    end_for
       

--     load digital reg_send fx1 waveform "SER_REG_SEND" with send_word
--     enable digital reg_send fx1 waveform "SER_REG_SEND"

    load     digital reg_send fx1 waveform "OTP_SEND" with send_word
     enable   digital reg_send fx1 waveform "OTP_SEND"
    
    execute digital pattern "OTP_WRITE" at label lab run to end wait


end_body





function mlw(data) : multisite lword
--------------------------------------------------------------------------------
--
in lword           : data


local

multisite lword    : mdata

end_local

body

    mdata = data
    
    return (mdata)

end_body

function OTP_Reg_Write_Matchloop_Burst(device_id, register, otpwritedata,start_addr,stop_addr,skip_addr,addr_jump1,MEM_TYPE,Array_offset): multisite boolean
--------------------------------------------------------------------------------
--  
in word               : device_id, register
in multisite lword     : otpwritedata[?]   -----[134]
in word                : start_addr                ----- first memory location to prog
in word                : stop_addr                 ----- last memory  location to prog
in word                : skip_addr                 ----- memory address to skip program
in word                : addr_jump1                ----- memory address jump to program
in string[20]          : MEM_TYPE                  ----- GMSL1_HDMI1X or HDMI2X
in word                : Array_offset   --------GMSL1 array offset = 1, HDMI1X and HDMI2X offset = 0.  in GMSL1 the way data structure is array element is correspond to mem addr while HDMI it shifts up by 1
                                        -----example   otp_write_data_gmsl1X[1] and otp_write_data_hdmi2X[1] point to memory address 1; while otp_write_data_hdmi1X [1] point to mem addr 0. 
local

word list[MAX_SITES]  : active_sites_local
word                  : siteidx, idx, sites_local
word                  : csite,j

multisite word        : send_word[2592]
multisite word        : mdata
string[3]             : lab
word                  : addr,otp_addr
multisite boolean     : rslt
end_local

body

    active_sites_local = get_active_sites()
    sites_local = word(len(active_sites_local))

--    lab = "S"+string(bytes1+bytes2)

    for siteidx = 1 to sites_local do
        csite = active_sites_local[siteidx]
        j = 0
--        for addr = 5 to 0x84 do -----5 to 0x84 do
        for addr = start_addr to stop_addr do -----5 to 0x84 do
            send_word[csite,1 +j] = add_parity_bit(device_id)
            send_word[csite,2 +j] = add_parity_bit((register & 16#FF00) >> 8)
            send_word[csite,3 +j] = add_parity_bit(register & 16#FF)
            if addr = skip_addr then
                addr = addr_jump1 --------0x80
            end_if
            otp_addr = addr*32
            send_word[csite,4 +j] = add_parity_bit(otp_addr & 16#FF)
            send_word[csite,5 +j] = add_parity_bit((otp_addr & 16#FF00) >> 8)
            for idx=1 to 4 do ---only 4 data bytes
                mdata[csite] = word( (otpwritedata[csite,addr+Array_offset]>>(8*lword(idx-1))) & 16#FF)
                send_word[csite,idx+5 + j] = add_parity_bit(mdata[csite])
            end_for            
            j = j + 9
        end_for

  
 	
    end_for
 wait(0)

     load     digital reg_send fx1 waveform "OTP_WRITE_SEND" with send_word
     enable   digital reg_send fx1 waveform "OTP_WRITE_SEND"
    if MEM_TYPE = "GMSL1_HDMI1X" then
        execute digital pattern "OTP_WRITE_BURST_MATCH_UART"  at label "GMSL1_HDMI1" run to end wait dlog  into rslt   ---- program  73 locations for HDMI1X and 75 for GMSL1.
    else
        execute digital pattern "OTP_WRITE_BURST_MATCH_UART"  at label "HDMI2" run to end wait dlog  into rslt      ---- program 228 locations
    end_if

    return(rslt)
end_body





function OTP_Reg_Read_burst(device_id, register, register2,start_addr,stop_addr,addr_jump1, addr_jump_to, addr_jump2,MEM_TYPE): multisite lword[?]-----lword[78]
--------------------------------------------------------------------------------
--  
-------------Man Tran
in word               : device_id, register, register2  ------
in word               : start_addr    -----------first memory location to start read  for HDCP currently gmsl1 start at 5, hmdi1x start at 0,hdmi2x start at 128
in word               : stop_addr   ------------ end of memory address    for HDCP; gmsl1 stop at 81; hdmi1x stop at 73; hdmi2x stop at 355...
in word               : addr_jump1  ------------  memory address jump for HDCP(  gmsl1 jump from 0x4B to 0x79)
in word               : addr_jump_to  ------------ memory address start read again.
in word               : addr_jump2  ------------ for tracability ; provide trim site, date, serial number.... Need check with Mu Li which addrs
in string[20]         : MEM_TYPE
local


word list[MAX_SITES]  : active_sites_local
word                  : siteidx, idx, sites_local
word                  : csite,temp_Array[68]

word                  : send_word[1824]------send_word[616]
multisite word        : cap_data[5304],cap_data_hdmi2[15504]
multisite word        : reg_read[22]
multisite lword       : rread, read_data[78], read_data_hdmi2x[228]
word                  : addr, j
word                  : otp_addr,index,otp_length
end_local

body

    active_sites_local = get_active_sites()
    sites_local = word(len(active_sites_local))

     j = 0----initialized
 -----   
----Setup for burst read: 
---Read protocol: 1. Write cycle nad read cycle
---1. write cycle: synch frame-> device id-> MSB register otp address holder -> LSB register otp address holder->number of bytes-> actual LSB addr-> actual MSB addr->ack
---2> Read cycle : synch fram -> device id +1-> MSB read register-> LSB read register -> number of byte need to read-> ack and capture data  

     for addr = start_addr to stop_addr do                                ---0x81 do 
        if addr = addr_jump1 then                                         ---0x4B  
            addr = addr_jump_to                                          -------- 0x80
        end_if
        otp_addr = addr * 32
        send_word[1+j] = add_parity_bit(device_id)
        send_word[2+j] = add_parity_bit((register & 16#FF00) >> 8)
        send_word[3+j] = add_parity_bit(register & 16#FF)
        send_word[4+j] = add_parity_bit(otp_addr & 16#FF)
        send_word[5+j] = add_parity_bit((otp_addr & 16#FF00) >> 8)  
        send_word[6+j] = add_parity_bit(device_id+1)
        send_word[7+j] = add_parity_bit((register2 & 16#FF00) >> 8)
        send_word[8+j] = add_parity_bit(register2 & 16#FF)   
       j = j+ 8  
    end_for

 --  define digital reg_send fx1 waveform "OTP_WRITE_READ_SEND"        on DES_GPI18_SDA_RX    for 400 vectors serial lsb mode 9 bits
--   define digital capture fx1 waveform  "OTP_CAPTURE_READ_BURST"     on DES_GPI19_SCL_TX     for 68 vectors serial msb mode 4 bits
----depend on type of memory read back set the correct wave form
    if (MEM_TYPE = "GMSL1_HDMI1X") then
        otp_length = 78
        load     digital reg_send fx1 waveform "OTP_WRITE_READ_SEND_HDMI2X"  with send_word
        enable   digital reg_send fx1 waveform "OTP_WRITE_READ_SEND_HDMI2X"
        enable digital capture fx1 waveform "OTP_CAPTURE_READ_BURST_ALL_GMSL1_HDMI1X"
        execute digital pattern "OTP_WRITE_READ_BURST_UART"   at label "GMSL1_HDMI1X" run to end wait
        wait for digital capture fx1 waveform"OTP_CAPTURE_READ_BURST_ALL_GMSL1_HDMI1X"
        read digital capture fx1 waveform "OTP_CAPTURE_READ_BURST_ALL_GMSL1_HDMI1X" into cap_data
    
    else
        otp_length = 228
        load     digital reg_send fx1 waveform "OTP_WRITE_READ_SEND_HDMI2X" with send_word
        enable   digital reg_send fx1 waveform "OTP_WRITE_READ_SEND_HDMI2X"
        enable digital capture fx1 waveform "OTP_CAPTURE_READ_BURST_ALL_HDMI2X"
        execute digital pattern "OTP_WRITE_READ_BURST_UART" at label "HDMI2X"  run to end wait
        wait for digital capture fx1 waveform"OTP_CAPTURE_READ_BURST_ALL_HDMI2X"
        read digital capture fx1 waveform "OTP_CAPTURE_READ_BURST_ALL_HDMI2X" into cap_data_hdmi2    
    end_if
--- Process the data read back ------
    if otp_length < 79 then
        for siteidx=1 to sites_local do
            csite = active_sites_local[siteidx]
            for i = 1 to otp_length do --74 do -------------i = 1 to 75 do --74
                for j = 1 to 68 do
                    index = j+(i-1)*68
                    temp_Array[j] = cap_data[csite, index]   ----cap_data[csite, index]
                end_for
                reg_read[csite] = Analyze_Read_M(temp_Array,4)
------------------Initialized rrread for next loop
                rread[csite] =0      
                for idx=0 to (4-1) do
                    rread[csite] = (lword(reg_read[csite,idx+1]))<<lword(8*idx) + rread[csite]
                end_for
                read_data[csite,i ] = rread[csite]
            end_for
        end_for
    else
        for siteidx=1 to sites_local do
            csite = active_sites_local[siteidx]
            for i = 1 to otp_length do --74 do -------------i = 1 to 75 do --74
                for j = 1 to 68 do
                    index = j+(i-1)*68
                    temp_Array[j] = cap_data_hdmi2[csite, index]   ----cap_data[csite, index]
                end_for
                reg_read[csite] = Analyze_Read_M(temp_Array,4)
----------------Initialized rrread for next loop
                rread[csite] =0      
                for idx=0 to (4-1) do
                    rread[csite] = (lword(reg_read[csite,idx+1]))<<lword(8*idx) + rread[csite]
                end_for
                    read_data_hdmi2x[csite,i ] = rread[csite]

            end_for
        end_for
   end_if

    if otp_length < 79 then ---gmsl1 style
        return (read_data)
    else
        return (read_data_hdmi2x)
        
   end_if
end_body



procedure Prog_None_HDCP(vdd, vdd18, vio, vterm, DEVICE_ADDR_ID, OTP_FAIL_PIN,OTP_DONE_PIN, trimok,SERIAL_NUMBER,SITETRIM,TIMETRIM,YrTrim,MonthTrim,DayTrim,POWERUP,POWERDOWN,SpeedGrade,DualVideo,GRADE,DVideo,WFRNUM,XLOC,YLOC,LOTNUM1, LOTNUM2, LOTNUM3, LOTNUM4, LOTNUM5, LOTNUM6, LOTNUM7, LOTNUM8, LOTNUM9, stuckdetectlim,Reg13Lim,Reg15Lim,Reg15LimOk,PrgFailDoneOkLim,OTPLockLim,InitialTrimCheck510, InitialTrimCheck511,OTP_Enhancement_Check)
--------------------------------------------------------------------------------
--  
in float            : vdd, vdd18, vio, vterm
in_out integer_test : trimok,SERIAL_NUMBER,SITETRIM,TIMETRIM,GRADE,DVideo,YrTrim,MonthTrim,DayTrim
in word             : DEVICE_ADDR_ID      -- SER_ID or DES_ID
in PIN LIST[1]      : OTP_FAIL_PIN,OTP_DONE_PIN
in boolean          : POWERUP,POWERDOWN,SpeedGrade,DualVideo
in_out integer_test :  XLOC, YLOC, WFRNUM
in_out integer_test : LOTNUM1, LOTNUM2, LOTNUM3, LOTNUM4, LOTNUM5, LOTNUM6, LOTNUM7, LOTNUM8, LOTNUM9,Reg13Lim,Reg15Lim,Reg15LimOk,PrgFailDoneOkLim,OTPLockLim
in_out array of integer_test: stuckdetectlim
in_out integer_test : InitialTrimCheck510, InitialTrimCheck511 , OTP_Enhancement_Check


local
word list[16]       : OTP_active_sites

lword               : addr, bit
word                : logical_addr
integer             : idx,q,trim_fail_count
word                : siteidx, thissite
multisite integer   : soak_flagtrim_fail_count
integer             : NEED_PROGRAM = 0
integer             : mem_offset
multisite lword     : otp_write_data[134]
multisite lword     : otp_data,otp_data510
multisite lword     : reg_data,reg_data1
multisite integer   : regvalue
 multisite lword     : tempdata,tempdata1


 multisite boolean   : otp_fail
 multisite boolean   : ALREADY_PROGRAMMED

multisite boolean   :  DEV_FAILED ,otp_prog_ok
lword               :  NUM_OF_KEYS = 0
word list[4]        :  key_failure_sites = <::>
string[6]           :  OTP_TEMP = "HOT"
word                :  DEV_ID 
multisite lword     :  otp_addr
multisite lword     :  first_fail_loc,fail_count
multisite lword     : readback_data[712], read_data_burst[78]
integer             : array_index
float               : time_meas
float               :  Vconf0, Vconf1
multisite integer   : prog_ok,otp_blank_test
multisite lword     :  lowword, upperword
word                :  sites, site, begin_sites
multisite integer   : reg_val,  serial_num, sitetrim,time_trim,speedgrade,dualvideo,year_trim,month_trim,day_trim
  integer      : time_h, time_m, time_s
  integer      : date_m, date_d, date_y

multisite lword     : temp_write_data[6]

string[20]          : TestTemp,TestType 
multisite lword     :  ws_read_value[8]
multisite integer       : lot_chr1, lot_chr2, lot_chr3, lot_chr4, lot_chr5, lot_chr6, lot_chr7, lot_chr8, lot_chr9
multisite integer       : x_rslt, y_rslt, wafer_rslt, x_coord_rd, y_coord_rd



  word list[16]         : current_active_sites_retest
  word LIST[MAX_SITES]  : local_active_sites
  word                  : Csite, local_sites
  word                 : inx
  multisite integer    : DevIdCalc
  multisite integer    : IntDieID, IntDieRev
  multisite integer    : WAFERHEX, XHEX, YHEX, foundStuck
   boolean               : StuckDetect

  multisite lword      : Reg15Val, Reg13Val
  multisite integer    : Reg15ValInt, Reg13ValInt, Reg15ValOk,Loc511Data,OTPLock
  multisite float      : measdone,meas_prg_fail
  multisite boolean    : DonePinHigh,PrgFailPin,PartFail
  boolean              : PrgLoc511
  string[6]            : Test_Type
  string[15]           : Part_Num
  multisite lword      : reg_data84Min,reg_data85Min ,reg_data86Min  ,reg_data84Max,reg_data85Max,reg_data86Max

  multisite lword      : reg_data81Min,reg_data511Min,reg_data81Max,reg_data511Max, reg_data510Max, reg_data_510_TrimCheck,  reg_data_511_TrimCheck
  multisite integer    : DataMinMaxNotEq
  multisite integer    : TrimmedCheck510fail, TrimmedCheck511fail,  trimcheck_enhancement, OTP8_PgmFail_Check, OTP8_PgmDone_Check

end_local






body

static    lword     : serial_number =  0
   get_expr("OpVar_TestType", TestType)  -- determine test type, QA or FT
   get_expr("OpVar_TestTemp", TestTemp)  -- determine test temperature, (ROOM, HOT, COLD)
   
    get_expr("OpVar_ProductUnderTest", Part_Num)

  TrimmedCheck510fail = 0 
  TrimmedCheck511fail = 0
  trimcheck_enhancement = 0
  otp_fail = FALSE
  DEV_ID = DEVICE_ADDR_ID
--serial_number =  139
  current_active_sites = get_active_sites()
  sites = word(len(current_active_sites))

   time(time_h, time_m, time_s)     -- get time
   date(date_m, date_d, date_y)     -- get date
   get_expr("OpVar_TestTemp", TestTemp )
   get_expr("OpVar_TestType", TestType )

------------ Power Up HS89 -----------------------
-- 
--     active_sites = get_active_sites
--     sites = word(len(active_sites))  

    --POWER_CONNECT    -- need this for reseting device
    
    -- can take out later but keep for now to make sure all MFP pins connected to DPs
      open cbit MFP_LT_RELAY  

    --make sure RSVD pin float (HVVI disconnect)
    disconnect hvvi chan SER_RSVD    -- need to float RSVD, important!!
    connect digital pin ALL_PATTERN_PINS to dcl
    disconnect digital pin SER_CAPVDD from dcl                 -- need to float CAP_VDD pin  
    wait(3ms) 

        -----Dut power up function
   DutPowerUp(vio, vdd18, vdd, "UART", "TP_GMSL2",POWERUP)

 wait(0ms) 

----Check WS INFO
            OTP_Reg_Write(DEV_ID, OTP0,1, mlw(0x40), 0,mlw(0))---Enable OPT read 
            OTP_Reg_Write(DEV_ID, OTP1,1, mlw(0x00), 0, mlw(0))---Select GMSL section        

-- Move WS Info Read after Contact Test   
--        for  addr =0  to  0x4 do ---  ws info
--             otp_addr =  32*(addr)	   
--             OTP_Reg_Write(DEV_ID, 16#1802,2, otp_addr, 0,mlw(0x00) )---set address to read from
--             array_index = array_index + 1 
--             reg_data = OTP_Reg_Read(DEV_ID, 16#1814, 4)
--             for siteidx = 1 to sites do  
--                 thissite =current_active_sites [siteidx]                   
--                 ws_read_value[thissite,addr + 1] = reg_data[thissite]
--             end_for    
--        end_for
       
       ------------------ Deternmine if a part has been trimmed or not by reading CRC locations and lock  zin 2/19/2020 -------------------------
       
        ----Read location 510 to see Pre Trim Status
        otp_addr =  32*510	   
        OTP_Reg_Write(DEV_ID, OTP2,2, otp_addr, 0,mlw(0x00) )---set address to read from   
        tempdata1 = OTP_Reg_Read(DEV_ID, OTP14, 4)    
         reg_data_510_TrimCheck = tempdata1
       
       
        ----Read location 511 to see Pre Trim Status
        otp_addr =  32*511	   
        OTP_Reg_Write(DEV_ID, OTP2,2, otp_addr, 0,mlw(0x00) )---set address to read from   
        tempdata1 = OTP_Reg_Read(DEV_ID, OTP14, 4)    
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

-- Move WS read Info after contact test
-- ----Process and decode data
--     for siteidx = 1 to sites do
--         thissite = current_active_sites[siteidx]
-- 
-- --         lot_id_scramble[thissite] = chr(ws_trim_info[1])+chr(ws_trim_info[2])+chr(ws_trim_info[3])+chr(ws_trim_info[4])+chr(ws_trim_info[5])+chr(ws_trim_info[6])+chr(ws_trim_info[7])+chr(ws_trim_info[8])+chr(ws_trim_info[9])
--         lot_chr1[thissite] = integer((ws_read_value[thissite,2] & 16#0000FF00)>>8)
--         lot_chr2[thissite] = integer((ws_read_value[thissite,2] & 16#00FF0000)>>16)
--         lot_chr3[thissite] = integer((ws_read_value[thissite,2] & 16#FF000000)>>24)
--         lot_chr4[thissite] = integer((ws_read_value[thissite,3] & 16#000000FF)>>0)
--         lot_chr5[thissite] = integer((ws_read_value[thissite,3] & 16#0000FF00)>>8)
--         lot_chr6[thissite] = integer((ws_read_value[thissite,3] & 16#00FF0000)>>16)
--         lot_chr7[thissite] = integer((ws_read_value[thissite,3] & 16#FF000000)>>24)
--         lot_chr8[thissite] = integer((ws_read_value[thissite,4] & 16#000000FF)>>0)
--         lot_chr9[thissite] = integer((ws_read_value[thissite,4] & 16#0000FF00)>>8)
--         wafer_rslt[thissite] = integer((ws_read_value[thissite,2] & 16#000000FF) >> 0)
--         x_coord_rd[thissite] = integer((ws_read_value[thissite,1] & 16#0000FFFF) >> 0)
--         y_coord_rd[thissite] = integer((ws_read_value[thissite,1] & 16#FFFF0000) >> 16)
-- 
--     if (x_coord_rd[thissite] >> 15 = 1) then
--         x_rslt[thissite] = integer((x_coord_rd[thissite] & 16#7FFF)*(-1))
--     else
--         x_rslt[thissite] = x_coord_rd[thissite]
--     end_if
--     
--     if (y_coord_rd[thissite] >> 15 = 1) then
--         y_rslt[thissite] = integer((y_coord_rd[thissite] & 16#7FFF)*(-1))
--     else
--         y_rslt[thissite] = y_coord_rd[thissite]
--     end_if
--     
--     end_for

  ----------- Register 13 & 15 to determine if device is already trimmed  -------------
  ----------- Check for HDCP capable bit and device ID --------------------------------
   
    reg_data = OTP_Reg_Read(SER_ID, REG13, 1)       -- DevID No Trim MAX96755 (REG13 = 155) , MAX96755F Trimmed (REG13 = 155) , MAX96757 Trimmed  (REG13 = 156), MAX96757F Trimmed  (REG13 = 156)
    regvalue = integer(reg_data)
    reg_data1 = OTP_Reg_Read(SER_ID, REG15, 1)      -- (Trimed Capability) No Trim MAX96755 (REG15 = 0) , Trimmed Part will read REG15 > 0 , MAX96755F REG15 = 32 (0x20) , MAX96757 REG15 = 1 (0x01), MAX96757F REG15 = 33 (0x21) 
    RegRead(SER_ID, 0x1808 , 1,  upperword,lowword, "SER_UART_Read")      ---Check memory lock bit. Make sure it is high
    OTPLock =   integer(lowword)   -- OTP RD DONE and OTP LOCK  1000 1000 (0x88)     


    
    for siteidx = 1 to sites do
        thissite = current_active_sites[siteidx]   
        OTPLock[thissite] =   (integer(lowword[thissite]) &0x8) >> 3
    end_for
   
---OTP read memory----
       OTP_Reg_Write(DEV_ID, OTP0,1, mlw(0x00), 0, mlw(0x00))---disable program
       OTP_Reg_Write(DEV_ID,OTP0 ,1, mlw(0x40), 0, mlw(0x00))---enable read
       fail_count =0 ---reset fail_count variable 

----------------------------------------------------------
       for  addr =0x84  to  0x84 do ---  11 to  0x83     
        
            otp_addr =  32*(addr)	   
            OTP_Reg_Write(DEV_ID, 16#1802,2, otp_addr, 0,mlw(0x00) )---set address to read from/ Just checking OTP5 contents
            array_index = array_index + 1 
            reg_data = OTP_Reg_Read(DEV_ID, 16#1814, 4)
            for siteidx = 1 to sites do  
                thissite =current_active_sites [siteidx]                   
                if reg_data[thissite] = 0 then --- part not trimmed yet
                    NEED_PROGRAM = NEED_PROGRAM+1
                else 
                    deactivate site thissite  --- already trimmed no need to
                end_if
            end_for    
       end_for
     
     ------------------TestTemp ="HOT" -- need to take out this Zin force trim at Room
-----       
   if (NEED_PROGRAM >=1 and (TestTemp ="HOT")and TestType ="FT"  ) then  -- If at least one site needs to be OTP'ed, execute block
        
        OTP_active_sites = get_active_sites()  -- sites active for OTP trim
        sites = word(len(OTP_active_sites))
-----Modify procedure to  the newest require by DE. Trim at Vddio = 2.75V, Vdd18 =2.1V, and Vdd = 0.95
        reg_data = OTP_Reg_Read(DEV_ID, SR_CTRL0, 1) 
        OTP_Reg_Write(DEV_ID, DR_CTRL0,1, (reg_data | 0x40), 0,mlw(0x00) )--------Turn off GMLS phy for trim because with this rev Vdd18 = 2.1V to trim it is higher then abmax spec 9/2018
---       Set_SER_Voltages(vio, vdd, vdd18)
        Set_SER_Voltages(2.75, 0.95, 2.1 )

---------------------------- OTP Programming 
        OTP_Reg_Write(DEV_ID, OTP0,1, mlw(0x00), 0,mlw(0))---disable read OTP0 =0X1800 FOR HS89
        OTP_Reg_Write(DEV_ID, OTP1,1, mlw(0x02), 0, mlw(0))---enable  OTP_PGM_DONE and OTP_PGM_FAIL to GPIO15  and GPIO14  and select GMSL section OTP1 = 0X1801
---OTP Write 
        OTP_Reg_Write(DEV_ID, OTP0,1, mlw(0x20), 0, mlw(0))---enable write 
 
        set digital pin OTP_DONE_PIN + OTP_FAIL_PIN modes to driver pattern comparator enable all fails
        set digital pin  OTP_DONE_PIN + OTP_FAIL_PIN levels to vih 0.9*vio vil 0.1*vio vol 0.5*vio voh 0.5*vio iol 0mA ioh 0mA vref 0V
   
-----This is just for debug by program single location at a time MT

----Program location 84,85 and 86 for time stamp 
        for siteidx =1 to sites do
            thissite = OTP_active_sites[siteidx]
            serial_number = serial_number + 1 --- increase 1
            temp_write_data[thissite,4] =  (lword(thissite) << 20 )|serial_number
            temp_write_data[thissite,5] =  (lword(time_h) << 16 )| (lword(time_m) << 8 )| (lword(time_s)  )-----Program time this device was trimed
            temp_write_data[thissite,6] =  (lword(date_y) << 16 )| (lword(date_m) << 8 )| (lword(date_d)  )-----Program time this device was trimed
        end_for

        for addr =  4 to 6 do ---- addr =  0x84to 0x86 do 
            otp_addr = (addr + 0x80) * 32      ---0x80
	
	   for siteidx =1 to sites do
	       thissite = OTP_active_sites[siteidx]
               otp_data[thissite] = temp_write_data[thissite,addr]
	   end_for	
            OTP_Reg_Write(DEV_ID, 16#1802,2, otp_addr, 4, otp_data )---Write data to address
            wait(10ms) --- will work this out time wait for otp done/fail---50
            
            --z read digital pin OTP_DONE_PIN state compare to high into DonePinHigh   ----expect high MT 1/2020
            --z read digital pin OTP_FAIL_PIN  state compare to low into PrgFailPin    ---expect low  

       -- Reading OTP8 to check OTP_PGM_DONE and OTP_PGM_FAIL
       
        RegRead(SER_ID, 0x1808 , 1,  upperword,lowword, "SER_UART_Read")      ---Check OTP8 bit4 to check OTP_PGM_FAIL status
        OTPLock =   integer(lowword)   -- OTP RD DONE and OTP LOCK  1000 1000 (0x88) 
        
         for siteidx =1 to sites do
	       thissite = OTP_active_sites[siteidx]
	       
	       OTP8_PgmFail_Check[thissite] = OTPLock[thissite] & 0x10 >> 4
	       OTP8_PgmDone_Check[thissite] = OTPLock[thissite] & 0x20 >> 5
	       
	       if ( OTP8_PgmDone_Check[thissite] = 0 or OTP8_PgmFail_Check[thissite] = 1) then  
	       	      trimcheck_enhancement [thissite] = 1  -- program fail
	       end_if  
	       	       
	       if ( OTP8_PgmDone_Check[thissite] = 1 and (OTP8_PgmFail_Check[thissite] = 1) ) then	       
	          
	           trimcheck_enhancement [thissite] = 1  -- program fail
	       
	       end_if
	       
	 end_for 



         
	   for siteidx =1 to sites do
	       thissite = OTP_active_sites[siteidx]
               if( trimcheck_enhancement [thissite] = 1  )then
                    PartFail[thissite] = true
                    PrgLoc511 = true
                end_if
	   end_for 
	   
	          
      end_for
            
            if SpeedGrade or DualVideo then
                if SpeedGrade then
                    if Part_Num = "MAX96755F" then
                        otp_data = 0x20_00_00_00
                    end_if
                    
                    if Part_Num = "MAX96755R" then   --for now
                        otp_data = 0x20_00_00_00
                    end_if
                    
                    if Part_Num = "MAX96755H" then
                        otp_data = 0x30_00_00_00
                    end_if                   
                                      
                end_if    
                
                if DualVideo then
                    otp_data = 0x08_00_00_00 ----  0x09_00_00_00 trim hdcp enable for supply current measurement  (MAX9295E)
                end_if
                
                otp_addr = 0x81*32
                OTP_Reg_Write(DEV_ID, 16#1802,2,otp_addr , 4, otp_data )---Write data to address  0x81
                wait(10ms) --- will work this out time wait for otp done/fail           
                
                --z read digital pin OTP_DONE_PIN state compare to high into DonePinHigh   ----expect high MT 1/2020
                --z read digital pin OTP_FAIL_PIN  state compare to low into PrgFailPin    ---expect low 
                
                -- Reading OTP8 to check OTP_PGM_DONE and OTP_PGM_FAIL
       
                RegRead(SER_ID, 0x1808 , 1,  upperword,lowword, "SER_UART_Read")      ---Check OTP8 bit4 to check OTP_PGM_FAIL status
                OTPLock =   integer(lowword)   -- OTP RD DONE and OTP LOCK  1000 1000 (0x88) 
        
                for siteidx =1 to sites do
	            thissite = OTP_active_sites[siteidx]
	       
	           OTP8_PgmFail_Check[thissite] = OTPLock[thissite] & 0x10 >> 4
	           OTP8_PgmDone_Check[thissite] = OTPLock[thissite] & 0x20 >> 5	
	           
	       if ( OTP8_PgmDone_Check[thissite] = 0 or OTP8_PgmFail_Check[thissite] = 1) then  
	       	      trimcheck_enhancement [thissite] = 1  -- program fail
	       end_if         
	       	       
	           if ( OTP8_PgmDone_Check[thissite] = 1 and (OTP8_PgmFail_Check[thissite] = 1) ) then	       
	          
	               trimcheck_enhancement [thissite] = 1  -- program fail
	       
	           end_if
	       
	       end_for  
	        
	       for siteidx =1 to sites do
	           thissite = OTP_active_sites[siteidx]
                    if( not trimcheck_enhancement [thissite] = 0  )then
                        PartFail[thissite] = true
                       PrgLoc511 = true
                    end_if
	       end_for 
	             
           end_if
---------if part failed done or prog then program BAD data to location 511
        if PrgLoc511 then
            for siteidx =1 to sites do
	       thissite = OTP_active_sites[siteidx]
                if PartFail[thissite] then
                    otp_data[thissite] = 0xEFEFEFEF
                    otp_data510[thissite] = 0xFEFEFEFE
                else
                    otp_data[thissite] = 0x0
                end_if
	   end_for
           otp_addr = 511*32
           OTP_Reg_Write(DEV_ID, 16#1802,2,otp_addr , 4, otp_data )---Write data to address
           wait(10ms) --- will work this out time wait for otp done/fail 
           otp_addr = 510*32
           OTP_Reg_Write(DEV_ID, 16#1802,2,otp_addr , 4, otp_data510 )---Write data to address
           wait(10ms) --- will work this out time wait for otp done/fail 
	end_if          
--   RegRead(SER_ID, 0x1808 , 1,  upperword,lowword, "SER_UART_Read") 


---OTP Write lock
    for i = 1 to 4 do 
        OTP_Reg_Write(DEV_ID, 16#1800,1, mlw(0x10), 0, mlw(0))---enable write and lock
        wait(1ms)          
        OTP_Reg_Write(DEV_ID, 16#1800,1, mlw(0x00), 0, mlw(0))---enable write and lock
    end_for

                  -- Reading OTP8 to check OTP_PGM_DONE and OTP_PGM_FAIL
       
        RegRead(SER_ID, 0x1808 , 1,  upperword,lowword, "SER_UART_Read")      ---Check OTP8 bit4 to check OTP_PGM_FAIL status
        OTPLock =   integer(lowword)   -- OTP RD DONE and OTP LOCK  1000 1000 (0x88) 
        
         -- for siteidx =1 to sites do
-- 	       thissite = OTP_active_sites[siteidx]
-- 	       
-- 	       OTP8_PgmFail_Check[thissite] = OTPLock[thissite] & 0x10 >> 4
-- 	       OTP8_PgmDone_Check[thissite] = OTPLock[thissite] & 0x20 >> 5
-- 	       
-- 	       if ( OTP8_PgmDone_Check[thissite] = 0 or OTP8_PgmFail_Check[thissite] = 1) then  
-- 	       	      trimcheck_enhancement [thissite] = 1  -- program fail
-- 	       end_if  	       
-- 	       	       
-- 	       if ( OTP8_PgmDone_Check[thissite] = 1 and (OTP8_PgmFail_Check[thissite] = 1) ) then	       
-- 	          
-- 	           trimcheck_enhancement [thissite] = 1  -- program fail
-- 	       
-- 	       end_if
-- 	       
-- 	 end_for  


    DutPowerUp(vio, vdd18, vdd, "UART", "TP_GMSL2",POWERUP)
  ---Change supply to 1.7 as requested by DE
        if Test_Type = "QA" then
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
      
       OTP_Reg_Write(DEV_ID, OTP0,1, mlw(0x00), 0, mlw(0x00))---disable program
       OTP_Reg_Write(DEV_ID,OTP0 ,1, mlw(0x40), 0, mlw(0x00))---enable read
        prog_ok =0 ---reset fail_count variable 

        for addr =  4 to 6 do ---- addr =  82 to 0x84 do 
            otp_addr =  32*(addr + 0x80)	   
            OTP_Reg_Write(DEV_ID, 16#1802,2, otp_addr, 0,mlw(0x00) )---set address to read from
            array_index = array_index + 1 
            reg_data = OTP_Reg_Read(DEV_ID, 16#1814, 4)
            for siteidx = 1 to sites do  
                thissite =OTP_active_sites [siteidx]                   
                if (reg_data[thissite] <> temp_write_data[thissite,addr]) or PartFail[thissite]  then
                    prog_ok[thissite] = prog_ok[thissite] + 1
                end_if
            end_for    
        end_for
-----------------Need addition condition for max read back
    Set_SER_Voltages(3.6, 1.05, 1.9) -- Vmax for both QA and FT

        for addr =  4 to 6 do ---- addr =  82 to 0x84 do 
            otp_addr =  32*(addr + 0x80)	   
            OTP_Reg_Write(DEV_ID, 16#1802,2, otp_addr, 0,mlw(0x00) )---set address to read from
            array_index = array_index + 1 
            reg_data = OTP_Reg_Read(DEV_ID, 16#1814, 4)
            for siteidx = 1 to sites do  
                thissite =OTP_active_sites [siteidx]                   
                if (reg_data[thissite] <> temp_write_data[thissite,addr]) or PartFail[thissite]  then
                    prog_ok[thissite] = prog_ok[thissite] + 2
                end_if
            end_for    
        end_for


-- --------------------------------end of verify  -----
    end_if 


----Read data at Vmax
 
    activate site current_active_sites
    sites = word(len(current_active_sites)) --- get number of sites at begining

    Set_SER_Voltages(3.6, 1.05, 1.9) -- Vmax for both QA and FT

----------------------------------
 -----Read memory location 0x84 and 85; serial number and date trimmed 
       OTP_Reg_Write(DEV_ID, OTP0,1, mlw(0x40), 0,mlw(0))---Enable OPT read 
       OTP_Reg_Write(DEV_ID, OTP1,1, mlw(0x00), 0, mlw(0))---Select GMSL section

      otp_addr =  32*(0x84)	   
      OTP_Reg_Write(DEV_ID, OTP2,2, otp_addr, 0,mlw(0x00) )---set address to read from   
      reg_data = OTP_Reg_Read(DEV_ID, OTP14, 4)
      reg_data84Max  = reg_data   ---added

      otp_addr =  32*(0x85)	   
      OTP_Reg_Write(DEV_ID, OTP2,2, otp_addr, 0,mlw(0x00) )---set address to read from   
      tempdata = OTP_Reg_Read(DEV_ID, OTP14, 4)
      reg_data85Max   =     tempdata
      otp_addr =  32*(0x86)
      OTP_Reg_Write(DEV_ID, OTP2,2, otp_addr, 0,mlw(0x00) )---set address to read from   
      tempdata1 = OTP_Reg_Read(DEV_ID, OTP14, 4)
      reg_data86Max   =     tempdata1     
     
      for siteidx = 1 to sites do
          thissite = current_active_sites[siteidx]  
          sitetrim[thissite] = integer(reg_data[thissite] & 0xFFFFFF)>> 20
          serial_num[thissite] = integer(reg_data[thissite]) & 0xFFFF
          time_trim[thissite] = integer(tempdata[thissite]) & 0xFFFFFF ---Datalog out minute and second 
          year_trim[thissite] = integer(tempdata1[thissite]) >> 16
          month_trim[thissite] = integer((tempdata1[thissite]) >> 8) & 0xFF
          day_trim[thissite] = integer(tempdata1[thissite])  & 0xFF
          

      end_for
------ read device ID
   RegRead(SER_ID, SR_REG15 , 1,  upperword,Reg15Val, "SER_UART_Read")  ---- read function bit trim
   RegRead(SER_ID, SR_REG13 , 1,  upperword,Reg13Val, "SER_UART_Read") ---- read device ID. 8x8HDCP = 0x9C, 8x8NoneHDCP=0x9B
   RegRead(SER_ID, 0x1808 , 1,  upperword,lowword, "SER_UART_Read")      ---Check memory lock bit. Make sure it is high
   OTPLock =   integer(lowword)
--    if SpeedGrade or DualVideo then--- read back value
        otp_addr =  32*(0x81)	   
        OTP_Reg_Write(DEV_ID, OTP2,2, otp_addr, 0,mlw(0x00) )---set address to read from   
        tempdata = OTP_Reg_Read(DEV_ID, OTP14, 4)    
        reg_data81Max = tempdata

----Read location 511 to see if part failed Prog or done bit during trim. If it is failed then data = 0xBAD  MT 1/2020
        otp_addr =  32* 511	   
        OTP_Reg_Write(DEV_ID, OTP2,2, otp_addr, 0,mlw(0x00) )---set address to read from   
        tempdata1 = OTP_Reg_Read(DEV_ID, OTP14, 4)    
        reg_data511Max = tempdata1

      for siteidx = 1 to sites do
          thissite = current_active_sites[siteidx]   
          if  ( tempdata[thissite] & 0x20000000 == 0x20000000 or tempdata[thissite] & 0x30000000 == 0x30000000)  then
                speedgrade[thissite] = 1
          else
                speedgrade[thissite] = 0
          end_if
          
          if  ( tempdata[thissite] & 0x08_00_00_00 == 0x08_00_00_00 or tempdata[thissite] & 0x09_00_00_00 == 0x09_00_00_00)  then
                dualvideo[thissite] = 1
          else
                dualvideo[thissite] = 0
          end_if   

        Reg15ValInt[thissite] =  integer(Reg15Val[thissite])
        Reg13ValInt[thissite] =  integer(Reg13Val[thissite])
        Loc511Data[thissite] =  integer(tempdata1[thissite])
        OTPLock[thissite] =   (integer(lowword[thissite]) &0x8) >> 3

        if SpeedGrade then
             Reg15ValOk[thissite] = (Reg15ValInt[thissite] & 0xFF)>>5      ----Max96755F
        elseif DualVideo then    
             Reg15ValOk[thissite] = (Reg15ValInt[thissite] & 0xFF)>>3    ----Max9295E
        else 
            if  Reg15ValInt[thissite] = 0 then            ----Max96755
                Reg15ValOk[thissite] = 1
            else
                Reg15ValOk[thissite] = -1
            end_if
        end_if
    end_for


   ---Change supply to 1.7 as requested by DE
    if Test_Type = "QA" then
        Set_SER_Voltages(1.7, 0.95, 1.7)
    else
        if OTP_TEMP = "COLD" then
           Set_SER_Voltages(1.7, 0.95, 1.58) -------- FT flow  cold
        else
            Set_SER_Voltages(1.7, 0.95, 1.68) -------- FT flow
       end_if   
   end_if     


 -----Read memory location 0x84 and 85; serial number and date trimmed 
       OTP_Reg_Write(DEV_ID, OTP0,1, mlw(0x40), 0,mlw(0))---Enable OPT read 
       OTP_Reg_Write(DEV_ID, OTP1,1, mlw(0x00), 0, mlw(0))---Select GMSL section

      otp_addr =  32*(0x84)	   
      OTP_Reg_Write(DEV_ID, OTP2,2, otp_addr, 0,mlw(0x00) )---set address to read from   
      reg_data = OTP_Reg_Read(DEV_ID, OTP14, 4)

      reg_data84Min  = reg_data   ---added
      otp_addr =  32*(0x85)	   
      OTP_Reg_Write(DEV_ID, OTP2,2, otp_addr, 0,mlw(0x00) )---set address to read from   
      tempdata = OTP_Reg_Read(DEV_ID, OTP14, 4)
      reg_data85Min  = tempdata
      
      otp_addr =  32*(0x86)
      OTP_Reg_Write(DEV_ID, OTP2,2, otp_addr, 0,mlw(0x00) )---set address to read from   
      tempdata1 = OTP_Reg_Read(DEV_ID, OTP14, 4)
      reg_data86Min  = tempdata1
        
        otp_addr =  32*(0x81)	   
        OTP_Reg_Write(DEV_ID, OTP2,2, otp_addr, 0,mlw(0x00) )---set address to read from   
        tempdata = OTP_Reg_Read(DEV_ID, OTP14, 4)    
        reg_data81Min  = tempdata

----Read location 511 to see if part failed Prog or done bit during trim. If it is failed then data = 0xFEFEFEFE  MT 1/2020
        otp_addr =  32*511	   
        OTP_Reg_Write(DEV_ID, OTP2,2, otp_addr, 0,mlw(0x00) )---set address to read from   
        tempdata1 = OTP_Reg_Read(DEV_ID, OTP14, 4)    
        reg_data511Min  = tempdata1

-----Now compare Vmin and Vmax data 
    for siteidx = 1 to sites do
        thissite = current_active_sites[siteidx]
        if(reg_data511Min[thissite]<>reg_data511Max[thissite] or reg_data81Min[thissite]<>reg_data81Max[thissite] or reg_data84Min[thissite]<>reg_data84Max[thissite] or reg_data85Min[thissite]<>reg_data85Max[thissite]or reg_data86Min[thissite]<>reg_data86Max[thissite])then

            DataMinMaxNotEq[thissite] = 1
        end_if
    end_for        


wait(0)


---------------- Power Off -------------------
  disconnect digital pin OTP_FAIL_PIN + OTP_DONE_PIN from ppmu
  connect digital pin OTP_FAIL_PIN + OTP_DONE_PIN to dcl
  wait(200us)
--------  DutPowerDown
 ------ Power Off ----
  set digital pin ALL_PATTERN_PINS - fpga_pattern_pins levels to vil 0V vih 100mV iol 0uA ioh 0uA vref 0V
  wait(100us)
  
  set digital pin ALL_PATTERN_PINS modes to comparator enable all fails
  set hcovi SER_VDD+SER_VDDIO +SER_VDD18 to fv 0V vmax 4V clamp imax 600mA imin -600mA   

  wait(3ms)     -- extra for 47uF cap on SER_VDD    
  -- Initialize for set_SER_Voltages(vio, vcore, v18) routine
  vdd_global[1] = 0V   --SER_VDDIO
  vdd_global[2] = 0V   --SER_VDD  
  vdd_global[3] = 0V   --SER_VDDA(VDD18)

----Datalog out

    test_value TrimmedCheck510fail with InitialTrimCheck510
    test_value TrimmedCheck511fail with InitialTrimCheck511
    test_value OTPLock             with OTPLockLim -- 03/26/2020 move Lockbit test binning here 
     
    if NEED_PROGRAM > 0 then  ----data log trim 
        test_value  prog_ok with trimok
    end_if 

     test_value serial_num with SERIAL_NUMBER
     test_value sitetrim with SITETRIM
     test_value time_trim with TIMETRIM
     test_value year_trim with YrTrim
     test_value month_trim with MonthTrim
     test_value day_trim with DayTrim
     
-- Stuck Detect Move at Read WS info test
-- get_expr("OpVar_StuckDetect", StuckDetect)       
-- if StuckDetect then
-- local_active_sites = get_active_sites()
-- local_sites = word(len(local_active_sites))
--     for inx = 1 to local_sites do
--     Csite = local_active_sites[inx]
--     WAFERHEX[Csite] = (wafer_rslt[Csite] << 16)
--         if (x_rslt[Csite] < 0) then
--             XHEX[Csite] = ((abs(x_rslt[Csite]) + 128) << 8)
--             else
--             XHEX[Csite] = (x_rslt[Csite] << 8)
--             end_if
--         if (y_rslt[Csite] < 0) then
--             YHEX[Csite] = (abs(y_rslt[Csite]) + 128)
--             else
--             YHEX[Csite] = y_rslt[Csite]
--             end_if
--         CurDevCode[Csite] = WAFERHEX[Csite] + XHEX[Csite] + YHEX[Csite]
--         if (CurDevCode[Csite] == 0) then
--             foundStuck[Csite] = 1
--         else_if (CurDevCode[Csite] <> PrevDevCode[Csite]) then
--             foundStuck[Csite] = 0
--             StuckCounter[Csite] = 0
--         else
--             foundStuck[Csite] = (-1)
--             StuckCounter[Csite] = StuckCounter[Csite] + 1
--         end_if
--         PrevDevCode[thissite] = CurDevCode[thissite]  -- 01/13/2020 hcu added missing code to get the previous value
--     end_for
-- 
-- test_value foundStuck with stuckdetectlim
-- 
-- end_if    


--    if SpeedGrade then
     test_value speedgrade with GRADE
--    end_if
--    if DualVideo then
     test_value dualvideo with DVideo
--    end_if    

-- Move WS read info after contact test
--     test_value wafer_rslt           with WFRNUM
--     test_value x_rslt               with XLOC
--     test_value y_rslt               with YLOC
--     test_value lot_chr1             with LOTNUM1
--     test_value lot_chr2             with LOTNUM2
--     test_value lot_chr3             with LOTNUM3
--     test_value lot_chr4             with LOTNUM4
--     test_value lot_chr5             with LOTNUM5
--     test_value lot_chr6             with LOTNUM6
--     test_value lot_chr7             with LOTNUM7
--     test_value lot_chr8             with LOTNUM8
--     test_value lot_chr9             with LOTNUM9
    
    test_value trimcheck_enhancement with OTP_Enhancement_Check

    test_value Reg13ValInt         with Reg13Lim
    test_value Reg15ValInt         with Reg15Lim
    test_value Reg15ValOk          with Reg15LimOk
    test_value Loc511Data          with PrgFailDoneOkLim
   -- test_value OTPLock             with OTPLockLim

end_body

function OTP_Real_Key_gmsl_1X(otp_temp, sitenum, speed_grade_trim, keytype,serial_n) : lword[134]

--------------------------------------------------------------------------------
--  This function to grabe key from the pool and then format keys to real_key for otp 
in string[6] : otp_temp  -- Temperature at which HDCP key is to be trimmed.
                         -- Should be "ROOM" or "HOT"
in word      : sitenum   -- site requesting HDCP key
--in lword     : die_rev   -- Die Revision (0 = pass 1), (1 = pass 2), etc no longer needed  for gmsl2 part
in lword     : speed_grade_trim
in lword     : serial_n
in string[10]         : keytype   -- (SER_PTX01 or DES_PRX01)

local 

    integer         : status = -2
    lword           : hdcp_bytes[2052]
    lword           : real_keys[134]
    string[4]       : TestType
    string[6]       : TestTemp
    string[8]       : response
    float           : ttime

end_local


body

   get_expr("OpVar_TestType", TestType)  -- determine test type, QA or FT
   get_expr("OpVar_TestTemp", TestTemp)  -- determine test temperature, (ROOM, HOT, COLD)
   
   hdcp_bytes = 0   -- redundant assignment to make sure arrays are set to 0
   real_keys = 0    -- redundant assignment to make sure arrays are set to 0
   
   HDCP_key_server_code[sitenum] = 0  -- reset variable
 
 Key_Type = keytype 
-- Get an HDCP key only during final test (FT) and for temperature selected by otp_temp
   if TestType == "FT" AND TestTemp == otp_temp then

--      start_timer
--      if Not Key_Pool_Refreshed then
--         status = call_c_library("dalPopulatePool_wrapper", Key_Type, numKeys)
--      end_if
      

      status = call_c_library("dalGetSingleKey_wrapper", hdcp_bytes, Key_Type, &keyID[sitenum])               

      Key_Pool_Refreshed = FALSE
--      key_time[sitenum] = stop_timer
      
   end_if
   

-- Set or Clear the Global Flag fetched_HDCP_key which is used to determine if an HDCP key was succesfully fetched   
   if status ==0 then
      fetched_HDCP_key[sitenum] = TRUE
      set_expr("GRABBED_HDCP_KEY.Meas",TRUE)  -- used for binning
      
      real_keys = Format_Keys_gmsl_1X(hdcp_bytes, speed_grade_trim, sitenum,serial_n)  -- format keys for OTP
   else
      fetched_HDCP_key[sitenum] = FALSE
   end_if
--   status = call_c_library("dalLogSingleKey_wrapper", 3, "134",1)
 
-- Print message if HDCP key SHA1 hash check fails
   if status == -1 then
      Print_banner_message("HDCP key SHA1 hash check error!","","")
   end_if
   
   
-- Print message if there is an error obtaining an HDCP key from the server   
   if status > 0 then
      Print_banner_message("HDCP KEY SERVER ERROR","Please notify test engineer if problem persists","Press 'Enter' to Continue")
      input(stdin, response!L)
      HDCP_key_server_code[sitenum] = status   -- HDCP_key_server_code will be datalogged to indicate HDCP key server errors
   end_if
   


-- return the fetched key     
    return (real_keys)


end_body



function Format_Keys_gmsl_1X(hdcp_key_array, speed_grade_trim,trimsite,serialnumber) : lword[134]

--------------------------------------------------------------------------------
-- The HDCP keys returned by the key server are in a certain order according to  
-- the "HDCP Signing Facility User's Guide"
-- The KSV occupies the first 8 bytes. The most significant 3 bytes are filled with zeros.
-- The next 280 bytes are the device keys (Key0 - Key39). Each device key is 7 bytes long.
-- They are stored in little-endian format, such that the least significant byte is the
-- first byte of the sequence, followed by bytes of increasing significance until the
-- last byte which is the most significant byte.

in lword : hdcp_key_array[2052]  -- this is the array in the format as described above.
                                -- this function will format it so it is ready to be OTP'ed
				-- into the device.
in lword  : speed_grade_trim            -- trim speed grade bit                       
in lword  : serialnumber   ---- serial number
in word   : trimsite
local

  lword         : formatted_keys[134] -- formatted hdcp keys ready to be OTP'ed
  lword         : idx, jjj
  string[15]    : Part_name
  integer      : time_h, time_m, time_s
  integer      : date_m, date_d, date_y

end_local

body

get_expr("OpVar_ProductUnderTest", Part_name)
 

-- -- Load location 3 with 16#00007300
--    formatted_keys[3] = 16#00007300  -- hard code 16#00007300 at address 3 ---No need these any more with new gmsl design from HS84/HS87

           time(time_h, time_m, time_s)     -- get time
           date(date_m, date_d, date_y)     -- get date
----Mu and Eric Wu asked to move away from address 0x82.
--- 0x82 and 0x83 may be used for some internal trim
--0x84 to 0x8b can be used for tracability
--0x8C to 0x511 will be used for HDCP2X in the future.   -----MT 09/28/2017
---Place serial number to the last 2 bytes and site to the third byte at address 0x84

  formatted_keys[0x84] = (lword(trimsite) << 20 )| serialnumber
  formatted_keys[0x85] = (lword(time_h) << 16 )| (lword(time_m) << 8 )| (lword(time_s)  )-----Program time this device was trimed
  formatted_keys[0x86] = (lword(date_y) << 16 )| (lword(date_m) << 8 )| (lword(date_d)  )-----Program time this device was trimed
   


-- Place KSV in location 0x80 & 0x81 -----122 & 123
   for idx =1 to 4 do
       formatted_keys[0x80] = formatted_keys[0x80] | (hdcp_key_array[idx]<<(8*(idx-1)))
   end_for
   
   --formatted_keys[123] = hdcp_key_array[5] | 16#00110300   -- 4th digit from left is revision #
--    die_rev = 0xF & die_rev  -- use only lower four bits
--    die_rev = die_rev << 16  -- shift die rev to bits[19:16]
--   formatted_keys[0x81] = hdcp_key_array[5]  | 16#41000300 ----        -- bit[19:16] = revision ---for scramble 16#7F000200--- none scamble 16#7F000000
  
   if speed_grade_trim = 1 then
      
      if Part_name = "MAX96757F" then
        formatted_keys[0x81] = hdcp_key_array[5]  | 16#21000200 ----Trim bit 13  of Device byte 2    ------16#21000300  ---3 is scamble and lock
      end_if
      
      if Part_name = "MAX96757H" then
        formatted_keys[0x81] = hdcp_key_array[5]  | 16#31000200 ----Trim bit 13  of Device byte 2     ------16#31000300  ---3 is scamble and lock
      end_if
      
      if Part_name = "MAX96757R" then
        --z formatted_keys[0x81] = hdcp_key_array[5]  | 16#27000200 ----Trim bit 13  of Device byte 2    ------16#27000300  ---3 is scamble and lock
        formatted_keys[0x81] = hdcp_key_array[5]  | 16#21000200 ----Trim bit 13  of Device byte 2    ------16#21000300  ---3 is scamble and lock ( For now we will trim as 96757F)
      end_if
      
      if Part_name = "MAX96973S" then
        formatted_keys[0x81] = hdcp_key_array[5]  | 16#01000200 ----no Trim bit 13 of Device byte 2 ----| 16#41000300 -----16#01000300---3 is scamble and lock ( Same as MAX96757 Full Version HDCP)
      end_if
      
   else
        formatted_keys[0x81] = hdcp_key_array[5]  | 16#01000200 ----no Trim bit 13 of Device byte 2 ----| 16#41000300 -----16#01000300---3 is scamble and lock ( MAX96757 Full Version HDCP )
   end_if 
        


-- Place device keys (Key0 - Key39) in array locations 4-73
   jjj=5
   
   for idx =9 to 288 by 4 do
       formatted_keys[jjj] = formatted_keys[jjj] |  hdcp_key_array[idx]
       formatted_keys[jjj] = formatted_keys[jjj] | (hdcp_key_array[idx+1] <<(8*1))
       formatted_keys[jjj] = formatted_keys[jjj] | (hdcp_key_array[idx+2] <<(8*2))
       formatted_keys[jjj] = formatted_keys[jjj] | (hdcp_key_array[idx+3] <<(8*3))   
       jjj = jjj+1
   end_for



   return(formatted_keys)


end_body


procedure BlankTest(vdd, vdd18, vio, DEVICE_ADDR_ID, OTP_FAIL_PIN,OTP_DONE_PIN, trimok,SERIAL_NUMBER,SITETRIM,TIMETRIM,POWERUP,POWERDOWN)
--------------------------------------------------------------------------------
--  
in float            : vdd, vdd18, vio
in_out integer_test : trimok,SERIAL_NUMBER,SITETRIM,TIMETRIM
in word             : DEVICE_ADDR_ID      -- SER_ID or DES_ID
in PIN LIST[1]      : OTP_FAIL_PIN,OTP_DONE_PIN
in boolean          : POWERUP,POWERDOWN

local
word list[16]       : OTP_active_sites

lword               : addr, bit
word                : logical_addr
integer             : idx,q,trim_fail_count
word                : siteidx, thissite
integer             : NeedBlankTest  = 0
integer             : mem_offset
multisite lword     : otp_write_data[134]
multisite lword     : otp_data
multisite lword     : reg_data,reg_data1
multisite integer   : regvalue
multisite lword     : tempdata

multisite boolean   : ALREADY_PROGRAMMED

multisite boolean   :  DEV_FAILED ,otp_prog_ok
lword               :  NUM_OF_KEYS = 0
word list[4]        :  key_failure_sites = <::>
string[6]           :  OTP_TEMP = "HOT"
word                :  DEV_ID 
multisite lword     :  otp_addr
multisite lword     :  first_fail_loc,fail_count
multisite lword     : readback_data[712], read_data_burst[78]
integer             : array_index
float               : time_meas
float               :  Vconf0, Vconf1
multisite integer   : prog_ok,otp_blank_test
multisite lword     :  lowword, upperword
word                :  sites, site, begin_sites
multisite integer   : reg_val,  serial_num, sitetrim,time_trim


multisite lword     : temp_write_data[5]
end_local

body

static    lword     : serial_number = 0

--  otp_fail = FALSE
  DEV_ID = DEVICE_ADDR_ID

  current_active_sites = get_active_sites()
  sites = word(len(current_active_sites))

 

------------ Power Up HS89 -----------------------
-- 
--     active_sites = get_active_sites
--     sites = word(len(active_sites))  

    --POWER_CONNECT    -- need this for reseting device
    
    -- can take out later but keep for now to make sure all MFP pins connected to DPs
      open cbit MFP_LT_RELAY  

    --make sure RSVD pin float (HVVI disconnect)
    disconnect hvvi chan SER_RSVD    -- need to float RSVD, important!!
    connect digital pin ALL_PATTERN_PINS to dcl
    disconnect digital pin SER_CAPVDD from dcl                 -- need to float CAP_VDD pin  
    wait(3ms) 
        
     -----Dut power up function
   DutPowerUp(vio, vdd18, vdd, "UART", "TP_GMSL2",POWERUP)
reg_data = OTP_Reg_Read(DEV_ID, 16#00, 1)


---OTP read memory----
       OTP_Reg_Write(DEV_ID, OTP0,1, mlw(0x00), 0, mlw(0x00))---disable program
       OTP_Reg_Write(DEV_ID,OTP0 ,1, mlw(0x40), 0, mlw(0x00))---enable read
       fail_count =0 ---reset fail_count variable 

----------------------------------------------------------
       for  addr =0x82  to  0x82 do ---  11 to  0x83     
        
            otp_addr =  32*(addr)	   
            OTP_Reg_Write(DEV_ID, 16#1802,2, otp_addr, 0,mlw(0x00) )---set address to read from
            array_index = array_index + 1 
            reg_data = OTP_Reg_Read(DEV_ID, 16#1814, 4)
            for siteidx = 1 to sites do  
                thissite = current_active_sites [siteidx]                   
                if reg_data[thissite] = 0 then --- part not trimmed yet
                    NeedBlankTest = NeedBlankTest +1 
                else 
                    deactivate site thissite  --- already trimmed no need to
                end_if
            end_for    
       end_for
       
-----       
   if ( NeedBlankTest>=1) then  -- If at least one site needs to be OTP'ed, execute block
        
        OTP_active_sites = get_active_sites()  -- sites active for OTP trim
        sites = word(len(OTP_active_sites))
---------------------------- OTP Programming 
---Mu adds blank check procedure on 6/2017-----MT
 -----Need talk to Mu If blank test is  perform then can not trim       
        OTP_Reg_Write(DEV_ID, OTP12,1, mlw(0x24), 0,mlw(0))--- SR_OTP12 = 0X1818, set to 0x24
        OTP_Reg_Write(DEV_ID, OTP1,1, mlw(0x00), 0, mlw(0))----select GMSL OTP section
        OTP_Reg_Write(DEV_ID, OTP18,1, mlw(0x01), 0,mlw(0))--- SR_OTP18 = 0X1818, TURN ON OTP_BLANK_REQ BIT
 
        wait(300us)
        reg_data = OTP_Reg_Read(SER_ID,OTP18, 1)   -----Readback make sure done bit = 1 and fail bit = 0,otherwise failed device
        otp_blank_test = integer(reg_data) ---- for dlog
        OTP_Reg_Write(DEV_ID, OTP18,1, mlw(0x00), 0,mlw(0))--- SR_OTP18 = 0X1818, TURN OFF OTP_BLANK_REQ BIT


   end_if 



    activate site current_active_sites
    sites = word(len(current_active_sites)) --- get number of sites at begining

---------------- Power Off -------------------

--------  DutPowerDown
 ------ Power Off ----

     set digital pin ALL_PATTERN_PINS modes to comparator enable all fails
      powerdown_device(POWERDOWN)  


----Datalog out
    if NeedBlankTest > 0 then  ----data log trim 
        test_value  prog_ok with trimok
    end_if 

     test_value serial_num with SERIAL_NUMBER
     test_value sitetrim with SITETRIM
     test_value time_trim with TIMETRIM

    
end_body

procedure Program_HDCP_FFFF(vdd, vdd18, vio, vterm, DEVICE_ADDR_ID, OTP_FAIL_PIN,OTP_DONE_PIN,KEY_TYPE, REG13_ID, SPEED_GRADE_TRIM, DIE_REV, trimmed_it, server_code_it,trimok, otp_trim_it, key_time_ft,OTP_READ_VERIFY,SERIAL_NUMBER,SITETRIM,TIMETRIM,ManualTrim)
--------------------------------------------------------------------------------
--  
in float            : vdd, vdd18, vio, vterm

in string[20]       : KEY_TYPE       -- SER_PTX01 (Tx), DES_PRX01 (Rx) --- Key_Type = "SER_PTX01"  -- Type of key to get. 
                                                                                   -- "PRX01" for Receiver (Deserializer) "Test" key
                                                                                   -- "PTX01" for Transmitter (Serializer) "Test" key
				                                                   -- "DES_PRX01" for Receiver (Deserializer) "Real" key
                                                                                   -- "SER_PTX01" for Transmitter (Serializer) "Real" key
in lword            : REG13_ID  -- Expected  values for HDCP trimmed device
--in string[3]        : DEV_TYPE       -- Device Type (SER or DES)
in lword            : DIE_REV        -- 0 (pass 1), 1(pass 2), 2(pass 3), etc (die revision)
in word             : DEVICE_ADDR_ID      -- SER_ID or DES_ID
in_out integer_test : trimmed_it, server_code_it,otp_trim_it,OTP_READ_VERIFY,trimok,SERIAL_NUMBER,SITETRIM,TIMETRIM

in_out float_test   : key_time_ft

in PIN LIST[1]       : OTP_FAIL_PIN,OTP_DONE_PIN
in lword             : SPEED_GRADE_TRIM           -- ONLY needed for hs87,89,94 up to this time. 
in      boolean     : ManualTrim
local

word list[16]       : OTP_active_sites
lword               : addr, bit
word                : logical_addr
integer             : idx,q,trim_fail_count
word                : siteidx, thissite
multisite integer   : soak_flagtrim_fail_count
integer             : NEED_PROGRAM = 0
integer             : mem_offset
multisite lword     : otp_write_data[134]
multisite lword     : otp_data
multisite lword     : reg_data,reg_data1
multisite integer   : regvalue
 multisite lword     : tempdata
 multisite boolean   : otp_fail
 multisite boolean   : ALREADY_PROGRAMMED

multisite boolean   :  DEV_FAILED ,otp_prog_ok
lword               :  NUM_OF_KEYS = 0
word list[4]        :  key_failure_sites = <::>
string[6]           :  OTP_TEMP = "HOT"
word                :  DEV_ID 
multisite lword     :  otp_addr
multisite lword     :  first_fail_loc
multisite lword     : readback_data[712], read_data_burst[78]
integer             : array_index
float               : time_meas
float               :  Vconf0, Vconf1
multisite integer   : prog_ok,otp_blank_test
multisite lword     :  lowword, upperword
word                :  sites, site, begin_sites,fail_count
multisite integer   : reg_val,  serial_num, sitetrim,time_trim
multisite integer   : gmsl_1X_addr_fail
multisite boolean   : gmsl_1X_site_fail
multisite float     : otp_icc1[1,600],otp_icc1_fail[1,600]
multisite boolean   : OTP_DONE_BIT_CHECK, OTP_FAIL_BIT_CHECK
end_local

body

static    lword     : serial_number = 0

  otp_fail = FALSE
  DEV_ID = DEVICE_ADDR_ID

  current_active_sites = get_active_sites()
  sites = word(len(current_active_sites))


------------ Power Up HS89 -----------------------
-- 
--     active_sites = get_active_sites
--     sites = word(len(active_sites))  

    --POWER_CONNECT    -- need this for reseting device
    
    -- can take out later but keep for now to make sure all MFP pins connected to DPs
      open cbit MFP_LT_RELAY  

    --make sure RSVD pin float (HVVI disconnect)
    disconnect hvvi chan SER_RSVD    -- need to float RSVD, important!!
    connect digital pin ALL_PATTERN_PINS to dcl
    disconnect digital pin SER_CAPVDD from dcl                 -- need to float CAP_VDD pin  
    wait(3ms) 
        
    -- reset levels 
    set digital pin ALL_PATTERN_PINS levels to vil 0V vih 0.2V vol 0V voh 0V iol 0mA ioh 0mA vref 0V
    set digital pin ALL_PATTERN_PINS modes to driver pattern     -- Do not delete !!! 
    wait(1ms)
  
    execute digital pattern "PowerUp" at label "ALL_ZERO" wait   -- Do not delete in order to reset all pins to vil level !!!
    wait(1ms)        
    

    --The function below is for setting DUT supplies ONLY, change Voltage if Required  
    Set_SER_Voltages(vio, vdd, vdd18)
    wait (10ms) -- trial for 47uF cap on SER_VDD
        
    Vconf0 = 0.11 * vio   -- UART    
    Vconf1 = 0.16 * vio
    set digital pin SER_GPO4_CFG0  + SER_GPO6_CFG2 levels to vil Vconf0 vih vio   -- TP/UART mode with DEV_ID = 0x80
    set digital pin  SER_GPO5_CFG1 levels to vil Vconf1 vih vio                    ---GMSL2 mode         

    wait(1ms)
    
        
  -------- Set PWDN =1 to power up device --------
    execute digital pattern "PowerUp" at label "TP" run to end wait
    wait(6ms) 
   

  ----------- Register 13 & 15 to determine if device is already trimmed  -------------
  ----------- Check for HDCP capable bit and device ID --------------------------------
  
    reg_data = OTP_Reg_Read(SER_ID, REG13, 1)
    regvalue = integer(reg_data)
    reg_data1 = OTP_Reg_Read(SER_ID, REG15, 1)
 

--  test_value regvalue with trimmed_it

  
  ----------------- Determine which sites have already been OTP'ed
    for siteidx=1 to sites do
        thissite = current_active_sites[siteidx]
        reg_data[thissite] = reg_data[thissite] 
        if ((reg_data[thissite] == REG13_ID) or  (reg_data1[thissite] == 0x7F)) then  ---reason check for reg_data1 because HS94, MPW3 doesnot update reg13 as HS89. DE said nex rev
            ALREADY_PROGRAMMED[thissite] = TRUE
        else
            ALREADY_PROGRAMMED[thissite] = FALSE
        end_if
    end_for
   
------- Check if device has already failed or not. This is needed in case Run to End mode
------ is selected. Do not get a key and do not trim if device has already failed.
  
    DEV_FAILED = NOT(get_boolean_passing_sites)

  -- Determine how many keys are needed  
    for siteidx = 1 to sites do
        thissite = current_active_sites[siteidx]
        if( NOT ALREADY_PROGRAMMED[thissite] AND NOT DEV_FAILED[thissite]) then
            NUM_OF_KEYS = NUM_OF_KEYS + 1
        end_if
    end_for

----Grab key  
    if NUM_OF_KEYS > 0 then
        DAL_Populate_Key_Pool(NUM_OF_KEYS, OTP_TEMP, KEY_TYPE)
    end_if
----- If device has already been OTP'ed or has already failed, deactivate site
----- Get a Key for sites that need to be trimmed

------------Hardcode to 0xFFFF_FFFF
        otp_write_data   = 0xFFFF_FFFF
--     for siteidx=1 to sites do
--         thissite = current_active_sites[siteidx]
--             if not ALREADY_PROGRAMMED[thissite] AND not DEV_FAILED[thissite] then
--                 serial_number = serial_number + 1 ----Per Eric's requirment we need to program serial number for tracability
-- 	        otp_write_data[thissite] = OTP_Real_Key_gmsl_1X(OTP_TEMP,thissite,SPEED_GRADE_TRIM,KEY_TYPE,serial_number)   -- get an HDCP key when testing at HOT (105C)
-- 
-- 	        if fetched_HDCP_key[thissite] then
-- 	           NEED_PROGRAM = NEED_PROGRAM+1
-- 	        else
-- 	           key_failure_sites = key_failure_sites + <:thissite:>
-- 	       end_if      
--             else
--                 deactivate site thissite
--             end_if
--    end_for


  -- Datalog if at least one site has not been trimmed
    if NEED_PROGRAM > 0 then
------      test_value HDCP_key_server_code with server_code_it
------      test_value key_time with key_time_ft
    end_if
    
    deactivate site key_failure_sites
  
    if (NEED_PROGRAM >=1) then  -- If at least one site needs to be OTP'ed, execute block
        
        OTP_active_sites = get_active_sites()  -- sites active for OTP trim
        sites = word(len(OTP_active_sites))

---------------------------- OTP Programming -------------------------------------------------
-----Mu adds blank check procedure on 6/2017-----MT
 -----Need talk to Mu If blank test is  perform then can not trim       
--         OTP_Reg_Write(DEV_ID, OTP1,1, mlw(0x00), 0, mlw(0))----select GMSL OTP section
--         OTP_Reg_Write(DEV_ID, OTP18,1, mlw(0x01), 0,mlw(0))--- SR_OTP18 = 0X1818, TURN ON OTP_BLANK_REQ BIT
--         wait(300us)
--         reg_data = OTP_Reg_Read(SER_ID,OTP18, 1)   -----Readback make sure done bit = 1 and fail bit = 0,otherwise failed device
--         otp_blank_test = integer(reg_data) ---- for dlog
--         OTP_Reg_Write(DEV_ID, OTP18,1, mlw(0x00), 0,mlw(0))--- SR_OTP18 = 0X1818, TURN OFF OTP_BLANK_REQ BIT

-------        
        OTP_Reg_Write(DEV_ID, OTP0,1, mlw(0x00), 0,mlw(0))---disable read OTP0 =0X1800 FOR HS89
        OTP_Reg_Write(DEV_ID, OTP1,1, mlw(0x02), 0, mlw(0))---enable  OTP_PGM_DONE and OTP_PGM_FAIL to GPIO15  and GPIO14  and select GMSL section OTP1 = 0X1801

---OTP Write 
        OTP_Reg_Write(DEV_ID, OTP0,1, mlw(0x20), 0, mlw(0))---enable write 
 
        set digital pin OTP_DONE_PIN + OTP_FAIL_PIN modes to driver pattern comparator enable all fails
        set digital pin  OTP_DONE_PIN + OTP_FAIL_PIN levels to vih 0.9*vio vil 0.1*vio vol 0.5*vio voh 0.5*vio iol 0mA ioh 0mA vref 0V

---------- Begin programming at address 5----for GMSL2 part OTP for 1.4keys OTP address starts at 4.
-----------
        if ManualTrim then
---This is just for debug by program single location at a time MT
            for addr=  5 to 0x84 do  
                if addr = 0x4b then ---- No need to program from 4b to 0x7F
                    addr = 0x80
                end_if
                otp_addr = addr * 32
	
	        for siteidx =1 to sites do
	           thissite = OTP_active_sites[siteidx]
                    if addr = 0x81 then
                        otp_data[thissite] = 0xFFFF_FFCF    ------no scamble and no otp done
                        otp_write_data[thissite,addr]   =  0xFFFF_FFCF 
                    else    
                        otp_data[thissite] = otp_write_data[thissite,addr]
                    end_if    
	        end_for	
------Per Mu need to do Vddio current measurement
                measure hcovi i on SER_VDDIO for 600 samples every 5us trigger on syncref "meas_otp_i" into memory 
                
                OTP_Reg_Write(DEV_ID, OTP2,2, otp_addr, 4, otp_data )---Write data to address
--------Polling on DONE pin
                wait(10ms)----remove this after burst/match implement
-------- ---Check for done and fail bits
                    for j = 1 to 20 do
                       read  digital pin OTP_DONE_PIN state compare to high into OTP_DONE_BIT_CHECK
	               for siteidx =1 to sites do                            ---- This loop only work on 1 site                 
	                   thissite = OTP_active_sites[siteidx]                    
                            if OTP_DONE_BIT_CHECK[thissite] then
                                j = 22
                                break
                            end_if               
                        wait(1ms)
                        end_for 
                    end_for 
-----Measure Fail pin                
                    read  digital pin OTP_FAIL_PIN  state compare to low into OTP_FAIL_BIT_CHECK                       
                if  (not OTP_FAIL_BIT_CHECK[thissite]) or(not  OTP_DONE_BIT_CHECK[thissite] ) then    ---- part failed stop here call Mu work on multisite later if needed
                        wait(0)            
                        read hcovi SER_VDDIO for 600 points into otp_icc1_fail  
                        prog_ok[thissite] = 1 ---failed
                        i = 500
                        break      
                    else
                       read hcovi SER_VDDIO  for 600 points into otp_icc1
                    end_if         
            end_for

         else
            otp_prog_ok = OTP_Reg_Write_Matchloop_Burst(DEV_ID, OTP2, otp_write_data, 5,0x86,0x4B,0x80,"GMSL1_HDMI1X",0 )-------Program whole memory in burst mode
------Prepare for datalog
            for siteidx = 1 to sites do 
                thissite = OTP_active_sites[siteidx]
                if otp_prog_ok[thissite] then
                    prog_ok[thissite] = 0 ---passed
                else
                    prog_ok[thissite] = 1 ---failed
                end_if        
            end_for    
        end_if      -------------manual trim
  
----------
--verify what opt memory contain make sure it match with write in data.
---OTP read memory----
       OTP_Reg_Write(DEV_ID, OTP0,1, mlw(0x00), 0, mlw(0x00))---disable program
       OTP_Reg_Write(DEV_ID,OTP0 ,1, mlw(0x40), 0, mlw(0x00))---enable read
       fail_count =0 ---reset fail_count variable 

---DE require verify read back at different supply    
    Set_SER_Voltages(1.7, vdd, vdd18)

 ----Read whole memeroy at once MT
       read_data_burst = OTP_Reg_Read_burst(DEV_ID, OTP2, OTP14,   5    ,   0x86    ,    0x4B    ,   0x80       ,    -1, "GMSL1_HDMI1X")

       mem_offset = 0----initialize
       trim_fail_count = 0
---------Verify data read correctly
        for  i = 1 to  75 do
             if i >= 71 then   
                addr = 0x80 + lword(mem_offset)
                mem_offset = mem_offset + 1
             else
                addr = lword(i) + 4-----opt write data start at index 5
            end_if   
            
            for siteidx = 1 to sites do
                thissite =OTP_active_sites [siteidx]
                if (read_data_burst[thissite,i]  <> otp_write_data[thissite,addr]) and not(gmsl_1X_site_fail[thissite]) then
                   gmsl_1X_addr_fail[thissite] = integer(addr)
                   gmsl_1X_site_fail[thissite] = true
                   fail_count = fail_count +1   
                   if fail_count = sites then
                        addr = 1000 --- no need to compare
                    end_if                    
                end_if

            end_for          
       end_for 
wait(0)

----------------OTP LOCK This procedure from Mu but read back did not see status bit of OTP LOCK updated. Per Mu Li's request  the disable bit in OTP memory cell also need to be trimmed in program section.
       OTP_Reg_Write(DEV_ID, OTP0,1, mlw(0x00), 0,mlw(0))---disable read/write
       OTP_Reg_Write(DEV_ID, OTP1,1, mlw(0x02), 0, mlw(0))---enable  OTP_PGM_DONE and OTP_PGM_FAIL to GPIO15  and GPIO14  and select GMSL section
---OTP Write 
        OTP_Reg_Write(DEV_ID, 16#1800,1, mlw(0x20), 0, mlw(0))---enable write and lock
        wait(1ms)        
        reg_data = OTP_Reg_Read(DEV_ID, OTP8, 1)----Readback Lock status bit; it doesnot update.
                                                  
    end_if
--------------------------------end of verify  

    activate site current_active_sites
    sites = word(len(current_active_sites)) --- get number of sites at begining
----------------------------------
 -----Read memory location 0x84 and 85; serial number and date trimmed 
       OTP_Reg_Write(DEV_ID, OTP0,1, mlw(0x40), 0,mlw(0))---Enable OPT read 
       OTP_Reg_Write(DEV_ID, OTP1,1, mlw(0x00), 0, mlw(0))---Select GMSL section

      otp_addr =  32*(0x84)	   
      OTP_Reg_Write(DEV_ID, OTP2,2, otp_addr, 0,mlw(0x00) )---set address to read from   
      reg_data = OTP_Reg_Read(DEV_ID, OTP14, 4)


      otp_addr =  32*(0x85)	   
      OTP_Reg_Write(DEV_ID, OTP2,2, otp_addr, 0,mlw(0x00) )---set address to read from   
      tempdata = OTP_Reg_Read(DEV_ID, OTP14, 4)

      for siteidx = 1 to sites do
          thissite = current_active_sites[siteidx]  
          sitetrim[thissite] = integer(reg_data[thissite] & 0xFFFFFF)>> 20
          serial_num[thissite] = integer(reg_data[thissite]) & 0xFFFF
          time_trim[thissite] = integer(tempdata[thissite]) & 0xFFFFFF ---Datalog out minute and second 
      end_for
---------------- Power Off -------------------
  disconnect digital pin OTP_FAIL_PIN + OTP_DONE_PIN from ppmu
  connect digital pin OTP_FAIL_PIN + OTP_DONE_PIN to dcl
  wait(200us)
--------  DutPowerDown
 ------ Power Off ----
  set digital pin ALL_PATTERN_PINS levels to vil 0V vih 200mV iol 0uA ioh 0uA vref 0V
  wait(100us)
  
  set digital pin ALL_PATTERN_PINS modes to comparator enable all fails
  set hcovi SER_VDD+SER_VDDIO +SER_VDD18 to fv 0V vmax 4V clamp imax 600mA imin -600mA   

  wait(3ms)     -- extra for 47uF cap on SER_VDD    
  -- Initialize for set_SER_Voltages(vio, vcore, v18) routine
  vdd_global[1] = 0V   --SER_VDDIO
  vdd_global[2] = 0V   --SER_VDD  
  vdd_global[3] = 0V   --SER_VDDA(VDD18)

----Datalog out
     
      test_value regvalue with trimmed_it-----check DEVICE_ID( not device address) For HS89 8x8 tqfn none hdcp = 0x9B, HDCP = 0x9C

  if NEED_PROGRAM > 0 then  ----data log trim 
     test_value HDCP_key_server_code with server_code_it
     test_value key_time with key_time_ft
     test_value prog_ok with trimok
     test_value trim_fail_count with OTP_READ_VERIFY
  end_if

     test_value serial_num with SERIAL_NUMBER
     test_value sitetrim with SITETRIM
     test_value time_trim with TIMETRIM


end_body

function OTP_Return_OneWord(OtpRdDataIn): multisite lword[288]
--------------------------------------------------------------------------------
--  
in multisite lword     :OtpRdDataIn[?]


local
        word list[MAX_SITES]  : active_sites
        word                  : siteidx, idx,sites, i ,j
        multisite lword       : ReturnOneWord[288]
end_local


body

        active_sites = get_active_sites()
        sites = word(len(active_sites))

        for idx = 1 to sites do
            siteidx = active_sites[idx]

            for j = 1 to 72 do
                for i = 1 to 4 do
                    ReturnOneWord[siteidx, 4*(j-1) +i ] = (OtpRdDataIn[siteidx,j] >> lword(8*(i-1)))& 0xFF
                end_for
            end_for
        end_for
        
        return(ReturnOneWord)
end_body

function Crc32Calculate (ValArray, NumBytes, InitCrc) : multisite lword
  in multisite lword   :  ValArray[288]
  in word             :  NumBytes
  in boolean          :  InitCrc

local
  multisite lword      : CrcRetVal
  word list[MAX_SITES] : ActiveSites
  word                 : Sites, sIdx, Cs, cIdx, Ctr = 0
  lword                 : CrtableIdx
end_local

static multisite lword : CrcValue
const CRC_INIT = 0xFFFFFFFF
const XOROUT   = 0xFFFFFFFF

body
  ActiveSites = get_active_sites()
  Sites = word(len(ActiveSites))
  
  if InitCrc then
    CrcValue = CRC_INIT
    Crc32FillTable
  endif

  for sIdx = 1 to Sites do
    Cs = ActiveSites[sIdx]
    for cIdx = 1 to NumBytes do
      CrtableIdx = (CrcValue[Cs] % lword(ValArray[Cs, cIdx])) & 0xFF
      CrcValue[Cs] = CrcTable[CrtableIdx + 1]  % (CrcValue[Cs] >> 8)
    endfor
    CrcRetVal[Cs] = CrcValue[Cs] % XOROUT
  endfor


  return (CrcRetVal)
end_body

procedure Crc32FillTable

local

end_local

body
  if CrcTable[1] <> 0x0 or CrcTable[2] <> 0x77073096 or CrcTable[256] <> 0x2D02EF8D then
    println(stdout, "Storing CRC32 table to memory")
    
    CrcTable[1]   = 0x00000000
    CrcTable[2]   = 0x77073096
    CrcTable[3]   = 0xEE0E612C
    CrcTable[4]   = 0x990951BA
    CrcTable[5]   = 0x076DC419
    CrcTable[6]   = 0x706AF48F
    CrcTable[7]   = 0xE963A535
    CrcTable[8]   = 0x9E6495A3
    CrcTable[9]   = 0x0EDB8832
    CrcTable[10]  = 0x79DCB8A4
    CrcTable[11]  = 0xE0D5E91E
    CrcTable[12]  = 0x97D2D988
    CrcTable[13]  = 0x09B64C2B
    CrcTable[14]  = 0x7EB17CBD
    CrcTable[15]  = 0xE7B82D07
    CrcTable[16]  = 0x90BF1D91
    CrcTable[17]  = 0x1DB71064
    CrcTable[18]  = 0x6AB020F2
    CrcTable[19]  = 0xF3B97148
    CrcTable[20]  = 0x84BE41DE
    CrcTable[21]  = 0x1ADAD47D
    CrcTable[22]  = 0x6DDDE4EB
    CrcTable[23]  = 0xF4D4B551
    CrcTable[24]  = 0x83D385C7
    CrcTable[25]  = 0x136C9856
    CrcTable[26]  = 0x646BA8C0
    CrcTable[27]  = 0xFD62F97A
    CrcTable[28]  = 0x8A65C9EC
    CrcTable[29]  = 0x14015C4F
    CrcTable[30]  = 0x63066CD9
    CrcTable[31]  = 0xFA0F3D63
    CrcTable[32]  = 0x8D080DF5
    CrcTable[33]  = 0x3B6E20C8
    CrcTable[34]  = 0x4C69105E
    CrcTable[35]  = 0xD56041E4
    CrcTable[36]  = 0xA2677172
    CrcTable[37]  = 0x3C03E4D1
    CrcTable[38]  = 0x4B04D447
    CrcTable[39]  = 0xD20D85FD
    CrcTable[40]  = 0xA50AB56B
    CrcTable[41]  = 0x35B5A8FA
    CrcTable[42]  = 0x42B2986C
    CrcTable[43]  = 0xDBBBC9D6
    CrcTable[44]  = 0xACBCF940
    CrcTable[45]  = 0x32D86CE3
    CrcTable[46]  = 0x45DF5C75
    CrcTable[47]  = 0xDCD60DCF
    CrcTable[48]  = 0xABD13D59
    CrcTable[49]  = 0x26D930AC
    CrcTable[50]  = 0x51DE003A
    CrcTable[51]  = 0xC8D75180
    CrcTable[52]  = 0xBFD06116
    CrcTable[53]  = 0x21B4F4B5
    CrcTable[54]  = 0x56B3C423
    CrcTable[55]  = 0xCFBA9599
    CrcTable[56]  = 0xB8BDA50F
    CrcTable[57]  = 0x2802B89E
    CrcTable[58]  = 0x5F058808
    CrcTable[59]  = 0xC60CD9B2
    CrcTable[60]  = 0xB10BE924
    CrcTable[61]  = 0x2F6F7C87
    CrcTable[62]  = 0x58684C11
    CrcTable[63]  = 0xC1611DAB
    CrcTable[64]  = 0xB6662D3D
    CrcTable[65]  = 0x76DC4190
    CrcTable[66]  = 0x01DB7106
    CrcTable[67]  = 0x98D220BC
    CrcTable[68]  = 0xEFD5102A
    CrcTable[69]  = 0x71B18589
    CrcTable[70]  = 0x06B6B51F
    CrcTable[71]  = 0x9FBFE4A5
    CrcTable[72]  = 0xE8B8D433
    CrcTable[73]  = 0x7807C9A2
    CrcTable[74]  = 0x0F00F934
    CrcTable[75]  = 0x9609A88E
    CrcTable[76]  = 0xE10E9818
    CrcTable[77]  = 0x7F6A0DBB
    CrcTable[78]  = 0x086D3D2D
    CrcTable[79]  = 0x91646C97
    CrcTable[80]  = 0xE6635C01
    CrcTable[81]  = 0x6B6B51F4
    CrcTable[82]  = 0x1C6C6162
    CrcTable[83]  = 0x856530D8
    CrcTable[84]  = 0xF262004E
    CrcTable[85]  = 0x6C0695ED
    CrcTable[86]  = 0x1B01A57B
    CrcTable[87]  = 0x8208F4C1
    CrcTable[88]  = 0xF50FC457
    CrcTable[89]  = 0x65B0D9C6
    CrcTable[90]  = 0x12B7E950
    CrcTable[91]  = 0x8BBEB8EA
    CrcTable[92]  = 0xFCB9887C
    CrcTable[93]  = 0x62DD1DDF
    CrcTable[94]  = 0x15DA2D49
    CrcTable[95]  = 0x8CD37CF3
    CrcTable[96]  = 0xFBD44C65
    CrcTable[97]  = 0x4DB26158
    CrcTable[98]  = 0x3AB551CE
    CrcTable[99]  = 0xA3BC0074
    CrcTable[100] = 0xD4BB30E2
    CrcTable[101] = 0x4ADFA541
    CrcTable[102] = 0x3DD895D7
    CrcTable[103] = 0xA4D1C46D
    CrcTable[104] = 0xD3D6F4FB
    CrcTable[105] = 0x4369E96A
    CrcTable[106] = 0x346ED9FC
    CrcTable[107] = 0xAD678846
    CrcTable[108] = 0xDA60B8D0
    CrcTable[109] = 0x44042D73
    CrcTable[110] = 0x33031DE5
    CrcTable[111] = 0xAA0A4C5F
    CrcTable[112] = 0xDD0D7CC9
    CrcTable[113] = 0x5005713C
    CrcTable[114] = 0x270241AA
    CrcTable[115] = 0xBE0B1010
    CrcTable[116] = 0xC90C2086
    CrcTable[117] = 0x5768B525
    CrcTable[118] = 0x206F85B3
    CrcTable[119] = 0xB966D409
    CrcTable[120] = 0xCE61E49F
    CrcTable[121] = 0x5EDEF90E
    CrcTable[122] = 0x29D9C998
    CrcTable[123] = 0xB0D09822
    CrcTable[124] = 0xC7D7A8B4
    CrcTable[125] = 0x59B33D17
    CrcTable[126] = 0x2EB40D81
    CrcTable[127] = 0xB7BD5C3B
    CrcTable[128] = 0xC0BA6CAD
    CrcTable[129] = 0xEDB88320
    CrcTable[130] = 0x9ABFB3B6
    CrcTable[131] = 0x03B6E20C
    CrcTable[132] = 0x74B1D29A
    CrcTable[133] = 0xEAD54739
    CrcTable[134] = 0x9DD277AF
    CrcTable[135] = 0x04DB2615
    CrcTable[136] = 0x73DC1683
    CrcTable[137] = 0xE3630B12
    CrcTable[138] = 0x94643B84
    CrcTable[139] = 0x0D6D6A3E
    CrcTable[140] = 0x7A6A5AA8
    CrcTable[141] = 0xE40ECF0B
    CrcTable[142] = 0x9309FF9D
    CrcTable[143] = 0x0A00AE27
    CrcTable[144] = 0x7D079EB1
    CrcTable[145] = 0xF00F9344
    CrcTable[146] = 0x8708A3D2
    CrcTable[147] = 0x1E01F268
    CrcTable[148] = 0x6906C2FE
    CrcTable[149] = 0xF762575D
    CrcTable[150] = 0x806567CB
    CrcTable[151] = 0x196C3671
    CrcTable[152] = 0x6E6B06E7
    CrcTable[153] = 0xFED41B76
    CrcTable[154] = 0x89D32BE0
    CrcTable[155] = 0x10DA7A5A
    CrcTable[156] = 0x67DD4ACC
    CrcTable[157] = 0xF9B9DF6F
    CrcTable[158] = 0x8EBEEFF9
    CrcTable[159] = 0x17B7BE43
    CrcTable[160] = 0x60B08ED5
    CrcTable[161] = 0xD6D6A3E8
    CrcTable[162] = 0xA1D1937E
    CrcTable[163] = 0x38D8C2C4
    CrcTable[164] = 0x4FDFF252
    CrcTable[165] = 0xD1BB67F1
    CrcTable[166] = 0xA6BC5767
    CrcTable[167] = 0x3FB506DD
    CrcTable[168] = 0x48B2364B
    CrcTable[169] = 0xD80D2BDA
    CrcTable[170] = 0xAF0A1B4C
    CrcTable[171] = 0x36034AF6
    CrcTable[172] = 0x41047A60
    CrcTable[173] = 0xDF60EFC3
    CrcTable[174] = 0xA867DF55
    CrcTable[175] = 0x316E8EEF
    CrcTable[176] = 0x4669BE79
    CrcTable[177] = 0xCB61B38C
    CrcTable[178] = 0xBC66831A
    CrcTable[179] = 0x256FD2A0
    CrcTable[180] = 0x5268E236
    CrcTable[181] = 0xCC0C7795
    CrcTable[182] = 0xBB0B4703
    CrcTable[183] = 0x220216B9
    CrcTable[184] = 0x5505262F
    CrcTable[185] = 0xC5BA3BBE
    CrcTable[186] = 0xB2BD0B28
    CrcTable[187] = 0x2BB45A92
    CrcTable[188] = 0x5CB36A04
    CrcTable[189] = 0xC2D7FFA7
    CrcTable[190] = 0xB5D0CF31
    CrcTable[191] = 0x2CD99E8B
    CrcTable[192] = 0x5BDEAE1D
    CrcTable[193] = 0x9B64C2B0
    CrcTable[194] = 0xEC63F226
    CrcTable[195] = 0x756AA39C
    CrcTable[196] = 0x026D930A
    CrcTable[197] = 0x9C0906A9
    CrcTable[198] = 0xEB0E363F
    CrcTable[199] = 0x72076785
    CrcTable[200] = 0x05005713
    CrcTable[201] = 0x95BF4A82
    CrcTable[202] = 0xE2B87A14
    CrcTable[203] = 0x7BB12BAE
    CrcTable[204] = 0x0CB61B38
    CrcTable[205] = 0x92D28E9B
    CrcTable[206] = 0xE5D5BE0D
    CrcTable[207] = 0x7CDCEFB7
    CrcTable[208] = 0x0BDBDF21
    CrcTable[209] = 0x86D3D2D4
    CrcTable[210] = 0xF1D4E242
    CrcTable[211] = 0x68DDB3F8
    CrcTable[212] = 0x1FDA836E
    CrcTable[213] = 0x81BE16CD
    CrcTable[214] = 0xF6B9265B
    CrcTable[215] = 0x6FB077E1
    CrcTable[216] = 0x18B74777
    CrcTable[217] = 0x88085AE6
    CrcTable[218] = 0xFF0F6A70
    CrcTable[219] = 0x66063BCA
    CrcTable[220] = 0x11010B5C
    CrcTable[221] = 0x8F659EFF
    CrcTable[222] = 0xF862AE69
    CrcTable[223] = 0x616BFFD3
    CrcTable[224] = 0x166CCF45
    CrcTable[225] = 0xA00AE278
    CrcTable[226] = 0xD70DD2EE
    CrcTable[227] = 0x4E048354
    CrcTable[228] = 0x3903B3C2
    CrcTable[229] = 0xA7672661
    CrcTable[230] = 0xD06016F7
    CrcTable[231] = 0x4969474D
    CrcTable[232] = 0x3E6E77DB
    CrcTable[233] = 0xAED16A4A
    CrcTable[234] = 0xD9D65ADC
    CrcTable[235] = 0x40DF0B66
    CrcTable[236] = 0x37D83BF0
    CrcTable[237] = 0xA9BCAE53
    CrcTable[238] = 0xDEBB9EC5
    CrcTable[239] = 0x47B2CF7F
    CrcTable[240] = 0x30B5FFE9
    CrcTable[241] = 0xBDBDF21C
    CrcTable[242] = 0xCABAC28A
    CrcTable[243] = 0x53B39330
    CrcTable[244] = 0x24B4A3A6
    CrcTable[245] = 0xBAD03605
    CrcTable[246] = 0xCDD70693
    CrcTable[247] = 0x54DE5729
    CrcTable[248] = 0x23D967BF
    CrcTable[249] = 0xB3667A2E
    CrcTable[250] = 0xC4614AB8
    CrcTable[251] = 0x5D681B02
    CrcTable[252] = 0x2A6F2B94
    CrcTable[253] = 0xB40BBE37
    CrcTable[254] = 0xC30C8EA1
    CrcTable[255] = 0x5A05DF1B
    CrcTable[256] = 0x2D02EF8D
  endif
end_body

procedure Program_HDCP_keys_lessWSInfo(vdd, vdd18, vio, vterm, DEVICE_ADDR_ID, OTP_FAIL_PIN,OTP_DONE_PIN,KEY_TYPE, REG13_ID, SPEED_GRADE_TRIM, DIE_REV, trimmed_it, server_code_it,trimok, otp_trim_it, key_time_ft,OTP_READ_VERIFY,SERIAL_NUMBER,SITETRIM,TIMETRIM,POWERUP,POWERDOWN,YrTrim,MonthTrim,DayTrim,Crc1p7dlog,Crc1p9dlog,OTPLOCK,SpeedLimit,InitialTrimCheck510, InitialTrimCheck511,TrimEnhancementCheck, Reg13_ID_Post, Reg15_ID_Post)
--------------------------------------------------------------------------------
--  
    in float            : vdd, vdd18, vio, vterm
    in string[20]       : KEY_TYPE       -- SER_PTX01 (Tx), DES_PRX01 (Rx) --- Key_Type = "SER_PTX01"  -- Type of key to get. 
                                                                                   -- "PRX01" for Receiver (Deserializer) "Test" key
    in boolean        : POWERUP,POWERDOWN                                                                                   -- "PTX01" for Transmitter (Serializer) "Test" key
				                                                   -- "DES_PRX01" for Receiver (Deserializer) "Real" key
                                                                                   -- "SER_PTX01" for Transmitter (Serializer) "Real" key
    in lword            : REG13_ID  -- Expected  values for HDCP trimmed device
    in lword            : DIE_REV        -- 0 (pass 1), 1(pass 2), 2(pass 3), etc (die revision)
    in word             : DEVICE_ADDR_ID      -- SER_ID or DES_ID
    in_out integer_test : trimmed_it, server_code_it,otp_trim_it,OTP_READ_VERIFY,trimok,SERIAL_NUMBER,SITETRIM,TIMETRIM,YrTrim,MonthTrim,DayTrim
    in_out float_test   : key_time_ft
    in_out integer_test : Crc1p7dlog,Crc1p9dlog,OTPLOCK,SpeedLimit
    in_out integer_test : InitialTrimCheck510, InitialTrimCheck511,TrimEnhancementCheck
    in_out integer_test : Reg13_ID_Post, Reg15_ID_Post
   
    in PIN LIST[1]       : OTP_FAIL_PIN,OTP_DONE_PIN
    in lword             : SPEED_GRADE_TRIM           -- ONLY needed for hs87,89,94 up to this time. 

local

    word list[16]       : OTP_active_sites
    lword               : addr, bit, NUM_OF_KEYS = 0
    integer             : idx,q,trim_fail_count,NEED_PROGRAM = 0, mem_offset
    word                : siteidx, thissite, DEV_ID
    multisite lword     : otp_write_data[134], reg_data, reg_data1, tempdata, tempdata1, otp_addr, readback_data[712], read_data_burst[78], lowword, upperword
    multisite boolean   : ALREADY_PROGRAMMED, DEV_FAILED, otp_prog_ok, gmsl_1X_site_fail,  gmsl_1X_site_fail1p9

    word list[4]        :  key_failure_sites = <::>
    string[6]           :  OTP_TEMP  , Test_Type
    string[15]          : Part_Num
    float               : time_meas
    word                :  sites, site, begin_sites,fail_count
    multisite integer   : reg_val,  serial_num, sitetrim,time_trim,year_trim,month_trim,day_trim, gmsl_1X_addr_fail, gmsl_1X_addr_fail1p9
    multisite lword     : OtpRdWordValues[288], CrcValue, CrcValueRb1p7, CrcValueRb1p9, CrcValue1p9,CrcValue1p7
    multisite integer   : Crc1p7,Crc1p9,speedgrade, OTP_DevBytesOtpByte_dlog, OtpLockScramble, regvalue, prog_ok,otp_blank_test
    
    multisite boolean    : DonePinHigh,PrgFailPin,PartFail
    boolean              : PrgLoc511
    multisite integer    : TrimmedCheck510fail, TrimmedCheck511fail, trimcheck_enhancement
    multisite lword      : reg_data81Min,reg_data511Min,reg_data81Max,reg_data511Max, reg_data510Max, reg_data_510_TrimCheck,  reg_data_511_TrimCheck
    multisite lword      : reg_data84Min,reg_data85Min ,reg_data86Min  ,reg_data84Max,reg_data85Max,reg_data86Max
    multisite lword      : Reg15Val, Reg13Val
    multisite integer    : Reg15ValInt, Reg13ValInt, Reg15ValOk,Loc511Data,OTPLock, OTP8_PgmFail_Check
    multisite lword      : otp_data,otp_data510
    multisite integer   : reg13_val_post, reg15_val_post

end_local

body

    static    lword     : serial_number = 0
    
    
    TrimmedCheck510fail = 0 
    TrimmedCheck511fail = 0
    trimcheck_enhancement = 0
    

    DEV_ID = DEVICE_ADDR_ID

    current_active_sites = get_active_sites()
    sites = word(len(current_active_sites))

    -- zm 93 --
    ------------ Power Up HS89 -----------------------
    -- 
    --     active_sites = get_active_sites
    --     sites = word(len(active_sites))  

    --POWER_CONNECT    -- need this for reseting device
    
    -- can take out later but keep for now to make sure all MFP pins connected to DPs
      open cbit MFP_LT_RELAY  


    -----Dut power up function
    DutPowerUp(vio, vdd18, vdd, "UART", "TP_GMSL2",POWERUP)


    ----------- Register 13 & 15 to determine if device is already trimmed  -------------
    ----------- Check for HDCP capable bit and device ID --------------------------------
  
    reg_data = OTP_Reg_Read(SER_ID, REG13, 1)      -- if reg_data = 156 (0x9C), part has been trimmed for HDCP version 
    regvalue = integer(reg_data)
    reg_data1 = OTP_Reg_Read(SER_ID, REG15, 1)     -- this is for checking speed limit (Video Resolution) bit[5:4] / Dual View bit[3]/ Dual Link bit[2] / Splitter Mode bit[1]/ HDCP Capability bit[0]
    
    get_expr("OpVar_ProductUnderTest", Part_Num)
    
   ------------------ Deternmine if a part has been trimmed or not by reading CRC locations and lock  zin 2/19/2020 -------------------------
        
    OTP_Reg_Write(DEV_ID, OTP0,1, mlw(0x40), 0,mlw(0))---Enable OPT read 
    OTP_Reg_Write(DEV_ID, OTP1,1, mlw(0x00), 0, mlw(0))---Select GMSL section     
             
   ----Read location 510 to see if part has been previously programmed with 0xFEFEFEFE. If yes, part will be sent to OtpInitialTrimCheck fail bin
   otp_addr =  32*(510)	   
   OTP_Reg_Write(DEV_ID, OTP2,2, otp_addr, 0,mlw(0x00) )---set address to read from   
   tempdata1 = OTP_Reg_Read(DEV_ID, OTP14, 4)    
   reg_data_510_TrimCheck = tempdata1       
       
   ----Read location 511 to see if part has been previously programmed with 0xFEFEFEFE. If yes, part will be sent to OtpInitialTrimCheck fail bin
   otp_addr =  32*(511)	   
   OTP_Reg_Write(DEV_ID, OTP2,2, otp_addr, 0,mlw(0x00) )---set address to read from   
   tempdata1 = OTP_Reg_Read(DEV_ID, OTP14, 4)    
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
 

  -----------------Debug
   OTP_Reg_Write(DEV_ID, OTP0,1, mlw(0x00), 0, mlw(0x00))           --- # disable program
   OTP_Reg_Write(DEV_ID, OTP0,1, mlw(0x40), 0, mlw(0x00))           --- # enable read

    ---- Read whole memeroy at once MT
    read_data_burst = OTP_Reg_Read_burst(DEV_ID, OTP2, OTP14, 5, 0x86, 0x4B, 0x80,  -1, "GMSL1_HDMI1X")
    otp_addr =  32*0x01	   
    OTP_Reg_Write(DEV_ID, OTP2, 2, otp_addr, 0,mlw(0x00) ) ---set address to read from   
    lowword = OTP_Reg_Read(DEV_ID, OTP14, 4)
    wait(0)
    otp_addr =  32*0x02	   
    OTP_Reg_Write(DEV_ID, OTP2, 2, otp_addr, 0,mlw(0x00) ) ---set address to read from   
    lowword = OTP_Reg_Read(DEV_ID, OTP14, 4)
    wait(0)
    otp_addr =  32*0x03	   
    OTP_Reg_Write(DEV_ID, OTP2, 2, otp_addr, 0,mlw(0x00) ) ---set address to read from   
    lowword = OTP_Reg_Read(DEV_ID, OTP14, 4)
    wait(0)        
    otp_addr =  32*0x04	   
    OTP_Reg_Write(DEV_ID, OTP2, 2, otp_addr, 0,mlw(0x00) ) ---set address to read from   
    lowword = OTP_Reg_Read(DEV_ID, OTP14, 4)
    wait(0)
    otp_addr =  32*0x83	   
    OTP_Reg_Write(DEV_ID, OTP2, 2, otp_addr, 0,mlw(0x00) ) ---set address to read from   
    lowword = OTP_Reg_Read(DEV_ID, OTP14, 4)
    wait(0)
   
    -------------------------------------------------------------------------------------------------------------------
    wait(0)
    --  test_value regvalue with trimmed_it

  
   ----------------- Determine which sites have already been OTP'ed
    for siteidx=1 to sites do
        thissite = current_active_sites[siteidx]
         
        if ((reg_data[thissite] == REG13_ID) or  (reg_data1[thissite] == 0x01)) then  ---reason check for reg_data1 because HS94, MPW3 doesnot update reg13 as HS89. DE said nex rev
            ALREADY_PROGRAMMED[thissite] = TRUE
        else
            ALREADY_PROGRAMMED[thissite] = FALSE
        end_if
    end_for
   
    ------- Check if device has already failed or not. This is needed in case Run to End mode
    ------ is selected. Do not get a key and do not trim if device has already failed.
  
    DEV_FAILED = NOT(get_boolean_passing_sites)

    -- Determine how many keys are needed  
    for siteidx = 1 to sites do
        thissite = current_active_sites[siteidx]
        if( NOT ALREADY_PROGRAMMED[thissite] AND NOT DEV_FAILED[thissite]) then
            NUM_OF_KEYS = NUM_OF_KEYS + 1
        end_if
    end_for

 
    -------------------------------z OTP_TEMP  ="HOT"
    -------------------------------OTP_TEMP  ="ROOM"  --z Force Trim at Room need to remove for production
    

    ----Grab key   
    if NUM_OF_KEYS > 0 then
        DAL_Populate_Key_Pool(NUM_OF_KEYS, OTP_TEMP, KEY_TYPE)
    end_if

    ----- If device has already been OTP'ed or has already failed, deactivate site
    ----- Get a Key for sites that need to be trimmed
    for siteidx=1 to sites do
        thissite = current_active_sites[siteidx]
            if not ALREADY_PROGRAMMED[thissite] AND not DEV_FAILED[thissite] then
                serial_number = serial_number + 1 ----Per Eric's requirment we need to program serial number for tracability
                -- otp_write_data[thissite] = OTP_Real_Key_mod(OTP_TEMP,thissite,DIE_REV,thissite,serial_number)   -- get an HDCP key when testing at HOT (105C)
	        otp_write_data[thissite] = OTP_Real_Key_gmsl_1X(OTP_TEMP,thissite,SPEED_GRADE_TRIM,KEY_TYPE,serial_number)   -- get an HDCP key when testing at HOT (105C)
	        if fetched_HDCP_key[thissite] then
	           NEED_PROGRAM = NEED_PROGRAM+1
	        else
	           key_failure_sites = key_failure_sites + <:thissite:>
	       end_if      
            else
                deactivate site thissite
            end_if
   end_for


    -- Datalog if at least one site has not been trimmed
    if NEED_PROGRAM > 0 then
        ------      test_value HDCP_key_server_code with server_code_it
        ------      test_value key_time with key_time_ft
    end_if
    
    deactivate site key_failure_sites
  
    if (NEED_PROGRAM >=1) then  -- If at least one site needs to be OTP'ed, execute block
        
        OTP_active_sites = get_active_sites()  -- sites active for OTP trim
        sites = word(len(OTP_active_sites))

        ---------------------------- OTP Programming -------------------------------------------------

        reg_data = OTP_Reg_Read(DEV_ID, SR_CTRL0, 1)
        OTP_Reg_Write(DEV_ID, DR_CTRL0,1, (reg_data | 0x40), 0,mlw(0x00) )--------Turn off GMLS phy for trim because with this rev Vdd18 = 2.1V to trim it is higher then abmax spec 9/2018
        
        --------------------DE requests to trim part at Vdd =0.95V, Vdd18 =2.1V and Vddio =2.75V other supplies don't care can by at type.... 9/2018 MT.
        ----------- Set_SER_Voltages(vio, vcore, v18)
        Set_SER_Voltages(2.75, 0.95V, 2.1)

        ---------------------------- OTP Programming -------------------------------------------------
        OTP_Reg_Write(DEV_ID, OTP0,1, mlw(0x00), 0,mlw(0))---disable read OTP0 =0X1800 FOR HS89
        OTP_Reg_Write(DEV_ID, OTP1,1, mlw(0x02), 0, mlw(0))---enable  OTP_PGM_DONE and OTP_PGM_FAIL to GPIO15  and GPIO14  and select GMSL section OTP1 = 0X1801

        ---OTP Write 
        OTP_Reg_Write(DEV_ID, OTP0,1, mlw(0x20), 0, mlw(0))---enable write 
 
        set digital pin OTP_DONE_PIN + OTP_FAIL_PIN modes to driver pattern comparator enable all fails
        set digital pin  OTP_DONE_PIN + OTP_FAIL_PIN levels to vih 0.9*vio vil 0.1*vio vol 0.5*vio voh 0.5*vio iol 0mA ioh 0mA vref 0V


        ---------------------------------------------------------------------------------
        start_timer

        otp_prog_ok = OTP_Reg_Write_Matchloop_Burst(DEV_ID, OTP2, otp_write_data, 5,0x86,0x4B,0x80,"GMSL1_HDMI1X",0 )-------Program whole memory in burst mode
        
        ------Prepare for datalog
        for siteidx = 1 to sites do 
            thissite = OTP_active_sites[siteidx]
            if otp_prog_ok[thissite] then
                prog_ok[thissite] = 0 ---passed
            else
                prog_ok[thissite] = 1 ---failed
            end_if        
        end_for    
        time_meas = stop_timer   
        
        read digital pin OTP_DONE_PIN state compare to high into DonePinHigh   ----expect high MT 1/2020
        read digital pin OTP_FAIL_PIN  state compare to low into PrgFailPin    ---expect low 
        
        RegRead(SER_ID, 0x1808 , 1,  upperword,lowword, "SER_UART_Read")      ---Check OTP8 bit4 to check OTP_PGM_FAIL status
        OTPLock =   integer(lowword)   -- OTP RD DONE and OTP LOCK  1000 1000 (0x88) 
        
         for siteidx =1 to sites do
	       thissite = OTP_active_sites[siteidx]
	       
	       OTP8_PgmFail_Check[thissite] = OTPLock[thissite] & 0x10 >> 4	       
	       	       
	       if ( (not DonePinHigh[thissite]) or (not PrgFailPin [thissite]) or (OTP8_PgmFail_Check [thissite]= 1) ) then	       
	          
	           trimcheck_enhancement [thissite] = 1 
	       
	       end_if
	       
	 end_for 
        
        -----------------z ------------------------------------------------------------------------------
        
        otp_data = 0x00  -- initialize the otp_data for location 511
        otp_data510 = 0x00 -- initialize the otp_data510 for location 510
        
        for siteidx =1 to sites do
	       thissite = OTP_active_sites[siteidx]
               if( (not DonePinHigh[thissite] )or(not PrgFailPin[thissite]) or (OTP8_PgmFail_Check[thissite] = 1))then
                    PartFail[thissite] = true
                    PrgLoc511 = true  -- not multisite
                end_if
	end_for  
	
	---------if part failed done or prog then program BAD data to location 511
        if PrgLoc511 then
            for siteidx =1 to sites do
	       thissite = OTP_active_sites[siteidx]
                if PartFail[thissite] then
                    otp_data[thissite] = 0xEFEFEFEF
                    otp_data510[thissite] = 0xFEFEFEFE
                else
                    otp_data[thissite] = 0x0
                end_if
	   end_for
	   
	   otp_addr = 511*32
           OTP_Reg_Write(DEV_ID, 16#1802,2,otp_addr , 4, otp_data )---Write data to address    program the CRC check location with BAD data
           wait(10ms) --- will work this out time wait for otp done/fail 
           --zin otp_addr = 511*32 -- not required two times write
           --zin OTP_Reg_Write(DEV_ID, 16#1802,2,otp_addr , 4, otp_data )---Write data to address    program the CRC check location with BAD data
           --zin wait(10ms) --- will work this out time wait for otp done/fail 
           
           read digital pin OTP_DONE_PIN state compare to high into DonePinHigh   ----expect high MT 1/2020
           read digital pin OTP_FAIL_PIN  state compare to low into PrgFailPin    ---expect low 
        
           RegRead(SER_ID, 0x1808 , 1,  upperword,lowword, "SER_UART_Read")      ---Check OTP8 bit4 to check OTP_PGM_FAIL status
           OTPLock =   integer(lowword)   -- OTP RD DONE and OTP LOCK  1000 1000 (0x88) 
        
           
            for siteidx =1 to sites do
	       thissite = OTP_active_sites[siteidx]
	       
	       OTP8_PgmFail_Check[thissite] = OTPLock[thissite] & 0x10 >> 4	       
	       	       
	       if ( (not DonePinHigh[thissite]) or (not PrgFailPin [thissite]) or (OTP8_PgmFail_Check[thissite] = 1) ) then	       
	          
	           trimcheck_enhancement [thissite] = 1 
	       
	     end_if
	       
	 end_for 
	 
	 DonePinHigh = false
	 PrgFailPin =  false
	 
         otp_addr = 510*32
         OTP_Reg_Write(DEV_ID, 16#1802,2,otp_addr , 4, otp_data510 )---Write data to address  program the CRC check location with BAD data
         wait(10ms) --- will work this out time wait for otp done/fail
         --zin otp_addr = 510*32 -- not required two times write
         --zin OTP_Reg_Write(DEV_ID, 16#1802,2,otp_addr , 4, otp_data510 )---Write data to address  program the CRC check location with BAD data
         --zin wait(10ms) --- will work this out time wait for otp done/fail  
         
         read digital pin OTP_DONE_PIN state compare to high into DonePinHigh   ----expect high MT 1/2020
         read digital pin OTP_FAIL_PIN  state compare to low into PrgFailPin    ---expect low 
        
         RegRead(SER_ID, 0x1808 , 1,  upperword,lowword, "SER_UART_Read")      ---Check OTP8 bit4 to check OTP_PGM_FAIL status
         OTPLock =   integer(lowword)   -- OTP RD DONE and OTP LOCK  1000 1000 (0x88) 
           
         for siteidx =1 to sites do
	       thissite = OTP_active_sites[siteidx]
	       
	       OTP8_PgmFail_Check[thissite] = OTPLock[thissite] & 0x10 >> 4	       
	       	       
	       if ( (not DonePinHigh[thissite]) or (not PrgFailPin [thissite]) or (OTP8_PgmFail_Check[thissite] = 1) ) then	       
	          
	           trimcheck_enhancement [thissite] = 1 	       
	       end_if
	   end_for
	    
	end_if            
        
        ---------------- z end --------------------------------------------------------------------------   

  
        ----------
        --verify what opt memory contain make sure it match with write in data.
        ---OTP read memory----
        OTP_Reg_Write(DEV_ID, OTP0,1, mlw(0x00), 0, mlw(0x00))---disable program
        OTP_Reg_Write(DEV_ID,OTP0 ,1, mlw(0x40), 0, mlw(0x00))---enable read
        fail_count =0 ---reset fail_count variable 

        ---DE require verify read back at different supply    
        Set_SER_Voltages(1.7, vdd, vdd18)
        if Test_Type = "FT"  then
            if OTP_TEMP = "COLD" then
                Set_SER_Voltages(1.7, 0.95, 1.58)                               --- # DE require verify read back at different supply   VDDIO= 1.7V VDD18= 1.58V, VDDD=0.95V   
            else
                Set_SER_Voltages(1.7, 0.95, 1.68)     ---Hot and Room                          --- # DE require verify read back at different supply   VDDIO= 1.7V VDD18= 1.68V, VDDD=0.95V   
            end_if
        else
            Set_SER_Voltages(1.7, 0.95, 1.7)    
        end_if    



        -----------------------------------------------------------------------
        ----Read whole memeroy at once MT
        read_data_burst = OTP_Reg_Read_burst(DEV_ID, OTP2, OTP14,   5    ,   0x86    ,    0x4B    ,   0x80       ,    -1, "GMSL1_HDMI1X")

        mem_offset = 0----initialize
        trim_fail_count = 0
    
        ---------Verify data read correctly
        for  i = 1 to  75 do
        
            if i = 74 then
                i= 75 -- we don't want to check this location ( for OSC trim code and not in CRC calculation)
                mem_offset = mem_offset + 1
            end_if
             
            if i >= 71 then   
                addr = 0x80 + lword(mem_offset)
                mem_offset = mem_offset + 1
            else
                addr = lword(i) + 4-----opt write data start at index 5
            end_if   
            
            for siteidx = 1 to sites do
                thissite =OTP_active_sites [siteidx]
                if (read_data_burst[thissite,i]  <> otp_write_data[thissite,addr]) and not(gmsl_1X_site_fail[thissite]) then
                    gmsl_1X_addr_fail[thissite] = integer(addr)
                    gmsl_1X_site_fail[thissite] = true
                    fail_count = fail_count +1   
                    if fail_count = sites then
                        addr = 1000 --- no need to compare   ----need change it to i
                    end_if                    
                end_if
            end_for          
        end_for 
        wait(0)

        -------------------per De read again at higher supplies
        -------------------------VDDIO= 3.6V VDD18= 1.9V, VDDD=1.05V---------------

        Set_SER_Voltages(3.6, 1.05,1.9)

        fail_count = 0                                                  --- # reset all flags
        gmsl_1X_site_fail = false 
        
        ---- Read whole memeroy at once MT
        read_data_burst = OTP_Reg_Read_burst(DEV_ID, DR_OTP2, DR_OTP14, 5, 0x86, 0x4B, 0x80,  -1, "GMSL1_HDMI1X")
        mem_offset = 0                                                  --- # initialize

        for  i = 1 to  75 do                                            --- # Verify data read correctly
             
            if i = 74 then
                i= 75 -- we don't want to check this location ( for OSC trim code and not in CRC calculation) 
                    mem_offset = mem_offset + 1
            end_if
        
            if i >= 71 then   
                addr = 0x80 + lword(mem_offset)
                mem_offset = mem_offset + 1
            else
                addr = lword(i) + 4                                     --- # opt write data start at index 5
            end_if     
            for siteidx = 1 to sites do
                thissite =OTP_active_sites [siteidx]
                if (read_data_burst[thissite,i]  <> otp_write_data[thissite,addr]) and not(gmsl_1X_site_fail1p9[thissite]) then
                    gmsl_1X_addr_fail1p9[thissite] = integer(addr)
                    gmsl_1X_site_fail1p9[thissite] = true
                    fail_count = fail_count +1   
                    if fail_count = sites then
                        i = 1000 --- no need to compare  ---same thing 
                    end_if                    
                end_if
            end_for        
        end_for 
        wait(0)        

        --------------------------Now need power cycle for buring CRC     

        DutPowerUp(vio, vdd18, vdd, "UART", "TP_GMSL2",POWERUP)
        wait(2ms)
        Set_SER_Voltages(3.6, 1.05, 1.9)
        wait(2ms)
        OTP_Reg_Write(DEV_ID, OTP0,1, mlw(0x00), 0, mlw(0x00))           --- # disable program
        OTP_Reg_Write(DEV_ID, OTP0,1, mlw(0x40), 0, mlw(0x00))           --- # enable read

        ---- Read whole memeroy at once MT
        read_data_burst = OTP_Reg_Read_burst(DEV_ID, OTP2, OTP14, 5, 0x86, 0x4B, 0x80,  -1, "GMSL1_HDMI1X")
        OtpRdWordValues =  OTP_Return_OneWord(read_data_burst)
        ---Calulate CRC base on HS84
        CrcValue = Crc32Calculate(OtpRdWordValues, 288, true)    ---need check in debug mt
        
        otp_data510 = 0  -- make sure all iniitialize with 0
        
        -----Only program CrcValue if part pass reading verification otherwise as it is retested we might encounter mix-bin rejects. MT
        for siteidx = 1 to sites do
            thissite =OTP_active_sites [siteidx]
            if gmsl_1X_site_fail[thissite] or gmsl_1X_site_fail1p9[thissite] or PartFail[thissite] then
                CrcValue[thissite] =  0xEFEFEFEF
                otp_data510[thissite] = 0xFEFEFEFE          
            end_if
            
            -- if PartFail[thissite] then
            --     CrcValue[thissite] = 0  -- this part already program with 0xEFEFEFEF on location511
            --     otp_data510[thissite] = 0 -- this part already program with 0xFEFEFEFE on location510         
            -- end_if
        
        end_for   

        -----Disable GMSL phy again
        reg_data = OTP_Reg_Read(DEV_ID, DR_CTRL0, 1)
        OTP_Reg_Write(DEV_ID, SR_CTRL0,1, (reg_data | 0x40), 0,mlw(0x00) )--------Turn off GMLS phy for trim because with this rev Vdd18 = 2.1V to trim it is higher then abmax spec 9/2018
        wait(10ms)
        Set_SER_Voltages(2.75, 0.95V, 2.1)                           -----Change to supplies to requested values
        wait(10ms)

        ----Burn CRC into memory location 511
        OTP_Reg_Write(DEV_ID, OTP0,1, mlw(0x00), 0, mlw(0))              --- # 16#1800: disable read OTP0 =0X1800 FOR HS89
        OTP_Reg_Write(DEV_ID, OTP1,1, mlw(0x02), 0, mlw(0))              --- # 16#1801: enable  OTP_PGM_DONE and OTP_PGM_FAIL to GPIO15  and GPIO14  and select GMSL section OTP1 = 0X1801
        OTP_Reg_Write(DEV_ID, OTP0,1, mlw(0x20), 0, mlw(0))              --- # Enable write
        
        DonePinHigh = false
        PrgFailPin = false  
        otp_addr   =   511*32                                               ----- set otp address to burn CRC value                
        OTP_Reg_Write(DEV_ID, 16#1802,2,otp_addr , 4, CrcValue )---Write data to address
        wait(10mS)
 
        ----Burn again
        --zin OTP_Reg_Write(DEV_ID, 16#1802,2,otp_addr , 4, CrcValue )---Write data to address
        --zin wait(10mS)
        
        read digital pin OTP_DONE_PIN state compare to high into DonePinHigh   ----expect high MT 1/2020
        read digital pin OTP_FAIL_PIN  state compare to low into PrgFailPin    ---expect low
        
        RegRead(SER_ID, 0x1808 , 1,  upperword,lowword, "SER_UART_Read")      ---Check OTP8 bit4 to check OTP_PGM_FAIL status
        OTPLock =   integer(lowword)   -- OTP RD DONE and OTP LOCK  1000 1000 (0x88) 
        
        for siteidx =1 to sites do
	       thissite = OTP_active_sites[siteidx]
	       
	       OTP8_PgmFail_Check[thissite] = OTPLock[thissite] & 0x10 >> 4  -- checking OTP8 OTP_PGM_FAIL and if filed will bin out to sepeate bin
	       
	       if ( (not DonePinHigh[thissite]) or (not PrgFailPin [thissite]) or (OTP8_PgmFail_Check[thissite] = 1) ) then	       
	          
	           trimcheck_enhancement [thissite] = 1 
	       
	       end_if
	       
	 end_for   
        
        wait(0)
        -------------z -----------------------------------------
        DonePinHigh = false
        PrgFailPin = false  
        otp_addr   =   510*32                                               ----- set otp address to burn 510 value                
        OTP_Reg_Write(DEV_ID, 16#1802,2,otp_addr , 4,otp_data510 )---Write data to address
        wait(10mS)
 
        ----Burn again
        OTP_Reg_Write(DEV_ID, 16#1802,2,otp_addr , 4, otp_data510 )---Write data to address
        wait(10mS)
        
        read digital pin OTP_DONE_PIN state compare to high into DonePinHigh   ----expect high MT 1/2020
        read digital pin OTP_FAIL_PIN  state compare to low into PrgFailPin    ---expect low  
        
        RegRead(SER_ID, 0x1808 , 1,  upperword,lowword, "SER_UART_Read")      ---Check OTP8 bit4 to check OTP_PGM_FAIL status
        OTPLock =   integer(lowword)   -- OTP RD DONE and OTP LOCK  1000 1000 (0x88) 
        
        for siteidx =1 to sites do
	       thissite = OTP_active_sites[siteidx]
	       
	       OTP8_PgmFail_Check[thissite] = OTPLock[thissite] & 0x10 >> 4  -- checking OTP8 OTP_PGM_FAIL and if filed will bin out to sepeate bin
	       
	       if ( (not DonePinHigh[thissite]) or (not PrgFailPin [thissite]) or (OTP8_PgmFail_Check[thissite] = 1) ) then	       
	          
	           trimcheck_enhancement [thissite] = 1 
	       
	       end_if
	       
	       
	 end_for   
        
        wait(0)
        ------------ z end -------------------------------------
        
        ----Debug --------------------------------&&&&()))))))      
        OTP_Reg_Write(DEV_ID, OTP0,1, mlw(0x40), 0,mlw(0))---Enable OPT read 
        OTP_Reg_Write(DEV_ID, OTP1,1, mlw(0x00), 0, mlw(0))---Select GMSL section       
        
        ---Read programed Crc at mem location 511
        otp_addr =  32*511	   
        OTP_Reg_Write(DEV_ID, OTP2, 2, otp_addr, 0,mlw(0x00) ) ---set address to read from   
        lowword = OTP_Reg_Read(DEV_ID, OTP14, 4)
        wait(0)
        ------))))))))
        ----------------OTP LOCK 

        OTP_Reg_Write(DEV_ID, OTP0, 1, mlw(0x00), 0, mlw(0)) ---disable read/write
        OTP_Reg_Write(DEV_ID, OTP1, 1, mlw(0x02), 0, mlw(0)) ---enable  OTP_PGM_DONE and OTP_PGM_FAIL to GPIO15  and GPIO14  and select GMSL section

        -- OTP_Reg_Write(DEV_ID, DR_OTPF,1  ,mlw(0xFF) , 0,  mlw(0) ) ---Mu Li removes this and add loop of 4 times program

        
         DonePinHigh = false
	 PrgFailPin =  false
        
        
        ---OTP Write 
        for i = 1 to 4 do 
            OTP_Reg_Write(DEV_ID,  OTP0, 1, mlw(0x10), 0, mlw(0))--- lock
            wait(1ms) 
            OTP_Reg_Write(DEV_ID, 16#1800,1, mlw(0x00), 0, mlw(0))---enable write and lock       
        end_for
        
        read digital pin OTP_DONE_PIN state compare to high into DonePinHigh   ----expect high MT 1/2020
        read digital pin OTP_FAIL_PIN  state compare to low into PrgFailPin    ---expect low 
        
        RegRead(SER_ID, 0x1808 , 1,  upperword,lowword, "SER_UART_Read")      ---Check OTP8 bit4 to check OTP_PGM_FAIL status
        OTPLock =   integer(lowword)   -- OTP RD DONE and OTP LOCK  1000 1000 (0x88) 
        
        --  for siteidx =1 to sites do
-- 	       thissite = OTP_active_sites[siteidx]
-- 	       
-- 	       OTP8_PgmFail_Check[thissite] = OTPLock[thissite] & 0x10 >> 4	       
-- 	       	       
-- 	       if ( (not DonePinHigh[thissite]) or (not PrgFailPin [thissite]) or (OTP8_PgmFail_Check[thissite] = 1) ) then	       
-- 	          
-- 	           trimcheck_enhancement [thissite] = 1 
-- 	       
-- 	       end_if
-- 	       
-- 	 end_for 
        
        
        
        -- reg_data = OTP_Reg_Read(DEV_ID, DR_CTRL0, 1)


        Set_SER_Voltages(1.7,  0.95V,1.7)    ---Change supplies to normal range MT
       
        -- reg_data = OTP_Reg_Read(DEV_ID, DR_OTP8, 1)  ----Readback Lock status bit                                                  
        -- OTP_Reg_Write(DEV_ID, DR_OTP0, 1, mlw(0x00), 0, mlw(0)) ---disable read/write
                       
    end_if
    --------------------------------end of verify  

    activate site current_active_sites
    sites = word(len(current_active_sites)) --- get number of sites at begining

    --------------------------Now need power cycle after buring CRC        
  
    DutPowerUp(vio, vdd18, vdd, "UART", "TP_GMSL2",POWERUP)
    
    Set_SER_Voltages(3.6, 1.05,1.9) -- zin change for Vmax normal read
    
    --------------------------------
    -----Read memory location 0x84 and 85; serial number and date trimmed 
    OTP_Reg_Write(DEV_ID, OTP0,1, mlw(0x40), 0,mlw(0))---Enable OPT read 
    OTP_Reg_Write(DEV_ID, OTP1,1, mlw(0x00), 0, mlw(0))---Select GMSL section

    otp_addr =  32*(0x84)	   
    OTP_Reg_Write(DEV_ID, OTP2,2, otp_addr, 0,mlw(0x00) )---set address to read from   
    reg_data = OTP_Reg_Read(DEV_ID, OTP14, 4)


    otp_addr =  32*(0x85)	   
    OTP_Reg_Write(DEV_ID, OTP2,2, otp_addr, 0,mlw(0x00) )---set address to read from   
    tempdata = OTP_Reg_Read(DEV_ID, OTP14, 4)
    otp_addr =  32*(0x86)
    OTP_Reg_Write(DEV_ID, OTP2,2, otp_addr, 0,mlw(0x00) )---set address to read from   
    tempdata1 = OTP_Reg_Read(DEV_ID, OTP14, 4)
    for siteidx = 1 to sites do
        thissite = current_active_sites[siteidx]  
        sitetrim[thissite] = integer(reg_data[thissite] & 0xFFFFFF)>> 20
        serial_num[thissite] = integer(reg_data[thissite]) & 0xFFFF
        time_trim[thissite] = integer(tempdata[thissite]) & 0xFFFFFF ---Datalog out minute and second 
        year_trim[thissite] = integer(tempdata1[thissite]) >> 16
        month_trim[thissite] = integer((tempdata1[thissite]) >> 8) & 0xFF
        day_trim[thissite] = integer(tempdata1[thissite])  & 0xFF
          

    end_for
--       for siteidx = 1 to sites do
--           thissite = current_active_sites[siteidx]  
--           sitetrim[thissite] = integer(reg_data[thissite] & 0xFFFFFF)>> 20
--           serial_num[thissite] = integer(reg_data[thissite]) & 0xFFFF
--           time_trim[thissite] = integer(tempdata[thissite]) & 0xFFFFFF ---Datalog out minute and second 
-- 
-- 
-- 
--       end_for

    ---Read programed Crc at mem location 511
    otp_addr =  32*511	   
    OTP_Reg_Write(DEV_ID, OTP2, 2, otp_addr, 0,mlw(0x00) ) ---set address to read from   
    CrcValueRb1p9 = OTP_Reg_Read(DEV_ID, OTP14, 4)

    ----Read whole memory to check CrcValue
    ---- Read whole memeroy at once MT
    read_data_burst = OTP_Reg_Read_burst(DEV_ID, OTP2, OTP14, 5, 0x86, 0x4B, 0x80,  -1, "GMSL1_HDMI1X")
    OtpRdWordValues =  OTP_Return_OneWord(read_data_burst)
    ---Calulate CRC base on HS84
    CrcValue1p9 = Crc32Calculate(OtpRdWordValues, 288, true)   
    ---Change supply to 1.7 as requested by DE
    
    if Test_Type = "QA" then
        Set_SER_Voltages(1.7, 0.95, 1.7)
    else
        if OTP_TEMP = "COLD" then
            Set_SER_Voltages(1.7, 0.95, 1.58) -------- FT flow  cold
        else
            Set_SER_Voltages(1.7, 0.95, 1.68) -------- FT flow
        end_if   
     end_if
        
    ---Read programed Crc at mem location 511
    otp_addr =  32*511	   
    OTP_Reg_Write(DEV_ID, OTP2, 2, otp_addr, 0,mlw(0x00) ) ---set address to read from   
    CrcValueRb1p7 = OTP_Reg_Read(DEV_ID, OTP14, 4)

    ---Read programed Speedlimit or not  at mem location 0x81
    otp_addr =  32*0x81	   
    OTP_Reg_Write(DEV_ID, OTP2, 2, otp_addr, 0,mlw(0x00) ) ---set address to read from   
    tempdata1 = OTP_Reg_Read(DEV_ID, OTP14, 4)
    
    reg_data1 = OTP_Reg_Read(SER_ID, REG15, 1) 
    
    for siteidx = 1 to sites do
        thissite = current_active_sites[siteidx]   
        
        if Part_Num = "MAX96757F" then
           if  ( (tempdata1[thissite]&0x20000000) == 0x20000000)  then
              speedgrade[thissite] = 1
           else
              speedgrade[thissite] = 0
           end_if
         end_if
        
        if Part_Num = "MAX96757H" then
           if  ( (tempdata1[thissite]&0x30000000) == 0x30000000)  then
              speedgrade[thissite] = 1
           else
              speedgrade[thissite] = 0
           end_if
         end_if
         
        if Part_Num = "MAX96757R" then
           if  ( (tempdata1[thissite]&0x20000000) == 0x20000000)  then
              speedgrade[thissite] = 1
           else
              speedgrade[thissite] = 0
           end_if
         end_if       
        
       
         
        if Part_Num = "MAX96757" or Part_Num = "MAX96973S" then   -- no speed grade trim 
           if  ( reg_data1[thissite]  == 0x01)  then
              speedgrade[thissite] = 0
           else
              speedgrade[thissite] = 1
           end_if
        end_if
         
         
    end_for

    ----Read whole memory to check CrcValue
    ---- Read whole memeroy at once MT
    read_data_burst = OTP_Reg_Read_burst(DEV_ID, OTP2, OTP14, 5, 0x86, 0x4B, 0x80,  -1, "GMSL1_HDMI1X")
    OtpRdWordValues =  OTP_Return_OneWord(read_data_burst)
    
    ---Calulate CRC base on HS84
    CrcValue1p7 = Crc32Calculate(OtpRdWordValues, 288, true)           
        
    for siteidx = 1 to sites do
        thissite = current_active_sites[siteidx]  
        if CrcValueRb1p7[thissite] = 0 then
            Crc1p7[thissite] = 1                                   ---------Readback data failed during trim
        elseif CrcValue1p7[thissite] <> CrcValueRb1p7[thissite] then
            Crc1p7[thissite] = 2                                    ---------Data flipped
        else
            Crc1p7[thissite] = 0
        endif
        
        if CrcValueRb1p9[thissite] = 0 then
            Crc1p9[thissite] = 1                                  ---------Readback data failed during trim
        elseif CrcValue1p9[thissite] <> CrcValueRb1p9[thissite] then
            Crc1p9[thissite] = 2                                   ---------Data flipped
        else
            Crc1p9[thissite] = 0    
        endif
    end_for    

    ----readlock
    reg_data = OTP_Reg_Read(DEV_ID, DR_OTP8, 1)  ----Readback Lock status bit and scramble
    OtpLockScramble = integer(reg_data ) & 0x0C
    
    --------------------------Post Trim Device ID check ----------------------------------------------------------------------
    ----------- Register 13 & 15 to determine if device is already trimmed  -------------
    ----------- Check for HDCP capable bit and device ID --------------------------------
  
    reg_data = OTP_Reg_Read(SER_ID, REG13, 1)      -- if reg_data = 156 (0x9C), part has been trimmed for HDCP version 
    reg13_val_post = integer(reg_data)
    reg_data1 = OTP_Reg_Read(SER_ID, REG15, 1)     -- this is for checking speed limit (Video Resolution) bit[5:4] / Dual View bit[3]/ Dual Link bit[2] / Splitter Mode bit[1]/ HDCP Capability bit[0]
    reg15_val_post = integer(reg_data1)
        
        
---------------- Power Off -------------------
    disconnect digital pin OTP_FAIL_PIN + OTP_DONE_PIN from ppmu
    connect digital pin OTP_FAIL_PIN + OTP_DONE_PIN to dcl
    wait(200us)
    
    set digital pin ALL_PATTERN_PINS  levels to vil 0V vih 200mV iol 0uA ioh 0uA vref 0V
    wait(100us)
  
    set digital pin ALL_PATTERN_PINS modes to comparator enable all fails
    set hcovi SER_VDD+SER_VDDIO +SER_VDD18 to fv 0V vmax 4V clamp imax 600mA imin -600mA   

    wait(3ms)     -- extra for 47uF cap on SER_VDD    
    -- Initialize for set_SER_Voltages(vio, vcore, v18) routine
    vdd_global[1] = 0V   --SER_VDDIO
    vdd_global[2] = 0V   --SER_VDD  
    vdd_global[3] = 0V   --SER_VDDA(VDD18)


    ----Datalog out
     
    test_value regvalue with trimmed_it-----check DEVICE_ID( not device address) For HS89 8x8 tqfn none hdcp = 0x9B, HDCP = 0x9C
    
    test_value TrimmedCheck510fail with InitialTrimCheck510
    test_value TrimmedCheck511fail with InitialTrimCheck511

    if NEED_PROGRAM > 0 then  ----data log trim 
        test_value HDCP_key_server_code with server_code_it
        test_value key_time with key_time_ft
        test_value prog_ok with trimok
        test_value trimcheck_enhancement with TrimEnhancementCheck
        --z test_value trim_fail_count with OTP_READ_VERIFY
    end_if

    test_value serial_num with SERIAL_NUMBER
    test_value sitetrim with SITETRIM
    test_value time_trim with TIMETRIM
    test_value year_trim with YrTrim
    test_value month_trim with MonthTrim
    test_value day_trim with DayTrim
    test_value Crc1p7 with Crc1p7dlog
    test_value Crc1p9 with Crc1p9dlog
    
    test_value OtpLockScramble with OTPLOCK
    test_value speedgrade   with SpeedLimit
    
    test_value reg13_val_post with Reg13_ID_Post
    test_value reg15_val_post with Reg15_ID_Post

end_body

