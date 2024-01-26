#!/bin/bash

########################################## ROUTINE DESCRIPTION ###########################################################
####                                                                                                                  ####
#### This bash code performs an XMM-Newton MOS quick data reduction to estimate the RGS instrumental line broadening  ####
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
#### 3) At first it runs the ODF basic routines (cifduild, odfingest) and then EPIC                                   ####
####    The RGS data reduction is run with the routine RGS_data_reduction_extended_src.sh (they can be merged in 1)   ####
####                                                                                                                  ####
#### 4) After removal of Solar flares, it extract MOS 1 data, extract the images in detector coordinates              ####
####    IMPORTANT: the SPEX rgsvprof tool is used to estimate surface brightness profile and convert it in angstrom   ####
####                                                                                                                  ####
#### 5) A quick PYTHON script opens the line broadening profiles, compared them and estimate an average profile       ####
####                                                                                                                  ####
#### NOTE: all main commands have been disabled with a single "#"; uncomment & launch each one as first exercise      ####
####                                                                                                                  ####
#### There are 4 levels: 0=ODF individual processing, 1=event files, 2=clean products, 3=stacking observations        ####
####                                                                                                                  ####
#### Sometimes XMM/SAS will give warnings like "** odfingest: warning", most are OK. Take care for ** error **        ####
####                                                                                                                  ####
####   License: This public code was developed for and published in the paper Pinto et al. (2015),                    ####
####   DOI: 10.1051/0004-6361/201425278, arXiv: 1501.01069, bibcode: 2015A&A...575A..38P. You may refer to this.      ####
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
 export SAS_VERBOSITY=1

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
 
 echo "--------EPIC MOS data reduction: running emproc, in this case only for MOS 1"

# emproc selectinstruments=yes emos1=yes -V 1 > emproc_log.txt # Extracting only MOS1 data (for imaging / RGS line broadening)
#
#   ln -s $( find . -name '*_EMOS1_*Evts.ds') mos1.fits
#
# echo $( find . -name 'mos1.fits')
  
echo "-------Extracting lightcurves for Solar flares removal: ----------------- MOS 1"

#   evselect table="mos1.fits:EVENTS" withrateset=Y rateset=mos1_lc.fits \
#    timecolumn=TIME maketimecolumn=Y timebinsize=100 makeratecolumn=Y \
#    expression='#XMMEA_EM && (PI>10000) && (PATTERN==0)' -V 1 >> log_epic_flaring
#
#    dsplot table=mos1_lc.fits x=TIME y=RATE &
#
#   tabgtigen table=mos1_lc.fits  expression="(RATE < 0.35)" gtiset=mos1_gti.fits  -V 1 >> log_epic_flaring
#
#   evselect table="mos1.fits:EVENTS" withfilteredset=Y filteredset=mos1_filtered.fits destruct=Y keepfilteroutput=T \
#    expression='#XMMEA_EM && gti(mos1_gti.fits,TIME) && (PI in [300:10000]) && (PATTERN<=12)' -V 1 >> log_epic_flaring

  echo "---------Filtering data-------------------------------------------------------------------------"

#    evselect table="mos1.fits:EVENTS" withfilteredset=Y filteredset=mos1_filtered.fits destruct=Y keepfilteroutput=T \
#             expression='#XMMEA_EM && gti(mos1_gti.fits,TIME) && (PI in [300:10000]) && (PATTERN<=12)' -V 1 >> log_epic_flaring

echo "MOS 1 filtered dataset created:" ${DIR}/$i/$j/pps/mos1_filtered.fits

echo "Extracting MOS 1 images (sky and detector coordinates) for several ranges of energy (for loop on energy ranges)"

minimum_energy=( 300  800  326  350 350 500  900 1200 1800 3000 460  690  350  500)
maximum_energy=(2500 1400 2500 1770 500 900 1200 1800 3000 7000 690  890 1770 1770)
identif_energy=(full iron rgs1 rgs2   0   A    B    C    D    E  A2   B2 rgs3  RGS)

mkdir mos1_images
mkdir mos1_images_skycoord

 for ((a=13;a<=13;a++)); # for this exercise we extract only the band of RGS where the source is above the BKG (0.5-1.77 keV)
  do
   echo Energy range $((${a}+1)): ${minimum_energy[a]} - ${maximum_energy[a]} eV "(band: ${identif_energy[a]})"

### echo "Uncomment the following if you also want to extract a skycoord image"
###
### evselect table=mos1_filtered.fits expression="(PI in [${minimum_energy[a]}:${maximum_energy[a]}])" filtertype=expression \
###          imageset=./mos1_images_skycoord/mos1_band_${identif_energy[a]}.fits \
###          xcolumn=X ycolumn=Y ximagebinsize=80 yimagebinsize=80 \
###          ximagesize=600 yimagesize=600 imagebinning=binSize withimageset=yes > my_images_log.txt

# evselect table=mos1_filtered.fits expression="(PI in [${minimum_energy[a]}:${maximum_energy[a]}])" filtertype=expression \
#          imageset=./mos1_images/mos1_band_${identif_energy[a]}_det.fits \
#          xcolumn=DETX ycolumn=DETY ximagebinsize=80 yimagebinsize=80 \
#          ximagesize=600 yimagesize=600 imagebinning=binSize withimageset=yes > my_images_log.txt

  done
 
echo "Extracting MOS 1 cumulative profiles with RGSvprof (for RGS line instrumental broadening) ----------"

### NOTE: if you chose a 90% PSF extration for RGS spectra then select +/-0.4 arc minutes Cross-dispersion
###       a 10 arcmin selection region along the dispersion direction is normally sufficient.

 cd mos1_images/

 for file in mos1_band_RGS_det
 do

echo "rgsvprof for $file within 0.4x2 arcmin with 10 am width"

#rgsvprof << EOF
#${file}.fits
#-0.4 +0.4
#10.0
#$file.0p4.10am.dat
#EOF

 done

cd ..
 
index=$(($index+1))

echo "End of the main commands!"

  cd ${DIR}
done

done

cd ${DIR}/${i}

echo "PYTHON checking the shape of the vProf RGS line broadening profiles"

#find . -name "*.0p4.10am.dat"
#
#python - <<EOF
#
#import numpy as np
#import matplotlib.pyplot as plt
#
#w1,c1=np.loadtxt("0046340101/pps/mos1_images/mos1_band_RGS_det.0p4.10am.dat",usecols=(0,1), unpack=True)
#w2,c2=np.loadtxt("0406200101/pps/mos1_images/mos1_band_RGS_det.0p4.10am.dat",usecols=(0,1), unpack=True)
#
#fig1=plt.figure(1)
#frame1=fig1.add_axes((.12,.12,.85,.85)) # Y: 0.1-0.3+0.00, 0.3-0.5+0.025, 0.5-0.7+0.050, 0.7-0.9+0.075
#
#plt.plot(w1, c1, c='black', linestyle='-',  label="0046340101")
#plt.plot(w2, c2, c='red',   linestyle='--', label="0406200101")
#
#### Computing and saving average profile:
#
#c3=(c1+c2)/2.
#
#output=np.column_stack((w1, c3))
#
#np.savetxt('mos1_band_RGS_det.0p4.10am.txt',output,'%1.5e')
#
#### Update plot
#
#plt.plot(w2, c3, c='blue',   linestyle=':', label="Average profile")
#
#plt.legend(loc='upper left', fontsize=10, framealpha=0.) # ,bbox_to_anchor=(0.75, 1.04)
#
#plt.ylabel("Cumulative profile", fontsize=13)
#plt.xlabel("Wavelength (Angstrom)", fontsize=13)
#
#frame1.set_xlim([-0.7,+0.7])
#frame1.set_ylim([0,1])
#
#plt.rcParams.update({'font.size': 13})
#
#plt.savefig('RGS_lineprof_cum.pdf',bbox_inches='tight')
#plt.close('all')
#
#EOF
#
#open RGS_lineprof_cum.pdf


cd ${DIR}


echo 'Done !!!!!!!!!!'

date > Info_ending_time.txt 
T="$(($(date +%s)-T))"
cat Info_starting_time.txt
cat Info_ending_time.txt
echo "Time elapsed: ${T} sec"
echo "Time elapsed: "$(($T/60))"+ min"
