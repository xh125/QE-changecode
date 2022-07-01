#!/bin/bash
ensampledir='ensample'
epwdir='/share/home/zw/xiehua/workfiles/qefies/Graphene/epw-ifc'
for i in $(seq 12 12 60)
  do
  mkdir epwkq${i}
  cp LVCSH.in epwkq${i}
#  cp lvcsh.bsub epwkq${i}
#  sed -i "2s:lvcsh:lvcsh-kq${i}-s0:g" epwkq${i}/lvcsh.bsub
  sed -i "s:epwoutname:epwoutname = \"${epwdir}/epw${i}.out\" !:g" epwkq${i}/LVCSH.in
  
  cd epwkq${i}
  cat > lvcsh.bsub <<-EOF
	#!/bin/bash
	#BSUB -J lvcsh-kq${i}-s0
	#BSUB -q privateq-zw
	##BSUB -q publicq
	#BSUB -n 28
	#BSUB -R "span[ptile=28]"
	#BSUB -o %J.out
	#BSUB -e %J.err

	CURDIR=\$PWD
	rm -f nodelist >& /dev/null
	for host in \`echo \$LSB_HOSTS\`
	do
	echo \$host >> nodelist
	done
	NP=\`cat nodelist | wc -l\`
	rm nodelist

	module use /share/home/zw/xiehua/modulefiles
	module load lvcsh/0.3-mpi

	mpirun -np \$NP LVCSH
EOF
chmod +x lvcsh.bsub

  cat > runlvcshen.sh <<-FFF
	#!/bin/bash
	ensampledir=${ensampledir}
	for j in \$(seq 0 1 0)
	  do
	  mkdir ${ensampledir}\${j}
	  cp LVCSH.in ${ensampledir}\${j}
	  cp lvcsh.bsub ${ensampledir}\${j}
	  cd ${ensampledir}\${j}
	  sed -i "2s:lvcsh-kq${i}-s0:lvcsh-kq${i}-s\${j}:g" lvcsh.bsub
	  bsub < lvcsh.bsub
	  cd ..
	  done
FFF

  chmod +x runlvcshen.sh
  bash runlvcshen.sh
  cd ..		
  done
