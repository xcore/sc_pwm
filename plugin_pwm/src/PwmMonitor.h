/*
 * Copyright XMOS Limited - 2010
 */

#ifndef _PWM_MONITOR_H_
#define _PWM_MONITOR_H_

#include <list>

struct XsiCallbacks;

class PwmMonitor {
public:
	PwmMonitor(struct XsiCallbacks *xsi, const char *arguments);

	void clock();
	void setMonitoring(bool enabled);
	void reportStatus();

private:
	struct XsiCallbacks *m_xsi;
	unsigned int m_padNumber;
    bool m_monitoringEnabled;
    std::list<unsigned int> m_values;
};

#endif





