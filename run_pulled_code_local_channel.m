% Diagnostic run of the pulled 224G implementation using a local public
% IEEE channel pair because the original D: drive Touchstone files are absent.
addpath(genpath(fileparts(mfilename('fullpath'))));
out=fullfile(pwd,'results','target_reproduction');
c=config_224G(); c.noise.reference='adc_input'; c.channel.type='touchstone';
c.channel.touchstone=struct('thru_file',fullfile(pwd,'channel','data','ieee_candidates','Bch2_7_t.s4p'), ...
 'fext_file',fullfile(pwd,'channel','data','ieee_candidates','Bch2_7_f1.s4p'));
c.channel.touchstone.port_left=[1 3];c.channel.touchstone.port_right=[2 4];
c.channel.touchstone.num_taps=512;c.channel.touchstone.main_cursor_idx=2;
c.sim.num_ofdm_symbols=2000;c.chest.L_moving_avg=200;
r=run_224G_test(c,struct('seed_offset',3));
row=struct('ber',r.ber,'ser_with_cancel',r.ser,'ser_without_cancel',r.ser_other_mode, ...
 'bits',r.num_bits,'symbols',r.num_qam_symbols,'rate_Gbps',c.ofdm.N_used*c.mod.bits_per_sym*c.fs/(c.ofdm.N_FFT+c.ofdm.N_CP)/1e9, ...
 'noise_reference',c.noise.reference,'channel','IEEE Bch2_7 THRU + Bch2_7 FEXT1 (local proxy)');
writetable(struct2table(row),fullfile(out,'pulled_code_local_channel_run.csv'));
save(fullfile(out,'pulled_code_local_channel_run.mat'),'row','c','r');
fprintf('PULLED CODE WITH LOCAL PROXY: SER_cancel %.6g SER_no_cancel %.6g BER %.6g\n',r.ser,r.ser_other_mode,r.ber);
fprintf('Proxy channel: %s | %s\n',c.channel.touchstone.thru_file,c.channel.touchstone.fext_file);
