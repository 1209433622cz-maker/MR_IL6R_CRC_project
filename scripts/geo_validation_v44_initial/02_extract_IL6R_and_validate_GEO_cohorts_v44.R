#!/usr/bin/env Rscript
args <- commandArgs(trailingOnly = TRUE)
ROOT <- ifelse(length(args) >= 1, args[1], getwd())
indir <- file.path(ROOT, "7_Output", "v44_independent_validation", "GEO_raw")
outdir <- file.path(ROOT, "7_Output", "v44_independent_validation", "results")
dir.create(outdir, recursive=TRUE, showWarnings=FALSE)
if (!requireNamespace("Biobase", quietly=TRUE)) stop("Install Biobase")
library(Biobase)
find_il6r_probe <- function(eset) {
  fd <- tryCatch(fData(eset), error=function(e) data.frame())
  if (nrow(fd)==0) return(character())
  unique(rownames(fd)[apply(fd, 1, function(x) any(grepl("IL6R", as.character(x), ignore.case=FALSE)))])
}
rows <- list()
for (gse in c("GSE39582","GSE17536","GSE17537","GSE14333")) {
  rds <- file.path(indir, paste0(gse,"_GEOquery_gset.rds")); if (!file.exists(rds)) next
  gset <- readRDS(rds); eset <- if (is.list(gset)) gset[[1]] else gset
  probes <- find_il6r_probe(eset)
  rows[[gse]] <- data.frame(cohort=gse, n_samples=ncol(exprs(eset)), n_features=nrow(exprs(eset)), il6r_probes=paste(probes, collapse=";"))
}
write.table(do.call(rbind, rows), file=file.path(outdir,"v44_GEO_IL6R_probe_audit.tsv"), sep="\t", quote=FALSE, row.names=FALSE)
cat("__DONE__ ", as.character(Sys.time()), "\n")
