#!/bin/bash
ensampledir=ensample
for j in $(seq 0 1 0)
  do
  mkdir ensample${j}
  cp LVCSH.in ensample${j}
  cp lvcsh.bsub ensample${j}
  cd ensample${j}
  sed -i "2s:lvcsh-kq36-s0:lvcsh-kq36-s${j}:g" lvcsh.bsub
  bsub < lvcsh.bsub
  cd ..
  done
