# ===================================================================
# Utilities
# ===================================================================
import math


def generate_sine(a_frequency: float):
    pass


def format_as_bstring(a_val_fixed: int, a_data_width: int):

    if a_data_width <= 0:
        raise ValueError(f"Invalid width: {a_data_width}")

    # produce two's-complement bit pattern of 'width' bits
    mask = (1 << a_data_width) - 1
    val_masked = mask & a_val_fixed
    bstring = format(val_masked, f"0{a_data_width}b")

    if len(bstring) != a_data_width:
        raise ValueError(
            "Binary string was longer than allowed depth! Actual=",
            len(bstring),
            "vs Expected=",
            1 << a_data_width,
        )
    return bstring


def compare_value(a_actual, a_reference):
    if a_reference is not None:
        match = math.isclose(a=a_actual, b=a_reference, rel_tol=0.01, abs_tol=1e-3)
        diff_rel = abs(a_actual - a_reference) / (a_reference + 1e-9)
        if not match:
            print(
                f"Mismatch! Reference={a_reference} vs Actual={a_actual} <===> %diff={diff_rel}"
            )
            return False
        else:
            print(
                f"Pass!! Reference={a_reference} vs Actual={a_actual} <===> %diff={diff_rel}"
            )
    return True
