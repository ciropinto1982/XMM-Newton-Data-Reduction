#!/bin/bash

########################################## ROUTINE DESCRIPTION ###########################################################
####                                                                                                                  ####
#### This bash code performs an XMM-Newton full and basic data reduction for a single source and exposure             ####
####                                                                                                                  ####
#### 1) Provide source name and exposure and, importantly, the ODF (raw data) directory and sub-directory             ####
####    Here we adopt the following structure:                                                                        ####
####    ${PWD} is the local directory and the launching directory, ${PWD}/SOURCE_NAME/ contains all the data          ####
####    ${PWD}/SOURCE_NAME/odf contains the data, the code will put the products into ${PWD}/SOURCE_NAME/pps          ####
####    More detail on the directory structure is provided below, see "DIR_work"                                      ####
####                                                                                                                  ####
#### 2) The code will automatically create the necessary sub-directories (apart from the ODF) and run XMM-SAS         ####
####    Each task's output is stored in file called "log_***.txt" so that the detail calculation can be checked.      ####
####                                                                                                                  ####
#### 3) At first it runs the ODF basic routines (cifduild, odfingest) and then EPPROC, EMPROC, RGSPROC, OMCHAIN       ####
####                                                                                                                  ####
#### 4) Then you will need to open the EPIC/MOS & pn event files or images to chose & load the extraction regions     ####
####    for source & background, this is necessary to run the second part to extract spectra and lightcurves.         ####
####                                                                                                                  ####
#### 5) The code also converts the spectra in SPEX format (if SPEX is installed), opens the spectra & saves plots     ####
####                                                                                                                  ####
#### NOTE: all main commands have been disabled with a single "#"; uncomment & launch each one as first exercise      ####
####                                                                                                                  ####
#### There are 4 levels: 0=ODF individual processing, 1=event files, 2=clean products, 3=stacking observations        ####
####                                                                                                                  ####
#### Sometimes XMM/SAS will give warnings like "** odfingest: warning", most are OK. Take care for ** error **        ####
####                                                                                                                  ####
####   License: This public code was developed for and published in the paper Pinto et al. (2017),                    ####
####   DOI: 10.1093/mnras/stx641, arXiv: 1612.05569, bibcode: 2017MNRAS.468.2865P. You may refer to this              ####
####   when using this code, especially to compare the spectra and lightcurves that you make using it.                ####
####                                                                                                                  ####
##########################################################################################################################

############################### DEFINE DIRECTORIES & ENVIRONMENT VARIABLES ###############################################

echo " SET HEASOFT: heainit"                                         # Initialise HASOFT manually typing "heainit"
echo " SET XMM-SAS: setsas or"                                       # Initialise XMMSAS manually typing "setsas"
echo " SET XMM-SAS: source /PATH/TO/YOUR/SAS/VERSION/setsas.sh"      #                 ... or your full executable
echo " SET XMM-SAS: SAS_CCFPATH=/PATH/TO/YOUR/SAS/ccf_files"         # Indicate the path to the XMM CALDB
echo " SET XMM-SAS: CALDB downloaded from: https://www.cosmos.esa.int/web/xmm-newton/current-calibration-files"
echo " SET XMM-XSA: ODF's downloaded from: https://nxsa.esac.esa.int/nxsa-web/#search"

DIR_work=$PWD               # The current directory, i.e. the launching and working directory

cd ${DIR_work}              # This "cd" is necessary only if the working dorectory is a different one

### This code assumes, for simplicity, that the data are stored according to the following layout:
###
### /DIR_work/
### /DIR_work/SOURCE_NAME
### /DIR_work/SOURCE_NAME/EXPOSURE
### /DIR_work/SOURCE_NAME/EXPOSURE/odf (this sub-directory is assumed as downloaded from XMM-Newton/XSA webarchive)
### /DIR_work/SOURCE_NAME/EXPOSURE/pps (this sub-directory is created by the code once the source list is provided)

############################### SOURCE & EXPOSURE LISTS READING ##########################################################
###
### In this example we assume the following directory (sub) structure:
###
###   DIR_work=${PWD}
### ${DIR_work}/NGC55
### ${DIR_work}/NGC55/0655050101
### ${DIR_work}/NGC55/0655050101/odf (this sub-directory is just as downloaded from XMM-Newton / XSA web archive)
### ${DIR_work}/NGC55/0655050101/pps (this sub-directory is created by the code once the source list is provided)

SOURCE_NAME=NGC55        # Give the source (and directory) name to the environment variables SOURCE_NAME and i
EXPOSURE=0655050101      # Give the exposure (and sub-directory) name to the environment variables EXPOSURE and j

i=${SOURCE_NAME}         # This is just to simply and shorten the nomenclature (necessary)
j=${EXPOSURE}            # This is just to simply and shorten the nomenclature (necessary)

 echo "I am working on Source ${i} and Exposure ${j}"

############################### CREATING STRUCTURE OF SUB-DIRECTORIES ####################################################

# mkdir ${DIR_work}/${i}/${j}/odf # This is principle should have been created at the moment of the XSA data download.
  mkdir ${DIR_work}/${i}/${j}/pps

############################### START TO WORK ON THE ODF RAW DATA FILES ##################################################

echo "————————————————— LEVEL 0.0 cifbuild, odfingest (create summary and calibration files) ————————————————————————————"

# echo "Going to the ODF directory"

cd ${DIR_work}/${i}/${j}/odf/
   
#  echo "Uncompressing ODF files" # Ignore this commands if you have already uncompressed the ODF files.
#
#  tar -xf `find . -name '*.tar.gz'`                     # Uncompress 1st level archive (downloaded file)
#  tar -xf `find . -name '*.TAR'`                        # Uncompress 2nd level archive (from this above)
#  
###  rm  `find . -name '*TAR'`                           # Don't delete archives before checking directory contents
###  rm  `find . -name '*.tar.gz'`                       # Don't delete archives before checking directory contents

### echo "SUM files: `find . -name '*SUM.*'`"            # Checking availabe ODF-SUM files

###  rm `find . -name '*SUM.SAS'`                        # this is to remove old SUM.SAS files

export SAS_ODF=$PWD                                      # IMPORTANT: readin ODF directory                     (necessary)
export SAS_CCFPATH=/PATH/TO/YOUR/SAS/CCF/FILES           # IMPORTANT: update CCF CALDB DIR                     (necessary)
export SAS_VERBOSITY=1                                   # OPTION   : choose verbosity level       (detail of information)

#cifbuild -V 1 > cifbuild_log.txt   # The command ">" dump all the terminal content into ascii file cifbuild_log.txt

export SAS_CCF=$PWD/ccf.cif                              # Updating CCF file location and environment variable (necessary)

#odfingest -V 1 > odfingest_log.txt # The command ">" dump all the terminal content into ascii file odfingest_log.txt

echo "SAS ODF file: `find . -name '*SUM.SAS'`"           # Checking outcome of ofingest run: SUM file

SAS_ODF_FILE=$(find . -name '*SUM.SAS')                  # Reading location of the ODF-SUMMARY file            (necessary)
SAS_ODF_FILE=${SAS_ODF_FILE:2}                           # Removing initial two characters "./" of filename    (necessary)
  
export SAS_ODF=${DIR_work}/${i}/${j}/odf                 # Updating ODF file location and environment variable (necessary)
export SAS_CCF=$SAS_ODF/ccf.cif                          # Updating CCF file location and environment variable (necessary)
export SAS_ODF=${DIR_work}/${i}/${j}/odf/${SAS_ODF_FILE} # Updating ODF file location and environment variable (necessary)

 echo "SAS_CCF: $SAS_CCF"                                # Checking CCF file and environment variable
 echo "SAS_ODF: $SAS_ODF"                                # Checking ODF file and environment variable

# echo "Going to the PPS directory"

cd ${DIR_work}/${i}/${j}/pps/

############################### START TO CREATE DATA PRODUCTS (EVENT FILES) ##############################################

echo "————————————————— LEVEL 1.0 rgsproc, epproc, omchain (create event files) —————————————————————————————————————————"

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

############################### CLEAN THE EVENT LISTS TO PRODUCE CLEAN DATA ##############################################
###
### IMPORTANT: in order to open the plots with dsplot you must have setup XMGRACE correctly

echo "————————————— LEVEL 2.1 EPIC filtering data for solar flares, extract images & spectra (evselect) —————————————————"

echo "Filtering EPIC MOS 1,2 and pn for solar flares" # provide the count rate thresholds in c/s i.e. [0.35,0.35,0.5]

#echo "-------Extracting lightcurves: ----------------- MOS 1" # Note that command ">>" attach output to previous file
#
# evselect table="mos1.fits:EVENTS" withrateset=Y rateset=mos1_lc.fits \
#  timecolumn=TIME maketimecolumn=Y timebinsize=100 makeratecolumn=Y \
#  expression='#XMMEA_EM && (PI>10000) && (PATTERN==0)' -V 1 >> log_fl.txt
#
# # dsplot table=mos1_lc.fits x=TIME y=RATE &
#
# tabgtigen table=mos1_lc.fits  expression="(RATE < 0.35)" gtiset=mos1_gti.fits  -V 1 >> log_fl.txt
#
# evselect table="mos1.fits:EVENTS" withfilteredset=Y filteredset=mos1_filtered.fits destruct=Y keepfilteroutput=T \
# expression='#XMMEA_EM && gti(mos1_gti.fits,TIME) && (PI in [300:10000]) && (PATTERN<=12)' -V 1 >> log_fl.txt
#
#echo "-------Extracting lightcurves: ----------------- MOS 2"
#
# evselect table="mos2.fits:EVENTS" withrateset=Y rateset=mos2_lc.fits \
#  timecolumn=TIME maketimecolumn=Y timebinsize=100 makeratecolumn=Y \
#  expression='#XMMEA_EM && (PI>10000) && (PATTERN==0)' -V 1 >> log_fl.txt
#
# # dsplot table=mos2_lc.fits x=TIME y=RATE &
#
# tabgtigen table=mos2_lc.fits  expression="(RATE < 0.35)" gtiset=mos2_gti.fits  -V 1 >> log_fl.txt
#
# evselect table="mos2.fits:EVENTS" withfilteredset=Y filteredset=mos2_filtered.fits destruct=Y keepfilteroutput=T \
# expression='#XMMEA_EM && gti(mos2_gti.fits,TIME) && (PI in [300:10000]) && (PATTERN<=12)' -V 1 >> log_fl.txt
#
#echo "-------Extracting lightcurves: ----------------- PN"
#
# evselect table="pn.fits:EVENTS" withrateset=Y rateset=pn_lc.fits \
#  timecolumn=TIME maketimecolumn=Y timebinsize=100 makeratecolumn=Y \
#  expression='#XMMEA_EP && (PI>10000&&PI<12000) && (PATTERN==0)' -V 1 >> log_fl.txt
#
# # dsplot table=pn_lc.fits x=TIME y=RATE &
#
# tabgtigen table=pn_lc.fits  expression="(RATE < 0.5)" gtiset=pn_gti.fits  -V 1 >> log_fl.txt
#
# evselect table="pn.fits:EVENTS" withfilteredset=Y filteredset=pn_filtered.fits destruct=Y keepfilteroutput=T \
# expression='#XMMEA_EP && gti(pn_gti.fits,TIME) && (PI in [300:10000]) && (PATTERN<=4) && (FLAG==0)' -V 1 >> log_fl.txt

############################### EPIC IMAGE, SPECTRA AND LIGHTCURVE EXTRACTION ############################################

echo "Extracting MOS 1,2 and pn images in SKY coordinates" # provide energy band limits in eV e.g. 300:10000 [eV]

# evselect table=mos1_filtered.fits expression="(PI in [300:10000])" \
#          filtertype=expression imageset=mos1_image_0310keV.fits \
#          xcolumn=X ycolumn=Y ximagebinsize=80 yimagebinsize=80 \
#          ximagesize=600 yimagesize=600 imagebinning=binSize withimageset=yes > my_images_log.txt
#
# evselect table=mos2_filtered.fits expression="(PI in [300:10000])" \
#          filtertype=expression imageset=mos2_image_0310keV.fits \
#          xcolumn=X ycolumn=Y ximagebinsize=80 yimagebinsize=80 \
#          ximagesize=600 yimagesize=600 imagebinning=binSize withimageset=yes >> my_images_log.txt
#
# evselect table=pn_filtered.fits expression="(PI in [300:10000])" \
#          filtertype=expression imageset=pn_image_0310keV.fits \
#          xcolumn=X ycolumn=Y ximagebinsize=80 yimagebinsize=80 \
#          ximagesize=600 yimagesize=600 imagebinning=binSize withimageset=yes >> my_images_log.txt

echo "Stacking EPIC MOS-pn images from different detectors" # provide a list (images_list.txt) of images

#rm images_list.txt
#
#echo  `find . -name '*_image_0310keV.fits' | sort` > images_list.txt
#
#cat images_list.txt
#
#emosaic imagesets="`cat images_list.txt`" mosaicedset=epic_image_0310keV.fits
#
### IMPORTANT: to view the image as done here you need to have "ds9" installed on you pc.
#
#ds9 epic_image_0310keV.fits -bin factor 2 -scale log -cmap b -contour yes -contour limits 1 100 \
#                            -contour smooth 5 -contour nlevels 6 -contour save ds9.con
#
#/Applications/SAOImage\ DS9.app/Contents/MacOS/ds9 epic_image_0310keV.fits -bin factor 2 -scale log \
#-cmap b -contour yes -contour limits 1 100 -contour smooth 5 -contour nlevels 6 -contour save ds9.con &

echo "IMPORTANT: for EPIC MOS-PN spectra extraction, OPEN EACH IMAGE OR EVENT FILE & SELECT COORDINATES!"

### <<<<<<<<< THIS SPECIFIC PART OF PROVIDING THE COORDINATES IS INTERACTIVE! >>>>>>>>>
###
### Here you need to open an image or an event file for <<<EACH>>> detector to find out the ideal coordinates
### the example shows circular regions for source and background spectra and lightcurve extraction.
###
### IMPORTANT: when opening the images with e.g. ds9, select the coordinates in PHYSICAL format (see below).
###            and fill in expression=".... && (PATTERN<=....) && ((X,Y) IN circle(SKY-X,SKY-Y,RADIUS))" as below
###            make sure that both source and background regions are OK for MOS 1,2 and pn (i.e. out of chip gaps)
###            Also, the coordinates from the stacked images will not work out as they aren't physical.
###
### For instance, let's open with ds9 the image files:
###              "ds9 mos1_image_0310keV.fits mos2_image_0310keV.fits pn_image_0310keV.fits &"
###
###               And from the panels, select "SCALE->LOG" for all, and "EDIT->REGION"
###
### coordinate_SRC="(24038.473,25244.649,400)"  # 20 arcsec radius NGC 55 ULX-1 (source) observation 0655050101
### coordinate_BKG="(23972.946,28093.003,1000)" # 50 arcsec radius NGC 55 ULX-1 (backgr) observation 0655050101
###
### These regions will be OK for both EPIC MOS 1,2 and pn (same chip and out of chip gaps):

coordinate_SRC="(24038.473,25244.649,400)"  # do not comment this line unless you past the coordinates in evselect
coordinate_BKG="(23972.946,28093.003,1000)" # do not comment this line unless you past the coordinates in evselect

echo "Extraction of EPIC spectra for coordinates: ${coordinate_SRC} and ${coordinate_BKG}"

# echo "Extracting source and background spectra:"
#
# evselect table=mos1_filtered.fits withspectrumset=yes spectrumset=MOS1_SRC_spec.fits \
#   energycolumn=PI spectralbinsize=5 withspecranges=yes specchannelmin=0 specchannelmax=11999 \
#   expression="#XMMEA_EM && (PATTERN<=12) && ((X,Y) IN circle${coordinate_SRC})" -V 1 > log_epic_spectra.txt
#
# evselect table=mos1_filtered.fits withspectrumset=yes spectrumset=MOS1_BKG_spec.fits \
#   energycolumn=PI spectralbinsize=5 withspecranges=yes specchannelmin=0 specchannelmax=11999 \
#   expression="#XMMEA_EM && (PATTERN<=12) && ((X,Y) IN circle${coordinate_BKG})" -V 1 >> log_epic_spectra.txt
#
# # dsplot table=MOS1_SRC_spec.fits x=CHANNEL y=COUNTS &
# # dsplot table=MOS1_BKG_spec.fits x=CHANNEL y=COUNTS &
#
# evselect table=mos2_filtered.fits withspectrumset=yes spectrumset=MOS2_SRC_spec.fits \
#   energycolumn=PI spectralbinsize=5 withspecranges=yes specchannelmin=0 specchannelmax=11999 \
#   expression="#XMMEA_EM && (PATTERN<=12) && ((X,Y) IN circle${coordinate_SRC})" -V 1 >> log_epic_spectra.txt
#
# evselect table=mos2_filtered.fits withspectrumset=yes spectrumset=MOS2_BKG_spec.fits \
#   energycolumn=PI spectralbinsize=5 withspecranges=yes specchannelmin=0 specchannelmax=11999 \
#   expression="#XMMEA_EM && (PATTERN<=12) && ((X,Y) IN circle${coordinate_BKG})" -V 1 >> log_epic_spectra.txt
#
# #dsplot table=MOS2_SRC_spec.fits x=CHANNEL y=COUNTS &
# #dsplot table=MOS2_BKG_spec.fits x=CHANNEL y=COUNTS &
#
# evselect table=pn_filtered.fits withspectrumset=yes spectrumset=PN_SRC_spec.fits \
#   energycolumn=PI spectralbinsize=5 withspecranges=yes specchannelmin=0 specchannelmax=20479 \
#   expression="(FLAG==0) && (PATTERN<=4) && ((X,Y) IN circle${coordinate_SRC})" -V 1 >> log_epic_spectra.txt
#
# evselect table=pn_filtered.fits withspectrumset=yes spectrumset=PN_BKG_spec.fits \
#   energycolumn=PI spectralbinsize=5 withspecranges=yes specchannelmin=0 specchannelmax=20479 \
#   expression="(FLAG==0) && (PATTERN<=4) && ((X,Y) IN circle${coordinate_BKG})" -V 1 >> log_epic_spectra.txt
#
# # dsplot table=PN_SRC_spec.fits x=CHANNEL y=COUNTS &
# # dsplot table=PN_BKG_spec.fits x=CHANNEL y=COUNTS &

# echo "Calculating / scaling sourcne and background regions areas: will update the SRC/BKG spectra info"
#
# backscale spectrumset=MOS1_SRC_spec.fits badpixlocation=mos1_filtered.fits >> log_epic_spectra.txt
# backscale spectrumset=MOS1_BKG_spec.fits badpixlocation=mos1_filtered.fits >> log_epic_spectra.txt
# backscale spectrumset=MOS2_SRC_spec.fits badpixlocation=mos2_filtered.fits >> log_epic_spectra.txt
# backscale spectrumset=MOS2_BKG_spec.fits badpixlocation=mos2_filtered.fits >> log_epic_spectra.txt
# backscale spectrumset=PN_SRC_spec.fits badpixlocation=pn_filtered.fits     >> log_epic_spectra.txt
# backscale spectrumset=PN_BKG_spec.fits badpixlocation=pn_filtered.fits     >> log_epic_spectra.txt

# echo "Calculating response matrices (takes a bit long) and eff area"
#
#  rmfgen spectrumset=MOS1_SRC_spec.fits rmfset=MOS1_SRC.rmf >> log_epic_spectra.txt
#  arfgen spectrumset=MOS1_SRC_spec.fits arfset=MOS1_SRC.arf withrmfset=yes rmfset=MOS1_SRC.rmf \
#         badpixlocation=mos1_filtered.fits detmaptype=psf >> log_epic_spectra.txt
#  rmfgen spectrumset=MOS2_SRC_spec.fits rmfset=MOS2_SRC.rmf >> log_epic_spectra.txt
#  arfgen spectrumset=MOS2_SRC_spec.fits arfset=MOS2_SRC.arf withrmfset=yes rmfset=MOS2_SRC.rmf \
#         badpixlocation=mos2_filtered.fits detmaptype=psf >> log_epic_spectra.txt
#  rmfgen spectrumset=PN_SRC_spec.fits rmfset=PN_SRC.rmf >> log_epic_spectra.txt
#  arfgen spectrumset=PN_SRC_spec.fits arfset=PN_SRC.arf withrmfset=yes rmfset=PN_SRC.rmf \
#         badpixlocation=pn_filtered.fits detmaptype=psf >> log_epic_spectra.txt

# echo "Binning the spectra to enable Chi2: remember to bin also on resolution i.e. oversample=3."
#
#  specgroup spectrumset=MOS1_SRC_spec.fits mincounts=25 oversample=3 rmfset=MOS1_SRC.rmf arfset=MOS1_SRC.arf \
#             backgndset=MOS1_BKG_spec.fits groupedset=MOS1_SRC_spec_grp25.fits >> log_epic_spectra.txt
#  specgroup spectrumset=MOS2_SRC_spec.fits mincounts=25 oversample=3 rmfset=MOS2_SRC.rmf arfset=MOS2_SRC.arf \
#             backgndset=MOS2_BKG_spec.fits groupedset=MOS2_SRC_spec_grp25.fits >> log_epic_spectra.txt
#  specgroup spectrumset=PN_SRC_spec.fits mincounts=25 oversample=3 rmfset=PN_SRC.rmf arfset=PN_SRC.arf \
#             backgndset=PN_BKG_spec.fits groupedset=PN_SRC_spec_grp25.fits >> log_epic_spectra.txt
#
#  dsplot table=MOS1_SRC_spec_grp25.fits x=CHANNEL y=COUNTS &
#  dsplot table=MOS2_SRC_spec_grp25.fits x=CHANNEL y=COUNTS &
#  dsplot table=PN_SRC_spec_grp25.fits   x=CHANNEL y=COUNTS &

echo "Trafo converting EPIC spectra to SPEX format (SPO/RES fits format)"

### IMPORTANT: TRAFO does not over-write pre-existing files, if you have already converted some spectra
###            either change the output SPO/RES names or delete the previous spectra like this below:
###            rm MOS1_SRC_spec_grp25.spo MOS1_SRC_spec_grp25.res etc.
#
#trafo<<EOF
#1
#1
#10000
#3
#16
#MOS1_SRC_spec_grp25.fits
#y
#y
#3.E-5 5.E-3
#1
#0
#MOS1_SRC_spec_grp25
#MOS1_SRC_spec_grp25
#EOF
#
#trafo<<EOF
#1
#1
#10000
#3
#16
#MOS2_SRC_spec_grp25.fits
#y
#y
#3.E-5 5.E-3
#1
#0
#MOS2_SRC_spec_grp25
#MOS2_SRC_spec_grp25
#EOF
#
#trafo<<EOF
#1
#1
#10000
#3
#16
#PN_SRC_spec_grp25.fits
#y
#y
#1
#0
#PN_SRC_spec_grp25
#PN_SRC_spec_grp25
#EOF

echo "Open SPEX to plot the EPIC spectra (you need to have SPEX installed)."

#spex<<EOF
# da PN_SRC_spec_grp25 PN_SRC_spec_grp25
# da MOS1_SRC_spec_grp25 MOS1_SRC_spec_grp25
# da MOS2_SRC_spec_grp25 MOS2_SRC_spec_grp25
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
# p ry 1e-3 20
# p se a
# p li dis t
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
# p cap id text "${i} ${j} EPIC spectra: PN (b/w) MOS1 (r) MOS2 (g) BKG (blue)"
# p cap id disp t
# p cap ut disp f
# p cap lt disp f
# p
# p de cps ${i}_${j}_EPIC_keV.ps
# p
# p clo 2
# q
#EOF

#echo "Converting SPEX output plot from postscript to PDF and open it:"
#
#ps2pdf ${i}_${j}_EPIC_keV.ps
#open   ${i}_${j}_EPIC_keV.pdf

echo "————————————————— LEVEL 2.2 EPIC (pn) TIMING: extract lightcurves within an energy range ——————————————————————————"

echo "Extracting PN lightcurves (raw and corrected)" # provide energy band limits e.g. 300:10000 [eV] as for spectra.

echo "Extracting PN lightcurves with binsize ${timebinsize}" # provide also the time binsize in seconds e.g. 1000 (1ks)

# evselect table=pn_filtered.fits energycolumn=PI \
#     expression="(FLAG==0) && (PATTERN<=4) && ((X,Y) IN circle${coordinate_SRC}) && (PI in [300:10000])" \
#     withrateset=yes rateset=PN_src_lightcurve_raw_0310keV.lc timebinsize=1000 \
#     maketimecolumn=yes makeratecolumn=yes > log_lightcurve.txt
#
# evselect table=pn_filtered.fits energycolumn=PI \
#     expression="(FLAG==0) && (PATTERN<=4) && ((X,Y) IN circle${coordinate_BKG}) && (PI in [300:10000])" \
#     withrateset=yes rateset=PN_bkg_lightcurve_raw_0310keV.lc timebinsize=1000 \
#     maketimecolumn=yes makeratecolumn=yes >> log_lightcurve.txt
#
##    dsplot table=PN_src_lightcurve_raw_0310keV.lc withx=yes x=TIME withy=yes y=RATE &
##    dsplot table=PN_bkg_lightcurve_raw_0310keV.lc withx=yes x=TIME withy=yes y=RATE &

### Correting the lightcurves for detector quantum efficiency and other properties with epiclccorr:
#
#    epiclccorr srctslist=PN_src_lightcurve_raw_0310keV.lc eventlist=pn_filtered.fits \
#               bkgtslist=PN_bkg_lightcurve_raw_0310keV.lc withbkgset=yes applyabsolutecorrections=yes \
#                  outset=PN_lccorr_0310keV.lc >> log_lightcurve.txt
#
#    dsplot table=PN_lccorr_0310keV.lc withx=yes x=TIME withy=yes y=RATE &

### Use dstoplot to dump the lightcurve into an ascii file!
#
#dstoplot table=PN_lccorr_0310keV.lc withx=yes x=TIME withy=yes y=RATE.ERROR \
#        output=file outputfile=PN_lccorr_0310keV.txt >> log_lightcurve.txt

### Plot only one lightcurve with QDP/PLT: adopt a sleeping time of 1 second if window closes too quickly
###
### QDP plotting is part of HEASOFT and (of course) needs the x-windows to be enabled.
#
#qdp << EOF
#PN_lccorr_0310keV.txt
#/xs
#p
#q
#EOF
#
##sleep 1

############################### RGS DATA CLEANING, 1D IMAGE ABD SPECTRA EXTRACTION #######################################

echo "————————————————— LEVEL 2.3 RGS data reduction (BKG flaring, PSF selection and stacking) ——————————————————————————"

#echo "RGS1,2 Extracting information and exposure detail from the eventlist file:"

R1_EVE=`find . -name '*R1*EVENLI*'` # Search for the RGS 1 event file (created by rgsproc) - do not comment this line
R2_EVE=`find . -name '*R2*EVENLI*'` # Search for the RGS 2 event file (created by rgsproc) - do not comment this line

R1_EVE=${R1_EVE:2} # Removing initial two characters "./" of filename                      - do not comment this line
R2_EVE=${R2_EVE:2} # Removing initial two characters "./" of filename                      - do not comment this line

   did=${R1_EVE:0:11} # Read deteail on the exposure e.g. "P0655050101"                    - do not comment this line
expno1=${R1_EVE:13:4} # Read deteail on the RGS1 detector e.g. "R1S004"                    - do not comment this line
expno2=${R2_EVE:13:4} # Read deteail on the RGS2 detector e.g. "R1S005"                    - do not comment this line

srcid=1 # source id number. For standard rgsproc will be =1, if you instead had provided RA,DEC to rgsproc it will be =3.

#echo "RGS 1,2 background lightcurve extraction: necessary for solar flare subtraction"
#
# evselect table="${did}R1${otype}${expno1}EVENLI0000.FIT:EVENTS" makeratecolumn=yes \
#	      maketimecolumn=yes timecolumn=TIME timebinsize=100 \
# expression="(CCDNR == 9) && ((M_LAMBDA,XDSP_CORR) in REGION(${did}R1${otype}${expno1}SRCLI_0000.FIT:RGS1_BACKGROUND))" \
#          rateset=rgs1_bglc.fits > rgs_flaring.txt
# evselect table="${did}R2${otype}${expno2}EVENLI0000.FIT:EVENTS" makeratecolumn=yes \
#          maketimecolumn=yes timecolumn=TIME timebinsize=100 \
# expression="(CCDNR == 9) && ((M_LAMBDA,XDSP_CORR) in REGION(${did}R2${otype}${expno2}SRCLI_0000.FIT:RGS2_BACKGROUND))" \
#          rateset=rgs2_bglc.fits >> rgs_flaring.txt
#
##  dsplot table=rgs1_bglc.fits x=TIME y=RATE &
##  dsplot table=rgs2_bglc.fits x=TIME y=RATE &

#echo "Build ${i} / ${j} RGS good time intervals (GTI, i.e. out of flares)"
#echo "RGS 1 & 2 GTI are merged, we take only times that are good for both"
#
#   tabgtigen table=rgs1_bglc.fits gtiset=gti_rgs1.fits expression="(RATE < 0.2)"
#   tabgtigen table=rgs2_bglc.fits gtiset=gti_rgs2.fits expression="(RATE < 0.2)"
#
#   gtimerge tables="gti_rgs1.fits gti_rgs2.fits" withgtitable=yes \
#            gtitable=gti_rgs_merged.fits mergemode=and plotmergeresult=false

### IMPORTANT: for extended sources like galaxies xpsfincl=95 or 99 would be more appropriate
###            or you'd miss a lot of counts from the RGS PSF wings
###           "withbackgroundmodel" enables the extraction of an additional (template) model background spectrum
###            If the source is not centered in the field of view, you'll need to provide also (RA,DEC)
###            In which case coordinates are provided by looking at the EPIC images.
#
#echo "RGS 1 & 2 event files are being filtered for solar flares (standard: both RGS 1 and 2, orders 1 and 2)"
#
#bkgcor=NO                   # not removing BKG at this stage (as BKG spectrum will be produced anyway, it's better)
#gtifile=gti_rgs_merged.fits # GTI for solar flares removal
#xpsfincl=90                 # PSF % to be include for source spectrum extraction
#xpsfexcl=98                 # PSF % to be excluded (i.e. PSF wings) for BKG spectrum extraction
#pdistincl=95                # PDI % to be include (i.e. pulse fraction) for source spectrum extraction
#
# rgsproc bkgcorrect=${bkgcor} auxgtitables=${gtifile} withbackgroundmodel=yes entrystage=3:filter \
#         finalstage=5:fluxing xpsfincl=${xpsfincl} xpsfexcl=${xpsfexcl} pdistincl=${pdistincl} >> rgs_flaring.txt
#
#srcid=1 # source id number. For standard rgsproc will be =1, if you instead had provided RA,DEC to rgsproc it will be =3.

### IMPORTANT: Launching rgsproc with coordinates specification: if require different ascension & declination
###            this is necessary only if the source coordinates are different from the observation pointings!
###            these can be obtaining opening e.g. MOS 1 images and selecting a region and WCS/Degrees for (RA,DEC)
###
### srclabel=ULX1
### srcra=3.870781905
### srcdec=-39.22161478
###
### rgsproc srcra=${srcra} srcdec=${srcdec} withsrc=${withsrc} srclabel=${srclabel} srcstyle=${srcstyle} \
###         bkgcorrect=${bkgcor} auxgtitables=${gtifile} withbackgroundmodel=yes \
###         xpsfincl=${xpsfincl} xpsfexcl=${xpsfexcl} pdistincl=${pdistincl} -V 2
###
### srcid=3
###
### echo In this case, and only, the "srcid" needs to be put equal to 3 rather than default 1.

#echo "Make RGS 1,2 region and banana plots to check extraction accuracy."
#
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
### gv rgs_region_R1.ps & # here is ignored as gv / ghostview (PS viewer) is not always available
### gv rgs_region_R2.ps & # here is ignored as gv / ghostview (PS viewer) is not always available
#
### Convert from POSTSCRIPT to PDF and open plots. You might have to choose a specific PDF viewer
#
#ps2pdf rgs_region_R1.ps
#ps2pdf rgs_region_R2.ps
#
#open rgs_region_R1.pdf rgs_region_R2.pdf

### IMPORTANT: RGS 1 and 2 spectra are being used (also) without overbinning to avoid loosing spectral resolutio
###            The spectra will be rebinned in SPEX directly to take care of 1/3 LSF oversampling.

echo "Trafo converting RGS spectra to SPEX format (SPO/RES fits format)"

### IMPORTANT: TRAFO does not over-write pre-existing files, if you have already converted some spectra
###            either change the output SPO/RES names or delete the previous spectra like this below:
###            rm SRC_rgs1_expbkg.spo SRC_rgs1_expbkg.res etc.
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
#RGS1_SRC_expbkg
#RGS1_SRC_expbkg
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
#RGS2_SRC_expbkg
#RGS2_SRC_expbkg
#EOF

echo "Combining RGS 1-2 first order spectra (for plotting purposes or less noisy spectra): adopting exposure background"

### First create the list containing the source spectra, BKG and respmats (accurately sorted)
### Then stack the spectra with the "rgscombine" task, finally converting them to SPEX format

# echo ' '`find . -name '*SRSPEC1001.FIT' | sort` > src_list.txt
# echo ' '`find . -name '*BGSPEC1001.FIT' | sort` > bgs_list.txt
# echo ' '`find . -name '*RSPMAT1001.FIT' | sort` > rsp_list.txt
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
#RGS_stacked_SRC_expbkg
#RGS_stacked_SRC_expbkg
#EOF

echo "Open SPEX to plot RGS 1,2 spectra and their stacks"

#spex<<EOF
#da RGS1_SRC_expbkg RGS1_SRC_expbkg
#da RGS2_SRC_expbkg RGS2_SRC_expbkg
#da RGS_stacked_SRC_expbkg RGS_stacked_SRC_expbkg
#ign  0:6     u a
#ign 30:40    u a
#bin  6:30 5 u a
#p de xs
#p ty da
#p ux a
#p uy a
#p cap id text "${i} ${j} RGS 1 (red), 2 (green) and stacked (b/w) spectra"
#plot cap ut disp f
#plot cap lt disp f
#p se 1
#p da col 2
#p li dis t
#p li col 2
#p se 2
#p da col 3
#p li dis t
#p li col 3
#p se 3
#p da col 1
#p li dis t
#p li col 1
#p se al
#p back disp t
#p da lw 3
#p mo lw 3
#p box lw 3
#p cap y lw 3
#p cap it lw 3
#p cap x lw 3
#p uy a
##p uy fa
##p ry 0 5
##p rx 7 35
##p rx 13 23
#p
#da sh
#p de cps ${i}_${j}_RGS_Ang.ps
#p
#p clo 2
#q
#EOF
#
#ps2pdf ${i}_${j}_RGS_Ang.ps
#  open ${i}_${j}_RGS_Ang.pdf

echo "Open SPEX to plot RGS (stacked) and EPIC together"

#spex<<EOF
#da RGS_stacked_SRC_expbkg RGS_stacked_SRC_expbkg
#da PN_SRC_spec_grp25      PN_SRC_spec_grp25
#da MOS1_SRC_spec_grp25    MOS1_SRC_spec_grp25
#da MOS2_SRC_spec_grp25    MOS2_SRC_spec_grp25
#ign ins 1  0:7     u a
#ign ins 1 27:40    u a
#bin ins 1  7:27 8  u a
#ign ins 2:4  0:0.3 u ke
#ign ins 2:4 10:100 u ke
#p de xs
#p ty da
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
#p da col 4
#p li col 4
#p li dis t
#p se al
#p li dis t
#p mo dis f
#p ba lt 4
#p ba dis t
#p ba col 8
#p ba lt 1
#p ba lw 3
#p cap id text "${i} ${j} PN (red), MOS 1 (green) and 2 (blue), RGS stacked (b/w) spectra"
#p cap id disp t
#p cap ut disp f
#p cap lt disp f
#p da lw 3
#p mo lw 5
#p box lw 3
#p cap y lw 3
#p cap it lw 3
#p cap x lw 3
#p ux ke
#p uy fke
#p x lo
#p y lo
#p rx 0.3 10
#p ry 1e-3 30
#p se a
#p ba dis t
#p ba lt 4
#p
#p de cps ${i}_${j}_EPIC_RGS_keV.ps
#p
#p clo 2
#q
#EOF
#
#ps2pdf ${i}_${j}_EPIC_RGS_keV.ps
#  open ${i}_${j}_EPIC_RGS_keV.pdf

echo "————————————————— LEVEL 2.4 RGS (1+2) TIMING: extract lightcurves within an energy range ——————————————————————————"

#echo "RGS1,2 Extracting information and exposure detail from the eventlist file:"

R1_EVE=`find . -name '*R1*EVENLI*'` # Search for the RGS 1 event file (created by rgsproc) - do not comment this line
R2_EVE=`find . -name '*R2*EVENLI*'` # Search for the RGS 2 event file (created by rgsproc) - do not comment this line

R1_EVE=${R1_EVE:2} # Removing initial two characters "./" of filename                      - do not comment this line
R2_EVE=${R2_EVE:2} # Removing initial two characters "./" of filename                      - do not comment this line

   did=${R1_EVE:0:11} # Read deteail on the exposure e.g. "P0655050101"                    - do not comment this line
expno1=${R1_EVE:13:4} # Read deteail on the RGS1 detector e.g. "R1S004"                    - do not comment this line
expno2=${R2_EVE:13:4} # Read deteail on the RGS2 detector e.g. "R1S005"                    - do not comment this line

srcid=1 # source id number. For standard rgsproc will be =1, if you instead had provided RA,DEC to rgsproc it will be =3.

### Correting the lightcurves for detector quantum efficiency and other properties with rgslccorr:
#
#   rgslccorr evlist="${did}R1${otype}${expno1}EVENLI0000.FIT ${did}R2${otype}${expno2}EVENLI0000.FIT" \
#		    srclist="${did}R1${otype}${expno1}SRCLI_0000.FIT ${did}R2${otype}${expno2}SRCLI_0000.FIT" \
#	    timebinsize=1000 orders='1 2' sourceid=${srcid} outputsrcfilename=RGS_lccorr_0310keV.lc > log_lightcurve.txt
#
#    dstoplot table=RGS_lccorr_0310keV.lc withx=yes x=TIME withy=yes y=RATE.ERROR \
#		    output=file outputfile=RGS_lccorr_0310keV.txt >> log_lightcurve.txt
#
### Plot only one lightcurve with QDP/PLT: adopt a sleeping time of 1 second if window closes too quickly
###
### QDP plotting is part of HEASOFT and (of course) needs the x-windows to be enabled.
#
#qdp << EOF
#RGS_lccorr_0310keV.txt
#/xs
#p
#q
#EOF

cd ${DIR_work} ### Going back to home / launching directory

echo 'The data reduction routine is over.'
echo "———————————————————————————————————————————————————————————————————————————————————————————————————————————————————"
##########################################################################################################################

