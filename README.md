DSMR
====

Dutch Smart Meter Reading (DSMR) 

Release 0.1
-----------

The DSMR project intends to assist users to retrieve data from a DSMR (Dutch Smart Meter) Port p1 and to manage the data into readable output.

The process-flow is :

1. Setup access to p1 using the port on the Smartmeter
2. Reading the serialport
3. Store the data in a MySQL database
4. run a stored procedure to extract the relevant data
5. Make the data available in Excel, your browsers, etc


