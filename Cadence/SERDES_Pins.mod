static
  PIN LIST[1]: SER_PWDNB
  PIN LIST[1]: SER_X1_AUXSCL
  PIN LIST[1]: SER_X2_AUXSDA
  PIN LIST[1]: SER_GPIO0_MS_LOCK
  PIN LIST[1]: SER_GPIO1_LFLTB_ERRB
  PIN LIST[1]: SER_GPIO2_GPO_SCLK
  PIN LIST[1]: SER_GPIO3_RCLKOUT
  PIN LIST[1]: SER_GPO4_CFG0
  PIN LIST[1]: SER_GPO5_CFG1
  PIN LIST[1]: SER_GPO6_CFG2
  PIN LIST[1]: SER_GPIO7_WS
  PIN LIST[1]: SER_GPIO8_SCK
  PIN LIST[1]: SER_GPIO9_SD
  PIN LIST[1]: SER_GPIO10_CNTL0_WSOR_SDA2
  PIN LIST[1]: SER_GPIO11_CNTL1_SCKOR_SCL2

  PIN LIST[1]: SER_GPIO12_MS1_SDOR

  PIN LIST[1]: SER_GPIO13_LMN0
  PIN LIST[1]: SER_GPIO14_LMN1
  PIN LIST[1]: SER_GPIO15_LMN2_SS2_RO
  PIN LIST[1]: SER_GPIO16_LMN3_SS1_BNE
  PIN LIST[1]: SER_GPIO17_CNTL2_SDA1_MOSI
  PIN LIST[1]: SER_GPIO18_CNTL3_SCL1_MISO
  PIN LIST[1]: SER_GPIO19_RXSDA
  PIN LIST[1]: SER_GPIO20_TXSCL
  PIN LIST[1]: SER_CKAN
  PIN LIST[1]: SER_CKAP
  PIN LIST[1]: SER_DA0N
  PIN LIST[1]: SER_DA0P


  PIN LIST[1]: SER_DA3N
  PIN LIST[1]: SER_DA3P
  PIN LIST[1]: SER_DA2N
  PIN LIST[1]: SER_DA2P
  PIN LIST[1]: SER_CKBN
  PIN LIST[1]: SER_CKBP
  PIN LIST[1]: SER_DB0N
  PIN LIST[1]: SER_DB0P
  PIN LIST[1]: SER_DB1N
  PIN LIST[1]: SER_DB1P
  PIN LIST[1]: SER_DB2N
  PIN LIST[1]: SER_DB2P
  PIN LIST[1]: SER_DB3N
  PIN LIST[1]: SER_DB3P
  PIN LIST[1]: SER_DA1N
  PIN LIST[1]: SER_DA1P

  PIN LIST[1]: SER_RSVD
  PIN LIST[1]: SER_XRES


--Ser power pins  
  PIN LIST[1]: SER_CAPVDD
  PIN LIST[1]: SER_VDD
  PIN LIST[1]: SER_VDD18
  PIN LIST[1]: SER_VDDIO
---Ser Abus pin use VI16 to meas  
  PIN LIST[1]: SER_ABUS0
  PIN LIST[1]: SER_ABUS1
  PIN LIST[1]: SER_ABUS2
  PIN LIST[1]: SER_ABUS3
  
  PIN LIST[1]: SER_SIOAN
  PIN LIST[1]: SER_SIOAP
  PIN LIST[1]: SER_SIOBN
  PIN LIST[1]: SER_SIOBP

  PIN LIST[1]:   SER_DP_RESERVE	
  
-------------------

  --FPGA pins
  PIN LIST[1]: FPGA_SCLK
  PIN LIST[1]: FPGA_SDOUT
  PIN LIST[1]: FPGA_SDIN
  PIN LIST[1]: FPGA_CSB
---Ser pin use VI16 to measure DC/DCTM

  
  PIN LIST[1]: DC_SE_P_A_VI
  PIN LIST[1]: DC_SE_M_A_VI
  PIN LIST[1]: DC_SE_P_B_VI
  PIN LIST[1]: DC_SE_M_B_VI

  PIN LIST[1]: SER_GPIO3_ABUS0_DCTM
  PIN LIST[1]: SER_GPO4_ABUS1_DCTM
  PIN LIST[1]: SER_GPO5_ABUS2_DCTM  
  PIN LIST[1]: SER_GPO6_ABUS3_DCTM
  PIN LIST[1]: DES_GPIO5_DCTM

--Ser pin use OVI to measure DC 
  PIN LIST[1]: DC_MEAS_A
  PIN LIST[1]: DC_MEAS_B


---DNUT Pins
  PIN LIST[1]: DNUT_VTERM
  PIN LIST[1]: DNUT_VDD
  PIN LIST[1]: DES_RXSDA
  PIN LIST[1]: DES_TXSCL

----LT supply
 PIN LIST[1]: LT_SUPPLY

  --Relays  
  PIN LIST[1]: COAXB_P_RELAY
  PIN LIST[1]: COAXB_M_RELAY
  PIN LIST[1]: DC_K5
  PIN LIST[1]: DC_K6
  PIN LIST[1]: DC_K7
  PIN LIST[1]: DC_K8
  PIN LIST[1]: CB2_SLDC
  PIN LIST[1]: CB1_SLDC
  PIN LIST[1]: X1X2_POSC
  PIN LIST[1]: X1X2
  PIN LIST[1]: X1X2_OSC_DP
  PIN LIST[1]: XRES_RELAY
  PIN LIST[1]: XRES1_RELAY   ----revb hw
  PIN LIST[1]: CB_SIOA

  PIN LIST[1]: FB_RELAY
  PIN LIST[1]: DCTM_K1
  PIN LIST[1]: DCTM_K2
  PIN LIST[1]: ABUS_RELAY
  PIN LIST[1]: MFP_LT_RELAY
  PIN LIST[1]: RXTX_K1
  PIN LIST[1]: I2C1_LT_CB
  PIN LIST[1]: I2C2_FT2_LT_CB
  PIN LIST[1]: I2C_LT_CB
  PIN LIST[1]: I2C2_FT1_LT_CB

  -- PinGroups 
   
    PIN LIST[30]: ALL_PATTERN_PINS  ---[28]
    PIN LIST[2] : AUX_PINS
    PIN LIST[24] :SER_EVEN_PINS
    PIN LIST[24] :SER_ODD_PINS
    PIN LIST[4]  :DC_SE_VI
    PIN LIST[4]  :fpga_pattern_pins
    PIN LIST[2]  :DES_TX_RX

----pin group relay
    PIN LIST [8]  : ALL_HCOVI_RELAYS
    PIN LIST [10] : ALL_FX_RELAYS
    PIN LIST [2]  : ALL_OVI_RELAYS
    PIN LIST [20]  : SER_CSI_PINS
    PIN LIST [23]  : SER_GPIO_PWDNB
    PIN LIST [4]   : SER_LMN_PINS
    PIN LIST [21]   : SER_ALL_MFP 
    PIN LIST [4]   : SER_GPO_PINS
    PIN LIST [10]  : SER_CSI_EVEN_PINS
    PIN LIST [10]  : SER_CSI_ODD_PINS

    PIN LIST [1]  : DNUT_RXTX_RELAY
    PIN LIST [1]  : DNUT_OSC_RELAY
    PIN LIST [4]  : ABUS_DP_pl,ABUS_VI_PINS
    PIN LIST [1]  : RSVD_RELAY
    PIN LIST [1]  : MFP_LT_K12_RELAY
    PIN LIST [10]  :CSI_Leakage_Even,CSI_Leakage_Odd


end_static


procedure GetPins

body


  SER_PWDNB			= eval_pin_list_expr("SER_PWDNB")
  SER_X1_AUXSCL			= eval_pin_list_expr("SER_X1_AUXSCL")
  SER_X2_AUXSDA			= eval_pin_list_expr("SER_X2_AUXSDA")
  SER_GPIO0_MS_LOCK		= eval_pin_list_expr("SER_GPIO0_MS_LOCK")
  SER_GPIO1_LFLTB_ERRB		= eval_pin_list_expr("SER_GPIO1_LFLTB_ERRB")
  SER_GPIO2_GPO_SCLK		= eval_pin_list_expr("SER_GPIO2_GPO_SCLK")
  SER_GPIO3_RCLKOUT		= eval_pin_list_expr("SER_GPIO3_RCLKOUT")
  SER_GPO4_CFG0			= eval_pin_list_expr("SER_GPO4_CFG0")
  SER_GPO5_CFG1 		= eval_pin_list_expr("SER_GPO5_CFG1")
  SER_GPO6_CFG2 		= eval_pin_list_expr("SER_GPO6_CFG2")
  SER_GPIO7_WS			= eval_pin_list_expr("SER_GPIO7_WS")
  SER_GPIO8_SCK 		= eval_pin_list_expr("SER_GPIO8_SCK")
  SER_GPIO9_SD			= eval_pin_list_expr("SER_GPIO9_SD")
  SER_GPIO10_CNTL0_WSOR_SDA2	= eval_pin_list_expr("SER_GPIO10_CNTL0_WSOR_SDA2")
  SER_GPIO11_CNTL1_SCKOR_SCL2	= eval_pin_list_expr("SER_GPIO11_CNTL1_SCKOR_SCL2")
  SER_GPIO12_MS1_SDOR		= eval_pin_list_expr("SER_GPIO12_MS1_SDOR")
  SER_GPIO13_LMN0		= eval_pin_list_expr("SER_GPIO13_LMN0")
  SER_GPIO14_LMN1		= eval_pin_list_expr("SER_GPIO14_LMN1")
  SER_GPIO15_LMN2_SS2_RO	= eval_pin_list_expr("SER_GPIO15_LMN2_SS2_RO")
  SER_GPIO16_LMN3_SS1_BNE	= eval_pin_list_expr("SER_GPIO16_LMN3_SS1_BNE")
  SER_GPIO17_CNTL2_SDA1_MOSI	= eval_pin_list_expr("SER_GPIO17_CNTL2_SDA1_MOSI")
  SER_GPIO18_CNTL3_SCL1_MISO	= eval_pin_list_expr("SER_GPIO18_CNTL3_SCL1_MISO")
  SER_GPIO19_RXSDA		= eval_pin_list_expr("SER_GPIO19_RXSDA")
  SER_GPIO20_TXSCL		= eval_pin_list_expr("SER_GPIO20_TXSCL")
  SER_CKAN			= eval_pin_list_expr("SER_CKAN")
  SER_CKAP			= eval_pin_list_expr("SER_CKAP")
  SER_DA0N			= eval_pin_list_expr("SER_DA0N")
  SER_DA0P			= eval_pin_list_expr("SER_DA0P")
  SER_DA3N			= eval_pin_list_expr("SER_DA3N")
  SER_DA3P			= eval_pin_list_expr("SER_DA3P")
  SER_DA2N			= eval_pin_list_expr("SER_DA2N")
  SER_DA2P			= eval_pin_list_expr("SER_DA2P")
  SER_CKBN			= eval_pin_list_expr("SER_CKBN")
  SER_CKBP			= eval_pin_list_expr("SER_CKBP")
  SER_DB0N			= eval_pin_list_expr("SER_DB0N")
  SER_DB0P			= eval_pin_list_expr("SER_DB0P")
  SER_DB1N			= eval_pin_list_expr("SER_DB1N")
  SER_DB1P			= eval_pin_list_expr("SER_DB1P")
  SER_DB2N			= eval_pin_list_expr("SER_DB2N")
  SER_DB2P			= eval_pin_list_expr("SER_DB2P")
  SER_DB3N			= eval_pin_list_expr("SER_DB3N")
  SER_DB3P			= eval_pin_list_expr("SER_DB3P")
  SER_DA1N			= eval_pin_list_expr("SER_DA1N")
  SER_DA1P			= eval_pin_list_expr("SER_DA1P")

  SER_RSVD			= eval_pin_list_expr("SER_RSVD")
  SER_XRES			= eval_pin_list_expr("SER_XRES")
			

--Ser power pins  		
  SER_CAPVDD			= eval_pin_list_expr("SER_CAPVDD")
  SER_VDD			= eval_pin_list_expr("SER_VDD")
  SER_VDD18			= eval_pin_list_expr("SER_VDD18")
  SER_VDDIO			= eval_pin_list_expr("SER_VDDIO")
---Ser Abus pin use VI16 to meas  
  SER_ABUS0			= eval_pin_list_expr("SER_ABUS0")
  SER_ABUS1			= eval_pin_list_expr("SER_ABUS1")
  SER_ABUS2			= eval_pin_list_expr("SER_ABUS2")
  SER_ABUS3			= eval_pin_list_expr("SER_ABUS3")
  				
  SER_SIOAN			= eval_pin_list_expr("SER_SIOAN")
  SER_SIOAP			= eval_pin_list_expr("SER_SIOAP")
  SER_SIOBN			= eval_pin_list_expr("SER_SIOBN")
  SER_SIOBP			= eval_pin_list_expr("SER_SIOBP")
-----Note only site 2 and 3 pins dp reserves are valid				

  SER_DP_RESERVE		= eval_pin_list_expr("SER_DP_RESERVE")
  
-------------------
-------

  --FPGA pins			
  FPGA_SCLK			= eval_pin_list_expr("FPGA_SCLK")
  FPGA_SDOUT			= eval_pin_list_expr("FPGA_SDOUT")
  FPGA_SDIN			= eval_pin_list_expr("FPGA_SDIN")
  FPGA_CSB			= eval_pin_list_expr("FPGA_CSB")
---Ser pin use VI16 to measure DC/DCTM
 

 DC_SE_P_A_VI			= eval_pin_list_expr("DC_SE_P_A_VI")
 DC_SE_M_A_VI			= eval_pin_list_expr("DC_SE_M_A_VI")
 DC_SE_P_B_VI			= eval_pin_list_expr("DC_SE_P_B_VI")
 DC_SE_M_B_VI			= eval_pin_list_expr("DC_SE_M_B_VI")

 SER_GPIO3_ABUS0_DCTM		= eval_pin_list_expr("SER_GPIO3_ABUS0_DCTM")
 SER_GPO4_ABUS1_DCTM		= eval_pin_list_expr("SER_GPO4_ABUS1_DCTM")
 SER_GPO5_ABUS2_DCTM  		= eval_pin_list_expr("SER_GPO5_ABUS2_DCTM")
 SER_GPO6_ABUS3_DCTM		= eval_pin_list_expr("SER_GPO6_ABUS3_DCTM")
--Ser pin use OVI to measure DC 
 DC_MEAS_A  		        = eval_pin_list_expr("DC_MEAS_A")
 DC_MEAS_B  		        = eval_pin_list_expr("DC_MEAS_B")


---DNUT Pins			
  DNUT_VTERM			= eval_pin_list_expr("DNUT_VTERM")
  DNUT_VDD			= eval_pin_list_expr("DNUT_VDD")
  DES_RXSDA			= eval_pin_list_expr("DES_RXSDA")
  DES_TXSCL			= eval_pin_list_expr("DES_TXSCL")


----LT supply
 LT_SUPPLY			= eval_pin_list_expr("LT_SUPPLY")
				
  --Relays  			
  COAXB_P_RELAY			= eval_pin_list_expr("COAXB_P_RELAY")
  COAXB_M_RELAY			= eval_pin_list_expr("COAXB_M_RELAY")
  DC_K5				= eval_pin_list_expr("DC_K5")
  DC_K6 			= eval_pin_list_expr("DC_K6")
  DC_K7 			= eval_pin_list_expr("DC_K7")
  DC_K8 			= eval_pin_list_expr("DC_K8")
  CB2_SLDC			= eval_pin_list_expr("CB2_SLDC")
  CB1_SLDC			= eval_pin_list_expr("CB1_SLDC")
  X1X2_POSC			= eval_pin_list_expr("X1X2_POSC")
  X1X2				= eval_pin_list_expr("X1X2")
  X1X2_OSC_DP			= eval_pin_list_expr("X1X2_OSC_DP")
  XRES_RELAY			= eval_pin_list_expr("XRES_RELAY")
  XRES1_RELAY			= eval_pin_list_expr("XRES1_RELAY")   ----revB hw
  CB_SIOA			= eval_pin_list_expr("CB_SIOA")

  FB_RELAY			= eval_pin_list_expr("FB_RELAY")
  DCTM_K1			= eval_pin_list_expr("DCTM_K1")
  DCTM_K2			= eval_pin_list_expr("DCTM_K2")
  ABUS_RELAY			= eval_pin_list_expr("ABUS_RELAY")
  MFP_LT_RELAY			= eval_pin_list_expr("MFP_LT_RELAY")
  RXTX_K1			= eval_pin_list_expr("RXTX_K1")
  I2C1_LT_CB			= eval_pin_list_expr("I2C1_LT_CB")
  I2C2_FT2_LT_CB		= eval_pin_list_expr("I2C2_FT2_LT_CB")
  I2C_LT_CB			= eval_pin_list_expr("I2C_LT_CB")
  I2C2_FT1_LT_CB		= eval_pin_list_expr("I2C2_FT1_LT_CB")

  -- PinGroups 

 ALL_PATTERN_PINS		= eval_pin_list_expr("ALL_PATTERN_PINS")
 AUX_PINS           		= eval_pin_list_expr("AUX_PINS") ----X1,X2 DP AND USE TO CONTROL OSC
 SER_EVEN_PINS           	= eval_pin_list_expr("SER_EVEN_PINS") 
 SER_ODD_PINS           	= eval_pin_list_expr("SER_ODD_PINS") 
 DC_SE_VI           	        = eval_pin_list_expr("DC_SE_VI") 
 fpga_pattern_pins              = eval_pin_list_expr("fpga_pattern_pins")
 DES_TX_RX                      = eval_pin_list_expr("DES_TX_RX")


---Pin group rlays
 ALL_HCOVI_RELAYS              = eval_pin_list_expr("ALL_HCOVI_RELAYS")
 ALL_FX_RELAYS                 = eval_pin_list_expr("ALL_FX_RELAYS")
 ALL_OVI_RELAYS                = eval_pin_list_expr("ALL_OVI_RELAYS")
 SER_CSI_PINS                  = eval_pin_list_expr("SER_CSI_PINS")
--abus0_pins	    = eval_pin_list_expr("abus0_pins")

--fpga_pattern_pins    = eval_pin_list_expr("fpga_pattern_pins") 

SER_GPIO_PWDNB              = eval_pin_list_expr("SER_GPIO_PWDNB")
SER_LMN_PINS              = eval_pin_list_expr("SER_LMN_PINS")

SER_ALL_MFP              = eval_pin_list_expr("SER_ALL_MFP")
SER_GPO_PINS              = eval_pin_list_expr("SER_GPO_PINS")

SER_CSI_EVEN_PINS              = eval_pin_list_expr("SER_CSI_EVEN_PINS")
SER_CSI_ODD_PINS              = eval_pin_list_expr("SER_CSI_ODD_PINS")

DNUT_RXTX_RELAY               = eval_pin_list_expr("DNUT_RXTX_RELAY")
DNUT_OSC_RELAY               = eval_pin_list_expr("DNUT_OSC_RELAY")

ABUS_DP_pl                    = eval_pin_list_expr("ABUS_DP_pl")
ABUS_VI_PINS                  = eval_pin_list_expr("ABUS_VI_PINS")
 
RSVD_RELAY              = eval_pin_list_expr("RSVD_RELAY")
MFP_LT_K12_RELAY              = eval_pin_list_expr("MFP_LT_K12_RELAY")    -----revb hw

CSI_Leakage_Even             = eval_pin_list_expr("CSI_Leakage_Even")
CSI_Leakage_Odd             = eval_pin_list_expr("CSI_Leakage_Odd")

end_body
