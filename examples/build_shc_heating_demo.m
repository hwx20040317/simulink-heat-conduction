function modelFile = build_shc_heating_demo
%BUILD_SHC_HEATING_DEMO Constant heating with convection to a reservoir.
% SPDX-License-Identifier: MIT
root = fileparts(fileparts(mfilename('fullpath')));
setup_shc(false);
name = 'shc_heating_cooling';
assert(~bdIsLoaded(name), 'SHC:DemoAlreadyLoaded', 'Close shc_heating_cooling before rebuilding.');
load_system(fullfile(root, 'library', 'SHCLib.slx'));
new_system(name);
cleanup = onCleanup(@() close_system(name, 0)); %#ok<NASGU>
set_param(name, 'SolverType', 'Fixed-step', 'Solver', 'ode4', ...
    'FixedStep', '0.1', 'StopTime', '500', 'ReturnWorkspaceOutputs', 'on');
workspace = get_param(name, 'ModelWorkspace');
defaults = {'mass_demo',0.5;'cp_demo',1000;'T0_demo',20;'Tenv_demo',20; ...
    'P_demo',100;'h_demo',10;'A_demo',0.5};
for k = 1:size(defaults,1), assignin(workspace, defaults{k,1}, defaults{k,2}); end
add_block('SHCLib/Heat flow boundary', [name '/Heater'], 'power', 'P_demo', ...
    'Position', [50 110 200 175]);
add_block('simulink/Math Operations/Sum', [name '/Net heat into body'], ...
    'Inputs', '++', 'Position', [265 115 295 165]);
add_block('SHCLib/Thermal mass', [name '/Body'], ...
    'mass', 'mass_demo', 'cp', 'cp_demo', 'Tinit', 'T0_demo', ...
    'Position', [370 105 550 185]);
add_block('SHCLib/Convection', [name '/Convection to ambient'], ...
    'h', 'h_demo', 'area', 'A_demo', 'Position', [650 260 830 345]);
add_block('SHCLib/Temperature boundary', [name '/Ambient'], ...
    'temperature', 'Tenv_demo', 'Position', [370 310 550 375]);
add_block('simulink/Signal Routing/Mux', [name '/T P Qout Qnet'], ...
    'Inputs', '4', 'Position', [930 100 935 270]);
add_block('simulink/Sinks/To Workspace', [name '/Record'], ...
    'VariableName', 'thermal', 'SaveFormat', 'Structure With Time', ...
    'Position', [990 160 1110 200]);
add_block('simulink/Sinks/Scope', [name '/Scope'], 'Position', [990 315 1030 355]);
add_line(name, 'Heater/1', 'Net heat into body/1', 'autorouting', 'on');
add_line(name, 'Convection to ambient/1', 'Net heat into body/2', 'autorouting', 'on');
add_line(name, 'Net heat into body/1', 'Body/1', 'autorouting', 'on');
add_line(name, 'Body/1', 'Convection to ambient/1', 'autorouting', 'on');
add_line(name, 'Ambient/1', 'Convection to ambient/2', 'autorouting', 'on');
add_line(name, 'Body/1', 'T P Qout Qnet/1', 'autorouting', 'on');
add_line(name, 'Heater/1', 'T P Qout Qnet/2', 'autorouting', 'on');
add_line(name, 'Convection to ambient/2', 'T P Qout Qnet/3', 'autorouting', 'on');
add_line(name, 'Net heat into body/1', 'T P Qout Qnet/4', 'autorouting', 'on');
add_line(name, 'T P Qout Qnet/1', 'Record/1', 'autorouting', 'on');
add_line(name, 'T P Qout Qnet/1', 'Scope/1', 'autorouting', 'on');
note = Simulink.Annotation(name, sprintf(['Heating + convection | C=m*cp=500 J/K\n' ...
    'P=100 W, h*A=5 W/K, T0=Tamb=20 degC\n' ...
    'T_eq=40 degC, time constant=100 s | Qnet=P+Q1, Qout=Q2']));
note.Position = [50 10 1080 75];
set_param(name, 'Location', [70 80 1300 600]);
modelFile = fullfile(root, 'examples', [name '.slx']);
save_system(name, modelFile);
fprintf('BUILT %s\n', modelFile);
end
