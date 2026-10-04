function fig = plot_channel_response(cfg, save_path)
%PLOT_CHANNEL_RESPONSE  Plot the main (THRU) and FEXT synthetic channel
%magnitude responses vs. frequency, matching the style of [FEXT] Fig. 8.
%
% Both curves are evaluated from the SAME objects the simulation uses (the
% truncated minimum-phase FIRs), so the figure shows what the link really
% sees (earlier versions mixed the analytic main-loss law with the FEXT FIR).

[h_main, main_info] = main_channel(cfg);
[h_fext, ~] = fext_channel(cfg, main_info);

Nfft = cfg.channel.ir_fft_len;
f_ir = (0:Nfft/2) * (cfg.fs/Nfft);
Hm = fft(h_main, Nfft);
Hf = fft(h_fext, Nfft);
main_dB = 20*log10(abs(Hm(1:numel(f_ir))) + 1e-12);
fext_dB = 20*log10(abs(Hf(1:numel(f_ir))) + 1e-12);

fig = figure('Visible', 'off', 'Color', 'w', 'Position', [100 100 640 420]);
hold on; grid on; box on;
ax_ch = gca;
plot(f_ir/1e9, main_dB, 'b-',  'LineWidth', 1.5, 'DisplayName', 'Main (THRU) channel');
plot(f_ir/1e9, fext_dB, 'r--', 'LineWidth', 1.5, 'DisplayName', 'FEXT channel');
xlabel('Frequency (GHz)');
ylabel('Magnitude response (dB)');
title('Synthetic main and FEXT channel frequency response (parameterized model)');
legend('Location', 'best');
xlim([0, cfg.fs/2/1e9]);
ylim([-70, 0]);
% anchors (the 40 GHz anchor lies just outside the plotted band edge)
plot([1 1]*cfg.channel.fext_ratio_at_freq/1e9, [-70 0], 'k:', 'LineWidth', 1, 'HandleVisibility', 'off');
text(cfg.channel.fext_ratio_at_freq/1e9, -66, sprintf('  %d dB main/FEXT @ %.1f GHz', ...
    round(cfg.channel.fext_to_main_ratio_dB), cfg.channel.fext_ratio_at_freq/1e9), ...
    'Parent', ax_ch, 'FontSize', 8);
text(cfg.fs/2/1e9, -3, sprintf('main loss: %d dB @ %.0f GHz anchor  ', ...
    round(cfg.channel.main_loss_dB_at_f), cfg.channel.main_loss_at_freq/1e9), ...
    'Parent', ax_ch, 'HorizontalAlignment', 'right', 'FontSize', 8);
if nargin >= 2 && ~isempty(save_path)
    save_figure(fig, save_path);
end
end
