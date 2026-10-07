% Companion-paper Fig.25 full clipping grid; separate from fixed FEXT baseline.
addpath(genpath(fileparts(mfilename('fullpath'))));
out=fullfile(pwd,'results','phase1');diary(fullfile(out,'clipping_console.log'));
cleanup=onCleanup(@()diary('off'));
rows=struct([]);i=0;
for tx=linspace(2.97,4.70,11)
 for rx=linspace(3.33,5.40,12)
  c=config_224G();c.dac.clip_reference='rms';c.adc.clip_reference='rms';
  c.dac.clip_ratio_dB=20*log10(tx);c.adc.clip_ratio_dB=20*log10(rx);
  c.sim.num_ofdm_symbols=200;r=run_224G_test(c,struct('seed_offset',9));i=i+1;
  s=struct('tx_RMS_ratio',tx,'rx_RMS_ratio',rx,'ber',r.ber,'ser',r.ser);
  if i==1,rows=s;else,rows(i)=s;end
 end
 fprintf('Clipping row %d/11 complete\n',round((tx-2.97)/(4.70-2.97)*10)+1);
end
writetable(struct2table(rows),fullfile(out,'224G_clipping_grid.csv'));
% Longer unchanged-parameter baseline, 51.5 million bits/lane across seeds.
confirmation=struct([]);
for seed=[211 239 263]
 c=config_224G();c.sim.num_ofdm_symbols=5600;
 r=run_224G_test(c,struct('seed_offset',seed));
 s=struct('seed',seed,'ber',r.ber,'ser',r.ser,'naive_ser',r.ser_other_mode, ...
  'bit_errors',r.bit_errors,'num_bits',r.num_bits, ...
  'symbol_errors',r.symbol_errors,'num_symbols',r.num_qam_symbols);
 if isempty(confirmation),confirmation=s;else,confirmation(end+1)=s;end
 fprintf('224G long confirmation seed%d BER %.6g SER %.6g\n',seed,r.ber,r.ser);
end
writetable(struct2table(confirmation),fullfile(out,'224G_long_confirmation.csv'));
save(fullfile(out,'224G_clipping_confirmation.mat'),'rows','confirmation');
fprintf('CLIPPING_COMPLETE\n');
