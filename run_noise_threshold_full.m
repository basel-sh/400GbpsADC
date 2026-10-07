addpath(genpath(fileparts(mfilename('fullpath'))));out=fullfile(pwd,'results','target_reproduction');
diary(fullfile(out,'noise_threshold_full.log'));cleanup=onCleanup(@()diary('off'));
rows=struct([]);idx=0;levels=[0.1 0.15 0.2 0.3];seeds=[521 547 571];
for noise=levels
 for seed=seeds
  c=config_224G();c.noise.rx_input_rms_V=noise*1e-3;c.sim.num_ofdm_symbols=5600;c.chest.L_moving_avg=1000;
  r=run_224G_test(c,struct('seed_offset',seed));idx=idx+1;
  row=struct('noise_mV',noise,'seed',seed,'ber',r.ber,'ser',r.ser,'bit_errors',r.bit_errors,'num_bits',r.num_bits,'symbol_errors',r.symbol_errors,'num_symbols',r.num_qam_symbols);
  if idx==1,rows=row;else,rows(idx)=row;end
  fprintf('Noise %.2fmV seed%d BER%.9g SER%.9g errors%d/%d\n',noise,seed,r.ber,r.ser,r.bit_errors,r.num_bits);
 end
end
writetable(struct2table(rows),fullfile(out,'noise_threshold_full.csv'));save(fullfile(out,'noise_threshold_full.mat'),'rows');fprintf('NOISE_THRESHOLD_FULL_COMPLETE\n');
