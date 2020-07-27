--------------------------------------------------------------------------------
-- Filename: DVM_tests.mod
--
-- Purpose:
--     HP3458 Scope and analog bus connection routines.
--
-- Procedures and functions included in this file
--     Close_Analog_Bus_to_DUT_Site
--     Close_DUT_ANALOG_Relay
--     Open_DUT_ANALOG_Relay
--     Connect_DVM_to_DUT_Site
--     Disconnect_DVM_from_DUT_Site
--     Connect_DVM_to_CAL_bus
--     Set_DVM_Display_State
--
-- History:
--     02/20/2010   pla                 -- Initial Version
--     05/27/2011   pla                 -- Added new procedure that sets state of HP Meter display
--                                      -- Removed use module statements for user_digital.mod 
--                                      -- and user_cbit_ctrl.mod 
--                                      
--
-- Operator variables:
--     none
--
-- Globals:
--     none
--
--------------------------------------------------------------------------------

use module "user_globals.mod"
use module "./lib/lib_HP3458A_gpib.mod"

const

    
end_const

static

    multisite float       : iref_cal_64uA
    multisite float       : iref_cal_4uA
    
end_static
    


procedure Close_Analog_Bus_to_DUT_Site(ana_bus_line)

in word :   ana_bus_line

--------------------------------------------------------------------------------
--  

const

    -- check on 0x25 versus 0x1011_1111_1111_1111
    
    REG     =   16#25
    SLOT    =   1
    -- Set Low active relay
    ANALOG1 =   2#1011_1111_1111_1111
    ANALOG2 =   2#1101_1111_1111_1111
    ANALOG3 =   2#1110_1111_1111_1111
    ANALOG4 =   2#1111_0111_1111_1111
    
end_const


local

    word    :   regData, closeRelayData
    
end_local

body

    -- get current register data value
    read cx register offset REG slot SLOT into regData
    
    if ana_bus_line = 1 then
        closeRelayData = regData & ANALOG1
    else_if ana_bus_line = 2 then
        closeRelayData = regData & ANALOG2
    else_if ana_bus_line = 3 then
        closeRelayData = regData & ANALOG3
    else_if ana_bus_line = 4 then
        closeRelayData = regData & ANALOG4
    end_if

    -- set current register data value
    set cx register offset REG slot SLOT to closeRelayData
    
end_body

procedure Close_DUT_ANALOG_Relay(num_wire, meas_type, cal_bus, crate)

in string[80] :   num_wire
in string[80] :   meas_type
in boolean    :   cal_bus
in word       :   crate

--------------------------------------------------------------------------------
--  

const

    -- check on 0x25 versus 0x1011_1111_1111_1111
    
    REG     =   16#25
    -- Set relay mask : Low active relay
    DVM_LF =   2#1011_1111_1111_1111       -- ANALOG1
    DVM_LS =   2#1101_1111_1111_1111       -- ANALOG2
    DVM_HF =   2#1110_1111_1111_1111       -- ANALOG3
    DVM_HS =   2#1111_0111_1111_1111       -- ANALOG4
    DVM_MV =   2#0000_0000_0001_0000       -- Meas Voltage : Open  K20
    DVM_MI =   2#1111_1111_1110_1111       -- Meas Current : Close K20
    DVM_ALL_OPEN =   2#0111_1000_0000_0000        -- OR with orig
    DVM_ALL_CLOSE =   2#1000_0111_1111_1111       -- AND with orig
    
end_const


local

    word    :   regData, newRegData, regData23, regData23New
    word    :   ssba_slot
    
end_local

body

    if crate = 0 then
        ssba_slot = 1
    else_if crate = 1 then
        ssba_slot = 33
    end_if
    
    -- get current register data value
    read cx register offset REG slot ssba_slot into regData
    
    read cx register offset 16#23 slot ssba_slot into regData23

    if num_wire = "4WIRE" then
        newRegData = regData & DVM_LF & DVM_LS & DVM_HF & DVM_HS
    else_if num_wire = "2WIRE" then
        newRegData = regData & DVM_LF & DVM_HF
    else_if num_wire = "OPEN" then
        newRegData = regData | DVM_ALL_OPEN
    else
        println(stdout,"ERROR : Dut level DVM Connect option")
        println(stdout,"Options : 4WIRE or 2WIRE")
        halt
    end_if
    
    if meas_type = "V" then
        newRegData = newRegData | DVM_MV
    else_if meas_type = "I" then
        newRegData = newRegData & DVM_MI
    else
        println(stdout,"ERROR : Dut level DVM Connect option")
        println(stdout,"Options : V or I")
        halt
    end_if
    
    -- set current register data value
    set cx register offset REG slot ssba_slot to newRegData
    
    -- Open dvm connection to cal bus
    if not cal_bus then   -- Open dvm connection to cal bus
        set cx register offset 16#23 slot ssba_slot to 16#EEFF
    else            -- Close dvm connection to cal bus
        set cx register offset 16#23 slot ssba_slot to 16#EEE7 
    end_if
    read cx register offset 16#23 slot ssba_slot into regData23New
    
end_body


procedure Open_DUT_ANALOG_Relay

--------------------------------------------------------------------------------
--  

const

    -- check on 0x25 versus 0x1011_1111_1111_1111
    
    REG     =   16#25
    SLOT    =   1
    -- Set relay mask : Low active relay
    DVM_ALL_OPEN =   2#0111_1000_0000_0000       -- ANALOG1/2/3/4
    
end_const


local

    word    :   regData, newRegData
    
end_local

body

    -- get current register data value
    read cx register offset REG slot SLOT into regData

    newRegData = regData | DVM_ALL_OPEN

    -- set current register data value
    set cx register offset REG slot SLOT to newRegData
    
end_body


procedure Connect_DVM_to_DUT_Site(num_wire,meas_type)
--------------------------------------------------------------------------------
--
in string[80] :   num_wire
in string[80] :   meas_type

--------------------------------------------------------------------------------
-- This procedure will connect the HP3458 meter to loadboard through the SSBA pins
--
-- Connection modes are "4WIRE" "2WIRE" or "OPEN"
-- "OPEN" connection is actually disconnected mode
--
-- Measure modes are "V" or "I"
--
-- This procedure is called during OnLoad flow in both DVM_Init and SMA_and_DVM_Init flow nodes,
--  where it is connected in "2WIRE" mode with measure mode of "V"  
--------------------------------------------------------------------------------





const
    
end_const


local

    word    :   regData, newRegData
    
end_local

body


    if num_wire = "4WIRE" then
        connect cx abus1 to cal force low 
        connect cx abus2 to cal sense low 
        connect cx abus3 to cal force hi 
        connect cx abus4 to cal sense hi 
    else_if num_wire = "2WIRE" then
        connect cx abus1 to cal force low 
        disconnect cx abus2 from cal sense low 
        connect cx abus3 to cal force hi 
        disconnect cx abus4 from cal sense hi 
    else_if num_wire = "OPEN" then
        disconnect cx abus1 from cal force low 
        disconnect cx abus2 from cal sense low 
        disconnect cx abus3 from cal force hi 
        disconnect cx abus4 from cal sense hi 
    else
        println(stdout,"ERROR : Dut level DVM Connect option")
        println(stdout,"Options : 4WIRE or 2WIRE")
        halt
    end_if
    
    if meas_type = "V" then
        connect cx dvm to cal bus measure v 
    else_if meas_type = "I" then
        connect cx dvm to cal bus measure i
    else
        println(stdout,"ERROR : Dut level DVM Connect option")
        println(stdout,"Options : V or I")
        halt
    end_if
    
    if num_wire = "4WIRE" then
        connect cx abus1 to dut cage0
        connect cx abus2 to dut cage0
        connect cx abus3 to dut cage0
        connect cx abus4 to dut cage0
    else_if num_wire = "2WIRE" then
        connect cx abus1 to dut cage0
        disconnect cx abus2 from dut cage0
        connect cx abus3 to dut cage0
        disconnect cx abus4 from dut cage0
    else_if num_wire = "OPEN" then
        disconnect cx abus1 from dut cage0
        disconnect cx abus2 from dut cage0
        disconnect cx abus3 from dut cage0
        disconnect cx abus4 from dut cage0
    end_if
    
    -- do this if you need CAL-Bus isolation from the ANALOG Bus
    if true then
        Close_DUT_ANALOG_Relay(num_wire, meas_type, false, 0)
    end_if
    
end_body


procedure Disconnect_DVM_from_DUT_Site

--------------------------------------------------------------------------------
--  

const
    
end_const


local

    word    :   regData, newRegData
    
end_local

body


    disconnect cx abus1 from cal force low 
    disconnect cx abus2 from cal sense low 
    disconnect cx abus3 from cal force hi 
    disconnect cx abus4 from cal sense hi 
    
    disconnect cx dvm from cal bus 
    
    Open_DUT_ANALOG_Relay
    
end_body


procedure Connect_DVM_to_CAL_bus(meas_type)

in string[80] :   meas_type

--------------------------------------------------------------------------------
--  

const
    
end_const


local

    word    :   regData, newRegData
    
end_local

body

    -- This routine leaves the Analog Bus connected to
    -- allow for thermal stability
    -- The open DMM mux on the Dutboard provides isolation
        
    if meas_type = "V" then
        connect cx dvm to cal bus measure v 
    else_if meas_type = "I" then
        connect cx dvm to cal bus measure i
    else
        println(stdout,"ERROR : Dut level DVM Connect option")
        println(stdout,"Options : V or I")
        halt
    end_if
        
end_body


procedure Set_DVM_Display_State(addr, display_state)
--------------------------------------------------------------------------------
--  
    in word : addr
    in word : display_state

--------------------------------------------------------------------------------
-- This procedure will turn on or off the HP3458 display based on the value of the 
-- display_state parameter.  1==ON and 0==Off
--
-- According to LTXC, turning off the display will save approximately 30ms per measurement.
--
-- This procedure is called during OnLoad flow in both DVM_Init and SMA_and_DVM_Init flow nodes,
--  where the display mode is set to OFF.
--------------------------------------------------------------------------------

local

end_local

body

    if display_state == 0 then
        talk cx to gpib address addr with sprint("DISP 0;")
    elseif display_state ==1 then 
        talk cx to gpib address addr with sprint("DISP 1;")   
    else
        println(stdout, "")
        println(stdout, " ****************************************************************************************************")
        println(stdout, " ****************************************************************************************************")
        println(stdout, " **********                                                                                **********")
        println(stdout, "")
        println(stdout, "      Invalid Value for parameter display_state in call to DVM_tests.mod/Set_DVM_Display_State")       
        println(stdout, "           display_state = 0 to turn Display OFF     display_state = 1 to turn Display ON ")
        println(stdout, "")
        println(stdout, " **********                                                                                **********")
        println(stdout, " ****************************************************************************************************")
        println(stdout, " ****************************************************************************************************")
        println(stdout, "")

    end_if    

end_body

