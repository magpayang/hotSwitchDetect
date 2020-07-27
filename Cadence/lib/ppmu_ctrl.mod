------------------------------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------------------------
-- This is a Cadence software module designed to control the FX1 & FX-HS PPMU
-- The code is designed to minimize transients and glitches when changing settings on the PPMU
--
-- The code is also designed to overcome certain characteristics of the Cadence API that can lead to unexpected
-- behavior. The routines ensure that the driver does not rely on default values. 

-- Version  Name        Notes
-- 01       C Hughes    First Version
-- 02       C Hughes    02/11/2010
--                      Added entry states to 'ppmu_connect_meas_FIMV'
--                      Added delay parameters for DCL_MBB & DCL_BBM
--                      Added parameters to support ganged FI measurement. Paremeter changed from boolean to string.
--                      Added parameters for voltage clamps in FV routines for FI modes at disconnect.
--                      Removed FI_1pA exit state from FN routines
--                      Changed to use ppmu relay disconnect rather than ppmu disconnect
--                      Added some comments to clarify some of the functionality
-- 03       C Hughes    02/17/2010
--                      Changed to use ppmu relay disconnect rather than ppmu disconnect (missed some in Ver 02)
--                      Changed routine 'ppmu_connect_meas_FVMI' ALIGN connect to disconnect PPMU when setting FV
--                      This was to avoid a transient on the FX-HS.
-- 04       C Hughes    02/19/2010
--                      Changed to use set & relay connect in place of connect in 'ppmu_connect_meas_FIMV'
-- 05       C Hughes    03/10/2010
--                      Added the missing ExitState "ENTRY" to 'ppmu_connect_meas_FVMI' & 'ppmu_disconnect_FVMI'
-- 06       C Hughes    04/09/2010
--                      Added extra procedures 'ppmu_connect_FIMV' & 'ppmu_connect_FVMI'
--                      Fixed some errors in the comments for the Entry & Exit states
-- 07       C Hughes    05/27/2010
--                      Removed the parameters 'VClamp_Min' & 'VClamp_Max' from the routine 'ppmu_connect_FVMI'
--                      since these parameters are not used. Fixed some errors in the comments.
-- 08       C Hughes    08/20/2010
--                      Removed the ALIGN connect option from the procedure 'ppmu_connect_FVMI' because it would
--                      only work for a pin list of length 1
-- 09       C Hughes    09/14/2010
--                      Made parameters private to avoid mulitply defined parameter issues when used in conjunction
--                      with other Cadence modules.

------------------------------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------------------------
private
const
    MAX_CMD_LEN = 20
    MAX_PINS    = 256
end_const

const
    VCLAMP_MAX  = +7V
    VCLAMP_MIN  = -2V
    PPMU_VMAX   = +7V
    PPMU_VMIN   = -2V

    ALIGN       = "ALIGN"
    HOLD        = "HOLD"
    ENTRY       = "ENTRY"
    FI_1pA      = "FI_1pA"
    DISCONN     = "DISCONN"
    VM          = "VM"

    DCL_MBB     = "DCL_MBB"
    DCL_BBM     = "DCL_BBM"
    
    NO_MEAS     = 0

    PAR_MEAS    = "PARALLEL"
    SER_MEAS    = "SERIAL"
    GANG_MEAS   = "GANGED"    
    
end_const

static
    boolean     : verify_states = false   -- Set true to verify hardware state matches that specified in user parameters
end_static
end_private

procedure ppmu_connect_meas_FVMI( InPins , VForce , IRange , VSteps , VclampMin , VclampMax , TSettle , Average , MeasMode , Result , EntryState , EntryWait , VEntry  , ExitState , ExitWait )
------------------------------------------------------------------------------------------------------------------
--This routine will connect the ppmu in force voltage measure current mode
--Optionally the DCL relay can be managed by this routine.
--  1. In order to support a clean transition between a DCL function and the PPMU an DCL entry state and voltage can be specified.
--     The DCL_xxx entry states will hot switch the relays and the user must ensure the DCL is physically programmed to VEntry. 
--  2. In order to support a clean transition between a PPMU function and the DCL an exit state is specified. The DCL_xxx exit states
--     will hot switch the relays. At the exit point the PPMU voltage will be restored to Ventry and again the user must ensure the DCL
--     was physically programmed to VEntry to avoid transients. 

--Note 'vmax' clause has no effect in FV mode and are deliberately omitted
--     dlog clause for measure is deliberately omitted. Use of test_value is recommended instead.
--     'clamps' clause has no effect in FV mode and is provide for FI optional disconnect state.

--There is the option to:
--  1. Manage the DCL & PPMU relays based on the value of EntryState (see options below)
--  2. Ramp the voltage from VEntry to VForce in VSteps steps
--  3. Make a current measurement based on the value of Average (No measuremnt if = 0)
--  4. Set the exit state based on the value of ExitState (see options below)

in_out pin list             : InPins                -- PPMU pins
in float                    : VForce                -- Forcing voltage. Make equal to VEntry for no step.
in float                    : IRange                -- Current range
in integer                  : VSteps                -- If > 1 this is the number of steps for voltage ramp
in float                    : VclampMin, VclampMax  -- ONLY APPLIES TO FI AT DISCONNECT : Minimum & Maximum voltage clamps
in float                    : TSettle               -- Wait time after the connect and before the measure if used
in word                     : Average               -- If > 0 then a measurement is made with this number of averages
in string [MAX_CMD_LEN]     : MeasMode              -- PAR_MEAS , SER_MEAS or GANG_MEAS measurement
in_out multisite float      : Result[?]             -- conformant array for measured results

in string [MAX_CMD_LEN]     : EntryState            -- Mode that exists when entering the routine
                                                    -- DISCONN  : The PPMU and DCL are disconnected
                                                    -- DCL_MBB  : If the DCL is connected connect PPMU before disconnecting DCL
                                                    -- DCL_BBM  : If the DCL is connected disconnect DCL before connecting PPMU
                                                    -- ALIGN    : Measure the voltage in FNMV and connect, forcing measured value
in float                    : EntryWait             -- Delay between Make/Break or Break/Make for connect

in float                    : VEntry                -- The voltage on the pin at the point of entry. If no ramp is specified 
                                                    -- the voltage will step from this voltage to VForce. For no step make
                                                    -- VEntry = VForce. If a ramp is specified the ramp will start at this value
                                                    -- and ramp to VForce

in string [MAX_CMD_LEN]     : ExitState             -- Mode to leave the PPMU in at the end of the routine
                                                    -- HOLD     : Leave PPMU in FV mode with VForce value
                                                    -- ENTRY    : Leave PPMU in FV mode and return the PPMU to VEntry
                                                    -- FI_1pA   : Leave in FI mode to 1pA (same IRange specified)
                                                    -- DCL_MBB  : Set to VEntry, restore the DCL connection and disconnect the PPMU
                                                    -- DCL_BBM  : Set to VEntry, disconnect the PPMU and restore the DCL connection
                                                    -- DISCONN  : Disable and disconnect ppmu
                                                    -- VM       : Voltmeter mode (force gated off)

in float                    : ExitWait              -- Delay between Make/Break or Break/Make for disconnect
                                                    
local
    float                   : StepSize              -- used in ramp
    float                   : StepValue             -- used in ramp
    integer                 : i                     -- used in ramp
    integer                 : NumPins
    multisite word          : ppmu_fv_state[MAX_PINS]
    multisite word          : ppmu_fi_state[MAX_PINS]
    word list [16]          : ActiveSites 
    integer                 : NumSites, SitePtr, PinPtr
    word                    : Site
    multisite float         : GangedResult
end_local

body

    ActiveSites = get_active_sites
    NumSites = len(ActiveSites)
    
    if EntryState == DISCONN then -- Nothing should be connected so connect
        if verify_states then
            read digital ppmu InPins fv state ppmu_fv_state
            read digital ppmu InPins fi state ppmu_fi_state
            NumPins = len(InPins)
            for SitePtr = 1 to NumSites do
                Site = ActiveSites[SitePtr]
                for PinPtr = 1 to NumPins do
                    if ppmu_fv_state[Site,PinPtr] <> 0 or ppmu_fi_state[1,PinPtr] <> 0 then
                        println(stdout,"WARNING : PPMU state of channel ",InPins[PinPtr]," in not consistent with the specified EntryState")
                    end_if
                end_for               
            end_for
        end_if
        set digital ppmu InPins to fv VEntry measure i max IRange delay 0mS
        connect digital pin InPins to ppmu delay 0ms
    else_if EntryState == DCL_MBB then -- make before break : Connect PPMU before DCL disconnect
        set digital ppmu InPins to fv VEntry measure i max IRange delay 0mS
        connect digital pin InPins to ppmu delay 0ms
        wait(EntryWait)
        disconnect digital pin InPins from dcl delay 0ms
    else_if EntryState == DCL_BBM then -- break before make : Disconnect DCL before connecting PPMU
        disconnect digital pin InPins from dcl delay 0ms
        wait(EntryWait)
        set digital ppmu InPins to fv VEntry measure i max IRange delay 0mS
        connect digital pin InPins to ppmu delay 0ms
    else_if EntryState == ALIGN then -- Measure the voltage in VM mode and connect, forcing measured value
        set digital ppmu InPins to fi 0mA imax IRange clamps to vmin VclampMin vmax VclampMax delay 0mS
        connect digital pin InPins to ppmu delay 0ms
        measure digital ppmu InPins voltage average 4 into Result
        NumPins = len(InPins)
        deactivate site ActiveSites
        for SitePtr = 1 to NumSites do
            Site = ActiveSites[SitePtr]
            activate site Site
            for PinPtr = 1 to NumPins do
                disconnect digital pin InPins[PinPtr] from ppmu delay 0ms   -- Disconnect to avoid last FV glitch on FX-HS
                set digital ppmu InPins[PinPtr] to fv Result[Site,PinPtr] measure i max IRange delay 0mS
                connect digital pin InPins[PinPtr] to ppmu delay 0ms
            end_for
            deactivate site Site
         end_for
         activate site ActiveSites
    else
        set digital ppmu InPins to fi 1pA imax IRange clamps to vmin VclampMin vmax VclampMax delay 0mS
        disconnect digital pin InPins from ppmu delay 0ms
        println(stdout,"WARNING : Invalid EntryState of ",EntryState," specified in routine 'ppmu_connect_meas_FVMI' or 'ppmu_connect_FVMI'")
        println(stdout,"          PPMU has been disconnected on channels ",InPins)
    end_if
    
    if VSteps <= 1 then         -- set force value directly
        if VForce <> VEntry then
            set digital ppmu InPins to fv VForce measure i max IRange delay 0mS
        end_if
    else                        -- ramp up to force value
        StepSize = ( VForce - VEntry) / float(VSteps)
        StepValue = VEntry+StepSize
        for i = 1 to VSteps do
            set digital ppmu InPins to fv StepValue measure i max IRange delay 0mS
            StepValue = StepValue + StepSize
        endfor
    endif        

    wait(TSettle)

    if Average > 0 then         -- skip settle delay and measure if Average = 0
        if MeasMode = PAR_MEAS then
            measure digital ppmu InPins current imax IRange average Average into Result
        else_if MeasMode = SER_MEAS then
            measure digital ppmu InPins current imax IRange average Average serial into Result
        else_if MeasMode = GANG_MEAS then
            measure digital ppmu InPins current imax IRange average Average ganged into GangedResult
            for SitePtr = 1 to NumSites do
                Site = ActiveSites[SitePtr]
                Result[Site] = 999999.9
                Result[Site,1] = GangedResult[Site]
            end_for
        else
            println(stdout,"WARNING : Invalid MeasMode of ",MeasMode," specified in routine 'ppmu_connect_meas_FVMI' or 'ppmu_connect_FVMI'")
            println(stdout,"          Returning failing measure values on channels ",InPins)
            Result = 999999.9
        end_if
    endif

    if ExitState == HOLD then       -- leaves PPMU in FVMI mode with set level
        -- Do nothing
    else_if ExitState == ENTRY then       -- leaves PPMU in FVMI mode with voltage at Ventry
        if VEntry <> VForce then
            set digital ppmu InPins to fv VEntry measure i max IRange delay 0mS
        end_if
    else_if ExitState == FI_1pA then       -- leaves PPMU in FIMV mode with safe level
        set digital ppmu InPins to fi 1pA imax IRange clamps to vmin VclampMin vmax VclampMax delay 0mS
    else_if ExitState == DCL_MBB then -- make before break : Connect DCL before PPMU disconnect
        if VForce <> VEntry then
            set digital ppmu InPins to fv VEntry measure i max IRange delay 0mS
        end_if
        connect digital pin InPins to dcl delay 0ms
        wait(ExitWait)
        disconnect digital pin InPins from ppmu delay 0ms
    else_if ExitState == DCL_BBM then -- break before make : Disconnect PPMU before connecting DCL
        if VForce <> VEntry then
            set digital ppmu InPins to fv VEntry measure i max IRange delay 0mS
        end_if
        disconnect digital pin InPins from ppmu delay 0ms
        wait(ExitWait)
        connect digital pin InPins to dcl delay 0ms
    else_if ExitState == DISCONN then   -- sets PPMU to safe level and disconnects it
        set digital ppmu InPins to fi 1pA imax IRange clamps to vmin VclampMin vmax VclampMax delay 0mS
        disconnect digital pin InPins from ppmu delay 0ms
    else_if ExitState == VM then        -- sets ppmu to Voltmeter mode
        connect digital ppmu InPins to fi 0mA imax IRange clamps to vmin VclampMin vmax VclampMax delay 0mS
    else -- exit state is not a valid option. Print a warning message and disconnect PPMU
        set digital ppmu InPins to fi 1pA imax IRange clamps to vmin VclampMin vmax VclampMax delay 0mS
        disconnect digital pin InPins from ppmu delay 0ms
        println(stdout,"WARNING : Invalid ExitState of ",ExitState," specified in routine 'ppmu_connect_meas_FVMI' or 'ppmu_connect_FVMI'")
        println(stdout,"          PPMU has been disconnected on channels ",InPins)
    endif


end_body
------------------------------------------------------------------------------------------------------------------


procedure ppmu_connect_meas_FIMV( InPins , IForce , IRange , ISteps , VclampMin , VclampMax , TSettle , Average , Result , EntryState , EntryWait , ExitState , ExitWait )
------------------------------------------------------------------------------------------------------------------
--This routine will connect the ppmu in force current measure voltage mode.
--Note that FNMV (Voltmeter Mode) cannot be set by this routine. Use 'ppmu_connect_meas_FNMV' instead.
--Note 'measure v max' clause has no effect in FI mode and is deliberately omitted
--dlog clause for measure is deliberately omitted. Use of test_value is recommended instead.

--There is the option to:
--  1. Manage the DCL & PPMU relays based on the value of EntryState (see options below)
--  2. Ramp the current from 0mA to IForce in ISteps steps
--  3. Make a measurement based on the value of Average (No measurement if = 0)
--  4. Set the exit state based on the value of ExitState (see options below)

in_out pin list             : InPins                -- PPMU pins
in float                    : IForce                -- Forcing current
in float                    : IRange                -- Current range
in integer                  : ISteps                -- If > 1 this is the number of steps for current ramp
in float                    : VclampMin, VclampMax  -- Minimum & Maximum voltage clamps
in float                    : TSettle               -- After the connect and before the measure if used
in word                     : Average               -- If > 0 then a measurement is made with this number of averages
in_out multisite float      : Result[?]             -- conformant array for measured results


in string [MAX_CMD_LEN]     : EntryState            -- Mode that exists when entering the routine
                                                    -- DISCONN  : The PPMU and DCL are disconnected
                                                    -- DCL_MBB  : If the DCL is connected connect PPMU before disconnecting DCL
                                                    -- DCL_BBM  : If the DCL is connected disconnect DCL before connecting PPMU

in float                    : EntryWait             -- Delay between Make/Break or Break/Make for connect

in string [MAX_CMD_LEN]     : ExitState             -- mode to leave the PPMU in at the end of the routine
                                                    -- HOLD     : Leave PPMU in FI mode to IForce value
                                                    -- FI_1pA   : Leave in FI mode to 1pA (same IRange specified)
                                                    -- DISCONN  : Disable and disconnect ppmu
                                                    -- DCL_MBB  : Restore the DCL connection and disconnect the PPMU
                                                    -- DCL_BBM  : Disconnect the PPMU and restore the DCL connection
                                                    -- VM       : Voltmeter mode (force gated off)

in float                    : ExitWait              -- Delay between Make/Break or Break/Make for connect
                                                    
local
    float                   : StepSize              -- used in ramp
    float                   : StepValue             -- used in ramp
    integer                 : i                     -- used in ramp
    integer                 : NumPins
    multisite word          : ppmu_fv_state[MAX_PINS]
    multisite word          : ppmu_fi_state[MAX_PINS]
    word list [16]          : ActiveSites 
    integer                 : NumSites, SitePtr, PinPtr
    word                    : Site
    word list[MAX_PINS]     : fx_chans
end_local

body

    if EntryState == DISCONN then -- Nothing should be connected so connect
        if verify_states then
            read digital ppmu InPins fv state ppmu_fv_state
            read digital ppmu InPins fi state ppmu_fi_state
            NumPins = len(InPins)
            for SitePtr = 1 to NumSites do
                Site = ActiveSites[SitePtr]
                for PinPtr = 1 to NumPins do
                    --print_ppmu_reg_state(InPins[PinPtr],"")
                    if ppmu_fv_state[Site,PinPtr] <> 0 or ppmu_fi_state[1,PinPtr] <> 0 then
                        println(stdout,"WARNING : PPMU state of channel ",InPins[PinPtr]," in not consistent with the specified EntryState")
                    end_if
                end_for               
            end_for
        end_if
        --This is faster than above
        set digital ppmu InPins to fi 1pA imax 2uA clamps to vmin VclampMin vmax VclampMax delay 0mS   -- safe connection state
        connect digital pin InPins to ppmu  delay 0mS   -- safe connection method
    else_if EntryState == DCL_MBB then -- make before break : Connect PPMU before DCL disconnect
        set digital ppmu InPins to fi 1pA imax 2uA clamps to vmin VclampMin vmax VclampMax delay 0mS   -- safe connection state
        connect digital pin InPins to ppmu  delay 0mS   -- safe connection method
        wait(EntryWait)
        disconnect digital pin InPins from dcl
    else_if EntryState == DCL_BBM then -- break before make : Disconnect DCL before connecting PPMU
        disconnect digital pin InPins from dcl
        wait(EntryWait)
        set digital ppmu InPins to fi 1pA imax 2uA clamps to vmin VclampMin vmax VclampMax delay 0mS   -- safe connection state
        connect digital pin InPins to ppmu  delay 0mS   -- safe connection method
    else
        set digital ppmu InPins to fi 1pA imax IRange clamps to vmin VclampMin vmax VclampMax delay 0mS
        disconnect digital pin InPins from ppmu
        println(stdout,"WARNING : Invalid EntryState of ",EntryState," specified in routine 'ppmu_connect_meas_FIMV' or 'ppmu_connect_FIMV'")
        println(stdout,"          PPMU has been disconnected on channels ",InPins)
    end_if

    if ISteps <= 1 then         -- set force value directly
        set digital ppmu InPins to fi IForce imax IRange clamps to vmin VclampMin vmax VclampMax delay 0mS
    else                        -- ramp up to force value
        StepSize = IForce / float(ISteps)
        StepValue = StepSize
        for i = 1 to ISteps do
            set digital ppmu InPins to fi StepValue imax IRange clamps to vmin VclampMin vmax VclampMax delay 0mS
            StepValue = StepValue + StepSize
        endfor
    endif        

    wait(TSettle)

    if Average > 0 then         -- skip settle delay and measure if Average = 0
        measure digital ppmu InPins voltage average Average into Result
    endif

    if ExitState == HOLD then       -- leaves PPMU in FIMV mode with set level
        -- Do nothing
    else_if ExitState == FI_1pA then       -- leaves PPMU in FIMV mode with safe level
        set digital ppmu InPins to fi 1pA imax IRange clamps to vmin VclampMin vmax VclampMax delay 0mS 
    else_if ExitState == DISCONN then   -- sets PPMU to safe level and disconnects it
        set digital ppmu InPins to fi 1pA imax IRange clamps to vmin VclampMin vmax VclampMax delay 0mS
        disconnect digital pin InPins from ppmu delay 0ms
    else_if ExitState == DCL_MBB then -- make before break : Connect DCL before PPMU disconnect
        connect digital pin InPins to dcl
        wait(ExitWait)
        set digital ppmu InPins to fi 1pA imax IRange clamps to vmin VclampMin vmax VclampMax delay 0mS
        disconnect digital pin InPins from ppmu delay 0ms
    else_if ExitState == DCL_BBM then -- break before make : Disconnect PPMU before connecting DCL
        set digital ppmu InPins to fi 1pA imax IRange clamps to vmin VclampMin vmax VclampMax delay 0mS
        disconnect digital pin InPins from ppmu delay 0ms
        wait(ExitWait)
        connect digital pin InPins to dcl
    else_if ExitState == VM then        -- sets ppmu to Voltmeter mode
        connect digital ppmu InPins to fi 0.0mA imax IRange clamps to vmin VclampMin vmax VclampMax delay 0mS
    else -- exit state is not a valid option. Print a warning message and disconnect PPMU
        set digital ppmu InPins to fi 1pA imax IRange clamps to vmin VclampMin vmax VclampMax delay 0mS
        disconnect digital pin InPins from ppmu delay 0ms
        println(stdout,"WARNING : Invalid ExitState of ",ExitState," specified in routine 'ppmu_connect_meas_FIMV' or 'ppmu_connect_FIMV'")
        println(stdout,"          PPMU has been disconnected on channels ",InPins)
    endif


end_body
------------------------------------------------------------------------------------------------------------------


procedure ppmu_disconnect_FIMV(InPins, IRange, VclampMin, VclampMax, ExitState , ExitWait )
------------------------------------------------------------------------------------------------------------------
--This routine will disconnect the ppmu from force current measure voltage mode
--The dcl relay is not managed by this routine. If the dcl needs to be reconnected the user should ensure the
--dcl relay is closed after exiting this routine
--Note 'measure v max clause' has no effect in FI mode and is deliberately omitted

--There is the option to:
--  1. Set the exit state based on the value of ExitState (see options below)

in_out pin list             : InPins                -- PPMU pins
in float                    : IRange                -- Current range
in float                    : VclampMin, VclampMax  -- Minimum & Maximum voltage clamps

in string [MAX_CMD_LEN]     : ExitState             -- mode to leave the PPMU in at the end of the routine
                                                    -- FI_1pA   : Leave in FI mode to 1pA (same IRange specified)
                                                    -- DISCONN  : Disable and disconnect ppmu
                                                    -- DCL_MBB  : Restore the DCL connection and disconnect the PPMU
                                                    -- DCL_BBM  : Disconnect the PPMU and restore the DCL connection
                                                    -- VM       : Voltmeter mode (force gated off)

in float                    : ExitWait              -- Delay between Make/Break or Break/Make for connect
                                                    
body


    if ExitState == FI_1pA then       -- leaves PPMU in FIMV mode with safe level
        set digital ppmu InPins to fi 1pA imax IRange clamps to vmin VclampMin vmax VclampMax delay 0mS 
    else_if ExitState == DISCONN then   -- sets PPMU to safe level and disconnects it
        set digital ppmu InPins to fi 1pA imax IRange clamps to vmin VclampMin vmax VclampMax delay 0mS
        disconnect digital pin InPins from ppmu delay 0ms
    else_if ExitState == DCL_MBB then -- make before break : Connect DCL before PPMU disconnect
        connect digital pin InPins to dcl
        wait(ExitWait)
        set digital ppmu InPins to fi 1pA imax IRange clamps to vmin VclampMin vmax VclampMax delay 0mS
        disconnect digital pin InPins from ppmu delay 0ms
    else_if ExitState == DCL_BBM then -- break before make : Disconnect PPMU before connecting DCL
        set digital ppmu InPins to fi 1pA imax IRange clamps to vmin VclampMin vmax VclampMax delay 0mS
        disconnect digital pin InPins from ppmu delay 0ms
        wait(ExitWait)
        connect digital pin InPins to dcl
    else_if ExitState == VM then        -- sets ppmu to Voltmeter mode
        connect digital ppmu InPins to fi 0.0mA imax IRange clamps to vmin VclampMin vmax VclampMax delay 0mS
    else -- exit state is not a valid option. Print a warning message and disconnect PPMU
        set digital ppmu InPins to fi 1pA imax IRange clamps to vmin VclampMin vmax VclampMax delay 0mS
        disconnect digital pin InPins from ppmu delay 0ms
        println(stdout,"WARNING : Invalid ExitState of ",ExitState," specified in routine 'ppmu_disconnect_FIMV'")
        println(stdout,"          PPMU has been disconnected on channels ",InPins)
    endif


end_body
------------------------------------------------------------------------------------------------------------------


procedure ppmu_disconnect_FVMI(InPins, VForce, IRange, VclampMin , VclampMax , VExit , ExitState , ExitWait)
------------------------------------------------------------------------------------------------------------------
--This routine will disconnect the ppmu from force voltage measure current mode
--Optionally the DCL relay can be managed by this routine.
--  1. In order to support a clean transition between a PPMU function and the DCL an exit state is specified. The DCL_xxx exit states
--     will hot switch the relays. At the exit point the PPMU voltage will be restored to VExit and again the user must ensure the DCL
--     is physically programmed to VExit. 

--Note 'vmax' and 'clamps' clauses have no effect in FV mode and are deliberately omitted
--There is the option to:
--  1. Set the exit state based on the value of ExitState (see options below)

in_out pin list             : InPins                -- PPMU pins
in float                    : VForce                -- The PPMU Forcing voltage at the point of entry
in float                    : IRange                -- Current range
in float                    : VclampMin, VclampMax  -- ONLY APPLIES TO FI AT DISCONNECT : Minimum & Maximum voltage clamps

in float                    : VExit                 -- The voltage to set on the pin at the point of exit. For no step make
                                                    -- VExit = VForce.

in string [MAX_CMD_LEN]     : ExitState             -- Mode to leave the PPMU in at the end of the routine
                                                    -- DCL_MBB  : Set to VEntry, restore the DCL connection and disconnect the PPMU
                                                    -- DCL_BBM  : Set to VEntry, disconnect the PPMU and restore the DCL connection
                                                    -- FI_1pA   : Leave in FI mode to 1pA (same IRange specified)
                                                    -- DISCONN  : Disable and disconnect ppmu
                                                    -- VM       : Voltmeter mode (force gated off)

in float                    : ExitWait              -- Delay between Make/Break or Break/Make for disconnect
                                                    
local
    float                   : StepSize              -- used in ramp
    float                   : StepValue             -- used in ramp
    integer                 : i                     -- used in ramp
    integer                 : NumPins
    multisite word          : ppmu_fv_state[MAX_PINS]
    multisite word          : ppmu_fi_state[MAX_PINS]
end_local

body


    if ExitState == FI_1pA then       -- leaves PPMU in FIMV mode with safe level
        set digital ppmu InPins to fi 1pA imax IRange clamps to vmin VclampMin vmax VclampMax delay 0mS
    else_if ExitState == DCL_MBB then -- make before break : Connect DCL before PPMU disconnect
        if VForce <> VExit then
            set digital ppmu InPins to fv VExit measure i max IRange delay 0mS
        end_if
        connect digital pin InPins to dcl
        disconnect digital pin InPins from ppmu delay 0ms
    else_if ExitState == DCL_BBM then -- break before make : Disconnect PPMU before connecting DCL
        if VForce <> VExit then
            set digital ppmu InPins to fv VExit measure i max IRange delay 0mS
        end_if
        disconnect digital pin InPins from ppmu delay 0ms
        connect digital pin InPins to dcl
    else_if ExitState == DISCONN then   -- sets PPMU to safe level and disconnects it
        set digital ppmu InPins to fi 1pA imax IRange clamps to vmin VclampMin vmax VclampMax delay 0mS
        disconnect digital pin InPins from ppmu delay 0ms
    else_if ExitState == VM then        -- sets ppmu to Voltmeter mode
        connect digital ppmu InPins to fi 0mA imax IRange clamps to vmin VclampMin vmax VclampMax delay 0mS
    else -- exit state is not a valid option. Print a warning message and disconnect PPMU
        set digital ppmu InPins to fi 1pA imax IRange clamps to vmin VclampMin vmax VclampMax delay 0mS
        disconnect digital pin InPins from ppmu delay 0ms
        println(stdout,"WARNING : Invalid ExitState of ",ExitState," specified in routine 'ppmu_disconnect_FVMI'")
        println(stdout,"          PPMU has been disconnected on channels ",InPins)
    endif


end_body
------------------------------------------------------------------------------------------------------------------


procedure ppmu_connect_meas_FNMV( InPins , IRange , VclampMin , VclampMax , TSettle , Average , Result , ExitState )
------------------------------------------------------------------------------------------------------------------
--This routine will connect the ppmu in force nothing measure voltage mode (voltmeter mode : PPMU passive)
--The DCL relay is not managed by this routine. If the DCL needs to be disconnected the user should ensure the
--DCL relay is open before entering this routine. In the case of FX-HS this feature is supported in firmware and connecting
--the PPMU will automatically disconnect the DCL.
--Note 'vmax' and 'clamps' clauses have no effect in FN mode and are deliberately omitted

--There is the option to:
--  1. Make a measurement based on the value of Average (No measuremnt if = 0)
--  2. Set the exit state based on the value of ExitState (see options below)

in_out pin list             : InPins                -- PPMU pins
in float                    : IRange                -- Current range (only has meaning for ExitState
in float                    : VclampMin, VclampMax  -- ONLY APPLIES TO FI AT DISCONNECT : Minimum & Maximum voltage clamps
in float                    : TSettle               -- Wait time after the connect and before the measure if used
in word                     : Average               -- If > 0 then a measurement is made with this number of averages
in_out multisite float      : Result[?]             -- conformant array for measured results

in string [MAX_CMD_LEN]     : ExitState             -- mode to leave the PPMU in at the end of the routine
                                                    -- VM       : Voltmeter mode (force gated off)
                                                    -- FI_1pA   : Leave in FI mode to 1pA (same IRange specified)
                                                    -- DISCONN  : Disconnect ppmu leave in VM mode
                                     
body

    connect digital ppmu InPins to fi 0pA imax IRange delay 0mS   -- only connection method for VM

    wait(TSettle)

    if Average > 0 then         -- skip settle delay and measure if Average = 0
        measure digital ppmu InPins voltage average Average into Result
    endif

    if ExitState == VM then        -- keeps ppmu in Voltmeter mode
        --Do nothing
    else_if ExitState == FI_1pA then   -- Put in force current mode with a small current and leave connected
        set digital ppmu InPins to fi 1pA imax IRange clamps to vmin VclampMin vmax VclampMax delay 0mS 
    else_if ExitState == DISCONN then   -- PPMU is safe so just disconnect it
        disconnect digital pin InPins from ppmu delay 0ms
    else -- exit state is not a valid option. Print a warning message and disconnect PPMU
        set digital ppmu InPins to fi 1pA imax IRange clamps to vmin VclampMin vmax VclampMax delay 0mS
        disconnect digital pin InPins from ppmu delay 0ms
        println(stdout,"WARNING : Invalid ExitState of ",ExitState," specified in routine 'ppmu_connect_meas_FNMV'")
        println(stdout,"          PPMU has been disconnected on channels ",InPins)
    endif


end_body
------------------------------------------------------------------------------------------------------------------


procedure ppmu_meas_FIMV(InPins, MeasSettle, Average, Result)
------------------------------------------------------------------------------------------------------------------
--This routine will make a ppmu measurement in force current measure voltage mode
--It is assumed that the ppmu is already connected and the DCL relay is open if necessary.
--No change is made to the PPMU or DCL connections or ranges

--Note 'measure v max clause' has no effect in FI mode and is deliberately omitted


in_out pin list             : InPins                -- PPMU pins
in float                    : MeasSettle            -- Wait time if the measure is used
in word                     : Average               -- Number of averages for the measurement
in_out multisite float      : Result[?]             -- conformant array for measured results


body

    if Average > 0 then         -- skip settle delay and measure if Average = 0
        wait(MeasSettle)
        measure digital ppmu InPins voltage average Average into Result
    end_if
        
end_body
------------------------------------------------------------------------------------------------------------------


procedure ppmu_set_FIMV(InPins, IForce, IRange, VclampMin, VclampMax, TSettle)
------------------------------------------------------------------------------------------------------------------
--This routine will set the ppmu force current and current range in force current measure voltage mode
--It is assumed that the ppmu is already connected and the DCL relay is open if necessary.
--No change is made to the PPMU or DCL connections

--Note 'measure v max clause' has no effect in FI mode and is deliberately omitted
--     The set command will have immediate effect on the output (no enable required)


in_out pin list             : InPins                -- PPMU pins
in float                    : IForce                -- Forcing current
in float                    : IRange                -- Current range
in float                    : VclampMin, VclampMax  -- Minimum & Maximum voltage clamps
in float                    : TSettle               -- Settle time after set
                                                    

body

    set digital ppmu InPins to fi IForce imax IRange clamps to vmin VclampMin vmax VclampMax delay TSettle

end_body
------------------------------------------------------------------------------------------------------------------


procedure ppmu_set_FVMI( InPins , VForce , IRange , TSettle)
------------------------------------------------------------------------------------------------------------------
--This routine will set the ppmu force voltage and measure current range in force voltage measure current mode
--It is assumed that the ppmu is already connected and the DCL relay is open if necessary.
--No change is made to the PPMU or DCL connections

--Note 'vmax' and 'clamps' clauses have no effect in FV mode and are deliberately omitted
--     The set command will have immediate effect on the output (no enable required)


in_out pin list             : InPins                -- PPMU pins
in float                    : VForce                -- Forcing voltage
in float                    : IRange                -- Current range
in float                    : TSettle               -- Settle time after set


body
    
    set digital ppmu InPins to fv VForce measure i max IRange delay TSettle

end_body
------------------------------------------------------------------------------------------------------------------


procedure ppmu_meas_FVMI(InPins, IRange , MeasSettle , Average , MeasMode , Result)
------------------------------------------------------------------------------------------------------------------
--This routine will make a ppmu measurement in force voltage measure current mode
--It is assumed that the ppmu is already connected and the DCL relay is open if necessary.
--No change is made to the PPMU or DCL connections

--Note 'measure v max clause' has no effect in FI mode and is deliberately omitted


in_out pin list             : InPins                -- PPMU pins
in float                    : IRange                -- Current range
in float                    : MeasSettle            -- Wait time if the measure is used
in word                     : Average               -- Number of averages for the measurement
in string [MAX_CMD_LEN]     : MeasMode              -- PAR_MEAS , SER_MEAS or GANG_MEAS measurement
in_out multisite float      : Result[?]             -- Conformant array for measured results
                                                    -- Ganged result will be in the 1st location of each site

local
    word list [16]          : ActiveSites 
    integer                 : NumSites, SitePtr, PinPtr
    word                    : Site
    multisite float         : GangedResult
end_local


body

    if Average > 0 then         -- skip settle delay and measure if Average = 0
        ActiveSites = get_active_sites
        NumSites = len(ActiveSites)
        wait(MeasSettle)
        if MeasMode = PAR_MEAS then
            measure digital ppmu InPins current imax IRange average Average into Result
        else_if MeasMode = SER_MEAS then
            measure digital ppmu InPins current imax IRange average Average serial into Result
        else_if MeasMode = GANG_MEAS then
            measure digital ppmu InPins current imax IRange average Average ganged into GangedResult
            for SitePtr = 1 to NumSites do
                Site = ActiveSites[SitePtr]
                Result[Site] = 999999.9
                Result[Site,1] = GangedResult[Site]
            end_for
        else
            println(stdout,"WARNING : Invalid MeasMode of ",MeasMode," specified in routine 'ppmu_meas_FVMI'")
            println(stdout,"          Returning failing measure values on channels ",InPins)
            Result = 999999.9
        end_if
    endif
    
end_body
------------------------------------------------------------------------------------------------------------------


procedure ppmu_connect_FIMV( InPins , IForce , IRange , ISteps , VclampMin , VclampMax , EntryState , EntryWait )
------------------------------------------------------------------------------------------------------------------
--This routine will connect the ppmu in force current measure voltage mode.
--Note that FVMV (Voltmeter Mode) cannot be set by this routine. Use 'ppmu_connect_FNMV' instead.
--The DCL relay is not managed by this routine. If the DCL needs to be disconnected the user should ensure the
--DCL relay is open before entering this routine. In the case of FX-HS this feature is supported in firmware and connecting
--the PPMU will automatically disconnect the DCL.
--Note 'measure v max clause' has no effect in FI mode and is deliberately omitted

--There is the option to:
--  1. Manage the DCL & PPMU relays based on the value of EntryState (see options below)
--  2. Ramp the current from 0mA to IForce in ISteps steps

in_out pin list             : InPins                -- PPMU pins
in float                    : IForce                -- Forcing current
in float                    : IRange                -- Current range
in integer                  : ISteps                -- If > 1 this is the number of steps for current ramp
in float                    : VclampMin, VclampMax  -- Minimum & Maximum voltage clamps


in string [MAX_CMD_LEN]     : EntryState            -- Mode that exists when entering the routine
                                                    -- DISCONN  : The PPMU and DCL are disconnected
                                                    -- DCL_MBB  : If the DCL is connected connect PPMU before disconnecting DCL
                                                    -- DCL_BBM  : If the DCL is connected disconnect DCL before connecting PPMU

in float                    : EntryWait             -- Delay between Make/Break or Break/Make for connect
                                                    
local
    multisite float         : Result[1]             -- dummy array for measured results
end_local

body

    ppmu_connect_meas_FIMV( InPins , IForce , IRange , ISteps , VclampMin , VclampMax , 0ms , 0 , Result , EntryState , EntryWait , HOLD , 0ms )

end_body
------------------------------------------------------------------------------------------------------------------


procedure ppmu_connect_FVMI( InPins , VForce , IRange , VSteps , EntryState , EntryWait , VEntry )
------------------------------------------------------------------------------------------------------------------
--This routine will connect the ppmu in force voltage measure current mode
--Optionally the DCL relay can be managed by this routine.
--  1. In order to support a clean transition between a DCL function and the PPMU an DCL entry state and voltage can be specified.
--     The DCL_xxx entry states will hot switch the relays and the user must ensure the DCL is physically programmed to VEntry. 

--Note 'vmax' and 'clamps' clauses have no effect in FV mode and are deliberately omitted

--There is the option to:
--  1. Manage the DCL & PPMU relays based on the value of EntryState (see options below)
--  2. Ramp the voltage from VEntry to VForce in VSteps steps

in_out pin list             : InPins                -- PPMU pins
in float                    : VForce                -- Forcing voltage. Make equal to VEntry for no step.
in float                    : IRange                -- Current range
in integer                  : VSteps                -- If > 1 this is the number of steps for current ramp

in string [MAX_CMD_LEN]     : EntryState            -- Mode that exists when entering the routine
                                                    -- DISCONN  : The PPMU and DCL are disconnected
                                                    -- DCL_MBB  : If the DCL is connected connect PPMU before disconnecting DCL
                                                    -- DCL_BBM  : If the DCL is connected disconnect DCL before connecting PPMU
                                                    -- ALIGN    : This is not supported for this command
in float                    : EntryWait             -- Delay between Make/Break or Break/Make for connect

in float                    : VEntry                -- The voltage on the pin at the point of entry. If no ramp is specified 
                                                    -- the voltage will step from this voltage to VForce. For no step make
                                                    -- VEntry = VForce. If a ramp is specified the ramp will start at this value
                                                    -- and ramp to VForce

                                                    
local
    multisite float         : Result[1]             -- dummy array for measured results
end_local

body

    if EntryState == ALIGN then -- This is not supported for this command
        set digital ppmu InPins to fi 1pA imax IRange clamps to vmin VCLAMP_MIN vmax VCLAMP_MAX delay 0mS
        disconnect digital pin InPins from ppmu delay 0ms
        println(stdout,"WARNING : Invalid EntryState of ",EntryState," specified in routine 'ppmu_connect_FVMI'")
        println(stdout,"          PPMU has been disconnected on channels ",InPins)
    else
        ppmu_connect_meas_FVMI( InPins , VForce , IRange , VSteps , VCLAMP_MIN , VCLAMP_MAX , 0ms , 0 , PAR_MEAS , Result , EntryState , EntryWait , VEntry  , HOLD , 0ms )
    end_if



end_body
------------------------------------------------------------------------------------------------------------------


