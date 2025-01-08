#!/usr/bin/env python3

from pathlib import Path
from vunit import VUnit
from shutil import copyfile
from os import makedirs, getenv
import re

# Function to take the csv/wave from a folder with unknown path and put that csv/wave into a folder with known path
def post_func(results):
    report = results.get_report()
    out_dir_csv = Path(report.output_path) / "outcsv"
    out_dir_wave = Path(report.output_path) / "wave"
    list = [out_dir_csv,out_dir_wave]

    for items in list:        
        try:
            makedirs(str(items))
        except FileExistsError:
            pass

    for key, item in report.tests.items():
        if key == "lib.tb_dac.test":
            copyfile(
                str(Path(item.path) / "log.csv"),
                str(out_dir_csv / "tb_dac.csv"),
            )
            copyfile(
                str(Path(item.path) / "ghdl" / "wave.vcd"),
                str(out_dir_wave / "wave_dac.vcd"),
            )

vu = VUnit.from_argv()
vu.add_vhdl_builtins()
vu.enable_location_preprocessing()

ROOT = Path(__file__).parent

lib = vu.add_library("lib").add_source_files([
  ROOT / "tb_dac.vhd", 
  ROOT / "../../wr-cores/modules/wr_dacs/serial_dac856x.vhd"
])

vu.main(post_run=post_func)
