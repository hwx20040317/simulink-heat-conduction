# v0.2.0 验证 / Verification

2026-10-22，Windows，MATLAB 9.14.0.2206163 / Simulink R2023a。
恢复 MATLAB 默认路径后，只添加本项目路径，从源码构建库和新示例，再执行 `test_shc_all`。

**61 / 61 项通过：24 项原导热回归检查 + 37 项新增检查。**

| 检查 / Check | 项数 / Count |
|---|---:|
| 原导热与离散双热质量回归 / Original conduction and discrete two-mass regressions | 24 |
| 对流方向、零温差及 h=0 / Convection signs, equal temperatures and h=0 | 4 |
| 热容温升、降温、零功率及容量缩放 / Thermal mass ramps and capacitance scaling | 4 |
| 恒温与正/负/零热功率边界 / Prescribed temperature and signed heat-power boundaries | 6 |
| 非法参数及容量/热导乘积溢出 / Invalid values and product overflow | 10 |
| 五种瞬态工况的解析解及能量平衡 / Five transient cases, temperature and energy | 10 |
| 时间步长收敛 / Time-step refinement | 1 |
| 新热容与原导热元件耦合的解析解及封闭能量守恒 / New masses with existing conduction | 2 |

## 新示例：加热及对流 / Heating and convection

```text
C = m*cp = 500 J/K
H = h*A = 5 W/K
P = 100 W
T(0) = Tamb = 20 degC
C*dT/dt = P-H*(T-Tamb)
Teq = Tamb+P/H = 40 degC
tau = C/H = 100 s
T(t) = Teq+(T(0)-Teq)*exp(-t/tau)
```

ode4，步长 0.1 s，计算至 500 s：

- 最大温度解析误差 / Max analytical temperature error: **1.4921397450962104e-13 degC**。
- 最大采样能量残差 / Max sampled energy residual: **0.0008277198467112612 J**。
- 相对能量误差 / Relative energy error: **1.6554396934224813e-8**。

温度误差接近该简单线性算例的浮点计算精度，不代表所有实际模型都有同等精度。

## 能量记账 / Energy bookkeeping

```text
Eheater  = integral(P dt)                         [J, signed]
Eambient = integral(Q2_convection dt)             [J, positive body -> ambient]
DeltaU   = C*(T-T0)                              [J]
residual = Eheater-Eambient-DeltaU
```

累计热量由输出采样点采用梯形积分得到，因此残差包含采样积分误差。
不同工况允许加热功率或向环境热流为负；使用同一符号约定核对能量。
这些是示例运行后的诊断量，不是额外的通用监测库元件。

Cumulative heat uses trapezoidal integration of output samples, so the residual includes sampling/integration error. Signed powers are retained for cooling and a warmer reservoir.

## 边界与收敛 / Boundary cases and refinement

解析解覆盖：恒功率加热、无加热自由冷却、负功率移热、环境比物体温度高、h=0 绝热加热。
h=0 时使用线性解析解 `T=T0+P*t/C`，无除零计算。

ode4 步长从 10 s 缩小至 5 s，最大温度误差从 **6.664821121660225e-6** 降为 **3.995219444163922e-7 degC**。

新热容连接原双材料平壁导热元件的封闭双热质量测试中：

- 温度解析误差 / Temperature error: **5.6843418860808015e-14 degC**。
- 总能量相对变化 / Relative energy variation: **1.3096723705530167e-15**。

## 复现与范围 / Reproduce and scope

```matlab
setup_shc(false)
report = test_shc_all;
```

完整报告在运行后写入 `build/validation_v0_2.json`；公开快照见同目录的 `validation-v0.2.0.json`。
库回调、模块引用检查包含在保留的回归套件中。只使用基础 Simulink 模块，无 Simscape 或第三方热库依赖。
其他 MATLAB 版本尚未验证。实际应用仍需验证材料参数、空间离散、边界条件及时间步长。
