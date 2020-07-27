-------------------------------------------------------------------------------------------
--                                  REVISION LOG                                         --
--                                                                                       --
-- Filename: user_globals.mod
--
-- Purpose:
--     Declaraction/initialization of global contants and variables.  Control logic for first_run.
--
-- Procedures and functions included in this file
--     Set_Cadence_enVision_Constants
--     Set_Cadence_OpVar_variables
--     Multisite_first_run_Control_Start
--     Multisite_first_run_Control_Stop
--     Set_STDF_Parameters
--
-- History:
--     04/16/2010  pla            -- Initial version
--     05/26/2011  pla            -- Changed FastBin State on "first_run" to TRUE
--                                -- Changed FC_bool parameter to Store_FBin_State for readability 
--     06/15/2011  pla            -- Added Set_STDF_Parameters procedure to populate certain STDF parameters
--
-- Operator variables used:
--    Set_Cadence_OpVar_variables:
--        OpVar_TestTemp
--        OpVar_TestType 
--
--    Set_STDF_Parameters:
--        OpVar_DieType
--
--------------------------------------------------------------------------------

use module "./lib/lib_common.mod"

const
  
  -- General Constants
    PI = rad(180.0)
    ON = TRUE
    OFF = FALSE
    OVI_MAX             = 24
    VI16_MAX            = 256
    MAX_DP_PINS         = 192


    SER_ID  = 0x80
    DESA_ID = 0x90
    DESB_ID = 0x94
    SER_DNUT_ID = 0x00----- Need to check on this one later
    PROG_OSC = 0xB4
    PORT_EXP = 0xDA
    
    SYS_CLK = 150.0e6

end_const

    


static

    word list[MAX_SITES]   : active_sites 
    word list[MAX_SITES]   : current_active_sites
    word                   : sites
    boolean                : eng_debug = FALSE
--    boolean                : first_run  - JC - remove
    boolean                : global_setup = FALSE
    string[20]             : test_type
    float                  : last_vdd   
    string[20]             : temp_setting  
    integer                : Retest_int 
    word list[MAX_SITES]   : EndFlowLiveSites  
    word list[MAX_SITES]   : InitFlowLiveSites  
    word                   : InitSites   
    boolean                : Store_FBin_State  
    boolean                : FBin_First_Run = TRUE
    boolean                : AllSitesStored 
    integer                : NUM_SITES  --populated by enVision global value during OnLoad

    boolean                : DEBUG_REG_RW = false
    multisite float         : gCAL_LMN_IFRC[4]  -- calibrate each of the four LMN pins near the -5u force; when forcing current, use iForceTarget-gCAL_LMN_IFRC
    integer                : LoopCntr =1, OptoolModeCheckStatic --03/26/2020 StuckUp Detect Variables
    boolean                :StuckDetect, ChDevIns -- 03/26/2020 Stuck Up Detect Variables    
end_static

global
  
  word                : idx
  word                : i, j, k


  float               : vdd_global[3]  -- [SER_IOVDD=vdd_global[1], SER_VDD=vdd_global[2], SER_VDDA=vdd_global[3]]
  float               : OSC_FREQ       -- stores current value of programmable oscillator frequency
--  integer             : char_site = 2
  string[8]           : mode1          -- mode to latch (COAX or TP)
  string[8]           : mode2          -- UART or I2C
  boolean             : CHAR
  word                : csite
  string[25]          : DEVICE
  float               : UART_FREQ
  float               : I2C_FREQ
 multisite lword      : RdWordUpper, RdWordLower
  multisite integer   : bin73cnt
  boolean             : GPIO_Debug
  boolean             : Reload_GPIO_Patterns
  boolean             : gLMN_PMU_CAL_FAIL
  
   multisite integer      : PrevDevCode, StuckCounter, CurDevCode
end_global


procedure Set_Cadence_OpVar_variables
--------------------------------------------------------------------------------
--  

local

    string[10]  : retestState

end_local

body

    -- pla Set the variable "temp_setting" to the correct Temperature string value for the current DUT.
    get_expr("OpVar_TestTemp", temp_setting) -- Set temp_setting to the value of OpVar_TestTemp 

    -- pla Set the variable "temp_type" to the correct string value for the current DUT.
    get_expr("OpVar_TestType", test_type) -- Set temp_type to the value of OpVar_TestType 

    -- pla This function sets the variable "Retest_int" to the correct string value for the current DUT.
    get_expr("OpVar_ReTest", retestState) -- Set retest_state to the value of OpVar_ReTest 
    if retestState = "0" then
        Retest_int = 0
    else
        Retest_int = 1
    endif        

end_body

procedure Set_Cadence_enVision_Constants
--------------------------------------------------------------------------------
--  

local

end_local

body

    get_expr("NUM_SITES", NUM_SITES)    

end_body

procedure Multisite_first_run_Control_Start
--------------------------------------------------------------------------------
--  
--------------------------------------------------------------------------------
-- DESCRIPTION
-- This is one of a pair of routines that work in tandem with the first_run variable as a test-time
-- enhancement, while countering the handler's activation/deactivation of sites in multisite programming.
-- 
-- TT enhancement : Code that should only be executed during the "first_run" can be placed inside loops 
--                  use first_run == TRUE as condition for running.
--
-- Additional logic added to counter handler's activation/deactivation of sites:    
--                  If we still have the same sites active at the end as were active at start
--                  then we deassert the first_run variable.
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- DEPENDENCIES
--
-- first_run: Global variable initialized to TRUE in the Global_Init procedure 
--            during OnLoad Flow.   
--------------------------------------------------------------------------------

local

end_local

body
    -- get BinTool active sites to determine status for first_run de-assert
    active_sites = get_active_sites
    sites = word(len(active_sites))

-- End variable initialization

--=========================================================================================================
    -- Logic to counter handler's activation/deactivation of sites.    

    -- InitFlowLiveSites and InitSites variables are initialized in this procedure on first_run.

    --First time through the next if statement will not run.  It is in place for later runs, where active 
    --sites change from previous run, and all sites reusable variables were not previously 
    --stored.  In this case, the first_run flag is set to true, and reusable code is run for the 
    --active sites.
--=========================================================================================================
    
    if NOT first_run AND NOT AllSitesStored then
        if NOT active_sites = InitFlowLiveSites then
            first_run = true
        end_if
    end_if        
    
--=========================================================================================================
   -- Added logic to counter handler's activation/deactivation of sites. 
   
    --First time through this code section will run.  After that, this code section will run if both
    --of these 2 statements are true: 
    --1. All sites have never previously been active at the same time during the current runtime 
    --   session (AllSitesStored = false).
    --2. The number of active sites has not changed since last run; however the actual active sites are different.
    
    -- In addition, this code section will run if these 2 statements are true:
    --1. The number of active sites changes. 
    --2. All sites have never previously been active at the same time during the current runtime 
    --   session (AllSitesStored = false).

    -- Once all sites are run through to the end of the flow, AllSitesStored flag is set to true.
    -- If AllSitesStored=true, then switching between various active/deactive states on sites will
    -- not cause the reusable code to be re-run.
    
    -- When this next code section runs, the current FastBinning state is saved to the Store_FBin_State variable.
    -- Then FastBinning is temporarily set to value of FBin_First_Run during the "first run" code set.
    -- If FBin_First_Run == TRUE (default) then all sites that were active at the start of the OnStart flow 
    -- (InitFlowLiveSites) must PASS (Bin 1) for first_run to change to FALSE; i.e.,
    --                     InitFlowLiveSites == EndFlowLiveSites  
    --  At this point, FastBinning is set back to the stored state (Store_FBin_State).
    
    -- If value of FBin_First_Run is changed to FALSE, this means that all sites active at the start of OnStart
    -- flow (InitFlowLiveSites) will be active at the end of the flow (EndFlowLiveSites), even if failing, 
    -- since FastBinning is FALSE.  Therefore, InitFlowLiveSites == EndFlowLiveSites.
    -- At the end of the OnStart flow, FastBinning is set back to the stored state (Store_FBin_State). 
--=========================================================================================================

    if first_run then
        InitFlowLiveSites = active_sites
        InitSites = word(len( InitFlowLiveSites ))
        get_expr("TestProgData.evFastBinning", Store_FBin_State )
        set_expr("TestProgData.evFastBinning", FBin_First_Run )
    end_if


end_body

procedure Multisite_first_run_Control_Stop
--------------------------------------------------------------------------------
--  
--------------------------------------------------------------------------------
-- DESCRIPTION
-- This is one of a pair of routines that work in tandem with the first_run variable as a test-time
-- enhancement, while countering the handler's activation/deactivation of sites in multisite programming.
-- 
-- TT enhancement : Code that should only be executed during the "first_run" can be placed inside loops 
--                  use first_run == TRUE as condition for running.
--
-- Additional logic added to counter handler's activation/deactivation of sites:    
--                  If we still have the same sites active at the end as were active at start
--                  then we deassert the first_run variable.
--
-- InitFlowLiveSites and InitSites variables are initialized in the Multisite_first_run_Control_Start
-- procedure, called in the OnInit_Connect procedure during the OnInit Flow.
--------------------------------------------------------------------------------


--------------------------------------------------------------------------------
-- DEPENDENCIES
--
-- NUM_SITES: Constant in Globals_Spec set to loadboard maximum number of sites.
-- OpVar_DieType:     String variable expected to exist in Operator Variables 
--                    list populated with correct DieType string
--------------------------------------------------------------------------------
     
local

end_local

body

    EndFlowLiveSites = get_active_sites  
      
        if first_run then 
            if EndFlowLiveSites = InitFlowLiveSites then          
                first_run = false
                set_expr("TestProgData.evFastBinning", Store_FBin_State )
                if InitSites = word(NUM_SITES) then
                    AllSitesStored = true
                end_if    
            end_if
        else_if AllSitesStored then
            first_run = false
        else    
            if NOT EndFlowLiveSites = InitFlowLiveSites then 
                first_run = true  
            end_if
        end_if

end_body

procedure Set_STDF_Parameters
--------------------------------------------------------------------------------
--  
--------------------------------------------------------------------------------
-- DESCRIPTION
-- This procedure populates certain TestProgData parameters with the proper 
-- data for STDF datalogging of same parameters.
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- DEPENDENCIES
--
-- STDF_SPEC_VERSION: String constant expected to exist in Global_Spec object
-- OpVar_DieType:     String variable expected to exist in Operator Variables 
--                    list populated with correct DieType string
--------------------------------------------------------------------------------

local

    String[MAX_STRING] : stdf_spec_version = ""
    String[MAX_STRING] : family_id = "" 
    String[1]          : test_mode = ""
    integer            : optool_mode

end_local

private const ENG_MODE = "E"
private const PROD_MODE = "P"

body

    -- Populate TestProgData member used to fill STDF parameter MIR.SPEC_VER
    get_expr("STDF_SPEC_VERSION", stdf_spec_version)
    set_expr("TestProgData.TestSpecRev", stdf_spec_version)
    
    -- Populate TestProgData member used to fill STDF parameter MIR.FAMILY_ID
    get_expr("OpVar_DieType", family_id)
    set_expr("TestProgData.ProdId", family_id)

    -- Populate TestProgData member used to fill STDF parameter MIR.MODE_COD
    get_expr("TestProgData.OptoolMode", optool_mode)
    if (optool_mode == 0 ) then
        set_expr("TestProgData.TestMode", PROD_MODE)
    else_if (optool_mode == 1) then
        set_expr("TestProgData.TestMode", ENG_MODE)
    else
        set_expr("TestProgData.TestMode", ENG_MODE)
        optool_mode = 1
        set_expr("TestProgData.OptoolMode", optool_mode)
        Print_banner_message( "Error in Set_STDF_Parameters procedure", "OpTool Mode s/b set to either '1 - ENG' or '0 - PROD'", "Actual setting of OpTool Mode is " + sprint(optool_mode) + "- Defaulting to '1'" )
    end_if               

end_body

