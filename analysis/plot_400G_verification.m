function plot_400G_verification
root=fileparts(fileparts(mfilename('fullpath')));
out=fullfile(root,'results','400G_verification');figdir=fullfile(out,'figures');
if ~exist(figdir,'dir'),mkdir(figdir);end
t=readtable(fullfile(out,'screening.csv'),'TextType','string');
names=["64QAM_paper_scalar_budgets","64QAM_only_9bit", ...
 "64QAM_low_loss_matched_loading","64QAM_low_noise","64QAM_candidate_8bit"];
ix=zeros(size(names));for k=1:numel(names),ix(k)=find(t.name==names(k),1);end
y=t.ber(ix);zero=y==0;y(zero)=-log(.05)./t.num_bits(ix(zero));
f=figure('Visible','off','Color','w','Position',[80 80 1100 610]);
semilogy(1:5,y,'o-','LineWidth',2,'MarkerSize',8,'Color',[.12 .34 .52]);hold on;
semilogy(find(zero),y(zero),'v','MarkerSize',11,'LineWidth',2,'Color',[.08 .5 .35]);
yline(2.4e-6,'--','LineWidth',1.5,'Color',[.7 .15 .2]);
text(5.25,2.4e-6*1.25,'Paper BER target: 2.4e-6','HorizontalAlignment','right','Color',[.7 .15 .2]);
set(gca,'XTick',1:5,'XTickLabel',{'Original budgets','9-bit only', ...
 'Low-loss channel + loading','0.3 mV noise','22.3 fs jitter / 8-bit'});
xlim([.7 5.3]);ylim([1e-8 1]);grid on;box on;
ylabel('Pre-FEC BER','Color',[.15 .15 .15]);title('400 Gb/s per lane: which upgrades matter?','Color',[.15 .15 .15]);
style_axes;
for k=1:5
 if zero(k),lab=sprintf('0 errors; upper bound %.2g',y(k));else,lab=sprintf('%.3g',y(k));end
 align='center';if k==5,align='right';end
 text(k,y(k)*1.6,lab,'HorizontalAlignment',align,'FontSize',10,'Color',[.15 .15 .15]);
end
annotation(f,'textbox',[.1 .01 .85 .09],'String', ...
 'Screening: 6,132,000 bits/case. Zero-error point is shown at its nominal 95% upper bound, not at BER=0. Synthetic channels; clipping fixed at 12.6/13.4 dB.', ...
 'EdgeColor','none','FontSize',10,'Color',[.15 .15 .15]);
exportgraphics(f,fullfile(figdir,'400G_upgrade_bottlenecks.png'),'Resolution',180);
savefig(f,fullfile(figdir,'400G_upgrade_bottlenecks.fig'));close(f);
p=readtable(fullfile(out,'pooled.csv'),'TextType','string');
a=readtable(fullfile(out,'training_pooled.csv'));
y=[p.ber;a.ber];upper=[p.ber_upper95_nominal;upper95(a.bit_errors,a.num_bits)];
zero=y==0;display_y=y;display_y(zero)=upper(zero);
f=figure('Visible','off','Color','w','Position',[80 80 1100 610]);
semilogy(1:4,display_y,'o','MarkerSize',9,'LineWidth',2,'Color',[.12 .34 .52]);hold on;
semilogy(find(zero),display_y(zero),'v','MarkerSize',11,'LineWidth',2,'Color',[.08 .5 .35]);
semilogy(1:4,upper,'_','MarkerSize',17,'LineWidth',2,'Color',[.3 .3 .3]);
yline(2.4e-6,'--','LineWidth',1.5,'Color',[.7 .15 .2]);
text(4.35,2.4e-6*1.25,'Paper BER target: 2.4e-6','HorizontalAlignment','right','Color',[.7 .15 .2]);
set(gca,'XTick',1:4,'XTickLabel',{'64-QAM / 8-bit','256-QAM / 9-bit', ...
 '256-QAM / lower noise+jitter','256-QAM / L=1000'});
xlim([.6 4.4]);ylim([1e-8 1e-4]);grid on;box on;
ylabel('Pre-FEC BER','Color',[.15 .15 .15]);title('Independent long-run verification at 400 Gb/s per lane','Color',[.15 .15 .15]);
style_axes;
for k=1:4
 if zero(k),lab=sprintf('0 observed; upper95 %.3g',upper(k));else,lab=sprintf('BER %.3g',y(k));end
 text(k,display_y(k)*1.65,lab,'HorizontalAlignment','center','FontSize',10,'Color',[.15 .15 .15]);
end
annotation(f,'textbox',[.1 .01 .85 .09],'String', ...
 'Three independent seeds/candidate. 103 million bits for 64-QAM; 137 million for each 256-QAM candidate. Bounds assume independent decisions and do not cover model uncertainty. Ideal converters; synthetic low-loss channel.', ...
 'EdgeColor','none','FontSize',10,'Color',[.15 .15 .15]);
exportgraphics(f,fullfile(figdir,'400G_independent_confirmation.png'),'Resolution',180);
savefig(f,fullfile(figdir,'400G_independent_confirmation.fig'));close(f);
fprintf('400G verification charts saved to %s\n',figdir);
end
function style_axes
set(gca,'Color','w','XColor',[.15 .15 .15],'YColor',[.15 .15 .15], ...
 'GridColor',[.65 .65 .65],'MinorGridColor',[.8 .8 .8], ...
 'Position',[.1 .22 .86 .66],'FontSize',11);
end
function u=upper95(e,n)
if e==0,u=-log(.05)/n;return;end
z=1.64485362695147;p=e/n;
u=(p+z^2/(2*n)+z*sqrt(p*(1-p)/n+z^2/(4*n^2)))/(1+z^2/n);
end
