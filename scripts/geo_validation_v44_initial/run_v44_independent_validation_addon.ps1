#（PowerShell）运行 v44 独立 GEO 验证脚本
$ROOT = "D:\SCI2\MD-1\MR_IL6R_CRC_project_template_v4"
$PKG = Join-Path $ROOT "2_code\99_reporting\v44_independent_validation_addon"
$RSCRIPT = "C:\Program Files\R\R-4.3.3\bin\Rscript.exe"
& $RSCRIPT (Join-Path $PKG "01_R_scripts\01_download_GEO_validation_cohorts_v44.R") $ROOT
& $RSCRIPT (Join-Path $PKG "01_R_scripts\02_extract_IL6R_and_validate_GEO_cohorts_v44.R") $ROOT
echo "__DONE__ $(Get-Date)"
