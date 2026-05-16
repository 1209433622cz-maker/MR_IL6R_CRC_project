#（PowerShell）检查 v45 独立 GEO 验证输出
param([string]$ROOT = "D:\SCI2\MD-1\MR_IL6R_CRC_project_template_v4")
cd $ROOT
Write-Host "== v45 independent validation results =="
Get-ChildItem ".\7_Output\v45_independent_validation" -Recurse -File -ErrorAction SilentlyContinue |
  Sort-Object LastWriteTime -Descending |
  Select-Object FullName, Length, LastWriteTime

echo "__DONE__ $(Get-Date)"
