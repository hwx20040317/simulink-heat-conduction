function result = run_shc_demo(showFigure)
%RUN_SHC_DEMO Simulate the example and compare with its analytical solution.
% SPDX-License-Identifier: MIT
if nargin == 0, showFigure = true; end
root = fileparts(fileparts(mfilename('fullpath')));
setup_shc(false);
modelFile = fullfile(root, 'examples', 'shc_two_masses.slx');
if ~isfile(modelFile), build_shc_demo; end
wasLoaded = bdIsLoaded('shc_two_masses');
if ~wasLoaded
    load_system(modelFile);
    cleanup = onCleanup(@() close_system('shc_two_masses', 0)); %#ok<NASGU>
end
output = sim('shc_two_masses', 'ReturnWorkspaceOutputs', 'on');
data = output.get('temperatures');
result.time = data.time;
result.temperature = data.signals.values;
delta = 20*exp(-result.time*(1/1000+1/500)/0.8);
result.analytical = [100/3+delta/3, 100/3-2*delta/3];
energy = result.temperature*[1000;500];
result.relativeEnergyError = max(abs(energy-energy(1)))/abs(energy(1));
result.maxTemperatureError = max(abs(result.temperature(:)-result.analytical(:)));
if showFigure
    figure('Color', 'w');
    plot(result.time, result.temperature, 'LineWidth', 1.5); hold on;
    plot(result.time, result.analytical, '--', 'LineWidth', 1);
    grid on; xlabel('Time (s)'); ylabel('Temperature (degC)');
    legend('T1 simulation', 'T2 simulation', 'T1 analytical', 'T2 analytical', 'Location', 'best');
    title('Two thermal capacitances connected by a conduction element');
end
end
