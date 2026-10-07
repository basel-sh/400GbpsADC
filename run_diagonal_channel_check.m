addpath(genpath(fileparts(mfilename('fullpath'))));
out=fullfile(pwd,'results','target_reproduction');
diary(fullfile(out,'diagonal_channel_check.log')); cleanup=onCleanup(@()diary('off'));
c0=config_224G(); c0.channel.ofdm_diagonal=true; c0.sim.num_ofdm_symbols=5600;
rows=struct([]);
for i=1:3
 seed=[521 547 571]; c=c0;
 r=run_224G_test(c,struct('seed_offset',seed(i)));
 row=struct('seed',seed(i),'ber',r.ber,'ser',r.ser,'bit_errors',r.bit_errors, ...
  'num_bits',r.num_bits,'num_symbols',r.num_qam_symbols,'mode','paper diagonal channel, synthetic response');
 if i==1,rows=row;else,rows(i)=row;end
 fprintf('Diagonal synthetic seed %d BER %.9g SER %.9g errors %d/%d\n',seed(i),r.ber,r.ser,r.bit_errors,r.num_bits);
end
writetable(struct2table(rows),fullfile(out,'diagonal_channel_check.csv')); save(fullfile(out,'diagonal_channel_check.mat'),'rows');
fprintf('DIAGONAL_CHANNEL_CHECK_COMPLETE\n');
