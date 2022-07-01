#!/bin/bash
for i in {120..120}
	do
	cp epw.in epw${i}.in
	sed -i "s:epwwrite:epwwrite=.false. ! :g" epw${i}.in
	sed -i "s:epwread:epwread=.true. !:g" epw${i}.in
	sed -i "s:epbread:epbread=.false. !:g" epw${i}.in
	sed -i "s:epbwrite:epbwrite=.false. !:g" epw${i}.in
	sed -i "s:wannierize:wannierize=.false. !:g" epw${i}.in
	sed -i "s:elecselfen:elecselfen=.true. !:g" epw${i}.in
  
	sed -i "s:nkf1:nkf1=$i !:g" epw${i}.in
	sed -i "s:nkf2:nkf2=$i !:g" epw${i}.in  
	sed -i "s:nqf1:nqf1=$i !:g" epw${i}.in
	sed -i "s:nqf2:nqf2=$i !:g" epw${i}.in  

	cat >qe-epw${i}.bsub <<-EOF
	#!/bin/bash
	#BSUB -J epw-ifc${i}
	#BSUB -q privateq-zw
	##BSUB -q publicq
	#BSUB -n 28
	#BSUB -R "span[ptile=28]"
	#BSUB -o %J.out
	#BSUB -e %J.err
	
	CURDIR=\$PWD
	rm -f nodelist${i} >& /dev/null
	for host in \`echo \$LSB_HOSTS\`
	do
	echo \$host >> nodelist${i}
	done
	NP=\`cat nodelist${i} | wc -l\`
	rm nodelist${i}
	
	module use /share/home/zw/xiehua/modulefiles
	module load Quantum_Espresso/7.0
	
	mpirun -np \$NP epw.x -nk \$NP <epw${i}.in> epw${i}.out	
	EOF

	
	chmod +x qe-epw${i}.bsub
	bsub < qe-epw${i}.bsub
	done
