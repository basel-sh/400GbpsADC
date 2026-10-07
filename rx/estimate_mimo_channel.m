function [H13,H24,H23,H14,chest_diag] = estimate_mimo_channel(cfg,opts)
% Paper Eqs.7-12, followed by averaging inverse coefficients (Fig.7).
% Batch pilots to retain channel memory between adjacent symbols.
if nargin<2, opts=struct(); end
N=cfg.ofdm.N_used; L=cfg.chest.L_moving_avg;
if ~isfield(opts,'seed_offset'), opts.seed_offset=0; end
base_seed=cfg.sim.rng_seed+opts.seed_offset+777;
if isfield(cfg.chest,'vary_pilots') && ~cfg.chest.vary_pilots
    b=generate_bits(2*N,base_seed); S=repmat(qam_modulate(b,4),1,L);
else
    b=generate_bits(2*N*L,base_seed); S=reshape(qam_modulate(b,4),N,L);
end
if isfield(cfg.chest,'pilot_scale'),S=S*cfg.chest.pilot_scale;end
X1=zeros(N,2*L); X2=X1;
X1(:,1:2:end)=S; X1(:,2:2:end)=S;
X2(:,1:2:end)=-S; X2(:,2:2:end)=S;
opts.seed_offset=5000+opts.seed_offset;
[Y1,Y2]=link_forward_pass(X1,X2,cfg,opts);
[h13,h23,h14,h24]=channel_estimation(S,Y1(:,1:2:end), ...
    Y2(:,1:2:end),Y1(:,2:2:end),Y2(:,2:2:end));
H13=mean(h13,2); H23=mean(h23,2); H14=mean(h14,2); H24=mean(h24,2);
chest_diag=struct('H13_raw',h13,'H23_raw',h23,'H14_raw',h14,'H24_raw',h24);
D=h13.*h24-h23.*h14;
if any(abs(D(:))<1e-12), error('CHEST:singular','Singular training estimate'); end
p1=h24./D; p2=-h23./D; p3=-h14./D; p4=h13./D;
if ~isfield(cfg.chest,'average_domain') || strcmp(cfg.chest.average_domain,'coefficients')
    chest_diag.P1=mean(p1,2); chest_diag.P2=mean(p2,2);
    chest_diag.P3=mean(p3,2); chest_diag.P4=mean(p4,2);
else
    D=H13.*H24-H23.*H14;
    chest_diag.P1=H24./D; chest_diag.P2=-H23./D;
    chest_diag.P3=-H14./D; chest_diag.P4=H13./D;
end
chest_diag.P_conv_L=1:L;
chest_diag.H13_mag_vs_L=abs(cumsum(h13,2)./(1:L));
chest_diag.P1_mag_vs_L=abs(cumsum(p1,2)./(1:L));
chest_diag.P2_mag_vs_L=abs(cumsum(p2,2)./(1:L));
end
