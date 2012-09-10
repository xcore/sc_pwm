# The TARGET variable determines what target system the application is 
# compiled for. It either refers to an XN file in the source directories
# or a valid argument for the --target option when compiling.

TARGET = XC-1A

# The APP_NAME variable determines the name of the final .xe file. It should
# not include the .xe postfix. If left blank the name will default to 
# the project name

APP_NAME =

# The flags passed to xcc when building the application
# You can also set the following to override flags for a particular language:
#
#    XCC_XC_FLAGS, XCC_C_FLAGS, XCC_ASM_FLAGS, XCC_CPP_FLAGS
#
# If the variable XCC_MAP_FLAGS is set it overrides the flags passed to 
# xcc for the final link (mapping) stage.

XCC_FLAGS = -g -DPORT_WIDTH=$(PORT_WIDTH) -DTIMESTEP=$(TIMESTEP) -O3

# The USED_MODULES variable lists other module used by the application. 

USED_MODULES = module_pwm_multibit_port

#=============================================================================

PWM_PLUGIN = ../plugin_pwm/bin/PWM.dll


PORT_WIDTH=4

ifeq ($(PORT_WIDTH), 4)
    TIMESTEP=150
    PLUGINS=--plugin $(PWM_PLUGIN) '42' --plugin $(PWM_PLUGIN) '43' --plugin $(PWM_PLUGIN) '48' --plugin $(PWM_PLUGIN) '49'
else
ifeq ($(PORT_WIDTH), 8)
    TIMESTEP=150
    PLUGINS=--plugin $(PWM_PLUGIN) '42' --plugin $(PWM_PLUGIN) '43' --plugin $(PWM_PLUGIN) '44' --plugin $(PWM_PLUGIN) '45' \
            --plugin $(PWM_PLUGIN) '46' --plugin $(PWM_PLUGIN) '47' --plugin $(PWM_PLUGIN) '48' --plugin $(PWM_PLUGIN) '49'
else
ifeq ($(PORT_WIDTH), 16)
    TIMESTEP=250
    PLUGINS=--plugin $(PWM_PLUGIN) '42' --plugin $(PWM_PLUGIN) '43' --plugin $(PWM_PLUGIN) '44' --plugin $(PWM_PLUGIN) '45' \
            --plugin $(PWM_PLUGIN) '46' --plugin $(PWM_PLUGIN) '47' --plugin $(PWM_PLUGIN) '48' --plugin $(PWM_PLUGIN) '49' \
            --plugin $(PWM_PLUGIN) '54' --plugin $(PWM_PLUGIN) '55' --plugin $(PWM_PLUGIN) '56' --plugin $(PWM_PLUGIN) '57' \
            --plugin $(PWM_PLUGIN) '58' --plugin $(PWM_PLUGIN) '59' --plugin $(PWM_PLUGIN) '60' --plugin $(PWM_PLUGIN) '61'
else
    $(error "Invalid port width")
endif
endif
endif

EXECUTABLE=bin/XC-1A/app_pwm_multibit_port_test.xe
TIMINGSCRIPT=../module_pwm_multibit_port/src/pwm.py
#TRACING=--trace-to trace.txt --vcd-tracing '-o trace.vcd -ports-detailed'

test:
	xsim $(PLUGINS) $(TRACING) $(EXECUTABLE)

time:
	xta load $(EXECUTABLE) source $(TIMINGSCRIPT) $(PORT_WIDTH) $(TIMESTEP) -exit


#=============================================================================
# The following part of the Makefile includes the common build infrastructure
# for compiling XMOS applications. You should not need to edit below here.

XMOS_MAKE_PATH ?= ../..
include $(XMOS_MAKE_PATH)/xcommon/module_xcommon/build/Makefile.common
