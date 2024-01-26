### TRAFO tool: ad-hoc data management for SPEX
###
### Link RGS spectra order 1 and 2 for simultaneous fits
### The use of 2 sectors enable non-identical models.
###
### The data were already converted to SPEX (single epctra)
### and now are linked together through 1 multiple spectrum
###
### IMPORTANT: before creating the model type "sector new"
###            to tell SPEX that there 2 sectors (orders 1, 2)
###
### SPEX is then open to quickly plot the data

file1=rgs_stacked_align_90
file2=rgs_stacked_align_90_o2

#trafo<<EOF
#3
#2
#10000
#2
#1 1
#no
#${file1}
#${file1}
#2 2
#no
#${file2}
#${file2}
#rgs_stacked_align_90_sec2
#rgs_stacked_align_90_sec2
#EOF

### SPEX quick plot ###

#spex<<EOF
#da rgs_stacked_align_90_sec2 rgs_stacked_align_90_sec2
#sec new
#ign 0:6.5 u a
#ign 30:100 u a
#ign ins 1 reg 2 18.:100 u a
#p de xs
#p ty da
#p se 2
#p da col 2
#bin ins 1 reg 1 0:40  5 u a
#bin ins 1 reg 2 0:40 10 u a
#p ux a
#p uy fa
#p ry 0 20
#pl
#p de cps plot_data.ps
#p
#p clo 2
#q
#EOF
#
#ps2pdf plot_data.ps
#  open plot_data.pdf
