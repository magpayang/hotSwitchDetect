use module "./user_globals.mod"
use module "./lib/lib_common.mod"
use module "./SERDES_Pins.mod"
use module "./reg_access.mod"
use module "./FPGA.mod"
use module "./general_calls.mod"
function FS7140SetFrequency(DevId, UsrFreq) : multisite word
--------------------------------------------------------------------------------
--  This function writes to FS7140 registers to set the frequency given a
--  27MHz crystal. Actual frequencies are selected to match Toshiba frequencies.
in word               : DevId
in float              : UsrFreq


local
  lword                 : LowerDataWord = 0, UpperDataWord = 0
  multisite lword       : LowerRdWord, UpperRdWord
  string[8]             : response
  word                  : local_sites, CurSite
  multisite word        : Status
  word list[MAX_SITES]  : current_active_sites, local_active_sites 

end_local

body


    local_active_sites = get_active_sites()
    LowerRdWord = 0
    UpperRdWord = 0
    Status = 0
    
    if (UsrFreq == 6.144MHz) then
      UpperDataWord = (34 << 8 + 130)   -- Register Bytes 5 - 4     
      LowerDataWord = ((56 << 24) + (119 << 16) + (0 << 8) + 39)    -- Register Bytes 3 - 0
    elseif (UsrFreq == 6.25MHz) then
      UpperDataWord = (34 << 8 + 129)   -- Register Bytes 5 - 4     
      LowerDataWord = ((144 << 24) + (119 << 16) + (0 << 8) + 27)    -- Register Bytes 3 - 0
    elseif (UsrFreq == 12.288MHz) then
      UpperDataWord = (34 << 8 + 130)   -- Register Bytes 5 - 4     
      LowerDataWord = ((56 << 24) + (55 << 16) + (0 << 8) + 39)     -- Register Bytes 3 - 0
    elseif (UsrFreq == 12.5MHz) then
      UpperDataWord = (34 << 8 + 129)   -- Register Bytes 5 - 4     
      LowerDataWord = ((144 << 24) + (55 << 16) + (0 << 8) + 27)     -- Register Bytes 3 - 0
    elseif (UsrFreq == 25MHz) then
      UpperDataWord = (34 << 8 + 129)        
      LowerDataWord = ((144 << 24) + (23 << 16) + (0 << 8) + 27)    -- refdiv = 27, post3 = 1, post2 = 2, post1 = 8, FBKDIV = 0x190 
    else_if (UsrFreq == 49.152MHz) then
      UpperDataWord = (34 << 8 + 130)        
      LowerDataWord = ((56 << 24) + (7 << 16) + (0 << 8) + 39)
    else_if (UsrFreq == 50MHz) then
      UpperDataWord = (34 << 8 + 129)        
      LowerDataWord = ((144 << 24) + (7 << 16) + (0 << 8) + 27)
    else
        println(stdout,UsrFreq)
        Print_banner_message("Error","Frequency Not Supported","Press 'Enter' to Continue")
        input(stdin, response!L)
    end_if



    i = 3
    if(UsrFreq <> OSC_FREQ) then
       current_active_sites = get_active_sites()
      local_sites = word(len(current_active_sites))
      
      while (i > 0 and local_sites > 0) do
        RegWrite(DevId, 16#0, 6, UpperDataWord, LowerDataWord, "Aux_I2C_Write") 
        wait(1ms) 
        RegRead(DevId, 0, 6, UpperRdWord, LowerRdWord, "Aux_I2C_Read")   
        for idx = 1 to local_sites do
          CurSite = current_active_sites[idx]
          if LowerRdWord[CurSite] == LowerDataWord and UpperRdWord[CurSite] == UpperDataWord then
             deactivate site CurSite
             Status[CurSite] = 1
          endif
        endfor
        current_active_sites = get_active_sites()
        local_sites = word(len(current_active_sites))
        i = i - 1    
      end_while
    endif
   
    activate site local_active_sites
   
    --OSC_FREQ = UsrFreq
    return(Status)
   
end_body


procedure SetPortExpander(DevId, data)
--------------------------------------------------------------------------------
--  This function writes to the MAX7321 Port Expander
in word                 : DevId
in word                 : data


local
  lword                 : LowerDataWord = 0
  multisite lword       : LowerRdWord, UpperRdWord
  word                  : local_sites, CurSite
  word list[MAX_SITES]  : current_active_sites, local_active_sites 

end_local

body


    local_active_sites = get_active_sites()
 
    LowerDataWord = lword(data)
    
    
    current_active_sites = get_active_sites()
    local_sites = word(len(current_active_sites))
    
    i = 3
      
    while (i > 0 and local_sites > 0) do
       RegWrite(DevId, 0, 1, 0, LowerDataWord, "Aux_I2C_Write_PortExp")
       RegRead(DevId, 0, 1, UpperRdWord, LowerRdWord, "Aux_I2C_Read_PortExp")   
       for idx = 1 to local_sites do
          CurSite = current_active_sites[idx]
          if LowerRdWord[CurSite] == LowerDataWord then
             deactivate site CurSite
          endif
       endfor
       current_active_sites = get_active_sites()
       local_sites = word(len(current_active_sites))
       i = i - 1    
    end_while

   
    activate site local_active_sites
   

   
end_body



function Configure_And_Link(TP_COAX, TX_SPD, RX_SPD, Lock_Delay) : multisite lword
--------------------------------------------------------------------------------
--  
in string[6]           : TP_COAX
in float               : TX_SPD, RX_SPD
in float               : Lock_Delay


local lword            : ser_tx_speed, ser_rx_speed
local lword            : des_tx_speed, des_rx_speed
local lword            : ser_link_speed_code
local lword            : des_link_speed_code
local multisite lword  : ser_lock, des_lock
local multisite lword  : lock_result


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

   wait(Lock_Delay)   --NEEDED to see LOCK bits on both SER/DES at 3G serial links !!!   
   
   ser_lock  = fpga_UART_Read("FPGA1", "SER", SER_ID, 0x13, 1)
   des_lock  = fpga_UART_Read("FPGA1", "DES", DESA_ID, 0x13, 1)   -- DES lock bit, 0xCA expected


   lock_result = (ser_lock << 8) + des_lock
   return(lock_result)


end_body

