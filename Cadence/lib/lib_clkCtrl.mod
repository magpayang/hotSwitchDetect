-------------------------------------------------------------------------------------------
--                                                                                       --
--                                     MX Clock Control                                  --
--                                                                                       --
--                                     Author : C.HUGHES                                 --  
--                                                                                       --
--                                                                                       --
-------------------------------------------------------------------------------------------

-------------------------------------------------------------------------------------------
--                                                                                       --
--                                  REVISION LOG                                         --
--                                                                                       --
-- Revision         Who     Comments                                                     --
--
-- Aug 18 2005      CH      First Version
-- Oct 20 2005      CH      Added BS additional routines
-- Oct 27 2005      CH      changed SAMPLE_CLK_LEVEL to 16.0
-- Jan 18 2006      CH      Added Table mode to speed up IQ modulation switching
--                          Removed the procedure 'SetAuxiliaryClkMod' which
--                          is not required.
-- May 01 2006      CH      Increased resolution of frequency string for GPIB commands.
-- Jan 09 2007      CH      Moved Table mode to routine 'SetAuxiliaryClkTableMode'
--                          This is so this can be run during the calibration only.
-- Feb 16 2007      CH      Added 'SetSampleClkQuiet'
-- Oct 12 2020      WDC     Added URV5 code
-------------------------------------------------------------------------------------------
-- The following routines are available to the user:
-- All other routines are 'private' and for local use by the software module

-- InitAllClks

-- InitJitterClk
-- EnableJitterClk
-- SetJitterClkFrequency
-- SetJitterClkLevel
-- SetJitterClkModulation
-- EnableJitterClkAtLevel
-- EnableJitterClkForRJ

-- InitAuxiliaryClk
-- SetAuxiliaryClkFrequency
-- SetAuxiliaryClkLevel
-- SetAuxiliaryClkIQ
-- SetAuxiliaryClkTableMode

-- InitSampleClk
-- SetSampleClkFrequency
-- SetSampleClkFrequencyOnly
-- SetSampleClkLevel
-- SetSampleClkIQ
-- SetSampleClkMod
-- SetSampleClkQuiet

-- ScopeTrigger

-------------------------------------------------------------------------------------------
--                                                                                       --
--                              TEST PROGRAM  MODULES                                    --
--                                                                                       --
-------------------------------------------------------------------------------------------
--use module "urv5_control.mod"




-- STATIC VARIABLES REQUIRED TO CONTROL THE JITTER CLOCK
 
static double                       : RfFreq 
static double                       : RfAmplitude 
static string[10]                   : RfOutOn  = " "
static string[10]                   : RfIqOn = " "
static string[10]                   : RfExtOn = " "
static string[10]                   : RfModOn = " "
static string[10]                   : RfLevelingOn = " "

static boolean                      : RfIqMode = false
static boolean                      : JittClkEn = false

static integer                      : rfClkGenType = AGILENT_E8267C
static string [80]                  : rfClkGpibCommands [ GENERATOR_TYPES , RF_CLK_COMMANDS ]

-- STATIC VARIABLES REQUIRED TO CONTROL THE AUX CLOCK
static double                       : AuxClkFreq
static double                       : AuxClkAmplitude 
static string[10]                   : AuxModOn = " "
static string[10]                   : AuxModIq = " "

-- STATIC VARIABLES REQUIRED TO CONTROL THE SAMPLER CLOCK
static double                       : SampleClkFreq

static boolean                      : ScopeMode = false
static double                       : SampleClkAmplitude 
static string[32]                   : Operator_Input_user = ""
static boolean                      : afe_config = false

-- STATIC VARIABLES REQUIRED TO CONTROL THE CLK3 CLOCK
static double                       : Clk3Freq
static double                       : Clk3Amplitude
static string[10]                   : Clk3ModOn = " "
static string[10]                   : Clk3ModIq = " "

-- STATIC VARIABLES REQUIRED TO CONTROL THE CLK3 CLOCK
static double                       : Clk4Freq
static double                       : Clk4Amplitude
static string[10]                   : Clk4ModOn = " "
static string[10]                   : Clk4ModIq = " "

 

const AGILENT_E8267C                = 1
const ANRITSU_MG369XA               = 1 + AGILENT_E8267C
const GENERATOR_TYPES               = ANRITSU_MG369XA
                                    
const RF_CLK_MOD_ON                 = 1 + 0
const RF_CLK_MOD_OFF                = 1 + RF_CLK_MOD_ON
const RF_CLK_AMPL_2                 = 1 + RF_CLK_MOD_OFF
const RF_CLK_AMPL_1                 = 1 + RF_CLK_AMPL_2
const RF_CLK_FREQ_2                 = 1 + RF_CLK_AMPL_1
const RF_CLK_FREQ_1                 = 1 + RF_CLK_FREQ_2
const RF_CLK_RESET                  = 1 + RF_CLK_FREQ_1
const RF_CLK_COMMANDS               = RF_CLK_RESET
                                     

-- CONSTANTS REQUIRED TO CONTROL THE RPF CONTROLLED JITTER CLOCK

const RFP_CLK_LEVEL                 = -5.0dBm
                                    
const RFP_MIN_FREQ                  = 300KHz
const RFP_MAX_FREQ                  = 6.4GHz
                                     
-- CONSTANTS REQUIRED TO CONTROL THE OPTIONAL AGILENT JITTER CLOCK

const RFCLK1_GPIB_ADDR              = 19
const RFCLK1_MIN_FREQ               = 0GHz
const RFCLK1_MAX_FREQ               = 20GHz
const RFCLK1_MAX_LEVEL              = +25 dBm
const RFCLK1_MIN_LEVEL              = -135 dBm
const RFCLK1_LEVEL                  = -3dBm
                                     
-- CONSTANTS REQUIRED TO CONTROL THE REFERENCE CLOCK

const AUX_CLK_GPIB_ADDR             = 8
const AUX_CLK_MIN_FREQ              = 300KHz
const AUX_CLK_MAX_FREQ              = 6.0GHz
const AUX_CLK_MAX_LEVEL             = +10 dBm
const AUX_CLK_MIN_LEVEL             = -140 dBm
const AUX_CLK_MAX_LEVEL_SMA100      = +16 dBm
const AUX_CLK_MIN_LEVEL_SMA100      = -145 dBm
                                    
const AUX_CLK_LEVEL                 = 0.0 dBm
                                    
-- -- CONSTANTS REQUIRED TO CONTROL THE MX SAMPLE CLOCK
-- 
const SAMPLE_CLK_GPIB_ADDR          = 9
const SAMPLE_CLK_MIN_FREQ           = 300KHz
const SAMPLE_CLK_MAX_FREQ           = 6.0GHz
const SAMPLE_CLK_LEVEL              = 16.0
const SAMPLE_CLK_MAX_LEVEL_SMA100   = +16 dBm
const SAMPLE_CLK_MIN_LEVEL_SMA100   = -145 dBm
const SAMPLE_CLK_MAX_LEVEL          = +10 dBm
const SAMPLE_CLK_MIN_LEVEL          = -140 dBm

const CLK3_GPIB_ADDR                = 11
const CLK3_MIN_FREQ                 = 300KHz
const CLK3_MAX_FREQ                 = 6.0GHz
const CLK3_LEVEL                    = 16.0
const CLK3_MAX_LEVEL_SMA100         = +10 dBm
const CLK3_MIN_LEVEL_SMA100         = -90 dBm
const CLK3_MAX_LEVEL                = +16 dBm
const CLK3_MIN_LEVEL                = -140 dBm
static boolean                      : gen3Installed

const CLK4_GPIB_ADDR                = 11
const CLK4_MIN_FREQ                 = 300KHz
const CLK4_MAX_FREQ                 = 6.0GHz
const CLK4_LEVEL                    = 16.0
const CLK4_MAX_LEVEL_SMA100         = +10 dBm
const CLK4_MIN_LEVEL_SMA100         = -90 dBm
const CLK4_MAX_LEVEL                = +16 dBm
const CLK4_MIN_LEVEL                = -140 dBm
static boolean                      : gen4Installed

const RF_CAL_REFERENCE_LEVEL        = 5.0dBm

static double                       : aux_clk_max_level    = AUX_CLK_MAX_LEVEL
static double                       : aux_clk_min_level    = AUX_CLK_MIN_LEVEL
static double                       : sample_clk_max_level = SAMPLE_CLK_MAX_LEVEL
static double                       : sample_clk_min_level = SAMPLE_CLK_MIN_LEVEL
static double                       : clk3_max_level       = CLK3_MAX_LEVEL
static double                       : clk3_min_level       = CLK3_MIN_LEVEL
static double                       : clk4_max_level       = CLK4_MAX_LEVEL
static double                       : clk4_min_level       = CLK4_MIN_LEVEL
                                                             
static float                        : optimumJitterClockLevel = -8.0dBm
static boolean                      : jitBiasCalibrated = false
static integer                      : clkTyp
                                
const SRC_PREFIX                    = 1
const INIT_CLK_1                    = SRC_PREFIX       + 1
const INIT_CLK_2                    = INIT_CLK_1       + 1
const INIT_CLK_3                    = INIT_CLK_2       + 1
const SET_FREQ                      = INIT_CLK_3       + 1
const SET_LEVEL1                    = SET_FREQ         + 1
const SET_LEVEL2                    = SET_LEVEL1       + 1
const SET_IQ1                       = SET_LEVEL2       + 1
const SET_IQ2                       = SET_IQ1          + 1
const RESET_AND_CLEAR               = SET_IQ2          + 1
const SET_TABLE_MODE1               = RESET_AND_CLEAR  + 1
const GPIB_NUM_STRINGS              = SET_TABLE_MODE1
                                   
const SMIQ_CLK                      = 1
const AFE_CLK                       = SMIQ_CLK         + 1
const SMATE_CLK                     = AFE_CLK          + 1
const GPIB_GEN_TYPES                = SMATE_CLK
                                
static word                         : sampClkGPIBAddr [ 3 ]
                                
const AUX_CLK                       = 1
const SMP_CLK                       = 2
static string [ 16 ]                : srcPrefix [ 3 , 2 ]
static string [ 16 ]                : outPrefix [ 3 , 2 ]
                                    
static string [ 256 ]               : gpibCmds [ GPIB_NUM_STRINGS , GPIB_GEN_TYPES ]
static boolean                      : gpibInitialized = false
static integer                      : genType
                   
const URV5_GPIB_ADDRESS             = 10
const GPIB_LENGTH                   = 255  -- default string length
const POWER_METER_DELAY             = 5s   -- time delay needed for the power meter (URV5) to zero its offset
                                
global boolean                      : enable_urv5_optimization  =  true   -- set to false to revert to unoptimized URV5 measurements
global integer                      : gpib_timeout_count = 0

const CAL_RF_FREQ_SZ                = 1000
const CAL_MAGN                      = 1
const CAL_FREQ                      = 2

static double                       : magFreqPairs [ 2 , CAL_RF_FREQ_SZ ]
static double                       : auxClkCalAry [ CAL_RF_FREQ_SZ ]
static double                       : smpClkCalAry [ CAL_RF_FREQ_SZ ]
static double                       : clk3CalAry   [ CAL_RF_FREQ_SZ ]
static double                       : clk4CalAry   [ CAL_RF_FREQ_SZ ]

const RF_FREQ_CK_SZ                 = 1649
const RF_LEVEL_CK_SZ                = 3

static boolean                      : smateExists
-------------------------------------------------------------------------------------------
procedure initGPIBStrings
-------------------------------------------------------------------------------------------

local string [ 256 ]        : identStr

body

    if gpibInitialized then
        return
    endif
    talk cx to gpib address AUX_CLK_GPIB_ADDR with "*RST;*CLS"
    talk cx to gpib address AUX_CLK_GPIB_ADDR with "*IDN?"

    listen cx to gpib adr AUX_CLK_GPIB_ADDR into identStr for 80 bytes
--    println(stdout,"GPIB ADDR: ", AUX_CLK_GPIB_ADDR )
--    println(stdout,identStr)

    if     pos ( "SMIQ06" , identStr ) > 0 then
        genType = SMIQ_CLK
    elseif pos ( "SMA100" , identStr ) > 0 then
        genType = AFE_CLK
    elseif pos ( "SMATE"  , identStr ) > 0 then
        genType = SMATE_CLK
    elseif tester_simulated then
        genType = SMATE_CLK
    else
        println ( stdout , "Can't find supported generator at GIPB ADDR 8!  Halting.... " )
        halt
    endif
    
    sampClkGPIBAddr [ AFE_CLK   ] = SAMPLE_CLK_GPIB_ADDR
    sampClkGPIBAddr [ SMIQ_CLK  ] = SAMPLE_CLK_GPIB_ADDR
    sampClkGPIBAddr [ SMATE_CLK ] = AUX_CLK_GPIB_ADDR  -- smate uses same GPIB addr for both channels

    srcPrefix [ AFE_CLK         , AUX_CLK   ] = "SOURCE:"
    srcPrefix [ AFE_CLK         , SMP_CLK   ] = "SOURCE:"
    srcPrefix [ SMIQ_CLK        , AUX_CLK   ] = "SOURCE:"
    srcPrefix [ SMIQ_CLK        , SMP_CLK   ] = "SOURCE:"
    srcPrefix [ SMATE_CLK       , AUX_CLK   ] = "SOURCE1:"
    srcPrefix [ SMATE_CLK       , SMP_CLK   ] = "SOURCE2:"
    
    outPrefix [ AFE_CLK         , AUX_CLK   ] = "OUTP:"
    outPrefix [ AFE_CLK         , SMP_CLK   ] = "OUTP:"
    outPrefix [ SMIQ_CLK        , AUX_CLK   ] = "OUTP:"
    outPrefix [ SMIQ_CLK        , SMP_CLK   ] = "OUTP:"
    outPrefix [ SMATE_CLK       , AUX_CLK   ] = "OUTP1:"
    outPrefix [ SMATE_CLK       , SMP_CLK   ] = "OUTP2:"
    
    gpibCmds [ INIT_CLK_1       , AFE_CLK   ]  = "*SRE 0"
    gpibCmds [ INIT_CLK_1       , SMIQ_CLK  ]  = "POW:ALC:SEAR OFF"
    gpibCmds [ INIT_CLK_1       , SMATE_CLK ]  = "POW:ALC:SEAR OFF"

    gpibCmds [ INIT_CLK_2       , AFE_CLK   ]  = ""
    gpibCmds [ INIT_CLK_2       , SMIQ_CLK  ]  = "DM:IQ:TRAN FAST"
    gpibCmds [ INIT_CLK_2       , SMATE_CLK ]  = "IQ:TRAN FAST"
    
    gpibCmds [ INIT_CLK_3       , AFE_CLK   ]  = "ROSC:SOUR EXT"
    gpibCmds [ INIT_CLK_3       , SMIQ_CLK  ]  = "ROSC:SOUR EXT"
    gpibCmds [ INIT_CLK_3       , SMATE_CLK ]  = "ROSC:SOUR EXT"
                                                  
    gpibCmds [ SET_FREQ         , AFE_CLK   ]  = "FREQ "
    gpibCmds [ SET_FREQ         , SMIQ_CLK  ]  = "FREQ "
    gpibCmds [ SET_FREQ         , SMATE_CLK ]  = "FREQ "

    gpibCmds [ SET_LEVEL1       , AFE_CLK   ]  = "POW "
    gpibCmds [ SET_LEVEL1       , SMIQ_CLK  ]  = "POW "
    gpibCmds [ SET_LEVEL1       , SMATE_CLK ]  = "POW "

    gpibCmds [ SET_LEVEL2       , AFE_CLK   ]  = "STAT ON"
    gpibCmds [ SET_LEVEL2       , SMIQ_CLK  ]  = "STAT ON"
    gpibCmds [ SET_LEVEL2       , SMATE_CLK ]  = "STAT ON"
                                                  
    gpibCmds [ SET_IQ1          , AFE_CLK   ]  = ""
    gpibCmds [ SET_IQ1          , SMIQ_CLK  ]  = "DM:IQ:STAT ON"
    gpibCmds [ SET_IQ1          , SMATE_CLK ]  = "IQ:STAT ON"

    gpibCmds [ SET_IQ2          , AFE_CLK   ]  = ""
    gpibCmds [ SET_IQ2          , SMIQ_CLK  ]  = "DM:IQ:STAT OFF"
    gpibCmds [ SET_IQ2          , SMATE_CLK ]  = "IQ:STAT OFF"

    gpibCmds [ RESET_AND_CLEAR  , AFE_CLK   ]  = "*RST;*CLS"
    gpibCmds [ RESET_AND_CLEAR  , SMIQ_CLK  ]  = "*RST;*CLS"
    gpibCmds [ RESET_AND_CLEAR  , SMATE_CLK ]  = "*RST;*CLS"

    gpibCmds [ SET_TABLE_MODE1  , AFE_CLK   ]  = ""
    gpibCmds [ SET_TABLE_MODE1  , SMIQ_CLK  ]  = "SOUR:POW:ALC:TABL:MEAS?"
    gpibCmds [ SET_TABLE_MODE1  , SMATE_CLK ]  = "SOUR:POW:ALC:TABL:MEAS?"
    
    gpibInitialized = true

endbody
-------------------------------------------------------------------------------------------
procedure InitJitterClk
------------------------------------------------------------------------------------------------------
local string [ 10 ] : test_gpib

body


    send cx gpib device clear to address RFCLK1_GPIB_ADDR
    talk cx to gpib address RFCLK1_GPIB_ADDR with "*RST" 
    talk cx to gpib address RFCLK1_GPIB_ADDR with "*IDN?"
    listen cx to gpib address RFCLK1_GPIB_ADDR into test_gpib for 50 bytes

    Rfclk1_reset
    Rfclk1_set_10MHz_reference("ext")
    Rfclk1_DM_sel_IQ_signal_source("ext")
    Rfclk1_switch_IQ_modulation("off")
    Rfclk1_enable_output_modulation("off")
    Rfclk1_DM_auto_BBfilter("off")
    Rfclk1_DM_select_BBfilter("off")
--    Rfclk1_EnableLeveling ( "on" )
    
    Rfclk1_set_frequency(1.0GHz)
    Rfclk1_set_amplitude(-100.0)
    Rfclk1_enable_RF_output("off")

    RfIqMode = false
    RfModOn = ""
    EnableJitterClk("off",RFP_MIN_FREQ)

endbody
--------------------------------------------------------------------------------
procedure SetJitterClkModulation(mod_mode)
--------------------------------------------------------------------------------
in string[20]       : mod_mode

body

    if mod_mode = "off" then

        Rfclk1_enable_output_modulation ( "off" )
        Rfclk1_switch_IQ_modulation ( "off" )

    elseif mod_mode = "on" then

        Rfclk1_enable_output_modulation ( "on" )
        Rfclk1_switch_IQ_modulation ( "off" )

    elseif mod_mode = "iq" then
    
        Rfclk1_enable_output_modulation ( "on" )
        Rfclk1_switch_IQ_modulation ( "on" )
        
    else
    
        println ( stdout , "Illegal parameter " + sprint ( mod_mode ) + "." )
        println ( stdout , "Argument to procedure 'SetJitterClkModulation' must be 'iq' 'on' or 'off'" )
        println ( stdout , "Halted from procedure 'SetJitterClkModulation'" )
        halt
        
    endif
    wait(30ms)

endbody
--------------------------------------------------------------------------------
private procedure Rfclk1_DM_sel_IQ_signal_source(signal_source)
--------------------------------------------------------------------------------
-- EXTernal - selects a 50 ohm impedence for the I and Q connectors and routes
-- the applied signals to the I/Q modulator
-- INTernal -  same function as the BBG1 selection (included for backward compatibility)
-- BBG1 - selects the baseband generator as the source for the I/Q signals and
-- requires Option 002/602
-- EXT600 - selects a 600 ohm impedence for the I and Q input connectors (on rear panel)
-- and routes the applied signals to the I/Q modulator                    
-- OFF - disables the digital modulation source

in string [ 10 ]        :  signal_source
 
local string [ 200 ]    : gpib_command

body

    if signal_source <> RfExtOn then
        if signal_source = "ext" then
            gpib_command = "DM:SOUR EXT"
        elseif signal_source = "int" then
            gpib_command = "DM:SOUR INT"
        elseif signal_source = "bbg1" then
            gpib_command = "DM:SOUR BBG1"
        elseif signal_source = "ext600" then
            gpib_command = "DM:SOUR EXT600"  
        elseif signal_source = "off" then
            gpib_command = "DM:SOUR OFF"
        else
            println(stdout, "Illegal parameter "+sprint(signal_source)+".")
            println(stdout, "Argument to procedure 'Rfclk1_DM_select_IQ_signal_source' must be 'EXT'; 'INT'; 'BBG1'; 'EXT600'; or 'OFF'")
            println(stdout, "Halted from procedure 'Rfclk1_DM_select_IQ_signal_source'")
            halt
        endif

        talk cx to gpib address RFCLK1_GPIB_ADDR with gpib_command
        RfExtOn = signal_source
    endif
   
endbody
--------------------------------------------------------------------------------
private procedure Rfclk1_enable_output_modulation ( on_off )
--------------------------------------------------------------------------------
  
in string [ 10 ]        : on_off -- boolean expression  
                       
local string [ 200 ]    : gpib_command

body

    if on_off <> RfModOn then
        if on_off = "on" then
            gpib_command = "OUTP:MODulation ON"
        elseif on_off = "off" then
            gpib_command = "OUTP:MODulation OFF"
        else
            println(stdout, "Illegal parameter "+sprint(on_off)+".")
            println(stdout, "Argument to procedure 'rfclk1_enable_output_modulation' must be 'on' or 'off'")
            println(stdout, "Halted from procedure 'rfclk1_enable_output_modulation'")
            halt
        endif

        talk cx to gpib address RFCLK1_GPIB_ADDR with gpib_command 
        RfModOn = on_off
    endif 
    
endbody
--------------------------------------------------------------------------------
private procedure Rfclk1_enable_RF_output ( on_off )
--------------------------------------------------------------------------------  
in string[10]:  on_off -- boolean expression

local string [ 200 ]        : gpib_command

body

    if  on_off <> RfOutOn then
        if on_off = "on" then
            gpib_command = "OUTP ON"     
        elseif on_off = "off" then
            gpib_command = "OUTP OFF"
        else
            println(stdout, "Illegal parameter "+sprint(on_off)+".")
            println(stdout, "Argument to procedure 'rfclk1_enable_RF_output' must be 'on' or 'off'")
            println(stdout, "Halted from procedure 'rfclk1_enable_RF_output'")
            halt
        endif
        talk cx to gpib address RFCLK1_GPIB_ADDR with gpib_command 
        RfOutOn = on_off
    endif
    Rfclk1_gate_op( on_off )
endbody
--------------------------------------------------------------------------------
private procedure Rfclk1_gate_op(on_off)
--------------------------------------------------------------------------------
in string [ 10 ]    :  on_off -- boolean expression to set gate on or off

local string [ 20 ] : gpib_command
 
body

    if on_off = "on" then
        gpib_command = "OUTP:STAT ON"
    elseif on_off = "off" then
        gpib_command = "OUTP:STAT OFF"
    else
        println(stdout, "Illegal parameter "+sprint(on_off)+".")
        println(stdout, "Argument to procedure 'gpib_gate_op' must be 'on' or 'off'")
        println(stdout, "Halted from procedure 'gpib_gate_op'")
        halt
    endif

    talk cx to gpib address  RFCLK1_GPIB_ADDR with gpib_command
   
endbody
--------------------------------------------------------------------------------
private procedure Rfclk1_reset
-----------------------------------------------------------------------

local string [ 20 ]     : gpib_command

body

    gpib_command = "*RST"
    talk cx to gpib address RFCLK1_GPIB_ADDR with gpib_command 
    RfFreq = 0.0Hz
    RfAmplitude = 0.0
    RfOutOn = " "
    RfIqOn =  " "
    
endbody
-----------------------------------------------------------------------
private procedure Rfclk1_set_10MHz_reference ( ext_int )
--------------------------------------------------------------------------------
in string[10]:  ext_int -- boolean expression to set reference to external or internal

local string[20]: gpib_command

body

    if ext_int = "ext" then
        gpib_command = "SOUR:ROSC:SOUR EXT"
    elseif ext_int = "int" then
        gpib_command = "SOUR:ROSC:SOUR INT"
    else
        println(stdout, "Illegal parameter "+sprint(ext_int)+".")
        println(stdout, "Argument to procedure 'gpib_gate_op' must be 'ext' or 'int'")
        println(stdout, "Halted from procedure 'rfclk1_set_10MHz_reference'")
        halt
    endif
    
    talk cx to gpib address RFCLK1_GPIB_ADDR with gpib_command

endbody
--------------------------------------------------------------------------------
private procedure Rfclk1_set_amplitude ( gpib_amplitude )
--------------------------------------------------------------------------------
in double               : gpib_amplitude   -- in dBm

local string [ 200 ]    : gpib_command_str 
 
body
      
    if  gpib_amplitude <> RfAmplitude then
        if gpib_amplitude > RFCLK1_MAX_LEVEL then
            println(stdout, "Maximum value for amplitude is "+sprint(RFCLK1_MAX_LEVEL)+" dBm.")
            println(stdout, "Halted from procedure 'rfclk1_set_amplitude'")
            halt
        elseif gpib_amplitude < RFCLK1_MIN_LEVEL then
            println(stdout, "Minimum value for amplitude is "+sprint(RFCLK1_MIN_LEVEL)+" dBm.")
            println(stdout, "Halted from procedure 'rfclk1_set_amplitude'")
            halt
        else      
            gpib_command_str = "POW:AMPL  "+sprint(gpib_amplitude:8:6)+"dBm"
            talk cx to gpib adr RFCLK1_GPIB_ADDR with gpib_command_str
            RfAmplitude = gpib_amplitude
        endif
    endif
    
endbody
--------------------------------------------------------------------------------
private procedure Rfclk1_set_frequency ( gpib_freq )
--------------------------------------------------------------------------------
in double: gpib_freq
 
local string[200]: gpib_command_str  

body
      
    if gpib_freq <> RfFreq then
        if gpib_freq > RFCLK1_MAX_FREQ then
            println(stdout, "Maximum value for frequency is "+sprint(RFCLK1_MAX_FREQ)+" Hz.")
            println(stdout, "Halted from procedure 'rfclk1_set_frequency'")
            halt
        else
            gpib_command_str = "FREQuency "+sprint(gpib_freq:12:10)+"Hz"
            talk cx to gpib address RFCLK1_GPIB_ADDR with gpib_command_str 
            RfFreq = gpib_freq
        endif
    endif
    
endbody
--------------------------------------------------------------------------------
private procedure Rfclk1_switch_IQ_modulation ( on_off ) -- turn IQ modulation on or off
--------------------------------------------------------------------------------

in string [ 10 ]        :  on_off -- boolean expression to turn IQ modulation on or off

local string [ 200 ]    : gpib_command

body
   
    if on_off <> RfIqOn then
        if on_off = "on" then
            gpib_command = "SOUR:DM:STAT ON"
        elseif on_off = "off" then
            gpib_command = "SOUR:DM:STAT OFF"
        else
            println(stdout, "Illegal parameter "+sprint(on_off)+".")
            println(stdout, "Argument to procedure 'rfclk1_switch_IQ_modulation' must be 'on' or 'off'")
            println(stdout, "Halted from procedure 'rfclk1_switch_IQ_modulation'")
            halt
        endif

        talk cx to gpib address RFCLK1_GPIB_ADDR with gpib_command
        RfIqOn = on_off
    endif
    
endbody
----------------------------------------------------------------------------- 
private procedure Rfclk1GpibInit ( rfClk1GeneratorType )
--------------------------------------------------------------------------------
in integer              : rfClk1GeneratorType

body

    rfClkGenType = rfClk1GeneratorType
    
    rfClkGpibCommands [ ANRITSU_MG369XA , RF_CLK_RESET ]        = "*RST"
    rfClkGpibCommands [ AGILENT_E8267C  , RF_CLK_RESET ]        = "*RST"

    rfClkGpibCommands [ ANRITSU_MG369XA , RF_CLK_FREQ_1 ]       = "F0 "
    rfClkGpibCommands [ AGILENT_E8267C  , RF_CLK_FREQ_1 ]       = "FREQuency "

    rfClkGpibCommands [ ANRITSU_MG369XA , RF_CLK_FREQ_2 ]       = "HZ"
    rfClkGpibCommands [ AGILENT_E8267C  , RF_CLK_FREQ_2 ]       = "Hz"

    rfClkGpibCommands [ ANRITSU_MG369XA , RF_CLK_AMPL_1 ]       = "L0 "
    rfClkGpibCommands [ AGILENT_E8267C  , RF_CLK_AMPL_1 ]       = "POW:AMPL "

    rfClkGpibCommands [ ANRITSU_MG369XA , RF_CLK_AMPL_2 ]       = ""
    rfClkGpibCommands [ AGILENT_E8267C  , RF_CLK_AMPL_2 ]       = "dBm"

    rfClkGpibCommands [ ANRITSU_MG369XA , RF_CLK_MOD_ON ]       = ""
    rfClkGpibCommands [ AGILENT_E8267C  , RF_CLK_MOD_ON ]       = "OUTP:MODulation ON"

    rfClkGpibCommands [ ANRITSU_MG369XA , RF_CLK_MOD_OFF ]      = ""
    rfClkGpibCommands [ AGILENT_E8267C  , RF_CLK_MOD_OFF ]      = "OUTP:MODulation OFF"


endbody
--------------------------------------------------------------------------------
private procedure Rfclk1_DM_auto_BBfilter(on_off)
--------------------------------------------------------------------------------
in string [ 10 ]        : on_off -- "on" enables automatic selection of the filters for I/Q signals
                                 
local string [ 200 ]    : gpib_command


body

    if on_off = "on" then
        gpib_command = "SOUR:DM:BBFilter:AUTO ON"
    elseif on_off = "off" then
        gpib_command = "SOUR:DM:BBFilter:AUTO OFF"
    else
        println(stdout, "Illegal parameter "+sprint(on_off)+".")
        println(stdout, "Argument to procedure 'Rfclk1_DM_auto_basebandfilter' must be 'on' or 'off'")
        println(stdout, "Halted from procedure 'Rfclk1_DM_auto_basebandfilter'")
        halt
    endif

    talk cx to gpib address RFCLK1_GPIB_ADDR with gpib_command 
 
endbody
--------------------------------------------------------------------------------
private procedure Rfclk1_DM_select_BBfilter(on_off)
--------------------------------------------------------------------------------  
in string[10]:  on_off --  on = 40MHz filter; off = bypass

local string[200]: GPIB_command


body

    if on_off = "on" then
        GPIB_command = "SOUR:DM:BBFilter 40E6"
    elseif on_off = "off" then
        GPIB_command = "SOUR:DM:BBFilter THRough"
    else
        println(stdout, "Illegal parameter "+sprint(on_off)+".")
        println(stdout, "Argument to procedure 'Rfclk1_DM_select_basebandfilter' must be 'on' or 'off'")
        println(stdout, "Halted from procedure 'Rfclk1_DM_select_basebandfilter'")
        halt
    endif

    talk cx to gpib adr RFCLK1_GPIB_ADDR with GPIB_command
 
endbody
--------------------------------------------------------------------------------
procedure SetJitterClkFrequency(BitRate)
--------------------------------------------------------------------------------
in double       : BitRate
body

if BitRate <> RfFreq then

    Rfclk1_set_frequency ( BitRate )
    RfFreq = BitRate

end_if

endbody
--------------------------------------------------------------------------------
procedure EnableJitterClk ( jitClk_enable , bitRate )
------------------------------------------------------------------------
in string[20]       : jitClk_enable -- Turn on/off the jitter clock
in double           : bitRate       -- BitRate of VXGTO's output if timing is from Jitter Clock
------------------------------------------------------------------------
--  This procedure sets the Jitter Clock's frequency to BitRate and 
--  turns on/off the power amplifier driving the VXGTO transmitter's Jitter Clock Input
------------------------------------------------------------------------
body
    
    if jitClk_enable = "on" then

        Rfclk1_set_frequency(bitRate)
        if bitRate > 6.0GHz and bitRate < 9.0GHz then
            Rfclk1_set_amplitude ( double ( optimumJitterClockLevel ) )
        else
            Rfclk1_set_amplitude ( -20.0dBm +  2.0 * double ( integer ( 0.5 * ( bitRate + 0.5GHz - 1.25GHz ) / 537500000.0 ) ) )  -- sets  jitter cock to -20 dbm @ 1.25GHz and 0dBm at 12GHz
        endif
        Rfclk1_enable_RF_output("on")
        wait(115ms)
        JittClkEn = true

    else_if jitClk_enable = "off" then

        Rfclk1_set_frequency( bitRate )
        Rfclk1_set_amplitude( -100.0 )
        Rfclk1_enable_RF_output( "off" )
        wait(5ms)
        JittClkEn = false
    else
        println(stdout, "Illegal parameter "+sprint(jitClk_enable)+".")
        println(stdout, "Argument to procedure 'EnableJitterClock' must be 'on' or 'off'")
        println(stdout, "Halted from procedure 'EnableJitterClock'")
        halt
    end_if
        
endbody
----------------------------------------------------------------------------- 
procedure InitAllClks
------------------------------------------------------------------------------------------------------

body

    InitJitterClk
    InitAuxiliaryClk
    InitSampleClk
    
endbody
--------------------------------------------------------------------------------
procedure ScopeTrigger(BitRate,BitsPerWaveform)
------------------------------------------------------------------------------
in double    : BitRate          --  Data rate of pattern
in integer   : BitsPerWaveform  --  Number of device bits captured in waveform
------------------------------------------------------------------------------
--  This procedure permits using the sample clock as a scope trigger when static
--  variable ScopeMode is set true.
------------------------------------------------------------------------------
body

if ScopeMode then

    SetSampleClkFrequency(BitRate/double(BitsPerWaveform)/8.0)
    wait(0ms)     -- SET BREAKPOINT HERE TO OBSERVE ON OSCILLOSCOPE

end_if

endbody
------------------------------------------------------------------------------
procedure EnableJitterClkAtLevel(JitClk_enable,BitRate,Level)
------------------------------------------------------------------------
in string[20]   : JitClk_enable -- Turn on/off the jitter clock
in double       : BitRate       -- BitRate of VXGTO's output if timing is from Jitter Clock
in float        : Level         -- Programmed amplitude in dBm
------------------------------------------------------------------------
--  This procedure sets the Jitter Clock's frequency to BitRate and 
--  turns on/off the power amplifier driving the VXGTO transmitter's Jitter Clock Input
------------------------------------------------------------------------
body
    
    if JitClk_enable = "on" then

        Rfclk1_set_frequency(BitRate)
        Rfclk1_set_amplitude(double(Level))
        Rfclk1_enable_RF_output("on")
        JittClkEn = true

    else_if JitClk_enable = "off" then

        Rfclk1_set_frequency(BitRate)
        Rfclk1_set_amplitude(-100.0)
        Rfclk1_enable_RF_output("off")
        JittClkEn = false
    else
        println(stdout, "Illegal parameter "+sprint(JitClk_enable)+".")
        println(stdout, "Argument to procedure 'EnableJitterClock' must be 'on' or 'off'")
        println(stdout, "Halted from procedure 'EnableJitterClock'")
        halt
    end_if
        
endbody
----------------------------------------------------------------------------- 
procedure EnableJitterClkForRJ(JitClk_enable,BitRate)
------------------------------------------------------------------------
in string[20]   : JitClk_enable -- Turn on/off the jitter clock
in double       : BitRate       -- BitRate of VXGTO's output if timing is from Jitter Clock
------------------------------------------------------------------------
--  This procedure sets the Jitter Clock's frequency to BitRate and 
--  turns on/off the power amplifier driving the VXGTO transmitter's Jitter Clock Input
------------------------------------------------------------------------
body
    
    if JitClk_enable = "on" then

        Rfclk1_set_frequency(BitRate)
        Rfclk1_set_amplitude ( -20.0dBm + ( BitRate - 1.25GHz ) / 537500000.0 )  -- sets  jitter cock to -20 dbm @ 1.25GHz and 0dBm at 12GHz
        Rfclk1_enable_RF_output("on")
        JittClkEn = true

    else_if JitClk_enable = "off" then

        Rfclk1_set_frequency(BitRate)
        Rfclk1_enable_RF_output("off")
        JittClkEn = false
    else
        println(stdout, "Illegal parameter "+sprint(JitClk_enable)+".")
        println(stdout, "Argument to procedure 'EnableJitterClock' must be 'on' or 'off'")
        println(stdout, "Halted from procedure 'EnableJitterClock'")
        halt
    end_if
        
endbody
----------------------------------------------------------------------------- 
procedure SetJitterClkLevel(inLevel)
--------------------------------------------------------------------------------
in double       : inLevel
body

        if inLevel <= RFCLK1_MAX_LEVEL and inLevel >= RFCLK1_MIN_LEVEL then
            Rfclk1_set_amplitude ( inLevel )
       else
            println(stdout, "Programmed  value is "+sprint(inLevel)+" dBm.")
            println(stdout, "Minimum value for level is "+sprint(RFCLK1_MIN_LEVEL)+" dBm.")
            println(stdout, "Maximum value for level is "+sprint(RFCLK1_MAX_LEVEL)+" dBm.")
            println(stdout, "Halted from procedure 'SetJitterClkLevel'")
            halt
        endif
 
endbody
--------------------------------------------------------------------------------
 procedure Rfclk1_EnableLeveling ( on_off ) -- turn IQ modulation on or off
--------------------------------------------------------------------------------

in string [ 10 ]        :  on_off -- boolean expression to turn IQ modulation on or off

local string [ 200 ]    : gpib_command

body
   
    if on_off = "on" then
        gpib_command = ":CORR ON"
         talk cx to gpib address RFCLK1_GPIB_ADDR with ":POW:ATT:AUTO OFF"
         talk cx to gpib address RFCLK1_GPIB_ADDR with ":POW:ATT 20DB"
         talk cx to gpib address RFCLK1_GPIB_ADDR with ":POW:ALC:SOUR DIOD"
         talk cx to gpib address RFCLK1_GPIB_ADDR with ":POW:ALC ON"
    elseif on_off = "off" then
        gpib_command = ":CORR OFF"
    else
        println(stdout, "Illegal parameter "+sprint(on_off)+".")
        println(stdout, "Argument to procedure 'rfclk1_switch_IQ_modulation' must be 'on' or 'off'")
        println(stdout, "Halted from procedure 'rfclk1_switch_IQ_modulation'")
        halt
    endif

    talk cx to gpib address RFCLK1_GPIB_ADDR with gpib_command
    RfLevelingOn = on_off
    
endbody
----------------------------------------------------------------------------- 
private procedure InitSMIQAuxClock ( gpibAddr )
--------------------------------------------------------------------------------
in word                 : gpibAddr

local
  string[1]             : y_n = ""
  integer               : i
end_local

body

    if genType = AFE_CLK then
        talk cx to gpib address gpibAddr with "*SRE 0"
        talk cx to gpib address gpibAddr with srcPrefix [ genType , AUX_CLK ] +  "ROSC:SOUR EXT"
    else
        if genType = SMIQ_CLK then
            talk cx to gpib address gpibAddr with srcPrefix [ genType , AUX_CLK ] +  "POW:ALC:SEAR OFF"
            talk cx to gpib address gpibAddr with srcPrefix [ genType , AUX_CLK ] +  "DM:IQ:TRAN FAST"
        elseif genType = SMATE_CLK then
            talk cx to gpib address gpibAddr with srcPrefix [ genType , AUX_CLK ] +  "IQ:GAIN DB0"
            talk cx to gpib address gpibAddr with srcPrefix [ genType , AUX_CLK ] +  "IQ:IMP:STAT OFF"
            talk cx to gpib address gpibAddr with srcPrefix [ genType , AUX_CLK ] +  "IQ:SWAP OFF"
            talk cx to gpib address gpibAddr with srcPrefix [ genType , AUX_CLK ] +  "IQ:WBST ON"
            talk cx to gpib address gpibAddr with srcPrefix [ genType , AUX_CLK ] +  "IQ:CRES 0 "
            talk cx to gpib address gpibAddr with srcPrefix [ genType , AUX_CLK ] +  "IQ:SOUR ANAL"
        endif
        talk cx to gpib address gpibAddr with srcPrefix [ genType , AUX_CLK ] +  "ROSC:SOUR EXT"
        SetAuxiliaryClkIQ ( "on" )
        SetAuxiliaryClkIQ ( "off" )
   endif

   SetAuxiliaryClkLevel ( -60.0 dBm )
   SetAuxiliaryClkLevel ( -135.0 dBm )
   SetAuxiliaryClkFrequency ( 2.0GHz )
   SetAuxiliaryClkFrequency ( 1.0GHz )
   AuxClkAmplitude = -1000.0
   AuxClkFreq = 0.0

endbody
--------------------------------------------------------------------------------
procedure SetClk3Frequency ( inFreq )
--------------------------------------------------------------------------------
in double               : inFreq

local string [ 255 ]    : freqString

body

        if inFreq >= CLK3_MIN_FREQ and inFreq <= CLK3_MAX_FREQ then
            if  inFreq <> Clk3Freq then
                freqString = srcPrefix [ SMATE_CLK , AUX_CLK ] + gpibCmds [ SET_FREQ , SMATE_CLK ] + sprint ( inFreq:12:10!u=MHz )
                talk cx to gpib address CLK3_GPIB_ADDR with freqString
                Clk3Freq = inFreq
            endif    
        else
            println(stdout, "Programmed  value is "+sprint( inFreq )+" Hz.")
            println(stdout, "Minimum value for frequency is "+sprint(CLK3_MIN_FREQ)+" Hz.")
            println(stdout, "Maximum value for frequency is "+sprint(CLK3_MAX_FREQ)+" Hz.")
            println(stdout, "Halted from procedure 'SetClk3Frequency'")
            halt
        endif

endbody
--------------------------------------------------------------------------------
private procedure SetSMIQAuxClockFreq ( gpibAddr , freq )
--------------------------------------------------------------------------------
in word             : gpibAddr
in double           : freq

local string [ 32 ] : freqString

body

    if  freq <> AuxClkFreq then
        freqString = srcPrefix [ genType , AUX_CLK ] + gpibCmds [ SET_FREQ , genType ] + sprint ( freq:12:10!u=MHz )
        talk cx to gpib address gpibAddr with freqString
        AuxClkFreq = freq
    end_if
    
endbody
--------------------------------------------------------------------------------
private procedure SetSMIQAuxClockLevel ( gpibAddr , level )
--------------------------------------------------------------------------------
in word             : gpibAddr
in double           : level

local string [ 256 ] : levelString

body

    if level <> AuxClkAmplitude then
        levelString = srcPrefix [ genType , AUX_CLK ] + gpibCmds [ SET_LEVEL1 , genType ] + sprint ( level:4:1 ) + "; "
        talk cx to gpib address gpibAddr with levelString
        talk cx to gpib address gpibAddr with outPrefix [ genType , AUX_CLK ] + gpibCmds [ SET_LEVEL2 , genType ]
        AuxClkAmplitude = level
    end_if

endbody
--------------------------------------------------------------------------------
procedure InitAuxiliaryClk
--------------------------------------------------------------------------------

body

    initGPIBStrings
    if afe_config then
        aux_clk_min_level = AUX_CLK_MIN_LEVEL_SMA100 
        aux_clk_max_level = AUX_CLK_MAX_LEVEL_SMA100
    endif 

    LoadRFCalfactorArray ( "auxiliaryClkLevels" , auxClkCalAry )
    InitSMIQAuxClock ( AUX_CLK_GPIB_ADDR )

endbody
--------------------------------------------------------------------------------
procedure SetAuxiliaryClkLevel ( inLevel )
--------------------------------------------------------------------------------
in double           : inLevel   -- Level in dBm


body
    
    if inLevel >= aux_clk_min_level and inLevel <= aux_clk_max_level then
        SetSMIQAuxClockLevel ( AUX_CLK_GPIB_ADDR , inLevel )
    else
        println(stdout, "Programmed  value is "+sprint(inLevel)+" dBm.")
        println(stdout, "Minimum value for level is "+sprint(aux_clk_min_level)+" dBm.")
        println(stdout, "Maximum value for level is "+sprint(aux_clk_max_level)+" dBm.")
        println(stdout, "Halted from procedure 'SetAuxiliaryClkLevel'")
        halt
    endif

endbody
--------------------------------------------------------------------------------
procedure SetAuxiliaryClkIQ ( on_off )
--------------------------------------------------------------------------------
in string [ 10 ]        : on_off -- boolean expression  
                       
local string [ 200 ]    : gpib_command

body
    if on_off <> AuxModIq then
        if on_off = "on" then
            gpib_command = srcPrefix [ genType , AUX_CLK ] + gpibCmds [ SET_IQ1          , genType ] 
        elseif on_off = "off" then
            gpib_command = srcPrefix [ genType , AUX_CLK ] + gpibCmds [ SET_IQ2          , genType ] 
        else
            println(stdout, "Illegal parameter "+sprint(on_off)+".")
            println(stdout, "Argument to procedure 'SetAuxiliaryClkIQ' must be 'on' or 'off'")
            println(stdout, "Halted from procedure 'SetAuxiliaryClkIQ'")
        halt
        endif

        talk cx to gpib address AUX_CLK_GPIB_ADDR with gpib_command 
        AuxModIq = on_off
    endif 
    
    
endbody
--------------------------------------------------------------------------------
procedure SetAuxiliaryClkMod ( on_off )
--------------------------------------------------------------------------------
in string [ 10 ]            : on_off -- boolean expression  
                       
local string [ 200 ]        : gpib_command

body

    println(stdout,"ERROR : OBSOLETE ROUTINE : SetAuxiliaryClkMod")
    
endbody
--------------------------------------------------------------------------------
procedure SetAuxiliaryClkTableMode
-------------------------------------------------------------------------------

local integer               : i

body

    send cx gpib device clear to address AUX_CLK_GPIB_ADDR
    talk cx to gpib address AUX_CLK_GPIB_ADDR with srcPrefix [ genType , AUX_CLK ] + gpibCmds [ RESET_AND_CLEAR  , genType ]
    talk cx to gpib address AUX_CLK_GPIB_ADDR with srcPrefix [ genType , AUX_CLK ] + gpibCmds [ INIT_CLK_3       , genType ] 

    print(stdout,"SMIQ Table mode setup : aux_clk")
    talk cx to gpib address AUX_CLK_GPIB_ADDR with srcPrefix [ genType , AUX_CLK ] + gpibCmds [ SET_TABLE_MODE1  , genType ] 
    wait(1sec)  -- want >90 second total wait time
    for i = 1 to 20 do
	print(stdout," .")
	flush(stdout)
	wait(4.5sec)
    end_for
    println(stdout,"")
    
    talk cx to gpib address AUX_CLK_GPIB_ADDR with srcPrefix [ genType , AUX_CLK ] +  gpibCmds [ INIT_CLK_1       , genType ] 
    wait ( 50ms )
    talk cx to gpib address AUX_CLK_GPIB_ADDR with srcPrefix [ genType , AUX_CLK ] +  gpibCmds [ INIT_CLK_2       , genType ]
    wait ( 50ms )

endbody
--------------------------------------------------------------------------------
procedure SetSampleClkFrequencyOnly ( inFreq )
--------------------------------------------------------------------------------
in double           : inFreq

body

        if inFreq >= SAMPLE_CLK_MIN_FREQ and inFreq <= SAMPLE_CLK_MAX_FREQ then
            SetSMIQSampleClockFreq  ( sampClkGPIBAddr [ genType ] , inFreq )
        else
            println(stdout, "Programmed  value is "+sprint(inFreq)+" Hz.")
            println(stdout, "Minimum value for frequency is "+sprint(AUX_CLK_MIN_FREQ)+" Hz.")
            println(stdout, "Maximum value for frequency is "+sprint(AUX_CLK_MAX_FREQ)+" Hz.")
            println(stdout, "Halted from procedure 'SetAuxiliaryClkFrequency'")
            halt
        endif

endbody
--------------------------------------------------------------------------------
procedure SetSMIQSampleClockLevel ( gpibAddr , level )
--------------------------------------------------------------------------------
in word                 : gpibAddr
in double               : level

local string [ 256 ]    : levelString

body

if level <> SampleClkAmplitude then  
    levelString = srcPrefix [ genType , SMP_CLK ] + gpibCmds [ SET_LEVEL1 , genType ] + sprint ( level:4:1 )-- + "dBm" 
    talk cx to gpib address gpibAddr with levelString
    talk cx to gpib address gpibAddr with outPrefix [ genType , SMP_CLK ] + gpibCmds [ SET_LEVEL2 , genType ]
    SampleClkAmplitude = level
endif

endbody
--------------------------------------------------------------------------------
private procedure SetSMIQSampleClockFreq ( gpibAddr , freq )
--------------------------------------------------------------------------------
in word                 : gpibAddr
in double               : freq

local string [ 256 ]    : freqString

body

    if  freq <> SampleClkFreq then
        freqString = srcPrefix [ genType , SMP_CLK ] + gpibCmds [ SET_FREQ , genType ] + sprint ( freq:12:10!u=MHz )
        talk cx to gpib address gpibAddr with freqString
        SampleClkFreq = freq
    endif    
    
endbody
--------------------------------------------------------------------------------
procedure SetSampleClkFrequency ( inFreq )
--------------------------------------------------------------------------------
in double       : inFreq
body

if inFreq >= SAMPLE_CLK_MIN_FREQ and inFreq <= SAMPLE_CLK_MAX_FREQ then
    SetSMIQSampleClockFreq  ( sampClkGPIBAddr [ genType ] , inFreq )
    SetSMIQSampleClockLevel ( sampClkGPIBAddr [ genType ] , SAMPLE_CLK_LEVEL )
else
    println(stdout, "Programmed  value is "+sprint(inFreq)+" Hz.")
    println(stdout, "Minimum value for frequency is "+sprint(SAMPLE_CLK_MIN_FREQ)+" Hz.")
    println(stdout, "Maximum value for frequency is "+sprint(SAMPLE_CLK_MAX_FREQ)+" Hz.")
    println(stdout, "Halted from procedure 'SetSampleClkFrequency'")
    halt
endif

endbody
--------------------------------------------------------------------------------
procedure SetSampleClkLevel ( inLevel )
--------------------------------------------------------------------------------
in double           : inLevel   -- Level in dBm


body
    
    if inLevel >= sample_clk_min_level and inLevel <= sample_clk_max_level then
        SetSMIQSampleClockLevel ( sampClkGPIBAddr [ genType ] , inLevel )
    else
        println(stdout, "Programmed  value is "+sprint(inLevel)+" dBm.")
        println(stdout, "Minimum value for level is "+sprint(aux_clk_min_level)+" dBm.")
        println(stdout, "Maximum value for level is "+sprint(aux_clk_max_level)+" dBm.")
        println(stdout, "Halted from procedure 'SetAuxiliaryClkLevel'")
        halt
    endif

endbody
--------------------------------------------------------------------------------
private procedure InitSMIQSampleClock ( gpibAddr )
--------------------------------------------------------------------------------
in word                 : gpibAddr


local float             : amplitude

body


    if  genType = AFE_CLK then
        talk cx to gpib address gpibAddr with "*RST;*CLS" 
        talk cx to gpib address gpibAddr with "*SRE 0"
    elseif  genType = SMIQ_CLK then
        talk cx to gpib address gpibAddr with "*RST;*CLS" 
        talk cx to gpib address gpibAddr with srcPrefix [ genType , SMP_CLK ] + "DM:IQ:STAT OFF"
    elseif genType = SMATE_CLK then
        talk cx to gpib address gpibAddr with srcPrefix [ genType , SMP_CLK ] + "IQ:GAIN DB0"
        talk cx to gpib address gpibAddr with srcPrefix [ genType , SMP_CLK ] + "IQ:IMP:STAT OFF"
        talk cx to gpib address gpibAddr with srcPrefix [ genType , SMP_CLK ] + "IQ:SWAP OFF"
        talk cx to gpib address gpibAddr with srcPrefix [ genType , SMP_CLK ] + "IQ:WBST ON"
        talk cx to gpib address gpibAddr with srcPrefix [ genType , SMP_CLK ] + "IQ:CRES 0 "
        talk cx to gpib address gpibAddr with srcPrefix [ genType , SMP_CLK ] + "IQ:SOUR ANAL"
        talk cx to gpib address gpibAddr with srcPrefix [ genType , SMP_CLK ] + "IQ:STAT OFF"
    endif                                                                       
    talk cx to gpib address gpibAddr with   "ROSC:SOUR EXT" 
    SampleClkFreq = 0.0
    SampleClkAmplitude = -200.0 dBm
    SetSampleClkFrequency (  1.0GHz  )
    SetSampleClkLevel     ( -135.0dBm )
       
endbody
--------------------------------------------------------------------------------
procedure InitSampleClk
--------------------------------------------------------------------------------

body

    initGPIBStrings
    if afe_config then
        sample_clk_min_level = SAMPLE_CLK_MIN_LEVEL_SMA100 
        sample_clk_max_level = SAMPLE_CLK_MAX_LEVEL_SMA100
    endif

    LoadRFCalfactorArray ( "sampleClkLevel" , smpClkCalAry )
    InitSMIQSampleClock ( sampClkGPIBAddr [ genType ] )

endbody
--------------------------------------------------------------------------------
procedure SetSampleClkQuiet(inFreq)
--------------------------------------------------------------------------------
in double       : inFreq


body

    if inFreq >= SAMPLE_CLK_MIN_FREQ and inFreq <= SAMPLE_CLK_MAX_FREQ then
        SetSMIQSampleClockFreq  ( sampClkGPIBAddr [ genType ] , inFreq )
        SetSMIQSampleClockLevel ( sampClkGPIBAddr [ genType ] , -100dBm )
    else
        println(stdout, "Programmed  value is "+sprint(inFreq)+" Hz.")
        println(stdout, "Minimum value for frequency is "+sprint(SAMPLE_CLK_MIN_FREQ)+" Hz.")
        println(stdout, "Maximum value for frequency is "+sprint(SAMPLE_CLK_MAX_FREQ)+" Hz.")
        println(stdout, "Halted from procedure 'SetSampleClkFrequency'")
        halt
    endif

endbody
--------------------------------------------------------------------------------
private procedure IdentSMIQAuxClock ( gpibAddr )
--------------------------------------------------------------------------------
in word                 : gpibAddr
local
  string[43] :  IdentStr
end_local

body

    talk cx to gpib address gpibAddr with "*IDN?"
    listen cx to gpib adr gpibAddr into IdentStr for 43 bytes
    println(stdout,"GPIB ADDR :",gpibAddr)
    println(stdout,IdentStr)

endbody

--------------------------------------------------------------------------------
private procedure SetSMIQGpibAddr ( oldGpibAddr ,  newGpibAddr )
--------------------------------------------------------------------------------
in word             : oldGpibAddr
in word             : newGpibAddr

local string [ 32 ] : adrString

body

    adrString = "SYST:COMM:GPIB:ADDR "+sprint(newGpibAddr:1)
    talk cx to gpib address oldGpibAddr with adrString
    
endbody
--------------------------------------------------------------------------------
procedure ClearURV5PowerMeter
--------------------------------------------------------------------------------
--  Send a GPIB clear to the URV5 power meter.


local string[ 255 ]:  gpib_string


body
    
    gpib_string = ""
    send cx gpib device clear to adr URV5_GPIB_ADDRESS
    wait (300ms)
    initialize cx gpib device at address URV5_GPIB_ADDRESS with eos 0x14 10
--    cx gpib remote enable on
--    set cx gpib timeout to 10s  -- allow enough time for all types of URV5 commands to complete
                             -- without the GPIB timining out 

    gpib_string = "C0,C1" + chr (13)  -- initiate readback of sensor calfactors by URV5 meter
    talk cx to gpib adr URV5_GPIB_ADDRESS with gpib_string --end  -- meter should display 'init'

endbody 
--------------------------------------------------------------------------------
function InventoryNrv5PowerProbe : word list [ 1 ]
--------------------------------------------------------------------------------
 
local word                      : i 
local string[1]                 : head_string 
local string[GPIB_LENGTH]       : gpib_string
local string[GPIB_LENGTH]       : response_string
local word list[1]              : nrv5_list 
                                  
 
body

    -- URV5 must be on the User Gpib Bus ( not the System GPIB Bus )
    -- The gpib driver must be loaded.
    --
    -- URV5 slot A corresponds to test head 1
    -- URV5 slot B corresponds to test head 2

    head_string = chr ( asc  ("A" ) + head_number - 1 )
    gpib_string = "P" + head_string + ",S4" + chr ( 13 ) + chr ( 10 )

    talk cx to gpib adr URV5_GPIB_ADDRESS with gpib_string --end

    if not tester_simulated then
        listen cx to gpib adr URV5_GPIB_ADDRESS into response_string for 20 bytes
        if not pos ( "NO PROBE", response_string ) <> 0 then  -- Fix SPR LTXun11207
            nrv5_list = <: 1 :>
        endif
    endif

    return ( nrv5_list ) 

endbody
--------------------------------------------------------------------------------
procedure Zero_source_power_meter
--------------------------------------------------------------------------------

--  Initiate a self-adjust of the reference (a.k.a electrical zero) of
--  the URV5/NRV5 power meter setup. 
--
--  This adjustment should improve the measuring accuracy, provided the
--  following steps are observed:
--
--  1) Allow the basic unit and probes to warm up (30 min. at least).
--  2) Make sure no voltage is present at the probes (terminate them).
--  3) Do not zero right after a high power measurement (capacitor settling).
--  4) Do not move the cables of the probes (not to induce low voltages in cables).

body

    println ( stdhdr, "power meter zero" )

    gpib cx talk to adr URV5_GPIB_ADDRESS with "O1" + chr( 13 ) end

    if not tester_simulated then
        wait (POWER_METER_DELAY)
    endif

endbody 
--------------------------------------------------------------------------------
function InventoryURV5PowerMeter: word list[1]
-------------------------------------------------
--  Return <:1:> is a URV5 power meter is present on the
--  User GPIB bus, else return <::>.

 
local string [ GPIB_LENGTH ]            : response_string
local word list [ 1 ]                   :  urv5_list
 
body

    -- URV5 must be on the User Gpib Bus (not the System GPIB Bus)
    -- The gpib driver must be loaded.

--    gpib cx device clear adr URV5_GPIB_ADDRESS
    wait ( 300.0ms )

    listen cx to gpib adr URV5_GPIB_ADDRESS into response_string for 20 bytes

    if pos ( "URV5" , response_string ) <> 0 then
        urv5_list = <: 1 :>
    endif

    return ( urv5_list ) 

endbody

procedure TestURV5PowerMeter
--------------------------------------------------------------------------------
--  Read the internal error status of the URV5 power meter. A code
--  of 0000H means all self-tests passed. A non-zero code indicates
--  one or more errors.

local string [ GPIB_LENGTH ]            :  gpib_string     
local string [ GPIB_LENGTH ]            :  response_string 
                                                           
body

    gpib_string = "P" + chr ( asc ( "A" ) + head_number - 1 ) + ",S5" + chr ( 13 )
    talk cx to gpib adr URV5_GPIB_ADDRESS with gpib_string --end

    if not tester_simulated then
        listen cx to gpib adr URV5_GPIB_ADDRESS into response_string for 13 bytes
        if not pos ( "ERRCODE 0000H", response_string ) <> 0 then
            if response_string = "" then
                response_string = "NO RESPONSE"
            endif
            print   ( stdout , "@nERROR urv5_control.mod/Test_source_power_meter: Power meter self-test failed " )
            println  (stdout , "(" + response_string + ") !!!")
            halt
        endif
    endif

endbody 
--------------------------------------------------------------------------------
function SelectOptimumURV5PowerMeterMode ( minimum_level ) : word
--------------------------------------------------------------------------------
--  Select the optimal URV5 meter's measurement mode (1 - 5)
--  as a function of the minimum expected signal level.

in float:  minimum_level  -- minimum expected signal level (in volts).

const MINIMUM_LEVEL_F4          = 12.6mV  -- F4 mode
const MINIMUM_LEVEL_F3          =  8.9mV  -- F3
const MINIMUM_LEVEL_F2          =  6.3mV  -- F2
      
local word                      : power_meter_mode = 0  -- power meter mode F{1 - 5]

body

    power_meter_mode = 0
    if minimum_level >= MINIMUM_LEVEL_F4 then
        power_meter_mode = 4
    elseif minimum_level >= MINIMUM_LEVEL_F3 then
        power_meter_mode = 3
    else
        power_meter_mode = 2
    endif

    return (power_meter_mode)

endbody
--------------------------------------------------------------------------------
function SelectOptimumURV5PowerMeterDelay ( meter_mode ) : float
--------------------------------------------------------------------------------
--

in word:  meter_mode

static float:  meter_delays[5]

body

   if meter_delays[1] == 0.0 then   
       meter_delays[1] = 4000.0ms  -- recommended delay after an F1-mode measurement
       meter_delays[2] =  950.0ms  --                            F2
       meter_delays[3] =  270.0ms  --                            F3
       meter_delays[4] =   80.0ms  --                            F4
       meter_delays[5] =   35.0ms  --                            F5
   endif

   return ( meter_delays [ meter_mode ] )

endbody
--------------------------------------------------------------------------------
function SelectOptimumURV5PowerMeterModeDBm (minimum_dbmlevel): word
--------------------------------------------------------------------------------
--  Select the optimal URV5 meter's measurement mode (1 - 5)
--  as a function of the minimum expected signal level.

in float:  minimum_dbmlevel  -- minimum expected signal level (in dBm).

const MINIMUM_LEVEL_F4          =  -25dBm  -- F4 mode
const MINIMUM_LEVEL_F3          =  -28dBm  -- F3
const MINIMUM_LEVEL_F2          =  -31dBm  -- F2

local word                      : power_meter_mode = 0  -- power meter mode F{1 - 5]

body

    if minimum_dbmlevel >= MINIMUM_LEVEL_F4 then
        power_meter_mode = 4
    elseif minimum_dbmlevel >= MINIMUM_LEVEL_F3 then
        power_meter_mode = 3
    else
        power_meter_mode = 2
    endif

    return (power_meter_mode)

endbody
--------------------------------------------------------------------------------
function MeasureURV5InputLevelInDBm ( frequency , minimum_dbmlevel ) : float
--------------------------------------------------------------------------------
--  Measure broadband power with the URV5 meter through the NRV5-Z2
--  power sensor. Make an educated guess to select the power meter's speed
--  mode, and make a second pass measuremnt if the first pass used the wrong
--  mode.
--
--  GPIB legend:
--
--     PA:  Probe A
--     IA:  Input for channel A valid
--     F1:  slow measurement speed (4 1/2 digit display, 4000ms acquisition time)
--     F2:  slow measurement speed (4 1/2 digit display, 1000ms acquisition time)
--     F3:  slow measurement speed (4 1/2 digit display,  260ms acquisition time)
--     F4:  fast measurement mode (4 1/2 digit display,   80ms acquisition time)
--     KF1: Frequency correction on
--     DF:  Correction frequency in Hz
--     X1:  Trigger command
--     N1:  Output without alpha header
--     U1:  Output units are dBm.

in  double                      :  frequency         -- frequency at which the power level is to be measured 
in  float                       :  minimum_dbmlevel  -- expected signal level (in dBm).



local word                      :  meter_mode        
local word                      :  optimal_meter_mode
local word                      :  iteration         
local string[GPIB_LENGTH]       :  prefix_string     
local string[GPIB_LENGTH]       :  suffix_string     
local string[GPIB_LENGTH]       :  gpib_string       
local string[GPIB_LENGTH]       :  response_string   
local float                     :  meter_delay       
local float                     :  measured_dbmlevel 
                                                     

body

    -- Note:  Using slot A of the URV5 meter for head 1, and slot B for head 2:
    --
    if head_number == 2 then
        prefix_string = "PB,IB,F"
    else
        prefix_string = "PA,IA,F"
    endif

    if enable_urv5_optimization then
        meter_mode = SelectOptimumURV5PowerMeterModeDBm (minimum_dbmlevel)  -- enable optimization of meter modes
    else
        meter_mode = 2  -- do not optimize; always use F2 mode (slowest)
    endif

    suffix_string = ",KF1,DF" + sprint (frequency!f:1:0) + ",X1,N1,U1"

    for iteration = 1 to 2 do

        gpib_string = prefix_string + sprint (meter_mode!d:1) + suffix_string
        talk cx to gpib adr URV5_GPIB_ADDRESS with gpib_string --end

        meter_delay = SelectOptimumURV5PowerMeterDelay ( meter_mode )
        wait (meter_delay)

        if not tester_simulated then
            listen cx to gpib adr URV5_GPIB_ADDRESS into response_string for 20 bytes
            
            -- LTXun26099  P. Cevasco 2003-03-12
            -- The response_string from the URV5 is blank if a timeout has occurred.  Previously,
            -- the response_string was fed into "sinput" measured_dbmlevel without being checked.
            -- This caused measured_dbmlevel to be set to 0.0 (which is a valid measured value)
            -- and this error was never picked up by the cal.
            --
            -- The URV5 returns a blank string if there is a GPIB timeout
            if ( response_string == "" ) then
                
                -- Try to clear the URV5 and the GPIB bus and make another measurement
                --
                ClearURV5PowerMeter
                gpib_timeout_count = gpib_timeout_count + 1

                talk to gpib adr URV5_GPIB_ADDRESS with gpib_string end
                wait (meter_delay)
                
                listen cx to gpib adr URV5_GPIB_ADDRESS into response_string for 12 bytes

                -- If we are still timedout, halt the cal
                if ( response_string == "" ) then
                    println (stdout, "Unrecoverable GPIB Timeout")
                    halt
                else
                    sinput (response_string, measured_dbmlevel)
                end_if
                
            else
                sinput (response_string, measured_dbmlevel)
            end_if 
                   
        else
            measured_dbmlevel = minimum_dbmlevel
        endif

        optimal_meter_mode = SelectOptimumURV5PowerMeterModeDBm ( measured_dbmlevel )

        if meter_mode <= optimal_meter_mode then
            break  -- skip the second iteration if the meter mode was lower-numbered (i.e. slower) or equal in the first iteration
        else
            meter_mode = optimal_meter_mode  -- allow second iteration; this time in the correct mode !
        endif

    endfor

    return ( measured_dbmlevel )

endbody
--------------------------------------------------------------------------------
function MeasureURV5InputLevel ( frequency , minimum_level ): float
-------------------------------------------------------------------------
--  Measure broadband power with the URV5 meter through the NRV5-Z2
--  power sensor. Make an educated guess to select the power meter's speed
--  mode, and make a second pass measuremnt if the first pass used the wrong
--  mode.
--
--  GPIB legend:
--
--     PA:  Probe A
--     IA:  Input for channel A valid
--     F1:  slow measurement speed (4 1/2 digit display, 4000ms acquisition time)
--     F2:  slow measurement speed (4 1/2 digit display, 1000ms acquisition time)
--     F3:  slow measurement speed (4 1/2 digit display,  260ms acquisition time)
--     F4:  fast measurement mode (4 1/2 digit display,   80ms acquisition time)
--     KF1: Frequency correction on
--     DF:  Correction frequency in Hz
--     X1:  Trigger command
--     N1:  Output without alpha header
--     U0:  Output units are V.

in  double                      :  frequency      -- frequency at which the power level is to be measured 
in   float                      :  minimum_level  -- expected signal level (in volts).



local word                      :  meter_mode        
local word                      :  optimal_meter_mode
local word                      :  iteration         
local string [ GPIB_LENGTH ]    :  prefix_string     
local string [ GPIB_LENGTH ]    :  suffix_string     
local string [ GPIB_LENGTH ]    :  gpib_string       
local string [ GPIB_LENGTH ]    :  response_string   
local float                     :  meter_delay       
local float                     :  measured_level    
                                                     

body

    -- Note:  Using slot A of the URV5 meter for head 1, and slot B for head 2:
    --
    if head_number == 2 then
        prefix_string = "PB,IB,F"
    else
        prefix_string = "PA,IA,F"
    endif

    if enable_urv5_optimization then
        meter_mode = SelectOptimumURV5PowerMeterMode (minimum_level)  -- enable optimization of meter modes
    else
        meter_mode = 2  -- do not optimize; always use F2 mode (slowest)
    endif

    suffix_string = ",KF1,DF" + sprint (frequency!f:1:0) + ",X1,N1,U0"

    for iteration = 1 to 2 do

        gpib_string = prefix_string + sprint (meter_mode!d:1) + suffix_string
        talk cx to gpib adr URV5_GPIB_ADDRESS with gpib_string + chr ( 13 )

        meter_delay = SelectOptimumURV5PowerMeterDelay (meter_mode)
        wait (meter_delay)

        if not tester_simulated then
            listen cx to gpib adr URV5_GPIB_ADDRESS into response_string for 20 bytes
            sinput (response_string, measured_level)
        else
            measured_level = minimum_level
        endif

        optimal_meter_mode = SelectOptimumURV5PowerMeterMode (measured_level)

        if meter_mode <= optimal_meter_mode then
            break  -- skip the second iteration if the meter mode was lower-numbered (i.e. slower) or equal in the first iteration
        else
            meter_mode = optimal_meter_mode  -- allow second iteration; this time in the correct mode !
        endif

    endfor

    if measured_level < 0.0 then
        measured_level = 1nV  -- covert all negative values to 1nV to prevent
    endif                     -- math errors in routines expecting a positive value

    return ( measured_level )

endbody

procedure SetAuxiliaryClkCalibrated ( frequency , amplitude_dBm )
------------------------------------------------------------------------------------
in double               : frequency
in double               : amplitude_dBm

local integer           : calIndex
local integer           : i
local double            : y
local double            : x
local double            : inLevel

body

    SetAuxiliaryClkFrequency ( frequency )
    calIndex = integer ( double ( CAL_RF_FREQ_SZ ) * frequency / AUX_CLK_MAX_FREQ )
    
    if calIndex < CAL_RF_FREQ_SZ - 3 then
        i = calIndex - 1
    else
        i = CAL_RF_FREQ_SZ - 3
    endif
    
    if i < 1 then 
        i = 1 
    endif
    
    x = frequency * double ( CAL_RF_FREQ_SZ ) / AUX_CLK_MAX_FREQ - double ( i - 1 )
    y = CubicSpline ( auxClkCalAry [ i : i + 3 ] , x )

    inLevel = amplitude_dBm + ( RF_CAL_REFERENCE_LEVEL - y )
    if inLevel >= aux_clk_min_level and inLevel <= aux_clk_max_level + 7.0 then
        SetSMIQAuxClockLevel ( AUX_CLK_GPIB_ADDR , inLevel )
    else
        println(stdout, "Programmed  value is "+sprint(inLevel)+" dBm.")
        println(stdout, "Minimum value for level is "+sprint(aux_clk_min_level)+" dBm.")
        println(stdout, "Maximum value for level is "+sprint(aux_clk_max_level)+" dBm.")
        println(stdout, "Halted from procedure 'clkCtrl.mod/SetAuxiliaryClkCalibrated'")
        halt
    endif

endbody
------------------------------------------------------------------------------------
function CubicSpline ( yAry , x ) : double
--------------------------------------------------------------------------------
in double               : yAry [ ? ]
in double               : x

local integer           : length
local integer           : offset
local integer           : increment
local double            : z [ 4 ]
local double            : y

local integer           : i


body

    if dimsize ( yAry , 1 ) = 4 then
        length = 4
        PolynomialRegression ( yAry , 1 , 1 , length , z )
        y = z [ 1 ] + z [ 2 ] * x + z [ 3 ] * x * x + z [ 4 ] * x * x * x
        return ( y )
    endif
    
endbody
--------------------------------------------------------------------------------
procedure PolynomialRegression ( inAry , offset , increment , length , outAry )
--------------------------------------------------------------------------------
--  
in_out double           : inAry [ ? ]
in integer              : offset
in integer              : increment
in integer              : length
in_out double           : outAry [ ? ]

const SIZE              = 4

local integer           : level                 
local integer           : i                     
local integer           : i2
local integer           : j                     
local integer           : k                     
local integer           : l                     
local double            : x1 [ SIZE ]                 
local integer           : n                     
local double            : y [ SIZE ]                  
local double            : x [ SIZE , SIZE ]                
local double            : y1                    
local double            : x0                    
local double            : x0_array[17] 
local double            : xx0                   
local double            : source_volts          
local double            : output[17]
local integer           : w
local integer           : order


body

   order  = dimsize ( outAry , 1 )
       
   x = 0.0
   x1 = 0.0
   y = 0.0
   for l = 1 to length do
       x0= double ( ( l - 1 ) * increment + offset )
       y1 = double ( inAry [ ( l - 1 ) * increment + offset ] )
       x1 [ 1 ] = 1.0
       for i = 2 to order do
           x1 [ i ] = x0 * x1 [ i - 1 ]
       endfor
       y = y + ( x1 * y1 )
       for i= 1 to order do
           for j= 1 to order do
               x[i,j]=x[i,j]+x1[i]*x1[j]
           endfor
       endfor
   endfor
   for i=1 to order do
       j=i
       y[i]=y[i]/x[i,j] 
       x[i]=x[i]/x[i,j]                               
       for i2=1 to order do
           if i2<>i then
              y[i2]=y[i2]-y[i]*x[i2,j]
              x[i2]=x[i2]-x[i]*x[i2,j]
           endif
       endfor
   endfor
   j=k
   outAry = double ( y [ 1 : order ] )


endbody
--------------------------------------------------------------------------------

procedure SetClk3Calibrated ( frequency , amplitude_dBm )
------------------------------------------------------------------------------------
in double               : frequency
in double               : amplitude_dBm

local integer           : calIndex
local integer           : i
local double            : y
local double            : x
local double            : inLevel

body

    SetClk3Frequency ( frequency )
    calIndex = integer ( double ( CAL_RF_FREQ_SZ ) * frequency / CLK3_MAX_FREQ )
    
    if calIndex < CAL_RF_FREQ_SZ - 3 then
        i = calIndex - 1
    else
        i = CAL_RF_FREQ_SZ - 3
    endif
    
    if i < 1 then 
        i = 1 
    endif
    
    x = frequency * double ( CAL_RF_FREQ_SZ ) / CLK3_MAX_FREQ - double ( i - 1 )
    y = CubicSpline ( clk3CalAry [ i : i + 3 ] , x )

    inLevel = amplitude_dBm + ( RF_CAL_REFERENCE_LEVEL - y )
    if inLevel >= clk3_min_level and inLevel <= clk3_max_level + 7.0 then
        SetClk3Level ( inLevel )
    else
        println(stdout, "Programmed  value is "+sprint(inLevel)+" dBm.")
        println(stdout, "Minimum value for level is "+sprint(clk3_min_level)+" dBm.")
        println(stdout, "Maximum value for level is "+sprint(clk3_max_level)+" dBm.")
        println(stdout, "Halted from procedure 'clkCtrl.mod/SetClk3Calibrated'")
        halt
    endif

endbody
------------------------------------------------------------------------------------
procedure SetClk4Calibrated ( frequency , amplitude_dBm )
------------------------------------------------------------------------------------
in double               : frequency
in double               : amplitude_dBm

local integer           : calIndex
local integer           : i
local double            : y
local double            : x
local double            : inLevel

body

    SetClk4Frequency ( frequency )
    calIndex = integer ( double ( CAL_RF_FREQ_SZ ) * frequency / CLK4_MAX_FREQ )
    
    if calIndex < CAL_RF_FREQ_SZ - 3 then
        i = calIndex - 1
    else
        i = CAL_RF_FREQ_SZ - 3
    endif
    
    if i < 1 then 
        i = 1 
    endif
    
    x = frequency * double ( CAL_RF_FREQ_SZ ) / CLK4_MAX_FREQ - double ( i - 1 )
    y = CubicSpline ( clk4CalAry [ i : i + 3 ] , x )

    inLevel = amplitude_dBm + ( RF_CAL_REFERENCE_LEVEL - y )
    if inLevel >= clk4_min_level and inLevel <= clk4_max_level + 7.0 then
        SetClk4Level ( inLevel )
    else
        println( stdout , "Programmed  value is "+sprint ( inLevel ) +" dBm." )
        println( stdout , "Minimum value for level is "+sprint(clk4_min_level)+" dBm." )
        println( stdout , "Maximum value for level is "+sprint(clk4_max_level)+" dBm." )
        println( stdout , "Halted from procedure 'clkCtrl.mod/SetClk4Calibrated'" )
        halt
    endif

endbody
------------------------------------------------------------------------------------
procedure SetClk4Frequency ( inFreq )
--------------------------------------------------------------------------------
in double               : inFreq

local string [ 255 ]    : freqString

body

        if inFreq >= CLK4_MIN_FREQ and inFreq <= CLK4_MAX_FREQ then
            if  inFreq <> Clk4Freq then
                freqString = srcPrefix [ SMATE_CLK , SMP_CLK ] + gpibCmds [ SET_FREQ , SMATE_CLK ] + sprint ( inFreq:12:10!u=MHz )
                talk cx to gpib address CLK4_GPIB_ADDR with freqString
                Clk4Freq = inFreq
            endif    
        else
            println(stdout, "Programmed  value is "+sprint(inFreq)+" Hz.")
            println(stdout, "Minimum value for frequency is "+sprint(CLK4_MIN_FREQ)+" Hz.")
            println(stdout, "Maximum value for frequency is "+sprint(CLK4_MAX_FREQ)+" Hz.")
            println(stdout, "Halted from procedure 'SetClk4Frequency'")
            halt
        endif

endbody
--------------------------------------------------------------------------------
procedure SetClk3Level ( inLevel )
--------------------------------------------------------------------------------
in double               : inLevel   -- Level in dBm

local string [ 256 ]    : levelString


body
    
    if inLevel >= clk3_min_level and inLevel <= clk3_max_level then
        if inLevel <> Clk3Amplitude then
            levelString = srcPrefix [ SMATE_CLK , AUX_CLK ] + gpibCmds [ SET_LEVEL1 , SMATE_CLK ] + sprint ( inLevel:4:1 ) + "; "
            talk cx to gpib address CLK3_GPIB_ADDR with levelString
            talk cx to gpib address CLK3_GPIB_ADDR with outPrefix [ SMATE_CLK , AUX_CLK ] + gpibCmds [ SET_LEVEL2 , SMATE_CLK ]
            Clk3Amplitude = inLevel
        endif
    else
        println(stdout, "Programmed  value is "+sprint(inLevel)+" dBm.")
        println(stdout, "Minimum value for level is "+sprint(clk3_min_level)+" dBm.")
        println(stdout, "Maximum value for level is "+sprint(clk3_max_level)+" dBm.")
        println(stdout, "Halted from procedure 'SetClk3Level'")
        halt
    endif

endbody
--------------------------------------------------------------------------------
procedure SetClk4Level ( inLevel )
--------------------------------------------------------------------------------
in double               : inLevel   -- Level in dBm

local string [ 256 ]    : levelString

body

    if inLevel >= clk4_min_level and inLevel <= clk4_max_level + 7.0 then
        if inLevel <> Clk4Amplitude then
            levelString = srcPrefix [ SMATE_CLK , SMP_CLK ] + gpibCmds [ SET_LEVEL1 , SMATE_CLK ] + sprint ( inLevel:4:1 ) + "; "
            talk cx to gpib address CLK4_GPIB_ADDR with levelString
            talk cx to gpib address CLK4_GPIB_ADDR with outPrefix [ SMATE_CLK , SMP_CLK ] + gpibCmds [ SET_LEVEL2 , SMATE_CLK ]
            Clk4Amplitude = inLevel
        endif
    else
        println(stdout, "Programmed  value is "+sprint(inLevel)+" dBm.")
        println(stdout, "Minimum value for level is "+sprint(clk4_min_level)+" dBm.")
        println(stdout, "Maximum value for level is "+sprint(clk4_max_level)+" dBm.")
        println(stdout, "Halted from procedure 'SetClk4Level'")
        halt
    endif

endbody
--------------------------------------------------------------------------------
procedure SetClk3IQ ( on_off )
--------------------------------------------------------------------------------
in string [ 10 ]        : on_off -- boolean expression  
                       
local string [ 200 ]    : gpib_command

body

    if on_off <> Clk3ModIq then
        if on_off = "on" then
            gpib_command = srcPrefix [ SMATE_CLK , AUX_CLK ] + gpibCmds [ SET_IQ1 , genType ] 
        elseif on_off = "off" then                                               
            gpib_command = srcPrefix [ SMATE_CLK , AUX_CLK ] + gpibCmds [ SET_IQ2 , genType ] 
        else                                                                     
            println(stdout, "Illegal parameter "+sprint(on_off)+".")
            println(stdout, "Argument to procedure 'SetClk3IQ' must be 'on' or 'off'")
            println(stdout, "Halted from procedure 'clkCtrl.mod/SetClk3IQ'")
        halt
        endif

        talk cx to gpib address CLK3_GPIB_ADDR with gpib_command 
        Clk3ModIq = on_off
    endif 
    
endbody
--------------------------------------------------------------------------------
procedure SetClk4IQ ( on_off )
--------------------------------------------------------------------------------
in string [ 10 ]        : on_off -- boolean expression  
                       
local string [ 200 ]    : gpib_command

body

    if on_off <> Clk4ModIq then
        if on_off = "on" then
            gpib_command = srcPrefix [ SMATE_CLK , SMP_CLK ] + gpibCmds [ SET_IQ1 , genType ] 
        elseif on_off = "off" then                                                 
            gpib_command = srcPrefix [ SMATE_CLK , SMP_CLK ] + gpibCmds [ SET_IQ2 , genType ] 
        else                                                                       
            println(stdout, "Illegal parameter "+sprint(on_off)+".")
            println(stdout, "Argument to procedure 'SetClk4IQ' must be 'on' or 'off'")
            println(stdout, "Halted from procedure 'clkCtrl.mod/SetClk4IQ'")
        halt
        endif

        talk cx to gpib address CLK4_GPIB_ADDR with gpib_command 
        Clk4ModIq = on_off
    endif 
    
endbody
--------------------------------------------------------------------------------
procedure SetAuxiliaryClkFrequency ( inFreq )
--------------------------------------------------------------------------------
in double           : inFreq

body

        if inFreq >= AUX_CLK_MIN_FREQ and inFreq <= AUX_CLK_MAX_FREQ then
            SetSMIQAuxClockFreq  ( AUX_CLK_GPIB_ADDR , inFreq )
        else
            println(stdout, "Programmed  value is "+sprint(inFreq)+" Hz.")
            println(stdout, "Minimum value for frequency is "+sprint(AUX_CLK_MIN_FREQ)+" Hz.")
            println(stdout, "Maximum value for frequency is "+sprint(AUX_CLK_MAX_FREQ)+" Hz.")
            println(stdout, "Halted from procedure 'SetAuxiliaryClkFrequency'")
            halt
        endif

endbody
--------------------------------------------------------------------------------

procedure InitClk3
--------------------------------------------------------------------------------
local word              : gpibAddr
local word              : genType
local string [ 255 ]    : identStr

body

    if smateExists then
        talk cx to gpib address CLK3_GPIB_ADDR with "*RST;*CLS"
        talk cx to gpib address CLK3_GPIB_ADDR with "*IDN?"
        listen cx to gpib adr CLK3_GPIB_ADDR into identStr for 80 bytes
    
        if pos ( "SMATE"  , identStr ) = 0 then
            gen3Installed = false
            return
        endif
        
        LoadRFCalfactorArray ( "Clk3Level" , clk3CalAry )
      
        gen3Installed = true
        
        genType = SMATE_CLK
        gpibAddr = CLK3_GPIB_ADDR
        talk cx to gpib address gpibAddr with srcPrefix [ genType , AUX_CLK ] + "IQ:GAIN DB0"
        talk cx to gpib address gpibAddr with srcPrefix [ genType , AUX_CLK ] + "IQ:IMP:STAT OFF"
        talk cx to gpib address gpibAddr with srcPrefix [ genType , AUX_CLK ] + "IQ:SWAP OFF"
        talk cx to gpib address gpibAddr with srcPrefix [ genType , AUX_CLK ] + "IQ:WBST ON"
        talk cx to gpib address gpibAddr with srcPrefix [ genType , AUX_CLK ] + "IQ:CRES 0 "
        talk cx to gpib address gpibAddr with srcPrefix [ genType , AUX_CLK ] + "IQ:SOUR ANAL"
        talk cx to gpib address gpibAddr with srcPrefix [ genType , AUX_CLK ] + "IQ:STAT OFF"
        talk cx to gpib address gpibAddr with srcPrefix [ genType , SMP_CLK ] + "POW:ALC:STAT ON"
        talk cx to gpib address gpibAddr with srcPrefix [ genType , AUX_CLK ] + "ROSC:SOUR EXT"
        Clk3Freq = 0.0
        Clk3Amplitude = -120.0 dBm
        SetClk3Frequency (  1.0GHz  )
        SetClk3Level     ( -80.0dBm )
    endif
    
endbody
--------------------------------------------------------------------------------
procedure InitClk4
--------------------------------------------------------------------------------
local word              : gpibAddr
local word              : genType
local string [ 255 ]    : identStr

body

    if smateExists then
        talk cx to gpib address CLK4_GPIB_ADDR with "*RST;*CLS"
        talk cx to gpib address CLK4_GPIB_ADDR with "*IDN?"
    
        listen cx to gpib adr CLK4_GPIB_ADDR into identStr for 80 bytes
        if pos ( "SMATE"  , identStr ) = 0 then
            gen4Installed = false
            return
        endif
    
        LoadRFCalfactorArray ( "Clk4Level" , clk4CalAry )
    
        gen4Installed = true
        
        genType = SMATE_CLK
        gpibAddr = CLK4_GPIB_ADDR
        talk cx to gpib address gpibAddr with srcPrefix [ genType , SMP_CLK ] + "IQ:GAIN DB0"
        talk cx to gpib address gpibAddr with srcPrefix [ genType , SMP_CLK ] + "IQ:IMP:STAT OFF"
        talk cx to gpib address gpibAddr with srcPrefix [ genType , SMP_CLK ] + "IQ:SWAP OFF"
        talk cx to gpib address gpibAddr with srcPrefix [ genType , SMP_CLK ] + "IQ:WBST ON"
        talk cx to gpib address gpibAddr with srcPrefix [ genType , SMP_CLK ] + "IQ:CRES 0 "
        talk cx to gpib address gpibAddr with srcPrefix [ genType , SMP_CLK ] + "IQ:SOUR ANAL"
        talk cx to gpib address gpibAddr with srcPrefix [ genType , SMP_CLK ] + "IQ:STAT OFF"
        talk cx to gpib address gpibAddr with srcPrefix [ genType , SMP_CLK ] + "POW:ALC:STAT ON"
        talk cx to gpib address gpibAddr with srcPrefix [ genType , SMP_CLK ] + "ROSC:SOUR EXT"
        Clk4Freq = 0.0
        Clk4Amplitude = -120.0 dBm
        SetClk4Frequency (  1.0GHz  )
        SetClk4Level     ( -80.0dBm )
    endif
    
endbody
--------------------------------------------------------------------------------
procedure LoadRFCalfactorArray ( fileName , calAry )
--------------------------------------------------------------------------------
in string [ 255 ]           : fileName
in_out double               : calAry [ ? ]


local string [ 255 ]        : pathName
local integer               : length
local integer               : file1
local integer               : i

body

    length = dimsize ( calAry , 1 )
    pathName = "/ltx/testers/" + tester_name + "/calfiles/gtoFE/" + fileName
    if exist ( pathName ) then
        open ( file1 , pathName , "r" )
        for i = 1 to length do
            input ( file1 , calAry [ i ] )
        endfor
        close ( file1 )
    else
        calAry = RF_CAL_REFERENCE_LEVEL 
    endif
        
endbody
--------------------------------------------------------------------------------
procedure SetSampleClkCalibrated ( frequency , amplitude_dBm )
------------------------------------------------------------------------------------
in double               : frequency
in double               : amplitude_dBm

local integer           : calIndex
local integer           : i
local double            : y
local double            : x
local double            : inLevel

body

    SetSampleClkFrequencyOnly ( frequency )
    calIndex = integer ( double ( CAL_RF_FREQ_SZ ) * frequency / AUX_CLK_MAX_FREQ )
    
    if calIndex < CAL_RF_FREQ_SZ - 3 then
        i = calIndex - 1
    else
        i = CAL_RF_FREQ_SZ - 3
    endif
    
    if i < 1 then 
        i = 1 
    endif
    
    x = frequency * double ( CAL_RF_FREQ_SZ ) / SAMPLE_CLK_MAX_FREQ - double ( i - 1 )
    y = CubicSpline ( smpClkCalAry [ i : i + 3 ] , x )

    inLevel = amplitude_dBm + ( RF_CAL_REFERENCE_LEVEL - y )
    if inLevel >= sample_clk_min_level and inLevel <= sample_clk_max_level + 7.0 then
        SetSMIQSampleClockLevel ( sampClkGPIBAddr [ genType ] , inLevel )
    else
        println(stdout, "Programmed  value is "+sprint(inLevel)+" dBm.")
        println(stdout, "Minimum value for level is "+sprint(sample_clk_min_level)+" dBm.")
        println(stdout, "Maximum value for level is "+sprint(sample_clk_max_level)+" dBm.")
        println(stdout, "Halted from procedure 'clkCtrl.mod/SetSampleClkCalibrated'")
        halt
    endif

endbody
------------------------------------------------------------------------------------
procedure FindSmate
--------------------------------------------------------------------------------

body

    smateExists = false
    if exist ( "/ltx/testers/" + tester_name + "/calfiles/gtoFE/SMATE_AT_GPIB_ADDR_29" ) then
        smateExists = true
    endif

endbody
--------------------------------------------------------------------------------
