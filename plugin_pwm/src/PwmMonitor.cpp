/*
 * Copyright XMOS Limited - 2010
 */

#include <limits.h>
#include <stdio.h>
#include <stdlib.h>
#include "PwmMonitor.h"
#include "xsiplugin.h"

enum {
	PWM_SIGNAL_LOW  = 0,
	PWM_SIGNAL_HIGH = 1,
};

#define NODE 0
#define CORE 0

PwmMonitor::PwmMonitor(XsiCallbacks *xsi, unsigned int instanceId, const char *arguments) :
    m_xsi(xsi),
    m_instanceId(instanceId),
    m_oldPadValue(0),
    m_numHighs(0),
    m_numLows(0),
    m_clock(0),
    m_doneAddress(0),
    m_tracingEnabled(false),
    m_numCycles(0),
    m_maxNumCycles(UINT_MAX)
{
	m_padNumber = atoi(arguments);
}

void PwmMonitor::clock() {
    ++m_clock;
    if (!m_tracingEnabled)
    	return;

	unsigned int padValue;
	m_xsi->readPad(m_padNumber, &padValue);

	if (padValue != m_oldPadValue) {
		switch (padValue) {
		case PWM_SIGNAL_HIGH:
		    // PWM cycle high transition (i.e. start)
			if ((m_numCycles > 0) && (m_numCycles <= m_maxNumCycles)) {
				// Display duty cycle from previous PWM cycle
				double dutyCycle = m_numHighs * 100.0 / (m_numHighs + m_numLows);
				printf("DUTY CYCLE(%d): %.0f%%\n", m_padNumber, dutyCycle);
				fflush(stdout);
			}

			if ((m_numCycles == m_maxNumCycles) && (m_doneAddress != 0)) {
				unsigned char data = 0x1;
				m_xsi->writeMem(NODE, CORE, m_doneAddress + m_instanceId, 1, &data);
			}

			// Reset counters
			m_numHighs = 0;
			m_numLows = 0;

			++m_numCycles;
			break;
		}
	}

	switch (padValue) {
	case PWM_SIGNAL_HIGH:
		++m_numHighs;
		break;

	case PWM_SIGNAL_LOW:
		++m_numLows;
		break;
	}
	m_oldPadValue = padValue;
}

void PwmMonitor::setTracingEnabled(bool tracingEnabled) {
	m_tracingEnabled = tracingEnabled;
}

void PwmMonitor::setDoneAddress(unsigned int doneAddress) {
    m_doneAddress = doneAddress;
}

void PwmMonitor::setMaxNumCycles(unsigned int maxNumCycles) {
    m_maxNumCycles = maxNumCycles;
}

