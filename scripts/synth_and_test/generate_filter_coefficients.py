#!/usr/bin/env python3

import math
from scipy.signal import remez, firwin, kaiserord, freqz
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


def generate_coefficients_remez(
    a_attenuation_db: float,
    a_gain: float,
    a_fstop: list,
    a_fpass: list,
    a_fs: float,
    a_multirate_factor: int = None,
    a_plot: bool = True,
):
    """
    Use SciPy's implementation of the Parks-McClellan algorithm. Works for LPF and HPF.

    Note: For very large transition bands, this algorithm will break down as the passband and stopband
    become so very tiny so there are not enough distinct frequency points to perform optimiziation. I found
    this out when using the halfband iterations... Works absolutely perfectly for your run-of-the-mill polyphase though!!
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

    # Remez Exchange algorithm (parks-mcclellan)
    taps = remez(
        numtaps=nbr_of_taps,
        bands=bands,
        desired=gain,
        fs=a_fs,
    )

    # Get coefficients
    w, h = freqz(taps, [1], worN=2000, fs=a_fs)
    __plot_response(
        a_w=w, a_h=h, a_atten_db=a_attenuation_db, a_taps=taps, a_title=title
    )
    if a_plot:
        print(
            f"=====================\nGenerated {title} with:\nN_taps={nbr_of_taps}\nBands_hz={bands}\nG={gain}\n=====================\n"
        )
        plt.show()
    return taps


def generate_coefficients_least_squares():
    """
    Use SciPy's implementation of the Least Squares method.
    """
    pass


def generate_coefficients_firwin(
    a_attenuation_db: float,
    a_gain: float,
    a_fstop: list,
    a_fpass: list,
    a_fs: float,
    a_multirate_factor: int = None,
    a_plot: bool = True,
):
    """
    Use SciPy's implementation of the Window method.

    Note: Extremely robust for wide transition bands where Remez fails.
    """
    fpass_1 = a_fpass[0]
    fstop_1 = a_fstop[0]
    fpass_2 = 0
    fstop_2 = 0
    bpf_en = len(a_fstop) > 1
    if bpf_en:
        assert len(a_fstop) == 2, "No more than 2 stop frequences allowed!"
        assert len(a_fpass) == 2, "Expected 2 fpass since 2 fstop was specified!"
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
        cutoff = [(fpass_1 + fstop_1)/2, (fpass2+fstop_2)/2]
        pass_zero = False
        title = "BPF (Window)"
    elif fstop_1 > fpass_1:
        # LPF
        cutoff = (fpass_1 + fstop_1)/2
        pass_zero = True
        title = "LPF (Window)"
    else:
        # HPF
        cutoff = (fpass_1 + fstop_1)/2
        pass_zero = False
        title = "HPF (Window)"

    nbr_of_taps, beta = kaiserord(a_attenuation_db, (fstop_1 - fpass_1) / (0.5 * a_fs))

    # Create odd number of taps
    if a_multirate_factor is None:
        if nbr_of_taps % 2 == 0:
            nbr_of_taps += 1
    else:
        while nbr_of_taps % a_multirate_factor != 0:
            nbr_of_taps += 1

    # FIR Window algorithm (use 'hamming' by default)
    taps = firwin(
        numtaps=nbr_of_taps,
        cutoff=cutoff,
        window=('kaiser', beta),
        pass_zero=pass_zero,
        fs=a_fs,
        scale=False
    )
    taps *= a_gain

    # Get coefficients
    w, h = freqz(taps, [1], worN=2000, fs=a_fs)
    __plot_response(
        a_w=w, a_h=h, a_atten_db=a_attenuation_db, a_taps=taps, a_title=title
    )
    if a_plot:
        print(
            f"=====================\nGenerated {title} with:\nN_taps={nbr_of_taps}\nBands_hz={bands}\nG={gain}\n=====================\n"
        )
        plt.show()
    return taps


if __name__ == "__main__":
    fs = 10.0e3
    fpass = [2.0e3]
    fstop = [2.5e3]
    a_db = 60
    generate_coefficients_remez(
        a_attenuation_db=a_db, a_fstop=fstop, a_fpass=fpass, a_fs=fs
    )
