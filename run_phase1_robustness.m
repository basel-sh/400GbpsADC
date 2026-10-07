% Candidate robustness to jitter modeling and converter resolution.
addpath(genpath(fileparts(mfilename('fullpath'))));
out=fullfile(pwd,'results','phase1');diary(fullfile(out,'robustness_console.log'));
cleanup=onCleanup(@()diary('off'));rows=struct([]);
for q=[64 256]
 for bits=[7 8 9]
  for meth={'spline','spectral_linear'}
   c=config_400G(struct('mod',struct('order',q),'dac',struct('bits',bits), ...
    'adc',struct('bits',bits),'channel',struct('main_loss_dB_at_f',5)));
   c.noise.rx_input_rms_V=0.3e-3;c.jitter.rms_UI=0.003;c.jitter.method=meth{1};
   c.deemph.gain_dB=@(k)-3.5*(511-k)/510;
   c.sim.num_ofdm_symbols=1200;r=run_224G_test(c,struct('seed_offset',83));
   row=pack(c,r,83);if isempty(rows),rows=row;else,rows(end+1)=row;end
   fprintf('Q%d bits%d %s BER %.6g SER %.6g\n',q,bits,meth{1},r.ber,r.ser);
  end
 end
end
writetable(struct2table(rows),fullfile(out,'400G_robustness.csv'));
% Confirm lower-bandwidth 256-QAM path with 9 bits and spectral jitter.
confirmation=struct([]);c.dac.bits=9;c.adc.bits=9;c.jitter.method='spectral_linear';
c.sim.num_ofdm_symbols=5600;
for seed=[307 331 359]
 r=run_224G_test(c,struct('seed_offset',seed));row=pack(c,r,seed);
 if isempty(confirmation),confirmation=row;else,confirmation(end+1)=row;end
 fprintf('256QAM confirm seed%d BER %.6g SER %.6g\n',seed,r.ber,r.ser);
end
writetable(struct2table(confirmation),fullfile(out,'256QAM_confirmation.csv'));
save(fullfile(out,'256QAM_confirmation.mat'),'confirmation','c');
fprintf('ROBUSTNESS_COMPLETE\n');

function s=pack(c,r,seed)
s=struct('qam',c.mod.order,'bits',c.dac.bits,'jitter_method',c.jitter.method, ...
 'seed',seed,'fs_GSs',c.fs/1e9,'ber',r.ber,'ser',r.ser,'naive_ser',r.ser_other_mode, ...
 'bit_errors',r.bit_errors,'num_bits',r.num_bits,'symbol_errors',r.symbol_errors,'num_symbols',r.num_qam_symbols);
end
