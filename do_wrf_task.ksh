#! /bin/ksh
#
# This script allows the user to manage a WRF simulation. After editing the wrf_domain.input file
# the user can run the model by executing this script.
#

grep mpich_noshared_dir wrf_domain.input | cut -d":" -f2 | read mpich_noshared_dir	# bin path of your mpich with no shared libs
grep wps_root_dir wrf_domain.input  	 | cut -d":" -f2 | read wps_root_dir    	# WPS root dir (wps will run in this directory)
grep wrf_root_dir wrf_domain.input   	 | cut -d":" -f2 | read wrf_root_dir    	# WRF root dir (wrf will run in this directory)
grep data_source wrf_domain.input    	 | cut -d":" -f2 | read data_source	 	    # data source
grep expt wrf_domain.input           	 | cut -d":" -f2 | read expt 	    		# experiment name
grep max_domain wrf_domain.input         | cut -d":" -f2 | read max_domain    		# max domain
grep wrf_run_mode wrf_domain.input       | cut -d":" -f2 | read wrf_run_mode   		# max domain

case ${wrf_run_mode} in hindcast)
	grep idate wrf_domain.input | cut -d":" -f2 | read idate				# initial date in the format yyyymmddhh
	grep fdate wrf_domain.input | cut -d":" -f2 | read fdate				# final date in the format yyyymmddhh
;;
			forecast)
	# here i'm keeping 2 days of spin up, since i'm not running in restart mode

	date +%Y%m%d | read idate
	echo $idate
	date --date="$idate 00:00:00" +%s 	     | read idate
	echo "scale=0; (${idate} + 248400)" 	     | bc -l | read fdate
	echo "scale=0; (${idate} - 183600)"          | bc -l | read idate
	date -d "1970-01-01 $idate sec" "+%Y%m%d%H"  | read idate
	date -d "1970-01-01 $fdate sec" "+%Y%m%d%H"  | read fdate
;;
esac

echo $idate $fdate

pwd | read root_dir			# path to the funtions

# pre-processing

${root_dir}/write_wrf_namelist.ksh				# writes namelist
${root_dir}/sed_wrf_namelist.ksh ${idate} ${fdate}		# change namelist to the experiment configurations

cd ${wps_root_dir}

ln -sf ${wps_root_dir}/output/${expt}/namelist.wps ${wps_root_dir}

if [[ ! -e ${wps_root_dir}/output/${expt}/geo_em.d0${max_domain}.nc ]]; then
	ln -sf ${wps_root_dir}/geogrid/GEOGRID.TBL.ARW ${wps_root_dir}/GEOGRID.TBL
	${wps_root_dir}/geogrid.exe 		# making the domain
fi

# downloading data
cd ${root_dir}

case ${wrf_run_mode} in hindcast)
     ${root_dir}/get_atm_data.ksh ${idate} ${fdate} ${data_source}		# get atmospheric data for hindcast experiment

;;
			forecast)
			
     ${root_dir}/get_gfs_prod.ksh ${idate} ${fdate}           		# get atmospheric data for a forecast experiment

;;
esac

# Run the ungrib and metgrid programs (must be in the ${wps_root_dir})
cd ${wps_root_dir}
\rm ${wps_root_dir}/output/${expt}/met_em*

# run ungrib
ln -sf ${wps_root_dir}/ungrib/Variable_Tables/Vtable.GFS ${wps_root_dir}/Vtable
${wps_root_dir}/link_grib.csh ${wps_root_dir}/data/${data_source}/*
${wps_root_dir}/ungrib.exe

# run metgrid
ln -sf ${wps_root_dir}/metgrid/METGRID.TBL.ARW ${wps_root_dir}/METGRID.TBL
${wps_root_dir}/metgrid.exe

\rm FILE* GRIB*

cd ${wrf_root_dir}/run

## Run WRF Model
# Remove old files and link new ones
\rm ${wrf_root_dir}/run/rsl.* ${wrf_root_dir}/run/met_em.d0* 
\rm ${wrf_root_dir}/run/wrfinput_d0* ${wrf_root_dir}/run/wrfbdy_d01 
\rm ${wrf_root_dir}/run/wrfout_d0*
ln -sf ${wps_root_dir}/output/${expt}/namelist.input ${wrf_root_dir}/run
ln -sf ${wps_root_dir}/output/${expt}/iolist.txt ${wrf_root_dir}/run
ln -sf ${wps_root_dir}/output/${expt}/met_em* ${wrf_root_dir}/run

ulimit -s unlimited

# Run real.exe (initial and boundary conditions)
${wrf_root_dir}/run/real.exe

clear

echo " Running the WRF model in ${wrf_run_mode} mode, for period ${idate} to ${fdate}..."
echo " "

# Run wrf.exe (Integrate the numerical model)

# Test if mpd is running, if so then starts the model else turn on mpd and run the model

ps -ef | grep -v grep | grep mpd | wc -l | read mpd_aux

if [[ ${mpd_aux} > 0 ]];then
	${mpich_noshared_dir}/mpirun -np 32 ${wrf_root_dir}/run/wrf.exe
else
	${mpich_noshared_dir}/mpd &
	${mpich_noshared_dir}/mpirun -np 32 ${wrf_root_dir}/run/wrf.exe
fi


# This piece of code is inteted to run the model compiled with shared memory option
#export OMP_NUM_THREADS=16

#./wrf.exe

