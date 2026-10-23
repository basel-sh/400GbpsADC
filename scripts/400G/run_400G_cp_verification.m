% Test whether longer CP removes the 256-QAM floor, retaining 400 Gb/s/lane.
root=fileparts(fileparts(fileparts(mfilename('fullpath'))));addpath(genpath(root));
out=fullfile(root,'results','400G','verification');
diary(fullfile(out,'cp_console.log'));clean=onCleanup(@()diary('off'));
rows=struct([]);cs={};
for cp=[8 16 32 64]
 c=config_400G(struct('mod',struct('order',256),'ofdm',struct('N_CP',cp), ...
  'dac',struct('bits',9),'adc',struct('bits',9), ...
  'channel',struct('main_loss_dB_at_f',5)));
 c.noise.reference='channel_output';c.noise.rx_input_rms_V=0.3e-3;
 c.jitter.rms_UI=22.28199e-15*c.fs;c.jitter.method='spectral_linear';
 c.deemph.k1_dB=-3.5;c.deemph.gain_dB=@(k)-3.5*(511-k)/510;
 c.sim.num_ofdm_symbols=1000;cs{end+1}=c;
 assert(c.dac.clip_ratio_dB==12.6 && c.adc.clip_ratio_dB==13.4);
 assert(abs(c.achieved_data_rate_bps/400e9-1)<1e-12);
 r=run_224G_test(c,struct('seed_offset',541));row=pack(c,r,541);
 if isempty(rows),rows=row;else,rows(end+1)=row;end
 writetable(struct2table(rows),fullfile(out,'cp_screening.csv'));
end
% Select the shortest CP that passes both screening targets, then new seeds.
ix=find([rows.ber]<=2.4e-6 & [rows.ser]<=1.4e-5,1);
confirm=struct([]);
if ~isempty(ix)
 c=cs{ix};c.sim.num_ofdm_symbols=5600;
 for seed=[563 587 613]
  r=run_224G_test(c,struct('seed_offset',seed));row=pack(c,r,seed);
  if isempty(confirm),confirm=row;else,confirm(end+1)=row;end
  writetable(struct2table(confirm),fullfile(out,'cp_confirmation.csv'));
 end
 N=sum([confirm.num_bits]);E=sum([confirm.bit_errors]);Ns=sum([confirm.num_symbols]);Es=sum([confirm.symbol_errors]);
 pooled=struct('cp',c.ofdm.N_CP,'rate_Gbps',c.achieved_data_rate_bps/1e9, ...
  'fs_GSs',c.fs/1e9,'ber',E/N,'ser',Es/Ns,'bit_errors',E,'num_bits',N, ...
  'symbol_errors',Es,'num_symbols',Ns);
 writetable(struct2table(pooled),fullfile(out,'cp_pooled.csv'));
 fprintf('CP pooled %d: BER %.9g SER %.9g errors%d/%d\n',c.ofdm.N_CP,E/N,Es/Ns,E,N);
end
save(fullfile(out,'cp_verification.mat'),'rows','confirm','cs');
function s=pack(c,r,seed)
s=struct('cp',c.ofdm.N_CP,'seed',seed,'rate_Gbps',c.achieved_data_rate_bps/1e9, ...
 'fs_GSs',c.fs/1e9,'bandwidth_GHz',c.fs/2e9,'bits',c.adc.bits, ...
 'dac_clip_dB',c.dac.clip_ratio_dB,'adc_clip_dB',c.adc.clip_ratio_dB, ...
 'ber',r.ber,'ser',r.ser,'bit_errors',r.bit_errors,'num_bits',r.num_bits, ...
 'symbol_errors',r.symbol_errors,'num_symbols',r.num_qam_symbols);
fprintf('256-QAM CP%d Fs%.6f: BER %.9g SER %.9g\n',s.cp,s.fs_GSs,s.ber,s.ser);
end
