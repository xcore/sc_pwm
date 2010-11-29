/*
 * Copyright XMOS Limited - 2010
 */

#ifndef _PWM_MONITOR_H_
#define _PWM_MONITOR_H_

class XsiCallbacks;

class PwmMonitor {
public:
	PwmMonitor(XsiCallbacks *xsi, unsigned int instanceId, const char *arguments);

	void clock();

	void setTracingEnabled(bool tracingEnabled);
	void setDoneAddress(unsigned int doneAddress);
	void setMaxNumCycles(unsigned int maxNumCycles);

private:
	XsiCallbacks *m_xsi;
	unsigned int m_instanceId;
	unsigned int m_padNumber;
	unsigned int m_oldPadValue;
	unsigned int m_numHighs;
	unsigned int m_numLows;
    unsigned int m_clock;
    unsigned int m_doneAddress;
    bool m_tracingEnabled;
    unsigned int m_numCycles;
    unsigned int m_maxNumCycles;
};

#endif





