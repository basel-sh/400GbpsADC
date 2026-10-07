% Find whether measured-phase inter-symbol interference is the gap source.
addpath(genpath(fileparts(mfilename('fullpath'))));
out=fullfile(pwd,'results','target_reproduction');diary(fullfile(out,'cp_phase_sweep.log'));
cleanup=onCleanup(@()diary('off'));rows=struct([]);
c0=config_224G();c0.channel.type='measured_complex';
c0.channel.main_response_csv=fullfile(pwd,'channel','data','c2c_candidates','C2C_PCB_SYSVIA_16dB_thru.csv');
c0.channel.fext_response_csv=fullfile(pwd,'channel','data','fig8','fext.csv');
c0.channel.num_taps=256;c0.noise.rx_input_rms_V=0.1e-3;c0.sim.num_ofdm_symbols=2000;
for i=1:numel([8 16 32 64 70])
 cp=[8 16 32 64 70];c=c0;c.ofdm.N_CP=cp(i);
 c.fs=c.data_rate_bps*(c.ofdm.N_FFT+c.ofdm.N_CP)/(c.ofdm.N_used*c.mod.bits_per_sym);
 c.occupied_bw=c.fs/2;
 r=run_224G_test(c,struct('seed_offset',601));
 row=struct('cp',cp(i),'fs_GSs',c.fs/1e9,'edge_GHz',c.fs/2e9, ...
  'actual_Gbps',c.ofdm.N_used*c.mod.bits_per_sym*c.fs/(c.ofdm.N_FFT+c.ofdm.N_CP)/1e9, ...
  'ber',r.ber,'ser',r.ser,'bit_errors',r.bit_errors,'num_bits',r.num_bits);
 if i==1,rows=row;else,rows(i)=row;end
 fprintf('CP%d Fs%.3f BER%.7g SER%.7g\n',cp(i),c.fs/1e9,r.ber,r.ser);
end
writetable(struct2table(rows),fullfile(out,'cp_phase_sweep.csv'));
save(fullfile(out,'cp_phase_sweep.mat'),'rows');
fprintf('CP_PHASE_SWEEP_COMPLETE\n');
