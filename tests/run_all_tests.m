function run_all_tests()
%RUN_ALL_TESTS  Fast regression tests for the 224G simulator. Run from
%anywhere:  >> run_all_tests
% Each test throws an error (assert) on failure.

proj_root = fileparts(fileparts(mfilename('fullpath')));
addpath(genpath(proj_root));

tests = {'test_quantizer', 'test_clip_ratio', 'test_deemphasis_gain', ...
         'test_ofdm_roundtrip', 'test_mimo_math', 'test_frozen_gain', ...
         'test_noise_free_floor'};
n_fail = 0;
for i = 1:numel(tests)
    try
        feval(tests{i});
        fprintf('PASS  %s\n', tests{i});
    catch err
        n_fail = n_fail + 1;
        fprintf('FAIL  %s : %s\n', tests{i}, err.message);
    end
end
if n_fail > 0
    error('run_all_tests:failed', '%d test(s) failed', n_fail);
end
fprintf('All %d tests passed.\n', numel(tests));
end
