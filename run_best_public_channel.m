% Test strongest public THRU shape/phase candidate against digitized Fig.8 FEXT.
% Noise budget sweep tests whether the paper BER requires an unstated lower AFE noise.
addpath(genpath(fileparts(mfilename('fullpath'))));
out=fullfile(pwd,'results','target_reproduction');diary(fullfile(out,'public_channel_noise.log'));
cleanup=onCleanup(@()diary('off'));rows=struct([]);
c0=config_224G();
c0.channel.type='measured_complex';
c0.channel.main_response_csv=fullfile(pwd,'channel','data','c2c_candidates','C2C_PCB_SYSVIA_16dB_thru.csv');
c0.channel.fext_response_csv=fullfile(pwd,'channel','data','fig8','fext.csv');
c0.channel.num_taps=256;
i=0;
for noise=[1.8 0.3 0.1]
 for seed=[521 547 571]
  c=c0;c.noise.rx_input_rms_V=noise*1e-3;c.sim.num_ofdm_symbols=5600;
  r=run_224G_test(c,struct('seed_offset',seed));i=i+1;
  row=struct('noise_mV',noise,'seed',seed,'ber',r.ber,'ser',r.ser, ...
    'naive_ser',r.ser_other_mode,'bit_errors',r.bit_errors,'num_bits',r.num_bits, ...
    'symbol_errors',r.symbol_errors,'num_symbols',r.num_qam_symbols, ...
    'fs_GSs',c.fs/1e9,'thru','C2C_PCB_SYSVIA_16dB','fext','digitized Fig.8 magnitude');
  if i==1,rows=row;else,rows(i)=row;end
  fprintf('Noise %.2fmV seed%d BER%.7g SER%.7g errors%d/%d\n',noise,seed,r.ber,r.ser,r.bit_errors,r.num_bits);
 end
end
writetable(struct2table(rows),fullfile(out,'public_channel_noise.csv'));
save(fullfile(out,'public_channel_noise.mat'),'rows');
fprintf('PUBLIC_CHANNEL_NOISE_COMPLETE\n');
