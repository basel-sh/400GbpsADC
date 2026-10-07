addpath(genpath(fileparts(mfilename('fullpath'))));out=fullfile(pwd,'results','target_reproduction');
diary(fullfile(out,'zero_noise_l2000.log'));cleanup=onCleanup(@()diary('off'));
rows=struct([]);seeds=[607 631 659];
for i=1:numel(seeds)
 c=config_224G();c.noise.rx_input_rms_V=0;c.sim.num_ofdm_symbols=5600;c.chest.L_moving_avg=2000;
 r=run_224G_test(c,struct('seed_offset',seeds(i)));
 row=struct('seed',seeds(i),'L',2000,'ber',r.ber,'ser',r.ser,'bit_errors',r.bit_errors,'num_bits',r.num_bits,'symbol_errors',r.symbol_errors,'num_symbols',r.num_qam_symbols);
 if i==1,rows=row;else,rows(i)=row;end
 fprintf('Zero-noise L2000 seed%d BER%.9g SER%.9g errors%d/%d\n',seeds(i),r.ber,r.ser,r.bit_errors,r.num_bits);
end
writetable(struct2table(rows),fullfile(out,'zero_noise_l2000.csv'));save(fullfile(out,'zero_noise_l2000.mat'),'rows');fprintf('ZERO_NOISE_L2000_COMPLETE\n');
