function [code1,code2] = capture_code_pair(code_samples, code_repitition_interval, Decimation_Rate, Fs, bit_tap_spacing, bits_per_code)
%% Code Alignment

tic
code_envelope = envelope(real(code_samples),600*16,'rms');
max_val = max(code_envelope);
min_val = min(code_envelope);

figure
hold on
plot(code_envelope)

start_index = 0;
low_threshold = ((max_val-min_val)/8)+min_val; %1/8th the way up from lowest point
low_width = 0;
for i = 1:length(code_envelope)
    
     %Check exit condition
    if code_envelope(i) > low_threshold & start_index > 0 %Found rising edge after low section
        if low_width > 1500
            start_index = i-1500; %Move starting index back 3000 samples from rising edge of first code
        else
            start_index = i-low_width; %If theres not enough space, move back as far as it can go
        end
        break;
    end
    
    if code_envelope(i) <= low_threshold %Find first low section
        start_index = i;
        low_width = low_width + 1;
    else
        low_width = 0;
    end
   
end

stem(start_index,max_val); % Plot starting low index    

%% Collect Pair of Codes
    
    clean_codes = [];
    codes = [];
    for x = 1:2
        code_grab_start_index = start_index+(x-1)*code_repitition_interval*Fs;
        segment = code_samples(code_grab_start_index:code_grab_start_index+round(bits_per_code*bit_tap_spacing*Decimation_Rate*1.4));
        
        segment_filtered = lowpass(abs(segment.^2),1e3,Fs);
        dec_seg = decimate(movmean(segment_filtered,32),Decimation_Rate); %decimate(movmean(segment_filtered,32),8);
        
        figure
        plot(dec_seg)
        med =.01; %(max(dec_seg)-min(dec_seg))/3;
        clean_dec_seg = [];
        for i = 1:(length(dec_seg))
            if dec_seg(i) >= med
                clean_dec_seg = [clean_dec_seg ; 1];
            else
                clean_dec_seg = [clean_dec_seg ; 0];
            end
        end
        
    
        start_of_sig = find(clean_dec_seg,1);
        clean_dec_seg = clean_dec_seg(start_of_sig:start_of_sig+(bits_per_code*bit_tap_spacing));
    
        clean_codes = [clean_codes, clean_dec_seg];
        
        
        %PLL
        sample_index = bit_tap_spacing/2;
        sample_index_array = [];
        code = [];
        for i = 1:bits_per_code
            
            sample_tap_val = clean_dec_seg(sample_index);
            monitor_tap_val_ahead = clean_dec_seg(sample_index+bit_tap_spacing/2);
            monitor_tap_val_behind = clean_dec_seg(sample_index-bit_tap_spacing/2+1);
            if sample_tap_val ~= monitor_tap_val_ahead
                sample_index = sample_index - 2;
            elseif sample_tap_val ~= monitor_tap_val_behind
                sample_index = sample_index + 2;
            end
            sample_index_array = [sample_index_array;sample_index];
            code = [code; clean_dec_seg(sample_index)];
            
            sample_index = sample_index + bit_tap_spacing;
            
        end
        
        x = 1:bits_per_code;
        figure
        hold on
        plot(clean_dec_seg)
        stem(sample_index_array,code)
        ylim([-0.2 1.2])

        codes =[codes, code]; %Append new code to array
        
    end
    
    
    code1 = codes(:,1);
    code2 = codes(:,2);
    toc
    % Plot Data
    figure
    hold on
    plot(code1)
    figure
    hold on
    plot(code2)
    %stem(x,code)
end