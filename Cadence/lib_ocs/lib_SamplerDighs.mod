-------------------------------------------------------------------------------------------
--                                                                                       --
--                          GTO Front End Sampler and DIGHS Test Suite                   --
--                                                                                       --
--                                     Author : B.SCHUSHEIM                              --  
--
-------------------------------------------------------------------------------------------

-------------------------------------------------------------------------------------------
--                                                                                       --
--                                  REVISION LOG                                         --
--                                                                                       --
-- Revision         Who     Comments                                                     --
--                          
--
-- Oct 11 2005      BS      Rev 0   Original Code                                        --
--
--                                                                                       --
-- May  5 2006      WDC   RCS Revision level: $Id: SamplerDighs.mod,v 1.1 Exp wdc $      --
--
--                                                                                       --
-- June 13 2008     BS      Rev 2   Added Spread Spectrum measurements, Spectra Strip    --
--                                   Cable and FR4 optional simulation to Data Dependent --
--                                  Jitter.  Added AFE channel assignment procedure      --
-- 
--
-- Oct 10 2008      BS      Rev 3   Added Transmission Medium simulation for FR4         --
--                                   Laminate Medium simulation for FR4 laminate, Cat 5, --
--                                    Cat 6, Cat 7 and Spectra-Strip cables for use in   --
--                                   DDJ/Eye Pattern testing.                            --
--
-- Oct 23 2008      BS      Rev 3.1  Spectra-Strip Cable filter simulation derived from  --
--                                   actual Spectra_Strip Cable.  Found manufacturer's   --
--                                   typical insertion loss to be a little optimistic    --
--                                   compared to the reference cable.                    --
--
-- Oct 27 2008     BS       Rev 3.2  Expanded DDJ Eye Pattern test to accomodate 512 bit --
--                                   pattern.                                            --
--
-- May 27 2011     PLA      Rev 3.3  Edited "use module" statements to reflect renamed   --
--                                   and relocated dependent modules.                    --

-------------------------------------------------------------------------------------------

-------------------------------------------------------------------------------------------
--                              MODULE DESCRIPTION 

--      This Cadence module contains procedures for testing and measuring high speed digital
-- waveforms and their jitter.  Procedures that perform a complete test are as follows:

--  ********************  "WaverformMeasurementTest" ***************************
--  This procedure sets up, captures and proceesses high speed serial data, to provide Rise Time, Fall Time,
--  Duty Cycle Distortion,by utilizing the GTO Front End samplers and   Differential Output Level (with and/or 
--  without pre-emphasis and de-emphasis).  Measurement results are compared to limits and datalogged.
--
--  An optional feature of this procedure is software equalization to compensate for printed circuit trace
--  and cable between the device under test and the measuring sampler within the GTO Front End.
--
-- This procedure calls procedures "SetupWaveformMeasurement" and "WaveformMeasurement".


--  **************************  "Direct_R_J_Test" *********************************
-- This procedure performs a complete random jitter test including setting up, capturing waveform, processing and testing
-- measurements results against specified limits.  Procedures "SetupWaveformMeasurement" and "Direct_R_J_Measure(SampDighsPins"
-- are called by this procedure.  The data pattern being captured must be a square pattern such as a repeating 1010...10
-- pattern or a repeating 11001100...1100 data pattern.  
--
-- This procedure outputs the random jitter measurement as an RMS (Root Mean Square) value, which can later be used 
-- in combination with an array of zero volt crossing data transition points and periodic jitter measurements to derive 
-- the total jitter. 


--  ********************  "RandJitFromSpectrumTest" ***************************
-- This procedure calls procedures uses Spectrum Analysis to measure Random Jitter with a phase noise 
-- measurement technique.   It sets up, captures and processes, then test against specified limits and dataloggs results.
-- The GTO Front End sampler waveform must be a square waveform, such as a repeating 1010...10 pattern or a repeating 11001100...1100
-- data pattern.  The processing filters out periodic jitter tones and alows bandpass filtering of captured phase noise.


--  *************************  "DdjEyePatternTest" ********************************
-- This procedure performs a complete data dependent jitter test including setting up, capturing waveform, processing and testing
-- measurements results against specified limits.  Procedures "SetupDdjEyePattern" and "DdjEyePattern" are called by
-- this procedure. Random Jitter is filtered out of the waveform  being captured, to produce an Eye pattern test of just 
-- the deterministic jitter.  The recommended pattern for use with this procedure is a between 20 bits and 160 bits long and rich 
-- in data dependent jitter.
-- The resultant Eye Pattern is also tested against an Eye Pattern Mask defined by a 6 element array of EyeMaskData. 
--
--  MaskPointA, MaskPointB, MaskPointC and MaskPointD define timing positions 
--  of the mask with values between 0.0 and 1.0.  For example MaskPointA,  A 
--  could be 0.2, MaskPointB,  B could be 0.3, MaskPointC,  C could be 0.7 
--  and MaskPointD,  D could be 0.8. MaskLevel and - MaskLevel are equal in
--  magnitude with respect to the 0.0V level.
--
--  MaskLevelMinMax determines the upper and lower voltage limits for the mask.
--
--     |<--------------Bit Cell 1.0UI ---------->|    ****  Data Stream
--     |
--     | ----------------------------------------|..... MaskLevelMinMax
--     |       ****************************      |
--     |    *      ___________________ .....*....|..... MaskLevel
--     |   *      /:                 :\      *   |
--     |  *      / :                 : \      *  |
--     | *      /  :                 :  \......*.|..... 0.0V
--     | *     :\  :                 :  /:     * |
--     |  *    : \ :                 : / :    *  |
--     |   *   :  \:_________________:/..:...*...|..... -MaskLevel
--     |    *  :   :                 :   :  *    |
--     |      *****************************      |
--     | ----------------------------------------|..... -MaskLevelMinMax
--    0.0      A   B                 C   D      1.0

--   EyeMaskData[1] is MaskPointA
--   EyeMaskData[2] is MaskPointB
--   EyeMaskData[3] is MaskPointC
--   EyeMaskData[4] is MaskPointD
--   EyeMaskData[5] is MaskLevel
--   EyeMaskData[6] is MaskLevelMinMax
--
--  An optional feature of this procedure is software equalization to compensate for printed circuit trace
--  and cable between the device under test and the measuring sampler within the GTO Front End.
--
--  Another optional feature allows adding software filters simulating the Inter-Symbol-Interference of 
--  long cables or printed circuit traces,  Specifically Spectra Strip cable and FR4 microstrip traces.
--  This filter eliminates the need to have the ltransmission medium in the signal path from a DUT's 
--  output to the measuring sampler.  This is used where a devices output Data Dependent Jitter is to be 
--  observed at the far end of the transmission medium.
--
--   In addition to measuring and testing DDJ and eye pattern, the procedure also outputs an array of zero 
-- volt crossing data transition points which can later be used in combination with random jitter and 
-- periodic jitter measurements to derive the total jitter. 


--  *************************  "SubRateJitterTest" ********************************
-- This procedure performs a complete Sub-Rate jitter test, including timing setup, spectrum capture, processing, 
-- measuring, comparing to test limits and daatalogging results. Sub-Rate jitter is periodic jitter that typically 
-- is associated with a DUT's PLL clock divider.
--
-- The required measurement waveform must be a square pattern, such as a repeating 1010...10pattern or 
-- a repeatoing 11001100...1100 data pattern.


--  *************************  "TotalJitterTest" ********************************
-- This procedure calls procedure "TotalJitter" and derives total P-P  jitter and Eye Width at a specified Bit Error 
-- Rate down to 10^-18.  Then it compares measurement data against test limits and datalogs results.
--
-- The procedure utilizes measurement results from a pervious measurement of the Random Jitter
-- and previous measurement of Deterministic Jitter, including periodic jitter (Sub-Rate Jitter) and data dependent jitter.


--  *************************  "SpreadSpectrumTest" ********************************
-- This procedure calls procedures "SetupSpreadSpectrumMeas", "SetupSpreadSpectrumMeasurement", "SetupSpreadSpecModFreqMeas",
-- ansd "SetupSpreadSpecModFreqMeasurement".  It is used to measure Spread Spectrum parameters from a continuously repeating
-- square pattern, such as 1010...10.  Parameters measured are Peak Reduction, Spread Range, Maximum Data Rate of spread, 
-- Minimum Data Rate of spread, and Modulation Frequency. 


--  *************************  "SamplerDighsInit" ********************************
-- The Initialize procedure should be called when the program is loaded. It is normally used for
-- one-time instrument setups, 


-------------------------------------------------------------------------------------------

-------------------------------------------------------------------------------------------
--                                                                                       --
--                              TEST PROGRAM  MODULES                                    --
--                                                                                       --
  use module "../lib/lib_gtoFrontEndCtrl.mod"
  use module "../lib/lib_gtoFrontEndConsts.mod"
  use module "../lib/lib_clkCtrl.mod"
-------------------------------------------------------------------------------------------

-------------------------------------------------------------------------------------------
--                                                                                       --                           
--                             STATIC VARIABLES                                         --                                       
--                                                                                       --
static
    float                             : BifWaveform[MAX_DIGHS,SAMP_DIGHS_WAVEFORM_SAMPLES]
    float                             : BifSpectrumData[MAX_DIGHS,SAMP_DIGHS_SPECTRUM_SAMPLES]
    float                             : BifSubRateJitData[MAX_DIGHS,SAMP_DIGHS_SUB_RATE_SAMPLES]
    float                             : BifDdjWaveform[MAX_DIGHS,SAMP_DIGHS_MAX_EYE_SAMPLES]
    float                             : TransFilter[MAX_FILTERS,SAMP_DIGHS_TRANS_FILTER]
    float                             : BifSpreadSpectrumData[MAX_DIGHS,SAMP_DIGHS_SSC_MEAS_SAMPLES]
    float                             : BifRawDdjWaveform[MAX_DIGHS,SAMP_DIGHS_MAX_DECIMATED_SAMPLES]
    float                             : Bathtub[MAX_DIGHS+1,BATHTUB_STEPS]
    float                             : SpectrumCal102[MAX_DIGHS,SAMP_DIGHS_SPECTRUM_SAMPLES]
    float                             : SpectrumCal51[MAX_DIGHS,SAMP_DIGHS_SPECTRUM_SAMPLES]
    float                             : SpectrumCal25[MAX_DIGHS,SAMP_DIGHS_SPECTRUM_SAMPLES]
    boolean                           : CharMode = false    -- Characterization Mode
    boolean                           : DisplayMode = True -- Display Mode for status page observation
    boolean                           : Scope_Mode = false  -- Scope Mode for Oscillope Sync with Sample Clock
    boolean                           : use_dighsb = true   -- Set this boolean false to use dighs instead of dighsb, otherwise set true
    float                             : LossSpectrum[200]   -- Reference Equalization Array
    float                             : R4350_6MilEqPerInch[200]
    float                             : R4350_10MilEqPerInch[200]
    float                             : R4003_8MilEqPerInch[200]
    float                             : SpectraStripLoss[200]
    float                             : SpectraStripLoss2[10]
    float                             : SpectraStripLoss3[10]
    float                             : Fr4MicrostripLossPerInch[200]
    float                             : Fr4MicrostripLossPerInch2[10]
    float                             : Fr4MicrostripLossPerInch3[10]
    float                             : Cat5_CableLoss[200]
    float                             : Cat5_CableLoss2[10]
    float                             : Cat5_CableLoss3[10]
    float                             : Cat6_CableLoss[200]
    float                             : Cat6_CableLoss2[10]
    float                             : Cat6_CableLoss3[10]
    float                             : Cat7_CableLoss[200]
    float                             : Cat7_CableLoss2[10]
    float                             : Cat7_CableLoss3[10]
    float                             : SpectrumRef[SAMP_DIGHS_SPECTRUM_SAMPLES/2 +1]  -- First Site, First Channel Reference Spectrum
end_static
-------------------------------------------------------------------------------------------

-------------------------------------------------------------------------------------------
--                                                                                       --                           
--                             GENERAL CONSTANTS                                         --                                       
--                                                                                       --
const 
    MAX_DIGHS                        = 4         -- Maximum Number of digitizers
    SAMP_DIGHS_MAX_SAMPLE_CLK_FREQ   = 1400.0MHz -- Maximum Sampler Clock frequency for Waveform capture
    SAMP_DIGHS_MAX_DIG_FREQ          = 105.0MHz  -- Maximum Sampling frequency for Waveform capture
    SAMP_DIGHS_MIN_DIG_FREQ          = 3.125MHz  -- Minimum Sampling frequency for Waveform capture
    SAMP_DIGHS_SPECTRUM_CLK_FREQ     = 102.4MHz  -- Maximum Sampling frequency for spectrum capture
    SAMP_DIGHS_EYE_SAMPLES_PER_BIT   = 200       -- Eye Pattern samples per bit
    SAMP_DIGHS_ALT_EYE_SAMPS_PER_BIT = 100       -- Eye Pattern samples per bit for patterns over 250 bits long
    SAMP_DIGHS_MAX_EYE_WAVEFORM_BITS = 512       -- Maximum number of Eye Pattern Bits
    SAMP_DIGHS_MAX_EYE_EDGES         = 256       -- Maximum Number of Eye Pattern edges
    SAMP_DIGHS_MAX_EYE_FFT_SAMPLES   = 16384     -- Maximum FFT Size for Eye Pattern filter
    SAMP_DIGHS_TRANS_FILTER          = 65536     -- Maximum size for transmission filter
    SAMP_DIGHS_MAX_DECIMATION        = 10         -- Maximum decimation ratio
    SAMP_DIGHS_MAX_EYE_SAMPLES       = SAMP_DIGHS_MAX_EYE_WAVEFORM_BITS * SAMP_DIGHS_ALT_EYE_SAMPS_PER_BIT
    SAMP_DIGHS_MAX_DECIMATED_SAMPLES = SAMP_DIGHS_MAX_EYE_SAMPLES * SAMP_DIGHS_MAX_DECIMATION 
    SAMP_DIGHS_WAVEFORM_SAMPLES      = 8192      -- Waveform Analysis sample size
    SAMP_DIGHS_WAVEFORM_2BIT_PK_DLY  = SAMP_DIGHS_WAVEFORM_SAMPLES/2*3/16  -- Rise and Fall Times referenced to 3/16 Bit Time delay from peak on 2 bit waveform
    SAMP_DIGHS_SPECTRUM_SAMPLES      = 16384     -- Spectrum Analysis sample size
    SAMP_DIGHS_SUB_RATE_SAMPLES      = 16384     -- Sub Rate Jitter Measurement sample size
    SAMP_DIGHS_SSC_MEAS_SAMPLES      = 16384     -- spread Spectrum Measurement sample size 
    SAMP_DIGHS_SSC_MEAS_OFFSET       = 6.2MHz    -- SMS Spread Spectrum Measurement offset frequency below top of spectrum
    
    MAX_FILTERS                      = 6         -- Maximum number of Transmission medium filters  -- used in DDJ Eye Pattern test
    MAX_NUM_TONES                    = 40        -- Max number of periodic jitter tones to return -- from procedure SpectrumAnalysis
    CARRIER_TONE_SUB_RATE_MEAS       = 320       -- FFT Harmonic for carrier frequency in Sub-Rate Jitter measurement
    BATHTUB_STEPS                    = 20 * SAMP_DIGHS_EYE_SAMPLES_PER_BIT

                -- CONSTANTS REQUIRED TO SELECT SAMPLER TO DIGITIZER CONNECTIONS
    AUX_IN_ODD_CHAN                  = 1
    DATA_IN_ODD_CHAN                 = 2
    AUX_IN_EVEN_CHAN                 = 3
    DATA_IN_EVEN_CHAN                = 4
 
                --  CONSTANTS REQUIRED TO SELECT EQUALIZATION DUT BOARD LAMINATE
     R4350_10Mil                     = 1
     R4350_6Mil                      = 2
     R4003_8Mil                      = 3

    --These constants are array indices into the "results" array
    --for the SC_waveformParametrics procedure.  The constant
    --name indicates the location of the corresponding result.
    PAR_RISE_TIME         = 1
    PAR_FALL_TIME         = 1 + PAR_RISE_TIME
    PAR_WIDTH_P           = 1 + PAR_FALL_TIME
    PAR_VOD_P             = 1 + PAR_WIDTH_P
    PAR_VOD_D             = 1 + PAR_VOD_P
    DUMMY                 = 1 + PAR_VOD_D
    PAR_ARY_SZ            = DUMMY  -- use this constant to define the size of the results array

end_const
procedure SetEyeMask(MaskPointA,MaskPointB,MaskPointC,MaskPointD,MaskLevel,MaskLevelMinMax,BitsPerWaveform,SamplesPerBit ,EyeMask)
 in float              : MaskPointA       --  Early Zero Crossing Bit Cell marker point
 in float              : MaskPointB       --  Early Mask level Bit Cell Marker Point
 in float              : MaskPointC       --  Late Mask level Bit Cell Marker Point
 in float              : MaskPointD       --  Late Zero Crossing Bit Cell marker point
 in float              : MaskLevel        --  Voltage level defining + and - Mask Levels Inside the Data Stream
 in float              : MaskLevelMinMax  --  Voltage level defining + and - Mask Levels Outside the Data Stream
 in integer            : BitsPerWaveform  --  Length in bits in the waveform (e.g. 127 for prbs2^7-1)
 in integer            : SamplesPerBit    -- Total samples per Bit of data
 in_out float          : EyeMask[?]       --  Eye Mask to compare against captured waveform

-----------------------------------------------------------------
--  This procedure defines the Eye Pattern Mask for a Waveform 
--  measurement set up by procedure SetupGTOfeEyeDDJMeas and 
--  processed inprocedure Procedure ProcessGTOfeEyeDDJMeas. 
--  This procedure mus be executed first to define the Eye Pattern Mask
--  before processing is executed.
--
--  MaskPointA, MaskPointB, MaskPointC and MaskPointD define timing positions 
--  of the mask with values between 0.0 and 1.0.  For example MaskPointA,  A 
--  could be 0.2, MaskPointB,  B could be 0.3, MaskPointC,  C could be 0.7 
--  and MaskPointD,  D could be 0.8. MaskLevel and - MaskLevel are equal in
--  magnitude with respect to the 0.0V level.
--
--  MaskLevelMinMax determines the upper and lower voltage limits for the mask.
--
--     |<--------------Bit Cell 1.0UI ---------->|    ****  Data Stream
--     |
--     | ----------------------------------------|..... MaskLevelMinMax
--     |       ****************************      |
--     |    *      ___________________ .....*....|..... MaskLevel
--     |   *      /:                 :\      *   |
--     |  *      / :                 : \      *  |
--     | *      /  :                 :  \......*.|..... 0.0V
--     | *     :\  :                 :  /:     * |
--     |  *    : \ :                 : / :    *  |
--     |   *   :  \:_________________:/..:...*...|..... -MaskLevel
--     |    *  :   :                 :   :  *    |
--     |      *****************************      |
--     | ----------------------------------------|..... -MaskLevelMinMax
--    0.0      A   B                 C   D      1.0

-----------------------------------------------------------------
local
  integer              : i, PtA, PtB, PtC, PtD
endlocal
body


    EyeMask =  - MaskLevelMinMax 
    PtA = integer(MaskPointA * float(SamplesPerBit))
    PtB = integer(MaskPointB * float(SamplesPerBit))
    PtC = integer(MaskPointC * float(SamplesPerBit))
    PtD = integer(MaskPointD * float(SamplesPerBit))
    for i = PtA to PtB do
        EyeMask[i + SamplesPerBit/2] = float(i- PtA)/float(PtB-PtA+1) * MaskLevel
    end_for
    EyeMask[PtB + SamplesPerBit/2:PtC + SamplesPerBit/2] = MaskLevel
    for i = PtC to PtD do
         EyeMask[i + SamplesPerBit/2] = float(PtD - i)/float(PtD-PtC) * MaskLevel
    end_for
    EyeMask[1:SamplesPerBit/2] = EyeMask[1+SamplesPerBit:SamplesPerBit*3/2]

    for i = 2 to BitsPerWaveform do
         EyeMask[1+SamplesPerBit * (i-1):SamplesPerBit * i] = EyeMask[1:SamplesPerBit]
    end_for
end_body

procedure SetupWaveformMeasurement(SamplerConnection,SampDighsPins,DataRate,BitsPerWaveform,MeasLevelMax)
in multisite integer   : SamplerConnection[MAX_DIGHS] -- "DataInOdd" (2), "DataInEven" (4), AltInOdd" (1) or "AltInEven" (3)
in pin list[MAX_DIGHS] : SampDighsPins                -- Selected DIGHS Channels               
in double              : DataRate                     -- Data rate of waveform being tested
in integer             : BitsPerWaveform              -- Length in bits in the waveform (e.g. 8 for repeating 11110000 data pattern)
in float               : MeasLevelMax                 --  Maximum differential voltage expected in measured waveform (Sets up DIGHS measurement range)
---------------------------------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------------------------------
-- This procedure sets up High Speed Sampler timing and DIDHS timing for Waveform analysis from which Rise Time, Fall Time,
-- Duty Cycle Distortion, and Differential Output Level (with or without pre-emphasis and de-emphasis) can be measured.
--
-- This procedure is a companion to procedure "WaveformMeasurement".
---------------------------------------------------------------------------------------------------------------------
 
local
   double        : WaveformFrequency
   double        : SamplerClkFreq 
   double        : DigitizerClkFreq
   double        : Bits_Per_Waveform                                         -- Number of device bits captured in waveform
   double        : UndersamplingFactor                                       -- Scale factor for undersampling 
   double        : SamplingIntervalBits -- Undersampling interval in terms of bits   
   double        : WaveformSamples      -- Waveform sample size 
   word list[4]  : SampClk
   word list[2]  : SampClkSel = <::>
end_local

body 

    Bits_Per_Waveform    = double(BitsPerWaveform)
    WaveformFrequency    = DataRate/Bits_Per_Waveform
    UndersamplingFactor  = double(integer(WaveformFrequency * 4.0/SAMP_DIGHS_MAX_SAMPLE_CLK_FREQ + 1.0))
    
    
    SamplingIntervalBits = Bits_Per_Waveform * UndersamplingFactor
    WaveformSamples      = double((integer(DataRate/SamplingIntervalBits/SAMP_DIGHS_MAX_DIG_FREQ)+1) * SAMP_DIGHS_WAVEFORM_SAMPLES)
    SamplerClkFreq       = DataRate/SamplingIntervalBits * (WaveformSamples*SamplingIntervalBits/Bits_Per_Waveform )/(WaveformSamples*SamplingIntervalBits/Bits_Per_Waveform+ 1.0)    
    DigitizerClkFreq     = SamplerClkFreq/double(integer(WaveformSamples)) * double(SAMP_DIGHS_WAVEFORM_SAMPLES)
    
    if  SamplerClkFreq * 4.0 >= SAMP_DIGHS_MAX_SAMPLE_CLK_FREQ then
        SamplerDivider      =  4
    else
        SamplerDivider = integer(SAMP_DIGHS_MAX_SAMPLE_CLK_FREQ/2.0/SamplerClkFreq) * 2
        if SamplerDivider > 60 then
             SamplerDivider = 60
        end_if
    end_if
        
    SamplerClkFreq       = SamplerClkFreq * double(SamplerDivider)
    lastSampleClockFreq  = SamplerClkFreq
    
    
    -- PROGRAM SAMPLER CLOCK
    if use_dighsb then
        SampClk             = dighsb_ptc(SampDighsPins)
    else
        SampClk             = dighs_ptc(SampDighsPins)
    end_if
    if (1 in SampClk) or (2 in SampClk) then
       SampClkSel = <:1:>
    end_if
    if (3 in SampClk) or (4 in SampClk) then
       SampClkSel = SampClkSel + <:2:>
    end_if

    GTB_SelectSampleClockOutput ( SampClkSel , DIVIDED_CLOCK )
    SetSampleClkFrequency(SamplerClkFreq )
    SetSamplerDivider(SampDighsPins,SamplerDivider)
    
    -- PROGRAM DIGHS
    ConnectDighsToSamp(SamplerConnection,SampDighsPins )
    if use_dighsb then
        set dighsb SampDighsPins sample rate to DigitizerClkFreq
        if DigitizerClkFreq > 70MHz then
            set dighsb SampDighsPins to max MeasLevelMax/2.0 lpf mhz40
        else_if DigitizerClkFreq >= 50MHz then
            set dighsb SampDighsPins to max MeasLevelMax/2.0 lpf mhz28
        else
            set dighsb SampDighsPins to max MeasLevelMax/2.0 lpf mhz22
            enable dighsb SampDighsPins low sample clock mode
        end_if      
    else
        set dighs chan SampDighsPins sample rate to DigitizerClkFreq
         if DigitizerClkFreq > 100MHz then 
                set dighs chan SampDighsPins to max MeasLevelMax/2.0 lpf mhz65
         else
                set dighs chan SampDighsPins to max MeasLevelMax/2.0 lpf mhz32
         end_if   
     end_if  
endbody
---------------------------------------------------------------------------------------------------------------------
procedure WaveformMeasurement(SampDighsPins,BitsPerWaveform,DataRate,MeasurementScale,preemphasis_expected,StartOnTrigger,Sampler,UseEq,MaxEqualFreq,EqualLength,RiseTime,FallTime,DCD,VOD_P,VOD_D)
--------------------------------------------------------------------------------  
in pin list[MAX_DIGHS] : SampDighsPins         -- Selected DIGHS Channels        
in integer             : BitsPerWaveform       -- Length in bits in the waveform (e.g. 8 for repeating 11110000 data pattern)
in double              : DataRate              -- Data rate of waveform being tested
in  float              : MeasurementScale      -- Scale factor to correct for attenuation in measurement path  
in boolean             : preemphasis_expected  -- Set true if waveform has Preemphasis, otherwise set false
in boolean             : StartOnTrigger        -- Waveform capture starts on detection of sync1 from digital pattern
in multisite integer   : Sampler[MAX_DIGHS]    -- Select GTO_SAMPLER or AUX_SAMPLER
in boolean             : UseEq                 -- Set true to enable equalization of captured waveform otherwise set false
in float               : MaxEqualFreq          -- Frequency of maximum equalization if boolean UseEq is set true
in float               : EqualLength           -- Total trace length in DUT output measurement path to be equalized if boolean UseEq is set true
out multisite double   : RiseTime[MAX_DIGHS]   -- Measured Rise Time
out multisite double   : FallTime[MAX_DIGHS]   -- Measured Fall Time
out multisite double   : DCD[MAX_DIGHS]        -- Measured DutyCycleDistortion
out multisite double   : VOD_P[MAX_DIGHS]      -- Measured  Output Differential Voltage with Premphasis  
out multisite double   : VOD_D[MAX_DIGHS]      -- Measured  Output Differential Voltage with Deemphasis  
---------------------------------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------------------------------
--  This procedure executes the capture of high speed serial data by utilizing the GTO Front End samplers and   
--  the DIGHS digitizer.  The high speed waveform is translated down to a slower waveform with the identical 
--  shape.  This slower waveform is then sampled by the DIGHS connected to the sampler's output.        
--
--  An optional feature of this procedure is software equalization to compensate for printed circuit trace
--  and cable between the device under test and the measuring sampler within the GTO Front End.
--
--  Waveform analysis of the captured data provides measurement of Rise Time, Fall Time, Duty Cycle Distortion, 
-- and Differential Output Level (with or without pre-emphasis and de-emphasis).
--
-- This procedure is a companion to procedure "SetupWaveformMeasurement".
---------------------------------------------------------------------------------------------------------------------
local
  float                : scaled_data_array[SAMP_DIGHS_WAVEFORM_SAMPLES]
  float                : raw_data_array[SAMP_DIGHS_WAVEFORM_SAMPLES]
  double               : SamplingResolution
  double               : ScopeSyncFreq
  double               : VOD_Square
  double               : SquareTime
  float                : SampDighsEqual[200]
  float                : level_threshold = 0.25
  float                : CalArray[500]         -- Waveform calibration array
  integer              : CalArySize
  integer              : SitePtr
  integer              : ChanPtr
  integer              : EqualClampTone
  integer              : SiteCount
  integer              : PortCount
  integer              : WaveformHarmonic
  word list[16]        : SiteList
  multisite double     : results[MAX_DIGHS,6]
  double               : Bif_results[MAX_DIGHS,6]
  boolean              : t 
  integer              : i
  float                : x
  boolean              : use_BIF = true --false       -- Use the Cadence Built-In-Function
  float                : ary2[3*SAMP_DIGHS_WAVEFORM_SAMPLES]
  float                : ary3[3*SAMP_DIGHS_WAVEFORM_SAMPLES]
  multisite float      : results_float[MAX_DIGHS,PAR_ARY_SZ]
  multisite float      : FilteredWaveform[MAX_DIGHS,SAMP_DIGHS_WAVEFORM_SAMPLES]
  word list[MAX_DIGHS] : DigPorts
end_local

body

    PortCount  = len(SampDighsPins)
    SiteList  = get_active_sites
    SiteCount = len(SiteList)
    if use_dighsb then
        DigPorts   = dighsb_ptc(SampDighsPins)
    else
        DigPorts   = dighs_ptc(SampDighsPins)
    end_if 
   WaveformHarmonic = 256/BitsPerWaveform 
   if WaveformHarmonic < 15 then
       WaveformHarmonic = 15
   end_if
   
    if use_dighsb then
        if StartOnTrigger then
            connect dighsb DigPorts trigger to sync2       
            define dighsb DigPorts capture "a" at 0 as SAMP_DIGHS_WAVEFORM_SAMPLES points
            start dighsb DigPorts capture "a" triggered
        else
            define dighsb DigPorts capture "a" at 0 as SAMP_DIGHS_WAVEFORM_SAMPLES points
            start dighsb DigPorts capture "a"
        endif
        wait for dighsb SampDighsPins timeout 100ms into t
        read dighsb DigPorts capture "a" for SAMP_DIGHS_WAVEFORM_SAMPLES points into BifWaveform
    else
         if StartOnTrigger then
             measure dighs chan DigPorts for SAMP_DIGHS_WAVEFORM_SAMPLES points into memory adr 1 trigger on sync2
         else
             measure dighs chan DigPorts for SAMP_DIGHS_WAVEFORM_SAMPLES points into memory adr 1
         end_if
         for SitePtr = 1 to SiteCount do  
            for ChanPtr = 1 to PortCount do
              read  dighs chan DigPorts[(SitePtr -1) * PortCount + ChanPtr] for SAMP_DIGHS_WAVEFORM_SAMPLES points from memory adr 1 into BifWaveform[(SitePtr -1) * PortCount + ChanPtr,1:SAMP_DIGHS_WAVEFORM_SAMPLES]
          end_for
        end_for    
    end_if
    
    for SitePtr = 1 to SiteCount do  
       for ChanPtr = 1 to PortCount do
            if (BitsPerWaveform > 1) and EqualLength >= 0.0 then            
                GTB_CorrectWaveform (DigPorts[word(SitePtr-1)*word(PortCount) + word(ChanPtr)] ,2 - (word(Sampler[SiteList[SitePtr],ChanPtr]) mod 2) , BitsPerWaveform , DataRate , 10.0GHz , 17.5 GHz , BifWaveform[(SitePtr -1) * PortCount + ChanPtr,1:SAMP_DIGHS_WAVEFORM_SAMPLES] , scaled_data_array )    
                BifWaveform[(SitePtr -1) * PortCount + ChanPtr,1:SAMP_DIGHS_WAVEFORM_SAMPLES] = scaled_data_array
            end_if 
        end_for
    end_for
    
        if UseEq  and  abs(EqualLength) >= 0.5 then
            EqualClampTone = integer(MaxEqualFreq/100.0e6)
            SampDighsEqual = LossSpectrum * abs(EqualLength)
            SampDighsEqual[EqualClampTone+1:200] = SampDighsEqual[EqualClampTone]
            if not (CharMode or DisplayMode) then
                calc_wave_ac_params_with_eq(BifWaveform, SampDighsEqual, SAMP_DIGHS_WAVEFORM_SAMPLES, SiteCount * PortCount, BitsPerWaveform, DataRate, WaveformHarmonic, level_threshold, preemphasis_expected, Bif_results)
            else
                char_wave_ac_params_with_eq(BifWaveform, SampDighsEqual, SAMP_DIGHS_WAVEFORM_SAMPLES, SiteCount * PortCount, BitsPerWaveform, DataRate, WaveformHarmonic, level_threshold, preemphasis_expected, Bif_results)
            endif
        else
            if not (CharMode or DisplayMode)then
                calc_wave_ac_params(BifWaveform, SAMP_DIGHS_WAVEFORM_SAMPLES, SiteCount * PortCount, BitsPerWaveform, DataRate, WaveformHarmonic, level_threshold, preemphasis_expected, Bif_results)
            else
                char_wave_ac_params(BifWaveform, SAMP_DIGHS_WAVEFORM_SAMPLES, SiteCount * PortCount, BitsPerWaveform, DataRate, WaveformHarmonic, level_threshold, preemphasis_expected, Bif_results)
            endif
        endif

         
    for SitePtr = 1 to SiteCount do  
        for ChanPtr = 1 to PortCount do
            RiseTime[SiteList[SitePtr],ChanPtr] = Bif_results[(SitePtr -1) * PortCount + ChanPtr,1] 
            FallTime[SiteList[SitePtr],ChanPtr] = Bif_results[(SitePtr -1) * PortCount + ChanPtr,2] 
            DCD[SiteList[SitePtr],ChanPtr]      = Bif_results[(SitePtr -1) * PortCount + ChanPtr,3] - double(BitsPerWaveform/2)/DataRate
            VOD_P[SiteList[SitePtr],ChanPtr]    = Bif_results[(SitePtr -1) * PortCount + ChanPtr,4] * double(MeasurementScale)
            VOD_D[SiteList[SitePtr],ChanPtr]    = Bif_results[(SitePtr -1) * PortCount + ChanPtr,5] * double(MeasurementScale)

            if DisplayMode then   --   **** Set DisplayMode true to observe waveform in Status Display or set false for throughput  ****
                scaled_data_array = BifWaveform[(SitePtr -1) * PortCount + ChanPtr,1:SAMP_DIGHS_WAVEFORM_SAMPLES] * MeasurementScale
                SamplingResolution = double(BitsPerWaveform)/DataRate/double(SAMP_DIGHS_WAVEFORM_SAMPLES)
          
                -- Add above array to status page as plots.
                -- a -g scaled_data_array ; grid
                --**** Enter Numeric values -- scale -mult SamplingResolution -offset 0.0                   
                -- units -x ps
                -- units -y Volts                 
          
                wait(0.0mS)   -- SET BREAKPOINT HERE TO OBSERVE WAVEFORM ON STATUS DISPLAY 

            end_if
        
            --Debug code to trap failures            
            if RiseTime[SiteList[SitePtr],ChanPtr] > 0.3/DataRate or  RiseTime[1,ChanPtr] < 0.0pS then
                wait(0ms)
            end_if
            if FallTime[SiteList[SitePtr],ChanPtr] > 0.3/DataRate or  FallTime[1,ChanPtr] < 0.0pS then
                wait(0ms)
            end_if
        end_for
    end_for
             
    if ScopeMode then
        ScopeSyncFreq = DataRate/double(BitsPerWaveform)/double(integer(DataRate/double(BitsPerWaveform)/500MHz)+1)
        SetSampleClkFrequency(ScopeSyncFreq)
        GTB_SelectSampleClockOutput ( <:1:> , DIVIDED_CLOCK )
        GTB_SetSampleClockDivider ( 1 , 4 )
        wait(1ms)  -- SET BREAKPOINT HERE TO OBSERVE WAVEFORM ON OSCILLOSCOPE
    endif
         
endbody


procedure SetupSpectrumAnalysis ( SamplerConnection , SampDighsPins , DataRate , BitsPerWaveform , MeasLevelMax , NoiseFreqMax )
---------------------------------------------------------------------------------------------------------------------
in multisite integer   : SamplerConnection[MAX_DIGHS] -- AUX_IN_ODD_CHAN, DATA_IN_ODD_CHAN, AUX_IN_EVEN_CHAN or DATA_IN_EVEN_CHAN
in pin list[MAX_DIGHS] : SampDighsPins                -- Selected DIGHS Channels                
in double              : DataRate                     -- Data rate of waveform being tested
in  integer            : BitsPerWaveform              -- Length in bits in the waveform (e.g. 2 for repeating 10 data pattern)
in float               : MeasLevelMax                 -- Maximum differential voltage expected in measured waveform (Sets up DIGHS measurement range)
in float               : NoiseFreqMax                 -- High Noise frequency Low Pass cutoff ( Selects DIGHS anti-aliasing filter -- no filter if > 65MHz,
                                                      -- 65MHz  filter if <= 65MHz and > 32MHz,  or 32MHz filter if < 32MHz)
---------------------------------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------------------------------
-- This procedure sets up High Speed Sampler timing and DIDHS timing for spectrum analysis for testing and measureing
-- injected jitter tones or for measure random jitter with a phase noise technique.  Input waveforms for using this 
-- spectrum analysis must be square, such as a repeating 1010...10 data pattern oe a repeating 11001100...1100 data pattern.
--
-- The resultant spectrum has the fundamental frequency of the waveform down-converted into the spectrum's first bin.
-- Resolution Bandwidth of the resultant spectrum is defined by input parameter "NoiseFreqMax", where the RBW is 3.75KHz 
-- if the spectrum, "NoiseFreqMax", is less than 30.72MHz, otherwise the RSB of the spectrum is 7.5KHz
---------------------------------------------------------------------------------------------------------------------
 
local double            : WaveformFrequency
local double            : SamplerClkFreq 
local double            : SampleFrequency
local double            : DigitizerClkFreq
local double            : Bits_Per_Waveform                                         -- Number of device bits captured in waveform
local double            : UndersamplingFactor                                       -- Scale factor for undersampling 
local double            : L_O_Freq 
local double            : FreqBinSize
local float             : MaxBinSize 
local integer           : SamplerDivider
local word list[4]      : SampClk
local word list[2]      : SampClkSel = <::>
body

    Bits_Per_Waveform = double ( BitsPerWaveform )
    WaveformFrequency = DataRate / Bits_Per_Waveform 
    MaxBinSize        = SAMP_DIGHS_SPECTRUM_CLK_FREQ / SAMP_DIGHS_SPECTRUM_SAMPLES
              
    if NoiseFreqMax <= ( SAMP_DIGHS_SPECTRUM_CLK_FREQ / 4.0 - MaxBinSize ) then
        DigitizerClkFreq = SAMP_DIGHS_SPECTRUM_CLK_FREQ / 2.0
    else 
        DigitizerClkFreq = SAMP_DIGHS_SPECTRUM_CLK_FREQ
    endif
    
    FreqBinSize         = DigitizerClkFreq/double(SAMP_DIGHS_SPECTRUM_SAMPLES)
    L_O_Freq            = WaveformFrequency - FreqBinSize
    UndersamplingFactor = double(integer(L_O_Freq * 4.0/SAMP_DIGHS_MAX_SAMPLE_CLK_FREQ + 1.0))
    SampleFrequency     = L_O_Freq/UndersamplingFactor
    if  L_O_Freq * 4.0 >= SAMP_DIGHS_MAX_SAMPLE_CLK_FREQ then
        SamplerDivider      =  4
    else
        SamplerDivider = integer(SAMP_DIGHS_MAX_SAMPLE_CLK_FREQ/2.0/SampleFrequency) * 2
        if SamplerDivider > 60 then
             SamplerDivider = 60
        end_if
    end_if
    if use_dighsb then
        SampClk             = dighsb_ptc(SampDighsPins)
    else
        SampClk             = dighs_ptc(SampDighsPins)
    end_if
    if (1 in SampClk) or (2 in SampClk) then
       SampClkSel = <:1:>
    end_if
    if (3 in SampClk) or (4 in SampClk) then
       SampClkSel = SampClkSel + <:2:>
    end_if

    GTB_SelectSampleClockOutput ( SampClkSel , DIVIDED_CLOCK )
    SamplerClkFreq = double(SamplerDivider) * SampleFrequency      
    -- PROGRAM SAMPLER CLOCK
    SetSampleClkFrequency(SamplerClkFreq )
    SetSamplerDivider(SampDighsPins,SamplerDivider)
    
    -- PROGRAM DIGHS
    ConnectDighsToSamp(SamplerConnection,SampDighsPins )         
    if use_dighsb then
        set dighsb SampDighsPins sample rate to DigitizerClkFreq
        set dighsb SampDighsPins to max MeasLevelMax/2.0 lpf NoiseFreqMax 
    else
        set dighs chan SampDighsPins sample rate to DigitizerClkFreq
        set dighs chan SampDighsPins to max MeasLevelMax/2.0 lpf NoiseFreqMax 
    end_if

end_body
--------------------------------------------------------------------------------

procedure SetupDdjEyePattern(SamplerConnection,SampDighsPins,DataRate,BitsPerWaveform,MeasLevelMax,DecimationFactor)
in multisite integer   : SamplerConnection[MAX_DIGHS]  -- "DataInOdd", "DataInEven", AltInOdd" or "AltInEven"
in pin list[MAX_DIGHS] : SampDighsPins                 -- Selected DIGHS Channels            
in double              : DataRate                      -- Data rate of waveform being tested
in integer             : BitsPerWaveform               -- Length in bits in the waveform (e.g. 127 for prbs2^7-1)
in float               : MeasLevelMax                  --  Maximum differential voltage expected in measured waveform (Sets up DIGHS measurement range)
out integer            : DecimationFactor              -- Another Scale factor for undersampling ( This parameter is to be passed to procedure DdjEyePattern
---------------------------------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------------------------------
-- This procedure provides the means to execute data dependent jitter testing via the GTO Front End high speed sampler.
-- The procedure is designed to set up the capture a waveform rich in deterministic jitter.  From this pattern
-- the P-P deterministic jitter is derived.  Random Jitter is filtered out of the waveform 
-- being captured, to produce an Eye pattern test of just the deterministic jitter.  The recommended 
-- pattern for use with this procedure is a between 20 bits and 160 bits long.  This procedure is a
-- companion to procedure "DdjEyePattern".
--
-- After this procedure is executed to set up the samplers it will be necessary
-- To execute "DdjEyePattern" to capture and process the waveform to obtain data 
-- dependent jitter as well as an eye pattern.
---------------------------------------------------------------------------------------------------------------------  
const EYE_SAMPLE_OFFSET_FREQ    = 4.0 kHz

local lword                     : WaveformSamples
local double                    : WaveformFrequency
local double                    : SampleFrequency
local double                    : SamplerClkFreq 
local double                    : Bits_Per_Waveform                                         -- Number of device bits captured in waveform
local double                    : UndersamplingFactor                                       -- Scale factor for undersampling 
local integer                   : SamplerDivider
local integer                   : BPW_Scale
local word list[4]              : SampClk
local word list[2]              : SampClkSel = <::>
local integer                   : SamplesPerBit

body
    if BitsPerWaveform > 160 then
       SamplesPerBit = SAMP_DIGHS_ALT_EYE_SAMPS_PER_BIT
    else
        SamplesPerBit  = SAMP_DIGHS_EYE_SAMPLES_PER_BIT
    end_if    
    
    if (DataRate < 1.0GHz) and (SamplesPerBit * BitsPerWaveform < 20000) then
        BPW_Scale = 20000/SamplesPerBit/BitsPerWaveform
    else   
        BPW_Scale = 1
    end_if

    WaveformSamples         = lword ( BitsPerWaveform ) * lword(SamplesPerBit * BPW_Scale)
    Bits_Per_Waveform       = double ( BitsPerWaveform )
    WaveformFrequency       = DataRate / Bits_Per_Waveform
                        
    UndersamplingFactor     = WaveformFrequency / SAMP_DIGHS_MAX_DIG_FREQ
    if UndersamplingFactor  > 1.0 then
        UndersamplingFactor = double ( integer ( UndersamplingFactor + 1.0 ) )
        SampleFrequency     = WaveformFrequency / UndersamplingFactor
        DecimationFactor    = 1
        SamplerDivider      = 5 
    elseif ( WaveformFrequency / SAMP_DIGHS_MIN_DIG_FREQ) >= 1.0 then
        UndersamplingFactor = 1.0
        SampleFrequency     = WaveformFrequency
        SamplerDivider      = integer ( SAMP_DIGHS_MAX_SAMPLE_CLK_FREQ / 2.0 / SampleFrequency )              
        DecimationFactor    = 1
        if SamplerDivider   > 30 then  
            SamplerDivider  = 30
        endif
    else
        DecimationFactor    = integer ( SAMP_DIGHS_MIN_DIG_FREQ / WaveformFrequency ) + 1 
        SampleFrequency     = WaveformFrequency * double ( DecimationFactor )     
        UndersamplingFactor = 1.0
        SamplerDivider      = 15
    endif
    
    SamplerDivider = 2 * SamplerDivider  
    SampleFrequency = SampleFrequency * (double(WaveformSamples) * UndersamplingFactor)/ (double(WaveformSamples)*UndersamplingFactor + 1.0/double(DecimationFactor))           
    SamplerClkFreq = double(SamplerDivider) * SampleFrequency      
        
      
     -- PROGRAM SAMPLER CLOCK      
    if use_dighsb then
        SampClk             = dighsb_ptc(SampDighsPins)
    else
        SampClk             = dighs_ptc(SampDighsPins)
    end_if
    if (1 in SampClk) or (2 in SampClk) then
       SampClkSel = <:1:>
    end_if
    if (3 in SampClk) or (4 in SampClk) then
       SampClkSel = SampClkSel + <:2:>
    end_if

    GTB_SelectSampleClockOutput ( SampClkSel , DIVIDED_CLOCK )
    SetSampleClkFrequency(SamplerClkFreq )
    SetSamplerDivider(SampDighsPins,SamplerDivider)     
    
       
    -- PROGRAM DIGHS
    ConnectDighsToSamp(SamplerConnection,SampDighsPins )
    if use_dighsb then
         set dighsb SampDighsPins sample rate to SampleFrequency 
         set dighsb SampDighsPins to max MeasLevelMax/2.0 lpf SampleFrequency * 0.39
         if SampleFrequency < 50MHz then
             enable dighsb SampDighsPins low sample clock mode
         end_if
    else
         set dighs chan SampDighsPins sample rate to SampleFrequency
         set dighs chan SampDighsPins to max MeasLevelMax/2.0 lpf float(SampleFrequency * 0.4)
    end_if

end_body
---------------------------------------------------------------------------------------------------------------------
procedure SetupSubRateJitterMeasurement(SamplerConnection,SampDighsPins,DataRate,BitsPerWaveform,MeasLevelMax) 
in multisite integer   : SamplerConnection[MAX_DIGHS]  -- "DataInOdd", "DataInEven", AltInOdd" or "AltInEven"
in pin list[MAX_DIGHS] : SampDighsPins                 -- Selected DIGHS Channels               
in double              : DataRate                      -- Data rate of waveform being tested
in  integer            : BitsPerWaveform               -- Length in bits in the waveform (e.g. 2 for repeating 10 data pattern)
in float               : MeasLevelMax                  --  Maximum differential voltage expected in measured waveform (Sets up DIGHS measurement range)
---------------------------------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------------------------------
-- This procedure sets up time for the High Speed Sampler and the DIGHS for measurement of Sub-Rate peridic jitter,
-- where the jitter tone is an integer division of the dater rate.  This jitter is typically associated with a DUT's 
-- PLL clock divider.  This proicedure is a companion to procedure "SubRateJitterMeasurement". 
--
-- The input waveform required for Sub-Rate Jitter measurement must be a continuously repeating square pattern such as a
-- 1010...10 data pattern or a 11001100...1100 data pattern.
---------------------------------------------------------------------------------------------------------------------
  
local
   double        : WaveformFrequency
   double        : SamplerClkFreq 
   double        : SampleFrequency
   double        : Bits_Per_Waveform                                         -- Number of device bits captured in waveform
   double        : UndersamplingFactor                                       -- Scale factor for undersampling 
   double        : L_O_Freq 
   double        : FreqBinSize
   integer       : SamplerDivider
   word list[4]  : SampClk
   word list[2]  : SampClkSel = <::>
end_local

body

    Bits_Per_Waveform        = double(BitsPerWaveform)
    WaveformFrequency        = DataRate/Bits_Per_Waveform 
    
        UndersamplingFactor     = WaveformFrequency/SAMP_DIGHS_MAX_DIG_FREQ
        if UndersamplingFactor > 1.0 then
            UndersamplingFactor = double(integer(UndersamplingFactor + 1.0))
            SampleFrequency     = WaveformFrequency/UndersamplingFactor
            SamplerDivider      = 5 
        else
            UndersamplingFactor = 1.0
            SampleFrequency     = WaveformFrequency
            SamplerDivider      = integer(SAMP_DIGHS_MAX_SAMPLE_CLK_FREQ/2.0/SampleFrequency)            
            if SamplerDivider > 30 then  
                SamplerDivider  = 30
            end_if
        end_if
        
        SamplerDivider = 2 * SamplerDivider  
        L_O_Freq          = SampleFrequency * double(SAMP_DIGHS_SUB_RATE_SAMPLES) * UndersamplingFactor/ (double(SAMP_DIGHS_SUB_RATE_SAMPLES) * UndersamplingFactor + double(CARRIER_TONE_SUB_RATE_MEAS))
        SampleFrequency    = L_O_Freq/UndersamplingFactor
        FreqBinSize        = WaveformFrequency/double(CARRIER_TONE_SUB_RATE_MEAS)
   
        SamplerClkFreq = double(SamplerDivider) * SampleFrequency      
    
       -- PROGRAM SAMPLER CLOCK
    if use_dighsb then
        SampClk             = dighsb_ptc(SampDighsPins)
    else
        SampClk             = dighs_ptc(SampDighsPins)
    end_if
    if (1 in SampClk) or (2 in SampClk) then
       SampClkSel = <:1:>
    end_if
    if (3 in SampClk) or (4 in SampClk) then
       SampClkSel = SampClkSel + <:2:>
    end_if

    GTB_SelectSampleClockOutput ( SampClkSel , DIVIDED_CLOCK )
      SetSampleClkFrequency(SamplerClkFreq )
      SetSamplerDivider(SampDighsPins,SamplerDivider)
      
      -- PROGRAM DIGHS
      ConnectDighsToSamp(SamplerConnection,SampDighsPins )
    if use_dighsb then
        set dighsb SampDighsPins sample rate to SampleFrequency
        set dighsb SampDighsPins to max MeasLevelMax/2.0 lpf mhz22
    else
         set dighs chan SampDighsPins sample rate to SampleFrequency
         set dighs chan SampDighsPins to max MeasLevelMax/2.0 lpf mhz32
    end_if

end_body

procedure Direct_R_J_Measure(SampDighsPins,BitsPerWaveform,DataRate,StartOnTrigger,RandomJitter)
--------------------------------------------------------------------------------
in pin list[MAX_DIGHS] : SampDighsPins             -- Selected DIGHS Channels             
in integer             : BitsPerWaveform           -- Length in bits in the waveform (e.g. 2 for repeating 10 pattern)
in double              : DataRate                  -- Data rate of waveform being tested
in boolean             : StartOnTrigger            -- Waveform capture starts on detection of sync1 from digital pattern
out multisite double   : RandomJitter[MAX_DIGHS]   -- Measured Random Jitter (RMS) 
---------------------------------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------------------------------  
-- This procedure captures and processes square waveforms from samplers 
-- to provide a Random Jitter measurements.  Note: Waveform must 
--
-- In order to use this procedure, it is necessary to first execute procedure
-- "SetupWaveformMeasurement" to set up the GTO front end samplers for the measurement.
-- The data pattern being captured must be a square pattern such as a repeating 1010...10
-- pattern or a repeating 11001100...1100 data pattern.  Random jitter measurement is  
-- outputted as an RMS (Root Mean Square) value.
---------------------------------------------------------------------------------------------------------------------  
local
  multisite float      : Waveform[MAX_DIGHS,SAMP_DIGHS_WAVEFORM_SAMPLES]
  multisite float      : Unfiltered_Waveform[MAX_DIGHS,SAMP_DIGHS_WAVEFORM_SAMPLES]
  float                : UnfilteredWaveform[SAMP_DIGHS_WAVEFORM_SAMPLES]
  float                : CleanWaveform[SAMP_DIGHS_WAVEFORM_SAMPLES]
  float                : level_threshold = 0.2
  double               : SamplingResolution
  double               : ScopeSyncFreq
  integer              : ChanPtr
  integer              : PortCount
  integer              : SitePtr
  integer              : SiteCount
  word list[16]        : SiteList
  multisite boolean    : t [ 16]
  double               : BifRandomJitter[MAX_DIGHS]   -- Measured Random Jitter (RMS) 
end_local
body
  
     PortCount  = len(SampDighsPins)
     SiteList   = get_active_sites
     SiteCount  = len(SiteList)
     
     if use_dighsb then
        if StartOnTrigger then
            connect dighsb SampDighsPins trigger to sync2       
            define dighsb SampDighsPins capture "a" at 0 as SAMP_DIGHS_WAVEFORM_SAMPLES points
            start dighsb SampDighsPins capture "a" triggered
            wait for dighsb SampDighsPins timeout 100ms into  t
            read dighsb SampDighsPins capture "a" for SAMP_DIGHS_WAVEFORM_SAMPLES points into Waveform
        else
            define dighsb SampDighsPins capture "a" at 0 as SAMP_DIGHS_WAVEFORM_SAMPLES points
            start dighsb SampDighsPins capture "a"
            wait for dighsb SampDighsPins timeout 1000ms into  t
            read dighsb SampDighsPins capture "a" for SAMP_DIGHS_WAVEFORM_SAMPLES points into Waveform
        endif
    else
         if StartOnTrigger then
             measure dighs chan SampDighsPins for SAMP_DIGHS_WAVEFORM_SAMPLES points into memory adr 1 trigger on sync2
             read  dighs chan SampDighsPins for SAMP_DIGHS_WAVEFORM_SAMPLES points from memory adr 1 into Waveform
         else
             measure dighs chan SampDighsPins for SAMP_DIGHS_WAVEFORM_SAMPLES points into Waveform
         end_if
    end_if

    for SitePtr = 1 to SiteCount do  
        for ChanPtr = 1 to PortCount do
            BifWaveform[(SitePtr -1) * PortCount + ChanPtr,1:SAMP_DIGHS_WAVEFORM_SAMPLES] = Waveform[SiteList[SitePtr],ChanPtr,1:SAMP_DIGHS_WAVEFORM_SAMPLES]
        end_for
    end_for

    if (CharMode or DisplayMode) then
        Unfiltered_Waveform = Waveform
        char_random_jitter(BifWaveform,SAMP_DIGHS_WAVEFORM_SAMPLES,SiteCount * PortCount,BitsPerWaveform,DataRate,15,level_threshold,BifRandomJitter)    
    else
        calc_random_jitter(BifWaveform,SAMP_DIGHS_WAVEFORM_SAMPLES,SiteCount * PortCount,BitsPerWaveform,DataRate,15,level_threshold,BifRandomJitter)
    endif

    for SitePtr = 1 to SiteCount do  
        for ChanPtr = 1 to PortCount do
            RandomJitter[SitePtr,ChanPtr] = BifRandomJitter[(SitePtr -1) * PortCount + ChanPtr]
        end_for
    end_for

   if DisplayMode then   --   **** Set DisplayMode true to observe CleanWaveform and UnfilteredWaveform in Status Display ****
         for SitePtr = 1 to SiteCount do  
             for ChanPtr = 1 to PortCount do
                     CleanWaveform = BifWaveform[(SitePtr -1) * PortCount + ChanPtr,1:SAMP_DIGHS_WAVEFORM_SAMPLES]
                     UnfilteredWaveform = Unfiltered_Waveform[SiteList[SitePtr],ChanPtr,1:SAMP_DIGHS_WAVEFORM_SAMPLES]
                     SamplingResolution = double(BitsPerWaveform)/DataRate/double(SAMP_DIGHS_WAVEFORM_SAMPLES)

                          -- Add CleanWaveform and UnfilteredWaveform to status page as plots.
                          -- a -g CleanWaveform ; grid
                          -- a -g UnfilteredWaveform  -t scatter
                                  --**** Enter Numeric values -- scale -mult SamplingResolution -offset 0.0                   
                          -- units -x ps
                          -- units -y Volts                 

                    wait(0mS)   -- SET BREAKPOINT HERE TO OBSERVE WAVEFORM ON STATUS DISPLAY
           end_for
       end_for
   
    end_if

      if ScopeMode then
      
            ScopeSyncFreq = DataRate/double(BitsPerWaveform)/double(integer(DataRate/double(BitsPerWaveform)/500MHz)+1)
            SetSampleClkFrequency(ScopeSyncFreq)
            wait(1ms)  -- SET BREAKPOINT HERE TO OBSERVE WAVEFORM ON OSCILLOSCOPE
      end_if

end_body
procedure SpectrumAnalysis(SampDighsPins,BitsPerWaveform,DataRate,StartOnTrigger,MeasLevelMax,NoiseFreqMin,NoiseFreqHP_Corner,NoiseFreqMax,NumberOfTones, RandomJitter,JitterTones,PP_Jitter)
--------------------------------------------------------------------------------  
in pin list[MAX_DIGHS] : SampDighsPins                        -- Selected DIGHS Channels           
in integer             : BitsPerWaveform                      -- Length in bits in the waveform (e.g. 2 for repeating 10 data pattern)
in double              : DataRate                             -- Data rate of waveform being tested
in boolean             : StartOnTrigger                       -- Waveform capture starts on detection of sync1 from digital pattern
in float               : MeasLevelMax                         -- Maximum differential voltage expected in measured waveform 
in float               : NoiseFreqMin                         -- Low Noise frequency High Pass Brick wall cutoff 
in float               : NoiseFreqHP_Corner                   -- Low Noise frequency High Pass 3dB cutoff
in float               : NoiseFreqMax                         -- High Noise frequency Low Pass cutoff 
in integer             : NumberOfTones                        -- Number of periodic jitter tones frequencies to be processed
out multisite double   : RandomJitter[MAX_DIGHS]              -- Random Jitter measurement (RMS) (Periodic Jitter Tones removed from measurement)
out multisite float    : JitterTones[MAX_DIGHS,MAX_NUM_TONES] -- Periodic Jitter Tone Frequencies
out multisite float    : PP_Jitter[MAX_DIGHS,MAX_NUM_TONES]   -- Periodic Tone's Jitter P-P  
---------------------------------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------------------------------
-- This procedure captures a down-converted spectrum from a square waveform, such as a repeating 1010...10 pattern or 
-- a repeating 11001100...1100 pattern, with the High Speed Sampler and DIGHS. The spectrum data provides the means for
-- testing and measureing injected jitter tones or for measure random jitter using a phase noise technique.
--
-- The resultant spectrum has the fundamental frequency of the waveform down-converted into the spectrum's first bin.
-- Resolution Bandwidth of the resultant spectrum is defined by input parameter "NoiseFreqMax", where the RBW is 3.75KHz 
-- if the spectrum, "NoiseFreqMax", is less than 30.72MHz, otherwise the RSB of the spectrum is 7.5KHz.
--
-- This procedure is a companion to procedure "SetupSpectrumAnalysis".
---------------------------------------------------------------------------------------------------------------------  

local double               : FreqBinSize
local float                : SpectrumFft [ MAX_DIGHS , SAMP_DIGHS_SPECTRUM_SAMPLES / 2 + 1 ]
local integer              : i
local double               : results[ MAX_DIGHS , 3 ]
local multisite double     : PeakCarrierLevel [ MAX_DIGHS ] 
local multisite double     : RJ_PJ_Rms [ MAX_DIGHS ] 
local float                : Spectrum [ SAMP_DIGHS_SPECTRUM_SAMPLES / 2 + 1 ]
local float                : FftSpectrum[ SAMP_DIGHS_SPECTRUM_SAMPLES ]
local float                : wave [ SAMP_DIGHS_SPECTRUM_SAMPLES ]
local float                : MaxBinSize
local double               : ScopeSyncFreq
local integer              : ChanPtr
local integer              : PortCount
local  integer             : SitePtr
local  integer             : SiteCount
local  integer             : TonePtr
local  word list[16]       : SiteList
local word list[MAX_DIGHS] : DigPorts
local boolean              : t 
local float                : BifJitterTones[MAX_DIGHS,MAX_NUM_TONES] -- Periodic Jitter Tone Frequencies
local float                : BifPP_Jitter[MAX_DIGHS,MAX_NUM_TONES]   -- Periodic Tone's Jitter P-P  
body   
    if use_dighsb then
        DigPorts   = dighsb_ptc(SampDighsPins)
    else
        DigPorts   = dighs_ptc(SampDighsPins)
    end_if 
  
    if use_dighsb then
        DigPorts   = dighsb_ptc(SampDighsPins)
    else
        DigPorts   = dighs_ptc(SampDighsPins)
    end_if 
    PortCount  = len( SampDighsPins )
    SiteList   = get_active_sites
    SiteCount  = len(SiteList)
    MaxBinSize = SAMP_DIGHS_SPECTRUM_CLK_FREQ/SAMP_DIGHS_SPECTRUM_SAMPLES

    if use_dighsb then
        if StartOnTrigger then
            connect dighsb DigPorts trigger to sync2       
            define dighsb DigPorts capture "a" at 0 as SAMP_DIGHS_SPECTRUM_SAMPLES points
            start dighsb DigPorts capture "a" triggered
        else
            define dighsb DigPorts capture "a" at 0 as SAMP_DIGHS_SPECTRUM_SAMPLES points
            start dighsb DigPorts capture "a"
        endif
        wait for dighsb DigPorts timeout 100ms into  t
        read dighsb DigPorts capture "a" for SAMP_DIGHS_SPECTRUM_SAMPLES points into BifSpectrumData

        -- a -g BifSpectrumData ; grid
        wait(0ms)

    else
        if StartOnTrigger then
             measure dighs chan DigPorts for SAMP_DIGHS_SPECTRUM_SAMPLES points into memory adr 1 trigger on sync2
         else
             measure dighs chan DigPorts for SAMP_DIGHS_SPECTRUM_SAMPLES points into memory adr 1
         end_if
         for SitePtr = 1 to SiteCount do  
            for ChanPtr = 1 to PortCount do
               read  dighs chan DigPorts[(SitePtr -1) * PortCount + ChanPtr] for SAMP_DIGHS_SPECTRUM_SAMPLES points from memory adr 1 into BifSpectrumData[(SitePtr -1) * PortCount + ChanPtr,1:SAMP_DIGHS_SPECTRUM_SAMPLES]
            end_for
        end_for    
    end_if

    if NoiseFreqMax <= (SAMP_DIGHS_SPECTRUM_CLK_FREQ/4.0  - MaxBinSize) then
        FreqBinSize  = SAMP_DIGHS_SPECTRUM_CLK_FREQ/2.0/double(SAMP_DIGHS_SPECTRUM_SAMPLES)
    else 
        FreqBinSize  = SAMP_DIGHS_SPECTRUM_CLK_FREQ/double(SAMP_DIGHS_SPECTRUM_SAMPLES)
    endif
    
    for SitePtr = 1 to SiteCount do  
      for ChanPtr = 1 to PortCount do
        wave = BifSpectrumData[(SitePtr -1) * PortCount + ChanPtr,1:SAMP_DIGHS_SPECTRUM_SAMPLES]    
        FftSpectrum = fft(BifSpectrumData[(SitePtr -1) * PortCount + ChanPtr,1:SAMP_DIGHS_SPECTRUM_SAMPLES])

        -- a -g FftSpectrum ; grid
        wait(0ms)
        
         if NoiseFreqMax <= (SAMP_DIGHS_SPECTRUM_CLK_FREQ/4.0  - MaxBinSize) then
             if SpectrumCal25[DigPorts[(SitePtr -1) * PortCount + ChanPtr],3] <> 0.0 then
                 FftSpectrum = FftSpectrum * SpectrumCal25[DigPorts[(SitePtr -1) * PortCount + ChanPtr],1:SAMP_DIGHS_SPECTRUM_SAMPLES]
             end_if
         else
             if SpectrumCal51[DigPorts[(SitePtr -1) * PortCount + ChanPtr],3] <> 0.0 then
                 FftSpectrum = FftSpectrum * SpectrumCal51[DigPorts[(SitePtr -1) * PortCount + ChanPtr],1:SAMP_DIGHS_SPECTRUM_SAMPLES]
             end_if
         endif
        BifSpectrumData[(SitePtr -1) * PortCount + ChanPtr,1:SAMP_DIGHS_SPECTRUM_SAMPLES] = inverse_fft(FftSpectrum)
      end_for
    end_for

    -- a -g BifSpectrumData ; grid
    
    if (CharMode or DisplayMode) then
        char_jitter_spectrum(BifSpectrumData,SAMP_DIGHS_SPECTRUM_SAMPLES,SiteCount * PortCount,BitsPerWaveform,DataRate,MeasLevelMax,NoiseFreqMin,NoiseFreqHP_Corner,NoiseFreqMax,FreqBinSize,results,NumberOfTones,BifJitterTones,BifPP_Jitter,SpectrumFft)             
        SpectrumRef = SpectrumFft[1,1:SAMP_DIGHS_SPECTRUM_SAMPLES/2 +1]
    else
        calc_jitter_spectrum(BifSpectrumData,SAMP_DIGHS_SPECTRUM_SAMPLES,SiteCount * PortCount,BitsPerWaveform,DataRate,MeasLevelMax,NoiseFreqMin,NoiseFreqHP_Corner,NoiseFreqMax,FreqBinSize,results,NumberOfTones,BifJitterTones,BifPP_Jitter)             
    endif
    
    -- a -g SpectrumFft ; grid
    -- a -g SpectrumRef ; grid
    
--     for i=1 to 10 do
--         println(stdout, BifJitterTones[1,i]!e:15:6, " Hz: ", BifPP_Jitter[1,i]*1.0E12:8:2, " ps", " (",BifPP_Jitter[1,i]*float(DataRate), " UIPP)"  )
--     end_for
--     println(stdout,"RMS jitter w/o periodic = ", results[1,1]*1.0E12, "ps")
--     println(stdout,"@n")
--     wait(0ms)
   
    for SitePtr = 1 to SiteCount do  
      for ChanPtr = 1 to PortCount do        
        RandomJitter [SiteList[SitePtr], ChanPtr ]     = results [(SitePtr -1) * PortCount + ChanPtr , 1 ]
        PeakCarrierLevel [SiteList[SitePtr], ChanPtr ] = results [(SitePtr -1) * PortCount + ChanPtr , 2 ]
        RJ_PJ_Rms [SiteList[SitePtr], ChanPtr ]        = results [(SitePtr -1) * PortCount + ChanPtr , 3 ]
        for TonePtr = 1 to NumberOfTones do
            JitterTones[SiteList[SitePtr],ChanPtr,TonePtr] = BifJitterTones[(SitePtr -1) * PortCount + ChanPtr,TonePtr]
            PP_Jitter[SiteList[SitePtr],ChanPtr,TonePtr]   = BifPP_Jitter[(SitePtr -1) * PortCount + ChanPtr,TonePtr]
        end_for
        if DisplayMode then   --   **** Set DisplayMode true to observe Spectrum in Status Display ****        
            Spectrum = SpectrumFft[(SitePtr -1) * PortCount + ChanPtr,1:SAMP_DIGHS_SPECTRUM_SAMPLES/2 +1]
            wave     = BifSpectrumData[(SitePtr -1) * PortCount + ChanPtr,1:SAMP_DIGHS_SPECTRUM_SAMPLES]
                -- a -g  Spectrum; grid   
                    --**** Enter Numeric values -- scale -mult FreqBinSize  -offset 0.0
                    --e.g.  scale -mult 3.1250e+3             
                -- units -x MHz
                -- units -y dB                
                --ScopeSyncFreq = (double(BitsPerWaveform)/DataRate)/double(SAMP_DIGHS_SPECTRUM_SAMPLES)

            wait(0mS)   -- SET BREAKPOINT HERE TO OBSERVE WAVEFORM ON STATUS DISPLAY
        endif
      end_for 
    end_for 

    if ScopeMode then
        ScopeSyncFreq = DataRate/double(BitsPerWaveform)/double(integer(DataRate/double(BitsPerWaveform)/500MHz)+1)
        SetSampleClkFrequency(ScopeSyncFreq)
        wait(1ms)  -- SET BREAKPOINT HERE TO OBSERVE WAVEFORM ON OSCILLOSCOPE
    endif

end_body
--------------------------------------------------------------------------------
procedure SubRateJitterMeasurement(SampDighsPins,BitsPerWaveform,DataRate,StartOnTrigger,MeasLevelMax,JitterTone,PPJitter)
--------------------------------------------------------------------------------  
in pin list[MAX_DIGHS] : SampDighsPins         -- Selected DIGHS Channels              
in integer             : BitsPerWaveform       -- Length in bits in the waveform (e.g. 2 for repeating 10 data pattern)
in double              : DataRate              -- Data rate of waveform being tested
in boolean             : StartOnTrigger        -- Waveform capture starts on detection of sync1 from digital pattern
in float               : MeasLevelMax          -- Maximum differential voltage expected in measured waveform 
out multisite double   : JitterTone[MAX_DIGHS] -- Frequency of Sub-Rate Jitter
out multisite double   : PPJitter[MAX_DIGHS]   -- Amplitude of Sub-Rate Jitter P-P  
---------------------------------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------------------------------
-- This procedure captures a spectrum from a square waveform, such as a continuously repeating 1010...10 data pattern or 
-- 11001100...1100 data pattern.  The spectrum captured with the High Speed Sampler and the DIGHS places the carrier or
-- fundamental frequency of the waveform in the spectrum's 320th forrier harmonic.  Any Sub-Rate jitter, which is a 
-- jitter tones that is an integer division of the data rate, is measured.  This jitter is typically associated with a DUT's 
-- PLL clock divider.  This proicedure is a companion to procedure "SetupSubRateJitterMeasurement". 
--
-- This procedure's output data includes both the frequency and amplitude of the Sub-Rate jitter tone
----------------------------------------------------------------------------------------------------------------------  
local
  double               : FreqBinSize
  float                : SpectrumFft[MAX_DIGHS,SAMP_DIGHS_SPECTRUM_SAMPLES/2 +1]
  double               : results[MAX_DIGHS,2]
  boolean              : t 
  float                : Spectrum[SAMP_DIGHS_SPECTRUM_SAMPLES/2 +1]
  integer              : ChanPtr
  integer              : PortCount
  integer              : SitePtr
  integer              : SiteCount
  word list[16]        : SiteList
 word list[MAX_DIGHS]  : DigPorts
end_local
body
    if use_dighsb then
        DigPorts   = dighsb_ptc(SampDighsPins)
    else
        DigPorts   = dighs_ptc(SampDighsPins)
    end_if 
    PortCount  = len(SampDighsPins)
    SiteList   = get_active_sites
    SiteCount  = len(SiteList)

    if use_dighsb then
        if StartOnTrigger then
            connect dighsb DigPorts trigger to sync2       
            define dighsb DigPorts capture "a" at 0 as SAMP_DIGHS_SUB_RATE_SAMPLES points
            start dighsb DigPorts capture "a" triggered
        else
            define dighsb DigPorts capture "a" at 0 as SAMP_DIGHS_SUB_RATE_SAMPLES points
            start dighsb DigPorts capture "a"
        endif
        wait for dighsb DigPorts timeout 100ms into  t
        read dighsb DigPorts capture "a" for SAMP_DIGHS_SUB_RATE_SAMPLES points into BifSubRateJitData
    else
       if StartOnTrigger then
           measure dighs chan DigPorts for SAMP_DIGHS_SUB_RATE_SAMPLES points into memory adr 1 trigger on sync2
       else
           measure dighs chan DigPorts for SAMP_DIGHS_SUB_RATE_SAMPLES points into memory adr 1
       end_if
       for SitePtr = 1 to SiteCount do  
          for ChanPtr = 1 to PortCount do
            read  dighs chan DigPorts[(SitePtr -1) * PortCount + ChanPtr] for SAMP_DIGHS_SUB_RATE_SAMPLES points from memory adr 1 into BifSubRateJitData[(SitePtr -1) * PortCount + ChanPtr,1:SAMP_DIGHS_SUB_RATE_SAMPLES]
        end_for
      end_for    
    
    end_if

    calc_subrate_jitter(BifSubRateJitData,SAMP_DIGHS_SUB_RATE_SAMPLES,SiteCount * PortCount,DataRate,CARRIER_TONE_SUB_RATE_MEAS,MeasLevelMax,SpectrumFft,results)


     FreqBinSize = DataRate/double(BitsPerWaveform)/double(CARRIER_TONE_SUB_RATE_MEAS)


      for SitePtr = 1 to SiteCount do  
         for ChanPtr = 1 to PortCount do

             JitterTone[SiteList[SitePtr],ChanPtr]  = results[(SitePtr -1) * PortCount + ChanPtr,1]
             PPJitter[SiteList[SitePtr],ChanPtr]    = results[(SitePtr -1) * PortCount + ChanPtr,2]

             if DisplayMode then   --   **** Set DisplayMode true to observe Spectrum in Status Display ****        

                    Spectrum = SpectrumFft[(SitePtr -1) * PortCount + ChanPtr,1:SAMP_DIGHS_SPECTRUM_SAMPLES/2 +1]
            
                          -- a -g  Spectrum; grid   
                                 --**** Enter Numeric values -- scale -mult FreqBinSize  -offset 0.0                   
                          -- units -x MHz
                          -- units -y dB                

                    wait(0mS)   -- SET BREAKPOINT HERE TO OBSERVE WAVEFORM ON STATUS DISPLAY
           end_if
       end_for
   end_for 
 



end_body
procedure DdjEyePattern(SampDighsPins,BitsPerWaveform,EdgesPerWaveform,DecimationFactor,DataRate,MeasurementScale,StartOnTrigger,Sampler,UseEq,MaxEqualFreq,EqualLength,EyeMaskData,FilterNumber,DDJ,EyeWidth,EyeTest,DdjPtsOut)
in pin list[MAX_DIGHS] : SampDighsPins       -- Selected DIGHS Channels           
in integer             : BitsPerWaveform     -- Length in bits in the waveform (e.g. 127 for prbs2^7-1)
in integer             : EdgesPerWaveform    -- Number of edge transitions in the waveform (e.g. 64 for prbs2^7-1)
in integer             : DecimationFactor    -- Decimation factor from procedure SetupDdjEyePattern
in double              : DataRate            -- Data rate of waveform being tested
in  float              : MeasurementScale    -- Scale factor to correct for attenuation in measurement path  
in boolean             : StartOnTrigger      -- Waveform capture starts on detection of sync1 from digital pattern
in multisite integer   : Sampler[MAX_DIGHS]  -- Select GTO_SAMPLER or AUX_SAMPLER
in boolean             : UseEq               -- Set true to enable equalization of captured waveform otherwise set false
in float               : MaxEqualFreq        -- Frequency of maximum equalization if boolean UseEq is set true
in float               : EqualLength         -- Total trace length in DUT output measurement path to be equalized if boolean UseEq is set true
in float               : EyeMaskData[6]      -- Eye Pattern mask's Early Zero Crossing Bit Cell marker point
in integer             : FilterNumber        -- Enter 0 < FilterNumber <= MAX_FILTERS
out multisite double   : DDJ[MAX_DIGHS]      -- P-P Data Dependent jitter
out multisite double   : EyeWidth[MAX_DIGHS] -- Eye pattern opening at zero volt crossing
out multisite float    : EyeTest[MAX_DIGHS]  -- Eye pattern test result with respect to mask
out multisite float    : DdjPtsOut[MAX_DIGHS,SAMP_DIGHS_MAX_EYE_EDGES]  -- Array of zero volt crossing data transition points
---------------------------------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------------------------------
-- This procedure is a companion to procedure "SetupDdjEyePattern".  It 
-- captures and processes a GTO front End sampler waveform for Eye Pattern data and
-- derives the Data Dependent Jitter from it.  Random Jitter is filtered out of the waveform 
-- being captured, to produce an Eye pattern test of just the deterministic jitter.  The recommended 
-- pattern for use with this procedure is a between 20 bits and 160 bits long and rich in data dependent jitter.
-- The resultant Eye Pattern is also tested against an Eye Pattern Mask defined by a 6 element array of EyeMaskData. 
--
--  MaskPointA, MaskPointB, MaskPointC and MaskPointD define timing positions 
--  of the mask with values between 0.0 and 1.0.  For example MaskPointA,  A 
--  could be 0.2, MaskPointB,  B could be 0.3, MaskPointC,  C could be 0.7 
--  and MaskPointD,  D could be 0.8. MaskLevel and - MaskLevel are equal in
--  magnitude with respect to the 0.0V level.
--
--  MaskLevelMinMax determines the upper and lower voltage limits for the mask.
--
--     |<--------------Bit Cell 1.0UI ---------->|    ****  Data Stream
--     |
--     | ----------------------------------------|..... MaskLevelMinMax
--     |       ****************************      |
--     |    *      ___________________ .....*....|..... MaskLevel
--     |   *      /:                 :\      *   |
--     |  *      / :                 : \      *  |
--     | *      /  :                 :  \......*.|..... 0.0V
--     | *     :\  :                 :  /:     * |
--     |  *    : \ :                 : / :    *  |
--     |   *   :  \:_________________:/..:...*...|..... -MaskLevel
--     |    *  :   :                 :   :  *    |
--     |      *****************************      |
--     | ----------------------------------------|..... -MaskLevelMinMax
--    0.0      A   B                 C   D      1.0

--   EyeMaskData[1] is MaskPointA
--   EyeMaskData[2] is MaskPointB
--   EyeMaskData[3] is MaskPointC
--   EyeMaskData[4] is MaskPointD
--   EyeMaskData[5] is MaskLevel
--   EyeMaskData[6] is MaskLevelMinMax

-- In order to use this procedure, it is necessary to first execute procedure
-- SetupDdjEyePattern to set up the samplers for the measurement. The required 
-- pattern should be one rich in Data Dependent Jitter, such as a continuously 
-- executing PRBS 2^7 -1 or K25.5.
--
--  An optional feature of this procedure is software equalization to compensate for printed circuit trace
--  and cable between the device under test and the measuring sampler within the GTO Front End.
--
-- Output parameters includes the peak to peak data dependent jitter and eye pattern 
-- eye width.  Also outputted is an array of zero volt crossing data transition points
-- which can later be used in combination with random jitter and periodic jitter measurements
-- to derive the total jitter. 
---------------------------------------------------------------------------------------------------------------------
local
  float                : MaskPointA         -- Eye Pattern mask's Early Zero Crossing Bit Cell marker point
  float                : MaskPointB         -- Eye Pattern mask's Early level Bit Cell Marker Point
  float                : MaskPointC         -- Eye Pattern mask's Late level Bit Cell Marker Point 
  float                : MaskPointD         -- Eye Pattern mask's Late Zero Crossing Bit Cell marker point 
  float                : MaskLevel          -- Voltage level defining + and - Mask Levels Inside the Data Stream
  float                : MaskLevelMinMax    -- Voltage level defining + and - Mask Levels Outside the Data Stream
  float                : SampDighsEqual[200]
  float                : EyeMask[SAMP_DIGHS_MAX_EYE_SAMPLES]
  float                : EyeMaskAry[SAMP_DIGHS_MAX_EYE_SAMPLES*2]
  float                : OuterEyeMask[SAMP_DIGHS_MAX_EYE_SAMPLES*2]
  float                : EyeDataAry[SAMP_DIGHS_MAX_EYE_SAMPLES*2]
  float                : EyeTestData[SAMP_DIGHS_MAX_EYE_SAMPLES]
  float                : DisplayWaveform[SAMP_DIGHS_MAX_EYE_SAMPLES]
  float                : EyeTestAry[MAX_DIGHS,SAMP_DIGHS_MAX_EYE_SAMPLES]
  float                : XtrmAry[4]
  float                : EyeTestInside
  float                : EyeTestOutside
  float                : EyeScale
  float                : EyeOffset
  float                : SampleScale
  float                : CalArray[500]         -- Waveform calibration array
  float                : TenDdjWaveform[SAMP_DIGHS_MAX_EYE_SAMPLES * 10]
  float                : DroopScale
  double               : ScopeSyncFreq
  integer              : CalArySize
  integer              : SampleSize
  integer              : SampleSize2
  integer              : TenSampleSize
  integer              : DisplaySize
  integer              : EqualClampTone
  integer              : PortCount
  integer              : i,j,ii
  integer              : ChanPtr
  integer              : SitePtr
  integer              : SiteCount
  integer              : AverageCount
  integer              : BPW_Scale
  integer              : HarmonicHR
  integer              : SamplesPerBit
  word list[16]        : SiteList
   double              : results[MAX_DIGHS,2]
  boolean              : t
  word list[MAX_DIGHS] : DigPorts
  float                : BifDdjPtsOut[MAX_DIGHS,SAMP_DIGHS_MAX_EYE_EDGES]  -- Array of zero volt crossing data transition points
end_local

body
     PortCount       = len(SampDighsPins) 
     SiteList        = get_active_sites
     SiteCount       = len(SiteList)
    if use_dighsb then
        DigPorts   = dighsb_ptc(SampDighsPins)
    else
        DigPorts   = dighs_ptc(SampDighsPins)
    end_if 
     
     MaskPointA      = EyeMaskData[1]
     MaskPointB      = EyeMaskData[2]
     MaskPointC      = EyeMaskData[3]
     MaskPointD      = EyeMaskData[4]
     MaskLevel       = EyeMaskData[5]
     MaskLevelMinMax = EyeMaskData[6]
     
    if (DataRate < 1.0GHz) and (SAMP_DIGHS_EYE_SAMPLES_PER_BIT* BitsPerWaveform < 20000) then
        BPW_Scale = 20000/SAMP_DIGHS_EYE_SAMPLES_PER_BIT/BitsPerWaveform
    else
        BPW_Scale = 1
    end_if
    DroopScale    = 1.0176^(float(BitsPerWaveform)/float(DataRate*15.0e-9))
    if BitsPerWaveform > 160 then
       SamplesPerBit = SAMP_DIGHS_ALT_EYE_SAMPS_PER_BIT
    else
        SamplesPerBit  = SAMP_DIGHS_EYE_SAMPLES_PER_BIT
    end_if        
    
    SampleSize    = SamplesPerBit * BitsPerWaveform * BPW_Scale
    AverageCount  = integer(30.0e-3*DataRate)/(SampleSize*BitsPerWaveform) 
    HarmonicHR    = SamplesPerBit * BPW_Scale/20 - 1
    if HarmonicHR < 17 then
        HarmonicHR = 17
    end_if
    if DecimationFactor > 1 then
        TenSampleSize = SampleSize * DecimationFactor
        AverageCount = 1
    else
        if  AverageCount > 10 then 
            AverageCount = 10
        end_if
        TenSampleSize = AverageCount * SampleSize
    end_if
    
    SetEyeMask(MaskPointA,MaskPointB,MaskPointC,MaskPointD,MaskLevel,MaskLevelMinMax,BitsPerWaveform,SamplesPerBit * BPW_Scale,EyeMask[1:SampleSize])
    
    if use_dighsb then
        if StartOnTrigger then
            connect dighsb DigPorts trigger to sync2       
            define dighsb DigPorts capture "a" at 0 as lword(TenSampleSize) points
            start dighsb DigPorts capture "a" triggered
        else
            define dighsb DigPorts capture "a" at 0 as lword(TenSampleSize) points
            start dighsb DigPorts capture "a"
        endif
        wait for dighsb DigPorts timeout 100ms into t
        read dighsb DigPorts capture "a" for lword(TenSampleSize) points into BifRawDdjWaveform
     
       if False then   
         open( ii, program_load_path + "../dj.txt","w") 
        
        for j=1 to TenSampleSize do
            println(ii,BifRawDdjWaveform[1,j]!f:30:15)
        end_for
        close(ii)
        wait(0ms)
       end_if
        
    else
         if StartOnTrigger then
             measure dighs chan DigPorts for lword(TenSampleSize) points into memory adr 1 trigger on sync2
         else
             measure dighs chan DigPorts for lword(TenSampleSize) points into memory adr 1
         end_if
         for SitePtr = 1 to SiteCount do  
            for ChanPtr = 1 to PortCount do
              read  dighs chan DigPorts[(SitePtr -1) * PortCount + ChanPtr] for lword(TenSampleSize) points from memory adr 1 into BifRawDdjWaveform[(SitePtr -1) * PortCount + ChanPtr,1:TenSampleSize]
          end_for
        end_for    
    end_if
      
    for SitePtr = 1 to SiteCount do  
        for ChanPtr = 1 to PortCount do
           TenDdjWaveform[1:TenSampleSize] = BifRawDdjWaveform[(SitePtr -1) * PortCount + ChanPtr,1:TenSampleSize] 
           if DecimationFactor > 1 then
               vp_pick(TenDdjWaveform,1,DecimationFactor,TenDdjWaveform,1,1,SampleSize)
           else
               for i = 2 to AverageCount do
                   TenDdjWaveform[1:SampleSize] = TenDdjWaveform[1:SampleSize] + TenDdjWaveform[(i-1)*SampleSize+1:i*SampleSize] 
               end_for
           end_if
           TenDdjWaveform[1:SampleSize] = TenDdjWaveform[1:SampleSize] * MeasurementScale/float(AverageCount) 
            if  EqualLength >= 0.0 then
                GTB_CorrectWaveform (DigPorts[(SiteList[SitePtr]-1)*word(PortCount) + word(ChanPtr)]  , 2 - (word(Sampler[SiteList[SitePtr],ChanPtr]) mod 2)  , BitsPerWaveform , DataRate , 10.0GHz , 17.5GHz , TenDdjWaveform[1:SampleSize] , TenDdjWaveform[1:SampleSize] )    
           else
                TenDdjWaveform[1:SampleSize] = TenDdjWaveform[1:SampleSize] * DroopScale
           end_if
           if (FilterNumber > 0) and  (FilterNumber < MAX_FILTERS +1) then
               ApplyTransmissionFilter(TenDdjWaveform[1:SampleSize],FilterNumber)              
           end_if
           BifDdjWaveform[(SitePtr -1) * PortCount + ChanPtr,1:SampleSize] = TenDdjWaveform[1:SampleSize]
        end_for
    end_for
    
    if UseEq  and  abs(EqualLength) >= 0.5  then
        EqualClampTone = integer(MaxEqualFreq/100.0e6)
        SampDighsEqual = LossSpectrum * abs(EqualLength)
        SampDighsEqual[EqualClampTone+1:200] = SampDighsEqual[EqualClampTone]
        if (CharMode or DisplayMode) then
            char_eye_ddj_with_eq(BifDdjWaveform,SampDighsEqual,SiteCount * PortCount,DataRate,BitsPerWaveform,SamplesPerBit * BPW_Scale,HarmonicHR,EdgesPerWaveform,EyeTestAry,BifDdjPtsOut,results)
        else
            calc_eye_ddj_with_eq(BifDdjWaveform,SampDighsEqual,SiteCount * PortCount,DataRate,BitsPerWaveform,SamplesPerBit * BPW_Scale,HarmonicHR,EdgesPerWaveform,EyeTestAry,BifDdjPtsOut,results)
        end_if
    else
        if (CharMode or DisplayMode) then
            char_eye_ddj(BifDdjWaveform,SiteCount * PortCount,DataRate,BitsPerWaveform,SamplesPerBit * BPW_Scale,HarmonicHR,EdgesPerWaveform,EyeTestAry,BifDdjPtsOut,results)
       else 
           calc_eye_ddj(BifDdjWaveform,SiteCount * PortCount,DataRate,BitsPerWaveform,SamplesPerBit * BPW_Scale,HarmonicHR,EdgesPerWaveform,EyeTestAry,BifDdjPtsOut,results)
         endif
    endif    

    for SitePtr = 1 to SiteCount do  
       for ChanPtr = 1 to PortCount do
         DDJ[SiteList[SitePtr],ChanPtr]      = results[(SitePtr -1) * PortCount + ChanPtr,2]
         EyeWidth[SiteList[SitePtr],ChanPtr] = results[(SitePtr -1) * PortCount + ChanPtr,1]
         DdjPtsOut[SiteList[SitePtr],ChanPtr,1:EdgesPerWaveform] = BifDdjPtsOut[(SitePtr -1) * PortCount + ChanPtr,1:EdgesPerWaveform]
         
         vp_sub(EyeTestAry[(SitePtr -1) * PortCount + ChanPtr,1:SampleSize],1,EyeMask,1,EyeTestData,1,SampleSize)
         XtrmAry = xtrm(EyeTestData[1:SampleSize])
         EyeTestInside = XtrmAry[3]
    
         EyeTestData[1:SampleSize] = EyeTestAry[(SitePtr -1) * PortCount + ChanPtr,1:SampleSize]
         XtrmAry = xtrm(EyeTestData[1:SampleSize])
         EyeTestOutside =  MaskLevelMinMax - XtrmAry[1]
         
         if EyeTestInside > EyeTestOutside then
              EyeTest[SiteList[SitePtr],ChanPtr] = EyeTestOutside
         else
              EyeTest[SiteList[SitePtr],ChanPtr] = EyeTestInside
         end_if
      end_for
   end_for
      
      if DisplayMode then
          DisplaySize    = 2 * SampleSize
          SampleScale    = 1.0/float(SamplesPerBit * BPW_Scale)/float(DataRate)
          EyeScale       = SampleScale/float(BitsPerWaveform)
          EyeOffset      = -float(DisplaySize) * EyeScale/4.0 *1.0e12
          SampleSize2    = SampleSize*2 
          EyeMaskAry = 0.0
          for i = 1 to BitsPerWaveform  do
              for j = 1 to SamplesPerBit * BPW_Scale do
                 if j mod 2 = 0 then
                     EyeMaskAry[(j-1)*BitsPerWaveform + i] = EyeMask[(i-1)* SamplesPerBit * BPW_Scale + j]
                     OuterEyeMask[(j-1)*BitsPerWaveform + i] = - MaskLevelMinMax 
                 else
                     EyeMaskAry[(j-1)*BitsPerWaveform + i] = -EyeMask[(i-1)* SamplesPerBit * BPW_Scale + j]
                     OuterEyeMask[(j-1)*BitsPerWaveform + i] = MaskLevelMinMax
                 end_if
              end_for
          end_for
          EyeMaskAry[SampleSize + 1: 2 * SampleSize] = EyeMaskAry[ 1:SampleSize]
          OuterEyeMask[SampleSize + 1: 2 * SampleSize] = OuterEyeMask[ 1:SampleSize]
          for SitePtr = 1 to SiteCount do  
             for ChanPtr = 1 to PortCount do
                 vp_mov(BifDdjWaveform[(SitePtr -1) *  PortCount + ChanPtr,1:SampleSize],1,DisplayWaveform,1,SampleSize)
                 EyeDataAry = 0.0
                 for i = 1 to BitsPerWaveform  do
                     for j = 1 to SamplesPerBit * BPW_Scale do
                         EyeDataAry[(j-1)*BitsPerWaveform + i] = DisplayWaveform[(i-1)* SamplesPerBit * BPW_Scale + j]
                     end_for
                 end_for
                 EyeDataAry[SampleSize + 1: 2 * SampleSize] = EyeDataAry[ 1:SampleSize]
                
                 -- Add the indicated arrays to status page as "scatter" plots to observe the Eye pattern.
                          -- a -g EyeDataAry[1:SampleSize2] -t scatter; grid
                          -- a -g OuterEyeMask[1:SampleSize2] -t scatter
                          -- a -g EyeMaskAry[1:SampleSize2] -t scatter
                               --**** Enter Numeric values -- scale -mult EyeScale -offset EyeOffset
                          -- units -x ps
                          -- units -y Volts
                 
                 -- To observe pattern waveform on status page add "ScaledWaveform" as line graph.
                          -- a -g  DisplayWaveform[1:SampleSize]  ; grid
                              --**** Enter Numeric values -- scale -mult SampleScale -offset 0.0
                          -- units -x ns
                          -- units -y Volts
                 -- Rotate_array ( 21697 , DisplayWaveform[1:SampleSize] , DisplayWaveform[1:SampleSize] ) 
                 wait(0.0mS)   -- SET BREAKPOINT HERE TO DISPLAY EYE DIAGRAM
                                 
              end_for
          end_for
      end_if 


      if Scope_Mode  then
            ScopeSyncFreq = DataRate/double(BitsPerWaveform)/double(integer(DataRate/double(BitsPerWaveform)/500MHz)+1)
            SetSampleClkFrequency(ScopeSyncFreq)
            wait(1ms)  -- SET BREAKPOINT HERE TO OBSERVE WAVEFORM ON OSCILLOSCOPE
      end_if
      
end_body
procedure ConnectDighsToSamp(SamplerConnection,SampDighsPins)
in multisite integer   : SamplerConnection[MAX_DIGHS]  --  AUX_IN_ODD_CHAN, DATA_IN_ODD_CHAN, AUX_IN_EVEN_CHAN or DATA_IN_EVEN_CHAN 
in pin list[MAX_DIGHS] : SampDighsPins                 -- Selected DIGHS Channels    
---------------------------------------------------------------------------------------------------------------------
-- This procedure is used to connects the selected DIGHS digitizer channel to the selected GTO front end output.
---------------------------------------------------------------------------------------------------------------------
local
  word list[MAX_DIGHS] : DighsPins
  word                 : BufferConnection
  word                 : SamplerSelection 
  integer              : ChanPtr
  integer              : PortCount
 integer               : Site
 integer               : SiteCount
 word list[16]         : SiteList
 word list[4]          : DigPorts
end_local

body

    SiteList   = get_active_sites
    SiteCount  = len(SiteList)
    PortCount  = len(SampDighsPins)
    DighsPins  = dighsb_ptc(SampDighsPins)
    
    if use_dighsb then
        connect dighsb SampDighsPins to input b balanced
    else
        connect dighs chan SampDighsPins to input b balanced
    end_if

    for Site = 1 to SiteCount do          
        for ChanPtr = 1 to PortCount do          
            BufferConnection =  ((word(SamplerConnection[SiteList[Site],ChanPtr]) -1)/2 & 1)  + ((DighsPins[(Site -1) * PortCount + ChanPtr]-1) & 2) + 1
            SamplerSelection =  ((word(SamplerConnection[SiteList[Site],ChanPtr]) - 1) & 1) + 1
             GTB_ConnectSamplerToDigitizer (BufferConnection , SamplerSelection , DighsPins[(Site -1) * PortCount + ChanPtr] )
        end_for
    end_for

end_body

procedure SampDighsInit(LaminateEq)
in integer : LaminateEq  -- Select Laminate R4350_10Mil, R4350_6Mil, or R4003_8Mil
-------------------------------------------------------------------------------------------
-- The Initialize procedure should be called when the program is loaded. It is normally used for
-- one-time instrument setups, 
-------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------
local
set[MAX_DIGHS] : SampDighsPins            

    word    : i,j
 string[10] : test_gpib
endlocal
body


        -- INITIALIZE SAMPLE CLOCK AND AUX CLK
          InitSampleClk
      
        -- INITIALIZE DIGHS
           SampDighsPins = inventory_all_chans("dighsb")
           initialize dighsb SampDighsPins -- hardware, memory
           SpectrumCal51  = 1.0
           SpectrumCal25  = 1.0

        -- INITIALIZE EQUALIZATION ARRAY
           Make4350_10MilEqArray
           Make4350_6MilEqArray
           Make4003_8MilEqArray
           if LaminateEq = R4350_10Mil then
              LossSpectrum = R4350_10MilEqPerInch
           else_if LaminateEq = R4350_6Mil then
              LossSpectrum = R4350_6MilEqPerInch
           else_if LaminateEq = R4003_8Mil then
              LossSpectrum = R4003_8MilEqPerInch
           else
              LossSpectrum = R4350_10MilEqPerInch
           end_if
           

end_body


procedure TotalJitter(SampDighsPins,BitsPerWaveform,EdgesPerWaveform,BitErrorRate,DataRate,DdjPts,RandJitRms,PerJitPP,EyeWidth,TotalJitter)
in pin list[MAX_DIGHS] : SampDighsPins                              -- Selected DIGHS Channels          
in integer             : BitsPerWaveform                            -- Length in bits in the waveform from DdjEyePattern measurement (e.g. 127 for repeating PRBS2^7 -1 data pattern)
in integer             : EdgesPerWaveform                           -- Number of edge transitions in the waveform from DdjEyePattern measurement (e.g. 64 for prbs2^7-1)
in double              : BitErrorRate                               --  Specified Bit Error Rate
in double              : DataRate                                   -- Data rate of waveform being tested
in multisite float     : DdjPts[MAX_DIGHS,SAMP_DIGHS_MAX_EYE_EDGES] -- Array of zero volt crossing data transition points from from DdjEyePattern measurement
in multisite double    : RandJitRms[MAX_DIGHS]                      --  Passed in measured random Jitter as RMS value 
in multisite double    : PerJitPP[MAX_DIGHS]                        -- Passed in measured periodic Jitter as pk-pk value 
out multisite double   : EyeWidth[MAX_DIGHS]                        --  Derived eye width at specified Bit Error Rate 
out multisite double   : TotalJitter[MAX_DIGHS]                     -- Derived total Jitter at specified Bit Error Rate
---------------------------------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------------------------------
-- This procedure combines previously measured jitter components to derives total P-P  jitter and Eye Width at a 
-- specified Bit Error Rate down to 10^-18. 
--
-- The procedure utilizes measurement results from a pervious measurement of the Random Jitter
-- and previous measurement of Deterministic Jitter, including periodic jitter and Data Dependent Jitter.
-- Periodic jitter is most often due to Sub-Rate jitter produced by a DUT's PLL  
-- Deterministic jitter transition points, which can be captured by procedure "DdjEyePattern", are transferred to this 
-- procedure via array "DdjPts". 
---------------------------------------------------------------------------------------------------------------------
local
  float                : RjStepFactor
  float                : BerScale
  float                : BerOffset
  float                : BathtubCurve[BATHTUB_STEPS]
  float                : BitCell[BATHTUB_STEPS]
  float                : DdjMarker[BATHTUB_STEPS]
  float                : PjMarker[BATHTUB_STEPS]
  float                : BerMarker[BATHTUB_STEPS]
  float                : XtrmArray[4]
  float                : BifDdjPts[SAMP_DIGHS_MAX_EYE_EDGES]
  double               : BifRandJitRms
  double               : BifPerJitPP
  integer              : PortCount
  integer              : ChanPtr
  integer              : PjShift
  integer              : i
  integer              : SitePtr
  integer              : SiteCount
  integer              : BathtubSteps
  word list[16]        : SiteList
  double               : results[2]
end_local
body
     PortCount  = len(SampDighsPins)
     SiteList   = get_active_sites
     SiteCount  = len(SiteList)
     
     if DataRate < 1.0GHz then
        BathtubSteps = BATHTUB_STEPS
     else_if DataRate < 2.0GHz then
        BathtubSteps = BATHTUB_STEPS/2
     else_if DataRate < 4.0GHz then
        BathtubSteps = BATHTUB_STEPS/4
     else
        BathtubSteps = BATHTUB_STEPS/10
     end_if

       
     for SitePtr = 1 to SiteCount do  
       for ChanPtr = 1 to PortCount do
            if PerJitPP[SiteList[SitePtr],ChanPtr] > 1.0 then
                PerJitPP[SiteList[SitePtr],ChanPtr] = 0.0
            end_if
            BifDdjPts[1:EdgesPerWaveform] = DdjPts[SiteList[SitePtr],ChanPtr,1:EdgesPerWaveform]
            BifRandJitRms = RandJitRms[SiteList[SitePtr],ChanPtr]
            BifPerJitPP = PerJitPP[SiteList[SitePtr],ChanPtr]
            calc_total_jitter(1,BathtubSteps,BitsPerWaveform,EdgesPerWaveform,BitErrorRate,DataRate,BifDdjPts[1:EdgesPerWaveform],BifRandJitRms,BifPerJitPP,Bathtub[(SitePtr -1) * PortCount + ChanPtr,1:BathtubSteps],results)
            EyeWidth[SiteList[SitePtr],ChanPtr]    = results[1]
            TotalJitter[SiteList[SitePtr],ChanPtr] = results[2]
       end_for
     end_for 

     if DisplayMode then
          BitCell = -18.0
          BitCell[BathtubSteps/4] = 0.0
          BitCell[BathtubSteps*3/4] = 0.0
          BerMarker = log(float(BitErrorRate))

          for SitePtr = 1 to SiteCount do  
             for ChanPtr = 1 to PortCount do
                BathtubCurve[1:BathtubSteps] = Bathtub[(SitePtr -1) * PortCount + ChanPtr,1:BathtubSteps]
                RjStepFactor = float(2.0/DataRate/double(BathtubSteps))
                BerScale =1.0/float(BitsPerWaveform)
                PjShift = integer(float(PerJitPP[SiteList[SitePtr],ChanPtr])/RjStepFactor + 0.5)/2 

                BerOffset   = -float(BathtubSteps/2) * RjStepFactor/2.0 *1.0e12
                for i = 1 to BathtubSteps  do
                      if BathtubCurve[i] > 1.0e-18 then
                            BathtubCurve[i] =log(BathtubCurve[i])
                       else
                            BathtubCurve[i] = -18.0
                       end_if
                  end_for

                  DdjMarker = -18.0
                  PjMarker = -18.0
                  XtrmArray =  xtrm(DdjPts[SiteList[SitePtr],ChanPtr,1:EdgesPerWaveform])
                  DdjMarker[integer(XtrmArray[1]/RjStepFactor + 0.5)+BathtubSteps/4 + PjShift] = log(1.0/256.0)
                  DdjMarker[integer(XtrmArray[3]/RjStepFactor + 0.5)+BathtubSteps/4 - PjShift] = log(1.0/2.0)
                  DdjMarker[BathtubSteps*3/4- integer(XtrmArray[1]/RjStepFactor + 0.5) - PjShift] =  log(1.0/256.0)
                  DdjMarker[BathtubSteps*3/4 - integer(XtrmArray[3]/RjStepFactor + 0.5) + PjShift] = log(1.0/2.0-1.0/256.0)
                  if  PjShift > 1 then   -- if too close together, make 2
                      PjMarker[BathtubSteps/4 - PjShift] = log(1.0/4.0)        
                      PjMarker[BathtubSteps/4 + PjShift] = log(1.0/16.0)        
                      PjMarker[BathtubSteps*3/4 - PjShift] = log(1.0/16.0)        
                      PjMarker[BathtubSteps*3/4 + PjShift] = log(1.0/4.0)        
                  end_if
 
                          -- a -g BathtubCurve[1:BathtubSteps] ; grid
                          -- a -g BitCell[1:BathtubSteps] 
                          -- a -g BerMarker[1:BathtubSteps] 
                          -- a -g DdjMarker[1:BathtubSteps] 
                          -- a -g PjMarker[1:BathtubSteps]
                          --**** Enter Numeric values 
                          -- scale -mult RjStepFactor -offset BerOffset                  
                          -- units -x ps
                          -- units -y Log                 

                  wait(0.0ms)   -- SET BREAKPOINT HERE TO VIEW BATHTUB PLOT
             end_for
          end_for
     end_if


end_body

procedure SetSamplerDivider(SampDighsPins,SamplerDivider)
in pin list[MAX_DIGHS] : SampDighsPins      -- Selected DIGHS Channels
in integer             : SamplerDivider     -- Sample clock divide ratio     
---------------------------------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------------------------------
-- This procedure sets up the GTO Front End Track to Hold divider ratio.
---------------------------------------------------------------------------------------------------------------------
local
  word                 : sampler_divider
  word list[MAX_DIGHS] : DighsPins 
 end_local

body
     sampler_divider = word(SamplerDivider)
     DighsPins  = dighsb_ptc(SampDighsPins)

       if (1 in DighsPins) or (2 in DighsPins) then
           GTB_SetSampleClockDivider ( 1 , sampler_divider )    
       end_if
       if (3 in DighsPins) or (4 in DighsPins) then
           GTB_SetSampleClockDivider ( 3 , sampler_divider )    
       end_if

end_body

procedure WaveformMeasurementTest(SampDighsPins,MeasLevelMax,MeasurementScale,BitsPerWaveform,DataRate,SamplerConnection,preemphasis_expected,EqualLength,VodAveraged,ResultTest, rise_time_limits, fall_time_limits,duty_cycle_limits,diff_vod_p_limits,diff_vod_d_limits,diff_vod_limits,diff_vod_o_limits)
-----------------------------------------------------------------------------------------------------------  
 in pin list[MAX_DIGHS]     : SampDighsPins                -- Selected DIGHS Channels                
 in  float                  : MeasLevelMax                 -- Maximum differential voltage expected in measured waveform (Sets up DIGHS measurement range)
 in  float                  : MeasurementScale             -- Scale factor to correct for attenuation in measurement path  
 in integer                 : BitsPerWaveform              -- Length in bits in the waveform (e.g. 2 for repeating 10 data pattern)
 in double                  : DataRate                     -- Data Rate of Transmitted data
 in multisite integer       : SamplerConnection[MAX_DIGHS] --  AUX_IN_ODD_CHAN, DATA_IN_ODD_CHAN, AUX_IN_EVEN_CHAN or DATA_IN_EVEN_CHAN
 in boolean                 : preemphasis_expected
 in float                   : EqualLength
 in boolean                 : VodAveraged
 in integer                 : ResultTest[7]           -- See Below     
 in_out array of float_test : rise_time_limits        -- Set ResultTest[1] to 1 to perform test, or set ResultTest[1] to 0 to ignore test
 in_out array of float_test : fall_time_limits        -- Set ResultTest[2] to 1 to perform test, or set ResultTest[2] to 0 to ignore test
 in_out array of float_test : duty_cycle_limits       -- Set ResultTest[3] to 1 to perform test, or set ResultTest[3] to 0 to ignore test
 in_out array of float_test : diff_vod_p_limits       -- Set ResultTest[4] to 1 to perform test, or set ResultTest[4] to 0 to ignore test
 in_out array of float_test : diff_vod_d_limits       -- Set ResultTest[5] to 1 to perform test, or set ResultTest[5] to 0 to ignore test
 in_out array of float_test : diff_vod_limits         -- Set ResultTest[6] to 1 to perform test, or set ResultTest[6] to 0 to ignore test
 in_out array of float_test : diff_vod_o_limits       -- Set ResultTest[7] to 1 to perform % test, Set ResultTest[7] to 2 to perform dB test, or set ResultTest[7] to 0 to ignore test
 
------------------------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------------------
--  This procedure sets up, captures and proceesses high speed serial data, to provide Rise Time, Fall Time,
--  Duty Cycle Distortion,by utilizing the GTO Front End samplers and   Differential Output Level (with and/or 
--  without pre-emphasis and de-emphasis).  Measurement results are compared to limits and datalogged.
--
--  An optional feature of this procedure is software equalization to compensate for printed circuit trace
--  and cable between the device under test and the measuring sampler within the GTO Front End.
--
-- This procedure calls procedures "SetupWaveformMeasurement" and "WaveformMeasurement".
---------------------------------------------------------------------------------------------------------------------
local
    boolean            : StartOnTrigger = false
    boolean            : UseEq = true
    float              : MaxEqualFreq
 multisite double      : RiseTime[MAX_DIGHS]
 multisite double      : FallTime[MAX_DIGHS]
 multisite double      : DCD[MAX_DIGHS]
 multisite double      : VOD_P[MAX_DIGHS]
 multisite double      : VOD_D[MAX_DIGHS]
 multisite double      : VOD[MAX_DIGHS]
 multisite double      : VOD_O[MAX_DIGHS]
    integer            : PortCount
    integer            : ChanPtr
    integer            : SitePtr
    integer            : SiteCount
  word list[16]        : SiteList
end_local
body
    PortCount  = len(SampDighsPins)
    SiteList  = get_active_sites
    SiteCount = len(SiteList)

    MaxEqualFreq = float(DataRate* 1.5)
    if abs(EqualLength) > 20.0 then
        UseEq = false
    end_if
    

    SetupWaveformMeasurement(SamplerConnection,SampDighsPins,DataRate,BitsPerWaveform,MeasLevelMax/MeasurementScale) 
    wait(10.0ms)
    WaveformMeasurement(SampDighsPins,BitsPerWaveform,DataRate,MeasurementScale,preemphasis_expected,StartOnTrigger,SamplerConnection,UseEq,MaxEqualFreq,EqualLength,RiseTime,FallTime,DCD,VOD_P,VOD_D)
    if  ResultTest[1] = 1 then
        test_value RiseTime with rise_time_limits mode TVM_PINS 
    end_if
    if  ResultTest[2] = 1 then
        test_value FallTime with fall_time_limits mode TVM_PINS
    end_if
    if  ResultTest[3] = 1 then
        test_value DCD with duty_cycle_limits mode TVM_PINS
    end_if
    if  ResultTest[4] = 1 then
        test_value VOD_P with diff_vod_p_limits mode TVM_PINS
    end_if
    if  ResultTest[5] = 1 then
        test_value VOD_D with diff_vod_d_limits mode TVM_PINS
    end_if

    if ResultTest[6] = 1 then
       for SitePtr = 1 to SiteCount do  
         for ChanPtr = 1 to PortCount do
              if preemphasis_expected then
                  VOD[SiteList[SitePtr],ChanPtr] = (VOD_P[SiteList[SitePtr],ChanPtr] + VOD_D[SiteList[SitePtr],ChanPtr] )/2.0
              else_if VodAveraged then
                  VOD[SiteList[SitePtr],ChanPtr] = VOD_D[SiteList[SitePtr],ChanPtr]             
              else
                  VOD[SiteList[SitePtr],ChanPtr] = VOD_P[SiteList[SitePtr],ChanPtr]             
              end_if
         end_for
       end_for
       test_value VOD with diff_vod_limits mode TVM_PINS
    end_if

    if (ResultTest[7] = 1) or  (ResultTest[7] = 2) then
       for SitePtr = 1 to SiteCount do  
         for ChanPtr = 1 to PortCount do
              if ResultTest[7] = 1 then
                  VOD_O[SiteList[SitePtr],ChanPtr] = 100.0 * (VOD_P[SiteList[SitePtr],ChanPtr]/VOD_D[SiteList[SitePtr],ChanPtr] -1.0)
              else
                  VOD_O[SiteList[SitePtr],ChanPtr] = 20.0 * log((VOD_P[SiteList[SitePtr],ChanPtr]/VOD_D[SiteList[SitePtr],ChanPtr] -1.0))
              end_if
         end_for
       end_for
       test_value VOD_O with diff_vod_o_limits mode TVM_PINS
   end_if
end_body
procedure Direct_R_J_Test(SampDighsPins,SamplerConnection,DataRate,BitsPerWaveform,MeasLevelMax,MeasurementScale,StartOnTrigger,RandomJitter,random_jitter_limits)
in pin list[MAX_DIGHS] : SampDighsPins                -- Selected DIGHS Channels               
in multisite integer   : SamplerConnection[MAX_DIGHS] -- "DataInOdd", "DataInEven", AltInOdd" or "AltInEven"
in double              : DataRate                     -- Data rate of waveform being tested
in integer             : BitsPerWaveform              -- Length in bits in the waveform (e.g. 8 for repeating 11110000 data pattern)
in float               : MeasLevelMax                 --  Maximum differential voltage expected in measured waveform (Sets up DIGHS measurement range)
in  float              : MeasurementScale             -- Scale factor to correct for attenuation in measurement path  
in boolean             : StartOnTrigger            -- Waveform capture starts on detection of sync1 from digital pattern
out multisite double   : RandomJitter[MAX_DIGHS]   -- Measured Random Jitter (RMS) 
in_out array of float_test : random_jitter_limits 
---------------------------------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------------------------------
-- This procedure performs a complete random jitter test including setting up, capturing waveform, processing and testing
-- measurements results against specified limits.  Procedures "SetupWaveformMeasurement" and "Direct_R_J_Measure(SampDighsPins"
-- are called by this procedure.  The data pattern being captured must be a square pattern such as a repeating 1010...10
-- pattern or a repeating 11001100...1100 data pattern.  
--
-- This procedure outputs the random jitter measurement as an RMS (Root Mean Square) value, which can later be used 
-- in combination with an array of zero volt crossing data transition points and periodic jitter measurements to derive 
-- the total jitter. 
---------------------------------------------------------------------------------------------------------------------

body
    SetupWaveformMeasurement(SamplerConnection,SampDighsPins,DataRate,BitsPerWaveform,MeasLevelMax/MeasurementScale)
    Direct_R_J_Measure(SampDighsPins,BitsPerWaveform,DataRate,StartOnTrigger,RandomJitter)
    test_value RandomJitter with random_jitter_limits mode TVM_PINS 

end_body
procedure RandJitFromSpectrumTest(SampDighsPins,SamplerConnection,DataRate,BitsPerWaveform,MeasLevelMax,MeasurementScale,NoiseFreqMin,NoiseFreqHP_Corner,NoiseFreqMax,StartOnTrigger,RandomJitter)
in pin list[MAX_DIGHS] : SampDighsPins                -- Selected DIGHS Channels                
in multisite integer   : SamplerConnection[MAX_DIGHS] -- AUX_IN_ODD_CHAN, DATA_IN_ODD_CHAN, AUX_IN_EVEN_CHAN or DATA_IN_EVEN_CHAN
in double              : DataRate                     -- Data rate of waveform being tested
in integer             : BitsPerWaveform              -- Length in bits in the waveform (e.g. 2 for repeating 10 data pattern)
in float               : MeasLevelMax                 -- Maximum differential voltage expected in measured waveform (Sets up DIGHS measurement range)
in  float              : MeasurementScale             -- Scale factor to correct for attenuation in measurement path  
in float               : NoiseFreqMin                 -- Low Noise frequency High Pass Brick wall cutoff 
in float               : NoiseFreqHP_Corner           -- Low Noise frequency High Pass 3dB cutoff
in float               : NoiseFreqMax                 -- High Noise frequency Low Pass cutoff ( Selects DIGHS anti-aliasing filter -- no filter if > 65MHz,
                                                      --  65MHz  filter if <= 65MHz and > 32MHz,  or 32MHz filter if < 32MHz)
in boolean             : StartOnTrigger               -- Waveform capture starts on detection of sync1 from digital pattern
out multisite double   : RandomJitter[MAX_DIGHS]      -- Random Jitter measurement (RMS) (Periodic Jitter Tones removed from measurement)

local
   multisite float     : JitterTones[MAX_DIGHS,MAX_NUM_TONES] -- Periodic Jitter Tone Frequencies
   multisite float     : PP_Jitter[MAX_DIGHS,MAX_NUM_TONES]   -- Periodic Tone's Jitter P-P  
end_local
---------------------------------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------------------------------
-- This procedure calls procedures "SetupSpectrumAnalysis" and "SpectrumAnalysis" to measure Random Jitter using a phase noise 
-- measurement technique.   It sets up, captures and processes, then test against specified limits and dataloggs results.
-- The GTO Front End sampler waveform must be a square waveform, such as a repeating 1010...10 pattern or a repeating 11001100...1100
-- data pattern.  The processing filters out periodic jitter tones and alows bandpass filtering of captured phase noise.
---------------------------------------------------------------------------------------------------------------------
body
    
    SetupSpectrumAnalysis(SamplerConnection,SampDighsPins,DataRate,BitsPerWaveform,MeasLevelMax/MeasurementScale,NoiseFreqMax)
    wait(100ms)
    SpectrumAnalysis(SampDighsPins,BitsPerWaveform,DataRate,StartOnTrigger,MeasLevelMax/MeasurementScale,NoiseFreqMin,NoiseFreqHP_Corner,NoiseFreqMax,MAX_NUM_TONES, RandomJitter,JitterTones,PP_Jitter)
end_body
procedure DdjEyePatternTest(SampDighsPins,SamplerConnection,DataRate,BitsPerWaveform,EdgesPerWaveform,MeasLevelMax,MeasurementScale,StartOnTrigger,EqualLength,EyeMaskData,FilterNumber,ResultTest,DdjPtsOut,DDJ)
in pin list[MAX_DIGHS] : SampDighsPins                 -- Selected DIGHS Channels            
in multisite integer   : SamplerConnection[MAX_DIGHS]  -- "DataInOdd", "DataInEven", AltInOdd" or "AltInEven"
in double              : DataRate                      -- Data rate of waveform being tested
in integer             : BitsPerWaveform               -- Length in bits in the waveform (e.g. 127 for prbs2^7-1)
in integer             : EdgesPerWaveform              -- Number of edge transitions in the waveform (e.g. 64 for prbs2^7-1)
in float               : MeasLevelMax                  --  Maximum differential voltage expected in measured waveform (Sets up DIGHS measurement range)
in  float              : MeasurementScale              -- Scale factor to correct for attenuation in measurement path  
in boolean             : StartOnTrigger                -- Waveform capture starts on detection of sync1 from digital pattern
in float               : EqualLength                   -- Total trace length in DUT output measurement path to be equalized if boolean UseEq is set true
in float               : EyeMaskData[6]                -- Eye Pattern mask's Early Zero Crossing Bit Cell marker point
in integer             : ResultTest[3]                 -- See arrays of float_test below     
in integer             : FilterNumber                  -- Enter  0 < FilterNumber <= MAX_FILTERS
out multisite float    : DdjPtsOut[MAX_DIGHS,SAMP_DIGHS_MAX_EYE_EDGES]  -- Array of zero volt crossing data transition poiunts
out multisite double   : DDJ[MAX_DIGHS]
---------------------------------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------------------------------
-- This procedure performs a complete data dependent jitter test including setting up, capturing waveform, processing and testing
-- measurements results against specified limits.  Procedures "SetupDdjEyePattern" and "DdjEyePattern" are called by
-- this procedure. Random Jitter is filtered out of the waveform  being captured, to produce an Eye pattern test of just 
-- the deterministic jitter.  The recommended pattern for use with this procedure is a between 20 bits and 160 bits long and rich 
-- in data dependent jitter.
-- The resultant Eye Pattern is also tested against an Eye Pattern Mask defined by a 6 element array of EyeMaskData. 
--
--  MaskPointA, MaskPointB, MaskPointC and MaskPointD define timing positions 
--  of the mask with values between 0.0 and 1.0.  For example MaskPointA,  A 
--  could be 0.2, MaskPointB,  B could be 0.3, MaskPointC,  C could be 0.7 
--  and MaskPointD,  D could be 0.8. MaskLevel and - MaskLevel are equal in
--  magnitude with respect to the 0.0V level.
--
--  MaskLevelMinMax determines the upper and lower voltage limits for the mask.
--
--     |<--------------Bit Cell 1.0UI ---------->|    ****  Data Stream
--     |
--     | ----------------------------------------|..... MaskLevelMinMax
--     |       ****************************      |
--     |    *      ___________________ .....*....|..... MaskLevel
--     |   *      /:                 :\      *   |
--     |  *      / :                 : \      *  |
--     | *      /  :                 :  \......*.|..... 0.0V
--     | *     :\  :                 :  /:     * |
--     |  *    : \ :                 : / :    *  |
--     |   *   :  \:_________________:/..:...*...|..... -MaskLevel
--     |    *  :   :                 :   :  *    |
--     |      *****************************      |
--     | ----------------------------------------|..... -MaskLevelMinMax
--    0.0      A   B                 C   D      1.0

--   EyeMaskData[1] is MaskPointA
--   EyeMaskData[2] is MaskPointB
--   EyeMaskData[3] is MaskPointC
--   EyeMaskData[4] is MaskPointD
--   EyeMaskData[5] is MaskLevel
--   EyeMaskData[6] is MaskLevelMinMax
--
--  An optional feature of this procedure is software equalization to compensate for printed circuit trace
--  and cable between the device under test and the measuring sampler within the GTO Front End.
--
--   In addition to measuring and testing DDJ and eye pattern, the procedure also outputs an array of zero 
-- volt crossing data transition points which can later be used in combination with random jitter and 
-- periodic jitter measurements to derive the total jitter. 
---------------------------------------------------------------------------------------------------------------------

local
    boolean            : UseEq = false       
    integer            : DecimationFactor    -- Another Scale factor for undersampling ( This parameter is to be passed to procedure DdjEyePattern
    float              : MaxEqualFreq        -- Frequency of maximum equalization if boolean UseEq is set true
    multisite double   : EyeWidth[MAX_DIGHS] -- Eye pattern opening at zero volt crossing
    multisite float    : EyeTest[MAX_DIGHS]  -- Eye pattern test result with respect to mask
end_local

body

    if abs(EqualLength) > 20.0 then
        UseEq = false
    end_if

    MaxEqualFreq = float(DataRate * 1.5)
    SetupDdjEyePattern(SamplerConnection,SampDighsPins,DataRate,BitsPerWaveform,MeasLevelMax/MeasurementScale,DecimationFactor)

    wait(20ms)
    DdjEyePattern(SampDighsPins,BitsPerWaveform,EdgesPerWaveform,DecimationFactor,DataRate,MeasurementScale,StartOnTrigger,SamplerConnection,UseEq,MaxEqualFreq,EqualLength,EyeMaskData,FilterNumber,DDJ,EyeWidth,EyeTest,DdjPtsOut) 

end_body
procedure TotalJitterTest(SampDighsPins,BitsPerWaveform,EdgesPerWaveform,BitErrorRate,DataRate,DdjPts,RandJitRms,PerJitPP, ResultTest,total_jitter_limits,eye_width_limits)
in pin list[MAX_DIGHS] : SampDighsPins                              -- Selected DIGHS Channels          
in integer             : BitsPerWaveform                            -- Length in bits in the waveform from DdjEyePattern measurement (e.g. 127 for repeating PRBS2^7 -1 data pattern)
in integer             : EdgesPerWaveform                           -- Number of edge transitions in the waveform from DdjEyePattern measurement (e.g. 64 for prbs2^7-1)
in double              : BitErrorRate                               -- Specified Bit Error Rate
in double              : DataRate                                   -- Data rate of waveform being tested
in multisite float     : DdjPts[MAX_DIGHS,SAMP_DIGHS_MAX_EYE_EDGES] -- Array of zero volt crossing data transition poiunts from from DdjEyePattern measurement
in multisite double    : RandJitRms[MAX_DIGHS]                      -- Passed in measured random Jitter as RMS value 
in multisite double    : PerJitPP[MAX_DIGHS]                        -- Passed in measured periodic Jitter as pk-pk value 
in integer             : ResultTest[2]                              -- See Below 
in_out array of float_test : total_jitter_limits                    -- Set ResultTest[1] to 1 to perform test, or set ResultTest[1] to 0 to ignore test
in_out array of float_test : eye_width_limits                       -- Set ResultTest[2] to 1 to perform test, or set ResultTest[1] to 0 to ignore test
---------------------------------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------------------------------
-- This procedure calls procedure "TotalJitter" and derives total P-P  jitter and Eye Width at a specified Bit Error 
-- Rate down to 10^-18.  Then it compares measurement data to test limits and datalogs results.
--
-- The procedure utilizes measurement results from a pervious measurement of the Random Jitter
-- and previous measurement of Deterministic Jitter, including periodic jitter and data dependent jitter.
-- Periodic jitter is most often due to Sub-Rate jitter produced by a DUT's PLL  
-- Deterministic jitter transition points, which can be captured by procedure "DdjEyePattern", are transferred to this 
-- procedure via array "DdjPts".  
---------------------------------------------------------------------------------------------------------------------

local
     multisite double   : EyeWidth[MAX_DIGHS]                        --  Derived eye width at specified Bit Error Rate 
     multisite double   : Total_Jitter[MAX_DIGHS]                     -- Derived total Jitter at specified Bit Error Rate
end_local

body

    TotalJitter(SampDighsPins,BitsPerWaveform,EdgesPerWaveform,BitErrorRate,DataRate,DdjPts,RandJitRms,PerJitPP,EyeWidth,Total_Jitter)
 
    if  ResultTest[1] = 1 then
        test_value Total_Jitter with total_jitter_limits mode TVM_PINS
    end_if
    if  ResultTest[2] = 1 then
        test_value EyeWidth with eye_width_limits mode TVM_PINS
    end_if

end_body
procedure SubRateJitterTest(SampDighsPins,SamplerConnection,DataRate,BitsPerWaveform,MeasLevelMax,MeasurementScale,StartOnTrigger,JitterTone,PPJitAmp,jit_tone_amp_limits,jit_tone_freq_limits) 
in pin list[MAX_DIGHS] : SampDighsPins                 -- Selected DIGHS Channels               
in multisite integer   : SamplerConnection[MAX_DIGHS]  -- "DataInOdd", "DataInEven", AltInOdd" or "AltInEven"
in double              : DataRate                      -- Data rate of waveform being tested
in  integer            : BitsPerWaveform               -- Length in bits in the waveform (e.g. 2 for repeating 10 data pattern)
in float               : MeasLevelMax                  -- Maximum differential voltage expected in measured waveform (Sets up DIGHS measurement range)
in  float              : MeasurementScale              -- Scale factor to correct for attenuation in measurement path  
in boolean             : StartOnTrigger        -- Waveform capture starts on detection of sync1 from digital pattern
out multisite double   : JitterTone[MAX_DIGHS] -- Frequency of Sub-Rate Jitter
out multisite double   : PPJitAmp[MAX_DIGHS]   -- Amplitude of Sub-Rate Jitter P-P  
in_out array of float_test : jit_tone_amp_limits 
in_out array of float_test : jit_tone_freq_limits 


---------------------------------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------------------------------
-- This procedure performs a complete Sub-Rate jitter test, including timing setup, spectrum capture, processing, 
-- measuring, comparing to test limits and datalogging results.  Sub-Rate jitter is periodic jitter that typically 
-- is associated with a DUT's PLL clock divider.
--
--The required waveform must be a square pattern, such as a repeating 1010...10pattern or a repeatoing 11001100...1100 data pattern.
--
-- This procedure calls procedures "SetupSubRateJitterMeasurement" and "SubRateJitterMeasurement".
---------------------------------------------------------------------------------------------------------------------


body
      SetupSubRateJitterMeasurement(SamplerConnection,SampDighsPins,DataRate,BitsPerWaveform,MeasLevelMax/MeasurementScale)
      SubRateJitterMeasurement(SampDighsPins,BitsPerWaveform,DataRate,StartOnTrigger,MeasLevelMax,JitterTone,PPJitAmp) 
      test_value JitterTone with jit_tone_amp_limits mode TVM_PINS 
      test_value PPJitAmp with jit_tone_freq_limits mode TVM_PINS 

end_body

procedure Make4003_8MilEqArray
body
awrite(R4003_8MilEqPerInch[1:8],19.0600e-3,29.9500e-3,39.8900e-3,49.2200e-3,58.0200e-3,66.3400e-3,74.1900e-3,81.6300e-3)
awrite(R4003_8MilEqPerInch[9:16],88.7100e-3,95.4500e-3,101.8700e-3,108.0600e-3,114.0300e-3,119.7800e-3,125.3500e-3,130.7500e-3)
awrite(R4003_8MilEqPerInch[17:24],135.9900e-3,141.1000e-3,146.0800e-3,150.9400e-3,155.6900e-3,160.3400e-3,164.9000e-3,169.3700e-3)
awrite(R4003_8MilEqPerInch[25:32],173.7600e-3,178.0700e-3,182.3200e-3,186.4900e-3,190.6000e-3,194.6500e-3,198.6500e-3,202.5900e-3)
awrite(R4003_8MilEqPerInch[33:40],206.4800e-3,210.3200e-3,214.1100e-3,217.8600e-3,221.5600e-3,225.2360e-3,228.8600e-3,232.4500e-3)
awrite(R4003_8MilEqPerInch[41:48],236.0000e-3,239.5200e-3,243.0100e-3,246.4600e-3,249.8900e-3,253.2600e-3,256.6400e-3,259.9800e-3)
awrite(R4003_8MilEqPerInch[49:56],263.2900e-3,266.5800e-3,269.8400e-3,273.0700e-3,277.1716e-3,280.2928e-3,283.3947e-3,286.4780e-3)
awrite(R4003_8MilEqPerInch[57:64],289.5429e-3,292.5903e-3,295.6202e-3,298.6333e-3,301.6299e-3,304.6106e-3,307.5756e-3,310.5253e-3)
awrite(R4003_8MilEqPerInch[65:72],313.4601e-3,316.3802e-3,319.2862e-3,322.1782e-3,325.0566e-3,327.9217e-3,330.7736e-3,333.6129e-3)
awrite(R4003_8MilEqPerInch[73:80],336.4397e-3,339.2542e-3,342.0567e-3,344.8473e-3,347.6266e-3,350.3945e-3,353.1513e-3,355.8973e-3)
awrite(R4003_8MilEqPerInch[81:88],358.6326e-3,361.3573e-3,364.0718e-3,366.7761e-3,369.4705e-3,372.1554e-3,374.8305e-3,377.4961e-3)
awrite(R4003_8MilEqPerInch[89:96],380.1526e-3,382.8000e-3,385.4384e-3,388.0680e-3,390.6889e-3,393.3015e-3,395.9054e-3,398.5013e-3)
awrite(R4003_8MilEqPerInch[97:104],401.0890e-3,403.6687e-3,406.2405e-3,408.8046e-3,411.3610e-3,413.9099e-3,416.4514e-3,418.9855e-3)
awrite(R4003_8MilEqPerInch[105:112],421.5125e-3,424.0324e-3,426.5452e-3,429.0513e-3,431.5504e-3,434.0429e-3,436.5286e-3,439.0079e-3)
awrite(R4003_8MilEqPerInch[113:120],441.4808e-3,443.9472e-3,446.4076e-3,448.8615e-3,451.3094e-3,453.7513e-3,456.1872e-3,458.6172e-3)
awrite(R4003_8MilEqPerInch[121:128],461.0414e-3,463.4599e-3,465.8727e-3,468.2799e-3,470.6816e-3,473.0778e-3,475.4685e-3,477.8540e-3)
awrite(R4003_8MilEqPerInch[129:136],480.2342e-3,482.6092e-3,484.9790e-3,487.3437e-3,489.7035e-3,492.0582e-3,494.4079e-3,496.7528e-3)
awrite(R4003_8MilEqPerInch[137:144],499.0930e-3,501.4283e-3,503.7589e-3,506.0849e-3,508.4062e-3,510.7229e-3,513.0353e-3,515.3431e-3)
awrite(R4003_8MilEqPerInch[145:152],517.6465e-3,519.9455e-3,522.2402e-3,524.5305e-3,526.8167e-3,529.0986e-3,531.3764e-3,533.6501e-3)
awrite(R4003_8MilEqPerInch[153:160],535.9197e-3,538.1852e-3,540.4468e-3,542.7045e-3,544.9581e-3,547.2078e-3,549.4538e-3,551.6960e-3)
awrite(R4003_8MilEqPerInch[161:168],553.9343e-3,556.1690e-3,558.3999e-3,560.6272e-3,562.8508e-3,565.0707e-3,567.2873e-3,569.5001e-3)
awrite(R4003_8MilEqPerInch[169:176],571.7095e-3,573.9154e-3,576.1179e-3,578.3169e-3,580.5126e-3,582.7050e-3,584.8939e-3,587.0796e-3)
awrite(R4003_8MilEqPerInch[177:184],589.2620e-3,591.4412e-3,593.6171e-3,595.7898e-3,597.9595e-3,600.1260e-3,602.2893e-3,604.4496e-3)
awrite(R4003_8MilEqPerInch[185:192],606.6067e-3,608.7610e-3,610.9120e-3,613.0602e-3,615.2054e-3,617.3477e-3,619.4870e-3,621.6236e-3)
awrite(R4003_8MilEqPerInch[193:200],623.7570e-3,625.8878e-3,628.0156e-3,630.1408e-3,632.2631e-3,634.3827e-3,636.4994e-3,638.6135e-3)
end_body
private procedure Make4350_10MilEqArray
body
   awrite(R4350_10MilEqPerInch[1:8],17.5500e-3,27.7150e-3,37.0150e-3,45.7650e-3,54.0350e-3,61.8700e-3,69.2800e-3,76.3250e-3)
   awrite(R4350_10MilEqPerInch[9:16],83.0350e-3,89.4450e-3,95.5750e-3,101.4850e-3,107.1950e-3,112.7100e-3,118.0550e-3,123.2500e-3)
   awrite(R4350_10MilEqPerInch[17:24],128.3050e-3,133.2350e-3,138.0550e-3,142.7600e-3,147.3700e-3,151.8900e-3,156.3250e-3,160.6800e-3)
   awrite(R4350_10MilEqPerInch[25:32],164.9600e-3,169.1750e-3,173.3250e-3,177.4100e-3,181.4400e-3,185.4150e-3,189.3450e-3,193.2200e-3)
   awrite(R4350_10MilEqPerInch[33:40],197.0550e-3,200.8400e-3,204.5800e-3,208.2850e-3,211.9450e-3,215.5780e-3,219.1700e-3,222.7350e-3)
   awrite(R4350_10MilEqPerInch[41:48],226.2600e-3,229.7550e-3,233.2250e-3,236.6600e-3,240.0750e-3,243.4450e-3,246.8100e-3,250.1450e-3)
   awrite(R4350_10MilEqPerInch[49:56],251.4527e-3,254.8995e-3,258.3220e-3,261.7203e-3,265.7193e-3,269.2954e-3,272.8518e-3,276.3893e-3)
   awrite(R4350_10MilEqPerInch[57:64],279.9082e-3,283.4092e-3,286.8925e-3,290.3587e-3,293.8081e-3,297.2413e-3,300.6587e-3,304.0603e-3)
   awrite(R4350_10MilEqPerInch[65:72],307.4470e-3,310.8187e-3,314.1760e-3,317.5191e-3,320.8484e-3,324.1641e-3,327.4665e-3,330.7560e-3)
   awrite(R4350_10MilEqPerInch[73:80],334.0329e-3,337.2972e-3,340.5493e-3,343.7894e-3,347.0179e-3,350.2349e-3,353.4406e-3,356.6353e-3)
   awrite(R4350_10MilEqPerInch[81:88],359.8191e-3,362.9922e-3,366.1549e-3,369.3073e-3,372.4495e-3,375.5821e-3,378.7047e-3,381.8178e-3)  
   awrite(R4350_10MilEqPerInch[89:96],384.9215e-3,388.0160e-3,391.1013e-3,394.1778e-3,397.2454e-3,400.3044e-3,403.3548e-3,406.3969e-3)
   awrite(R4350_10MilEqPerInch[97:104],409.4307e-3,412.4564e-3,415.4740e-3,418.4839e-3,421.4859e-3,424.4803e-3,427.4672e-3,430.4465e-3)  
   awrite(R4350_10MilEqPerInch[105:112],433.4186e-3,436.3835e-3,439.3413e-3,442.2920e-3,445.2359e-3,448.1729e-3,451.1031e-3,454.0267e-3)   
   awrite(R4350_10MilEqPerInch[113:120],456.9439e-3,459.8544e-3,462.7588e-3,465.6567e-3,468.5484e-3,471.4340e-3,474.3136e-3,477.1871e-3)
   awrite(R4350_10MilEqPerInch[121:128],480.0547e-3,482.9166e-3,485.7727e-3,488.6230e-3,491.4678e-3,494.3070e-3,497.1406e-3,499.9689e-3)
   awrite(R4350_10MilEqPerInch[129:136],502.7919e-3,505.6095e-3,508.4218e-3,511.2290e-3,514.0312e-3,516.8282e-3,519.6201e-3,522.4072e-3)
   awrite(R4350_10MilEqPerInch[137:144],525.1893e-3,527.9667e-3,530.7392e-3,533.5071e-3,536.2701e-3,539.0285e-3,541.7824e-3,544.5319e-3)
   awrite(R4350_10MilEqPerInch[145:152],547.2767e-3,550.0171e-3,552.7531e-3,555.4846e-3,558.2120e-3,560.9351e-3,563.6539e-3,566.3686e-3)
   awrite(R4350_10MilEqPerInch[153:160],569.0790e-3,571.7854e-3,574.4878e-3,577.1862e-3,579.8805e-3,582.5708e-3,585.2573e-3,587.9399e-3)
   awrite(R4350_10MilEqPerInch[161:168],590.6186e-3,593.2937e-3,595.9649e-3,598.6324e-3,601.2961e-3,603.9562e-3,606.6128e-3,609.2656e-3)
   awrite(R4350_10MilEqPerInch[169:176],611.9149e-3,614.5607e-3,617.2030e-3,619.8417e-3,622.4772e-3,625.1092e-3,627.7376e-3,630.3629e-3)
   awrite(R4350_10MilEqPerInch[177:184],632.9849e-3,635.6034e-3,638.2186e-3,640.8307e-3,643.4397e-3,646.0454e-3,648.6479e-3,651.2473e-3)
   awrite(R4350_10MilEqPerInch[185:192],653.8435e-3,656.4367e-3,659.0267e-3,661.6138e-3,664.1979e-3,666.7791e-3,669.3572e-3,671.9324e-3)
   awrite(R4350_10MilEqPerInch[193:200],674.5046e-3,677.0739e-3,679.6404e-3,682.2041e-3,684.7650e-3,687.3231e-3,689.8782e-3,692.4306e-3)

end_body
procedure Make4350_6MilEqArray
body
awrite(R4350_6MilEqPerInch[1:8],22.8800e-3,35.1500e-3,46.1200e-3,56.4900e-3,66.4500e-3,76.0600e-3,85.3400e-3,94.3100e-3)
awrite(R4350_6MilEqPerInch[9:16],102.9700e-3,111.3500e-3,119.4500e-3,127.3000e-3,134.9100e-3,142.3000e-3,149.4800e-3,156.4800e-3)
awrite(R4350_6MilEqPerInch[17:24],163.2900e-3,169.9400e-3,176.4400e-3,182.7900e-3,189.0100e-3,195.1100e-3,201.0900e-3,206.9900e-3)
awrite(R4350_6MilEqPerInch[25:32],212.7300e-3,218.4100e-3,223.9900e-3,229.4800e-3,234.9000e-3,240.2400e-3,245.5000e-3,250.7000e-3)
awrite(R4350_6MilEqPerInch[33:40],255.8300e-3,260.9000e-3,265.9000e-3,270.8500e-3,275.7500e-3,280.5900e-3,285.3800e-3,290.1300e-3)
awrite(R4350_6MilEqPerInch[41:48],294.8300e-3,299.4800e-3,304.1384e-3,308.4355e-3,312.7052e-3,316.9485e-3,321.1664e-3,325.3597e-3)
awrite(R4350_6MilEqPerInch[49:56],329.5292e-3,333.6758e-3,337.8000e-3,341.9027e-3,345.9846e-3,350.0463e-3,354.0883e-3,358.1114e-3)
awrite(R4350_6MilEqPerInch[57:64],362.1160e-3,366.1027e-3,370.0719e-3,374.0242e-3,377.9601e-3,381.8799e-3,385.7843e-3,389.6733e-3)
awrite(R4350_6MilEqPerInch[65:72],393.5477e-3,397.4075e-3,401.2535e-3,405.0857e-3,408.9046e-3,412.7105e-3,416.5038e-3,420.2846e-3)
awrite(R4350_6MilEqPerInch[73:80],424.0535e-3,427.8104e-3,431.5559e-3,435.2901e-3,439.0133e-3,442.7258e-3,446.4277e-3,450.1193e-3)
awrite(R4350_6MilEqPerInch[81:88],453.8010e-3,457.4727e-3,461.1348e-3,464.7876e-3,468.4310e-3,472.0656e-3,475.6911e-3,479.3082e-3)
awrite(R4350_6MilEqPerInch[89:96],482.9166e-3,486.5168e-3,490.1088e-3,493.6929e-3,497.2691e-3,500.8377e-3,504.3988e-3,507.9524e-3)
awrite(R4350_6MilEqPerInch[97:104],511.4988e-3,515.0381e-3,518.5705e-3,522.0961e-3,525.6150e-3,529.1271e-3,532.6330e-3,536.1323e-3)
awrite(R4350_6MilEqPerInch[105:112],539.6257e-3,543.1128e-3,546.5939e-3,550.0692e-3,553.5385e-3,557.0024e-3,560.4604e-3,563.9132e-3)
awrite(R4350_6MilEqPerInch[113:120],567.3605e-3,570.8025e-3,574.2392e-3,577.6709e-3,581.0975e-3,584.5192e-3,587.9361e-3,591.3480e-3)
awrite(R4350_6MilEqPerInch[121:128],594.7553e-3,598.1580e-3,601.5562e-3,604.9500e-3,608.3391e-3,611.7241e-3,615.1049e-3,618.4814e-3)
awrite(R4350_6MilEqPerInch[129:136],621.8538e-3,625.2221e-3,628.5865e-3,631.9471e-3,635.3036e-3,638.6563e-3,642.0055e-3,645.3508e-3)
awrite(R4350_6MilEqPerInch[137:144],648.6927e-3,652.0307e-3,655.3655e-3,658.6967e-3,662.0247e-3,665.3491e-3,668.6703e-3,671.9882e-3)
awrite(R4350_6MilEqPerInch[145:152],675.3030e-3,678.6147e-3,681.9232e-3,685.2286e-3,688.5313e-3,691.8308e-3,695.1275e-3,698.4212e-3)
awrite(R4350_6MilEqPerInch[153:160],701.7121e-3,705.0003e-3,708.2858e-3,711.5686e-3,714.8487e-3,718.1262e-3,721.4010e-3,724.6734e-3)
awrite(R4350_6MilEqPerInch[161:168],727.9432e-3,731.2108e-3,734.4758e-3,737.7384e-3,740.9987e-3,744.2567e-3,747.5125e-3,750.7659e-3)
awrite(R4350_6MilEqPerInch[169:176],754.0172e-3,757.2661e-3,760.5131e-3,763.7579e-3,767.0006e-3,770.2414e-3,773.4802e-3,776.7168e-3)
awrite(R4350_6MilEqPerInch[177:184],779.9516e-3,783.1843e-3,786.4153e-3,789.6443e-3,792.8715e-3,796.0970e-3,799.3205e-3,802.5424e-3)
awrite(R4350_6MilEqPerInch[185:192],805.7625e-3,808.9810e-3,812.1977e-3,815.4128e-3,818.6263e-3,821.8381e-3,825.0484e-3,828.2572e-3)
awrite(R4350_6MilEqPerInch[193:200],831.4644e-3,834.6700e-3,837.8741e-3,841.0770e-3,844.2784e-3,847.4783e-3,850.6768e-3,853.8740e-3)
end_body

procedure TimeDelay(delay)
in float    : delay
body
    wait(delay)
end_body
procedure SC_waveformParametrics ( inWave , splitterAttenScale , bitsPerWaveform , dataRate , scaledWaveform , ary2 , ary3 , preemphasisWaveformExpected , use_square , results)
--------------------------------------------------------------------------------
in_out float            : inWave [ ? ]
in float                : splitterAttenScale
in integer              : bitsPerWaveform
in double               : dataRate
in_out float            : scaledWaveform [ ? ]        -- size of inWave
in_out float            : ary3 [ ? ]                  -- 3 * size of inWave
in_out float            : ary2 [ ? ]                  -- 3 * size of inWave
in boolean              : preemphasisWaveformExpected
in boolean              : use_square
in_out double           : results [ ? ] 
local
float                   : xtrmAry [ 4 ]
float                   : offset
float                   : level20
float                   : level80
float                   : x
integer                 : maxPt
integer                 : minPt
integer                 : zeroCrossingP
integer                 : zeroCrossingN
integer                 : riseStart
integer                 : riseStop
integer                 : fallStart
integer                 : fallStop
integer                 : length
integer                 : lengthX2
integer                 : lengthX3
integer                 : i
integer                 : slice1, slice2
float                   : max_v, min_v
float                   : pos_v, neg_v
double                  : square_time
double                   : tim_avg
integer                 : tim1, tim2
float                   : ary_tmp[SAMP_DIGHS_WAVEFORM_SAMPLES]
end_local


body


    length = dimsize ( inWave , 1 )

    -----------------------------------------------------------------------------
    -- Waveform processing
    -----------------------------------------------------------------------------
    vp_smul ( splitterAttenScale , inWave , 1 , scaledWaveform , 1 , length )
    ary2 [ 1 : length ] = fft ( scaledWaveform )
    ary2 [ 15 * bitsPerWaveform : length ] = 0.0
    ary2 [ 2 ] = 0.0
    scaledWaveform = inverse_fft ( ary2 [ 1 : length ] )    
    offset = - ary2 [ 1 ]
    vp_sadd ( offset , scaledWaveform , 1 , scaledWaveform , 1 , length )
    vp_pick ( scaledWaveform , 1 , 1 , ary2 , 1 , 1 , length )
    i = length + 1
    vp_pick ( scaledWaveform , 1 , 1 , ary2 , i , 1 , length )
    i = 2 * length + 1
    vp_pick ( scaledWaveform , 1 , 1 , ary2 , i , 1 , length )

    xtrmAry = xtrm ( ary2 [ 1 : length ] )
    minPt = integer ( xtrmAry [ 4 ] )
    min_v= xtrmAry [ 3 ]
    maxPt = integer ( xtrmAry [ 2 ] )
    max_v = xtrmAry [ 1 ]

    i = 3 * length 
    vp_abs ( ary2 , 1 , ary3 , 1 , i )

    if minPt > maxPt then
        slice2 = maxPt + SAMP_DIGHS_WAVEFORM_SAMPLES
    else
        slice2 = maxPt
    end_if
    slice1 = minPt 
    xtrmAry = xtrm ( ary3 [ slice1 : slice2 ] )
    zeroCrossingP = slice1 + integer( xtrmAry [ 4 ] ) - 1

    if maxPt > minPt then
        slice2 = minPt + SAMP_DIGHS_WAVEFORM_SAMPLES
    else
        slice2 = minPt
    end_if
    slice1 = maxPt 
    xtrmAry = xtrm ( ary3 [ slice1 : slice2 ] )
    zeroCrossingN = slice1 + integer( xtrmAry [ 4 ] ) - 1
        
    if preemphasisWaveformExpected then
        if bitsPerWaveform = 2 then
            pos_v = ary2 [ maxPt + SAMP_DIGHS_WAVEFORM_2BIT_PK_DLY ] 
            neg_v = ary2 [ minPt + SAMP_DIGHS_WAVEFORM_2BIT_PK_DLY ] 
        else
            pos_v = ary2 [ zeroCrossingN - SAMP_DIGHS_WAVEFORM_SAMPLES / bitsPerWaveform ]
            neg_v = ary2 [ zeroCrossingP + SAMP_DIGHS_WAVEFORM_SAMPLES - SAMP_DIGHS_WAVEFORM_SAMPLES / bitsPerWaveform ]
        endif
    else
            pos_v = ary2 [ maxPt ] 
            neg_v = ary2 [ minPt ] 
    endif
    
    level20 = neg_v * 0.8 + pos_v * 0.2
    level80 = pos_v * 0.8 + neg_v * 0.2
    i = 3 * length
    x = - level20

    if preemphasisWaveformExpected then
        vp_sadd ( x , ary2 , 1 , ary3 , 1 , i ) 
        vp_abs ( ary3 , 1 , ary3 , 1 , i )
        if bitsPerWaveform = 2 then
            xtrmAry = xtrm ( ary3 [ maxPt + SAMP_DIGHS_WAVEFORM_SAMPLES - SAMP_DIGHS_WAVEFORM_SAMPLES / bitsPerWaveform : maxPt + SAMP_DIGHS_WAVEFORM_SAMPLES ] )
            riseStart = maxPt + SAMP_DIGHS_WAVEFORM_SAMPLES - SAMP_DIGHS_WAVEFORM_SAMPLES / bitsPerWaveform + integer ( xtrmAry [ 4 ] ) - 1
            xtrmAry = xtrm ( ary3 [ minPt + SAMP_DIGHS_WAVEFORM_SAMPLES - SAMP_DIGHS_WAVEFORM_SAMPLES / bitsPerWaveform : minPt + SAMP_DIGHS_WAVEFORM_SAMPLES ] )
            fallStop = minPt + SAMP_DIGHS_WAVEFORM_SAMPLES - SAMP_DIGHS_WAVEFORM_SAMPLES / bitsPerWaveform + integer ( xtrmAry [ 4 ] ) - 1
        else
            xtrmAry = xtrm ( ary3 [ maxPt + SAMP_DIGHS_WAVEFORM_SAMPLES - SAMP_DIGHS_WAVEFORM_SAMPLES * 2 / bitsPerWaveform : maxPt + SAMP_DIGHS_WAVEFORM_SAMPLES ] )
            riseStart = maxPt + SAMP_DIGHS_WAVEFORM_SAMPLES - SAMP_DIGHS_WAVEFORM_SAMPLES * 2 / bitsPerWaveform + integer ( xtrmAry [ 4 ] ) - 1
            xtrmAry = xtrm ( ary3 [ minPt + SAMP_DIGHS_WAVEFORM_SAMPLES - SAMP_DIGHS_WAVEFORM_SAMPLES * 2 / bitsPerWaveform : minPt + SAMP_DIGHS_WAVEFORM_SAMPLES ] )
            fallStop = minPt + SAMP_DIGHS_WAVEFORM_SAMPLES - SAMP_DIGHS_WAVEFORM_SAMPLES * 2 / bitsPerWaveform + integer ( xtrmAry [ 4 ] ) - 1
        endif
    else

        vp_mov ( ary2 , 1 , ary3 , 1 , i ) 

        --Find start of Rise Time
        slice1 = minPt+1
        slice2 = zeroCrossingP
        i = slice2 - slice1 + 1
        vp_clip ( x , ary2 [ slice1 : slice2 ] , 1 , ary3 [ slice1 : slice2 ] , 1 , i )
        --Search backwards from zero crossing 
        vp_reverse ( ary3 [ slice1 : slice2 ] , 1 , i )
        xtrmAry = xtrm ( ary3 [ slice1 : slice2 ] )
        riseStart = slice2 - integer ( xtrmAry [ 4 ] ) + 1

        --Find end of Fall Time
        slice1 = zeroCrossingN
        if minPt < zeroCrossingN then
            slice2 = minPt + SAMP_DIGHS_WAVEFORM_SAMPLES
        else
            slice2 = minPt 
        end_if
        i = slice2 - slice1 + 1
        vp_clip ( x , ary2 [ slice1 : slice2 ] , 1 , ary3 [ slice1 : slice2 ] , 1 , i ) 
        xtrmAry = xtrm ( ary3 [ slice1 : slice2 ] ) -- zero crossing (falling) to min
        fallStop = slice1 + integer ( xtrmAry [ 4 ] ) - 1

    endif   
    i = 3 * length
    x = - level80
        
    if preemphasisWaveformExpected then
        vp_sadd ( x , ary2 , 1, ary3 , 1 , i )    
        vp_abs  ( ary3, 1 , ary3 , 1 , i )    
        if bitsPerWaveform = 2 then
            xtrmAry = xtrm ( ary3 [ maxPt + SAMP_DIGHS_WAVEFORM_SAMPLES - SAMP_DIGHS_WAVEFORM_SAMPLES / bitsPerWaveform : maxPt + SAMP_DIGHS_WAVEFORM_SAMPLES ] )
            riseStop = maxPt + SAMP_DIGHS_WAVEFORM_SAMPLES - SAMP_DIGHS_WAVEFORM_SAMPLES / bitsPerWaveform + integer ( xtrmAry [ 4 ] ) - 1
            xtrmAry = xtrm ( ary3 [ minPt + SAMP_DIGHS_WAVEFORM_SAMPLES - SAMP_DIGHS_WAVEFORM_SAMPLES / bitsPerWaveform : minPt + SAMP_DIGHS_WAVEFORM_SAMPLES ] )
            fallStart = minPt + SAMP_DIGHS_WAVEFORM_SAMPLES - SAMP_DIGHS_WAVEFORM_SAMPLES / bitsPerWaveform + integer ( xtrmAry [ 4 ] ) - 1
        else
            xtrmAry = xtrm ( ary3 [ maxPt + SAMP_DIGHS_WAVEFORM_SAMPLES - SAMP_DIGHS_WAVEFORM_SAMPLES * 2 / bitsPerWaveform : maxPt + SAMP_DIGHS_WAVEFORM_SAMPLES ] )
            riseStop = maxPt + SAMP_DIGHS_WAVEFORM_SAMPLES - SAMP_DIGHS_WAVEFORM_SAMPLES * 2 / bitsPerWaveform + integer ( xtrmAry [ 4 ] ) - 1
            xtrmAry = xtrm ( ary3 [ minPt + SAMP_DIGHS_WAVEFORM_SAMPLES - SAMP_DIGHS_WAVEFORM_SAMPLES * 2 / bitsPerWaveform : minPt + SAMP_DIGHS_WAVEFORM_SAMPLES ] )
            fallStart = minPt + SAMP_DIGHS_WAVEFORM_SAMPLES - SAMP_DIGHS_WAVEFORM_SAMPLES * 2 / bitsPerWaveform + integer ( xtrmAry [ 4 ] ) - 1
        endif
    else

        --Find start of Fall Time
        slice1 = maxPt+1
        slice2 = zeroCrossingN
        i = slice2 - slice1 + 1
        vp_clip ( x , ary2 [ slice1 : slice2 ] , 1 , ary3 [ slice1 : slice2 ] , 1 , i ) 
        --Search backwards from zero crossing 
        vp_reverse ( ary3 [ slice1 : slice2 ] , 1 , i )
        xtrmAry = xtrm ( ary3 [ slice1 : slice2 ] ) -- max to zero crossing (falling)
        fallStart = slice2 - integer ( xtrmAry [ 2 ] ) + 1

        --Find end of Rise Time
        slice1 = zeroCrossingP
        if maxPt < zeroCrossingP then
            slice2 = maxPt + SAMP_DIGHS_WAVEFORM_SAMPLES
        else
            slice2 = maxPt 
        end_if
        i = slice2 - slice1 + 1
        vp_clip ( x , ary2 [ slice1 : slice2 ] , 1 , ary3 [ slice1 : slice2 ] , 1 , i ) 
        xtrmAry = xtrm ( ary3 [ slice1 : slice2 ] ) -- zero crossing (falling) to min
        xtrmAry = xtrm ( ary3 [ slice1 : slice2 ] ) -- zero crossing (rising) to max
        riseStop = slice1 + integer ( xtrmAry [ 2 ] ) - 1

    endif   
    scaledWaveform = ary2 [ zeroCrossingP : zeroCrossingP  + SAMP_DIGHS_WAVEFORM_SAMPLES - 1 ]   
    results [ PAR_RISE_TIME ] = double ( riseStop - riseStart ) * double(bitsPerWaveform) / dataRate / double( length )
    results [ PAR_FALL_TIME ] = double ( fallStop - fallStart ) * double(bitsPerWaveform) / dataRate / double( length )
    if zeroCrossingN > zeroCrossingP then
        results [ PAR_WIDTH_P ] = double ( zeroCrossingN - zeroCrossingP ) * double(bitsPerWaveform) / dataRate / double( length )
    else
        results [ PAR_WIDTH_P ] = double ( zeroCrossingN + SAMP_DIGHS_WAVEFORM_SAMPLES - zeroCrossingP ) * double(bitsPerWaveform) / dataRate / double( length )
    end_if

    results [ PAR_VOD_P ] = double(max_v - min_v)

    if use_square and not(preemphasisWaveformExpected) then
        ary3[1:SAMP_DIGHS_WAVEFORM_SAMPLES] = abs(scaledWaveform)
        square_time = double(bitsPerWaveform)/dataRate
--orig  results [ PAR_VOD_D ] = double(avg(ary3[1:SAMP_DIGHS_WAVEFORM_SAMPLES])) * 2.0 * square_time/(square_time - (results [ PAR_RISE_TIME ] + results [ PAR_FALL_TIME ])/1.2)

--new average based on segment after rise and before fall
        if(SAMP_DIGHS_WAVEFORM_SAMPLES/2-fallStop+fallStart <= riseStop-riseStart) then
            results [ PAR_VOD_D ] = 999999.0
        else
            results [ PAR_VOD_D ] = double(avg(ary3[riseStop-riseStart:SAMP_DIGHS_WAVEFORM_SAMPLES/2-fallStop+fallStart])*2.0)
        end_if
        
        --Scale for top vs peak
        results [ PAR_RISE_TIME ] = results [ PAR_RISE_TIME ] * results [ PAR_VOD_D ] / results [ PAR_VOD_P ]
        results [ PAR_FALL_TIME ] = results [ PAR_FALL_TIME ] * results [ PAR_VOD_D ] / results [ PAR_VOD_P ]
    else
        results [ PAR_VOD_D ] = double(pos_v - neg_v)
    end_if

    results [ DUMMY ] = 0.0
endbody
--------------------------------------------------------------------------------
procedure SC_waveformParametricsMultisite ( inWave , splitterAttenScale , num_ports, bitsPerWaveform , dataRate , scaledWaveform , ary2 , ary3 , preemphasisWaveformExpected , use_square , results)
--------------------------------------------------------------------------------
in_out multisite float  : inWave [ ?,? ]
in float                : splitterAttenScale
in integer              : num_ports
in integer              : bitsPerWaveform
in double               : dataRate
in_out multisite float  : scaledWaveform [ ?,? ]      -- size of inWave
in_out float            : ary3 [ ? ]                  -- 3 * size of inWave
in_out float            : ary2 [ ? ]                  -- 3 * size of inWave
in boolean              : preemphasisWaveformExpected
in boolean              : use_square
in_out multisite double : results [ ?,?] 
local
    word list[16]       : act_sites
    integer             : num_sites
    integer             : site_ptr
    integer             : chan_ptr
    word                : site, chan
end_local


body

act_sites = get_active_sites
num_sites = len(act_sites)

for site_ptr = 1 to num_sites do
    site = act_sites[site_ptr]
    for chan_ptr = 1 to num_ports do    
        SC_waveformParametrics ( inWave[site,chan_ptr] , 1.0 , bitsPerWaveform , dataRate , scaledWaveform[site,chan_ptr] , ary2 , ary3 , preemphasisWaveformExpected , use_square , results[site,chan_ptr])
    end_for
end_for


endbody
--------------------------------------------------------------------------------

procedure SetupSpreadSpectrumMeas(SampDighsPins,SpreadExpected,HighDataRate,BitsPerWaveform,MeasLevelMax,SamplerConnection,L_O_Freq,FreqBinSize,DownSpreadingRef)
---------------------------------------------------------------------------------------------------------------------
in pin list[MAX_DIGHS]       : SampDighsPins     -- Selected DIGHS Channels                
in float                     : SpreadExpected    -- Percentage of Spectrum to spread (100 X (MaxFreq - MinFreq)/NomFreq)
in double                    : HighDataRate      -- High Serial Data rate
in integer                   : BitsPerWaveform   -- Number of device bits captured in waveform
in float                     : MeasLevelMax      --  Maximum differential voltage expected in measured waveform (Sets up DIGHS measurement range)
in multisite integer         : SamplerConnection[MAX_DIGHS] -- AUX_IN_ODD_CHAN, DATA_IN_ODD_CHAN, AUX_IN_EVEN_CHAN or DATA_IN_EVEN_CHAN
out double                   : L_O_Freq          -- Spectrum Reference Frequency -- Local Oscillator
out double                   : FreqBinSize       -- Size of frequency bins -- Capture Resolution Bandwidth
out double                   : DownSpreadingRef  -- Spectrum Reference for Top of Down Spreading Range
----------------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------------
-- This procedure sets up the VXGTO Front End samplers for capturing a Spread Spectrum.  
-- Companion procedures are "SpreadSpectrumMeasurement" and "SpreadSpectrumTest".
--
-- This procedure is called by "SpreadSpectrumTest" to set up the samplers.  Then procedure 
-- "SpreadSpectrumMeasurement" capture the waveform with Sampler.  After the waveform is captured, 
-- procedure "SpreadSpectrumTest" processes the measurements and datalog the results.
----------------------------------------------------------------------------------------------
local
    double                   : UndersamplingFactor  -- Scale factor for undersampling 
    double                   : SampleFrequency
    double                   : FreqOffset
    double                   : SamplerClkFreq
    double                   : LO_Offset 
    double                   : DighsFreq 
    word list[4]             : SampClk
    word list[2]             : SampClkSel = <::>
end_local

body
    if HighDataRate/double(BitsPerWaveform) > 150MHz then 
        LO_Offset = SAMP_DIGHS_SPECTRUM_CLK_FREQ/4.0 
    else_if HighDataRate/double(BitsPerWaveform) > 75MHz then 
        LO_Offset = SAMP_DIGHS_SPECTRUM_CLK_FREQ/8.0 
    else_if HighDataRate/double(BitsPerWaveform) > 37.5MHz then 
        LO_Offset = SAMP_DIGHS_SPECTRUM_CLK_FREQ/16.0 
    else_if HighDataRate/double(BitsPerWaveform) > 18.75MHz then 
        LO_Offset = SAMP_DIGHS_SPECTRUM_CLK_FREQ/32.0 
    else 
        LO_Offset = SAMP_DIGHS_SPECTRUM_CLK_FREQ/64.0 
    end_if 
    DighsFreq            = LO_Offset * 4.0
    FreqBinSize          = double(SAMP_DIGHS_SPECTRUM_CLK_FREQ/SAMP_DIGHS_SSC_MEAS_SAMPLES)
    L_O_Freq             =  HighDataRate/double(BitsPerWaveform) * (1.0 - double(SpreadExpected)/200.0) - LO_Offset 

    UndersamplingFactor  = double(integer(L_O_Freq * 4.0/SAMP_DIGHS_MAX_SAMPLE_CLK_FREQ + 1.0))
    SampleFrequency      = L_O_Freq/UndersamplingFactor
    
    if  L_O_Freq * 4.0 >= SAMP_DIGHS_MAX_SAMPLE_CLK_FREQ then
        SamplerDivider      =  4
    else
        SamplerDivider = integer(SAMP_DIGHS_MAX_SAMPLE_CLK_FREQ/2.0/SampleFrequency) * 2
        if SamplerDivider > 60 then
             SamplerDivider = 60
        end_if
    end_if
    
    SamplerClkFreq       = double(SamplerDivider) * SampleFrequency      
    DownSpreadingRef     = HighDataRate/double(BitsPerWaveform) - L_O_Freq

    -- PROGRAM SAMPLER CLOCK
    if use_dighsb then
        SampClk             = dighsb_ptc(SampDighsPins)
    else
        SampClk             = dighs_ptc(SampDighsPins)
    end_if
    if (1 in SampClk) or (2 in SampClk) then
       SampClkSel = <:1:>
    end_if
    if (3 in SampClk) or (4 in SampClk) then
       SampClkSel = SampClkSel + <:2:>
    end_if

    GTB_SelectSampleClockOutput ( SampClkSel , DIVIDED_CLOCK )
    SetSampleClkFrequency(SamplerClkFreq )
    SetSamplerDivider(SampDighsPins,SamplerDivider)
    
    -- PROGRAM DIGHS
    ConnectDighsToSamp(SamplerConnection,SampDighsPins )         
    if use_dighsb then
        set dighsb SampDighsPins sample rate to DighsFreq
        set dighsb SampDighsPins to max MeasLevelMax/2.0 lpf (HighDataRate/double(BitsPerWaveform) - L_O_Freq) * 1.25
         if DighsFreq < 50MHz then
             enable dighsb SampDighsPins low sample clock mode
         end_if
    else
         set dighs chan SampDighsPins sample rate to DighsFreq
         if (HighDataRate/double(BitsPerWaveform) - L_O_Freq) > 25MHz then
                set dighs chan SampDighsPins to max MeasLevelMax/2.0 lpf mhz65
         else
                set dighs chan SampDighsPins to max MeasLevelMax/2.0 lpf mhz32
         end_if   
    end_if
  
end_body

procedure SpreadSpectrumMeasurement(SampDighsPins,StartOnTrigger,SpectrumReferenceFreq,DownSpreadingRef,ResBandwidth,DownSpreading,peak_reduction,spreading_range,LowFrequency,HighFrequency)
in pin list[MAX_DIGHS]       : SampDighsPins                    -- Selected DIGHS Channels                
in boolean                   : StartOnTrigger                   -- Waveform capture starts on detection of sync1 from digital pattern
in double                    : SpectrumReferenceFreq            -- For Frequency measurement pass this parameter in from procedure SetupSpreadSpectrumMeas 
in double                    : DownSpreadingRef                 -- For Down Spreading measurement pass this parameter in from procedure SetupSpreadSpectrumMeas 
in float                     : ResBandwidth                     -- Resolution Bandwidth, Enter value between 6.25KHz and 500KHz, 100KHz default value.
in boolean                   : DownSpreading                    -- Set true if Nominal Data Rate is Maximum Data rate otherwise set false
out multisite  float         : peak_reduction[MAX_DIGHS]        -- Measure peak reduction
out multisite  float         : spreading_range[MAX_DIGHS]       -- Measured  Spreading Range
out multisite  float         : LowFrequency[MAX_DIGHS]          -- Measured  Low frequency
out multisite  float         : HighFrequency[MAX_DIGHS]         -- Measured  High Frequency
---------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------
-- This procedure is used to read the spectrum of a Spread Spectrum Clock, or the 
-- or the spectrum of a square data pattern driven by a Spread Spectrum Clock. This
-- procedure is a companion to procedures "SetupSpreadSpectrumMeas" and "SpreadSpectrumTest".
--
-- This procedure and procedure "SetupSpreadSpectrumMeas" are called by procedure 
-- "SpreadSpectrumTest" to setup, measure and datalog Spread Spectrum test results.  
---------------------------------------------------------------------------------------
local
    float                : wave[SAMP_DIGHS_SSC_MEAS_SAMPLES]
    float                : pwr_fft_oversample[SAMP_DIGHS_SSC_MEAS_SAMPLES/2+1]
    float                : pwr_fft[SAMP_DIGHS_SSC_MEAS_SAMPLES/2+1]
    float                : pwr_fft_time[SAMP_DIGHS_SSC_MEAS_SAMPLES/2+1]
    float                : RefAry[SAMP_DIGHS_SSC_MEAS_SAMPLES/2+1]
    float                : PR_Ary[SAMP_DIGHS_SSC_MEAS_SAMPLES/2+1]
    float                : ZeroSS_Ary[SAMP_DIGHS_SSC_MEAS_SAMPLES/2+1]
    float                : TestAry[SAMP_DIGHS_SSC_MEAS_SAMPLES/2+1]
    float                : TestAry2[SAMP_DIGHS_SSC_MEAS_SAMPLES/2+1]
    float                : SpectrumSamples
    float                : TotalPower 
    float                : XtrmAry[4]
    float                : SpectrumBinSize
    float                : PR_adj
    float                : LowBin
    float                : HighBin
    float                : FreqBinSize 
    float                : DighsFreq                    
    integer              : SumSteps
    integer              : SpectrumBins
    double               : RefOffset
    integer              : RefBin
    integer              : j,k,m,n
    integer              : SiteCount
    integer              : PortCount
    integer              : ChanPtr
    integer              : SitePtr
    integer              : DighsSamples
    word list[16]        : SiteList
    word list[MAX_DIGHS] : DigPorts
    boolean              : t 
end_local

body
     if use_dighsb then
        DigPorts   = dighsb_ptc(SampDighsPins)
     else
        DigPorts   = dighs_ptc(SampDighsPins)
     end_if 
     PortCount = len(SampDighsPins)
     SiteList  = get_active_sites
     SiteCount = len(SiteList)
   
     if DownSpreadingRef >= SAMP_DIGHS_SPECTRUM_CLK_FREQ/4.0 then
          DighsSamples = SAMP_DIGHS_SSC_MEAS_SAMPLES
          DighsFreq = SAMP_DIGHS_SPECTRUM_CLK_FREQ
     else_if DownSpreadingRef >= SAMP_DIGHS_SPECTRUM_CLK_FREQ/8.0 then
          DighsSamples = SAMP_DIGHS_SSC_MEAS_SAMPLES/2
          DighsFreq = SAMP_DIGHS_SPECTRUM_CLK_FREQ/2.0
     else_if DownSpreadingRef >= SAMP_DIGHS_SPECTRUM_CLK_FREQ/16.0 then
          DighsSamples = SAMP_DIGHS_SSC_MEAS_SAMPLES/4
          DighsFreq = SAMP_DIGHS_SPECTRUM_CLK_FREQ/4.0
     else_if DownSpreadingRef >= SAMP_DIGHS_SPECTRUM_CLK_FREQ/32.0 then
          DighsSamples = SAMP_DIGHS_SSC_MEAS_SAMPLES/8
          DighsFreq = SAMP_DIGHS_SPECTRUM_CLK_FREQ/8.0
     else_if DownSpreadingRef >= SAMP_DIGHS_SPECTRUM_CLK_FREQ/64.0 then
          DighsSamples = SAMP_DIGHS_SSC_MEAS_SAMPLES/16
          DighsFreq = SAMP_DIGHS_SPECTRUM_CLK_FREQ/16.0
      end_if
      
     if use_dighsb then
         if StartOnTrigger then
              connect dighsb DigPorts trigger to sync2       
              define dighsb DigPorts capture "a" at 0 as DighsSamples points
              start dighsb DigPorts capture "a" triggered
         else
             define dighsb DigPorts capture "a" at 0 as DighsSamples points
             start dighsb DigPorts capture "a"
         end_if
              wait for dighsb DigPorts timeout 100ms into  t
              read dighsb DigPorts capture "a" for DighsSamples points into BifSpreadSpectrumData
     else
         if StartOnTrigger then
             measure dighs chan DigPorts for lword(DighsSamples) points into memory adr 1 trigger on sync2
         else
             measure dighs chan DigPorts for lword(DighsSamples) points into memory adr 1 
         end_if
         for SitePtr = 1 to SiteCount do  
            for ChanPtr = 1 to PortCount do
               read  dighs chan DigPorts[(SitePtr -1) * PortCount + ChanPtr] for lword(DighsSamples) points from memory adr 1 into BifSpreadSpectrumData[(SitePtr -1) * PortCount + ChanPtr,1:DighsSamples]
            end_for
        end_for    
     end_if 
     
     

     if  ResBandwidth > 1.0e9 then
         ResBandwidth = 100KHz
     else_if  (ResBandwidth > 500KHz) then
         ResBandwidth = 500KHz
     else_if (ResBandwidth < 6.25KHz) then
         ResBandwidth = 6.25KHz
     end_if
      
     FreqBinSize     = DighsFreq/float(DighsSamples)
     SumSteps        = integer(ResBandwidth/FreqBinSize)
     SpectrumBinSize = float(FreqBinSize) * float(SumSteps)
     SpectrumBins    = DighsSamples/SumSteps/2 + 1

     PR_adj = 10.0 * log(SpectrumBinSize/ResBandwidth)
     if (DownSpreadingRef > double(DighsFreq)/4.0) and (DownSpreadingRef < double(DighsFreq)/2.0) then
         if DownSpreading then
             RefOffset = - (DownSpreadingRef + 2.0 * double(SpectrumBinSize))/1.0e6
             RefBin = integer(float(DownSpreadingRef)/SpectrumBinSize) + 2
         else
             RefOffset = - double(DighsFreq)/4.0e6
             RefBin = integer(DighsFreq/4.0/SpectrumBinSize)
         end_if
     end_if        
     
    
    
    for SitePtr = 1 to SiteCount do
      for ChanPtr = 1 to PortCount do
       
        pwr_fft_time = 0.0 
        wave[1:DighsSamples] = BifSpreadSpectrumData[(SitePtr -1) * PortCount + ChanPtr,1:DighsSamples] 
        pwr_fft_oversample[1:DighsSamples/2+1] = power_fft(wave[1:DighsSamples]) 
        TotalPower = sum(pwr_fft_oversample[2:DighsSamples/2+1])  
         for j = 1 to SumSteps do
              vp_add(pwr_fft_time[2:SpectrumBins],1,pwr_fft_oversample[j+1:DighsSamples/2+1],SumSteps,pwr_fft_time[2:SpectrumBins],1,SpectrumBins-1)
        end_for
        pwr_fft[1:SpectrumBins] = 10.0*log(pwr_fft_time[1:SpectrumBins]/TotalPower + 1.0e-12) + PR_adj
        XtrmAry = xtrm(pwr_fft[1:SpectrumBins])
        peak_reduction[SiteList[SitePtr],ChanPtr] = -XtrmAry[1]
        PR_Ary = XtrmAry[1]
        RefAry = XtrmAry[1] - 3.0 
        vp_smin(RefAry[1],pwr_fft[1:SpectrumBins],1,TestAry,1,SpectrumBins)
        TestAry2[1:SpectrumBins] = RefAry[1:SpectrumBins] - TestAry[1:SpectrumBins]
        XtrmAry = xtrm(TestAry2[1:SpectrumBins*3/4])
        LowBin = XtrmAry[4] - 1.0
        vp_reverse(TestAry2[1:SpectrumBins],1,SpectrumBins)
        XtrmAry = xtrm(TestAry2[1:SpectrumBins - integer(LowBin) ])
        HighBin =float(SpectrumBins) - XtrmAry[4]
        spreading_range[SiteList[SitePtr],ChanPtr] = SpectrumBinSize * (HighBin - LowBin)
        LowFrequency[SiteList[SitePtr],ChanPtr]    = float(SpectrumReferenceFreq) + SpectrumBinSize * (LowBin - 0.5)
        HighFrequency[SiteList[SitePtr],ChanPtr]   = float(SpectrumReferenceFreq) + SpectrumBinSize * (HighBin - 0.5)
        
        if DisplayMode then
             ZeroSS_Ary = 0.0
             n = integer(1.5e6/SpectrumBinSize)
             if n >integer(LowBin)/5 then
                 n = integer(LowBin)/5 + 1
             end_if
             m = integer(LowBin) - n
             k = SpectrumBins/m
             for j = 1 to k do
                 ZeroSS_Ary[1+(j-1)*m:j*m] = pwr_fft[2:m+1] 
             end_for
             ZeroSS_Ary[integer(HighBin) + n:SpectrumBins] = pwr_fft[integer(HighBin) + n:SpectrumBins] 
             ZeroSS_Ary[RefBin] = 0.0
                    -- observe pwr_fft for spectrum
                          -- a -g pwr_fft[1:SpectrumBins] ; grid
                          -- a -g PR_Ary[1:SpectrumBins]
                          -- a -g ZeroSS_Ary[1:SpectrumBins]
                                 --**** Enter Numeric values   -- scale -mult SpectrumBinSize -offset RefOffset         
                          -- units -x MHz
                          -- units -y dB                 
 
            wait(0mS)   -- SET BREAKPOINT HERE TO DISPLAY WAVEFORM 
        end_if

     end_for
   end_for

end_body


procedure SpreadSpectrumTest(SampDighsPins,SpreadPercent,HighBitRate,BitsPerWaveform,MeasLevelMax,MeasurementScale,SamplerConnection,StartOnTrigger,ResBandwidth,DownSpreading,ResultTest,peak_reduction_limits,spreading_range_limits,low_bit_rate_limits,high_bit_rate_limits,modulation_freq_limits)
in pin list[MAX_DIGHS]     : SampDighsPins                  -- Selected DIGHS Channels                
in float                   : SpreadPercent                  -- Expected Percentage of Spectrum to spread (100 X (MaxFreq - MinFreq)/NomFreq)
in double                  : HighBitRate                    -- Maximum Expected Serial Data rate
in integer                 : BitsPerWaveform                -- Number of device bits captured in data waveform, for clock input enter 1  
in float                   : MeasLevelMax                   --  Maximum differential voltage expected in measured waveform (Sets up DIGHS measurement range)
in  float                  : MeasurementScale               -- Scale factor to correct for attenuation in measurement path  
in multisite integer       : SamplerConnection[MAX_DIGHS]   -- AUX_IN_ODD_CHAN, DATA_IN_ODD_CHAN, AUX_IN_EVEN_CHAN or DATA_IN_EVEN_CHAN
in boolean                 : StartOnTrigger                 -- Set true to start on trigger or false to start immediately  
in float                   : ResBandwidth                   -- Resolution Bandwidth, Enter 6.25KHz, 12.5KHz, 25KHz, 50KHz or 100KHz
in boolean                 : DownSpreading                  -- Set true if Nominal Data Rate is Maximum Data rate otherwise set false
in integer                 : ResultTest[5]                  -- See Below     
in_out array of float_test : peak_reduction_limits          -- Set ResultTest[1] to 1 to perform test, or set ResultTest[1] to 0 to ignore test
in_out array of float_test : spreading_range_limits         -- Set ResultTest[2] to 1 to perform test, or set ResultTest[1] to 0 to ignore test
in_out array of float_test : low_bit_rate_limits            -- Set ResultTest[2] to 1 to perform test, or set ResultTest[1] to 0 to ignore test
in_out array of float_test : high_bit_rate_limits           -- Set ResultTest[2] to 1 to perform test, or set ResultTest[1] to 0 to ignore test
in_out array of float_test : modulation_freq_limits         -- Set ResultTest[3] to 1 to perform test, or set ResultTest[1] to 0 to ignore test
local
     double                : SpectrumReferenceFreq          -- Spectrum Reference Frequency
     double                : FreqBinSize                    -- Size of frequency bins -- Capture Resolution Bandwidth
     double                : DownSpreadingRef               -- Spectrum Reference for Top of Down Spreading Range
     multisite  float      : peak_reduction[MAX_DIGHS]      -- Measure peak reduction
     multisite  float      : low_bit_rate[MAX_DIGHS]        -- Low data rate measured
     multisite  float      : high_bit_rate[MAX_DIGHS]       -- High data rate measured
     multisite  float      : low_frequency[MAX_DIGHS]       -- Measured Low Frequency
     multisite  float      : high_frequency[MAX_DIGHS]      -- Measured High Frequency
     multisite  float      : spreading_range[MAX_DIGHS]     -- Measured Spreading Range
     multisite  float      : modulation_freq[MAX_DIGHS]     -- Modulation Frequency
end_local
body
    if (ResultTest[1]) = 1 or  (ResultTest[2] = 1) or  (ResultTest[3] = 1) or  (ResultTest[4] = 1) then
        SetupSpreadSpectrumMeas(SampDighsPins,SpreadPercent,HighBitRate,BitsPerWaveform,MeasLevelMax/MeasurementScale,SamplerConnection,SpectrumReferenceFreq,FreqBinSize,DownSpreadingRef)
        wait(10.0ms)
        SpreadSpectrumMeasurement(SampDighsPins,StartOnTrigger,SpectrumReferenceFreq,DownSpreadingRef,ResBandwidth,DownSpreading,peak_reduction,spreading_range,low_frequency,high_frequency)
    end_if
    if (ResultTest[5]) = 1  then
        SetupSpreadSpecModFreqMeas(SampDighsPins,HighBitRate,BitsPerWaveform,MeasLevelMax/MeasurementScale,SamplerConnection,StartOnTrigger)
        wait(10.0ms)
        SpreadSpecModFreqMeasurement(SampDighsPins,float(HighBitRate)/float(BitsPerWaveform),StartOnTrigger,modulation_freq)
    end_if
    
    if  ResultTest[1] = 1 then
        test_value peak_reduction with peak_reduction_limits mode TVM_PINS 
     end_if
    if  ResultTest[2] = 1 then 
        test_value spreading_range with spreading_range_limits mode TVM_PINS
    end_if
    if  ResultTest[3] = 1 then
        low_bit_rate = low_frequency * float(BitsPerWaveform)
        test_value low_bit_rate with low_bit_rate_limits mode TVM_PINS
    end_if
    if  ResultTest[4] = 1 then
        high_bit_rate = high_frequency * float(BitsPerWaveform)
        test_value high_bit_rate with high_bit_rate_limits mode TVM_PINS
    end_if
    if  ResultTest[5] = 1 then
        test_value modulation_freq with modulation_freq_limits mode TVM_PINS
    end_if

end_body

procedure SetupSpreadSpecModFreqMeas(SampDighsPins,HighDataRate,BitsPerWaveform,MeasLevelMax,SamplerConnection,StartOnTrigger)
---------------------------------------------------------------------------------------------------------------------
in pin list[MAX_DIGHS]       : SampDighsPins     -- Selected DIGHS Channels                
in double                    : HighDataRate      -- High Serial Data rate
in integer                   : BitsPerWaveform   -- Number of device bits captured in waveform
in float                     : MeasLevelMax      --  Maximum differential voltage expected in measured waveform (Sets up DIGHS measurement range)
in multisite integer         : SamplerConnection[MAX_DIGHS] -- AUX_IN_ODD_CHAN, DATA_IN_ODD_CHAN, AUX_IN_EVEN_CHAN or DATA_IN_EVEN_CHAN
in boolean                   : StartOnTrigger    -- Set true to start on trigger or false to start immediately  
----------------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------------
-- This procedure sets up the VXGTO Front End samplers for capturing a Spread Spectrum.  
-- Companion procedures are "SpreadSpecModFreqMeasurement" and "SpreadSpectrumTest".
--
-- This procedure is called by "SpreadSpectrumTest" to set up the samplers.  Then procedure 
-- "SpreadSpecModFreqMeasurement" capture the waveform with Sampler and measures the modulation frequency. 
-- After the modulation frequency is measured, procedure "SpreadSpectrumTest" processes and datalogs the results.
----------------------------------------------------------------------------------------------
local
    double                   : UndersamplingFactor  -- Scale factor for undersampling 
    double                   : SampleFrequency
    double                   : SamplerClkFreq 
    double                   : L_O_Freq 
    double                   : DighsFreq                    
    word list[4]             : SampClk
    word list[2]             : SampClkSel = <::>
end_local

body
    if HighDataRate/double(BitsPerWaveform) > 150MHz then 
          DighsFreq = SAMP_DIGHS_SPECTRUM_CLK_FREQ
    else_if HighDataRate/double(BitsPerWaveform) > 75MHz then 
          DighsFreq = SAMP_DIGHS_SPECTRUM_CLK_FREQ/2.0
    else_if HighDataRate/double(BitsPerWaveform) > 37.5MHz then 
          DighsFreq = SAMP_DIGHS_SPECTRUM_CLK_FREQ/4.0
    else_if HighDataRate/double(BitsPerWaveform) > 18.75MHz then 
          DighsFreq = SAMP_DIGHS_SPECTRUM_CLK_FREQ/8.0
    else 
          DighsFreq = SAMP_DIGHS_SPECTRUM_CLK_FREQ/16.0
    end_if 


    L_O_Freq             =  HighDataRate/double(BitsPerWaveform) ---- - 1.0MHz
    UndersamplingFactor  = double(integer(L_O_Freq * 4.0/SAMP_DIGHS_MAX_SAMPLE_CLK_FREQ + 1.0))
    SampleFrequency      = L_O_Freq/UndersamplingFactor
    
    if  L_O_Freq * 4.0 >= SAMP_DIGHS_MAX_SAMPLE_CLK_FREQ then
        SamplerDivider      =  4
    else
        SamplerDivider = integer(SAMP_DIGHS_MAX_SAMPLE_CLK_FREQ/2.0/SampleFrequency) * 2
        if SamplerDivider > 60 then
             SamplerDivider = 60
        end_if
    end_if
   
    SamplerClkFreq       = double(SamplerDivider) * SampleFrequency      

    -- PROGRAM SAMPLER CLOCK
    if use_dighsb then
        SampClk             = dighsb_ptc(SampDighsPins)
    else
        SampClk             = dighs_ptc(SampDighsPins)
    end_if
    if (1 in SampClk) or (2 in SampClk) then
       SampClkSel = <:1:>
    end_if
    if (3 in SampClk) or (4 in SampClk) then
       SampClkSel = SampClkSel + <:2:>
    end_if

    GTB_SelectSampleClockOutput ( SampClkSel , DIVIDED_CLOCK )
    SetSampleClkFrequency(SamplerClkFreq )
    SetSamplerDivider(SampDighsPins,SamplerDivider)
    
    -- PROGRAM DIGHS
    ConnectDighsToSamp(SamplerConnection,SampDighsPins )         
    if use_dighsb then
        set dighsb SampDighsPins sample rate to DighsFreq
        set dighsb SampDighsPins to max MeasLevelMax/2.0 lpf mhz22
        if DighsFreq < 50MHz then
            enable dighsb SampDighsPins low sample clock mode
        end_if
    else
         set dighs chan SampDighsPins sample rate to DighsFreq
         set dighs chan SampDighsPins to max MeasLevelMax/2.0 lpf mhz32
    end_if  
end_body

procedure SpreadSpecModFreqMeasurement(SampDighsPins,HighWaveformFreq,StartOnTrigger,ModulationFreq)
in pin list[MAX_DIGHS]       : SampDighsPins                    -- Selected DIGHS Channels                
in float                     : HighWaveformFreq                 -- High Waveform Frequency -- DataRate/BitsPerwaveform
in boolean                   : StartOnTrigger                   -- Waveform capture starts on detection of sync1 from digital pattern
out multisite  float         : ModulationFreq[MAX_DIGHS]        -- Measure Modulation Frequency
---------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------
-- This procedure is used to capture waveform samples of a Spread Spectrum Clock, or the 
-- or the spectrum of a square data pattern driven by a Spread Spectrum Clock. This
-- procedure is a companion to procedures "SetupSpreadSpecModFreqMeas" and "SpreadSpectrumTest".
--
-- To use this procedure, first "SetupSpreadSpecModFreqMeas" is executed to set up the samplers 
-- After the waveform is captured, this procedure measures the spectrums modulation
-- frequency. "SetupSpreadSpecModFreqMeas and this procedure are called by "SpreadSpectrumTest". 
-- After calling these two procedures "SpreadSpectrumTest" processes the measurements and
-- datalogs the results.
---------------------------------------------------------------------------------------
local
    float                : StepSize
    float                : SpreadData[SAMP_DIGHS_SSC_MEAS_SAMPLES] 
    float                : SpreadData2[SAMP_DIGHS_SSC_MEAS_SAMPLES] 
    float                : ModulationSteps   
    float                : XtrmAry[4]
    float                : DighsFreq
    float                : Clip
    integer              : ShiftSteps  
    integer              : Marker1   
    integer              : Marker2   
    integer              : j,k,l
    integer              : SiteCount
    integer              : PortCount
    integer              : ChanPtr
    integer              : SitePtr
    integer              : DighsSamples
    word list[16]        : SiteList
    word list[MAX_DIGHS] : DigPorts
    boolean              : t 
end_local

body

    if HighWaveformFreq > 150MHz then 
          DighsFreq = SAMP_DIGHS_SPECTRUM_CLK_FREQ
          DighsSamples = SAMP_DIGHS_SSC_MEAS_SAMPLES
    else_if HighWaveformFreq > 75MHz then 
          DighsFreq = SAMP_DIGHS_SPECTRUM_CLK_FREQ/2.0
          DighsSamples = SAMP_DIGHS_SSC_MEAS_SAMPLES/2
    else_if HighWaveformFreq > 37.5MHz then 
          DighsFreq = SAMP_DIGHS_SPECTRUM_CLK_FREQ/4.0
          DighsSamples = SAMP_DIGHS_SSC_MEAS_SAMPLES/4
    else_if HighWaveformFreq > 18.75MHz then 
          DighsFreq = SAMP_DIGHS_SPECTRUM_CLK_FREQ/8.0
          DighsSamples = SAMP_DIGHS_SSC_MEAS_SAMPLES/8
    else 
          DighsFreq = SAMP_DIGHS_SPECTRUM_CLK_FREQ/16.0
          DighsSamples = SAMP_DIGHS_SSC_MEAS_SAMPLES/16
    end_if 

     if use_dighsb then
        DigPorts   = dighsb_ptc(SampDighsPins)
     else
        DigPorts   = dighs_ptc(SampDighsPins)
     end_if 
     PortCount = len(SampDighsPins)
     SiteList  = get_active_sites
     SiteCount = len(SiteList)

     if use_dighsb then
         if StartOnTrigger then
              connect dighsb DigPorts trigger to sync2       
              define dighsb DigPorts capture "a" at 0 as DighsSamples points
              start dighsb DigPorts capture "a" triggered
         else
             define dighsb DigPorts capture "a" at 0 as DighsSamples points
             start dighsb DigPorts capture "a"
         end_if
              wait for dighsb DigPorts timeout 100ms into  t
              read dighsb DigPorts capture "a" for DighsSamples points into BifSpreadSpectrumData
     else
         if StartOnTrigger then
             measure dighs chan DigPorts for lword(DighsSamples) points into memory adr 1 trigger on sync2
         else
             measure dighs chan DigPorts for lword(DighsSamples) points into memory adr 1
         end_if
         for SitePtr = 1 to SiteCount do  
            for ChanPtr = 1 to PortCount do
               read  dighs chan DigPorts[(SitePtr -1) * PortCount + ChanPtr] for lword(DighsSamples) points from memory adr 1 into BifSpreadSpectrumData[(SitePtr -1) * PortCount + ChanPtr,1:DighsSamples]
            end_for
        end_for    
     end_if 

     StepSize   =   1.0/DighsFreq
    
    k = 10
    l = DighsSamples/2 
    for SitePtr = 1 to SiteCount do
      for ChanPtr = 1 to PortCount do
       
        SpreadData[1:DighsSamples] = BifSpreadSpectrumData[(SitePtr -1) * PortCount + ChanPtr,1:DighsSamples] 
        SpreadData[1:DighsSamples] = fft(SpreadData[1:DighsSamples])
        for j = k to l do
            SpreadData[2*j]   = SpreadData[2*j] * float(j)/float(k)
            SpreadData[2*j-1] = SpreadData[2*j-1] * float(j)/float(k)
        end_for
        SpreadData[1:DighsSamples] = inverse_fft(SpreadData[1:DighsSamples])
        SpreadData[1:DighsSamples] = abs(SpreadData[1:DighsSamples])
        SpreadData2 = 0.0
        for j = 1 to 50 do
            SpreadData2[1:DighsSamples-50] = SpreadData2[1:DighsSamples-50] + SpreadData[j:DighsSamples-51+j] 
        end_for
        XtrmAry = xtrm(SpreadData2[1:DighsSamples])
        SpreadData[1:DighsSamples] = SpreadData2[1:DighsSamples]/XtrmAry[1]
        Clip = 0.2
        vp_smax(Clip,SpreadData,1,SpreadData,1,DighsSamples)
        Clip = 0.9
        vp_smin(Clip,SpreadData,1,SpreadData,1,DighsSamples)
        XtrmAry = xtrm(SpreadData[1:DighsSamples])
        Marker1 = integer(XtrmAry[4])
        XtrmAry = xtrm(SpreadData[Marker1:DighsSamples])
        Marker1 = integer(XtrmAry[2]) + Marker1 -1
        XtrmAry = xtrm(SpreadData[Marker1:DighsSamples])
        Marker2 = integer(XtrmAry[4]) + Marker1 -1
        XtrmAry = xtrm(SpreadData[Marker2:DighsSamples])
        Marker2 = integer(XtrmAry[2]) + Marker2 -1
        ModulationSteps = float(Marker2 - Marker1)
        ModulationFreq[SiteList[SitePtr],ChanPtr] = float(DighsFreq)/ModulationSteps
        
        
        if DisplayMode then
                    -- observe SpreadData
                          -- a -g SpreadData[1:DighsSamples] ; grid
                                 --**** Enter Numeric values   -- scale -mult StepSize -offset 0.0        
                          -- units -x nS
                          -- units -y dB                 
 
            wait(0mS)   -- SET BREAKPOINT HERE TO DISPLAY WAVEFORM 
        end_if

     end_for
   end_for

end_body


procedure SamplerMultisiteSelect(Aux1Port,Data1Port,Aux2Port,Data2Port,Aux4Port,Data4Port)
out multisite integer : Aux1Port[1]  -- Single Channel Aux Port 4 Site Sampler Connection  
out multisite integer : Data1Port[1] -- Single Channel Data Port 4 Site Sampler Connection
out multisite integer : Aux2Port[2]  -- Single Channel Aux Port 4 Site Sampler Connection  
out multisite integer : Data2Port[2] -- Single Channel Data Port 4 Site Sampler Connection
out multisite integer : Aux4Port[4]  -- Single Channel Aux Port 4 Site Sampler Connection  
out multisite integer : Data4Port[4] -- Single Channel Data Port 4 Site Sampler Connection
body
    Aux1Port  = 0
    Data1Port = 0
    Aux2Port  = 0
    Data2Port = 0
    Aux4Port  = 0
    Data4Port = 0
    
    Aux1Port[1]  = AUX_IN_ODD_CHAN
    Aux1Port[2]  = AUX_IN_EVEN_CHAN 
    Aux1Port[3]  = AUX_IN_ODD_CHAN
    Aux1Port[4]  = AUX_IN_EVEN_CHAN 
    Data1Port[1] = DATA_IN_ODD_CHAN
    Data1Port[2] = DATA_IN_EVEN_CHAN
    Data1Port[3] = DATA_IN_ODD_CHAN
    Data1Port[4] = DATA_IN_EVEN_CHAN
    
    Aux2Port[1,1]  = AUX_IN_ODD_CHAN
    Aux2Port[1,2]  = AUX_IN_EVEN_CHAN 
    Aux2Port[2,1]  = AUX_IN_ODD_CHAN
    Aux2Port[2,2]  = AUX_IN_EVEN_CHAN 
    Data2Port[1,1] = DATA_IN_ODD_CHAN
    Data2Port[1,2] = DATA_IN_EVEN_CHAN
    Data2Port[2,1] = DATA_IN_ODD_CHAN
    Data2Port[2,2] = DATA_IN_EVEN_CHAN
    
    Aux4Port[1,1]  = AUX_IN_ODD_CHAN
    Aux4Port[1,2]  = AUX_IN_EVEN_CHAN 
    Aux4Port[1,3]  = AUX_IN_ODD_CHAN
    Aux4Port[1,4]  = AUX_IN_EVEN_CHAN 
    Data4Port[1,1] = DATA_IN_ODD_CHAN
    Data4Port[1,2] = DATA_IN_EVEN_CHAN
    Data4Port[1,3] = DATA_IN_ODD_CHAN
    Data4Port[1,4] = DATA_IN_EVEN_CHAN
end_body     
procedure AFE_SamplerSelection(SampDighsPins,Samplers,SamplerConnection)
 in pin list[MAX_DIGHS] :  SampDighsPins    -- Selected DIGHS Channels
 in integer             :  Samplers[?]      -- Array of Sampler Channels Enter Site 1 Samplers first, then Site 2's , Site 3's Site 4's 
                                            -- Valid Samplers are 1 thru 8 
 Out multisite integer  :  SamplerConnection[4] 
 -------------------------------------------------------------------------------------------------------------------------------------
--  This procedure produces the SamplerConnection Array that is to be passed into various test procedures within this Cadence module
-- SamplerDighs.mod.  Sampler connections to the digitizers are defined by the output array Sampler_Connection. 

-- *************** For the Analog Front End hardware **********************
-- 
--  Up to four digitizer channels can be passed into SampDighsPins.  In the standard configuration they are DIGHS 1 through 4.
--  Channels 1 through 4 are the 1V p-p input channels.
--  Channels 5 through 8 are the 2V p-p input channels.
--
--  Channels 1, 2, 5, and 6 are on Analog Front End board 1, and can connect only to digitizer channels 1 or 2
--  Channels 3, 4, 8, and 8 are on Analog Front End board 2, and can connect only to digitizer channels 3 or 4
 -------------------------------------------------------------------------------------------------------------------------------------
            
local
    integer            : Site
    integer            : Port
    integer            : Samp
    integer            : SampCount
    integer            : PortCount
    integer            : SitePtr
    integer            : SiteCount
    integer            : SamplerPointer[8]
  word list[16]        : SiteList
end_local
body

    PortCount  = len(SampDighsPins)
    SiteList   = get_active_sites
    SiteCount  = len(SiteList)
    SampCount  = dimsize(Samplers,1)
    Samp       = 0
    Site       = 0

    SamplerPointer[1] = 1
    SamplerPointer[2] = 3
    SamplerPointer[3] = 1
    SamplerPointer[4] = 3
    SamplerPointer[5] = 2
    SamplerPointer[6] = 4
    SamplerPointer[7] = 2
    SamplerPointer[8] = 4
    SamplerConnection = 0
    
    while Samp <> SampCount do
        Site = Site + 1
        for Port = 1 to PortCount do
            Samp = Samp + 1
            SamplerConnection[Site,Port] = SamplerPointer[Samplers[Samp]]
        end_for
    end_while
end_body     
procedure SpectraStripCableSim(FilterNumber,DataRate,BitsPerWaveform,CableLength,LengthInFeet)
in integer   : FilterNumber    -- Number identifying the filter to be generated, 0 < FilterNumber <= MAX_FILTERS
in double    : DataRate        -- Data Rate 
in integer   : BitsPerWaveform -- Number of bits to the waveform
in float     : CableLength     -- E nter length in Meters or in Feet
in boolean   : LengthInFeet    -- Set True if length is in feet otherwise set false if length is in Meters
------------------------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------------------
-- This procedure is used to generate a software filter with the spectral losses of "spectra Strip" cable.
-- The generated filter can be applied to a digitized waveform, producing the observation of the waveform 
-- as it would appear at the end of the defined cable.  
-- 
-- The generation of a  cable filter should be executed only once within the OnLoad flow.  Up to  MAX_FILTERS filters 
-- can be Generated, where MAX_FILTERS is a constant in this modules environment.  Each filter takes about 250ms to generated. 
-- Once generated the filter can be applied in production test to a digitized PRBS7 or K28.5 pattern.  Execution time is
-- about 15mS.
--  
--  This procedure is a companion to procedure "ApplyTransmissionFilter", which is used to apply the filter to 
-- a digitized waveform.
------------------------------------------------------------------------------------------------------------
local
    float   : Filter[SAMP_DIGHS_TRANS_FILTER]
    float   : CableSim[200]
    float   : CableSim2[10]
    float   : CableSim3[10]
    float   : K  
    float   :BinStep
    float   : Tone
    float   : ToneDelta
    float   : LossLevel
    float   : Scale
    integer : i
    integer : TonePtr
    integer : TonePtr2
    integer : TonePtr3
    integer : FilterSamples
    integer : SamplesPerBit   

end_local
body

     K = sqr(2.0)

    if BitsPerWaveform > 160 then
       SamplesPerBit = SAMP_DIGHS_ALT_EYE_SAMPS_PER_BIT
    else
        SamplesPerBit  = SAMP_DIGHS_EYE_SAMPLES_PER_BIT
    end_if    

MakeSpectraStripSim
if (BitsPerWaveform * SamplesPerBit) > SAMP_DIGHS_TRANS_FILTER/2 then  
    FilterSamples = SAMP_DIGHS_TRANS_FILTER
 else_if (BitsPerWaveform * SamplesPerBit) > SAMP_DIGHS_TRANS_FILTER/4 then  
    FilterSamples = SAMP_DIGHS_TRANS_FILTER/2
 else_if (BitsPerWaveform * SamplesPerBit) > SAMP_DIGHS_TRANS_FILTER/8 then  
    FilterSamples = SAMP_DIGHS_TRANS_FILTER/4
 else_if (BitsPerWaveform * SamplesPerBit) > SAMP_DIGHS_TRANS_FILTER/16 then  
    FilterSamples = SAMP_DIGHS_TRANS_FILTER/8
 else_if (BitsPerWaveform * SamplesPerBit) > SAMP_DIGHS_TRANS_FILTER/32 then  
    FilterSamples = SAMP_DIGHS_TRANS_FILTER/16
 end_if   

if LengthInFeet then
    K = K * 0.3048
 end_if
for i = 1 to 200 do
  CableSim[i] =  SpectraStripLoss[i]* K * CableLength
end_for
for i = 1 to 10 do
  CableSim2[i] =  SpectraStripLoss2[i]* K * CableLength
  CableSim3[i] =  SpectraStripLoss3[i]* K * CableLength
end_for
   
     Filter = 0.0
     Filter[1] = 0.5
   
   BinStep = float(DataRate) * float(SamplesPerBit)/float(FilterSamples)
   for i = 2 to FilterSamples/2 do
       Tone = BinStep * float(i-1)
       TonePtr = integer(Tone/100.0e6)
       TonePtr2 = integer(Tone/10.0e6)
       TonePtr3 = integer(Tone/1.0e6)
       if TonePtr3 = 0 then
           Filter[2*i-1] = 1.0
       else_if TonePtr3 < 10 then            
           ToneDelta = (Tone - float(TonePtr3)* 1.0e6)/1.0e6
           LossLevel = 10.0 ^ ((CableSim3[TonePtr3]  + ToneDelta * (CableSim3[TonePtr3 + 1] - CableSim3[TonePtr3]))/20.0)
           Filter[2*i-1] = LossLevel
       else_if TonePtr2 < 10 then            
           ToneDelta = (Tone - float(TonePtr2)* 10.0e6)/10.0e6
           LossLevel = 10.0 ^ ((CableSim2[TonePtr2]  + ToneDelta * (CableSim2[TonePtr2 + 1] - CableSim2[TonePtr2]))/20.0)
           Filter[2*i-1] = LossLevel
       else_if TonePtr < 200 then 
           ToneDelta = (Tone - float(TonePtr)* 100.0e6)/100.0e6
           LossLevel = 10.0 ^ ((CableSim[TonePtr]  + ToneDelta * (CableSim[TonePtr + 1] - CableSim[TonePtr]))/20.0)
           Filter[2*i-1] = LossLevel
       end_if
   end_for
   Scale = Filter[3]

Filter[1:FilterSamples] = inverse_fft(Filter[1:FilterSamples])
Filter[FilterSamples/2 + 1:FilterSamples] = 0.0
Filter[1:FilterSamples] = fft(Filter[1:FilterSamples]) 
Scale = Scale/sqr(Filter[3]^2.0 + Filter[4]^2.0)
Filter = Filter * Scale

TransFilter[FilterNumber,1:SAMP_DIGHS_TRANS_FILTER] = Filter
wait(0ms)

end_body
procedure Fr4MicrostripSim(FilterNumber,DataRate,BitsPerWaveform,TraceLength,Thickness6Mil,LengthInInches)
in integer   : FilterNumber    -- Number identifying the filter to be generated, 0 < FilterNumber <= MAX_FILTERS
in double    : DataRate        -- Data Rate 
in integer   : BitsPerWaveform -- Number of bits to the waveform
in float     : TraceLength     -- Enter length in centimeters or in inches
in boolean   : Thickness6Mil   -- Set true for 6 mill otherwise set false for 10 mill 
in boolean   : LengthInInches  -- Set True if length is in inches otherwise set false if length is in centimeters
------------------------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------------------
-- This procedure is used to generate a software filter with the spectral losses of a microstrip trace on FR4 .
-- The generated filter can be applied to a digitized waveform, producing the observation of the waveform 
-- as it would appear at the end of the defined circuit boiard trace.  
-- 
-- The generation of a FR4 microstrip filter should be executed only once within the OnLoad flow.  Up to MAX_FILTERS filters 
-- can be Generated, where MAX_FILTERS is a constant in this modules environment.  Each filter takes about 250ms to generated. 
-- Once generated the filter can be applied in production test to a digitized PRBS7 or K28.5 pattern.  Execution time is
-- about 15mS.
--  
--  This procedure is a companion to procedure "ApplyTransmissionFilter", which is used to apply the filter to 
-- a digitized waveform.
------------------------------------------------------------------------------------------------------------
local
    float   : Filter[SAMP_DIGHS_TRANS_FILTER]
    float   : Fr4Sim[200]
    float   : Fr4Sim2[10]
    float   : Fr4Sim3[10]
    float   : K 
    float   : BinStep
    float   : Tone
    float   : ToneDelta
    float   : LossLevel
    float   : Scale
    integer : i
    integer : TonePtr
    integer : TonePtr2
    integer : TonePtr3
    integer : FilterSamples
    integer : SamplesPerBit  

end_local
body
    K = sqr(2.0)
    if BitsPerWaveform > 160 then
       SamplesPerBit = SAMP_DIGHS_ALT_EYE_SAMPS_PER_BIT
    else
        SamplesPerBit  = SAMP_DIGHS_EYE_SAMPLES_PER_BIT
    end_if    


MakeFR4MicrostripLossArray

if (BitsPerWaveform * SamplesPerBit) > SAMP_DIGHS_TRANS_FILTER/2 then  
    FilterSamples = SAMP_DIGHS_TRANS_FILTER
 else_if (BitsPerWaveform * SamplesPerBit) > SAMP_DIGHS_TRANS_FILTER/4 then  
    FilterSamples = SAMP_DIGHS_TRANS_FILTER/2
 else_if (BitsPerWaveform * SamplesPerBit) > SAMP_DIGHS_TRANS_FILTER/8 then  
    FilterSamples = SAMP_DIGHS_TRANS_FILTER/4
 else_if (BitsPerWaveform * SamplesPerBit) > SAMP_DIGHS_TRANS_FILTER/16 then  
    FilterSamples = SAMP_DIGHS_TRANS_FILTER/8
 else_if (BitsPerWaveform * SamplesPerBit) > SAMP_DIGHS_TRANS_FILTER/32 then  
    FilterSamples = SAMP_DIGHS_TRANS_FILTER/16
 end_if   

if Thickness6Mil then
    K = 1.23
end_if
if not LengthInInches then
    K = K * 0.3937
 end_if
for i = 1 to 200 do
  Fr4Sim[i] =  Fr4MicrostripLossPerInch[i]* K * TraceLength
end_for
for i = 1 to 10 do
  Fr4Sim2[i] =  Fr4MicrostripLossPerInch2[i]* K * TraceLength
  Fr4Sim3[i] =  Fr4MicrostripLossPerInch3[i]* K * TraceLength
end_for
   
     Filter = 0.0
     Filter[1] = 0.5

   BinStep = float(DataRate) * float(SamplesPerBit)/float(FilterSamples)
   for i = 2 to FilterSamples/2 do
       Tone = BinStep * float(i-1)
       TonePtr  = integer(Tone/100.0e6)
       TonePtr2 = integer(Tone/10.0e6)
       if TonePtr3 = 0 then
           Filter[2*i-1] = 1.0
       else_if TonePtr3 < 10 then 
           ToneDelta = (Tone - float(TonePtr3)* 1.0e6)/1.0e6
           LossLevel = 10.0 ^ ((Fr4Sim3[TonePtr3]  + ToneDelta * (Fr4Sim3[TonePtr3 + 1] - Fr4Sim3[TonePtr3]))/20.0)
           Filter[2*i-1] = LossLevel
       else_if TonePtr2 < 10 then 
           ToneDelta = (Tone - float(TonePtr2)* 10.0e6)/10.0e6
           LossLevel = 10.0 ^ ((Fr4Sim2[TonePtr2]  + ToneDelta * (Fr4Sim2[TonePtr2 + 1] - Fr4Sim2[TonePtr2]))/20.0)
           Filter[2*i-1] = LossLevel
       else_if TonePtr < 200 then 
           ToneDelta = (Tone - float(TonePtr)* 100.0e6)/100.0e6
           LossLevel = 10.0 ^ ((Fr4Sim[TonePtr]  + ToneDelta * (Fr4Sim[TonePtr + 1] - Fr4Sim[TonePtr]))/20.0)
           Filter[2*i-1] = LossLevel
       end_if
   end_for
   Scale = Filter[3]

Filter[1:FilterSamples] = inverse_fft(Filter[1:FilterSamples])
Filter[FilterSamples/2 + 1:FilterSamples] = 0.0
Filter[1:FilterSamples] = fft(Filter[1:FilterSamples]) 
Scale = Scale/sqr(Filter[3]^2.0 + Filter[4]^2.0)
Filter = Filter * Scale

TransFilter[FilterNumber,1:SAMP_DIGHS_TRANS_FILTER] = Filter
wait(0ms)

end_body
procedure ApplyTransmissionFilter(Waveform,FilterNumber)
in_out float   : Waveform[?]    -- Captured waveform
in integer     : FilterNumber   -- Enter 0 < FilterNumber <= MAX_FILTERS
------------------------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------------------
-- This procedure is used to apply a previously generated cable filter or FR4 filter to a captured waveform
-- The previously generated filter is applied to a digitized waveform, producing the observation of the waveform 
-- as it would appear at the end of the defined circuit boiard trace.  
-- 
-- The generation of a FR4 microstrip filter should be executed only once within the OnLoad flow.  Up to MAX_FILTERS filters can
-- be Generated, where MAX_FILTERS is a constant in this modules environment.  Each filter takes about 250ms to generated.  Once
-- generated the filter can be used with this procedure in production test with a digitized Waveform (PRBS7 or K28.5 pattern). 
-- Execution time is about 15mS.
--  
--  This procedure is a companion to procedures "Fr4MicrostripSim","MakeCat5eSim" and "SpectraStripCableSim", which wre used to generate
--  up to 3 Transmission filters for simulation of FR4 Traces, Category 5 cable or Spectra Strip cable.
------------------------------------------------------------------------------------------------------------
local
    float   : Filter[SAMP_DIGHS_TRANS_FILTER]      -- Filter array size must be 2^Nth, >= Waveform array and < 2 * Waveform array.
    float   : Waveform2[SAMP_DIGHS_TRANS_FILTER*2]
    integer : FilterSamples
    integer : WaveformSamples
    integer : Shift
end_local
body

 WaveformSamples = dimsize(Waveform,1)
 
if (WaveformSamples) > SAMP_DIGHS_TRANS_FILTER/2 then  
    FilterSamples = SAMP_DIGHS_TRANS_FILTER
 else_if (WaveformSamples) > SAMP_DIGHS_TRANS_FILTER/4 then  
    FilterSamples = SAMP_DIGHS_TRANS_FILTER/2
 else_if (WaveformSamples) > SAMP_DIGHS_TRANS_FILTER/8 then  
    FilterSamples = SAMP_DIGHS_TRANS_FILTER/4
 else_if (WaveformSamples) > SAMP_DIGHS_TRANS_FILTER/16 then  
    FilterSamples = SAMP_DIGHS_TRANS_FILTER/8
 else_if (WaveformSamples) > SAMP_DIGHS_TRANS_FILTER/32 then  
    FilterSamples = SAMP_DIGHS_TRANS_FILTER/16
 end_if   

 Shift = (FilterSamples -WaveformSamples)/2
 
 Filter = TransFilter[FilterNumber,1:SAMP_DIGHS_TRANS_FILTER] 
  
 Waveform2[1:WaveformSamples]                    = Waveform[1:WaveformSamples]  
 Waveform2[1+WaveformSamples:2*WaveformSamples]  = Waveform[1:WaveformSamples]             
 Waveform2[1:FilterSamples]                      = fft(Waveform2[1:FilterSamples])
 Waveform2[1:FilterSamples]                      = complex_multiply(Filter[1:FilterSamples],Waveform2[1:FilterSamples])
 Waveform2[1:FilterSamples]                      = inverse_fft(Waveform2[1:FilterSamples])
 Waveform                                        = Waveform2[Shift+1:WaveformSamples+Shift]               
end_body

procedure MakeSpectraStripSim
local
    integer : i
    float   : K1 = -0.0559
    float   : K2 = -0.24
end_local
body

awrite( SpectraStripLoss[1:10],-0.269944,-0.318585,-0.436749,-0.488018,-0.575263,-0.630915,-0.620449,-0.649614,-0.673572,-0.667205)
awrite( SpectraStripLoss[11:20],-0.747843,-0.730888,-0.768809,-0.779371,-0.828299,-0.891984,-0.963604,-1.041334,-1.072190,-1.157767)
awrite( SpectraStripLoss[21:30],-1.229655,-1.264956,-1.291895,-1.302435,-1.312766,-1.298370,-1.316637,-1.343531,-1.356766,-1.406336)
awrite( SpectraStripLoss[31:40],-1.442213,-1.484862,-1.508640,-1.574586,-1.605184,-1.629534,-1.669285,-1.721093,-1.771074,-1.794661)
awrite( SpectraStripLoss[41:50],-1.805467,-1.859559,-1.928086,-1.921771,-1.928244,-1.990067,-2.045413,-2.082797,-2.159855,-2.182201)
awrite( SpectraStripLoss[51:60],-2.282431,-2.269782,-2.323426,-2.348041,-2.347068,-2.358402,-2.400816,-2.440747,-2.457588,-2.429380)
awrite( SpectraStripLoss[61:70],-2.519030,-2.581183,-2.583211,-2.680356,-2.651885,-2.806820,-2.805121,-2.852097,-2.909741,-2.996796)
awrite( SpectraStripLoss[71:80],-2.998937,-3.117538,-2.943655,-3.056529,-3.062539,-3.082004,-3.020370,-3.059675,-3.082422,-3.128146)
awrite( SpectraStripLoss[81:90],-3.169856,-3.263141,-3.340847,-3.328890,-3.469239,-3.538285,-3.752211,-3.736029,-3.820982,-3.964906)
awrite( SpectraStripLoss[91:100],-4.024837,-4.179842,-4.200899,-4.424163,-4.840932,-4.720653,-4.930076,-5.131806,-5.423554,-5.587176)

for i = 101 to 200 do
   SpectraStripLoss[i] = K1 * float(i)
end_for
for i = 1 to 10 do
   SpectraStripLoss2[i] = K2 * (float(i)/10.0)^0.521
   SpectraStripLoss3[i] = K2 * (float(i)/100.0)^0.521
end_for
end_body

procedure GFE_SamplerSelection(SampDighsPins,Samplers,SamplerConnection)
 in pin list[MAX_DIGHS] :  SampDighsPins    -- Selected DIGHS Channels
 in integer             :  Samplers[?]      -- Array of Sampler Channels Enter Site 1 Samplers first, then Site 2's , Site 3's Site 4's 
                                            -- Enter  1 for AUX_IN_ODD_CHAN, 2 forDATA_IN_ODD_CHAN, 3 for AUX_IN_EVEN_CHAN, 4 for DATA_IN_EVEN_CHAN 
 Out multisite integer  :  SamplerConnection[4] 
 -------------------------------------------------------------------------------------------------------------------------------------
--  This procedure produces the SamplerConnection Array that is to be passed into various test procedures within this Cadence module
-- SamplerDighs.mod.  Sampler connections to the digitizers are defined by the output array Sampler_Connection. 

-- *************** For the GTO Front End hardware **********************
-- 
--  Up to four digitizer channels can be passed into SampDighsPins.  In the standard configuration they are DIGHS 1 through 4.
--  DATA_IN Sampler are the 2V p-p input channels.
--  AUX_IN Samplers are the 1V p-p input channels.
--
 -------------------------------------------------------------------------------------------------------------------------------------
            
local
    integer            : Site
    integer            : Port
    integer            : Samp
    integer            : SampCount
    integer            : PortCount
    integer            : SitePtr
    integer            : SiteCount
 --   integer            : SamplerPointer[8]
  word list[16]        : SiteList
end_local
body

    PortCount  = len(SampDighsPins)
    SiteList   = get_active_sites
    SiteCount  = len(SiteList)
    SampCount  = dimsize(Samplers,1)
    Samp       = 0
    Site       = 0

    while Samp <> SampCount do
        Site = Site + 1
        for Port = 1 to PortCount do
            Samp = Samp + 1
            SamplerConnection[Site,Port] = Samplers[Samp]
        end_for
    end_while
end_body     
procedure MakeCat5Sim
local
    integer : i
    float   : K1 = -0.01967
    float   : K2 = -0.00023
    float   : K3 = -0.0005
end_local
body
for i = 1 to 200 do
   Cat5_CableLoss[i] = K1 * sqr(float(i*100)) + K2 * float(i*100) + K3/sqr(float(i*100))
end_for
for i = 1 to 10 do
    Cat5_CableLoss2[i] = K1 * sqr(float(i*10)) + K2 * float(i*10) + K3/sqr(float(i*10))
    Cat5_CableLoss3[i] = K1 * sqr(float(i)) + K2 * float(i) + K3/sqr(float(i))
end_for
end_body

procedure Cat5_CableSim(FilterNumber,DataRate,BitsPerWaveform,CableLength,LengthInFeet)
in integer   : FilterNumber    -- Number identifying the filter to be generated, 0 < FilterNumber <= MAX_FILTERS
in double    : DataRate        -- Data Rate 
in integer   : BitsPerWaveform -- Number of bits to the waveform
in float     : CableLength     -- Enter length in Meters or in Feet
in boolean   : LengthInFeet    -- Set True if length is in feet otherwise set false if length is in Meters
------------------------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------------------
-- This procedure is used to generate a software filter with the spectral losses of Category 5 cable.
-- The generated filter can be applied to a digitized waveform, producing the observation of the waveform 
-- as it would appear at the end of the defined cable.  
-- 
-- The generation of a  cable filter should be executed only once within the OnLoad flow.  Up to  MAX_FILTERS filters can
-- be Generated, where MAX_FILTERS is a constant in this modules environment.  Each filter takes about 250ms to generated. 
-- Once generated the filter can be applied in production test to a digitized PRBS7 or K28.5 pattern.  Execution time is
-- about 15mS.
--  
--  This procedure is a companion to procedure "ApplyTransmissionFilter", which is used to apply the filter to 
-- a digitized waveform.
------------------------------------------------------------------------------------------------------------
local
    float   : Filter[SAMP_DIGHS_TRANS_FILTER]
    float   : Filter2[SAMP_DIGHS_TRANS_FILTER]
    float   : CableSim[200]
    float   : CableSim2[10]
    float   : CableSim3[10]
    float   : K   
    float   :BinStep
    float   : Tone
    float   : ToneDelta
    float   : LossLevel
    float   : Scale
    integer : i
    integer : TonePtr
    integer : TonePtr2
    integer : TonePtr3
    integer : FilterSamples
    integer : SamplesPerBit  

end_local
body

    K = sqr(2.0)
    if BitsPerWaveform > 160 then
       SamplesPerBit = SAMP_DIGHS_ALT_EYE_SAMPS_PER_BIT
    else
        SamplesPerBit  = SAMP_DIGHS_EYE_SAMPLES_PER_BIT
    end_if    

MakeCat5Sim
if (BitsPerWaveform * SamplesPerBit) > SAMP_DIGHS_TRANS_FILTER/2 then  
    FilterSamples = SAMP_DIGHS_TRANS_FILTER
 else_if (BitsPerWaveform * SamplesPerBit) > SAMP_DIGHS_TRANS_FILTER/4 then  
    FilterSamples = SAMP_DIGHS_TRANS_FILTER/2
 else_if (BitsPerWaveform * SamplesPerBit) > SAMP_DIGHS_TRANS_FILTER/8 then  
    FilterSamples = SAMP_DIGHS_TRANS_FILTER/4
 else_if (BitsPerWaveform * SamplesPerBit) > SAMP_DIGHS_TRANS_FILTER/16 then  
    FilterSamples = SAMP_DIGHS_TRANS_FILTER/8
 else_if (BitsPerWaveform * SamplesPerBit) > SAMP_DIGHS_TRANS_FILTER/32 then  
    FilterSamples = SAMP_DIGHS_TRANS_FILTER/16
 end_if   

if LengthInFeet then
    K = K * 0.3048
 end_if
 
 
for i = 1 to 200 do
  CableSim[i] =  Cat5_CableLoss[i]* K * CableLength
end_for
for i = 1 to 10 do
  CableSim2[i] =  Cat5_CableLoss2[i]* K * CableLength
  CableSim3[i] =  Cat5_CableLoss3[i]* K * CableLength
end_for
   
     Filter = 0.0
     Filter[1] = 0.5
   
   BinStep = float(DataRate) * float(SamplesPerBit)/float(FilterSamples)
   for i = 2 to FilterSamples/2 do
       Tone = BinStep * float(i-1)
       TonePtr  = integer(Tone/100.0e6)
       TonePtr2 = integer(Tone/10.0e6)
       TonePtr3 = integer(Tone/1.0e6)
       if TonePtr3 = 0 then
           Filter[2*i-1] = 1.0
       else_if TonePtr3 < 10 then            
           ToneDelta = (Tone - float(TonePtr3)* 1.0e6)/1.0e6
           LossLevel = 10.0 ^ ((CableSim3[TonePtr3]  + ToneDelta * (CableSim3[TonePtr3 + 1] - CableSim3[TonePtr3]))/20.0)
           Filter[2*i-1] = LossLevel
       else_if TonePtr2 < 10 then            
           ToneDelta = (Tone - float(TonePtr2)* 10.0e6)/10.0e6
           LossLevel = 10.0 ^ ((CableSim2[TonePtr2]  + ToneDelta * (CableSim2[TonePtr2 + 1] - CableSim2[TonePtr2]))/20.0)
           Filter[2*i-1] = LossLevel
       else_if TonePtr < 200 then            
           ToneDelta = (Tone - float(TonePtr)* 100.0e6)/100.0e6
           LossLevel = 10.0 ^ ((CableSim[TonePtr]  + ToneDelta * (CableSim[TonePtr + 1] - CableSim[TonePtr]))/20.0)
           Filter[2*i-1] = LossLevel
       end_if
   end_for
   Scale = Filter[3]

Filter[1:FilterSamples] = inverse_fft(Filter[1:FilterSamples])
Filter[FilterSamples/2 + 1:FilterSamples] = 0.0
Filter[1:FilterSamples] = fft(Filter[1:FilterSamples]) 
Scale = Scale/sqr(Filter[3]^2.0 + Filter[4]^2.0)
Filter = Filter * Scale

TransFilter[FilterNumber,1:SAMP_DIGHS_TRANS_FILTER] = Filter
wait(0ms)

end_body

procedure MakeFR4MicrostripLossArray
body
awrite(Fr4MicrostripLossPerInch3[1:10],-0.00169,-0.00244,-0.00304,-0.00356,-0.00403,-0.00447,-0.00487,-0.00526,-0.00563,-0.00599)
awrite(Fr4MicrostripLossPerInch2[1:10],-0.00599,-0.00905,-0.01136,-0.01403,-0.01626,-0.01840,-0.02047,-0.02248,-0.02446,-0.02640)

awrite(Fr4MicrostripLossPerInch[1:8],-0.02641,-0.04476,-0.06216,-0.07896,-0.09525,-0.11104,-0.12639,-0.14133)
awrite(Fr4MicrostripLossPerInch[9:16],-0.15591,-0.17016,-0.18413,-0.19784,-0.21132,-0.22460,-0.23770,-0.25063)
awrite(Fr4MicrostripLossPerInch[17:24],-0.26341,-0.27606,-0.28858,-0.30099,-0.31329,-0.32549,-0.33760,-0.34963)
awrite(Fr4MicrostripLossPerInch[25:32],-0.36157,-0.37345,-0.38525,-0.39699,-0.40867,-0.42030,-0.43186,-0.44338)
awrite(Fr4MicrostripLossPerInch[33:40],-0.45485,-0.46627,-0.47764,-0.48898,-0.50027,-0.51153,-0.52274,-0.53393)
awrite(Fr4MicrostripLossPerInch[41:48],-0.54508,-0.55620,-0.56729,-0.57834,-0.58937,-0.60038,-0.61135,-0.62230)
awrite(Fr4MicrostripLossPerInch[49:56],-0.63323,-0.64413,-0.65501,-0.66587,-0.67671,-0.68753,-0.69832,-0.70910)
awrite(Fr4MicrostripLossPerInch[57:64],-0.71986,-0.73060,-0.74133,-0.75203,-0.76272,-0.77340,-0.78406,-0.79470)
awrite(Fr4MicrostripLossPerInch[65:72],-0.80533,-0.81595,-0.82635,-0.83714,-0.84771,-0.85828,-0.86883,-0.87937)
awrite(Fr4MicrostripLossPerInch[73:80],-0.88990,-0.90041,-0.91092,-0.92141,-0.93190,-0.94237,-0.95284,-0.96329)
awrite(Fr4MicrostripLossPerInch[81:88],-0.97374,-0.98417,-0.99460,-1.00502,-1.01543,-1.02583,-1.03622,-1.04661)
awrite(Fr4MicrostripLossPerInch[89:96],-1.05699,-1.06736,-1.07772,-1.08808,-1.09842,-1.10877,-1.11910,-1.12943)
awrite(Fr4MicrostripLossPerInch[97:104],-1.13975,-1.15007,-1.16038,-1.17069,-1.18098,-1.19128,-1.20156,-1.21185)
awrite(Fr4MicrostripLossPerInch[105:112],-1.22212,-1.23239,-1.24266,-1.25292,-1.26318,-1.27343,-1.28368,-1.29392)
awrite(Fr4MicrostripLossPerInch[113:120],-1.30416,-1.31440,-1.32463,-1.33485,-1.34508,-1.35529,-1.36551,-1.37572)
awrite(Fr4MicrostripLossPerInch[121:128],-1.38593,-1.39613,-1.40633,-1.41653,-1.42672,-1.43691,-1.44710,-1.45728)
awrite(Fr4MicrostripLossPerInch[129:136],-1.46747,-1.47764,-1.48782,-1.49799,-1.50816,-1.51833,-1.52849,-1.53866)
awrite(Fr4MicrostripLossPerInch[137:144],-1.54882,-1.55897,-1.56913,-1.57928,-1.58943,-1.59958,-1.60973,-1.61987)
awrite(Fr4MicrostripLossPerInch[145:152],-1.63002,-1.64016,-1.65030,-1.66043,-1.67057,-1.68070,-1.69083,-1.70096)
awrite(Fr4MicrostripLossPerInch[153:160],-1.71109,-1.72122,-1.73135,-1.74174,-1.75159,-1.76171,-1.77184,-1.78195)
awrite(Fr4MicrostripLossPerInch[161:168],-1.79207,-1.80219,-1.81231,-1.82242,-1.83253,-1.84265,-1.85276,-1.86287)
awrite(Fr4MicrostripLossPerInch[169:176],-1.87298,-1.88309,-1.89320,-1.90330,-1.91341,-1.92352,-1.93362,-1.94373)
awrite(Fr4MicrostripLossPerInch[177:184],-1.95383,-1.96394,-1.97404,-1.98414,-1.99425,-2.00435,-2.01445,-2.02455)
awrite(Fr4MicrostripLossPerInch[185:192],-2.03465,-2.04475,-2.05485,-2.06495,-2.07505,-2.08515,-2.09525,-2.10535)
awrite(Fr4MicrostripLossPerInch[193:200],-2.11545,-2.12555,-2.13565,-2.14575,-2.15585,-2.16595,-2.17605,-2.18615)
end_body

procedure MakeCat6Sim
local
    integer : i
    float   : K1 = -0.01836
    float   : K2 = -0.00015
    float   : K3 = -0.0005
end_local
body
for i = 1 to 200 do
   Cat6_CableLoss[i] = K1 * sqr(float(i*100)) + K2 * float(i*100) + K3/sqr(float(i*100))
end_for
for i = 1 to 10 do
    Cat6_CableLoss2[i] = K1 * sqr(float(i*10)) + K2 * float(i*10) + K3/sqr(float(i*10))
    Cat6_CableLoss3[i] = K1 * sqr(float(i)) + K2 * float(i) + K3/sqr(float(i))
end_for
end_body
procedure Cat6_CableSim(FilterNumber,DataRate,BitsPerWaveform,CableLength,LengthInFeet)
in integer   : FilterNumber    -- Number identifying the filter to be generated, Enter 0 < FilterNumber <= MAX_FILTERS
in double    : DataRate        -- Data Rate 
in integer   : BitsPerWaveform -- Number of bits to the waveform
in float     : CableLength     -- Enter length in Meters or in Feet
in boolean   : LengthInFeet    -- Set True if length is in feet otherwise set false if length is in Meters
------------------------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------------------
-- This procedure is used to generate a software filter with the spectral losses of Category 6 cable.
-- The generated filter can be applied to a digitized waveform, producing the observation of the waveform 
-- as it would appear at the end of the defined cable.  
-- 
-- The generation of a  cable filter should be executed only once within the OnLoad flow.  Up to  MAX_FILTERS filters can
-- be Generated, where MAX_FILTERS is a constant in this modules environment.  Each filter takes about 250ms to generated. 
-- Once generated the filter can be applied in production test to a digitized PRBS7 or K28.5 pattern.  Execution time is
-- about 15mS.
--  
--  This procedure is a companion to procedure "ApplyTransmissionFilter", which is used to apply the filter to 
-- a digitized waveform.
------------------------------------------------------------------------------------------------------------
local
    float   : Filter[SAMP_DIGHS_TRANS_FILTER]
    float   : Filter2[SAMP_DIGHS_TRANS_FILTER]
    float   : CableSim[200]
    float   : CableSim2[10]
    float   : CableSim3[10]
    float   : K  
    float   :BinStep
    float   : Tone
    float   : ToneDelta
    float   : LossLevel
    float   : Scale
    integer : i
    integer : TonePtr
    integer : TonePtr2
    integer : TonePtr3
    integer : FilterSamples
    integer : SamplesPerBit  

end_local
body
    K = sqr(2.0)
    if BitsPerWaveform > 160 then
       SamplesPerBit = SAMP_DIGHS_ALT_EYE_SAMPS_PER_BIT
    else
        SamplesPerBit  = SAMP_DIGHS_EYE_SAMPLES_PER_BIT
    end_if    

MakeCat6Sim
if (BitsPerWaveform * SamplesPerBit) > SAMP_DIGHS_TRANS_FILTER/2 then  
    FilterSamples = SAMP_DIGHS_TRANS_FILTER
 else_if (BitsPerWaveform * SamplesPerBit) > SAMP_DIGHS_TRANS_FILTER/4 then  
    FilterSamples = SAMP_DIGHS_TRANS_FILTER/2
 else_if (BitsPerWaveform * SamplesPerBit) > SAMP_DIGHS_TRANS_FILTER/8 then  
    FilterSamples = SAMP_DIGHS_TRANS_FILTER/4
 else_if (BitsPerWaveform * SamplesPerBit) > SAMP_DIGHS_TRANS_FILTER/16 then  
    FilterSamples = SAMP_DIGHS_TRANS_FILTER/8
 else_if (BitsPerWaveform * SamplesPerBit) > SAMP_DIGHS_TRANS_FILTER/32 then  
    FilterSamples = SAMP_DIGHS_TRANS_FILTER/16
 end_if   

if LengthInFeet then
    K = K * 0.3048
 end_if
 
 
for i = 1 to 200 do
  CableSim[i] =  Cat6_CableLoss[i]* K * CableLength
end_for
for i = 1 to 10 do
  CableSim2[i] =  Cat6_CableLoss2[i]* K * CableLength
  CableSim3[i] =  Cat6_CableLoss3[i]* K * CableLength
end_for
   
     Filter = 0.0
     Filter[1] = 0.5
   
   BinStep = float(DataRate) * float(SamplesPerBit)/float(FilterSamples)
   for i = 2 to FilterSamples/2 do
       Tone = BinStep * float(i-1)
       TonePtr  = integer(Tone/100.0e6)
       TonePtr2 = integer(Tone/10.0e6)
       TonePtr3 = integer(Tone/1.0e6)
       if TonePtr3 = 0 then
           Filter[2*i-1] = 1.0
       else_if TonePtr3 < 10 then            
           ToneDelta = (Tone - float(TonePtr3)* 1.0e6)/1.0e6
           LossLevel = 10.0 ^ ((CableSim3[TonePtr3]  + ToneDelta * (CableSim3[TonePtr3 + 1] - CableSim3[TonePtr3]))/20.0)
           Filter[2*i-1] = LossLevel
       else_if TonePtr2 < 10 then            
           ToneDelta = (Tone - float(TonePtr2)* 10.0e6)/10.0e6
           LossLevel = 10.0 ^ ((CableSim2[TonePtr2]  + ToneDelta * (CableSim2[TonePtr2 + 1] - CableSim2[TonePtr2]))/20.0)
           Filter[2*i-1] = LossLevel
       else_if TonePtr < 200 then            
           ToneDelta = (Tone - float(TonePtr)* 100.0e6)/100.0e6
           LossLevel = 10.0 ^ ((CableSim[TonePtr]  + ToneDelta * (CableSim[TonePtr + 1] - CableSim[TonePtr]))/20.0)
           Filter[2*i-1] = LossLevel
       end_if
   end_for
   Scale = Filter[3]

Filter[1:FilterSamples] = inverse_fft(Filter[1:FilterSamples])
Filter[FilterSamples/2 + 1:FilterSamples] = 0.0
Filter[1:FilterSamples] = fft(Filter[1:FilterSamples]) 
Scale = Scale/sqr(Filter[3]^2.0 + Filter[4]^2.0)
Filter = Filter * Scale

TransFilter[FilterNumber,1:SAMP_DIGHS_TRANS_FILTER] = Filter
wait(0ms)

end_body

procedure MakeCat7Sim
local
    integer : i
    float   : K1 = -0.01750  
    float   : K2 = -0.00010  
    float   : K3 = -0.0020    
    float   : Cable[600]
end_local
body
----------------------------------------------------------------------------------
--This Category 7 model was derived from attenuation data listed in datasheet for 
-- Addison's Category 7 STP cable.  The ANSI/TIA/EIA Standard defining Category 7 
-- cable is still under development and is not finalized at this time --08/01/08.  
-- The Addison specification for this cable may be subject to change.
----------------------------------------------------------------------------------
for i = 1 to 200 do
   Cat7_CableLoss[i] = K1 * sqr(float(i*100)) + K2 * float(i*100) + K3/sqr(float(i*100))
end_for

for i = 1 to 10 do
    Cat7_CableLoss2[i] = K1 * sqr(float(i*10)) + K2 * float(i*10) + K3/sqr(float(i*10))
    Cat7_CableLoss3[i] = K1 * sqr(float(i)) + K2 * float(i) + K3/sqr(float(i))
end_for
end_body


procedure Cat7_CableSim(FilterNumber,DataRate,BitsPerWaveform,CableLength,LengthInFeet)
in integer   : FilterNumber    -- Number identifying the filter to be generated, Enter 0 < FilterNumber <= MAX_FILTERS
in double    : DataRate        -- Data Rate 
in integer   : BitsPerWaveform -- Number of bits to the waveform
in float     : CableLength     -- Enter length in Meters or in Feet
in boolean   : LengthInFeet    -- Set True if length is in feet otherwise set false if length is in Meters
------------------------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------------------
-- This procedure is used to generate a software filter with the spectral losses of Category 7 cable.
-- The generated filter can be applied to a digitized waveform, producing the observation of the waveform 
-- as it would appear at the end of the defined cable.  
-- 
-- The generation of a  cable filter should be executed only once within the OnLoad flow.  Up to 3 filters can
-- be Generated, TransFilter1, TransFilter2, and TransFilter3.  Each filter takes about 250ms to generated.  Once
-- generated the filter can be applied in production test to a digitized PRBS7 or K28.5 pattern.  Execution time is
-- about 15mS.
--  
--  This procedure is a companion to procedure "ApplyTransmissionFilter", which is used to apply the filter to 
-- a digitized waveform.
------------------------------------------------------------------------------------------------------------
local
    float   : Filter[SAMP_DIGHS_TRANS_FILTER]
    float   : Filter2[SAMP_DIGHS_TRANS_FILTER]
    float   : CableSim[200]
    float   : CableSim2[10]
    float   : CableSim3[10]
    float   : K 
    float   :BinStep
    float   : Tone
    float   : ToneDelta
    float   : LossLevel
    float   : Scale
    integer : i
    integer : TonePtr
    integer : TonePtr2
    integer : TonePtr3
    integer : FilterSamples
    integer : SamplesPerBit  

end_local
body

    K = sqr(2.0)
    if BitsPerWaveform > 160 then
       SamplesPerBit = SAMP_DIGHS_ALT_EYE_SAMPS_PER_BIT
    else
        SamplesPerBit  = SAMP_DIGHS_EYE_SAMPLES_PER_BIT
    end_if    


MakeCat7Sim
if (BitsPerWaveform * SamplesPerBit) > SAMP_DIGHS_TRANS_FILTER/2 then  
    FilterSamples = SAMP_DIGHS_TRANS_FILTER
 else_if (BitsPerWaveform * SamplesPerBit) > SAMP_DIGHS_TRANS_FILTER/4 then  
    FilterSamples = SAMP_DIGHS_TRANS_FILTER/2
 else_if (BitsPerWaveform * SamplesPerBit) > SAMP_DIGHS_TRANS_FILTER/8 then  
    FilterSamples = SAMP_DIGHS_TRANS_FILTER/4
 else_if (BitsPerWaveform * SamplesPerBit) > SAMP_DIGHS_TRANS_FILTER/16 then  
    FilterSamples = SAMP_DIGHS_TRANS_FILTER/8
 else_if (BitsPerWaveform * SamplesPerBit) > SAMP_DIGHS_TRANS_FILTER/32 then  
    FilterSamples = SAMP_DIGHS_TRANS_FILTER/16
 end_if   

if LengthInFeet then
    K = K * 0.3048
 end_if
 
 
for i = 1 to 200 do
  CableSim[i] =  Cat7_CableLoss[i]* K * CableLength
end_for
for i = 1 to 10 do
  CableSim2[i] =  Cat7_CableLoss2[i]* K * CableLength
  CableSim3[i] =  Cat7_CableLoss3[i]* K * CableLength
end_for
   
     Filter = 0.0
     Filter[1] = 0.5
   
   BinStep = float(DataRate) * float(SamplesPerBit)/float(FilterSamples)
   for i = 2 to FilterSamples/2 do
       Tone = BinStep * float(i-1)
       TonePtr  = integer(Tone/100.0e6)
       TonePtr2 = integer(Tone/10.0e6)
       TonePtr3 = integer(Tone/1.0e6)
       if TonePtr3 = 0 then
           Filter[2*i-1] = 1.0
       else_if TonePtr3 < 10 then            
           ToneDelta = (Tone - float(TonePtr3)* 1.0e6)/1.0e6
           LossLevel = 10.0 ^ ((CableSim3[TonePtr3]  + ToneDelta * (CableSim3[TonePtr3 + 1] - CableSim3[TonePtr3]))/20.0)
           Filter[2*i-1] = LossLevel
       else_if TonePtr2 < 10 then            
           ToneDelta = (Tone - float(TonePtr2)* 10.0e6)/10.0e6
           LossLevel = 10.0 ^ ((CableSim2[TonePtr2]  + ToneDelta * (CableSim2[TonePtr2 + 1] - CableSim2[TonePtr2]))/20.0)
           Filter[2*i-1] = LossLevel
       else_if TonePtr < 200 then            
           ToneDelta = (Tone - float(TonePtr)* 100.0e6)/100.0e6
           LossLevel = 10.0 ^ ((CableSim[TonePtr]  + ToneDelta * (CableSim[TonePtr + 1] - CableSim[TonePtr]))/20.0)
           Filter[2*i-1] = LossLevel
       end_if
   end_for
   Scale = Filter[3]

Filter[1:FilterSamples] = inverse_fft(Filter[1:FilterSamples])
Filter[FilterSamples/2 + 1:FilterSamples] = 0.0
Filter[1:FilterSamples] = fft(Filter[1:FilterSamples]) 
Scale = Scale/sqr(Filter[3]^2.0 + Filter[4]^2.0)
Filter = Filter * Scale

TransFilter[FilterNumber,1:SAMP_DIGHS_TRANS_FILTER] = Filter
wait(0ms)

end_body


