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
Polyphase filters are an optimized converter+filter combination. A sample converter changes the effective Nyquist frequency and depending on if its decimation or interpolation two scenarios occurs:

A. Decimate: frequencies above the new Nyquist frequency will get aliased into the passband. 

B. Interpolate: image frequencies above the original Nyquist will be within the new Nyquist frequency

With the above in mind, an aliasing or image filter is required to get rid of the unwanted frequencies. But instead of simply adding a FIR filter a polyphase filter makes use of the multirate factor to create a very effective filter structure. Since it is known how many samples will be discarded or how many zeros will be added, the filter can be built to never perform an operation on a sample that will add no information. The FIR filter coefficients are split into M "phases" of equal length, where M is the multirate factor.. 

A. Decimate: New samples are rotated into each phase and when all phases have new input data one filter operation executes. Therefore each phase have effectively discarded M samples. 

B. Interpolation: Samples are input to all phases and instantly executed. The output data is rotated from each phase output. 

By not performing any unnecessary operations this filter makes the most use of available hardware. The transition region determines the tap order of the filter.

### Halfband
Halfband filters are made from one or more stages. Each stage interpolates or decimates by 2, and by cascading them one can get power-of-two. The filter passband is Fs/4, which generates a peculiar effect. Every other coefficient is zero! Since the multirate factor is two, we get two phases. The upper phase contains the non-zero coefficients. The lower phase are all zeros except one namely the middle coefficients which always becomes C=0.5. 

A. Interpolation: the filter gain is G=2, so the middle coefficient becomes C=0.5*2=1. A delay tap.

A. Decimation: the middle coefficient is C=0.5. A shift-by-1.

Since each interpolation stage increases the transition region, the tap number decreases for each interpolate-by-2 stage. For decimation, the reverse is true which makes the first stage the less resource-heavy one. 

### CIC (Cascaded Integrator Comb)
CIC filters are sample rate converters utilizing only adders and subtractors. It's a recursive running sum, which actually is a LPF of sorts. One can then add in a decimator or interpolator to get a cheap sample rate filter. Larger attenuation can be obtained by cascading more running sum parts. Lastly, the passband of a pure CIC filter is drooping like a sinc, so an ordinary FIR compensation filter is added to compensate for it. The FIR filter response is of course the inverse sinc.