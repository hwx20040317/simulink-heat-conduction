function shc_add_thermal_element(block, position, spec)
%SHC_ADD_THERMAL_ELEMENT Construct a v0.2 thermal element from basic blocks.
% SPDX-License-Identifier: MIT
add_block('built-in/Subsystem', block, 'Position', position, 'FontSize', 10);
switch spec.kind
    case 'mass'
        add_block('simulink/Sources/In1', [block '/Qnet'], ...
            'PortDimensions', '1', 'Position', [30 65 60 85]);
        add_block('simulink/Math Operations/Gain', [block '/Inverse capacitance'], ...
            'Gain', '1/(mass*cp)', 'Position', [120 50 255 100]);
        add_block('simulink/Continuous/Integrator', [block '/Temperature state'], ...
            'InitialCondition', 'Tinit', 'Position', [320 50 370 100]);
        add_block('simulink/Sinks/Out1', [block '/T'], 'Position', [440 65 470 85]);
        add_line(block, 'Qnet/1', 'Inverse capacitance/1');
        add_line(block, 'Inverse capacitance/1', 'Temperature state/1');
        add_line(block, 'Temperature state/1', 'T/1');
        drawing = sprintf(['plot(.5+.18*cos(0:pi/32:2*pi),.5+.30*sin(0:pi/32:2*pi));\n' ...
            'text(.5,.5,''C'');\nport_label(''input'',1,''Qnet'');\nport_label(''output'',1,''T'');']);
    case 'convection'
        add_block('simulink/Sources/In1', [block '/T1'], ...
            'PortDimensions', '1', 'Position', [25 45 55 65]);
        add_block('simulink/Sources/In1', [block '/T2'], 'Port', '2', ...
            'PortDimensions', '1', 'Position', [25 130 55 150]);
        add_block('simulink/Math Operations/Sum', [block '/Temperature difference'], ...
            'Inputs', '-+', 'Position', [120 65 150 125]);
        add_block('simulink/Math Operations/Gain', [block '/Heat into node 1'], ...
            'Gain', 'h*area', 'Position', [225 75 310 115]);
        add_block('simulink/Math Operations/Gain', [block '/Opposite heat'], ...
            'Gain', '-1', 'Position', [365 135 410 165]);
        add_block('simulink/Sinks/Out1', [block '/Q1'], 'Position', [465 85 495 105]);
        add_block('simulink/Sinks/Out1', [block '/Q2'], 'Port', '2', 'Position', [465 140 495 160]);
        add_line(block, 'T1/1', 'Temperature difference/1');
        add_line(block, 'T2/1', 'Temperature difference/2');
        add_line(block, 'Temperature difference/1', 'Heat into node 1/1');
        add_line(block, 'Heat into node 1/1', 'Q1/1');
        add_line(block, 'Heat into node 1/1', 'Opposite heat/1', 'autorouting', 'on');
        add_line(block, 'Opposite heat/1', 'Q2/1');
        drawing = sprintf(['plot([.32 .32],[.22 .78]);\nplot([.68 .68],[.22 .78]);\n' ...
            'text(.5,.5,''hA'');\nport_label(''input'',1,''T1'');\nport_label(''input'',2,''T2'');\n' ...
            'port_label(''output'',1,''Q1'');\nport_label(''output'',2,''Q2'');']);
    case {'temperature','heatflow'}
        if strcmp(spec.kind, 'temperature')
            expression = 'temperature'; port = 'T';
        else
            expression = 'power'; port = 'Q';
        end
        add_block('simulink/Sources/Constant', [block '/Prescribed value'], ...
            'Value', expression, 'Position', [90 50 220 100]);
        add_block('simulink/Sinks/Out1', [block '/' port], 'Position', [290 65 320 85]);
        add_line(block, 'Prescribed value/1', [port '/1']);
        drawing = sprintf(['plot([.32 .32 .68 .68 .32],[.22 .78 .78 .22 .22]);\n' ...
            'text(.5,.5,''%s'');\nport_label(''output'',1,''%s'');'], port, port);
    otherwise
        error('SHC:UnknownElement', 'Unknown element kind: %s', spec.kind);
end
mask = Simulink.Mask.create(block);
mask.Type = ['SHC ' spec.name];
mask.Description = spec.description;
mask.Help = 'disp(get_param(gcb,''MaskDescription''));';
for k = 1:size(spec.parameters,1)
    mask.addParameter('Type', 'edit', 'Name', spec.parameters{k,1}, ...
        'Prompt', spec.parameters{k,2}, 'Value', spec.parameters{k,3}, ...
        'Evaluate', 'on', 'Tunable', 'off');
end
mask.Initialization = [checks(spec.positive, 'positive') ...
    checks(spec.nonnegative, 'nonnegative') checks(spec.finite, '') spec.extra];
mask.Display = drawing;
set_param(block, 'MaskIconUnits', 'normalized');
end

function code = checks(names, condition)
code = '';
for k = 1:numel(names)
    attributes = '''real'',''scalar'',''finite''';
    if ~isempty(condition), attributes = [attributes ',''' condition '''']; end %#ok<AGROW>
    code = [code sprintf('validateattributes(%s,{''numeric''},{%s},''SHC'',''%s'');\n', ...
        names{k}, attributes, names{k})]; %#ok<AGROW>
end
end
