#!/usr/bin/env Rscript
# MR_IL6R_CRC v45.0.0 - robust GEO download for independent validation
# This script fixes the v44 issue where getGEO() sometimes saved a character path instead of an ExpressionSet.
args <- commandArgs(trailingOnly = TRUE)
ROOT <- ifelse(length(args) >= 1, args[1], getwd())
OUT <- file.path(ROOT, "7_Output", "v45_independent_validation")
RAW <- file.path(OUT, "GEO_raw")
LOGD <- file.path(OUT, "logs")
dir.create(RAW, recursive = TRUE, showWarnings = FALSE)
dir.create(LOGD, recursive = TRUE, showWarnings = FALSE)

message("[v45] ROOT = ", ROOT)
message("[v45] RAW  = ", RAW)

if (!requireNamespace("BiocManager", quietly = TRUE)) install.packages("BiocManager")
if (!requireNamespace("GEOquery", quietly = TRUE)) BiocManager::install("GEOquery", ask = FALSE, update = FALSE)
if (!requireNamespace("Biobase", quietly = TRUE)) BiocManager::install("Biobase", ask = FALSE, update = FALSE)
suppressPackageStartupMessages({ library(GEOquery); library(Biobase) })

cohorts <- data.frame(
  gse = c("GSE39582", "GSE17536", "GSE17537", "GSE14333"),
  role = c("primary_external_validation", "sensitivity_validation", "sensitivity_validation", "sensitivity_validation"),
  stringsAsFactors = FALSE
)

save_audit <- list()
for (i in seq_len(nrow(cohorts))) {
  gse <- cohorts$gse[i]
  message("[v45 GEO download] ", gse)
  status <- "not_started"; class_txt <- NA_character_; n_sets <- NA_integer_; note <- NA_character_
  obj <- tryCatch({
    GEOquery::getGEO(gse, GSEMatrix = TRUE, getGPL = TRUE, destdir = RAW)
  }, error = function(e) {
    message("[WARN] getGPL=TRUE failed for ", gse, ": ", conditionMessage(e))
    tryCatch(GEOquery::getGEO(gse, GSEMatrix = TRUE, getGPL = FALSE, destdir = RAW), error = function(e2) e2)
  })
  class_txt <- paste(class(obj), collapse = ";")
  if (inherits(obj, "error")) {
    status <- "download_failed"; note <- conditionMessage(obj); n_sets <- 0L
  } else {
    status <- "downloaded"; n_sets <- if (is.list(obj)) length(obj) else 1L; note <- "saved raw GEOquery object"
  }
  saveRDS(obj, file = file.path(RAW, paste0(gse, "_GEOquery_gset_v45.rds")))
  save_audit[[gse]] <- data.frame(gse=gse, role=cohorts$role[i], status=status, object_class=class_txt, n_sets=n_sets, note=note)
}

audit <- do.call(rbind, save_audit)
write.table(audit, file=file.path(LOGD, paste0("v45_GEO_download_audit_", format(Sys.time(), "%Y%m%d_%H%M%S"), ".tsv")), sep="\t", quote=FALSE, row.names=FALSE)
cat("__DONE__ ", as.character(Sys.time()), "\n")
