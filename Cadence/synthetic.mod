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
