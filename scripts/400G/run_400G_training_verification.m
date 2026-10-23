% Test whether more CHEST averaging stabilizes 256-QAM at unchanged budgets.
root=fileparts(fileparts(fileparts(mfilename('fullpath'))));addpath(genpath(root));
out=fullfile(root,'results','400G_verification');
diary(fullfile(out,'training_console.log'));clean=onCleanup(@()diary('off'));
s=load(fullfile(out,'screening.mat'));ix=find(strcmp({s.rows.name},'256QAM_candidate_9bit'),1);
c=s.configs{ix};c.chest.L_moving_avg=1000;rows=struct([]);
for seed=[401 641 673 701]
 if seed==401,c.sim.num_ofdm_symbols=1000;else,c.sim.num_ofdm_symbols=5600;end
 r=run_224G_test(c,struct('seed_offset',seed));row=pack(c,r,seed);
 if isempty(rows),rows=row;else,rows(end+1)=row;end
 writetable(struct2table(rows),fullfile(out,'training_confirmation.csv'));
end
c.sim.num_ofdm_symbols=1000;c.jitter.method='spline';
r=run_224G_test(c,struct('seed_offset',401));model_check=pack(c,r,401);
writetable(struct2table(model_check),fullfile(out,'training_spline_check.csv'));
a=rows([rows.seed]~=401);N=sum([a.num_bits]);E=sum([a.bit_errors]);Ns=sum([a.num_symbols]);Es=sum([a.symbol_errors]);
pooled=struct('qam',256,'L',1000,'ber',E/N,'ser',Es/Ns, ...
 'bit_errors',E,'num_bits',N,'symbol_errors',Es,'num_symbols',Ns, ...
 'max_lane_ber',max([a.ber_lane1 a.ber_lane2]));
writetable(struct2table(pooled),fullfile(out,'training_pooled.csv'));
save(fullfile(out,'training_verification.mat'),'rows','pooled','model_check','c');
fprintf('L1000 pooled BER %.9g SER %.9g over %d bits\n',E/N,Es/Ns,N);
function row=pack(c,r,seed)
b1=qam_demodulate(r.tx_syms1,256);z1=qam_demodulate(r.rx_syms1,256);
b2=qam_demodulate(r.tx_syms2,256);z2=qam_demodulate(r.rx_syms2,256);
row=struct('seed',seed,'qam',256,'L',c.chest.L_moving_avg,'rate_Gbps',c.achieved_data_rate_bps/1e9, ...
 'fs_GSs',c.fs/1e9,'bits',c.adc.bits,'jitter_method',c.jitter.method, ...
 'dac_clip_dB',c.dac.clip_ratio_dB,'adc_clip_dB',c.adc.clip_ratio_dB, ...
 'ber',r.ber,'ber_lane1',mean(b1~=z1),'ber_lane2',mean(b2~=z2), ...
 'ser',r.ser,'bit_errors',r.bit_errors,'num_bits',r.num_bits, ...
 'symbol_errors',r.symbol_errors,'num_symbols',r.num_qam_symbols);
fprintf('L%d %s seed%d BER %.9g SER %.9g\n',row.L,row.jitter_method,seed,r.ber,r.ser);
end
