# Changelog

## 0.2.0 — 2026-10-22

- Added continuous Thermal mass, constant-coefficient Convection, Temperature boundary and Heat flow boundary elements.
- Added signed heat conventions, parameter validation and finite-capacitance/conductance checks.
- Added a ready-to-run constant-heating/convection model with analytical temperature and sampled energy comparisons.
- Added free-cooling, negative-power, warm-reservoir, adiabatic, time-step-refinement and closed two-mass references.
- Kept all four v0.1.0 conduction block paths, parameters, ports and original regression cases.
- Updated Chinese/English documentation, previews and source-rebuild instructions.
- Thermal mass uses a continuous state. Choose a continuous solver for models containing it; the original discrete example is retained.

## 0.1.0 — 2026-10-19

- Initial public release: four planar/cylindrical conduction elements, rebuildable sources and a two-capacitance example.
- 24 numerical, validation and dependency checks in MATLAB/Simulink R2023a.
- MIT License; Chinese and English documentation.
