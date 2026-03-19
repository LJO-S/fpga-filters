#!/usr/bin/env python3

import math
from scipy.signal import remez, freqz
from matplotlib import pyplot as plt
import numpy as np
from pathlib import Path


def __two_stage_decimation_factors(
    a_fstop: float, a_fpass: float, a_decimation_factor: int
):
    freq_ratio = (a_fstop - a_fpass) / a_fstop
    m_1_opt = (
        2
        * a_decimation_factor
        * (1 - math.sqrt((a_decimation_factor * freq_ratio) / (2 - freq_ratio)))
        / (2 - freq_ratio * (a_decimation_factor + 1))
    )
    m_1 = int(math.ceil(m_1_opt))
    while a_decimation_factor % m_1 != 0:
        m_1 += 1
    m_2 = a_decimation_factor / m_1
    return m_1, m_2


def _calculate_nbr_of_taps(
    a_attenuation_db: float, a_fstop: float, a_fpass: float, a_fs: float
):
    """
    Calculate number of taps required for desired atten, fstop and fpass in a LPF.
    Uses Fred Harris "rule-of-thumb" formula
    """
    return int(math.ceil(a_fs * a_attenuation_db / (22 * abs(a_fstop - a_fpass))))


def __plot_response(a_w, a_h, a_atten_db, a_taps, a_title):
    """
    Utility function to plot response functions
    """
    fig = plt.figure()
    ax1 = fig.add_subplot(211)
    ax1.plot(a_w, 20 * np.log10(np.abs(a_h)))
    ax1.set_ylim(-a_atten_db, 5)
    ax1.grid(True)
    ax1.set_xlabel("Frequency (Hz)")
    ax1.set_ylabel("Gain (dB)")
    ax1.set_title(a_title)
    ax2 = fig.add_subplot(212)
    ax2.plot(a_taps)
    ax2.grid(True)
    ax2.set_xlabel("Coefficient Index")
    ax2.set_ylabel("N/A")
    ax2.set_title(f"{a_title} Coefficients")


def __dump_taps_to_txt(a_taps: np.array, a_data_width: int, a_output_path: Path):
    a_output_path.parent.mkdir(exist_ok=True, parents=True)
    with open(a_output_path, "w") as f:
        for coeff in a_taps:
            # 1. Convert to fixed-point
            fixed_point_val = int(round(coeff * (2.0**a_data_width)))

            if a_data_width <= 0:
                raise ValueError(f"Invalid width: {a_data_width}")

            # 2. Format as binary string
            # produce two's-complement bit pattern of 'width' bits
            mask = (1 << a_data_width) - 1
            val_masked = mask & fixed_point_val
            coeff_bstring = format(val_masked, f"0{a_data_width}b")
            if len(coeff_bstring) != a_data_width:
                raise ValueError(
                    "Binary string was longer than allowed depth! Actual=",
                    len(coeff_bstring),
                    "vs Expected=",
                    a_data_width,
                )
            f.write(f"{coeff_bstring}\n")


def generate_coefficients_remez(
    a_attenuation_db: float,
    a_gain: float,
    a_fstop: list,
    a_fpass: list,
    a_fs: float,
    a_data_width: int,
    a_output_dir: str = f"../data/filter_coefficients/",
    a_multirate_factor: int = None,
    a_save: bool = True,
):
    """
    Use SciPy's implementation of the Parks-McClellan algorithm. Works for LPF and HPF.
    """
    fpass_1 = a_fpass[0]
    fstop_1 = a_fstop[0]
    fpass_2 = 0
    fstop_2 = 0
    bpf_en = False
    if len(a_fstop) > 1:
        assert len(a_fstop) == 2, "No more than 2 stop frequences allowed!"
        assert len(a_fpass) == 2, "Expected 2 fpass since 2 fstop was specified!"
        bpf_en = True
        fpass_2 = a_fpass[1]
        fstop_2 = a_fstop[1]

    # Get maximum number of taps required
    nbr_of_taps_1 = _calculate_nbr_of_taps(
        a_attenuation_db=a_attenuation_db, a_fstop=fstop_1, a_fpass=fpass_1, a_fs=a_fs
    )
    nbr_of_taps = nbr_of_taps_1

    bands = list()
    if bpf_en:
        # BPF
        nbr_of_taps_2 = _calculate_nbr_of_taps(
            a_attenuation_db=a_attenuation_db,
            a_fstop=fstop_2,
            a_fpass=fpass_2,
            a_fs=a_fs,
        )
        nbr_of_taps = max(nbr_of_taps_1, nbr_of_taps_2)
        bands = [0, fstop_1, fpass_1, fpass_2, fstop_2, 0.5 * a_fs]
        gain = [0, a_gain, 0]
        title = "BPF"
    elif fstop_1 > fpass_1:
        # LPF
        bands = [0, fpass_1, fstop_1, 0.5 * a_fs]
        gain = [a_gain, 0]
        title = "LPF"
    else:
        # HPF
        bands = [0, fstop_1, fpass_1, 0.5 * a_fs]
        gain = [0, a_gain]
        title = "HPF"

    # Create odd number of taps
    if a_multirate_factor is None:
        if nbr_of_taps % 2 == 0:
            nbr_of_taps += 1
    else:
        while nbr_of_taps % a_multirate_factor != 0:
            nbr_of_taps += 1

    print(
        f"=====================\nGenerating {title} with:\nN_taps={nbr_of_taps}\nBands_hz={bands}\nG={gain}\n=====================\n"
    )

    # Remez Exchange algorithm (parks-mcclellan)
    taps = remez(
        numtaps=nbr_of_taps,
        bands=bands,
        desired=gain,
        fs=a_fs,
    )

    # Get coefficients
    # TODO: Save fig instead
    w, h = freqz(taps, [1], worN=2000, fs=a_fs)
    __plot_response(
        a_w=w, a_h=h, a_atten_db=a_attenuation_db, a_taps=taps, a_title=title
    )
    if a_save:
        # Dump coefficients
        output_path = Path(a_output_dir) / f"{title}_{a_data_width}b.txt"
        __dump_taps_to_txt(
            a_taps=taps, a_data_width=a_data_width, a_output_path=output_path
        )
    else:
        plt.show()
    return taps


def generate_coefficients_least_squares():
    """
    Use SciPy's implementation of the Least Squares method.
    """
    pass


def generate_coefficients_window():
    """
    Use SciPy's implementation of the Window method.
    """
    pass


if __name__ == "__main__":
    fs = 10.0e3
    fpass = [2.0e3]
    fstop = [2.5e3]
    a_db = 60
    generate_coefficients_remez(
        a_attenuation_db=a_db, a_fstop=fstop, a_fpass=fpass, a_fs=fs, a_data_width=28
    )
