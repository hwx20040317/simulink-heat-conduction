function report = test_shc
%TEST_SHC Reference heat flows, material equivalence, invalid inputs and energy.
% SPDX-License-Identifier: MIT
root = fileparts(fileparts(mfilename('fullpath')));
setup_shc(false);
load_system(fullfile(root, 'library', 'SHCLib.slx'));
names = {'Planar conduction', 'Planar conduction 2 materials', ...
    'Radial conduction', 'Radial conduction 2 materials'};
model = 'shc_reference_check';
assert(~bdIsLoaded(model), 'SHC:TestModelAlreadyLoaded', 'Close shc_reference_check first.');
new_system(model);
cleanup = onCleanup(@() close_system(model, 0)); %#ok<NASGU>
set_param(model, 'SolverType', 'Fixed-step', 'Solver', 'FixedStepDiscrete', ...
    'FixedStep', '0.01', 'StopTime', '0.02', 'ReturnWorkspaceOutputs', 'on');
add_block('simulink/Sources/Constant', [model '/T1'], 'Value', '40');
add_block('simulink/Sources/Constant', [model '/T2'], 'Value', '20');
for k = 1:4
    element = sprintf('Element%d', k);
    mux = sprintf('Mux%d', k);
    record = sprintf('Record%d', k);
    add_block(['SHCLib/' names{k}], [model '/' element]);
    add_block('simulink/Signal Routing/Mux', [model '/' mux], 'Inputs', '2');
    add_block('simulink/Sinks/To Workspace', [model '/' record], ...
        'VariableName', sprintf('heat%d', k), 'SaveFormat', 'Array');
    add_line(model, 'T1/1', [element '/1']);
    add_line(model, 'T2/1', [element '/2']);
    add_line(model, [element '/1'], [mux '/1']);
    add_line(model, [element '/2'], [mux '/2']);
    add_line(model, [mux '/1'], [record '/1']);
end
set_param([model '/Element3'], 'lambda', '1', 'le', '1/(2*pi)', ...
    'diamInt', '1', 'diamExt', 'exp(1)');
set_param([model '/Element4'], 'lambda1', '1', 'lambda2', '2', 'le', '1/(2*pi)', ...
    'diamInt', '1', 'diamCt', 'exp(1)', 'diamExt', 'exp(3)', 'ctr', '0.5');
passed = 0;
temperatures = [40 20;20 40;20 20];
magnitudes = [400 25 20 8];
for c = 1:3
    set_param([model '/T1'], 'Value', num2str(temperatures(c,1)));
    set_param([model '/T2'], 'Value', num2str(temperatures(c,2)));
    output = sim(model, 'ReturnWorkspaceOutputs', 'on');
    direction = sign(temperatures(c,2)-temperatures(c,1));
    for k = 1:4
        value = output.get(sprintf('heat%d', k));
        expected = direction*magnitudes(k)*[1 -1];
        assert(max(abs(value(end,:)-expected)) < 1e-10, 'Incorrect reference heat flow.');
        assert(max(abs(sum(value,2))) < 1e-12, 'Heat flows are not equal and opposite.');
        passed = passed+1;
        fprintf('PASS %02d reference %s, T=[%g %g], Q=[%g %g] W\n', ...
            passed, names{k}, temperatures(c,:), value(end,:));
    end
end

set_param([model '/T1'], 'Value', '40');
set_param([model '/T2'], 'Value', '20');
set_param([model '/Element2'], 'ctr', '0');
output = sim(model, 'ReturnWorkspaceOutputs', 'on');
value = output.get('heat2');
assert(abs(value(end,2)-100/3) < 1e-10, 'Zero-contact result is incorrect.');
passed = passed+1;
fprintf('PASS %02d zero-contact planar result\n', passed);

set_param([model '/Element1'], 'lambda', '1', 'distance', '0.007', 'area', '0.01');
set_param([model '/Element2'], 'lambda2', '1');
output = sim(model, 'ReturnWorkspaceOutputs', 'on');
a = output.get('heat1'); b = output.get('heat2');
assert(max(abs(a(end,:)-b(end,:))) < 1e-10, 'Planar material equivalence failed.');
passed = passed+1;
fprintf('PASS %02d identical-material planar equivalence\n', passed);

set_param([model '/Element3'], 'diamExt', 'exp(3)');
set_param([model '/Element4'], 'lambda2', '1', 'ctr', '0');
output = sim(model, 'ReturnWorkspaceOutputs', 'on');
a = output.get('heat3'); b = output.get('heat4');
assert(max(abs(a(end,:)-b(end,:))) < 1e-10, 'Radial material equivalence failed.');
assert(abs(a(end,2)-20/3) < 1e-10, 'Radial analytical result is incorrect.');
passed = passed+1;
fprintf('PASS %02d identical-material cylindrical equivalence\n', passed);

invalid = {1, 'area', '0', 'area'; ...
    1, 'distance', '0', 'distance'; ...
    2, 'ctr', '-1', 'ctr'; ...
    3, 'diamExt', '0.5', 'Require 0 < diamInt < diamExt'; ...
    4, 'diamCt', '30', 'Require 0 < diamInt < diamCt < diamExt'; ...
    3, 'lambda', 'NaN', 'lambda'; ...
    4, 'le', '0', 'le'};
for k = 1:size(invalid,1)
    block = sprintf('%s/Element%d', model, invalid{k,1});
    parameter = invalid{k,2};
    previous = get_param(block, parameter);
    rejected = false;
    try
        set_param(block, parameter, invalid{k,3});
        sim(model, 'ReturnWorkspaceOutputs', 'on');
    catch exception
        rejected = contains(getReport(exception, 'extended', 'hyperlinks', 'off'), invalid{k,4});
    end
    set_param(block, parameter, previous);
    assert(rejected, 'An invalid parameter was not rejected for the expected reason.');
    passed = passed+1;
    fprintf('PASS %02d invalid Element%d.%s rejected\n', passed, invalid{k,1}, parameter);
end

result = run_shc_demo(false);
assert(all(isfinite(result.temperature(:))), 'Nonfinite transient temperature.');
assert(result.relativeEnergyError < 1e-10, 'Energy conservation failed.');
assert(result.maxTemperatureError < 2e-4, 'Transient differs from analytical solution.');
passed = passed+1;
fprintf('PASS %02d transient energy and analytical comparison\n', passed);

callbacks = {'PreLoadFcn', 'PostLoadFcn', 'InitFcn', 'StartFcn', 'PreSaveFcn'};
for k = 1:numel(callbacks)
    assert(isempty(get_param('SHCLib', callbacks{k})), 'Unexpected library callback.');
end
blocks = find_system('SHCLib', 'LookUnderMasks', 'all', 'Type', 'Block');
for k = 1:numel(blocks)
    reference = get_param(blocks{k}, 'ReferenceBlock');
    assert(isempty(reference) || startsWith(reference, 'simulink/'), ...
        'Unexpected third-party block reference: %s', reference);
end
passed = passed+1;
fprintf('PASS %02d library callbacks and block dependency audit\n', passed);
report.projectVersion = '0.1.0';
report.matlabVersion = version;
report.passed = passed;
report.relativeEnergyError = result.relativeEnergyError;
report.maxTemperatureError = result.maxTemperatureError;
report.generatedUTC = char(datetime('now', 'TimeZone', 'UTC', 'Format', 'yyyy-MM-dd''T''HH:mm:ss''Z'''));
outputDir = fullfile(root, 'build');
if ~isfolder(outputDir), mkdir(outputDir); end
save(fullfile(outputDir, 'validation.mat'), 'report', 'result');
fid = fopen(fullfile(outputDir, 'validation.json'), 'w', 'n', 'UTF-8');
assert(fid >= 0, 'Cannot write verification report.');
fileCleanup = onCleanup(@() fclose(fid)); %#ok<NASGU>
fprintf(fid, '%s\n', jsonencode(report, 'PrettyPrint', true));
fprintf('ALL_CHECKS_PASSED: %d; analytical error %.8g degC; energy error %.8g\n', ...
    passed, report.maxTemperatureError, report.relativeEnergyError);
end
