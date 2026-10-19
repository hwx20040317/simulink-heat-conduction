# 发布到 GitHub

这是一个可单独发布的项目目录，不要上传它的上级工作区。

## 仓库信息

- GitHub 账号：`hwx20040317`。
- 仓库：`simulink-heat-conduction`。
- 可见性：Public。
- 许可证：MIT；`LICENSE` 中署名为项目 contributors。
- 首个版本：`v0.1.0`。

GitHub 上公开可见与明确授予开源使用权限不同，因此仓库中包含独立的 LICENSE 文件。参考：[GitHub — Licensing a repository](https://docs.github.com/en/repositories/managing-your-repositorys-settings-and-features/customizing-your-repository/licensing-a-repository)。

## 源文件与后续更新

仓库地址为 `https://github.com/hwx20040317/simulink-heat-conduction`。源码位于仓库根目录，包括隐藏文件 `.gitignore`。中文入口为 `README.md`，英文入口为 `README.en.md`。

应提交 `library/SHCLib.slx`、`examples/shc_two_masses.slx` 以及全部源码、文档和 LICENSE。`build/`、`slprj/`、自动保存文件和编译缓存不提交。

发布 ZIP 包与源文件包含同样的项目文件。发布前可以在仅包含 MATLAB/Simulink 默认路径的新会话中验证：

```matlab
% 在新会话执行，当前文件夹为仓库根目录
restoredefaultpath
addpath(pwd)
setup_shc(false)
test_shc
```

测试报告保存在 `build/validation.json`，发布验证记录可写入 `docs/VALIDATION.md`。其他 MATLAB 版本只有在实际验证通过后再增加兼容声明。

## 仓库简介

Planar and cylindrical radial heat-conduction elements for Simulink, with two-material interfaces, contact resistance, rebuildable sources and analytical validation.

## v0.1.0 版本说明

- Four conduction elements: one/two-material planar and one/two-material cylindrical radial conduction.
- Consistent temperature inputs and equal/opposite heat-flow outputs.
- Optional total contact resistance for two-material elements.
- Rebuildable library, editable parameter masks, and invalid-parameter checks.
- Two-capacitance transient example and numerical reference checks.
- Tested in MATLAB/Simulink R2023a; MIT-licensed project sources and models.
