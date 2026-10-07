addpath(genpath(fileparts(mfilename('fullpath')))); out=fullfile(pwd,'results','target_reproduction');
diary(fullfile(out,'adc_input_clipping_grid.log')); cleanup=onCleanup(@()diary('off'));
rows=struct([]); i=0; txs=[2.97 3.25 3.41 3.7 4.0]; rxs=[3.30 3.50 3.73 4.0 4.3];
for tx=txs
 for rx=rxs
  c=config_224G(); c.noise.reference='adc_input'; c.channel.ofdm_diagonal=true; c.sim.num_ofdm_symbols=200;
  c.dac.clip_reference='rms';c.adc.clip_reference='rms';
  c.dac.clip_ratio_dB=20*log10(tx);c.adc.clip_ratio_dB=20*log10(rx);
  r=run_224G_test(c,struct('seed_offset',901)); i=i+1;
  row=struct('tx_rms',tx,'rx_rms',rx,'ber',r.ber,'ser',r.ser,'errors',r.bit_errors,'bits',r.num_bits);
  if i==1,rows=row;else,rows(i)=row;end
 end
 fprintf('TX %.2f complete\n',tx);
end
writetable(struct2table(rows),fullfile(out,'adc_input_clipping_grid.csv'));save(fullfile(out,'adc_input_clipping_grid.mat'),'rows');
[~,ix]=min([rows.ber]);fprintf('BEST TX%.3f RX%.3f BER%.9g SER%.9g\n',rows(ix).tx_rms,rows(ix).rx_rms,rows(ix).ber,rows(ix).ser);
