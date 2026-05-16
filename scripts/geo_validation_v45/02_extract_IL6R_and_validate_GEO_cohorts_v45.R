#!/usr/bin/env Rscript
# MR_IL6R_CRC v45.0.0 - robust IL6R extraction and validation audit for GEO cohorts
args <- commandArgs(trailingOnly = TRUE)
ROOT <- ifelse(length(args) >= 1, args[1], getwd())
OUT <- file.path(ROOT, "7_Output", "v45_independent_validation")
RAW <- file.path(OUT, "GEO_raw")
RES <- file.path(OUT, "results")
FIG <- file.path(OUT, "figures")
LOGD <- file.path(OUT, "logs")
dir.create(RES, recursive = TRUE, showWarnings = FALSE)
dir.create(FIG, recursive = TRUE, showWarnings = FALSE)
dir.create(LOGD, recursive = TRUE, showWarnings = FALSE)

if (!requireNamespace("Biobase", quietly=TRUE)) stop("Install Biobase first: BiocManager::install('Biobase')")
if (!requireNamespace("GEOquery", quietly=TRUE)) stop("Install GEOquery first: BiocManager::install('GEOquery')")
if (!requireNamespace("data.table", quietly=TRUE)) install.packages("data.table")
suppressPackageStartupMessages({ library(Biobase); library(GEOquery); library(data.table) })

cohorts <- c("GSE39582", "GSE17536", "GSE17537", "GSE14333")

as_eset_list <- function(obj, gse) {
  # getGEO can return: ExpressionSet, list of ExpressionSets, character path(s), or error.
  if (inherits(obj, "error")) return(list(error = conditionMessage(obj)))
  if (inherits(obj, "ExpressionSet")) return(list(obj))
  if (is.list(obj) && any(vapply(obj, function(x) inherits(x, "ExpressionSet"), logical(1)))) {
    return(obj[vapply(obj, function(x) inherits(x, "ExpressionSet"), logical(1))])
  }
  if (is.character(obj)) {
    paths <- obj[file.exists(obj)]
    # if the saved character path is relative or stale, search RAW for series_matrix file.
    if (length(paths) == 0) paths <- Sys.glob(file.path(RAW, paste0(gse, "*series_matrix*.txt.gz")))
    if (length(paths) == 0) paths <- Sys.glob(file.path(RAW, paste0(gse, "*series_matrix*.txt")))
    esets <- list()
    for (p in paths) {
      message("[v45 parse filename] ", p)
      parsed <- tryCatch(GEOquery::getGEO(filename = p, GSEMatrix = TRUE, getGPL = TRUE), error=function(e) e)
      if (inherits(parsed, "ExpressionSet")) esets[[basename(p)]] <- parsed
      if (is.list(parsed)) {
        ok <- parsed[vapply(parsed, function(x) inherits(x, "ExpressionSet"), logical(1))]
        if (length(ok) > 0) esets <- c(esets, ok)
      }
    }
    if (length(esets) > 0) return(esets)
  }
  list(error = paste("Unsupported GEO object class:", paste(class(obj), collapse=";")))
}

find_il6r_probes <- function(eset) {
  fd <- tryCatch(as.data.frame(fData(eset)), error=function(e) data.frame())
  if (nrow(fd) == 0) {
    return(data.table(probe_id=character(), matched_field=character(), matched_value=character()))
  }
  fd$probe_id__ <- rownames(fd)
  symbol_cols <- names(fd)[grepl("symbol|gene|assignment|title|annotation", names(fd), ignore.case=TRUE)]
  if (length(symbol_cols) == 0) symbol_cols <- names(fd)
  out <- list()
  for (col in symbol_cols) {
    vals <- as.character(fd[[col]])
    hit <- grepl("(^|[^A-Za-z0-9])IL6R([^A-Za-z0-9]|$)", vals, ignore.case=FALSE)
    if (any(hit, na.rm=TRUE)) {
      out[[col]] <- data.table(probe_id=fd$probe_id__[hit], matched_field=col, matched_value=vals[hit])
    }
  }
  if (length(out)==0) return(data.table(probe_id=character(), matched_field=character(), matched_value=character()))
  unique(rbindlist(out, fill=TRUE))
}

infer_group <- function(pd) {
  txt <- apply(pd, 1, function(x) paste(as.character(x), collapse=" | "))
  normal <- grepl("normal|adjacent|non.?tumou?r|mucosa|healthy", txt, ignore.case=TRUE)
  tumor <- grepl("tumou?r|cancer|carcinoma|crc|colon adenocarcinoma|colorectal", txt, ignore.case=TRUE) & !normal
  group <- ifelse(normal, "normal_or_adjacent", ifelse(tumor, "tumor_or_cancer", "unclassified"))
  group
}

probe_audit <- list(); sample_rows <- list(); cohort_summary <- list(); tumor_normal_rows <- list(); pheno_cols <- list()
for (gse in cohorts) {
  rds <- file.path(RAW, paste0(gse, "_GEOquery_gset_v45.rds"))
  if (!file.exists(rds)) rds <- file.path(RAW, paste0(gse, "_GEOquery_gset.rds"))
  if (!file.exists(rds)) {
    cohort_summary[[gse]] <- data.table(cohort=gse, status="missing_rds", n_samples=NA_integer_, n_features=NA_integer_, il6r_probe_count=0)
    next
  }
  obj <- readRDS(rds)
  esets <- as_eset_list(obj, gse)
  if (!is.null(esets$error)) {
    cohort_summary[[gse]] <- data.table(cohort=gse, status="parse_failed", n_samples=NA_integer_, n_features=NA_integer_, il6r_probe_count=0, note=esets$error)
    next
  }
  # Pick the platform with the largest number of samples.
  ncols <- vapply(esets, function(e) ncol(exprs(e)), integer(1))
  eset <- esets[[which.max(ncols)]]
  ex <- exprs(eset); pd <- as.data.frame(pData(eset)); fd <- as.data.frame(fData(eset))
  probes <- find_il6r_probes(eset)
  probe_audit[[gse]] <- data.table(cohort=gse, platform=annotation(eset), probes)
  pheno_cols[[gse]] <- data.table(cohort=gse, column_name=names(pd), example_value=vapply(pd, function(x) paste(head(unique(as.character(x)), 3), collapse=" | "), character(1)))
  if (nrow(probes) == 0) {
    cohort_summary[[gse]] <- data.table(cohort=gse, status="no_IL6R_probe_detected", platform=annotation(eset), n_samples=ncol(ex), n_features=nrow(ex), il6r_probe_count=0)
    next
  }
  ids <- intersect(unique(probes$probe_id), rownames(ex))
  if (length(ids) == 0) {
    cohort_summary[[gse]] <- data.table(cohort=gse, status="IL6R_probe_not_in_expression_matrix", platform=annotation(eset), n_samples=ncol(ex), n_features=nrow(ex), il6r_probe_count=nrow(probes))
    next
  }
  # choose highest-IQR IL6R probe as primary, and also report mean collapsed value.
  iqr <- apply(ex[ids,,drop=FALSE], 1, IQR, na.rm=TRUE)
  primary_probe <- names(which.max(iqr))
  il6r_primary <- as.numeric(ex[primary_probe,])
  il6r_mean <- colMeans(ex[ids,,drop=FALSE], na.rm=TRUE)
  group <- infer_group(pd)
  sample_rows[[gse]] <- data.table(cohort=gse, sample_id=colnames(ex), platform=annotation(eset), primary_probe=primary_probe, il6r_primary=il6r_primary, il6r_probe_mean=il6r_mean, inferred_group=group)
  cohort_summary[[gse]] <- data.table(cohort=gse, status="IL6R_extracted", platform=annotation(eset), n_samples=ncol(ex), n_features=nrow(ex), il6r_probe_count=length(ids), primary_probe=primary_probe, n_normal=sum(group=="normal_or_adjacent"), n_tumor=sum(group=="tumor_or_cancer"), n_unclassified=sum(group=="unclassified"))
  if (sum(group=="normal_or_adjacent") >= 3 && sum(group=="tumor_or_cancer") >= 3) {
    wt <- wilcox.test(il6r_primary[group=="tumor_or_cancer"], il6r_primary[group=="normal_or_adjacent"])
    tumor_normal_rows[[gse]] <- data.table(cohort=gse, n_tumor=sum(group=="tumor_or_cancer"), n_normal=sum(group=="normal_or_adjacent"), median_tumor=median(il6r_primary[group=="tumor_or_cancer"], na.rm=TRUE), median_normal=median(il6r_primary[group=="normal_or_adjacent"], na.rm=TRUE), wilcox_p=wt$p.value)
  }
}

write_dt <- function(x, file) data.table::fwrite(x, file=file, sep="\t")
summary_dt <- rbindlist(cohort_summary, fill=TRUE)
probe_dt <- if (length(probe_audit)>0) rbindlist(probe_audit, fill=TRUE) else data.table()
sample_dt <- if (length(sample_rows)>0) rbindlist(sample_rows, fill=TRUE) else data.table()
tn_dt <- if (length(tumor_normal_rows)>0) rbindlist(tumor_normal_rows, fill=TRUE) else data.table()
pheno_dt <- if (length(pheno_cols)>0) rbindlist(pheno_cols, fill=TRUE) else data.table()

write_dt(summary_dt, file.path(RES, "v45_GEO_IL6R_cohort_summary.tsv"))
write_dt(probe_dt, file.path(RES, "v45_GEO_IL6R_probe_audit.tsv"))
write_dt(sample_dt, file.path(RES, "v45_GEO_IL6R_sample_level_expression.tsv"))
write_dt(tn_dt, file.path(RES, "v45_GEO_IL6R_tumor_normal_validation.tsv"))
write_dt(pheno_dt, file.path(RES, "v45_GEO_pheno_column_audit.tsv"))

# Candidate survival columns audit only; exact survival mapping should be manually confirmed before Cox models.
surv_cols <- pheno_dt[grepl("survival|death|vital|relapse|recurrence|rfs|dfs|os|days|month|follow|status", column_name, ignore.case=TRUE)]
write_dt(surv_cols, file.path(RES, "v45_GEO_candidate_survival_columns_for_manual_mapping.tsv"))
manual_template <- data.table(cohort=cohorts, time_col="", event_col="", event_coding_positive="", notes="Fill manually after checking v45_GEO_pheno_column_audit.tsv; do not run Cox models until mapping is confirmed.")
write_dt(manual_template, file.path(RES, "v45_GEO_survival_manual_mapping_template.tsv"))
cat("__DONE__ ", as.character(Sys.time()), "\n")
