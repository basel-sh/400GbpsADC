function fig = plot_results(x, y_cell, legend_labels, x_label, y_label, title_str, save_path, use_semilogy)
%PLOT_RESULTS  Generic multi-curve results plot (BER/SER vs. swept
%parameter), used across experiments/*.m for consistent, presentation-ready
%figure styling.
%
% Inputs:
%   x             - 1 x N x-axis values (shared across curves)
%   y_cell        - 1 x C cell array, each a 1 x N vector of y-values
%   legend_labels - 1 x C cell array of strings
%   x_label, y_label, title_str - axis/title strings
%   save_path     - if non-empty, saves the figure as PNG
%   use_semilogy  - logical, default true (BER/SER plots are log-scale)

if nargin < 8
    use_semilogy = true;
end

fig = figure('Visible', 'off', 'Color', 'w', 'Position', [100 100 900 560]);
ax = axes(fig);
hold(ax, 'on'); grid(ax, 'on'); box(ax, 'on');
all_values = cellfun(@(v) v(:), y_cell, 'UniformOutput', false);
all_values = vertcat(all_values{:});
positive = all_values(isfinite(all_values) & all_values > 0);
log_scale = use_semilogy && ~isempty(positive);
if log_scale
    % Set the scale explicitly: semilogy with hold already on can retain a
    % linear scale. Zero observations are marked at a labelled display floor.
    set(ax, 'YScale', 'log');
    display_floor = 10^(floor(log10(min(positive))) - 1);
end
markers = {'o-','s-','^-','d-','v-','p-'};
palette = [0 0.447 0.741; 0.85 0.325 0.098; 0.10 0.60 0.40];
has_zero_floor = false;
for c = 1:numel(y_cell)
    m = markers{mod(c-1, numel(markers))+1};
    label = lower(legend_labels{c});
    color = palette(mod(c-1,size(palette,1))+1,:);
    if contains(label, 'without'), color = palette(2,:);
    elseif contains(label, 'with fext'), color = palette(1,:); end
    values = y_cell{c};
    if log_scale
        values(values == 0) = NaN;
    end
    plot(ax, x, values, m, 'Color', color, 'LineWidth', 1.6, 'MarkerSize', 5, ...
        'DisplayName', legend_labels{c});
    if log_scale && any(y_cell{c} == 0)
        zero_idx = y_cell{c} == 0;
        plot(ax, x(zero_idx), display_floor*ones(1,nnz(zero_idx)), 'v', ...
            'Color', color, 'MarkerFaceColor', 'w', 'MarkerSize', 7, ...
            'HandleVisibility', 'off');
        has_zero_floor = true;
    end
end
xlabel(ax, x_label); ylabel(ax, y_label);
title(ax, title_str, 'Interpreter', 'none');
legend(ax, 'Location', 'best');
if has_zero_floor
    ylim(ax, [display_floor/2 max(positive)*1.5]);
    subtitle(ax, 'Open triangles: zero observed errors, shown at a display floor');
elseif isempty(positive) && all(all_values == 0)
    ylim(ax, [-0.05 1]);
    subtitle(ax, 'All measurements are zero observed errors');
end

if nargin >= 7 && ~isempty(save_path)
    save_figure(fig, save_path);
end

end
