function modelFile = build_shc_demo
%BUILD_SHC_DEMO Build two capacitances connected by the two-material element.
% SPDX-License-Identifier: MIT
root = fileparts(fileparts(mfilename('fullpath')));
setup_shc(false);
name = 'shc_two_masses';
assert(~bdIsLoaded(name), 'SHC:DemoAlreadyLoaded', 'Close shc_two_masses before rebuilding.');
load_system(fullfile(root, 'library', 'SHCLib.slx'));
new_system(name);
cleanup = onCleanup(@() close_system(name, 0)); %#ok<NASGU>
set_param(name, 'SolverType', 'Fixed-step', 'Solver', 'FixedStepDiscrete', ...
    'FixedStep', '0.01', 'StopTime', '200', 'ReturnWorkspaceOutputs', 'on');
add_block('SHCLib/Planar conduction 2 materials', [name '/Conduction'], ...
    'Position', [295 130 470 245]);
add_block('simulink/Discrete/Discrete-Time Integrator', [name '/T1'], ...
    'InitialCondition', '40', 'SampleTime', '0.01', 'Position', [175 105 225 145]);
add_block('simulink/Discrete/Discrete-Time Integrator', [name '/T2'], ...
    'InitialCondition', '20', 'SampleTime', '0.01', 'Position', [175 275 225 315]);
add_block('simulink/Math Operations/Gain', [name '/Inverse C1'], ...
    'Gain', '1/1000', 'Position', [65 105 115 145]);
add_block('simulink/Math Operations/Gain', [name '/Inverse C2'], ...
    'Gain', '1/500', 'Position', [65 275 115 315]);
add_block('simulink/Signal Routing/Mux', [name '/Temperatures'], ...
    'Inputs', '2', 'Position', [550 145 555 215]);
add_block('simulink/Sinks/To Workspace', [name '/Record'], ...
    'VariableName', 'temperatures', 'SaveFormat', 'Structure With Time', ...
    'Position', [610 160 735 200]);
add_block('simulink/Sinks/Scope', [name '/Temperature scope'], 'Position', [620 270 660 310]);
add_line(name, 'T1/1', 'Conduction/1', 'autorouting', 'on');
add_line(name, 'T2/1', 'Conduction/2', 'autorouting', 'on');
add_line(name, 'Conduction/1', 'Inverse C1/1', 'autorouting', 'on');
add_line(name, 'Conduction/2', 'Inverse C2/1', 'autorouting', 'on');
add_line(name, 'Inverse C1/1', 'T1/1');
add_line(name, 'Inverse C2/1', 'T2/1');
add_line(name, 'T1/1', 'Temperatures/1', 'autorouting', 'on');
add_line(name, 'T2/1', 'Temperatures/2', 'autorouting', 'on');
add_line(name, 'Temperatures/1', 'Record/1');
add_line(name, 'Temperatures/1', 'Temperature scope/1', 'autorouting', 'on');
note = Simulink.Annotation(name, sprintf(['Two thermal capacitances | C1=1000 J/K, C2=500 J/K\n' ...
    'T1(0)=40 degC, T2(0)=20 degC, R=0.8 K/W\n' ...
    'Expected equilibrium: 33.3333 degC | Time constant: 266.6667 s']));
note.Position = [65 15 725 70];
set_param(name, 'Location', [100 100 950 530]);
modelFile = fullfile(root, 'examples', [name '.slx']);
save_system(name, modelFile);
fprintf('BUILT %s\n', modelFile);
end
