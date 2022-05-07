clear all
close all

% load("raw_data.mat")
% load("code_1.mat")
% load("code_2.mat")

%-------------------------------------------------------------------------------
% User Defined Variables
Fc = 390e6; % H: 390.6e6
Fs = 1e6;
Decimation_Rate = 16;
code_bit_width = 16; % H: 32% Bit width in # of Fs/Decimation_Rate samples
bits_per_code = 128; % H: 84 % Bits per code in # of Fs/Decimation_Rate samples
code_repitition_interval = .1; % Reptition period to transmit code
avg_pwr_threshold = .01; % Power threshold used when detecting if a code is being transmitted
%-------------------------------------------------------------------------------

% Derived Variables
SamplesPerFrame_capture = code_repitition_interval*Fs*4
SamplesPerFrame_detect = 2^13; % Not used yet, switching between frame sizes takes too long

%Setup Pluto Receiver and Transmitter
rx=sdrrx('Pluto','CenterFrequency',Fc,'OutputDataType','double','SamplesPerFrame',SamplesPerFrame_capture, 'EnableBurstMode', true, 'GainSource', 'AGC Fast Attack', 'BasebandSampleRate', Fs);    
tx = sdrtx('Pluto','CenterFrequency',Fc, 'Gain',0, 'BasebandSampleRate', Fs); % -50 gives good reaction

timeSpan = rx.SamplesPerFrame/rx.BasebandSampleRate;
ts = dsp.TimeScope('SampleRate', rx.BasebandSampleRate,...
                        'TimeSpan', timeSpan,...
                        'BufferLength', rx.SamplesPerFrame  );

%% Code to get testing data if pluto is unavailable
%detect_samples = samples(2706540:2703540+2^13);
%code_samples = samples(3192900:3192900+400000);
%avg_pwr_code = sum(abs(code_samples.^2))/length(code_samples)


%% Code Detection
disp('********** Press and Hold Garage Door Opener')
detection = 0;
while detection == 0
    %tic
    detect_samples = rx();
    avg_pwr_code = sum(abs((detect_samples(1:length(detect_samples)/2).^2))/(length(detect_samples)/2));
    if avg_pwr_code > avg_pwr_threshold
       detection = 1;
    end
    %toc
end

disp('********** Release Garage Door Opener')

%Plot Raw Samples
figure
hold on
title('Raw Data Capture of Detected Garage Door Signal')
xlabel('Time')
ylabel('Real RF Signal')
plot(real(detect_samples))

%% First Code Pair Capture
% rx.release();
% rx.SamplesPerFrame = SamplesPerFrame_capture;
code_samples = detect_samples; %rx() while detect_samples is same size as code_samples dont fetch new chunk of data

[code1, code2] = capture_code_pair(code_samples, code_repitition_interval, Decimation_Rate, Fs, code_bit_width, bits_per_code);

%% Break in Code Detection (Release of button)

detection = 0;
while detection == 0
    %tic
    detect_samples = rx();
    %filtered_samples = movmean(abs(detect_samples.^2),32);
    avg_pwr_code = sum(abs((detect_samples(1:length(detect_samples)/2).^2))/(length(detect_samples)/2));
    if avg_pwr_code < avg_pwr_threshold
       detection = 1;
    end
    %toc
end


%% Wait for Next Code
disp('********** Press and Hold Garage Door Opener')
detection = 0;
while detection == 0
    %tic
    detect_samples = rx();
    %filtered_samples = movmean(abs(detect_samples.^2),32);
    avg_pwr_code = sum(abs((detect_samples(1:length(detect_samples)/2).^2))/(length(detect_samples)/2));
    if avg_pwr_code > avg_pwr_threshold
       detection = 1;
    end
    %toc
end

disp('********** Release Garage Door Opener')

%% Second Code Pair Capture

% rx.release();
% rx.SamplesPerFrame = SamplesPerFrame_capture;
code_samples = detect_samples; %rx() while detect_samples is same size as code_samples dont fetch new chunk of data

[code3, code4] = capture_code_pair(code_samples, code_repitition_interval, Decimation_Rate, Fs, code_bit_width, bits_per_code);


%% Transmit Codes
transmit_code(tx, code1, code2, code_bit_width, Decimation_Rate, Fs, code_repitition_interval, 1, 1)

transmit_code(tx, code3, code4, code_bit_width, Decimation_Rate, Fs, code_repitition_interval, 1, 1)
