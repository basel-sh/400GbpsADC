function fig = plot_channel_response(cfg, save_path)
%PLOT_CHANNEL_RESPONSE  Plot the main (THRU) and FEXT synthetic channel
%magnitude responses vs. frequency, matching the style of [FEXT] Fig. 8.

[h_main, main_info] = main_channel(cfg);
[h_fext, ~] = fext_channel(cfg, main_info); %#ok<ASGLU>

f_axis = linspace(0, cfg.fs/2, 2048);
main_loss_dB = -main_info.loss_dB_fn(f_axis);

fig = figure('Visible', 'off', 'Color', 'w', 'Position', [100 100 640 420]);
hold on; grid on; box on;
plot(f_axis/1e9, main_loss_dB, 'b-', 'LineWidth', 1.5, 'DisplayName', 'Main (THRU) channel');

% FEXT loss = main loss + ratio (recomputed from fext_channel's info for
% consistency, but we only have the impulse response here, so evaluate via
% the FFT magnitude of h_fext directly for the plot)
Hf = fft(h_fext, cfg.channel.ir_fft_len);
f_ir = (0:cfg.channel.ir_fft_len/2) * (cfg.fs/cfg.channel.ir_fft_len);
fext_dB = 20*log10(abs(Hf(1:numel(f_ir))) + 1e-12);
plot(f_ir/1e9, fext_dB, 'r--', 'LineWidth', 1.5, 'DisplayName', 'FEXT channel');

% (xline() is not available in Octave; use a portable vertical line instead)
yl = ylim();
plot([1 1]*cfg.channel.main_loss_at_freq/1e9, yl, 'k:', 'LineWidth', 1, 'HandleVisibility', 'off');
text(cfg.channel.main_loss_at_freq/1e9, yl(2), ...
    sprintf('  %d dB @ %.0f GHz anchor', round(cfg.channel.main_loss_dB_at_f), cfg.channel.main_loss_at_freq/1e9), ...
    'VerticalAlignment', 'top');

xlabel('Frequency (GHz)');
ylabel('Magnitude response (dB)');
title('Synthetic main and FEXT channel frequency response (parameterized model)');
legend('Location', 'best');
xlim([0, cfg.fs/2/1e9]);

if nargin >= 2 && ~isempty(save_path)
    save_figure(fig, save_path);
end

end
