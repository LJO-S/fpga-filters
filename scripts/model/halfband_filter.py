import math
import numpy as np
from matplotlib import pyplot as plt
from collections import deque
from pathlib import Path
from bitstring import BitArray


from scripts.synth_and_test.generate_filter_coefficients import (
    generate_coefficients_remez, generate_coefficients_firwin
)


class Halfband_filter:
    def __init__(
        self,
        a_fpass: float,
        a_fstop: float,
        a_gain: float,
        a_atten_db: float,
        a_fs: int,
        a_data_width: int = 16,
        a_plot_coeffs: bool = False,
    ):
        # Characteristics
        self.fpass = a_fpass
        self.fstop = a_fstop
        self.atten_db = a_atten_db
        self.fs = a_fs
        self.data_width = a_data_width

        # Generate filter coefficients
        try: 
            self.taps_prototype = generate_coefficients_remez(
                a_attenuation_db=a_atten_db,
                a_gain=a_gain,
                a_fstop=[a_fstop],
                a_fpass=[a_fpass],
                a_fs=self.fs,
                a_multirate_factor=None,
                a_plot=a_plot_coeffs,
            )
            if np.isnan(self.taps_prototype).any():
                raise ValueError
        except:
            self.taps_prototype = generate_coefficients_firwin(
                a_attenuation_db=a_atten_db,
                a_gain=a_gain,
                a_fstop=[a_fstop],
                a_fpass=[a_fpass],
                a_fs=self.fs,
                a_multirate_factor=None,
                a_plot=a_plot_coeffs,
            )
        print(self.taps_prototype)
        self.taps_prototype[np.abs(self.taps_prototype) <= 1e-4] = 0.0
        # The nbr of taps are odd, but the code below re-uses a interpolate-by-2 structure
        self.taps_prototype = list(self.taps_prototype)
        self.taps_prototype.append(0.0)

        # Generate Polyphase structure
        self.taps_polyphase = np.zeros((2, len(self.taps_prototype) // 2))
        for i, coeff in enumerate(self.taps_prototype):
            # Create polyphase matrix
            self.taps_polyphase[i % 2][i // 2] = coeff
        print(self.taps_polyphase)
        self.shift_register = [
            deque([0.0] * self.taps_polyphase.shape[1]) for _ in range(2)
        ]
        self.input_data = list()

    def dump_to_txt(self, a_output_dir, a_order_idx):
        # Dump coefficients
        output_path = Path(a_output_dir) / f"HBF_{self.data_width}_{a_order_idx}.txt"
        output_path.parent.mkdir(exist_ok=True, parents=True)
        with open(output_path, "w") as f:
            for _, coeff in enumerate(self.taps_prototype):
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


class Halfband_interpolate_part:
    def __init__(
        self,
        a_fpass: float,
        a_fstop: float,
        a_atten_db: float,
        a_fs: int,
        a_data_width: int = 16,
    ):
        # Characteristics
        self.fpass = a_fpass
        self.fstop = a_fstop
        self.atten_db = a_atten_db
        self.fs = a_fs
        self.data_width = a_data_width

        self.filter_obj = Halfband_filter(
            a_fpass=a_fpass,
            a_fstop=a_fstop,
            a_gain=2.0,
            a_atten_db=a_atten_db,
            a_fs=a_fs,
        )

    def tick(self, a_new_sample):
        # Push new sample into delay line
        result = list()
        for phase in range(2):
            self.filter_obj.shift_register[phase].appendleft(a_new_sample)
            self.filter_obj.shift_register[phase].pop()
            result.append(
                np.dot(self.filter_obj.taps_polyphase[phase], self.filter_obj.shift_register[phase])
            )
        return result

    def dump_to_txt(self, a_output_dir):
        self.filter_obj.dump_to_txt(a_output_dir=a_output_dir)


class Halfband_decimate_part:
    def __init__(
        self,
        a_fpass: float,
        a_fstop: float,
        a_atten_db: float,
        a_fs: int,
        a_data_width: int = 16,
    ):
        # Characteristics
        self.fpass = a_fpass
        self.fstop = a_fstop
        self.atten_db = a_atten_db
        self.fs = a_fs
        self.data_width = a_data_width
        self.ddc_counter = 0

        self.filter_obj = Halfband_filter(
            a_fpass=a_fpass,
            a_fstop=a_fstop,
            a_gain=1.0,
            a_atten_db=a_atten_db,
            a_fs=a_fs,
        )
        self.input_register = [
            deque([0.0] * self.taps_polyphase.shape[1]) for _ in range(2)
        ]

    def tick(self, a_new_sample):
        # Push new sample into input delay line
        self.input_register.appendleft(a_new_sample)
        self.input_register.pop()
        # Compute output every M samples
        self.ddc_counter += 1
        if self.ddc_counter % 2 == 0:
            result = 0
            for phase in range(2):
                # Update the delay line of each sub-filter with its respective sample
                self.filter_obj.shift_register[phase].appendleft(
                    self.input_register[phase]
                )
                self.filter_obj.shift_register[phase].pop()
                # Accumulate the "Multiply-and-Accumulate"
                result += np.dot(
                    self.filter_obj.taps_polyphase[phase], self.shift_register[phase]
                )
            # Increment decimate counter
            return result
        return None

    def dump_to_txt(self, a_output_dir):
        self.filter_obj.dump_to_txt(a_output_dir=a_output_dir)


class Halfband_interpolate:
    def __init__(
        self,
        a_fpass: float,
        a_atten_db: float,
        a_fs: int,
        a_multirate_factor: int,
        a_data_width: int = 16,
    ):
        # Characteristics
        self.fpass = a_fpass
        self.atten_db = a_atten_db
        self.fs = a_fs
        self.multirate_factor = a_multirate_factor
        self.data_width = a_data_width

        assert a_multirate_factor % 2 == 0, f"L={a_multirate_factor} is NOT a pow-of-2"

        self.interpolate_chain = list()

        fs_new = a_fs
        for i in range(int(np.ceil(np.log2(a_multirate_factor)))):
            delta = (
                fs_new / 2 - a_fpass
            ) * 2  # this might look complex but is actually pretty intuitive if you draw it
            fs_new *= 2
            fpass = fs_new / 4 - (delta / 2)
            fstop = fs_new / 4 + (delta / 2)
            print("idx ",i)
            print("delta ", delta)
            print("fsnew ", fs_new)
            print("fpass ", fpass)
            print("fstop ", fstop)
            # Append to the chain of interpolate-by-2
            self.interpolate_chain.append(
                Halfband_interpolate_part(
                    a_fpass=fpass,
                    a_fstop=fstop,
                    a_atten_db=a_atten_db,
                    a_fs=fs_new,
                    a_data_width=a_data_width,
                )
            )

    def tick(self, a_new_sample):
        # Depth of chain
        num_stages = int(np.ceil(np.log2(self.multirate_factor)))
        result = [[] for _ in range(num_stages)]

        # Stage 0: first interpolation
        result[0] = self.interpolate_chain[0].tick(a_new_sample=a_new_sample)

        # Stages 1 to N: chained interpolation
        for l_idx in range(1, num_stages):
            prev_stage_samples = result[l_idx - 1]
            curr_stage_output = [0.0] * (len(prev_stage_samples) * 2)
            for s_idx, s in enumerate(prev_stage_samples):
                curr_stage_output[2 * s_idx : 2 * s_idx + 2] = self.interpolate_chain[l_idx].tick(a_new_sample=s)
            result[l_idx] = curr_stage_output
        return result[-1]

    def dump_to_txt(self, a_output_dir: str):
        for interpolate_part in self.interpolate_chain:
            interpolate_part.dump_to_txt(a_output_path=a_output_dir)


if __name__ == "__main__":
    # ================================
    # TYPE
    INTERPOLATE = False
    # ================================
    # PARAMETERS
    FS = 48.8e3
    INPUT_FREQ = 0.1 * FS
    FPASS = 0.2 * FS
    ATTEN_DB = 60
    L = 16
    # ================================
    # A. Generate 1/10 FS sine
    N = 1024
    t = np.arange(N) * (1 / FS)
    input_data = np.sin(2 * np.pi * (INPUT_FREQ) * t)

    # B. Create Polyphase filter
    filter_obj = Halfband_interpolate(
        a_fpass=FPASS,
        a_atten_db=ATTEN_DB,
        a_fs=FS,
        a_multirate_factor=L,
    )
    result = list()
    for input in input_data:
        output = filter_obj.tick(a_new_sample=input)
        for res in output:
            result.append(res)
    fig = plt.figure()
    # ----------------------------------------------------------
    ax1 = fig.add_subplot(221)
    ax1.plot(input_data, marker="o")
    ax1.grid(True)
    # ----------------------------------------------------------
    ax2 = fig.add_subplot(223)
    ax2.plot(result, marker="o")
    ax2.grid(True)
    # ----------------------------------------------------------
    x_axis_freq = np.fft.rfftfreq(len(t), 1 / FS)
    fft_input = np.fft.rfft(input_data)
    magnitude = np.maximum(np.abs(fft_input), 1e-12)
    magnitudeDB = 20 * np.log10(magnitude)
    ax3 = fig.add_subplot(222)
    ax3.plot(x_axis_freq, magnitudeDB)
    ax3.set_ylim(-10, 100)
    ax3.grid(True)
    # ----------------------------------------------------------
    new_fs = FS * L
    t = np.arange(N * L) * (1 / new_fs)
    x_axis_freq = np.fft.rfftfreq(len(t), 1 / new_fs)
    fft_output = np.fft.rfft(result)
    magnitude = np.maximum(np.abs(fft_output), 1e-12)
    magnitudeDB = 20 * np.log10(magnitude)
    ax4 = fig.add_subplot(224)
    ax4.plot(x_axis_freq, magnitudeDB)
    ax4.set_ylim(-10, 100)
    ax4.grid(True)
    plt.show()

    # print("Hello world!")
