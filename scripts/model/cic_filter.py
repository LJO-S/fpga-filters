import numpy as np
from matplotlib import pyplot as plt
from collections import deque
from pathlib import Path
from scipy.signal import firwin2, freqz


class comb:
    def __init__(self, a_order: int, a_register_width: int ):
        self.mask = (1 << a_register_width) - 1
        self.sign_bit = 1 << (a_register_width - 1)
        self.register_width = a_register_width
        self.order = a_order
        self.delay_line = deque([0] * self.order)

    def tick(self, a_new_sample):
        # Compute output
        result = (a_new_sample - self.delay_line[-1]) & self.mask
        # Push new sample into delay line
        self.delay_line.appendleft(a_new_sample & self.mask)
        self.delay_line.pop()
        # Sign-extend
        if result & self.sign_bit:
            return result - (1 << self.register_width)
        return result

class integrator:
    def __init__(self, a_register_width: int):
        self.mask = (1 << a_register_width) - 1
        self.sign_bit = 1 << (a_register_width - 1)
        self.register_width = a_register_width
        self.accumulator = 0

    def tick(self, a_new_sample):
        # Update accumulator
        self.accumulator = (self.accumulator + a_new_sample) & self.mask
        # Sign-extend
        if self.accumulator & self.sign_bit:
            return self.accumulator - (1 << self.register_width)
        return self.accumulator

class cic_decimate:
    def __init__(
        self,
        a_decimate_factor: int,
        a_fpass: float,
        a_fs: float,
        a_n: int = 1,
        a_atten_db: int = 60,
        a_data_width: int = 16,
        a_plot_en: bool = False
    ):
        # Characteristics
        self.data_width = a_data_width
        self.ddc_counter = 0

        # The order is typically 1 or 2 for high-sample rate conversions
        self.R = a_decimate_factor 
        self.D = self.R * a_n
        self.N = self.D // self.R

        # Find order of the filter
        n = np.linspace(-0.5, 0.5, 1000)
        n[n==0] = 1e-12  # Avoid division by zero
        alias_freq_normalized = 1.0 / self.R
        fpass_normalized = a_fpass / a_fs
        alias_band = (n > (alias_freq_normalized - fpass_normalized)) & (n < alias_freq_normalized)
        self.order = 1
        while True:
            # Compute the magnitude response of the CIC filter
            cic_response = np.abs(np.sin(n * np.pi * self.D) / np.sin(n * np.pi)) ** self.order
            cic_response_compare  = cic_response / np.max(cic_response)  # Normalize to 0 dB
            # Check if the response meets the attenuation requirement
            if np.max(cic_response_compare[alias_band]) <= 10 ** (-a_atten_db / 20):
                break
            self.order += 1
            if self.order > 30:  # Arbitrary limit to prevent infinite loop
                raise ValueError("Unable to meet attenuation requirement with reasonable filter order.")
            
        print("Determined CIC filter order:", self.order)

        # Plotting
        if a_plot_en:
            min_val = np.min(20 * np.log10(cic_response_compare[alias_band]))
            plt.figure()
            plt.plot(n, 20 * np.log10(cic_response_compare), label=f"CIC Filter Order {self.order}")
            for i in range(5):
                # Only draw line inside cic_response_compare range
                plt.fill_between(n, min_val - 30, 20 * np.log10(cic_response_compare), where=(n > alias_freq_normalized * i - fpass_normalized) & (n < alias_freq_normalized * i + fpass_normalized), color='r', alpha=0.3, label=f"Aliasing Band {i}" if i == 0 else None)
            # Color the bandwidth between DC and passband edge under the curve
            plt.fill_between(n, min_val - 30, 20 * np.log10(cic_response_compare), where=(np.abs(n) < fpass_normalized), color='g', alpha=0.3, label="Passband")
            # Draw attenuation line
            plt.axhline(-a_atten_db, color='k', linestyle='--', label=f"{a_atten_db} dB Attenuation")
            # Color the bandwidth between aliasing frequency and Nyquist
            plt.xlabel("Frequency")
            plt.ylabel("Magnitude (dB)")
            plt.title("CIC Filter Response")
            plt.ylim(min_val - 30, 5)
            plt.legend()
            plt.grid(True)
            plt.show()

        # Get register width for integrator and comb stages
        self.register_width = a_data_width + self.order * int(np.ceil(np.log2(self.D)))

        # Create integrator stages
        self.integrator_stages = [integrator(a_register_width=self.register_width) for _ in range(self.order)]

        # Create comb stages
        self.comb_stages = [comb(a_order=self.N, a_register_width=self.register_width) for _ in range(self.order)]

        # Generate coefficients for an inverse sinc filter (compensation filter)
        num_taps = 10 * self.order + 1
        coeffs = inverse_sinc_compensation_filter(
            a_num_taps=num_taps,
            a_multirate_factor=1 / self.R,
            a_D=self.D,
            a_Q=self.order,
            a_fpass=a_fpass,
            a_fs=a_fs,
            a_plot_en=a_plot_en
        )
        self.compensation_filter = compensation_fir(a_coefficients=coeffs)

    def tick(self, a_new_sample):
        # Process through integerator stages
        res = int(a_new_sample * ((1 << (self.data_width - 1)) - 1))  # Convert to fixed-point representation

        # Integrate
        for i in range(self.order):
                res = self.integrator_stages[i].tick(res)
        # Decimate
        self.ddc_counter += 1
        if self.ddc_counter % self.R == 0:
            # Comb
            for i in range(self.order):
                res = self.comb_stages[i].tick(res)

            # Convert to float for compensation filter
            res = float(res / ((1 << (self.data_width - 1)) - 1))  # Normalize to [-1, 1]
            
            # Normalize
            res /= self.D ** self.order
            
            # Apply compensation filter
            res = self.compensation_filter.tick(res)
            return res
        else:
            return None

class cic_interpolate:
    def __init__(
        self,
        a_interpolate_factor: int,
        a_fpass: float,
        a_fs: float,
        a_n: int = 1,
        a_atten_db: int = 60,
        a_data_width: int = 16,
        a_plot_en: bool = False
    ):
        # Characteristics
        self.data_width = a_data_width
        self.ddc_counter = 0

        # The order is typically 1 or 2 for high-sample rate conversions
        self.R = a_interpolate_factor 
        self.D = self.R * a_n
        self.N = self.D // self.R

        # Find order of the filter
        n = np.linspace(-0.5, 0.5, 1000)
        n[n==0] = 1e-12  # Avoid division by zero
        image_freq_normalized = 1.0 / self.R
        fpass_normalized = a_fpass / (a_fs * self.R)
        image_band = (n > (image_freq_normalized - fpass_normalized)) & (n < image_freq_normalized)
        self.order = 1
        while True:
            # Compute the magnitude response of the CIC filter
            cic_response = np.abs(np.sin(n * np.pi * self.D) / np.sin(n * np.pi)) ** self.order
            cic_response_compare  = cic_response / np.max(cic_response)  # Normalize to 0 dB
            # Check if the response meets the attenuation requirement
            if np.max(cic_response_compare[image_band]) <= 10 ** (-a_atten_db / 20):
                break
            self.order += 1
            if self.order > 30:  # Arbitrary limit to prevent infinite loop
                raise ValueError("Unable to meet attenuation requirement with reasonable CIC order.")
            
        print("Determined CIC filter order:", self.order)

        # Plotting
        if a_plot_en:
            min_val = np.min(20 * np.log10(cic_response_compare[image_band]))
            plt.figure()
            plt.plot(n, 20 * np.log10(cic_response_compare), label=f"CIC Filter Order {self.order}")
            for i in range(5):
                # Only draw line inside cic_response_compare range
                plt.fill_between(n, min_val - 30, 20 * np.log10(cic_response_compare), where=(n > image_freq_normalized * i - fpass_normalized) & (n < image_freq_normalized * i + fpass_normalized), color='r', alpha=0.3, label=f"Image Band {i}" if i == 0 else None)
            # Color the bandwidth between DC and passband edge under the curve
            plt.fill_between(n, min_val - 30, 20 * np.log10(cic_response_compare), where=(np.abs(n) < fpass_normalized), color='g', alpha=0.3, label="Passband")
            # Draw attenuation line
            plt.axhline(-a_atten_db, color='k', linestyle='--', label=f"{a_atten_db} dB Attenuation")
            # Color the bandwidth between aliasing frequency and Nyquist
            plt.xlabel("Frequency")
            plt.ylabel("Magnitude (dB)")
            plt.title("CIC Filter Response")
            plt.ylim(min_val - 30, 5)
            plt.legend()
            plt.grid(True)
            plt.show()

        # Get register width for integrator and comb stages
        self.register_width = a_data_width + self.order * int(np.ceil(np.log2(self.D)))

        # Create integrator stages
        self.integrator_stages = [integrator(a_register_width=self.register_width) for _ in range(self.order)]

        # Create comb stages
        self.comb_stages = [comb(a_order=self.N, a_register_width=self.register_width) for _ in range(self.order)]

        # Generate coefficients for an inverse sinc filter (compensation filter)
        num_taps = 10 * self.order + 1
        coeffs = inverse_sinc_compensation_filter(
            a_num_taps=num_taps,
            a_multirate_factor=self.R,
            a_D=self.D,
            a_Q=self.order,
            a_fpass=a_fpass,
            a_fs=a_fs,
            a_plot_en=a_plot_en
        )
        self.compensation_filter = compensation_fir(a_coefficients=coeffs)

    def tick(self, a_new_sample):
        # Apply compensation filter
        res = self.compensation_filter.tick(a_new_sample)

        # Convert to fixed-point representation
        res = int(res * ((1 << (self.data_width - 1)) - 1))  

        # Comb
        for i in range(self.order):
                res = self.comb_stages[i].tick(res)

        # Interpolate
        output = list()
        for i in range(self.R):
            # Zero fill
            if i == 0:
                res_interpolated = res
            else:
                res_interpolated = 0

            # Integrate
            for i in range(self.order):
                res_interpolated = self.integrator_stages[i].tick(res_interpolated)

            # Convert to float for compensation filter
            res_interpolated = float(res_interpolated / ((1 << (self.data_width - 1)) - 1))  # Normalize to [-1, 1]
            
            # Normalize
            res_interpolated /= ((self.D) ** self.order) / self.R

            output.append(res_interpolated)
        return output   

class compensation_fir:
    def __init__(self, a_coefficients):
        self.coefficients = a_coefficients
        self.delay_line = deque([0.0] * len(self.coefficients))

    def tick(self, a_new_sample):
        # Update delay line
        self.delay_line.appendleft(a_new_sample)
        self.delay_line.pop()
        # Compute output
        result = 0.0
        for coeff, sample in zip(self.coefficients, self.delay_line):
            result += coeff * sample
        return result

def inverse_sinc_compensation_filter(
        a_num_taps: int, 
        a_multirate_factor: int, 
        a_D: int, 
        a_Q: int, 
        a_fpass: float,
        a_fs: float,
        a_plot_en: bool = False
        ):
    
    # f is the frequency axis for firwin2: 0..1 maps to 0..fs_low/2                                 
    # The compensation filter always runs at the low sample rate (input for interpolation, 
    # output for decimation) so fs_low = a_fs * min(a_multirate_factor, 1)
    f = np.linspace(0, 1, 1000)
    fs_low = a_fs * min(a_multirate_factor, 1.0)
    fpass_normalized = a_fpass / (fs_low / 2)

    # Convert output-Nyquist-normalised f to input-rate-normalised frequency for the CIC formula
    # f=1 (output Nyquist = fs_out/2) 
    R_effective = a_multirate_factor if a_multirate_factor >= 1 else 1.0 / a_multirate_factor
    f_input = f / (2 * R_effective)
    f_input[0] = 1e-12  # avoid division by zero at DC

    # CIC magnitude response: |sin(pi*f*D) / sin(pi*f)|^Q at input-rate-normalised frequencies
    # D = R*M (decimation ratio times differential delay), Q = number of stages
    cic_response = np.abs(np.sin(np.pi * f_input * a_D) / (np.sin(np.pi * f_input))) ** a_Q
    cic_response /= a_D ** a_Q  # remove DC gain D^Q so response is 1.0 at DC

    # Desired response: invert the CIC droop in the passband so the cascade is flat
    # Do not care in the stopband because alias/image rejection is the CIC's job and not the compensation filter's
    desired_response = np.ones_like(f)
    passband = f < (fpass_normalized)
    desired_response[passband] = 1.0 / cic_response[passband]

    # Normalise to unity gain at DC (index 1 is the first non-zero frequency point near DC)
    desired_response /= desired_response[1]

    # Design an FIR with the arbitrary passband/stopband shape using frequency sampling
    coeffs = firwin2(numtaps=a_num_taps, freq=f, gain=desired_response)

    # Plot the frequency response of the compensation filter
    if a_plot_en:
        w, h = freqz(coeffs, worN=2048, fs=fs_low)
        plt.figure()
        ax1 = plt.subplot(211)
        ax1.plot(w, 20 * np.log10(np.abs(h)), label="Compensation FIR")
        ax1.set_title("Frequency Response of Compensation FIR Filter")
        ax1.set_xlabel("Frequency (Hz)")
        ax1.set_ylabel("Magnitude (dB)")    
        ax2 = plt.subplot(212)
        ax2.plot(coeffs, marker="o")
        ax2.set_title("Compensation FIR Coefficients")
        ax2.set_xlabel("Coefficient Index")
        ax2.set_ylabel("Coefficient Value")
        plt.show()
    return coeffs

if __name__ == "__main__":
    # ================================
    # TYPE
    INTERPOLATE = True
    PLOT = True
    # ================================
    # PARAMETERS
    L = 64
    M = 64
    FS = 100
    if not INTERPOLATE:
        FS = FS * M

    INPUT_FREQ = 0.08582347 * (FS / M) if not INTERPOLATE else 0.3 * FS
    FPASS = 0.45 * (FS / M) if not INTERPOLATE else 0.45 * FS

    if INPUT_FREQ >= FPASS:
        raise ValueError(f"Input frequency {INPUT_FREQ} must be less than passband edge {FPASS} to avoid aliasing.")
    # print(FPASS)
    ATTEN_DB = 45
    # ================================
    # A. Generate sine
    N = 1024
    t = np.arange(N) * (1 / FS)
    input_data = np.sin(2 * np.pi * (INPUT_FREQ) * t)

    # B. Create Polyphase filter
    if INTERPOLATE:
        filter_obj = cic_interpolate(
            a_interpolate_factor=L,
            a_fpass=FPASS,
            a_fs=FS,
            a_n=1,
            a_atten_db=ATTEN_DB,
            a_data_width=16,   
            a_plot_en=PLOT 
        )
    else:
        filter_obj = cic_decimate(
            a_decimate_factor=M,
            a_fpass=FPASS,
            a_fs=FS,
            a_n=1,
            a_atten_db=ATTEN_DB,
            a_data_width=16,   
            a_plot_en=PLOT 
        )

    result = list()
    for input in input_data:
        output = filter_obj.tick(a_new_sample=input)
        if INTERPOLATE:
            for res in output:
                result.append(res)
        else:
            if output is not None:
                result.append(output)
    if PLOT:
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
        # Find max frequency component in input signal
        max_freq_index = np.argmax(magnitude)
        max_freq = x_axis_freq[max_freq_index]
        # Print arrow pointing to the max frequency component
        ax3.annotate(f"Input Frequency: {max_freq:.1f} Hz", xy=(max_freq, magnitudeDB[max_freq_index]), xytext=(max_freq, magnitudeDB[max_freq_index] + 10), arrowprops=dict(facecolor='black', shrink=0.05), fontsize=8)
        # ----------------------------------------------------------
        if INTERPOLATE:
            new_fs = FS * L
            t = np.arange(N * L) * (1 / new_fs)
        else:
            new_fs = FS / M
            t = np.arange(N // M) * (1 / new_fs)
        x_axis_freq = np.fft.rfftfreq(len(t), 1 / new_fs)
        fft_output = np.fft.rfft(result)
        magnitude = np.maximum(np.abs(fft_output), 1e-12)
        magnitudeDB = 20 * np.log10(magnitude)
        ax4 = fig.add_subplot(224)
        ax4.plot(x_axis_freq, magnitudeDB)
        ax4.set_ylim(-10, 100)
        ax4.grid(True)
        # Find max frequency component in input signal
        max_freq_index = np.argmax(magnitude)
        max_freq = x_axis_freq[max_freq_index]
        # Print arrow pointing to the max frequency component
        ax4.annotate(f"Output Frequency: {max_freq:.1f} Hz", xy=(max_freq, magnitudeDB[max_freq_index]), xytext=(max_freq, magnitudeDB[max_freq_index] + 10), arrowprops=dict(facecolor='black', shrink=0.05), fontsize=8)
        plt.show()

