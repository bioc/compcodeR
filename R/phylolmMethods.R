#' @title Get the tree from a phyloCompData object
#'
#' @description
#' Return the tree of a \code{phyloCompData} object.
#' If no tree, return a star tree with unit height, and throw a warning.
#' 
#' @param cdata a phyloCompData object.
#' 
#' @return A tree of class \code{phylo}
#' 
#' @keywords internal
#' 
getTree <- function(cdata) {
  if (is.null(phylo.tree(cdata)) || length(phylo.tree(cdata)) == 0) {
    message("There were no tree in the data object. Using a star tree of unit height in phylolm.")
    ntaxa <- info.parameters(cdata)$samples.per.cond * 2
    tree <- ape::stree(ntaxa, "star")
    tree$edge.length <- rep(1, nrow(tree$edge))
    tree$tip.label <- rownames(sample.annotations(cdata))
    return(tree)
  } else {
    tree <- phylo.tree(cdata)
    if (!ape::is.ultrametric(tree)) stop("The tree must be ultrametric.")
    return(tree)
  }
}

#' @title Extract phylolm results
#'
#' @description
#' Extract results from a phylolm object.
#' The coefficient of interest must be named "condition".
#' 
#' @param phylo_lm_obj a phylolm object.
#' 
#' @return A list, with:
#' \describe{
#' \item{pvalue}{the p value of the differential expression.}
#' \item{logFC}{the log fold change of the differential expression.}
#' \item{score}{1 - pvalue.}
#' }
#' 
#' @keywords internal
#' 
extract_results_phylolm <- function(phylo_lm_obj) {
  res <- as.data.frame(summary(phylo_lm_obj)$coefficients)
  result.table <- data.frame('pvalue' = res['condition2', 'p.value'],
                             'logFC' = res['condition2', 'Estimate'],
                             'score' = 1 - res['condition2', 'p.value'])
  return(result.table)
}

#' @title Perform the phylolm analysis
#'
#' @description
#' Perform the phylolm analysis for a given gene.
#' 
#' @param dat the data associated with a gene
#' @param design_data design matrix
#' @param design_formula design formula
#' @param tree phylogenetic tree
#' @param model the model to be used in phylolm
#' @param measurement_error boolean
#' 
#' @return A list, with:
#' \describe{
#' \item{pvalue}{the p value of the differential expression.}
#' \item{logFC}{the log fold change of the differential expression.}
#' \item{score}{1 - pvalue.}
#' }
#' 
#' @keywords internal
#' 
phylolm_analysis <- function(dat, design_data, design_formula, tree, model, measurement_error, ...) {
  data_reg <- design_data
  data_reg$expr <- dat
  levels(data_reg$condition) <- c(1, 2)
  res <- try(extract_results_phylolm(phylolm::phylolm(paste('expr', paste(as.character(design_formula), collapse = '')),
                                                      data = data_reg,
                                                      phy = tree,
                                                      model = model,
                                                      measurement_error = measurement_error, 
                                                      ...)))
  if (inherits(res, 'try-error')) {
    if (model == 'BM' && measurement_error) {
      res <- try(extract_results_phylolm(phylolm::phylolm(paste('expr', paste(as.character(design_formula), collapse = '')),
                                                          data = data_reg,
                                                          phy = tree,
                                                          model = 'lambda',
                                                          measurement_error = FALSE, 
                                                          ...)))
    }
  }
  if (inherits(res, 'try-error')) {
    res <- data.frame('pvalue' = 1.0,
                      'logFC' = 0.0,
                      'score' = 0.0)
    warning(paste0('A gene produced an error.'))
  }
  return(res)
}

#' Generate a \code{.Rmd} file containing code to perform differential expression analysis with \code{\link[phylolm]{phylolm}}.
#' 
#' A function to generate code that can be run to perform differential expression analysis of RNAseq data (comparing two conditions) using the phylolm package. The code is written to a \code{.Rmd} file. This function is generally not called by the user, the main interface for performing differential expression analysis is the \code{\link{runDiffExp}} function.
#' 
#' For more information about the methods and the interpretation of the parameters, see the \code{\link[phylolm]{phylolm}} package and the corresponding publications. 
#' 
#' @param data.path The path to a .rds file containing the \code{phyloCompData} object that will be used for the differential expression analysis.
#' @param result.path The path to the file where the result object will be saved.
#' @param codefile The path to the file where the code will be written.
#' @param norm.method The between-sample normalization method used to compensate for varying library sizes and composition in the differential expression analysis. The normalization factors are calculated using the \code{calcNormFactors} of the \code{edgeR} package. Possible values are \code{"TMM"}, \code{"RLE"}, \code{"upperquartile"} and \code{"none"}
#' @param model The model for trait evolution on the tree. Default to "BM".
#' @param measurement_error A logical value indicating whether there is measurement error. Default to TRUE.
#' @param extra.design.covariates A vector containing the names of extra control variables to be passed to the design matrix of \code{phyolm}. All the covariates need to be a column of the \code{sample.annotations} data frame from the \code{\link{phyloCompData}} object, with a matching column name. The covariates can be a numeric vector, or a factor. Note that "condition" factor column is always included, and should not be added here. See Details.
#' @param length.normalization one of "none" (no correction), "TPM" or "RPKM" (default). See details.
#' @param data.transformation one of "log2", "asin(sqrt)" or "sqrt". Data transformation to apply to the normalized data.
#' @param ... Further arguments to be passed to function \code{\link[phylolm]{phylolm}}.
#' 
#' @details 
#' The \code{length.matrix} field of the \code{phyloCompData} object 
#' is used to normalize the counts, using one of the following formulas:
#' * \code{length.normalization="none"} : \eqn{CPM_{gi} = \frac{N_{gi} + 0.5}{NF_i \times \sum_{g} N_{gi} + 1} \times 10^6}
#' * \code{length.normalization="TPM"} : \eqn{TPM_{gi} = \frac{(N_{gi} + 0.5) / L_{gi}}{NF_i \times \sum_{g} N_{gi}/L_{gi} + 1} \times 10^6}
#' * \code{length.normalization="RPKM"} : \eqn{RPKM_{gi} = \frac{(N_{gi} + 0.5) / L_{gi}}{NF_i \times \sum_{g} N_{gi} + 1} \times 10^9}
#' 
#' where \eqn{N_{gi}} is the count for gene g and sample i,
#' where \eqn{L_{gi}} is the length of gene g in sample i,
#' and \eqn{NF_i} is the normalization for sample i,
#' normalized using \code{calcNormFactors} of the \code{edgeR} package.
#' 
#' The function specified by the \code{data.transformation} is then applied
#' to the normalized count matrix.
#' 
#' The "\eqn{+0.5}" and "\eqn{+1}" are taken from Law et al 2014,
#' and dropped from the normalization 
#' when the transformation is something else than \code{log2}.
#' 
#' The "\eqn{\times 10^6}" and "\eqn{\times 10^9}" factors are omitted when
#' the \code{asin(sqrt)} transformation is taken, as \eqn{asin} can only
#' be applied to real numbers smaller than 1.
#' 
#' The \code{design} model used in the \code{\link[phylolm]{phylolm}}
#' uses the "condition" column of the \code{sample.annotations} data frame from the \code{\link{phyloCompData}} object
#' as well as all the covariates named in \code{extra.design.covariates}.
#' For example, if \code{extra.design.covariates = c("var1", "var2")}, then
#' \code{sample.annotations} must have two columns named "var1" and "var2", and the design formula
#' in the \code{\link[phylolm]{phylolm}} function will be:
#' \code{~ condition + var1 + var2}.
#' 
#' @export 
#' @author Charlotte Soneson, Paul Bastide, Mélina Gallopin
#' @return The function generates a \code{.Rmd} file containing the code for performing the differential expression analysis. This file can be executed using e.g. the \code{knitr} package.
#' @references 
#' Ho, L. S. T. and Ane, C. 2014. "A linear-time algorithm for Gaussian and non-Gaussian trait evolution models". Systematic Biology 63(3):397-408.
#' 
#' Law, C.W., Chen, Y., Shi, W. et al. (2014) voom: precision weights unlock linear model analysis tools for RNA-seq read counts. Genome Biol 15, R29.
#'
#' Musser, JM, Wagner, GP. (2015): Character trees from transcriptome data: Origin and individuation of morphological characters and the so‐called “species signal”. J. Exp. Zool. (Mol. Dev. Evol.) 324B: 588– 604.
#' 
#' @examples
#' try(
#' if (require(ape) && require(phylolm)) {
#' tmpdir <- normalizePath(tempdir(), winslash = "/")
#' set.seed(20200317)
#' tree <- rphylo(10, 0.1, 0)
#' mydata.obj <- generateSyntheticData(dataset = "mydata", n.vars = 1000, 
#'                                     samples.per.cond = 5, n.diffexp = 100, 
#'                                     tree = tree,
#'                                     id.species = 1:10,
#'                                     lengths.relmeans = rpois(1000, 1000),
#'                                     lengths.dispersions = rgamma(1000, 1, 1),
#'                                     output.file = file.path(tmpdir, "mydata.rds"))
#' ## Add covariates
#' ## Model fitted is count.matrix ~ condition + test_factor + test_reg
#' sample.annotations(mydata.obj)$test_factor <- factor(rep(1:2, each = 5))
#' sample.annotations(mydata.obj)$test_reg <- rnorm(10, 0, 1)
#' saveRDS(mydata.obj, file.path(tmpdir, "mydata.rds"))
#' ## Diff Exp
#' runDiffExp(data.file = file.path(tmpdir, "mydata.rds"), result.extent = "DESeq2", 
#'            Rmdfunction = "phylolm.createRmd", 
#'            output.directory = tmpdir,
#'            norm.method = "TMM",
#'            extra.design.covariates = c("test_factor", "test_reg"),
#'            length.normalization = "RPKM")
#' })
phylolm.createRmd <- function(data.path, result.path, codefile, 
                              norm.method,
                              model = "BM", measurement_error = TRUE,
                              extra.design.covariates = NULL,
                              length.normalization = "RPKM",
                              data.transformation = "log2",
                              ...) {
  codefile <- file(codefile, open = 'w')
  writeLines("### phylolm", codefile)
  writeLines(paste("Data file: ", data.path, sep = ''), codefile)
  writeLines(c("```{r, echo = TRUE, eval = TRUE, include = TRUE, message = TRUE, error = TRUE, warning = TRUE}", 
               "require(phylolm)", 
               "require(limma)", 
               "require(edgeR)",
               paste("cdata <- readRDS('", data.path, "')", sep = '')), codefile)
  if (is.list(readRDS(data.path))) {
    writeLines("cdata <- convertListTophyloCompData(cdata)", codefile)
  }
  
  writeLines(c("is.valid <- check_phyloCompData(cdata)",
               "if (!(is.valid == TRUE)) stop('Not a valid phyloCompData object.')"),
             codefile)
  ## Design for normalization
  writeLines(c("", "# Design"),codefile)
  if (is.null(extra.design.covariates)) {
    writeLines(c(
      "design_formula <- as.formula(~ condition)",
      "design_data <- sample.annotations(cdata)[, 'condition', drop = FALSE]"),
      codefile)
  } else {
    writeLines(c(
      paste0("design_formula <- as.formula(paste(' ~ ', paste(c('", paste(extra.design.covariates, collapse = "', '"), "'), collapse= '+'), '+ condition'))"),
      paste0("design_data <- sample.annotations(cdata)[, c('", paste(extra.design.covariates, collapse = "', '"), "', 'condition'), drop = FALSE]")),
      codefile)
  }
  writeLines(c(
    "design_data$condition <- factor(design_data$condition)",
    "design <- model.matrix(design_formula, design_data)"),
    codefile)
  writeNormalization(norm.method, length.normalization, data.transformation, codefile)
  ## Functions to apply phylolm
  writeLines(c("", "# Wrapper functions"),codefile)
  ff <- deparse(extract_results_phylolm)
  ff[1] <- paste0("extract_results_phylolm <- ", ff[1])
  writeLines(ff, codefile)
  ff <- deparse(phylolm_analysis)
  ff[1] <- paste0("phylolm_analysis <- ", ff[1])
  writeLines(ff, codefile)
  ## Apply analysis
  writeLines(c("", "# Analysis"),codefile)
  extra_args <- eval(substitute(alist(...)))
  extra_args <- sapply(extra_args, function(x) paste(" = ", x))
  extra_args <- paste(names(extra_args), extra_args, collapse = ", ")
  writeLines(c("tree <- getTree(cdata)"),codefile)
  writeLines(c(
    paste0("phylolm.results_list <- apply(data.trans, 1, phylolm_analysis, design_data = design_data, design_formula = design_formula, tree = tree, model = '", model, "', measurement_error = ", measurement_error, ", ", extra_args, ")"),
    "result.table <- do.call(rbind, phylolm.results_list)"),
    codefile)
  writeLines(c(
    "result.table$adjpvalue <- p.adjust(result.table$pvalue, 'BH')"),
    codefile)
  writeLines(c("", "# Save the results"),codefile)
  writeLines(c(
    "rownames(result.table) <- rownames(count.matrix(cdata))",
    "result.table(cdata) <- result.table", 
    "package.version(cdata) <- paste('phylolm,', packageVersion('phylolm'))",
    "package.version(cdata) <- paste('limma,', packageVersion('limma'))",
    "analysis.date(cdata) <- date()",
    paste("method.names(cdata) <- list('short.name' = 'phylolm', 'full.name' = '",
          paste('phylolm', packageVersion('limma'), packageVersion('phylolm'), '.', norm.method, '.',
                model, '.',
                ifelse(!is.null(measurement_error), 'me', 'nome'), '.',
                "lengthNorm.", length.normalization, '.',
                "dataTrans.", data.transformation,
                ifelse(!is.null(extra.design.covariates), paste0(".", paste(extra.design.covariates, collapse = ".")), ""),
                sep = ''),
          "')", sep = ''),
    "is.valid <- check_compData_results(cdata)",
    "if (!(is.valid == TRUE)) stop('Not a valid phyloCompData result object.')",
    paste("saveRDS(cdata, '", result.path, "')", sep = "")),
    codefile)  
  writeLines("print(paste('Unique data set ID:', info.parameters(cdata)$uID))", codefile)
  writeLines("sessionInfo()", codefile)
  writeLines("```", codefile)
  close(codefile)
}

#' Generate a \code{.Rmd} file containing code to normalize data.
#' @param norm.method The between-sample normalization method used to compensate for varying library sizes and composition in the differential expression analysis. The normalization factors are calculated using the \code{calcNormFactors} of the \code{edgeR} package. Possible values are \code{"TMM"}, \code{"RLE"}, \code{"upperquartile"} and \code{"none"}
#' @param length.normalization one of "none" (no correction), "TPM", "RPKM" (default). See details.
#' @param data.transformation one of "log2", "asin(sqrt)" or "sqrt." Data transformation to apply to the normalized data.
#' @param codefile 
#' 
#' @details 
#' The \code{length.matrix} field of the \code{phyloCompData}
#' object is used to normalize the counts. 
#' \describe{
#' \item{\code{none}:}{No length normalization.}
#' \item{\code{TPM}:}{The raw counts are divided by the length of their associated genes before normalization by \code{voom}.}
#' \item{\code{RPKM}:}{The log2 length is substracted to the log2 CPM computed by \code{voom} for each gene and sample.}
#' }
#' 
#' @keywords internal
#' 
writeNormalization <- function(norm.method, length.normalization, data.transformation, codefile) {
  writeLines(c("", "# Normalisation"),codefile)
  length.normalization <- match.arg(length.normalization, c("RPKM", "TPM", "none"))
  data.transformation <- match.arg(data.transformation, c("log2", "asin(sqrt)", "sqrt"))
  if (length.normalization == "none") {
    writeLines(c(paste("nf <- edgeR::calcNormFactors(count.matrix(cdata), method = '", norm.method, "')", sep = ''),
                 "lib.size <- colSums(count.matrix(cdata)) * nf"),
               codefile)
    if (data.transformation == "log2") {
      writeLines("data.norm <- sweep(count.matrix(cdata) + 0.5, 2, lib.size + 1, '/')", codefile)
    } else {
      writeLines("data.norm <- sweep(count.matrix(cdata), 2, lib.size, '/')", codefile)
    }
    if (data.transformation != "asin(sqrt)") writeLines("data.norm <- data.norm * 1e6", codefile)
  } else if (length.normalization == "TPM") {
    writeLines(c(paste("nf <- edgeR::calcNormFactors(count.matrix(cdata) / length.matrix(cdata), method = '", norm.method, "')", sep = ''),
                 "lib.size <- colSums(count.matrix(cdata) / length.matrix(cdata)) * nf"),
               codefile)
    if (data.transformation == "log2") {
      writeLines("data.norm <- sweep((count.matrix(cdata) + 0.5) / length.matrix(cdata), 2, lib.size + 1, '/')", codefile)
    } else {
      writeLines("data.norm <- sweep((count.matrix(cdata)) / length.matrix(cdata), 2, lib.size, '/')", codefile)
    }
    if (data.transformation != "asin(sqrt)") writeLines("data.norm <- data.norm * 1e6", codefile)
  } else if (length.normalization == "RPKM") {
    writeLines(c(paste("nf <- edgeR::calcNormFactors(count.matrix(cdata), method = '", norm.method, "')", sep = ''),
                 "lib.size <- colSums(count.matrix(cdata)) * nf"),
               codefile)
    if (data.transformation == "log2") {
      writeLines("data.norm <- sweep((count.matrix(cdata) + 0.5) / length.matrix(cdata), 2, lib.size + 1, '/')", codefile)
    } else {
      writeLines("data.norm <- sweep((count.matrix(cdata)) / length.matrix(cdata), 2, lib.size, '/')", codefile)
    }
    if (data.transformation != "asin(sqrt)") writeLines("data.norm <- data.norm * 1e9", codefile)
  }
  writeLines(c("", "# Transformation"),codefile)
  if (data.transformation == "log2") {
    writeLines("data.trans <- log2(data.norm)", codefile)
  } else if (data.transformation == "asin(sqrt)") {
    writeLines("data.trans <- asin(sqrt(data.norm))", codefile)
  } else if (data.transformation == "sqrt") {
    writeLines("data.trans <- sqrt(data.norm)", codefile)
  }
  writeLines("rownames(data.trans) <- rownames(count.matrix(cdata))", codefile)
}