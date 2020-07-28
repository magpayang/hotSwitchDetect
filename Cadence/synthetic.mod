use module"./Audio.mod"
use module"./DVM_tests.mod"
use module"./FlowControl.mod"
use module"./FPGA.mod"
use module"./FPGA.mod_org"
use module"./functional.mod"
use module"./general_calls.mod"
use module"./gen_calls2.mod"
use module"./gpio.mod"
use module"./HDCP.mod"
use module"./HS89.tp"
use module"./hw_check.mod"
use module"./I2CTIMING_TEST.mod"
use module"./oLDI.mod"
use module"./reg_access.mod"
use module"./rlms.mod"
use module"./SERDES_Pins.mod"
use module"./synthetic.mod"
use module"./tester_cbits.mod"
use module"./user_cbit_ctrl.mod"
use module"./user_digital.mod"
use module"./user_globals.mod"
use module"./utility_functions.mod"
-- this is important, do not delete
--all legends: --hex1marker for read cbit --hex2marker for read digital pin levels --hex0marker for toggle to vref levels

procedure getPreviousCbitStatus
local
--blank space
end_local
body

	csites = getactivesites()

	for idx = 1 to activesites():
		--0x1MARKER
read cbitK10_K11_HDMI__FXHS_DC+K12_K21_LMN01AB__OPEN_45KOHM+K13_K14_RX0_RX1__DCARD_ATE+K15_K33_RX0RX2_RX1RXC__DC+K16_SIOAN__DCARD_ATE+K17_K47_GMSL__FXHS_DC+K18_K48_GMSL__ATTEN_DC+K19_K20_HDMI__FXHS_DC+K2_RESISTOR_XRES_SPST+K23_K54_GMSL__OPEN_DIFFTERM+K24_K55_GMSL__OPEN_1OHM+K25_K57_GMSL_DIFFTEST__VI16+K26_K49_GMSL_ATTEN__FXHS+K28_SIOAP__DC_TERM+K29_SIOAP__DCARD_ATE+K3_DP__XRES_CMUCAP_OR_DCARD+K30_SIOAN__DC_TERM+K31_K32_RX2_RXC__DCARD_ATE+K4_K58_GPIO_14_GPIO15_GPIO16_GPIO17__DP_LT+K43_SIOBN__DCARD_ATE+K44_SIOBP__DCARD_ATE+K45_SIOBN__DC_TERM+K46_SIOBP__DC_TERM+K5_DDCSCL_DDCSDA__DP_LT+K50_GPIO06_GPIO07__DP_LT+K52_GPIO04_GPIO05__DP_LT+K59_GPIO08_GPIO09__DP_LT+K6_K51_GPIO14_GPIO15_GPIO16_GPIO17__DP_VI+K60_GPIO00_GPIO01__DP_LT+K61_GPIO10_GPIO11__DP_LT+K62_GPIO12_GPIO13__DP_LT+K63_HPD__DP_LT+K64_GPIO02_GPIO03__DP_LT+K65_K66_HDMI_ABUS__VI16+K7_LOCK_ERRB__DP_LT+K72_X1_X2__OSC_XTAL+K73_ABUS2_ABUS3__VI_DCTM+K74_X1__DP_OSC+K75_ABUS0_ABUS1__VI_DCTM+K8_SDARX_SCLTX__DP_DCARD+K9_K85_SDA_SCL_DDCSDA_DDCSCL__OPEN_1KPU+K86_GPIO00__LTGPIO_LTI2C+K87_GPIO01__LTGPIO_LTI2C+K89_GPIO02__LTGPIO_LTI2C+K88_GPIO04__LTGPIO_LTI2C+DCARD_K1_SIOBN_TERM__DNUT+DCARD_K13_SIOBN__DNUT1_DNUT2+DCARD_K14_SIOBP__DNUT1_DNUT2+DCARD_K15_DNUT2_SDA_SCL__FPGA_DP+DCARD_K16_DNUT2_X1_X2__OSC_XTAL+DCARD_K2_SIOBP_TERM__DNUT+DCARD_K3_SIOAP_TERM__DNUT+DCARD_K4_SIOAN_TERM__DNUT+DCARD_K5_DNUT1_SDA_SCL__FPGA_DP+DCARD_K6_DNUT1_X1_X2__OSC_XTAL+DCARD_K7_SIOAP__DNUT1_DNUT2+DCARD_K8_SIOAN__DNUT1_DNUT2+GMSL_SHORT_PHASE_SWITCH into previousCbitStatus
		--read cbit all_cbits into previousCbitStatus
		--0x1ENDMARKER
	end_for	
end_body

procedure getCurrentCbitStatus
local
--blank space
end_local
body
	csites = getactivesites()
	
	for idx = 1 to activesites():
		--0x1MARKER
read cbitK10_K11_HDMI__FXHS_DC+K12_K21_LMN01AB__OPEN_45KOHM+K13_K14_RX0_RX1__DCARD_ATE+K15_K33_RX0RX2_RX1RXC__DC+K16_SIOAN__DCARD_ATE+K17_K47_GMSL__FXHS_DC+K18_K48_GMSL__ATTEN_DC+K19_K20_HDMI__FXHS_DC+K2_RESISTOR_XRES_SPST+K23_K54_GMSL__OPEN_DIFFTERM+K24_K55_GMSL__OPEN_1OHM+K25_K57_GMSL_DIFFTEST__VI16+K26_K49_GMSL_ATTEN__FXHS+K28_SIOAP__DC_TERM+K29_SIOAP__DCARD_ATE+K3_DP__XRES_CMUCAP_OR_DCARD+K30_SIOAN__DC_TERM+K31_K32_RX2_RXC__DCARD_ATE+K4_K58_GPIO_14_GPIO15_GPIO16_GPIO17__DP_LT+K43_SIOBN__DCARD_ATE+K44_SIOBP__DCARD_ATE+K45_SIOBN__DC_TERM+K46_SIOBP__DC_TERM+K5_DDCSCL_DDCSDA__DP_LT+K50_GPIO06_GPIO07__DP_LT+K52_GPIO04_GPIO05__DP_LT+K59_GPIO08_GPIO09__DP_LT+K6_K51_GPIO14_GPIO15_GPIO16_GPIO17__DP_VI+K60_GPIO00_GPIO01__DP_LT+K61_GPIO10_GPIO11__DP_LT+K62_GPIO12_GPIO13__DP_LT+K63_HPD__DP_LT+K64_GPIO02_GPIO03__DP_LT+K65_K66_HDMI_ABUS__VI16+K7_LOCK_ERRB__DP_LT+K72_X1_X2__OSC_XTAL+K73_ABUS2_ABUS3__VI_DCTM+K74_X1__DP_OSC+K75_ABUS0_ABUS1__VI_DCTM+K8_SDARX_SCLTX__DP_DCARD+K9_K85_SDA_SCL_DDCSDA_DDCSCL__OPEN_1KPU+K86_GPIO00__LTGPIO_LTI2C+K87_GPIO01__LTGPIO_LTI2C+K89_GPIO02__LTGPIO_LTI2C+K88_GPIO04__LTGPIO_LTI2C+DCARD_K1_SIOBN_TERM__DNUT+DCARD_K13_SIOBN__DNUT1_DNUT2+DCARD_K14_SIOBP__DNUT1_DNUT2+DCARD_K15_DNUT2_SDA_SCL__FPGA_DP+DCARD_K16_DNUT2_X1_X2__OSC_XTAL+DCARD_K2_SIOBP_TERM__DNUT+DCARD_K3_SIOAP_TERM__DNUT+DCARD_K4_SIOAN_TERM__DNUT+DCARD_K5_DNUT1_SDA_SCL__FPGA_DP+DCARD_K6_DNUT1_X1_X2__OSC_XTAL+DCARD_K7_SIOAP__DNUT1_DNUT2+DCARD_K8_SIOAN__DNUT1_DNUT2+GMSL_SHORT_PHASE_SWITCH into previousCbitStatus
		read cbit all_cbits into previousCbitStatus
		--0x1ENDMARKER
	end_for	
end_body

procedure toggleCbitDetect
local
--blank space
end_local
body
	csites = getactivesites()
	
	for idx = 1 to activesites()then
		csite = activesite[idx]
		for idx = 1 to 100 then
			if previousCbitStatus[csite, idx] XOR currentCbitStatus[csite, idx] then
				toggleDetect[csite,idx] = 1
			else:
				toggleDetect[csite,idx] = 0	
		end_for		
	end_for	
	
	--0x2MARKER
read DNUT_SCL+DNUT_SDA+DUT_CMU_CAP+DUT_DDCSCL+DUT_DDCSDA+DUT_GPIO00+DUT_GPIO01+DUT_GPIO02_MS+DUT_GPIO03_RCLKOUT_RCLKEN+DUT_GPIO04+DUT_GPIO05_BNE_SS1+DUT_GPIO06_RO_SS2+DUT_GPIO07_MISO+DUT_GPIO08_MOSI+DUT_GPIO09_SCLK+DUT_WS_GPIO10+DUT_SCK_GPIO11+DUT_SD_GPIO12+DUT_SDOR_GPIO13_ADD0+DUT_SCKOR_GPIO14_ADD1+DUT_WSOR_GPIO15_ADD2+DUT_GPIO16_CXTP+DUT_GPIO17_I2CSEL+DUT_SCL_TX+DUT_SDA_RX+DUT_SIOA_N+DUT_SIOA_P+DUT_SIOB_N+DUT_SIOB_P+DUT_XRES+FPGA_CSB+FPGA_SCLK+FPGA_SDIN+FPGA_SDOUT+FPGA_GPIO_P15+DNUT_X1+DUT_HSPD+DUT_LMN0A+DUT_LMN0B+DUT_LMN1A+DUT_LMN1B+DUT_NC_GMSL2B+DUT_PWDNB+DUT_RX0_N+DUT_RX0_P+DUT_RX1_N+DUT_RX1_P+DUT_RX2_N+DUT_RX2_P+DUT_RXC_N+DUT_RXC_P+DUT_X1+DUT_ERRB_LFLTB_INTOUTB+DUT_HPD+DUT_LOCK+DUT_X2 levels vref indo into digitalVrefStatus
	read cbit all_digital levels vref into digitalVrefStatus --get digital pin vref status
	--0x2ENDMARKER
	
	for idx = 1 to activesites()then		-- process the info. reduce to boolean
		csite = activesite[idx]
		for idx = 1 to <number of digitalPinstobeTested> then
			if digitalVrefStatus[csite, idx] >= 900mV(not fixed), then
				digitalVrefStatusBoolean = 1
			else:
				digitalVrefStatusBoolean = 0	
		end_for		
	end_for	
	
	
	for idx = 1 to activesites()then	-- hot switch detect part
		csite = activesite[idx]
		for idx = 1 to 100 then
			--0xMARKER -- marker for program to write mapping
			if toggleDetect[csite,idx] then -- this is mapping is created during the question and answer part

			--0xENDMARKER
			end_if
		end_for		
	end_for	
end_body
