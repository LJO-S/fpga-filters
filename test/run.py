#!/usr/bin/env python3

# ============================================================
from pathlib import Path
from vunit import VUnit

import sys
import os

sys.path.append("../")
from scripts.model.polyphase_filter import Polyphase_interpolate
from scripts.synth_and_test.polyphase_filter import polyphase_intepolate_checker


# ============================================================
def encode(config: dict) -> str:
    return ", ".join(["%s:%s" % (key, str(config[key])) for key in config])


# ============================================================
# Setup

VU = VUnit.from_argv(compile_builtins=False)
VU.add_vhdl_builtins()

# Enable location preprocessing but exclude all but check_false to make the example less bloated
VU.enable_location_preprocessing(
    exclude_subprograms=[
        "debug",
        "info",
        "check",
        "check_failed",
        "check_true",
        "check_implication",
        "check_stable",
        "check_equal",
        "check_not_unknown",
        "check_zero_one_hot",
        "check_one_hot",
        "check_next",
        "check_sequence",
        "check_relation",
    ]
)
VU.enable_check_preprocessing()

# ============================================================
# Directories

# Source directory
src_dir = (Path(__file__).parent / ".." / "src").resolve()

# Testbench directory
tb_dir = (Path(__file__).parent).resolve()

# Waveform .do directory
wave_dir = (Path(__file__).parent / "wave").resolve()

lib = VU.add_library("lib")

# ============================================================
# Add sources
for src_file in src_dir.rglob("*.vhd"):
    lib.add_source_file(src_file)

# ============================================================
# Add testbenches
for tb_file in tb_dir.rglob("tb_*"):
    if tb_file.is_relative_to(tb_dir / "vunit_out"):
        # Skipping vunit_out directory
        continue
    if tb_file.is_relative_to(tb_dir / "wave"):
        # Skipping .do directory
        continue
    lib.add_source_file(tb_file)

# ============================================================
# Add waves
for tb in lib.get_test_benches():
    wave_do = wave_dir / f"{tb.name}.do"
    if wave_do.is_file():
        print(f"- Found existing .do file at: {wave_do}\r")
        tb.set_sim_option("modelsim.init_file.gui", "launch.tcl")
        tb.set_sim_option(
            "modelsim.vsim_flags.gui",
            [
                "-t 1ps",
                "-fsmdebug",
                '-voptargs="+acc"',
                "-coverage",
                "-debugDB",
                "-do",
                f"{{{wave_do.as_posix()}}}",
            ],
        )
    else:
        print(f"- No existing .do file for {tb.name}. Running add_waveforms.tcl\r")
        tb.set_sim_option("modelsim.init_file.gui", "add_waveforms.tcl")
        tb.set_sim_option(
            "modelsim.vsim_flags.gui",
            ["-t 1ps", "-fsmdebug", '-voptargs="+acc"', "-coverage", "-debugDB"],
        )
# ============================================================
# Add test configs

# --------------------
# Polyphase Interpolate
# --------------------
testbench = lib.entity("polyphase_interpolate_tb")
test = testbench.test("auto")

# Configuration
G_DATA_WIDTH = 28
FS = 50.0e3
L = 4
FPASS = 13.0e3
FSTOP = (FS / 2) - FPASS
while FSTOP < FPASS:
    FSTOP += 0.1 * FS
    if FSTOP > FS / 2:
        raise ValueError("FSTOP too large!")

cfg = dict(
    fpass=FPASS,
    fstop=FSTOP,
    atten_db=60,
    fs=FS,
    multirate_factor=L,
    G_DATA_WIDTH=G_DATA_WIDTH,
)

# Generate taps etc
polyphase_obj = Polyphase_interpolate(
    a_fpass=cfg["fpass"],
    a_fstop=cfg["fstop"],
    a_atten_db=cfg["atten_db"],
    a_fs=cfg["fs"],
    a_multirate_factor=cfg["multirate_factor"],
    a_data_width=cfg["G_DATA_WIDTH"],
)

polyphase_checker_obj = polyphase_intepolate_checker(a_polyphase_object=polyphase_obj)

test.add_config(
    name=f'L={cfg["multirate_factor"]}_FS={cfg["fs"]}',
    generics=dict(
        G_DATA_WIDTH=cfg["G_DATA_WIDTH"],
        G_COEFF_WIDTH=cfg["G_DATA_WIDTH"],
        G_FILTER_ORDER=len(polyphase_obj.taps_prototype),
        G_MULTIRATE_FACTOR=cfg["multirate_factor"],
        G_INIT_FILE=f'DUC{cfg["multirate_factor"]}_{cfg["G_DATA_WIDTH"]}b_fpass{int(cfg["fpass"])}_fstop{int(cfg["fstop"])}_fs{int(cfg["fs"])}.txt',
    ),
    pre_config=polyphase_checker_obj.pre_config_wrapper(
        a_input_samples=1024, a_cfg=cfg
    ),
    # post_check=polyphase_checker_obj.post_check_wrapper(a_cfg=cfg),
)

# And another testbench etc.
# ============================================================

VU.add_compile_option("modelsim.vcom_flags", ["+acc=npr", '+cover="sbcef'])

VU.main()
