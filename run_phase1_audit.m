% Reproducible paper audit, ablations and rate-correct 400G candidate search.
% New output directory preserves previous results.
root=fileparts(mfilename('fullpath')); addpath(genpath(root));
out=fullfile(root,'results','phase1'); if ~exist(out,'dir'),mkdir(out);end
diary(fullfile(out,'phase1_console.log')); cleanup=onCleanup(@()diary('off'));
cfg=config_224G(); cfg.sim.num_ofdm_symbols=500;
cases={}; labels={};
cases{end+1}=cfg; labels{end+1}='FEXT_literal_meanabs_preVGA';
c=cfg;c.dac.clip_reference='rms';c.adc.clip_reference='rms';
cases{end+1}=c;labels{end+1}='FEXT_dB_RMS_preVGA';
c=cfg;c.noise.reference='adc_input';cases{end+1}=c;labels{end+1}='FEXT_meanabs_ADC_noise_assumption';
c=cfg;c.noise.rx_input_rms_V=0;cases{end+1}=c;labels{end+1}='ablation_no_thermal_noise';
c=cfg;c.jitter.rms_UI=0;cases{end+1}=c;labels{end+1}='ablation_no_jitter';
c=cfg;c.dac.bits=14;c.adc.bits=14;cases{end+1}=c;labels{end+1}='ablation_near_ideal_quantization';
c=cfg;c.chest.L_moving_avg=1000;cases{end+1}=c;labels{end+1}='CHEST_L1000';
c=cfg;c.chest.average_domain='channel';cases{end+1}=c;labels{end+1}='average_H_then_invert_alternative';
c=cfg;c.chest.vary_pilots=false;cases{end+1}=c;labels{end+1}='fixed_QPSK_pilots_alternative';
c=cfg;c.ofdm.N_CP=64;cases{end+1}=c;labels{end+1}='CP64_rate_reduced_diagnostic';
audit=struct([]);
for i=1:numel(cases)
    c=cases{i};r=run_224G_test(c,struct('seed_offset',1));
    row=summary_row(labels{i},c,r);
    if i==1,audit=row;else,audit(i)=row;end
    fprintf('%s: BER %.6g SER %.6g naive %.6g EVM %.3f%%\n',labels{i},r.ber,r.ser,r.ser_other_mode,r.evm_percent);
    if i==1,baseline=r;save(fullfile(out,'baseline_224G.mat'),'baseline','-v7.3');end
end
writetable(struct2table(audit),fullfile(out,'224G_audit.csv'));
save(fullfile(out,'224G_audit.mat'),'audit','cases');
% 400G search: independent architecture/resource assumptions, fixed paper noise.
rows=struct([]); idx=0; bestcfg=[];bestber=inf;
for q=[16 64 256]
 for bits=[7 8 9]
  for de=[-10.5 -16 -22]
   for loss=[23 15 10]
    c=config_400G(struct('mod',struct('order',q), ...
       'dac',struct('bits',bits),'adc',struct('bits',bits), ...
       'channel',struct('main_loss_dB_at_f',loss)));
    c.deemph.gain_dB=@(k)de*(511-k)/510;
    c.sim.num_ofdm_symbols=150;c.chest.L_moving_avg=200;
    r=run_224G_test(c,struct('seed_offset',2));idx=idx+1;
    row=summary_row(sprintf('400G_Q%d_B%d_DE%.1f_L%.1f',q,bits,de,loss),c,r);
    if idx==1,rows=row;else,rows(idx)=row;end
    if r.ber<bestber,bestber=r.ber;bestcfg=c;end
    if mod(idx,9)==0
      fprintf('400G search %d/81: current best BER %.6g\n',idx,bestber);
      writetable(struct2table(rows),fullfile(out,'400G_candidates.csv'));
    end
   end
  end
 end
end
writetable(struct2table(rows),fullfile(out,'400G_candidates.csv'));
save(fullfile(out,'400G_candidates.mat'),'rows','bestcfg');
% Multi-seed independent confirmation; total exceeds DSE's 48 million bits/lane.
confirmcfg={cfg,bestcfg};confirmation=struct([]);idx=0;
for j=1:2
 c=confirmcfg{j};c.sim.num_ofdm_symbols=2800;
 for seed=[31 53 79]
  r=run_224G_test(c,struct('seed_offset',seed));idx=idx+1;
  row=summary_row(sprintf('confirm_%d_seed%d',j,seed),c,r);
  if idx==1,confirmation=row;else,confirmation(idx)=row;end
  fprintf('%s: BER %.6g SER %.6g errors %d/%d\n',confirmation(idx).name,r.ber,r.ser,r.bit_errors,r.num_bits);
 end
end
writetable(struct2table(confirmation),fullfile(out,'confirmation.csv'));
save(fullfile(out,'phase1_summary.mat'),'audit','rows','confirmation','bestcfg');
fprintf('PHASE1_AUDIT_COMPLETE\n');

function s=summary_row(name,c,r)
rate=c.ofdm.N_used*c.mod.bits_per_sym*c.fs/(c.ofdm.N_FFT+c.ofdm.N_CP);
s=struct('name',name,'rate_Gbps',rate/1e9,'fs_GSs',c.fs/1e9, ...
 'bandwidth_GHz',c.fs/2e9,'qam',c.mod.order,'dac_bits',c.dac.bits, ...
 'adc_bits',c.adc.bits,'loss40_dB',c.channel.main_loss_dB_at_f, ...
 'ber',r.ber,'ser',r.ser,'naive_ser',r.ser_other_mode,'evm_percent',r.evm_percent, ...
 'bit_errors',r.bit_errors,'num_bits',r.num_bits, ...
 'symbol_errors',r.symbol_errors,'num_symbols',r.num_qam_symbols);
end
