function figureHandle = plot_shc_heating_result(result, visible)
%PLOT_SHC_HEATING_RESULT Plot temperature and the sampled energy balance.
% SPDX-License-Identifier: MIT
if nargin < 2, visible = 'on'; end
figureHandle = figure('Color','w','Visible',visible,'Position',[100 80 1000 740]);
tiledlayout(2,1,'TileSpacing','compact');
nexttile;
plot(result.time,result.temperature,'LineWidth',1.7); hold on;
plot(result.time,result.analytical,'--','LineWidth',1.2);
yline(result.config.Tambient,':','Ambient');
grid on; xlabel('Time (s)'); ylabel('Temperature (degC)');
legend('Simulation','Analytical','Location','best');
title('Constant heat power with convection to a prescribed ambient');
nexttile;
plot(result.time,[result.energyIn result.energyOut result.storedEnergyChange], 'LineWidth',1.4);
grid on; xlabel('Time (s)'); ylabel('Energy (J)');
legend('Signed heater input','Signed heat to ambient','Stored energy change','Location','best');
title(sprintf('Sampled energy balance: max residual %.3g J',max(abs(result.energyResidual))));
end
