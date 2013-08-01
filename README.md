DSMR
====

Dutch Smart Meter Reading (DSMR) Project. 

This projects will evoluate during the next months.  

Release 0.1
-----------

The DSMR project intends to assist users to retrieve data from a DSMR (Dutch Smart Meter) P1 port and to extract the data into readable output.

The process-flow is :

1. Setup access to p1 using the port on the Smartmeter
2. Reading the serialport
3. Store the data in a MySQL database
4. Run a stored procedure to extract the relevant data
5. Make the data available in Excel, your browsers, etc


Requirements (under construction)
------------

1. Sample Layout of data send by DSMR P1 port + "DSMR V4.0 final P1.pdf"
2. MySql database, see DSMR.sql
2. MySQL Stored Procedure to extract data from the rawdata send by DSMR P1 port, see DSMR.sql
3. (n/a) Serial Cable, see serialcable.pdf  
4. (n/a) Python program to read com/serial-port
5. (n/a) User Interface to visualize Energy Consumption
6. (n/a) DSMR-data generator to simulate DSMR P1 port behaviour

n/a : not available yet, work in progress


