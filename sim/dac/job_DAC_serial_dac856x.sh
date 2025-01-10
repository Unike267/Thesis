#!/usr/bin/env bash

set -ex

cd $(dirname "$0")

./run.py -v --gtkwave-fmt vcd

mv vunit_out/wave/wave_dac.vcd ../..
mv vunit_out/outcsv/tb_dac.csv ../..
