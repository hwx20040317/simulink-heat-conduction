function report = test_shc_thermal
%TEST_SHC_THERMAL Numerical references for the four v0.2 element families.
% SPDX-License-Identifier: MIT
root = fileparts(fileparts(mfilename('fullpath')));
setup_shc(false);
load_system(fullfile(root,'library','SHCLib.slx'));
model = 'shc_thermal_reference';
assert(~bdIsLoaded(model),'SHC:TestModelAlreadyLoaded','Close shc_thermal_reference first.');
new_system(model);
cleanup = onCleanup(@() close_system(model,0)); %#ok<NASGU>
set_param(model,'SolverType','Fixed-step','Solver','ode4','FixedStep','0.1', ...
    'StopTime','10','ReturnWorkspaceOutputs','on');
add_block('SHCLib/Temperature boundary',[model '/Temperature'],'temperature','40');
add_block('simulink/Sources/Constant',[model '/T2'],'Value','20');
add_block('SHCLib/Convection',[model '/Convection']);
add_block('SHCLib/Heat flow boundary',[model '/Power']);
add_block('SHCLib/Thermal mass',[model '/Mass']);
add_block('simulink/Signal Routing/Mux',[model '/Signals'],'Inputs','5');
add_block('simulink/Sinks/To Workspace',[model '/Record'], ...
    'VariableName','thermalReference','SaveFormat','Structure With Time');
add_line(model,'Temperature/1','Convection/1');
add_line(model,'T2/1','Convection/2');
add_line(model,'Power/1','Mass/1');
add_line(model,'Convection/1','Signals/1');
add_line(model,'Convection/2','Signals/2');
add_line(model,'Mass/1','Signals/3');
add_line(model,'Power/1','Signals/4');
add_line(model,'Temperature/1','Signals/5');
add_line(model,'Signals/1','Record/1');
passed = 0;
cases = [40 20 100 20;20 40 -50 20;20 20 0 -10];
for k = 1:size(cases,1)
    set_param([model '/Temperature'],'temperature',num2str(cases(k,1)));
    set_param([model '/T2'],'Value',num2str(cases(k,2)));
    set_param([model '/Power'],'power',num2str(cases(k,3)));
    set_param([model '/Mass'],'Tinit',num2str(cases(k,4)));
    output = sim(model,'ReturnWorkspaceOutputs','on');
    data = output.get('thermalReference'); values = data.signals.values;
    expected = 5*(cases(k,2)-cases(k,1))*[1 -1];
    assert(max(abs(values(:,1:2)-expected),[],'all')<1e-10,'Convection heat sign/magnitude is incorrect.');
    assert(max(abs(sum(values(:,1:2),2)))<1e-12,'Convection does not conserve heat.');
    passed = pass(passed,sprintf('convection direction case %d',k));
    reference = cases(k,4)+cases(k,3)*data.time/1000;
    assert(max(abs(values(:,3)-reference))<1e-10,'Constant-power thermal mass is incorrect.');
    passed = pass(passed,sprintf('thermal mass ramp case %d',k));
    assert(max(abs(values(:,4)-cases(k,3)))<1e-12,'Heat power boundary is incorrect.');
    passed = pass(passed,sprintf('signed heat boundary case %d',k));
    assert(max(abs(values(:,5)-cases(k,1)))<1e-12,'Temperature boundary is incorrect.');
    passed = pass(passed,sprintf('temperature boundary case %d',k));
end
set_param([model '/Temperature'],'temperature','40');
set_param([model '/Convection'],'h','0');
output = sim(model,'ReturnWorkspaceOutputs','on'); data = output.get('thermalReference');
assert(max(abs(data.signals.values(:,1:2)),[],'all')<1e-12,'h=0 must give zero heat flow.');
passed = pass(passed,'zero heat transfer coefficient');
set_param([model '/Convection'],'h','10');
set_param([model '/Power'],'power','100');
set_param([model '/Mass'],'mass','2','cp','1000','Tinit','20');
output = sim(model,'ReturnWorkspaceOutputs','on'); data = output.get('thermalReference');
assert(abs(data.signals.values(end,3)-20.5)<1e-10,'Incorrect mass/capacitance scaling.');
passed = pass(passed,'capacitance scaling');

invalid = {'Mass','mass','0','mass';'Mass','cp','-1','cp'; ...
    'Mass','Tinit','NaN','Tinit';'Convection','h','-1','h'; ...
    'Convection','area','0','area';'Temperature','temperature','Inf','temperature'; ...
    'Power','power','NaN','power';'Power','power','1+1i','power'; ...
    'Mass','mass','1e308','thermal capacitance'; ...
    'Convection','area','1e308','convective conductance'};
for k = 1:size(invalid,1)
    block = [model '/' invalid{k,1}]; parameter = invalid{k,2};
    oldValue = get_param(block,parameter); rejected = false;
    try
        set_param(block,parameter,invalid{k,3});
        sim(model,'ReturnWorkspaceOutputs','on');
    catch exception
        rejected = contains(getReport(exception,'extended','hyperlinks','off'),invalid{k,4});
    end
    set_param(block,parameter,oldValue);
    assert(rejected,'Invalid thermal parameter was not rejected for the expected reason.');
    passed = pass(passed,['invalid ' invalid{k,1} '.' parameter]);
end

transientCases = {struct,struct('power',0,'Tinit',60),struct('power',-50), ...
    struct('power',0,'Tambient',50),struct('h',0)};
caseNames = {'heating','free cooling','negative heat power','warm reservoir','adiabatic heating'};
for k = 1:numel(transientCases)
    result = run_shc_heating_demo(false,transientCases{k});
    assert(all(isfinite(result.temperature)) && result.maxTemperatureError<1e-7, ...
        'Transient temperature differs from the analytical solution.');
    assert(abs(result.temperature(1)-result.config.Tinit)<1e-12,'Incorrect initial temperature.');
    passed = pass(passed,[caseNames{k} ' analytical temperature']);
    assert(result.relativeEnergyError<1e-6,'Sampled energy balance failed.');
    assert(max(abs(result.netHeat-(result.power-result.heatOut)))<1e-10,'Incorrect heat bookkeeping.');
    passed = pass(passed,[caseNames{k} ' energy balance']);
    if k == 1, baseline = result; end
end
coarse = run_shc_heating_demo(false,struct('step',10));
fine = run_shc_heating_demo(false,struct('step',5));
assert(coarse.maxTemperatureError>1e-7 && fine.maxTemperatureError<coarse.maxTemperatureError/8, ...
    'Time-step refinement did not reduce the RK4 temperature error.');
passed = pass(passed,'time-step refinement');
[closedTemperatureError,closedEnergyError] = checkClosedMasses;
assert(closedTemperatureError<1e-7,'New masses and existing conduction differ from analytical solution.');
passed = pass(passed,'existing conduction + new thermal masses');
assert(closedEnergyError<1e-10,'Closed two-mass energy conservation failed.');
passed = pass(passed,'closed two-mass energy conservation');

report.projectVersion = shc_version;
report.passed = passed;
report.heatingTemperatureError = baseline.maxTemperatureError;
report.heatingEnergyRelativeError = baseline.relativeEnergyError;
report.heatingEnergyResidualJ = max(abs(baseline.energyResidual));
report.coarseStepError = coarse.maxTemperatureError;
report.fineStepError = fine.maxTemperatureError;
report.closedTemperatureError = closedTemperatureError;
report.closedEnergyRelativeError = closedEnergyError;
save(fullfile(root,'build','thermal_validation.mat'),'report','baseline');
fprintf('THERMAL_CHECKS_PASSED: %d\n',passed);
end

function number = pass(number,label)
number = number+1;
fprintf('PASS THERMAL %02d %s\n',number,label);
end

function [temperatureError,energyError] = checkClosedMasses
model = 'shc_closed_thermal_masses';
assert(~bdIsLoaded(model),'SHC:TestModelAlreadyLoaded','Close shc_closed_thermal_masses first.');
new_system(model);
cleanup = onCleanup(@() close_system(model,0)); %#ok<NASGU>
set_param(model,'SolverType','Fixed-step','Solver','ode4','FixedStep','0.1', ...
    'StopTime','200','ReturnWorkspaceOutputs','on');
add_block('SHCLib/Planar conduction 2 materials',[model '/Conduction']);
add_block('SHCLib/Thermal mass',[model '/Mass1'],'mass','1','cp','1000','Tinit','40');
add_block('SHCLib/Thermal mass',[model '/Mass2'],'mass','0.5','cp','1000','Tinit','20');
add_block('simulink/Signal Routing/Mux',[model '/Temperatures'],'Inputs','2');
add_block('simulink/Sinks/To Workspace',[model '/Record'], ...
    'VariableName','closedTemperatures','SaveFormat','Structure With Time');
add_line(model,'Mass1/1','Conduction/1'); add_line(model,'Mass2/1','Conduction/2');
add_line(model,'Conduction/1','Mass1/1'); add_line(model,'Conduction/2','Mass2/1');
add_line(model,'Mass1/1','Temperatures/1'); add_line(model,'Mass2/1','Temperatures/2');
add_line(model,'Temperatures/1','Record/1');
output = sim(model,'ReturnWorkspaceOutputs','on'); data = output.get('closedTemperatures');
delta = 20*exp(-data.time*(1/1000+1/500)/0.8);
analytical = [100/3+delta/3,100/3-2*delta/3];
temperature = data.signals.values;
temperatureError = max(abs(temperature-analytical),[],'all');
energy = temperature*[1000;500];
energyError = max(abs(energy-energy(1)))/abs(energy(1));
end
