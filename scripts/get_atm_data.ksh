#! /bin/ksh

# This script execute the download of atmospheric data to set 
# boundary and initial conditions to the WRF model
# The user can pick data from FNL or GFS dataset.
#
# Programmed by Leonardo Carvalho 


#
# This script uses the wrf_domain.input file (set it properly)
# The downloaded files will be stored in the ${wps_root_dir}/data/${data_source} dir
#
# Usage ./get_atm_data.ksh initial_date end_date data_source
# data_source can be FNL or GFS; initial_date and end_date in the format yyyymmddhh
# Example: ./get_atm_data.ksh 2013122200 2013122300 GFS

idate=$1
fdate=$2
data_source=$3

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

(( i -= 10800 ))
(( j -= 10800 ))



# Download ucar coockies

email=youremail@email.com
psswd=YourPassword

wget -V |grep 'GNU Wget ' | cut -d ' ' -f3 | read v

if [[ '$v >= 1.09' ]]; then
opt='wget --no-check-certificate'
else
opt=wget
fi

opt1='-O /dev/null --save-cookies auth.rda_ucar_edu --post-data'
opt2="email=${email}&passwd=${psswd}&action=login"

$opt $opt1="$opt2" https://rda.ucar.edu/cgi-bin/login
opt1="-N --load-cookies auth.rda_ucar_edu"

echo $idate | cut -c1-4 | read yaux
echo $idate | cut -c1-8 | read vvvv

case ${data_source} in FNL)
	opt2="$opt $opt1 http://rda.ucar.edu/data/ds083.2/"
	if [[ $yaux < 1999 ]]; then
		echo " "
		echo "ERROR IN DOWNLOADING DATA..."
		echo "ERR 01 - There is no FNL data for years before 1999..."
		exit 1

#	elif [[ $yaux < 2008 ]]; then
#		grib_version=grib1
#		else
#		grib_version=grib1

	fi
	;;

		       GFS)
	if [[ $yaux < 2007 ]]; then
		echo " "
		echo "ERROR IN DOWNLOADING DATA..."
		echo "ERR 02 - There is no GFS data for years before 2007..."
		exit 2
	fi
	
	if [[ $yaux < 2015 ]]; then

		opt2="$opt $opt1 http://rda.ucar.edu/data/ds335.0/"
	else
		opt2="$opt $opt1 http://rda.ucar.edu/data/ds084.1/"
	fi

	grib_version=grib2
	;;
esac

# Loop over dates and download data

while (( $j >= $i )); do

	date -d "1970-01-01 $i sec" "+%Y%m%d%H" | read d
	
	echo $d | cut -c1-4  | read yyyy
	echo $d | cut -c5-6  | read mm
	echo $d | cut -c7-8  | read dd
	echo $d | cut -c9-10 | read hh
	
	case ${data_source} in FNL)
		if (($i < 1196917200));	then
			grib_version=grib1
		else
			grib_version=grib2
		fi

		file="${grib_version}/${yyyy}/${yyyy}.${mm}/fnl_${yyyy}${mm}${dd}_${hh}_00.${grib_version}"
		aux_file=fnl_${yyyy}${mm}${dd}_${hh}_00.${grib_version}
	;;
			       GFS)
				       	if (($i < 1420066800)); then
						file="GFS0p5/${yyyy}/GFS_Global_0p5deg_${yyyy}${mm}${dd}_${hh}00_anl.${grib_version}"
						aux_file=GFS_Global_0p5deg_${yyyy}${mm}${dd}_${hh}00_anl.${grib_version}
					else

						file="${yyyy}/${yyyy}${mm}${dd}/gfs.0p5.${yyyy}${mm}${dd}${hh}.f000.${grib_version}"
						aux_file=GFS_Global_0p5deg_${yyyy}${mm}${dd}_${hh}00_anl.${grib_version}
					fi
	
	;;
	esac
	
	if [[ ! -e ${aux_file} ]]; then	
		echo "Downloading ${aux_file} from ${data_source} data source..."
		echo ""
		${opt2}${file}
	else
		echo " "
		echo "The file ${aux_file} already exist, skipping to the next..."
		echo " "
	fi
	
	(( i += $dt ))
done

\rm auth.rda_ucar_edu
