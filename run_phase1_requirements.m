% Extend the audit to converter/clipping and achievable noise/channel budgets.
addpath(genpath(fileparts(mfilename('fullpath'))));
out=fullfile(pwd,'results','phase1');diary(fullfile(out,'requirements_console.log'));
cleanup=onCleanup(@()diary('off'));
rows=struct([]);i=0;
% Preserve paper's 224G parameters, measure required input-referred noise budget.
for noise=[1.8 1.0 0.7 0.5 0.3 0.1]
 c=config_224G();c.noise.rx_input_rms_V=noise*1e-3;c.sim.num_ofdm_symbols=1000;
 r=run_224G_test(c,struct('seed_offset',5));i=i+1;
 row=pack('224G_noise_budget',c,r,noise);if i==1,rows=row;else,rows(i)=row;end
 fprintf('224G noise %.2fmV BER %.6g SER %.6g\n',noise,r.ber,r.ser);
end
% Measured candidate is a sensitivity case, NOT an identified paper channel.
for typ={'measured_magnitude_minphase','measured_complex'}
 c=config_224G();c.channel.type=typ{1};c.channel.num_taps=256;
 c.channel.main_response_csv=fullfile(pwd,'channel','data','ieee_candidates','Bch2_7_t_sdd21.csv');
 c.sim.num_ofdm_symbols=1000;r=run_224G_test(c,struct('seed_offset',5));i=i+1;
 rows(i)=pack(typ{1},c,r,1.8);
 fprintf('%s BER %.6g SER %.6g\n',typ{1},r.ber,r.ser);
end
% 400G candidates with explicit, changed physical budgets.
bestber=inf;bestcfg=[];
for q=[64 256]
 for loss=[5 10 15 23]
  for noise=[0.3 0.5 1.0 1.8]
   for jit=[0.003 0.01]
    c=config_400G(struct('mod',struct('order',q),'dac',struct('bits',9), ...
     'adc',struct('bits',9),'channel',struct('main_loss_dB_at_f',loss)));
    c.noise.rx_input_rms_V=noise*1e-3;c.jitter.rms_UI=jit;
    de=-loss*0.7;c.deemph.gain_dB=@(k)de*(511-k)/510;
    c.sim.num_ofdm_symbols=300;r=run_224G_test(c,struct('seed_offset',7));i=i+1;
    rows(i)=pack('400G_changed_budgets',c,r,noise);
    if r.ber<bestber,bestber=r.ber;bestcfg=c;end
   end
  end
  fprintf('400G Q%d loss%d complete, best BER %.6g\n',q,loss,bestber);
 end
end
writetable(struct2table(rows),fullfile(out,'requirements.csv'));
save(fullfile(out,'requirements.mat'),'rows','bestcfg');
% Independent confirmation: minimum 48 million bits PER lane for both QAM choices.
confirmation=struct([]);
for seed=[101 127 151]
 c=bestcfg;c.sim.num_ofdm_symbols=5600;
 r=run_224G_test(c,struct('seed_offset',seed));
 row=pack('400G_conditional_confirmation',c,r,c.noise.rx_input_rms_V*1e3);
 if isempty(confirmation),confirmation=row;else,confirmation(end+1)=row;end
 fprintf('400G conditional seed%d BER %.6g SER %.6g errors%d/%d\n',seed,r.ber,r.ser,r.bit_errors,r.num_bits);
end
writetable(struct2table(confirmation),fullfile(out,'conditional_confirmation.csv'));
save(fullfile(out,'conditional_confirmation.mat'),'confirmation','bestcfg');
fprintf('REQUIREMENTS_COMPLETE\n');

function s=pack(name,c,r,noise)
s=struct('name',name,'qam',c.mod.order,'rate_Gbps',c.ofdm.N_used*c.mod.bits_per_sym*c.fs/(c.ofdm.N_FFT+c.ofdm.N_CP)/1e9, ...
 'fs_GSs',c.fs/1e9,'loss40_dB',c.channel.main_loss_dB_at_f,'noise_mV',noise, ...
 'jitter_UI',c.jitter.rms_UI,'ber',r.ber,'ser',r.ser,'naive_ser',r.ser_other_mode, ...
 'bit_errors',r.bit_errors,'num_bits',r.num_bits,'symbol_errors',r.symbol_errors,'num_symbols',r.num_qam_symbols);
end
