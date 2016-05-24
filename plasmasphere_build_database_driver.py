#! /usr/bin/env python

# Starts IDL and runs plasmasphere_build_database.pro

import subprocess
import string
import datetime
import time

p='a'   #select probe 'a' or 'b'

d0 = datetime.datetime(2014, 1, 1, 0, 0, 0)
d1 = datetime.datetime(2016, 1, 1, 0, 0, 0)

ndays = str(d1 - d0)

start = 0
end = ndays.find('days')
ndays = ndays[start:end-1]

dnew = d0.isoformat()
end = dnew.find('T')
dnew = dnew[0:end]



for x in range(0,int(ndays)):
	print "x = ",x
	print "dnew = ", dnew
	exit_code = subprocess.call(['/Applications/exelis/idl84/bin/idl','-e',
		'plasmasphere_build_database_driver_rbsp', '-args','%s'%dnew,'%s'%p])
	tnew = time.mktime(d0.timetuple()) + 86400*(x+1)
	dnew = d0.fromtimestamp(tnew)
	dnew = dnew.isoformat()
	end = dnew.find('T')
	dnew = dnew[0:end]
