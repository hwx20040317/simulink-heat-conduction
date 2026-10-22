# Simulink Heat Conduction

中文 | [English](README.en.md)

A source-rebuildable library for conduction and lumped thermal networks using ordinary Simulink signals. / 使用普通 Simulink 信号搭建的导热与集总热网络元件库。

**Version 0.2.0 · MATLAB/Simulink R2023a · MIT License**

![Library preview](docs/library_preview.png)

## 导热元件 / Conduction elements

| 元件 | 用途 | 总热阻 R [K/W] |
|---|---|---|
| Planar conduction | 单材料平壁 | `distance/(lambda*area)` |
| Planar conduction 2 materials | 双材料平壁及界面接触热阻 | `distance1/(lambda1*area)+distance2/(lambda2*area)+ctr` |
| Radial conduction | 单层同轴圆筒径向导热 | `log(diamExt/diamInt)/(2*pi*lambda*le)` |
| Radial conduction 2 materials | 双层同轴圆筒及界面接触热阻 | `log(diamCt/diamInt)/(2*pi*lambda1*le)+log(diamExt/diamCt)/(2*pi*lambda2*le)+ctr` |

四个原有导热元件的名称、参数和端口保持兼容。元件内部为普通 Simulink 基础模块，可查看内部连接；提供完整 `.m` 构建源码和可直接打开的 `.slx` 文件。

## v0.2.0 新增：基础热网络元件

| 元件 | 输入 → 输出 | 含义 |
|---|---|---|
| Thermal mass | Qnet [W] → T [℃ 或 K] | `dT/dt=Qnet/(mass*cp)`，初始温度 Tinit |
| Convection | T1、T2 → Q1、Q2 [W] | `Q1=h*area*(T2-T1)`，`Q2=-Q1` |
| Temperature boundary | 无输入 → T | 恒定的规定温度，表示理想恒温环境 |
| Heat flow boundary | 无输入 → Q [W] | 恒定热功率，正值加热、负值移热 |

- 热容参数：质量 `mass` [kg]、比热 `cp` [J/(kg·K)]、初温 `Tinit`。所有流入该物体的热流先求和，再接到 Qnet。
- 对流参数：换热系数 `h` [W/(m²·K)]、面积 `area` [m²]；允许 h=0，表示该换热路径绝热。元件不包含流体流动或换热系数关联式。
- 温度边界接到导热/对流元件的一侧，提供温度信号；理想边界温度不随所交换的热量改变。对同一个规定温度节点不再另外积分其温度。
- 热功率边界提供总功率 W；若输入数据是热流密度 W/m²，需先乘作用面积。
- 时变温度或功率可直接使用兼容的标准 Simulink 信号源。本版两种封装边界为常值形式。

## 环境 / Requirements

- MATLAB + Simulink。预生成文件和验证环境为 **R2023a**；其他版本尚未验证。旧版本用户可尝试从源码重新构建，不能据此视为已兼容。
- 无需 Simscape 或其他第三方热库；不提供 MATLAB/Simulink 本身的许可证。
- 标量、有限实数参数；本版导热系数、比热和对流换热系数在一次仿真内为常量。
- **新增 Thermal mass 使用连续积分器，需要连续状态求解器，例如 ode4 或 ode45。** 原有纯离散算例仍使用自己的离散积分器；包含新热容的模型不能选 FixedStepDiscrete。

## 加载 / Quick start

下载或克隆本仓库后，将 MATLAB 当前文件夹切换到仓库根目录：

```matlab
setup_shc
```

打开 `SHCLib`，或在 Library Browser 中找到 **Heat Conduction**，拖入元件。
路径仅添加到当前会话，未调用 `savepath`。
更新版本后，若内存中仍加载着旧 SHCLib，请先将需要保留的库修改另存备份，关闭该库，再执行 `setup_shc`。

```matlab
% 新示例：恒功率加热 + 向恒温环境对流散热
setup_shc(false)
result = run_shc_heating_demo;

% 全部检查：原导热回归 + 新元件与瞬态检查
report = test_shc_all;

% 保留 v0.1.0 双热质量示例
legacy = run_shc_demo;
```

新示例 `examples/shc_heating_cooling.slx` 已配置好求解器与模型工作区参数，不需要往基础工作区填变量。重建示例使用 `build_shc_heating_demo`。

默认质量 0.5 kg、比热 1000 J/(kg·K)，热容为 500 J/K；加热功率 100 W、h=10 W/(m²·K)、面积 0.5 m²，环境及初始温度均为 20 ℃。解析平衡温度为 40 ℃，时间常数为 100 s；ode4 步长 0.1 s，计算至 500 s。

![Heating model](docs/heating_cooling_model.png)

![Heating and energy validation](docs/heating_cooling_validation.png)

运行结果包括温度、解析解、热功率、向环境散出的热流、累计热量、储热变化及能量误差。累计热量在运行后由采样数据做梯形积分，因此误差包含采样积分误差；本版尚未增加通用的能量监测库元件。

可在不修改模型文件的情况下改变示例参数：

```matlab
cooling = run_shc_heating_demo(true, struct('power',0,'Tinit',60));
adiabatic = run_shc_heating_demo(true, struct('h',0));
```

示例文件为 `examples/shc_two_masses.slx`。两个热容量分别为 1000、500 J/K，初始温度 40、20 ℃，连接热阻 0.8 K/W；最终平衡温度为 33.3333 ℃，时间常数为 266.6667 s。固定步长为 0.01 s，仿真时长为 200 s。

![Simulation versus analytical solution](docs/demo_validation.png)

原导热与双热质量示例保留 **24 项回归检查**；原示例最大解析解温差为 8.86×10⁻⁵ ℃，能量相对偏差为 9.02×10⁻¹⁵。新版完整验证见 [docs/VALIDATION_v0.2.0.md](docs/VALIDATION_v0.2.0.md)，首版记录保留于 [docs/VALIDATION.md](docs/VALIDATION.md)。

**v0.2.0 已在 R2023a 中通过全部 61 项检查（24 项回归 + 37 项新增）。** 新加热示例最大温度解析误差 1.49×10⁻¹³ ℃；采样能量积分最大残差 8.28×10⁻⁴ J，相对误差 1.66×10⁻⁸。

## 接口及符号 / Ports

```text
Inputs:  T1, T2 — temperatures [degC or K, same scale]
Outputs: Q1, Q2 — heat entering the corresponding node [W]

Q1 = (T2 - T1) / R
Q2 = -Q1
```

T1=40 ℃、T2=20 ℃时，Q1<0、Q2>0。把 Q1 加入节点1的总热流，把 Q2 加入节点2的总热流，再通过 `dT/dt=Qnet/(m*cp)` 更新节点温度。

圆筒元件的 T1 为内侧温度、T2 为外侧温度。端口是有方向的普通 Simulink 信号；与 Simscape 热守恒端口不能直接连接。

导热和对流元件不包含热容量。需要瞬态结果时，使用外部 Thermal mass 储热节点，或使用自己构建的储热方程。

## 几何与接触热阻

- `lambda`：W/(m·K)；距离、长度、直径：m；`area`：m²；`ctr`：K/W。
- 平壁距离为实际温度节点间的导热距离。双材料距离分别为节点到界面的距离；中心温度离散时通常包含半单元厚度。
- 圆筒公式描述同轴圆筒壁的一维径向导热。要求直径严格递增且内径大于零；并排圆柱接触、圆心控制体和轴向导热需要相应的其他模型。
- `ctr` 是**总接触热阻**。若原始数据为单位面积接触热阻 R'' [m²·K/W]，平壁使用 `ctr=R''/area`，圆筒界面使用 `ctr=R''/(pi*diamCt*le)`。
- 默认参数仅用于演示。实际计算需填写几何和材料参数，并检查离散尺度、步长与边界条件。

## 从源码重建 / Rebuild

保存需要保留的改动并关闭已加载的 `SHCLib` 后：

```matlab
setup_shc(false)
build_shc_library
```

`src/shc_block_specs.m` 定义四个导热元件；`src/shc_thermal_specs.m` 与 `src/shc_add_thermal_element.m` 定义和构建四个新元件；`src/build_shc_library.m` 生成 `library/SHCLib.slx`。源码均可编辑。重复构建会替换项目自己的库文件，不会修改其他模型。

## 目录

```text
library/     SHCLib.slx 与 Library Browser 注册入口
src/         参数定义及完整构建源码
examples/    恒功率加热/对流散热、双热质量示例与运行入口
tests/       数值及依赖检查
docs/        预览、验证记录和发布说明
setup_shc.m  当前会话加载入口
LICENSE      MIT 开源许可证
```

## 实现来源与许可证

本项目根据标准平壁、圆筒热阻和串联热阻关系，从普通 Simulink 模块独立构建，采用温度—热流的显式信号流热网络形式。本仓库未打包第三方商业热库、受保护的 P 文件、第三方库链接或授权检查替代文件。

本项目新增源码、模型和文档采用 [MIT License](LICENSE)。MATLAB、Simulink 及其内置组件的权利和使用条件由 MathWorks 决定，不属于本项目许可证的授予范围。

公式参考：[MathWorks — Conductive Heat Transfer](https://www.mathworks.com/help/simscape/ref/conductiveheattransfer.html)、[Convective Heat Transfer](https://www.mathworks.com/help/simscape/ref/convectiveheattransfer.html)。实现参考：[Simulink Integrator](https://www.mathworks.com/help/simulink/slref/integrator.html)、[Add Libraries to Library Browser](https://www.mathworks.com/help/simulink/ug/adding-libraries-to-the-library-browser.html)。

仓库主页：[hwx20040317/simulink-heat-conduction](https://github.com/hwx20040317/simulink-heat-conduction)。维护及发布说明见 [docs/PUBLISHING.md](docs/PUBLISHING.md)。
