#! /bin/ksh

# This script start a WRF simulation (hindcast or forecast)
# The user must to edit the file wrf_task.namelist first
# where will be provided the main parameters for the WRF run.

# Programmed by Leonardo Carvalho 

# Set some variables to perform the simulation

init_date=$1								# initial date in the format yyyymmddhh
final_date=$2								# final date in the format yyyymmddhh

grep max_domain wrf_domain.input     | cut -d":" -f2 | read max_domain 	    # number of domain (nesting)
grep wps_root_dir wrf_domain.input   | cut -d":" -f2 | read wps_root_dir    # WPS root dir
grep geog_root_path wrf_domain.input | cut -d":" -f2 | read geog_root_path  # WPS root dir
grep expt wrf_domain.input           | cut -d":" -f2 | read expt 	    # number of domain (nesting)

output_dir=${wps_root_dir}/output/${expt}

if [[ ! -d ${output_dir} ]]; then
	mkdir -p ${output_dir}
fi


cp ./wrf_domain.input ${output_dir}
cd ${output_dir}

geo_res="'30s'"								# geog resolution

echo $1 | cut -c1-4  | read yyyys		# start year
echo $1 | cut -c5-6  | read mms 		# start month
echo $1 | cut -c7-8  | read dds 		# start day
echo $1 | cut -c9-10 | read hhs			# start hour

echo $2 | cut -c1-4  | read yyyye		# end year
echo $2 | cut -c5-6  | read mme 		# end month
echo $2 | cut -c7-8  | read dde 		# end day
echo $2 | cut -c9-10 | read hhe			# end hour

start_date="'${yyyys}-${mms}-${dds}_${hhs}:00:00'"
end_date="'${yyyye}-${mme}-${dde}_${hhe}:00:00'"

idate=${yyyys}${mms}${dds}
fdate=${yyyye}${mme}${dde}

date --date="$idate $hhs:00:00" +%s | read i
date --date="$fdate $hhe:00:00" +%s | read j

echo "scale=0; ($j - $i)/3600" | bc -l | read run_hours

### Get parameters from first domain to calculate truelat, truelon, etc, etc... ###

# Domain corners #

grep d01_lon wrf_domain.input | cut -d":" -f2 | read ilon
grep d01_lon wrf_domain.input | cut -d":" -f3 | read flon
grep d01_lat wrf_domain.input | cut -d":" -f2 | read ilat
grep d01_lat wrf_domain.input | cut -d":" -f3 | read flat

# Spatial resulution #

grep dx wrf_domain.input | cut -d":" -f2 | read dx
grep dy wrf_domain.input | cut -d":" -f2 | read dy

# making the variables to sed it in the namelist.wps and namelist.input

echo "scale=5; (${dx}/110000)" | bc -l | read dxg
echo "scale=5; (${dy}/110000)" | bc -l | read dyg

echo "scale=0; (${flon} - ${ilon})/${dxg}" | bc -l | read e_we
echo "scale=0; (${flat} - ${ilat})/${dyg}" | bc -l | read e_sn

echo "scale=2; (${ilon} + (${e_we}/2)*${dxg})/1" | bc -l | read ref_lon
echo "scale=2; (${ilat} + (${e_sn}/2)*${dyg})/1" | bc -l | read ref_lat

echo "scale=1; (${e_we}/2)" | bc -l | read ref_x
echo "scale=1; (${e_sn}/2)" | bc -l | read ref_y

# sed namelist.wps
sed "s&<max_domain>&${max_domain}&g" namelist.wps   |\
		             sed "s&<ref_lat>&${ref_lat}&g" |\
		             sed "s&<ref_lon>&${ref_lon}&g" |\
		            sed "s&<truelat1>&${ref_lat}&g" |\
		            sed "s&<truelat2>&${ref_lat}&g" |\
		           sed "s&<stand_lon>&${ref_lon}&g" |\
		                 sed "s&<ref_x>&${ref_x}&g" |\
			             sed "s&<ref_y>&${ref_y}&g" |\
		                       sed "s&<dx>&${dx}&g" |\
 			                   sed "s&<dy>&${dy}&g" |\
		                sed "s&<ewe_d01>&${e_we}&g" |\
 			            sed "s&<esn_d01>&${e_sn}&g" |\
 		         sed "s&<geo_res_d01>&${geo_res}&g" |\
		        sed "s&<start_d01>&${start_date}&g" |\
       		        sed "s&<end_d01>&${end_date}&g" |\
  	           sed "s&<output_dir>&${output_dir}&g" |\
       sed "s&<geog_root_path>&${geog_root_path}&g" |\
    	   sed "s&<geo_tbl_path>&${wps_root_dir}&g" |\
       sed "s&<metgrid_tbl_path>&${wps_root_dir}&g" > namelist.wps.temp

# sed namelist.input
sed "s&<run_hours>&${run_hours}&g" namelist.input   |\
	           sed "s&<max_domain>&${max_domain}&g" |\
		                 sed "s&<yyyys>&${yyyys}&g" |\
		                     sed "s&<mms>&${mms}&g" |\
		                     sed "s&<dds>&${dds}&g" |\
		    	             sed "s&<hhs>&${hhs}&g" |\
		                 sed "s&<yyyye>&${yyyye}&g" |\
		     	             sed "s&<mme>&${mme}&g" |\
		    	             sed "s&<dde>&${dde}&g" |\
		    	             sed "s&<hhe>&${hhe}&g" |\
		                sed "s&<ewe_d01>&${e_we}&g" |\
		                sed "s&<esn_d01>&${e_sn}&g" |\
		                   sed "s&<dx_d01>&${dx}&g" |\
 			               sed "s&<dy_d01>&${dy}&g" > namelist.input.temp




mv namelist.wps.temp namelist.wps
mv namelist.input.temp namelist.input


# Aux vars
lat_aux=${ilat}
lon_aux=${ilon}

if [[ ${max_domain} -gt 1 ]]; then
	for i in {2..$max_domain};do
# grep spatial reference from wrf_domain.input file

		grep d0${i}_lon wrf_domain.input | cut -d":" -f2 | read ilon
		grep d0${i}_lon wrf_domain.input | cut -d":" -f3 | read flon
		grep d0${i}_lat wrf_domain.input | cut -d":" -f2 | read ilat
		grep d0${i}_lat wrf_domain.input | cut -d":" -f3 | read flat
	
		echo "scale=0; (${ilon} - ${lon_aux})/${dxg}" | bc -l | read ips
		echo "scale=0; (${ilat} - ${lat_aux})/${dyg}" | bc -l | read jps
	
		echo "scale=5; (${dxg}/3)" | bc -l | read dxg	
		echo "scale=5; (${dyg}/3)" | bc -l | read dyg

		echo "scale=2; (${dx}/3)" | bc -l  | read dx	
		echo "scale=2; (${dy}/3)" | bc -l  | read dy
	
		echo "scale=0; (${flon} - ${ilon})/${dxg}" | bc -l | read e_we
		echo "scale=0; (${flat} - ${ilat})/${dyg}" | bc -l | read e_sn

# sanity check for wrf nested grid (I'm always enlarging the domain, keep it in mind)

		expr ${e_we} % 3 | read aux_ewe
		expr ${e_sn} % 3 | read aux_esn
		
		while [[ ${aux_ewe} -ne 0 ]];do
			(( e_we += 1 ))
			expr ${e_we} % 3 | read aux_ewe
		done		
		while [[ ${aux_esn} -ne 0 ]];do
			(( e_sn += 1 ))
			expr ${e_sn} % 3 | read aux_esn
		done
		
		(( e_we += 1 ))
		(( e_sn += 1 ))
	
			
	#	if [[ ${dxg} > .09 ]]; then
	#		geo_res="'10m'"
	#	elif [[ ${dxg} > 0.03 ]]; then
	#		geo_res="'5m'"
	#	elif [[ ${dxg} > 0.01 ]]; then
	#		geo_res="'2m'"
	#	else
	#		geo_res="'30s'"
	#	fi

		geo_res="'30s'"

		echo $geo_res

        	sed "s&<start_d0${i}>&${start_date}&g"  namelist.wps |\
			          sed "s&<end_d0${i}>&${end_date}&g" |\
		        	      sed "s&<ewe_d0${i}>&${e_we}&g" |\
 			      	      sed "s&<esn_d0${i}>&${e_sn}&g" |\
		               	   sed "s&<ips_d0${i}>&${ips}&g" |\
	 			           sed "s&<jps_d0${i}>&${jps}&g" |\
 		           sed "s&<geo_res_d0${i}>&${geo_res}&g" > namelist.wps.temp

        	       sed "s&<ewe_d0${i}>&${e_we}&g" namelist.input |\
 			      	              sed "s&<esn_d0${i}>&${e_sn}&g" |\
		               	           sed "s&<ips_d0${i}>&${ips}&g" |\
	 			                   sed "s&<jps_d0${i}>&${jps}&g" |\
	 			                     sed "s&<dx_d0${i}>&${dx}&g" |\
 		                             sed "s&<dy_d0${i}>&${dy}&g" > namelist.input.temp

		mv namelist.wps.temp namelist.wps
		mv namelist.input.temp namelist.input

		lat_aux=${ilat}
		lon_aux=${ilon}
	done

(( max_domain += 1 ))
	
	for j in {${max_domain}..5};do
		sed "s&<ewe_d0${j}>,&""&g" namelist.wps  |\
			         sed "s&<start_d0${j}>,&""&g"|\
			          sed "s&<end_d0${j}>,&""&g" |\
			          sed "s&<esn_d0${j}>,&""&g" |\
		     	      sed "s&<ips_d0${j}>,&""&g" |\
	 	              sed "s&<jps_d0${j}>,&""&g" |\
	              sed "s&<geo_res_d0${j}>,&""&g" > namelist.wps.temp



		sed "s&<ewe_d0${j}>,&""&g" namelist.input |\
			           sed "s&<esn_d0${j}>,&""&g" |\
		     	       sed "s&<ips_d0${j}>,&""&g" |\
	 	               sed "s&<jps_d0${j}>,&""&g" |\
	 	                sed "s&<dx_d0${j}>,&""&g" |\
	                    sed "s&<dy_d0${j}>,&""&g" > namelist.input.temp

		mv namelist.input.temp namelist.input
		mv namelist.wps.temp namelist.wps
	done	

	
fi

\rm ${output_dir}/wrf_domain.input
