# Simulink Heat Conduction

中文 | [English](README.en.md)

A small, source-rebuildable library for planar and cylindrical radial heat conduction using ordinary Simulink signals. / 使用普通 Simulink 信号搭建的一维平壁与圆筒径向导热元件库。

**Version 0.1.0 · MATLAB/Simulink R2023a · MIT License**

![Library preview](docs/library_preview.png)

## 四个元件 / Elements

| 元件 | 用途 | 总热阻 R [K/W] |
|---|---|---|
| Planar conduction | 单材料平壁 | `distance/(lambda*area)` |
| Planar conduction 2 materials | 双材料平壁及界面接触热阻 | `distance1/(lambda1*area)+distance2/(lambda2*area)+ctr` |
| Radial conduction | 单层同轴圆筒径向导热 | `log(diamExt/diamInt)/(2*pi*lambda*le)` |
| Radial conduction 2 materials | 双层同轴圆筒及界面接触热阻 | `log(diamCt/diamInt)/(2*pi*lambda1*le)+log(diamExt/diamCt)/(2*pi*lambda2*le)+ctr` |

导热元件内部为普通的加减、乘除、常数及增益模块，可查看内部连接。提供完整 `.m` 构建源码和可直接打开的 `.slx` 文件。

## 环境 / Requirements

- MATLAB + Simulink。预生成文件和验证环境为 **R2023a**；其他版本尚未验证。旧版本用户可尝试从源码重新构建，不能据此视为已兼容。
- 无需 Simscape 或其他第三方热库；不提供 MATLAB/Simulink 本身的许可证。
- 标量、有限实数参数；当前版本导热系数在一次仿真内为常量。

## 加载 / Quick start

下载或克隆本仓库后，将 MATLAB 当前文件夹切换到仓库根目录：

```matlab
setup_shc
```

打开 `SHCLib`，或在 Library Browser 中找到 **Heat Conduction**，拖入元件。
路径仅添加到当前会话，未调用 `savepath`。

```matlab
% 构建并运行双热质量示例，与解析解比较
setup_shc(false)
build_shc_demo
result = run_shc_demo;

% 运行参考算例、参数检查、能量守恒验证
report = test_shc;
```

示例文件为 `examples/shc_two_masses.slx`。两个热容量分别为 1000、500 J/K，初始温度 40、20 ℃，连接热阻 0.8 K/W；最终平衡温度为 33.3333 ℃，时间常数为 266.6667 s。固定步长为 0.01 s，仿真时长为 200 s。

![Simulation versus analytical solution](docs/demo_validation.png)

R2023a 下已通过 **24 项检查**；此示例最大解析解温差为 8.86×10⁻⁵ ℃，能量相对偏差为 9.02×10⁻¹⁵。记录见 [docs/VALIDATION.md](docs/VALIDATION.md)。

## 接口及符号 / Ports

```text
Inputs:  T1, T2 — temperatures [degC or K, same scale]
Outputs: Q1, Q2 — heat entering the corresponding node [W]

Q1 = (T2 - T1) / R
Q2 = -Q1
```

T1=40 ℃、T2=20 ℃时，Q1<0、Q2>0。把 Q1 加入节点1的总热流，把 Q2 加入节点2的总热流，再通过 `dT/dt=Qnet/(m*cp)` 更新节点温度。

圆筒元件的 T1 为内侧温度、T2 为外侧温度。端口是有方向的普通 Simulink 信号；与 Simscape 热守恒端口不能直接连接。

导热元件只表示热阻，不包含热容量。需要瞬态结果时，在外部配置储热节点；示例展示了用普通积分器实现储热的方法。

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

`src/shc_block_specs.m` 定义参数、公式与检查规则，`src/build_shc_library.m` 从普通 Simulink 模块生成 `library/SHCLib.slx`。两者均可编辑。重复构建会替换项目自己的库文件，不会修改其他模型。

## 目录

```text
library/     SHCLib.slx 与 Library Browser 注册入口
src/         参数定义及完整构建源码
examples/    双热质量示例与运行入口
tests/       数值及依赖检查
docs/        预览、验证记录和发布说明
setup_shc.m  当前会话加载入口
LICENSE      MIT 开源许可证
```

## 实现来源与许可证

本项目根据标准平壁、圆筒热阻和串联热阻关系，从普通 Simulink 模块独立构建，采用温度—热流的显式信号流热网络形式。本仓库未打包第三方商业热库、受保护的 P 文件、第三方库链接或授权检查替代文件。

本项目新增源码、模型和文档采用 [MIT License](LICENSE)。MATLAB、Simulink 及其内置组件的权利和使用条件由 MathWorks 决定，不属于本项目许可证的授予范围。

公式参考：[MathWorks — Conductive Heat Transfer](https://www.mathworks.com/help/simscape/ref/conductiveheattransfer.html)。Library Browser 注册方法参考：[MathWorks — Add Libraries to Library Browser](https://www.mathworks.com/help/simulink/ug/adding-libraries-to-the-library-browser.html)。

仓库主页：[hwx20040317/simulink-heat-conduction](https://github.com/hwx20040317/simulink-heat-conduction)。维护及发布说明见 [docs/PUBLISHING.md](docs/PUBLISHING.md)。
