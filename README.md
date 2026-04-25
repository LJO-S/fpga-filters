# FPGA Filter Repository
This repository contains generic filters intended to be used on an FPGA. They include:
- FIR filter
- Polyphase filters
- Halfband filters
- CIC filters

## How to generate .vhd files and .txt coefficients 
Easy!

1. Find the associated run.py testcase in /test/
2. Modify the generic parameters to fit your use-case
3. Run the test!
4. The generated files will be found in:
    - Coefficients: /test/vunit_out/"your testcase here"
    - PKG files (if necessary): /src/"your filter type here"


## Use cases for each filter type
First off, the FIR filters can be used whenever you need filtering of sorts. The three other filters (polyphase, halfband, CIC) has to do with sample rate conversion. In other words, if you want to digitally down-convert or up-convert a data stream you should use one of these filters - the filters are simply a rate converter merged with an anti-aliasing or anti-imaging filter. Many times the filters are strung together in a mix, but when do you use each one?

### -- Polyphase --

Use:
- When R /= powers-of-two & 
- When working with channelization

Pros:

- Behaves like a converter + FIR filter with minimal hardware consumption
- Exact passband shaping

Cons: 
- Uses the most hardware vs halfband/cic
- Author-limited to integer decimate/interpolate factors 

### -- Halfband --

Use:
- When R = powers-of-two

Pros:

- Requires minimum number of taps
- Sharp cutoff
- Small size (~ N/4 multipliers)

Cons: 

- Passband limited to Fs/4
- Decimate/Interpolate limited to R = powers-of-two 

### -- CIC --

Use:
- Perfect for huge decimation/interpolation factors (R=16 to 1024+)
- Massive sample rate e.g. first stage of DDC or last stage of a DUC. 
- "Lean mean fat-free filtering machine" - Richard G. Lyons in "Understanding DSP"

Pros:

- In itself requires 0 multipliers

Cons: 

- Bad frequency response = "passband droop" (mitigateble with FIR compensation filter, which of course consumes multipliers)
- Author-limited to R = powers-of-two 

## Theory
### FIR

### Polyphase

### Halfband

### CIC (Cascaded Integrator Comb)