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

fig = figure('Visible', 'off', 'Color', 'w', 'Position', [100 100 640 460]);
hold on; grid on; box on;
markers = {'o-','s-','^-','d-','v-','p-'};
for c = 1:numel(y_cell)
    m = markers{mod(c-1, numel(markers))+1};
    if use_semilogy
        semilogy(x, max(y_cell{c}, eps), m, 'LineWidth', 1.5, 'MarkerSize', 5, ...
            'DisplayName', legend_labels{c});
    else
        plot(x, y_cell{c}, m, 'LineWidth', 1.5, 'MarkerSize', 5, ...
            'DisplayName', legend_labels{c});
    end
end
xlabel(x_label);
ylabel(y_label);
title(title_str, 'Interpreter', 'none');
legend('Location', 'best');

if nargin >= 7 && ~isempty(save_path)
    save_figure(fig, save_path);
end

end
