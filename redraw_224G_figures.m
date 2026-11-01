function figures = redraw_224G_figures(show_figures)
%REDRAW_224G_FIGURES  Recreate the redesigned figures entirely in MATLAB.
%   redraw_224G_figures       redraws saved results and opens the figures.
%   redraw_224G_figures(false) redraws PNGs without opening figure windows.
% No Python, new random samples, or link simulation is used. main_224 calls
% these same plotting functions during a fresh full simulation.
if nargin < 1, show_figures = true; end
root = fileparts(mfilename('fullpath'));
addpath(genpath(root));
snapshot_path = fullfile(root,'results','224G','results_224G.mat');
if ~exist(snapshot_path,'file')
    error('redraw_224G_figures:noResults','Run main_224 first to create results_224G.mat.');
end
snapshot = load(snapshot_path,'results');
r = snapshot.results;
fig_dir = fullfile(root,'results','224G','figures');
r2 = r.test234.test2; r3 = r.test234.test3; r4 = r.test234.test4;
r6 = r.test56.test6;
figures = plot_fext_diagnostics(r2,r3,r4,r.cfg,fig_dir);
figures(end+1) = plot_constellation(r6.rx_syms1_other,r6.rx_syms1, ...
    'TEST 6: full 224G baseline constellation, lane 1 (all sub-channels)', ...
    fullfile(fig_dir,'fig04_05_constellation_before_after_fext_cancel.png'));
N = r.cfg.ofdm.N_used;
sub_idx = max(round([0.05 0.4 0.9]*N),1);
labels = {'low-frequency','mid-frequency','high-frequency'};
for i=1:numel(sub_idx)
    k=sub_idx(i); pick=k:N:numel(r3.rx_syms1);
    figures(end+1) = plot_constellation(r3.rx_syms1(pick),r4.rx_syms1(pick), ...
        sprintf('TEST 3/4: sub-channel k=%d (%s), lane 1',k,labels{i}), ...
        fullfile(fig_dir,sprintf('test4_constellation_k%d_%s.png',k,labels{i})));
end
figures(end+1) = plot_baseline_ser(r6,fig_dir);
if show_figures
    set(figures,'Visible','on');
else
    close(figures);
end
fprintf('Redrew 7 comparison figures in MATLAB from saved samples.\n');
fprintf('Output: %s\n',fig_dir);
end
