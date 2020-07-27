use module "lib_gtoFrontEndConsts.mod"  
use module "lib_clkCtrl.mod"

--  20050704        wdc     Created
--  20060208        wdc     Added support for VGA calibration
--                          Added switch for GTO Buffer status display
--  20060209        wdc     Fixed  for VGA calibration
--                          Disabled GTB_SetSourceLevelAndSendTrigger
--  20110526        pla     Add prefix "lib_" to module names for local template copies

-- GTB_init
--------------------------------------------------------------------------------
--  This procedure is used to initialize all of the static arrays used by gtoFrontEndCtrl.mod.
--  Execute this procedure at program load time.  It needs to be executed only once.

-- GTB_Enable_Status_Display ( displaySwitch )
--------------------------------------------------------------------------------
--  This procdure switchs the GTO Buffer's status display on and off.  
--  Use the constants DISPLAY_ON to enable the display and DISPLAY_OFF to 
--  disable the display.  The display is enabled by default.  Disabling the 
--  display will reduce test times.

-- GTB_ConnectSamplerToDigitizer ( gtbSamplerChan , auxOrGtoSamp , digitizerChan )
--------------------------------------------------------------------------------
--  This procedure is used to connect a sampler to a digitizer channel.  There are
--  four digitizer channels.  In the standard configuration they are DIGHS 1 through 4.
--  The first parameter selects a gto buffer channel.  the second parameter selects
--  either the aux sampler or the sampler connected to the channels GTO RX input on
--  the channel selected in the first parameter.  Use the constant names AUX_SAMPLER or 
--  GTO_SAMPLER as the two possible choices.  The third parameter is the DIGHS channel
--  to which the sampler is connected.  The choices are 1 through four.  IT IS VERY
--  IMPORTANT TO NOTE that samplers channels and digitizer channels are in groups of two.
--  This means that samplers on gto buffer channels 1 and 2 can only be connected to 
--  DIGHS channels 1 or 2, and that samplers on gto buffer channels 3 and 4 can only 
--  be connected to DIGHS channels 3 or 4.

--  GTB_DisconnectSampFromDigitizer ( digitizerChan )
--------------------------------------------------------------------------------
--  This procedure is used to disconnect the digitizer selected by digitizerChan from 
--  the sampler to which it was connected.  

--  GTB_SelectSampleClockOutput ( gtbSampleClockList , outputSelection )
--------------------------------------------------------------------------------
--  This procedure selects the signal that is sent to the sample clock output ports
--  on the test head.  There are two sample clock output ports.  Sample clock 1 output
--  is associated with buffer channels 1 and 2.  Sample clock 2 output is associated
--  with channels 3 and 4.  
--  
--  To select the sample clocks outputs to be set by selecting <:1:>, <:2:>, or <:1,2:>
--  as values for gtbSampleClockList.
--
--  There are three possible conditions to set with outputSelection. 
--  Choose GENERATOR to send the output of the clock generator to the sample clock output.
--  Choose DIVIDED_CLOCK to send the divided clock at the rate seen by the samplers to the sample clock output
--  Choose OFF to inhibit any output from the port.

--  GTB_SelectSourceMUXPath ( bufChan , gtoChan )
--------------------------------------------------------------------------------
--  This procedure selects the GTO output to Buffer output mapping for the 
--  GAIN PATH ONLY.  The gain path through the GTO Buffer includes a 2 by 2
--  crosspoint switch that may be used to connect either of two GTO outputs
--  to either of two GTO Buffer outputs.  This enables the user to switch
--  patterns on software command.
--
--  This mapping in on a per-gto-brick basis, so that GTO channel 1 can be sent
--  to either or both GTO Buffer outputs 1 and 2.  GTO channel 2 can be sent
--  to either or both GTO Buffer outputs 1 and 2.  GTO channel 3 can be sent
--  to either or both GTO Buffer outputs 3 and 4.  GTO channel 4 can be sent
--  to either or both GTO Buffer outputs 3 and 4.  
--  Other choices may give undesired results.

--  GTB_SelectSourceMUXPathAndSendTrigger ( bufChan , gtoChan , triggerNumber )
--------------------------------------------------------------------------------
--  This procedure selects the GTO output to Buffer output mapping for the 
--  GAIN PATH ONLY.  The gain path through the GTO Buffer includes a 2 by 2
--  crosspoint switch that may be used to connect either of two GTO outputs
--  to either of two GTO Buffer outputs.  This enables the user to switch
--  patterns on software command.
--
--  Simultaneously with the switch, a pulse will be emitted onto the SyncBus
--  line ( 1 through 8 ) selected by triggerNumber
--
--  This mapping in on a per-gto-brick basis, so that GTO channel 1 can be sent
--  to either or both GTO Buffer outputs 1 and 2.  GTO channel 2 can be sent
--  to either or both GTO Buffer outputs 1 and 2.  GTO channel 3 can be sent
--  to either or both GTO Buffer outputs 3 and 4.  GTO channel 4 can be sent
--  to either or both GTO Buffer outputs 3 and 4.  
--  Other choices may give undesired results.

--  GTB_SelectSourceMUXPathOnTrigger ( bufChan , gtoChan , triggerNumber )
--------------------------------------------------------------------------------
--  This procedure selects the GTO output to Buffer output mapping for the 
--  GAIN PATH ONLY.  The gain path through the GTO Buffer includes a 2 by 2
--  crosspoint switch that may be used to connect either of two GTO outputs
--  to either of two GTO Buffer outputs.  This enables the user to switch
--  patterns on command.
--
--  This procedure arms the control hardware in the GTO buffer to set the 
--  crosspoint switch upon receipt of a pulse on the SyncBusline ( 1 through 8 )
--  selected by triggerNumber.
--
--  This mapping in on a per-gto-brick basis, so that GTO channel 1 can be sent
--  to either or both GTO Buffer outputs 1 and 2.  GTO channel 2 can be sent
--  to either or both GTO Buffer outputs 1 and 2.  GTO channel 3 can be sent
--  to either or both GTO Buffer outputs 3 and 4.  GTO channel 4 can be sent
--  to either or both GTO Buffer outputs 3 and 4.  
--  Other choices may give undesired results.

--  GTB_SelectSourcePath ( gtbSrc , gtbSrcPath , gtbSrcConnection )
--------------------------------------------------------------------------------
--  This procedure is used to select any of 6 different signal paths through
--  the RF Relay matrix in the GTO Buffer source.  
--
--  Three of the paths are used for signal level setting to increase the 
--  dynamic range of the GTO.  Three additional paths are available to
--  the user so that application-specific signal conditioning can be accomplished.
--
--  gtbSrc selects the source channel to set.
--
--  gtbSrcPath selects one of the six paths.  The followin constants are to
--  be used for path selection:
--  GTB_SRC_THROUGH     for the path direct from the GTO output to the head.
--  GTB_SRC_GAIN        for the path through the variable gain amplifier.
--  GTB_SRC_ATTN        for the path through the 26dB attenuator.
--  GTB_SRC_USER1       for the first user path.
--  GTB_SRC_USER2       for the second user path.
--  GTB_SRC_USER3       for the third user path
--
--  gtbSrcConnection is used to select whether which sides of the
--  differential pair are energized.  The non-inverting, inverting or both
--  sides may be selected  The following constants are to
--  be used for path selection:
--
--  SE_PLUS             for the non-inverting output only.
--  SE_MINUS            for the inverting output only.
--  BALANCED            for both output together.

--  GTB_SetSampleClockDivider ( gtbSampler , divisor )
--------------------------------------------------------------------------------
--  This procedure sets the sample clock divider on the GTO Buffer analog board.
--  The same divider is shared across all four samplers on a board.  This means
--  that Aux Sampler 1, GTO Rx sampler 1, Aux Sampler 2, and GTO Rx sampler 2 all
--  share the same clock divider, and changing either channel 1 or 2 will always
--  change both channels.  Similarly,  This means  that Aux Sampler 3, GTO Rx 
--  sampler 3, Aux Sampler 4, and GTO Rx sampler 4 all share the same clock divider,
--  and changing either channel 3 or 4 will always change both channels.  
--
--  Select 1, 2, 3 or 4 for gtbSampler
--
--  The divisor can be set from 4 to 64 in steps of 2.  If an odd number is selected
--  the next lower even number will be selected.  Selections that are out of range
--  will generate an error message.


--  GTB_SetSourceLevel ( gtbSrcList , gtbSrcConnection , gtbSrcLevel , forceHighRange )
--------------------------------------------------------------------------------
--  this procedure will be reworked for calbration later.
--  This procedure is designed to change the level of all
--  channels in the list gtbSrcList. If the level is within the
--  range of the Variable Gain  Amplifier path, then the relays 
--  will all be set to the proper state, followed by all the
--  control dacs being set simultaneously.  So if the level change
--  is from one level supported by the gain path to another 
--  supported by the gain path, all channels will change simultaneously.
--
--  gtbSrcConnection is used to select whether which sides of the
--  differential pair are energized.  The non-inverting, inverting or both
--  sides may be selected  The following constants are to
--  be used for path selection:
--
--  SE_PLUS             for the non-inverting output only.
--  SE_MINUS            for the inverting output only.
--  BALANCED            for both output together.
--
--  gtbSrcLevel is the output level in volts peak-to-peak.
--
--  forceHighRange forces the variable gain range fo the vx_gto buffer to be used.
--  This allows the trigger capabilities for level changes and the source switch to be
--  used down to ouput levels of as little as 100mv.  Otherwise, the lower limit of the
--  gain path is 1.0v.

--  GTB_SetSourceLevelOnTrigger ( gtbSrcList , gtbSrcConnection , gtbSrcLevel , syncBusLine )
--------------------------------------------------------------------------------
--  this procedure will be reworked for calbration later.
--  This procedure is designed to change the level of all
--  channels in the list gtbSrcList. If the level is within the
--  range of the Variable Gain  Amplifier path, then the relays 
--  will all be set to the proper state, followed by all the
--  control dacs being set simultaneously.  So if the level change
--  is from one level supported by the gain path to another 
--  supported by the gain path, all channels will change simultaneously.
--
--  gtbSrcConnection is used to select whether which sides of the
--  differential pair are energized.  The non-inverting, inverting or both
--  sides may be selected  The following constants are to
--  be used for path selection:
--
--  SE_PLUS             for the non-inverting output only.
--  SE_MINUS            for the inverting output only.
--  BALANCED            for both output together.
--
--  gtbSrcLevel is the output level in volts peak-to-peak.
--
--  This procedure arms the control hardware in the GTO buffer to set the 
--  level dacs upon receipt of a pulse on the SyncBusline ( 1 through 8 )
--  selected by triggerNumber.
--

--  GTB_SetSourceLevelAndSendTrigger ( gtbSrcSet , gtbSrcConnection , gtbSrcLevel , gtbTriggerChannel )
--------------------------------------------------------------------------------
--  this procedure will be reworked for calbration later.
--  This procedure is designed to change the level of all
--  channels in the list gtbSrcList. If the level is within the
--  range of the Variable Gain  Amplifier path, then the relays 
--  will all be set to the proper state, followed by all the
--  control dacs being set simultaneously.  So if the level change
--  is from one level supported by the gain path to another 
--  supported by the gain path, all channels will change simultaneously.
--
--  gtbSrcConnection is used to select whether which sides of the
--  differential pair are energized.  The non-inverting, inverting or both
--  sides may be selected  The following constants are to
--  be used for path selection:
--
--  SE_PLUS             for the non-inverting output only.
--  SE_MINUS            for the inverting output only.
--  BALANCED            for both output together.
--
--  gtbSrcLevel is the output level in volts peak-to-peak.
--
--  Simultaneously with the change in level, a pulse will be emitted onto the SyncBus
--  line ( 1 through 8 ) selected by triggerNumber.

--------------------------------------------------------------------------------
procedure GTB_set_address ( slotNumber , regAddr , data , masque )
--------------------------------------------------------------------------------
in word                         : slotNumber
in word                         : regAddr
in word                         : data
in word                         : masque

body

    gtb_shadow [ regAddr ] = gtb_shadow [ regAddr ] & masque | data
    set cx register offset regAddr slot slotNumber to gtb_shadow [ regAddr ]
--    read cx register offset regAddr slot slotNumber into gtb_shadow [ regAddr ]

    if gtbStatusEnabled then
        GTB_UpdateStatus
    endif
    
endbody
--------------------------------------------------------------------------------
procedure GTB_init
--------------------------------------------------------------------------------
--  This procedure is used to initialize all of the static arrays used by gtoFrontEndCtrl.mod.
--  Execute this procedure at program load time.  It needs to be executed only once.

local integer               : i
local set [ 4 ]             : femconSet

body

    gtbSlotNum = GTB_SLOT_NUM

    gtbSrcSet = [ ]    
    gtbSrcSet = inventory_all_chans("vx_gto")
    femconSet = inventory_all_chans("femcon")

    afe = false
    if gtbSrcSet = [ ] and femconSet = [ 1 ] then  -- AFE present ( SSIP TESTER )
        gtbSrcSet = [ 1 , 2 , 3 , 4 ]
        afe_config = true
        afe = true
        afeVgaList = <: 1 , 3 :>
        if exist ( "/ltx/testers/" + tester_name + "/calfiles/gtoFE/.four_vgas" ) then
            fourVgas = true
            afeVgaList = <: 1 , 2 , 3 , 4 :>
        endif
    elseif gtbSrcSet = [ ] and femconSet = [  ] then
        println ( stdout , " Checker aborted.  No GTO channels are present " )
        halt
    endif
    
    if rfCal then
        return
    endif
    
    GTB_initNominalCalfactors
    GTB_ReadCalFile
    GTB_ReadJitClkLevelCalfile
    GTB_InitSamplerCalPathVariables
    GTB_ReadSamplerCalfactorFiles
    GTB_initSamplerCalfactorTables
    GTB_InitRelayClickCounter
    GTB_initJitterClockLevel
    
    
    gtbSrcDacAAddr [ 1 ] = GTOBUF_A_CH1_A_GAIN
    gtbSrcDacBAddr [ 1 ] = GTOBUF_A_CH1_B_GAIN
    gtbSrcDacAAddr [ 2 ] = GTOBUF_A_CH2_A_GAIN
    gtbSrcDacBAddr [ 2 ] = GTOBUF_A_CH2_B_GAIN
    gtbSrcDacAAddr [ 3 ] = GTOBUF_B_CH3_A_GAIN
    gtbSrcDacBAddr [ 3 ] = GTOBUF_B_CH3_B_GAIN
    gtbSrcDacAAddr [ 4 ] = GTOBUF_B_CH4_A_GAIN
    gtbSrcDacBAddr [ 4 ] = GTOBUF_B_CH4_B_GAIN
    
    gtbSrcRelayAddr [ 1 ] = GTOBUF_A_CH_1_RLY
    gtbSrcRelayAddr [ 2 ] = GTOBUF_A_CH_2_RLY
    gtbSrcRelayAddr [ 3 ] = GTOBUF_B_CH_3_RLY
    gtbSrcRelayAddr [ 4 ] = GTOBUF_B_CH_4_RLY
    
    gtbSrcConnectAry [ GTB_SRC_THROUGH , SE_PLUS  ] = GTB_SRC_THROUGH_DATA & SE_PLUS_MASK
    gtbSrcConnectAry [ GTB_SRC_THROUGH , SE_MINUS ] = GTB_SRC_THROUGH_DATA & SE_MINUS_MASK
    gtbSrcConnectAry [ GTB_SRC_THROUGH , BALANCED ] = GTB_SRC_THROUGH_DATA & BALANCED_MASK
    gtbSrcConnectAry [ GTB_SRC_GAIN    , SE_PLUS  ] = GTB_SRC_GAIN_DATA    & SE_PLUS_MASK 
    gtbSrcConnectAry [ GTB_SRC_GAIN    , SE_MINUS ] = GTB_SRC_GAIN_DATA    & SE_MINUS_MASK
    gtbSrcConnectAry [ GTB_SRC_GAIN    , BALANCED ] = GTB_SRC_GAIN_DATA    & BALANCED_MASK
    gtbSrcConnectAry [ GTB_SRC_ATTN    , SE_PLUS  ] = GTB_SRC_ATTN_DATA    & SE_PLUS_MASK 
    gtbSrcConnectAry [ GTB_SRC_ATTN    , SE_MINUS ] = GTB_SRC_ATTN_DATA    & SE_MINUS_MASK
    gtbSrcConnectAry [ GTB_SRC_ATTN    , BALANCED ] = GTB_SRC_ATTN_DATA    & BALANCED_MASK
    gtbSrcConnectAry [ GTB_SRC_USER1   , SE_PLUS  ] = GTB_SRC_USER1_DATA   & SE_PLUS_MASK 
    gtbSrcConnectAry [ GTB_SRC_USER1   , SE_MINUS ] = GTB_SRC_USER1_DATA   & SE_MINUS_MASK
    gtbSrcConnectAry [ GTB_SRC_USER1   , BALANCED ] = GTB_SRC_USER1_DATA   & BALANCED_MASK
    gtbSrcConnectAry [ GTB_SRC_USER2   , SE_PLUS  ] = GTB_SRC_USER2_DATA   & SE_PLUS_MASK 
    gtbSrcConnectAry [ GTB_SRC_USER2   , SE_MINUS ] = GTB_SRC_USER2_DATA   & SE_MINUS_MASK
    gtbSrcConnectAry [ GTB_SRC_USER2   , BALANCED ] = GTB_SRC_USER2_DATA   & BALANCED_MASK
    gtbSrcConnectAry [ GTB_SRC_USER3   , SE_PLUS  ] = GTB_SRC_USER3_DATA   & SE_PLUS_MASK 
    gtbSrcConnectAry [ GTB_SRC_USER3   , SE_MINUS ] = GTB_SRC_USER3_DATA   & SE_MINUS_MASK
    gtbSrcConnectAry [ GTB_SRC_USER3   , BALANCED ] = GTB_SRC_USER3_DATA   & BALANCED_MASK
    
    gtbPathStatusAry [ GTB_SRC_THROUGH ]        = " THROUGH   "
    gtbPathStatusAry [ GTB_SRC_ATTN ]           = " 26dB ATTEN"
    gtbPathStatusAry [ GTB_SRC_GAIN ]           = " VAR GAIN  "
    gtbPathStatusAry [ GTB_SRC_USER1 ]          = " USER 1    "
    gtbPathStatusAry [ GTB_SRC_USER2 ]          = " USER 2    "
    gtbPathStatusAry [ GTB_SRC_USER3 ]          = " USER 3    "
    
    gtbPathEndedAry [ SE_PLUS ]                 = " SINGLE ENDED +"
    gtbPathEndedAry [ SE_MINUS ]                = " SINGLE ENDED -"
    gtbPathEndedAry [ BALANCED ]                = " BALANCED"
    
    gtbMuxStates [ 1 , 1            , GTB_DATA ] = GTB_MUX_ODD_GTO_SRC_TO_ODD_OUTPUT
    gtbMuxStates [ 1 , 1            , GTB_MASK ] = GTB_MUX_ODD_OUTPUT_MASK
    gtbMuxStates [ 1 , 1            , GTB_ADDR ] = GTOBUF_A_SRC_SW
    gtbMuxStates [ 1 , 2            , GTB_DATA ] = GTB_MUX_EVEN_GTO_SRC_TO_ODD_OUTPUT
    gtbMuxStates [ 1 , 2            , GTB_MASK ] = GTB_MUX_ODD_OUTPUT_MASK
    gtbMuxStates [ 1 , 2            , GTB_ADDR ] = GTOBUF_A_SRC_SW
    gtbMuxStates [ 1 , 3            , GTB_DATA ] = GTB_MUX_ODD_GTO_SRC_TO_ODD_OUTPUT
    gtbMuxStates [ 1 , 3            , GTB_MASK ] = GTB_MUX_ODD_OUTPUT_MASK
    gtbMuxStates [ 1 , 3            , GTB_ADDR ] = GTOBUF_A_SRC_SW
    gtbMuxStates [ 1 , 4            , GTB_DATA ] = GTB_MUX_EVEN_GTO_SRC_TO_ODD_OUTPUT
    gtbMuxStates [ 1 , 4            , GTB_MASK ] = GTB_MUX_ODD_OUTPUT_MASK
    gtbMuxStates [ 1 , 4            , GTB_ADDR ] = GTOBUF_A_SRC_SW
    gtbMuxStates [ 1 , MUX_SRC_OFF  , GTB_DATA ] = GTB_MUX_DISABLE_ODD_OUTPUT
    gtbMuxStates [ 1 , MUX_SRC_OFF  , GTB_MASK ] = GTB_MUX_ODD_OUTPUT_MASK
    gtbMuxStates [ 1 , MUX_SRC_OFF  , GTB_ADDR ] = GTOBUF_A_SRC_SW

    gtbMuxStates [ 2 , 1            , GTB_DATA ] = GTB_MUX_ODD_GTO_SRC_TO_EVEN_OUTPUT
    gtbMuxStates [ 2 , 1            , GTB_MASK ] = GTB_MUX_EVEN_OUTPUT_MASK
    gtbMuxStates [ 2 , 1            , GTB_ADDR ] = GTOBUF_A_SRC_SW
    gtbMuxStates [ 2 , 2            , GTB_DATA ] = GTB_MUX_EVEN_GTO_SRC_TO_EVEN_OUTPUT
    gtbMuxStates [ 2 , 2            , GTB_MASK ] = GTB_MUX_EVEN_OUTPUT_MASK
    gtbMuxStates [ 2 , 2            , GTB_ADDR ] = GTOBUF_A_SRC_SW
    gtbMuxStates [ 2 , 3            , GTB_DATA ] = GTB_MUX_ODD_GTO_SRC_TO_EVEN_OUTPUT
    gtbMuxStates [ 2 , 3            , GTB_MASK ] = GTB_MUX_EVEN_OUTPUT_MASK
    gtbMuxStates [ 2 , 3            , GTB_ADDR ] = GTOBUF_A_SRC_SW
    gtbMuxStates [ 2 , 4            , GTB_DATA ] = GTB_MUX_EVEN_GTO_SRC_TO_EVEN_OUTPUT
    gtbMuxStates [ 2 , 4            , GTB_MASK ] = GTB_MUX_EVEN_OUTPUT_MASK
    gtbMuxStates [ 2 , 4            , GTB_ADDR ] = GTOBUF_A_SRC_SW
    gtbMuxStates [ 2 , MUX_SRC_OFF  , GTB_DATA ] = GTB_MUX_DISABLE_EVEN_OUTPUT
    gtbMuxStates [ 2 , MUX_SRC_OFF  , GTB_MASK ] = GTB_MUX_EVEN_OUTPUT_MASK
    gtbMuxStates [ 2 , MUX_SRC_OFF  , GTB_ADDR ] = GTOBUF_A_SRC_SW

    gtbMuxStates [ 3 , 1            , GTB_DATA ] = GTB_MUX_ODD_GTO_SRC_TO_ODD_OUTPUT
    gtbMuxStates [ 3 , 1            , GTB_MASK ] = GTB_MUX_ODD_OUTPUT_MASK
    gtbMuxStates [ 3 , 1            , GTB_ADDR ] = GTOBUF_B_SRC_SW
    gtbMuxStates [ 3 , 2            , GTB_DATA ] = GTB_MUX_EVEN_GTO_SRC_TO_ODD_OUTPUT
    gtbMuxStates [ 3 , 2            , GTB_MASK ] = GTB_MUX_ODD_OUTPUT_MASK
    gtbMuxStates [ 3 , 2            , GTB_ADDR ] = GTOBUF_B_SRC_SW
    gtbMuxStates [ 3 , 3            , GTB_DATA ] = GTB_MUX_ODD_GTO_SRC_TO_ODD_OUTPUT
    gtbMuxStates [ 3 , 3            , GTB_MASK ] = GTB_MUX_ODD_OUTPUT_MASK
    gtbMuxStates [ 3 , 3            , GTB_ADDR ] = GTOBUF_B_SRC_SW
    gtbMuxStates [ 3 , 4            , GTB_DATA ] = GTB_MUX_EVEN_GTO_SRC_TO_ODD_OUTPUT
    gtbMuxStates [ 3 , 4            , GTB_MASK ] = GTB_MUX_ODD_OUTPUT_MASK
    gtbMuxStates [ 3 , 4            , GTB_ADDR ] = GTOBUF_B_SRC_SW
    gtbMuxStates [ 3 , MUX_SRC_OFF  , GTB_DATA ] = GTB_MUX_DISABLE_ODD_OUTPUT
    gtbMuxStates [ 3 , MUX_SRC_OFF  , GTB_MASK ] = GTB_MUX_ODD_OUTPUT_MASK
    gtbMuxStates [ 3 , MUX_SRC_OFF  , GTB_ADDR ] = GTOBUF_B_SRC_SW

    gtbMuxStates [ 4 , 1            , GTB_DATA ] = GTB_MUX_ODD_GTO_SRC_TO_EVEN_OUTPUT
    gtbMuxStates [ 4 , 1            , GTB_MASK ] = GTB_MUX_EVEN_OUTPUT_MASK
    gtbMuxStates [ 4 , 1            , GTB_ADDR ] = GTOBUF_B_SRC_SW
    gtbMuxStates [ 4 , 2            , GTB_DATA ] = GTB_MUX_EVEN_GTO_SRC_TO_EVEN_OUTPUT
    gtbMuxStates [ 4 , 2            , GTB_MASK ] = GTB_MUX_EVEN_OUTPUT_MASK
    gtbMuxStates [ 4 , 2            , GTB_ADDR ] = GTOBUF_B_SRC_SW
    gtbMuxStates [ 4 , 3            , GTB_DATA ] = GTB_MUX_ODD_GTO_SRC_TO_EVEN_OUTPUT
    gtbMuxStates [ 4 , 3            , GTB_MASK ] = GTB_MUX_EVEN_OUTPUT_MASK
    gtbMuxStates [ 4 , 3            , GTB_ADDR ] = GTOBUF_B_SRC_SW
    gtbMuxStates [ 4 , 4            , GTB_DATA ] = GTB_MUX_EVEN_GTO_SRC_TO_EVEN_OUTPUT
    gtbMuxStates [ 4 , 4            , GTB_MASK ] = GTB_MUX_EVEN_OUTPUT_MASK
    gtbMuxStates [ 4 , 4            , GTB_ADDR ] = GTOBUF_B_SRC_SW
    gtbMuxStates [ 4 , MUX_SRC_OFF  , GTB_DATA ] = GTB_MUX_DISABLE_EVEN_OUTPUT
    gtbMuxStates [ 4 , MUX_SRC_OFF  , GTB_MASK ] = GTB_MUX_EVEN_OUTPUT_MASK
    gtbMuxStates [ 4 , MUX_SRC_OFF  , GTB_ADDR ] = GTOBUF_B_SRC_SW

    gtbSamplClkControlAddr [ 1 ] = GTOBUF_A_CLK_CTL
    gtbSamplClkControlAddr [ 2 ] = GTOBUF_A_CLK_CTL
    gtbSamplClkControlAddr [ 3 ] = GTOBUF_B_CLK_CTL
    gtbSamplClkControlAddr [ 4 ] = GTOBUF_B_CLK_CTL
 
    gtbSampClkOutputSelection [ 1 ] = GTB_CLOCK_OUTPUT_GENERATOR
    gtbSampClkOutputSelection [ 2 ] = GTB_CLOCK_OUTPUT_DIVIDED  
    gtbSampClkOutputSelection [ 3 ] = GTB_CLOCK_OUTPUT_OFF      
   

    
    gtbSamplerMuxStates [ 1 , AUX_SAMPLER , ODD  , GTB_DATA ] = GTB_MUX_ODD_AUX_SAMPLER_TO_ODD_DIGITIZER
    gtbSamplerMuxStates [ 1 , AUX_SAMPLER , ODD  , GTB_MASK ] = GTB_MUX_ODD_DIGITIZER_MASK
    gtbSamplerMuxStates [ 1 , AUX_SAMPLER , ODD  , GTB_ADDR ] = GTOBUF_A_SAMP_MUX_CTL
    gtbSamplerMuxStates [ 1 , AUX_SAMPLER , EVEN , GTB_DATA ] = GTB_MUX_EVEN_AUX_SAMPLER_TO_ODD_DIGITIZER
    gtbSamplerMuxStates [ 1 , AUX_SAMPLER , EVEN , GTB_MASK ] = GTB_MUX_ODD_DIGITIZER_MASK
    gtbSamplerMuxStates [ 1 , AUX_SAMPLER , EVEN , GTB_ADDR ] = GTOBUF_A_SAMP_MUX_CTL
    gtbSamplerMuxStates [ 1 , AUX_SAMPLER , OFF  , GTB_DATA ] = GTB_MUX_DISABLE_ODD_DIGITIZER
    gtbSamplerMuxStates [ 1 , AUX_SAMPLER , OFF  , GTB_MASK ] = GTB_MUX_ODD_DIGITIZER_MASK
    gtbSamplerMuxStates [ 1 , AUX_SAMPLER , OFF  , GTB_ADDR ] = GTOBUF_A_SAMP_MUX_CTL

    gtbSamplerMuxStates [ 2 , AUX_SAMPLER , ODD  , GTB_DATA ] = GTB_MUX_ODD_AUX_SAMPLER_TO_EVEN_DIGITIZER
    gtbSamplerMuxStates [ 2 , AUX_SAMPLER , ODD  , GTB_MASK ] = GTB_MUX_EVEN_DIGITIZER_MASK
    gtbSamplerMuxStates [ 2 , AUX_SAMPLER , ODD  , GTB_ADDR ] = GTOBUF_A_SAMP_MUX_CTL
    gtbSamplerMuxStates [ 2 , AUX_SAMPLER , EVEN , GTB_DATA ] = GTB_MUX_EVEN_AUX_SAMPLER_TO_EVEN_DIGITIZER
    gtbSamplerMuxStates [ 2 , AUX_SAMPLER , EVEN , GTB_MASK ] = GTB_MUX_EVEN_DIGITIZER_MASK
    gtbSamplerMuxStates [ 2 , AUX_SAMPLER , EVEN , GTB_ADDR ] = GTOBUF_A_SAMP_MUX_CTL
    gtbSamplerMuxStates [ 2 , AUX_SAMPLER , OFF  , GTB_DATA ] = GTB_MUX_DISABLE_EVEN_DIGITIZER
    gtbSamplerMuxStates [ 2 , AUX_SAMPLER , OFF  , GTB_MASK ] = GTB_MUX_EVEN_DIGITIZER_MASK
    gtbSamplerMuxStates [ 2 , AUX_SAMPLER , OFF  , GTB_ADDR ] = GTOBUF_A_SAMP_MUX_CTL
                                           
    gtbSamplerMuxStates [ 3 , AUX_SAMPLER , ODD  , GTB_DATA ] = GTB_MUX_ODD_AUX_SAMPLER_TO_ODD_DIGITIZER
    gtbSamplerMuxStates [ 3 , AUX_SAMPLER , ODD  , GTB_MASK ] = GTB_MUX_ODD_DIGITIZER_MASK
    gtbSamplerMuxStates [ 3 , AUX_SAMPLER , ODD  , GTB_ADDR ] = GTOBUF_B_SAMP_MUX_CTL
    gtbSamplerMuxStates [ 3 , AUX_SAMPLER , EVEN , GTB_DATA ] = GTB_MUX_EVEN_AUX_SAMPLER_TO_ODD_DIGITIZER
    gtbSamplerMuxStates [ 3 , AUX_SAMPLER , EVEN , GTB_MASK ] = GTB_MUX_ODD_DIGITIZER_MASK
    gtbSamplerMuxStates [ 3 , AUX_SAMPLER , EVEN , GTB_ADDR ] = GTOBUF_B_SAMP_MUX_CTL
    gtbSamplerMuxStates [ 3 , AUX_SAMPLER , OFF  , GTB_DATA ] = GTB_MUX_DISABLE_ODD_DIGITIZER
    gtbSamplerMuxStates [ 3 , AUX_SAMPLER , OFF  , GTB_MASK ] = GTB_MUX_ODD_DIGITIZER_MASK
    gtbSamplerMuxStates [ 3 , AUX_SAMPLER , OFF  , GTB_ADDR ] = GTOBUF_B_SAMP_MUX_CTL
                                           
    gtbSamplerMuxStates [ 4 , AUX_SAMPLER , ODD  , GTB_DATA ] = GTB_MUX_ODD_AUX_SAMPLER_TO_EVEN_DIGITIZER
    gtbSamplerMuxStates [ 4 , AUX_SAMPLER , ODD  , GTB_MASK ] = GTB_MUX_EVEN_DIGITIZER_MASK
    gtbSamplerMuxStates [ 4 , AUX_SAMPLER , ODD  , GTB_ADDR ] = GTOBUF_B_SAMP_MUX_CTL
    gtbSamplerMuxStates [ 4 , AUX_SAMPLER , EVEN , GTB_DATA ] = GTB_MUX_EVEN_AUX_SAMPLER_TO_EVEN_DIGITIZER
    gtbSamplerMuxStates [ 4 , AUX_SAMPLER , EVEN , GTB_MASK ] = GTB_MUX_EVEN_DIGITIZER_MASK
    gtbSamplerMuxStates [ 4 , AUX_SAMPLER , EVEN , GTB_ADDR ] = GTOBUF_B_SAMP_MUX_CTL
    gtbSamplerMuxStates [ 4 , AUX_SAMPLER , OFF  , GTB_DATA ] = GTB_MUX_DISABLE_EVEN_DIGITIZER
    gtbSamplerMuxStates [ 4 , AUX_SAMPLER , OFF  , GTB_MASK ] = GTB_MUX_EVEN_DIGITIZER_MASK
    gtbSamplerMuxStates [ 4 , AUX_SAMPLER , OFF  , GTB_ADDR ] = GTOBUF_B_SAMP_MUX_CTL
    
    gtbSamplerMuxStates [ 1 , GTO_SAMPLER , ODD  , GTB_DATA ] = GTB_MUX_ODD_GTO_SAMPLER_TO_ODD_DIGITIZER
    gtbSamplerMuxStates [ 1 , GTO_SAMPLER , ODD  , GTB_MASK ] = GTB_MUX_ODD_DIGITIZER_MASK
    gtbSamplerMuxStates [ 1 , GTO_SAMPLER , ODD  , GTB_ADDR ] = GTOBUF_A_SAMP_MUX_CTL
    gtbSamplerMuxStates [ 1 , GTO_SAMPLER , EVEN , GTB_DATA ] = GTB_MUX_EVEN_GTO_SAMPLER_TO_ODD_DIGITIZER
    gtbSamplerMuxStates [ 1 , GTO_SAMPLER , EVEN , GTB_MASK ] = GTB_MUX_ODD_DIGITIZER_MASK
    gtbSamplerMuxStates [ 1 , GTO_SAMPLER , EVEN , GTB_ADDR ] = GTOBUF_A_SAMP_MUX_CTL
    gtbSamplerMuxStates [ 1 , GTO_SAMPLER , OFF  , GTB_DATA ] = GTB_MUX_DISABLE_ODD_DIGITIZER
    gtbSamplerMuxStates [ 1 , GTO_SAMPLER , OFF  , GTB_MASK ] = GTB_MUX_ODD_DIGITIZER_MASK
    gtbSamplerMuxStates [ 1 , GTO_SAMPLER , OFF  , GTB_ADDR ] = GTOBUF_A_SAMP_MUX_CTL
                                                           
    gtbSamplerMuxStates [ 2 , GTO_SAMPLER , ODD  , GTB_DATA ] = GTB_MUX_ODD_GTO_SAMPLER_TO_EVEN_DIGITIZER
    gtbSamplerMuxStates [ 2 , GTO_SAMPLER , ODD  , GTB_MASK ] = GTB_MUX_EVEN_DIGITIZER_MASK
    gtbSamplerMuxStates [ 2 , GTO_SAMPLER , ODD  , GTB_ADDR ] = GTOBUF_A_SAMP_MUX_CTL
    gtbSamplerMuxStates [ 2 , GTO_SAMPLER , EVEN , GTB_DATA ] = GTB_MUX_EVEN_GTO_SAMPLER_TO_EVEN_DIGITIZER
    gtbSamplerMuxStates [ 2 , GTO_SAMPLER , EVEN , GTB_MASK ] = GTB_MUX_EVEN_DIGITIZER_MASK
    gtbSamplerMuxStates [ 2 , GTO_SAMPLER , EVEN , GTB_ADDR ] = GTOBUF_A_SAMP_MUX_CTL
    gtbSamplerMuxStates [ 2 , GTO_SAMPLER , OFF  , GTB_DATA ] = GTB_MUX_DISABLE_EVEN_DIGITIZER
    gtbSamplerMuxStates [ 2 , GTO_SAMPLER , OFF  , GTB_MASK ] = GTB_MUX_EVEN_DIGITIZER_MASK
    gtbSamplerMuxStates [ 2 , GTO_SAMPLER , OFF  , GTB_ADDR ] = GTOBUF_A_SAMP_MUX_CTL
                                                           
    gtbSamplerMuxStates [ 3 , GTO_SAMPLER , ODD  , GTB_DATA ] = GTB_MUX_ODD_GTO_SAMPLER_TO_ODD_DIGITIZER
    gtbSamplerMuxStates [ 3 , GTO_SAMPLER , ODD  , GTB_MASK ] = GTB_MUX_ODD_DIGITIZER_MASK
    gtbSamplerMuxStates [ 3 , GTO_SAMPLER , ODD  , GTB_ADDR ] = GTOBUF_B_SAMP_MUX_CTL
    gtbSamplerMuxStates [ 3 , GTO_SAMPLER , EVEN , GTB_DATA ] = GTB_MUX_EVEN_GTO_SAMPLER_TO_ODD_DIGITIZER
    gtbSamplerMuxStates [ 3 , GTO_SAMPLER , EVEN , GTB_MASK ] = GTB_MUX_ODD_DIGITIZER_MASK
    gtbSamplerMuxStates [ 3 , GTO_SAMPLER , EVEN , GTB_ADDR ] = GTOBUF_B_SAMP_MUX_CTL
    gtbSamplerMuxStates [ 3 , GTO_SAMPLER , OFF  , GTB_DATA ] = GTB_MUX_DISABLE_ODD_DIGITIZER
    gtbSamplerMuxStates [ 3 , GTO_SAMPLER , OFF  , GTB_MASK ] = GTB_MUX_ODD_DIGITIZER_MASK
    gtbSamplerMuxStates [ 3 , GTO_SAMPLER , OFF  , GTB_ADDR ] = GTOBUF_B_SAMP_MUX_CTL
                                                           
    gtbSamplerMuxStates [ 4 , GTO_SAMPLER , ODD  , GTB_DATA ] = GTB_MUX_ODD_GTO_SAMPLER_TO_EVEN_DIGITIZER
    gtbSamplerMuxStates [ 4 , GTO_SAMPLER , ODD  , GTB_MASK ] = GTB_MUX_EVEN_DIGITIZER_MASK
    gtbSamplerMuxStates [ 4 , GTO_SAMPLER , ODD  , GTB_ADDR ] = GTOBUF_B_SAMP_MUX_CTL
    gtbSamplerMuxStates [ 4 , GTO_SAMPLER , EVEN , GTB_DATA ] = GTB_MUX_EVEN_GTO_SAMPLER_TO_EVEN_DIGITIZER
    gtbSamplerMuxStates [ 4 , GTO_SAMPLER , EVEN , GTB_MASK ] = GTB_MUX_EVEN_DIGITIZER_MASK
    gtbSamplerMuxStates [ 4 , GTO_SAMPLER , EVEN , GTB_ADDR ] = GTOBUF_B_SAMP_MUX_CTL
    gtbSamplerMuxStates [ 4 , GTO_SAMPLER , OFF  , GTB_DATA ] = GTB_MUX_DISABLE_EVEN_DIGITIZER
    gtbSamplerMuxStates [ 4 , GTO_SAMPLER , OFF  , GTB_MASK ] = GTB_MUX_EVEN_DIGITIZER_MASK
    gtbSamplerMuxStates [ 4 , GTO_SAMPLER , OFF  , GTB_ADDR ] = GTOBUF_B_SAMP_MUX_CTL

    s = ""
    gtbHighRange = false
    gtbSampMuxStates [ 1 ] = "gto sampler"
    gtbSampMuxStates [ 2 ] = "gto sampler"
    gtbSampMuxStates [ 3 ] = "aux sampler"
    gtbSampMuxStates [ 4 ] = "aux sampler"

    GTB_AmpsToLowOutput ( <: 1 , 2 , 3 , 4 :> )
    
    if 1 in gtbSrcSet then
        GTB_SelectSourceMUXPath ( <: 1 , 2 :> , <: MUX_SRC_OFF , MUX_SRC_OFF :> )
        GTB_SetSourceLevel      ( <: 1 , 2 :> , BALANCED , 0.5V, GTB_NORMAL_SOURCE_RANGING )
        GTB_SelectSampleClockOutput ( <: 1 :> , DIVIDED_CLOCK )
        GTB_SetSampleClockDivider ( 1 , 4 )
    endif
    
    if 3 in gtbSrcSet then
        GTB_SelectSourceMUXPath ( <: 3 , 4 :> , <: MUX_SRC_OFF , MUX_SRC_OFF :> )
        GTB_SetSourceLevel      ( <: 3 , 4 :> , BALANCED , 0.5V, GTB_NORMAL_SOURCE_RANGING )
        GTB_SelectSampleClockOutput ( <: 3 :> , DIVIDED_CLOCK )
        GTB_SetSampleClockDivider ( 3 , 4 )
    endif
    
endbody
--------------------------------------------------------------------------------
procedure GTB_SelectSourcePath ( gtbSrc , gtbSrcPath , gtbSrcConnection )
--------------------------------------------------------------------------------
--  This procedure is used to select any of 6 different signal paths through
--  the RF Relay matrix in the GTO Buffer source.  
--
--  Three of the paths are used for signal level setting to increase the 
--  dynamic range of the GTO.  Three additional paths are available to
--  the user so that application-specific signal conditioning can be accomplished.
--
--  gtbSrc selects the source channel to set.
--
--  gtbSrcPath selects one of the six paths.  The following constants are to
--  be used for path selection:
--  GTB_SRC_THROUGH     for the path direct from the GTO output to the head.
--  GTB_SRC_GAIN        for the path through the variable gain amplifier.
--  GTB_SRC_ATTN        for the path through the 26dB attenuator.
--  GTB_SRC_USER1       for the first user path.
--  GTB_SRC_USER2       for the second user path.
--  GTB_SRC_USER3       for the third user path
--
--  gtbSrcConnection is used to select whether which sides of the
--  differential pair are energized.  The non-inverting, inverting or both
--  sides may be selected  The following constants are to
--  be used for path selection:
--
--  SE_PLUS             for the non-inverting output only.
--  SE_MINUS            for the inverting output only.
--  BALANCED            for both output together.


in integer                  : gtbSrc
in integer                  : gtbSrcPath
in integer                  : gtbSrcConnection

local integer               : i

body

    if gtbSrcPath <> GTB_SRC_GAIN then  -- if not using VGA, disable input
        GTB_SelectSourceMUXPath ( <: word ( gtbSrc ) :> , <: MUX_SRC_OFF :> )
    endif
    
    GTB_set_address ( gtbSlotNum , gtbSrcRelayAddr [ gtbSrc ] , gtbSrcConnectAry [ gtbSrcPath , gtbSrcConnection ] , 0 )

endbody
--------------------------------------------------------------------------------
procedure GTB_SetSourceLevel ( gtbSrcList , gtbSrcConnection , gtbSrcLevel , forceHighRange )
--------------------------------------------------------------------------------
--  this procedure will be reworked for calbration later.
--  This procedure is designed to change the level of all
--  channels in the list gtbSrcList. If the level is within the
--  range of the Variable Gain  Amplifier path, then the relays 
--  will all be set to the proper state, followed by all the
--  control dacs being set simultaneously.  So if the level change
--  is from one level supported by the gain path to another 
--  supported by the gain path, all channels will change simultaneously.
--
--  gtbSrcConnection is used to select whether which sides of the
--  differential pair are energized.  The non-inverting, inverting or both
--  sides may be selected  The following constants are to
--  be used for path selection:
--
--  SE_PLUS             for the non-inverting output only.
--  SE_MINUS            for the inverting output only.
--  BALANCED            for both output together.
--
--  gtbSrcLevel is the output level in volts peak-to-peak.
--
--  forceHighRange forces the variable gain range for the vx_gto buffer to be used.
--  This allows the trigger capabilities for level changes and the source switch to be
--  used down to ouput levels of as little as 100mv.  Otherwise, the lower limit of the
--  gain path is 1.0v.
-- 
--  GTB_FORCE_HIGH_SOURCE_RANGE is used to force the high range
--  GTB_NORMAL_SOURCE_RANGING   is used for normal ranging


in word list [ 4 ]          : gtbSrcList
in integer                  : gtbSrcConnection
in float                    : gtbSrcLevel
in boolean                  : forceHighRange

local integer               : i
local integer               : gtbSrcPath
local float                 : gtbSrcSelectLevel
local float                 : gtbSrcCalculatedLevel
local word                  : dacA [ GTB_MAX_SRC ]
local word                  : dacB [ GTB_MAX_SRC ]
local word                  : dacSelectBits
local boolean               : loadDacs

body

    GTB_set_address ( gtbSlotNum , GTOBUF_DAC_TRIG_CTL , 0 , 0 )
    GTB_set_address ( gtbSlotNum , GTOBUF_SYN_DIR      , 0 , 0 )
    
    if gtbSrcConnection <> BALANCED then
        gtbSrcSelectLevel = gtbSrcLevel * 2.0
    else 
        gtbSrcSelectLevel = gtbSrcLevel 
    endif

    loadDacs = false

    if forceHighRange then 
        if gtbSrcSelectLevel < GTB_SRC_GAIN_FORCED_MIN and forceHighRange then 
            println ( stdout )
            println ( stdout , "ERROR!! GTO output level: " + sprint ( gtbSrcLevel ) + " V is outside specified forced range." )
            println ( stdout , "from: gtoFrontEndCtrl.mod/GTB_setSourceLevel. " )
            println ( stdout )    
        else
            gtbSrcPath = GTB_SRC_GAIN
            gtbSrcCalculatedLevel = GTB_SRC_GAIN_PATH_GTO_LEVEL
            for i = 1 to len ( gtbSrcList ) do
                GTB_CalculateGainPathBits ( gtbSrcList [ i ] , gtbSrcSelectLevel , dacA [ i ] , dacB [ i ] )
            endfor
            loadDacs = true
        endif
    elseif gtbSrcSelectLevel < GTB_SRC_ATTEN_PATH_MIN then 
        println ( stdout )
        println ( stdout , "ERROR!! GTO output level: " + sprint ( gtbSrcLevel ) + " V is outside specified range." )
        println ( stdout , "from: gtoFrontEndCtrl.mod/GTB_setSourceLevel. " )
        println ( stdout )    
    elseif gtbSrcSelectLevel < GTB_SRC_ATTEN_PATH_MAX then
        gtbSrcPath = GTB_SRC_ATTN
        gtbSrcCalculatedLevel =  gtbSrcSelectLevel * gtbAttnPathCalfactor
        GTB_AmpsToLowOutput ( gtbSrcList ) 
    elseif gtbSrcSelectLevel < GTB_SRC_THROUGH_PATH_MAX then
        gtbSrcPath = GTB_SRC_THROUGH
        gtbSrcCalculatedLevel =  gtbSrcSelectLevel * gtbThroughPathCalfactor 
        GTB_AmpsToLowOutput ( gtbSrcList ) 
    elseif gtbSrcSelectLevel < GTB_SRC_GAIN_PATH_MAX then
        gtbSrcPath = GTB_SRC_GAIN
        gtbSrcCalculatedLevel = GTB_SRC_GAIN_PATH_GTO_LEVEL
        for i = 1 to len ( gtbSrcList ) do
            GTB_CalculateGainPathBits ( gtbSrcList [ i ] , gtbSrcSelectLevel , dacA [ i ] , dacB [ i ] )
        endfor
        loadDacs = true
    else
        println ( stdout )
        println ( stdout , "ERROR!! GTO output level: " + sprint ( gtbSrcLevel ) + " V is outside specified range." )
        println ( stdout , "from: gtoFrontEndCtrl.mod/GTB_setSourceLevel. " )
        println ( stdout )
    endif

    if not afe then
        set vx_gto gtbSrcList output level to gtbSrcCalculatedLevel force
    endif
    
    dacSelectBits = 0
    for i = 1 to len ( gtbSrcList )  do
        if i in gtbSrcSet then
            if gtbSrcPath <> GTB_SRC_GAIN then  -- if not using VGA, disable input
                gtbHighRange [ i ] = false
                GTB_SelectSourceMUXPath ( <: word ( i ) :> , <: MUX_SRC_OFF :> )
            else
                gtbHighRange [ i ] = true
            endif
            GTB_UpdateSourcePathCounts ( gtbSrcList [ i ] , gtbSrcPath , gtbSrcConnection )
            GTB_set_address ( gtbSlotNum , gtbSrcRelayAddr [ gtbSrcList [ i ] ] , gtbSrcConnectAry [ gtbSrcPath , gtbSrcConnection ] , 0 )
            if loadDacs then
                dacSelectBits = dacSelectBits | 3 * ( 2 ^ ( 2 * ( gtbSrcList [ i ] - 1 ) ) )
                GTB_set_address ( gtbSlotNum , gtbSrcDacAAddr  [ gtbSrcList [ i ] ] , dacA [ i ] , 0 )
                GTB_set_address ( gtbSlotNum , gtbSrcDacBAddr  [ gtbSrcList [ i ] ] , dacB [ i ] , 0 )
            endif
        endif
    endfor  

    if gtbSrcPath = GTB_SRC_GAIN then
        wait ( 0.05s )
    endif
    
    if loadDacs then
        GTB_set_address ( gtbSlotNum , GTOBUF_DAC_CTL , dacSelectBits , 16#0 )
    endif

endbody
--------------------------------------------------------------------------------
procedure GTB_CalculateGainPathBits ( chan , gtbSrcLevel , dacA , dacB )
--------------------------------------------------------------------------------
in word                         : chan
in float                        : gtbSrcLevel
out word                        : dacA
out word                        : dacB

local integer                   : i , j , k , l

body

    if gtbSrcLevel < gtbDacBCalLevels [ chan , 1 ] then
        dacA = 0
        j = gtbDacBCalSz [ chan ] / 2
        k = gtbDacBCalSz [ chan ] / 4
        for i = 1 to 100 do 
            if j > gtbDacBCalSz [ chan ] - 1 then
                j = gtbDacBCalSz [ chan ] - 1
            elseif j < 1 then
                j = 1
            endif
            if gtbDacBCalLevels [ chan , j ]  > gtbSrcLevel and gtbDacBCalLevels [ chan , j + 1 ] > gtbSrcLevel then 
                j = j + k
                k = ( k + 1 ) / 2 
            elseif gtbDacBCalLevels [ chan , j ] < gtbSrcLevel and gtbDacBCalLevels [ chan , j + 1 ] < gtbSrcLevel then 
                j = j - k
                k = ( k + 1 ) / 2 
            else
                dacB = word ( gtbDacBCalBits [ chan , j ] + integer ( float ( gtbDacBCalBits [ chan , j + 1 ] - gtbDacBCalBits [ chan , j ] ) * ( ( gtbSrcLevel - gtbDacBCalLevels [ chan , j ] ) / ( gtbDacBCalLevels [ chan , j + 1 ] - gtbDacBCalLevels [ chan , j ] ) ) ))
                break
            endif
--            println ( stdout , i:12 , j:12 , k:12 ,gtbDacBCalLevels [ chan , j ]:12:6 , gtbDacBCalLevels [ chan , j + 1 ]:12:6 , gtbSrcLevel:12:6 ) 
        endfor
    else
        dacB = 0
        j = gtbDacACalSz [ chan ] / 2
        k = gtbDacACalSz [ chan ] / 4
        for i = 1 to 100 do 
            if j > gtbDacACalSz [ chan ] - 1 then
                j = gtbDacACalSz [ chan ] - 1
            endif
            if j = 0 then
                j = 1 
            endif
            if gtbDacACalLevels [ chan , j ]  < gtbSrcLevel and gtbDacACalLevels [ chan , j + 1 ] < gtbSrcLevel then 
                j = j + k
                k = ( k + 1 ) / 2
            elseif gtbDacACalLevels [ chan , j ] > gtbSrcLevel and gtbDacACalLevels [ chan , j + 1 ] > gtbSrcLevel then 
                j = j - k
                k = ( k + 1 ) / 2
            else
                dacA = word ( gtbDacACalBits [ chan , j ] - integer ( float ( gtbDacACalBits [ chan , j + 1 ] - gtbDacACalBits [ chan , j ] ) * ( ( gtbSrcLevel - gtbDacACalLevels [ chan , j ] ) / ( gtbDacACalLevels [ chan , j + 1 ] - gtbDacACalLevels [ chan , j ] ) ) ))
                break
            endif
 --           println ( stdout , i:12 , j:12 , k:12 ,gtbDacBCalLevels [ chan , j ]:12:6 , gtbDacBCalLevels [ chan , j + 1 ]:12:6 , gtbSrcLevel:12:6 ) 
        endfor
    endif

endbody
--------------------------------------------------------------------------------
procedure GTB_SelectSourceMUXPath ( bufChanList , gtoChanList )
--------------------------------------------------------------------------------
--  This procedure selects the GTO output to Buffer output mapping for the 
--  GAIN PATH ONLY.  The gain path through the GTO Buffer includes a 2 by 2
--  crosspoint switch that may be used to connect either of two GTO outputs
--  to either of two GTO Buffer outputs.  This enables the user to switch
--  patterns on software command.
--
--  This mapping in on a per-gto-brick basis, so that GTO channel 1 can be sent
--  to either or both GTO Buffer outputs 1 and 2.  GTO channel 2 can be sent
--  to either or both GTO Buffer outputs 1 and 2.  GTO channel 3 can be sent
--  to either or both GTO Buffer outputs 3 and 4.  GTO channel 4 can be sent
--  to either or both GTO Buffer outputs 3 and 4.  
--  Other choices may give undesired results.


in word list [ 4 ]              : bufChanList   -- selects the Gto Buffer output
in word list [ 5 ]              : gtoChanList   -- selects the Gto Source.

local integer                   : i

body

    GTB_set_address ( gtbSlotNum , GTOBUF_SRC_SW_TRIG_CTL , 16#0 , 16#0 )
    
    for i = 1 to len ( bufChanList ) do
        if gtbHighRange [ i ] then 
            GTB_set_address ( gtbSlotNum , gtbMuxStates [ bufChanList [ i ] , gtoChanList [ i ] , GTB_ADDR ] , gtbMuxStates [ bufChanList [ i ] , gtoChanList [ i ] , GTB_DATA ] , gtbMuxStates [ bufChanList [ i ] , gtoChanList [ i ] , GTB_MASK ] )
        else
            GTB_set_address ( gtbSlotNum , gtbMuxStates [ bufChanList [ i ] , MUX_SRC_OFF , GTB_ADDR ] , gtbMuxStates [ bufChanList [ i ] , MUX_SRC_OFF , GTB_DATA ] , gtbMuxStates [ bufChanList [ i ] , MUX_SRC_OFF , GTB_MASK ] )
        endif
    endfor
    
endbody
--------------------------------------------------------------------------------
procedure GTB_SetSampleClockDivider ( gtbSampler , divisor )
--------------------------------------------------------------------------------
--  This procedure sets the sample clock divider on the GTO Buffer analog board.
--  The same divider is shared across all four samplers on a board.  This means
--  that Aux Sampler 1, GTO Rx sampler 1, Aux Sampler 2, and GTO Rx sampler 2 all
--  share the same clock divider, and changing either channel 1 or 2 will always
--  change both channels.  Similarly,  This means  that Aux Sampler 3, GTO Rx 
--  sampler 3, Aux Sampler 4, and GTO Rx sampler 4 all share the same clock divider,
--  and changing either channel 3 or 4 will always change both channels.  
--
--  Select 1, 2, 3 or 4 for gtbSampler
--
--  The divisor can be set from 4 to 64 in steps of 2.  If an odd number is selected
--  the next lower even number will be selected.  Selections that are out of range
--  will generate an error message.

in word                                 : gtbSampler  --  sampler channel associated with a divider.
in word                                 : divisor     -- range is 4 to 64 in steps of 2.  Odd numbers will be reduced by 1.


body

    if divisor > 64 or divisor < 4 then
        println ( stdout , "ERROR: sample clock divider must be set to an even number between 4 and 64." )
        println ( stdout , "from: gtoFrontEndCtrl.mod/GTB_SetSampleClockDivider" )
    else
        if gtbSampler in [ 1 , 2 , 5 , 6 ] then
            gtb_sampleClkDivVal [ 1 : 2 ] = divisor
            gtb_sampleClkDivVal [ 5 : 6 ] = divisor
        else
            gtb_sampleClkDivVal [ 3 : 4 ] = divisor
            gtb_sampleClkDivVal [ 7 : 8 ] = divisor
        endif
        GTB_set_address ( gtbSlotNum , gtbSamplClkControlAddr [ gtbSampler ] , 31 & ~( ( divisor  >> 1 ) - 1) , GTB_CLK_DIVIDER_MASK )
    endif

endbody
--------------------------------------------------------------------------------
procedure GTB_SelectSampleClockOutput ( gtbSampleClockList , outputSelection )
--------------------------------------------------------------------------------
--  This procedure selects the signal that is sent to the sample clock output ports
--  on the test head.  There are two sample clock output ports.  Sample clock 1 output
--  is associated with buffer channels 1 and 2.  Sample clock 2 output is associated
--  with channels 3 and 4.  
--  
--  To select the sample clocks outputs to be set by selecting <:1:>, <:2:>, or <:1,2:>
--  as values for gtbSampleClockList.
--
--  There are three possible conditions to set. 
--  Choose GENERATOR to send the output of the clock generator to the sample clock output.
--  Choose DIVIDED_CLOCK to send the divided clock at the rate seen by the samplers to the sample clock output
--  Choose OFF to inhibit any output from the port.


in word list [ GTB_MAX_SRC ]            : gtbSampleClockList
in word                                 : outputSelection  -- GENERATOR, DIVIDED_CLOCK or OFF

local integer                           : i
local word                              : j

body

    for i = 1 to len ( gtbSampleClockList ) do
        if gtbSampleClockList [ i ] in gtbSrcSet then
            GTB_set_address ( gtbSlotNum , gtbSamplClkControlAddr [ gtbSampleClockList [ i ] ] , gtbSampClkOutputSelection [ outputSelection ] , GTB_CLOCK_OUTPUT_SELECT_MASK )
        endif
    endfor  

endbody
--------------------------------------------------------------------------------
function GTB_read_address ( slotNumber , regAddr ) : word
--------------------------------------------------------------------------------
in word                         : slotNumber
in word                         : regAddr

body

    read cx register offset regAddr slot GTB_SLOT_NUM into gtb_shadow [ regAddr ]
    return ( gtb_shadow [ regAddr ] )
    
endbody
--------------------------------------------------------------------------------
procedure GTB_SelectSourceMUXPathOnTrigger ( bufChanList , gtoChanList , triggerNumber )
--------------------------------------------------------------------------------
--  This procedure selects the GTO output to Buffer output mapping for the 
--  GAIN PATH ONLY.  The gain path through the GTO Buffer includes a 2 by 2
--  crosspoint switch that may be used to connect either of two GTO outputs
--  to either of two GTO Buffer outputs.  This enables the user to switch
--  patterns on command.
--
--  This procedure arms the control hardware in the GTO buffer to set the 
--  crosspoint switch upon receipt of a pulse on the SyncBusline ( 1 through 8 )
--  selected by triggerNumber.
--
--  This mapping in on a per-gto-brick basis, so that GTO channel 1 can be sent
--  to either or both GTO Buffer outputs 1 and 2.  GTO channel 2 can be sent
--  to either or both GTO Buffer outputs 1 and 2.  GTO channel 3 can be sent
--  to either or both GTO Buffer outputs 3 and 4.  GTO channel 4 can be sent
--  to either or both GTO Buffer outputs 3 and 4.  
--  Other choices may give undesired results.

in word list [ 4 ]              : bufChanList       -- selected GTO Buffer output
in word list [ 4 ]              : gtoChanList       -- selected GTO channel
in word                         : triggerNumber     

local integer                   : i
local word                      : trig
local word                      : trigBit

body

    trig = 1 << ( triggerNumber + 7 )
    
    GTB_set_address ( gtbSlotNum , GTOBUF_SRC_SW_TRIG_CTL , trig , 16#00FF )
    GTB_set_address ( gtbSlotNum , GTOBUF_SYN_DIR , trig , 16#00FF )

    for i = 1 to len ( bufChanList ) do
        if gtbHighRange [ i ] then 
            GTB_set_address ( gtbSlotNum , gtbMuxStates [ bufChanList [ i ] , gtoChanList [ i ] , GTB_ADDR ] , gtbMuxStates [ bufChanList [ i ] , gtoChanList [ i ] , GTB_DATA ] , gtbMuxStates [ bufChanList [ i ] , gtoChanList [ i ] , GTB_MASK ] )
        else
            GTB_set_address ( gtbSlotNum , gtbMuxStates [ bufChanList [ i ] , MUX_SRC_OFF , GTB_ADDR ] , gtbMuxStates [ bufChanList [ i ] , gtoChanList [ i ] , GTB_DATA ] , gtbMuxStates [ bufChanList [ i ] , gtoChanList [ i ] , GTB_MASK ] )
        endif
    endfor
    
endbody
--------------------------------------------------------------------------------
procedure GTB_SelectSourceMUXPathAndSendTrigger ( bufChanList , gtoChanList , triggerNumber )
--------------------------------------------------------------------------------
--  This procedure selects the GTO output to Buffer output mapping for the 
--  GAIN PATH ONLY.  The gain path through the GTO Buffer includes a 2 by 2
--  crosspoint switch that may be used to connect either of two GTO outputs
--  to either of two GTO Buffer outputs.  This enables the user to switch
--  patterns on software command.
--
--  Simultaneously with the switch, a pulse will be emitted onto the SyncBus
--  line ( 1 through 8 ) selected by triggerNumber
--
--  This mapping in on a per-gto-brick basis, so that GTO channel 1 can be sent
--  to either or both GTO Buffer outputs 1 and 2.  GTO channel 2 can be sent
--  to either or both GTO Buffer outputs 1 and 2.  GTO channel 3 can be sent
--  to either or both GTO Buffer outputs 3 and 4.  GTO channel 4 can be sent
--  to either or both GTO Buffer outputs 3 and 4.  
--  Other choices may give undesired results.

in word list [ 4 ]              : bufChanList       -- selected GTO Buffer output
in word list [ 4 ]              : gtoChanList       -- selected GTO channel
in word                         : triggerNumber     -- choices are 1 through 8

local integer                   : i
local word                      : trig

body

    trig = 1 << ( triggerNumber + 7 )
    GTB_set_address ( gtbSlotNum , GTOBUF_SRC_SW_TRIG_CTL , trig , ~trig )
    
    for i = 1 to len ( bufChanList ) do
        if gtbHighRange [ i ] then 
            GTB_set_address ( gtbSlotNum , gtbMuxStates [ bufChanList [ i ] , gtoChanList [ i ] , GTB_ADDR ] , gtbMuxStates [ bufChanList [ i ] , gtoChanList [ i ] , GTB_DATA ] , gtbMuxStates [ bufChanList [ i ] , gtoChanList [ i ] , GTB_MASK ] )
        else
            GTB_set_address ( gtbSlotNum , gtbMuxStates [ bufChanList [ i ] , MUX_SRC_OFF , GTB_ADDR ] , gtbMuxStates [ bufChanList [ i ] , gtoChanList [ i ] , GTB_DATA ] , gtbMuxStates [ bufChanList [ i ] , gtoChanList [ i ] , GTB_MASK ] )
        endif
    endfor
    
endbody
--------------------------------------------------------------------------------
procedure GTB_SetSourceLevelOnTrigger ( gtbSrcList , gtbSrcConnection , gtbSrcLevel , syncBusLine )
--------------------------------------------------------------------------------
--  this procedure will be reworked for calbration later.
--  This procedure is designed to change the level of all
--  channels in the list gtbSrcList. If the level is within the
--  range of the Variable Gain  Amplifier path, then the relays 
--  will all be set to the proper state, followed by all the
--  control dacs being set simultaneously.  So if the level change
--  is from one level supported by the gain path to another 
--  supported by the gain path, all channels will change simultaneously.
--
--  gtbSrcConnection is used to select whether which sides of the
--  differential pair are energized.  The non-inverting, inverting or both
--  sides may be selected  The following constants are to
--  be used for path selection:
--
--  SE_PLUS             for the non-inverting output only.
--  SE_MINUS            for the inverting output only.
--  BALANCED            for both output together.
--
--  gtbSrcLevel is the output level in volts peak-to-peak.
--
--  This procedure arms the control hardware in the GTO buffer to set the 
--  level dacs upon receipt of a pulse on the SyncBusline ( 1 through 8 )
--  selected by triggerNumber.
--

in word list [ 4 ]          : gtbSrcList
in integer                  : gtbSrcConnection
in float                    : gtbSrcLevel
in word                     : syncBusLine

local integer               : i
local word                  : gtbSrcPath
local float                 : gtbSrcSelectLevel
local float                 : gtbSrcCalculatedLevel
local word                  : dacA [ 4 ]
local word                  : dacB [ 4 ]
local word                  : dacSelectBits
local boolean               : loadDacs
local word                  : syncBusLineBit

body

    if syncBusLine < 1 or syncBusLine > 8 then
        println ( stdout , "ERROR!  syncbus line must be between 1 and 8.")
        println ( stdout , "from gtoFrontEndCtrl.mod/GTB_SetSourceLevelOnTrigger." )
        println ( stdout , "halt." )
        halt
    endif
    syncBusLineBit = 128 << syncBusLine
    GTB_set_address ( gtbSlotNum , GTOBUF_DAC_TRIG_CTL , syncBusLineBit , 16#00FF )
    GTB_set_address ( gtbSlotNum , GTOBUF_SYN_DIR , syncBusLineBit , 16#00FF )

    if gtbSrcConnection <>  BALANCED then
        gtbSrcSelectLevel = gtbSrcLevel * 2.0
    else 
        gtbSrcSelectLevel = gtbSrcLevel 
    endif
    
    loadDacs = false

    if gtbSrcSelectLevel < GTB_SRC_GAIN_PATH_MAX then
        gtbSrcPath = GTB_SRC_GAIN
        gtbSrcCalculatedLevel = GTB_SRC_GAIN_PATH_GTO_LEVEL
        for i = 1 to len ( gtbSrcList ) do
            if gtb_shadow [ gtbSrcRelayAddr [ gtbSrcList [ i ] ] ] <> gtbSrcConnectAry [ GTB_SRC_GAIN , gtbSrcConnection ] then
                GTB_AmpsToLowOutput ( <: gtbSrcList [ i ] :> ) 
            endif
            GTB_CalculateGainPathBits ( gtbSrcList [ i ] , gtbSrcSelectLevel , dacA [ gtbSrcList [ i ] ] , dacB [ gtbSrcList [ i ] ] )
        endfor
        loadDacs = true
    else
        println ( stdout )
        println ( stdout , "ERROR!! GTO output level: " + sprint ( gtbSrcLevel ) + " V is outside specified range." )
        println ( stdout , "from: gtoFrontEndCtrl.mod/GTB_setSourceLevel. " )
        println ( stdout )
    endif
    
    if not afe then
        set vx_gto gtbSrcList output level to gtbSrcCalculatedLevel force
    endif
    
    dacSelectBits = 0
    for i = 1 to len ( gtbSrcList )  do
        if i in gtbSrcSet then
            if gtbSrcPath <> GTB_SRC_GAIN then  -- if not using VGA, disable input
                gtbHighRange [ i ] = false
                GTB_SelectSourceMUXPath ( <: word ( i ) :> , <: MUX_SRC_OFF :> )
            endif
            GTB_set_address ( gtbSlotNum , gtbSrcRelayAddr [ gtbSrcList [ i ] ] , gtbSrcConnectAry [ gtbSrcPath , gtbSrcConnection ] , 0 )
            if loadDacs then
                dacSelectBits = dacSelectBits | 3 * ( 2 ^ ( 2 * ( gtbSrcList [ i ] - 1 ) ) )
                GTB_set_address ( gtbSlotNum , gtbSrcDacAAddr  [ gtbSrcList [ i ] ] , dacA [ i ] , 0 )
                GTB_set_address ( gtbSlotNum , gtbSrcDacBAddr  [ gtbSrcList [ i ] ] , dacB [ i ] , 0 )
            endif
        endif
    endfor  

    if gtbSrcPath = GTB_SRC_GAIN then
        wait ( 0.05s )
    endif
    
    if loadDacs then
        GTB_set_address ( gtbSlotNum , GTOBUF_DAC_CTL , dacSelectBits , 16#0 )
    endif
    
endbody
--------------------------------------------------------------------------------
procedure GTB_SetSourceLevelAndSendTrigger ( gtbSrcSet , gtbSrcConnection , gtbSrcLevel , gtbTriggerChannel )
--------------------------------------------------------------------------------
--  this procedure will be reworked for calbration later.
--  This procedure is designed to change the level of all
--  channels in the list gtbSrcList. If the level is within the
--  range of the Variable Gain  Amplifier path, then the relays 
--  will all be set to the proper state, followed by all the
--  control dacs being set simultaneously.  So if the level change
--  is from one level supported by the gain path to another 
--  supported by the gain path, all channels will change simultaneously.
--
--  gtbSrcConnection is used to select whether which sides of the
--  differential pair are energized.  The non-inverting, inverting or both
--  sides may be selected  The following constants are to
--  be used for path selection:
--
--  SE_PLUS             for the non-inverting output only.
--  SE_MINUS            for the inverting output only.
--  BALANCED            for both output together.
--
--  gtbSrcLevel is the output level in volts peak-to-peak.
--
--  Simultaneously with the change in level, a pulse will be emitted onto the SyncBus
--  line ( 1 through 8 ) selected by triggerNumber.

in set [ 4 ]                : gtbSrcSet
in integer                  : gtbSrcConnection
in float                    : gtbSrcLevel
in word                     : gtbTriggerChannel

local word                  : i
local word                  : gtbSrcPath
local float                 : gtbSrcSelectLevel
local float                 : gtbSrcCalculatedLevel
local word                  : dacA
local word                  : dacB
local word                  : trig
local word                  : dacSelectBits
local boolean               : loadDacs

body

if false then  
    -- set board to send pulse onto selected sync line
    trig = 1 << ( gtbTriggerChannel - 1 )
    GTB_set_address ( gtbSlotNum , GTOBUF_SYN_DIR , trig , ~trig )
    GTB_set_address ( gtbSlotNum , GTOBUF_DAC_TRIG_CTL , trig << 8 , 16#0 )

    if gtbSrcConnection <>  BALANCED then
        gtbSrcSelectLevel = gtbSrcLevel * 2.0
    else 
        gtbSrcSelectLevel = gtbSrcLevel * 2.0
    endif
    
    loadDacs = false

    set vx_gto gtbSrcSet output level to 100.0 mv force
    if gtbSrcSelectLevel < GTB_SRC_ATTEN_PATH_MIN then 
        println ( stdout )
        println ( stdout , "ERROR!! GTO output level: " + sprint ( gtbSrcLevel ) + " V is outside specified range." )
        println ( stdout , "from: gtoFrontEndCtrl.mod/GTB_setSourceLevel. " )
        println ( stdout )    
    elseif gtbSrcSelectLevel < GTB_SRC_ATTEN_PATH_MAX then
        gtbSrcPath = GTB_SRC_ATTN
        gtbSrcCalculatedLevel =  gtbSrcLevel * gtbAttnPathCalfactor 
    elseif gtbSrcSelectLevel < GTB_SRC_THROUGH_PATH_MAX then
        gtbSrcPath = GTB_SRC_THROUGH
        gtbSrcCalculatedLevel =  gtbSrcLevel * gtbThroughPathCalfactor 
    elseif gtbSrcSelectLevel < GTB_SRC_GAIN_PATH_MAX then
        gtbSrcPath = GTB_SRC_GAIN
        gtbSrcCalculatedLevel = GTB_SRC_GAIN_PATH_GTO_LEVEL
--        GTB_CalculateGainPathBits ( gtbSrcSelectLevel , dacA , dacB )
        loadDacs = true
    else
        println ( stdout )
        println ( stdout , "ERROR!! GTO output level: " + sprint ( gtbSrcLevel ) + " V is outside specified range." )
        println ( stdout , "from: gtoFrontEndCtrl.mod/GTB_setSourceLevel. " )
        println ( stdout )
    endif
    
    set vx_gto gtbSrcSet output level to gtbSrcCalculatedLevel
    
--    GTB_CalculateGainPathBits ( gtbSrcSelectLevel , dacA , dacB )
    
    dacSelectBits = 0
    for i = 1 to GTB_MAX_SRC do
        if i in gtbSrcSet then
            GTB_set_address ( gtbSlotNum , gtbSrcRelayAddr [ i ] , gtbSrcConnectAry [ gtbSrcPath , gtbSrcConnection ] , 0 )
            if loadDacs then
                dacSelectBits = dacSelectBits | 2#11 << ( 2 * i )
                GTB_set_address ( gtbSlotNum , gtbSrcDacAAddr  [ i ] , dacA , 0 )
                GTB_set_address ( gtbSlotNum , gtbSrcDacBAddr  [ i ] , dacB , 0 )
            endif
        endif
    endfor  
    
    if loadDacs then
        GTB_set_address ( gtbSlotNum , GTOBUF_DAC_CTL , dacSelectBits , 16#0 )
    endif
endif
endbody
--------------------------------------------------------------------------------
procedure GTB_DisconnectSampFromDigitizer ( digitizerChan )
--------------------------------------------------------------------------------
--  This procedure is used to disconnect the digitizer selected by digitizerChan from 
--  the sampler to which it was connected.  

in word                         : digitizerChan    -- choices are 1,2,3,4

local word                      : i

body

    i = ( ( digitizerChan - 1 ) mod 2 ) + 1
    GTB_set_address ( gtbSlotNum , gtbSamplerMuxStates [ digitizerChan , AUX_SAMPLER , OFF , GTB_ADDR ] , gtbSamplerMuxStates [ digitizerChan , AUX_SAMPLER , OFF , GTB_DATA ] , gtbSamplerMuxStates [ digitizerChan , AUX_SAMPLER , OFF , GTB_MASK ] )

endbody
--------------------------------------------------------------------------------
procedure GTB_UpdateStatus
--------------------------------------------------------------------------------
local integer               : i

body

    s = ""
    i = 1
    s [ i ] = "SOURCE PATH"
    GTB_UpdateSourcePathStatus ( i , 1 , GTOBUF_A_CH_1_RLY )
    GTB_UpdateSourcePathStatus ( i , 2 , GTOBUF_A_CH_2_RLY )
    GTB_UpdateSourcePathStatus ( i , 3 , GTOBUF_B_CH_3_RLY )
    GTB_UpdateSourcePathStatus ( i , 4 , GTOBUF_B_CH_4_RLY )
    i = i + 1
    s [ i ] = ""
    i = i + 1
    s [ i ] = "SOURCE DATA MUX (Gain Path ONLY!)"
    GTB_UpdateSourceMUXState ( i )
    i = i + 1
    s [ i ] = ""
    i = i + 1
    s [ i ] = "SAMPLER DATA MUX"
    GTB_UpdateSamplerMuxStatus ( i )
    i = i + 1
    s [ i ] = ""
    i = i + 1
    s [ i ] = "SAMPLE CLOCK CONNECTION TO HEAD"
    GTB_UpdateClockConnectionStatus ( i )
    i = i + 1
    s [ i ] = ""
    i = i + 1
    s [ i ] = "SAMPLE CLOCK DIVIDER"
    GTB_UpdateClockDividerStatus ( i )

endbody
--------------------------------------------------------------------------------
procedure GTB_UpdateClockConnectionStatus ( i )
--------------------------------------------------------------------------------
in_out integer              : i

body

    i = i + 1
    s [ i ] = "Sample Clock Output 1 "
    if gtb_shadow [ GTOBUF_A_CLK_CTL ] &  ~GTB_CLOCK_OUTPUT_SELECT_MASK = GTB_CLOCK_OUTPUT_OFF then
        s [ i ] = s [ i ] + "is OFF "
    elseif gtb_shadow [ GTOBUF_A_CLK_CTL ] & ~GTB_CLOCK_OUTPUT_SELECT_MASK = GTB_CLOCK_OUTPUT_DIVIDED then
        s [ i ] = s [ i ] + "is connected to sample clock divider "
    elseif gtb_shadow [ GTOBUF_A_CLK_CTL ] & ~GTB_CLOCK_OUTPUT_SELECT_MASK = GTB_CLOCK_OUTPUT_GENERATOR then
        s [ i ] = s [ i ] + "is connected to generator directly "
    else
        s [ i ] = " ERROR. UNDEFINED STATE!" 
    endif
    
    i = i + 1
    s [ i ] = "Sample Clock Output 2 "
    if gtb_shadow [ GTOBUF_B_CLK_CTL ] & ~GTB_CLOCK_OUTPUT_SELECT_MASK = GTB_CLOCK_OUTPUT_OFF then
        s [ i ] = s [ i ] + "is OFF "
    elseif gtb_shadow [ GTOBUF_B_CLK_CTL ] & ~GTB_CLOCK_OUTPUT_SELECT_MASK = GTB_CLOCK_OUTPUT_DIVIDED then
        s [ i ] = s [ i ] + "is connected to sample clock divider "
    elseif gtb_shadow [ GTOBUF_B_CLK_CTL ] & ~GTB_CLOCK_OUTPUT_SELECT_MASK = GTB_CLOCK_OUTPUT_GENERATOR then
        s [ i ] = s [ i ] + "is connected to generator directly "
    else
        s [ i ] = " ERROR. UNDEFINED STATE!" 
    endif

endbody
--------------------------------------------------------------------------------
procedure GTB_UpdateClockDividerStatus ( i )
--------------------------------------------------------------------------------
in_out integer              : i

body

    i = i + 1
    s [ i ] = "Sample Clock Divider 1 is set to "
    if gtb_shadow [ GTOBUF_A_CLK_CTL ] & ~GTB_CLK_DIVIDER_MASK = 0 then
        s [ i ] = s [ i ] + "OFF "
    elseif gtb_shadow [ GTOBUF_A_CLK_CTL ] & ~GTB_CLK_DIVIDER_MASK < 32 then
        s [ i ] = s [ i ] + sprint ( 2 * ( ( ~gtb_shadow [ GTOBUF_A_CLK_CTL ] & ~GTB_CLK_DIVIDER_MASK ) + 1 ) )
    else
        s [ i ] = " ERROR. Divider must be set to less than 64" 
    endif
    
    i = i + 1
    s [ i ] = "Sample Clock Divider 2 is set to "
    if gtb_shadow [ GTOBUF_B_CLK_CTL ] & ~GTB_CLK_DIVIDER_MASK = 0 then
        s [ i ] = s [ i ] + "OFF "
    elseif gtb_shadow [ GTOBUF_B_CLK_CTL ] & ~GTB_CLK_DIVIDER_MASK < 32 then
        s [ i ] = s [ i ] + sprint ( 2 * ( ( ~gtb_shadow [ GTOBUF_B_CLK_CTL ] & ~GTB_CLK_DIVIDER_MASK ) + 1 ) )
    else
        s [ i ] = " ERROR. Divider must be set to less than 64" 
    endif

endbody
--------------------------------------------------------------------------------
procedure GTB_UpdateSourcePathStatus ( i , chanNum , chanAddr )
--------------------------------------------------------------------------------
in_out integer              : i
in integer                  : chanNum
in integer                  : chanAddr

local integer               : j
local integer               : k

body

    i = i + 1
    
    s [ i ] = "Source " + sprint ( chanNum:1 ) + " buffer path: "
    for j = 1 to GTB_SRC_PATH_COUNT do
        for k = 1 to GTB_SRC_PATH_ENDS do
            if gtb_shadow [ chanAddr ] = gtbSrcConnectAry [ j , k ] then
                s [ i ] = s [ i ] + gtbPathStatusAry [ j ] + gtbPathEndedAry [ k ]
                j = GTB_SRC_PATH_COUNT
                k = GTB_SRC_PATH_ENDS
            elseif gtb_shadow [ chanAddr ] = 0 then 
                s [ i ] = s [ i ] + "Disconnected"
                j = GTB_SRC_PATH_COUNT
                k = GTB_SRC_PATH_ENDS
            endif
        endfor
    endfor
    
endbody
--------------------------------------------------------------------------------
procedure GTB_UpdateSamplerMuxStatus ( i )
--------------------------------------------------------------------------------
in_out integer                  : i


body

    i = i + 1 
    if gtb_shadow [ GTOBUF_A_SAMP_MUX_CTL ] & ~GTB_MUX_ODD_DIGITIZER_ENABLE_MASK = 0 then
            s [ i ] = "VxGTO samplers disconnected from DIGHS channel 1"
    else
        if gtb_shadow [ GTOBUF_A_SAMP_MUX_CTL ] & ~GTB_MUX_ODD_DIGITIZER_MASK = GTB_MUX_ODD_GTO_SAMPLER_TO_ODD_DIGITIZER  then
            s [ i ] = "VxGTO channel 1 GTO_RX sampler connected to DIGHS channel 1"
        elseif gtb_shadow [ GTOBUF_A_SAMP_MUX_CTL ] & ~GTB_MUX_ODD_DIGITIZER_MASK = GTB_MUX_EVEN_GTO_SAMPLER_TO_ODD_DIGITIZER then
            s [ i ] = "VxGTO channel 2 GTO_RX sampler connected to DIGHS channel 1"
        elseif gtb_shadow [ GTOBUF_A_SAMP_MUX_CTL ] & ~GTB_MUX_ODD_DIGITIZER_MASK = GTB_MUX_ODD_AUX_SAMPLER_TO_ODD_DIGITIZER then
            s [ i ] = "VxGTO channel 1 AUX    sampler connected to DIGHS channel 1"
        elseif gtb_shadow [ GTOBUF_A_SAMP_MUX_CTL ] & ~GTB_MUX_ODD_DIGITIZER_MASK = GTB_MUX_EVEN_AUX_SAMPLER_TO_ODD_DIGITIZER then
            s [ i ] = "VxGTO channel 2 AUX    sampler connected to DIGHS channel 1"
        endif
    endif

    i = i + 1 
    if gtb_shadow [ GTOBUF_A_SAMP_MUX_CTL ] & ~GTB_MUX_EVEN_DIGITIZER_ENABLE_MASK = 0 then
            s [ i ] = "VxGTO samplers disconnected from DIGHS channel 2"
    else
        if gtb_shadow [ GTOBUF_A_SAMP_MUX_CTL ] & ~GTB_MUX_EVEN_DIGITIZER_MASK = GTB_MUX_ODD_GTO_SAMPLER_TO_EVEN_DIGITIZER then
            s [ i ] = "VxGTO channel 1 GTO_RX sampler connected to DIGHS channel 2"
        elseif gtb_shadow [ GTOBUF_A_SAMP_MUX_CTL ] & ~GTB_MUX_EVEN_DIGITIZER_MASK = GTB_MUX_EVEN_GTO_SAMPLER_TO_EVEN_DIGITIZER then
            s [ i ] = "VxGTO channel 2 GTO_RX sampler connected to DIGHS channel 2"
        elseif gtb_shadow [ GTOBUF_A_SAMP_MUX_CTL ] & ~GTB_MUX_EVEN_DIGITIZER_MASK = GTB_MUX_ODD_AUX_SAMPLER_TO_EVEN_DIGITIZER then
            s [ i ] = "VxGTO channel 1 AUX    sampler connected to DIGHS channel 2"
        elseif gtb_shadow [ GTOBUF_A_SAMP_MUX_CTL ] & ~GTB_MUX_EVEN_DIGITIZER_MASK = GTB_MUX_EVEN_AUX_SAMPLER_TO_EVEN_DIGITIZER then
            s [ i ] = "VxGTO channel 2 AUX    sampler connected to DIGHS channel 2"
        endif
    endif
    
    i = i + 1 
    if gtb_shadow [ GTOBUF_B_SAMP_MUX_CTL ] & ~GTB_MUX_ODD_DIGITIZER_ENABLE_MASK = 0 then
            s [ i ] = "VxGTO samplers disconnected from DIGHS channel 3"
    else
        if gtb_shadow [ GTOBUF_B_SAMP_MUX_CTL ] & ~GTB_MUX_ODD_DIGITIZER_MASK = GTB_MUX_ODD_GTO_SAMPLER_TO_ODD_DIGITIZER then
            s [ i ] = "VxGTO channel 3 GTO_RX sampler connected to DIGHS channel 3"
        elseif gtb_shadow [ GTOBUF_B_SAMP_MUX_CTL ] & ~GTB_MUX_ODD_DIGITIZER_MASK = GTB_MUX_EVEN_GTO_SAMPLER_TO_ODD_DIGITIZER then
            s [ i ] = "VxGTO channel 4 GTO_RX sampler connected to DIGHS channel 3"
        elseif gtb_shadow [ GTOBUF_B_SAMP_MUX_CTL ] & ~GTB_MUX_ODD_DIGITIZER_MASK = GTB_MUX_ODD_AUX_SAMPLER_TO_ODD_DIGITIZER then
            s [ i ] = "VxGTO channel 3 AUX    sampler connected to DIGHS channel 3"
        elseif gtb_shadow [ GTOBUF_B_SAMP_MUX_CTL ] & ~GTB_MUX_ODD_DIGITIZER_MASK = GTB_MUX_EVEN_AUX_SAMPLER_TO_ODD_DIGITIZER then
            s [ i ] = "VxGTO channel 4 AUX    sampler connected to DIGHS channel 3"
        endif
    endif

    i = i + 1 
    if gtb_shadow [ GTOBUF_B_SAMP_MUX_CTL ] & ~GTB_MUX_EVEN_DIGITIZER_ENABLE_MASK = 0 then
            s [ i ] = "VxGTO samplers disconnected from DIGHS channel 4"
    else
        if gtb_shadow [ GTOBUF_B_SAMP_MUX_CTL ] & ~GTB_MUX_EVEN_DIGITIZER_MASK = GTB_MUX_ODD_GTO_SAMPLER_TO_EVEN_DIGITIZER then
            s [ i ] = "VxGTO channel 3 GTO_RX sampler connected to DIGHS channel 4"
        elseif gtb_shadow [ GTOBUF_B_SAMP_MUX_CTL ] & ~GTB_MUX_EVEN_DIGITIZER_MASK = GTB_MUX_EVEN_GTO_SAMPLER_TO_EVEN_DIGITIZER then
            s [ i ] = "VxGTO channel 4 GTO_RX sampler connected to DIGHS channel 4"
        elseif gtb_shadow [ GTOBUF_B_SAMP_MUX_CTL ] & ~GTB_MUX_EVEN_DIGITIZER_MASK = GTB_MUX_ODD_AUX_SAMPLER_TO_EVEN_DIGITIZER then
            s [ i ] = "VxGTO channel 3 AUX    sampler connected to DIGHS channel 4"
        elseif gtb_shadow [ GTOBUF_B_SAMP_MUX_CTL ] & ~GTB_MUX_EVEN_DIGITIZER_MASK = GTB_MUX_EVEN_AUX_SAMPLER_TO_EVEN_DIGITIZER then
            s [ i ] = "VxGTO channel 4 AUX    sampler connected to DIGHS channel 4"
        endif
    endif
    
endbody
--------------------------------------------------------------------------------
procedure GTB_ConnectSamplerToDigitizer ( gtbSamplerChan , auxOrGtoSamp , digitizerChan )
--------------------------------------------------------------------------------
--  This procedure is used to connect a sampler to a digitizer channel.  There are
--  four digitizer channels.  In the standard configuration they are DIGHS 1 through 4.
--  The first parameter selects a gto buffer channel.  the second parameter selects
--  either the aux sampler or the sampler connected to the channels GTO RX input on
--  the channel selected in the first parameter.  Use the constant names AUX_SAMPLER or 
--  GTO_SAMPLER as the two possible choices.  The third parameter is the DIGHS channel
--  to which the sampler is connected.  The choices are 1 through four.  IT IS VERY
--  IMPORTANT TO NOTE that samplers channels and digitizer channels are in groups of two.
--  This means that samplers on gto buffer channels 1 and 2 can only be connected to 
--  DIGHS channels 1 or 2, and that samplers on gto buffer channels 3 and 4 can only 
--  be connected to DIGHS channels 3 or 4.

in word                         : gtbSamplerChan   -- GTO Buffer channel choices are 1,2,3,4
in word                         : auxOrGtoSamp     -- choices are AUX_SAMPLER or GTO_SAMPLER
in word                         : digitizerChan    -- Digitizer Channel choices are 1,2,3,4

local word                      : i
local integer                   : j
local integer                   : k

body

    i = ( ( gtbSamplerChan - 1 ) mod 2 ) + 1
    GTB_set_address ( gtbSlotNum , gtbSamplerMuxStates [ digitizerChan , auxOrGtoSamp , i  , GTB_ADDR ] , gtbSamplerMuxStates [ digitizerChan , auxOrGtoSamp , i , GTB_DATA ] , gtbSamplerMuxStates [ digitizerChan , auxOrGtoSamp , i , GTB_MASK ] )
    
endbody
--------------------------------------------------------------------------------
procedure GTB_UpdateSourceMUXState ( i )
--------------------------------------------------------------------------------
in_out integer                  : i

body

    i = i + 1
    if gtb_shadow [ GTOBUF_A_SRC_SW ] & ~GTB_MUX_ODD_OUTPUT_MASK = GTB_MUX_ODD_GTO_SRC_TO_ODD_OUTPUT then
        s [ i ] = "GTO Buffer source 1 output connected to VxGTO source 1"
    elseif gtb_shadow [ GTOBUF_A_SRC_SW ] & ~GTB_MUX_ODD_OUTPUT_MASK = GTB_MUX_EVEN_GTO_SRC_TO_ODD_OUTPUT then
        s [ i ] = "GTO Buffer source 1 output connected to VxGTO source 2"
    elseif gtb_shadow [ GTOBUF_A_SRC_SW ] & ~GTB_MUX_ODD_OUTPUT_MASK = GTB_MUX_DISABLE_ODD_OUTPUT then
        s [ i ] = "GTO Buffer source 1 output gated off"
    endif

    i = i + 1
    if gtb_shadow [ GTOBUF_A_SRC_SW ] & ~GTB_MUX_EVEN_OUTPUT_MASK = GTB_MUX_ODD_GTO_SRC_TO_EVEN_OUTPUT then
        s [ i ] = "GTO Buffer source 2 output connected to VxGTO source 1"
    elseif gtb_shadow [ GTOBUF_A_SRC_SW ] & ~GTB_MUX_EVEN_OUTPUT_MASK = GTB_MUX_EVEN_GTO_SRC_TO_EVEN_OUTPUT then
        s [ i ] = "GTO Buffer source 2 output connected to VxGTO source 2"
    elseif gtb_shadow [ GTOBUF_A_SRC_SW ] & ~GTB_MUX_EVEN_OUTPUT_MASK = GTB_MUX_DISABLE_EVEN_OUTPUT then
        s [ i ] = "GTO Buffer source 2 output gated off"
    endif

    i = i + 1
    if gtb_shadow [ GTOBUF_B_SRC_SW ] & ~GTB_MUX_ODD_OUTPUT_MASK = GTB_MUX_ODD_GTO_SRC_TO_ODD_OUTPUT then
        s [ i ] = "GTO Buffer source 3 output connected to VxGTO source 3"
    elseif gtb_shadow [ GTOBUF_B_SRC_SW ] & ~GTB_MUX_ODD_OUTPUT_MASK = GTB_MUX_EVEN_GTO_SRC_TO_ODD_OUTPUT then
        s [ i ] = "GTO Buffer source 3 output connected to VxGTO source 4"
    elseif gtb_shadow [ GTOBUF_B_SRC_SW ] & ~GTB_MUX_ODD_OUTPUT_MASK = GTB_MUX_DISABLE_ODD_OUTPUT then
        s [ i ] = "GTO Buffer source 3 output gated off"
    endif

    i = i + 1
    if gtb_shadow [ GTOBUF_B_SRC_SW ] & ~GTB_MUX_EVEN_OUTPUT_MASK = GTB_MUX_ODD_GTO_SRC_TO_EVEN_OUTPUT then
        s [ i ] = "GTO Buffer source 4 output connected to VxGTO source 3"
    elseif gtb_shadow [ GTOBUF_B_SRC_SW ] & ~GTB_MUX_EVEN_OUTPUT_MASK = GTB_MUX_EVEN_GTO_SRC_TO_EVEN_OUTPUT then
        s [ i ] = "GTO Buffer source 4 output connected to VxGTO source 4"
    elseif gtb_shadow [ GTOBUF_B_SRC_SW ] & ~GTB_MUX_EVEN_OUTPUT_MASK = GTB_MUX_DISABLE_EVEN_OUTPUT then
        s [ i ] = "GTO Buffer source 4 output gated off"
    endif

endbody
--------------------------------------------------------------------------------
procedure GTB_ReadCalFile
--------------------------------------------------------------------------------
local string [ 256 ]        : calfactorPathName
local string [ 256 ]        : fileEntry
local integer               : file1
local integer               : i , j
local integer               : month
local integer               : day
local integer               : year
local integer               : chan
local integer               : factorSz

body

    calfactorPathName = GTB_GetVGACalfilePathname
    if exist ( calfactorPathName ) then
        open ( file1 , calfactorPathName , "r" )
        input ( file1 , fileEntry!L ) -- get date
        sinput ( fileEntry , month , day , year )
        println (stdout, "GTO Buffer was calibrated on: " , month , day , year )
        
        for i = 1 to 100 do
            input ( file1 , fileEntry!L ) -- get cal table ID
            if fileEntry = GTB_CAL_DACA_ID then
                input ( file1 , fileEntry!L )  -- get channel
                sinput ( fileEntry , chan )
                input ( file1 , fileEntry!L )  -- get number of calfactors in the table
                sinput ( fileEntry , factorSz )
                gtbDacACalSz [ chan ] = factorSz
                gtbDacACalBits [ chan ] = 0
                gtbDacACalLevels [ chan ] = 0.0
                for j = 1 to factorSz do
                    input ( file1 , fileEntry!L )  -- read the pairs of bits and levels
                    sinput ( fileEntry , gtbDacACalBits [ chan , j ] , gtbDacACalLevels [ chan , j ])
                endfor
--                println ( stdout , "Calfactors loaded for : VGA DAC A on Channel " + sprint ( chan ) )
            elseif fileEntry = GTB_CAL_DACB_ID then
                input ( file1 , fileEntry!L )  -- get channel
                sinput ( fileEntry , chan )
                input ( file1 , fileEntry!L )  -- get number of calfactors in the table
                sinput ( fileEntry , factorSz )
                gtbDacBCalSz [ chan ] = factorSz
                gtbDacBCalBits [ chan ] = 0
                gtbDacBCalLevels [ chan ] = 0.0
                for j = 1 to factorSz do
                    input ( file1 , fileEntry!L )
                    sinput ( fileEntry , gtbDacBCalBits [ chan , j ] , gtbDacBCalLevels [ chan , j ])
                endfor
--                println ( stdout , "Calfactors loaded for : VGA DAC B on Channel " + sprint ( chan ) )
            else 
                break
            endif
        endfor
        close ( file1 )
    else 
        println (stdout , "Using nominal calfiles. " + calfactorPathName  , " not found." )
    endif
    
endbody
--------------------------------------------------------------------------------
function GTB_GetVGACalfilePathname : string [ 256 ]
--------------------------------------------------------------------------------

local string [ 256 ]            : s8 [ 8 ]

body

    GTB_GetReferenceCalfactorNames ( s8 )
    return ( "/ltx/testers/" + tester_name + "/calfiles/gtoFE/va_" + s8 [ 3 ] + "_" + s8 [ 4 ] + "_" + s8 [ 6 ] )
    
endbody    
--------------------------------------------------------------------------------
procedure GTB_AmpsToLowOutput ( gtbSrcList )
--------------------------------------------------------------------------------
in word list [ 4 ]          : gtbSrcList

local integer               : i
local integer               : length
local word                  : dacSelectBits
local boolean               : loadDacs = false

body

    length = len ( gtbSrcList )
    dacSelectBits = 0
    for i = 1 to length do
        if gtb_shadow [ gtbSrcDacAAddr [ i ] ] <> GTB_DAC_A_SHUTDOWN_LEVEL or gtb_shadow  [ gtbSrcDacBAddr [ i ] ] <> GTB_DAC_B_SHUTDOWN_LEVEL then
            GTB_set_address ( gtbSlotNum , gtbSrcDacAAddr [ i ] , GTB_DAC_A_SHUTDOWN_LEVEL , 0 )
            GTB_set_address ( gtbSlotNum , gtbSrcDacBAddr [ i ] , GTB_DAC_B_SHUTDOWN_LEVEL , 0 )
            dacSelectBits = dacSelectBits | 3 * ( 2 ^ ( 2 * ( gtbSrcList [ i ] - 1 ) ) )
            loadDacs = true
        endif
    endfor

    if loadDacs then
        GTB_set_address ( gtbSlotNum , GTOBUF_DAC_CTL , dacSelectBits , 16#0 )
    endif
    
endbody
--------------------------------------------------------------------------------
procedure GTB_initNominalCalfactors
--------------------------------------------------------------------------------
local integer       : i , j 

body

    gtbDacBCalSz = 97
    gtbDacACalSz = 110

    gtbDacACalBits = 0  
    gtbDacBCalBits = 0
    gtbDacACalLevels = 0.0  
    gtbDacBCalLevels = 0.0
    

    for i = 1 to 110 do
        for j = 1 to 4 do

            gtbDacACalBits [ j , 1 ] =       0
            gtbDacACalBits [ j , 2 ] =     256
            gtbDacACalBits [ j , 3 ] =     512
            gtbDacACalBits [ j , 4 ] =     768
            gtbDacACalBits [ j , 5 ] =    1024
            gtbDacACalBits [ j , 6 ] =    1280
            gtbDacACalBits [ j , 7 ] =    1536
            gtbDacACalBits [ j , 8 ] =    1792
            gtbDacACalBits [ j , 9 ] =    2048
            gtbDacACalBits [ j , 10 ] =   2304
            gtbDacACalBits [ j , 11 ] =   2560
            gtbDacACalBits [ j , 12 ] =   2816
            gtbDacACalBits [ j , 13 ] =   3072
            gtbDacACalBits [ j , 14 ] =   3328
            gtbDacACalBits [ j , 15 ] =   3584
            gtbDacACalBits [ j , 16 ] =   3840
            gtbDacACalBits [ j , 17 ] =   4096
            gtbDacACalBits [ j , 18 ] =   4352
            gtbDacACalBits [ j , 19 ] =   4608
            gtbDacACalBits [ j , 20 ] =   4864
            gtbDacACalBits [ j , 21 ] =   5120
            gtbDacACalBits [ j , 22 ] =   5376
            gtbDacACalBits [ j , 23 ] =   5632
            gtbDacACalBits [ j , 24 ] =   5888
            gtbDacACalBits [ j , 25 ] =   6144
            gtbDacACalBits [ j , 26 ] =   6400
            gtbDacACalBits [ j , 27 ] =   6656
            gtbDacACalBits [ j , 28 ] =   6912
            gtbDacACalBits [ j , 29 ] =   7168
            gtbDacACalBits [ j , 30 ] =   7424
            gtbDacACalBits [ j , 31 ] =   7680
            gtbDacACalBits [ j , 32 ] =   7936
            gtbDacACalBits [ j , 33 ] =   8192
            gtbDacACalBits [ j , 34 ] =   8448
            gtbDacACalBits [ j , 35 ] =   8704
            gtbDacACalBits [ j , 36 ] =   8960
            gtbDacACalBits [ j , 37 ] =   9216
            gtbDacACalBits [ j , 38 ] =   9472
            gtbDacACalBits [ j , 39 ] =   9728
            gtbDacACalBits [ j , 40 ] =   9984
            gtbDacACalBits [ j , 41 ] =  10240
            gtbDacACalBits [ j , 42 ] =  10496
            gtbDacACalBits [ j , 43 ] =  10752
            gtbDacACalBits [ j , 44 ] =  11008
            gtbDacACalBits [ j , 45 ] =  11264
            gtbDacACalBits [ j , 46 ] =  11520
            gtbDacACalBits [ j , 47 ] =  11776
            gtbDacACalBits [ j , 48 ] =  12032
            gtbDacACalBits [ j , 49 ] =  12288
            gtbDacACalBits [ j , 50 ] =  12544
            gtbDacACalBits [ j , 51 ] =  12800
            gtbDacACalBits [ j , 52 ] =  13056
            gtbDacACalBits [ j , 53 ] =  13312
            gtbDacACalBits [ j , 54 ] =  13568
            gtbDacACalBits [ j , 55 ] =  13824
            gtbDacACalBits [ j , 56 ] =  14080
            gtbDacACalBits [ j , 57 ] =  14336
            gtbDacACalBits [ j , 58 ] =  14592
            gtbDacACalBits [ j , 59 ] =  14848
            gtbDacACalBits [ j , 60 ] =  15104
            gtbDacACalBits [ j , 61 ] =  15360
            gtbDacACalBits [ j , 62 ] =  15616
            gtbDacACalBits [ j , 63 ] =  15872
            gtbDacACalBits [ j , 64 ] =  16128
            gtbDacACalBits [ j , 65 ] =  16384
            gtbDacACalBits [ j , 66 ] =  16640
            gtbDacACalBits [ j , 67 ] =  16896
            gtbDacACalBits [ j , 68 ] =  17152
            gtbDacACalBits [ j , 69 ] =  17408
            gtbDacACalBits [ j , 70 ] =  17664
            gtbDacACalBits [ j , 71 ] =  17920
            gtbDacACalBits [ j , 72 ] =  18176
            gtbDacACalBits [ j , 73 ] =  18432
            gtbDacACalBits [ j , 74 ] =  18688
            gtbDacACalBits [ j , 75 ] =  18944
            gtbDacACalBits [ j , 76 ] =  19200
            gtbDacACalBits [ j , 77 ] =  19456
            gtbDacACalBits [ j , 78 ] =  19712
            gtbDacACalBits [ j , 79 ] =  19968
            gtbDacACalBits [ j , 80 ] =  20224
            gtbDacACalBits [ j , 81 ] =  20480
            gtbDacACalBits [ j , 82 ] =  20736
            gtbDacACalBits [ j , 83 ] =  20992
            gtbDacACalBits [ j , 84 ] =  21248
            gtbDacACalBits [ j , 85 ] =  21504
            gtbDacACalBits [ j , 86 ] =  21760
            gtbDacACalBits [ j , 87 ] =  22016
            gtbDacACalBits [ j , 88 ] =  22272
            gtbDacACalBits [ j , 89 ] =  22528
            gtbDacACalBits [ j , 90 ] =  22784
            gtbDacACalBits [ j , 91 ] =  23040
            gtbDacACalBits [ j , 92 ] =  23296
            gtbDacACalBits [ j , 93 ] =  23552
            gtbDacACalBits [ j , 94 ] =  23808
            gtbDacACalBits [ j , 95 ] =  24064
            gtbDacACalBits [ j , 96 ] =  24320
            gtbDacACalBits [ j , 97 ] =  24576
            gtbDacACalBits [ j , 98 ] =  24832
            gtbDacACalBits [ j , 99 ] =  25088
            gtbDacACalBits [ j , 100 ] = 25344
            gtbDacACalBits [ j , 101 ] = 25600
            gtbDacACalBits [ j , 102 ] = 25856
            gtbDacACalBits [ j , 103 ] = 26112
            gtbDacACalBits [ j , 104 ] = 26368
            gtbDacACalBits [ j , 105 ] = 26624
            gtbDacACalBits [ j , 106 ] = 26880
            gtbDacACalBits [ j , 107 ] = 27136
            gtbDacACalBits [ j , 108 ] = 27392
            gtbDacACalBits [ j , 109 ] = 27648
            gtbDacACalBits [ j , 110 ] = 27904
        
            gtbDacACalLevels [ j , 1 ] =   2.762639
            gtbDacACalLevels [ j , 2 ] =   2.762016
            gtbDacACalLevels [ j , 3 ] =   2.761827
            gtbDacACalLevels [ j , 4 ] =   2.766504
            gtbDacACalLevels [ j , 5 ] =   2.770911
            gtbDacACalLevels [ j , 6 ] =   2.775576
            gtbDacACalLevels [ j , 7 ] =   2.782271
            gtbDacACalLevels [ j , 8 ] =   2.788439
            gtbDacACalLevels [ j , 9 ] =   2.794126
            gtbDacACalLevels [ j , 10 ] =   2.800720
            gtbDacACalLevels [ j , 11 ] =  2.808323
            gtbDacACalLevels [ j , 12 ] =  2.813370
            gtbDacACalLevels [ j , 13 ] =  2.823022
            gtbDacACalLevels [ j , 14 ] =  2.828776
            gtbDacACalLevels [ j , 15 ] =  2.839202
            gtbDacACalLevels [ j , 16 ] =  2.847224
            gtbDacACalLevels [ j , 17 ] =  2.856841
            gtbDacACalLevels [ j , 18 ] =  2.865736
            gtbDacACalLevels [ j , 19 ] =  2.873836
            gtbDacACalLevels [ j , 20 ] =  2.883401
            gtbDacACalLevels [ j , 21 ] =  2.893674
            gtbDacACalLevels [ j , 22 ] =  2.903410
            gtbDacACalLevels [ j , 23 ] =  2.914644
            gtbDacACalLevels [ j , 24 ] =  2.925447
            gtbDacACalLevels [ j , 25 ] =  2.935441
            gtbDacACalLevels [ j , 26 ] =  2.946820
            gtbDacACalLevels [ j , 27 ] =  2.956540
            gtbDacACalLevels [ j , 28 ] =  2.968949
            gtbDacACalLevels [ j , 29 ] =  2.981866
            gtbDacACalLevels [ j , 30 ] =  2.992454
            gtbDacACalLevels [ j , 31 ] =  3.005300
            gtbDacACalLevels [ j , 32 ] =  3.017456
            gtbDacACalLevels [ j , 33 ] =  3.029460
            gtbDacACalLevels [ j , 34 ] =  3.043269
            gtbDacACalLevels [ j , 35 ] =  3.054971
            gtbDacACalLevels [ j , 36 ] =  3.068375
            gtbDacACalLevels [ j , 37 ] =  3.082032
            gtbDacACalLevels [ j , 38 ] =  3.093483
            gtbDacACalLevels [ j , 39 ] =  3.108281
            gtbDacACalLevels [ j , 40 ] =  3.121134
            gtbDacACalLevels [ j , 41 ] =  3.135916
            gtbDacACalLevels [ j , 42 ] =  3.148467
            gtbDacACalLevels [ j , 43 ] =  3.161891
            gtbDacACalLevels [ j , 44 ] =  3.175603
            gtbDacACalLevels [ j , 45 ] =  3.189427
            gtbDacACalLevels [ j , 46 ] =  3.205465
            gtbDacACalLevels [ j , 47 ] =  3.215725
            gtbDacACalLevels [ j , 48 ] =  3.232156
            gtbDacACalLevels [ j , 49 ] =  3.245039
            gtbDacACalLevels [ j , 50 ] =  3.260328
            gtbDacACalLevels [ j , 51 ] =  3.273970
            gtbDacACalLevels [ j , 52 ] =  3.288807
            gtbDacACalLevels [ j , 53 ] =  3.301872
            gtbDacACalLevels [ j , 54 ] =  3.314547
            gtbDacACalLevels [ j , 55 ] =  3.330974
            gtbDacACalLevels [ j , 56 ] =  3.343974
            gtbDacACalLevels [ j , 57 ] =  3.359644
            gtbDacACalLevels [ j , 58 ] =  3.373291
            gtbDacACalLevels [ j , 59 ] =  3.388636
            gtbDacACalLevels [ j , 60 ] =  3.401985
            gtbDacACalLevels [ j , 61 ] =  3.416262
            gtbDacACalLevels [ j , 62 ] =  3.429475
            gtbDacACalLevels [ j , 63 ] =  3.443780
            gtbDacACalLevels [ j , 64 ] =  3.457978
            gtbDacACalLevels [ j , 65 ] =  3.472282
            gtbDacACalLevels [ j , 66 ] =  3.485431
            gtbDacACalLevels [ j , 67 ] =  3.497483
            gtbDacACalLevels [ j , 68 ] =  3.512049
            gtbDacACalLevels [ j , 69 ] =  3.525267
            gtbDacACalLevels [ j , 70 ] =  3.539223
            gtbDacACalLevels [ j , 71 ] =  3.553738
            gtbDacACalLevels [ j , 72 ] =  3.567438
            gtbDacACalLevels [ j , 73 ] =  3.580293
            gtbDacACalLevels [ j , 74 ] =  3.591445
            gtbDacACalLevels [ j , 75 ] =  3.605718
            gtbDacACalLevels [ j , 76 ] =  3.618639
            gtbDacACalLevels [ j , 77 ] =  3.632807
            gtbDacACalLevels [ j , 78 ] =  3.644689
            gtbDacACalLevels [ j , 79 ] =  3.658760
            gtbDacACalLevels [ j , 80 ] =  3.671423
            gtbDacACalLevels [ j , 81 ] =  3.684372
            gtbDacACalLevels [ j , 82 ] =  3.697118
            gtbDacACalLevels [ j , 83 ] =  3.709660
            gtbDacACalLevels [ j , 84 ] =  3.721085
            gtbDacACalLevels [ j , 85 ] =  3.734003
            gtbDacACalLevels [ j , 86 ] =  3.747555
            gtbDacACalLevels [ j , 87 ] =  3.758298
            gtbDacACalLevels [ j , 88 ] =  3.770905
            gtbDacACalLevels [ j , 89 ] =  3.783419
            gtbDacACalLevels [ j , 90 ] =  3.793591
            gtbDacACalLevels [ j , 91 ] =  3.806377
            gtbDacACalLevels [ j , 92 ] =  3.816919
            gtbDacACalLevels [ j , 93 ] =  3.828132
            gtbDacACalLevels [ j , 94 ] =  3.841207
            gtbDacACalLevels [ j , 95 ] =  3.853017
            gtbDacACalLevels [ j , 96 ] =  3.862935
            gtbDacACalLevels [ j , 97 ] =  3.873843
            gtbDacACalLevels [ j , 98 ] =  3.885732
            gtbDacACalLevels [ j , 99 ] =  3.895701
            gtbDacACalLevels [ j , 100 ] = 3.907009
            gtbDacACalLevels [ j , 101 ] = 3.917671
            gtbDacACalLevels [ j , 102 ] = 3.928641
            gtbDacACalLevels [ j , 103 ] = 3.938149
            gtbDacACalLevels [ j , 104 ] = 3.948660
            gtbDacACalLevels [ j , 105 ] = 3.960017
            gtbDacACalLevels [ j , 106 ] = 3.969329
            gtbDacACalLevels [ j , 107 ] = 3.977738
            gtbDacACalLevels [ j , 108 ] = 3.988406
            gtbDacACalLevels [ j , 109 ] = 3.996673
            gtbDacACalLevels [ j , 110 ] = 4.007257
            
            gtbDacBCalBits [ j , 1 ] =       0 
            gtbDacBCalBits [ j , 2 ] =     500 
            gtbDacBCalBits [ j , 3 ] =    1029 
            gtbDacBCalBits [ j , 4 ] =    1588 
            gtbDacBCalBits [ j , 5 ] =    2174 
            gtbDacBCalBits [ j , 6 ] =    2781 
            gtbDacBCalBits [ j , 7 ] =    3409 
            gtbDacBCalBits [ j , 8 ] =    4057 
            gtbDacBCalBits [ j , 9 ] =    4724 
            gtbDacBCalBits [ j , 10 ] =   5408 
            gtbDacBCalBits [ j , 11 ] =   6109 
            gtbDacBCalBits [ j , 12 ] =   6826 
            gtbDacBCalBits [ j , 13 ] =   7557 
            gtbDacBCalBits [ j , 14 ] =   8302 
            gtbDacBCalBits [ j , 15 ] =   9060 
            gtbDacBCalBits [ j , 16 ] =   9830 
            gtbDacBCalBits [ j , 17 ] =  10610 
            gtbDacBCalBits [ j , 18 ] =  11401 
            gtbDacBCalBits [ j , 19 ] =  12202 
            gtbDacBCalBits [ j , 20 ] =  13011 
            gtbDacBCalBits [ j , 21 ] =  13828 
            gtbDacBCalBits [ j , 22 ] =  14652 
            gtbDacBCalBits [ j , 23 ] =  15483 
            gtbDacBCalBits [ j , 24 ] =  16320 
            gtbDacBCalBits [ j , 25 ] =  17162 
            gtbDacBCalBits [ j , 26 ] =  18008 
            gtbDacBCalBits [ j , 27 ] =  18858 
            gtbDacBCalBits [ j , 28 ] =  19710 
            gtbDacBCalBits [ j , 29 ] =  20565 
            gtbDacBCalBits [ j , 30 ] =  21421 
            gtbDacBCalBits [ j , 31 ] =  22277 
            gtbDacBCalBits [ j , 32 ] =  23133 
            gtbDacBCalBits [ j , 33 ] =  23988 
            gtbDacBCalBits [ j , 34 ] =  24842 
            gtbDacBCalBits [ j , 35 ] =  25693 
            gtbDacBCalBits [ j , 36 ] =  26541 
            gtbDacBCalBits [ j , 37 ] =  27385 
            gtbDacBCalBits [ j , 38 ] =  28224 
            gtbDacBCalBits [ j , 39 ] =  29056 
            gtbDacBCalBits [ j , 40 ] =  29879 
            gtbDacBCalBits [ j , 41 ] =  30693 
            gtbDacBCalBits [ j , 42 ] =  31498 
            gtbDacBCalBits [ j , 43 ] =  32292 
            gtbDacBCalBits [ j , 44 ] =  33074 
            gtbDacBCalBits [ j , 45 ] =  33843 
            gtbDacBCalBits [ j , 46 ] =  34597 
            gtbDacBCalBits [ j , 47 ] =  35336 
            gtbDacBCalBits [ j , 48 ] =  36061 
            gtbDacBCalBits [ j , 49 ] =  36771 
            gtbDacBCalBits [ j , 50 ] =  37467 
            gtbDacBCalBits [ j , 51 ] =  38147 
            gtbDacBCalBits [ j , 52 ] =  38811 
            gtbDacBCalBits [ j , 53 ] =  39458 
            gtbDacBCalBits [ j , 54 ] =  40089 
            gtbDacBCalBits [ j , 55 ] =  40704 
            gtbDacBCalBits [ j , 56 ] =  41304 
            gtbDacBCalBits [ j , 57 ] =  41886 
            gtbDacBCalBits [ j , 58 ] =  42452 
            gtbDacBCalBits [ j , 59 ] =  43001 
            gtbDacBCalBits [ j , 60 ] =  43533 
            gtbDacBCalBits [ j , 61 ] =  44048 
            gtbDacBCalBits [ j , 62 ] =  44547 
            gtbDacBCalBits [ j , 63 ] =  45028 
            gtbDacBCalBits [ j , 64 ] =  45492 
            gtbDacBCalBits [ j , 65 ] =  45939 
            gtbDacBCalBits [ j , 66 ] =  46369 
            gtbDacBCalBits [ j , 67 ] =  46784 
            gtbDacBCalBits [ j , 68 ] =  47182 
            gtbDacBCalBits [ j , 69 ] =  47564 
            gtbDacBCalBits [ j , 70 ] =  47933 
            gtbDacBCalBits [ j , 71 ] =  48287 
            gtbDacBCalBits [ j , 72 ] =  48626 
            gtbDacBCalBits [ j , 73 ] =  48953 
            gtbDacBCalBits [ j , 74 ] =  49266 
            gtbDacBCalBits [ j , 75 ] =  49567 
            gtbDacBCalBits [ j , 76 ] =  49858 
            gtbDacBCalBits [ j , 77 ] =  50141 
            gtbDacBCalBits [ j , 78 ] =  50414 
            gtbDacBCalBits [ j , 79 ] =  50679 
            gtbDacBCalBits [ j , 80 ] =  50934 
            gtbDacBCalBits [ j , 81 ] =  51181 
            gtbDacBCalBits [ j , 82 ] =  51420 
            gtbDacBCalBits [ j , 83 ] =  51653 
            gtbDacBCalBits [ j , 84 ] =  51880 
            gtbDacBCalBits [ j , 85 ] =  52099 
            gtbDacBCalBits [ j , 86 ] =  52315 
            gtbDacBCalBits [ j , 87 ] =  52524 
            gtbDacBCalBits [ j , 88 ] =  52730 
            gtbDacBCalBits [ j , 89 ] =  52930 
            gtbDacBCalBits [ j , 90 ] =  53125 
            gtbDacBCalBits [ j , 91 ] =  53316 
            gtbDacBCalBits [ j , 92 ] =  53504 
            gtbDacBCalBits [ j , 93 ] =  53689 
            gtbDacBCalBits [ j , 94 ] =  53870 
            gtbDacBCalBits [ j , 95 ] =  54049 
            gtbDacBCalBits [ j , 96 ] =  54227 
            gtbDacBCalBits [ j , 97 ] =  54400
            gtbDacBCalLevels [ j , 1 ] =   2.762260
            gtbDacBCalLevels [ j , 2 ] =   2.763337
            gtbDacBCalLevels [ j , 3 ] =   2.757321
            gtbDacBCalLevels [ j , 4 ] =   2.735141
            gtbDacBCalLevels [ j , 5 ] =   2.712963
            gtbDacBCalLevels [ j , 6 ] =   2.686462
            gtbDacBCalLevels [ j , 7 ] =   2.658130
            gtbDacBCalLevels [ j , 8 ] =   2.625363
            gtbDacBCalLevels [ j , 9 ] =   2.591995
            gtbDacBCalLevels [ j , 10 ] =  2.557200
            gtbDacBCalLevels [ j , 11 ] =  2.518120
            gtbDacBCalLevels [ j , 12 ] =  2.479460
            gtbDacBCalLevels [ j , 13 ] =  2.437330
            gtbDacBCalLevels [ j , 14 ] =  2.395290
            gtbDacBCalLevels [ j , 15 ] =  2.349639
            gtbDacBCalLevels [ j , 16 ] =  2.305635
            gtbDacBCalLevels [ j , 17 ] =  2.260530
            gtbDacBCalLevels [ j , 18 ] =  2.212552
            gtbDacBCalLevels [ j , 19 ] =  2.165669
            gtbDacBCalLevels [ j , 20 ] =  2.117094
            gtbDacBCalLevels [ j , 21 ] =  2.068478
            gtbDacBCalLevels [ j , 22 ] =  2.020462
            gtbDacBCalLevels [ j , 23 ] =  1.970376
            gtbDacBCalLevels [ j , 24 ] =  1.921087
            gtbDacBCalLevels [ j , 25 ] =  1.872465
            gtbDacBCalLevels [ j , 26 ] =  1.821388
            gtbDacBCalLevels [ j , 27 ] =  1.772782
            gtbDacBCalLevels [ j , 28 ] =  1.722602
            gtbDacBCalLevels [ j , 29 ] =  1.671571
            gtbDacBCalLevels [ j , 30 ] =  1.622905
            gtbDacBCalLevels [ j , 31 ] =  1.571585
            gtbDacBCalLevels [ j , 32 ] =  1.522607
            gtbDacBCalLevels [ j , 33 ] =  1.471690
            gtbDacBCalLevels [ j , 34 ] =  1.422547
            gtbDacBCalLevels [ j , 35 ] =  1.372895
            gtbDacBCalLevels [ j , 36 ] =  1.323508
            gtbDacBCalLevels [ j , 37 ] =  1.274148
            gtbDacBCalLevels [ j , 38 ] =  1.223249
            gtbDacBCalLevels [ j , 39 ] =  1.175220
            gtbDacBCalLevels [ j , 40 ] =  1.128465
            gtbDacBCalLevels [ j , 41 ] =  1.081889
            gtbDacBCalLevels [ j , 42 ] =  1.035946
            gtbDacBCalLevels [ j , 43 ] =  0.990592
            gtbDacBCalLevels [ j , 44 ] =  0.945829
            gtbDacBCalLevels [ j , 45 ] =  0.902498
            gtbDacBCalLevels [ j , 46 ] =  0.862335
            gtbDacBCalLevels [ j , 47 ] =  0.822776
            gtbDacBCalLevels [ j , 48 ] =  0.785806
            gtbDacBCalLevels [ j , 49 ] =  0.749189
            gtbDacBCalLevels [ j , 50 ] =  0.714610
            gtbDacBCalLevels [ j , 51 ] =  0.680924
            gtbDacBCalLevels [ j , 52 ] =  0.649399
            gtbDacBCalLevels [ j , 53 ] =  0.618896
            gtbDacBCalLevels [ j , 54 ] =  0.590496
            gtbDacBCalLevels [ j , 55 ] =  0.562134
            gtbDacBCalLevels [ j , 56 ] =  0.536115
            gtbDacBCalLevels [ j , 57 ] =  0.510872
            gtbDacBCalLevels [ j , 58 ] =  0.486677
            gtbDacBCalLevels [ j , 59 ] =  0.463626
            gtbDacBCalLevels [ j , 60 ] =  0.442060
            gtbDacBCalLevels [ j , 61 ] =  0.420487
            gtbDacBCalLevels [ j , 62 ] =  0.400620
            gtbDacBCalLevels [ j , 63 ] =  0.381782
            gtbDacBCalLevels [ j , 64 ] =  0.363552
            gtbDacBCalLevels [ j , 65 ] =  0.346998
            gtbDacBCalLevels [ j , 66 ] =  0.330661
            gtbDacBCalLevels [ j , 67 ] =  0.315385
            gtbDacBCalLevels [ j , 68 ] =  0.301513
            gtbDacBCalLevels [ j , 69 ] =  0.287822
            gtbDacBCalLevels [ j , 70 ] =  0.274814
            gtbDacBCalLevels [ j , 71 ] =  0.263190
            gtbDacBCalLevels [ j , 72 ] =  0.251388
            gtbDacBCalLevels [ j , 73 ] =  0.240594
            gtbDacBCalLevels [ j , 74 ] =  0.230750
            gtbDacBCalLevels [ j , 75 ] =  0.221856
            gtbDacBCalLevels [ j , 76 ] =  0.212768
            gtbDacBCalLevels [ j , 77 ] =  0.204668
            gtbDacBCalLevels [ j , 78 ] =  0.196379
            gtbDacBCalLevels [ j , 79 ] =  0.188857
            gtbDacBCalLevels [ j , 80 ] =  0.181636
            gtbDacBCalLevels [ j , 81 ] =  0.175077
            gtbDacBCalLevels [ j , 82 ] =  0.168660
            gtbDacBCalLevels [ j , 83 ] =  0.162105
            gtbDacBCalLevels [ j , 84 ] =  0.156693
            gtbDacBCalLevels [ j , 85 ] =  0.150864
            gtbDacBCalLevels [ j , 86 ] =  0.145846
            gtbDacBCalLevels [ j , 87 ] =  0.140564
            gtbDacBCalLevels [ j , 88 ] =  0.135590
            gtbDacBCalLevels [ j , 89 ] =  0.130915
            gtbDacBCalLevels [ j , 90 ] =  0.126594
            gtbDacBCalLevels [ j , 91 ] =  0.122413
            gtbDacBCalLevels [ j , 92 ] =  0.118217
            gtbDacBCalLevels [ j , 93 ] =  0.114326
            gtbDacBCalLevels [ j , 94 ] =  0.110685
            gtbDacBCalLevels [ j , 95 ] =  0.106747
            gtbDacBCalLevels [ j , 96 ] =  0.103164
            gtbDacBCalLevels [ j , 97 ] =  0.099691    
        endfor
    endfor 


    
endbody
--------------------------------------------------------------------------------
procedure GTB_Enable_Status_Display ( displaySwitch )
--------------------------------------------------------------------------------
--  This procdure switchs the GTO Buffer's status display on and off.  
--  Use the constants DISPLAY_ON to enable the display and DISPLAY_OFF to 
--  disable the display.  The display is enabled by default.  Disabling the 
--  display will reduce test times.

in boolean                  : displaySwitch

body

    gtbStatusEnabled = displaySwitch

endbody
--------------------------------------------------------------------------------
procedure GTB_InitSamplerCalPathVariables
--------------------------------------------------------------------------------

local integer                   : file1
local integer                   : m , d , y , i , j
local integer                   : r 
local string [ 64 ]             : fstr
local string [ 256 ]            : s8 [ 8 ]
local lword                     : exitStatus
local string [ 256 ]            : s9 [ 9 ]
local string [ 256 ]            : str 

body

    scopeCalPathName = "/ltx/testers/" + tester_name + "/calfiles/gtoFE/"
    if exist ( scopeCalPathName + ".ser" ) then
        open ( file1 , scopeCalPathName + ".ser" , "r" )
        input ( file1 , loadBoardSerNum!L )
        close ( file1 )
        
        -- create unique dir filename
        date ( m , d , y )
        exitStatus = 0
        for i = 1 to 4 do
            r = integer ( rnd ( ) * 1000000000.0 )
            fstr = "/tmp/xl_" + sprint ( m:1 ) + sprint ( d:1 ) + sprint ( y:1 ) + sprint ( r:1 ) 
            if exist ( fstr ) then
                exitStatus = wait_for_nic_shell_command ( "rm " + fstr )
            endif
            if exitStatus = 0 then
                break
            endif
        endfor
        if i < 5 then
            exitStatus = wait_for_nic_shell_command ( "ls -l " + "/ltx/testers/" + tester_name + "/calfiles | grep gtoFE > " + fstr )
            if exist ( fstr ) then 
            open ( file1 , fstr , "r" )
                input ( file1 , str!L )
                GTB_strSplit ( " " , str , s9 )
                if s9 [ 1 ] <> "drwxrwxrwx" then
                    exitStatus = wait_for_nic_shell_command ( "chmod 777 " + "/ltx/testers/" + tester_name + "/calfiles/" + s9 [ 9 ] )
                    if exitStatus <> 0 then
                        println ( stdout , "@nERROR! GTO Front End calfile directory: " + s9 [ 9 ] )
                        println ( stdout , "does not have correct permissions.  Please " )
                        println ( stdout , "change them to 777 using the following command:@n" )
                        println ( stdout , "chmod 777 " + s9 [ 9 ] )
                        println ( stdout , "@nYou must be the directory's owner ( " + s9 [ 3 ] + " ) or root to perform this function." )
                        println ( stdout , "from: gtoFrontEndCtrl.mod/GTB_InitSamplerCalPathVariables@n" )
                    endif
                endif
            close ( file1 )
            endif
            if exist ( "/ltx/testers/" + tester_name + "/calfiles/gtoFE/tmp" ) then
                exitStatus = wait_for_nic_shell_command ( "ls -l " + "/ltx/testers/" + tester_name + " /calfiles/gtoFE | grep tmp > " + fstr )
                if exist ( fstr ) then 
                open ( file1 , fstr , "r" )
                    input ( file1 , str!L )
                    GTB_strSplit ( " " , str , s9 )
                    if s9 [ 1 ] <> "-rw-rw-rw-" then
                        exitStatus = wait_for_nic_shell_command ( "chmod 666 " + s9 [ 9 ] )
                        if exitStatus <> 0 then
                            println ( stdout , "ERROR! GTO Front End calfile: " + s9 [ 9 ] )
                            println ( stdout , "does not have correct permissions.  Please " )
                            println ( stdout , "change them to 666 using the following command:@n" )
                            println ( stdout , "chmod 666 " + s9 [ 9 ] )
                            println ( stdout , "@nyou must be the directory's owner: " + s9 [ 3 ] + " or root to perform this function." )
                            println ( stdout , "from: gtoFrontEndCtrl.mod/GTB_InitSamplerCalPathVariables@n@n" )
                        endif
                    endif
                close ( file1 )
                endif
            endif
            GTB_GetReferenceCalfactorNames ( s8 )
            j = integer ( s8 [ 3 ] )
            if j > 0 and j < 100000000 then
                println ( stdout , "Valid GTO Front End cal loadboard serial number found." )
            else
                println ( stdout , "No Valid GTO Front End cal loadboard serial number found." )
                println ( stdout , "Please run vx_gto_fe_cal." )
                println ( stdout , "from: gtoFrontEndCtrl.mod/GTB_InitSamplerCalPathVariables." )
            endif
            exitStatus = wait_for_nic_shell_command ( "ls -l " + "/ltx/testers/" + tester_name + "/calfiles/gtoFE/*" + s8 [ 3 ] + "_" + s8 [ 4 ] + "* >" + fstr )
            if exitStatus <> 0 then
                println ( stdout , "Error in creating temporary file! You should NEVER see this error message 002." )
                halt
            endif
            open ( file1 , fstr , "r" )
            for i = 1 to 18 do
                input ( file1 , str!L )
                GTB_strSplit ( " " , str , s9 )
                if s9 [ 1 ] <> "-rw-rw-rw-" then
                    exitStatus = wait_for_nic_shell_command ( "chmod 666 " + s9 [ 9 ] )
                    if exitStatus <> 0 then
                        println ( stdout , "ERROR! GTO Front End calfile: " + s9 [ 9 ] )
                        println ( stdout , "does not have correct permissions.  Please " )
                        println ( stdout , "change them to 666 using the following command:@n" )
                        println ( stdout , "chmod 666 " + s9 [ 9 ] )
                        println ( stdout , "@nyou must be the file's owner ( " + s9 [ 3 ] + " ) or root to perform this function." )
                        println ( stdout , "from: gtoFrontEndCtrl.mod/GTB_InitSamplerCalPathVariables@n@n" )
                    endif
                endif
            endfor
            close ( file1 )
            for i = 1 to 8 do
                str = "/ltx/testers/" + tester_name + "/calfiles/gtoFE/sa_" + sprint ( i:1 ) + "_"  + s8 [ 3 ] + "_" + s8 [ 4 ] + "_" + s8 [ 5 ] + "_" + s8 [ 6 ] 
                if not exist ( str ) then
                    println ( stdout , "ERROR: This calibration file does not exist:" )
                    println ( stdout , str )
                    println ( stdout , "from: gtoFrontEndCtrl.mod/GTB_InitSamplerCalPathVariables@n@n" )
                endif
            endfor
            for i = 1 to 8 do
                str = "/ltx/testers/" + tester_name + "/calfiles/gtoFE/sc_" + sprint ( i:1 ) + "_"  + s8 [ 3 ] + "_" + s8 [ 4 ] + "_" + s8 [ 5 ] + "_" + s8 [ 6 ] 
                if not exist ( str ) then
                    println ( stdout , "ERROR: This calibration file does not exist:" )
                    println ( stdout , str )
                    println ( stdout , "from: gtoFrontEndCtrl.mod/GTB_InitSamplerCalPathVariables@n@n" )
                endif
            endfor
            str = "/ltx/testers/" + tester_name + "/calfiles/gtoFE/sd_" + s8 [ 3 ] + "_" + s8 [ 4 ] + "_" + s8 [ 5 ] + "_" + s8 [ 6 ] 
            if not exist ( str ) and not afe then
                println ( stdout , "ERROR: This calibration file does not exist:" )
                println ( stdout , str )
                println ( stdout , "from: gtoFrontEndCtrl.mod/GTB_InitSamplerCalPathVariables@n@n" )
            endif
            str = "/ltx/testers/" + tester_name + "/calfiles/gtoFE/va_" + s8 [ 3 ] + "_" + s8 [ 4 ] + "_" + s8 [ 6 ] 
            if not exist ( str ) then
                println ( stdout , "ERROR: This calibration file does not exist:" )
                println ( stdout , str )
                println ( stdout , "from: gtoFrontEndCtrl.mod/GTB_InitSamplerCalPathVariables@n@n" )
            endif
            exitStatus = wait_for_nic_shell_command ( "rm " + fstr )
        else
            println ( stdout , "Error in creating temporary file! You should NEVER see this error message 001." )
            halt
        endif
        wait ( 0.1 )
    else
        println ( stdout , "This tester has no calbration files." )
        println ( stdout , "From: gtoFrontEndCtrl.mod/GTB_GetSamplerCalPathname" )
    endif
    
endbody    
--------------------------------------------------------------------------------
procedure GTB_ReadSamplerCalfactorFiles
------------------------------------------------------------------------------------------

local integer           : file1
local integer           : file2
local integer           : i , j
local string [ 256 ]    : str
local string [ 256 ]    : s8 [ 8 ]

body
    
    GTB_GetReferenceCalfactorNames ( s8 )

--     if exist ( scopeCalPathName + ".ser" ) then
--         open ( file1 , scopeCalPathName + ".ser" , "r" )
--         input ( file1 , str!L )
--         close ( file1 )
--     else
--         println ( stdout , "calfactor filename not known.  Please Run the Calibration program" )
--         println ( stdout , "    From: Abstruse error generator @ GTB_ReadSamplerCalfactorFiles." )
--         halt
--     endif
--     
--     if exist ( scopeCalPathName + "." + str ) then
--         open ( file1 , scopeCalPathName + "." + str , "r" )
--         input ( file1 , str!L )
--         close ( file1 )
--    endif
    
    str = s8 [ 3 ] + "_" + s8 [ 4 ] + "_" + s8 [ 5 ] + "_" + s8 [ 6 ]

    for i = 1 to 8 do
        if exist ( scopeCalPathName + "/sc_" + sprint ( i : 1 ) + "_" + str ) then
            open ( file1 , scopeCalPathName + "/sc_" + sprint ( i : 1 ) + "_"  + str , "r" )
            for j = 1 to SCOPE_CAPTURE_SIZE do
                input ( file1 , scopeImpulse   [ i , j ] )
            endfor
        else    
        endif
        close ( file1 )
    endfor
    
    for i = 1 to 8 do
        if exist ( scopeCalPathName + "/sa_" + sprint ( i : 1 ) + "_" + str ) then
            open ( file2 , scopeCalPathName + "/sa_" + sprint ( i : 1 ) + "_"  + str , "r" )
            for j = 1 to SCOPE_CAPTURE_SIZE do
                 input ( file2 , samplerImpulse [ i , j ] )
            endfor
        else
        endif
        close ( file2 )
    endfor
    
    if pos ( "_40000_I" , str ) <> 0  then
        for i = 1 to 4 do
--            scopeImpulse [ i , 1000 : ] = 0.0
--            samplerImpulse [ i , 1000 : ] = 0.0
        endfor
        for i = 5 to 8 do
                scopeImpulse [ i , 3200 : ] = 0.0
--            samplerImpulse [ i , 1000 : 1100 ] = 0.0
              samplerImpulse [ i , 3200 : ] = 0.0
        endfor    
    endif

    for i = 1 to 8 do
        gtb_thDroopTimeConstants [ i , 1 ] = 475.0e-9
        gtb_thDroopTimeConstants [ i , 2 ] = 2.25e-6
    endfor
    
    if exist ( scopeCalPathName + "/sd_" + str ) and not afe then
        open ( file1 , scopeCalPathName + "/sd_" + str , "r" )
        for i = 1 to 8 do
            input ( file1 , j )
            if ( 1 + ( ( j - 1 ) mod 4 ) ) in gtbSrcSet then
                input ( file1 , gtb_thDroopTimeConstants [ j , 1 ] )
                input ( file1 , gtb_thDroopTimeConstants [ j , 2 ] )
            else
                input ( file1 , file2 )
                input ( file1 , file2 )
            endif
        endfor
        close ( file1 )
    endif
        
endbody
------------------------------------------------------------------------------------------
procedure GTB_ScaleCalfactors ( channel , bitsPerWaveform , bitRate , k )
--------------------------------------------------------------------------------

in word                 : channel
in word                 : bitsPerWaveform
in double               : bitRate
in integer              : k

const PI                = rad ( 180.0 )
const ARY_SZ            = 2 ^ 20

local word              : divisor
local integer           : length   
local integer           : startAddr
local integer           : endAddr  
local double            : ffreq
local double            : decimationRatio
local double            : approxDec
local integer           : i , j , l , m , m2  , n , p
local double            : sr1
local double            : s1
local double            : ff1
local double            : b1
local double            : sr2
local double            : s2
local double            : ff2
local double            : w , x , y , z
local double            : ary1 [ ARY_SZ ]
local double            : ary2 [ ARY_SZ ]
local double            : ary3 [ ARY_SZ ]
local double            : xc [ 2 ]
local double            : yc [ 2 ]
local float             : droopFactor


body

    ffreq = bitRate / double ( bitsPerWaveform )
    decimationRatio = ffreq / ( CAL_WAVE_RATE  * 2.0 )
    n = integer ( decimationRatio )
    m = integer ( 1.0 / decimationRatio )
    m2 = integer ( 1.0 / sqr ( decimationRatio ) )

    if n = 0 then
        ff2 = ffreq / double ( n + 1 )
        sr1 = CALFILE_SAMPLE_RATE
        sr2 = bitRate * double ( bitsPerWaveform )
        z = 1000000000.0
        for i = SCOPE_CAPTURE_SIZE  to 4 * SCOPE_CAPTURE_SIZE do
            s1 = double ( i )
            ff1 = sr1 / s1
            x = 1.0e9
            for j = i * m to 2 * i * m do
                approxDec = 1.0 / double ( m ) * double ( i ) / double ( j )
                y = abs ( approxDec / decimationRatio - 1.0 )
                if y > x then
                    w = x
                    break
                endif
                x = y
            endfor
            if z > w then
                p = i
                l = j - 1
                z = w
            endif
            if z < 1.0e-10 then 
                break
            endif
        endfor
    elseif m = 0 or ( n=1 and m=1 ) then
        ff2 = ffreq / double ( n + 1 )
        sr1 = CALFILE_SAMPLE_RATE
        sr2 = bitRate * double ( bitsPerWaveform )
        z = 10.0
        for i = SCOPE_CAPTURE_SIZE to ( 4 + m ) * SCOPE_CAPTURE_SIZE do
            s1 = double ( i )
            ff1 = sr1 / s1
            x = 1.0e9
            for j = i to  ( 2 + m2 ) * i do
                approxDec = double ( n + 1 ) * double ( i ) / double ( j )
                y = abs ( approxDec / decimationRatio - 1.0 )
                if y > x then
                    w = x
                    break
                endif
                x = y
            endfor
            if z > w then
                p = i
                l = j - 1
                z = w
            endif
            if z = 0.0 then 
                break
            endif
        endfor
    else
        p = SCOPE_CAPTURE_SIZE
        l = SCOPE_CAPTURE_SIZE  
    endif 
    
    ary1 = 0.0
    ary1 [ 1 : SCOPE_CAPTURE_SIZE ] = fft ( scopeImpulse [ channel ] )
    
    ary1 [ 1 : p ] = inverse_fft ( ary1 [ 1 : p ] )
    z = avg ( ary1 [ p / 4 : p ] )
    if p + 1 <= l then
        ary1 [ p + 1 : l ] = 0.0 -- z
    endif 
    ary1 [ 1 : l ] =  fft ( ary1 [ 1 : l ] )
    ary1 [ 1 : 2 ] =  0.0
    
    ary2 = 0.0
   
    ary2 [ 1 : SCOPE_CAPTURE_SIZE ] = fft ( samplerImpulse [ channel ] )
    
    
--    ary2 [ 257:258 ] = ( ary2 [ 255:256 ] + ary2 [ 259:260 ] ) / 2.0
    ary2 [ 1 : p ] = inverse_fft ( ary2 [ 1 : p ] )
    z = avg ( ary2 [ p / 4 : p ] )
    if p + 1  <= l then
        ary2 [ p + 1 : l ] = 0.0 -- z 
    endif
    ary2 [ 1 : l ] =  fft ( ary2 [ 1 : l ] )
    
    vp_cdiv ( ary1 , 1 , ary2 , 1 , ary3 , 1 , ( l - 1 ) / 2 )
    
    samplerCalFactorStart [ k ] = lastCalAryIndex + 1
    startAddr = samplerCalFactorStart [ k ]
    for i = 0 to l - 1 by 2  do
        z = double ( i ) * ffreq / 2.0
        xc = ary3 [ i * ( n + 1 ) + 1 : i * ( n + 1 ) + 2 ]
        yc = cartesian_to_polar ( xc )
        if i = 2 then 
            if ffreq > 2.875GHz then
                yc [ 2 ] =  yc [ 2 ] + 3.0
            else
                yc [ 2 ] =  yc [ 2 ] + 4.0 * ffreq / 2.5GHz
            endif
        endif

        yc [ 2 ] = yc [ 2 ] - ( 5.0 * z / 35.0GHz ) ^ 2.0
        yc [ 1 ] = yc [ 1 ] * ( 1.0 + ( z / 18.0GHz ) ^ 2.0 )
        if z > gtb_bw and gtb_sb >= gtb_bw then
            yc [ 1 ] = yc [ 1 ] * 0.5 * ( 1.0 + cos  (  ( PI * ( z - gtb_bw ) ) / ( gtb_sb - gtb_bw - 0.000000001 ) ) )
        endif
        xc = polar_to_cartesian ( yc )
        samplerCalFactors [ startAddr + i : startAddr + i + 1 ] = float ( xc ) --* ( 1.0 + float ( i ) * float ( ffreq ) / 20.0 GHz )
        
        if z > gtb_sb then
            break
        endif
    endfor
    
    divisor = gtb_sampleClkDivVal [ ( 2 + ( channel ) mod 4 ) >> 1 ] 
    droopFactor = float ( exp  ( 1.0 / ( gtb_thDroopTimeConstants [ channel , 1 ] * SampleClkFreq / 2.0  ) ) ) * float ( exp  ( 1.0 / ( gtb_thDroopTimeConstants [ channel , 2 ] *  SampleClkFreq / double ( divisor - 2 ) ) ) ) 

    samplerCalfactorLen   [ k ] = i + 2
    samplerCalfactorStop  [ k ] = i + 1 + startAddr
    lastCalAryIndex = samplerCalfactorStop [ k ]

    samplerCalFactors [ samplerCalFactorStart [ k ] : samplerCalfactorStop  [ k ] ] = samplerCalFactors [ samplerCalFactorStart [ k ] : samplerCalfactorStop  [ k ] ] * droopFactor
    
endbody
--------------------------------------------------------------------------------
function GTB_CAL_hash ( channel , bitsPerWaveform , bitRate ) : integer
--------------------------------------------------------------------------------
in word                 : channel
in word                 : bitsPerWaveform
in double               : bitRate

local integer           : i , j , k
local double            : hashValue

body

    hashValue = sqr ( double ( channel * bitsPerWaveform ) * bitRate )
    i = integer ( hashValue ) mod SAMP_CALFACS + 1
    
    for j = 1 to SAMP_CALFACS do
        k = ( i + j - 2 ) mod SAMP_CALFACS + 1
        if samplerCalfactorChan [ k ] = 0 then
            GTB_ScaleCalfactors ( channel , bitsPerWaveform , bitRate , k )
            samplerCalfactorChan [ k ] = channel
            samplerCalfactorFreq [ k ] = bitRate
            samplerCalfactorBits [ k ] = bitsPerWaveform
            return ( k )
        elseif samplerCalfactorFreq [ k ] = bitRate  and  samplerCalfactorBits [ k ] = bitsPerWaveform  and samplerCalfactorChan [ k ] = channel then
            return ( k )
        else
        endif
    endfor
    
    println ( stdout , "The sampler calfactor array is full" )
    println ( stdout , "Execution is halted" )
    println ( stdout , "From: gtoFrontEndCtrl.mod/GTB_CAL_hash" )
    halt
    
endbody
--------------------------------------------------------------------------------

procedure GTB_initSamplerCalfactorTables
--------------------------------------------------------------------------------

body

    lastCalAryIndex       = 0
    samplerCalFactorStart = 0
    samplerCalfactorStop  = 0
    samplerCalfactorLen   = 0
    samplerCalfactorFreq  = 0.0
    samplerCalfactorChan  = 0
    samplerCalfactorBits  = 0
    samplerCalfactorLoc   = false
    samplerCalFactors     = 0.0
      
endbody
--------------------------------------------------------------------------------

function GTB_GetCalfactors ( sampNum , bitsPerWaveform , bitRate , length , startAddr , endAddr ) : integer
--------------------------------------------------------------------------------
in word                 : sampNum
in integer              : bitsPerWaveform
in double               : bitRate
out integer             : length
out integer             : startAddr
out integer             : endAddr

local integer           : i , j , k 

body

    
    i = GTB_CAL_hash ( sampNum , word ( bitsPerWaveform ) , bitRate )

    length    = samplerCalfactorLen   [ i ]
    startAddr = samplerCalFactorStart [ i ]
    endAddr   = samplerCalfactorStop  [ i ]
    return ( i )
    
endbody
--------------------------------------------------------------------------------
procedure GTB_CorrectWaveform ( channel , sampId , bitsPerWaveform , bitRate , passBand , stopBand , inAry , outAry )
--------------------------------------------------------------------------------
in word                 : channel               -- channel number.
in word                 : sampId                -- AUX_SAMPLER or GTO_SAMPLER.
in integer              : bitsPerWaveform       -- bits collected in waveform capture to be corrected.
in double               : bitRate               -- actual bit rate of waveform going into the sampler.
in double               : passBand              -- desired flat bandwidth of sampler.
in double               : stopBand              -- desired beginning of the stopband. (Raised half cosine  transition between.)
in float                : inAry  [ ? ]          -- input array of sampled data.
in_out float            : outAry [ ? ]          -- corrected output array ( must be the same size or larger than inAry ).

local integer           : startAddr
local integer           : endAddr
local integer           : length
local integer           : i
local float             : vHi
local float             : vLo
local word              : sampNum

body

    if passBand > 0.0 and stopBand > 0.0 and stopBand >= passBand then
        gtb_bw = passBand
        gtb_sb = stopBand
    else
        gtb_bw = GTB_FLAT_SAMPLER_BW  
        gtb_sb = GTB_SAMPLER_STOP_BAND
    endif
        
    sampNum = channel + sampId * 4 - 4
    i = GTB_GetCalfactors ( sampNum , bitsPerWaveform , bitRate , length , startAddr , endAddr )
    
    inAry = fft ( inAry )
    vp_cmul ( inAry , 1 , samplerCalFactors [ startAddr : endAddr ] , 1 , outAry , 1 , length / 2 )
    outAry [ length + 1 : ] = 0.0
    outAry = inverse_fft ( outAry )

endbody
--------------------------------------------------------------------------------
procedure GTB_InitRelayClickCounter
--------------------------------------------------------------------------------
--local string [ 256 ]            : cumFilename
--local string [ 256 ]            : backupCumFilename
local string [ 256 ]            : currentFilename
local integer                   : h , m , s , mn , da , yr


body

    if not clickCounterInitialized then
        cumulativeCountPathName = scopeCalPathName + "/gto_FE_relayCountCumulative.csv"
        backupCumulativeCountPathName = scopeCalPathName + "/gto_FE_relayCountCumulativeBackup.csv"
        currentCounterPathName = scopeCalPathName + "/gto_FE_relayCountCurrent"
        
        GTB_AddCurrentCountsToCum
    
        time ( h  , m  , s  )
        date ( mn , da , yr )
        gtb_counterStartingTime = sprint (  h:1 ) + ":" + sprint (  m:1 ) + ":" + sprint (  s:1 ) 
        gtb_counterStartingDate = sprint ( mn:1 ) + "/" + sprint ( da:1 ) + "/" + sprint ( yr:1 ) 
        gtb_counterTime = m 
        gtb_relayClicks = 0
        gtb_programRuns = 0
        clickCounterInitialized = true
    endif
        
endbody
--------------------------------------------------------------------------------

procedure GTB_AddCurrentCountsToCum
--------------------------------------------------------------------------------
-- local string [ 256 ]            : cumFilename
-- local string [ 256 ]            : backupCumFilename
-- local string [ 256 ]            : currentFilename

local integer                   : file1
local integer                   : file2
local integer                   : i , j , k
local string  [ 256 ]           : inStr
local string  [ 256 ]           : lStr [ 24 ]
local string  [ 256 ]           : outStr
local integer                   : ioError
local integer                   : totals [ GTB_MAX_SRC ]
local string  [ 256 ]           : c [ 16 ]

body

    if not exist ( cumulativeCountPathName ) then
        open ( file1 , cumulativeCountPathName , "w" )
        print ( file1 , "GTO Front End Relay Actuation Record," )
        print ( file1 , "Program,Starting,Starting,Ending,Ending,Run" )
        for i = 1 to GTB_MAX_SRC do
            print ( file1 , "," + "Channel " + sprint ( i:1 ) )
        endfor
        println ( file1 )
        print ( file1 , "For LTX Tester: " + tester_name + ",Name,Date,Time,Date,Time,Count" )
        for i = 1 to GTB_MAX_SRC do
            print ( file1 , "," )
        endfor
        println ( file1 )
        print ( file1 , "Totals,,,,," )
        for i = 1 to GTB_MAX_SRC + 1 do
            print ( file1 , "," )
        endfor
        println ( file1 )
        close ( file1 )
    endif

    if exist ( currentCounterPathName ) then
    
        open ( file1 , currentCounterPathName , "r" )
            input ( file1 , c [ 1 ]!L )
            input ( file1 , c [ 2 ]!L )
            input ( file1 , c [ 3 ]!L )
            input ( file1 , c [ 4 ]!L )
            input ( file1 , c [ 5 ]!L )
            input ( file1 , c [ 6 ]!L )
            for i = 1 to GTB_MAX_SRC do
                input ( file1 , c [ 6 + i ]!L )
            endfor
        close ( file1 )
        wait_for_nic_shell_command ( "rm " + currentCounterPathName )
    
        if exist ( cumulativeCountPathName ) then
            if 0 = wait_for_nic_shell_command ( "cp " + cumulativeCountPathName + " " + backupCumulativeCountPathName ) then
                k = 2 
                open ( file1 , backupCumulativeCountPathName , "r" )
                open ( file2 , cumulativeCountPathName , "w" )
                while ioError = 0 do
                    input ( file1 , inStr!L )
                    ioError = integer ( io_errnum )
                    if ioError <> 0 then 
                        break
                    endif
                    j = GTB_strSplit ( "," , inStr , lStr )
                    if lStr [ 1 ] = "Totals" then
                        for i = 1 to 6 + GTB_MAX_SRC do
                            print ( file2 , "," + c [ i ] )
                        endfor
                        println ( file2 )
                        print ( file2 , "Totals,,,,," )
                        print ( file2 ,  ",=sum(G3:G" + sprint ( k:1 ) + "),=sum(H3:H" + sprint ( k:1 ) + "),=sum(I3:I" + sprint ( k:1 ) + "),=sum(J3:J" + sprint ( k:1 ) + "),=sum(K3:K" + sprint ( k:1 ) + ")" )
                        println ( file2 )
                        break
                    elseif lStr [ 1 ] = "" and lStr [ 2 ] = "Name" then
                        println ( file2 , inStr )
                    elseif lStr [ 1 ] = "GTO Front End Relay Actuation Record" or lStr [ 1 ] = "Program" or lStr [ 1 ] = "Name" then
                        println ( file2 , inStr )
                    else
                        println ( file2 , inStr )
                        k = k + 1
                    endif
                endwhile
                close ( file1 )
                close ( file2 )
            endif
        endif
    endif

endbody
--------------------------------------------------------------------------------

procedure GTB_UpdateSourcePathCounts ( chanNum , sourcePath , sourceConnection )
--------------------------------------------------------------------------------
in word                     : chanNum
in integer                  : sourcePath
in integer                  : sourceConnection

local integer               : relayState
local integer               : j
local integer               : k
local string [ 256 ]        : str

body

    relayState = sourcePath * ( GTB_SRC_PATH_ENDS ) + sourceConnection
    if gtb_previousRelayState [ chanNum ] <> relayState  then
        if printRelayActuations then
          str = "Source " + sprint ( chanNum:1 ) + " buffer path: "
          for j = 1 to GTB_SRC_PATH_COUNT do
              for k = 1 to GTB_SRC_PATH_ENDS do
                  if gtb_shadow [ gtbSrcRelayAddr [ chanNum ] ] = gtbSrcConnectAry [ j , k ] then
                      str = str + gtbPathStatusAry [ j ] + gtbPathEndedAry [ k ]
                      j = GTB_SRC_PATH_COUNT
                      k = GTB_SRC_PATH_ENDS
                  elseif gtb_shadow [ gtbSrcRelayAddr [ chanNum ] ] = 0 then 
                      str = str + "Disconnected"
                      j = GTB_SRC_PATH_COUNT
                      k = GTB_SRC_PATH_ENDS
                  endif
              endfor
          endfor
        endif
        gtb_previousRelayState [ chanNum ] = relayState       
        gtb_relayClicks [ chanNum ] = gtb_relayClicks [ chanNum ] + 1
    endif

endbody
--------------------------------------------------------------------------------
procedure GTB_ClickCounter_ON_STOP
--------------------------------------------------------------------------------

local integer               : h , m , s
local integer               : file1

body

    gtb_programRuns = gtb_programRuns + 1
    
    time ( h , m , s )
    if ( m - gtb_counterTime ) mod 60 > 5 then
        gtb_counterTime = m
        GTB_UpdateCurrenClickCounts
    endif
    
endbody
--------------------------------------------------------------------------------
procedure GTB_ClickCounter_ON_HALT
--------------------------------------------------------------------------------


body

    GTB_ClickCounter_ON_STOP

endbody
--------------------------------------------------------------------------------
procedure GTB_UpdateCurrenClickCounts
--------------------------------------------------------------------------------

local integer                   : file1
local integer                   : i
local string  [ 256 ]           : currentTime
local string  [ 256 ]           : currentDate
local integer                   : h , m , s , mn , da , yr

body

    time ( h  , m  , s  )
    date ( mn , da , yr )
    currentTime = sprint (  h:1 ) + ":" + sprint (  m:1 ) + ":" + sprint (  s:1 ) 
    currentDate = sprint ( mn:1 ) + "/" + sprint ( da:1 ) + "/" + sprint ( yr:1 ) 
    
    open ( file1 , currentCounterPathName , "w" )
    println ( file1 , program_name )
    println ( file1 , gtb_counterStartingDate )
    println ( file1 , gtb_counterStartingTime )
    println ( file1 , currentDate )
    println ( file1 , currentTime )
    println ( file1 , gtb_programRuns )
    for i = 1 to GTB_MAX_SRC do
        println ( file1 , gtb_relayClicks [ i ] )
    endfor
    close ( file1 )
    
endbody
--------------------------------------------------------------------------------
procedure GTB_ClickCounter_ON_UNLOAD
--------------------------------------------------------------------------------


body

    GTB_UpdateCurrenClickCounts
    GTB_AddCurrentCountsToCum
    
endbody
--------------------------------------------------------------------------------
function GTB_strSplit ( delimiter , inStr , outStr ) : integer
--------------------------------------------------------------------------------
in string [ 1 ]                     : delimiter
in_out string                       : inStr
in_out string [ 256 ]               : outStr [ ? ]

local integer                       : length
local integer                       : i , j

body

    length = len ( inStr )
    outStr = ""
    j = 1
    for i = 1 to length do
        if inStr [ i ] = delimiter then
            j = j + 1
            while inStr [ i ] = delimiter do
                i = i + 1
                if i > length then
                    break
                endif
            endwhile
            i = i - 1 
        else
            outStr [ j ] = outStr [ j ] + inStr [ i ]
        endif
    endfor 
    return ( j )     
            
endbody
--------------------------------------------------------------------------------
procedure GTB_GetReferenceCalfactorNames ( outStr )
--------------------------------------------------------------------------------
in_out string [ 256 ]       : outStr [ ? ]


local integer               : file1
local string [ 256 ]        : str
local string [ 256 ]        : lastCalLoadboard
local string [ 256 ]        : calFileData
local integer               : i , j , k
local lword                 : returnCode


body

--println ( stdout , "/ltx/testers/" + tester_name + "/calfiles/gtoFE"  )
    -- make sure that calfile directory exists
    if 0 <>  wait_for_nic_shell_command ( "cd /ltx/testers/" + tester_name + "/calfiles" ) then
        println ( stdout , "System directory /ltx/testers/" + tester_name + "/calfiles does not exist." )
        println ( stdout , "Please correct LTX OS installation. HALT!" )
        halt
    endif
    
    --  cd into gto front end calfile directory
    if 0 <>  wait_for_nic_shell_command ( "cd /ltx/testers/" + tester_name + "/calfiles/gtoFE" ) then   --make sure that gto front end calfile directory exists, and cd into it.
        if 0 <>  wait_for_nic_shell_command ( "cd /ltx/testers/" + tester_name + "/calfiles ; mkdir /ltx/testers/" + tester_name + "/calfiles/gtoFE" ) then   --if the gto front end calfile directory doesn't exist, try to make it.
            println ( stdout , "GTO Front End calfile directory /ltx/testers/" + tester_name + "/calfiles/gtoFE could not be created." )
            println ( stdout , "This may be due to improper permissions.  Please correct this problem and try again. HALT!" )
            halt
        endif
    endif
    scopeCalPathName = "/ltx/testers/" + tester_name + "/calfiles/gtoFE"

    if loadBoardSerNumForScopeCal <> "" then
        lastCalLoadboard = loadBoardSerNumForScopeCal
        open ( file1 , scopeCalPathName + "/.ser" , "w" )
            println ( file1 , lastCalLoadboard )
        close ( file1 )
    elseif exist ( scopeCalPathName + "/.ser"  ) then
        open ( file1 , scopeCalPathName + "/.ser" , "r" )
            input ( file1 , lastCalLoadboard!L )
        close ( file1 )
    else
        println ( stdout , "ERROR: calfactors have not been properly loaded on this tester." )
        println ( stdout , "GTO Front End will not function without calibration." )
        println ( stdout , "Execution is halted.  From: gtoFrontEndCtrl.mod/GTB_GetReferenceCalfactorNames " )
        halt
    endif
    
    if exist ( scopeCalPathName + "/tmp" ) then
        wait_for_nic_shell_command ( "cd " + scopeCalPathName + "; rm tmp" )
    endif
    lastCalLoadboard = lastCalLoadboard [ 1 : 8 ]
    if 0 = wait_for_nic_shell_command ( "cd " + scopeCalPathName + "; ls sc_1_" + lastCalLoadboard + "_20* | sort -r  > tmp ; chmod 666 tmp " ) then
        if exist ( scopeCalPathName +"/tmp" ) then
            open ( file1 ,  scopeCalPathName +"/tmp" , "r" )
            input ( file1 , str!L )
            close ( file1 )
        endif
    endif
    wait_for_nic_shell_command ( "cd " + scopeCalPathName + "; rm tmp" )
    
    k = GTB_strSplit ( "_" , str , outStr )

endbody
--------------------------------------------------------------------------------
procedure GTB_ScaleCalfactorsNew ( channel , bitsPerWaveform , bitRate , k )
--------------------------------------------------------------------------------

in word                 : channel
in word                 : bitsPerWaveform
in double               : bitRate
in integer              : k

const PI                = rad ( 180.0 )

local integer           : length   
local integer           : startAddr
local integer           : endAddr  
local double            : ffreq
local double            : decimationRatio
local double            : approxDec
local integer           : i , j , l , m , m2  , n , p
local double            : sr1
local double            : s1
local double            : ff1
local double            : b1
local double            : sr2
local double            : s2
local double            : ff2
local double            : w , x , y , z
local double            : ary1 [ 262144 ]
local double            : ary2 [ 262144 ]
local double            : ary3 [ 262144 ]
local double            : xc [ 2 ]
local double            : yc [ 2 ]


body

    ffreq = bitRate / double ( bitsPerWaveform )
    decimationRatio = ffreq / ( CAL_WAVE_RATE  * 2.0 )
    n = integer ( decimationRatio )
    m = integer ( 1.0 / decimationRatio )
    m2 = integer ( 1.0 / sqr ( decimationRatio ) )

    if n = 0 then
if false then
        ff2 = ffreq / double ( n + 1 )
        sr1 = CALFILE_SAMPLE_RATE
        sr2 = bitRate * double ( bitsPerWaveform )
        z = 1000000000.0
        j = i * m - 1
        for i = SCOPE_CAPTURE_SIZE  to 4 * SCOPE_CAPTURE_SIZE do
            s1 = double ( i )
            ff1 = sr1 / s1
            x = 1.0e9
            approxDec = 1.0 / double ( m ) * double ( i ) / double ( j )
            while approxDec > decimationRatio do
                j = j + 1
                approxDec = 1.0 / double ( m ) * double ( i ) / double ( j )
                y = abs ( approxDec / decimationRatio - 1.0 )
                if y > x then
                    w = x
                    break
                endif
                x = y
            endwhile
            if z > w then
                p = i
                l = j - 1
                z = w
            endif
            if z < 1.0e-10 then 
                break
            endif
        endfor
else
        ff2 = ffreq / double ( n + 1 )
        sr1 = CALFILE_SAMPLE_RATE
        sr2 = bitRate * double ( bitsPerWaveform )
        z = 1000000000.0
        for i = SCOPE_CAPTURE_SIZE  to 4 * SCOPE_CAPTURE_SIZE do
            s1 = double ( i )
            ff1 = sr1 / s1
            x = 1.0e9
            for j = i * m to 2 * i * m do
                approxDec = 1.0 / double ( m ) * double ( i ) / double ( j )
                y = abs ( approxDec / decimationRatio - 1.0 )
                if y > x then
                    w = x
                    break
                endif
                x = y
            endfor
            if z > w then
                p = i
                l = j - 1
                z = w
            endif
            if z < 1.0e-10 then 
                break
            endif
        endfor
endif
    elseif m = 0 then
        ff2 = ffreq / double ( n + 1 )
        sr1 = CALFILE_SAMPLE_RATE
        sr2 = bitRate * double ( bitsPerWaveform )
        z = 10.0
        for i = SCOPE_CAPTURE_SIZE to ( 4 + m ) * SCOPE_CAPTURE_SIZE do
            s1 = double ( i )
            ff1 = sr1 / s1
            x = 1.0e9
            for j = i to  ( 2 + m2 ) * i do
                approxDec = double ( n + 1 ) * double ( i ) / double ( j )
                y = abs ( approxDec / decimationRatio - 1.0 )
                if y > x then
                    w = x
                    break
                endif
                x = y
            endfor
            if z > w then
                p = i
                l = j - 1
                z = w
            endif
            if z = 0.0 then 
                break
            endif
        endfor
    else
        p = SCOPE_CAPTURE_SIZE
        l = SCOPE_CAPTURE_SIZE  
    endif 
    
    ary1 = 0.0
    ary1 [ 1 : SCOPE_CAPTURE_SIZE ] = fft ( scopeImpulse [ channel ] )
    ary1 [ 257:258 ] = ( ary1 [ 255:256 ] + ary1 [ 259:260 ] ) / 2.0
    ary1 [ 1 : p ] = inverse_fft ( ary1 [ 1 : p ] )
    z = avg ( ary1 [ p / 4 : p ] )
    ary1 [ p + 1 : l ] = 0.0 --z 
    ary1 [ 1 : l ] =  fft ( ary1 [ 1 : l ] )
    ary1 [ 1 : 2 ] =  0.0
    
    ary2 = 0.0
    ary2 [ 1 : SCOPE_CAPTURE_SIZE ] = fft ( samplerImpulse [ channel ] )
    ary2 [ 257:258 ] = ( ary2 [ 255:256 ] + ary2 [ 259:260 ] ) / 2.0
    ary2 [ 1 : p ] = inverse_fft ( ary2 [ 1 : p ] )
    z = avg ( ary2 [ p / 4 : p ] )
    ary2 [ p + 1 : l ] = 0.0 --z 
    ary2 [ 1 : l ] =  fft ( ary2 [ 1 : l ] )
    
    vp_cdiv ( ary1 , 1 , ary2 , 1 , ary3 , 1 , ( l - 1 ) / 2 )
    
    samplerCalFactorStart [ k ] = lastCalAryIndex + 1
    startAddr = samplerCalFactorStart [ k ]
    for i = 0 to l - 1 by 2  do
        z = double ( i ) * ffreq / 2.0
        xc = ary3 [ i * ( n + 1 ) + 1 : i * ( n + 1 ) + 2 ]
        yc = cartesian_to_polar ( xc )
        if i = 2 then 
            yc [ 2 ] =  yc [ 2 ] + 3.0
        endif
        yc [ 2 ] = yc [ 2 ] + ( 5.0 * z / 20.0GHz ) ^ 3.0
        yc [ 1 ] = yc [ 1 ] * ( 1.0 + ( double ( i ) * ffreq / 35.0GHz ) ^ 4.0 )
        if ( ffreq * double ( i ) / 2.0 ) > gtb_bw and gtb_sb >= gtb_bw then
            yc [ 1 ] = yc [ 1 ] * 0.5 * ( 1.0 + cos  (  ( PI * ( ( ( ffreq ) * double ( i ) / 2.0 ) - gtb_bw ) ) / ( gtb_sb - gtb_bw - 0.000000001 ) ) )
        endif
        xc = polar_to_cartesian ( yc )
        samplerCalFactors [ startAddr + i : startAddr + i + 1 ] = float ( xc ) --* ( 1.0 + float ( i ) * float ( ffreq ) / 20.0 GHz )
        
        if z > gtb_sb then
            break
        endif
    endfor
    samplerCalfactorLen   [ k ] = i + 2
    samplerCalfactorStop  [ k ] = i + 1 + startAddr
    lastCalAryIndex = samplerCalfactorStop [ k ]

endbody
--------------------------------------------------------------------------------

procedure GTB_initTemporaryCalfactors ( aBits , bBits )
--------------------------------------------------------------------------------
in float            : aBits [ 4 ]
in float            : bBits [ 4 ]

local integer       : i , j 

body

    gtbDacBCalSz = 103
    gtbDacACalSz = 103

    gtbDacACalBits = 0  
    gtbDacBCalBits = 0
    gtbDacACalLevels = 0.0  
    gtbDacBCalLevels = 0.0
    
    for i = 1 to 103 do
        for j = 1 to 4 do
            gtbDacACalBits   [ j ,  i ] = integer ( aBits [ j ] / 100.0 ) * ( i - 1 )
            gtbDacACalLevels [ j ,  i ] = 2.8 + 0.012 * float ( i - 1 )

            gtbDacBCalBits   [ j ,  i ] = integer ( bBits [ j ] / 100.0 ) * ( i - 1 )
            gtbDacBCalLevels [ j ,  i ] = 2.8 - 0.027 * float ( i - 1 )

        endfor
    endfor 
    
endbody
--------------------------------------------------------------------------------
procedure GTB_on_load
--------------------------------------------------------------------------------

body

    GTB_init
    
endbody
--------------------------------------------------------------------------------
procedure GTB_on_stop
--------------------------------------------------------------------------------

body

    GTB_ClickCounter_ON_STOP
    
endbody
--------------------------------------------------------------------------------
procedure GTB_on_unload
--------------------------------------------------------------------------------

body

    GTB_ClickCounter_ON_UNLOAD
    
endbody
--------------------------------------------------------------------------------
procedure GTB_on_halt
--------------------------------------------------------------------------------

body

    GTB_ClickCounter_ON_STOP
    
endbody
--------------------------------------------------------------------------------
procedure GTB_on_abort
--------------------------------------------------------------------------------

body

    GTB_ClickCounter_ON_STOP
    
endbody
--------------------------------------------------------------------------------
procedure AFE_GateVgaOff ( afeSrcList )
--------------------------------------------------------------------------------
in word list [ 4 ]     : afeSrcList

body

    GTB_AmpsToLowOutput ( afeSrcList )
    GTB_SelectSourceMUXPath ( afeSrcList , <: MUX_SRC_OFF , MUX_SRC_OFF :> )

endbody
--------------------------------------------------------------------------------
procedure AFE_SetVgaOutputLevel ( gtbSrcList , gtbSrcLevel )
--------------------------------------------------------------------------------
in word list [ 4 ]          : gtbSrcList
in float                    : gtbSrcLevel


--  This procedure is designed to change the level of all
--  channels in the list gtbSrcList.   Any VGAs in gtbSrcList that have been gated off will be enabled.


body

    GTB_SetSourceLevel ( gtbSrcList , BALANCED , gtbSrcLevel , GTB_FORCE_HIGH_SOURCE_RANGE )
    if not fourVgas then
        GTB_SelectSourceMUXPath ( gtbSrcList , gtbSrcList )
    endif

endbody
--------------------------------------------------------------------------------
procedure AFE_SetVgaOutputLevelOnTrigger ( gtbSrcList , gtbSrcLevel , syncBusLine )
--------------------------------------------------------------------------------
in word list [ 4 ]          : gtbSrcList
in float                    : gtbSrcLevel
in word                     : syncBusLine

--  This procedure is designed to change the level of all
--  channels in the list gtbSrcList.   
--
--  This statement can only be used on channels that are gated on.
--
--  This procedure arms the control hardware in the Analof Front End to set the 
--  level dacs upon receipt of a pulse on the SyncBusline ( 1 through 8 )
--  selected by triggerNumber.
--

body

    GTB_SetSourceLevelOnTrigger ( gtbSrcList , BALANCED , gtbSrcLevel , syncBusLine )
    if not fourVgas then
        GTB_SelectSourceMUXPath ( gtbSrcList , gtbSrcList )
    endif

endbody
--------------------------------------------------------------------------------
procedure AFE_SetSampleClockDivider ( gtbSampler , divisor )
--------------------------------------------------------------------------------
--  This procedure sets the sample clock divider on the GTO Buffer analog board.
--  The same divider is shared across all four samplers on a board.  This means
--  that Aux Sampler 1, GTO Rx sampler 1, Aux Sampler 2, and GTO Rx sampler 2 all
--  share the same clock divider, and changing either channel 1 or 2 will always
--  change both channels.  Similarly,  This means  that Aux Sampler 3, GTO Rx 
--  sampler 3, Aux Sampler 4, and GTO Rx sampler 4 all share the same clock divider,
--  and changing either channel 3 or 4 will always change both channels.  
--
--  Select 1 through 8 for gtbSampler
--
--  The divisor can be set from 4 to 64 in steps of 2.  If an odd number is selected
--  the next lower even number will be selected.  Selections that are out of range
--  will generate an error message.

in word                                 : gtbSampler  --  sampler channel associated with a divider.
in word                                 : divisor     -- range is 4 to 64 in steps of 2.  Odd numbers will be reduced by 1.

body

    gtbSampler = ( ( gtbSampler - 1 ) & 3 ) + 1
    GTB_SetSampleClockDivider ( gtbSampler , divisor )

endbody
--------------------------------------------------------------------------------
procedure AFE_ConnectSamplerToDigitizer ( afeSamplerChan , digitizerChan )
--------------------------------------------------------------------------------
--  This procedure is used to connect a sampler to a digitizer channel.  There are
--  four digitizer channels.  In the standard configuration they are DIGHS 1 through 4.
--  Channels 1 through 4 are the 1V p-p input channels.
--  Channels 5 through 8 are the 2V p-p input channels.
--
--  Channels 1, 2, 5, and 6 are on Analog Front End board 1, and can connect only to digitizer channels 1 or 2
--  Channels 3, 4, 8, and 8 are on Analog Front End board 2, and can connect only to digitizer channels 3 or 4

in word                         : afeSamplerChan   -- Analog Front End channel choices are 1,2,3,4,5,6,7,8
in word                         : digitizerChan    -- Digitizer Channel choices are 1,2,3,4

local word                      : gtbSamplerChan  
local word                      : auxOrGtoSamp     
local word                      : i
local integer                   : j
local integer                   : k

body

    gtbSamplerChan =  ( ( afeSamplerChan - 1 ) & 3 ) + 1
    auxOrGtoSamp = 1 + ( ( afeSamplerChan - 1 ) >> 2 ) 
    i = ( ( gtbSamplerChan - 1 ) mod 2 ) + 1
    GTB_set_address ( gtbSlotNum , gtbSamplerMuxStates [ digitizerChan , auxOrGtoSamp , i  , GTB_ADDR ] , gtbSamplerMuxStates [ digitizerChan , auxOrGtoSamp , i , GTB_DATA ] , gtbSamplerMuxStates [ digitizerChan , auxOrGtoSamp , i , GTB_MASK ] )
    
endbody
--------------------------------------------------------------------------------
procedure AFE_SelectSampleClockOutput ( gtbSampleClockList , outputSelection )
--------------------------------------------------------------------------------
--  This procedure selects the signal that is sent to the sample clock output ports
--  on the test head.  There are two sample clock output ports.  Sample clock 1 output
--  is associated with buffer channels 1, 2, 5, and 6.  Sample clock 2 output is associated
--  with channels 3, 4, 7, and 8.  
--  
--  To select the sample clocks outputs to be set by selecting <:1:>, <:2:>, or <:1,2:>
--  as values for gtbSampleClockList.
--
--  There are three possible conditions to set. 
--  Choose GENERATOR to send the output of the clock generator to the sample clock output.
--  Choose DIVIDED_CLOCK to send the divided clock at the rate seen by the samplers to the sample clock output
--  Choose OFF to inhibit any output from the port.


in word list [ GTB_MAX_SRC ]            : gtbSampleClockList
in word                                 : outputSelection  -- GENERATOR, DIVIDED_CLOCK or OFF

local integer                           : i
local word                              : j
local word list [ 4 ]                   : k

body

    j = 0
    for i = 1 to len ( gtbSampleClockList ) do
        if j & 1 = 0 and ( ( ( gtbSampleClockList [ i ] - 1 ) & 3 ) + 1 ) <= 2  then
            k = k + <: 1 :>
            j = j + 1
        elseif j & 2 = 0 and ( ( gtbSampleClockList [ i ] - 1 ) & 3 ) + 1 <= 4 then
            k = k + <: 3 :>
            j = j + 2
        elseif j = 3 then
            break
        endif
    endfor

    GTB_SelectSampleClockOutput ( k , outputSelection )

endbody
--------------------------------------------------------------------------------
procedure AFE_DisconnectSampFromDigitizer ( digitizerChan )
--------------------------------------------------------------------------------
--  This procedure is used to disconnect the digitizer selected by digitizerChan from 
--  the sampler to which it was connected.  

in word                         : digitizerChan    -- choices are 1,2,3,4


body
    
    GTB_DisconnectSampFromDigitizer ( digitizerChan )

endbody
--------------------------------------------------------------------------------
procedure AFE_CorrectWaveform ( afeSamplerChan , bitsPerWaveform , bitRate , passBand , stopBand , inAry , outAry )
--------------------------------------------------------------------------------
in word                 : afeSamplerChan        -- channel number.
in integer              : bitsPerWaveform       -- bits collected in waveform capture to be corrected.
in double               : bitRate               -- actual bit rate of waveform going into the sampler.
in double               : passBand              -- desired flat bandwidth of sampler.
in double               : stopBand              -- desired beginning of the stopband. (Raised half cosine transition inbetween.)
in float                : inAry  [ ? ]          -- input array of sampled data.
in_out float            : outAry [ ? ]          -- corrected output array ( must be the same size or larger than inAry ).

local integer           : startAddr
local integer           : endAddr
local integer           : length
local integer           : i
local float             : vHi
local float             : vLo
local word              : sampNum
local word              : sampId                -- AUX_SAMPLER or GTO_SAMPLER.
local word              : channel

body

    channel =  ( ( afeSamplerChan - 1 ) & 3 ) + 1
    sampId = 1 + ( ( afeSamplerChan - 1 ) >> 2 ) 
    GTB_CorrectWaveform ( channel , sampId , bitsPerWaveform , bitRate , passBand , stopBand , inAry , outAry )

endbody
--------------------------------------------------------------------------------
procedure AFE_init
--------------------------------------------------------------------------------

body
     
    GTB_init
    FindSmate
    InitAuxiliaryClk
    InitSampleClk
    InitClk3
    InitClk4
    
endbody
--------------------------------------------------------------------------------
procedure GTB_ReadTmpSamplerCalfactorFiles
------------------------------------------------------------------------------------------

local integer           : file1
local integer           : file2
local integer           : i , j
local string [ 256 ]    : str
local string [ 256 ]    : s8 [ 8 ]

body
    
    GTB_GetReferenceCalfactorNames ( s8 )

--     if exist ( scopeCalPathName + ".ser" ) then
--         open ( file1 , scopeCalPathName + ".ser" , "r" )
--         input ( file1 , str!L )
--         close ( file1 )
--     else
--         println ( stdout , "calfactor filename not known.  Please Run the Calibration program" )
--         println ( stdout , "    From: Abstruse error generator @ GTB_ReadSamplerCalfactorFiles." )
--         halt
--     endif
--     
--     if exist ( scopeCalPathName + "." + str ) then
--         open ( file1 , scopeCalPathName + "." + str , "r" )
--         input ( file1 , str!L )
--         close ( file1 )
--    endif
    
    str = s8 [ 3 ] + "_" + s8 [ 4 ] + "_" + s8 [ 5 ] + "_" + s8 [ 6 ] 

    for i = 1 to 8 do
        if exist ( scopeCalPathName + "/sc_" + sprint ( i : 1 ) + "_" + str ) then
            open ( file1 , scopeCalPathName + "/sc_" + sprint ( i : 1 ) + "_"  + str , "r" )
            for j = 1 to SCOPE_CAPTURE_SIZE do
                input ( file1 , scopeImpulse   [ i , j ] )
            endfor
        else    
        endif
        close ( file1 )
    endfor
    
    for i = 1 to 8 do
        if exist ( scopeCalPathName + "/sa_" + sprint ( i : 1 ) + "_" + str + ".tmp" ) then
            open ( file2 , scopeCalPathName + "/sa_" + sprint ( i : 1 ) + "_"  + str + ".tmp" , "r" )
            for j = 1 to SCOPE_CAPTURE_SIZE do
                 input ( file2 , samplerImpulse [ i , j ] )
            endfor
        else
        endif
        close ( file2 )
    endfor
    
    if pos ( "_40000_I" , str ) <> 0  then
        for i = 1 to 4 do
--            scopeImpulse [ i , 1000 : ] = 0.0
--            samplerImpulse [ i , 1000 : ] = 0.0
        endfor
        for i = 5 to 8 do
                scopeImpulse [ i , 3200 : ] = 0.0
--            samplerImpulse [ i , 1000 : 1100 ] = 0.0
              samplerImpulse [ i , 3200 : ] = 0.0
        endfor    
    endif

    for i = 1 to 8 do
        gtb_thDroopTimeConstants [ i , 1 ] = 475.0e-9
        gtb_thDroopTimeConstants [ i , 2 ] = 2.25e-6
    endfor
    
    if exist ( scopeCalPathName + "/sd_" + str ) then
        open ( file1 , scopeCalPathName + "/sd_" + str , "r" )
        for i = 1 to 8 do
            input ( file1 , j )
            if ( 1 + ( ( j - 1 ) mod 4 ) ) in gtbSrcSet then
                input ( file1 , gtb_thDroopTimeConstants [ j , 1 ] )
                input ( file1 , gtb_thDroopTimeConstants [ j , 2 ] )
            else
                input ( file1 , file2 )
                input ( file1 , file2 )
            endif
        endfor
        close ( file1 )
    endif
        
endbody
------------------------------------------------------------------------------------------
procedure GTB_initJitterClockLevel
--------------------------------------------------------------------------------

local integer           : file1

body

    optimumJitterClockLevel = -17.0dBm
    jitBiasCalibrated = false
    if exist ( "/ltx/testers/" + tester_name + SEVEN_GHZ_LEVEL ) then
        open ( file1 , "/ltx/testers/" + tester_name + SEVEN_GHZ_LEVEL , "r" )
            input ( file1 , optimumJitterClockLevel )
        close ( file1 )
        jitBiasCalibrated = true
    else
        if afe then
        else
            println ( stdout , "Warning, Jitter clock has not been calibrated for optimum performance." )
            println ( stdout , "A default value will be used." )
            println ( stdout , "Please load vx_gto_fe_cal.  Set Operator variable vxgto_jitter_clk_test to true and then run." )
            println ( stdout , "From: gtoFrontEndCtrl.mod/GTB_initJitterClockLevel" )
        endif
    endif
    
endbody
--------------------------------------------------------------------------------
procedure GTB_ReadJitClkLevelCalfile
--------------------------------------------------------------------------------

local integer           : file1

body

    if exist ( "/ltx/testers/" + tester_name + SEVEN_GHZ_LEVEL )then
        open ( file1 , "/ltx/testers/" + tester_name + SEVEN_GHZ_LEVEL , "r" )
        input ( file1 , optimumJitterClockLevel )
        close ( file1 )
    elseif afe then
    else
        println ( stdout , "Optimum jitter clock level calfactor not found." )
        println ( stdout , "Uning nominal level of -17.5 dBm." )
        println ( stdout , "From: gtoFrontEndCtrl.mod/GTB_ReadJitClkLevelCalfile." )
    endif
        
endbody
--------------------------------------------------------------------------------
procedure GTB_CheckCalfilePermissions
--------------------------------------------------------------------------------

body


endbody
--------------------------------------------------------------------------------
procedure AFE_SelectVgaMUXPath ( vgaOutputList , vgaInputList )
--------------------------------------------------------------------------------
--  This procedure selects the VGA input to VGA output mapping for the 
--  Between the VGA inputs and the VGA itself is a 2 by 2
--  crosspoint switch that may be used to connect either of two VGA inputs
--  to either of two VGA outputs.  This enables the user to switch
--  patterns on software command.
--
--  This mapping in on a per-gto-brick basis, so that VGA input channel 1 can be sent
--  to either or both VGA outputs 1 and 2.  VGA input 2 can be sent
--  to either or both VGA outputs 1 and 2.  VGA input 3 can be sent
--  to either or both VGA outputs 3 and 4.  VGA input 4 can be sent
--  to either or both VGA outputs 3 and 4.  
--  Other choices may give undesired results.


in word list [ 4 ]              : vgaOutputList   -- selects the Gto Buffer output
in word list [ 5 ]              : vgaInputList    -- selects the Gto Source.


body

    GTB_SelectSourceMUXPath ( vgaOutputList , vgaInputList )
    
endbody
--------------------------------------------------------------------------------
