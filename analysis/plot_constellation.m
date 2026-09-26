function fig = plot_constellation(syms_before, syms_after, title_str, save_path)
%PLOT_CONSTELLATION  Scatter plot of QAM constellations before/after
%equalization (or FEXT cancellation), matching [FEXT] Fig. 10 style.
%
% Inputs:
%   syms_before - complex vector (e.g. without FEXT cancellation), or []
%   syms_after  - complex vector (e.g. with FEXT cancellation)
%   title_str   - plot title
%   save_path   - if provided and non-empty, saves the figure as a PNG

fig = figure('Visible', 'off', 'Color', 'w', 'Position', [100 100 500 480]);
hold on; grid on; box on;
if ~isempty(syms_before)
    plot(real(syms_before), imag(syms_before), 'k.', 'MarkerSize', 4, ...
        'DisplayName', 'Without FEXT cancellation');
end
plot(real(syms_after), imag(syms_after), 'b.', 'MarkerSize', 4, ...
    'DisplayName', 'With FEXT cancellation');
axis equal;
xlabel('In-phase (I)');
ylabel('Quadrature (Q)');
title(title_str, 'Interpreter', 'none');
legend('Location', 'bestoutside');

if nargin >= 4 && ~isempty(save_path)
    save_figure(fig, save_path);
end

end
