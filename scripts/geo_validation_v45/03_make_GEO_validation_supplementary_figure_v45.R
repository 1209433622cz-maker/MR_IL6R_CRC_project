#!/usr/bin/env Rscript
# MR_IL6R_CRC v45.0.0 - make supplementary GEO validation figures from v45 results
args <- commandArgs(trailingOnly = TRUE)
ROOT <- ifelse(length(args) >= 1, args[1], getwd())
OUT <- file.path(ROOT, "7_Output", "v45_independent_validation")
RES <- file.path(OUT, "results")
FIG <- file.path(OUT, "figures")
dir.create(FIG, recursive=TRUE, showWarnings=FALSE)
if (!requireNamespace("data.table", quietly=TRUE)) install.packages("data.table")
if (!requireNamespace("ggplot2", quietly=TRUE)) install.packages("ggplot2")
if (!requireNamespace("patchwork", quietly=TRUE)) install.packages("patchwork")
suppressPackageStartupMessages({ library(data.table); library(ggplot2); library(patchwork) })

sample_file <- file.path(RES, "v45_GEO_IL6R_sample_level_expression.tsv")
summary_file <- file.path(RES, "v45_GEO_IL6R_cohort_summary.tsv")
tn_file <- file.path(RES, "v45_GEO_IL6R_tumor_normal_validation.tsv")
if (!file.exists(sample_file) || !file.exists(summary_file)) stop("Run 02_extract_IL6R_and_validate_GEO_cohorts_v45.R first.")
samp <- fread(sample_file)
summ <- fread(summary_file)
tn <- if (file.exists(tn_file)) fread(tn_file) else data.table()

theme_jtm <- function(base_size=9) theme_bw(base_size=base_size) + theme(panel.grid.minor=element_blank(), plot.title=element_text(face="bold"), axis.title=element_text(face="bold"), legend.title=element_text(face="bold"))

p1 <- ggplot(summ, aes(x=cohort, y=n_samples, fill=status)) + geom_col(width=0.65, color="#333333", linewidth=0.25) + coord_flip() + labs(title="A. GEO validation cohort audit", x=NULL, y="Samples") + theme_jtm()
p2 <- ggplot(samp, aes(x=cohort, y=il6r_primary, fill=cohort)) + geom_boxplot(outlier.size=0.3, width=0.55) + labs(title="B. IL6R expression distribution across GEO cohorts", x=NULL, y="IL6R expression (primary probe)") + theme_jtm() + theme(legend.position="none")
if (nrow(tn) > 0 && any(samp$inferred_group %in% c("normal_or_adjacent","tumor_or_cancer"))) {
  plot_dt <- samp[inferred_group %in% c("normal_or_adjacent","tumor_or_cancer")]
  p3 <- ggplot(plot_dt, aes(x=inferred_group, y=il6r_primary, fill=inferred_group)) + geom_boxplot(outlier.size=0.3, width=0.55) + facet_wrap(~cohort, scales="free_y") + labs(title="C. Tumour vs normal/adjacent validation where inferable", x=NULL, y="IL6R expression") + theme_jtm() + theme(axis.text.x=element_text(angle=25,hjust=1), legend.position="none")
} else {
  p3 <- ggplot() + annotate("label", x=0, y=0, label="No cohort had an automatically reliable tumour/normal split.\nUse phenotype audit for manual mapping.", size=4, label.size=0.25) + xlim(-1,1) + ylim(-1,1) + labs(title="C. Tumour-normal validation status") + theme_void(base_size=9)
}
fig <- p1 / p2 / p3 + plot_layout(heights=c(0.8,1,1.1))
out_png <- file.path(FIG, paste0("Supplementary_Figure_GEO_IL6R_external_validation_v45_", format(Sys.time(), "%Y%m%d_%H%M%S"), ".png"))
out_pdf <- sub("\\.png$", ".pdf", out_png)
ggsave(out_png, fig, width=9, height=10, dpi=450)
ggsave(out_pdf, fig, width=9, height=10, device=grDevices::cairo_pdf)
cat("[WRITE] ", out_png, "\n")
cat("[WRITE] ", out_pdf, "\n")
cat("__DONE__ ", as.character(Sys.time()), "\n")
