function figures = plot_fext_diagnostics(r2, r3, r4, cfg, fig_dir)
%PLOT_FEXT_DIAGNOSTICS  Honest SER and EVM comparisons, including zero errors.
% The per-tone panels use lane 1. Overall metrics pool both lanes (SER) or
% use the saved mean of the two lane EVM percentages. No link is rerun here.
orange = [0.85 0.325 0.098];
blue = [0 0.447 0.741];
ink = [0.10 0.16 0.20];
gray = [0.40 0.48 0.52];
N = cfg.ofdm.N_used;
x3 = reshape(r3.tx_syms1, N, []);
x4 = reshape(r4.tx_syms1, N, []);
y3 = reshape(r3.rx_syms1, N, []);
y4 = reshape(r4.rx_syms1, N, []);
% Same RMS-error / RMS-reference definition as calculate_evm, per tone.
evm3 = 100 * sqrt(mean(abs(y3-x3).^2, 2) ./ mean(abs(x3).^2, 2));
evm4 = 100 * sqrt(mean(abs(y4-x4).^2, 2) ./ mean(abs(x4).^2, 2));

figures = gobjects(1, 2);
figures(1) = figure('Visible','off','Color','w','Position',[100 100 1100 720]);
layout = tiledlayout(figures(1), 2, 1, 'TileSpacing','compact','Padding','compact');
title(layout, 'Tests 3-4: symbol decisions and residual distortion (lane 1)', ...
    'Color',ink,'FontSize',15,'FontWeight','bold');
ax = nexttile(layout);
hold(ax,'on');
plot(ax, 1:N, r3.ser_per_subchannel, '-', 'Color',orange, ...
    'LineWidth',2.5,'DisplayName','Without FEXT cancellation');
plot(ax, 1:N, r4.ser_per_subchannel, '--', 'Color',blue, ...
    'LineWidth',1.6,'DisplayName','With FEXT cancellation');
style_axes(ax, ink); xlim(ax,[1 N]); ylabel(ax,'Observed SER','Color',ink);
if ~any(r3.ser_per_subchannel) && ~any(r4.ser_per_subchannel)
    resolution = 1 / size(x3,2);
    ylim(ax,[-0.12*resolution 1.3*resolution]); yticks(ax,[0 resolution]);
    yline(ax,resolution,':','One symbol error per tone', ...
        'Color',gray,'HandleVisibility','off');
    title(ax,sprintf('Both curves are exactly zero: 0 / %d symbols per subcarrier',size(x3,2)), ...
        'Color',ink,'FontSize',12);
else
    peak = max([r3.ser_per_subchannel(:); r4.ser_per_subchannel(:)]);
    ylim(ax,[-0.04*peak 1.15*peak]);
end
legend(ax,'Location','northeast','TextColor',ink,'Color','w');
ax = nexttile(layout); hold(ax,'on');
plot(ax,1:N,evm3,'-','Color',orange,'LineWidth',1.6,'DisplayName','Without FEXT cancellation');
plot(ax,1:N,evm4,'--','Color',blue,'LineWidth',1.6,'DisplayName','With FEXT cancellation');
style_axes(ax,ink); xlim(ax,[1 N]);
ylim(ax,[0 max(0.01,1.15*max([evm3;evm4]))]);
xlabel(ax,'Subcarrier index k','Color',ink); ylabel(ax,'EVM (%)','Color',ink);
title(ax,'EVM reveals residual distortion even when no symbol decisions are wrong', ...
    'Color',ink,'FontSize',12);
legend(ax,'Location','northeast','TextColor',ink,'Color','w');
save_figure(figures(1),fullfile(fig_dir,'test3_4_ser_per_subchannel.png'));

figures(2) = figure('Visible','off','Color','w','Position',[100 100 1100 580]);
layout = tiledlayout(figures(2),1,2,'TileSpacing','compact','Padding','compact');
title(layout,'Tests 2-4: observed symbol errors and EVM', ...
    'Color',ink,'FontSize',15,'FontWeight','bold');
runs = {r2,r3,r4}; colors = [gray;orange;blue];
labels = {'No FEXT (T2)','No cancellation (T3)','With cancellation (T4)'};
counts = [r2.symbol_errors r3.symbol_errors r4.symbol_errors];
ax = nexttile(layout); hold(ax,'on');
for j=1:3
    scatter(ax,j,counts(j),90,colors(j,:),'filled');
    text(ax,j,counts(j)+0.05*max(1,max(counts)), ...
        sprintf('%d / %s\nSER = %.3g',counts(j),sprintf('%d',runs{j}.num_qam_symbols),runs{j}.ser), ...
        'HorizontalAlignment','center','VerticalAlignment','bottom','Color',ink,'FontSize',11);
end
style_axes(ax,ink); xlim(ax,[0.5 3.5]); ylim(ax,[-0.15 max(1,1.5*max(counts))]);
yticks(ax,unique([0 ceil(max(1,1.5*max(counts)))]));
xticks(ax,1:3); xticklabels(ax,labels); xtickangle(ax,15);
ylabel(ax,'Observed symbol errors (count)','Color',ink);
title(ax,'Zero errors are shown as points, not missing log bars','Color',ink,'FontSize',12);
ax = nexttile(layout);
values = [r2.evm_percent r3.evm_percent r4.evm_percent];
b = bar(ax,1:3,values,'FaceColor','flat'); b.CData = colors;
style_axes(ax,ink); xticks(ax,1:3); xticklabels(ax,labels); xtickangle(ax,15);
ylim(ax,[0 max(0.01,1.25*max(values))]); ylabel(ax,'EVM (%)','Color',ink);
title(ax,'Lower EVM means less residual distortion','Color',ink,'FontSize',12);
for j=1:3
    text(ax,j,values(j)+0.025*max(0.01,max(values)),sprintf('%.3f%%',values(j)), ...
        'HorizontalAlignment','center','VerticalAlignment','bottom','Color',ink,'FontWeight','bold');
end
save_figure(figures(2),fullfile(fig_dir,'test2_4_ser_comparison.png'));
end

function style_axes(ax, ink)
set(ax,'Color','w','XColor',ink,'YColor',ink,'FontSize',11, ...
    'GridColor',[0.68 0.73 0.76],'GridAlpha',0.35,'LineWidth',1);
grid(ax,'on'); box(ax,'on');
end
