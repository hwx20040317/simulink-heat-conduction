# Simulink Heat Conduction

[中文](README.md) | English

A small, source-rebuildable library for one-dimensional planar and cylindrical radial heat conduction using ordinary Simulink signals.

**Version 0.1.0 · MATLAB/Simulink R2023a · MIT License**

![Library preview](docs/library_preview.png)

## Elements

| Element | Application | Total resistance R [K/W] |
|---|---|---|
| Planar conduction | One planar material | `distance/(lambda*area)` |
| Planar conduction 2 materials | Two planar materials with optional contact resistance | `distance1/(lambda1*area)+distance2/(lambda2*area)+ctr` |
| Radial conduction | One coaxial cylindrical shell | `log(diamExt/diamInt)/(2*pi*lambda*le)` |
| Radial conduction 2 materials | Two coaxial shells with optional contact resistance | `log(diamCt/diamInt)/(2*pi*lambda1*le)+log(diamExt/diamCt)/(2*pi*lambda2*le)+ctr` |

Each masked subsystem contains ordinary Sum, Constant, Product and Gain blocks. Both ready-to-open `.slx` files and editable `.m` build sources are included.

## Requirements

- MATLAB and Simulink. Prebuilt models and verification use **R2023a**. Other releases have not been tested. Rebuilding from source may be an option for older releases, but compatibility is not guaranteed.
- No Simscape or third-party thermal library is required. A MATLAB/Simulink license is still required.
- Parameters are finite real scalars. Conductivities are constant within a simulation in this release.

## Quick start

Download or clone this repository and set the MATLAB current folder to its root:

```matlab
setup_shc
```

Open `SHCLib`, or find **Heat Conduction** in the Library Browser and drag elements into your model. Setup modifies only the current MATLAB session path; it does not call `savepath`.

```matlab
% Build and run the two-capacitance example
setup_shc(false)
build_shc_demo
result = run_shc_demo;

% Run numerical references, parameter checks and conservation checks
report = test_shc;
```

The example `examples/shc_two_masses.slx` connects capacitances of 1000 and 500 J/K, initially at 40 and 20 degC, through a resistance of 0.8 K/W. The equilibrium temperature is 33.3333 degC and the time constant is 266.6667 s. The simulation runs for 200 s with a 0.01 s fixed step.

![Simulation versus analytical solution](docs/demo_validation.png)

**24 checks passed** in R2023a. The example's maximum analytical temperature error is 8.86e-5 degC and its relative energy variation is 9.02e-15. See [the validation record](docs/VALIDATION.md) for details.

## Ports and signs

```text
Inputs:  T1, T2 — temperatures [degC or K, use the same scale]
Outputs: Q1, Q2 — heat entering the corresponding node [W]

Q1 = (T2 - T1) / R
Q2 = -Q1
```

For T1=40 degC and T2=20 degC, Q1 is negative and Q2 is positive. Include Q1 in the net heat input of node 1 and Q2 in that of node 2. Update each node temperature using `dT/dt=Qnet/(m*cp)`.

For radial elements, T1 is the inner temperature and T2 is the outer temperature. Ports are directed Simulink signals and cannot connect directly to Simscape thermal conserving ports.

These elements represent thermal resistance without internal heat storage. Add external thermal capacitances for transient models; the example demonstrates this using ordinary integrators.

## Geometry and contact resistance

- Conductivity `lambda`: W/(m K); distances, lengths and diameters: m; `area`: m^2; `ctr`: K/W.
- Planar distances refer to the actual locations of temperature nodes. In two-material elements, each distance is from its node to the interface. Cell-centered discretizations commonly use half-cell distances.
- Cylindrical equations describe one-dimensional radial conduction through coaxial shells. Diameters must be strictly increasing and the inner diameter must be positive. Side-by-side cylinder contact, a control volume containing the axis, and axial conduction require their corresponding models.
- `ctr` is **total contact resistance**. Convert area-specific resistance R'' [m^2 K/W] using `ctr=R''/area` for planar interfaces or `ctr=R''/(pi*diamCt*le)` for cylindrical interfaces.
- Defaults are illustrative. Use application-specific geometry and properties, and verify spatial discretization, time step and boundary conditions.

## Rebuild from source

Save any desired changes and close the loaded `SHCLib` before rebuilding:

```matlab
setup_shc(false)
build_shc_library
```

`src/shc_block_specs.m` defines parameters, equations and validation. `src/build_shc_library.m` creates `library/SHCLib.slx` from basic Simulink blocks. Rebuilding replaces this project's library file without editing unrelated models.

## Project layout

```text
library/     SHCLib.slx and Library Browser registration
src/         Editable element definitions and builder
examples/    Two-capacitance model, builder and runner
tests/       Numerical and dependency checks
docs/        Previews, validation record and publishing notes
setup_shc.m  Session setup entry point
LICENSE      MIT License
```

## Implementation and license

This project independently constructs an explicit temperature/heat-flow signal network from standard planar, cylindrical and series-resistance equations. It does not bundle a third-party commercial thermal library, protected P-code, third-party library links, or a replacement license-check function.

Project sources, models and documentation are provided under the [MIT License](LICENSE). MathWorks retains the rights to MATLAB, Simulink and their built-in components; their licensing is outside the scope of this project's MIT grant.

Equation reference: [MathWorks — Conductive Heat Transfer](https://www.mathworks.com/help/simscape/ref/conductiveheattransfer.html). Library registration reference: [MathWorks — Add Libraries to Library Browser](https://www.mathworks.com/help/simulink/ug/adding-libraries-to-the-library-browser.html).

Repository: [hwx20040317/simulink-heat-conduction](https://github.com/hwx20040317/simulink-heat-conduction).
