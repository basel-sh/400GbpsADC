function fig = plot_baseline_ser(r6, fig_dir)
%PLOT_BASELINE_SER  Both measured SERs on a zero-based, labelled linear axis.
fig = figure('Visible','off','Color','w','Position',[100 100 900 540]);
ax = axes(fig);
values = [r6.ser_other_mode r6.ser];
b = bar(ax, 1:2, values, 0.55, 'FaceColor','flat');
b.CData = [0.85 0.325 0.098; 0 0.447 0.741];
peak = max(values);
if peak <= 0, peak = 1 / r6.num_qam_symbols; end
ylim(ax,[0 1.3*peak]);
xticks(ax,1:2);
xticklabels(ax,{'Without FEXT cancellation','With FEXT cancellation'});
ylabel(ax,'Observed symbol error rate');
title(ax,'Full 224G baseline: SER with and without FEXT cancellation');
ax.YAxis.Exponent = 0;
ytickformat(ax,'%.1e');
set(ax,'YScale','linear','FontSize',12);
grid(ax,'on'); box(ax,'on');
for j=1:2
    text(ax,j,values(j)+0.035*peak,sprintf('%.4e',values(j)), ...
        'HorizontalAlignment','center','VerticalAlignment','bottom', ...
        'FontSize',12,'FontWeight','bold','Color',[0.10 0.16 0.20]);
end
save_figure(fig,fullfile(fig_dir,'fig08_mimo_comparison.png'));
end
