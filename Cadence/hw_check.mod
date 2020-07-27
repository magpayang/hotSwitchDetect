--------------------------------------------------------------------------------
-- Filename:
--     hw_check.mod
--
-- Purpose:
--     Routines to support the hardware checking.
--
-- Routines:
--
--     Board_HW_name_check                 -- See if this is the right board for this device
--     Empty_socket_check                  -- Check for empty socket.
--     Empty_socket_check_msg              -- Print message if it is not empty.
--     Determine_Checker_Result		   -- Set Checker_PASS flag based on value of OpVar_CheckerSite_Fail.
--     Halt_OnLoad_Flow			   -- Halts OnLoad flow safely when loadboard ID check fails and OpVar_FlowEnableOverride is FALSE.
--     Track_HWChecker_BoolTestResults     -- Update fail flag based on results of last test_value statement
--     Track_HWChecker_FloatTestResults    -- Update fail flag based on results of last test_value statement
--     Track_HWChecker_IntTestResults      -- Update fail flag based on results of last test_value statement
--     Determine_Checker_Result            -- Determines which exit port is used in TestFixture_Checker testblock
--     Determine_HWNameCheckResult         -- Determines value of OpVar_HWNameCheckResult and uses it in logic for 
--                                         -- exit port of Check_HWName_Result testblock.
--
-- History:
--     02/22/2010  pla            -- Initial Version
--     05/26/2011  pla            -- Latest version - see each procedure for documented changes.
--     12/07/2011  pla            -- Latest version - see each procedure for documented changes.
--     01/31/2012  pla            -- Latest version - see each procedure for documented changes.
--                                -- Made module globals private in order to avoid clashes with other modules  
--
-- Operator variables:
--     OpVar_HardwareName              -- Used by Board_HW_name_check
--     OpVar_CheckerSite_Fail
--     OpVar_HWNameCheckResult
--     
--
-- Globals:

private
    global
      multisite boolean : socketEmpty
    end_global

    static
        word list[MAX_SITES]                        : SITES_TO_DISABLE
    end_static
end_private

-- Import optional module to store global variables
use module "user_globals.mod"
use module "user_digital.mod"
use module "FlowControl.mod"
use module "./lib/lib_HP3458A_gpib.mod"
use module "FPGA.mod" --03/26/2020 add FPGA module
-- Import standard operator interface
use module "/testeng/testprog/loc/cardcat/ltx_mx/libraries/lib_operator_prompt/lib_operator_prompt.mod"

-- General library routines
use module "./lib/lib_common.mod"
use module "./lib/ppmu_ctrl.mod"

-- Import Main code routines
--use module "MAX92755.tp"

--------------------------------------------------------------------------------


function Board_HW_name_check(bypass) : boolean

in boolean : bypass  -- bypass check and return true

-------------------------------------------------------------------------------------------
-- Description:
--     Reads the EEPROM HW Name to see if it matches OpVar_HardwareName specified by the test engineer.  
--     Returns TRUE if the HW Name in the EEPROM matches OpVar_HardwareName.
--
-- History:
--     01/10/2010  Pamela Abela            -- Corrected to logic compare HWName read during OperatorPrompt
--                                         -- to stored OpVar_HardwareName 
--     02/22/2010  Pamela Abela            -- set OpVar_HWNameCheckResult to function return value
--     12/07/2011  Pamela Abela            -- Add logic to override bypass == TRUE when in production environment
--
-- Global variable usage:
--     TestProgData.OptoolMode (enVision)
--
-- Operator variable usage:
--      OpVar_HardwareName - should be something like "AC54/CL DUAL SITE"
--      OpVar_HWNameCheckResult
-------------------------------------------------------------------------------------------

local
   boolean            : checkOK = FALSE
   string[MAX_STRING] : opvarHWName
   integer            : OptoolMode   -- Return value for engineering mode check (0=Production)

end_local

body

    get_expr("TestProgData.OptoolMode", OptoolMode)   -- Determine if engineer/production mode

    if (bypass and (OptoolMode <> 0 )) or tester_simulated then
        checkOK = TRUE
    else
        get_expr("OpVar_HardwareName",opvarHWName)

        -- get loadboard name read during Operator Prompting and store it in variable Stored_HardwareName
        Get_LB_Name()          

        -- Remove white spaces and special characters that cause false failures in string comparison
        Strip_off_special_chars (opvarHWName)
        Strip_off_special_chars (Stored_HardwareName)

        if Stored_HardwareName == opvarHWName then   
            checkOK = TRUE
        else         
            checkOK = FALSE                    -- board is not the right one for this device OR EEPROM is either not programmed or compromised.
            Print_banner_message( "INCORRECT BOARD OR BOARD EEPROM NOT PROGRAMMED", "Testing is disabled", "Please unload, install the correct board, and reload the program" )
        end_if
    end_if --bypass

    set_expr("OpVar_HWNameCheckResult", checkOK)

    return( checkOK )
        
end_body

function Empty_socket_check( Analog_plist, IRange_Ana, Dig_pin, IForce_Dig, VClamp_Dig, Meas_Average, ExitState_Dig, EmptySocket_Icc_limits ) : boolean

in pin list[VI16_MAX]       : Analog_plist   -- Optional parameter
in float                    : IRange_Ana    
in pin                      : Dig_pin
in float                    : IForce_Dig
in float                    : VClamp_Dig
in word                     : Meas_Average
in string[MAX_STRING]       : ExitState_Dig
in_out array of float_test  : EmptySocket_Icc_limits


--------------------------------------------------------------------------------
-- Description:
--     This test performs ppmu contact test on a single digital pin to determine if there is a part 
--     in the socket.  Analog_plist is optional parameter in case you need to set some VI resources
--     to 0.0V on a specific device. 
--     
-- History:
--  03/19/2010  Pamela Abela     -- Initial Version 
--  05/25/2011  Pamela Abela     -- Added null pinlist check for Analog_plist
--                               -- Changed size of Analog_plist from 16 to constant declared in user_globals.mod    
--  12/12/2011  PLA              -- Initialize failFlag to FALSE
--  01/31/2012  PLA              -- Changed inline ppmu statements to procedure call from ppmu_ctrl.mod
--                               -- Changed hard-coded current/voltage/connection settings to passed in parameters
--                               -- Added 'Dependencies' and 'Side Effects' sections to comment 
--  07/28/2015  Massimo Mandrino -- socketEmpty variable assigned to false based on comparison towards both test limits
                                   
-- Operator variables:
--     None
--
-- Globals:
--     VI16_MAX - constant declared in user_globals.mod
--     MAX_STRING - System-defined constant

-- Dependencies:
--     PPMU must not be connected to Dig_pin on entry to this function
--     Dig_Pin must be a single pin defined in enVision

-- Side effects:
--     Dig_pin DCL and PPMU will be unconnected upon exit of function
--     To change this effect, change the "ExitState_Dig" string value used by ppmu_connect_meas_FIMV() 
--------------------------------------------------------------------------------

local
  multisite float       : vMeas[1]
  boolean               : failFlag=FALSE
  integer               : listIndex
  word                  : thisSite
  pin list[1]           : SinglePinList
  float                 : vclamp_min
end_local

body

  --Check for existence of Analog_plist before setting pin conditions  
    if Analog_plist <> <::> then
        connect ps Analog_plist remote
        set ps Analog_plist to fv 0.0V measure i max IRange_Ana clamp imax IRange_Ana imin 0.0mA
        gate ps Analog_plist on  
    end_if

--Create pinlist from single pin passed in to procedure
    SinglePinList = pin_to_pin_list(Dig_pin)

--Determine minimum voltage clamp for digital pin
    if VClamp_Dig > 2.0V then
        vclamp_min = -1.999V
    else    
        vclamp_min = -VClamp_Dig
    end_if
    
--     -- Connect ppmu to Digital pin and FIMV
--     disconnect pin Dig_pin from dcl
--     connect ppmu Dig_pin to fi 100uA imax (100uA *1.2) measure v max 2.0V clamps to vmin -2.0V vmax 2.0V delay 1ms
--     wait (10ms)
--     measure digital ppmu Dig_pin voltage vmax 2.0V average 10 into vMeas

    -- Ensure Digital pin resource is unconnected
    disconnect pin Dig_pin from dcl

    -- Connect ppmu to Digital pin and FIMV
    ppmu_connect_meas_FIMV(SinglePinList, IForce_Dig, (IForce_Dig *1.2), 1, vclamp_min, VClamp_Dig, 10ms, Meas_Average, vMeas, "DISCONN" , 0ms , ExitState_Dig , 0ms)

    -- Determine if the socket is empty
    test_value vMeas with EmptySocket_Icc_limits
    failFlag = Track_HWChecker_FloatTestResults( EmptySocket_Icc_limits )

    socketEmpty = True  -- Initialize flag to TRUE (socket empty) for all sites
    --------------------------------------------------------------------
    -- failFlag == TRUE then we know one or more sites are not empty
    -- Determine which are NOT empty and set flag to FALSE (NOT empty)    
    --------------------------------------------------------------------
    if failFlag then 
        for listIndex = 1 to len(active_sites) do
            thisSite = active_sites[listIndex]
            if (vMeas[thisSite,1] < float(EmptySocket_Icc_limits[1].low_limit[thisSite])) or (vMeas[thisSite,1] > float(EmptySocket_Icc_limits[1].high_limit[thisSite])) then
                socketEmpty[thisSite] = False
            end_if
        end_for
    end_if
     
--   -- Disconnect resources
--     set ppmu Dig_pin to fi 0.0A imax 1uA measure v max 2.0V delay 1mS
--     disconnect digital pin Dig_pin from ppmu delay 0.0mS

  --Check for existence of Analog_plist before setting pin conditions  
    if Analog_plist <> <::> then
        gate ps Analog_plist off
        disconnect ps Analog_plist   
    end_if
    
    return(NOT failFlag)

end_body

procedure Empty_socket_check_msg

--------------------------------------------------------------------------------
-- Description:
--     This procedure prints out a message that the socket is not empty.
--     
-- History:
--     mm/dd/yyyy  username            -- Comments
--     12/12/2011  PLA                 -- Moved declaration of socketEmpty to top of file     
--
-- Operator variables:
--     None
--
-- Globals:
--     None
--------------------------------------------------------------------------------

                                                                                                                                      
local
  word              : thisSite
  integer           : listIndex
end_local
                                                                                                                                      
body
                                                                                                                                      
-- Get the active sites,
-- then initiate a loop over each one.
  active_sites = get_active_sites
  for listIndex = 1 to len(active_sites) do
      thisSite = active_sites[listIndex]
      if not socketEmpty[thisSite] then
          Print_banner_message( "SOCKET NOT EMPTY", "Remove the device from site " + sprint(thisSite), "")
    end_if
  end_for
                                                                                                                                      
end_body
                                                                                                                                      
function Determine_Checker_Result : boolean
--------------------------------------------------------------------------------
-- 
 
-------------------------------------------------------------------------------------------
-- Description:
--     Determines PASS result of checker by reading the status of OpVar_CheckerSite_Fail.
--     If FALSE, then no sites failed - ALL SITES PASS.  
--     Global Checker_PASS is set to NOT (OPVar_CheckerSite_Fail) 
--     If Checker_PASS is TRUE, then OpVar_Force_HW_Check is set to FALSE
--     If Checker_PASS is FALSE, then next time OnStart flow is run, the HW_Check flow will run again.
--
--     Checker_PASS is returned - TRUE/PASS means exit port 0 is used - otherwise exit port 1 is used.
--
-- History:
--     02/22/2010  Pamela Abela            -- Initial version
--
-- Global variable usage:
--        Checker_PASS
--
-- Operator variable usage:
--        OpVar_CheckerSite_Fail
-------------------------------------------------------------------------------------------

local

    boolean :   failFlag
  
end_local

body

    get_expr("OpVar_CheckerSite_Fail", failFlag)

    Checker_PASS = NOT failFlag
    
    return(Checker_PASS)

end_body


procedure Halt_OnLoad_Flow -- : boolean
-------------------------------------------------------------------------------------------
-- Description:
--     Halts OnLoad flow safely when loadboard ID check fails and OpVar_FlowEnableOverride is FALSE.  
--
-- History:
--     02/22/2010  Pamela Abela            -- Initial version
--     03/19/2010                          -- Added comments
-- Global variable usage:
--     none
--
-- Operator variable usage:
--
--      OpVar_FlowEnableOverride
--      OpVar_FlowEnable
-------------------------------------------------------------------------------------------

local

end_local

body

--   Sets FlowEnable Operator Variables to known condition - FALSE 
    Set_FlowEnable_False()        

    halt  -- abort OnLoad and run OnFault flow 
    
    
    --***************************************************************
    -- Important NOTE:   The BIF Help for the halt command states that
    --                   the OnHalt_Flow runs after a call to "halt".  
    --                   This is NOT true, as the OnHalt_Flow is 
    --                   unsupported as of R15.4.0.  The OnFault_Flow
    --                   will run instead.
    --
    --                   During program unload, the OnUnload_Flow will
    --                   NOT run after a halt condition.
    --***************************************************************
 
end_body

function Track_HWChecker_FloatTestResults( Checker_Test )  : boolean
--------------------------------------------------------------------------------
--  

in_out array of float_test  : Checker_Test

-------------------------------------------------------------------------------------------
-- Description:
--     Tracks PASS/FAIL status of checker test by updating a local fail flag and returning it.
--     Call after each instance of test_value that uses array of float_test in test. 
--
-- History:
--     02/22/2010  Pamela Abela            -- Initial version
--     12/12/2011  PLA                     -- Initialize failFlag to FALSE
--
-- Global variable usage:
--     sites
--     active_sites
--
-- Operator variable usage:
--
-------------------------------------------------------------------------------------------



local
    integer     : size, testCount
    word        : siteCount
    integer     : singleTestResults = 0
    boolean     : failFlag=FALSE, interimFailFlag

end_local

body

    active_sites = get_active_sites
    sites = word(len(active_sites))

    size = dimsize(Checker_Test,1)

    for testCount=1 to size do
        singleTestResults = 0
        interimFailFlag = FALSE
        for siteCount=1 to sites do
            singleTestResults = singleTestResults + Checker_Test[testCount].test_result[siteCount]
        end_for                                                       
        if singleTestResults <> integer(sites) then                   
            interimFailFlag = TRUE
        end_if
        failFlag = failFlag OR interimFailFlag
    end_for

return(failFlag)

end_body
function Track_HWChecker_IntTestResults( Checker_Test )  : boolean
--------------------------------------------------------------------------------
--  

in_out array of integer_test  : Checker_Test

-------------------------------------------------------------------------------------------
-- Description:
--     Tracks PASS/FAIL status of checker test by updating local fail flag and returning it.
--     Call after each instance of test_value that uses array of integer_test in test. 
--
-- History:
--     02/22/2010  Pamela Abela            -- Initial version
--
-- Global variable usage:
--     sites
--     active_sites
--
-- Operator variable usage:
--
-------------------------------------------------------------------------------------------

local
    integer     : size, testCount
    word        : siteCount
    integer     : singleTestResults = 0
    boolean     : failFlag, interimFailFlag


    
end_local

body

    active_sites = get_active_sites
    sites = word(len(active_sites))

    size = dimsize(Checker_Test,1)
    for testCount=1 to size do
        singleTestResults = 0
        interimFailFlag = FALSE
        for siteCount=1 to sites do
            singleTestResults = singleTestResults + Checker_Test[testCount].test_result[siteCount]
        end_for    
        if singleTestResults <> integer(sites) then
            interimFailFlag = TRUE
        end_if
        failFlag = failFlag OR interimFailFlag
    end_for

return(failFlag)

end_body
function Track_HWChecker_BoolTestResults( Checker_Test )  : boolean
--------------------------------------------------------------------------------
--  

in_out array of boolean_test  : Checker_Test

-------------------------------------------------------------------------------------------
-- Description:
--     Tracks PASS/FAIL status of checker test by updating local fail flag and returning it.
--     Call after each instance of test_value that uses array of bool_test in test. 
--
-- History:
--     02/22/2010  Pamela Abela            -- Initial version
--
-- Global variable usage:
--     sites
--     active_sites
--
-- Operator variable usage:
--
-------------------------------------------------------------------------------------------

local
    integer     : size, testCount
    word        : siteCount
    integer     : singleTestResults = 0
    boolean     : failFlag, intFailFlag
    

    
end_local

body

    active_sites = get_active_sites
    sites = word(len(active_sites))

    size = dimsize(Checker_Test,1)
    for testCount=1 to size do
        singleTestResults = 0
        intFailFlag = FALSE
        for siteCount=1 to sites do
            singleTestResults = singleTestResults + Checker_Test[testCount].test_result[siteCount]
        end_for    
        if singleTestResults <> integer(sites) then
            intFailFlag = TRUE
        end_if
        failFlag = failFlag OR intFailFlag
    end_for

return(failFlag)

end_body

function Determine_HWNameCheckResult : boolean
--------------------------------------------------------------------------------
-- 
 
-------------------------------------------------------------------------------------------
-- Description:
--     This test is a safety mechanism to prevent Start of Test if the wrong board was installed,
--     causing premature halt of OnLoad flow.  In this case, the tester in not ready for test.
--
--     Determine result of HW Name Check test by reading value of OpVar_HWNameCheckResult and
--     returning it.  This return value is used to determine which exit port is used in testblock.
--     TRUE/PASS means exit port 0 is used - otherwise exit port 1 is used.
--
-- History:
--     02/22/2010  Pamela Abela            -- Initial version
--
-- Global variable usage:
--
-- Operator variable usage:
--     OpVar_HWNameCheckResult

-------------------------------------------------------------------------------------------

local

    boolean     : NameCheckPass
    
end_local

body

    get_expr("OpVar_HWNameCheckResult", NameCheckPass)

    return(NameCheckPass)

end_body

procedure HWCHK_Cal_PPMU_fi_with_DVM( ppmu_plist , iForce , RawLim , CalLim )
--------------------------------------------------------------------------------
--  Calibrate the PPMU used for LMN force-current by forcing a current with the
--      PPMU and measuring that current using the DVM (HP3458A)
--
-- Required: HP3458A DVM must have the APPS cable connected on SPC and SSIP testers
--
-- Globals/Statics: user_globals.mod -> gCAL_LMN_IFRC
--------------------------------------------------------------------------------
in pin list[4]                                  : ppmu_plist
in float                                        : iForce
in_out array of float_test                      : RawLim , CalLim
local
    multisite float                             : iRaw[4]
    float                                       : iClamp
    
    double                                      : iMeter

    word list[MAX_SITES]                        : actv, wlist
    word                                        : nSites, sidx, current_site, pchan
    integer                                     : pnum, nPins
    pin                                         : this_pin
    
    integer                                     : DEBUG = 0     -- 0:off, 1:normal prints, 2:sweep multiple currents
end_local

body
    DEBUG = 1
    deactivate sites SITES_TO_DISABLE
    actv = get_active_sites()
    nSites = word(len(actv))
    nPins  = len(ppmu_plist)

    iClamp = 1.1*abs(iForce)

    if DEBUG>0 then
        println(stdout, "@n", "CALIBRATE LMN PPMU: ":-64 , "IN PROGRESS")
    end_if
    gLMN_PMU_CAL_FAIL  = false
    ----------------------------------------------------------------
    -- prepare the PPMU
    ----------------------------------------------------------------
    enable digital ppmu ppmu_plist fv 0V vmax 5V measure i max iClamp
    set digital ppmu ppmu_plist to fv 0V vmax 1V measure i max iClamp
    disconnect digital pin ppmu_plist from dcl
    connect digital pin ppmu_plist to ppmu
    set     digital pin  ppmu_plist modes to driver off load off
    connect digital ppmu ppmu_plist to fv 0V vmax 1V measure i max iClamp

    disconnect ovi chan <:1:> from cal bus                          -- in case this was left on during the cable check

    ----------------------------------------------------------------
    -- prepare the DVM-to-CALBUS and CALBUS-to-ABUS connections
    ----------------------------------------------------------------
    connect cx abus1 to cal force low                               -- connects cal bus to abus
    connect cx abus2 to cal sense low
    connect cx abus3 to cal force high 
    connect cx abus4 to cal sense high 

    if false then
        -- connects abus to dut board "ANALOG1-4" pins (relays K31-K34 in CX_bus.pdf pg51)
        -- use this only if I want to be able to measure 
        connect cx abus1 to dut cage0                               
        connect cx abus2 to dut cage0
        connect cx abus3 to dut cage0
        connect cx abus4 to dut cage0
    end_if

    ----------------------------------------------------------------
    -- go thru pins and sites, and calibrate them all
    ----------------------------------------------------------------
    for pnum = 1 to nPins do
        this_pin = ppmu_plist[pnum]
        wlist = dp_ptc(this_pin)
        
        connect digital ppmu this_pin to fi 1pA imax iClamp clamps to vmin -0.3v vmax 3.9v
        
        for sidx = 1 to nSites do
            current_site = actv[sidx]
            pchan = wlist[sidx]

            -- connect HP3458 DVM HighForce to the calbus in cage0 (0-127) or cage1 (128-255)
            if pchan < 128 then
                connect cx dvm to cal bus cage0 measure i
            else
                connect cx dvm to cal bus cage1 measure i
            end_if

            close   digital pin this_pin on site current_site fx1 relay bus                 -- bus relay for digital pin
            close   digital pin this_pin on site current_site fx1 relay calbuslo            -- LO relay
            connect digital pin this_pin on site current_site to calbushi                   -- HI relay
--            set digital ppmu this_pin on site current_site to fi iForce imax 20uA clamps to vmin -0.3v vmax 3.9v -----             
            set digital ppmu this_pin on site current_site to fi iForce imax 20uA clamps to vmin -1.0v vmax 3.9v -----  DO pins need more than -0.3V otherwise, cal off by more than 200nA MT 7/20/2019
            wait(5ms)
            iMeter = Measure_HP3458A_current(18, 2, HP_METER)

            iRaw[current_site , pnum] = float(iMeter)            
            gCAL_LMN_IFRC[current_site , pnum] = float(iMeter) - iForce
            if DEBUG>0 then
                println(stdout, "s", current_site:-1, ".PPMU( ", get_pin_name( ppmu_plist[pnum] ):-16, "):", pchan:-8, iMeter!fu=uA:12:3, "  -  ", iForce!fu=uA:12:3, "@t=@t", gCAL_LMN_IFRC[current_site, pnum]!fu=nA:12:3 )
                if DEBUG>1 then
                    println(stdout)
                end_if
            end_if

            if DEBUG>1 then
                local integer: loop
                for loop = -11 to 11 do
                    iForce = float(loop)/11. * iClamp
                    if loop==0 then
                        iForce = 1pA
                    end_if
 --                   set digital ppmu this_pin on site current_site to fi iForce imax 20uA clamps to vmin -0.3v vmax 3.9v
                    set digital ppmu this_pin on site current_site to fi iForce imax 20uA clamps to vmin -1.0v vmax 3.9v
                    wait(5ms)
                    iMeter = Measure_HP3458A_current(18, 2, HP_METER)
                    println(stdout, "s", current_site:-1, ".PPMU( ", get_pin_name( ppmu_plist[pnum] ):-16, "):", pchan:-8, iMeter!fu=uA:12:3, "  -  ", iForce!fu=uA:12:3, "@t=@t", float(iMeter) - iForce!fu=nA:12:3 )                    
                end_for
                println(stdout)
            end_if

            set digital ppmu this_pin on site current_site to fi 1pA imax 20uA clamps to vmin -0.3v vmax 3.9v
            open digital pin this_pin on site current_site fx1 relay bus
            open digital pin this_pin on site current_site fx1 relay calbuslo
            disconnect digital pin this_pin on site current_site from calbushi
            disconnect cx dvm from cal bus

        end_for
        
    end_for -- pnum

    if DEBUG>0 then
        println(stdout, "@n")
    end_if
    
    ----------------------------------------------------------------
    -- cleanup DVM, ABUS, CALBUS connections
    ----------------------------------------------------------------
    disconnect cx dvm from cal bus
    disconnect cx abus1 from cal force low
    disconnect cx abus2 from cal sense low
    disconnect cx abus3 from cal force high
    disconnect cx abus4 from cal sense high
    disconnect cx abus1 from dut all cages
    disconnect cx abus2 from dut all cages
    disconnect cx abus3 from dut all cages
    disconnect cx abus4 from dut all cages
    disconnect cx abus1 from all cages
    disconnect cx abus2 from all cages
    disconnect cx abus3 from all cages
    disconnect cx abus4 from all cages

    ----------------------------------------------------------------
    -- datalog
    ----------------------------------------------------------------
    test_value iRaw with RawLim
    test_value gCAL_LMN_IFRC with CalLim

    -- HW CHECKER
    print(stdout, "CALIBRATE LMN PPMU: ":-64 )
    if Track_HWChecker_FloatTestResults( CalLim ) then
        println(stdout, "FAILED!")
        println(stdout, ">>@tCheck DigitalPin PPMU calibration, or relay paths between DUT MFP7/8/9/10 and DigitalPins@t<<")
        gLMN_PMU_CAL_FAIL = true

    else
        println(stdout, "PASSED")
    end_if
end_body



procedure test_HWBrdTstrSN (testData, StuckEnableLim )
--------------------------------------------------------------------------------
--  Report board serial number
--------------------------------------------------------------------------------
in_out array of float_test      : testData
in_out integer_test             : StuckEnableLim 
local
    integer                     : TESTER_NUM
    integer                     : Brd_Num   
    multisite float             : TesterNumber
    multisite float             : BoardNumber
    string[MAX_STRING]          : DummyString1
    string[MAX_STRING]          : DummyString2
    string[MAX_STRING]          : DummyString3

    multisite lword             : fpga_read_data
    multisite float             : my_float
    multisite float             : dlog[5]
    multisite integer           : isStuckEnabled
end_local

body

    TESTER_NUM =  get_tester_number()
    TesterNumber = float(TESTER_NUM)
    scatter_1d (TesterNumber , dlog , 1)

    RW_Maxim_EEPROM_Data(READ_EEPROM, 1, DummyString1, DummyString1, DummyString2, Brd_Num)
    BoardNumber = float(Brd_Num)
    scatter_1d ( BoardNumber , dlog , 2)

    -- Readback Firmware Revision
    fpga_read_data = fpga_read_register( "FPGA1" , FWREV_REG )
    my_float = float( fpga_read_data )
    scatter_1d( my_float , dlog , 3 )
    
    
    test_value dlog with testData
    
    
    ---- hcu 03/26/2020 datalog during prod if stuck detect was enabled
    get_expr("OpVar_StuckDetect", StuckDetect)    
    if OptoolModeCheckStatic == 0 then       
        if StuckDetect then
            isStuckEnabled = 1
            LoopCntr = 1                                   -- Re-initialize the value of v when OpVar_StuckDetect was manually set to TRUE
        else
            isStuckEnabled = 0
            println(stdout, "@nLOOPTEST COUNTER: ",LoopCntr," of 35")
        end_if
    test_value isStuckEnabled with StuckEnableLim
    end_if
    
end_body

function get_tester_number :   integer
--------------------------------------------------------------------------------
-- Returns the tester number.

local
    string[128]     : testername  --String that contains the full tester name.
    integer         : tester_number    --Contains the test number from the testername.
    integer         : x
    integer         : num, first_num, last_num
end_local

body
    tester_number = 0
    num = 0
    x = 0
    first_num = 0

    if(tester_simulated) then
      return(tester_number)
    end_if
    
    testername=tester_name
    num = len(testername)
    
    --Searches for the first number in the array.
    for x = 1 to num do
        tester_number = asc(testername[x])
        if tester_number >= 48 AND tester_number <= 57 then
           break
        end_if
    end_for
    first_num = x

    --Searches for the last number.
    for x = first_num+1 to num do
        tester_number = asc(testername[x])
        if tester_number < 48 OR tester_number > 57 then
           break
        end_if
    end_for    
    last_num = x - 1
    --Error Checking
    if (last_num <= 0) then
       last_num = 1
    end_if

    tester_number = integer(testername[first_num:last_num])
    return(tester_number)
end_body

