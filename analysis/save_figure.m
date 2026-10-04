function save_figure(fig, save_path)
%SAVE_FIGURE  Save a figure handle to a PNG at save_path, creating parent
%directories as needed (used by every plot_*.m function for automatic,
%consistent result saving -- Part 11 code-quality requirement).
[d, ~, ~] = fileparts(save_path);
if ~isempty(d) && ~exist(d, 'dir')
    mkdir(d);
end
set(fig, 'PaperPositionMode', 'auto');
try
    exportgraphics(fig, save_path, 'Resolution', 150);
catch
    print(fig, save_path, '-dpng', '-r150');
end
end
