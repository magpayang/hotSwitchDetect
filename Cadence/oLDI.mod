use module "./FPGA.mod"
use module "./general_calls.mod"
use module "./SERDES_Pins.mod"
use module "./user_globals.mod"
use module "./reg_access.mod"
use module "./gen_calls2.mod"
procedure DES_Configure_oLDI_Ports(oLDIChannel, splitter)
--------------------------------------------------------------------------------
--  
in string[8]  : oLDIChannel
in boolean    : splitter

local lword   :  VAL01CE
local lword   :  VAL01CF



body

     VAL01CF = 0x08
    
     if oLDIChannel == "A" then
        VAL01CE = 0X07
--     elseif oLDIChannel == "B" then
--        VAL01CE = 0X87
     elseif oLDIChannel == "AB" then
        VAL01CE = 0X07
     endif
     
     if splitter then
        VAL01CE = VAL01CE | 0x08
     elseif oLDIChannel == "AB" then
        VAL01CF = VAL01CF | 0x02
     endif


     RegWrite(DNUT1_ID, 0x01CE, 1, 0, VAL01CE, "dnut_uart_write")
     RegWrite(DNUT1_ID, 0x01CF, 1, 0, VAL01CF, "dnut_uart_write")

end_body


procedure fpga_UART_Write_HS84(FPGA, source, destination_id, reg, bytes, data)
--------------------------------------------------------------------------------
-- This function will initiate a UART Write transaction on the UART pins connected to
-- the "source". Up to four bytes can be written with this function. UART Frequency must
-- be previously set with the fpga_set_UART_Frequency procedure.

in string[5] : FPGA         -- "FPGA1" or "FPGA2"
in string[8] : source       -- "HS84", (FPGA sends UART transaction here)
in lword     : destination_id   -- UART slave device ID to Write to
in lword     : reg          -- starting register address
in lword     : bytes        -- number of bytes to read (1,2,3, or 4)
in lword     : data         -- data to write

local multisite lword : id_reg
local multisite lword : uart_data

body

     id_reg     = destination_id + (reg << 8) + (bytes << 24)
     uart_data  = data


     if source = "HS84" then
        fpga_write_register(FPGA, HS84DES_UART_SEND_DATA, uart_data)      -- this must be first
        fpga_write_register(FPGA, HS84DES_UART_ARB, id_reg)               -- then this
     endif


     UART_wait(bytes)


end_body


function fpga_UART_Read_HS84(FPGA, source, destination_id, reg, bytes) : multisite lword
--------------------------------------------------------------------------------
-- This function will initiate an UART Read transaction on the UART pins connected to
-- the "source". Up to four bytes can be read with this function. UART Frequency must
-- be previously set with the fpga_set_UART_Frequency procedure.

in string[5] : FPGA         -- "FPGA1" or "FPGA2"
in string[8] : source       -- "HS84"  (FPGA sends UART transaction here)
in lword     : destination_id   -- UART slave device ID to Read from
in lword     : reg          -- starting register address
in lword     : bytes        -- number of bytes to read (1,2, or 3)

local multisite lword : id_reg
local multisite lword : uart_data
local word            : fpga_reg1, fpga_reg2

body

     destination_id = destination_id + 1            -- set read bit
     id_reg         = destination_id + (reg << 8) + (bytes << 24)

     
     if source = "HS84" then
        fpga_reg1 = HS84DES_UART_ARB
        fpga_reg2 = HS84DES_UART_IN_DATA



        fpga_write_register(FPGA, fpga_reg1, id_reg) -- initiates UART transaction



-- Read captured UART data
        UART_wait(bytes)
        uart_data = fpga_read_register(FPGA, fpga_reg2) & (2^(8*bytes)-1)  -- mask out unused upper bytes
        return(uart_data)
        
     endif

end_body


procedure fpga_Enable_oLDI_Port(Channel)
--------------------------------------------------------------------------------
--  
in string[8]  : Channel

local multisite lword : wval

body

    if Channel = "A" then
       wval = 0x01
    elseif Channel = "B" then
       wval = 0x02
    elseif Channel = "AB" then
       wval = 0x03
    endif

    fpga_write_register("FPGA1", oLDI_PORT_EN, wval)

end_body

function Calculate_oLDI_BitRate(PClkFreq, oLDI_splitter) : lword
--------------------------------------------------------------------------------
--  
in float     : PClkFreq
in boolean   : oLDI_splitter

local float  : BitRate
local lword  : bcd_val


body
 
       BitRate = PClkFreq * 7.0 / 1.0e6     -- BitRate in Mbps

       if oLDI_splitter then
          BitRate = BitRate / 2.0
       endif
       
       bcd_val = ConvertToBinaryCodedDecimal(BitRate)

       return(bcd_val)

end_body

function ConvertToBinaryCodedDecimal(data) : lword
--------------------------------------------------------------------------------
--  Function converts a float to Binary Coded Decimal

in float         : data

local lword      : temp
local lword      : shift
local lword      : bcd


body

     temp = lword(data) 
     shift = 0
     bcd   = 0 
     
     while temp > 0 do
        bcd = bcd + ((temp mod 10) << shift)
        temp = temp / 10
        shift = shift + 4
     endwhile
     
     return(bcd)

end_body

function fpga_compare_video_pattern_msite(repeat_cnt, oLDIChannel, compare_addr, split_pixel, compare_mode) : multisite lword[2]
--------------------------------------------------------------------------------
--  This procedure begins pattern compare of the captured data
--  Result value is composed of 4 bits
--  bit[0] = 1 --> pattern compare is done
--  bit[1] = 1 --> pattern compared passed
--  bit[2] = 1 --> start of first frame was found
--  bit[3] = 1 --> at least 4096 vectors were captured

in lword       :  repeat_cnt      -- Repeat count. Number of frames to compare.
in string[4]   :  oLDIChannel     -- oLDI portA, portB or BOTH
in lword       :  compare_addr    -- beginning address of the compare pattern
in boolean     :  split_pixel
in string[8]   :  compare_mode    -- "normal" or "checker"


local multisite lword : writeVal
local word            : data, idx, site_idx, local_site_cnt
local multisite lword : wval
local multisite lword : rslt1, rslt2
local multisite lword : rslt[2]
local word list[8]    : asites
local word list[MAX_SITES]    : loc_current_active_sites
local multisite lword : temp
local word            : csite

body

    idx = 1

    fpga_write_register("FPGA1", VCMPRPT_REG, mslw(repeat_cnt))
   
    fpga_write_register("FPGA1", VPSA_REG, mslw(compare_addr))
    

    wval = 0
--  When compare_mode is checker, the compare data will change every 128 lines
--  For lines 1-128,   compare data begins at address "compare_addr"
--  For lines 129-256, compare data begins at address ("compare_addr" + 128)
    if compare_mode == "checker" then
       wval = (1 <<1)
    endif
    
    if split_pixel then
       wval = wval + 1
    endif

    fpga_write_register("FPGA1", oLDI_COMP_MODE, wval)

    
    if(oLDIChannel == "A" ) then
       writeVal = 0x01
    elseif(oLDIChannel == "B" ) then
       writeVal = 0x02
    elseif(oLDIChannel == "AB" ) then 
       writeVal = 0x03
    endif
    
    fpga_write_register("FPGA1", oLDI_PORT_EN, writeVal)    -- tell FPGA which oLDI ports to do a pattern compare on

    fpga_write_register("FPGA1", CTRLREG, mslw(VPATCMP))    -- send command to begin pattern compare


    asites = get_active_sites
    loc_current_active_sites = get_active_sites()
    local_site_cnt = word(len(loc_current_active_sites))


-- Read Result
    if(oLDIChannel == "A" OR oLDIChannel == "AB") then
     -- keep reading the register until the LSB is HIGH. This means the pattern compare has finished
       while (idx < 100 AND local_site_cnt > 0) do
         rslt1 = fpga_read_register("FPGA1", oLDI_RSLT1_REG)
         for site_idx = 1 to local_site_cnt do
           csite = loc_current_active_sites[site_idx]
           temp[csite] = rslt1[csite]
           if rslt1[csite] & 0x01 == 0x01 then              
              deactivate site loc_current_active_sites[site_idx]
           endif
         endfor
         loc_current_active_sites = get_active_sites()
         local_site_cnt = word(len(loc_current_active_sites))
         idx = idx + 1
       endwhile
       
     -- Reset in case compare state machine is stuck
       if idx > 99 AND local_site_cnt > 0 then
          fpga_reset("FPGA1")
       endif
          
       activate site asites
    endif


    if(oLDIChannel == "AB") then
       rslt2 = fpga_read_register("FPGA1", oLDI_RSLT2_REG)
    endif
    
    rslt1 = temp

    scatter_1d(rslt1, rslt, 1)
    scatter_1d(rslt2, rslt, 2)

    return(rslt)

end_body   -- fpga_compare_video_pattern_msite



function mslw(data) : multisite lword
--------------------------------------------------------------------------------
--  
in lword :  data

local multisite lword : newdata


body

    newdata = data
    return(newdata)

end_body

procedure fpga_debug(data, oLDIChannel, failsites)
--------------------------------------------------------------------------------
--  Prints the result of failing sites to the screen
in multisite lword     : data
in string[8]           : oLDIChannel
in word list[8]        : failsites         -- failing sites


local integer          : idx
local multisite lword  : data2, data3, data4, data5, data6, data7, data8
local word             : csite
local lword            : stadd, endadd


body

     if oLDIChannel == "A" then
        data2 = fpga_read_register("FPGA1", oLDI_FRMCNT1)
        data3 = fpga_read_register("FPGA1", oLDI_LINECNT1)
        data4 = fpga_read_register("FPGA1", oLDI_PIXELCNT1)
        data5 = fpga_read_register("FPGA1", oLDI_FRMSTADDR1)
        data6 = fpga_read_register("FPGA1", oLDI_TOTPIXCNT1)
        data7 = fpga_read_register("FPGA1", oLDI_BITFAIL1)
        data8 = fpga_read_register("FPGA1", oLDI_FAILADDR1)
     elseif oLDIChannel == "B" then
        data2 = fpga_read_register("FPGA1", oLDI_FRMCNT2)
        data3 = fpga_read_register("FPGA1", oLDI_LINECNT2)
        data4 = fpga_read_register("FPGA1", oLDI_PIXELCNT2)
        data5 = fpga_read_register("FPGA1", oLDI_FRMSTADDR2)
        data6 = fpga_read_register("FPGA1", oLDI_TOTPIXCNT2)
        data7 = fpga_read_register("FPGA1", oLDI_BITFAIL2)
        data8 = fpga_read_register("FPGA1", oLDI_FAILADDR2)
     endif
     
     for idx = 1 to len(failsites) do
         csite = failsites[idx]
         println(stdout, "Frame Count = ", data2[csite])              -- which frame failed
         println(stdout, "Line Count = ", data3[csite])               -- active line count of first failure
         println(stdout, "Pixel Count = ", data4[csite])              -- active pixel count within the line of first failure
         println(stdout, "Frame Start Count = ", data5[csite] - 1)    -- number of pixels until start of frame
         println(stdout, "Total Active Pixels = ", data6[csite])      
         println(stdout, "Failing Bits = ", data7[csite]!h)           -- failing bits
         println(stdout, "Fail Address = ", data8[csite] - 1)         -- RAM address of first failure
     endfor



end_body



procedure fpga_Read_DDR2_Memory(FPGA, startAdd, endAdd, _site, bin_hex_dec)
---------------------------------------------------------------------------------
-- This procedure reads data from DDR2 memory (external DDR2 RAM chip)

in string[5]          : FPGA         -- "FPGA1" or "FPGA2"
in lword              : startAdd, endAdd   -- starting & ending addresses
in word               : _site              -- display for this site only
in string[3]          : bin_hex_dec        -- display data in bin, hex or dec

local multisite lword : writeVal
local lword           : idx
local word            : dev

body

      if FPGA == "FPGA1" then
         dev = 0x00
      elseif FPGA == "FPGA2" then
         dev = 0x40
      endif


      writeVal = lword(startAdd)
      fpga_write_register(FPGA, DDR_ADDR, writeVal)
      fpga_read_register(FPGA, DDR_RD_DATA)
      
      for idx = startAdd+1 to endAdd+1 do
          writeVal = lword(idx)
          fpga_rw_datapair(FPGA_SRC_RD, 0x00, DDR_RD_DATA, word(idx-startAdd), writeVal)
          
          if(bin_hex_dec == "hex") then
	     println(stdout,"Data at address ",(idx-1)!z:5," is ",writeVal[_site]!h!z:7)
	  elseif(bin_hex_dec == "bin") then
	     println(stdout,"Data at address ",(idx-1)!z:5," is ",writeVal[_site]!b!z:32)
	  else
	     println(stdout,"Data at address ",(idx-1)!z:5," is ",writeVal[_site]!d)
	  endif
      end_for
      
      writeVal = 0


end_body



function Configure_And_Link3(TP_COAX) : multisite lword
--------------------------------------------------------------------------------
--  
in string[6]           : TP_COAX


local multisite lword  : SerLock, DesLock, hs84Lock
local multisite lword  : lock_result
local word             : site, ii


body

 ----Set SER and DES for coax or tp mode
    if TP_COAX = "TP" then           
        fpga_UART_Write("FPGA1","DES", DESA_ID, DR_CTRL1, 1, 0x0A)                  ---- TP mode 
        fpga_UART_Write_HS84("FPGA1","HS84", DESB_ID, DR_CTRL1, 1, 0x22)            ---- TP mode        
    end_if 
   

----Program link rate
    fpga_UART_Write_HS84("FPGA1","HS84", DESB_ID, DR_REG1, 1, 0x02  )       ---- DES GMSL link speed 6G/187M
    fpga_UART_Write("FPGA1","DES", DESA_ID, DR_REG1, 1, 0x02  )             ---- DES GMSL link speed 6G/187M
    fpga_UART_Write("FPGA1","SER", SER_ID, SR_REG1, 1,  0x08  )             ---- SER GMSL link speed 6G/187M
    
-- Diable VDDCMP Errors
    fpga_UART_Write("FPGA1","SER", SER_ID, SR_INTR6, 1, 0x63  )
-----Write to reg10 to update link speed setting 

    fpga_UART_Write("FPGA1","SER", SER_ID,  SR_CTRL0 , 1, 0x53  )           -- Setup for Splitter Mode
    fpga_UART_Write("FPGA1","DES", DESA_ID, DR_CTRL0 , 1, 0x02  )           -- HS92 -> Use LinkB
    wait(15ms)
    fpga_UART_Write("FPGA1","SER", SER_ID,  SR_CTRL0 , 1, 0x23  )           ---Reset One-Shot

-------------------------------------------------------------------------------

   wait(50ms) 
   
   SerLock  = fpga_UART_Read("FPGA1", "SER", SER_ID, 0x13, 1)
   DesLock  = fpga_UART_Read("FPGA1", "DES", DESA_ID, 0x13, 1)
   hs84Lock = fpga_UART_Read_HS84("FPGA1", "HS84", DESB_ID, 0x13, 1)
   
   
   active_sites = get_active_sites
   sites = word(len(active_sites))  
 
   for idx = 1 to sites do
     site = active_sites[idx]
     if ((SerLock[site] & 0xEB) <> 0xCA) then    
        for ii = 1 to 100 do
           SerLock = fpga_UART_Read("FPGA1", "SER", SER_ID,  0x13, 1)        -- 0xDA: Lock
           DesLock = fpga_UART_Read("FPGA1", "DES", DESA_ID, 0x13, 1)        -- 0xDA: Lock
           hs84Lock = fpga_UART_Read_HS84("FPGA1", "HS84", DESB_ID, 0x13, 1)
           wait(1ms)
           if (SerLock[site] & 0xEB) == 0xCA then
              break
           endif
        endfor
     endif 
   end_for

   lock_result = (SerLock << 8) + DesLock + (hs84Lock << 16)
   lock_result = lock_result & 0xFBFBFB    -- mask out Errors
   return(lock_result)


end_body


procedure fpga_capture_video(pixels, lines, HBP, HPW, HFP, VBP, VPW, VFP, FrameCnt, FrameDel)
--------------------------------------------------------------------------------
-- This procedure configures the FPGA registers and begins capturing video data

in lword:       pixels      -- number of active pixels per line
in lword:       lines       -- number of active lines
in lword:       HBP         -- Horizontal Back Porch  (number of pixels)
in lword:       HPW         -- Horizontal Pulse Width (number of pixels)
in lword:       HFP         -- Horizontal Front Porch (number of pixels)
in lword:       VBP         -- Vertical Back Porch    (number of lines)
in lword:       VPW         -- Vertical Pulse Width   (number of lines)
in lword:       VFP         -- Vertical Front Porch   (number of lines)

in lword:       FrameCnt    -- Frame Count   (number of frames)
in lword:       FrameDel    -- Delay start of data capture for this many frames

local multisite lword :  writeVal
local lword           :  resolution
local lword           :  hblank
local lword           :  vblank
local word            :  data
local lword           :  hfp, hpw, hbp
local lword           :  vfp, vpw, vbp
local lword           :  PIXELS, LINES

body

    hfp = HFP & 0xFF     -- limit HFP to 8 bits
    hpw = HPW & 0xFF     -- limit FPW to 8 bits
    hbp = HBP & 0x1FF    -- limit HBP to 9 bits
    
    vfp = VFP & 0xFF     -- limit VFP to 8 bits
    vpw = VPW & 0xFF     -- limit VPW to 8 bits
    vbp = VBP & 0xFF     -- limit VBP to 8 bits
    
    PIXELS = pixels & 0xFFF  -- limit pixels to 12 bits
    LINES  = lines  & 0xFFF  -- limit lines  to 12 bits 
        
    hblank     = (hbp<<16) + (hpw<<8) + hfp    -- pack horizontal blanking data
    vblank     = (vbp<<16) + (vpw<<8) + vfp    -- pack vertical blanking data
    resolution = (PIXELS<<16) + LINES          -- pack display resolution data


-- Write data to FPGA Registers
    writeVal = resolution
    fpga_write_register("FPGA1",VRES_REG, writeVal)
    writeVal = hblank
    fpga_write_register("FPGA1",VH_REG, writeVal)
    writeVal = vblank
    fpga_write_register("FPGA1",VV_REG, writeVal)
    writeVal = FrameCnt
    fpga_write_register("FPGA1",VRPT_REG, writeVal)
    fpga_write_register("FPGA1",VCMPRPT_REG, writeVal)
--    writeVal = FrameDel
--    fpga_write_register("FPGA1",VFRAME_DEL_REG, writeVal)
    
-- After the FPGA registers are setup, send command to begin capturing video data
   writeVal = VCAPEN           -- captures oLDI data
   fpga_write_register("FPGA1",CTRLREG, writeVal)
    
end_body


procedure WaitForVideoCapture
--------------------------------------------------------------------------------
-- Wait for video capture to finish by Checking MSB bit of oLDI_RSLT1_REG 

local word list[8]    : loc_active_sites
local word            : loc_sites
local word            : jj
local word            : CurrSite
local multisite lword : check

body

  loc_active_sites = get_active_sites()
  loc_sites        = word(len(loc_active_sites))

  -- Wait for capture to finish -----------------------------------------
     for idx = 1 to loc_sites do
         CurrSite = loc_active_sites[idx]
         for jj = 1 to 200 do  
             check = fpga_read_register("FPGA1", oLDI_RSLT1_REG)
             if check[CurrSite] & 0x8 = 0x8 then
          --    println(stdout, "Wait for capture index :", jj)
                break
             endif
         endfor
     endfor


end_body



procedure HDCP_Functional(Vdd, Vddio, Vdd18, TP_COAX, POWERUP, POWERDOWN, LockTest, FPGA_temp, oLDIFreq, VideoDet, HDCP_Auth, HDCP_Video)
--------------------------------------------------------------------------------
-- 
in float                     : Vdd, Vddio, Vdd18
in string[10]                : TP_COAX
in boolean                   : POWERUP,POWERDOWN
in_out array of integer_test : LockTest
in_out float_test            : FPGA_temp
in_out float_test            : oLDIFreq
in_out integer_test          : VideoDet
in_out integer_test          : HDCP_Auth
in_out integer_test          : HDCP_Video


local multisite lword        : lock_status
local multisite integer      : SerLock, hs84Lock, Lockrslt[2], verify_video, encryption
local multisite lword        : data, data2
local multisite float        : pclk_freq
local multisite lword        : rslt[2]
local multisite integer      : PiPeX_rslt
local multisite float        : measured_oLDIA_Freq
local multisite float        : fpga_die_temp
local multisite lword        : oBR
local boolean                : oLDI_splitter = FALSE
local float                  : BitRate, PclkFreq, ttime
local lword                  : numFrames = 2

body

    disconnect hvvi chan SER_RSVD    -- need to float RSVD, important!!
    close cbit X1X2_POSC             -- connects DPs to Port Expander
-----Dut power up function
    if POWERUP then
        if TP_COAX = "COAX" then
           close cbit COAXB_M_RELAY + CB2_SLDC
        else
           open cbit  COAXB_M_RELAY + CB2_SLDC
        endif
        close cbit FB_RELAY -- MIPI LoopBack Relays
        close cbit CB_SIOA  -- connect GMSL Link A to HS84
        wait(1ms)
        DutPowerUp(Vddio, Vdd18, Vdd, "UART", TP_COAX+"_GMSL2", POWERUP)
        set digital pin AUX_PINS levels to vil 0mV vih 3.3V iol 2mA ioh -2mA vref 3.3V
---Close relay to connect FPGA to control TX/RX on DNUT
        close cbit  DNUT_RXTX_RELAY + MFP_LT_K12_RELAY
        close cbit MFP_LT_RELAY  + I2C_LT_CB
        wait(0ms)
--------powerup_dnut_vdd_vterm(VDD_SET, VTERM_SET)
        powerup_dnut_vdd_vterm(1.2,1.2)
        wait(3ms)
  --fpga_Set_DNUT_Pins("FPGA1", CFG1, CFG0, PWDN, latch)
        fpga_Set_DNUT_Pins("FPGA1", 0, 0, 1, 1, TRUE)    -- UART/COAX/GMSL2=1/RATE=0(6 Gig link)
        fpga_write_register("FPGA1", OREG2, mslw(0x0A))
        fpga_write_register("FPGA1", OREG2, mslw(0x0B))  -- HS84 COAX/UART/6G   Address = 0x94
        wait(6ms)    
    else
        Set_SER_Voltages(Vddio, Vdd, Vdd18)
        set digital pin AUX_PINS levels to vil 0mV vih 3.3V iol 2mA ioh -2mA vref 3.3V
    end_if
   

-- Set FPGA UART Speed     
    fpga_set_UART_Frequency("FPGA1", 1MHz)


-- Establish Link Lock
    lock_status = Configure_And_Link_For_HDCP(TP_COAX)
     
    SerLock  = integer ((lock_status & 0xFF00) >> 8)
    hs84Lock = integer (lock_status & 0xFF)
    
    scatter_1d( SerLock ,  Lockrslt , 1 )
    scatter_1d( hs84Lock , Lockrslt , 2 )
    
    
 -- Configure HS84
    fpga_UART_Write_HS84("FPGA1", "HS84", DESB_ID, 0x1CE, 1, 0x47)  -- oLDI VESA on HS84
data2 = fpga_UART_Read_HS84("FPGA1", "HS84", DESB_ID, 0x1CE, 1)    
----------------------------------------------------------------------------------------
------- Generate color bar pattern using video timing & pattern generator (Pipe X) -----
------- Resolution is 1920x1200  (2080 x 1235  Total)
--- VPWidth = 6 lines
--- VBporch = 26
--- VFporch = 3
--- HPWidth = 32 pixels
--- HBporch = 80
--- HFporch = 48

    fpga_UART_Write("FPGA1", "SER", SER_ID, 0x1C8, 1, 0xE3)
--  fpga_UART_Write("FPGA1", "SER", SER_ID, 0x1CA, 4, 0x00000000)   -- These are the default values
    fpga_UART_Write("FPGA1", "SER", SER_ID, 0x1CE, 4, 0x0127C030)
    fpga_UART_Write("FPGA1", "SER", SER_ID, 0x1D2, 4, 0x000000A0)
    fpga_UART_Write("FPGA1", "SER", SER_ID, 0x1D6, 4, 0x00082000)
    fpga_UART_Write("FPGA1", "SER", SER_ID, 0x1DA, 4, 0x0401D304)
    fpga_UART_Write("FPGA1", "SER", SER_ID, 0x1DE, 4, 0x00800770)
    fpga_UART_Write("FPGA1", "SER", SER_ID, 0x1E2, 4, 0x02B004A0)
--  fpga_UART_Write("FPGA1", "SER", SER_ID, 0x1E6, 1, 0x04)         -- This is the default value
    
   

-- Enable Parallel Video   
    fpga_UART_Write("FPGA1", "SER", SER_ID, 0x07, 1, 0xF7)         -- Set PAR_VID_EN = 1
    
---- Set the LT direction SER -> FPGA
    SetPortExpander(PORT_EXP, 0x37)  -- FPGA drives SER MFP3
    
-- Send 150MHz PCLK to SER MFP3
    fpga_write_register("FPGA1", GPIO_CONTROL, mslw(0x80))
    wait(5ms)
    

-- Verify Video is being sent    
    data = fpga_UART_Read("FPGA1",       "SER", SER_ID,  0x102, 1)        -- Should be 0x8A
    data2 = fpga_UART_Read_HS84("FPGA1", "HS84", DESB_ID, 0x108, 1)       -- Should be 0x62
    
    verify_video = integer(data + (data2 << 8))
 
    
-- Enable AHDCP
    fpga_UART_Write("FPGA1",      "SER",  SER_ID,  0x16B7, 1, 0x00) -- Power Up HDCP Blocks
    fpga_UART_Write_HS84("FPGA1", "HS84", DESB_ID, 0x6B7,  1, 0x40) -- Power Up HDCP Blocks
    fpga_UART_Write("FPGA1",      "SER",  SER_ID,  0x1677, 1, 0x06)
    fpga_UART_Write("FPGA1",      "SER",  SER_ID,  0x16B9, 1, 0x94) -- Sets address of connected DNUT (HS84)
    fpga_UART_Write("FPGA1",      "SER",  SER_ID,  0x16B8, 1, 0x03)
    fpga_UART_Write("FPGA1",      "SER",  SER_ID,  0x16B8, 1, 0x00)
    fpga_UART_Write("FPGA1",      "SER",  SER_ID,  0x16B8, 1, 0x01)
    
    wait(40ms)
    encryption = integer(fpga_UART_Read("FPGA1",  "SER",  SER_ID,  0x1698, 1))   -- 0x70 indicates encryption has started succesfully
    
    --fpga_UART_Write_HS84("FPGA1", "HS84", DESB_ID, 0x2, 1, 0x7)  --z
    --wait(15ms)
    --wait(1600ms) -- Zin Debug Delay 
    fpga_UART_Write_HS84("FPGA1", "HS84", DESB_ID, 0x2, 1, 0x47)  --z
    wait(20ms)
    wait(25ms) -- Zin Debug Delay 
--------------------------------------------------------------------------------------------------------    
    fpga_Enable_oLDI_Port("A")
    PclkFreq = 150MHz          -- this is the expected Pixel Clock Frequency
    oBR = Calculate_oLDI_BitRate(PclkFreq, oLDI_splitter)   -- calculate oLDI BitRate
    fpga_write_register("FPGA1", oLDI_BIT_RATE, oBR)
    
    data2 = fpga_read_register("FPGA1", FPGA_DIE_TEMP)
    fpga_die_temp =  (float(data2) * 503.975 ) /4096.0 - 273.15

    wait(1ms)
    data2 = fpga_read_register("FPGA1", oLDIA_FREQ)
    measured_oLDIA_Freq = float(data2) * 1.0e5
---------------------------------------------------------------------------------------------------------     
-------------- Capture and Compare Video Pipe X
    -- fpga_capture_video(pixels, lines, HBP, HPW, HFP, VBP, VPW, VFP, FrameCnt, FrameDel)
    fpga_capture_video(1920, 1200, 80, 32, 48, 26, 6, 3, numFrames, 0)

    -- Wait for capture to finish -----------------------------------------
    WaitForVideoCapture()


    rslt = fpga_compare_video_pattern_msite(numFrames, "A", GRAD_PAT_ADDR, oLDI_splitter, "normal")
    PiPeX_rslt = integer(gather_1d( rslt , 1 ))
    
-- bit[3] --> at least 4096 vectors captured
-- bit[2] --> vsync edge found
-- bit[1] --> pattern compare passed
-- bit[0] --> pattern compare is done
    
    if PiPeX_rslt[3] <> 15 then
        wait(0)
    end_if
    
--    if PiPeX_rslt[3] <> 15 then
--      fpga_debug(data2, "A", <:3:>)
--      data2 = fpga_read_register("FPGA1", 121)
--     fpga_Read_DDR2_Memory("FPGA1",0x000000+0000,    0x000000+90, 3, "hex")
--        wait(0ms)
--      fpga_Read_DDR2_Memory("FPGA1",0x000000+66670,    0x000000+66800, 1,"hex")
--        fpga_Read_DDR2_Memory("FPGA1",0x000000+67180,    0x000000+67200, 1, "hex")
--        fpga_Read_DDR2_Memory("FPGA1",0x000000+2565390,  0x000000+2565900, 1, "hex")
--   endif
    

    
-- Power Off
    if(POWERDOWN) then
        set digital pin ALL_PATTERN_PINS  - FPGA_CSB-FPGA_SCLK-FPGA_SDIN-FPGA_SDOUT levels to vil 0V vih 200mV iol 0uA ioh 0uA vref 0V            
        powerdown_device(TRUE) -- (POWERDOWN)
        fpga_Set_DNUT_Pins("FPGA1", 0, 0, 1, 0, FALSE)   -- power down the DNUT
        fpga_write_register("FPGA1", OREG2, mslw(0x00))  -- power down HS84
        open cbit  DNUT_RXTX_RELAY + MFP_LT_K12_RELAY
        open cbit  MFP_LT_RELAY  + I2C_LT_CB

        open cbit  CB2_SLDC                 --OVI_RELAYS 
        open cbit  COAXB_M_RELAY            --OVI_RELAYS
        open cbit  FB_RELAY + CB_SIOA
        open cbit  X1X2_POSC             -- disconnects DPs to Port Expander zin
        wait(5ms)
    end_if
    
    
    test_value Lockrslt             with LockTest
    test_value fpga_die_temp        with FPGA_temp
    test_value measured_oLDIA_Freq  with oLDIFreq
    test_value verify_video         with VideoDet
    test_value encryption           with HDCP_Auth
    test_value PiPeX_rslt           with HDCP_Video
    

end_body

function Configure_And_Link_For_HDCP(TP_COAX) : multisite lword
--------------------------------------------------------------------------------
--  
in string[6]           : TP_COAX


local multisite lword  : SerLock, hs84Lock
local multisite lword  : lock_result
local word             : site, ii


body

 ----Set SER and DES for coax or tp mode
    if TP_COAX = "TP" then           
        fpga_UART_Write("FPGA1","DES", DESA_ID, DR_CTRL1, 1, 0x0A)                  ---- TP mode 
        fpga_UART_Write_HS84("FPGA1","HS84", DESB_ID, DR_CTRL1, 1, 0x22)            ---- TP mode        
    end_if 
   

----Program link rate
    fpga_UART_Write_HS84("FPGA1","HS84", DESB_ID, DR_REG1, 1, 0x02  )       ---- DES GMSL link speed 6G/187M
    fpga_UART_Write("FPGA1","SER", SER_ID, SR_REG1, 1,  0x08  )             ---- SER GMSL link speed 6G/187M
    
-- Diable VDDCMP Errors
    fpga_UART_Write("FPGA1","SER", SER_ID, SR_INTR6, 1, 0x63  )
-----Write to reg10 to update link speed setting 


    wait(15ms)
    fpga_UART_Write("FPGA1","SER", SER_ID,  SR_CTRL0 , 1, 0x21  )           ---Reset One-Shot (Use only GMSL Link A)

-------------------------------------------------------------------------------

   wait(50ms) 
   
   SerLock  = fpga_UART_Read("FPGA1", "SER", SER_ID, 0x13, 1)
   hs84Lock = fpga_UART_Read_HS84("FPGA1", "HS84", DESB_ID, 0x13, 1)
   
   
   active_sites = get_active_sites
   sites = word(len(active_sites))  
 
   for idx = 1 to sites do
     site = active_sites[idx]
     if ((SerLock[site] & 0xEB) <> 0xCA) then    
        for ii = 1 to 100 do
           SerLock = fpga_UART_Read("FPGA1", "SER", SER_ID,  0x13, 1)        -- 0xDA: Lock
           hs84Lock = fpga_UART_Read_HS84("FPGA1", "HS84", DESB_ID, 0x13, 1)
           wait(1ms)
           if (SerLock[site] & 0xEB) == 0xCA then
              break
           endif
        endfor
     endif 
   end_for

   lock_result = (SerLock << 8) + hs84Lock
   lock_result = lock_result & 0xFBFB    -- mask out Errors
   return(lock_result)


end_body

