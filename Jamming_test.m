clear all
close all

load("raw_data.mat")
load("code_1.mat")
load("code_2.mat")

Fc = 390.6e6;
Fs = 1e6;
SamplesPerFrame_detect = 2^13;
SamplesPerFrame_capture = 2^22;

%Setup Receiver
%rx=sdrrx('Pluto','CenterFrequency',Fc, 'OutputDataType','double','SamplesPerFrame',2^15, 'EnableBurstMode', true, 'GainSource', 'Manual', 'Gain', 30, 'BasebandSampleRate', Fs);
rx=sdrrx('Pluto','CenterFrequency',Fc,'OutputDataType','double','SamplesPerFrame',SamplesPerFrame_detect, 'EnableBurstMode', true, 'GainSource', 'AGC Fast Attack', 'BasebandSampleRate', Fs);    
tx = sdrtx('Pluto','CenterFrequency',390.6e6, 'Gain',0, 'BasebandSampleRate', Fs); % -50 gives good reaction

timeSpan = rx.SamplesPerFrame/rx.BasebandSampleRate;
ts = dsp.TimeScope('SampleRate', rx.BasebandSampleRate,...
                        'TimeSpan', timeSpan,...
                        'BufferLength', rx.SamplesPerFrame  );

% Fc_subcar = 100e3;
% dt = 1/Fs;
% Npts = SamplesPerFrame_detect;
% time = linspace(0,Npts*dt,Npts);
% jam_sig = 2*complex(cos(2*pi*Fc_subcar*time), sin(2*pi*Fc_subcar*time))';
% %jam_sig = awgn(ones(length(jam_sig),1),-20);
% tx.transmitRepeat(jam_sig);

code_samples= rx();
pause(4)
noise_samples= rx();
ts(code_samples)
ts(noise_samples)

tic
avg_pwr_noise = sum(abs(noise_samples.^2))/length(noise_samples)
avg_pwr_code = sum(abs(code_samples.^2))/length(code_samples)
toc
% max_array = [];
% for i = 1:64
%     test= rx();
%     spec = abs(fftshift(fft(test.^2),1024));
%     [~,max_index] = max(spec)
%     max_array = [max_array; max_index];
% end
% 
% plot(max_array)


% plot(real(jam_sig))

%tx.transmitRepeat(complex(zeros(length(jam_sig),1)));

detect_samples = samples(2706540:2703540+2^13);
code_samples = samples(3192900:3192900+400000);
avg_pwr_code = sum(abs(code_samples.^2))/length(code_samples)
tic
codes_filtered = lowpass(abs(code_samples.^2),1e3,Fs);
dec_codes = decimate(movmean(codes_filtered,32),16);

%% Code Detection
% detection = 0;
% for i = 1:100
%     %tic
%     detect_samples = rx();
%     %filtered_samples = movmean(abs(detect_samples.^2),32);
%     avg_pwr_code = sum(abs(detect_samples.^2))/length(detect_samples)
%     %toc
%     %plot(real(detect_samples))
%     %pause(16)
% end


%% Code Alignment

code_envelope = envelope(real(code_samples),600*16,'rms');
max_val = max(code_envelope);
min_val = min(code_envelope);

code_envelope = code_envelope(30000:end);


figure
hold on
plot(code_envelope)

start_index = 0;
low_threshold = ((max_val-min_val)/8)+min_val; %1/8th the way up from lowest point
low_width = 0;
for i = 1:length(code_envelope)
    
     %Check exit condition
    if code_envelope(i) > low_threshold & start_index > 0 %Found rising edge after low section
        if low_width > 3000
            start_index = i-3000;
        else
            start_index = i-low_width;
        end
        break;
    end
    
    if code_envelope(i) < low_threshold %Find first low section
        start_index = i;
        low_width = low_width + 1;
    else
        low_width = 0;
    end
   
end
toc
stem(start_index,max_val); % Plot starting low index







