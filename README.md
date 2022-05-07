# Garage Door Hacking

This code base includes files necessary to "hack" a garage door opener using a man in the middle (MITM) attack. This code was written for use with an ADALM PlutoSDR device. This code was proven to work on both a Craftsman and a Chamberlain garage door.


Files included:
  - garage_hack_script.m
      This is the main source code file and calls other capture_code_pair.m and transmit_code.m
  - capture_code_pair.m
      This file captures the code pairs for transmission
  - transmit_code.m
      This file transmits the captured codes from the PlutoSDR.
  - jamming_test.m
      This file transmits a noisy signal from the PlutoSDR. This jams the transmission between the remote and the opener, preventing the opener from seeing the transmitted codes. Mileage may vary depending on signal strength from remote.
      
      
Instructions for use:
1. Ensure that the PlutoSDR is connected.
2. Unplug the garage door opener.
3. Run garage_hack_script.m, following the prompted instructions to capture a code pair. Proceed to step 4 before beginning transmission.
4. Plug the garage door back in.
5. Press enter to begin transmission. The garage door should open or close, depending on its starting position.
6. Stop transmission.
7. If desired, a second code can be transmitted by following the prompts to return the garage door to its original state.


Initial setup:
  - Using the internet and the FCC ID found on the back of the opener, find your garage door's operating frequency. Change the value of Fc, on line 10 of garage_hack_script.m, to this frequency.
- code_bit_width and bits_per_code on lines 13 and 14 respectively may need to be adjusted for each garage door.
- Ensure that the following add ons are installed in MATLAB:
  - Signal Processing Toolbox
  - DSP System Toolbox
  - Communications Toolbox
  - Communications Toolbox Support Package for Analog Devices ADALM-Pluto Radio
