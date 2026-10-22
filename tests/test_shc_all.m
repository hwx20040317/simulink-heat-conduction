function report = test_shc_all
%TEST_SHC_ALL Run the unchanged conduction references and the v0.2 suite.
% SPDX-License-Identifier: MIT
root = fileparts(fileparts(mfilename('fullpath')));
conduction = test_shc;
thermal = test_shc_thermal;
report.projectVersion = shc_version;
report.matlabVersion = version;
report.conductionChecks = conduction.passed;
report.thermalChecks = thermal.passed;
report.passed = conduction.passed+thermal.passed;
report.conduction = conduction;
report.thermal = thermal;
report.generatedUTC = char(datetime('now','TimeZone','UTC','Format','yyyy-MM-dd''T''HH:mm:ss''Z'''));
fid = fopen(fullfile(root,'build','validation_v0_2.json'),'w','n','UTF-8');
assert(fid>=0,'Cannot write aggregate validation report.');
cleanup = onCleanup(@() fclose(fid)); %#ok<NASGU>
fprintf(fid,'%s\n',jsonencode(report,'PrettyPrint',true));
save(fullfile(root,'build','validation_v0_2.mat'),'report');
fprintf('ALL_V020_CHECKS_PASSED: %d\n',report.passed);
end
