function result = run_shc_heating_demo(showFigure, parameters)
%RUN_SHC_HEATING_DEMO Compare heating/cooling with the analytical solution.
%   parameters is an optional struct overriding mass, cp, Tinit, Tambient,
%   power, h, area, stopTime or step. Overrides do not modify the saved model.
% SPDX-License-Identifier: MIT
if nargin < 1, showFigure = true; end
if nargin < 2, parameters = struct; end
validateattributes(showFigure, {'logical'}, {'scalar'});
assert(isstruct(parameters) && isscalar(parameters), 'SHC:InvalidConfiguration', ...
    'parameters must be a scalar struct.');
config = struct('mass',0.5,'cp',1000,'Tinit',20,'Tambient',20, ...
    'power',100,'h',10,'area',0.5,'stopTime',500,'step',0.1);
fields = fieldnames(parameters);
for k = 1:numel(fields)
    assert(isfield(config, fields{k}), 'SHC:UnknownParameter', 'Unknown parameter: %s', fields{k});
    config.(fields{k}) = parameters.(fields{k});
end
positive = {'mass','cp','area','stopTime','step'};
for k = 1:numel(positive)
    validateattributes(config.(positive{k}), {'numeric'}, ...
        {'real','scalar','finite','positive'}, 'run_shc_heating_demo', positive{k});
end
validateattributes(config.h, {'numeric'}, {'real','scalar','finite','nonnegative'});
for field = {'Tinit','Tambient','power'}
    validateattributes(config.(field{1}), {'numeric'}, {'real','scalar','finite'}, ...
        'run_shc_heating_demo', field{1});
end
root = fileparts(fileparts(mfilename('fullpath')));
setup_shc(false);
name = 'shc_heating_cooling';
modelFile = fullfile(root, 'examples', [name '.slx']);
if ~isfile(modelFile), build_shc_heating_demo; end
wasLoaded = bdIsLoaded(name);
if ~wasLoaded
    load_system(modelFile);
    cleanup = onCleanup(@() close_system(name, 0)); %#ok<NASGU>
end
input = Simulink.SimulationInput(name);
mapping = {'mass','mass_demo';'cp','cp_demo';'Tinit','T0_demo'; ...
    'Tambient','Tenv_demo';'power','P_demo';'h','h_demo';'area','A_demo'};
for k = 1:size(mapping,1)
    input = input.setVariable(mapping{k,2}, config.(mapping{k,1}), 'Workspace', name);
end
input = input.setModelParameter('StopTime', num2str(config.stopTime,17), ...
    'FixedStep', num2str(config.step,17));
output = sim(input);
data = output.get('thermal');
result.config = config;
result.time = data.time;
result.temperature = data.signals.values(:,1);
result.power = data.signals.values(:,2);
result.heatOut = data.signals.values(:,3);
result.netHeat = data.signals.values(:,4);
capacitance = config.mass*config.cp;
conductance = config.h*config.area;
if conductance == 0
    result.equilibrium = NaN;
    result.timeConstant = Inf;
    result.analytical = config.Tinit+config.power*result.time/capacitance;
else
    result.equilibrium = config.Tambient+config.power/conductance;
    result.timeConstant = capacitance/conductance;
    result.analytical = result.equilibrium ...
        +(config.Tinit-result.equilibrium)*exp(-result.time/result.timeConstant);
end
result.energyIn = cumtrapz(result.time, result.power);
result.energyOut = cumtrapz(result.time, result.heatOut);
result.storedEnergyChange = capacitance*(result.temperature-config.Tinit);
result.energyResidual = result.energyIn-result.energyOut-result.storedEnergyChange;
energyScale = max([1;abs(result.energyIn);abs(result.energyOut);abs(result.storedEnergyChange)]);
result.relativeEnergyError = max(abs(result.energyResidual))/energyScale;
result.maxTemperatureError = max(abs(result.temperature-result.analytical));
if showFigure, plot_shc_heating_result(result); end
end
