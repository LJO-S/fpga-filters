import math
import numpy as np
from matplotlib import pyplot as plt
from collections import deque
from pathlib import Path
from bitstring import BitArray

from scripts.synth_and_test.generate_filter_coefficients import (
    generate_coefficients_remez,
)
from scripts.synth_and_test.utils import format_as_bstring, compare_value
from ..model.polyphase_filter import Polyphase_interpolate


class polyphase_intepolate_checker:
    def __init__(self, a_polyphase_object: Polyphase_interpolate):
        self.polyphase_obj: Polyphase_interpolate = a_polyphase_object

    def pre_config_wrapper(self, a_input_samples: int, a_cfg: dict):
        def pre_config(output_path) -> bool:
            # Report info
            if self.polyphase_obj.fstop > self.polyphase_obj.fpass:
                # LPF
                bands = [
                    0,
                    self.polyphase_obj.fpass,
                    self.polyphase_obj.fstop,
                    0.5 * self.polyphase_obj.fs_new,
                ]
                gain = [self.polyphase_obj.multirate_factor, 0]
                title = "LPF"
            else:
                # HPF
                bands = [
                    0,
                    self.polyphase_obj.fstop,
                    self.polyphase_obj.fpass,
                    0.5 * self.polyphase_obj.fs_new,
                ]
                gain = [0, self.polyphase_obj.multirate_factor]
                title = "HPF"

            print(
                f"=====================\nGenerated {title} with:\nN_taps={len(self.polyphase_obj.taps_prototype)}\nBands_hz={bands}\nG={gain}\n=====================\n"
            )
            # 1. Dump coefficients to text
            self.polyphase_obj.dump_to_txt(a_output_dir=Path(output_path))
            # 2. Generate input data & Dump to text
            input_path: Path = Path(output_path) / "input_data.txt"
            input_path.parent.mkdir(exist_ok=True, parents=True)
            res = list()
            with open(input_path, "w") as f:
                for i in range(a_input_samples):
                    # 1. Generate input data
                    input_data = np.cos(
                        2 * np.pi * a_cfg["input_frequency"] * i / a_cfg["fs"]
                    )
                    res.append(input_data)
                    print(input_data)

                    # 2. Convert to signed fixed-point
                    input_fixed = int(
                        round(input_data * (2.0 ** (a_cfg["G_DATA_WIDTH"] - 1)))
                    )

                    # 3. Format as binary string
                    input_fixed_bstring = format_as_bstring(
                        a_val_fixed=input_fixed, a_data_width=a_cfg["G_DATA_WIDTH"]
                    )

                    # 4. Write data
                    f.write(f"{input_fixed_bstring}\n")
            return True

        return pre_config

    def post_check_wrapper(self, a_cfg: dict):
        def post_check(output_path: str):

            checker = True

            # 0. Loop for data output entries:
            input_data_path: Path = Path(output_path) / "input_data.txt"
            output_data_path: Path = Path(output_path) / "output_data.txt"

            with open(output_data_path, "r") as f_out, open(
                input_data_path, "r"
            ) as f_in:
                for rd_idx, line in enumerate(f_out):
                    # 1. Fetch input
                    if rd_idx % int(a_cfg["multirate_factor"]) == 0:
                        input_data = f_in.readline()
                        input_data_f = BitArray(bin=input_data).int / (
                            2.0 ** a_cfg["G_DATA_WIDTH"]
                        )

                    # 2. Fetch output
                    output_data = line
                    output_data_f = BitArray(bin=output_data).int / (
                        2.0 ** a_cfg["G_DATA_WIDTH"]
                    )

                    # 3. Generate new reference data
                    if rd_idx % int(a_cfg["multirate_factor"]) == 0:
                        output_ref = self.polyphase_obj.tick(a_new_sample=input_data_f)
                        print(f"New reference=", output_ref)

                    comparison = compare_value(
                        a_actual=output_data_f,
                        a_reference=output_ref[rd_idx % a_cfg["multirate_factor"]],
                    )

                    # 4. Compare to data output entry
                    print()
                    print("i=", rd_idx % a_cfg["multirate_factor"])
                    print()
                    print("input=", input_data_f)
                    print()
                    print("output=", output_data_f)
                    print()
                    print(f"reference=", output_ref[rd_idx % a_cfg["multirate_factor"]])
                    print()
                    print("=====================================================")
                    checker = checker and comparison

            return checker

        return post_check


if __name__ == "__main__":
    print("Hello world!")
