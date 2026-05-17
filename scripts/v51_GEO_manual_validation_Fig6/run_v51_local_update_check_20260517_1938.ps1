#（PowerShell）MR_IL6R_CRC v51 复制并检查 GEO validation + Figure 6 更新文件
$ROOT = "D:\SCI2\MD-1\MR_IL6R_CRC_project_template_v4"
$OUT  = Join-Path $ROOT "4_figures_submission_v51"
New-Item -ItemType Directory -Force -Path $OUT | Out-Null

Write-Host "Run R script:"
Write-Host "Rscript .\make_Figure6_and_GEO_S2_v51_20260517_1938.R $ROOT"

Get-ChildItem $OUT -Recurse -File -ErrorAction SilentlyContinue |
  Select-Object FullName, Length, LastWriteTime |
  Sort-Object LastWriteTime -Descending |
  Format-Table -AutoSize

echo "__DONE__ $(Get-Date)"