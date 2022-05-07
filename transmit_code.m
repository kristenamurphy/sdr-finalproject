function transmit_code(tx, code1, code2, code_bit_width, Decimation_Rate, Fs,  code_repitition_period, prompt_user_start, prompt_user_stop)


    samples_per_code = code_repitition_period*Fs;
    
    %Prompt user to start first code transmission
    if prompt_user_start == 1
        prompt = "Press Enter To Transmit First Code";
        input(prompt)
    end
    
    %Upsample Code 1
    code_seq = []; 
    for i = 1:length(code1) % Create code sequence using code and bitwidth (# of samples per code)
        if code1(i)
            code_seq = [code_seq;ones(code_bit_width,1)];
        else
            code_seq = [code_seq;zeros(code_bit_width,1)];
        end
    end
            
    upsampled_code1 = interp(code_seq,Decimation_Rate,1,.5);
    zero_buffer1 = zeros(samples_per_code-length(upsampled_code1),1);
    tx_code1 = [upsampled_code1;zero_buffer1];
    
    %Upsample Code 2
    code_seq = []; 
    for i = 1:length(code2) % Create code sequence using code and bitwidth (# of samples per code)
        if code2(i) == 1
            code_seq = [code_seq;ones(code_bit_width,1)];
        else
            code_seq = [code_seq;zeros(code_bit_width,1)];
        end
    end
    upsampled_code2 = interp(code_seq,Decimation_Rate,1,.1);
    zero_buffer2 = zeros(samples_per_code-length(upsampled_code2),1);
    tx_code2 = [upsampled_code2;zero_buffer2];
    
    %Combine Code 1 and Code 2
    tx_sig = [tx_code1; tx_code2];
    
    % Create Subcarrier signal
    Fc_subcar = 10e3; % Use 10kHz subcarrier frequency
    dt = 1/Fs;
    Npts = length(tx_sig);
    time = linspace(0,Npts*dt,Npts);
    sub_car = complex(cos(2*pi*Fc_subcar*time), sin(2*pi*Fc_subcar*time))';
    
    % Modulate subcarrier with Combined codes
    mod_tx_sig = sub_car.*tx_sig;
    
    figure
    hold on
    plot(tx_sig)
    plot(real(mod_tx_sig))
    plot(imag(mod_tx_sig))
    
    %Transmit on repeat until user requests a stop
    tx.transmitRepeat(mod_tx_sig)
    if prompt_user_stop == 1
        prompt = "Press Enter Stop Transmission";
        input(prompt)
    else
        pause(2)
    end
    
    %Tranmit Zeros to stop sending code
    tx.transmitRepeat(complex(zeros(length(mod_tx_sig),1)))

end