#（PowerShell）v45：重新运行独立 GEO 验证 hotfix，生成结果表和补充图
param([string]$ROOT = "D:\SCI2\MD-1\MR_IL6R_CRC_project_template_v4")
$PKG = Join-Path $ROOT "2_code\99_reporting\v45_independent_validation_rescue"
$RSCRIPT = "C:\Program Files\R\R-4.3.3\bin\Rscript.exe"
if (!(Test-Path $RSCRIPT)) {
  $RSCRIPT = Get-ChildItem "C:\Program Files\R" -Filter Rscript.exe -Recurse -ErrorAction SilentlyContinue | Select-Object -First 1 -ExpandProperty FullName
}
if (!(Test-Path $RSCRIPT)) { Write-Host "[ERROR] Rscript.exe not found."; exit 1 }
$LOGD = Join-Path $ROOT "7_Output\v45_independent_validation\logs"
New-Item -ItemType Directory -Force -Path $LOGD | Out-Null

Write-Host "== v45 download GEO cohorts =="
& $RSCRIPT (Join-Path $PKG "01_R_hotfix_scripts\01_download_GEO_validation_cohorts_v45.R") $ROOT 2>&1 | Tee-Object -FilePath (Join-Path $LOGD ("v45_01_download_" + (Get-Date -Format yyyyMMdd_HHmmss) + ".log"))

Write-Host "== v45 extract IL6R and validation audit =="
& $RSCRIPT (Join-Path $PKG "01_R_hotfix_scripts\02_extract_IL6R_and_validate_GEO_cohorts_v45.R") $ROOT 2>&1 | Tee-Object -FilePath (Join-Path $LOGD ("v45_02_extract_" + (Get-Date -Format yyyyMMdd_HHmmss) + ".log"))

Write-Host "== v45 make supplementary GEO validation figure =="
& $RSCRIPT (Join-Path $PKG "01_R_hotfix_scripts\03_make_GEO_validation_supplementary_figure_v45.R") $ROOT 2>&1 | Tee-Object -FilePath (Join-Path $LOGD ("v45_03_make_figure_" + (Get-Date -Format yyyyMMdd_HHmmss) + ".log"))

echo "__DONE__ $(Get-Date)"
