#!/bin/bash

########################################## ROUTINE DESCRIPTION ###########################################################
####                                                                                                                  ####
#### This bash code performs an XMM-Newton RGS basic data reduction for 1 source + align/stack spectra of 2 exposures ####
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
#### 3) At first it runs the ODF basic routines (cifduild, odfingest) and then RGSPROC                                ####
####    Ideally, you should have launched before EPPROC or EMPROC to check X-ray emission peak and PSF/line width     ####
####                                                                                                                  ####
#### 4) After removal of Solar flares, it extract RGS data one specific ra/dec coordinates (if provided)              ####
####    IMPORTANT: chose the SRCID=1 for deault extraction and SRCID=3 if desired ra/dec are provided for alignment.  ####
####               The example provided here are 2 XMM on-axis observations of Centaurus galaxy cluster (Abell 3526)  ####
####                                                                                                                  ####
#### 5) The code also converts the spectra in SPEX format (if SPEX is installed), opens the spectra & saves plots     ####
####                                                                                                                  ####
#### NOTE: all main commands have been disabled with a single "#"; uncomment & launch each one as first exercise      ####
####                                                                                                                  ####
#### There are 4 levels: 0=ODF individual processing, 1=event files, 2=clean products, 3=stacking observations        ####
####                                                                                                                  ####
#### Sometimes XMM/SAS will give warnings like "** odfingest: warning", most are OK. Take care for ** error **        ####
####                                                                                                                  ####
####   License: This public code was developed for and published in the paper Pinto et al. (2015),                    ####
####   DOI: 10.1051/0004-6361/201425278, arXiv: 1501.01069, bibcode: 2015A&A...575A..38P. You may refer to this.      ####
####   For the line instrumental broadrening in extended sources please refer to parallel / complementary routine     ####
####   For theoretical info on such issue see https://spex-xray.github.io/spex-help/models/lpro.html                  ####
####                                                                                                                  ####
##########################################################################################################################

### Info: one # is for commands which can run after uncomment, three # are for comments/instructions.
###
### Info: help yourself with my comments before each command
###       and looking at SAS threads at https://www.cosmos.esa.int/web/xmm-newton/sas-threads
###
### Suggestion: if you are new to XMM/SAS execute the commands one-by-one by uncommenting/commenting them.

export SAS_CCFPATH=/PATH/TO/YOUR/SAS/CCF/FILES

date > Info_starting_time.txt
T="$(date +%s)"

echo "--------RGS data reduction for same exposures from 1 source. Need another routine for EPIC-pn/MOS routines---------"

DIR=$PWD
cd ${DIR}

### Define source name / exposure:
### these are also the name of the sub-directory and sub-sub-directory where we run data redcution.

declare -a src_ID=("A3526"      "A3526")
declare -a exp_ID=("0046340101" "0406200101")

for i in "${src_ID[0]}"
 do 

 for j in "${exp_ID[@]}"
 do
  echo

### print on the screen source and expo.

  printf "%s %s\n" "${i}" "${j}"

### Create or make sure that odf directory (containing the ODF files)
### and the pps directory (where we create products) already exist.

#mkdir ${DIR}/${i}/${j}/odf 
#mkdir ${DIR}/${i}/${j}/pps

 echo Checking directory ${DIR}/${i}/${j}/odf/ ------------------------
 
  cd ${DIR}/${i}/${j}/odf/
   
 echo reducing ODF files .........................................................................

### Untar (uncompress) archive containing ODF files, if any.
### IMPORTANT: set up SAS environment variables e.g. SAS_ODF.

###  tar -xf `find . -name '*.tar.gz'` # to untar / unzip ODF files
###  tar -xf `find . -name '*.TAR'`    # to untar / unzip ODF files
 
 export SAS_ODF=$PWD
 export SAS_CCFPATH=/PATH/TO/YOUR/SAS/CCF/FILES
 export SAS_VERBOSITY=2

###  rm `find . -name '*SUM.SAS'` # In case you want to remove OLD SAS SUM files.

### Run cifbuild to create calibration file: uncomment to run it

# cifbuild -V 1 > cifbuild_log.txt

 export SAS_CCF=$PWD/ccf.cif

### Run odfingest to create summary file: uncomment to run it

# odfingest -V 1 > odfingest_log.txt                             
  
 echo SAS ODF file: `find . -name '*SUM.SAS'`
 
  SAS_ODF_FILE=$(find . -name '*SUM.SAS')
  SAS_ODF_FILE=${SAS_ODF_FILE:2}

### Make sure the env variables are correctly set up.

    export SAS_CCFPATH=/PATH/TO/YOUR/SAS/CCF/FILES
    export SAS_ODF=${DIR}/${i}/${j}/odf
    export SAS_CCF=$SAS_ODF/ccf.cif
    export SAS_ODF=${DIR}/${i}/${j}/odf/${SAS_ODF_FILE}
    export SAS_VERBOSITY=1

 echo SAS_CCF: $SAS_CCF
 echo SAS_ODF: $SAS_ODF
  
 echo Checking directory ${DIR}/${i}/${j}/pps/ ------------------------

    cd ${DIR}/${i}/${j}/pps/
    
 echo I am working in directory: $PWD ...........................................................
 
echo ' running rgsproc, please be patient: uncomment to run it------------------'

# rgsproc -V 1 > rgsproc_log.txt

### The following rgsproc to directly align RGS spectra crashes, so use it later on once already launched rgsproc as above
###
### rgsproc withsrc=yes srclabel=A3526 \
###                    srcstyle=radec srcra=192.20573 srcdec=-41.312351 -V 1 > rgsproc_log.txt
###
### If necessary, remember to remove double/splitted small exposures (very short event files).

echo Event list created: ..................................................... `find . -name '*EVENLI*'`

echo Extracting information and exposure detail from the eventlist file:
 
R1_EVE=`find . -name '*R1*EVENLI*'`
R2_EVE=`find . -name '*R2*EVENLI*'`

R1_EVE=${R1_EVE:2}
R2_EVE=${R2_EVE:2}

    did=${R1_EVE:0:11}
expno1=${R1_EVE:13:4}
expno2=${R2_EVE:13:4}

srcid=3

echo "--------RGS background lightcurve: necessary to remove solar flares--------------------"

### Create BKG lightcurves for both RGS 1 and 2, plot them, choose cutting theshold e.g. standard 0.2 c/s,
### Create good time intervals (GTI) files and merge RGS 1-2 GTI files.

# evselect table="${did}R1${otype}${expno1}EVENLI0000.FIT:EVENTS" makeratecolumn=yes maketimecolumn=yes timecolumn=TIME timebinsize=100 \
#          expression="(CCDNR == 9) && ((M_LAMBDA,XDSP_CORR) in REGION(${did}R1${otype}${expno1}SRCLI_0000.FIT:RGS1_BACKGROUND))" \
#          rateset=rgs1_bglc.fits -V 1 > other_log.txt
# evselect table="${did}R2${otype}${expno2}EVENLI0000.FIT:EVENTS" makeratecolumn=yes maketimecolumn=yes timecolumn=TIME timebinsize=100 \
#          expression="(CCDNR == 9) && ((M_LAMBDA,XDSP_CORR) in REGION(${did}R2${otype}${expno2}SRCLI_0000.FIT:RGS2_BACKGROUND))" \
#          rateset=rgs2_bglc.fits -V 1 > other_log.txt
#
# #  dsplot table=rgs1_bglc.fits x=TIME y=RATE &
# #  dsplot table=rgs2_bglc.fits x=TIME y=RATE &
#
# tabgtigen table=rgs1_bglc.fits gtiset=gti_rgs1_0p1.fits expression="(RATE < 0.2)" -V 1 > other_log.txt
# tabgtigen table=rgs2_bglc.fits gtiset=gti_rgs2_0p1.fits expression="(RATE < 0.2)" -V 1 > other_log.txt
#
# gtimerge tables="gti_rgs1_0p1.fits gti_rgs2_0p1.fits" withgtitable=yes gtitable=gti_rgs_merged.fits \
#          mergemode=and plotmergeresult=false -V 1 > other_log.txt

### Set up for the level 2 extraction: GTI, mask and source coordinates, MODEL BKG spectrum extracted too

bkgcor=NO
gtifile=gti_rgs_merged.fits
withsrc=yes
srcstyle=radec
srclabel=A3526
srcra=192.20573
srcdec=-41.312351
xpsfincl=90
xpsfexcl=98
pdistincl=95

### Rerun rgsproc with exact coordinates, masks e.g. PSF=90% (default=95%), and GTI file to remove flares.

#  rgsproc srcra=${srcra} srcdec=${srcdec} withsrc=${withsrc} srclabel=${srclabel} srcstyle=${srcstyle} \
#          bkgcorrect=${bkgcor} auxgtitables=${gtifile} withbackgroundmodel=yes \
#          xpsfincl=${xpsfincl} xpsfexcl=${xpsfexcl} pdistincl=${pdistincl} -V 1 > rgsproc_log.txt
        
### Chosing "srcid=3" makes sure that in the coming the data spectra extracted above are considered

srcid=3

echo "--------RGS region and banana plot to show selection regions---------------------------------------------------------------"

#  evselect table="${did}R1${otype}${expno1}EVENLI0000.FIT:EVENTS" withimageset=yes imageset='rgs_spatial1.fit' \
#           xcolumn='M_LAMBDA' ycolumn='XDSP_CORR' -V 1 > other_log.txt
#  evselect table="${did}R1${otype}${expno1}EVENLI0000.FIT:EVENTS" withimageset=yes imageset='rgs_banana1.fit' \
#           xcolumn='M_LAMBDA' ycolumn='PI' withyranges=yes yimagemin=0 yimagemax=3000 \
#           expression="region(${did}R1${otype}${expno1}SRCLI_0000.FIT:RGS1_SRC${srcid}_SPATIAL,M_LAMBDA,XDSP_CORR)" -V 1 > other_log.txt
#
#  evselect table="${did}R2${otype}${expno2}EVENLI0000.FIT:EVENTS" withimageset=yes imageset='rgs_spatial2.fit' \
#           xcolumn='M_LAMBDA' ycolumn='XDSP_CORR' -V 1 > other_log.txt
#  evselect table="${did}R2${otype}${expno2}EVENLI0000.FIT:EVENTS" withimageset=yes imageset='rgs_banana2.fit' \
#           xcolumn='M_LAMBDA' ycolumn='PI' withyranges=yes yimagemin=0 yimagemax=3000 \
#           expression="region(${did}R2${otype}${expno2}SRCLI_0000.FIT:RGS2_SRC${srcid}_SPATIAL,M_LAMBDA,XDSP_CORR)" -V 1 > other_log.txt
#
#  rgsimplot endispset='rgs_banana1.fit' spatialset='rgs_spatial1.fit' srcidlist="${srcid}" \
#            srclistset="${did}R1${otype}${expno1}SRCLI_0000.FIT" \
#            withendispregionsets=yes withendispset=yes withspatialregionsets=yes \
#            withspatialset=yes device=/cps plotfile=rgs_region_R1.ps -V 1 > other_log.txt
#  rgsimplot endispset='rgs_banana2.fit' spatialset='rgs_spatial2.fit' srcidlist="${srcid}" \
#            srclistset="${did}R2${otype}${expno2}SRCLI_0000.FIT" \
#            withendispregionsets=yes withendispset=yes withspatialregionsets=yes \
#            withspatialset=yes device=/cps plotfile=rgs_region_R2.ps -V 1 > other_log.txt
#
### ps2pdf rgs_region_R1.ps
### ps2pdf rgs_region_R2.ps
###   open rgs_region_R1.pdf
###   open rgs_region_R2.pdf

echo "End of the main commands!"

  cd ${DIR}
done

done

echo '--------------------RGS spectra stacking order 1 and order 2 from all exposures---------------------------'

cd ${DIR}/${i}

### Make a list of source spectrum files, response files, background files.
### Then run rgscombine to stack them all (both RGS 1 and 2 first order).
### Here the modelbackground spectrum (000.FIT) is used. Then trafo convert.

# rm src_list.txt bkg_list.txt rsp_list.txt
#
# echo ' '`find . -name "*R*SRSPEC*1003.FIT" | sort` >> src_list.txt
# echo ' '`find . -name "*R*MBSPEC*1000.FIT" | sort` >> bkg_list.txt
# echo ' '`find . -name "*R*RSPMAT*1003.FIT" | sort` >> rsp_list.txt
#
# rgscombine pha="`cat src_list.txt`" bkg="`cat bkg_list.txt`" rmf="`cat rsp_list.txt`" \
#            filepha="rgs_stacked_srs_align_${xpsfincl}.fits" filermf="rgs_stacked_rmf_align_${xpsfincl}.fits" \
#            filebkg="rgs_stacked_bkg_align_${xpsfincl}.fits" rmfgrid=4000

### Convert to SPEX format via trafo
#
#trafo << EOF
#1
#1
#10000
#3
#16
#no
#rgs_stacked_srs_align_${xpsfincl}.fits
#y
#no
#0
#rgs_stacked_align_${xpsfincl}
#rgs_stacked_align_${xpsfincl}
#EOF

### Here the observation background spectrum (003.FIT) is used. Then trafo convert.

# rm src_list.txt bkg_list.txt rsp_list.txt
#
# echo ' '`find . -name "*R*SRSPEC*1003.FIT" | sort` >> src_list.txt
# echo ' '`find . -name "*R*BGSPEC*1003.FIT" | sort` >> bkg_list.txt
# echo ' '`find . -name "*R*RSPMAT*1003.FIT" | sort` >> rsp_list.txt
#
# rgscombine pha="`cat src_list.txt`" bkg="`cat bkg_list.txt`" rmf="`cat rsp_list.txt`" \
#            filepha="rgs_stacked_srs_align_${xpsfincl}.fits" filermf="rgs_stacked_rmf_align_${xpsfincl}.fits" \
#            filebkg="rgs_stacked_bgs_align_${xpsfincl}.fits" rmfgrid=4000

### Convert to SPEX format via trafo
#
#trafo << EOF
#1
#1
#10000
#3
#16
#no
#rgs_stacked_srs_align_${xpsfincl}.fits
#y
#no
#0
#rgs_stacked_align_bgs_${xpsfincl}
#rgs_stacked_align_bgs_${xpsfincl}
#EOF

echo "RGS rebinning to minimul S/N ratio: files might require INSTRUME key to be updated before rebinning."

# fparkey "RGS1" "rgs_stacked_srs_align_${xpsfincl}.fits[0]" INSTRUME add=yes
#
#  Signal_to_Noise=5  # Rebin by S/N ratio
#
#   Oversample_bin=0   # do not rebin by PSF
#
# specgroup spectrumset="rgs_stacked_srs_align_${xpsfincl}.fits" minSN=${Signal_to_Noise} \
#            backgndset="rgs_stacked_bkg_align_${xpsfincl}.fits" \
#                rmfset="rgs_stacked_rmf_align_${xpsfincl}.fits" \
#            groupedset="rgs_stacked_srs_align_${xpsfincl}_s2n${Signal_to_Noise}_oversample${Oversample_bin}.fits"
#
#trafo << EOF
#1
#1
#10000
#3
#16
#no
#rgs_stacked_srs_align_${xpsfincl}_s2n${Signal_to_Noise}_oversample${Oversample_bin}.fits
#y
#y
#no
#0
#rgs_stacked_srs_align_s2n${Signal_to_Noise}_oversample${Oversample_bin}_${xpsfincl}
#rgs_stacked_srs_align_s2n${Signal_to_Noise}_oversample${Oversample_bin}_${xpsfincl}
#EOF

### For exposure background:
#
# specgroup spectrumset="rgs_stacked_srs_align_${xpsfincl}.fits" minSN=${Signal_to_Noise} \
#            backgndset="rgs_stacked_bgs_align_${xpsfincl}.fits" \
#                rmfset="rgs_stacked_rmf_align_${xpsfincl}.fits" \
#            groupedset="rgs_stacked_srs_align_${xpsfincl}_s2n${Signal_to_Noise}_oversample${Oversample_bin}.fits"
#
#trafo << EOF
#1
#1
#10000
#3
#16
#no
#rgs_stacked_srs_align_${xpsfincl}_s2n${Signal_to_Noise}_oversample${Oversample_bin}.fits
#y
#y
#no
#0
#rgs_stacked_srs_align_bgs_s2n${Signal_to_Noise}_oversample${Oversample_bin}_${xpsfincl}
#rgs_stacked_srs_align_bgs_s2n${Signal_to_Noise}_oversample${Oversample_bin}_${xpsfincl}
#EOF

##################### Second order spectra stacking Useful for bright sources ############################
#
#### MODEL BKG
#
#rm src_list_o2.txt bkg_list_o2.txt rsp_list_o2.txt
#
# echo ' '`find . -name "*R*SRSPEC*2003.FIT" | sort` >> src_list_o2.txt
# echo ' '`find . -name "*R*MBSPEC*2000.FIT" | sort` >> bkg_list_o2.txt
# echo ' '`find . -name "*R*RSPMAT*2003.FIT" | sort` >> rsp_list_o2.txt
#
# rgscombine pha="`cat src_list_o2.txt`" bkg="`cat bkg_list_o2.txt`" rmf="`cat rsp_list_o2.txt`" \
#            filepha="rgs_stacked_srs_o2_align_${xpsfincl}.fits" filermf="rgs_stacked_rmf_o2_align_${xpsfincl}.fits" \
#            filebkg="rgs_stacked_bkg_o2_align_${xpsfincl}.fits" rmfgrid=4000
#
#trafo << EOF
#1
#1
#10000
#3
#16
#no
#rgs_stacked_srs_o2_align_${xpsfincl}.fits
#y
#no
#0
#rgs_stacked_align_${xpsfincl}_o2
#rgs_stacked_align_${xpsfincl}_o2
#EOF
#
#### Observational BKG
#
#rm src_list_o2.txt bkg_list_o2.txt rsp_list_o2.txt
#
# echo ' '`find . -name "*R*SRSPEC*2003.FIT" | sort` >> src_list_o2.txt
# echo ' '`find . -name "*R*BGSPEC*2003.FIT" | sort` >> bkg_list_o2.txt
# echo ' '`find . -name "*R*RSPMAT*2003.FIT" | sort` >> rsp_list_o2.txt
#
# rgscombine pha="`cat src_list_o2.txt`" bkg="`cat bkg_list_o2.txt`" rmf="`cat rsp_list_o2.txt`" \
#            filepha="rgs_stacked_srs_o2_align_${xpsfincl}.fits" filermf="rgs_stacked_rmf_o2_align_${xpsfincl}.fits" \
#            filebkg="rgs_stacked_bgs_o2_align_${xpsfincl}.fits" rmfgrid=4000
#
#trafo << EOF
#1
#1
#10000
#3
#16
#no
#rgs_stacked_srs_o2_align_${xpsfincl}.fits
#y
#no
#0
#rgs_stacked_align_bgs_${xpsfincl}_o2
#rgs_stacked_align_bgs_${xpsfincl}_o2
#EOF

################################### SPEX plot data ############################################

#spex<<EOF
#
#da rgs_stacked_align_90_o2 rgs_stacked_align_90_o2
#da rgs_stacked_align_90    rgs_stacked_align_90
#
#da rgs_stacked_align_bgs_90_o2 rgs_stacked_align_bgs_90_o2
#da rgs_stacked_align_bgs_90    rgs_stacked_align_bgs_90
#
#ign  0:6    u a
#ign 26:40   u a
#
#bin ins 1 6:40 10 u a
#bin ins 2 6:40  5 u a
#bin ins 3 6:40 10 u a
#bin ins 4 6:40  5 u a
#
#p de xs
#p ty da
#p ux a
#p uy fa
#p ry -1 8
#p se 1
#p da col 1
#p li col 1
#p ba col 1
#p se 2
#p da col 11
#p li col 11
#p ba col 11
#p se 3
#p da col 2
#p li col 2
#p ba col 2
#p se 4
#p da col 3
#p li col 3
#p ba col 3
#p cap id text "${i} RGS stacked spectrum: Model background VS Observational background"
#plot cap ut disp f
#plot cap lt disp f
#p se al
#p bac dis t
#p bac lt 4
#p da lw 3
#p mo lw 3
#p box lw 3
#p cap y lw 3
#p cap it lw 3
#p cap x lw 3
#p li dis t
#p mo dis f
#p ux a
#p uy fa
#p ry 0 18
#p rx 6 26
#p str new 18 16 "RGS order 1 MBS"
#p str new 18 15 "RGS order 2 MBS"
#p str new 18 14 "RGS order 1 OBS"
#p str new 18 13 "RGS order 2 OBS"
#p str 1 col 1
#p str 2 col 11
#p str 3 col 3
#p str 4 col 2
#p
#p de cps A3526_stacked_BKG_checks.ps
#p
#p clo 2
#q
#EOF
#
#ps2pdf A3526_stacked_BKG_checks.ps
#  open A3526_stacked_BKG_checks.pdf

cd ${DIR}


echo 'Done !!!!!!!!!!'

date > Info_ending_time.txt 
T="$(($(date +%s)-T))"
cat Info_starting_time.txt
cat Info_ending_time.txt
echo "Time elapsed: ${T} sec"
echo "Time elapsed: "$(($T/60))"+ min"
