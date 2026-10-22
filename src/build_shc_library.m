function libraryFile = build_shc_library
%BUILD_SHC_LIBRARY Rebuild the standalone library from plain MATLAB sources.
% No other user library is loaded or copied. Safe to repeat when SHCLib is closed.
% SPDX-License-Identifier: MIT
root = fileparts(fileparts(mfilename('fullpath')));
libraryFile = fullfile(root, 'library', 'SHCLib.slx');
assert(~bdIsLoaded('SHCLib'), 'SHC:LibraryAlreadyLoaded', ...
    'Close SHCLib after saving any desired edits before rebuilding.');
load_system('simulink');
new_system('SHCLib', 'Library');
cleanup = onCleanup(@() close_system('SHCLib', 0)); %#ok<NASGU>
set_param('SHCLib', 'Lock', 'off', 'EnableLBRepository', 'on');
specs = shc_block_specs;
positions = [70 100 250 205; 350 100 530 205; 70 310 250 415; 350 310 530 415];
for k = 1:numel(specs)
    makeElement(['SHCLib/' specs(k).name], positions(k,:), specs(k));
end
thermalSpecs = shc_thermal_specs;
thermalPositions = positions + [580 0 580 0];
for k = 1:numel(thermalSpecs)
    shc_add_thermal_element(['SHCLib/' thermalSpecs(k).name], thermalPositions(k,:), thermalSpecs(k));
end
note = Simulink.Annotation('SHCLib', sprintf( ...
    ['Heat Conduction %s | Signal-flow thermal modeling\n' ...
    'Conduction, thermal mass, convection and prescribed boundaries\n' ...
    'Heat entering each temperature node is positive.'], shc_version));
note.Position = [65 15 1100 70];
set_param('SHCLib', 'Location', [70 100 1310 650], 'Lock', 'on');
save_system('SHCLib', libraryFile);
fprintf('BUILT %s\n', libraryFile);
end

function makeElement(block, position, spec)
add_block('built-in/Subsystem', block, 'Position', position, 'FontSize', 10);
add_block('simulink/Sources/In1', [block '/T1'], 'Position', [25 45 55 65]);
add_block('simulink/Sources/In1', [block '/T2'], 'Port', '2', 'Position', [25 130 55 150]);
add_block('simulink/Math Operations/Sum', [block '/Temperature difference'], ...
    'Inputs', '-+', 'Position', [115 65 145 125]);
add_block('simulink/Sources/Constant', [block '/Resistance'], ...
    'Value', spec.resistance, 'Position', [100 200 310 235]);
add_block('simulink/Math Operations/Product', [block '/Heat flow'], ...
    'Inputs', '*/', 'Position', [365 75 405 115]);
add_block('simulink/Math Operations/Gain', [block '/Opposite heat flow'], ...
    'Gain', '-1', 'Position', [450 135 495 165]);
add_block('simulink/Sinks/Out1', [block '/Q1'], 'Position', [550 85 580 105]);
add_block('simulink/Sinks/Out1', [block '/Q2'], 'Port', '2', 'Position', [550 140 580 160]);
add_line(block, 'T1/1', 'Temperature difference/1');
add_line(block, 'T2/1', 'Temperature difference/2');
add_line(block, 'Temperature difference/1', 'Heat flow/1');
add_line(block, 'Resistance/1', 'Heat flow/2', 'autorouting', 'on');
add_line(block, 'Heat flow/1', 'Q1/1');
add_line(block, 'Heat flow/1', 'Opposite heat flow/1', 'autorouting', 'on');
add_line(block, 'Opposite heat flow/1', 'Q2/1');
mask = Simulink.Mask.create(block);
mask.Type = ['SHC ' spec.name];
mask.Description = spec.description;
mask.Help = 'disp(get_param(gcb,''MaskDescription''));';
for p = 1:size(spec.parameters, 1)
    mask.addParameter('Type', 'edit', 'Name', spec.parameters{p,1}, ...
        'Prompt', spec.parameters{p,2}, 'Value', spec.parameters{p,3}, ...
        'Evaluate', 'on', 'Tunable', 'off');
end
init = [validation(spec.positive, 'positive') validation(spec.nonnegative, 'nonnegative')];
mask.Initialization = [init spec.geometry newline ...
    sprintf(['validateattributes(%s,{''numeric''},' ...
    '{''real'',''scalar'',''finite'',''positive''},''SHC'',''R_total'');'], spec.resistance)];
mask.Display = [drawIcon(spec.icon) sprintf([ ...
    'port_label(''input'',1,''T1'');\nport_label(''input'',2,''T2'');\n' ...
    'port_label(''output'',1,''Q1'');\nport_label(''output'',2,''Q2'');'])];
set_param(block, 'MaskIconUnits', 'normalized');
end

function code = validation(names, condition)
code = '';
for k = 1:numel(names)
    code = [code sprintf(['validateattributes(%s,{''numeric''},' ...
        '{''real'',''scalar'',''finite'',''%s''},''SHC'',''%s'');\n'], ...
        names{k}, condition, names{k})]; %#ok<AGROW>
end
end

function code = drawIcon(kind)
if startsWith(kind, 'plane')
    code = sprintf('plot([.30 .30 .70 .70 .30],[.20 .80 .80 .20 .20]);\n');
    if strcmp(kind, 'plane2')
        code = [code sprintf('plot([.50 .50],[.20 .80]);\ntext(.39,.50,''1'');text(.61,.50,''2'');\n')];
    else
        code = [code sprintf('text(.50,.50,''k'');\n')];
    end
else
    code = sprintf([ ...
        'plot(.5+.26*cos(0:pi/32:2*pi),.5+.34*sin(0:pi/32:2*pi));\n' ...
        'plot(.5+.10*cos(0:pi/32:2*pi),.5+.13*sin(0:pi/32:2*pi));\n']);
    if strcmp(kind, 'radial2')
        code = [code sprintf('plot(.5+.18*cos(0:pi/32:2*pi),.5+.235*sin(0:pi/32:2*pi));\n')];
    end
end
end
