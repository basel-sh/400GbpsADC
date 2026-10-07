% AWGN-only oracle: isolate irreducible decision errors from training/quantization.
addpath(genpath(fileparts(mfilename('fullpath'))));
out=fullfile(pwd,'results','target_reproduction');
c=config_224G();c.sim.num_ofdm_symbols=5600;
o=struct('enable_channel',true,'enable_fext',true,'apply_impairments',true);
c=calibrate_link_gains(c,o);N=c.ofdm.N_used;T=c.sim.num_ofdm_symbols;
g=deemphasis_gain_vector(c);[hm,info]=main_channel(c);[hf,~]=fext_channel(c,info);
w=exp(-2j*pi*c.ofdm.k_idx*(0:numel(hm)-1)/c.ofdm.N_FFT);
H=c.dac.scale_fixed*g.*(w*hm);F=c.dac.scale_fixed*g.*(w*hf);
% For unitary FFT of real white noise: E|Nk|^2 = time-domain noise variance.
q=@(x)0.5*erfc(x/sqrt(2));gainnoise=(abs(H).^2+abs(F).^2)./abs(H.^2-F.^2).^2;
snr=1./(c.noise.rx_input_rms_V^2*gainnoise);
prail=2*(1-1/sqrt(c.mod.order))*q(sqrt(3*snr/(c.mod.order-1)));
analytic_ser=mean(1-(1-prail).^2);
results=struct([]);
for seed=[419 443 467]
 b1=generate_bits(N*6*T,seed);b2=generate_bits(N*6*T,seed+1);
 X1=reshape(qam_modulate(b1,64),N,T);X2=reshape(qam_modulate(b2,64),N,T);
 rng(seed+2,'twister');noise=c.noise.rx_input_rms_V/sqrt(2);
 Y1=H.*X1+F.*X2+noise*(randn(N,T)+1j*randn(N,T));
 Y2=F.*X1+H.*X2+noise*(randn(N,T)+1j*randn(N,T));
 [Z1,Z2]=mimo_fde(Y1,Y2,H,F,F,H,'cancel');
 e=sum(qam_demodulate(Z1(:),64)~=b1)+sum(qam_demodulate(Z2(:),64)~=b2);
 [s1,n1]=calculate_ser(X1,Z1,64);[s2,n2]=calculate_ser(X2,Z2,64);
 row=struct('seed',seed,'ber',e/(2*numel(b1)),'ser',(s1+s2)/2, ...
 'bit_errors',e,'num_bits',2*numel(b1),'symbol_errors',n1+n2,'num_symbols',2*N*T);
 if isempty(results),results=row;else,results(end+1)=row;end
 fprintf('AWGN_ONLY_ORACLE seed%d BER %.6g SER %.6g analyticSER %.6g\n',seed,row.ber,row.ser,analytic_ser);
end
writetable(struct2table(results),fullfile(out,'awgn_oracle.csv'));
save(fullfile(out,'awgn_oracle.mat'),'results','snr','analytic_ser','c');
