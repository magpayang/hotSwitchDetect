--------------------------------------------------------------------------------------
--                                     CONSTANTS                                    --
--------------------------------------------------------------------------------------

const


TEST_GPIB = 800

    HP_METER = 20       -- HP METER with connections through SSBA (ANALOG BUS)
    DCTM_HP_METER = 24  -- DCTM METER address
    URV5     =  9
    SME      = 15

    HP_ID_STR = "HEWLETT-PACKARD,34401A"
        mS              = 0.001
        uS              = 0.000001
        M               = 1000000.
        K               = 1000.
        pct             = 0.01
        uv              = 0.000001
        mv              = 0.001
--##    na              = 0.000000001
        ua              = 0.000001
        USR_GPIB        = 1
        SYSTM_GPIB      = 2
        DP_8V           = 1
        G_AUTO          = 16#0
        GPIB_TIMEOUT_STD    = 6.0

	num_of_bytes = 100 --cx min?
	
	NUM_POINTS = 1000
	HP_MEAS_I  = 1
	HP_MEAS_V  = 2


endconst

static

--There are provisions for test time reduction that reduces the amount of GPIB communication on subsequent Voltage or Current measurements.
--It requires this variable to be initialized in On_Init flow to Zero.    
    
    word  : hp_measure_mode
    
end_static

----------------------------------------------------------------------
procedure gpib_poll_for_meter( addr)
----------------------------------------------------------------------

in word                 : addr    

local
string[100]: DevStr = ""
endlocal

body
    disable cx all faults
    initialize cx gpib

-- MAM : unknown
--    gpib_talk_listen    

    enable cx faults

    -- execute misc commands, check for faults
    send cx gpib untalk unlisten

    -- do some visual tests
    send cx gpib device clear to address URV5 -- should produce string "HELLO" on the display
    wait(1mS)

    send cx gpib remote enable off -- HP METER display should switch from dashes to changing digits
    wait(1mS)
    
    send cx gpib device clear to address addr
    send cx gpib remote enable on
    send cx gpib trigger to address addr -- should produce an error status on display and beep
    wait(1mS)
end_body


procedure init_dvm( addr)
----------------------------------------------------------------------

in word                 : addr    

body

    --LTX_start
    --Test_clear_fails
    gpib_poll_for_meter( addr)
    --Test_print_fails

end_body

procedure Set_dvm_vrng (rng_max, addr)
-------------------------------------------------------------------------------------------
in float                : rng_max
in word                 : addr             

body
    -- sets resolution to maximum

       talk cx to gpib address addr with  sprint ("DCV ", rng_max, ", .00001;")

end_body



function Measure_HP3458A_volts(Num_of_bytes, Num_line_cycles, addr) : double
-------------------------------------------------------------------------------------------
in word     : Num_of_bytes
in integer  : Num_line_cycles
in word     : addr
local
    string[20]: readback = ""         
    string[20]: nplc_str  
    double:     dresult  = -99.              
    float:      fresult  = -99.   
    integer     :    i   
    boolean     : timeout
end_local

body

-- start_timer
-- println(stdout,stop_timer!u=mS)

    if hp_measure_mode <> HP_MEAS_V then
        -- Num_of_bytes is typically 18
        nplc_str = sprint (Num_line_cycles)
        if len(nplc_str) = 2 then       -- 1-digit
            nplc_str = sprint ("NPLC ", Num_line_cycles:-1,";")
        else_if len(nplc_str) = 3 then  -- 2-digit
            nplc_str = sprint ("NPLC ", Num_line_cycles:-2,";")
        else_if len(nplc_str) = 4 then  -- 3-digit
            nplc_str = sprint ("NPLC ", Num_line_cycles:-3,";")
        end_if
    
        talk    cx to gpib address addr with nplc_str
    
        -- next statement not verified
--        talk    cx to gpib address addr with sprint ("FUNC DCV, 10, 1.0e-6;")
        talk    cx to gpib address addr with sprint ("FUNC DCV, AUTO, 0.001;")
--        talk    cx to gpib address addr with sprint ("FUNC DCV, 5V, 0.1e-6;")
    
        talk    cx to gpib address addr with sprint ("END ALWAYS;")             
        talk    cx to gpib address addr with sprint ("OFORMAT ASCII;") 
        hp_measure_mode = HP_MEAS_V
    end_if
    talk    cx to gpib address addr with sprint ("TRIG SGL;")
    -- gpib listen, waits for measurement ready
--     wait(1/60 * Num_line_cycles)
--     wait(3Sec)
    listen  cx to gpib address addr into readback for Num_of_bytes bytes timeout into timeout
    sinput (readback, dresult)
    return (dresult)

end_body

function Measure_HP3458A_volts_new_array(Num_of_bytes,Num_of_readings, addr, j, result_array): double
-------------------------------------------------------------------------------------------
-- prototype routine for capturing an array of measurements
in word         : Num_of_bytes
in integer      : Num_of_readings
in word         : addr
in integer      : j
in_out float    : result_array[NUM_POINTS]

local
    string[16]: readback = ""         
    double:     dresult  = -99.              
    float:      fresult  = -99.   
    integer:    i    
end_local

body


 --      if Num_of_readings > 1 or false then
--     --talk    cx to gpib address addr with sprint ("PRESET DIG;")
--     --talk cx to gpib address addr with sprint("SWEEP 100E-9,2000")
--           talk    cx to gpib address addr with sprint ("PRESET DIG;")
--           talk    cx to gpib address addr with sprint ("APER 1.4E-6;")
--           talk    cx to gpib address addr with sprint ("MFORMAT SINT;")
--           talk    cx to gpib address addr with sprint ("MEM FIFO;")   
--           --talk    cx to gpib address addr with sprint ("TIMER 20E-6;")
--           --talk    cx to gpib address addr with sprint ("NRDGS "+sprint(Num_of_readings)+",TIMER;")
--           talk    cx to gpib address addr with sprint ("NRDGS "+sprint(Num_of_readings)+",AUTO;")
--           talk    cx to gpib address addr with sprint ("TARM SGL;")
--            
--           talk    cx to gpib address addr with sprint ("Dim Rdgs("+sprint(Num_of_readings)+");")
--       endif



    for i = 1 to Num_of_readings do 
    
        talk    cx to gpib address addr with sprint ("TRIG SGL;")
        wait(50ms)
        listen  cx to gpib address addr into readback for Num_of_bytes bytes
              -- listen cx to gpib adr addr into readback until end -- into readback
        
        sinput (readback, dresult)
        result_array[i] = float(dresult)
        
        if j==1 then
--                     talk    cx to gpib address addr with sprint ("NPLC "+sprint(NPLC)+";") --doesn't always work!!!     
                    talk    cx to gpib address addr with sprint ("TRIG SGL;")
            wait(50ms)
            listen  cx to gpib address addr into readback for Num_of_bytes bytes
              -- listen cx to gpib adr addr into readback until end -- into readback
        
            sinput (readback, dresult)
            result_array[i] = float(dresult)
        end_if 
           
    endfor
    --sinput (readback, dresult)
    return (dresult)

end_body


function Measure_HP3458A_current(Num_of_bytes, Num_line_cycles, addr) : double
-------------------------------------------------------------------------------------------
in word     : Num_of_bytes
in integer  : Num_line_cycles
in word     : addr
local
    string[20]: readback = ""         
    string[20]: nplc_str  
    double:     dresult  = -99.              
    float:      fresult  = -99.   
    integer     :    i   
    boolean     : timeout
end_local

body

    if hp_measure_mode <> HP_MEAS_I then
        -- Num_of_bytes is typically 18
        nplc_str = sprint (Num_line_cycles)
        if len(nplc_str) = 2 then       -- 1-digit
            nplc_str = sprint ("NPLC ", Num_line_cycles:-1,";")
        else_if len(nplc_str) = 3 then  -- 2-digit
            nplc_str = sprint ("NPLC ", Num_line_cycles:-2,";")
        else_if len(nplc_str) = 4 then  -- 3-digit
            nplc_str = sprint ("NPLC ", Num_line_cycles:-3,";")
        end_if
    
        talk    cx to gpib address addr with nplc_str
        talk    cx to gpib address addr with sprint ("FUNC DCI, AUTO, 0.0001;")
        talk    cx to gpib address addr with sprint ("END ALWAYS;")             
        talk    cx to gpib address addr with sprint ("OFORMAT ASCII;") 
        hp_measure_mode = HP_MEAS_I
    end_if
    
    talk    cx to gpib address addr with sprint ("TRIG SGL;")
    -- wait(1/60 * Num_line_cycles)
    listen  cx to gpib address addr into readback for Num_of_bytes bytes timeout into timeout
    sinput (readback, dresult)
    return (dresult)

end_body


