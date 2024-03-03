#! /bin/ksh

# This script writes the namelist.wps and namelist.input in the format used in
# this package

# Write namelist.wps


grep wps_root_dir wrf_domain.input   | cut -d":" -f2 | read wps_root_dir    # WPS root dir
grep expt wrf_domain.input           | cut -d":" -f2 | read expt 	    # number of domain (nesting)

output_dir=${wps_root_dir}/output/${expt}

if [[ ! -d ${output_dir} ]]; then
	mkdir -p ${output_dir}
fi

cd ${output_dir}

if [[ -e namelist.wps ]]; then
	\rm namelist.wps
fi

# namelist.wps
cat <<EOF> namelist.wps
&share
 wrf_core = 'ARW',
 max_dom = <max_domain>,
 start_date = <start_d01>,<start_d02>,<start_d03>,<start_d04>,<start_d05>,
 end_date   = <end_d01>,<end_d02>,<end_d03>,<end_d04>,<end_d05>,
 interval_seconds = 21600,
 io_form_geogrid = 2,
 opt_output_from_geogrid_path = '<output_dir>',
 debug_level = 0,
/

&geogrid
 parent_id         = 1,1,2,3,4,
 parent_grid_ratio = 1,3,3,3,3,
 i_parent_start    = 1,<ips_d02>,<ips_d03>,<ips_d04>,<ips_d05>,
 j_parent_start    = 1,<jps_d02>,<jps_d03>,<jps_d04>,<jps_d05>,
 e_we          = <ewe_d01>,<ewe_d02>,<ewe_d03>,<ewe_d04>,<ewe_d05>,
 e_sn          = <esn_d01>,<esn_d02>,<esn_d03>,<esn_d04>,<esn_d05>,
 geog_data_res = <geo_res_d01>,<geo_res_d02>,<geo_res_d03>,<geo_res_d04>,<geo_res_d05>,
 dx = <dx>,
 dy = <dy>,
 map_proj =  'lambert',
 ref_lat   = <ref_lat>,
 ref_lon   = <ref_lon>,
 truelat1  = <truelat1>,
 truelat2  = <truelat2>,
 stand_lon = <stand_lon>,
 geog_data_path = '<geog_root_path>',
 opt_geogrid_tbl_path = '<geo_tbl_path>',
 ref_x = <ref_x>,
 ref_y = <ref_y>,
/

&ungrib
 out_format = 'WPS',
 prefix = 'FILE',
/

&metgrid
 fg_name = 'FILE',
 io_form_metgrid = 2,
 opt_output_from_metgrid_path = '<output_dir>',
 opt_metgrid_tbl_path = '<metgrid_tbl_path>',
/

&mod_levs
 press_pa = 201300 , 200100 , 100000 ,
             95000 ,  90000 ,
             85000 ,  80000 ,
             75000 ,  70000 ,
             65000 ,  60000 ,
             55000 ,  50000 ,
             45000 ,  40000 ,
             35000 ,  30000 ,
             25000 ,  20000 ,
             15000 ,  10000 ,
              5000 ,   1000
/
EOF

#namelist.input
cat <<EOF> namelist.input
&time_control            
run_days                 = 0,
run_hours                = <run_hours>,
run_minutes              = 0,
run_seconds              = 0,
start_year               = <yyyys>,<yyyys>,<yyyys>,<yyyys>,<yyyys>,
start_month              = <mms>,<mms>,<mms>,<mms>,<mms>,
start_day                = <dds>,<dds>,<dds>,<dds>,<dds>,
start_hour               = <hhs>,<hhs>,<hhs>,<hhs>,<hhs>,
start_minute             = 00,       00,       00,       00,       00,
start_second             = 00,       00,       00,       00,       00,
end_year                 = <yyyye>,<yyyye>,<yyyye>,<yyyye>,<yyyye>,
end_month                = <mme>,<mme>,<mme>,<mme>,<mme>,
end_day                  = <dde>,<dde>,<dde>,<dde>,<dde>,
end_hour                 = <hhe>,<hhe>,<hhe>,<hhe>,<hhe>,
end_minute               = 00,       00,       00,       00,       00,
end_second               = 00,       00,       00,       00,       00,
interval_seconds         = 21600,
input_from_file          = .true.,   .false.,   .false.,   .false.,   .false.,
history_interval         = 180,       180,       60,       20,       60,
frames_per_outfile       = 1000,     1000,     1000,     1000,     1000,
restart                  = .false.,
restart_interval         = 5000,
io_form_history          = 2,
io_form_restart          = 2,
io_form_input            = 2,
io_form_boundary         = 2,
iofields_filename	 = "iolist.txt", "iolist.txt", "iolist.txt",
ignore_iofields_warning  = .true.,
debug_level              = 0,
/

&domains                 
time_step                = 60,
time_step_fract_num      = 0,
time_step_fract_den      = 1,
max_dom                  = <max_domain>,
e_we                     = <ewe_d01>,<ewe_d02>,<ewe_d03>,<ewe_d04>,<ewe_d05>,
e_sn                     = <esn_d01>,<esn_d02>,<esn_d03>,<esn_d04>,<esn_d05>,
e_vert                   = 27,       27,       27,       27,       50,
p_top_requested          = 1000,
num_metgrid_levels       = 50,
num_metgrid_soil_levels  = 4,
dx                       = <dx_d01>,<dx_d02>,<dx_d03>,<dx_d04>,<dx_d05>,
dy                       = <dy_d01>,<dy_d02>,<dy_d03>,<dy_d04>,<dy_d05>,
grid_id                  = 1,        2,        3,        4,        5,
parent_id                = 1,        1,        2,        3,        4,
i_parent_start           = 1,<ips_d02>,<ips_d03>,<ips_d04>,<ips_d05>,
j_parent_start           = 1,<jps_d02>,<jps_d03>,<jps_d04>,<jps_d05>,
parent_grid_ratio        = 1,        3,        3,        3,        3,
parent_time_step_ratio   = 1,        3,        3,        3,        3,
feedback                 = 1,
smooth_option            = 0,
max_dz			 = 10000,
dzbot			 = 100,
/

&physics                 
mp_physics               = 3,        3,        3,        3,        3,
ra_lw_physics            = 1,        1,        1,        1,        1,
ra_sw_physics            = 1,        1,        1,        1,        1,
radt                     = 30,       30,       30,       30,       30,
sf_sfclay_physics        = 1,        1,        1,        1,        1,
sf_surface_physics       = 2,        2,        2,        2,        2,
bl_pbl_physics           = 1,        1,        1,        1,        1,
bldt                     = 0,        0,        0,        0,        0,
cu_physics               = 1,        1,        1,        1,        1,
cudt                     = 5,        5,        5,        5,        5,
isfflx                   = 1,
ifsnow                   = 0,
icloud                   = 1,
surface_input_source     = 1,
num_soil_layers          = 4,
sf_urban_physics         = 0,        0,        0,        0,        0,
maxiens                  = 1,
maxens                   = 3,
maxens2                  = 3,
maxens3                  = 16,
ensdim                   = 144,
/

&fdda                    
/

&dynamics                
w_damping                = 0,
diff_opt                 = 1,
km_opt                   = 4,
diff_6th_opt             = 0,        0,
diff_6th_factor          = 0.12,     0.12,     0.12,     0.12,     0.12,
base_temp                = 290.,
damp_opt                 = 0,
zdamp                    = 5000.,    5000.,    5000.,    5000.,    5000.,
dampcoef                 = 0.2,      0.2,      0.2,      0.2,      0.2,
khdif                    = 0,        0,        0,        0,        0,
kvdif                    = 0,        0,        0,        0,        0,
non_hydrostatic          = .true.,   .true.,   .true.,   .true.,   .true.,
moist_adv_opt            = 1,        1,        1,        1,        1,
scalar_adv_opt           = 1,        1,        1,        1,        1,
/

&bdy_control             
spec_bdy_width           = 5,
spec_zone                = 1,
relax_zone               = 4,
specified                = .true.,  .false.,  .false.,  .false.,  .false.,
nested                   = .false.,   .true.,   .true.,   .true.,   .true.,
/

&grib2                   
/

&namelist_quilt          
nio_tasks_per_group      = 0,
nio_groups               = 1,
/
EOF


cat <<EOF> iolist.txt
-:h:0:LU_INDEX,ZNU,ZS,DZS,VAR,THM,TSK,TSK_FORCE,MU,MUB,NEST_POS,FNM,FNP,RDNW,RDN,DNW,CFN,CFN1,RDX,RDY
-:h:0:VAR_SSO,PH,PHB,HFX_FORCE_TEND,LH_FORCE_TEND,TSK_FORCE_TEND,DN,ALBEDO,ZNW,PHYD,QCLOUD,QRAIN
-:h:0:THIS_IS_AN_IDEAL_RUN,AREA2D,DX2D,RESM,ZETATOP,CF1,CF2,CF3,ITIMESTEP,QVAPOR,SST
-:h:0:SHDMAX,SHDMIN,SNOALB,TSLB,SMOIS,SH20,SMCREL,SEAICE,XICEM,UDROFF,IVGTYP,ISLTYP,VEGFRA
-:h:0:GRDFLX,ACGRDFLX,ACSNOM,SNOW,SNOWH,CANWAT,SSTSK,COSZEN,LAI,MAPFAC_M,MAPFAC_U,MAPFAC_V,MAPFAC_MX
-:h:0:MAPFAC_MY,MAPFAC_UX,MAPFAC_UY,MAPFAC_VX,MF_VX_INV,MAPFAC_VY,F,E,SINALPHA,COSALPHA,HGT,P_TOP
-:h:0:GOT_VAR_SSO,T00,P00,TLP,TISO,TLP_STRAT,P_STRAT,MAX_MSFTX,MAX_MSFTY,SNOWNC,GRAUPELNC,HAILNC
-:h:0:CLAT,ALBBCK,EMISS,NOAHRES,TMN,UST,PBLH,SNOWC,SR,SST_INPUT,SFROFF,SWNORM
-:h:0:SAVE_TOPO_FROM_REAL,ISEEDARR_SPPT,ISEEDARR_SKEBS,ISEEDARR_RAND_PERTURB,ISEEDARRAY_SPP_CONV
-:h:0:ISEEDARRAY_SPP_PBL,ISEEDARRAY_SPP_LSM,C1H,C2H,C1F,C2F,C3H,C4H,C3F,C4F,PCB,PC,XLAND,LAKEMASK
EOF


