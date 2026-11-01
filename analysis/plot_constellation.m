function fig = plot_constellation(syms_before, syms_after, title_str, save_path)
%PLOT_CONSTELLATION  Compare QAM constellations on matched, readable axes.
% Separate panels prevent nearly coincident cancellation cases from hiding
% one another. Orange = without FEXT cancellation; blue = with cancellation.
%
% Inputs:
%   syms_before - complex vector (e.g. without FEXT cancellation), or []
%   syms_after  - complex vector (e.g. with FEXT cancellation)
%   title_str   - plot title
%   save_path   - if provided and non-empty, saves the figure as a PNG

fig = figure('Visible', 'off', 'Color', 'w', ...
    'Position', [100 100 1100 560]);
orange = [0.85 0.325 0.098];
blue = [0 0.447 0.741];
ink = [0.10 0.16 0.20];
all_syms = [syms_before(:); syms_after(:)];
extent = max(abs([real(all_syms); imag(all_syms)]));
if isempty(extent) || ~isfinite(extent) || extent == 0
    extent = 1;
end
limit = 1.08 * extent;

if ~isempty(syms_before)
    panel_count = 2;
    series = {syms_before, syms_after};
    labels = {'Without FEXT cancellation', 'With FEXT cancellation'};
    colors = {orange, blue};
else
    panel_count = 1;
    series = {syms_after};
    labels = {'With FEXT cancellation'};
    colors = {blue};
end

layout = tiledlayout(fig, 1, panel_count, ...
    'TileSpacing', 'compact', 'Padding', 'compact');
heading = title(layout, title_str, 'Interpreter', 'none', ...
    'Color', ink, 'FontSize', 14, 'FontWeight', 'bold'); %#ok<NASGU>
for panel = 1:panel_count
    ax = nexttile(layout);
    values = series{panel};
    plot(ax, real(values), imag(values), '.', ...
        'Color', colors{panel}, 'MarkerSize', 4);
    set(ax, 'Color', 'w', 'XColor', ink, 'YColor', ink, ...
        'GridColor', [0.68 0.73 0.76], 'GridAlpha', 0.35, ...
        'FontSize', 12, 'LineWidth', 1);
    axis(ax, 'equal');
    xlim(ax, [-limit limit]);
    ylim(ax, [-limit limit]);
    grid(ax, 'on');
    box(ax, 'on');
    xlabel(ax, 'In-phase (I)', 'Color', ink);
    ylabel(ax, 'Quadrature (Q)', 'Color', ink);
    title(ax, labels{panel}, 'Color', colors{panel}, 'FontSize', 13);
end

if nargin >= 4 && ~isempty(save_path)
    save_figure(fig, save_path);
end

end
