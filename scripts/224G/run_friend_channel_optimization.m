% Reproducible comparison and bounded optimization of the pulled channel.
% Paper DAC/ADC clipping is fixed at 12.6/13.4 dB; optimize CHEST only.
root=fileparts(fileparts(fileparts(mfilename('fullpath')))); addpath(genpath(root));
out=fullfile(root,'results','224G');
if ~exist(out,'dir'),mkdir(out);end
diary(fullfile(out,'paper_clipping_optimization.log')); cleanup=onCleanup(@()diary('off'));
s=load(fullfile(out,'results_224G.mat'),'results'); base=s.results.cfg;
base.results_dir=out; base.fig_dir=fullfile(out,'figures');
base.dac.clip_ratio_dB=12.6; base.adc.clip_ratio_dB=13.4;
r=s.results.test56.test6;
if exist('friend_resume_confirmation','var') && friend_resume_confirmation
    checkpoint=fullfile(out,'paper_clipping_optimization.csv');
    if ~isfile(checkpoint),checkpoint=fullfile(out,'optimization.csv');end
    rows=table2struct(readtable(checkpoint)).';
    rows=rows([rows.dac_clip_dB]==12.6 & [rows.adc_clip_dB]==13.4);
    if isempty(rows),error('No saved runs use the required paper clipping settings.');end
else
rows=record('baseline',base,r,3);
[hm,mi]=main_channel(base); [hf,fi]=fext_channel(base,mi);
fprintf('THRU loss at 40GHz %.6g dB; retained energy main %.4f%% FEXT %.4f%%\n', ...
    mi.loss_dB_fn(40e9),mi.energy_in_taps_pct,fi.energy_in_taps_pct);
w=exp(-2j*pi*[3.7e9;37e9]*(0:numel(hm)-1)/base.fs);
fprintf('FIR main/FEXT ratio: %.6g dB at 3.7GHz; %.6g dB at 37GHz\n', ...
    20*log10(abs(w(1,:)*hm)/abs(w(1,:)*hf)), ...
    20*log10(abs(w(2,:)*hm)/abs(w(2,:)*hf)));
% Isolate averaging at the paper's fixed clipping ratios.
for L=[500 1000]
    c=base; c.chest.L_moving_avg=L;
    rr=run_224G_test(c,struct('seed_offset',3));
    rows(end+1)=record(sprintf('paper_settings_L%d',L),c,rr,3);
end
end
writetable(struct2table(rows),fullfile(out,'paper_clipping_optimization.csv'));
[~,best]=min([rows.ser]); c=base;
c.chest.L_moving_avg=rows(best).L;
c.sim.num_ofdm_symbols=5600;
confirm=struct([]);
for seed=[31 53 79]
    rr=run_224G_test(c,struct('seed_offset',seed));
    row=record('paper_clipping_confirmation',c,rr,seed);
    if isempty(confirm),confirm=row;else,confirm(end+1)=row;end
    writetable(struct2table(confirm),fullfile(out,'paper_clipping_confirmation.csv'));
end
save(fullfile(out,'paper_clipping_optimization.mat'),'rows','confirm','c');
fprintf('POOLED confirmation: BER %.9g SER %.9g over %.0f bits / %.0f QAM symbols\n', ...
    sum([confirm.bit_errors])/sum([confirm.num_bits]), ...
    sum([confirm.symbol_errors])/sum([confirm.num_symbols]), ...
    sum([confirm.num_bits]),sum([confirm.num_symbols]));
function row=record(name,c,r,seed)
row=struct('name',name,'seed',seed,'L',c.chest.L_moving_avg, ...
    'dac_clip_dB',c.dac.clip_ratio_dB,'adc_clip_dB',c.adc.clip_ratio_dB, ...
    'ber',r.ber,'ser',r.ser,'ser_without_cancel',r.ser_other_mode, ...
    'bit_errors',r.bit_errors,'num_bits',r.num_bits, ...
    'symbol_errors',r.symbol_errors,'num_symbols',r.num_qam_symbols, ...
    'evm_percent',r.evm_percent);
fprintf('%s seed%d L%d ADCclip%.1f: BER %.9g SER %.9g no-cancel %.9g\n', ...
    name,seed,row.L,row.adc_clip_dB,row.ber,row.ser,row.ser_without_cancel);
end
