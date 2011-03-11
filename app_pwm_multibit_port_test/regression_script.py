#!/usr/bin/python

def create_master_log(res_int,np_int):
	res=str(res_int)
	filename='MasterDutyCycle_'+res+'.txt'
	m_dc = open(filename,'w')
	for n in range(0,(res_int+1)):
		duty_cycle = (int)(round((((1.0* n)/res_int)*100.00)))
		for m in range (0,np_int):
			m_dc.write(str(duty_cycle))
			m_dc.write("\n")
		
	m_dc.close()
	command='copy ' + filename + ' master_dutycycle.txt'
	print(command)
	import os
	os.system(command)


def run_command(np_int):
	command = "xmake clean"
	import os
	os.system(command)
	command = "xmake all"
	import os
	os.system(command)
	if np_int == 4:
		command = "xmake PORT_WIDTH=4"
	elif np_int == 8:
		command = "xmake PORT_WIDTH=8"
	import os
	os.system(command)

def compare_result(res_int,ts_int,np_int,mt_int,ind):
	m_dc=open("master_dutycycle.txt",'r')
	sim_dc=open("dutyCycle_log.txt",'r')
	m_dc_val = m_dc.readline()
	sim_dc_val = sim_dc.readline()
	res = 1;
	while(m_dc_val != ''):
		m_dc_val_int = int(m_dc_val)
		sim_dc_val_int = int(sim_dc_val)
		print(m_dc_val_int)
		print(sim_dc_val_int)
		if sim_dc_val_int in range ((m_dc_val_int-1),(m_dc_val_int+1)):
			pass
		else:
			res=0
		
		m_dc_val = m_dc.readline()
		sim_dc_val = sim_dc.readline()
	
	m_dc.close()
	sim_dc.close()

	if ind == 0:
		error_fp = open('Error_log.txt','a')
		error_fp.write("RESOLUTION_")
		error_fp.write(str(res_int))
		error_fp.write("_TIMESTEP_")
		error_fp.write(str(ts_int))
		error_fp.write("_NUM_PORTS_")
		error_fp.write(str(np_int))
		error_fp.write("_MOD_TYPE_")
		error_fp.write(str(mt_int))
		if res == 1:
			print('Test PASSED')
			error_fp.write("     Test Passed ")
			error_fp.write("\n")
		else:
			print('TEST FALIED')
			error_fp.write("     Test Failed ")
			error_fp.write("\n")
		
		error_fp.write("c:\Python24\python.exe regression_script.py ")
		error_fp.write("-ind 0 ")
		error_fp.write("-resolution ")
		error_fp.write(str(res_int))
		error_fp.write(" -timestep ")
		error_fp.write(str(ts_int))
		error_fp.write(" -num_of_ports ")
		error_fp.write(str(np_int))
		error_fp.write(" -mod_type ")
		error_fp.write(str(mt_int))
		error_fp.write("\n")
		error_fp.write("\n")
		error_fp.close()
		return(res)
	else:
		if res == 0:
			return(0)
		else:
			return(1)
		
	


def run_independent(ind_test_val,ind_test_val_max):
	res_ind_final=1
	for n in range(ind_test_val,ind_test_val_max):
		print '-----------Running independent---------------'
		hdr = open('src/test_pwm_multibit.h','w')
		hdr.write("#define RESOLUTION 256")
		hdr.write("\n")
		hdr.write("#define TIMESTEP 10")
		hdr.write("\n")
		hdr.write("#define NUM_PORTS 16")
		hdr.write("\n")
		hdr.write("#define INDEPENDENT")
		hdr.write("\n")
		hdr.write("unsigned int mod_type = 1;")
		hdr.write("unsigned int value [NUM_PORTS]= {")
		value = n
		m_dc = open('master_dutycycle.txt','w')
		for m in range(0,16):
			duty_cycle = (int)(round((((1.0* value)/256.0)*100.00)))
			m_dc.write(str(duty_cycle))
			m_dc.write("\n")
			hdr.write(str(value))
			if m < 15:
				hdr.write(",")
			else:
				hdr.write("};")
				hdr.close()
			value = value+16
		
		m_dc.close()
		import os
		command='copy ' + 'master_dutycycle.txt ' + 'master_dutycycle_ind_'+str(n)+'.txt'
		os.system(command)
		np_int = 16
		run_command(np_int)
		res_ind=compare_result(0,0,0,0,1)
		command = 'copy ' + 'dutyCycle_log.txt ' + 'dutyCycle_log_ind_' + str(n) + '.txt'
		print(command)
		os.system(command)
		if res_ind == 0:
			res_ind_final=0;
		
		error_fp = open('Error_log.txt','a')
		error_fp.write("independent Test with dutycycle ")
		temp_value = value-256
		print(" Value is -------")
		print(value)
		print("Temp Value is -------")
		print(temp_value)
		for ind_range in range(0,16):
			error_fp.write(str(temp_value))
			error_fp.write(",")
			temp_value = temp_value +16
		
		if(res_ind == 0):
			error_fp.write(" Test FAILED")
			error_fp.write("\n")	
		else:
			error_fp.write(" Test PASSED")
			error_fp.write("\n")
		
		error_fp.write("c:\Python24\python.exe ")
		error_fp.write("regression_script.py -ind 1 -ind_test_num ")
		error_fp.write(str(n)) 
		error_fp.write("\n")
		error_fp.write("\n")
		error_fp.close()
	
	return(res_ind_final)



regression = 1
run_while = 1
ind_test = 0
ind_test_val = 0
ind_test_val_max = 16
inp_data_val =0
resolution = ''

import sys
str_arg = sys.argv
arg_len = len(str_arg)
print(arg_len)
if(arg_len == 1):
	regression = 1
	inp_data_val =1
	print('arg length is 1')
else:
	regression = 0
	if(arg_len == 5):
		if((sys.argv[1] == '-ind') & (sys.argv[3] == '-ind_test_num')):
			print(sys.argv[2])
			print(sys.argv[4])
			if(  (sys.argv[2] == '1')   & ( (int(sys.argv[4])) >= 0) & (  (int(sys.argv[4])) <= 16)  ):
				ind_test = 1
				ind_test_val = int(sys.argv[4])
				ind_test_val_max = ind_test_val + 1
				inp_data_val =1
				print('Independent test')
			else:
				print('incorrect1 arg')
		else:
			print('incorrect2 arg')
	else:
		if(arg_len == 11):
			if((sys.argv[1] == '-ind') & (sys.argv[3] == '-resolution') & (sys.argv[5] == '-timestep') & (sys.argv[7] == '-num_of_ports') & (sys.argv[9] == '-mod_type')):
				if(sys.argv[2] == '0'):
					res = sys.argv[4]
					ts = sys.argv[6]
					np = sys.argv[8]
					mt = sys.argv[10]
					inp_data_val =1
					ind_test_val = 0
					ind_test_val_max=0
					print('Normal test')
				else:
					print('incorrect3 arg')
			else:
				print('incorrect4 arg')
		else:
			print('incorrect5 arg')
		

if regression == 1:
	tlist=open("testlist.txt",'r')
	resolution=tlist.readline()
else:
	if ind_test == 0:
		resolution = res +'\n'
		mt=mt +'\n'
		ts=ts +'\n'
		np=np +'\n'
	

res_final=1
while((resolution != '') & (run_while == 1) & (ind_test == 0) & (inp_data_val == 1)):
	if regression == 1:
		mt=tlist.readline()
		mt_int = int(mt)
		ts=tlist.readline()
		ts_int = int(ts)
		np=tlist.readline()
		np_int = int(np)
		res_int=int(resolution)
	else:
		mt_int=int(mt)
		ts_int=int(ts)
		np_int=int(np)
		res_int=int(resolution)
	
	print (res_int + 1)
	hdr = open('src/test_pwm_multibit.h','w')
	hdr.write("# define RESOLUTION ")
	hdr.write(resolution)
	print (mt_int + 1)
	hdr.write("# define TIMESTEP ")
	print (ts_int + 1)
	hdr.write(ts)
	hdr.write("# define PORT_WIDTH ")	
	hdr.write(np)
	print (np_int +1)
	hdr.write("\n")
	hdr.write("unsigned int value[PORT_WIDTH] = {0}; ")
	hdr.write("\n")
	hdr.write("unsigned int edge = ")
	hdr.write(str(mt_int))
	hdr.write(";")
	hdr.write("\n")
	hdr.close()
	create_master_log(res_int,np_int)
	run_command(np_int)
	(res) = compare_result(res_int,ts_int,np_int,mt_int,0)
	if res == 0:
		res_final = 0
	
	import os
	command = 'copy ' + 'dutyCycle_log.txt ' + 'dutyCycle_log_' + str(res_int) + '.txt'
	print(command)
	os.system(command)
	command = "del dutyCycle_log.txt"
	os.system(command)
	if regression == 0:
		run_while = 0
	else:
		resolution=tlist.readline()
	

if regression == 1:
	tlist.close()

res=run_independent(ind_test_val,ind_test_val_max)
if res == 0:
	res_final=0

if res_final == 1:
	error_fp = open('Error_log.txt','a')
	error_fp.write("ALL_test PASSED\n")
	error_fp.close()

import os
command = "copy Error_Log.txt PWM_Error_Log.txt.txt"
os.system(command)
command = "del Error_Log.txt"
os.system(command)
command = "del dutyCycle_log.txt"
os.system(command)
	


	