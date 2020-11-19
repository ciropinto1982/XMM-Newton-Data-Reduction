#!/bin/bash

########################################## ROUTINE DESCRIPTION #######################################################
####                                                                                                              ####
#### This bash code reads in parallel the lists of sources and exposures to run XMM_newton/SAS reduction in loop: ####
####                                                                                                              ####
#### 1) Read the source names and exposures from two lists stored in ascii files, the reading is done in parallel ####
####                                                                                                              ####
#### 2) For each source and exposure it creates the necessary direcotries (apart from the ODF) and run XMM-SAS    ####
####                                                                                                              ####
#### 3) At first it run the ODF basic routines (cifduild, odfingest) and then EPPROC, EMPROC, RGSPROC, OMCHAIN    ####
####                                                                                                              ####
#### 4) Then it will require you to open manually the EPIC events or images to write the source and background .. ####
####    .. extraction regions, this way you can run the second part to extract spectra and lightcurves.           ####
####                                                                                                              ####
#### 5) The code also convert the spectra in SPEX format (if SPEX is installed), open the spectra and save plots  ####
####                                                                                                              ####
#### NOTE: all main commands have been disabled with a single "#"; uncomment & launch each one as first exercise  ####
####                                                                                                              ####
#### There are 4 levels: 0=ODF individual processing, 1=event files, 2=clean products, 3=stacking observations    ####
####                                                                                                              ####
######################################################################################################################

############################### DEFINE DIRECTORIES & ENVIRONMENT VARIABLES ###########################################

date > Info_starting_time.txt  # Creates a text file that stores start date and time to calculate routine duration
T="$(date +%s)"

echo " SET HEASOFT: heainit"                                     # Remember to initialise HASOFT manually typing "heainit"
echo " SET XMM-SAS: setsas or"                                   # Remember to initialise XMMSAS manually typing "setsas"
echo " SET XMM-SAS: source /PATH/TO/YOUR/SAS/VERSION/setsas.sh"  #                             ... or your full executable
echo " SET XMM-SAS: SAS_CCFPATH=/PATH/TO/YOUR/SAS/ccf_files"     # Remember to indicate the path to the CALDB
echo " SET XMM-SAS: CALDB downloaded from: https://www.cosmos.esa.int/web/xmm-newton/current-calibration-files"

DIR=$PWD                    # This is to be defined at the very beginning for the data structure

DIR_work=$PWD               # This is to define an eventually different working directory

cd ${DIR_work}              # This "cd" is necessary only if the working dorectory is a different one

### This code assumes, for simplicity, that the data are stored according to the following layout:
###
### /DIR_work/
### /DIR_work/list_of_src.txt
### /DIR_work/list_of_exp.txt
### /DIR_work/SOURCE_NAME1
### /DIR_work/SOURCE_NAME1/odf (this sub-directory is assumed as downloaded from XMM-Newton/XSA webarchive)
### /DIR_work/SOURCE_NAME1/pps (this sub-directory is created by the code once the source list is provided)
### /DIR_work/SOURCE_NAME2
### /DIR_work/SOURCE_NAME2/odf (this sub-directory is assumed as downloaded from XMM-Newton/XSA webarchive)
### /DIR_work/SOURCE_NAME2/pps (this sub-directory is created by the code once the source list is provided)
### ....

############################### SOURCE & BACKGROUND COORDINATE LISTS READING #########################################
###
### These files give the coordinates for source and background that are taken from EPIC images or event files (see below)

index=0

for i in `cat ${DIR_work}/BKG1_coordinates.txt` # BKG Coordinates for EPIC spectra and lc extraction
do
coordinate_BKG1[${index}]=${i}
echo Loading sources coordinates: ${coordinate_BKG1[${index}]}
index=$(($index+1))
done

index=0

for i in `cat ${DIR_work}/SRC1_coordinates.txt` # SRC Coordinates for EPIC spectra and lc extraction
do
coordinate_SRC1[${index}]=${i}
echo Loading sources coordinates: ${coordinate_SRC1[${index}]}
index=$(($index+1))
done

index=0

############################### SOURCE & EXPOSURE LISTS READING ######################################################

index=0

filename1=${DIR_work}/list_of_src.txt
filename2=${DIR_work}/list_of_exp.txt
filelines1=`cat $filename1`
filelines2=`cat $filename2`

set -f
IFS='
'
set -- $( cat $filename2 )
for i in `cat $filename1`
do
  echo

  if [ $index -gt 0 ]   #  [ $index -gt 0 ] or [ $1 != OBS_ID ] to skip all the sources other than certain ID e.g. 0 (first obs)
then
 echo "I am temporarily skipping Source/Expo ................. "$i" "$1" "
else

  printf "%s %s\n" "$i" "$1"

SOURCE=${i}                                   # Give the source name to the environment variable SOURCE

############################### CREATING STRUCTURE OF SUB-DIRECTORIES ################################################

mkdir ${DIR_work}/${SOURCE}/images_skycoord/       # DIR to dump EPIC images for stacking images from observations

mkdir ${DIR_work}/${SOURCE}/light_curves           # DIR to dump lc for comparing among observations
mkdir ${DIR_work}/${SOURCE}/light_curves/lc_files

mkdir ${DIR_work}/${SOURCE}/spectra_stacks         # DIR to dump spectra for stacking RGS and EPIC spectra
mkdir ${DIR_work}/${SOURCE}/spectra_stacks/rgs
mkdir ${DIR_work}/${SOURCE}/spectra_stacks/epic

DIR_backup_lghtcrv=${DIR_work}/${SOURCE}/light_curves/lc_files # Assign lc-backup-dir to an environment variable

# mkdir ${DIR_work}/${i}/$1/odf # This is principle should have been created at the moment of the data download.
  mkdir ${DIR_work}/${i}/$1/pps

############################### START TO WORK ON THE ODF RAW DATA FILES ##############################################

echo "———————————————————————— LEVEL 0.0 cifbuild, odfingest (create summary and calibration files) ————————————————————————————————"

echo Going to the ODF directory ${DIR_work}/${i}/$1/odf/
 
cd ${DIR_work}/${i}/$1/odf/
   
#  echo "Uncompressing ODF files"
#
#  tar -xf `find . -name '*.tar.gz'`
#  tar -xf `find . -name '*.TAR'`
#  
###  rm  `find . -name '*TAR'`
###  rm  `find . -name '*.tar.gz'`

echo SUM files: `find . -name '*SUM.*'`        # Checking availabe ODF-SUM files

###  rm `find . -name '*SUM.SAS'`              # this is to remove old SUM.SAS files

export SAS_ODF=$PWD                            # IMPORTANT: readin ODF directory
export SAS_CCFPATH=/PATH/TO/YOUR/SAS/ccf_files # IMPORTANT: update CCF CALDB DIR
export SAS_CCFPATH=/Users/ciropinto/Downloads/Software/SAS/ccf_2020/valid_ccf
export SAS_VERBOSITY=1                         # OPTION   : choose the verbosity level

#cifbuild -V 1 > cifbuild_log.txt

export SAS_CCF=$PWD/ccf.cif

#odfingest -V 1 > odfingest_log.txt

echo SAS ODF file: `find . -name '*SUM.SAS'`   # Checking outcome of dofingest: SUM file

SAS_ODF_FILE=$(find . -name '*SUM.SAS')        # Reading location of the ODF-SUMMARY file
SAS_ODF_FILE=${SAS_ODF_FILE:2}
  
export SAS_ODF=${DIR_work}/${i}/${1}/odf                 # Updating ODF file location and ENV variable
export SAS_CCF=$SAS_ODF/ccf.cif                          # Updating CCF file location and ENV variable
export SAS_ODF=${DIR_work}/${i}/${1}/odf/${SAS_ODF_FILE} # Updating ODF FILE location and ENV variable

echo SAS_CCF: $SAS_CCF                         # Checking ODF and CCF file env variables
echo SAS_ODF: $SAS_ODF
  
echo Going to the PPS directory ${DIR_work}/${i}/$1/pps/

cd ${DIR_work}/${i}/$1/pps/

############################### START TO CREATE DATA PRODUCTS (EVENT FILES) ##########################################

echo "———————————————————————— LEVEL 1.0 rgsproc, epproc, omchain (create event files) —————————————————————————————————————————————"

# emproc   -V 1 > emproc_log.txt
# epproc   -V 1 > epproc_log.txt
# rgsproc  -V 1 > rgsproc_log.txt
# omichain -V 1 > omichain_log.txt

#echo "Remember to remove wrong / short / multiple exposure in the same observation, if necessary."

#echo Event list created: `find . -name '*EVENLI*'`

#echo "EPIC data reduction -------- Create links to the correct / valid event files"

### rm mos1.fits mos2.fits pn.fits                     # to remove old links

# ln -s $( find . -name '*_EMOS1_*Evts.ds') mos1.fits
# ln -s $( find . -name '*_EMOS2_*Evts.ds') mos2.fits
# ln -s $( find . -name '*_EPN_*Evts.ds')   pn.fits

############################### CLEAN THE EVENT LISTS TO PRODUCE CLEAN DATA ##########################################

echo "———————————————————————— LEVEL 2.1 EPIC BKG flaring according to XMM-SAS standard routines (evselect) ————————————————————————"

#echo "-------Extracting lightcurves: ----------------- MOS 1"
#
#   evselect table="mos1.fits:EVENTS" withrateset=Y rateset=mos1_lc.fits \
#    timecolumn=TIME maketimecolumn=Y timebinsize=100 makeratecolumn=Y \
#    expression='#XMMEA_EM && (PI>10000) && (PATTERN==0)' -V 1 >> log_epic_flaring
#
#   # dsplot table=mos1_lc.fits x=TIME y=RATE &
#
#   tabgtigen table=mos1_lc.fits  expression="(RATE < 0.35)" gtiset=mos1_gti.fits  -V 1 >> log_epic_flaring
#
#   evselect table="mos1.fits:EVENTS" withfilteredset=Y filteredset=mos1_filtered.fits destruct=Y keepfilteroutput=T \
#    expression='#XMMEA_EM && gti(mos1_gti.fits,TIME) && (PI in [300:10000]) && (PATTERN<=12)' -V 1 >> log_epic_flaring
#
#echo "-------Extracting lightcurves: ----------------- MOS 2"
#
#   evselect table="mos2.fits:EVENTS" withrateset=Y rateset=mos2_lc.fits \
#    timecolumn=TIME maketimecolumn=Y timebinsize=100 makeratecolumn=Y \
#    expression='#XMMEA_EM && (PI>10000) && (PATTERN==0)' -V 1 >> log_epic_flaring
#
#   # dsplot table=mos2_lc.fits x=TIME y=RATE &
#
#   tabgtigen table=mos2_lc.fits  expression="(RATE < 0.35)" gtiset=mos2_gti.fits  -V 1 >> log_epic_flaring
#
#   evselect table="mos2.fits:EVENTS" withfilteredset=Y filteredset=mos2_filtered.fits destruct=Y keepfilteroutput=T \
#	 expression='#XMMEA_EM && gti(mos2_gti.fits,TIME) && (PI in [300:10000]) && (PATTERN<=12)' -V 1 >> log_epic_flaring
#
#echo "-------Extracting lightcurves: ----------------- PN"
#
#   evselect table="pn.fits:EVENTS" withrateset=Y rateset=pn_lc.fits \
#    timecolumn=TIME maketimecolumn=Y timebinsize=100 makeratecolumn=Y \
#    expression='#XMMEA_EP && (PI>10000&&PI<12000) && (PATTERN==0)' -V 1 >> log_epic_flaring
#
#   # dsplot table=pn_lc.fits x=TIME y=RATE &
#
#   tabgtigen table=pn_lc.fits  expression="(RATE < 0.5)" gtiset=pn_gti.fits  -V 1 >> log_epic_flaring
#
#   evselect table="pn.fits:EVENTS" withfilteredset=Y filteredset=pn_filtered.fits destruct=Y keepfilteroutput=T \
#    expression='#XMMEA_EP && gti(pn_gti.fits,TIME) && (PI in [300:10000]) && (PATTERN<=4) && (FLAG==0)' -V 1 >> log_epic_flaring

############################### EPIC IMAGE, SPECTRA AND LIGHTCURVE EXTRACTION ########################################

echo "Extracting MOS 1 images for several ranges of energy (for loop on energy ranges)"

mkdir images_skycoord/

minimum_energy=( 300  800  326  350 350 500  900 1200 1800 3000 460  690  500)
maximum_energy=(2500 1400 2500 1770 500 900 1200 1800 3000 7000 690  890 8000)
identif_energy=(full iron rgs1  rgs   0   A    B    C    D    E  A2   B2 epic)

for a in 3 12
do
echo Energy range $((${a}+1)): ${minimum_energy[a]} - ${maximum_energy[a]} eV "(band: ${identif_energy[a]})"

# evselect table=mos1_filtered.fits expression="(PI in [${minimum_energy[a]}:${maximum_energy[a]}])" \
#          filtertype=expression imageset=./images_skycoord/mos1_band_${identif_energy[a]}.fits \
#          xcolumn=X ycolumn=Y ximagebinsize=80 yimagebinsize=80 \
#          ximagesize=600 yimagesize=600 imagebinning=binSize withimageset=yes > my_images_log.txt
#
# evselect table=mos2_filtered.fits expression="(PI in [${minimum_energy[a]}:${maximum_energy[a]}])" \
#          filtertype=expression imageset=./images_skycoord/mos2_band_${identif_energy[a]}.fits \
#          xcolumn=X ycolumn=Y ximagebinsize=80 yimagebinsize=80 \
#          ximagesize=600 yimagesize=600 imagebinning=binSize withimageset=yes >> my_images_log.txt
#
# evselect table=pn_filtered.fits expression="(PI in [${minimum_energy[a]}:${maximum_energy[a]}])" \
#          filtertype=expression imageset=./images_skycoord/pn_band_${identif_energy[a]}.fits \
#          xcolumn=X ycolumn=Y ximagebinsize=80 yimagebinsize=80 \
#          ximagesize=600 yimagesize=600 imagebinning=binSize withimageset=yes >> my_images_log.txt

done

echo "Stacking EPIC MOS-pn images from different detectors"

cd images_skycoord/

#rm images_list.txt
#
#echo  `find . -name '*_band_epic.fits' | sort` > images_list.txt
#
#cat images_list.txt
#
#emosaic imagesets="`cat images_list.txt`" mosaicedset=${i}_EPIC_mosaic_epicband.fits
#
#rm images_list.txt
#
#echo  `find . -name '*_band_rgs.fits' | sort` > images_list.txt
#
#cat images_list.txt
#
#emosaic imagesets="`cat images_list.txt`" mosaicedset=${i}_EPIC_mosaic_rgsband.fits
#
#/Applications/SAOImage\ DS9.app/Contents/MacOS/ds9 ${i}_EPIC_mosaic_epicband.fits -bin factor 2 \
#     -scale log -cmap b \
#     -contour yes -contour limits 1 100 \
#     -contour smooth 5 -contour nlevels 6 -contour save ds9.con
#
# echo ------ Exposure $1 : Copying single images to directory for inspection or stacking -----
#
#cp mos1_band_epic.fits ${DIR_work}/${i}/images_skycoord/mos1_band_epic_$1.fits
#cp mos2_band_epic.fits ${DIR_work}/${i}/images_skycoord/mos2_band_epic_$1.fits
#cp   pn_band_epic.fits ${DIR_work}/${i}/images_skycoord/pn_band_epic_$1.fits

cd ..

echo "IMPORTANT: for EPIC MOS-PN spectra extraction, OPEN IMAGES / EVENT FILES AND CHECK COORDINATES!"

### Here you need to open an image or an event file for each observation to find out the ideal coordinates
### the example shows circular regions for source and background spectra and lightcurve extraction.
###
### IMPORTANT: when opening the images with e.g. ds9, select the coordinates in PHYSICAL format (see below).
###            and write them in column in the files SRC1_coordinates.txt and BKG1_coordinates.txt
###
### coordinate_SRC1="(25606.997,23913.969,400)"  # These are the typical coordinates format
### coordinate_BKG1="(22983.736,24974.488,1200)" # BKG should be larger if possible but match pn and MOS

echo "Extraction coordinates: ${coordinate_SRC1[${index}]} expo ID ${index}"

#
#   evselect table=mos1_filtered.fits withspectrumset=yes spectrumset=MOS1_SRC1_src_spec.fits \
#     energycolumn=PI spectralbinsize=5 withspecranges=yes specchannelmin=0 specchannelmax=11999 \
#     expression="#XMMEA_EM && (PATTERN<=12) && ((X,Y) IN circle${coordinate_SRC1[${index}]})" -V 1 > log_epic_spectra.txt
#
#   evselect table=mos1_filtered.fits withspectrumset=yes spectrumset=MOS1_BKG1_spec.fits \
#     energycolumn=PI spectralbinsize=5 withspecranges=yes specchannelmin=0 specchannelmax=11999 \
#     expression="#XMMEA_EM && (PATTERN<=12) && ((X,Y) IN circle${coordinate_BKG1[${index}]})" -V 1 >> log_epic_spectra.txt
#
##   dsplot table=MOS1_SRC1_src_spec.fits x=CHANNEL y=COUNTS &
##   dsplot table=MOS1_BKG1_spec.fits x=CHANNEL y=COUNTS &
#
#   evselect table=mos2_filtered.fits withspectrumset=yes spectrumset=MOS2_SRC1_src_spec.fits \
#     energycolumn=PI spectralbinsize=5 withspecranges=yes specchannelmin=0 specchannelmax=11999 \
#     expression="#XMMEA_EM && (PATTERN<=12) && ((X,Y) IN circle${coordinate_SRC1[${index}]})" -V 1 >> log_epic_spectra.txt
#
#   evselect table=mos2_filtered.fits withspectrumset=yes spectrumset=MOS2_BKG1_spec.fits \
#     energycolumn=PI spectralbinsize=5 withspecranges=yes specchannelmin=0 specchannelmax=11999 \
#     expression="#XMMEA_EM && (PATTERN<=12) && ((X,Y) IN circle${coordinate_BKG1[${index}]})" -V 1 >> log_epic_spectra.txt
#
##   dsplot table=MOS2_SRC1_src_spec.fits x=CHANNEL y=COUNTS &
##   dsplot table=MOS2_BKG1_spec.fits x=CHANNEL y=COUNTS &
#
#  evselect table=pn_filtered.fits withspectrumset=yes spectrumset=PN_SRC1_src_spec.fits \
#    energycolumn=PI spectralbinsize=5 withspecranges=yes specchannelmin=0 specchannelmax=20479 \
#    expression="(FLAG==0) && (PATTERN<=4) && ((X,Y) IN circle${coordinate_SRC1[${index}]})" -V 1 >> log_epic_spectra.txt
#
#  evselect table=pn_filtered.fits withspectrumset=yes spectrumset=PN_BKG1_spec.fits \
#    energycolumn=PI spectralbinsize=5 withspecranges=yes specchannelmin=0 specchannelmax=20479 \
#    expression="(FLAG==0) && (PATTERN<=4) && ((X,Y) IN circle${coordinate_BKG1[${index}]})" -V 1 >> log_epic_spectra.txt
#
##   dsplot table=PN_SRC1_src_spec.fits x=CHANNEL y=COUNTS &
##   dsplot table=PN_BKG1_spec.fits x=CHANNEL y=COUNTS &
#
#  echo "Calculating / scaling areas"
#
#   backscale spectrumset=MOS1_SRC1_src_spec.fits badpixlocation=mos1_filtered.fits >> log_epic_spectra.txt
#   backscale spectrumset=MOS1_BKG1_spec.fits badpixlocation=mos1_filtered.fits     >> log_epic_spectra.txt
#   backscale spectrumset=MOS2_SRC1_src_spec.fits badpixlocation=mos2_filtered.fits >> log_epic_spectra.txt
#   backscale spectrumset=MOS2_BKG1_spec.fits badpixlocation=mos2_filtered.fits     >> log_epic_spectra.txt
#   backscale spectrumset=PN_SRC1_src_spec.fits badpixlocation=pn_filtered.fits >> log_epic_spectra.txt
#   backscale spectrumset=PN_BKG1_spec.fits badpixlocation=pn_filtered.fits     >> log_epic_spectra.txt
#
#  echo "Response matrix and eff area"
#
#   rmfgen spectrumset=MOS1_SRC1_src_spec.fits rmfset=MOS1_SRC1_src.rmf >> log_epic_spectra.txt
#   arfgen spectrumset=MOS1_SRC1_src_spec.fits arfset=MOS1_SRC1_src.arf withrmfset=yes rmfset=MOS1_SRC1_src.rmf badpixlocation=mos1_filtered.fits detmaptype=psf >> log_epic_spectra.txt
#   rmfgen spectrumset=MOS2_SRC1_src_spec.fits rmfset=MOS2_SRC1_src.rmf >> log_epic_spectra.txt
#   arfgen spectrumset=MOS2_SRC1_src_spec.fits arfset=MOS2_SRC1_src.arf withrmfset=yes rmfset=MOS2_SRC1_src.rmf badpixlocation=mos2_filtered.fits detmaptype=psf >> log_epic_spectra.txt
#   rmfgen spectrumset=PN_SRC1_src_spec.fits rmfset=PN_SRC1_src.rmf >> log_epic_spectra.txt
#   arfgen spectrumset=PN_SRC1_src_spec.fits arfset=PN_SRC1_src.arf withrmfset=yes rmfset=PN_SRC1_src.rmf badpixlocation=pn_filtered.fits detmaptype=psf >> log_epic_spectra.txt
#
#  echo "Binning the spectra: remember to bin also jusy on resolution (no mincounts) to sim-fit with RGS in SPEX!"
#
#   specgroup spectrumset=MOS1_SRC1_src_spec.fits mincounts=25 oversample=3 rmfset=MOS1_SRC1_src.rmf arfset=MOS1_SRC1_src.arf backgndset=MOS1_BKG1_spec.fits groupedset=MOS1_SRC1_src_spec_grp25.fits >> log_epic_spectra.txt
#   specgroup spectrumset=MOS2_SRC1_src_spec.fits mincounts=25 oversample=3 rmfset=MOS2_SRC1_src.rmf arfset=MOS2_SRC1_src.arf backgndset=MOS2_BKG1_spec.fits groupedset=MOS2_SRC1_src_spec_grp25.fits >> log_epic_spectra.txt
#   specgroup spectrumset=PN_SRC1_src_spec.fits mincounts=25 oversample=3 rmfset=PN_SRC1_src.rmf arfset=PN_SRC1_src.arf backgndset=PN_BKG1_spec.fits groupedset=PN_SRC1_src_spec_grp25.fits >> log_epic_spectra.txt
#
##   dsplot table=PN_SRC1_src_spec_grp25.fits x=CHANNEL y=COUNTS &

 echo "Copying EPIC spectra to directory for stacking purposes"

# cp MOS1_SRC1_src_spec.fits ${DIR_work}/${SOURCE}/spectra_stacks/epic/P$1_MOS1_SRC1_src_spec.fits
# cp MOS2_SRC1_src_spec.fits ${DIR_work}/${SOURCE}/spectra_stacks/epic/P$1_MOS2_SRC1_src_spec.fits
# cp PN_SRC1_src_spec.fits   ${DIR_work}/${SOURCE}/spectra_stacks/epic/P$1_PN_SRC1_src_spec.fits
#
# cp MOS1_BKG1_spec.fits ${DIR_work}/${SOURCE}/spectra_stacks/epic/P$1_MOS1_BKG1_spec.fits
# cp MOS2_BKG1_spec.fits ${DIR_work}/${SOURCE}/spectra_stacks/epic/P$1_MOS2_BKG1_spec.fits
# cp PN_BKG1_spec.fits   ${DIR_work}/${SOURCE}/spectra_stacks/epic/P$1_PN_BKG1_spec.fits
#
# cp MOS1_SRC1_src.arf ${DIR_work}/${SOURCE}/spectra_stacks/epic/P$1_MOS1_SRC1_src.arf
# cp MOS2_SRC1_src.arf ${DIR_work}/${SOURCE}/spectra_stacks/epic/P$1_MOS2_SRC1_src.arf
# cp PN_SRC1_src.arf   ${DIR_work}/${SOURCE}/spectra_stacks/epic/P$1_PN_SRC1_src.arf
#
# cp MOS1_SRC1_src.rmf ${DIR_work}/${SOURCE}/spectra_stacks/epic/P$1_MOS1_SRC1_src.rmf
# cp MOS2_SRC1_src.rmf ${DIR_work}/${SOURCE}/spectra_stacks/epic/P$1_MOS2_SRC1_src.rmf
# cp PN_SRC1_src.rmf   ${DIR_work}/${SOURCE}/spectra_stacks/epic/P$1_PN_SRC1_src.rmf

 echo "Archive and backup EPIC spectra (SPO/RES SPEX FORMAT) before deleting and rewriting them"

# mkdir epic_spectra_oldcaldb
#
# mv `find . -name "MOS1_SRC1_spec_grp25*"` epic_spectra_oldcaldb/
# mv `find . -name "MOS2_SRC1_spec_grp25*"` epic_spectra_oldcaldb/
# mv `find . -name "PN_SRC1_spec_grp25*"`   epic_spectra_oldcaldb/
#
# tar -czf epic_spectra_oldcaldb.tgz epic_spectra_oldcaldb/
#
# rm -rf epic_spectra_oldcaldb/

  echo "Trafo converting the EPIC spectra to SPEX format"

### echo Remove old spo files as trafo cannot over-write
#
#### rm `find . -name "MOS1_SRC1_spec_grp25*"` `find . -name "MOS2_SRC1_spec_grp25*"` `find . -name "PN_SRC1_spec_grp25*"`
#
#trafo<<EOF
#1
#1
#10000
#3
#16
#MOS1_SRC1_src_spec_grp25.fits
#y
#y
#3.E-5 5.E-3
#1
#0
#MOS1_SRC1_spec_grp25
#MOS1_SRC1_spec_grp25
#EOF
#
#trafo<<EOF
#1
#1
#10000
#3
#16
#MOS2_SRC1_src_spec_grp25.fits
#y
#y
#3.E-5 5.E-3
#1
#0
#MOS2_SRC1_spec_grp25
#MOS2_SRC1_spec_grp25
#EOF
#
#trafo<<EOF
#1
#1
#10000
#3
#16
#PN_SRC1_src_spec_grp25.fits
#y
#y
#1
#0
#PN_SRC1_spec_grp25
#PN_SRC1_spec_grp25
#EOF

echo "Open SPEX to plot the EPIC spectra"

#spex<<EOF
#
# da PN_SRC1_spec_grp25 PN_SRC1_spec_grp25
#
# da MOS1_SRC1_spec_grp25 MOS1_SRC1_spec_grp25
#
# da MOS2_SRC1_spec_grp25 MOS2_SRC1_spec_grp25
#
# ign  0:0.3 u ke
# ign 10:100 u ke
#
# p de xs
# p ty da
# p ux ke
# p uy fke
# p x lo
# p rx 0.3 10
# p y lo
# p ry 1e-3 1e3
#
# p se a
# p li dis t
#
# p se 1
# p da col 1
# p li col 1
# p se 2
# p da col 2
# p li col 2
# p se 3
# p da col 3
# p li col 3
# p se 4
# p da col 11
# p li col 11
# p cap id text "${i} ${1} EPIC spectra: PN (w) MOS1 (r) MOS2 (g)"
# p cap id disp t
# p cap ut disp f
# p cap lt disp f
# p
#
# p de cps ${i}_${1}_EPIC_keV.ps
# p
# p clo 2
#
# q
#EOF
#
#ps2pdf ${i}_${1}_EPIC_keV.ps
#
#open ${i}_${1}_EPIC_keV.pdf

echo "———————————————————————— LEVEL 2.2 EPIC (pn) TIMING: extract lightcurves at different energy —————————————————————————————————"

mkdir EPIC_lightcurves

DIR_lc=${PWD}/EPIC_lightcurves

min_energy=( 300  300 1000   300)
max_energy=(5000 1000 5000 10000)
idf_energy=(0350 0310 1050  EPIC)

for a in 3     # 0 1 2 3 # for different energy bins for lightcurves # # # in Linux it used to be: ((a=0;a<=1 d;a++));
do
echo Light curve Energy range $((${a})): ${min_energy[a]} - ${max_energy[a]} eV "(band: ${idf_energy[a]})"
# echo

for timebinsize in 100 # # # or two: 100 1000 # or more: 250 500 1000 1500 2000 2500 3000 3500 4000 4500 5000 # time binsize in seconds
do

echo "Extracting PN lightcurves with binsize ${timebinsize}: dstoplot dump lc into an ascii file!"

#   evselect table=pn_filtered.fits energycolumn=PI \
#       expression="(FLAG==0) && (PATTERN<=4) && ((X,Y) IN circle${coordinate_SRC1[${index}]}) && (PI in [${min_energy[a]}:${max_energy[a]}])" \
#       withrateset=yes rateset=${DIR_lc}/PN_src_lightcurve_raw_${a}.lc timebinsize=${timebinsize} \
#       maketimecolumn=yes makeratecolumn=yes > log_lightcurve.txt
#
#   evselect table=pn_filtered.fits energycolumn=PI \
#       expression="(FLAG==0) && (PATTERN<=4) && ((X,Y) IN circle${coordinate_BKG1[${index}]}) && (PI in [${min_energy[a]}:${max_energy[a]}])" \
#       withrateset=yes rateset=${DIR_lc}/PN_bkg_lightcurve_raw_${a}.lc timebinsize=${timebinsize} \
#       maketimecolumn=yes makeratecolumn=yes >> log_lightcurve.txt
#
# # # #    dsplot table=PN_src_lightcurve_raw_${a}.lc withx=yes x=TIME withy=yes y=RATE &
# # # #    dsplot table=PN_bkg_lightcurve_raw_${a}.lc withx=yes x=TIME withy=yes y=RATE &
#
#    epiclccorr srctslist=${DIR_lc}/PN_src_lightcurve_raw_${a}.lc eventlist=pn_filtered.fits \
#               bkgtslist=${DIR_lc}/PN_bkg_lightcurve_raw_${a}.lc withbkgset=yes applyabsolutecorrections=yes \
#                  outset=${DIR_lc}/PN_lccorr_${idf_energy[a]}_${timebinsize}s.lc >> log_lightcurve.txt
#
#       ### Setting file instead of stdout into dsplot to save output into a file
#
# # # #    dsplot table=${DIR_lc}/PN_lccorr_${idf_energy[a]}_${timebinsize}s.lc withx=yes x=TIME withy=yes y=RATE
#
#### Use dstoplot instead of dsplot to dump the lightcurve into an ascii file!
#
#dstoplot table=${DIR_lc}/PN_lccorr_${idf_energy[a]}_${timebinsize}s.lc withx=yes x=TIME withy=yes y=RATE.ERROR \
#        output=file outputfile=${DIR_lc}/PN_lccorr_${idf_energy[a]}_${timebinsize}s.dat >> log_lightcurve.txt
#
#   cp ${DIR_lc}/PN_lccorr_${idf_energy[a]}_${timebinsize}s.dat ${DIR_backup_lghtcrv}/P$1_PN_lccorr_${idf_energy[a]}_${timebinsize}s.dat
#   cp ${DIR_lc}/PN_lccorr_${idf_energy[a]}_${timebinsize}s.lc  ${DIR_backup_lghtcrv}/P$1_PN_lccorr_${idf_energy[a]}_${timebinsize}s.lc

#echo "Plot lightcurves with QDP/PLT"
#
#qdp << EOF
#${DIR_lc}/PN_lccorr_${idf_energy[a]}_${timebinsize}s.dat
#/xs
#p
#q
#EOF

done
done

#echo "Plot only one lightcurve with QDP/PLT"
#
#qdp << EOF
#${DIR_lc}/PN_lccorr_EPIC_1000s.dat
#/xs
#p
#q
#EOF
#
#sleep 1

############################### RGS DATA CLEANING, 1D IMAGE ABD SPECTRA EXTRACTION ###################################

echo "———————————————————————— LEVEL 2.3 RGS data reduction (BKG flaring, PSF selection and stacking) ——————————————————————————————"

echo Extracting information and exposure detail from the eventlist file:
 
R1_EVE=`find . -name '*R1*EVENLI*'`
R2_EVE=`find . -name '*R2*EVENLI*'`

R1_EVE=${R1_EVE:2}
R2_EVE=${R2_EVE:2}

   did=${R1_EVE:0:11}
expno1=${R1_EVE:13:4}
expno2=${R2_EVE:13:4}

srcid=1

echo "RGS background lightcurve extraction:"

# evselect table="${did}R1${otype}${expno1}EVENLI0000.FIT:EVENTS" makeratecolumn=yes maketimecolumn=yes timecolumn=TIME timebinsize=100 \
#          expression="(CCDNR == 9) && ((M_LAMBDA,XDSP_CORR) in REGION(${did}R1${otype}${expno1}SRCLI_0000.FIT:RGS1_BACKGROUND))" \
#          rateset=rgs1_bglc.fits > rgs_flaring.txt
# evselect table="${did}R2${otype}${expno2}EVENLI0000.FIT:EVENTS" makeratecolumn=yes maketimecolumn=yes timecolumn=TIME timebinsize=100 \
#          expression="(CCDNR == 9) && ((M_LAMBDA,XDSP_CORR) in REGION(${did}R2${otype}${expno2}SRCLI_0000.FIT:RGS2_BACKGROUND))" \
#          rateset=rgs2_bglc.fits >> rgs_flaring.txt
#
#   dsplot table=rgs1_bglc.fits x=TIME y=RATE &
#   dsplot table=rgs2_bglc.fits x=TIME y=RATE &

echo "Filter "$i" "$1" RGS data and extract data product"

### echo: RGS 1 and 2 GTI are merged, i.e. only times that are good for both!
#
#   tabgtigen table=rgs1_bglc.fits gtiset=gti_rgs1_0p1.fits expression="(RATE < 0.2)"
#   tabgtigen table=rgs2_bglc.fits gtiset=gti_rgs2_0p1.fits expression="(RATE < 0.2)"
#
#   gtimerge tables="gti_rgs1_0p1.fits gti_rgs2_0p1.fits" withgtitable=yes \
#            gtitable=gti_rgs_merged.fits mergemode=and plotmergeresult=false

### echo: for extended sources like clusters xpsfincl=95 or 99 would be more appropriate
###
### echo: withbackgroundmodel enable the extraction of an additional model background spectrum

withsrc=yes
srcstyle=radec
bkgcor=NO
gtifile=gti_rgs_merged.fits
xpsfincl=90
xpsfexcl=98
pdistincl=95

echo "Coordinates should be double checked: if MOS1/2 are centered no need to run rgsproc at coordinates."

# rgsproc bkgcorrect=${bkgcor} auxgtitables=${gtifile} withbackgroundmodel=yes entrystage=3:filter \
#         finalstage=5:fluxing xpsfincl=${xpsfincl} xpsfexcl=${xpsfexcl} pdistincl=${pdistincl} >> rgs_flaring.txt

srcid=1

### echo "INFO: Launching rgsproc with coordinates specification: required right ascension and declination"
### echo "INFO: this is necessary only if the source coordinates different from the observation pointing!"
###
###
### srclabel=SRC1
### srcra=3.8708
### srcdec=-39.2219
###
### rgsproc srcra=${srcra} srcdec=${srcdec} withsrc=${withsrc} srclabel=${srclabel} srcstyle=${srcstyle} \
###         bkgcorrect=${bkgcor} auxgtitables=${gtifile} withbackgroundmodel=yes \
###         xpsfincl=${xpsfincl} xpsfexcl=${xpsfexcl} pdistincl=${pdistincl} -V 2
###
### srcid=3
###
### echo In this case, and only, the "srcid" needs to be put equal to 3 rather than default 1.

echo "Make RGS 1,2 region and banana plots to check extraction effciency."

#evselect table="${did}R1${otype}${expno1}EVENLI0000.FIT:EVENTS" withimageset=yes imageset='rgs_spatial1.fit' \
#         xcolumn='M_LAMBDA' ycolumn='XDSP_CORR' > rgs_banana.txt
#evselect table="${did}R1${otype}${expno1}EVENLI0000.FIT:EVENTS" withimageset=yes imageset='rgs_banana1.fit' \
#         expression="region(${did}R1${otype}${expno1}SRCLI_0000.FIT:RGS1_SRC${srcid}_SPATIAL,M_LAMBDA,XDSP_CORR)" \
#         xcolumn='M_LAMBDA' ycolumn='PI' withyranges=yes yimagemin=0 yimagemax=3000  >> rgs_banana.txt
#evselect table="${did}R2${otype}${expno2}EVENLI0000.FIT:EVENTS" withimageset=yes imageset='rgs_spatial2.fit' \
#         xcolumn='M_LAMBDA' ycolumn='XDSP_CORR' >> rgs_banana.txt
#evselect table="${did}R2${otype}${expno2}EVENLI0000.FIT:EVENTS" withimageset=yes imageset='rgs_banana2.fit' \
#         expression="region(${did}R2${otype}${expno2}SRCLI_0000.FIT:RGS2_SRC${srcid}_SPATIAL,M_LAMBDA,XDSP_CORR)" \
#         xcolumn='M_LAMBDA' ycolumn='PI' withyranges=yes yimagemin=0 yimagemax=3000 >> rgs_banana.txt
#
#rgsimplot endispset='rgs_banana1.fit' spatialset='rgs_spatial1.fit' srcidlist="${srcid}" \
#          srclistset="${did}R1${otype}${expno1}SRCLI_0000.FIT" withendispregionsets=yes \
#          withendispset=yes withspatialregionsets=yes withspatialset=yes \
#          device=/cps plotfile=rgs_region_R1.ps >> rgs_banana.txt
#rgsimplot endispset='rgs_banana2.fit' spatialset='rgs_spatial2.fit' srcidlist="${srcid}" \
#          srclistset="${did}R2${otype}${expno2}SRCLI_0000.FIT" withendispregionsets=yes \
#          withendispset=yes withspatialregionsets=yes withspatialset=yes \
#          device=/cps plotfile=rgs_region_R2.ps >> rgs_banana.txt
#
####gv rgs_region_R1.ps &
####gv rgs_region_R2.ps &
#
#ps2pdf rgs_region_R1.ps
#ps2pdf rgs_region_R2.ps
#
#open rgs_region_R1.pdf rgs_region_R2.pdf

echo "Copying spectra and responses to files with standard names (used by rgscombine / stacking below)"

#cp ${did}R1${otype}${expno1}SRSPEC100${srcid}.FIT SRC1_srs1.FIT
#cp ${did}R1${otype}${expno1}MBSPEC1000.FIT        SRC1_bkg1.FIT
#cp ${did}R1${otype}${expno1}RSPMAT100${srcid}.FIT SRC1_rsp1.FIT
#
#cp ${did}R2${otype}${expno2}SRSPEC100${srcid}.FIT SRC1_srs2.FIT
#cp ${did}R2${otype}${expno2}MBSPEC1000.FIT        SRC1_bkg2.FIT
#cp ${did}R2${otype}${expno2}RSPMAT100${srcid}.FIT SRC1_rsp2.FIT
#
#cp ${did}R1${otype}${expno1}BGSPEC100${srcid}.FIT SRC1_bgs1.FIT
#cp ${did}R2${otype}${expno2}BGSPEC100${srcid}.FIT SRC1_bgs2.FIT

echo "Copying RGS spectra to directory for stacking purposes"

# cp ${did}R1${otype}${expno1}SRSPEC100${srcid}.FIT ${DIR_work}/${SOURCE}/spectra_stacks/rgs
# cp ${did}R1${otype}${expno1}MBSPEC1000.FIT        ${DIR_work}/${SOURCE}/spectra_stacks/rgs
# cp ${did}R1${otype}${expno1}RSPMAT100${srcid}.FIT ${DIR_work}/${SOURCE}/spectra_stacks/rgs
# cp ${did}R2${otype}${expno2}SRSPEC100${srcid}.FIT ${DIR_work}/${SOURCE}/spectra_stacks/rgs
# cp ${did}R2${otype}${expno2}MBSPEC1000.FIT        ${DIR_work}/${SOURCE}/spectra_stacks/rgs
# cp ${did}R2${otype}${expno2}RSPMAT100${srcid}.FIT ${DIR_work}/${SOURCE}/spectra_stacks/rgs
# cp ${did}R1${otype}${expno1}BGSPEC100${srcid}.FIT ${DIR_work}/${SOURCE}/spectra_stacks/rgs
# cp ${did}R2${otype}${expno2}BGSPEC100${srcid}.FIT ${DIR_work}/${SOURCE}/spectra_stacks/rgs
# cp ${did}R1${otype}${expno1}SRSPEC200${srcid}.FIT ${DIR_work}/${SOURCE}/spectra_stacks/rgs
# cp ${did}R1${otype}${expno1}MBSPEC2000.FIT        ${DIR_work}/${SOURCE}/spectra_stacks/rgs
# cp ${did}R1${otype}${expno1}RSPMAT200${srcid}.FIT ${DIR_work}/${SOURCE}/spectra_stacks/rgs
# cp ${did}R2${otype}${expno2}SRSPEC200${srcid}.FIT ${DIR_work}/${SOURCE}/spectra_stacks/rgs
# cp ${did}R2${otype}${expno2}MBSPEC2000.FIT        ${DIR_work}/${SOURCE}/spectra_stacks/rgs
# cp ${did}R2${otype}${expno2}RSPMAT200${srcid}.FIT ${DIR_work}/${SOURCE}/spectra_stacks/rgs
# cp ${did}R1${otype}${expno1}BGSPEC200${srcid}.FIT ${DIR_work}/${SOURCE}/spectra_stacks/rgs
# cp ${did}R2${otype}${expno2}BGSPEC200${srcid}.FIT ${DIR_work}/${SOURCE}/spectra_stacks/rgs

echo "Archive and backup EPIC spectra (SPO/RES SPEX FORMAT) before deleting and rewriting them"

# mkdir rgs_spectra_oldcaldb
#
# mv `find . -name "*rgs*spo"` rgs_spectra_oldcaldb/
# mv `find . -name "*rgs*res"` rgs_spectra_oldcaldb/
#
# tar -czf rgs_spectra_oldcaldb.tgz rgs_spectra_oldcaldb/
#
# rm -rf rgs_spectra_oldcaldb/

echo "Trafo converting RGS spectra to SPEX format: exposure background spectrum (if SPEX is installed)"

### echo Remove old spo files as trafo cannot over-write
#
#trafo << EOF
#1
#1
#10000
#3
#16
#`ls ${did}R1${otype}${expno1}SRSPEC100${srcid}.FIT`
#y
#`ls ${did}R1${otype}${expno1}BGSPEC100${srcid}.FIT`
#y
#`ls ${did}R1${otype}${expno1}RSPMAT100${srcid}.FIT`
#no
#0
#SRC1_rgs1_expbkg
#SRC1_rgs1_expbkg
#EOF
#
#trafo << EOF
#1
#1
#10000
#3
#16
#`ls ${did}R2${otype}${expno2}SRSPEC100${srcid}.FIT`
#y
#`ls ${did}R2${otype}${expno2}BGSPEC100${srcid}.FIT`
#y
#`ls ${did}R2${otype}${expno2}RSPMAT100${srcid}.FIT`
#no
#0
#SRC1_rgs2_expbkg
#SRC1_rgs2_expbkg
#EOF
#
echo "Trafo converting RGS spectra to SPEX format: model background spectrum (if SPEX is installed)"

### echo Remove old spo files as trafo cannot over-write
#
#trafo << EOF
#1
#1
#10000
#3
#16
#`ls ${did}R1${otype}${expno1}SRSPEC100${srcid}.FIT`
#y
#`ls ${did}R1${otype}${expno1}MBSPEC1000.FIT`
#y
#`ls ${did}R1${otype}${expno1}RSPMAT100${srcid}.FIT`
#no
#0
#SRC1_rgs1_modbkg
#SRC1_rgs1_modbkg
#EOF
#
#trafo << EOF
#1
#1
#10000
#3
#16
#`ls ${did}R2${otype}${expno2}SRSPEC100${srcid}.FIT`
#y
#`ls ${did}R2${otype}${expno2}MBSPEC1000.FIT`
#y
#`ls ${did}R2${otype}${expno2}RSPMAT100${srcid}.FIT`
#no
#0
#SRC1_rgs2_modbkg
#SRC1_rgs2_modbkg
#EOF

# echo SPEX spectra extracted: `find . -name '*.spo'`
# echo Check also the extraction regions: `find . -name '*_R1.ps'`
# echo and the source spectra: `find . -name '*_srs1.FIT'`

echo "Combining RGS 1-2 (just for plotting purposes): exposure background"

# echo ' '`find . -name 'SRC1_srs*.FIT' | sort` > src_list.txt
# echo ' '`find . -name 'SRC1_bgs*.FIT' | sort` > bgs_list.txt
# echo ' '`find . -name 'SRC1_rsp*.FIT' | sort` > rsp_list.txt
#
# rgscombine pha="`cat src_list.txt`" bkg="`cat bgs_list.txt`" rmf="`cat rsp_list.txt`" \
#            filepha='rgs_stacked_srs.fits' filermf='rgs_stacked_rmf.fits' \
#            filebkg='rgs_stacked_bgs.fits' rmfgrid=4000 > rgs_stacking.txt
#
#trafo << EOF
#1
#1
#10000
#3
#16
#`ls rgs_stacked_srs.fits`
#y
#no
#0
#rgs_stacked_srs_expbkg
#rgs_stacked_srs_expbkg
#EOF

echo "Combining RGS 1-2 (just for plotting purposes): model background"

# echo ' '`find . -name 'SRC1_srs*.FIT' | sort` > src_list.txt
# echo ' '`find . -name 'SRC1_bkg*.FIT' | sort` > bkg_list.txt
# echo ' '`find . -name 'SRC1_rsp*.FIT' | sort` > rsp_list.txt
#
# rgscombine pha="`cat src_list.txt`" bkg="`cat bkg_list.txt`" rmf="`cat rsp_list.txt`" \
#            filepha='rgs_stacked_srs.fits' filermf='rgs_stacked_rmf.fits' \
#            filebkg='rgs_stacked_bkg.fits' rmfgrid=4000 >> rgs_stacking.txt
#
#trafo << EOF
#1
#1
#10000
#3
#16
#`ls rgs_stacked_srs.fits`
#y
#no
#0
#rgs_stacked_srs_modbkg
#rgs_stacked_srs_modbkg
#EOF

echo "Open SPEX to plot RGS 1,2 spectra and their stacks"

#spex<<EOF
#da SRC1_rgs1_expbkg SRC1_rgs1_expbkg
#da SRC1_rgs2_expbkg SRC1_rgs2_expbkg
#da SRC1_rgs1_modbkg SRC1_rgs1_modbkg
#da SRC1_rgs2_modbkg SRC1_rgs2_modbkg
#ign  0:6     u a
#ign 30:40    u a
#bin  6:30 5 u a
#da rgs_stacked_srs_expbkg rgs_stacked_srs_expbkg
#da rgs_stacked_srs_modbkg rgs_stacked_srs_modbkg
#ign ins 5:6  0:6     u a
#ign ins 5:6 30:40    u a
#bin ins 5:6  6:30 3  u a
#ign  0:6     u a
#ign 30:40    u a
#bin  6:30 5  u a
#p de xs
#p ty da
#p ux a
#p uy a
#p cap id text "${i} ${1} RGS 1,2 spectra (bgs and mbs) and stacked (bgs and mbs)"
#plot cap ut disp f
#plot cap lt disp f
#p se 1:2
#p da col 1
#p li dis t
#p li col 1
#p se 3:4
#p da col 11
#p li dis t
#p li col 11
#p se 5
#p da col 2
#p li dis t
#p li col 2
#p se 6
#p da col 3
#p se al
#p back disp f
#p da lw 3
#p mo lw 3
#p box lw 3
#p cap y lw 3
#p cap it lw 3
#p cap x lw 3
#p uy fa
#p ry 0 5
##p rx 7 35
##p rx 13 23
#p
#da sh
#p de cps ${SOURCE}_$1_RGS_Ang.ps
#p
#p clo 2
#q
#EOF
#
#ps2pdf ${SOURCE}_$1_RGS_Ang.ps
#  open ${SOURCE}_$1_RGS_Ang.pdf

echo "Open SPEX to plot RGS and EPIC individual / RGS 1-2 stacked spectra"

### If not all observations might have RGS spectra (i.e. were taken off axis) then load first EPIC data.

#spex<<EOF
#
#da rgs_stacked_srs_expbkg rgs_stacked_srs_expbkg
#da rgs_stacked_srs_mbsbkg rgs_stacked_srs_mbsbkg
#
#ign ins 1  0:7     u a
#ign ins 1 27:40    u a
#bin ins 1  7:27 5  u a
#ign ins 2  0:7     u a
#ign ins 2 27:40    u a
#bin ins 2  7:27 5  u a
#
#da PN_SRC1_spec_grp25   PN_SRC1_spec_grp25
#da MOS1_SRC1_spec_grp25 MOS1_SRC1_spec_grp25
#da MOS2_SRC1_spec_grp25 MOS2_SRC1_spec_grp25
#
#ign ins 3:5  0:0.3 u ke
#ign ins 3:5 10:100 u ke
#
###da SRC1_rgs1_expbkg SRC1_rgs1_expbkg
###da SRC1_rgs2_expbkg SRC1_rgs2_expbkg
###
###da SRC1_rgs1 SRC1_rgs1
###da SRC1_rgs2 SRC1_rgs2
###
###ign ins 6:10  0:6     u a
###ign ins 6:10 27:40    u a
###bin ins 6:10  6:27 15 u a
#
#p de xs
#p ty da
#
#p se 1
#p da col 1
#p li col 1
#p li dis t
#p se 2
#p da col 2
#p li col 2
#p li dis t
#p se 3
#p da col 3
#p li col 3
#p li dis t
#p se 4
#p da col 11
#p li col 11
#p li dis t
#p se 5
#p da col 12
#p ba col 12
#p li col 12
#p se al
#p li dis t
#p mo dis f
#p ba lt 4
#p ba dis f
#p ba col 8
#p ba lt 1
#p ba lw 3
#
#p cap id text "${i} ${1} PN (w) and MOS 1 (r) , 2 (g) RGS bgs (bb) mbs (pp) spectra"
#p cap id disp t
#p cap ut disp f
#p cap lt disp f
#p da lw 3
#p mo lw 5
#p box lw 3
#p cap y lw 3
#p cap it lw 3
#p cap x lw 3
#
#p ux ke
#p uy fke
#p x lo
#p y lo
#p rx 0.3 10
#p ry 1e-2 300
#p se a
#p ba dis f
#p
#
## Remember to add strings to distinguish detectors
##
##### to save as ascii file run "plot adum file_name(.qdp)"
##
## plot adum ${i}_${1}_EPIC_RGS over
#
#p de cps ${i}_${1}_EPIC_RGS.ps
#p
#p clo 2
#
#p ux a
#p uy fa
#p x li
#p y li
#p rx 1 30
#p ry 0 5
#p
#
#p de cps ${i}_${1}_EPIC_RGS_Ang.ps
#p
#p clo 2
#
#da sh
#
#q
#EOF
#
#ps2pdf ${i}_${1}_EPIC_RGS.ps
#ps2pdf ${i}_${1}_EPIC_RGS_Ang.ps
#
#open ${i}_${1}_EPIC_RGS.pdf
#open ${i}_${1}_EPIC_RGS_Ang.pdf

fi

index=$(($index+1))

  cd ${DIR_work}
  shift
done

echo "Individual data reduction is over."

echo "———————————————————————— LEVEL 3.1 EPIC data reduction (stacking of images from all observations) ————————————————————————————"

#echo --------- Stacking EPIC MOS-pn images from all observations ----------
#
#cd ${DIR_work}/${SOURCE}/images_skycoord/
#
# rm images_list.txt
#
# echo  `find . -name '*_band_epic*.fits' | sort` > images_list.txt
#
# cat images_list.txt
#
# emosaic imagesets="`cat images_list.txt`" mosaicedset=${SOURCE}_EPIC_mosaic_epicband.fits
#
# /Applications/SAOImage\ DS9.app/Contents/MacOS/ds9 ${SOURCE}_EPIC_mosaic_epicband.fits -bin factor 2 \
#     -scale log -cmap b \
#     -contour yes -contour limits 1 100 \
#     -contour smooth 5 -contour nlevels 6 -contour save ds9.con &
#
#cd ..

############################### EPIC AND RGS SPECTRA STACKING ########################################################

echo "———————————————————————— LEVEL 3.2 EPIC data reduction (stacking of spectra from all observations) ———————————————————————————"

cd ${DIR_work}/${SOURCE}/spectra_stacks/epic

###### Rememver to Remove off-axis spectra to produce EPIC stacks matching on-axis RGS

# echo `find . -name "*PN_SRC1_src_spec.fits" | sort`   > srs_list_epicpn.txt
# echo `find . -name "*PN_BKG1_spec.fits" | sort`       > bkg_list_epicpn.txt
# echo `find . -name "*PN_SRC1_src.rmf" | sort`         > rmf_list_epicpn.txt
# echo `find . -name "*PN_SRC1_src.arf" | sort`         > arf_list_epicpn.txt
#
# echo `find . -name "*MOS1_SRC1_src_spec.fits" | sort` > srs_list_epicMOS1.txt
# echo `find . -name "*MOS1_BKG1_spec.fits" | sort`     > bkg_list_epicMOS1.txt
# echo `find . -name "*MOS1_SRC1_src.rmf" | sort`       > rmf_list_epicMOS1.txt
# echo `find . -name "*MOS1_SRC1_src.arf" | sort`       > arf_list_epicMOS1.txt
#
# echo `find . -name "*MOS2_SRC1_src_spec.fits" | sort` > srs_list_epicMOS2.txt
# echo `find . -name "*MOS2_BKG1_spec.fits" | sort`     > bkg_list_epicMOS2.txt
# echo `find . -name "*MOS2_SRC1_src.rmf" | sort`       > rmf_list_epicMOS2.txt
# echo `find . -name "*MOS2_SRC1_src.arf" | sort`       > arf_list_epicMOS2.txt
#
#   epicspeccombine pha="`cat srs_list_epicpn.txt`" \
#    bkg="`cat bkg_list_epicpn.txt`" \
#    rmf="`cat rmf_list_epicpn.txt`" \
#    arf="`cat arf_list_epicpn.txt`" \
#    filepha="epicpn_stacked_srs_allexp.fits" \
#    filebkg="epicpn_stacked_bkg_allexp.fits" \
#    filersp="epicpn_stacked_rmf_allexp.fits"
#
#   epicspeccombine pha="`cat srs_list_epicMOS1.txt`" \
#    bkg="`cat bkg_list_epicMOS1.txt`" \
#    rmf="`cat rmf_list_epicMOS1.txt`" \
#    arf="`cat arf_list_epicMOS1.txt`" \
#    filepha="epicMOS1_stacked_srs_allexp.fits" \
#    filebkg="epicMOS1_stacked_bkg_allexp.fits" \
#    filersp="epicMOS1_stacked_rmf_allexp.fits"
#
#   epicspeccombine pha="`cat srs_list_epicMOS2.txt`" \
#    bkg="`cat bkg_list_epicMOS2.txt`" \
#    rmf="`cat rmf_list_epicMOS2.txt`" \
#    arf="`cat arf_list_epicMOS2.txt`" \
#    filepha="epicMOS2_stacked_srs_allexp.fits" \
#    filebkg="epicMOS2_stacked_bkg_allexp.fits" \
#    filersp="epicMOS2_stacked_rmf_allexp.fits"
#
# specgroup spectrumset=epicpn_stacked_srs_allexp.fits mincounts=25 oversample=3 rmfset=epicpn_stacked_rmf_allexp.fits \
#            backgndset=epicpn_stacked_bkg_allexp.fits groupedset=epicpn_stacked_grp_allexp.fits
#
# specgroup spectrumset=epicMOS1_stacked_srs_allexp.fits mincounts=25 oversample=3 rmfset=epicMOS1_stacked_rmf_allexp.fits \
#            backgndset=epicMOS1_stacked_bkg_allexp.fits groupedset=epicMOS1_stacked_grp_allexp.fits
#
# specgroup spectrumset=epicMOS2_stacked_srs_allexp.fits mincounts=25 oversample=3 rmfset=epicMOS2_stacked_rmf_allexp.fits \
#            backgndset=epicMOS2_stacked_bkg_allexp.fits groupedset=epicMOS2_stacked_grp_allexp.fits

echo "Trafo convert EPIC stacked spectra to SPEX format"

### echo Remove old spo files as trafo cannot over-write
#
# rm epicMOS1_stacked_grp_allexp.res epicMOS2_stacked_grp_allexp.res epicpn_stacked_grp_allexp.res
# rm epicMOS1_stacked_grp_allexp.spo epicMOS2_stacked_grp_allexp.spo epicpn_stacked_grp_allexp.spo
#
#trafo<<EOF
#1
#1
#10000
#3
#16
#epicpn_stacked_grp_allexp.fits
#y
#y
#1
#n
#0
#epicpn_stacked_grp_allexp
#epicpn_stacked_grp_allexp
#EOF
#
#trafo<<EOF
#1
#1
#10000
#3
#16
#epicMOS1_stacked_grp_allexp.fits
#y
#y
#3e-5 5e-3
#1
#n
#0
#epicMOS1_stacked_grp_allexp
#epicMOS1_stacked_grp_allexp
#EOF
#
#trafo<<EOF
#1
#1
#10000
#3
#16
#epicMOS2_stacked_grp_allexp.fits
#y
#y
#3e-5 5e-3
#1
#n
#0
#epicMOS2_stacked_grp_allexp
#epicMOS2_stacked_grp_allexp
#EOF

echo "Open SPEX to plot only EPIC spectra"

#epic_data_dir=${DIR_work}/${SOURCE}/spectra_stacks/epic
#
#cd ${epic_data_dir}
#
#spex<<EOF
#da epicpn_stacked_grp_allexp   epicpn_stacked_grp_allexp
#da epicMOS1_stacked_grp_allexp epicMOS1_stacked_grp_allexp
#da epicMOS2_stacked_grp_allexp epicMOS2_stacked_grp_allexp
#
#ign ins  0:0.3 u ke
#ign ins 10:100 u ke
#
#p de xs
#p ty da
#
#p se 1
#p da col 1
#p li col 1
#p ba col 1
#p li dis t
#p se 2
#p da col 2
#p li col 2
#p ba col 2
#p li dis t
#p se 3
#p da col 3
#p li col 3
#p ba col 3
#p li dis t
#p se 4
#p da col 2
#p li col 2
#p ba col 2
#p li dis t
#p se 5
#p da col 3
#p li col 3
#p ba col 3
#
#p se al
#p ba dis t
#p mo dis f
#p ba lt 4
#p ba lw 3
#
##p ux a
##p uy fa
##p ry 0.0 0.4
##p rx 7.0 26
##p ux a
##p rx 2 28
##p
#
#p cap id text "${i} EPIC (all) stacked spectra"
#plot cap ut disp f
#plot cap lt disp f
#p da lw 3
#p mo lw 3
#p mo dis f
#p box lw 3
#p cap y lw 3
#p cap it lw 3
#p cap x lw 3
#
#p ux ke
#p x  lo
#p rx 0.3 10
#p uy fke
#p y lo
#p ry 1e-3 20
#p
#
#p de cps ${i}_Stack_EPIC_allexp.ps
#p
#p clo 2
#
#q
#EOF
#
#ps2pdf ${i}_Stack_EPIC_allexp.ps
#  open ${i}_Stack_EPIC_allexp.pdf

echo "———————————————————————— LEVEL 3.3 RGS data reduction (stacking of spectra from all observations) ————————————————————————————"

cd ${DIR_work}/${SOURCE}/spectra_stacks/rgs

### echo Remove old spo files as trafo cannot over-write
#
#rm `find . -name "rgs_stacked_srs_expbkg_allexp*"`
#rm `find . -name "rgs_stacked_srs_mbsbkg_allexp*"`
#
#echo "Stacking RGS order 1 spectra"
#
# echo ' '`find . -name 'P*R*SRSPEC100*.FIT' | sort` > src_list.txt
# echo ' '`find . -name 'P*R*BGSPEC100*.FIT' | sort` > bgs_list.txt
# echo ' '`find . -name 'P*R*RSPMAT100*.FIT' | sort` > rsp_list.txt
#
# rgscombine pha="`cat src_list.txt`" bkg="`cat bgs_list.txt`" rmf="`cat rsp_list.txt`" \
#            filepha="rgs_stacked_srs_allexp.fits" filermf="rgs_stacked_rmf_allexp.fits" \
#            filebkg="rgs_stacked_bgs_allexp.fits" rmfgrid=4000 > rgs_stacking.txt
#
#trafo << EOF
#1
#1
#10000
#3
#16
#`ls rgs_stacked_srs_allexp.fits`
#y
#no
#0
#rgs_stacked_srs_expbkg_allexp
#rgs_stacked_srs_expbkg_allexp
#EOF
#
# echo ' '`find . -name 'P*R*SRSPEC100*.FIT' | sort` > src_list.txt
# echo ' '`find . -name 'P*R*MBSPEC100*.FIT' | sort` > bkg_list.txt
# echo ' '`find . -name 'P*R*RSPMAT100*.FIT' | sort` > rsp_list.txt
#
# rgscombine pha="`cat src_list.txt`" bkg="`cat bkg_list.txt`" rmf="`cat rsp_list.txt`" \
#            filepha="rgs_stacked_srs_allexp.fits" filermf="rgs_stacked_rmf_allexp.fits" \
#            filebkg="rgs_stacked_bkg_allexp.fits" rmfgrid=4000 >> rgs_stacking.txt
#
#trafo << EOF
#1
#1
#10000
#3
#16
#`ls rgs_stacked_srs_allexp.fits`
#y
#no
#0
#rgs_stacked_srs_mbsbkg_allexp
#rgs_stacked_srs_mbsbkg_allexp
#EOF

# echo "Stacking RGS order 2 spectra"
#
# echo ' '`find . -name 'P*R*SRSPEC200*.FIT' | sort` > src_list_bgs.txt
# echo ' '`find . -name 'P*R*BGSPEC200*.FIT' | sort` > bgs_list_bgs.txt
# echo ' '`find . -name 'P*R*RSPMAT200*.FIT' | sort` > rsp_list_bgs.txt
#
# rgscombine pha="`cat src_list_bgs.txt`" bkg="`cat bgs_list_bgs.txt`" rmf="`cat rsp_list_bgs.txt`" \
#            filepha='rgs_stacked_srs_allexp_o2.fits' filermf='rgs_stacked_rmf_allexp_o2.fits' \
#            filebkg='rgs_stacked_bgs_allexp_o2.fits' rmfgrid=4000 > rgs_stacking_o2.txt
#
#trafo << EOF
#1
#1
#10000
#3
#16
#`ls rgs_stacked_srs_allexp_o2.fits`
#y
#no
#0
#rgs_stacked_srs_expbkg_allexp_o2
#rgs_stacked_srs_expbkg_allexp_o2
#EOF
#
# echo ' '`find . -name 'P*R*SRSPEC200*.FIT' | sort` > src_list_mbs.txt
# echo ' '`find . -name 'P*R*MBSPEC200*.FIT' | sort` > bkg_list_mbs.txt
# echo ' '`find . -name 'P*R*RSPMAT200*.FIT' | sort` > rsp_list_mbs.txt
#
# rgscombine pha="`cat src_list_mbs.txt`" bkg="`cat bkg_list_mbs.txt`" rmf="`cat rsp_list_mbs.txt`" \
#            filepha='rgs_stacked_srs_allexp_o2.fits' filermf='rgs_stacked_rmf_allexp_o2.fits' \
#            filebkg='rgs_stacked_bkg_allexp_o2.fits' rmfgrid=4000 >> rgs_stacking_o2.txt
#
#trafo << EOF
#1
#1
#10000
#3
#16
#`ls rgs_stacked_srs_allexp_o2.fits`
#y
#no
#0
#rgs_stacked_srs_mbsbkg_allexp_o2
#rgs_stacked_srs_mbsbkg_allexp_o2
#EOF

echo "Binning the RGS order 1 spectra by signal to noise or just PSF: need updating INSTRUME keyword"

#  fparkey "RGS1" "rgs_stacked_srs_allexp.fits[0]" INSTRUME add=yes
#
#  specgroup spectrumset="rgs_stacked_srs_allexp.fits" oversample=3 \
#             backgndset="rgs_stacked_bgs_allexp.fits" \
#                 rmfset="rgs_stacked_rmf_allexp.fits" \
#             groupedset="rgs_stacked_srs_bgs_grp_allexp.fits"
#
#  specgroup spectrumset="rgs_stacked_srs_allexp.fits" oversample=3 \
#             backgndset="rgs_stacked_bkg_allexp.fits" \
#                 rmfset="rgs_stacked_rmf_allexp.fits" \
#             groupedset="rgs_stacked_srs_bkg_grp_allexp.fits"
#
#rm rgs_stacked_srs_bgs_grp_allexp.spo rgs_stacked_srs_bgs_grp_allexp.res
#rm rgs_stacked_srs_bkg_grp_allexp.spo rgs_stacked_srs_bkg_grp_allexp.res
#
#trafo << EOF
#1
#1
#10000
#3
#16
#rgs_stacked_srs_bgs_grp_allexp.fits
#y
#y
#no
#0
#rgs_stacked_srs_bgs_grp_allexp
#rgs_stacked_srs_bgs_grp_allexp
#EOF
#
#trafo << EOF
#1
#1
#10000
#3
#16
#rgs_stacked_srs_bkg_grp_allexp.fits
#y
#y
#no
#0
#rgs_stacked_srs_bkg_grp_allexp
#rgs_stacked_srs_bkg_grp_allexp
#EOF

echo "Binning the RGS order 2 spectra by signal to noise or just PSF: need updating INSTRUME keyword"

#  fparkey "RGS1" "rgs_stacked_srs_allexp_o2.fits[0]" INSTRUME add=yes
#
#  specgroup spectrumset="rgs_stacked_srs_allexp_o2.fits" oversample=3 \
#             backgndset="rgs_stacked_bgs_allexp_o2.fits" \
#                 rmfset="rgs_stacked_rmf_allexp_o2.fits" \
#             groupedset="rgs_stacked_srs_bgs_grp_allexp_o2.fits"
#
#  specgroup spectrumset="rgs_stacked_srs_allexp_o2.fits" oversample=3 \
#             backgndset="rgs_stacked_bkg_allexp_o2.fits" \
#                 rmfset="rgs_stacked_rmf_allexp_o2.fits" \
#             groupedset="rgs_stacked_srs_bkg_grp_allexp_o2.fits"
#
#rm rgs_stacked_srs_bgs_grp_allexp_o2.spo rgs_stacked_srs_bgs_grp_allexp_o2.res
#rm rgs_stacked_srs_bkg_grp_allexp_o2.spo rgs_stacked_srs_bkg_grp_allexp_o2.res
#
#trafo << EOF
#1
#1
#10000
#3
#16
#rgs_stacked_srs_bgs_grp_allexp_o2.fits
#y
#y
#no
#0
#rgs_stacked_srs_bgs_grp_allexp_o2
#rgs_stacked_srs_bgs_grp_allexp_o2
#EOF
#
#trafo << EOF
#1
#1
#10000
#3
#16
#rgs_stacked_srs_bkg_grp_allexp_o2.fits
#y
#y
#no
#0
#rgs_stacked_srs_bkg_grp_allexp_o2
#rgs_stacked_srs_bkg_grp_allexp_o2
#EOF

echo "Open SPEX to plot only RGS stacked spectra (only on-axis observations)"

epic_data_dir=${DIR_work}/${SOURCE}/spectra_stacks/epic # ALL EXPO (/epic_allexp/) or ONAXIS EXPO (/epic/)

#spex<<EOF
#
# da rgs_stacked_srs_bgs_grp_allexp_o2 rgs_stacked_srs_bgs_grp_allexp_o2
# da rgs_stacked_srs_bkg_grp_allexp_o2 rgs_stacked_srs_bkg_grp_allexp_o2
#
# ign ins 1:2  0:6     u a
# ign ins 1:2 27:40    u a
# bin ins 1:2  6:27  6 u a
#
# da rgs_stacked_srs_bgs_grp_allexp rgs_stacked_srs_bgs_grp_allexp
# da rgs_stacked_srs_bkg_grp_allexp rgs_stacked_srs_bkg_grp_allexp
#
# ign ins 3:4  0:6     u a
# ign ins 3:4 27:40    u a
# bin ins 3:4  6:27 3  u a
#
# da ${epic_data_dir}/epicpn_stacked_grp_allexp   ${epic_data_dir}/epicpn_stacked_grp_allexp
# da ${epic_data_dir}/epicMOS1_stacked_grp_allexp ${epic_data_dir}/epicMOS1_stacked_grp_allexp
# da ${epic_data_dir}/epicMOS2_stacked_grp_allexp ${epic_data_dir}/epicMOS2_stacked_grp_allexp
#
# ign ins 5:7  0:0.4 u ke
# ign ins 5:7 10:100 u ke
#
#p de xs
#p ty da
#
#p se 1
#p da col 11
#p li col 11
#p ba col 11
#p li dis t
#p se 2
#p da col 14
#p li col 14
#p ba col 14
#p li dis t
#p se 3
#p da col 1
#p li col 1
#p ba col 1
#p li dis t
#p se 4
#p da col 2
#p li col 2
#p ba col 2
#p li dis t
#p se 5
#p da col 3
#p li col 3
#p ba col 3
#p li dis t
#p se 6
#p da col 3
#p li col 3
#p ba col 3
#p li dis t
#p se 7
#p da col 3
#p li col 3
#p ba col 3
#p li dis t
#
#p se al
#p ba dis f
#p mo dis f
#p ba lt 4
#p ba lw 3
#
#plot cap id text "${i} EPIC (all) and RGS (onaxis) stacked spectra"
#plot cap ut disp f
#plot cap lt disp f
#p da lw 3
#p mo lw 5
#p box lw 3
#p cap y lw 3
#p cap it lw 3
#p cap x lw 3
#
#p ux a
#p uy fa
#p rx 2 28
#p ry 0 0.8
#p
#
## slightly shifting the RGS spectra updwards
#
#shiftplot instrument 1:4 region 1 2 1.1
#
## Ignoring RGS model background spectra (bad epic match)
#
#ign ins 2 reg 1 0:100 u a
#ign ins 4 reg 1 0:100 u a
#
#p de cps ${i}_Stack_EPIC_RGS_allexp_Ang.ps
#p
#p clo 2
#
##p ux ke
##p uy fke
##p x lo
##p y lo
##p rx 0.4 10
##p ry 1e-3 20
##
##p de cps ${i}_Stack_EPIC_RGS_allexp.ps
##p
##p clo 2
#
##da sh
##
##p uy cou
##p y lo
##p ry 1 1e4
##p
#
#q
#EOF
#
#ps2pdf ${i}_Stack_EPIC_RGS_allexp_Ang.ps
## open ${i}_Stack_EPIC_RGS_allexp_Ang.pdf
#
#ps2pdf ${i}_Stack_EPIC_RGS_allexp.ps
## open ${i}_Stack_EPIC_RGS_allexp.pdf

echo 'The data reduction routine is over.'

cd ${DIR_work}

date > Info_ending_time.txt 
T="$(($(date +%s)-T))"
cat Info_starting_time.txt
cat Info_ending_time.txt
echo "Time elapsed: ${T} sec"
echo "Time elapsed: "$(($T/60))"+ min"
