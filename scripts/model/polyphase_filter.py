import math
import numpy as np
from matplotlib import pyplot as plt
from collections import deque
from pathlib import Path
from bitstring import BitArray


from scripts.synth_and_test.generate_filter_coefficients import (
    generate_coefficients_remez,
)


class Polyphase_interpolate:
    def __init__(
        self,
        a_fpass: float,
        a_fstop: float,
        a_atten_db: float,
        a_fs: int,
        a_multirate_factor: int,
        a_data_width: int = 16,
        a_plot_coeffs: bool = False,
    ):
        # Characteristics
        self.fpass = a_fpass
        self.fstop = a_fstop
        self.atten_db = a_atten_db
        self.fs = a_fs
        self.fs_new = a_fs * a_multirate_factor
        self.multirate_factor = a_multirate_factor
        self.data_width = a_data_width

        # Generate prototype filter
        self.taps_prototype = generate_coefficients_remez(
            a_attenuation_db=a_atten_db,
            a_gain=a_multirate_factor,
            a_fstop=[a_fstop],
            a_fpass=[a_fpass],
            a_fs=self.fs_new,
            a_multirate_factor=a_multirate_factor,
            a_plot=a_plot_coeffs,
        )

        # Generate Polyphase structure
        self.taps_polyphase = np.zeros(
            (self.multirate_factor, len(self.taps_prototype) // self.multirate_factor)
        )
        for i, coeff in enumerate(self.taps_prototype):
            # Create polyphase matrix
            self.taps_polyphase[i % self.multirate_factor][
                i // self.multirate_factor
            ] = coeff
        self.shift_register = deque([0.0] * self.taps_polyphase.shape[1])
        self.input_data = list()

    def read_input_data(self, a_input_data: list):
        self.input_data = a_input_data
        return len(self.input_data) // self.taps_polyphase.shape[1]

    def tick(self, a_new_sample):
        # Push new sample into delay line
        self.shift_register.appendleft(a_new_sample)
        self.shift_register.pop()

        result = list()
        shift_register = list(self.shift_register)
        for phase in range(self.multirate_factor):
            result.append(np.dot(self.taps_polyphase[phase], shift_register))
        return result

    def dump_to_txt(self, a_output_dir):
        # Dump coefficients
        output_path = (
            Path(a_output_dir)
            / f"DUC{self.multirate_factor}_{self.data_width}b_fpass{int(self.fpass)}_fstop{int(self.fstop)}_fs{int(self.fs)}.txt"
        )
        output_path.parent.mkdir(exist_ok=True, parents=True)
        with open(output_path, "w") as f:
            for i, coeff in enumerate(self.taps_prototype):
                # 1. Convert to fixed-point
                fixed_point_val = int(round(coeff * (2.0 ** (self.data_width - 1))))

                if self.data_width <= 0:
                    raise ValueError(f"Invalid width: {self.data_width}")

                # 2. Format as binary string
                # produce two's-complement bit pattern of 'width' bits
                mask = (1 << self.data_width) - 1
                val_masked = mask & fixed_point_val
                coeff_bstring = format(val_masked, f"0{self.data_width}b")
                
                if len(coeff_bstring) != self.data_width:
                    raise ValueError(
                        "Binary string was longer than allowed depth! Actual=",
                        len(coeff_bstring),
                        "vs Expected=",
                        self.data_width,
                    )
                f.write(f"{coeff_bstring}\n")


if __name__ == "__main__":
    # ================================
    # PARAMTERS
    FS = 48.8e3
    INPUT_FREQ = 0.1 * FS
    FPASS = INPUT_FREQ
    FSTOP = (FS / 2) - FPASS
    ATTEN_DB = 60
    L = 16
    # ================================
    # A. Generate 1/10 FS sine
    N = 128
    t = np.arange(N) * (1 / FS)
    input_data = np.sin(2 * np.pi * (INPUT_FREQ) * t)

    # B. Create Polyphase filter
    polyphase_obj = Polyphase_interpolate(
        a_fpass=FPASS,
        a_fstop=FSTOP,
        a_atten_db=ATTEN_DB,
        a_fs=FS,
        a_multirate_factor=L,
        a_plot_coeffs=True,
    )
    nbr_iter = polyphase_obj.read_input_data(input_data)
    result = list()
    for input in input_data:
        output = polyphase_obj.tick(input)
        for res in output:
            result.append(res)
    fig = plt.figure()
    ax1 = fig.add_subplot(221)
    ax1.plot(input_data, marker="o")
    # ax1.plot(input_data)
    ax1.grid(True)
    ax2 = fig.add_subplot(223)
    ax2.plot(result, marker="o")
    # ax2.plot(result)
    ax2.grid(True)
    x_axis_freq = np.fft.rfftfreq(len(t), 1 / FS)
    fft_input = np.fft.rfft(input_data)
    magnitude = np.maximum(np.abs(fft_input), 1e-12)
    magnitudeDB = 20 * np.log10(magnitude)
    ax3 = fig.add_subplot(222)
    ax3.plot(x_axis_freq, magnitudeDB)
    ax3.set_ylim(-10, 100)
    ax3.grid(True)
    t = np.arange(N * L) * (1 / (FS * L))
    x_axis_freq = np.fft.rfftfreq(len(t), 1 / (FS * L))
    fft_output = np.fft.rfft(result[91::])
    magnitude = np.maximum(np.abs(fft_output), 1e-12)
    magnitudeDB = 20 * np.log10(magnitude)
    ax4 = fig.add_subplot(224)
    # ax4.plot(x_axis_freq, magnitudeDB)
    ax4.plot(magnitudeDB)
    ax4.set_ylim(-10, 100)
    ax4.grid(True)
    plt.show()

    print("Hello wolrd!")
