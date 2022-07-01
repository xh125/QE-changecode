set style data dots
set nokey
set xrange [0: 4.01702]
set yrange [-10.75805 : 10.04858]
set arrow from  1.47033, -10.75805 to  1.47033,  10.04858 nohead
set arrow from  2.31923, -10.75805 to  2.31923,  10.04858 nohead
set xtics ("G"  0.00000,"M"  1.47033,"K"  2.31923,"G"  4.01702)
 plot "graphene_band.dat"
