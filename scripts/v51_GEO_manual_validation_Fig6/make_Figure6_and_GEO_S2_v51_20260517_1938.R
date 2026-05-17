# MR_IL6R_CRC v51: reproduce Figure 6 candidate and Supplementary Figure S2
# Run in R from the project root after placing the v50/v51 TSV files in the paths below.
suppressPackageStartupMessages({
  library(ggplot2)
  library(data.table)
  library(patchwork)
})

ROOT <- ifelse(length(commandArgs(trailingOnly=TRUE)) >= 1, commandArgs(trailingOnly=TRUE)[1],
               "D:/SCI2/MD-1/MR_IL6R_CRC_project_template_v4")
STAMP <- format(Sys.time(), "%Y%m%d_%H%M%S")
OUT <- file.path(ROOT, "4_figures_submission_v51")
dir.create(OUT, recursive=TRUE, showWarnings=FALSE)

fig6_file <- file.path(ROOT, "7_Output/v50_Figure6_rerun/Figure_6_v50_scRNA_cell_level_source_data_20260517_063039.tsv")
if (file.exists(fig6_file)) {
  d <- fread(fig6_file)
  set.seed(51)
  dp <- d[sample(.N, min(.N, 25000))]
  pA <- ggplot(dp, aes(UMAP_1, UMAP_2, colour=Global_Cluster)) +
    geom_point(size=0.15, alpha=0.45) +
    labs(title="A. GSE146771 single-cell landscape", x="UMAP 1", y="UMAP 2", colour="Cell class") +
    theme_bw(base_size=9) + theme(panel.grid=element_blank(), plot.title=element_text(face="bold"))
  pB <- ggplot(dp, aes(UMAP_1, UMAP_2, colour=pmin(IL6R_expr, quantile(IL6R_expr, 0.99, na.rm=TRUE)))) +
    geom_point(size=0.15, alpha=0.55) +
    scale_colour_viridis_c(name="IL6R") +
    labs(title="B. IL6R expression across cells", x="UMAP 1", y="UMAP 2") +
    theme_bw(base_size=9) + theme(panel.grid=element_blank(), plot.title=element_text(face="bold"))
  s <- d[, .(n_cells=.N, pct_IL6R_positive=mean(IL6R_expr>0, na.rm=TRUE)*100,
             median_IL6_axis=median(IL6_axis_score, na.rm=TRUE)), by=Global_Cluster]
  pC <- ggplot(s, aes(reorder(Global_Cluster, pct_IL6R_positive), pct_IL6R_positive)) +
    geom_col(width=0.7) + coord_flip() +
    labs(title="C. Fraction of IL6R-positive cells", x=NULL, y="IL6R-positive cells (%)") +
    theme_bw(base_size=9) + theme(panel.grid.minor=element_blank(), plot.title=element_text(face="bold"))
  pD <- ggplot(s, aes(reorder(Global_Cluster, median_IL6_axis), median_IL6_axis)) +
    geom_col(width=0.7) + coord_flip() + geom_hline(yintercept=0, linetype=2) +
    labs(title="D. IL6-axis module score by cell class", x=NULL, y="Median IL6-axis module score") +
    theme_bw(base_size=9) + theme(panel.grid.minor=element_blank(), plot.title=element_text(face="bold"))
  fig6 <- (pA | pB) / (pC | pD) + plot_annotation(title="Figure 6. Single-cell IL6R and IL6-axis context in colorectal cancer immune microenvironments")
  ggsave(file.path(OUT, paste0("Figure_6_scRNA_IL6R_axis_v51_", STAMP, ".pdf")), fig6, width=12, height=9)
  ggsave(file.path(OUT, paste0("Figure_6_scRNA_IL6R_axis_v51_", STAMP, ".png")), fig6, width=12, height=9, dpi=300)
}

# Supplementary Figure S2 should be generated from Supplementary Tables S10-S12 using the v51 package tables.
message("__DONE__ ", Sys.time())