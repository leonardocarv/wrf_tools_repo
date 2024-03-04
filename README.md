# WRF Tools Repository

Setting up and running the WRF model can be tricky and time-consuming.

This repository contains a set of programs designed to facilitate the execution of 
a WRF ARW model run. The scripts generate model domains, download boundary condition files, 
and process data to obtain all the necessary files required for running the model.

Pre-requesites: 

1) installed WRF and WPS (https://github.com/wrf-model/WRF)
2) geological data (https://www2.mmm.ucar.edu/wrf/users/download/get_sources_wps_geog.html)

Description:

To simulate WRF using this programs the user may set model parameters using
the wrf_domain.input file. In tihs file the user provide system paths including
WRF and WPS instalation paths, and geological data path. This file also control 
model domain and period of simulation.

After editing wrf_domain.input the user must execute the script do_wrf_task.ksh

>> ./do_wrf_task.ksh

The program will search for all the input files, generate the WRF preprocessing,
link all necessary files, and execute the model.

Reminder: To download data from GFS or FNL dataset, please edit the get_atm_data.ksh script
setting your UCAR login and password

>> vim get_atm_data.ksh
>> 53 gg
>> email=youremail@email.com
>> 54 gg
>> psswd=YourPassword

I set a standard model physics for the WRF model. If you need to set other model physics 
please edit write_wrf_namelist.ksh


TO DO:

1) implement model physics input from file;
2) look for user input errors
3) implement restart in the forecast and hindcast run
4) description of CRONTAB in case of operational run
