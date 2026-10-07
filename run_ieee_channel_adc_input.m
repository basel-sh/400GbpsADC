addpath(genpath(fileparts(mfilename('fullpath'))));
out=fullfile(pwd,'results','target_reproduction'); diary(fullfile(out,'ieee_channel_adc_input.log')); cleanup=onCleanup(@()diary('off'));
c0=config_224G(); c0.noise.reference='adc_input'; c0.channel.ofdm_diagonal=true; c0.sim.num_ofdm_symbols=5600; c0.chest.L_moving_avg=1000;
c0.channel.type='measured_complex'; c0.channel.main_response_csv=fullfile(pwd,'channel/data/ieee_shape_search/Bch2_7_t.csv');
c0.channel.fext_response_csv=fullfile(pwd,'channel/data/fig8/fext.csv'); c0.channel.num_taps=256;
rows=struct([]); seeds=[521 547 571];
for i=1:numel(seeds)
 r=run_224G_test(c0,struct('seed_offset',seeds(i)));
 row=struct('seed',seeds(i),'ber',r.ber,'ser',r.ser,'bit_errors',r.bit_errors,'num_bits',r.num_bits, ...
  'symbol_errors',r.symbol_errors,'num_symbols',r.num_qam_symbols,'thru','IEEE Bch2_7 complex','fext','Fig8 magnitude minphase','noise_location','ADC input','mode','diagonal');
 if i==1,rows=row;else,rows(i)=row;end
 fprintf('IEEE Bch2_7 ADC-input seed%d BER%.9g SER%.9g errors%d/%d\n',seeds(i),r.ber,r.ser,r.bit_errors,r.num_bits);
end
writetable(struct2table(rows),fullfile(out,'ieee_channel_adc_input.csv'));save(fullfile(out,'ieee_channel_adc_input.mat'),'rows');
fprintf('IEEE_CHANNEL_ADC_INPUT_COMPLETE\n');
