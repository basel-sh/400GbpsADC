addpath(genpath(fileparts(mfilename('fullpath')))); out=fullfile(pwd,'results','target_reproduction');
diary(fullfile(out,'adc_input_best_clip_full.log')); cleanup=onCleanup(@()diary('off'));
c0=config_224G(); c0.noise.reference='adc_input';c0.channel.ofdm_diagonal=true;c0.sim.num_ofdm_symbols=5600;c0.chest.L_moving_avg=1000;
c0.dac.clip_reference='rms';c0.adc.clip_reference='rms';c0.dac.clip_ratio_dB=20*log10(3.41);c0.adc.clip_ratio_dB=20*log10(3.50);
rows=struct([]);seeds=[521 547 571];
for i=1:3
 r=run_224G_test(c0,struct('seed_offset',seeds(i)));
 row=struct('seed',seeds(i),'ber',r.ber,'ser',r.ser,'bit_errors',r.bit_errors,'num_bits',r.num_bits, ...
  'symbol_errors',r.symbol_errors,'num_symbols',r.num_qam_symbols,'tx_rms_ratio',3.41,'rx_rms_ratio',3.50,'noise_location','ADC input');
 if i==1,rows=row;else,rows(i)=row;end
 fprintf('Best clip seed%d BER%.9g SER%.9g errors%d/%d\n',seeds(i),r.ber,r.ser,r.bit_errors,r.num_bits);
end
writetable(struct2table(rows),fullfile(out,'adc_input_best_clip_full.csv'));save(fullfile(out,'adc_input_best_clip_full.mat'),'rows');
