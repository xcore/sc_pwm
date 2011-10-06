// Copyright (c) 2011, XMOS Ltd, All rights reserved
// This software is freely distributable under a derivative of the
// University of Illinois/NCSA Open Source License posted in
// LICENSE.txt and at <http://github.xcore.com/>

#include <limits.h>
#include <stdio.h>
#include <stdlib.h>
#include <iostream>
#include <math.h>
#include "PwmMonitor.h"
#include "xsiplugin.h"

enum {
	PWM_SIGNAL_LOW  = 0,
	PWM_SIGNAL_HIGH = 1,
};

#define NODE 0
#define CORE 0

using namespace std;

PwmMonitor::PwmMonitor(struct XsiCallbacks *xsi, const char *arguments) :
    m_xsi(xsi),
    m_monitoringEnabled(false)
{
	m_padNumber = atoi(arguments);
}

void PwmMonitor::clock() {
	//printf(" m_monitoringEnabled = %d \n",m_monitoringEnabled);
    if (!m_monitoringEnabled)
    	return;

    // reads the pin value.
	unsigned int pinValue;
	m_xsi->readPad(m_padNumber, &pinValue);
	//printf(" m_pad = %d pinValue = %d \n",m_padNumber,pinValue);

	// 	Stores the pin value in a list.
    m_values.push_back(pinValue);

/*
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
	*/
}

void PwmMonitor::setMonitoring(bool enabled) {
	m_monitoringEnabled = enabled;
}

void PwmMonitor::reportStatus() {

	FILE *dbfp = NULL;
	list<unsigned int>::iterator it;
	int value;
	int valuePrev;
	int count_high;
	int count_low;
	int count;
	int period = 0;
	int start_mon;
	int check_all_high;
	int check_all_low;
	int status_0_1,status_1_0;
	float duty_cycle;
	status_0_1 = 0;
	status_1_0 = 0;
	count = 0;
	count_high = 0;
	count_low = 0;
	start_mon = 0;
	check_all_high = 1;
	check_all_low = 0;
	dbfp = fopen ("dutyCycle_log.txt","a+");
	// Counts the highs and lows in the list

	for(it = m_values.begin(); it != m_values.end();){
		valuePrev = *it ;
		//printf("BIT = %d \n", valuePrev);
		it++;
		if(it == m_values.end()) break;
		value = *it;
		//printf("BIT = %d \n", value);
		check_all_high = check_all_high & valuePrev & value;
		check_all_low = check_all_low | valuePrev | value;
		if((value) & (!valuePrev)) start_mon = 1;
		if(start_mon == 0){
			continue;
		}
		check_all_high = check_all_high & value & valuePrev;

		if((value & (!valuePrev)) || (!value & (valuePrev))) {
			count++;
		}
		if(!status_0_1) {
			status_0_1 = (value & (!valuePrev));
		}

		//if(value & (!valuePrev)) printf("Low to High\n");

		if(!status_1_0){
			status_1_0 = ((!value) & valuePrev);
		}

		//if ((!value) & valuePrev) printf("High to Low\n");
		if(status_1_0) {
			status_0_1 = 0;
		}
		if(status_0_1) {
			status_1_0 = 0;
		}

		if(status_0_1){
			count_high++;
		}
		if(status_1_0){
			count_low++;
		}

		if(count == 3){
			count = 0;
			//printf("count_high = %d \n",count_high);
			//printf("count_low = %d \n",count_low);
			//printf("Break\n");
			break;
		}
	}
	// to calculate the duty cycle
	    period = 0;
		period = (count_high + count_low);
		printf("count_low = %d\n",count_low);
		printf("count_high = %d \n",count_high);
		//printf("period = %d,  \n",period);
		//if(count_high > 0) duty_cycle = ((count_high/period)*100);


	// Work out the period

	// Print to the console.
		//cout <<  "Duty_cycle \n"<< duty_cycle;
		if(check_all_high) duty_cycle = 100;
		else {
			if(!check_all_low) duty_cycle = 0;
			else {
				duty_cycle = (((float)count_high/period)*100.00);
			}
		}
		fprintf(dbfp,"%.0f%% \n",fabs(duty_cycle));
		//if(check_all_high) printf("all High\n");
		//if(!check_all_low) printf("all Low\n");
		//printf("out of loop\n");
		count_high = 0;
		count_low = 0;
		count = 0;
		status_0_1 = 0;
		status_1_0 = 0;
		start_mon = 0;
		duty_cycle = 0.0;
		period = 0;

	// Clear the list for the next time.
	m_values.clear();
	fclose(dbfp);
}

