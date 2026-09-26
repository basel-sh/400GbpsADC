function [Xhat1, Xhat2] = mimo_fde(Y1, Y2, H13, H23, H14, H24, mode)
%MIMO_FDE  Frequency-domain equalizer entry point, selecting between the
%single-lane FDE without FEXT cancellation ([FEXT] eq. (1), Sec. II-B) and
%the full 2x2 MIMO FEXT-cancelling equalizer (mimo/fext_cancellation.m,
%[FEXT] eqs. (3)-(6)).
%
% Inputs:
%   Y1, Y2             - N_used x N_symbols received (un-equalized) symbols
%   H13, H23, H14, H24  - N_used x 1 channel estimates (main: H13,H24;
%                         FEXT: H23,H14)
%   mode                - 'cancel' (default) : full 2x2 MIMO FEXT cancellation
%                         'naive'            : single-lane FDE, X_hat_m = Y_m / H_main_m,
%                                               ignoring FEXT terms entirely
%                                               (reproduces the paper's
%                                               "without FEXT cancellation"
%                                               comparison case, [FEXT] p.85)
%
% Outputs:
%   Xhat1, Xhat2 - N_used x N_symbols equalized symbol estimates

if nargin < 7
    mode = 'cancel';
end

switch mode
    case 'cancel'
        [Xhat1, Xhat2] = fext_cancellation(Y1, Y2, H13, H23, H14, H24);
    case 'naive'
        Xhat1 = Y1 ./ H13;
        Xhat2 = Y2 ./ H24;
    otherwise
        error('mimo_fde:badMode', 'mode must be ''cancel'' or ''naive''');
end

end
