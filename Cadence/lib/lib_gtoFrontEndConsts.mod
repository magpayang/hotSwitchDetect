-- MX head slot assignment for the GTO Buffer
--  20110526        pla     Add prefix "lib_" to module names for local template copy

const GTB_SLOT_NUM                                  = 5
static word                                         : gtbSlotNum
                                                    
-- Register Addresses                               
const GTOBUF_BD_ID                                  = 16#0000
const GTOBUF_BD_PROM                                = 16#0001
const GTOBUF_IRQEN                                  = 16#0002
const GTOBUF_BD_IRQ                                 = 16#0003
const GTOBUF_CTRL                                   = 16#0008
const GTOBUF_SYN_DIR                                = 16#0009
const GTOBUF_A_CH_1_RLY                             = 16#000A
const GTOBUF_A_CH_2_RLY                             = 16#000B
const GTOBUF_B_CH_3_RLY                             = 16#000C
const GTOBUF_B_CH_4_RLY                             = 16#000D
const GTOBUF_A_CLK_CTL                              = 16#000E
const GTOBUF_B_CLK_CTL                              = 16#000F
const GTOBUF_A_SRC_SW                               = 16#0010
const GTOBUF_B_SRC_SW                               = 16#0011
const GTOBUF_A_CH1_A_GAIN                           = 16#0012
const GTOBUF_A_CH1_B_GAIN                           = 16#0013
const GTOBUF_A_CH2_A_GAIN                           = 16#0014
const GTOBUF_A_CH2_B_GAIN                           = 16#0015
const GTOBUF_B_CH3_A_GAIN                           = 16#0016
const GTOBUF_B_CH3_B_GAIN                           = 16#0017
const GTOBUF_B_CH4_A_GAIN                           = 16#0018
const GTOBUF_B_CH4_B_GAIN                           = 16#0019
const GTOBUF_DAC_CTL                                = 16#001A
const GTOBUF_DAC_TRIG_CTL                           = 16#001B
const GTOBUF_SRC_SW_TRIG_CTL                        = 16#001C
const GTOBUF_A_SAMP_MUX_CTL                         = 16#001D
const GTOBUF_B_SAMP_MUX_CTL                         = 16#001E
                                                    
                                                    
const GTB_SHADOW_SZ                                 = GTOBUF_B_SAMP_MUX_CTL   

--Bit Values
const BIT0                                          = 1
const BIT1                                          = 2 * BIT0 
const BIT2                                          = 2 * BIT1 
const BIT3                                          = 2 * BIT2 
const BIT4                                          = 2 * BIT3 
const BIT5                                          = 2 * BIT4 
const BIT6                                          = 2 * BIT5 
const BIT7                                          = 2 * BIT6 
const BIT8                                          = 2 * BIT7 
const BIT9                                          = 2 * BIT8 
const BIT10                                         = 2 * BIT9 
const BIT11                                         = 2 * BIT10
const BIT12                                         = 2 * BIT11
const BIT13                                         = 2 * BIT12
const BIT14                                         = 2 * BIT13
const BIT15                                         = 2 * BIT14
                                                    
--GTOBUF_BD_ID                                      = 16#0000 bits 
const EE_SDA                                        = BIT7
const N_EE_WP                                       = BIT2
const EE_SCL                                        = BIT1
                                                    
--shadow array                                      
static word                                         : gtb_shadow [ GTB_SHADOW_SZ ]
const ADDR = 2                                      
const DATA = 1                                      
                                                    
--status display array
const DISPLAY_ON                                    = true                           
const DISPLAY_OFF                                   = false                           
static string [ 256 ]                               : gtb_st [ GTB_SHADOW_SZ ]
static boolean                                      : gtbStatusEnabled = DISPLAY_ON                               
--source relay control constants and arrays         
const GTB_SRC_SET                                   = [ 1 , 2 , 3 , 4 ]
                                                    
const GTB_MAX_SRC                                   = 4                                     --maximum in MX system
static set [ 16 ]                                   : gtbSrcSet                             --set can be determined by inventory
                                                    
static word                                         : gtbSrcRelayAddr [ GTB_MAX_SRC ]       --addresses of srce relays

const GTB_MAX_DAC_CALFACS                           = 256
const GTB_CAL_DACB_ID                               = "DacB_Calfacs"
const GTB_CAL_DACA_ID                               = "DacA_Calfacs"
const GTB_DAC_A_SHUTDOWN_LEVEL                      = 0
const GTB_DAC_B_SHUTDOWN_LEVEL                      = 54000

static string [ 256 ]                               : calfactorPathName
static float                                        : gtbHighMidPoint  [ GTB_MAX_SRC ]
static integer                                      : gtbDacBCalSz     [ GTB_MAX_SRC ] 
static integer                                      : gtbDacACalSz     [ GTB_MAX_SRC ]
static float                                        : gtbDacBCalLevels [ GTB_MAX_SRC , GTB_MAX_DAC_CALFACS ] 
static float                                        : gtbDacACalLevels [ GTB_MAX_SRC , GTB_MAX_DAC_CALFACS ] 
static float                                        : gtbDacANomLevels [ GTB_MAX_DAC_CALFACS ] 
static integer                                      : gtbDacBCalBits   [ GTB_MAX_SRC , GTB_MAX_DAC_CALFACS ] 
static integer                                      : gtbDacACalBits   [ GTB_MAX_SRC , GTB_MAX_DAC_CALFACS ] 
static integer                                      : gtbDacANomBits   [ GTB_MAX_DAC_CALFACS ] 


const GTB_SRC_PATH_COUNT                            = 6
const GTB_SRC_PATH_ENDS                             = 3
static word                                         : gtbSrcConnectAry [ GTB_SRC_PATH_COUNT , GTB_SRC_PATH_ENDS ]            --entries for all legal settings
static string [ 132 ]                               : gtbPathStatusAry [ GTB_SRC_PATH_COUNT ]
static string [ 132 ]                               : gtbPathEndedAry  [ GTB_SRC_PATH_ENDS  ]

                                           
const SE_PLUS                                       = 1                                     --three connection options
const SE_MINUS                                      = 2
const BALANCED                                      = 3
                                                    
const GTB_SRC_THROUGH                               = 1                                     --six paths
const GTB_SRC_ATTN                                  = 2
const GTB_SRC_GAIN                                  = 3
const GTB_SRC_USER1                                 = 4
const GTB_SRC_USER2                                 = 5
const GTB_SRC_USER3                                 = 6
                                                    
const GTB_SRC_THROUGH_DATA                          = BIT0 + BIT8                           --path data
const GTB_SRC_ATTN_DATA                             = BIT1 + BIT9
const GTB_SRC_GAIN_DATA                             = BIT2 + BIT10
const GTB_SRC_USER1_DATA                            = BIT3 + BIT11
const GTB_SRC_USER2_DATA                            = BIT4 + BIT12
const GTB_SRC_USER3_DATA                            = BIT5 + BIT13
                                                    
const SE_PLUS_MASK                                  = 2#111111                              -- connection mask
const SE_MINUS_MASK                                 = 2#11111100000000
const BALANCED_MASK                                 = SE_PLUS_MASK + SE_MINUS_MASK
                                                    
const GTB_SRC_ATTEN_PATH_MIN                        = 7.1mv
const GTB_SRC_ATTEN_PATH_MAX                        = 100.0mv
const GTB_SRC_THROUGH_PATH_MAX                      = 1000.0mv
const GTB_SRC_GAIN_PATH_MAX                         = 6000.0mv                                            
const GTB_SRC_GAIN_FORCED_MIN                       = 70.0mv
                                           
const GTB_FORCE_HIGH_SOURCE_RANGE                   = true
const GTB_NORMAL_SOURCE_RANGING                     = false

const GTB_SRC_ATTEN_PATH_NOMINAL_CALFAC             = 10.0 * sqr ( 2.0 )
static float                                        : gtbAttnPathCalfactor = GTB_SRC_ATTEN_PATH_NOMINAL_CALFAC

const GTB_SRC_ATTEN_THROUGH_NOMINAL_CALFAC          = 1.0
static float                                        : gtbThroughPathCalfactor = GTB_SRC_ATTEN_THROUGH_NOMINAL_CALFAC

const GTB_SRC_GAIN_PATH_GTO_LEVEL                   = 800.0mv

static word                                         : gtbSrcDacAAddr [ GTB_MAX_SRC ]
static word                                         : gtbSrcDacBAddr [ GTB_MAX_SRC ]

const GTB_DATA                                      = 1
const GTB_MASK                                      = 2
const GTB_ADDR                                      = 3
const ODD                                           = 1
const EVEN                                          = 2
const OFF                                           = 3
const MUX_SRC_OFF                                   = 5

const GTB_MUX_ODD_GTO_SRC_TO_ODD_OUTPUT             =  2#00
const GTB_MUX_EVEN_GTO_SRC_TO_ODD_OUTPUT            =  2#10
const GTB_MUX_DISABLE_ODD_OUTPUT                    =  2#01
const GTB_MUX_ODD_OUTPUT_MASK                       = ~2#11

const GTB_MUX_ODD_GTO_SRC_TO_EVEN_OUTPUT            =  2#1000
const GTB_MUX_EVEN_GTO_SRC_TO_EVEN_OUTPUT           =  2#0000
const GTB_MUX_DISABLE_EVEN_OUTPUT                   =  2#0100
const GTB_MUX_EVEN_OUTPUT_MASK                      = ~2#1100

static word                                         : gtbMuxStates [ GTB_MAX_SRC , GTB_MAX_SRC + 1 , 3 ]

static word                                         : gtbSamplClkControlAddr [ 4 ]
const GTB_CLK_DIVIDER_MASK                          = ~2#11111     
const GTB_CLOCK_OUTPUT_SELECT_MASK                  = ~2#1100000000000000

const GTB_CLOCK_OUTPUT_GENERATOR                    = 2#1000000000000000
const GTB_CLOCK_OUTPUT_DIVIDED                      = 2#0100000000000000
const GTB_CLOCK_OUTPUT_OFF                          = 2#0000000000000000

const GENERATOR                                     = 1
const DIVIDED_CLOCK                                 = 2
static word                                         : gtbSampClkOutputSelection [ 3 ]

static word                                         : gtbSamplerMuxStates [ GTB_MAX_SRC , 2 , 3 , 3 ]
const AUX_SAMPLER                                   = 1
const GTO_SAMPLER                                   = 2

const GTB_MUX_ODD_GTO_SAMPLER_TO_ODD_DIGITIZER      =  2#10000001
const GTB_MUX_EVEN_GTO_SAMPLER_TO_ODD_DIGITIZER     =  2#10000000
const GTB_MUX_ODD_AUX_SAMPLER_TO_ODD_DIGITIZER      =  2#10000011
const GTB_MUX_EVEN_AUX_SAMPLER_TO_ODD_DIGITIZER     =  2#10000010
const GTB_MUX_DISABLE_ODD_DIGITIZER                 =  2#00000000
const GTB_MUX_ODD_DIGITIZER_MASK                    = ~2#11111111
const GTB_MUX_ODD_DIGITIZER_ENABLE_MASK             = ~2#10000000
const GTB_MUX_ODD_DIGITIZER_CONNECT_MASK            = ~2#00000011

const GTB_MUX_ODD_GTO_SAMPLER_TO_EVEN_DIGITIZER     =  2#1000000100000000      
const GTB_MUX_EVEN_GTO_SAMPLER_TO_EVEN_DIGITIZER    =  2#1000000000000000  
const GTB_MUX_ODD_AUX_SAMPLER_TO_EVEN_DIGITIZER     =  2#1000001100000000     
const GTB_MUX_EVEN_AUX_SAMPLER_TO_EVEN_DIGITIZER    =  2#1000001000000000  
const GTB_MUX_DISABLE_EVEN_DIGITIZER                =  2#0000000000000000  
const GTB_MUX_EVEN_DIGITIZER_MASK                   = ~2#1111111100000000  
const GTB_MUX_EVEN_DIGITIZER_ENABLE_MASK            = ~2#1000000000000000  
const GTB_MUX_EVEN_DIGITIZER_CONNECT_MASK           = ~2#0000001100000000  
static string [ 132 ]                               : gtbSampMuxStates [ 4 ]
static boolean                                      : gtbHighRange [ 4 ]

static string [ 132 ]                               : s [ 32 ]

static set [ 2 ]                                    : gtb_GtoToDigMap [ GTB_MAX_SRC ]
--------------------------------------------------------------------------------
--  static arrays for sampler cal
const SAMP_CALFAC_ARY_SZ                            = 262144
static float                                        : samplerCalFactors [ SAMP_CALFAC_ARY_SZ ]

const SAMP_CALFACS                                  = 1024
static integer                                      : samplerCalFactorStart [ SAMP_CALFACS ]
static integer                                      : samplerCalfactorStop [ SAMP_CALFACS ]
static integer                                      : samplerCalfactorLen [ SAMP_CALFACS ]
static double                                       : samplerCalfactorFreq [ SAMP_CALFACS ]
static double                                       : samplerCalfactorPassband [ SAMP_CALFACS ]
static double                                       : samplerCalfactorStopband [ SAMP_CALFACS ]
static word                                         : samplerCalfactorChan [ SAMP_CALFACS ]
static word                                         : samplerCalfactorBits [ SAMP_CALFACS ]
static boolean                                      : samplerCalfactorLoc [ SAMP_CALFACS ]  

static integer                                      : lastCalAryIndex = 0
static string [ 256 ]                               : scopeCalPathName
static string [ 256 ]                               : currentCounterPathName
static string [ 256 ]                               : cumulativeCountPathName
static string [ 256 ]                               : backupCumulativeCountPathName

static integer                                      : gtb_counterTime
static string [ 256 ]                               : gtb_counterStartingTime
static string [ 256 ]                               : gtb_counterStartingDate
static boolean                                      : printRelayActuations = false
static integer                                      : gtb_previousRelayState [ GTB_MAX_SRC ]
static integer                                      : gtb_programRuns
static integer                                      : gtb_relayClicks [ GTB_MAX_SRC ]
static string [ 80 ]                                : loadBoardSerNum
static string [ 17 ]                                : loadBoardSerNumForScopeCal = ""
const CAL_WAVE_RATE                                 = 40.0MHz
const SCOPE_CAPTURE_SIZE                            = 4096
const CALFILE_SAMPLE_RATE                           = ( CAL_WAVE_RATE * 2 ) * double ( SCOPE_CAPTURE_SIZE )
static double                                       : scopeImpulse   [ 8 , SCOPE_CAPTURE_SIZE ]
static double                                       : samplerImpulse [ 8 , SCOPE_CAPTURE_SIZE ]
static integer                                      : SamplerDivider
static double                                       : lastSampleClockFreq

const GTB_FLAT_SAMPLER_BW                           = 12.0GHz                                 
const GTB_SAMPLER_STOP_BAND                         = 16.0GHz

static double                                       : gtb_bw = GTB_FLAT_SAMPLER_BW
static double                                       : gtb_sb = GTB_SAMPLER_STOP_BAND
static double                                       : gtb_thDroopTimeConstants [ GTB_MAX_SRC * 2 , 2 ]
static double                                       : gtb_sampleClkFrequency
static word                                         : gtb_sampleClkDivVal [ GTB_MAX_SRC * 2 ]
static double                                       : gtb_CalClockRate 

static boolean                                      : clickCounterInitialized  = false          
static boolean                                      : afe = false    
static boolean                                      : rfCal = false
static boolean                                      : fourVgas = false
const SEVEN_GHZ_LEVEL                               = "/calfiles/gtoFE/optimumLevel.txt"
static word list [ 8 ]                              : afeVgaList 

--------------------------------------------------------------------------------
