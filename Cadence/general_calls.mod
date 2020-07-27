use module "./user_globals.mod"
use module "./lib/lib_common.mod"
use module "./SERDES_Pins.mod"
use module "./reg_access.mod"
use module "./FPGA.mod"








function add_parity_bit(number_to_convert) :   word
--------------------------------------------------------------------------------
--  This function takes an unsigned integer (word) and checks for even/odd parity.
--  Number will have 8 bits of info. Function will convert it into a 9 bit number,
--  adding a parity bit into the MSB (9th bit).  Parity bit
--  is 1 if original parity is odd and 0 if it is even.
--  This algorithm loops one time for each bit that is set.
--  It's based on an algorithm that deletes the right most
--  bit in a byte. If the byte is 'b' then the algorithm is:
--  b = b & (b-1)
--  for example if
--       b = xxxx1000
--       b-1 = xxxx0111
-- b & (b-1) = xxxx0000   ;The right most bit of b is deleted


in word: number_to_convert

local

word :  bb, bit_count, converted_number

end_local

body

    bit_count=0
    bb = number_to_convert

    while bb <> 0 do
          bb = bb & (bb-1)
          bit_count = bit_count +1
    end_while
    
    converted_number = number_to_convert
    if (bit_count mod 2 = 1) then                -- if the number of 1's is odd
        converted_number = converted_number+2#100000000   -- set parity bit to 1
    endif
    
    return(converted_number)

end_body
procedure Set_SER_Voltages(vio, vcore, v18)
--------------------------------------------------------------------------------
--This function sets serializer voltages only if voltage needs to change.
--A global variable "vdd_global[]" is used to store the current voltages

in float    : vio     -- level for IOVDD
in float    : vcore   -- level for VDD core
in float    : v18     -- level for VDD18 (VDDA) 

local

   float    : volt_70pct
   float    : curr_v

end_local


body
    
    set digital pin  fpga_pattern_pins  levels to vil 0V vih 2.7 vol  2.7*0.5 voh 2.7*0.5 iol 0uA ioh 0uA vref 0V


-- Set serializer VDD voltage only if it needs to be changed
    if vcore <> vdd_global[2] then
       --set qfvi  SER_VDDD vrange to r60v vclamps to vmax 5v vmin -5v
        set hcovi SER_VDD  to fv vcore vmax 2.0V measure i max 600ma clamp imax 900mA imin -900mA
        vdd_global[2] = vcore
    end_if
    
-- Set serializer AVDD(VDD18) voltage only if it needs to be changed
    if v18 <> vdd_global[3] then
       set hcovi SER_VDD18  to fv v18 vmax 4V  measure  i max 600ma clamp imax 900mA imin -900mA      
       vdd_global[3] = v18
    end_if

    
-- Set serializer IOVDD voltage only if it needs to be changed
    if vio <> vdd_global[1] then
 
 
    -- if voltage needs to be set higher
       if vio > vdd_global[1] then
       
         if vdd_global[1] > 0.0 then
          curr_v = vdd_global[1]     -- current IOVDD voltage
	  volt_70pct = curr_v/0.7    -- highest voltage we can set IOVDD to before we risk voltage at /PWDN	       
	                             -- resetting the device
	 else
          curr_v = 1.5               -- current IOVDD voltage
	  volt_70pct = 1.5           -- highest voltage we can set IOVDD to before we risk voltage at /PWDN	       
	 end_if                      -- resetting the device
	                       	   
				     
          if vio <= volt_70pct then
	     set hcovi SER_VDDIO to fv vio   vmax 4V clamp imax 600mA imin -600mA
	     wait(400us)
	     set digital pin ALL_PATTERN_PINS - SER_GPIO20_TXSCL - SER_GPIO19_RXSDA - fpga_pattern_pins  levels to vil 0.2V vih vio vol 400mV voh vio*0.8 iol 0uA ioh 0uA vref 0V
             set digital pin SER_GPIO20_TXSCL + SER_GPIO19_RXSDA levels to vil 0V vih vio  vol 0.5*vio voh 0.5*vio iol 2mA ioh -2mA vref vio
--              set digital pin SER_GPIO20_TXSCL - SER_GPIO20_TXSCL- fpga_pattern_pins levels to vil 0V vih vio  vol 0.5*vio voh 0.5*vio iol 2mA ioh -2mA vref vio
      	     	  
	  else
	     set hcovi SER_VDDIO to fv volt_70pct   vmax 4V clamp imax 600mA imin -600mA
	     wait(400us)
	     set digital pin ALL_PATTERN_PINS  - SER_GPIO20_TXSCL - SER_GPIO19_RXSDA- fpga_pattern_pins levels to vil 0.2V vih volt_70pct vol 400mV voh volt_70pct*0.8 iol 0uA ioh 0uA vref 0V
             set digital pin SER_GPIO20_TXSCL + SER_GPIO19_RXSDA  levels to  vil 0V vih volt_70pct vol 0.5*volt_70pct voh 0.5*volt_70pct iol 0.2mA ioh -0.2mA vref volt_70pct
	     
	  -- After first setting to an intermediate voltage, it should now be ok to set to the final voltage 
	     set hcovi SER_VDDIO to fv vio   vmax 4V clamp imax 600mA imin -600mA
	     wait(400us)
	     set digital pin ALL_PATTERN_PINS  - SER_GPIO20_TXSCL - SER_GPIO19_RXSDA - fpga_pattern_pins levels to vil 0.2V vih vio-0.1v vol 400mV voh vio*0.8 iol 0uA ioh 0uA vref 0V
             set digital pin   SER_GPIO20_TXSCL + SER_GPIO19_RXSDA  levels to vil 0V vih vio vol 0.5*vio voh 0.5*vio iol 2mA ioh -2mA vref vio
	  end_if
       
       
    -- if voltage needs to be set lower
       else
          curr_v = vdd_global[1]     -- current IOVDD voltage
	  volt_70pct = curr_v*0.7    -- lowest voltage we can set /PWDN to before we risk voltage at /PWDN	       
	                             -- resetting the device
				     
          if vio >= volt_70pct then
	     set digital pin ALL_PATTERN_PINS  - SER_GPIO20_TXSCL - SER_GPIO19_RXSDA - fpga_pattern_pins levels to vil 0.2V vih vio vol vio*0.5 voh vio*0.5 iol 0uA ioh 0uA vref 0V
             set digital pin  SER_GPIO20_TXSCL + SER_GPIO19_RXSDA  levels to vil 0.2V vih vio  vol 400mV voh 0.8*vio iol 2mA ioh -2mA vref vio
	     set hcovi SER_VDDIO to fv vio vmax 4V clamp imax 600mA imin -600mA     
	  
	  else
	     set digital pin ALL_PATTERN_PINS  - SER_GPIO20_TXSCL - SER_GPIO19_RXSDA - fpga_pattern_pins levels to vil 0.2V vih volt_70pct vol 400mV voh volt_70pct*0.8 iol 0uA ioh 0uA vref 0V
             set digital pin  SER_GPIO20_TXSCL + SER_GPIO19_RXSDA  levels to  vil 0.2V vih volt_70pct vol 0.5*volt_70pct voh 0.5*volt_70pct iol 0.2mA ioh -0.2mA vref volt_70pct
	     set hcovi SER_VDDIO to fv volt_70pct   vmax 4V clamp imax 600mA imin -600mA
	     wait(400us)
	     
	     
	  -- After first setting to an intermediate voltage, it should now be ok to set to the final voltage
	     set digital pin ALL_PATTERN_PINS  - SER_GPIO20_TXSCL - SER_GPIO19_RXSDA - fpga_pattern_pins  levels to vil 0.2 vih vio vol 400mV voh vio*0.8 iol 0uA ioh 0uA vref 0V--- glitch
             set digital pin  SER_GPIO20_TXSCL + SER_GPIO19_RXSDA   levels to vil 0.0V vih vio-0.1  vol vio*0.5 voh 0.5*vio iol 2mA ioh -2mA vref vio 
	     set hcovi SER_VDDIO to fv vio   vmax 4V clamp imax 600mA imin -600mA	     
	  end_if
       end_if
              
       -- Supply for LT (might need to put LT in the loop above for LT protection when changing VDDIO)!!!
        set qfvi LT_SUPPLY irange to r500ma iclamps to imax 500mA imin -500mA
        set qfvi LT_SUPPLY to fv vio max 4V voltage supply mode                    
       vdd_global[1] = vio
       --zTTR wait(2ms)
       
    end_if    
	     
       set digital pin ALL_PATTERN_PINS  - SER_GPIO20_TXSCL - SER_GPIO19_RXSDA - fpga_pattern_pins  levels to vil 0.2 vih vio*0.9 vol 400mV voh vio*0.8 iol 0uA ioh 0uA vref 0V--- gli
       set digital pin  SER_GPIO20_TXSCL + SER_GPIO19_RXSDA   levels to vil 0.1V vih vio*0.9  vol vio*0.5 voh 0.5*vio iol 2mA ioh -2mA vref vio 
end_body


procedure RegRead(DevId, RegAddr, Bytes, UpperWord, LowerWord, PatternName)
--------------------------------------------------------------------------------
--  
in word                   : DevId, RegAddr, Bytes
out multisite lword       : UpperWord, LowerWord
in string[50]             : PatternName   -- pattern to run

local
   
   word list[MAX_SITES]   : active_sites_local
   word                   : siteidx, idx, sites_local, csite, reg_msb, reg_lsb, ByteOffset
   word                   : send_word[30]   -- change to lword for dsp_send
   multisite word         : cap_data[256]
   multisite word         : reg_read[22]
   multisite lword        : rread
   string[3]              : plab     -- pattern label
   string[30]             : cap_waveform    -- regsend capture waveform
   string[8]              : response
   string[1]              : WaveStr   
end_local

body

   active_sites_local = get_active_sites()
   sites_local = word(len(active_sites_local))
   UpperWord = 0
   LowerWord = 0
   plab = "S"+string(Bytes)

  if pos("UART", PatternName) > 1 then  
    send_word[1] = 2#101111001   --synch frame 0x79h
    send_word[2] = add_parity_bit(DevId+1)
     
    reg_msb = ((RegAddr & 16#FF00) >> 8)
    reg_lsb = (RegAddr & 16#FF)
    send_word[3] = add_parity_bit(reg_msb)
    send_word[4] = add_parity_bit(reg_lsb)
    send_word[5] = add_parity_bit(Bytes)

    if PatternName[1] = "S" or PatternName[1] == "s" then    
      cap_waveform = "SER_UART_READ_CAPTURE" + string((Bytes))    
      load     digital reg_send fx1 waveform "SER_UART_WRITE" with send_word
      enable   digital reg_send fx1 waveform "SER_UART_WRITE"
      enable   digital capture  fx1 waveform cap_waveform
    else
      cap_waveform = "DES_UART_READ_CAPTURE" + string(Bytes)
      load     digital reg_send fx1 waveform "DES_UART_WRITE" with send_word
      enable   digital reg_send fx1 waveform "DES_UART_WRITE"
      enable   digital capture  fx1 waveform cap_waveform
    end_if

    execute  digital pattern  PatternName at label plab run to end wait
    wait for digital capture  fx1 waveform cap_waveform
    read     digital capture  fx1 waveform cap_waveform into cap_data

    --- Process the data read back ------
    for siteidx=1 to sites_local do
      csite = active_sites_local[siteidx]
      reg_read[csite] = Analyze_Read_M(cap_data[csite], Bytes)
      for idx=0 to (Bytes-1) do
        if idx < 4 then
          LowerWord[csite] = (lword(reg_read[csite,idx+1]))<<lword(8*idx) + LowerWord[csite]
        else
          UpperWord[csite] = (lword(reg_read[csite,idx+1]))<<lword(8*(idx-4)) + UpperWord[csite]
        endif
      end_for
    end_for
  else     -- Access Type is I2C
    send_word[1] = DevId
    if pos("SER_I2C", PatternName) == 1 or pos("DES_I2C", PatternName) == 1 then  -- setup for 16 bit RegAddr address
      reg_msb = ((RegAddr & 16#FF00) >> 8)
      reg_lsb = (RegAddr & 16#FF)
      send_word[2] = reg_msb
      send_word[3] = reg_lsb
      send_word[4] = DevId + 1
    elseif pos("Aux_I2C_Read_Port", PatternName) == 1 then
      send_word[1] = DevId + 1
    else                                             -- setup for 8 bit RegAddr address
      send_word[2] = RegAddr
      send_word[3] = DevId + 1
    endif

    if pos("DES_", PatternName) == 1 then
      load   digital reg_send fx1 waveform "DES_I2C_WRITE" with send_word
      enable digital reg_send fx1 waveform "DES_I2C_WRITE"
      enable digital capture  fx1 waveform "DES_I2C_READ" + string(Bytes)
      execute  digital pattern  PatternName  at label plab run to end wait
      wait for digital capture  fx1 waveform "DES_I2C_READ" + string(Bytes)
      read  digital capture  fx1 waveform "DES_I2C_READ" + string(Bytes) into cap_data
    elseif pos("SER_", PatternName) == 1 then
      load   digital reg_send fx1 waveform "SER_I2C_WRITE" with send_word
      enable digital reg_send fx1 waveform "SER_I2C_WRITE"
      enable digital capture  fx1 waveform "SER_I2C_READ" + string(Bytes)
      execute  digital pattern  PatternName  at label plab run to end wait
      wait for digital capture  fx1 waveform "SER_I2C_READ" + string(Bytes)
      read  digital capture  fx1 waveform "SER_I2C_READ" + string(Bytes) into cap_data
    elseif pos("Aux_I2C_Read_Port", PatternName) == 1 then
      load   digital reg_send fx1 waveform "PORTEXP_I2C_WRITE" with send_word
      enable digital reg_send fx1 waveform "PORTEXP_I2C_WRITE"
      enable digital capture  fx1 waveform "PORTEXP_I2C_READ"
      execute  digital pattern  PatternName  at label plab run to end wait
      wait for digital capture  fx1 waveform "PORTEXP_I2C_READ"
      read  digital capture  fx1 waveform "PORTEXP_I2C_READ" into cap_data
    else
      load   digital reg_send fx1 waveform "OSC_I2C_WRITE" with send_word
      enable digital reg_send fx1 waveform "OSC_I2C_WRITE"
      enable digital capture  fx1 waveform "OSC_I2C_READ"
      execute  digital pattern  PatternName  at label plab run to end wait
      wait for digital capture  fx1 waveform "OSC_I2C_READ"
      read  digital capture  fx1 waveform "OSC_I2C_READ" into cap_data
   endif
    
    for siteidx=1 to sites_local do
      csite = active_sites_local[siteidx]
      for idx=0 to (Bytes-1) do
        if idx < 4 then
          LowerWord[csite] = (lword(cap_data[csite,idx+1]))<<lword(8*idx) + LowerWord[csite]
        else
          UpperWord[csite] = (lword(cap_data[csite,idx+1]))<<lword(8*(idx-4)) + UpperWord[csite]
        endif
      end_for
    end_for
  endif
end_body
function Analyze_Read_M(data_bytes, bytes) :   word[?]
--------------------------------------------------------------------------------
--  
in word       : data_bytes[?]
in word       : bytes

local

word          :   bit_position
word          :   data[22]
word          :   idx, idx2
word          :   kk[2], jj[2]
word          :   bit_weight

end_local

body

    data = 0    -- initialize data array to 0
    
    kk = FindStartBit(data_bytes,1,6) -- kk[1] is index with 1st start bit
    
    if kk[1] = 0 then  -- if no start bit found set data = -1
       data = -1
    else
       kk[1] = kk[1]+11   -- skip ack frame
       for idx =1 to bytes do
           jj = FindStartBit(data_bytes,kk[1],kk[1]+9)  -- changed to +9 from +6
           kk = jj  -- kk[1] keeps track of the index with start bit
           
           if kk[2] = 4 then
              bit_position = 2#1000
              kk[1] = kk[1]+1
           else
              bit_position = (2#1000)>>kk[2]
           end_if
     
         
           bit_weight = 0
           for idx2=kk[1]+1 to kk[1]+8 do
               if(data_bytes[idx2] & bit_position) <> 0 then
                  data[idx] = data[idx] + (1<<bit_weight)
               end_if
               bit_weight = bit_weight+1
           end_for
        
          if bit_position = 2#1000 then
             kk[1] = kk[1]+10
          else
             kk[1] = kk[1]+11   -- advance to next start bit for next loop iteration
          end_if
      
       end_for
    end_if       
            
    return(data)
    
end_body

function FindStartBit(data_bytes, st, sp): word[2]
--------------------------------------------------------------------------------
--  
in word         : data_bytes[?]
in word         : st    -- start index
in word         : sp    -- stop index

local

word    :   bit_position
word    :   aa, jj
boolean :   start_bit_found=false
word    :   idx_bloc[2]

end_local

body

   for jj=st to sp do
      bit_position = 2#1000
      for aa=1 to 4 do
        if(data_bytes[jj] & bit_position) = 0 then
           start_bit_found=true
	   break     -- exit loop when start bit is found
	end_if
	bit_position = bit_position >> 1
      end_for
      if start_bit_found then
         break
      end_if
    end_for
    
    idx_bloc[2] = aa
    
    if start_bit_found then
       idx_bloc[1] = jj
    else
       idx_bloc[1] = 0
    end_if
       
    return (idx_bloc)

end_body





















function RegWrite(DevId, RegAddr, ByteCnt, DataUpperWord, DataLowerWord, PatternName): multisite boolean
-----------------------------------------------------------------------------------------
-- Function allows writing up to 8 Bytes of data to any consecutive register space on the HS84, HS87 and oscillator dnuts

in word                    : DevId, RegAddr, ByteCnt
in lword                   : DataUpperWord, DataLowerWord
in string[50]              : PatternName     -- pattern to run

local
  word list[MAX_SITES]       : active_sites_local
  word                       : siteidx, idx, sites_local, csite, reg_msb, reg_lsb, ByteOffset, mdata
  word                       : send_word[30]  -- change to lword for dsp send
  multisite word             : ack[16]
  multisite boolean          : pass
  string[3]                  : plab     -- pattern label
  string[8]                  : response
end_local

body
  active_sites_local = get_active_sites()
  sites_local = word(len(active_sites_local))

  plab = "S"+string(ByteCnt)

  if DevId == SER_ID or DevId == DESA_ID or DevId == SER_DNUT_ID then
    reg_msb = ((RegAddr & 16#FF00) >> 8)
    reg_lsb = (RegAddr & 16#FF)
  endif
  
  if PatternName[5] = "U" OR PatternName[6] = "U" then                -- UART Mode ( dut_uart_write, dut_uart_read, dnut_uart_write, dnut_uart_read )
    
    send_word[1] = 2#101111001   --synch frame 0x79h
    send_word[2] = add_parity_bit(DevId)
    if DevId == 16#80 OR DevId == 16#90 then
      send_word[3] = add_parity_bit(reg_msb)
      send_word[4] = add_parity_bit(reg_lsb)
      send_word[5] = add_parity_bit(ByteCnt)
      ByteOffset = 5
    else 
      send_word[3] = add_parity_bit(RegAddr)
      send_word[4] = add_parity_bit(ByteCnt)
      ByteOffset = 4
    endif
    
    
    for idx=1 to ByteCnt do
      if idx < 5 then
       mdata = word( (DataLowerWord>>(8*lword(idx-1))) & 16#FF)
      else
        mdata = word( (DataUpperWord>>(8*lword(idx-5))) & 16#FF)
      endif  
       send_word[idx+ByteOffset] = add_parity_bit(mdata)
    end_for
      
      
    if DevId == DESA_ID OR DevId == SER_DNUT_ID then --Write to DNUT's (deserializer)
      load     digital reg_send fx1 waveform "DES_UART_WRITE" with send_word
      enable   digital capture  fx1 waveform "DES_UART_WRITE_CAPTURE"
      enable   digital reg_send fx1 waveform "DES_UART_WRITE"
	    
      execute  digital pattern PatternName at label  plab run to end wait
      wait for digital capture  fx1 waveform "DES_UART_WRITE_CAPTURE"
      read     digital capture  fx1 waveform "DES_UART_WRITE_CAPTURE" into ack
	 
    else    -- Write to DUT (serializer)   --WH:FOLLOWUP need a case where DevId != DUT or DNUT1 or DNUT2
      load     digital reg_send fx1 waveform "SER_UART_WRITE" with send_word
      enable   digital capture  fx1 waveform "SER_UART_WRITE_CAPTURE"
      enable   digital reg_send fx1 waveform "SER_UART_WRITE"
	    
      execute  digital pattern PatternName at label  plab run to end wait
     wait for digital capture  fx1 waveform "SER_UART_WRITE_CAPTURE"
     read     digital capture  fx1 waveform "SER_UART_WRITE_CAPTURE" into ack
    end_if


    for siteidx=1 to sites_local do
      csite = active_sites_local[siteidx]
      pass[csite] = Check_for_ack_frame(ack[csite])
    end_for

  else    -- I2C mode
    send_word[1] = DevId
    if DevId == SER_ID or DevId == DESA_ID or DevId == SER_DNUT_ID then
      send_word[2] = reg_msb
      send_word[3] = reg_lsb
      ByteOffset = 3
      elseif DevId == PORT_EXP then
       send_word[1] = DevId
       ByteOffset = 1
    else  -- dnut device other than the 8bit io extender.=
      send_word[2] = RegAddr
      ByteOffset = 2
    endif 
    for idx = 1 to ByteCnt do
      if idx < 5 then
        mdata = word( (DataLowerWord>>(8*lword(idx-1))) & 16#FF)
      else
        mdata = word( (DataUpperWord>>(8*lword(idx-5))) & 16#FF)
      endif  
      send_word[idx+ByteOffset] = mdata
    end_for

     if DevId == DESA_ID or DevId == SER_DNUT_ID then                                                  -- Write to DNUT (Comment was: Write to Serializer)
      load    digital reg_send fx1 waveform "DES_I2C_WRITE" with send_word
      enable  digital reg_send fx1 waveform "DES_I2C_WRITE"
    else_if DevId == SER_ID then                                            						-- Write to DUT  (Comment was: Write to Deserializer )
      load    digital reg_send fx1 waveform "SER_I2C_WRITE" with send_word
      enable  digital reg_send fx1 waveform "SER_I2C_WRITE"
    else_if DevId == PORT_EXP then
      load    digital reg_send fx1 waveform "PORTEXP_I2C_WRITE" with send_word
      enable  digital reg_send fx1 waveform "PORTEXP_I2C_WRITE"
    else_if DevId == PROG_OSC then                                                                    						-- Write to one of the utility DNUT's (non HS84/HS87.)
      load    digital reg_send fx1 waveform "OSC_I2C_WRITE" with send_word
      enable  digital reg_send fx1 waveform "OSC_I2C_WRITE"
    end_if
    execute digital pattern  PatternName at label plab run to end wait

     
    --Need to check pattern pass / fail state and populate the pass return variable
  end_if
--WH:FOLLOWUP. WORK ON LOGIC. This was the original first 6 lines of the above IF statement:
--    if DevId == SER_ID then                                                  -- Write to Serializer
--      load    digital reg_send fx1 waveform "SER_I2C_WRITE" with send_word
--      enable  digital reg_send fx1 waveform "SER_I2C_WRITE"
--    else_if DevId == DESA_ID then                                            -- Write to Deserializer
--      load    digital reg_send fx1 waveform "DES_I2C_WRITE" with send_word
--      enable  digital reg_send fx1 waveform "DES_I2C_WRITE"
           
  return (pass)

end_body

procedure SetTestMode (UsrMode, ResetMode, UsrPat)
in word : UsrMode
in boolean :  ResetMode
in string[32] : UsrPat

local
  lword : Tmv
  multisite lword       : LowerRdWord, UpperRdWord
end_local

body

  Tmv = 16#A0 | lword(UsrMode)

  if Not ResetMode then
    RegWrite(SER_ID, SR_TEST1, 1, 0, 16#A0, UsrPat) --DR-ID = 0x3F
    RegWrite(SER_ID, SR_TEST1, 1, 0, 16#C0, UsrPat)
    RegWrite(SER_ID, SR_TEST1, 1, 0, 16#CF, UsrPat)
    RegWrite(SER_ID, SR_TEST1, 1, 0, Tmv,   UsrPat)
  endif

  RegWrite(SER_ID, SR_TEST1, 1, 0, lword(UsrMode), UsrPat)
  RegRead(SER_ID, SR_TEST1 , 1, UpperRdWord, LowerRdWord, "SER_UART_Read")     

end_body

procedure force_instr(fi_pinlist, fi_pintype, fi_v_or_i, fi_set_vi, fi_range, fi_cmin, fi_cmax)
--------------------------------------------------------------------------------
--  

in PIN LIST[255]: fi_pinlist
in string[30]:    fi_pintype, fi_v_or_i
in float:         fi_set_vi, fi_range, fi_cmin, fi_cmax

local

end_local

body

	if fi_pintype = "PPMU" then
	
	   if fi_v_or_i = "VOLTAGE" then
	       set ppmu fi_pinlist to fv fi_set_vi measure i max fi_cmax  clamps to imin fi_cmin imax fi_cmax
	   else_if fi_v_or_i = "CURRENT" then
	       set ppmu fi_pinlist to fi fi_set_vi measure v max fi_cmax clamps to vmin fi_cmin vmax fi_cmax	   
	   end_if
	   
	else_if fi_pintype = "HCOVI" then
	
	   if fi_v_or_i = "VOLTAGE" then
               set hcovi fi_pinlist to fv fi_set_vi vmax fi_range measure i max fi_cmax clamp imax fi_cmax imin fi_cmin
	   else_if fi_v_or_i = "CURRENT" then
               set hcovi fi_pinlist to fi fi_set_vi imax fi_range measure v max fi_cmax clamp vmax fi_cmax vmin fi_cmin
	   end_if
	   
	else_if fi_pintype = "OVI" then
	
	   if fi_v_or_i = "VOLTAGE" then
               set ovi chan fi_pinlist to fv fi_set_vi measure i max fi_range clamp imax fi_cmax imin fi_cmin
	   else_if fi_v_or_i = "CURRENT" then
               set ovi chan fi_pinlist to fi fi_set_vi  clamp vmax fi_cmax vmin fi_cmin

	   end_if
	else_if fi_pintype = "QFVI" then
	
	   if fi_v_or_i = "VOLTAGE" then
	       --set qfvi SER_VDDD to fv 0V max r2p5v voltage supply mode	        
               --set qfvi chan fi_pinlist to fv fi_set_vi --measure i max fi_range clamp imax fi_cmax imin fi_cmin
	   else_if fi_v_or_i = "CURRENT" then
               --set qfvi chan fi_pinlist to fi fi_set_vi --clamp vmax fi_cmax vmin fi_cmin

	   end_if
	else_if fi_pintype = "VI16" then
	
	   if fi_v_or_i = "VOLTAGE" then
               set vi16 chan fi_pinlist to fv fi_set_vi measure i max fi_range clamp imax fi_cmax imin fi_cmin
	   else_if fi_v_or_i = "CURRENT" then
               set vi16 chan fi_pinlist to fi fi_set_vi measure v max fi_cmax clamp vmax fi_cmax vmin fi_cmin

	   end_if
	   
	end_if
  

end_body


procedure meas_instr(out_measurement, mi_pinlist, mi_pintype, mi_v_or_i,  mi_range, mi_sample, mi_period)
--------------------------------------------------------------------------------
--  

in PIN LIST[255]: mi_pinlist
in string[30]   : mi_pintype, mi_v_or_i
in float        : mi_range,  mi_period
in word         : mi_sample
out multisite float       : out_measurement[?]

local

double       : mi_period_hvvi
multisite float: mi_measurement[40]

end_local

body
        
    --mi_period_hvvi = double(mi_period)
    
	if mi_pintype = "PPMU" then
	   if mi_v_or_i = "VOLTAGE" then
	       measure ppmu mi_pinlist voltage vmax mi_range average mi_sample delay mi_period into out_measurement
	   else_if mi_v_or_i = "CURRENT" then
	       measure ppmu mi_pinlist current imax mi_range average mi_sample delay mi_period into out_measurement
	   end_if
	else_if mi_pintype = "HCOVI" then
	   if mi_v_or_i = "VOLTAGE" then
	       measure hcovi v on mi_pinlist for mi_sample samples every mi_period averaged into out_measurement
	   else_if mi_v_or_i = "CURRENT" then
	       measure hcovi i on mi_pinlist for mi_sample samples every mi_period averaged into out_measurement
	   end_if
	end_if
	
-- 	return(mi_measurement)
--      out_measurement = mi_measurement
--      mi_measurement
end_body




function Check_for_ack_frame(data) :   boolean
--------------------------------------------------------------------------------
--  
in word : data[16]


local

integer   : jj, aa
word      : bit_position
boolean   : start_bit_found
word      : bit_weight
word      : val
boolean   : ack_found = false

end_local

body

    for jj=1 to 5 do
      bit_position = 2#1000
      for aa=1 to 4 do
        if(data[jj] & bit_position) = 0 then
           start_bit_found=true
	   break     -- exit loop when start bit is found
	end_if
	bit_position = bit_position >> 1
      end_for
      if start_bit_found then
         break
      end_if
    end_for
    
    if aa==4 then
       bit_position = 2#1000
       jj= jj+1
    else
       bit_position = bit_position >>1      
    end_if
  
    
    bit_weight = 0
    for aa=jj+1 to jj+9 do
       if(data[aa] & bit_position) <>0 then
          val = val + (1<<bit_weight)
       end_if
       bit_weight = bit_weight+1
    end_for

  
  if ( val = 16#c3 ) then
     ack_found = true
  end_if
  
  
  return (ack_found)
  

end_body

function PorSearchHcovi(TestPins, Startv, Stopv, Ilimit, Resolution, Dir,vio): multisite float
--------------------------------------------------------------------------------
--  
in pin list[5]        : TestPins
in float              : Startv, Stopv, Ilimit, Resolution,vio
in string[5]          : Dir    -- "UP" or "DOWN"

local
  float           : Vramp
  multisite float : POR
  multisite float : Icc[1]
  word            : CurSite
  PIN LIST[1]     : MeasPin, Pintest
endlocal

body
  active_sites = get_active_sites()
  sites = word(len(active_sites))
  POR = -999V

    Pintest[1]= TestPins[1]
    MeasPin[1] = Pintest[1]---SER_VDD[1]----need check this
  current_active_sites = get_active_sites
  sites = word(len(current_active_sites))
  if Dir == "UP" then          -- POR turn on threshold search, if readable or current on ~60mA!
    for Vramp= Startv to Stopv by Resolution do
------ force_instr(fi_pinlist, fi_pintype, fi_v_or_i, fi_set_vi, fi_range, fi_cmin, fi_cmax)

      set hcovi Pintest to fv Vramp vmax 4V
---Rampup other pin too
      if Pintest == SER_VDDIO and (Ilimit < 100uA )then
            set digital pin  SER_GPIO20_TXSCL + SER_GPIO19_RXSDA levels to vil 0V vih Vramp  vol Vramp*0.5 voh 0.5*Vramp iol 2mA ioh -2mA vref Vramp
            set digital pin  SER_PWDNB levels to vil 0V vih 200mV  ---Cyle power down pin to reset part
 ----This is for MPW3
 --            set digital pin SER_GPO4_CFG0  + SER_GPO6_CFG2 levels to vil Vramp* 0.11 vih Vramp   -- TP/UART mode with DEV_ID = 0x80
--             set digital pin  SER_GPO5_CFG1 levels to vil Vramp*0.16 vih Vramp      
------- This is for MPW5
            set digital pin  SER_GPO5_CFG1 levels to vil Vramp*0.44 vih Vramp                   -----GMSL2
            set digital pin SER_GPO4_CFG0  levels to vil Vramp* 0.93 vih Vramp +200mV  -- TP/UART mode with DEV_ID = 0x80
            set digital pin SER_GPO6_CFG2 levels to vil Vramp*0.05 vih Vramp  -- TP/UART mode with DEV_ID = 0x80
            set digital pin  SER_PWDNB levels to vil 0V vih Vramp ---Bring powerdown pin up
            execute digital pattern "PowerUp" at label "TP" run to end wait
            wait (3ms)--- for handshake

      else
           ---------MPW5
             set digital pin  SER_GPO5_CFG1 levels to vil vio*0.44 vih   vio                -----GMSL2
            set digital pin SER_GPO4_CFG0  levels to vil vio* 0.93 vih vio -- TP/UART mode with DEV_ID = 0x80
            set digital pin SER_GPO6_CFG2 levels to vil vio*0.05 vih vio  -- TP/UART mode with DEV_ID = 0x80
            set digital pin  SER_PWDNB levels to vil 0V vih vio ---Bring powerdown pin up
            execute digital pattern "PowerUp" at label "TP" run to end wait
            wait(3ms)   --6   
        
      end_if 
      if Ilimit < 100uA then
        RegRead(SER_ID, 16#00, 1, RdWordUpper, RdWordLower, "SER_UART_Read")
         measure hcovi i on MeasPin for 25 samples every 20us averaged into Icc ---- we might need to meas on VDD18 only
        for idx = 1 to sites do
          CurSite = current_active_sites[idx]
          if  RdWordLower[CurSite] == 16#80  then
            POR[CurSite] = Vramp
            deactivate site CurSite
          end_if
        end_for
      else
--        measure hcovi i on MeasPin for 25 samples every 20us averaged into Icc ---- we might need to meas on VDD18 only
        measure hcovi i on MeasPin for 25 samples every 20us averaged into Icc ---- we might need to meas on VDD18 only
        for idx = 1 to sites do
          CurSite = current_active_sites[idx]
          if  Icc[CurSite, 1] > Ilimit then
            POR[CurSite] = Vramp
            deactivate site CurSite
          end_if
        end_for
      endif
      current_active_sites = get_active_sites
      sites = word(len(current_active_sites))
      if sites == 0 then 
        break
      endif 
    end_for
  elseif Dir == "DOWN" then     --- POR turn off threshold search; not able to read or current off ~15mA!  
    for Vramp= Startv downto Stopv by Resolution do
      set hcovi Pintest to fv Vramp vmax 4V
      if Pintest == SER_VDDIO and (Ilimit < 100uA )then
            set digital pin  SER_GPIO20_TXSCL + SER_GPIO19_RXSDA levels to vil 0V vih Vramp  vol Vramp*0.5 voh 0.5*Vramp iol 2mA ioh -2mA vref Vramp
            set digital pin  SER_PWDNB levels to vil 0V vih Vramp ---Bring powerdown pin up
            wait (6ms)--- for handshake
       end_if     
      if Ilimit < 100uA then
        RegRead(SER_ID, 16#00, 1, RdWordUpper, RdWordLower, "SER_UART_Read")
        measure hcovi i on MeasPin for 25 samples every 20us averaged into Icc
        for idx = 1 to sites do
          CurSite = current_active_sites[idx]
         if  RdWordLower[CurSite] <> 16#80 then
            POR[CurSite] = Vramp
            deactivate site CurSite
          end_if
        end_for
      else
        measure hcovi i on MeasPin for 25 samples every 20us averaged into Icc
        for idx = 1 to sites do
          CurSite = current_active_sites[idx]
          if  Icc[CurSite, 1] < Ilimit then
            POR[CurSite] = Vramp
            deactivate site CurSite
          end_if
        end_for
      endif
      current_active_sites = get_active_sites
      sites = word(len(current_active_sites))
      if sites < 1 then 
        break
      endif 
       
    end_for
  endif

  activate site active_sites
  return(POR)
end_body

function Cfg1Search(TestPins, Startv, Stopv, Resolution, CFGRegId,code_num , Dir): multisite float
--------------------------------------------------------------------------------
--  
in pin list[5]        : TestPins
in float              : Startv, Stopv, Resolution
in string[5]          : Dir    -- "UP" or "DOWN"
-- in string[25]         : Pat 
--in word               : DevId
in lword              : code_num 
in word               : CFGRegId

local
  float           : Vramp
  multisite float : Vcfg
  word            : CurSite
  PIN LIST[1]     : MeasPin
endlocal

body
  active_sites = get_active_sites()
  sites = word(len(active_sites))
  Vcfg = -999V
  RdWordLower =255
  
  current_active_sites = get_active_sites
  sites = word(len(current_active_sites))
 --    Turn to INTR0 register to turn on  FW_OSC_PU  bit per DE. This bit will turn on CFG pin osc otherwise it will not update conf register. This is only applied to hs89/78 MPW3 and later. 
   RegWrite(SER_ID,SR_INTR0, 1, 0, 16#E0, "SER_UART_Write")
  if Dir == "UP" then          -- Able to read turn on threshold search, if readable
    for Vramp= Startv to Stopv by Resolution do

      RegWrite(SER_ID,SR_CFG_3, 1, 0, 16#00, "SER_UART_Write") 
      set digital ppmu TestPins to fv Vramp vmax 5V measure i max 2mA
      wait(1ms)
      -- CFG_3: FORCE CFG PU  =1 to update CFG value
      RegWrite(SER_ID, SR_CFG_3, 1, 0, 16#02, "SER_UART_Write") 
      wait(1ms) 

--     execute digital pattern "PowerUp" at label "TP" run to end wait
      --read CFG reg
      --RegRead(DES_ID, 16#03F9, 1, RdWordUpper, RdWordLower, "des_i2c_read")
      RegRead(SER_ID, CFGRegId, 1, RdWordUpper, RdWordLower, "SER_UART_Read")
      for idx = 1 to sites do
         CurSite = current_active_sites[idx]
         if  RdWordLower[CurSite] <> code_num   then
            Vcfg[CurSite] = Vramp
            deactivate site CurSite
         end_if
       end_for
      current_active_sites = get_active_sites
      sites = word(len(current_active_sites))
      if sites == 0 then 
        break
      endif 
    end_for
  elseif Dir == "DOWN" then     --- POR turn off threshold search; not able to read or current off ~15mA!  
    for Vramp= Startv downto Stopv by Resolution do
      RegWrite(SER_ID,SR_CFG_3, 1, 0, 16#00, "SER_UART_Write") ---For hs89 SR_CFG_3 = 0x0543
      set digital ppmu TestPins to fv Vramp vmax 5V measure i max 2mA
      wait(1ms)
      -- CFG_3: FORCE CFG PU  =1 to update CFG value
      RegWrite(SER_ID,SR_CFG_3, 1, 0, 16#02, "SER_UART_Write") 
      wait(1ms) 
      --read CFG reg
      RegRead(SER_ID, CFGRegId, 1, RdWordUpper, RdWordLower, "SER_UART_Read")
      for idx = 1 to sites do
         CurSite = current_active_sites[idx]
         if  RdWordLower[CurSite] <> code_num then
            Vcfg[CurSite] = Vramp
            deactivate site CurSite
         end_if
       end_for
      current_active_sites = get_active_sites
      sites = word(len(current_active_sites))
      if sites == 0 then 
          break
      endif 
     end_for
  endif

  activate site active_sites
  return(Vcfg)
end_body


function CfgGoNoGo(TestPins, CFGRegId,TestVltg, code_num): multisite float
--------------------------------------------------------------------------------
--  
in pin list[5]        : TestPins
in float              : TestVltg
in lword              : code_num 
in word               : CFGRegId

local
  multisite float : Vcfg
  word            : CurSite
  PIN LIST[1]     : MeasPin
endlocal

body
  active_sites = get_active_sites()
  sites = word(len(active_sites))
  Vcfg = -999V
  RdWordLower =255
  
  current_active_sites = get_active_sites
  sites = word(len(current_active_sites))
 
 
 --    Turn to INTR0 register to turn on  FW_OSC_PU  bit per DE. This bit will turn on CFG pin osc otherwise it will not update conf register. This is only applied to hs89/78 MPW3 and later. 
      RegWrite(SER_ID,SR_INTR0, 1, 0, 16#E0, "SER_UART_Write")
 
      RegWrite(SER_ID,SR_CFG_3, 1, 0, 16#00, "SER_UART_Write") -----NOTE FOR HS89 SR_CFG_3 = 0X0543
      set digital ppmu TestPins to fv TestVltg vmax 2V measure i max 20mA
      wait(10us)
      -- CFG_3: FORCE CFG PU  =1 to update CFG value
      RegWrite(SER_ID,SR_CFG_3, 1, 0, 16#02, "SER_UART_Write") 
      wait(100us) --500us
      --read CFG reg
      RegRead(SER_ID, CFGRegId, 1, RdWordUpper, RdWordLower, "SER_UART_Read")

      for idx = 1 to sites do
          CurSite =  current_active_sites[idx]
          if  RdWordLower[CurSite] == code_num   then
             Vcfg[CurSite] = TestVltg
          else 
             Vcfg[CurSite] = 0mV
          endif
       end_for

     return(Vcfg)  
      
endbody      
function VilVihSearch(TestPins, PassVltg, FailVltg, VilVih, PatternName, StartLabel) : multisite float[50]
--------------------------------------------------------------------------------
-- HS84 device currently only has OR gate logic for vil/vih test modes.  All input pin states are output on the LOCK signal.
-- Due to only having OR gate login the VIH->VIL search uses the digital pins Vil parameter set to a passing High level then lowered during the seep to test the threshold value during the search.
-- VIL search value is obtained by sweeping the input voltage from Max->Min and the Vih search value is obtained by sweeping the input voltage from Min-Max voltage.

in PIN LIST[50]  : TestPins
in float         : FailVltg, PassVltg
in string[32]    : VilVih                   -- Test Type:  "VIL" or "VIH" 
in string[32]    : PatternName, StartLabel  

local
  multisite float   : SearchVal[50]
  multisite boolean : PatRes
  float             : CurVltg, StartVltg, StopVltg, CurStepVltg
  integer           : PinIdx, ResIdx
  word              : CurSite
  float             : StepVltg[3]
  PIN               : CurTestPin
end_local

body

start_timer()
  active_sites = get_active_sites
  sites = word(len(active_sites))
  SearchVal = 999V
  
  if PassVltg < FailVltg then
    StepVltg[1] = 100mV
    StepVltg[2] = 25mV
    StepVltg[3] = 2mV
  else
    StepVltg[1] = -100mV
    StepVltg[2] = -25mV
    StepVltg[3] = -2mV
  endif

  SearchVal = -999.0  -- Initialize all test pin search values to something that will never pass if the pin is not tested

  for PinIdx = 1 to len(TestPins) do
    CurTestPin = TestPins[PinIdx]
    
    for idx = 1 to sites do
      SearchVal[active_sites[idx], PinIdx] = PassVltg
    endfor  
    
    for ResIdx = 1 to 3 do
      CurStepVltg = StepVltg[ResIdx]

      current_active_sites = get_active_sites() 
      sites = word(len(current_active_sites))
      while sites > 0 do  
        for idx = 1 to sites do
          CurSite = current_active_sites[idx]
            set digital pin CurTestPin on site CurSite levels to vil PassVltg    -------reset hysterises mt otherwise it will have 0 standard deviation MT 3/2018
            wait(100us)
            set digital pin CurTestPin on site CurSite levels to vil SearchVal[CurSite, PinIdx]

        end_for     
--        set digital pin SER_GPIO_PWDNB  on site CurSite levels to vil 0
        execute digital pattern PatternName at label StartLabel into PatRes

        for idx = 1 to sites do
          if not PatRes[current_active_sites[idx]] then
            deactivate site current_active_sites[idx]
            SearchVal[CurSite, PinIdx] = SearchVal[CurSite, PinIdx] - CurStepVltg  -- Reset force voltage back to passing range

          else
            SearchVal[CurSite, PinIdx] = SearchVal[CurSite, PinIdx] + CurStepVltg
            if SearchVal[CurSite, PinIdx] > 4.0V or SearchVal[CurSite, PinIdx] < 0.0V then
              deactivate site CurSite
            endif
          endif
        endfor
        current_active_sites = get_active_sites() 
        sites = word(len(current_active_sites))
      end_while
  
      activate site active_sites
      sites = word(len(active_sites))

     set digital pin CurTestPin vil 0V
    end_for
--    set digital pin TestPins modes to comparator enable all fails

  endfor

  activate site active_sites

  return(SearchVal)

end_body

function msi(data) : multisite integer
--------------------------------------------------------------------------------
-- This function converts a multisite word to a multisite integer
in multisite lword      : data


local

word list[MAX_SITES]   : active_sites_local
word                   : sites_local
word                   : siteidx
word                   : csite
multisite integer      : msint

end_local


body


    active_sites_local = get_active_sites()
    sites_local = word(len(active_sites_local))


    for siteidx =1 to sites_local do
        csite = active_sites_local[siteidx]
	msint[csite] = integer(data[csite])
    end_for
    
    
    return (msint)


end_body
function Lmn_Search(TestPins, Startv, Stopv, Resolution, Reg_Read,Cmp_val, Dir): multisite float
--------------------------------------------------------------------------------
--  
in pin list[5]        : TestPins
in float              : Startv, Stopv, Resolution
in string[5]          : Dir    -- "UP" or "DOWN"
in word               : Reg_Read
in lword              : Cmp_val 
local
  float           : Iramp
  multisite float : Isrch
  word            : CurSite
  PIN LIST[1]     : MeasPin
endlocal

body
  active_sites = get_active_sites()
  sites = word(len(active_sites))
  Isrch = -999uA
  RdWordLower =255
  MeasPin[1] = TestPins[1]
  
  current_active_sites = get_active_sites
  sites = word(len(current_active_sites))
  
  if Dir == "UP" then          
    for Iramp= Startv to Stopv by Resolution do
      connect digital ppmu TestPins to fi Iramp imax 500uA measure v max 2V
      RegRead(SER_ID, Reg_Read, 1, RdWordUpper,RdWordLower, "SER_UART_Read")
      for idx = 1 to sites do
         CurSite = current_active_sites[idx]
         if  RdWordLower[CurSite] <> Cmp_val  then
            Isrch[CurSite] = Iramp
            deactivate site CurSite
         end_if
       end_for
      current_active_sites = get_active_sites
      sites = word(len(current_active_sites))
      if sites == 0 then 
        break
      endif 
    end_for
  elseif Dir == "DOWN" then   
    for Iramp= Startv downto Stopv by Resolution do
      set digital ppmu TestPins to fi Iramp imax 200uA measure v max 2V
      RegRead(SER_ID, Reg_Read, 1, RdWordUpper,RdWordLower, "SER_UART_Read")
       for idx = 1 to sites do
         CurSite = current_active_sites[idx]
         if  RdWordLower[CurSite] <> Cmp_val then
            Isrch[CurSite] = Iramp
            deactivate site CurSite
         end_if
       end_for
      current_active_sites = get_active_sites
      sites = word(len(current_active_sites))
      if sites == 0 then 
          break
      endif 
     end_for
  endif

  activate site active_sites
  set digital ppmu TestPins to fi 0uA imax 500uA measure v max 2V

  return(Isrch)
end_body

function Lmn_Search_mod(TestPins, Startv, Stopv, Resolution, Reg_Read,Cmp_val, Dir,LMN): multisite float
--------------------------------------------------------------------------------
--  
in pin list[5]        : TestPins
in float              : Startv, Stopv, Resolution
in string[5]          : Dir    -- "UP" or "DOWN"
in word               : Reg_Read
in lword              : Cmp_val 
in word               : LMN --- which lmn is testing 
local
  float           : Iramp
  multisite float : Isrch
  word            : CurSite
  PIN LIST[1]     : MeasPin
  multisite lword : read_bit_cmp  

endlocal

body
  active_sites = get_active_sites()
  sites = word(len(active_sites))
  Isrch = -999uA
  RdWordLower =255
  MeasPin[1] = TestPins[1]
  
  current_active_sites = get_active_sites
  sites = word(len(current_active_sites))
  
  if Dir == "UP" then          
    for Iramp= Startv to Stopv by Resolution do
      connect digital ppmu TestPins to fi Iramp imax 200uA measure v max 2V  -----500ua
      wait(200uS)
      RegRead(SER_ID, Reg_Read, 1, RdWordUpper,RdWordLower, "SER_UART_Read")
      if LMN = 0 or LMN = 2 then --- take  LSB bit to compare
            read_bit_cmp = RdWordLower & 0xF
      else --- lmn1 and lmn3 take 4 msb
            read_bit_cmp = ((RdWordLower & 0xF0) >> 4)
      end_if 
      for idx = 1 to sites do
         CurSite = current_active_sites[idx]
         if read_bit_cmp [CurSite] = Cmp_val  then
            Isrch[CurSite] = Iramp
            deactivate site CurSite
         end_if
       end_for
      current_active_sites = get_active_sites
      sites = word(len(current_active_sites))
      if sites == 0 then 
        break
      endif 
    end_for
  elseif Dir == "DOWN" then   
    for Iramp= Startv downto Stopv by Resolution do
      set digital ppmu TestPins to fi Iramp imax Iramp + 0.5uA measure v max 2V
      RegRead(SER_ID, Reg_Read, 1, RdWordUpper,RdWordLower, "SER_UART_Read")
      wait(200uS)
      if LMN = 0 or LMN = 2 then --- take  LSB bit to compare
            read_bit_cmp = RdWordLower & 0xF
      else --- lmn1 and lmn3 take 4 msb
            read_bit_cmp = ((RdWordLower & 0xF0) >> 4)
      end_if       
       for idx = 1 to sites do
         CurSite = current_active_sites[idx]
         if  read_bit_cmp[CurSite] = Cmp_val then
            Isrch[CurSite] = Iramp
            deactivate site CurSite
         end_if
       end_for
      current_active_sites = get_active_sites
      sites = word(len(current_active_sites))
      if sites == 0 then 
          break
      endif 
     end_for
  endif

  activate site active_sites
  set digital ppmu TestPins to fi 0uA imax 500uA measure v max 2V

  return(Isrch)
end_body

function MeasureXresVoltage :   multisite float
--------------------------------------------------------------------------------
--  

local
  multisite float   : MeasVal[1], RetVal
  word: CurSite  
end_local

body
  disconnect digital pin DUT_XRES from dcl
  enable digital ppmu DUT_XRES fi 0A imax 20uA measure v max 2V clamps to vmin -1V vmax 2V  
  connect digital ppmu DUT_XRES to fi 0mA imax 20uA measure v max 2V                          -- connect in HIZ mode
  wait(10ms)
  measure digital ppmu DUT_XRES voltage average 5 delay 10us into MeasVal
  disconnect digital ppmu DUT_XRES from fi
  set digital ppmu DUT_XRES to fv 0V vmax 2V measure i max 20mA clamps to imin 10mA imax 10mA
--WH:FOLLOWUP need to do anything else w. DCL or PPMU here?
  for idx=1 to sites do
    CurSite = active_sites[idx]
    RetVal[CurSite] = MeasVal[CurSite, 1]
  endfor
  return(RetVal)
end_body


procedure DevRegConfig (RegConfigStr)
in string[32] : RegConfigStr

local
  integer: i
  multisite lword:  l1, l2, u1, u2
end_local

body
--WH:FOLLOWUP ADD register writes to disable GPIO's through #19. Also revist GPIO0 and register mapping in general -- GPIO0 is not bonded out on the HS84 tQFN, is it being written to tristate anyway? (good for aQFN version.)

  if RegConfigStr == "LkgAllPins" then
----Mt not debug this section yet
--     RegWrite(SER_ID, SR_AUDIO_RX1, 1,  0, 16#00, "SER_UART_Write")    -- Disable the audio receiver
--     RegWrite(SER_ID, SR_REG2, 1, 0, 16#00, "SER_UART_Write")          -- Disable the audio transmitter but leave the uart DIS_LOCAL_CC enabled until all registers have been written
--     RegWrite(SER_ID, SR_TERM_CTL_REG, 1,  0, 16#C7, "SER_UART_Write") -- Disable the HDMI pullups
--     for i = 0 to 19 do
--       RegWrite(SER_ID, (SR_GPIO_A_0+(word(i)*3)), 2, 0, 16#0001, "SER_UART_Write")
--     endfor
-- 
--     RegWrite(SER_ID, SR_AUDIO_TX0_0, 1, 0, 16#80, "SER_UART_Write")
--     RegWrite(SER_ID, SR_AUDIO_TX0_1, 1, 0, 16#80, "SER_UART_Write")
--     RegWrite(SER_ID, SR_AUDIO_RX1, 1, 0, 16#20, "SER_UART_Write")
-- 
--     RegWrite(SER_ID, SR_IO_CHK2, 1, 0, 16#00, "SER_UART_Write")
-- --    RegWrite(SER_ID, SR_OLDI2, 1, 0, 16#C8, "SER_UART_Write")          -- Disable all output drivers on LVDS pins
--     RegWrite(SER_ID, SR_CTRL0, 1, 0, 16#40, "SER_UART_Write")          -- Hold link in reset mode
-- 
-- --  This register write must be the last one performed - else part loses communication (this appears to shut down local UART control too.)
--     RegWrite(SER_ID, SR_REG1, 1, 0, 16#20, "SER_UART_Write")          -- Disable the RX/SDA control channel for hs89 it is REG1 ont REG2
-------------------------------------------------------------######################

  elseif RegConfigStr == "PullupGpio40k" then
-------may not needed for HS89 becasue HS89 MFPs are  gpio and audio pins  MT 6/2017
--     RegWrite(SER_ID, SR_AUDIO_TX0_0, 1, 0, 16#80, "SER_UART_Write")
--     RegWrite(SER_ID, SR_AUDIO_TX0_1, 1, 0, 16#80, "SER_UART_Write")
--     RegWrite(SER_ID, SR_AUDIO_RX1, 1,  0, 16#00, "SER_UART_Write")    -- Disable the audio receiver
--     RegWrite(SER_ID, SR_REG2, 1, 0, 16#00, "SER_UART_Write")          -- Disable the audio transmitter but leave the uart DIS_LOCAL_CC enabled until all registers have been written

----  Move this write to the LOCK/ERRB portion  RegWrite(SER_ID, SR_IO_CHK2, 1, 0, 16#84, "SER_UART_Write")       -- Force ERRB to high state (PU only since it's open drain.)
---------------------------------------------------------------
    -- GpioA = 16#01,  GPIO_B = 16#60, GPIO_C = 16#C3)
    for i = 0 to 20 do                                                      ----for HS89 8x8 56 pins package has only 21 MFP
      RegWrite(SER_ID, (SR_GPIO_A_0+(word(i)*3)), 2,0 , 16#6001, "SER_UART_Write")  -- GPIO_B -- need 0x60 or would 0x40 also work OK?
    endfor
   
  elseif RegConfigStr == "PullupGpio1M" then
-------may not needed for HS89 MT becasue HS89 MFPs are  gpio and audio pins  MT 6/2017
--    RegWrite(SER_ID, SR_AUDIO_TX0_0, 1, 0, 16#80, "SER_UART_Write")
--     RegWrite(SER_ID, SR_AUDIO_TX0_1, 1, 0, 16#80, "SER_UART_Write")
--     RegWrite(SER_ID, SR_AUDIO_RX1, 1,  0, 16#00, "SER_UART_Write")    -- Disable the audio receiver
--     RegWrite(SER_ID, SR_REG2, 1, 0, 16#00, "SER_UART_Write")          -- Disable the audio transmitter but leave the uart DIS_LOCAL_CC enabled until all registers have been written
---------------------------------------------------------------

    -- GpioA = 16#81,  GPIO_B = 16#60, GPIO_C = 16#C3)
    for i = 0 to 20 do                                                      ----for HS89 8x8 56 pins package has only 21 MFP
      RegWrite(SER_ID, (SR_GPIO_A_0+(word(i)*3)), 2,0, 16#6081, "SER_UART_Write")  -- GPIO_B -- need 0x60 or would 0x40 also work OK?
    endfor

  elseif RegConfigStr == "PulldownGpio40k" then
-------may not needed for HS89 becasue HS89 MFPs are  gpio and audio pins  MT 6/2017
--     RegWrite(SER_ID, SR_AUDIO_TX0_0, 1, 0, 16#80, "SER_UART_Write")
--     RegWrite(SER_ID, SR_AUDIO_TX0_1, 1, 0, 16#80, "SER_UART_Write")
--     RegWrite(SER_ID, SR_AUDIO_RX1, 1,  0, 16#00, "SER_UART_Write")    -- Disable the audio receiver
--     RegWrite(SER_ID, SR_REG2, 1, 0, 16#00, "SER_UART_Write")          -- Disable the audio transmitter but leave the uart DIS_LOCAL_CC enabled until all registers have been written
---------------------------------------------------------------
    -- GpioA = 16#01,  GPIO_B = 16#A0, GPIO_C = 16#C3)
    for i = 0 to 20 do                                                     ----for HS89 8x8 56 pins package has only 21 MFP
      RegWrite(SER_ID, SR_GPIO_A_0+(word(i)*3), 3,16#C3 , 16#A001, "SER_UART_Write")  -- GPIO_B -- need 0xA0 or would 0x80 also work OK?
    endfor
--        RegWrite(SER_ID, SR_CTRL0, 1, 0, 16#40, "SER_UART_Write")
  elseif RegConfigStr == "PulldownGpio1M" then
-------may not needed for HS89 MT becasue HS89 MFPs are  gpio and audio pins  MT 6/2017
--     RegWrite(SER_ID, SR_AUDIO_TX0_0, 1, 0, 16#80, "SER_UART_Write")
--     RegWrite(SER_ID, SR_AUDIO_TX0_1, 1, 0, 16#80, "SER_UART_Write")
--     RegWrite(SER_ID, SR_AUDIO_RX1, 1,  0, 16#00, "SER_UART_Write")    -- Disable the audio receiver
--     RegWrite(SER_ID, SR_REG2, 1, 0, 16#00, "SER_UART_Write")          -- Disable the audio transmitter but leave the uart DIS_LOCAL_CC enabled until all registers have been written
---------------------------------------------------------------

    -- GpioA = 16#81,  GPIO_B = 16#A0, GPIO_C = 16#C3)
    for i = 0 to 20 do                                                     ----for HS89 8x8 56 pins package has only 21 MFP
      RegWrite(SER_ID, SR_GPIO_A_0+(word(i)*3), 2, 0, 16#A081, "SER_UART_Write")  -- GPIO_B -- need 0xA0 or would 0x80 also work OK?
    endfor
  elseif RegConfigStr = "PrbsTest" then
------Not debug yet
--     RegWrite(DNUT1_ID, DR_GPIO_A_0, 1, 0, 16#0, "dnut_uart_write")    -- each writes to GPIO_A and GPIO_B bytes disables output drivers and disconnects pullup / pulldown connections
--     RegWrite(DNUT1_ID, DR_GPIO_A_1, 1, 0, 16#0, "dnut_uart_write")    -- each writes to GPIO_A and GPIO_B bytes disables output drivers and disconnects pullup / pulldown connections
--     RegWrite(DNUT1_ID, DR_GPIO_A_2, 1, 0, 16#0, "dnut_uart_write")    -- each writes to GPIO_A and GPIO_B bytes disables output drivers and disconnects pullup / pulldown connections
--     RegWrite(DNUT1_ID, DR_GPIO_A_3, 1, 0, 16#0, "dnut_uart_write")    -- each writes to GPIO_A and GPIO_B bytes disables output drivers and disconnects pullup / pulldown connections
--     RegWrite(DNUT1_ID, DR_GPIO_A_4, 1, 0, 16#0, "dnut_uart_write")    -- each writes to GPIO_A and GPIO_B bytes disables output drivers and disconnects pullup / pulldown connections
--     RegWrite(DNUT1_ID, DR_GPIO_A_5, 1, 0, 16#0, "dnut_uart_write")    -- each writes to GPIO_A and GPIO_B bytes disables output drivers and disconnects pullup / pulldown connections
--     RegWrite(DNUT1_ID, DR_GPIO_A_6, 1, 0, 16#0, "dnut_uart_write")    -- each writes to GPIO_A and GPIO_B bytes disables output drivers and disconnects pullup / pulldown connections
--     RegWrite(DNUT1_ID, DR_GPIO_A_7, 1, 0, 16#0, "dnut_uart_write")    -- each writes to GPIO_A and GPIO_B bytes disables output drivers and disconnects pullup / pulldown connections
--     RegWrite(DNUT1_ID, DR_GPIO_A_8, 1, 0, 16#0, "dnut_uart_write")    -- each writes to GPIO_A and GPIO_B bytes disables output drivers and disconnects pullup / pulldown connections
--     RegWrite(DNUT1_ID, DR_GPIO_A_9, 1, 0, 16#0, "dnut_uart_write")    -- each writes to GPIO_A and GPIO_B bytes disables output drivers and disconnects pullup / pulldown connections
--     RegWrite(DNUT1_ID, DR_GPIO_A_10, 1, 0, 16#0, "dnut_uart_write")    -- each writes to GPIO_A and GPIO_B bytes disables output drivers and disconnects pullup / pulldown connections
--     RegWrite(DNUT1_ID, DR_GPIO_A_11, 1, 0, 16#0, "dnut_uart_write")    -- each writes to GPIO_A and GPIO_B bytes disables output drivers and disconnects pullup / pulldown connections
--     RegWrite(DNUT1_ID, DR_GPIO_A_12, 1, 0, 16#0, "dnut_uart_write")    -- each writes to GPIO_A and GPIO_B bytes disables output drivers and disconnects pullup / pulldown connections
--     RegWrite(DNUT1_ID, DR_GPIO_A_13, 1, 0, 16#0, "dnut_uart_write")    -- each writes to GPIO_A and GPIO_B bytes disables output drivers and disconnects pullup / pulldown connections
-- 
--     RegWrite(DNUT2_ID, DR_GPIO_A_0, 1, 0, 16#0, "dnut_uart_write")    -- each writes to GPIO_A and GPIO_B bytes disables output drivers and disconnects pullup / pulldown connections
--     RegWrite(DNUT2_ID, DR_GPIO_A_1, 1, 0, 16#0, "dnut_uart_write")    -- each writes to GPIO_A and GPIO_B bytes disables output drivers and disconnects pullup / pulldown connections
--     RegWrite(DNUT2_ID, DR_GPIO_A_2, 1, 0, 16#0, "dnut_uart_write")    -- each writes to GPIO_A and GPIO_B bytes disables output drivers and disconnects pullup / pulldown connections
--     RegWrite(DNUT2_ID, DR_GPIO_A_3, 1, 0, 16#0, "dnut_uart_write")    -- each writes to GPIO_A and GPIO_B bytes disables output drivers and disconnects pullup / pulldown connections
--     RegWrite(DNUT2_ID, DR_GPIO_A_4, 1, 0, 16#0, "dnut_uart_write")    -- each writes to GPIO_A and GPIO_B bytes disables output drivers and disconnects pullup / pulldown connections
--     RegWrite(DNUT2_ID, DR_GPIO_A_5, 1, 0, 16#0, "dnut_uart_write")    -- each writes to GPIO_A and GPIO_B bytes disables output drivers and disconnects pullup / pulldown connections
--     RegWrite(DNUT2_ID, DR_GPIO_A_6, 1, 0, 16#0, "dnut_uart_write")    -- each writes to GPIO_A and GPIO_B bytes disables output drivers and disconnects pullup / pulldown connections
--     RegWrite(DNUT2_ID, DR_GPIO_A_7, 1, 0, 16#0, "dnut_uart_write")    -- each writes to GPIO_A and GPIO_B bytes disables output drivers and disconnects pullup / pulldown connections
--     RegWrite(DNUT2_ID, DR_GPIO_A_8, 1, 0, 16#0, "dnut_uart_write")    -- each writes to GPIO_A and GPIO_B bytes disables output drivers and disconnects pullup / pulldown connections
--     RegWrite(DNUT2_ID, DR_GPIO_A_9, 1, 0, 16#0, "dnut_uart_write")    -- each writes to GPIO_A and GPIO_B bytes disables output drivers and disconnects pullup / pulldown connections
--     RegWrite(DNUT2_ID, DR_GPIO_A_10, 1, 0, 16#0, "dnut_uart_write")    -- each writes to GPIO_A and GPIO_B bytes disables output drivers and disconnects pullup / pulldown connections
--     RegWrite(DNUT2_ID, DR_GPIO_A_11, 1, 0, 16#0, "dnut_uart_write")    -- each writes to GPIO_A and GPIO_B bytes disables output drivers and disconnects pullup / pulldown connections
--     RegWrite(DNUT2_ID, DR_GPIO_A_12, 1, 0, 16#0, "dnut_uart_write")    -- each writes to GPIO_A and GPIO_B bytes disables output drivers and disconnects pullup / pulldown connections
--     RegWrite(DNUT2_ID, DR_GPIO_A_13, 1, 0, 16#0, "dnut_uart_write")    -- each writes to GPIO_A and GPIO_B bytes disables output drivers and disconnects pullup / pulldown connections
-- 
--     RegWrite(SER_ID, SR_GPIO_A_0, 1, 0, 16#0, "SER_UART_Write")    -- each writes to GPIO_A and GPIO_B bytes disables output drivers and disconnects pullup / pulldown connections
--     RegWrite(SER_ID, SR_GPIO_A_1, 1, 0, 16#0, "SER_UART_Write")    -- each writes to GPIO_A and GPIO_B bytes disables output drivers and disconnects pullup / pulldown connections
--     RegWrite(SER_ID, SR_GPIO_A_2, 1, 0, 16#0, "SER_UART_Write")    -- each writes to GPIO_A and GPIO_B bytes disables output drivers and disconnects pullup / pulldown connections
--     RegWrite(SER_ID, SR_GPIO_A_3, 1, 0, 16#0, "SER_UART_Write")    -- each writes to GPIO_A and GPIO_B bytes disables output drivers and disconnects pullup / pulldown connections
--     RegWrite(SER_ID, SR_GPIO_A_4, 1, 0, 16#0, "SER_UART_Write")    -- each writes to GPIO_A and GPIO_B bytes disables output drivers and disconnects pullup / pulldown connections
--     RegWrite(SER_ID, SR_GPIO_A_5, 1, 0, 16#0, "SER_UART_Write")    -- each writes to GPIO_A and GPIO_B bytes disables output drivers and disconnects pullup / pulldown connections
--     RegWrite(SER_ID, SR_GPIO_A_6, 1, 0, 16#0, "SER_UART_Write")    -- each writes to GPIO_A and GPIO_B bytes disables output drivers and disconnects pullup / pulldown connections
--     RegWrite(SER_ID, SR_GPIO_A_7, 1, 0, 16#0, "SER_UART_Write")    -- each writes to GPIO_A and GPIO_B bytes disables output drivers and disconnects pullup / pulldown connections
--     RegWrite(SER_ID, SR_GPIO_A_8, 1, 0, 16#0, "SER_UART_Write")    -- each writes to GPIO_A and GPIO_B bytes disables output drivers and disconnects pullup / pulldown connections
--     RegWrite(SER_ID, SR_GPIO_A_9, 1, 0, 16#0, "SER_UART_Write")    -- each writes to GPIO_A and GPIO_B bytes disables output drivers and disconnects pullup / pulldown connections
--     RegWrite(SER_ID, SR_GPIO_A_10, 1, 0, 16#0, "SER_UART_Write")    -- each writes to GPIO_A and GPIO_B bytes disables output drivers and disconnects pullup / pulldown connections
--     RegWrite(SER_ID, SR_GPIO_A_11, 1, 0, 16#0, "SER_UART_Write")    -- each writes to GPIO_A and GPIO_B bytes disables output drivers and disconnects pullup / pulldown connections
--     RegWrite(SER_ID, SR_GPIO_A_12, 1, 0, 16#0, "SER_UART_Write")    -- each writes to GPIO_A and GPIO_B bytes disables output drivers and disconnects pullup / pulldown connections
--     RegWrite(SER_ID, SR_GPIO_A_13, 1, 0, 16#0, "SER_UART_Write")    -- each writes to GPIO_A and GPIO_B bytes disables output drivers and disconnects pullup / pulldown connections
--     RegWrite(SER_ID, SR_GPIO_A_14, 1, 0, 16#0, "SER_UART_Write")    -- each writes to GPIO_A and GPIO_B bytes disables output drivers and disconnects pullup / pulldown connections
--     RegWrite(SER_ID, SR_GPIO_A_15, 1, 0, 16#0, "SER_UART_Write")    -- each writes to GPIO_A and GPIO_B bytes disables output drivers and disconnects pullup / pulldown connections
--     RegWrite(SER_ID, SR_GPIO_A_16, 1, 0, 16#0, "SER_UART_Write")    -- each writes to GPIO_A and GPIO_B bytes disables output drivers and disconnects pullup / pulldown connections
-----------------------------------------------------------------
-- --     RegWrite(SER_ID, SR_REG2, 1, 0, 16#17, "ser_uart_write")
-- --     RegWrite(DES_ID, DR_REG2, 1, 0, 16#17, "des_uart_write")



  elseif RegConfigStr = "GmslAEqTestConfig" then  -----Not debug yet MT
--     RegWrite(SER_ID, SR_RLMS50_A, 1, 0, 16#31, "SER_UART_Write")
--     RegWrite(SER_ID, SR_RLMS16_A, 1, 0, 16#2, "SER_UART_Write")
--     RegWrite(SER_ID, SR_RLMS15_A, 1, 0, 16#20, "SER_UART_Write")
--     RegWrite(SER_ID, SR_RLMSB_A, 1, 0, 16#0, "SER_UART_Write")
--     RegWrite(SER_ID, SR_RLMSA_A, 1, 0, 16#02, "SER_UART_Write")
--     RegWrite(SER_ID, SR_RLMS3C_A, 1, 0, 16#8, "SER_UART_Write")
--     RegWrite(SER_ID, SR_RLMS1F_A, 1, 0, 16#80, "SER_UART_Write")
--     RegWrite(SER_ID, SR_RLMS23_A, 1, 0, 16#00, "SER_UART_Write")
--     RegWrite(SER_ID, SR_RLMS12B_A, 1, 0, 16#01, "SER_UART_Write")
--     RegWrite(SER_ID, SR_RLMS12A_A, 1, 0, 16#41, "SER_UART_Write")
--     RegWrite(SER_ID, SR_RLMS29_A, 1, 0, 16#41, "SER_UART_Write")
--     RegWrite(SER_ID, SR_RLMS28_A, 1, 0, 16#41, "SER_UART_Write")
--     RegWrite(SER_ID, SR_RLMS27_A, 1, 0, 16#01, "SER_UART_Write")
--     RegWrite(SER_ID, SR_RLMS90_A, 1, 0, 16#80, "SER_UART_Write")
--     RegWrite(SER_ID, SR_RLMS45_A, 1, 0, 16#00, "SER_UART_Write")
--     RegWrite(SER_ID, SR_RLMSA8_A, 1, 0, 16#E0, "SER_UART_Write")
--     RegWrite(SER_ID, SR_RLMSA9_A, 1, 0, 16#B8, "SER_UART_Write")
--     wait(1ms)
--     RegWrite(SER_ID, SR_RLMSA8_A, 1, 0, 16#C0, "SER_UART_Write")
--     RegWrite(SER_ID, SR_RLMSA9_A, 1, 0, 16#20, "SER_UART_Write")
--     wait(1ms)
--     RegWrite(SER_ID, SR_RLMSA8_A, 1, 0, 16#E0, "SER_UART_Write")
--     RegWrite(SER_ID, SR_RLMSA9_A, 1, 0, 16#A8, "SER_UART_Write")
--     wait(1ms)
--     
--     
--     
--     RegWrite(SER_ID, SR_RLMS1F_A, 1, 0, 16#80, "SER_UART_Write")    -- 
--     RegWrite(SER_ID, SR_RLMS33_A, 1, 0, 16#00, "SER_UART_Write")   -- should be 0x00, not 0x20 per Wil Reyes' instructions from 8/2016



  endif

end_body



procedure DutPowerUp(vio, vdd18,vdd, opmode1,opmode2, powerup_needed)
--------------------------------------------------------------------------------
-- 
in float       : vio             -- IOVDD  voltage level
in float       : vdd18           -- VDD18 voltage level
in float       : vdd             -- VDD  voltage level
in string[15]   : opmode1,opmode2         -- mode to latch (UART or I2C) TP or COAX
in boolean     : powerup_needed  ----Need go through power up sequence
                                
local
    float             :     vcfg0, vcfg1, vcfg2
    multisite word    : OscStatus
    boolean           : reset_level  --- reset all pattern level; request by Viet to add this boolean
    string[4]           : MPW

endlocal



body
    MPW = "MPW5"
    reset_level = false
 -- Power Up all Devices
    if(powerup_needed) then
        if reset_level then
------------------------    -- reset levels 
            set digital pin ALL_PATTERN_PINS - FPGA_CSB-FPGA_SCLK-FPGA_SDIN-FPGA_SDOUT levels to vil 0.2V vih 0.4V vol 0V voh 0V iol 0mA ioh 0mA vref 0V
            set digital pin ALL_PATTERN_PINS - FPGA_CSB-FPGA_SCLK-FPGA_SDIN-FPGA_SDOUT modes to driver pattern     -- Do not delete !!! 
            wait(1ms)
            execute digital pattern "PowerUp" at label "ALL_ZERO" wait   -- Do not delete in order to reset all pins to vil level !!!
            wait(1ms)             
        end_if 
    --The function below is for setting DUT supplies ONLY, change Voltage if Required  
--        set digital pin SER_GPO4_CFG0 fx1  driver preset low  -------
        disconnect digital pin SER_CSI_PINS from dcl 
        Set_SER_Voltages(vio, vdd, vdd18)
        wait (10ms) -- trial for 47uF cap on SER_VDD

        if MPW = "MPW4" then
            if opmode1 == "UART" then
                vcfg0 = 0.11* vio       ------UART Mode
            else
                vcfg0 = 0.16* vio     ------I2C Mode
            end_if
        
            if opmode2 == "TP_GMSL2" then       
                vcfg1 = 0.16 * vio      -----TP and GMSL2  vcfg1   = 0.16
            elseif opmode2 == "COAX_GMSL2" then
                vcfg1 = 0.55 * vio      -----Coax and GMSL2
            elseif opmode2 == "TP_GMSL1" then
                vcfg1 = 0.11 * vio      -----TP and GMSL1
            elseif opmode2 == "COAX_GMSL1" then
                vcfg1 = 0.50 * vio      -----Coax and GMSL1
            else ---default to gmsl2 and tp
                vcfg1 = 0.16 * vio      -----TP and GMSL2 
            end_if
       
            vcfg2 = 0.11* vio    
    
        else

----Set operation UART or I2C ; gmsl 2 mode address = 0x80 for HS89 8x8 56pins       
            if opmode1 == "UART" then
                vcfg0 = 0.93* vio       ------UART Mode( update from MPW5 12/2017 addr = 0x80
            else
                vcfg0 = 0.05* vio       ------I2C Mode( update from MPW5 12/2017 addr = 0x80)---------------UART Mode old MPW3
            end_if
        
            if opmode2 == "TP_GMSL2" then       
                vcfg1 = 0.44 * vio                      -----TP and GMSL2 6GHz MPW5 12/2017
            elseif opmode2 == "COAX_GMSL2" then
                vcfg1 = 0.05 * vio                      -----Coax and GMSL2 6GHz MPW5 12/2017
            elseif opmode2 == "TP_GMSL1" then
                vcfg1 = 0.80 * vio -----------vcfg1 = 0.68 * vio                      -----TP and GMSL1 HIM Dis MPW5 12/20170.80 * vio
            elseif opmode2 == "COAX_GMSL1" then
                vcfg1 = 0.32 * vio                                    -------------vcfg1 = 0.20 * vio                  -----Coax and GMSL1 HIM Dis MPW5 12/2017
            else ---default to gmsl2 and tp
                vcfg1 = 0.44 * vio      -----TP and GMSL2 
            end_if
       
            vcfg2 = 0.05* vio                   ----RCLKOUT disable
        end_if        
--set digital pin  SER_GPO4_CFG0 levels to vil 0.5*vio vih vio vol 0.3*vio  voh 0.7*vio

        set digital pin  SER_GPO4_CFG0 levels to vil vcfg0 vih vio vol 0.3*vio  voh 0.7*vio  ----added mt 9/2017
        set digital pin  SER_GPO5_CFG1 levels to vil vcfg1 vih vio  vol 0.3*vio  voh 0.7*vio    
        set digital pin  SER_GPO6_CFG2 levels to vil vcfg2 vih vio  vol 0.3*vio  voh 0.7*vio            
        
 
        --zTTR wait(1ms)
  -------- Set PWDN =1 to power up DUT --------
         set digital pin SER_PWDNB  levels to vil 0.1*vio vih vio*0.9 vol 400mV voh vio*0.8 iol 0uA ioh 0uA vref 0V--- deglitch mt 2/2019
         execute digital pattern "PowerUp" at label "TP" run to end wait
        wait(6ms) -- needed z 
    else
----------The function below is for setting DUT supplies ONLY, change Voltage if Required  
        Set_SER_Voltages(vio, vdd, vdd18)    
        --zTTR wait(2ms)
    end_if


end_body


procedure powerdown_device(NEED_POWER_DOWN)
--------------------------------------------------------------------------------
--  
    in boolean      : NEED_POWER_DOWN
local

end_local

body
    if NEED_POWER_DOWN then ---- power down

 
        set digital pin ALL_PATTERN_PINS - FPGA_CSB-FPGA_SCLK-FPGA_SDIN-FPGA_SDOUT levels to vil 0V vih 100mV iol 0uA ioh 0uA vref 0V
--        set  digital  pin ALL_PATTERN_PINS - fpga_pattern_pins  fx1 driver  preset low 
        set hcovi SER_VDD + SER_VDD18 to fv 0.5V vmax 4V clamp imax 600mA imin -600mA      ---glitch on sioa/b pins   
        wait(2ms)---glitch on sioa/b pins
        set hcovi SER_VDD + SER_VDD18 to fv 0.0V vmax 4V clamp imax 600mA imin -600mA         
        set hcovi SER_VDDIO to fv 0V   vmax 4V clamp imax 600mA imin -600mA
        wait(5ms)     -- extra for 47uF cap on SER_VDD        --20ms 
  ---------- Initialize for set_SER_Voltages(vio, vcore, v18) routine
        vdd_global[1] = 0V   --SER_VDDIO
        vdd_global[2] = 0V   --SER_VDD  
        vdd_global[3] = 0V   --SER_VDDA(VDD18)   
    else
        ----do nothing
    end_if 

end_body

procedure powerup_dnut_vdd_vterm(VDD_SET, VTERM_SET)
--------------------------------------------------------------------------------
--  
in  float       : VDD_SET, VTERM_SET
local

end_local

body

--  Power up DES (HS92/MAX96912E)   
    set ovi chan DNUT_VDD to fv VDD_SET measure i max 500mA clamp imax 500mA imin -500mA   
    set hcovi  DNUT_VTERM to fv VTERM_SET measure i max 500mA clamp imax 500mA imin -500mA
    wait(1ms)
    connect ovi chan  DNUT_VDD remote
    connect hcovi  DNUT_VTERM remote
    wait(3ms)
    gate ovi chan DNUT_VDD on  ----put gate on statement on on load later
    gate hcovi DNUT_VTERM on
    wait(3ms)
end_body


function Mipi_LP_linear_Search(pinn, startV, stopV, patt, Label_high, Label_low, compare_pin) :   multisite float[2]
--------------------------------------------------------------------------------
--  This functions does a linear search for Vih and Vil thresholds
--  and returns both values. It uses the digital drivers to force voltage.
--  Use this function for pins with hysteresis.
in pin list[1]     : pinn     -- pin under test
in float           : startV   -- search start voltage value
in float           : stopV    -- search stop voltage value
in string[40]      : patt     -- name of pattern to run
in string[10]      : Label_high, Label_low 
in pin list[1]     : compare_pin

local

multisite boolean  : result
multisite boolean  : pfvalue
float              : bound1, bound2              -- search boundaries
float              : current_value, stepV, stepV_big
float              : last_passing, last_failing
multisite float    : thresh[2]

end_local

body

    current_active_sites = get_active_sites()
    csite = current_active_sites[1]
 
    -- only turn on MFP pin of interest
    set digital pin compare_pin modes to comparator enable all fails   



    bound1 = startV                    -- lower boundary
    bound2 = stopV                     -- upper boundary
    stepV  = 1mV                       -- step voltage for linear search
    stepV_big = stepV * 10.0
--------------- Begin Vih search ----------------------------------------

--    current_value = stopV - stepV
    current_value = startV
    while (current_value >= bound1 AND current_value <= bound2 ) do
    
       set digital ppmu pinn to fv current_value vmax 2v  measure i max 20ma
 --      wait(2ms)
       execute digital pattern patt at label Label_high run to end into pfvalue 
       
       if not pfvalue[csite] then    -- if pattern run failed
--          last_passing  = current_value          
          current_value = current_value + stepV_big
          wait(0ms)
 
       else                      -- if pattern passed 
--           last_passing  = current_value  
           if last_passing = startV then  ---- something wrong need check
              last_passing = 999.9
           else
                set digital ppmu pinn to fv startV vmax 2v  measure i max 20ma                  ---reset output to low
                wait(2ms)
                current_value = current_value - 2.0*stepV_big                                   ---return 2 big step
                while (current_value >= bound1 AND current_value <= bound2) do
                    set digital ppmu pinn to fv current_value vmax 2v  measure i max 20ma
                    execute digital pattern patt at label Label_high run to end into pfvalue 
                    if not pfvalue[csite] then    -- if pattern run failed
                        current_value = current_value + stepV
                    else                                                                -- if pattern passed 
                        last_passing  = current_value  
                        break
                   end_if
                end_while    
           end_if 
          break    -- exit loop
       end_if              

    end_while
    
    
    thresh[csite,1] = last_passing  -- vih threshold
    wait(0ms)
    
------------------------- End Vih search -------------------------------------    
    



--------------- Begin Vil search ----------------------------------------
    
    current_value = last_passing + 50mV    
    
    while (current_value >= bound1 AND current_value <= bound2) do
    
       set digital ppmu pinn to fv current_value vmax 1v  measure i max 20ma
--       wait(2ms)
       execute digital pattern patt at label Label_low run to end into pfvalue

       if not pfvalue[csite] then    -- if pattern run failed
--          last_passing  = current_value          
          current_value = current_value - stepV_big
          wait(0ms)
 
       else                      -- if pattern passed
--          last_passing  = current_value
            set digital ppmu pinn to fv stopV vmax 2v  measure i max 20ma              -----reset output to high
            current_value = current_value + 2.0*stepV_big                                  ---return 1 big step
            
            while (current_value >= bound1 AND current_value <= bound2) do
                set digital ppmu pinn to fv current_value vmax 2v  measure i max 20ma
                execute digital pattern patt at label Label_low run to end into pfvalue
                if not pfvalue[csite] then    -- if pattern run failed
                    current_value = current_value - stepV 
                else                      -- if pattern passed
                    last_passing  = current_value
                    break
                end_if
            end_while
          break    -- exit loop
            wait(0)		
       end_if              
--               break    -- exit loop
   wait(0)
    end_while
    
    
    thresh[csite,2] = last_passing  -- vih threshold
    wait(0ms)
------------------------- End Vil search -------------------------------------

    
    set digital ppmu pinn to fv 0.0 vmax 1v  measure i max 1ma   -- reset  value to 0V
    set digital pin compare_pin modes to comparator disable all fails  

    return(thresh)   -- returns both vih and vil threshold values
    
end_body

function Mipi_HS_linear_Search(pinn_P, pinn_N, V_com, stepV, patt, Label_high, Label_low, compare_pin) :   multisite float[2]
--------------------------------------------------------------------------------
--  This functions does a binary search for Vih and Vil thresholds
--  and returns both values. It uses the ppmu to force voltage.
--  Use this function for pins without hysteresis.
in pin list[1]     : pinn_P, pinn_N     -- pins under test
in float           : V_com              -- Common mode voltage
in float           : stepV              -- resolution of linear search voltage
in string[40]      : patt               -- name of pattern to run
in string[10]      : Label_high, Label_low 
in pin list[1]     : compare_pin

local

multisite boolean  : result
multisite boolean  : pfvalue
float              : bound1, bound2              -- binary search boundaries
float              : increment, current_value_P, current_value_N
float              : last_passing_P, last_passing_N, last_failing, Vstep_large, vstart_P, vstart_N, start_diff
multisite float    : thresh[2]

end_local

body

    current_active_sites = get_active_sites()
    csite = current_active_sites[1]
 
    -- only turn on MFP pin of interest
    set digital pin compare_pin modes to comparator enable all fails  
 
   Vstep_large = stepV * 10.0     
   start_diff = 50mV                                        ---might change to pass parameter from call function
--------------- Begin Pos diff search (P>N) --------------------------------
    current_value_P = V_com + start_diff
    current_value_N = V_com - start_diff
    vstart_P = current_value_P
    vstart_N = current_value_N
    pfvalue = FALSE    
    
    while (current_value_P - current_value_N) > -100mV do

       set digital ppmu pinn_P to fv current_value_P vmax 2v  measure i max 20ma
       set digital ppmu pinn_N to fv current_value_N vmax 2v  measure i max 20ma       
       wait(3ms)
       
       execute digital pattern patt at label Label_high run to end into pfvalue
      
       if  pfvalue[csite] then                                  -------------pattern passed
          last_passing_P  = current_value_P
          last_passing_N  = current_value_N          
          current_value_P = current_value_P - Vstep_large
          current_value_N = current_value_N + Vstep_large
       else                      -- if pattern run failed

          break    -- exit loop
       end_if       
               
    end_while
-------------------------------------
 ---search with finer resolution or datalog big fail number   

    if current_value_P - current_value_N < -100mV then  
        thresh[csite,2] = 999.0                          --- no threshold found
    else   ---search for finer step
    
        current_value_P = current_value_P + Vstep_large             ----return 1 step
        current_value_N = current_value_N - Vstep_large             ----return 1 step

        pfvalue = FALSE    
        
       set digital ppmu pinn_P to fv  vstart_P vmax 2v  measure i max 20ma  ---bring back to begin value
       set digital ppmu pinn_N to fv  vstart_N vmax 2v  measure i max 20ma       
       wait(3ms)        
 
       ---Search with finer resolution
       while (current_value_P - current_value_N) > -99mV do        
            set digital ppmu pinn_P to fv  current_value_P vmax 2v  measure i max 20ma  ---bring back to begin value
            set digital ppmu pinn_N to fv  current_value_N vmax 2v  measure i max 20ma                     
            wait(3ms)          
            execute digital pattern patt at label Label_high run to end into pfvalue
      
            if  pfvalue[csite] then    
                last_passing_P  = current_value_P
                last_passing_N  = current_value_N                          
                current_value_P = current_value_P - stepV
                current_value_N = current_value_N + stepV
            else                      -- if pattern run failed

                break    -- exit loop
            end_if       
               
        end_while        
        
        thresh[csite,1] =     last_passing_P -  last_passing_N   -------ViH        
--        thresh[csite,2] =  current_value_P - current_value_N   -- 
    end_if 
    wait(0ms)
    




------------------------- End Vih search -------------------------------------    
    



--------------- Begin Vil search ----------------------------------------
    current_value_P = V_com - start_diff
    current_value_N = V_com + start_diff
    vstart_P = current_value_P
    vstart_N = current_value_N
    pfvalue = FALSE
    
    while (current_value_N - current_value_P) > -100mV do
  
       set digital ppmu pinn_P to fv current_value_P vmax 1v  measure i max 20ma
       set digital ppmu pinn_N to fv current_value_N vmax 1v  measure i max 20ma
       wait(3ms)
    
       execute digital pattern patt at label Label_low run to end into pfvalue
       wait(0ms)

       if  pfvalue[csite] then    -- search until it passed 

          current_value_P = current_value_P + Vstep_large
          current_value_N = current_value_N - Vstep_large
       else                      -- passed, threshold found
          break    -- exit loop
       end_if
               
    end_while

-------------------------------------
 ---search with finer resolution or datalog big fail number   
    
    if current_value_N - current_value_P < -100mV then
        thresh[csite,2] = 999.9
    else    
        current_value_P = current_value_P - Vstep_large             ----return 1 step
        current_value_N = current_value_N + Vstep_large             ----return 1 step
        pfvalue = FALSE    
       set digital ppmu pinn_P to fv  vstart_P vmax 2v  measure i max 20ma  ---bring back to begin value
       set digital ppmu pinn_N to fv  vstart_N vmax 2v  measure i max 20ma       
       wait(3ms)   

        while (current_value_N - current_value_P) > -99mV do
  
            set digital ppmu pinn_P to fv current_value_P vmax 1v  measure i max 20ma
            set digital ppmu pinn_N to fv current_value_N vmax 1v  measure i max 20ma
            wait(3ms)    
            execute digital pattern patt at label Label_low run to end into pfvalue
            wait(0ms)
            if pfvalue[csite] then    -- search until it fail 
                last_passing_P  = current_value_P
                last_passing_N  = current_value_N

                current_value_P = current_value_P + stepV
                current_value_N = current_value_N - stepV
            else                      -- failed, threshold found
                break    -- exit loop
            end_if
               
        end_while
        thresh[csite,2] =          last_passing_P - last_passing_N
--        thresh[csite,1] =  current_value_P - current_value_N 
    end_if 




------------------------- End Vil search -------------------------------------
 
       set digital ppmu pinn_P to fv V_com vmax 2v  measure i max 20ma
       set digital ppmu pinn_N to fv V_com vmax 2v  measure i max 20ma
    wait(1ms)
    set digital pin compare_pin modes to comparator disable all fails  

    return(thresh)   -- returns both threshold values
    
end_body

function Mipi_HS_linear_Search_ppmu(pinn_P, pinn_N, V_com, stepV, patt, Label_high, Label_low, compare_pin,vddio_v) :   multisite float[2]
--------------------------------------------------------------------------------
--  This functions does a binary search for Vih and Vil thresholds
--  and returns both values. It uses the ppmu to force voltage.
--  Use this function for pins without hysteresis.
in pin list[1]     : pinn_P, pinn_N     -- pins under test
in float           : V_com              -- Common mode voltage
in float           : stepV              -- resolution of linear search voltage
in string[40]      : patt               -- name of pattern to run
in string[10]      : Label_high, Label_low 
in pin list[1]     : compare_pin
in float           : vddio_v 
local

multisite boolean  : result
multisite boolean  : pfvalue
float              : bound1, bound2              -- binary search boundaries
float              : increment, current_value_P, current_value_N
float              : last_passing_P, last_passing_N, last_failing
multisite float    : thresh[2]
multisite float    : Vmeas[1]
end_local

body

    current_active_sites = get_active_sites()
 csite = current_active_sites[1]
 
    -- only turn on MFP pin of interest
    set digital pin compare_pin modes to comparator enable all fails  
 
    
--------------- Begin Pos diff search (P>N) - Vin Low search-------------------------------
    current_value_P = V_com + 0.03
    current_value_N = V_com - 0.03
    pfvalue = FALSE    
    
    while ((current_value_P - current_value_N) > -10mV )do
        

       set digital ppmu pinn_P to fv current_value_P vmax 1v  measure i max 20ma
       set digital ppmu pinn_N to fv current_value_N vmax 1v  measure i max 20ma       
          
       wait(2ms)
       measure digital ppmu compare_pin voltage  vmax 3.0v average 20 delay 5us into Vmeas
       
      
       if Vmeas[csite] > vddio_v/2.0 then    -- still low
         
          current_value_P = current_value_P - stepV
          current_value_N = current_value_N + stepV
       else                      -- if pattern run failed
          --last_failing = current_value
          --current_value = current_value + increment
          break    -- exit loop
       end_if       
               
    end_while
        
    thresh[csite,2] =  current_value_P - current_value_N
    wait(0ms)
    
------------------------- End Vih search -------------------------------------    
    



--------------- Begin Vil search ----------------------------------------
    current_value_P = V_com - 0.03
    current_value_N = V_com + 0.03
    pfvalue = FALSE
    
    while (current_value_N - current_value_P) > -40mV do
  
       set digital ppmu pinn_P to fv current_value_P vmax 1v  measure i max 20ma
       set digital ppmu pinn_N to fv current_value_N vmax 1v  measure i max 20ma
       wait(2ms)
       measure digital ppmu compare_pin voltage  vmax 3.0v average 20 delay 5us into Vmeas
 
       if Vmeas[csite] < vddio_v/2.0 then    -- vih search
          current_value_P = current_value_P + stepV
          current_value_N = current_value_N - stepV
       else                      -- if pattern run failed
          break    -- exit loop
       end_if
               
    end_while
    
    
    thresh[csite,1] =  current_value_P - current_value_N -- Vdiff low, negative number
    
------------------------- End Vil search -------------------------------------
 
       set digital ppmu pinn_P to fv 0.0 vmax 2v  measure i max 20ma
       set digital ppmu pinn_N to fv 0.1 vmax 2v  measure i max 20ma
    wait(1ms)
--    set digital pin compare_pin modes to comparator disable all fails  

    return(thresh)   -- returns both threshold values
    
end_body

procedure WaitForRegister(  tTimeout , regAddr , regExpectedValue , regMask , deviceSerOrDes , busUseFpga , outSerRd , outDesRd , DEBUG )
--------------------------------------------------------------------------------
-- Waits for a register to hit the expected value (after a mask is applied)
--  up to a maximimum timeout
-- Can read back from the DUT and/or DNUT, using DP and/or FPGA as the master
--
in float                                        : tTimeout
in word                                        : regAddr
in lword                                        : regExpectedValue , regMask
in string[6]                                    : deviceSerOrDes                        -- "SER" or "DES" or "SERDES"
in boolean                                      : busUseFpga                            -- T:FPGA, F:DigitalPin
out multisite lword                             : outSerRd , outDesRd                   -- return values
in integer                                      : DEBUG                                 -- 0:off, 1:on, 2:verbose
--------------------------------------------------------------------------------
local
    float                                       : t0, dt
    boolean                                     : allReady = false
    boolean                                     : chkSer , chkDes
    boolean                                     : keep_debug_reg_rw
    word                                        : sidx, s, nSites
    word list[MAX_SITES]                        : actv
end_local

body
    actv = get_active_sites()
    nSites = word( len(actv) )
    
    keep_debug_reg_rw = DEBUG_REG_RW
    DEBUG_REG_RW = (DEBUG > 0) OR (keep_debug_reg_rw)

    start_timer()   ----Without start timer snap_timer will not update MT
    t0 = snap_timer()
    dt = 0s
    allReady = false
    
    chkSer = (0 < pos( "SER" , deviceSerOrDes ) )   -- "SER" or "SERDES"
    chkDes = (0 < pos( "DES" , deviceSerOrDes ) )   -- "DES" or "SERDES"

    -- Loop thru while time has not elapsed and at least one site or device hasn't matched    
    while( not(allReady) and (dt < tTimeout) ) do    
        allReady = true

        if chkSer then
            if busUseFpga then
                RdWordLower = fpga_UART_Read( "FPGA1" , "DES" , SER_ID  , lword(regAddr) , 1 )
            else
                RegRead( SER_ID , regAddr , 1 , RdWordUpper , RdWordLower , "SER_UART_Read" )
            end_if
            dt = snap_timer() - t0
            for sidx = 1 to nSites do
                s = actv[sidx]
                if regMask & RdWordLower[s] <> regExpectedValue then
                    allReady = false
                end_if
            end_for
        end_if

        if chkDes then
            if busUseFpga then
                RdWordLower = fpga_UART_Read( "FPGA1" , "DES"  , DESA_ID  , lword(regAddr) , 1 )                
            else
                RegRead( DESA_ID , regAddr , 1 , RdWordUpper , RdWordLower , "DES_UART_Read" )
            end_if
            dt = snap_timer() - t0
            for sidx = 1 to nSites do
                s = actv[sidx]
                if regMask & RdWordLower[s] <> regExpectedValue then
                    allReady = false
                end_if
            end_for
        end_if
        
        if DEBUG>0 then
            println(stdout, "WaitForRegister(): ", dt!fu=ms:8:0, " elapsed..." )
        end_if

        if not(allReady) and (200ms < dt and dt < tTimeout) and DEBUG>0 then
            -- step by 100ms if it's taken a long time, to reduce debug prints
            wait(100ms)
        end_if
    end_while

    -- grab a final copy of the SER
    if chkSer then
        if busUseFpga then
            outSerRd = fpga_UART_Read( "FPGA1" , "DES" , SER_ID  , lword(regAddr) , 1 )
        else
            RegRead( SER_ID , regAddr , 1 , RdWordUpper , outSerRd , "SER_UART_Read" )
        end_if
        if DEBUG>1 then
            DEBUG_DescribeRegisterValue( "SER_HS89" , SR_CTRL3 , outSerRd , "CTRL3: txdp_en, rxdp_lock, link_mode[1:0], locked, error, cmu_locked, x" )
        end_if
    else
        outSerRd = 0xFEEDF00D
    end_if

    if chkDes then
        if busUseFpga then
            outDesRd = fpga_UART_Read( "FPGA1" , "DES"  , DESA_ID  ,lword(regAddr) , 1 )
        else
            RegRead( DESA_ID , regAddr , 1 , RdWordUpper , outDesRd , "DES_UART_Read" )
        end_if
        if DEBUG>1 then
            DEBUG_DescribeRegisterValue( "DES_HS94" , DR_CTRL3 , outDesRd , "CTRL3: txdp_en, rxdp_lock, link_mode[1:0], locked, error, cmu_locked, x" )
        end_if
    else
        outDesRd = 0xFEEDF00D
    end_if

    if DEBUG>0 then
        dt = snap_timer() - t0
        println(stdout, "WaitForRegister(): ", dt!fu=ms:8:0, " elapsed", "@t", "[FINAL]" )
    end_if


    DEBUG_REG_RW = keep_debug_reg_rw

end_body


procedure DEBUG_DescribeRegisterValue( strDevice, regAddr, msRegValue, strDesc )
--------------------------------------------------------------------------------
--
in string[MAX_STRING]                           : strDevice, strDesc
in word                                         : regAddr
in multisite lword                              : msRegValue
--------------------------------------------------------------------------------
local
    word                                        : s
    word list[MAX_SITES]                        : actv
end_local

body
    actv = get_active_sites()

    print(stdout, "  ", sprint( strDevice:-1, "(0x", regAddr!Hz:4, "):" ):-30 )
    for s = 1 to word(NUM_SITES) do
        if s in actv then
            print(stdout, "  0b", msRegValue[s]!bz:8 )
        else
            print(stdout, "":12 )
        end_if
    end_for
    println(stdout, "@t| ", strDesc)
end_body

procedure WaitForRegister_mod(  tTimeout , regAddr , regExpectedValue , regMask , deviceSerOrDes , busUseFpga_Ser, busUseFpga_Des, outSerRd , outDesRd , DEBUG )
--------------------------------------------------------------------------------
-- Waits for a register to hit the expected value (after a mask is applied)
--  up to a maximimum timeout
-- Can read back from the DUT and/or DNUT, using DP and/or FPGA as the master
--
in float                                        : tTimeout
in word                                        : regAddr
in lword                                        : regExpectedValue , regMask
in string[6]                                    : deviceSerOrDes                        -- "SER" or "DES" or "SERDES"
in boolean                                      : busUseFpga_Des                        -- T:FPGA, F:DigitalPin
in boolean                                      : busUseFpga_Ser                        -- T:FPGA, F:DigitalPin
out multisite lword                             : outSerRd , outDesRd                   -- return values
in integer                                      : DEBUG                                 -- 0:off, 1:on, 2:verbose

--------------------------------------------------------------------------------
local
    float                                       : t0, dt
    boolean                                     : allReady = false
    boolean                                     : chkSer , chkDes
    boolean                                     : keep_debug_reg_rw
    word                                        : sidx, s, nSites
    word list[MAX_SITES]                        : actv
end_local

body
    actv = get_active_sites()
    nSites = word( len(actv) )
    
    keep_debug_reg_rw = DEBUG_REG_RW
    DEBUG_REG_RW = (DEBUG > 0) OR (keep_debug_reg_rw)

    start_timer()   ----Without start timer snap_timer will not update MT
    t0 = snap_timer()
    dt = 0s
    allReady = false
    
    chkSer = (0 < pos( "SER" , deviceSerOrDes ) )   -- "SER" or "SERDES"
    chkDes = (0 < pos( "DES" , deviceSerOrDes ) )   -- "DES" or "SERDES"

    -- Loop thru while time has not elapsed and at least one site or device hasn't matched    
    while( not(allReady) and (dt < tTimeout) ) do    
        allReady = true

        if chkSer then
            if busUseFpga_Ser then
                RdWordLower = fpga_UART_Read( "FPGA1" , "DES" , SER_ID  , lword(regAddr) , 1 )
            else
                RegRead( SER_ID , regAddr , 1 , RdWordUpper , RdWordLower , "SER_UART_Read" )
            end_if
            dt = snap_timer() - t0
            for sidx = 1 to nSites do
                s = actv[sidx]
                if regMask & RdWordLower[s] <> regExpectedValue then
                    allReady = false
                end_if
            end_for
        end_if

        if chkDes then
            if busUseFpga_Des then
                RdWordLower = fpga_UART_Read( "FPGA1" , "DES"  , DESA_ID  , lword(regAddr) , 1 )                
            else
                RegRead( DESA_ID , regAddr , 1 , RdWordUpper , RdWordLower , "DES_UART_Read" )
            end_if
            dt = snap_timer() - t0
            for sidx = 1 to nSites do
                s = actv[sidx]
                if regMask & RdWordLower[s] <> regExpectedValue then
                    allReady = false
                end_if
            end_for
        end_if
        
        if DEBUG>0 then
            println(stdout, "WaitForRegister(): ", dt!fu=ms:8:0, " elapsed..." )
        end_if

        if not(allReady) and (200ms < dt and dt < tTimeout) and DEBUG>0 then
            -- step by 100ms if it's taken a long time, to reduce debug prints
            wait(100ms)
        end_if
    end_while

    -- grab a final copy of the SER
    if chkSer then
        if busUseFpga_Ser then
            outSerRd = fpga_UART_Read( "FPGA1" , "DES" , SER_ID  , lword(regAddr) , 1 )
        else
            RegRead( SER_ID , regAddr , 1 , RdWordUpper , outSerRd , "SER_UART_Read" )
        end_if
        if DEBUG>1 then
            DEBUG_DescribeRegisterValue( "SER_HS89" , SR_CTRL3 , outSerRd , "CTRL3: txdp_en, rxdp_lock, link_mode[1:0], locked, error, cmu_locked, x" )
        end_if
    else
        outSerRd = 0xFEEDF00D
    end_if

    if chkDes then
        if busUseFpga_Des then
            outDesRd = fpga_UART_Read( "FPGA1" , "DES"  , DESA_ID  ,lword(regAddr) , 1 )
        else
            RegRead( DESA_ID , regAddr , 1 , RdWordUpper , outDesRd , "DES_UART_Read" )
        end_if
        if DEBUG>1 then
            DEBUG_DescribeRegisterValue( "DES_HS94" , DR_CTRL3 , outDesRd , "CTRL3: txdp_en, rxdp_lock, link_mode[1:0], locked, error, cmu_locked, x" )
        end_if
    else
        outDesRd = 0xFEEDF00D
    end_if

    if DEBUG>0 then
        dt = snap_timer() - t0
        println(stdout, "WaitForRegister(): ", dt!fu=ms:8:0, " elapsed", "@t", "[FINAL]" )
    end_if


    DEBUG_REG_RW = keep_debug_reg_rw

end_body


function find_Tmon_threshold (startv,stopv,stepv) :   multisite float [2]
--------------------------------------------------------------------------------
--  
in float    :   startv,stopv,stepv

local

  multisite   float             : threshold[2]
  word                          : sites, idx, site,i
  integer                       : idxs
  word list[MAX_SITES]          : active_sites
  multisite lword               : lowword, upperword
  word                          : sitecount  
  multisite float               : Vthreshold_up,Vthreshold_dn   
  multisite float               : TMON_BUS0, TMON_BUS1,DELTA_TMON
  float                         : Vthreshold_min,Vthreshold_max

end_local

body
    active_sites = get_active_sites
    sites = word(len(active_sites))  
-----Search with big step
--    stepv = 1mV
    Vthreshold_up =0.0
    sitecount = 0

     for startv = startv  to stopv  by stepv do 

        set vi16 chan SER_ABUS0 to fv startv  measure V max 3v  i max  300ua clamp imax 500uA  imin -10uA
        wait(0.5ms)
        measure vi16 v on chan  SER_ABUS0 for 10 samples every 10us averaged into TMON_BUS0
        measure vi16 v on chan  SER_ABUS1 for 10 samples every 10us averaged into TMON_BUS1
        DELTA_TMON = TMON_BUS0 - TMON_BUS1

        lowword =  fpga_UART_Read("FPGA1", "DES", SER_ID, 0x09, 1)      
--        lowword =  fpga_UART_Read("FPGA1", "DES", SER_ID, 0x00, 1)   
        for idx = 1 to sites do
            site = active_sites[idx]
            if (lowword[site] & 0x80) == 0x80 and Vthreshold_up[site] ==0.0 then
                Vthreshold_up[site] =  DELTA_TMON[site]
                if sitecount = 0 then
                    Vthreshold_min = Vthreshold_up[site]
                end_if
                sitecount = sitecount + 1                                             ----increase site count                
            end_if 
         end_for           
         if sitecount = sites then
                break

         end_if 

    end_for
-----Search with smaller step 1mV
    stepv = 1mV
    Vthreshold_up =0.0           ----Reset to 0
    sitecount = 0                 ----Reset to 0

    for startv = Vthreshold_min -50mV  to 1.7V by stepv do                             --- start at 50mVstep lower

        set vi16 chan SER_ABUS0 to fv startv  measure V max 3v  i max  300ua clamp imax 500uA  imin -10uA
        wait(500us)
        measure vi16 v on chan  SER_ABUS0 for 10 samples every 10us averaged into TMON_BUS0
        measure vi16 v on chan  SER_ABUS1 for 10 samples every 10us averaged into TMON_BUS1
        DELTA_TMON = TMON_BUS0 - TMON_BUS1    

        lowword =  fpga_UART_Read("FPGA1", "DES", SER_ID, 0x09, 1)      
        for idx = 1 to sites do
            site = active_sites[idx]
            if (lowword[site] & 0x80) == 0x80 and Vthreshold_up[site] ==0.0 then
                Vthreshold_up[site] =  DELTA_TMON[site]
                sitecount = sitecount + 1                                             ----increase site count                
            end_if 
         end_for           
         if sitecount = sites then
                break
         end_if 
    end_for
------Searching other side of threshold
  sitecount = 0
---Find max first 
    for idx = 1 to sites do
        site = active_sites[idx]
        if Vthreshold_up[site] >= Vthreshold_max then
            Vthreshold_max = Vthreshold_up[site]            
        end_if
    end_for    

    for startv = Vthreshold_max + 10mV downto 0.5V by stepv do
--close digital cbit    ABUS_RELAY +  MFP_LT_RELAY

        set vi16 chan SER_ABUS0 to fv startv  measure V max 3v  i max  300ua clamp imax 500uA  imin -10uA
        wait(500us)
        measure vi16 v on chan  SER_ABUS0 for 10 samples every 10us averaged into TMON_BUS0
        measure vi16 v on chan  SER_ABUS1 for 10 samples every 10us averaged into TMON_BUS1
        DELTA_TMON = TMON_BUS0 - TMON_BUS1    

        lowword =  fpga_UART_Read("FPGA1", "DES", SER_ID, 0x09, 1)          
        for idx = 1 to sites do
            site = active_sites[idx]
            if (lowword[site] & 0x80) <> 0x80 and Vthreshold_dn[site] ==0.0 then
                Vthreshold_dn[site] =  DELTA_TMON[site]
                sitecount = sitecount + 1                                             ----increase site count                
            end_if 
         end_for           
         if sitecount = sites then
                break
         end_if 
    end_for    
----- arrange data for return
    for idx = 1 to sites do
        site = active_sites[idx]
        threshold[site,1] =     Vthreshold_up[site]
        threshold[site,2] =     Vthreshold_dn[site]
    end_for    

    wait(0)

    return(threshold)
end_body

function meas_ABUS_SE_V (waitTime , TestMode) : multisite float[4]
-------------------------------------------------------------------------------------------------------------
--  DESCRIPTION
--  Measure single eneded voltage on all MFP/ABUS pins.
-- 
--  Assumes device set in correct mode.
--  Assumes MFP pins are connected to PPMU and setup in FNMV mode.
--
--
--  PASS PARAMETERS:
--  waitTime        -- Wait time between set test mode and measurement
--  TestMode        -- Which test mode to measure (abus_blk = #, abus_page = #)
--
--
--  USAGE:
--  meas_v = meas_ABUS_SE_V ( 1ms , 0x22 )      -- Measure all 4 channels for ABUS block 2 page 2



in float    : waitTime
in lword    : TestMode


local
    multisite float     : meas_v[4]
end_local

body

    -- Change MFP/ABUS pins to FI
    set digital ppmu ABUS_DP_pl to fi 0.0uA measure v max 1.7V            ---4
      wait(500us)
    -- Set test mode
    RegWrite(SER_ID, SR_TEST0, 1, 0x00, TestMode, "SER_UART_Write")      -- abus_blk = #, abus_page = #    SR_TEST0 = 0x3E

    if TestMode = 0x0F then -- TDIODE test  move here otherwise glitch  MT 2/2019
        set digital ppmu SER_GPIO3_RCLKOUT to fi 100uA measure v max 1.7V ---4
    end_if    

    wait(waitTime)

    measure digital ppmu ABUS_DP_pl voltage average 20 delay 10us into meas_v

    -- clear test mode
    set digital ppmu ABUS_DP_pl to fi 0.0uA measure v max 1.7V            ---4

    RegWrite(SER_ID,  SR_TEST0, 1, 0x00, 0x00, "SER_UART_Write")    -- HIZ

--    set digital ppmu ABUS_DP_pl to fv 0V measure i max 1mA
   set digital ppmu ABUS_DP_pl to fv 0V measure i max 2uA

--    set digital ppmu ABUS_DP_pl to fi 0mA measure v max 4V
    return(meas_v)

end_body

procedure RegWriteMultisite(device_id, register, bytes1, data1, bytes2, data2)
-----------------------------------------------------------------------------------------
-- Function allows writing up to 8 Bytes of data to any consecutive register space on the HS84, HS87 and oscillator dnuts
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


--  return (pass)

end_body

function RampVdd( Vio,Pin_Monitor, vddstart,vddstop, stepsize) :  multisite float [2] 
--------------------------------------------------------------------------------
--  
in float                        : Vio, vddstart,vddstop, stepsize
in pin list[1]                  : Pin_Monitor
local
    word list[16]               :  active_sites
    word                        :  sites, idx, site

    float                       : Vdd_Set
    float                       : SearchStart, SearchStop,SearchStep
    multisite float             : Meas_V[1], SetVdd,CapVdd_Trip,Meas_V1[1]
    multisite boolean           : SiteDoneFlag
    integer                     : sitecount,i
    multisite float             : returndata[2]
end_local

body
    active_sites = get_active_sites
    sites = word(len(active_sites))
    if  vddstart > vddstop then   ---- search down
            SearchStart = vddstop
            SearchStop = vddstart
            SearchStep = stepsize * -1.0
    else
            SearchStart = vddstart
            SearchStop = vddstop
            
    end_if
    if vddstart < vddstop then                  --------search up
        for Vdd_Set = vddstart  to vddstop  by stepsize do 
            set hcovi SER_VDD  to fv Vdd_Set   vmax 2.0V measure i max 600ma clamp imax 900mA imin -900mA    
            wait(3ms)
            measure digital ppmu Pin_Monitor voltage average 20 delay 10us into Meas_V
            measure digital ppmu SER_CAPVDD voltage average 20 delay 10us into  Meas_V1

            for idx = 1 to sites do
                site = active_sites[idx]            
                if(( Meas_V [site] > Vio/2.0) and not( SiteDoneFlag[site]))  then   -----pin is high

                    returndata[site,1] = Vdd_Set 
                    returndata[site,2] = Meas_V[site,1]             
                    sitecount = sitecount+ 1
                    SiteDoneFlag[site] = true
                end_if
            end_for
            if word(sitecount) = sites then
                break
            end_if
        end_for
    else
        for Vdd_Set = vddstart downto vddstop  by (stepsize) do 
            set hcovi SER_VDD  to fv Vdd_Set vmax 2.0V measure i max 600ma clamp imax 900mA imin -900mA    
--            set hcovi SER_VDD  to fv 1.15 vmax 2.0V measure i max 600ma clamp imax 900mA imin -900mA    

            wait(3ms)
            measure digital ppmu Pin_Monitor voltage average 20 delay 10us into  Meas_V
            measure digital ppmu SER_CAPVDD voltage average 20 delay 10us into Meas_V1
            for idx = 1 to sites do
                site = active_sites[idx]            
                if(( Meas_V[site] < Vio/2.0) and not( SiteDoneFlag[site]))  then   -----found pin is low
                    returndata[site,1] = Vdd_Set 
                    returndata[site,2] = Meas_V[site,1]             
                    sitecount = sitecount+ 1
                    SiteDoneFlag[site] = true
                end_if
            end_for
            if word(sitecount) = sites then
                break
            end_if
        end_for    
    end_if

    return(returndata)
end_body

function RegWrite_LockTiming(DevId, RegAddr, ByteCnt, DataUpperWord, DataLowerWord, PatternName): multisite boolean
-----------------------------------------------------------------------------------------
-- Function allows writing up to 8 Bytes of data to any consecutive register space on the HS84, HS87 and oscillator dnuts

in word                    : DevId, RegAddr, ByteCnt
in lword                   : DataUpperWord, DataLowerWord
in string[50]              : PatternName     -- pattern to run

local
  word list[MAX_SITES]       : active_sites_local
  word                       : siteidx, idx, sites_local, csite, reg_msb, reg_lsb, ByteOffset, mdata
  word                       : send_word[30]  -- change to lword for dsp send
  multisite word             : ack[16]
  multisite boolean          : pass
  string[3]                  : plab     -- pattern label
  string[8]                  : response
end_local

body
  active_sites_local = get_active_sites()
  sites_local = word(len(active_sites_local))

  plab = "S"+string(ByteCnt)

  if DevId == SER_ID or DevId == DESA_ID or DevId == SER_DNUT_ID then
    reg_msb = ((RegAddr & 16#FF00) >> 8)
    reg_lsb = (RegAddr & 16#FF)
  endif
  
--   if PatternName[5] = "U" OR PatternName[6] = "U" then                -- UART Mode ( dut_uart_write, dut_uart_read, dnut_uart_write, dnut_uart_read )
    
    send_word[1] = 2#101111001   --synch frame 0x79h
    send_word[2] = add_parity_bit(DevId)
    if DevId == 16#80 OR DevId == 16#90 then
      send_word[3] = add_parity_bit(reg_msb)
      send_word[4] = add_parity_bit(reg_lsb)
      send_word[5] = add_parity_bit(ByteCnt)
      ByteOffset = 5
    else 
      send_word[3] = add_parity_bit(RegAddr)
      send_word[4] = add_parity_bit(ByteCnt)
      ByteOffset = 4
    endif
    
    
    for idx=1 to ByteCnt do
      if idx < 5 then
       mdata = word( (DataLowerWord>>(8*lword(idx-1))) & 16#FF)
      else
        mdata = word( (DataUpperWord>>(8*lword(idx-5))) & 16#FF)
      endif  
       send_word[idx+ByteOffset] = add_parity_bit(mdata)
    end_for
      
      
    if DevId == DESA_ID OR DevId == SER_DNUT_ID then --Write to DNUT's (deserializer)
      load     digital reg_send fx1 waveform "DES_UART_WRITE" with send_word
--      enable   digital capture  fx1 waveform "DES_UART_WRITE_CAPTURE"
      enable   digital reg_send fx1 waveform "DES_UART_WRITE"
	    
      execute  digital pattern PatternName at label  plab run to end wait
--       wait for digital capture  fx1 waveform "DES_UART_WRITE_CAPTURE"
--       read     digital capture  fx1 waveform "DES_UART_WRITE_CAPTURE" into ack
	 
    else    -- Write to DUT (serializer)   --WH:FOLLOWUP need a case where DevId != DUT or DNUT1 or DNUT2
      load     digital reg_send fx1 waveform "SER_UART_WRITE" with send_word
--      enable   digital capture  fx1 waveform "SER_UART_WRITE_CAPTURE"
      enable   digital reg_send fx1 waveform "SER_UART_WRITE"
	    
      execute  digital pattern PatternName at label  plab run to end wait --dlog
--      wait for digital capture  fx1 waveform "SER_UART_WRITE_CAPTURE"
--      read     digital capture  fx1 waveform "SER_UART_WRITE_CAPTURE" into ack
    end_if


--     for siteidx=1 to sites_local do
--       csite = active_sites_local[siteidx]
--       pass[csite] = Check_for_ack_frame(ack[csite])
--     end_for


           
  return (pass)

end_body

procedure spi_master(source)
--------------------------------------------------------------------------------
-- This function set SPI master and slave; make sure the communication in I2C mode

in string[8]   : source          -- "SER", "DES"


local lword    : halfclock    
               
body

    halfclock = lword(round(300MHz /(2.0*12MHz)))      -- 850ns to 3.334ns (600kHz to 150MHz)
    if halfclock > 255 then
        halfclock = 255
    end_if
    
    

    ----------------------------------------------------------------
    --  First: _MCU_SER:
    --  FPGA master SPI into SER(DNUT), thru link to DES(DUT), out to FPGA slave
    --  So need to configure SER as the "local" and DES as the "remote"
    ----------------------------------------------------------------

 if source = "DES" then     
 
   -- Setup SER device as Spi Slave 
   fpga_UART_Write("FPGA1", "SER", SER_ID, SR_SPI_0, 3, 16#00E20B)    	
   fpga_UART_Write("FPGA1", "SER", SER_ID, SR_SPI_3, 3, 16#FFFF01)       --- 1tick (3.3ns) delay    
   fpga_UART_Write("FPGA1", "SER", SER_ID, SR_SPI_6, 1, 16#0C)    	--- SS1 out, SS2 out
   fpga_UART_Write("FPGA1", "SER", SER_ID, SR_SPI_7, 1, 16#00)	 	--- clear status  	

   fpga_UART_Write("FPGA1", "SER", SER_ID, SR_SPI_0, 1, 16#0A)	        --- Reset SPI	
   fpga_UART_Write("FPGA1", "SER", SER_ID, SR_SPI_0, 1, 16#0B)	 

   -- Setup DES device as the side with the FPGA-master,
   fpga_UART_Write("FPGA1", "DES", DESA_ID, DR_SPI_0, 3, 16#00E109)	
   fpga_UART_Write("FPGA1", "DES", DESA_ID, DR_SPI_3, 3, 16#FFFF01)    	--- 1tick (3.3ns) delay 	   
   fpga_UART_Write("FPGA1", "DES", DESA_ID, DR_SPI_6, 1, 16#03)	 	--- BufNotEmpty and R1/W0
   fpga_UART_Write("FPGA1", "DES", DESA_ID, DR_SPI_7, 1, 16#00)    	--- Read Only Register for RX and TX overflow and Byte CNT       
  
   fpga_UART_Write("FPGA1", "DES", DESA_ID, DR_SPI_0, 1, 16#08)	        --- Reset SPI 	
   fpga_UART_Write("FPGA1", "DES", DESA_ID, DR_SPI_0, 1, 16#09)	    	
     
 else
 
   fpga_UART_Write("FPGA1", "DES", DESA_ID, 0x05, 1, 16#00)		--- Set SPI_EN=1
   -- Setup SER device as the side with the FPGA-master, 
   fpga_UART_Write("FPGA1", "SER", SER_ID, SR_SPI_0, 3, 16#00E109)    	
   fpga_UART_Write("FPGA1", "SER", SER_ID, SR_SPI_3, 3, 16#707001)
   	  	
   --fpga_UART_Write("FPGA1", "SER", SER_ID, SR_SPI_3, 3, 16#FFFF01)	
   fpga_UART_Write("FPGA1", "SER", SER_ID, SR_SPI_6, 1, 16#03)    		
   
   --- Reset SPI
   fpga_UART_Write("FPGA1", "SER", SER_ID, SR_SPI_0, 1, 16#08)	   	
   fpga_UART_Write("FPGA1", "SER", SER_ID, SR_SPI_0, 1, 16#09)	   	

   -- Setup DES device as Spi slave 
   fpga_UART_Write("FPGA1", "DES", DESA_ID, DR_SPI_0, 3, 16#00E20b)		--- Set SPI_EN=1; SPI_LOC_N[7:2] =0x28 and SPI_BASE_PRIO[1:0] =0x1  
   fpga_UART_Write("FPGA1", "DES", DESA_ID, DR_SPI_3, 3, 16#707001)    	--- Set number of 300MHz clocks to delay to be 1  
   
    
   --fpga_UART_Write("FPGA1", "DES", DESA_ID, DR_SPI_3, 3, 16#FFFF01)    	--- Set number of 300MHz clocks to delay to be 1   
   fpga_UART_Write("FPGA1", "DES", DESA_ID, DR_SPI_6, 1, 16#0C)	 	--- Set BNE_IO_EN=RWN_IO_EN=1 for Slave 
  
   --- Reset SPI
   fpga_UART_Write("FPGA1", "DES", DESA_ID, DR_SPI_0, 1, 16#0A)	   	
   fpga_UART_Write("FPGA1", "DES", DESA_ID, DR_SPI_0, 1, 16#0B)	   	--- Set SPI_EN=1 

 endif


  

end_body


procedure spi_write(add,  data, data1, data2)
--------------------------------------------------------------------------------
-- This function converts a multisite word to a multisite integer
in  lword      : add, data, data1, data2

local lword : id, reset_and_drive
body

   id = add & 0xFFFFF000
   reset_and_drive = (add & 0xFFDF0000) + (1<<20)
--   fpga_write_register("FPGA1", SPI_COMMAND_REG, mslw(0x00100000))     ----Resets FPGA SPI
   fpga_write_register("FPGA1", SPI_COMMAND_REG, mslw(reset_and_drive))        ----Resets FPGA SPI and drives pin
  
   fpga_write_register("FPGA1", SPI_COMMAND_REG, mslw(id+0x1A6))              ---SPI_COMMAND_REG = 0x74  --- 116   
   fpga_write_register("FPGA1", SPI_COMMAND_REG, mslw(add))      
   fpga_write_register("FPGA1", SPI_COMMAND_REG, mslw(id+data))  
   fpga_write_register("FPGA1", SPI_COMMAND_REG, mslw(id+data1))
   fpga_write_register("FPGA1", SPI_COMMAND_REG, mslw(id+data2))
   fpga_write_register("FPGA1", SPI_COMMAND_REG, mslw(id+0x1A7))


end_body
function mslw(data) : multisite lword
--------------------------------------------------------------------------------
-- This function converts a multisite word to a multisite integer
in lword                : data


local

word list[MAX_SITES]   : active_sites_local
word                   : sites_local
word                   : siteidx
word                   : csite
multisite lword        : mslword

end_local


body

    mslword = data
    return (mslword)

end_body

function fpga_read_spi(FPGA, id, reg ) : multisite lword
--------------------------------------------------------------------------------
--  
in string[5]          : FPGA   -- "FPGA1" or "FPGA2"
in word               : reg    -- FPGA register to read from
in lword              : id 
local multisite lword : writeVal1, writeVal2, writeVal3
local multisite lword : writeVal_sum
local word            : dev
local lword           : deassert 
body

     deassert = id --+ 0x1A6
     if FPGA == "FPGA1" then
        dev = 0x00
     elseif FPGA == "FPGA2" then
        dev = 0x40
     endif
       
    fpga_write_register("FPGA1", SPI_COMMAND_REG, mslw(deassert))         -- 1st byte
    fpga_rw_datapair(FPGA_SRC_RD, dev, reg, 0x00, writeVal1)
    
    fpga_write_register("FPGA1", SPI_COMMAND_REG, mslw(deassert))         -- 2nd byte
    fpga_rw_datapair(FPGA_SRC_RD, dev, reg, 0x00, writeVal2)
    
    fpga_write_register("FPGA1", SPI_COMMAND_REG, mslw(deassert))         -- 3rd byte
    fpga_rw_datapair(FPGA_SRC_RD, dev, reg, 0x00, writeVal3)
    fpga_write_register("FPGA1", SPI_COMMAND_REG, mslw(deassert))         --**??++
    
    writeVal_sum =(((writeVal3&0xFF)<<16)+((writeVal2&0xFF)<<8)+ (writeVal1&0xFF))   
    return(writeVal_sum)

end_body






procedure SetSPIClock(spi_freq,spi_master_half_freq,spi_slave)    
--------------------------------------------------------------------------------
--  
---This function set spi bus freq. 
--- as of today only need set master =1/2 freq for 50MHz case. Slave can be run 50MHz clock while master can be run
--- at 25MHz. SPI Master setup time for 50MHz> 13ns, FPGA firmware can not do that yet.  ManTran 6/2018

    in float        : spi_freq
    in integer      : spi_master_half_freq
    in string[5]    : spi_slave


local
    
     float  : SpiFreq
     float  : data
     lword  : WriteData
end_local
    
    
body

        SpiFreq = spi_freq
        data = 300MHz/(2.0*SpiFreq)
                
        WriteData = lword(data)

        fpga_UART_Write("FPGA1", "SER", SER_ID, SR_SPI_4, 1,WriteData )
        fpga_UART_Write("FPGA1", "SER", SER_ID, SR_SPI_5, 1, WriteData)
        fpga_UART_Write("FPGA1", "DES", DESA_ID, DR_SPI_4, 1, WriteData )  ---master and slave same spi bus freq
        fpga_UART_Write("FPGA1", "DES", DESA_ID, DR_SPI_5, 1, WriteData )            
----This section is only set if need spi_master has 1/2 freq of slave( remote site = 1/2 freq)            
        if spi_master_half_freq = 1 then
            if spi_slave = "SER" then 
                fpga_UART_Write("FPGA1", "DES", DESA_ID, DR_SPI_4, 1, WriteData * 2) ---master havs 1/2freq 
                fpga_UART_Write("FPGA1", "DES", DESA_ID, DR_SPI_5, 1, WriteData *2)

            else   -----Des is slave( SER is master)
            
                fpga_UART_Write("FPGA1", "SER", SER_ID, SR_SPI_4, 1, WriteData * 2 )---master havs 1/2freq 
                fpga_UART_Write("FPGA1", "SER", SER_ID, SR_SPI_5, 1, WriteData * 2)
 
            end_if
         end_if                       
end_body

procedure GenerateColorBar1PipeLineX1x4(MipiSpeed,port)
--------------------------------------------------------------------------------
--  
    in  lword   :   MipiSpeed
    in string[5]: port
local

    lword       :  MIPI_SPEED  ---for flexible

end_local

body

    MIPI_SPEED  = 0x20| (MipiSpeed/100000000)


------------------------------------------------Procedure from Ezgi K

------ VID_TX_EN_
    if port = "A" then
        RegWrite(SER_ID,SR_REG2, 1, 0, 0xF3	, "SER_UART_Write" )
        RegWrite(SER_ID,SR_FRONTTOP_9,  1,0, 0x01, "SER_UART_Write" )
        RegWrite(SER_ID,SR_FRONTTOP_0, 1, 0, 0x7C, "SER_UART_Write" )
        RegWrite(SER_ID,SR_MIPI_RX1, 1 , 0,  0x33, "SER_UART_Write" )
        RegWrite(SER_ID,SR_MIPI_RX0, 1, 0,  0x84	, "SER_UART_Write")------------0x86
------- Enable MIPI loopback TX 
        RegWrite(SER_ID,SR_MIPI_LPB0, 1, 0, 0x01, "SER_UART_Write" )
    else
        RegWrite(SER_ID,SR_REG2, 1, 0, 0xF3	, "SER_UART_Write" )
        RegWrite(SER_ID,SR_FRONTTOP_9,  1,0, 0x10, "SER_UART_Write" )
        RegWrite(SER_ID,SR_FRONTTOP_0, 1, 0, 0x71, "SER_UART_Write" )
        RegWrite(SER_ID,SR_MIPI_RX1, 1 , 0,  0x33, "SER_UART_Write" )
        RegWrite(SER_ID,SR_MIPI_RX0, 1, 0,  0x85	, "SER_UART_Write")------------0x86
------- Enable MIPI loopback TX 
        RegWrite(SER_ID,SR_MIPI_LPB0, 1, 0, 0x20, "SER_UART_Write" )    
    end_if
------ Generate COLOR BAR pattern using video timing&pattern generator
    RegWrite(SER_ID,SR_VTX_X_VTX0, 1, 0,  0xe3, "SER_UART_Write" )
    RegWrite(SER_ID,SR_VTX_X_VTX2, 1, 0,  0x0, "SER_UART_Write" )
    RegWrite(SER_ID,SR_VTX_X_VTX3, 1, 0,  0x0, "SER_UART_Write" )
    RegWrite(SER_ID,SR_VTX_X_VTX4, 1, 0,  0x0, "SER_UART_Write" )
    RegWrite(SER_ID,SR_VTX_X_VTX5, 1, 0,  0x0, "SER_UART_Write" )
    RegWrite(SER_ID,SR_VTX_X_VTX6, 1, 0,  0x11, "SER_UART_Write" )
    RegWrite(SER_ID,SR_VTX_X_VTX7, 1, 0,  0x30, "SER_UART_Write" )
    RegWrite(SER_ID,SR_VTX_X_VTX8, 1, 0,  0x25, "SER_UART_Write" )
    RegWrite(SER_ID,SR_VTX_X_VTX9, 1, 0,  0xB2, "SER_UART_Write" )
    RegWrite(SER_ID,SR_VTX_X_VTX10, 1, 0,   0xC8, "SER_UART_Write" )
    RegWrite(SER_ID,SR_VTX_X_VTX11, 1, 0,  0x0, "SER_UART_Write" )
    RegWrite(SER_ID,SR_VTX_X_VTX12, 1, 0,  0x0, "SER_UART_Write" )
    RegWrite(SER_ID,SR_VTX_X_VTX13, 1, 0,   0x1, "SER_UART_Write" )
    RegWrite(SER_ID,SR_VTX_X_VTX14, 1, 0,  0x0, "SER_UART_Write" )
    RegWrite(SER_ID,SR_VTX_X_VTX15, 1, 0,  0x28, "SER_UART_Write" )
    RegWrite(SER_ID,SR_VTX_X_VTX16, 1, 0,  0x08, "SER_UART_Write" )
    RegWrite(SER_ID,SR_VTX_X_VTX17, 1, 0,  0x70, "SER_UART_Write" )
    RegWrite(SER_ID,SR_VTX_X_VTX18, 1, 0,  0x04, "SER_UART_Write" )
    RegWrite(SER_ID,SR_VTX_X_VTX19, 1, 0,  0x65, "SER_UART_Write" )
    RegWrite(SER_ID,SR_VTX_X_VTX20, 1, 0,  0x0, "SER_UART_Write" )
    RegWrite(SER_ID,SR_VTX_X_VTX21, 1, 0,  0x0, "SER_UART_Write" )
    RegWrite(SER_ID,SR_VTX_X_VTX22, 1, 0,  0x2, "SER_UART_Write" )
    RegWrite(SER_ID,SR_VTX_X_VTX23, 1, 0,  0x07, "SER_UART_Write" )
    RegWrite(SER_ID,SR_VTX_X_VTX24, 1, 0,  0x80, "SER_UART_Write" )
    RegWrite(SER_ID,SR_VTX_X_VTX25, 1, 0,  0x01, "SER_UART_Write" )
    RegWrite(SER_ID,SR_VTX_X_VTX26, 1, 0,  0x18, "SER_UART_Write" )
    RegWrite(SER_ID,SR_VTX_X_VTX27, 1, 0,  0x4, "SER_UART_Write" )
    RegWrite(SER_ID,SR_VTX_X_VTX28, 1, 0,  0x38, "SER_UART_Write" )
    RegWrite(SER_ID,SR_VTX_X_VTX29, 1, 0,  0x2, "SER_UART_Write" )
    RegWrite(SER_ID,SR_VTX_X_VTX30, 1, 0,  0x4, "SER_UART_Write" )

----------------------------------- Deserializer --------------------------------	"

---- lane mappings	"
    fpga_UART_Write("FPGA1","DES", DESA_ID,DR_MIPI_PHY3 , 1, 0x4e	)
    fpga_UART_Write("FPGA1","DES", DESA_ID,DR_MIPI_PHY4 , 1, 0xe4	)
----# lane count = 4	
    fpga_UART_Write("FPGA1","DES", DESA_ID,DR_MIPI_TX10_40A , 1, 0x00)
    fpga_UART_Write("FPGA1","DES", DESA_ID,DR_MIPI_TX10_44A , 1, 0xD0)
    fpga_UART_Write("FPGA1","DES", DESA_ID,DR_MIPI_TX10_48A , 1, 0xD0)
    fpga_UART_Write("FPGA1","DES", DESA_ID,DR_MIPI_TX10_4CA , 1, 0x00)
---# CSI rate = 900Mbps per lane	"
    fpga_UART_Write("FPGA1","DES", DESA_ID,DR_BACKTOP22 , 1,  MIPI_SPEED)----29
    fpga_UART_Write("FPGA1","DES", DESA_ID,DR_BACKTOP25 , 1,  MIPI_SPEED)----29
    fpga_UART_Write("FPGA1","DES", DESA_ID,DR_BACKTOP28 , 1,  MIPI_SPEED)----29
    fpga_UART_Write("FPGA1","DES", DESA_ID,DR_BACKTOP31 , 1,  MIPI_SPEED)----29
---- STR_SEL_Y = 0
    fpga_UART_Write("FPGA1","DES", DESA_ID,DR_RX0_0 , 1, 0x1)
    fpga_UART_Write("FPGA1","DES", DESA_ID,DR_RX0_1 , 1, 0x0)
    fpga_UART_Write("FPGA1","DES", DESA_ID,DR_RX0_2 , 1, 0x2)
    fpga_UART_Write("FPGA1","DES", DESA_ID,DR_RX0_3 , 1, 0x3)

  ----delay(80ms)   ------ need for reg102 updata correctly. but if move csi clock output at the end then this delay can be removed MT 6/2018


end_body


procedure GenerateColorBar2PipeLineY1x4(MipiSpeed)
--------------------------------------------------------------------------------
--  
    in  lword   :   MipiSpeed
local

    lword       :  MIPI_SPEED  ---for flexible

end_local

body

    MIPI_SPEED  = 0x20| (MipiSpeed/100000000)


------------------------------------------------Procedure from Ezgi K
--------# VID_TX_EN_X

    RegWrite(SER_ID, SR_REG2,1,0x0, 0xF3	, "SER_UART_Write")
    RegWrite(SER_ID, SR_FRONTTOP_9,1,0x0, 0x21, "SER_UART_Write" )
    RegWrite(SER_ID, SR_FRONTTOP_0,1,0x0, 0x7E, "SER_UART_Write" )
    RegWrite(SER_ID, SR_MIPI_RX1,1,0x0, 0x33, "SER_UART_Write" )
    RegWrite(SER_ID, SR_MIPI_RX0,1,0x0, 0x86, "SER_UART_Write" )
    RegWrite(SER_ID, SR_MIPI_LPB0,1,0x0, 0x21, "SER_UART_Write" )

---------# Generate the 2nd COLOR BAR pattern using video timing&pattern generator (pipe-Y)															
    RegWrite(SER_ID, SR_VTX_Y_VTX0,1,0x0,  0xe3, "SER_UART_Write" )
    RegWrite(SER_ID, SR_VTX_Y_VTX2,1,0x0,  0x0, "SER_UART_Write" )
    RegWrite(SER_ID, SR_VTX_Y_VTX3,1,0x0,  0x0, "SER_UART_Write" )
    RegWrite(SER_ID, SR_VTX_Y_VTX4,1,0x0,  0x0, "SER_UART_Write" )
    RegWrite(SER_ID, SR_VTX_Y_VTX5,1,0x0,  0x0, "SER_UART_Write" )
    RegWrite(SER_ID, SR_VTX_Y_VTX6,1,0x0,  0x11, "SER_UART_Write" )
    RegWrite(SER_ID, SR_VTX_Y_VTX7,1,0x0,  0x30, "SER_UART_Write" )
    RegWrite(SER_ID, SR_VTX_Y_VTX8,1,0x0,  0x25, "SER_UART_Write" )
    RegWrite(SER_ID, SR_VTX_Y_VTX9,1,0x0,  0xB2, "SER_UART_Write" )
    RegWrite(SER_ID, SR_VTX_Y_VTX10,1,0x0,  0xC8, "SER_UART_Write" )
    RegWrite(SER_ID, SR_VTX_Y_VTX11,1,0x0,  0x0, "SER_UART_Write" )
    RegWrite(SER_ID, SR_VTX_Y_VTX12,1,0x0,  0x0, "SER_UART_Write" )
    RegWrite(SER_ID, SR_VTX_Y_VTX13,1,0x0,  0x1, "SER_UART_Write" )
    RegWrite(SER_ID, SR_VTX_Y_VTX14,1,0x0,  0x0, "SER_UART_Write" )
    RegWrite(SER_ID, SR_VTX_Y_VTX15,1,0x0,  0x28, "SER_UART_Write" )
    RegWrite(SER_ID, SR_VTX_Y_VTX16,1,0x0,  0x08, "SER_UART_Write" )
    RegWrite(SER_ID, SR_VTX_Y_VTX17,1,0x0,  0x70, "SER_UART_Write" )
    RegWrite(SER_ID, SR_VTX_Y_VTX18,1,0x0,  0x04, "SER_UART_Write" )
    RegWrite(SER_ID, SR_VTX_Y_VTX19,1,0x0,  0x65, "SER_UART_Write" )
    RegWrite(SER_ID, SR_VTX_Y_VTX20,1,0x0,  0x0, "SER_UART_Write" )
    RegWrite(SER_ID, SR_VTX_Y_VTX21,1,0x0,  0x0, "SER_UART_Write" )
    RegWrite(SER_ID, SR_VTX_Y_VTX22,1,0x0,  0x2, "SER_UART_Write" )
    RegWrite(SER_ID, SR_VTX_Y_VTX23,1,0x0,  0x07, "SER_UART_Write" )
    RegWrite(SER_ID, SR_VTX_Y_VTX24,1,0x0,  0x80, "SER_UART_Write" )
    RegWrite(SER_ID, SR_VTX_Y_VTX25,1,0x0,  0x01, "SER_UART_Write" )
    RegWrite(SER_ID, SR_VTX_Y_VTX26,1,0x0,  0x18, "SER_UART_Write" )
    RegWrite(SER_ID, SR_VTX_Y_VTX27,1,0x0,  0x4, "SER_UART_Write" )
    RegWrite(SER_ID, SR_VTX_Y_VTX28,1,0x0,  0x38, "SER_UART_Write" )
    RegWrite(SER_ID, SR_VTX_Y_VTX29,1,0x0,  0x2, "SER_UART_Write" )
    RegWrite(SER_ID, SR_VTX_Y_VTX30,1,0x0,  0x4, "SER_UART_Write" )

------Setup Des
-----Lane mapping
    fpga_UART_Write("FPGA1","DES", DESA_ID, DR_MIPI_PHY3, 1, 0x4e)
    fpga_UART_Write("FPGA1","DES", DESA_ID, DR_MIPI_PHY4, 1, 0xe4)

------# lane count = 4	
    fpga_UART_Write("FPGA1", "DES", DESA_ID, DR_MIPI_TX10_40A , 1, 0x00 )
    fpga_UART_Write("FPGA1", "DES", DESA_ID, DR_MIPI_TX10_44A , 1, 0xD0 )
    fpga_UART_Write("FPGA1", "DES", DESA_ID, DR_MIPI_TX10_48A , 1, 0xD0 )
    fpga_UART_Write("FPGA1", "DES", DESA_ID, DR_MIPI_TX10_4CA , 1, 0x00 )

---# CSI rate = 900Mbps per lane	"
    fpga_UART_Write("FPGA1","DES", DESA_ID,DR_BACKTOP22 , 1,  MIPI_SPEED)----29
    fpga_UART_Write("FPGA1","DES", DESA_ID,DR_BACKTOP25 , 1,  MIPI_SPEED)----29
    fpga_UART_Write("FPGA1","DES", DESA_ID,DR_BACKTOP28 , 1,  MIPI_SPEED)----29
    fpga_UART_Write("FPGA1","DES", DESA_ID,DR_BACKTOP31 , 1,  MIPI_SPEED)----29
---- STR_SEL_
    fpga_UART_Write("FPGA1","DES", DESA_ID,DR_RX0_0 , 1, 0x2)
    fpga_UART_Write("FPGA1","DES", DESA_ID,DR_RX0_1 , 1, 0x0)
    fpga_UART_Write("FPGA1","DES", DESA_ID,DR_RX0_2 , 1, 0x1)
    fpga_UART_Write("FPGA1","DES", DESA_ID,DR_RX0_3 , 1, 0x3)

  ----delay(80ms)   ------ need for reg102 updata correctly. but if move csi clock output at the end then this delay can be removed MT 6/2018


end_body

procedure SetTestModeFPGA (UsrMode, ResetMode, UsrPat)
in word : UsrMode
in boolean :  ResetMode
in string[32] : UsrPat

local
  lword : Tmv
  multisite lword       : LowerRdWord, UpperRdWord
end_local

body

  Tmv = 16#A0 | lword(UsrMode)

  if Not ResetMode then
    fpga_UART_Write("FPGA1","SER", SER_ID, SR_TEST1, 1,16#A0) 
    fpga_UART_Write("FPGA1","SER", SER_ID, SR_TEST1 , 1, 16#C0) 
    fpga_UART_Write("FPGA1","SER", SER_ID, SR_TEST1 , 1,16#CF ) 
    fpga_UART_Write("FPGA1","SER", SER_ID, SR_TEST1 , 1,Tmv ) 
       
--     RegWrite(SER_ID, SR_TEST1, 1, 0, 16#A0, UsrPat) --DR-ID = 0x3F
--     RegWrite(SER_ID, SR_TEST1, 1, 0, 16#C0, UsrPat)
--     RegWrite(SER_ID, SR_TEST1, 1, 0, 16#CF, UsrPat)
--     RegWrite(SER_ID, SR_TEST1, 1, 0, Tmv,   UsrPat)
  endif

    fpga_UART_Write("FPGA1","SER", SER_ID, SR_TEST1 , 1,  lword(UsrMode) ) 
--   RegWrite(SER_ID, SR_TEST1, 1, 0, lword(UsrMode), UsrPat)
--   RegRead(SER_ID, SR_TEST1 , 1, UpperRdWord, LowerRdWord, "SER_UART_Read")     

end_body

procedure SetupGmslLinkSpeed(TX_SPD,RX_SPD,TP_COAX)
--------------------------------------------------------------------------------
--  
in float            : TX_SPD,RX_SPD
in string[20]       : TP_COAX
local
 lword           : ser_link_speed_code, des_link_speed_code, ser_tx_speed, ser_rx_speed, des_tx_speed, des_rx_speed
end_local

body
----Set SER and DES for coax or tp mode
    if TP_COAX = "TP" then
        RegWrite(SER_ID, SR_CTRL1, 1, 16#0F, 16#0A, "SER_UART_Write")               ---- TP mode SR_CTRL1  =0X11            
        fpga_UART_Write("FPGA1","DES", DESA_ID, DR_CTRL1, 1, 0x0A)                 ---- TP mode   DR_CTRL1 = 0x11       
        open  cbit COAXB_M_RELAY+ CB2_SLDC
    else
        RegWrite(SER_ID, SR_CTRL1, 1, 16#0F, 16#0F, "SER_UART_Write")               ---- coax mode SR_CTRL1  =0X11            
        fpga_UART_Write("FPGA1","DES", DESA_ID, DR_CTRL1, 1, 0x0F)                 ---- coax mode   DR_CTRL1 = 0x11      
        close  cbit COAXB_M_RELAY + CB2_SLDC
    end_if 
    wait(5mS) ---- relays settle
-------Set this to 3 GB
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

----Program link rate

    RegWrite(SER_ID, SR_REG1, 1, 16#00, ser_link_speed_code, "SER_UART_Write")             ---- SER GMSL link speed
    fpga_UART_Write("FPGA1","DES", DESA_ID, DR_REG1, 1,des_link_speed_code  )             ---- DES GMSL link speed


end_body

procedure UART_BITLEN_PT(freq)
--------------------------------------------------------------------------------
in double   : freq

local
 integer    : bit
 lword      : BitLen_PT
 multisite lword    : data
endlocal

body


   -- 1000ns(1MHz)/6.666ns = 150(0x96)    
   bit = integer((1.0/freq)/6.6ns)    
   BitLen_PT = lword(bit)-1
     
   fpga_UART_Write("FPGA1", "SER", SER_ID, SR_UART_PT_0 , 2, BitLen_PT) 
   fpga_UART_Write("FPGA1", "DES", DESA_ID, DR_UART_PT_0, 2, BitLen_PT) 
   
   fpga_UART_Write("FPGA1", "DES", SER_ID, DR_UART_PT_2, 2, BitLen_PT) 
   fpga_UART_Write("FPGA1", "SER", DESA_ID,SR_UART_PT_2 , 2, BitLen_PT) -- 1000ns(1MHz)/6.666ns = 150(0x96)
      
--   fpga_UART_Read("FPGA1", "SER", SER_ID, SR_UART_PT_0 , 2, BitLen_PT)    
--   data =  fpga_UART_Read("FPGA1", "SER", SER_ID, SR_UART_PT_0,  2)   
end_body

function VilVihSearch_RXTX(TestPins, PassVltg, FailVltg, VilVih, VDDIO) : multisite float[2]
--------------------------------------------------------------------------------
-- HS84 device currently only has OR gate logic for vil/vih test modes.  All input pin states are output on the LOCK signal.
-- Due to only having OR gate login the VIH->VIL search uses the digital pins Vil parameter set to a passing High level then lowered during the seep to test the threshold value during the search.
-- VIL search value is obtained by sweeping the input voltage from Max->Min and the Vih search value is obtained by sweeping the input voltage from Min-Max voltage.

in PIN LIST[2]  : TestPins
in float         : FailVltg, PassVltg
in string[32]    : VilVih                   -- Test Type:  "VIL" or "VIH" 
in float         : VDDIO

local
  multisite float   : SearchVal[2]
  multisite boolean : PatRes
  float             : CurVltg, StartVltg, StopVltg, CurStepVltg
  integer           : PinIdx, ResIdx
  word              : CurSite
  float             : StepVltg[3]
  PIN               : CurTestPin
  multisite lword   : lowword, upperword

end_local

body

start_timer()
  active_sites = get_active_sites
  sites = word(len(active_sites))
  SearchVal = 999V
  
--   if PassVltg < FailVltg then
--     StepVltg[1] = 100mV
--     StepVltg[2] = 25mV
--     StepVltg[3] = 2mV
--   else
--     StepVltg[1] = -100mV
--     StepVltg[2] = -25mV
--     StepVltg[3] = -2mV
--   endif

  if VilVih = "VIL" then
    StepVltg[1] = 100mV
    StepVltg[2] = 25mV
    StepVltg[3] = 2mV
  else
    StepVltg[1] = -100mV
    StepVltg[2] = -25mV
    StepVltg[3] = -2mV
  endif
  SearchVal = -999.0  -- Initialize all test pin search values to something that will never pass if the pin is not tested

  for PinIdx = 1 to len(TestPins) do
    CurTestPin = TestPins[PinIdx]
    
    for idx = 1 to sites do
      SearchVal[active_sites[idx], PinIdx] = PassVltg
    endfor  
    
    for ResIdx = 1 to 3 do
      CurStepVltg = StepVltg[ResIdx]

      current_active_sites = get_active_sites() 
      sites = word(len(current_active_sites))
      while sites > 0 do  
        for idx = 1 to sites do
          CurSite = current_active_sites[idx]
            if StepVltg[1] > 0.0 then ---- Search Vil
--                set digital pin CurTestPin on site CurSite levels to vil PassVltg vih VDDIO    -------reset hysterises mt otherwise it will have 0 standard deviation MT 3/2018
            
                set digital pin CurTestPin on site CurSite levels to vil SearchVal[CurSite, PinIdx] vih VDDIO*0.9  
            else
                set digital pin CurTestPin on site CurSite levels to vil 100mV vih SearchVal[CurSite, PinIdx]       
            end_if
            RegWrite(SER_ID, SR_CTRL1, 1, 0, 16#05,"SER_I2C_Write" )
            wait(100us)

        end_for     
--        set digital pin SER_GPIO_PWDNB  on site CurSite levels to vil 0
--set digital pin CurTestPin on site CurSite levels to vil 1.225
        RegRead(SER_ID, SR_CTRL1, 1, upperword, lowword,"SER_I2C_Read")
        
--        execute digital pattern PatternName at label StartLabel into PatRes

        for idx = 1 to sites do
          if  lowword[current_active_sites[idx]] <> 0x5 then
            deactivate site current_active_sites[idx]
            SearchVal[CurSite, PinIdx] = SearchVal[CurSite, PinIdx] - CurStepVltg  -- Reset force voltage back to passing range

          else
            SearchVal[CurSite, PinIdx] = SearchVal[CurSite, PinIdx] + CurStepVltg
            if SearchVal[CurSite, PinIdx] > VDDIO or SearchVal[CurSite, PinIdx] < 0.0V then
              deactivate site CurSite
            endif
          endif
        endfor
        current_active_sites = get_active_sites() 
        sites = word(len(current_active_sites))
      end_while
  
      activate site active_sites
      sites = word(len(active_sites))

     set digital pin CurTestPin vil 0.1V vih VDDIO*0.9
    end_for
--    set digital pin TestPins modes to comparator enable all fails

  endfor

  activate site active_sites

  return(SearchVal)

end_body

function Lmn_Search_mod1(TestPins, Starti, Stopi, Resolution, Reg_Read,Cmp_val, Dir,LMN): multisite float
--------------------------------------------------------------------------------
--  
in pin list[5]        : TestPins
in float              : Starti, Stopi, Resolution
in string[5]          : Dir    -- "UP" or "DOWN"
in word               : Reg_Read
in lword              : Cmp_val 
in word               : LMN --- which lmn is testing 
local
  float           : Iramp, max_irange, StepSize1
  multisite float : Isrch
  word            : CurSite
  PIN LIST[1]     : MeasPin
  multisite lword : read_bit_cmp  
  word             : site, idx, sites  
endlocal

body
  active_sites = get_active_sites()
  sites = word(len(active_sites))
  Isrch = -999uA
  RdWordLower =255
  MeasPin[1] = TestPins[1]
  
  current_active_sites = get_active_sites
  sites = word(len(current_active_sites))
  if abs(Starti) > 19.5 uA or abs(Stopi) > 19.5 uA then
    max_irange = 200uA
  else
    max_irange = 20uA
  endif  
    
   StepSize1 = 0.2uA
  if Dir == "UP" then          
------With coarse step size
 
    for Iramp= Starti to Stopi by StepSize1 do
        connect digital ppmu TestPins to fi Iramp imax max_irange measure v max 2V  -----500ua
        wait(200uS)
        RegRead(SER_ID, Reg_Read, 1, RdWordUpper,RdWordLower, "SER_UART_Read")
        if LMN = 0 or LMN = 2 then --- take  LSB bit to compare
            read_bit_cmp = RdWordLower & 0xF
        else --- lmn1 and lmn3 take 4 msb
            read_bit_cmp = ((RdWordLower & 0xF0) >> 4)
        end_if 
        for idx = 1 to sites do
            CurSite = current_active_sites[idx]
            if read_bit_cmp [CurSite] = Cmp_val  then
                Isrch[CurSite] = Iramp
                deactivate site CurSite
            end_if
        end_for
        current_active_sites = get_active_sites
        sites = word(len(current_active_sites))
        if sites == 0 then 
            break
        endif 
    end_for
--------- repeat for fine stepsize
       activate site active_sites
       sites = word(len(active_sites))
       current_active_sites = get_active_sites       
----Find the smallest one of all previous current
        for idx = 1 to sites do
            site = active_sites[idx] 
            if idx = 1 then 
                 Starti = Isrch[site]
            elseif      Starti > Isrch[site] then
                Isrch[site] = Starti
            end_if
         end_for       

------With smaller step size
    Starti = Starti - StepSize1
    current_active_sites = get_active_sites
    for Iramp= Starti to Stopi by Resolution do
        connect digital ppmu TestPins to fi Iramp imax max_irange measure v max 2V  -----500ua
        wait(200uS)
        RegRead(SER_ID, Reg_Read, 1, RdWordUpper,RdWordLower, "SER_UART_Read")
        if LMN = 0 or LMN = 2 then --- take  LSB bit to compare
            read_bit_cmp = RdWordLower & 0xF
        else --- lmn1 and lmn3 take 4 msb
            read_bit_cmp = ((RdWordLower & 0xF0) >> 4)
        end_if 
        for idx = 1 to sites do
            CurSite = current_active_sites[idx]
            if read_bit_cmp [CurSite] = Cmp_val  then
                Isrch[CurSite] = Iramp
                deactivate site CurSite
            end_if
        end_for
        current_active_sites = get_active_sites
        sites = word(len(current_active_sites))
        if sites == 0 then 
            break
        endif 
    end_for                

------------------end finer step
  elseif Dir == "DOWN" then   
-----Coarse  stepsize
        for Iramp= Starti downto Stopi by StepSize1 do
            set digital ppmu TestPins to fi Iramp imax max_irange measure v max 2V
            RegRead(SER_ID, Reg_Read, 1, RdWordUpper,RdWordLower, "SER_UART_Read")
            wait(200uS)
            if LMN = 0 or LMN = 2 then --- take  LSB bit to compare
                read_bit_cmp = RdWordLower & 0xF
            else --- lmn1 and lmn3 take 4 msb
                read_bit_cmp = ((RdWordLower & 0xF0) >> 4)
            end_if       
            for idx = 1 to sites do
                CurSite = current_active_sites[idx]
                if  read_bit_cmp[CurSite] = Cmp_val then
                    Isrch[CurSite] = Iramp
                    deactivate site CurSite
                end_if
            end_for
            current_active_sites = get_active_sites
            sites = word(len(current_active_sites))
            if sites == 0 then 
                break
            endif 
        end_for
------ find the max value among the sites
--------- repeat for fine stepsize
       activate site active_sites
       sites = word(len(active_sites))

----Find the bigges one of all previous current
        for idx = 1 to sites do
            site = active_sites[idx] 
            if idx = 1 then 
               Starti = Isrch[site]
            elseif      Starti < Isrch[site] then
                Isrch[site] = Starti
            end_if
         end_for       

-----Search with  finest step size
        Starti = Starti + StepSize1
        current_active_sites = get_active_sites
        for Iramp= Starti downto Stopi by Resolution do
            set digital ppmu TestPins to fi Iramp imax max_irange measure v max 2V
            RegRead(SER_ID, Reg_Read, 1, RdWordUpper,RdWordLower, "SER_UART_Read")
            wait(200uS)
            if LMN = 0 or LMN = 2 then --- take  LSB bit to compare
                read_bit_cmp = RdWordLower & 0xF
            else --- lmn1 and lmn3 take 4 msb
                read_bit_cmp = ((RdWordLower & 0xF0) >> 4)
            end_if       
            for idx = 1 to sites do
                CurSite = current_active_sites[idx]
                if  read_bit_cmp[CurSite] = Cmp_val then
                    Isrch[CurSite] = Iramp
                    deactivate site CurSite
                end_if
            end_for
            current_active_sites = get_active_sites
            sites = word(len(current_active_sites))
            if sites == 0 then 
                break
            endif 
        end_for

----end of smallest search loop

  endif



  activate site active_sites
  set digital ppmu TestPins to fi 0uA imax 20ua measure v max 2V

  return(Isrch)
end_body

function msfloat(data) : multisite float
--------------------------------------------------------------------------------
-- This function converts float to a multisite float
in float     : data


local

word list[MAX_SITES]   : active_sites_local
word                   : sites_local
word                   : siteidx
word                   : csite
multisite float      : msint

end_local


body


    active_sites_local = get_active_sites()
    sites_local = word(len(active_sites_local))


    for siteidx =1 to sites_local do
        csite = active_sites_local[siteidx]
	msint[csite] = data
    end_for
    
    
    return (msint)


end_body
procedure GenerateColorBar1PipeLineX1x4_1188Mbps(port)
--------------------------------------------------------------------------------
--  
in string[2]    : port
local

    lword       :  MIPI_SPEED  ---for flexible

end_local

body




------------------------------------------------Procedure from Ezgi K

------------------------------------------------Procedure from Ezgi K

------ VID_TX_EN_

        RegWrite(SER_ID,SR_REG2, 1, 0, 0xF3	, "SER_UART_Write" )
     if port = "A" then    
        RegWrite(SER_ID,SR_FRONTTOP_9,  1,0, 0x01, "SER_UART_Write" )
        RegWrite(SER_ID,SR_FRONTTOP_0, 1, 0, 0x7C, "SER_UART_Write" )
        RegWrite(SER_ID,SR_MIPI_RX1, 1 , 0,  0x33, "SER_UART_Write" )

        RegWrite(SER_ID,SR_MIPI_RX0, 1, 0,  0x84	, "SER_UART_Write")----0x86
------- Enable MIPI loopback TX 
        RegWrite(SER_ID,SR_MIPI_LPB0, 1, 0, 0x01, "SER_UART_Write" )
     
     else
        RegWrite(SER_ID,SR_FRONTTOP_9,  1,0, 0x10, "SER_UART_Write" )
        RegWrite(SER_ID,SR_FRONTTOP_0, 1, 0, 0x71, "SER_UART_Write" )
        RegWrite(SER_ID,SR_MIPI_RX1, 1 , 0,  0x33, "SER_UART_Write" )
        RegWrite(SER_ID,SR_MIPI_RX0, 1, 0,  0x85, "SER_UART_Write")----0x86
------- Enable MIPI loopback TX 
        RegWrite(SER_ID,SR_MIPI_LPB0, 1, 0, 0x20, "SER_UART_Write" )
     end_if        
     
------ Generate COLOR BAR pattern using video timing&pattern generator(2560x1080) Egzi 1/14/2019
        RegWrite(SER_ID,SR_VTX_X_VTX0,  1, 0, 0xE3,   "SER_UART_Write" )
        RegWrite(SER_ID,SR_VTX_X_VTX2,  1, 0, 0x00,  "SER_UART_Write" )
        RegWrite(SER_ID,SR_VTX_X_VTX3,  1, 0, 0x00,  "SER_UART_Write" )
        RegWrite(SER_ID,SR_VTX_X_VTX4,  1, 0, 0x00,  "SER_UART_Write" )
        RegWrite(SER_ID,SR_VTX_X_VTX5,  1, 0, 0x00,  "SER_UART_Write" )
        RegWrite(SER_ID,SR_VTX_X_VTX6,  1, 0, 0x3A,   "SER_UART_Write" )
        RegWrite(SER_ID,SR_VTX_X_VTX7,  1, 0, 0x98,   "SER_UART_Write" )
        RegWrite(SER_ID,SR_VTX_X_VTX8,  1, 0, 0x32,   "SER_UART_Write" )
        RegWrite(SER_ID,SR_VTX_X_VTX9,  1, 0, 0x20,   "SER_UART_Write" )
        RegWrite(SER_ID,SR_VTX_X_VTX10, 1, 0, 0x08,   "SER_UART_Write" )
        RegWrite(SER_ID,SR_VTX_X_VTX11, 1, 0, 0x00,  "SER_UART_Write" )
        RegWrite(SER_ID,SR_VTX_X_VTX12, 1, 0, 0x00,  "SER_UART_Write" )
        RegWrite(SER_ID,SR_VTX_X_VTX13, 1, 0, 0x00,  "SER_UART_Write" )
        RegWrite(SER_ID,SR_VTX_X_VTX14, 1, 0, 0x00,  "SER_UART_Write" )
        RegWrite(SER_ID,SR_VTX_X_VTX15, 1, 0, 0x2C,   "SER_UART_Write" )
        RegWrite(SER_ID,SR_VTX_X_VTX16, 1, 0, 0x0B,   "SER_UART_Write" )
        RegWrite(SER_ID,SR_VTX_X_VTX17, 1, 0, 0x8C,   "SER_UART_Write" )
        RegWrite(SER_ID,SR_VTX_X_VTX18, 1, 0, 0x04,   "SER_UART_Write" )
        RegWrite(SER_ID,SR_VTX_X_VTX19, 1, 0, 0x4C,   "SER_UART_Write" )
        RegWrite(SER_ID,SR_VTX_X_VTX20, 1, 0, 0x00,  "SER_UART_Write" )
        RegWrite(SER_ID,SR_VTX_X_VTX21, 1, 0, 0xBC,  "SER_UART_Write" )
        RegWrite(SER_ID,SR_VTX_X_VTX22, 1, 0, 0x40,  "SER_UART_Write" )
        RegWrite(SER_ID,SR_VTX_X_VTX23, 1, 0, 0x0A,   "SER_UART_Write" )
        RegWrite(SER_ID,SR_VTX_X_VTX24, 1, 0, 0x00,   "SER_UART_Write" )
        RegWrite(SER_ID,SR_VTX_X_VTX25, 1, 0, 0x01,   "SER_UART_Write" )
        RegWrite(SER_ID,SR_VTX_X_VTX26, 1, 0, 0xB8,   "SER_UART_Write" )
        RegWrite(SER_ID,SR_VTX_X_VTX27, 1, 0, 0x04,  "SER_UART_Write" )
        RegWrite(SER_ID,SR_VTX_X_VTX28, 1, 0, 0x38,   "SER_UART_Write" )
        RegWrite(SER_ID,SR_VTX_X_VTX29, 1, 0, 0x2 ,  "SER_UART_Write" )
        RegWrite(SER_ID,SR_VTX_X_VTX30, 1, 0, 0x4 ,  "SER_UART_Write" )

----------------------------------- Deserializer --------------------------------	"

---- lane mappings	"
        fpga_UART_Write("FPGA1","DES", DESA_ID,DR_MIPI_PHY3 , 1, 0x4e	)
        fpga_UART_Write("FPGA1","DES", DESA_ID,DR_MIPI_PHY4 , 1, 0xe4	)
----# lane count = 4	
        fpga_UART_Write("FPGA1","DES", DESA_ID,DR_MIPI_TX10_40A , 1, 0x00)
        fpga_UART_Write("FPGA1","DES", DESA_ID,DR_MIPI_TX10_44A , 1, 0xD0)
        fpga_UART_Write("FPGA1","DES", DESA_ID,DR_MIPI_TX10_48A , 1, 0xD0)
        fpga_UART_Write("FPGA1","DES", DESA_ID,DR_MIPI_TX10_4CA , 1, 0x00)

---- STR_SEL_Y = 0
        fpga_UART_Write("FPGA1","DES", DESA_ID,DR_RX0_0 , 1, 0x1)
        fpga_UART_Write("FPGA1","DES", DESA_ID,DR_RX0_1 , 1, 0x0)
        fpga_UART_Write("FPGA1","DES", DESA_ID,DR_RX0_2 , 1, 0x2)
        fpga_UART_Write("FPGA1","DES", DESA_ID,DR_RX0_3 , 1, 0x3)

------# Internal Datatype routing
-----# Send RGB888 Frame Start and Frame End in PIPE X to MIPI Port A (phy1)
    
        fpga_UART_Write("FPGA1","DES", DESA_ID, 0x040B  , 1,  0x07 )
        fpga_UART_Write("FPGA1","DES", DESA_ID, 0x042D  , 1,  0x55 )

-----# RAW16 Mapping
        fpga_UART_Write("FPGA1","DES", DESA_ID, 0x040D  , 1,  0x24 )
        fpga_UART_Write("FPGA1","DES", DESA_ID, 0x040E  , 1,  0x24 )

-----# Frame Start Mapping	
        fpga_UART_Write("FPGA1","DES", DESA_ID, 0x040F  , 1, 0x00  )
        fpga_UART_Write("FPGA1","DES", DESA_ID, 0x0410  , 1, 0x00  )

----# Frame End Mapping
        fpga_UART_Write("FPGA1","DES", DESA_ID, 0x0411  , 1, 0x01  )
        fpga_UART_Write("FPGA1","DES", DESA_ID, 0x0412  , 1, 0x01  )

    if port = "A" then
---# CSI rate = 1188Mbps per lane	"
        fpga_UART_Write("FPGA1","DES", DESA_ID, 0x1d00 , 1,  0xf4 )
        fpga_UART_Write("FPGA1","DES", DESA_ID, 0x320  , 1,  0x00 )---
        fpga_UART_Write("FPGA1","DES", DESA_ID, 0x31e  , 1,  0x52 )
        fpga_UART_Write("FPGA1","DES", DESA_ID, 0x330  , 1,  0x84 )
        fpga_UART_Write("FPGA1","DES", DESA_ID, 0x1d00 , 1,  0xf5 )
        fpga_UART_Write("FPGA1","DES", DESA_ID, 0x1d03 , 1,  0x12 )
        fpga_UART_Write("FPGA1","DES", DESA_ID, 0x1d07 , 1,  0x84 )
        fpga_UART_Write("FPGA1","DES", DESA_ID, 0x1d08 , 1,  0x2f )
        fpga_UART_Write("FPGA1","DES", DESA_ID, 0x1d09 , 1,  0x00 )
        fpga_UART_Write("FPGA1","DES", DESA_ID, 0x1d0A , 1,  0x91 )
        fpga_UART_Write("FPGA1","DES", DESA_ID, 0x1d0B , 1,  0xBF )
 
     else  ---- port b 
-----# channel B
        fpga_UART_Write("FPGA1","DES", DESA_ID, 0x1e00 , 1,  0xf4 )
        fpga_UART_Write("FPGA1","DES", DESA_ID, 0x323  , 1,  0x00 )
        fpga_UART_Write("FPGA1","DES", DESA_ID, 0x321  , 1,  0x52 )
        fpga_UART_Write("FPGA1","DES", DESA_ID, 0x330  , 1,  0x84 )
        fpga_UART_Write("FPGA1","DES", DESA_ID, 0x1e00 , 1,  0xf5 )
        fpga_UART_Write("FPGA1","DES", DESA_ID, 0x1e03 , 1,  0x12 )
        fpga_UART_Write("FPGA1","DES", DESA_ID, 0x1e07 , 1,  0x84 )
        fpga_UART_Write("FPGA1","DES", DESA_ID, 0x1e08 , 1,  0x2f )
        fpga_UART_Write("FPGA1","DES", DESA_ID, 0x1e09 , 1,  0x00 )
        fpga_UART_Write("FPGA1","DES", DESA_ID, 0x1e0a , 1,  0x91 )
        fpga_UART_Write("FPGA1","DES", DESA_ID, 0x1e0b , 1,  0xBF )
    end_if

end_body


procedure GenerateColorBarPipeLine2x4_1188
--------------------------------------------------------------------------------
--  

local

    lword       :  MIPI_SPEED  ---for flexible

end_local

body


------------------------------------------------Procedure from Ezgi K
--------# VID_TX_EN_X Y	Z	"U = 1	"

    RegWrite(SER_ID, SR_REG2,1,      0x0, 0xF3	, "SER_UART_Write")
---# START_PORT_AX = 1	 START_PORT_BZ = 1	" others are 0	"	
    RegWrite(SER_ID, SR_FRONTTOP_9,1,0x0, 0x41, "SER_UART_Write" )
---- # CLK_SEL_X = 0	 CLK_SEL_Z = 1	
    RegWrite(SER_ID, SR_FRONTTOP_0,1,0x0, 0x7C, "SER_UART_Write" )
----Lane count
    RegWrite(SER_ID, SR_MIPI_RX1,1,  0x0, 0x33, "SER_UART_Write" )
----# phy_config = 6 (2x4	 MIPI port-A and port-B)  	 invert_CSI_mode = 1	
    RegWrite(SER_ID, SR_MIPI_RX0,1,  0x0, 0x86, "SER_UART_Write" )
---Enable loopback
    RegWrite(SER_ID, SR_MIPI_LPB0,1, 0x0, 0x21, "SER_UART_Write" )

-----
------ Generate COLOR BAR pattern using video timing&pattern generator(2560x1080) Egzi 1/14/2019
    RegWrite(SER_ID,SR_VTX_X_VTX0,  1, 0, 0xE3,   "SER_UART_Write" )
    RegWrite(SER_ID,SR_VTX_X_VTX2,  1, 0, 0x00,  "SER_UART_Write" )
    RegWrite(SER_ID,SR_VTX_X_VTX3,  1, 0, 0x00,  "SER_UART_Write" )
    RegWrite(SER_ID,SR_VTX_X_VTX4,  1, 0, 0x00,  "SER_UART_Write" )
    RegWrite(SER_ID,SR_VTX_X_VTX5,  1, 0, 0x00,  "SER_UART_Write" )
    RegWrite(SER_ID,SR_VTX_X_VTX6,  1, 0, 0x3A,   "SER_UART_Write" )
    RegWrite(SER_ID,SR_VTX_X_VTX7,  1, 0, 0x98,   "SER_UART_Write" )
    RegWrite(SER_ID,SR_VTX_X_VTX8,  1, 0, 0x32,   "SER_UART_Write" )
    RegWrite(SER_ID,SR_VTX_X_VTX9,  1, 0, 0x20,   "SER_UART_Write" )
    RegWrite(SER_ID,SR_VTX_X_VTX10, 1, 0, 0x08,   "SER_UART_Write" )
    RegWrite(SER_ID,SR_VTX_X_VTX11, 1, 0, 0x00,  "SER_UART_Write" )
    RegWrite(SER_ID,SR_VTX_X_VTX12, 1, 0, 0x00,  "SER_UART_Write" )
    RegWrite(SER_ID,SR_VTX_X_VTX13, 1, 0, 0x00,  "SER_UART_Write" )
    RegWrite(SER_ID,SR_VTX_X_VTX14, 1, 0, 0x00,  "SER_UART_Write" )
    RegWrite(SER_ID,SR_VTX_X_VTX15, 1, 0, 0x2C,   "SER_UART_Write" )
    RegWrite(SER_ID,SR_VTX_X_VTX16, 1, 0, 0x0B,   "SER_UART_Write" )
    RegWrite(SER_ID,SR_VTX_X_VTX17, 1, 0, 0x8C,   "SER_UART_Write" )
    RegWrite(SER_ID,SR_VTX_X_VTX18, 1, 0, 0x04,   "SER_UART_Write" )
    RegWrite(SER_ID,SR_VTX_X_VTX19, 1, 0, 0x4C,   "SER_UART_Write" )
    RegWrite(SER_ID,SR_VTX_X_VTX20, 1, 0, 0x00,  "SER_UART_Write" )
    RegWrite(SER_ID,SR_VTX_X_VTX21, 1, 0, 0xBC,  "SER_UART_Write" )
    RegWrite(SER_ID,SR_VTX_X_VTX22, 1, 0, 0x40,  "SER_UART_Write" )
    RegWrite(SER_ID,SR_VTX_X_VTX23, 1, 0, 0x0A,   "SER_UART_Write" )
    RegWrite(SER_ID,SR_VTX_X_VTX24, 1, 0, 0x00,   "SER_UART_Write" )
    RegWrite(SER_ID,SR_VTX_X_VTX25, 1, 0, 0x01,   "SER_UART_Write" )
    RegWrite(SER_ID,SR_VTX_X_VTX26, 1, 0, 0xB8,   "SER_UART_Write" )
    RegWrite(SER_ID,SR_VTX_X_VTX27, 1, 0, 0x04,  "SER_UART_Write" )
    RegWrite(SER_ID,SR_VTX_X_VTX28, 1, 0, 0x38,   "SER_UART_Write" )
    RegWrite(SER_ID,SR_VTX_X_VTX29, 1, 0, 0x2 ,  "SER_UART_Write" )
    RegWrite(SER_ID,SR_VTX_X_VTX30, 1, 0, 0x4 ,  "SER_UART_Write" )



---------# Generate COLOR BAR pattern using video timing&pattern generator (2560x1080) on pipe-Z
														
    RegWrite(SER_ID, SR_VTX_Z_VTX0,1 ,0x0,  0xE3, "SER_UART_Write" )
    RegWrite(SER_ID, SR_VTX_Z_VTX2,1 ,0x0,  0x00, "SER_UART_Write" )
    RegWrite(SER_ID, SR_VTX_Z_VTX3,1 ,0x0,  0x00, "SER_UART_Write" )
    RegWrite(SER_ID, SR_VTX_Z_VTX4,1 ,0x0,  0x00, "SER_UART_Write" )
    RegWrite(SER_ID, SR_VTX_Z_VTX5,1 ,0x0,  0x00, "SER_UART_Write" )
    RegWrite(SER_ID, SR_VTX_Z_VTX6,1 ,0x0,  0x3A, "SER_UART_Write" )
    RegWrite(SER_ID, SR_VTX_Z_VTX7,1 ,0x0,  0x98, "SER_UART_Write" )
    RegWrite(SER_ID, SR_VTX_Z_VTX8,1 ,0x0,  0x32, "SER_UART_Write" )
    RegWrite(SER_ID, SR_VTX_Z_VTX9,1 ,0x0,  0x20, "SER_UART_Write" )
    RegWrite(SER_ID, SR_VTX_Z_VTX10,1,0x0,  0x08, "SER_UART_Write" )
    RegWrite(SER_ID, SR_VTX_Z_VTX11,1,0x0,  0x00, "SER_UART_Write" )
    RegWrite(SER_ID, SR_VTX_Z_VTX12,1,0x0,  0x00, "SER_UART_Write" )
    RegWrite(SER_ID, SR_VTX_Z_VTX13,1,0x0,  0x00, "SER_UART_Write" )
    RegWrite(SER_ID, SR_VTX_Z_VTX14,1,0x0,  0x00, "SER_UART_Write" )
    RegWrite(SER_ID, SR_VTX_Z_VTX15,1,0x0,  0x2C, "SER_UART_Write" )
    RegWrite(SER_ID, SR_VTX_Z_VTX16,1,0x0,  0x0B, "SER_UART_Write" )
    RegWrite(SER_ID, SR_VTX_Z_VTX17,1,0x0,  0x8C, "SER_UART_Write" )
    RegWrite(SER_ID, SR_VTX_Z_VTX18,1,0x0,  0x04, "SER_UART_Write" )
    RegWrite(SER_ID, SR_VTX_Z_VTX19,1,0x0,  0x4C, "SER_UART_Write" )
    RegWrite(SER_ID, SR_VTX_Z_VTX20,1,0x0,  0x00, "SER_UART_Write" )
    RegWrite(SER_ID, SR_VTX_Z_VTX21,1,0x0,  0xBC, "SER_UART_Write" )
    RegWrite(SER_ID, SR_VTX_Z_VTX22,1,0x0,  0x40, "SER_UART_Write" )
    RegWrite(SER_ID, SR_VTX_Z_VTX23,1,0x0,  0x0A, "SER_UART_Write" )
    RegWrite(SER_ID, SR_VTX_Z_VTX24,1,0x0,  0x00, "SER_UART_Write" )
    RegWrite(SER_ID, SR_VTX_Z_VTX25,1,0x0,  0x01, "SER_UART_Write" )
    RegWrite(SER_ID, SR_VTX_Z_VTX26,1,0x0,  0xB8, "SER_UART_Write" )
    RegWrite(SER_ID, SR_VTX_Z_VTX27,1,0x0,  0x04, "SER_UART_Write" )
    RegWrite(SER_ID, SR_VTX_Z_VTX28,1,0x0,  0x38, "SER_UART_Write" )
    RegWrite(SER_ID, SR_VTX_Z_VTX29,1,0x0,  0x2 , "SER_UART_Write" )
    RegWrite(SER_ID, SR_VTX_Z_VTX30,1,0x0,  0x4 , "SER_UART_Write" )
------Setup Des
-----Lane mapping
    fpga_UART_Write("FPGA1","DES", DESA_ID, DR_MIPI_PHY3, 1, 0x4e)
    fpga_UART_Write("FPGA1","DES", DESA_ID, DR_MIPI_PHY4, 1, 0xe4)

------# lane count = 4	
    fpga_UART_Write("FPGA1", "DES", DESA_ID, DR_MIPI_TX10_40A , 1, 0x00 )
    fpga_UART_Write("FPGA1", "DES", DESA_ID, DR_MIPI_TX10_44A , 1, 0xD0 )
    fpga_UART_Write("FPGA1", "DES", DESA_ID, DR_MIPI_TX10_48A , 1, 0xD0 )
    fpga_UART_Write("FPGA1", "DES", DESA_ID, DR_MIPI_TX10_4CA , 1, 0x00 )

----  STR_SEL's default
    fpga_UART_Write("FPGA1","DES", DESA_ID,DR_RX0_0 , 1, 0x0)
    fpga_UART_Write("FPGA1","DES", DESA_ID,DR_RX0_1 , 1, 0x1)
    fpga_UART_Write("FPGA1","DES", DESA_ID,DR_RX0_2 , 1, 0x2)
    fpga_UART_Write("FPGA1","DES", DESA_ID,DR_RX0_3 , 1, 0x3)

------# Internal Datatype routing
-----# Send RGB888 Frame Start and Frame End in PIPE X to MIPI Port A (phy1)
    fpga_UART_Write("FPGA1","DES", DESA_ID, 0x040B  , 1,  0x07 )
    fpga_UART_Write("FPGA1","DES", DESA_ID, 0x042D  , 1,  0x55 )
-----# RAW16 Mapping
    fpga_UART_Write("FPGA1","DES", DESA_ID, 0x040D  , 1,  0x24 )
    fpga_UART_Write("FPGA1","DES", DESA_ID, 0x040E  , 1,  0x24 )

-----# Frame Start Mapping	
    fpga_UART_Write("FPGA1","DES", DESA_ID, 0x040F  , 1, 0x00  )
    fpga_UART_Write("FPGA1","DES", DESA_ID, 0x0410  , 1, 0x00  )

----# Frame End Mapping
    fpga_UART_Write("FPGA1","DES", DESA_ID, 0x0411  , 1, 0x01  )
    fpga_UART_Write("FPGA1","DES", DESA_ID, 0x0412  , 1, 0x01  )

---# CSI rate = 1188Mbps per lane	"
    fpga_UART_Write("FPGA1","DES", DESA_ID, 0x1d00 , 1,  0xf4 )
    fpga_UART_Write("FPGA1","DES", DESA_ID, 0x320  , 1,  0x00 )
    fpga_UART_Write("FPGA1","DES", DESA_ID, 0x31e  , 1,  0x52 )
    fpga_UART_Write("FPGA1","DES", DESA_ID, 0x330  , 1,  0x84 )
    fpga_UART_Write("FPGA1","DES", DESA_ID, 0x1d00 , 1,  0xf5 )
    fpga_UART_Write("FPGA1","DES", DESA_ID, 0x1d03 , 1,  0x12 )
    fpga_UART_Write("FPGA1","DES", DESA_ID, 0x1d07 , 1,  0x84 )
    fpga_UART_Write("FPGA1","DES", DESA_ID, 0x1d08 , 1,  0x2f )
    fpga_UART_Write("FPGA1","DES", DESA_ID, 0x1d09 , 1,  0x00 )
    fpga_UART_Write("FPGA1","DES", DESA_ID, 0x1d0A , 1,  0x91 )
    fpga_UART_Write("FPGA1","DES", DESA_ID, 0x1d0B , 1,  0xBF )

-----# channel B
    fpga_UART_Write("FPGA1","DES", DESA_ID, 0x1e00 , 1,  0xf4 )
    fpga_UART_Write("FPGA1","DES", DESA_ID, 0x323  , 1,  0x00 )
    fpga_UART_Write("FPGA1","DES", DESA_ID, 0x321  , 1,  0x52 )
    fpga_UART_Write("FPGA1","DES", DESA_ID, 0x330  , 1,  0x84 )
    fpga_UART_Write("FPGA1","DES", DESA_ID, 0x1e00 , 1,  0xf5 )
    fpga_UART_Write("FPGA1","DES", DESA_ID, 0x1e03 , 1,  0x12 )
    fpga_UART_Write("FPGA1","DES", DESA_ID, 0x1e07 , 1,  0x84 )
    fpga_UART_Write("FPGA1","DES", DESA_ID, 0x1e08 , 1,  0x2f )
    fpga_UART_Write("FPGA1","DES", DESA_ID, 0x1e09 , 1,  0x00 )
    fpga_UART_Write("FPGA1","DES", DESA_ID, 0x1e0a , 1,  0x91 )
    fpga_UART_Write("FPGA1","DES", DESA_ID, 0x1e0b , 1,  0xBF )


---- STR_SEL_
    fpga_UART_Write("FPGA1","DES", DESA_ID,DR_RX0_0 , 1, 0x2)
    fpga_UART_Write("FPGA1","DES", DESA_ID,DR_RX0_1 , 1, 0x0)
    fpga_UART_Write("FPGA1","DES", DESA_ID,DR_RX0_2 , 1, 0x1)
    fpga_UART_Write("FPGA1","DES", DESA_ID,DR_RX0_3 , 1, 0x3)

  ----delay(80ms)   ------ need for reg102 updata correctly. but if move csi clock output at the end then this delay can be removed MT 6/2018


end_body


procedure SSEN_ON_OFF( port)
--------------------------------------------------------------------------------
--  
    in string[2]    : port
local

end_local

body
        if port = "A" then
            RegWrite(SER_ID, 0x1471 ,0x1 ,0x00,  0x2, "SER_UART_Write")-----0x1471
            RegWrite(SER_ID, 0x1464 ,0x1 ,0x00,  0x03, "SER_UART_Write")-----0x1464
            RegWrite(SER_ID, 0x1470 ,0x1 ,0x00,  0x01, "SER_UART_Write")-----0x1470
            RegWrite(SER_ID, 0x1471 ,0x1 ,0x00,  0x02, "SER_UART_Write")-----0x1471
            RegWrite(SER_ID, 0x1472 ,0x1 ,0x00,  0xAB, "SER_UART_Write")-----0x1472
            RegWrite(SER_ID, 0x1473 ,0x1 ,0x00,  0x00, "SER_UART_Write")-----0x1473
            RegWrite(SER_ID, 0x1474 ,0x1 ,0x00,  0x63, "SER_UART_Write")-----0x1474
            RegWrite(SER_ID, 0x1475 ,0x1 ,0x00,  0x07, "SER_UART_Write")-----0x1475
            RegWrite(SER_ID, 0x1476 ,0x1 ,0x00,  0x00, "SER_UART_Write")-----0x1476
            RegWrite(SER_ID, 0x1477 ,0x1 ,0x00,  0x00, "SER_UART_Write")-----0x1477
            RegWrite(SER_ID, 0x1471 ,0x1 ,0x00,  0x3, "SER_UART_Write")-----0x1471
        elseif  port ="B" then
-------LinkB
            RegWrite(SER_ID, 0x1571 ,0x1 ,0x00,  0x2, "SER_UART_Write")-----0x1571
            RegWrite(SER_ID, 0x1564 ,0x1 ,0x00,  0x03, "SER_UART_Write")-----0x1564
            RegWrite(SER_ID, 0x1570 ,0x1 ,0x00,  0x01, "SER_UART_Write")-----0x1570
            RegWrite(SER_ID, 0x1571 ,0x1 ,0x00,  0x02, "SER_UART_Write")-----0x1571
            RegWrite(SER_ID, 0x1572 ,0x1 ,0x00,  0xAB, "SER_UART_Write")-----0x1572
            RegWrite(SER_ID, 0x1573 ,0x1 ,0x00,  0x00, "SER_UART_Write")-----0x1573
            RegWrite(SER_ID, 0x1574 ,0x1 ,0x00,  0x63, "SER_UART_Write")-----0x1574
            RegWrite(SER_ID, 0x1575 ,0x1 ,0x00,  0x07, "SER_UART_Write")-----0x1575
            RegWrite(SER_ID, 0x1576 ,0x1 ,0x00,  0x00, "SER_UART_Write")-----0x1576
            RegWrite(SER_ID, 0x1577 ,0x1 ,0x00,  0x00, "SER_UART_Write")-----0x1577
            RegWrite(SER_ID, 0x1571 ,0x1 ,0x00,  0x3, "SER_UART_Write")-----0x1571
        elseif  port ="AB" then  ------ both links
            RegWrite(SER_ID, 0x1471 ,0x1 ,0x00,  0x2, "SER_UART_Write")-----0x1471
            RegWrite(SER_ID, 0x1464 ,0x1 ,0x00,  0x03, "SER_UART_Write")-----0x1464
            RegWrite(SER_ID, 0x1470 ,0x1 ,0x00,  0x01, "SER_UART_Write")-----0x1470
            RegWrite(SER_ID, 0x1471 ,0x1 ,0x00,  0x02, "SER_UART_Write")-----0x1471
            RegWrite(SER_ID, 0x1472 ,0x1 ,0x00,  0xAB, "SER_UART_Write")-----0x1472
            RegWrite(SER_ID, 0x1473 ,0x1 ,0x00,  0x00, "SER_UART_Write")-----0x1473
            RegWrite(SER_ID, 0x1474 ,0x1 ,0x00,  0x63, "SER_UART_Write")-----0x1474
            RegWrite(SER_ID, 0x1475 ,0x1 ,0x00,  0x07, "SER_UART_Write")-----0x1475
            RegWrite(SER_ID, 0x1476 ,0x1 ,0x00,  0x00, "SER_UART_Write")-----0x1476
            RegWrite(SER_ID, 0x1477 ,0x1 ,0x00,  0x00, "SER_UART_Write")-----0x1477
            RegWrite(SER_ID, 0x1471 ,0x1 ,0x00,  0x3, "SER_UART_Write")-----0x1471   
            -----turn on link B
            RegWrite(SER_ID, 0x1571 ,0x1 ,0x00,  0x2, "SER_UART_Write")-----0x1571
            RegWrite(SER_ID, 0x1564 ,0x1 ,0x00,  0x03, "SER_UART_Write")-----0x1564
            RegWrite(SER_ID, 0x1570 ,0x1 ,0x00,  0x01, "SER_UART_Write")-----0x1570
            RegWrite(SER_ID, 0x1571 ,0x1 ,0x00,  0x02, "SER_UART_Write")-----0x1571
            RegWrite(SER_ID, 0x1572 ,0x1 ,0x00,  0xAB, "SER_UART_Write")-----0x1572
            RegWrite(SER_ID, 0x1573 ,0x1 ,0x00,  0x00, "SER_UART_Write")-----0x1573
            RegWrite(SER_ID, 0x1574 ,0x1 ,0x00,  0x63, "SER_UART_Write")-----0x1574
            RegWrite(SER_ID, 0x1575 ,0x1 ,0x00,  0x07, "SER_UART_Write")-----0x1575
            RegWrite(SER_ID, 0x1576 ,0x1 ,0x00,  0x00, "SER_UART_Write")-----0x1576
            RegWrite(SER_ID, 0x1577 ,0x1 ,0x00,  0x00, "SER_UART_Write")-----0x1577
            RegWrite(SER_ID, 0x1571 ,0x1 ,0x00,  0x3, "SER_UART_Write")-----0x1571                 
        
     else    ---- reset all to init
        RegWrite(SER_ID, 0x1571 ,0x1 ,0x00,  0x2, "SER_UART_Write")   ----turn off spectrum
         RegWrite(SER_ID, 0x1471 ,0x1 ,0x00,  0x2, "SER_UART_Write")-----0x1471
    end_if

end_body

function CfgGoNoGo3PINS(TestPins, CFGRegId,TestVltg, code_num): multisite float[3]
--------------------------------------------------------------------------------
--  
in pin list[5]        : TestPins
in float              : TestVltg
in lword              : code_num 
in word               : CFGRegId

local
  multisite float : Vcfg[3]
  word            : CurSite
  PIN LIST[1]     : MeasPin
  multisite lword : ReadUpperConfig0, ReadLowerConfig0 , ReadUpperConfig1, ReadLowerConfig1 ,ReadUpperConfig2, ReadLowerConfig2
endlocal

body
  active_sites = get_active_sites()
  sites = word(len(active_sites))
  Vcfg = -999V
  RdWordLower =255
  
  current_active_sites = get_active_sites
  sites = word(len(current_active_sites))
 
 
 --    Turn to INTR0 register to turn on  FW_OSC_PU  bit per DE. This bit will turn on CFG pin osc otherwise it will not update conf register. This is only applied to hs89/78 MPW3 and later. 
      RegWrite(SER_ID,SR_INTR0, 1, 0, 16#E0, "SER_UART_Write")
 
      RegWrite(SER_ID,SR_CFG_3, 1, 0, 16#00, "SER_UART_Write") -----NOTE FOR HS89 SR_CFG_3 = 0X0543
      set digital ppmu TestPins to fv TestVltg vmax 2V measure i max 20mA
      wait(10us)
      -- CFG_3: FORCE CFG PU  =1 to update CFG value
      RegWrite(SER_ID,SR_CFG_3, 1, 0, 16#02, "SER_UART_Write") 
      wait(100us) --500us
      --read CFG reg
      RegRead(SER_ID, CFGRegId, 1, ReadUpperConfig0, ReadLowerConfig0, "SER_UART_Read")      
      RegRead(SER_ID, CFGRegId+1, 1, ReadUpperConfig1, ReadLowerConfig1, "SER_UART_Read")      
      RegRead(SER_ID, CFGRegId+2, 1, ReadUpperConfig2, ReadLowerConfig2, "SER_UART_Read")
      

      for idx = 1 to sites do
          CurSite =  current_active_sites[idx]
          
          if  ReadLowerConfig0[CurSite] == code_num   then
             Vcfg[CurSite,1] = TestVltg
          else
            Vcfg[CurSite,1] = 0mV
          endif
          
          if  ReadLowerConfig1[CurSite] == code_num   then
             Vcfg[CurSite,2] = TestVltg
          else
            Vcfg[CurSite,2] = 0mV
          endif
          
          if  ReadLowerConfig2[CurSite] == code_num   then
             Vcfg[CurSite,3] = TestVltg
          else
            Vcfg[CurSite,3] = 0mV
          endif         
          
       end_for

     return(Vcfg)  
      
endbody      
procedure GenerateColorBar_max96755H(port)
--------------------------------------------------------------------------------
--  
    in string[5]: port
local

    lword       :  MIPI_SPEED  ---for flexible

end_local

body

----# Test setup for HS89 MAX95755H (104MHz speed limited) current consumption             	
----#            	
----# Single 6G/187.5M link. 1x4 lane DSI input      594Mbps per lane.        	
----# 1680x720 video (2200x750 with blanking) at 60fps            	
----# Color bar pattern. 99MHz PCLK. RGB888            	
----#            	
----# author: EK - 06/14/2019            	
----#            	
----# setup :   HS89(0x80)       >---single GMSL2 link --->     HS94(0x90)             	
----#                         <--MIPI port-A looped back---<            	
----#            	
----#            	  fpga_UART_Write("FPGA1","DES", DESA_ID, DR_CTRL1, 1, 0x0F)                 
----# ------------------------------- Serializer --------------------------------		   "   RegWrite(SER_ID, SR_CTRL1, 1, 16#0F, 16#0A, "SER_UART_Write")		   
----#		   "   
----# VID_TX_EN_X     Y   Z    U = 1   "       
if port = "A" then
    RegWrite( SER_ID, 0x2, 1, 0x00, 0xF3   ,  "SER_UART_Write") 
----# START_PORT_AX = 1      others are 0	      "        
    RegWrite( SER_ID, 0x311, 1, 0x00, 0x01,  "SER_UART_Write")	
----# CLK_SEL_X = 0            	
    RegWrite( SER_ID, 0x308, 1, 0x00, 0x7C,  "SER_UART_Write")	
----# lane count = 4	            "	
    RegWrite( SER_ID, 0x331, 1, 0x00, 0x33,  "SER_UART_Write")	
----# phy_config = 4 (MIPI port A only)        invert_CSI_mode = 1       	
    RegWrite( SER_ID, 0x330, 1, 0x00, 0x84,  "SER_UART_Write")	
----# Enable MIPI loopback TX             	
    RegWrite( SER_ID, 0x370, 1, 0x00, 0x09,  "SER_UART_Write")	
 else  ---port B
        RegWrite(SER_ID,SR_REG2, 1, 0, 0xF3	, "SER_UART_Write" )
        RegWrite(SER_ID,SR_FRONTTOP_9,  1,0, 0x10, "SER_UART_Write" )
        RegWrite(SER_ID,SR_FRONTTOP_0, 1, 0, 0x71, "SER_UART_Write" )
        RegWrite(SER_ID,SR_MIPI_RX1, 1 , 0,  0x33, "SER_UART_Write" )
        RegWrite(SER_ID,SR_MIPI_RX0, 1, 0,  0x85	, "SER_UART_Write")------------0x86
------- Enable MIPI loopback TX 
        RegWrite(SER_ID,SR_MIPI_LPB0, 1, 0, 0x20, "SER_UART_Write" )    
    end_if    


----# Generate 1680x720 color bar pattern using the video timing & pattern generator            	
RegWrite( SER_ID, 0x1C8, 1, 0x00, 0xE3,  "SER_UART_Write")	
RegWrite( SER_ID, 0x1CA, 1, 0x00, 0x00,  "SER_UART_Write")	
RegWrite( SER_ID, 0x1CB, 1, 0x00, 0x00,  "SER_UART_Write")	
RegWrite( SER_ID, 0x1CC, 1, 0x00, 0x00,  "SER_UART_Write")	
RegWrite( SER_ID, 0x1CD, 1, 0x00, 0x00,  "SER_UART_Write")	
RegWrite( SER_ID, 0x1CE, 1, 0x00, 0x2A,  "SER_UART_Write")	
RegWrite( SER_ID, 0x1CF, 1, 0x00, 0xF8,  "SER_UART_Write")	
RegWrite( SER_ID, 0x1D0, 1, 0x00, 0x19,  "SER_UART_Write")	
RegWrite( SER_ID, 0x1D1, 1, 0x00, 0x02,  "SER_UART_Write")	
RegWrite( SER_ID, 0x1D2, 1, 0x00, 0x58,  "SER_UART_Write")	
RegWrite( SER_ID, 0x1D3, 1, 0x00, 0x00,  "SER_UART_Write")	
RegWrite( SER_ID, 0x1D4, 1, 0x00, 0x00,  "SER_UART_Write")	
RegWrite( SER_ID, 0x1D5, 1, 0x00, 0x00,  "SER_UART_Write")	
RegWrite( SER_ID, 0x1D6, 1, 0x00, 0x00,  "SER_UART_Write")	
RegWrite( SER_ID, 0x1D7, 1, 0x00, 0x28,  "SER_UART_Write")	
RegWrite( SER_ID, 0x1D8, 1, 0x00, 0x08,  "SER_UART_Write")	
RegWrite( SER_ID, 0x1D9, 1, 0x00, 0x70,  "SER_UART_Write")	
RegWrite( SER_ID, 0x1DA, 1, 0x00, 0x02,  "SER_UART_Write")	
RegWrite( SER_ID, 0x1DB, 1, 0x00, 0xEE,  "SER_UART_Write")	
RegWrite( SER_ID, 0x1DC, 1, 0x00, 0x00,  "SER_UART_Write")	
RegWrite( SER_ID, 0x1DD, 1, 0x00, 0xD7,  "SER_UART_Write")	
RegWrite( SER_ID, 0x1DE, 1, 0x00, 0xDC,  "SER_UART_Write")	
RegWrite( SER_ID, 0x1DF, 1, 0x00, 0x06,  "SER_UART_Write")	
RegWrite( SER_ID, 0x1E0, 1, 0x00, 0x90,  "SER_UART_Write")	
RegWrite( SER_ID, 0x1E1, 1, 0x00, 0x02,  "SER_UART_Write")	
RegWrite( SER_ID, 0x1E2, 1, 0x00, 0x08,  "SER_UART_Write")	
RegWrite( SER_ID, 0x1E3, 1, 0x00, 0x02,  "SER_UART_Write")	
RegWrite( SER_ID, 0x1E4, 1, 0x00, 0xD0,  "SER_UART_Write")	
RegWrite( SER_ID, 0x1E5, 1, 0x00, 0x2,  "SER_UART_Write")	
RegWrite( SER_ID, 0x1E6, 1, 0x00, 0x4,  "SER_UART_Write")	
----#		   "   
----# ------------------------------- Deserializer --------------------------------		   "   
----#		   "   
----# lane mappings		   "   
fpga_UART_Write("FPGA", "DES", DESA_ID,  0x333, 1, 0x4e	)     
fpga_UART_Write("FPGA", "DES", DESA_ID,  0x334, 1, 0xe4	)     
----# lane count = 4		   "   
fpga_UART_Write("FPGA", "DES", DESA_ID,  0x40A, 1, 0x00	)     
fpga_UART_Write("FPGA", "DES", DESA_ID,  0x44A, 1, 0xD0	)     
fpga_UART_Write("FPGA", "DES", DESA_ID,  0x48A, 1, 0xD0	)     
fpga_UART_Write("FPGA", "DES", DESA_ID,  0x4CA, 1, 0x00	)     
----# STR_SEL            	
fpga_UART_Write("FPGA", "DES", DESA_ID,  0x50, 1, 0x0	 )	
fpga_UART_Write("FPGA", "DES", DESA_ID,  0x51, 1, 0x1 )	
fpga_UART_Write("FPGA", "DES", DESA_ID,  0x52, 1, 0x2 )	
fpga_UART_Write("FPGA", "DES", DESA_ID,  0x53, 1, 0x3 )	
----# Internal Datatype routing            	
----# Send RGB888      Frame Start    and Frame End in PIPE X to MIPI Port A (phy1)    	
fpga_UART_Write("FPGA", "DES", DESA_ID,  0x040B, 1, 0x07 )	
fpga_UART_Write("FPGA", "DES", DESA_ID,  0x042D, 1, 0x55 )	
----# RAW16 Mapping            	
fpga_UART_Write("FPGA", "DES", DESA_ID,  0x040D, 1, 0x24 )	
fpga_UART_Write("FPGA", "DES", DESA_ID,  0x040E, 1, 0x24 )	
----# Frame Start Mapping            	
fpga_UART_Write("FPGA", "DES", DESA_ID,  0x040F, 1, 0x00 )	
fpga_UART_Write("FPGA", "DES", DESA_ID,  0x0410, 1, 0x00 )	
----# Frame End Mapping            	
fpga_UART_Write("FPGA", "DES", DESA_ID,  0x0411, 1, 0x01 )	
fpga_UART_Write("FPGA", "DES", DESA_ID,  0x0412, 1, 0x01 )	
----#            	
if port = "A" then
----# set CSI data rate to 594Mbps and force CSI clk out on HS94            	
    fpga_UART_Write("FPGA", "DES", DESA_ID,  0x1d00, 1, 0xf4 )	
    fpga_UART_Write("FPGA", "DES", DESA_ID,  0x320, 1, 0x00 )	
    fpga_UART_Write("FPGA", "DES", DESA_ID,  0x31e, 1, 0x52 )	
    fpga_UART_Write("FPGA", "DES", DESA_ID,  0x330, 1, 0x84 )	
    fpga_UART_Write("FPGA", "DES", DESA_ID,  0x1d00, 1, 0xf5 )	
    fpga_UART_Write("FPGA", "DES", DESA_ID,  0x1d03, 1, 0x92 )	
    fpga_UART_Write("FPGA", "DES", DESA_ID,  0x1d07, 1, 0x84 )	
    fpga_UART_Write("FPGA", "DES", DESA_ID,  0x1d08, 1, 0x2f )	
    fpga_UART_Write("FPGA", "DES", DESA_ID,  0x1d0a, 1, 0xa1 )	
else
    fpga_UART_Write("FPGA", "DES", DESA_ID,  0x1e00, 1, 0xf4 ) 
    fpga_UART_Write("FPGA", "DES", DESA_ID,  0x323,  1, 0x00 )
    fpga_UART_Write("FPGA", "DES", DESA_ID,  0x321,  1, 0x52 )
    fpga_UART_Write("FPGA", "DES", DESA_ID,  0x330, 1, 0x84 )
    fpga_UART_Write("FPGA", "DES", DESA_ID,  0x1e00, 1, 0xf5 ) 
    fpga_UART_Write("FPGA", "DES", DESA_ID,  0x1e03, 1, 0x92 ) 
    fpga_UART_Write("FPGA", "DES", DESA_ID,  0x1e07, 1, 0x84 ) 
    fpga_UART_Write("FPGA", "DES", DESA_ID,  0x1e08, 1, 0x2f ) 
    fpga_UART_Write("FPGA", "DES", DESA_ID,  0x1e0a, 1, 0xa1 ) 

 end_if   

----#	            "	
----# Disable HS89 periodic AEQ to keep the VDD18 current constant            	
RegWrite( SER_ID, 0x14A4, 1, 0x00, 0x00 ,  "SER_UART_Write")	
RegWrite( SER_ID, 0x15A4, 1, 0x00, 0x00 ,  "SER_UART_Write")	






end_body

procedure GenerateColorBar_max96755H_DL
--------------------------------------------------------------------------------
--  

local

    lword       :  MIPI_SPEED  ---for flexible
multisite lword   : LowerRdWord, UpperRdWord
end_local

body

------# Color bar pattern. 99MHz PCLK. RGB888	   
------#	   
------# author: EK - 06/14/2019	   
------#	   
------# setup :   HS89(0x80)       >---dual GMSL2 link --->     HS94(0x90) 	   
------#                     <--MIPI port-A and port-B looped back---<	   
------#	   
------#	  
------# ----------------------------------------------------------------------------	   
------# Establish dual GMSL2 link	   
-- fpga_UART_Write("FPGA1", "DES", DESA_ID, 0x10, 1, 0x10)	   
-- RegWrite(SER_ID, 0x10, 1, 0x00, 0x10, "SER_UART_Write")	   
-- RegWrite(SER_ID, 0x01, 1, 0x00, 0x18, "SER_UART_Write")	   
-- RegWrite(SER_ID, 0x10, 1, 0x00, 0x30, "SER_UART_Write")	   
-- RegWrite(SER_ID, 0x01, 1, 0x00, 0x08, "SER_UART_Write")	   
------# Here read Reg0x2F on HS89 or HS94; 0x66 indicates that both links are locked!!!	   
-- RegRead(SER_ID,0x2F, 1, UpperRdWord, LowerRdWord,"SER_UART_Read")  
------# ------------------------------- Serializer -------------------------------- 	   
------# 	   
------# VID_TX_EN_XYZ	   
RegWrite(SER_ID, 0x2, 1, 0x00, 0xF3 , "SER_UART_Write")	   
------# START_PORT_AX = 1 START_PORT_BY = 1 others are 0 	   
RegWrite(SER_ID, 0x311, 1, 0x00, 0x21, "SER_UART_Write")	   
------# CLK_SEL_X = 0 CLK_SEL_Y = 1	   
RegWrite(SER_ID, 0x308, 1, 0x00, 0x7E, "SER_UART_Write")	   
------# lane count = 4 	   
RegWrite(SER_ID, 0x331, 1, 0x00, 0x33, "SER_UART_Write")	   
------# phy_config = 6 (2x4 A and B)   invert_CSI_mode = 1	   
RegWrite(SER_ID, 0x330, 1, 0x00, 0x86 , "SER_UART_Write")	   
------# Enable MIPI loopback TX 	   
RegWrite(SER_ID, 0x370, 1, 0x00, 0x29, "SER_UART_Write")	   
------# Generate 1680x720 color bar pattern using the video timing & pattern generator - pipe X	   
RegWrite(SER_ID, 0x1C8, 1, 0x00, 0xE3, "SER_UART_Write")	   
RegWrite(SER_ID, 0x1CA, 1, 0x00, 0x00, "SER_UART_Write")	   
RegWrite(SER_ID, 0x1CB, 1, 0x00, 0x00, "SER_UART_Write")	   
RegWrite(SER_ID, 0x1CC, 1, 0x00, 0x00, "SER_UART_Write")	   
RegWrite(SER_ID, 0x1CD, 1, 0x00, 0x00, "SER_UART_Write")	   
RegWrite(SER_ID, 0x1CE, 1, 0x00, 0x2A, "SER_UART_Write")	   
RegWrite(SER_ID, 0x1CF, 1, 0x00, 0xF8, "SER_UART_Write")	   
RegWrite(SER_ID, 0x1D0, 1, 0x00, 0x19, "SER_UART_Write")	   
RegWrite(SER_ID, 0x1D1, 1, 0x00, 0x02, "SER_UART_Write")	   
RegWrite(SER_ID, 0x1D2, 1, 0x00, 0x58, "SER_UART_Write")	   
RegWrite(SER_ID, 0x1D3, 1, 0x00, 0x00, "SER_UART_Write")	   
RegWrite(SER_ID, 0x1D4, 1, 0x00, 0x00, "SER_UART_Write")	   
RegWrite(SER_ID, 0x1D5, 1, 0x00, 0x00, "SER_UART_Write")	   
RegWrite(SER_ID, 0x1D6, 1, 0x00, 0x00, "SER_UART_Write")	   
RegWrite(SER_ID, 0x1D7, 1, 0x00, 0x28, "SER_UART_Write")	   
RegWrite(SER_ID, 0x1D8, 1, 0x00, 0x08, "SER_UART_Write")	   
RegWrite(SER_ID, 0x1D9, 1, 0x00, 0x70, "SER_UART_Write")	   
RegWrite(SER_ID, 0x1DA, 1, 0x00, 0x02, "SER_UART_Write")	   
RegWrite(SER_ID, 0x1DB, 1, 0x00, 0xEE, "SER_UART_Write")	   
RegWrite(SER_ID, 0x1DC, 1, 0x00, 0x00, "SER_UART_Write")	   
RegWrite(SER_ID, 0x1DD, 1, 0x00, 0xD7, "SER_UART_Write")	   
RegWrite(SER_ID, 0x1DE, 1, 0x00, 0xDC, "SER_UART_Write")	   
RegWrite(SER_ID, 0x1DF, 1, 0x00, 0x06, "SER_UART_Write")	   
RegWrite(SER_ID, 0x1E0, 1, 0x00, 0x90, "SER_UART_Write")	   
RegWrite(SER_ID, 0x1E1, 1, 0x00, 0x02, "SER_UART_Write")	   
RegWrite(SER_ID, 0x1E2, 1, 0x00, 0x08, "SER_UART_Write")	   
RegWrite(SER_ID, 0x1E3, 1, 0x00, 0x02, "SER_UART_Write")	   
RegWrite(SER_ID, 0x1E4, 1, 0x00, 0xD0, "SER_UART_Write")	   
RegWrite(SER_ID, 0x1E5, 1, 0x00, 0x2, "SER_UART_Write")	   
RegWrite(SER_ID, 0x1E6, 1, 0x00, 0x4, "SER_UART_Write")	   
------#	   
------# Generate 1680x720 color bar pattern using the video timing & pattern generator - pipe Y	   
RegWrite(SER_ID, 0x20B, 1, 0x00, 0xE3, "SER_UART_Write")	   
RegWrite(SER_ID, 0x20D, 1, 0x00, 0x00, "SER_UART_Write")	   
RegWrite(SER_ID, 0x20E, 1, 0x00, 0x00, "SER_UART_Write")	   
RegWrite(SER_ID, 0x20F, 1, 0x00, 0x00, "SER_UART_Write")	   
RegWrite(SER_ID, 0x210, 1, 0x00, 0x00, "SER_UART_Write")	   
RegWrite(SER_ID, 0x211, 1, 0x00, 0x2A, "SER_UART_Write")	   
RegWrite(SER_ID, 0x212, 1, 0x00, 0xF8, "SER_UART_Write")	   
RegWrite(SER_ID, 0x213, 1, 0x00, 0x19, "SER_UART_Write")	   
RegWrite(SER_ID, 0x214, 1, 0x00, 0x02, "SER_UART_Write")	   
RegWrite(SER_ID, 0x215, 1, 0x00, 0x58, "SER_UART_Write")	   
RegWrite(SER_ID, 0x216, 1, 0x00, 0x00, "SER_UART_Write")	   
RegWrite(SER_ID, 0x217, 1, 0x00, 0x00, "SER_UART_Write")	   
RegWrite(SER_ID, 0x218, 1, 0x00, 0x00, "SER_UART_Write")	   
RegWrite(SER_ID, 0x219, 1, 0x00, 0x00, "SER_UART_Write")	   
RegWrite(SER_ID, 0x21A, 1, 0x00, 0x28, "SER_UART_Write")	   
RegWrite(SER_ID, 0x21B, 1, 0x00, 0x08, "SER_UART_Write")	   
RegWrite(SER_ID, 0x21C, 1, 0x00, 0x70, "SER_UART_Write")	   
RegWrite(SER_ID, 0x21D, 1, 0x00, 0x02, "SER_UART_Write")	   
RegWrite(SER_ID, 0x21E, 1, 0x00, 0xEE, "SER_UART_Write")	   
RegWrite(SER_ID, 0x21F, 1, 0x00, 0x00, "SER_UART_Write")	   
RegWrite(SER_ID, 0x220, 1, 0x00, 0xD7, "SER_UART_Write")	   
RegWrite(SER_ID, 0x221, 1, 0x00, 0xDC, "SER_UART_Write")	   
RegWrite(SER_ID, 0x222, 1, 0x00, 0x06, "SER_UART_Write")	   
RegWrite(SER_ID, 0x223, 1, 0x00, 0x90, "SER_UART_Write")	   
RegWrite(SER_ID, 0x224, 1, 0x00, 0x02, "SER_UART_Write")	   
RegWrite(SER_ID, 0x225, 1, 0x00, 0x08, "SER_UART_Write")	   
RegWrite(SER_ID, 0x226, 1, 0x00, 0x02, "SER_UART_Write")	   
RegWrite(SER_ID, 0x227, 1, 0x00, 0xD0, "SER_UART_Write")	   
RegWrite(SER_ID, 0x228, 1, 0x00, 0x2, "SER_UART_Write")	   
RegWrite(SER_ID, 0x229, 1, 0x00, 0x4, "SER_UART_Write")	   
------# 	   
------# ------------------------------- Deserializer -------------------------------- 	   
------# 	   
------# lane mappings 	   
fpga_UART_Write("FPGA1", "DES", DESA_ID, 0x333, 1, 0x4e )	   
fpga_UART_Write("FPGA1", "DES", DESA_ID, 0x334, 1, 0xe4 )	   
------# lane count = 4 	   
fpga_UART_Write("FPGA1", "DES", DESA_ID, 0x40A, 1, 0x00 )	   
fpga_UART_Write("FPGA1", "DES", DESA_ID, 0x44A, 1, 0xD0 )	   
fpga_UART_Write("FPGA1", "DES", DESA_ID, 0x48A, 1, 0xD0 )	   
fpga_UART_Write("FPGA1", "DES", DESA_ID, 0x4CA, 1, 0x00 )	   
------# STR_SEL	   
fpga_UART_Write("FPGA1", "DES", DESA_ID, 0x50, 1, 0x0)	   
fpga_UART_Write("FPGA1", "DES", DESA_ID, 0x51, 1, 0x2)	   
fpga_UART_Write("FPGA1", "DES", DESA_ID, 0x52, 1, 0x1)	   
fpga_UART_Write("FPGA1", "DES", DESA_ID, 0x53, 1, 0x3)	   
------# Internal Datatype routing	   
------# Send RGB888 Frame Start and Frame End in PIPE X to MIPI Port A (phy1)	   
fpga_UART_Write("FPGA1", "DES", DESA_ID, 0x040B, 1, 0x07)	   
fpga_UART_Write("FPGA1", "DES", DESA_ID, 0x042D, 1, 0x55)	   
------# RAW16 Mapping	   
fpga_UART_Write("FPGA1", "DES", DESA_ID, 0x040D, 1, 0x24)	   
fpga_UART_Write("FPGA1", "DES", DESA_ID, 0x040E, 1, 0x24)	   
------# Frame Start Mapping	   
fpga_UART_Write("FPGA1", "DES", DESA_ID, 0x040F, 1, 0x00)	   
fpga_UART_Write("FPGA1", "DES", DESA_ID, 0x0410, 1, 0x00)	   
------# Frame End Mapping	   
fpga_UART_Write("FPGA1", "DES", DESA_ID, 0x0411, 1, 0x01)	   
fpga_UART_Write("FPGA1", "DES", DESA_ID, 0x0412, 1, 0x01 )	   
------#	   
------# set CSI data rate to 594Mbps and force CSI clk out on HS94	   
fpga_UART_Write("FPGA1", "DES", DESA_ID, 0x1d00, 1, 0xf4)	   
fpga_UART_Write("FPGA1", "DES", DESA_ID, 0x320, 1, 0x00)	   
fpga_UART_Write("FPGA1", "DES", DESA_ID, 0x31e, 1, 0x52)	   
fpga_UART_Write("FPGA1", "DES", DESA_ID, 0x330, 1, 0x84)	   
fpga_UART_Write("FPGA1", "DES", DESA_ID, 0x1d00, 1, 0xf5)	   
fpga_UART_Write("FPGA1", "DES", DESA_ID, 0x1d03, 1, 0x92)	   
fpga_UART_Write("FPGA1", "DES", DESA_ID, 0x1d07, 1, 0x84)	   
fpga_UART_Write("FPGA1", "DES", DESA_ID, 0x1d08, 1, 0x2f)	   
fpga_UART_Write("FPGA1", "DES", DESA_ID, 0x1d0a, 1, 0xa1)	   
------#	   
fpga_UART_Write("FPGA1", "DES", DESA_ID, 0x1e00, 1, 0xf4)	   
fpga_UART_Write("FPGA1", "DES", DESA_ID, 0x323, 1, 0x00)	   
fpga_UART_Write("FPGA1", "DES", DESA_ID, 0x321, 1, 0x52)	   
fpga_UART_Write("FPGA1", "DES", DESA_ID, 0x330, 1, 0x84)	   
fpga_UART_Write("FPGA1", "DES", DESA_ID, 0x1e00, 1, 0xf5)	   
fpga_UART_Write("FPGA1", "DES", DESA_ID, 0x1e03, 1, 0x92)	   
fpga_UART_Write("FPGA1", "DES", DESA_ID, 0x1e07, 1, 0x84)	   
fpga_UART_Write("FPGA1", "DES", DESA_ID, 0x1e08, 1, 0x2f)	   
fpga_UART_Write("FPGA1", "DES", DESA_ID, 0x1e0a, 1, 0xa1)	   
------# 	   
------# Disable HS89 periodic AEQ to keep the VDD18 current constant	   
RegWrite(SER_ID, 0x14A4, 1, 0x00, 0x00 , "SER_UART_Write")	   
RegWrite(SER_ID, 0x15A4, 1, 0x00, 0x00 , "SER_UART_Write")	 

end_body

function meas_ABUS_SE_V_Vbg (waitTime , TestMode,Vdd18,Vdd) : multisite float[4]
-------------------------------------------------------------------------------------------------------------
--  DESCRIPTION
--  Measure single eneded voltage on all MFP/ABUS pins.
-- 
--  Assumes device set in correct mode.
--  Assumes MFP pins are connected to PPMU and setup in FNMV mode.
--
--
--  PASS PARAMETERS:
--  waitTime        -- Wait time between set test mode and measurement
--  TestMode        -- Which test mode to measure (abus_blk = #, abus_page = #)
--
--
--  USAGE:
--  meas_v = meas_ABUS_SE_V ( 1ms , 0x22 )      -- Measure all 4 channels for ABUS block 2 page 2



in float    : waitTime,Vdd,Vdd18
in lword    : TestMode


local
    multisite float     : meas_v[4]
end_local

body

    -- Change MFP/ABUS pins to FI
    set digital ppmu ABUS_DP_pl-SER_GPO6_CFG2 to fi 0.0uA measure v max 1.7V            ---4 -- added hcu 7/8/2020 fanout hs78 abus fix by pulling down abus 3 at vbg test 
      wait(500us)
   if TestMode = 0x04 and Vdd18 > 1.7 then  -----Some parts failed Vbg at Vmax with Hot Option. Reduce supplies would fix it MT 1/2020
       set hcovi SER_VDD18  to fv 1.8 vmax 4V  measure  i max 600ma clamp imax 900mA imin -900mA      
       set hcovi SER_VDD  to fv 1.0 vmax 4V  measure  i max 600ma clamp imax 900mA imin -900mA       
       wait(5ms) 
   end_if 
    -- Set test mode

    RegWrite(SER_ID, SR_TEST0, 1, 0x00, TestMode, "SER_UART_Write")      -- abus_blk = #, abus_page = #    SR_TEST0 = 0x3E

    if TestMode = 0x0F then -- TDIODE test  move here otherwise glitch  MT 2/2019
        set digital ppmu SER_GPIO3_RCLKOUT to fi 100uA measure v max 1.7V ---4
    end_if    
   if TestMode = 0x04 and  Vdd18> 1.7 then
       set hcovi SER_VDD18  to fv Vdd18 vmax 4V  measure  i max 600ma clamp imax 900mA imin -900mA      
       set hcovi SER_VDD  to fv Vdd vmax 4V  measure  i max 600ma clamp imax 900mA imin -900mA       
       wait(5ms) 
   end_if 

    wait(waitTime)

    measure digital ppmu ABUS_DP_pl voltage average 20 delay 10us into meas_v

    -- clear test mode
    set digital ppmu ABUS_DP_pl to fi 0.0uA measure v max 1.7V            ---4

    RegWrite(SER_ID,  SR_TEST0, 1, 0x00, 0x00, "SER_UART_Write")    -- HIZ

--    set digital ppmu ABUS_DP_pl to fv 0V measure i max 1mA
   set digital ppmu ABUS_DP_pl to fv 0V measure i max 2uA

--    set digital ppmu ABUS_DP_pl to fi 0mA measure v max 4V
    return(meas_v)

end_body

