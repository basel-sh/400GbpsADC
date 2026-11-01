function save_figure(fig, save_path)
%SAVE_FIGURE  Save a figure handle to a PNG at save_path, creating parent
%directories as needed (used by every plot_*.m function for automatic,
%consistent result saving -- Part 11 code-quality requirement).
[d, ~, ~] = fileparts(save_path);
if ~isempty(d) && ~exist(d, 'dir')
    mkdir(d);
end
% Do not inherit dark-theme axes/text when exporting a white presentation PNG.
ink = [0.10 0.16 0.20];
set(fig, 'Color', 'w', 'PaperPositionMode', 'auto');
axes_handles = findall(fig, 'Type', 'axes');
for ax = axes_handles(:)'
    set(ax, 'Color', 'w', 'XColor', ink, 'YColor', ink, 'ZColor', ink, ...
        'GridColor', [0.68 0.73 0.76], 'GridAlpha', 0.35);
end
legends = findall(fig, 'Type', 'legend');
for item = legends(:)'
    set(item, 'Color', 'w', 'TextColor', ink, 'EdgeColor', [0.75 0.80 0.82]);
end
% Preserve deliberate orange/blue text; replace only pale theme defaults.
text_handles = findall(fig, '-property', 'Color');
for item = text_handles(:)'
    if ~strcmp(get(item, 'Type'), 'text'), continue; end
    color = get(item, 'Color');
    if isnumeric(color) && numel(color) == 3 && min(color) > 0.60
        set(item, 'Color', ink);
    end
end
drawnow;
% Render first, then replace the PNG. This also avoids truncating the old
% image if a renderer fails or an image viewer has the file open.
if isempty(d), d = pwd; end
staged_path = [tempname(d) '.png'];
cleanup = onCleanup(@() remove_staged_file(staged_path)); %#ok<NASGU>
try
    exportgraphics(fig, staged_path, 'Resolution', 150, 'BackgroundColor', 'white');
catch
    print(fig, staged_path, '-dpng', '-r150');
end
[ok, message] = movefile(staged_path, save_path, 'f');
if ~ok, error('save_figure:replace', 'Could not save %s: %s', save_path, message); end
end

function remove_staged_file(path)
if exist(path, 'file'), delete(path); end
end
