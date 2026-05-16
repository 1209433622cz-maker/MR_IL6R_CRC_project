#!/usr/bin/env Rscript
args <- commandArgs(trailingOnly = TRUE)
ROOT <- ifelse(length(args) >= 1, args[1], getwd())
outdir <- file.path(ROOT, "7_Output", "v44_independent_validation", "GEO_raw")
dir.create(outdir, recursive=TRUE, showWarnings=FALSE)
if (!requireNamespace("BiocManager", quietly=TRUE)) install.packages("BiocManager")
if (!requireNamespace("GEOquery", quietly=TRUE)) BiocManager::install("GEOquery", ask=FALSE, update=FALSE)
library(GEOquery)
for (gse in c("GSE39582","GSE17536","GSE17537","GSE14333")) {
  message("[GEO] ", gse)
  gset <- tryCatch(getGEO(gse, GSEMatrix=TRUE, getGPL=TRUE), error=function(e) e)
  saveRDS(gset, file=file.path(outdir, paste0(gse,"_GEOquery_gset.rds")))
}
cat("__DONE__ ", as.character(Sys.time()), "\n")
