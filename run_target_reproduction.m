% Investigate author-unstated conventions; no successful case is promoted silently.
addpath(genpath(fileparts(mfilename('fullpath'))));
out=fullfile(pwd,'results','target_reproduction');if ~exist(out,'dir'),mkdir(out);end
diary(fullfile(out,'console.log'));cleanup=onCleanup(@()diary('off'));
rows=struct([]);bestber=inf;bestcfg=[];idx=0;
for source={'synthetic','fig8'}
 for noiseref={'channel_output','adc_input'}
  for L=[200 1000]
   for scale=[sqrt(2/42) sqrt(18/42) sqrt(50/42) sqrt(98/42)]
    c=config_224G();c.sim.num_ofdm_symbols=500;c.chest.L_moving_avg=L;
    c.chest.pilot_scale=scale;c.noise.reference=noiseref{1};
    if strcmp(source{1},'fig8')
       c.channel.type='digitized_magnitude_minphase';
       c.channel.main_response_csv=fullfile(pwd,'channel/data/fig8/thru.csv');
       c.channel.fext_response_csv=fullfile(pwd,'channel/data/fig8/fext.csv');
       c.channel.num_taps=256;
    end
    r=run_224G_test(c,struct('seed_offset',401));idx=idx+1;
    row=struct('source',source{1},'noise_reference',noiseref{1},'L',L, ...
       'pilot_scale',scale,'ber',r.ber,'ser',r.ser,'naive_ser',r.ser_other_mode, ...
       'evm_percent',r.evm_percent,'bit_errors',r.bit_errors,'num_bits',r.num_bits);
    if idx==1,rows=row;else,rows(idx)=row;end
    fprintf('%s %s L%d pilot%.3f BER %.6g SER %.6g naive%.4g\n',source{1},noiseref{1},L,scale,r.ber,r.ser,r.ser_other_mode);
    if r.ber<bestber,bestber=r.ber;bestcfg=c;end
   end
  end
 end
end
writetable(struct2table(rows),fullfile(out,'conventions.csv'));
save(fullfile(out,'conventions.mat'),'rows','bestcfg');
fprintf('CONVENTIONS_COMPLETE bestBER %.6g\n',bestber);
