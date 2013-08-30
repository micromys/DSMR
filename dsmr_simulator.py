import os
import sys 
import serial 
import datetime
from time import time, sleep 
from datetime import time, tzinfo
from random import randint

# next table is used for simulating kW per hour
#
# i.e. v[[0,1,800,1500],...] will generate between 800 and 1500 Watt between midnight and 01:00 am with tariffcode 1 (low)
#

v = [[0,1,800,1500],[1,1,500,700],[2,1,500,700],[3,1,400,500],[4,1,300,400],[5,1,300,400],
[6,1,300,400],[7,0,400,500],[8,0,400,600],[9,0,400,600],[10,0,400,500],[11,0,300,400],
[12,0,300,400],[13,0,300,400],[14,0,300,400],[15,0,300,400],[16,0,300,400],[17,0,300,400],
[18,0,900,1500],[19,0,700,1200],[20,0,500,700],[21,0,400,600],[22,0,400,600],[23,1,500,700]]

def deltasleep(t=10):    # due to crontab startup delay, starttime is synced up to t seconds
    sec             = float(datetime.datetime.now().strftime("%S.%f")) # get seconds.microseconds
    delta           = 0.0               # init delta
    r               = sec % t           # calculate remainder
    delta           = t - r             # calculate time diff in seconds so 0 <= delta <= t
    return float(delta)                 # return delta as sleep time

#	serial port definiton, setting are same as DSMR Port P1
com = serial.Serial() 
com.baudrate = 9600
com.bytesize = serial.SEVENBITS
com.parity = serial.PARITY_EVEN
com.xonxoff = False 
com.rtscts = False
com.timeout = 20 
com.port = "/dev/ttyS0"

try:
	com.open() 
except:
	sys.exit('4') 

os.system('clear')

print "========================================== serial port settings =============================================="
print("=  Name:%s,Port:%s,Speed:%s,Parity:%s,Bytesize:%s,Stopbits:%s,xonxoff:%s,rtscts:%s      =" % (com.name,com.port,com.baudrate,com.parity,com.bytesize,com.stopbits,com.xonxoff,com.rtscts))
print "=============================================================================================================="

sleep(deltasleep(10))

x=True 

while x==True:

	# get current hour and generate simulated power 
	h = int(datetime.datetime.now().strftime("%H"))	# get current hour
	e = float(randint(v[h][2],v[h][3]))/1000	# calculate random power usage in kW	
	f = "%07.2f" %(e)				# format it like 0000.00
	t = str(v[h][1])				# get tariffcode 0=High,1=Low	

	try:
		print datetime.datetime.now().strftime("%Y-%m-%d %H:%M:%S"), "Writing batch"
		com.writelines('/ISk5\999999-1004\n')			# meter identification/type				
		com.writelines('\n')
		com.writelines('0-0:96.1.1(4B414C37303035313338323936303133)\n')	
		com.writelines('1-0:1.8.1(00128.981*kWh)\n')		# total electricity consumption low
		com.writelines('1-0:1.8.2(00049.851*kWh)\n')		# total electricity consumption high
		com.writelines('1-0:2.8.1(00018.127*kWh)\n')		# total electricity delivered low
		com.writelines('1-0:2.8.2(00018.038*kWh)\n')		# total electricity delivered high
		#com.writelines('0-0:96.14.0(0001)\n')
                com.writelines('0-0:96.14.0(000'+t+')\n')	# tariff 0=high, 1=low
		com.writelines('1-0:1.7.0('+f+'*kW)\n')			# current electricity consumption
                #com.writelines('1-0:1.7.0(0000.81*kW)\n')		
		com.writelines('1-0:2.7.0(0000.00*kW)\n')		# current electricity delivery
		com.writelines('0-0:17.0.0(0999.00*kW)\n')
		com.writelines('0-0:96.3.10(1)\n')
		com.writelines('0-0:96.13.1()\n')
		com.writelines('0-0:96.13.0()\n')
		com.writelines('0-1:24.1.0(3)\n')
		com.writelines('0-1:96.1.0(3238303131303031333038323834393133)\n')
		com.writelines('0-1:24.3.0(130505210000)(00)(60)(1)(0-1:24.2.1)(m3)\n')	# timestamp last gas reading
		com.writelines('(00023.536)\n')				# gasmeter m3
		com.writelines('0-1:24.4.0(1)\n')			# gas throttle 0=closed, 1=open	
		com.writelines('!\n')
		
		sleep(deltasleep(10))					# now sleep up to 10 seconds (same as DSMR)

	except:
		sys.exit('8')
		
try:
	com.close() 
except:
	sys.exit('12')
