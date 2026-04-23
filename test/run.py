#!/usr/bin/env python3

# ============================================================
from pathlib import Path
from shutil import rmtree
from vunit import VUnit, VUnitCLI
from vunit.vivado import *

import sys
import os

sys.path.append("../")
from scripts.model.polyphase_filter import Polyphase_interpolate, Polyphase_decimate
from scripts.model.halfband_filter import Halfband_interpolate, Halfband_decimate
from scripts.model.cic_filter import cic_decimate, cic_interpolate
from scripts.synth_and_test.polyphase_filter import polyphase_intepolate_checker, polyphase_decimate_checker
from scripts.synth_and_test.halfband_filter import halfband_intepolate_checker, halfband_decimate_checker
from scripts.synth_and_test.cic_filter import cic_decimate_checker


# ============================================================
def encode(config: dict) -> str:
    return ", ".join(["%s:%s" % (key, str(config[key])) for key in config])


# ============================================================
# Setup
cli = VUnitCLI(description="VUnit project with Vivado Synthesis support")
cli.parser.add_argument(
    "--synth",
    type=str,
    default=None,
    help="Run Vivado synthesis on the specified entity",
)
cli.parser.add_argument(
    "--batch",
    action="store_true",
    default=False,
    help="Run in batch mode",
)
args = cli.parse_args()

VU = VUnit.from_args(args=args, compile_builtins=False)
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

# -----------------------------------------------------------------------
# Polyphase Interpolate
# Parallel
# -----------------------------------------------------------------------
testbench = lib.entity("polyphase_interpolate_parallel_tb")
test = testbench.test("auto")

# Configuration
G_DATA_WIDTH = 16
FS = 80.0e3
L = 8
FPASS = 13.0e3
# TODO
FSTOP = (FS / 2) - FPASS
while FSTOP < FPASS:
    FSTOP += 0.1 * FS
    if FSTOP > FS / 2:
        raise ValueError("FSTOP too large!")

cfg = dict(
    input_frequency=0.8 * FPASS,
    fpass=FPASS,
    fstop=FSTOP,
    atten_db=60,
    fs=FS,
    multirate_factor=L,
    G_DATA_WIDTH=G_DATA_WIDTH,
    G_DATA_WIDTH_FRAC=G_DATA_WIDTH - 2,
    G_COEFF_WIDTH=G_DATA_WIDTH,
)

# Generate taps etc
polyphase_obj = Polyphase_interpolate(
    a_fpass=cfg["fpass"],
    a_fstop=cfg["fstop"],
    a_atten_db=cfg["atten_db"],
    a_fs=cfg["fs"],
    a_multirate_factor=cfg["multirate_factor"],
    a_data_width=cfg["G_COEFF_WIDTH"],
)

polyphase_checker_obj = polyphase_intepolate_checker(a_polyphase_object=polyphase_obj)

test.add_config(
    name=f'L={cfg["multirate_factor"]}_FS={int(cfg["fs"])}',
    generics=dict(
        G_DATA_WIDTH=cfg["G_DATA_WIDTH"],
        G_COEFF_WIDTH=cfg["G_COEFF_WIDTH"],
        G_FILTER_ORDER=len(polyphase_obj.taps_prototype),
        G_MULTIRATE_FACTOR=cfg["multirate_factor"],
        G_INIT_FILE=f'DUC{cfg["multirate_factor"]}_{cfg["G_DATA_WIDTH"]}b_fpass{int(cfg["fpass"])}_fstop{int(cfg["fstop"])}_fs{int(cfg["fs"])}.txt',
    ),
    pre_config=polyphase_checker_obj.pre_config_wrapper(
        a_input_samples=1024, a_cfg=cfg
    ),
    post_check=polyphase_checker_obj.post_check_wrapper(a_cfg=cfg, a_save_plot=True),
)

# -----------------------------------------------------------------------
# Polyphase Interpolate
# Sequential
# -----------------------------------------------------------------------
testbench = lib.entity("polyphase_interpolate_sequential_tb")
test = testbench.test("auto")

# Configuration
G_DATA_WIDTH = 16
FS = 80.0e3
L = 8
FPASS = 13.0e3
FSTOP = (FS / 2) - FPASS
while FSTOP < FPASS:
    FSTOP += 0.1 * FS
    if FSTOP > FS / 2:
        raise ValueError("FSTOP too large!")

cfg = dict(
    input_frequency=0.8 * FPASS,
    fpass=FPASS,
    fstop=FSTOP,
    atten_db=60,
    fs=FS,
    multirate_factor=L,
    G_DATA_WIDTH=G_DATA_WIDTH,
    G_DATA_WIDTH_FRAC=G_DATA_WIDTH - 2,
    G_COEFF_WIDTH=G_DATA_WIDTH,
)

# Generate taps etc
polyphase_obj = Polyphase_interpolate(
    a_fpass=cfg["fpass"],
    a_fstop=cfg["fstop"],
    a_atten_db=cfg["atten_db"],
    a_fs=cfg["fs"],
    a_multirate_factor=cfg["multirate_factor"],
    a_data_width=cfg["G_COEFF_WIDTH"],
)

polyphase_checker_obj = polyphase_intepolate_checker(a_polyphase_object=polyphase_obj)

test.add_config(
    name=f'L={cfg["multirate_factor"]}_FS={int(cfg["fs"])}',
    generics=dict(
        G_DATA_WIDTH=cfg["G_DATA_WIDTH"],
        G_COEFF_WIDTH=cfg["G_COEFF_WIDTH"],
        G_FILTER_ORDER=len(polyphase_obj.taps_prototype),
        G_MULTIRATE_FACTOR=cfg["multirate_factor"],
        G_INIT_FILE=f'DUC{cfg["multirate_factor"]}_{cfg["G_DATA_WIDTH"]}b_fpass{int(cfg["fpass"])}_fstop{int(cfg["fstop"])}_fs{int(cfg["fs"])}.txt',
    ),
    pre_config=polyphase_checker_obj.pre_config_wrapper(
        a_input_samples=1024, a_cfg=cfg
    ),
    post_check=polyphase_checker_obj.post_check_wrapper(a_cfg=cfg, a_save_plot=True),
)

# -----------------------------------------------------------------------
# Polyphase Decimate
# Sequential
# -----------------------------------------------------------------------
testbench = lib.entity("polyphase_decimate_sequential_tb")
test = testbench.test("auto")

# Configuration
G_DATA_WIDTH = 16
FS = 160.0e3
M = 8
FPASS = 13.0e3
FSTOP = (FS/2) - FPASS
while FSTOP < FPASS:
    FSTOP += 0.1 * FS
    if FSTOP > FS / 2:
        raise ValueError("FSTOP too large!")

cfg = dict(
    input_frequency=0.8 * FPASS,
    fpass=FPASS,
    fstop=FSTOP,
    atten_db=60,
    fs=FS,
    multirate_factor=M,
    G_DATA_WIDTH=G_DATA_WIDTH,
    G_DATA_WIDTH_FRAC=G_DATA_WIDTH - 2,
    G_COEFF_WIDTH=G_DATA_WIDTH,
)

# Generate taps etc
polyphase_obj = Polyphase_decimate(
    a_fpass=cfg["fpass"],
    a_fstop=cfg["fstop"],
    a_atten_db=cfg["atten_db"],
    a_fs=cfg["fs"],
    a_multirate_factor=cfg["multirate_factor"],
    a_data_width=cfg["G_COEFF_WIDTH"],
)

polyphase_checker_obj = polyphase_decimate_checker(a_polyphase_object=polyphase_obj)

test.add_config(
    name=f'M={cfg["multirate_factor"]}_FS={int(cfg["fs"])}',
    generics=dict(
        G_DATA_WIDTH=cfg["G_DATA_WIDTH"],
        G_COEFF_WIDTH=cfg["G_COEFF_WIDTH"],
        G_FILTER_ORDER=len(polyphase_obj.taps_prototype),
        G_MULTIRATE_FACTOR=cfg["multirate_factor"],
        G_INIT_FILE=f'DDC{cfg["multirate_factor"]}_{cfg["G_DATA_WIDTH"]}b_fpass{int(cfg["fpass"])}_fstop{int(cfg["fstop"])}_fs{int(cfg["fs"])}.txt',
    ),
    pre_config=polyphase_checker_obj.pre_config_wrapper(
        a_input_samples=1024*16, a_cfg=cfg
    ),
    post_check=polyphase_checker_obj.post_check_wrapper(a_cfg=cfg, a_save_plot=True),
)

# -----------------------------------------------------------------------
# Halfband Interpolate
# Sequential
# -----------------------------------------------------------------------
testbench = lib.entity("halfband_interpolate_sequential_tb")
test = testbench.test("auto")

# Configuration
G_DATA_WIDTH = 16
FS = 48.8e3
L = 32
FPASS = 13.2e3

cfg = dict(
    input_frequency=0.8 * FPASS,
    fpass=FPASS,
    atten_db=60,
    fs=FS,
    multirate_factor=L,
    G_DATA_WIDTH=G_DATA_WIDTH,
    G_DATA_WIDTH_FRAC=G_DATA_WIDTH - 2,
    G_COEFF_WIDTH=G_DATA_WIDTH,
)

# Generate taps etc
halfband_interpolate_obj = Halfband_interpolate(
    a_fpass=cfg["fpass"],
    a_atten_db=cfg["atten_db"],
    a_fs=cfg["fs"],
    a_multirate_factor=cfg["multirate_factor"],
    a_data_width=cfg["G_COEFF_WIDTH"],
)
# Generate package file for synthesis
halfband_interpolate_obj.generate_vhdl_package(a_jinja_path="../scripts/synth_and_test/jinja", a_output_path="../src/halfband/interpolate/halfband_interpolate_pkg.vhd")

halfband_checker_obj = halfband_intepolate_checker(a_halfband_object=halfband_interpolate_obj)

test.add_config(
    name=f'L={cfg["multirate_factor"]}_FS={int(cfg["fs"])}',
    generics=dict(
        G_DATA_WIDTH=cfg["G_DATA_WIDTH"],
        G_COEFF_WIDTH=cfg["G_COEFF_WIDTH"],
        G_MULTIRATE_FACTOR=cfg["multirate_factor"],
        G_INIT_FILE=f'HBF_{cfg["G_COEFF_WIDTH"]}',
    ),
    pre_config=halfband_checker_obj.pre_config_wrapper(
        a_input_samples=256, a_cfg=cfg
    ),
    post_check=halfband_checker_obj.post_check_wrapper(a_cfg=cfg, a_save_plot=True),
)

# -----------------------------------------------------------------------
# Halfband Decimate
# Sequential
# -----------------------------------------------------------------------
testbench = lib.entity("halfband_decimate_tb")
test = testbench.test("auto")

# Configuration
G_DATA_WIDTH = 16
M = 2
FS = 48.8e3 * M
FPASS = 13.2e3

cfg = dict(
    input_frequency=0.8 * FPASS,
    fpass=FPASS,
    atten_db=60,
    fs=FS,
    multirate_factor=M,
    G_DATA_WIDTH=G_DATA_WIDTH,
    G_DATA_WIDTH_FRAC=G_DATA_WIDTH - 2,
    G_COEFF_WIDTH=G_DATA_WIDTH,
)

# Generate taps etc
halfband_decimate_obj = Halfband_decimate(
    a_fpass=cfg["fpass"],
    a_atten_db=cfg["atten_db"],
    a_fs=cfg["fs"],
    a_multirate_factor=cfg["multirate_factor"],
    a_data_width=cfg["G_COEFF_WIDTH"],
)

# Generate VHDL package for synthesis
halfband_decimate_obj.generate_vhdl_package(
    a_jinja_path="../scripts/synth_and_test/jinja",
    a_output_path="../src/halfband/decimate/halfband_decimate_pkg.vhd"
)

halfband_checker_obj = halfband_decimate_checker(a_halfband_object=halfband_decimate_obj)

test.add_config(
    name=f'M={cfg["multirate_factor"]}_FS={int(cfg["fs"])}',
    generics=dict(
        G_DATA_WIDTH=cfg["G_DATA_WIDTH"],
        G_COEFF_WIDTH=cfg["G_COEFF_WIDTH"],
        G_MULTIRATE_FACTOR=cfg["multirate_factor"],
        G_INIT_FILE=f'HBF_{cfg["G_COEFF_WIDTH"]}',
    ),
    pre_config=halfband_checker_obj.pre_config_wrapper(
        a_input_samples=256*16, a_cfg=cfg),
    post_check=halfband_checker_obj.post_check_wrapper(a_cfg=cfg, a_save_plot=True),
)

# -----------------------------------------------------------------------
# CIC Decimate
# -----------------------------------------------------------------------
testbench = lib.entity("cic_decimate_tb")
test = testbench.test("auto")

# Configuration
G_DATA_WIDTH = 16
M = 8
FS = 100e3 * M
FPASS = 13.2e3

cfg = dict(
    input_frequency=0.8 * FPASS,
    fpass=FPASS,
    atten_db=60,
    fs=FS,
    multirate_factor=M,
    G_DATA_WIDTH=G_DATA_WIDTH,
    G_DATA_WIDTH_FRAC=G_DATA_WIDTH - 2,
    G_COEFF_WIDTH=G_DATA_WIDTH,
)

# Generate CIC object, FIR coefficients, and CIC order
cic_decimate_obj = cic_decimate(
    a_decimate_factor=cfg["multirate_factor"],
    a_fpass=cfg["fpass"],
    a_fs=cfg["fs"],
    a_atten_db=cfg["atten_db"],
    a_data_width=cfg["G_COEFF_WIDTH"],
)

# Generate VHDL package for synthesis
cic_decimate_obj.generate_vhdl_package(
    a_jinja_path="../scripts/synth_and_test/jinja",
    a_output_path="../src/cic/decimate/cic_decimate_pkg.vhd"
)

cic_decimate_checker_obj = cic_decimate_checker(a_cic_object=cic_decimate_obj)

test.add_config(
    name=f'M={cfg["multirate_factor"]}',
    generics=dict(
        G_DATA_WIDTH=G_DATA_WIDTH,
        G_CIC_ORDER=cic_decimate_obj.order,
        G_MULTIRATE_FACTOR=cfg["multirate_factor"],
        G_INIT_FILE=f'CIC_{cfg["G_COEFF_WIDTH"]}.txt',
    ),
    pre_config=cic_decimate_checker_obj.pre_config_wrapper(
        a_input_samples=1024 * cfg["multirate_factor"], a_cfg=cfg
    ),
    post_check=cic_decimate_checker_obj.post_check_wrapper(a_cfg=cfg, a_save_plot=True),
)

# ============================================================
VU.add_compile_option("modelsim.vcom_flags", ["+acc=npr", '+cover="sbcef'])
# ============================================================
# Synthesize or simulate
if args.synth:
    print(f"--- Starting Vivado Synthesis for entity: {args.synth} ---")
    root = Path(__file__).parent.resolve()
    project_name = "vivado"
    if (root / project_name).exists():
        rmtree(root / project_name)
    # Path to TCL script
    tcl_script = (
        Path(__file__).parent / ".." / "scripts" / "tcl" / "generate_project.tcl"
    )
    try:
        run_vivado(
            tcl_file_name=str(tcl_script),
            tcl_args=[root, project_name, args.synth, src_dir, not (args.batch)],
            vivado_path=None,  # Uses default 'vivado' command
        )
        print("--- Synthesis Complete! ---")
    except Exception as e:
        print(f"Synthesis failed: {e}")
        sys.exit(1)
else:
    VU.main()
