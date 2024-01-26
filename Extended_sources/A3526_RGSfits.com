### SPEX executable file that fits stacked spectra order 1 and 2 simultaneously
###
### LOAD DATA (tell SPEX there is a new sector, i.e. a total of 2 sectors)

da rgs_stacked_align_90_sec2 rgs_stacked_align_90_sec2

sec new

### Manage data

ign  0:6    u a
ign 30:40   u a

bin  ins 1 reg 2 6:30 10 u a
bin  ins 1 reg 1 6:30  5 u a

### Plot data

p de xs
p ty da
p ux a
p uy a
p cap id text "A 3525 stacked spectrum : order 1 (blue) and 2 (black)"
plot cap ut disp f
plot cap lt disp f
p se al
p da lw 3
p mo lw 3
p box lw 3
p cap y lw 3
p cap it lw 3
p cap x lw 3
p ba col 3
p se 2
p da col 11
p li col 11
p se al
p line disp t
p uy fa
p y li
p

### Define distance: important to chose distance or redshift
###
### Starting with 1 single temperature CIE model
### the lines are also broadened (convolved) by instrumental broadening
### or the LINE CUMULATIVE PROFILE previously computed with rgsvprof
###
### model 1: CIE * REDSHIFT * ISM_absorption * INSTR_BROADENING
###
### Total ISM_absorption from https://www.swift.ac.uk/analysis/nhtot/
###
### Need for powerlaw (AGN / additional BKG) and/or multiple CIE?
### Are cooler lines (Fe XVII) narrower? Try 2nd LPRO with smaller "s"

dist 0.0110 z

com cie
com red
com hot
com lpro

com rel 1 2,3,4

par 1 1 no v 4E+07
par 1 1 t  r 0.1 10
par 1 1 t  v 1.5

par 1 2 z  v 0.0110

par 1 3 nh v 1.22E-03
par 1 3 nh s f
par 1 3 t  v 1e-6
par 1 3 t  s f
par 1 3 v  v 10

par 1 4 s  r 0.1 2
par 1 4 dl r -1 1
par 1 4 s  s  t
par 1 4 dl s  t
par 1 4 file av mos1_band_RGS_det.0p4.10am.txt

par 2 1 no:30 cou 1 1 no:30
par 2 2  z:fl cou 1 2  z:fl
par 2 3 nh:30 cou 1 3 nh:30
par 2 4  s:fi cou 1 4  s:fi
par 2 4  s    cou 1 4  s fac 0.5

### Chose to plot each fit step and band where to compute flux/luminosity

 fit print 1
 eli 0.3:2 keV
 eli 6:30 Ang

c
p
par sh fr

# fit
# fit
# fit
# par sh fr

### Adding 2nd CIE component

par 1 4 s v 1.0

com cie
com rel 5 2,3,4

par 1 5 no v 2e6
par 1 5 t  v 0.8

par 2 5 no:30 cou 1 5 no:30

c
p
par sh fr

# fit
# fit
# fit
# par sh fr

### SAVING PLOT:
#
# p de cps A3526_RGS.ps
# p
# p clo 2
# sys exe "ps2pdf A3526_RGS.ps"
# sys exe "  open A3526_RGS.pdf"

### How about releasing some abundances (07, 08, 10, 12)?
### Keep iron (26) to solar unless bremsstrahlung continuum is high enough 
