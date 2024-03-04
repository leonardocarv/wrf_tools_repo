#! /bin/ksh

# Get gfs prod data
#
#
idate=$1
fdate=$2
data_source=GFS_PROD

grep wps_root_dir wrf_domain.input |  cut -d":" -f2 | read wps_root_dir

data_path=${wps_root_dir}/data/${data_source}

if [[ ! -d ${data_path} ]]; then
	mkdir -p ${data_path}
fi

# change to dir where data will be stored
cd ${data_path}

# Time control
dt=21600 		# data time step in seconds

echo ${idate} | cut -c9-10 | read ihour
echo ${idate} | cut -c1-8  | read idate

echo ${fdate} | cut -c9-10 | read fhour
echo ${fdate} | cut -c1-8  | read fdate


date --date="$idate $ihour:00:00" +%s | read i
date --date="$fdate $fhour:00:00" +%s | read j
date +%Y%m%d | read a
date --date="$a 00:00:00" +%s 	     | read a   #  a ser inserida


(( i -= 10800 ))
(( j -= 10800 ))
(( a -= 10800 ))


while (( $j >= $i )); do

	date -d "1970-01-01 $i sec" "+%Y%m%d%H" | read d
	date -d "1970-01-01 $a sec" "+%Y%m%d%H" | read e

	
	echo $d | cut -c1-4  | read yyyy
	echo $d | cut -c5-6  | read mm
	echo $d | cut -c7-8  | read dd
	echo $d | cut -c9-10 | read hh
	

	echo $e | cut -c1-4  | read YYYY
	echo $e | cut -c5-6  | read MM
	echo $e | cut -c7-8  | read DD
	echo $e | cut -c9-10 | read HH
	

	file=GFS_Prod_Global_0p5deg_${yyyy}${mm}${dd}_${hh}00_anl.grib2

	
	if (($i<$a))

	then
	    wget -O $file "https://nomads.ncep.noaa.gov/pub/data/nccf/com/gfs/prod/gfs.${yyyy}${mm}${dd}/${hh}/atmos/gfs.t${hh}z.pgrb2full.0p50.f000"
        
    else
	    ((time_step=($i-$a)/3600))
	    printf "%03d\n" $ppp | read time_step
	    wget -O $file "https://nomads.ncep.noaa.gov/pub/data/nccf/com/gfs/prod/gfs.${YYYY}${MM}${DD}/${HH}/atmos/gfs.t${HH}z.pgrb2full.0p50.f${time_step}"
	    
	fi
	
	(( i += $dt ))
done

