% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/runDiffExp.R
\name{runDiffExp}
\alias{runDiffExp}
\title{The main function to run differential expression analysis}
\usage{
runDiffExp(
  data.file,
  result.extent,
  Rmdfunction,
  output.directory = ".",
  norm.path = TRUE,
  ...
)
}
\arguments{
\item{data.file}{The path to a \code{.rds} file containing the data on which the differential expression analysis will be performed, for example a \code{compData} object returned from \code{\link{generateSyntheticData}}.}

\item{result.extent}{The extension that will be added to the data file name in order to construct the result file name. This can be for example the differential expression method together with a version number.}

\item{Rmdfunction}{A function that creates an Rmd file containing the code that should be run to perform the differential expression analysis. All functions available through \code{compcodeR} can be listed using the \code{\link{listcreateRmd}} function.}

\item{output.directory}{The directory in which the result object will be saved.}

\item{norm.path}{Logical, whether to include the full (absolute) path to the output object in the saved code.}

\item{...}{Additional arguments that will be passed to the \code{Rmdfunction}, such as parameter choices for the differential expression method.}
}
\description{
The main function for running differential expression analysis (comparing two conditions), using one of the methods interfaced through \code{compcodeR} or a user-defined method. Note that the interface functions are provided for convenience and as templates for other, user-defined workflows, and there is no guarantee that the included differential expression code is kept up-to-date with the latest recommendations and best practices for running each of the interfaced methods, or that the chosen settings are suitable in all situations. The user should make sure that the analysis is performed in the way they intend, and check the code that was run, using e.g. the \code{generateCodeHTMLs()} function.
}
\examples{
tmpdir <- normalizePath(tempdir(), winslash = "/")
mydata.obj <- generateSyntheticData(dataset = "mydata", n.vars = 1000,
                                    samples.per.cond = 5, n.diffexp = 100,
                                    output.file = file.path(tmpdir, "mydata.rds"))
listcreateRmd()
runDiffExp(data.file = file.path(tmpdir, "mydata.rds"), result.extent = "voom.limma",
           Rmdfunction = "voom.limma.createRmd",
           output.directory = tmpdir, norm.method = "TMM")

if (interactive()) {
## The following list covers the currently available
## differential expression methods:
runDiffExp(data.file = "mydata.rds", result.extent = "DESeq2",
           Rmdfunction = "DESeq2.createRmd",
           output.directory = ".", fit.type = "parametric",
           test = "Wald", beta.prior = TRUE,
           independent.filtering = TRUE, cooks.cutoff = TRUE,
           impute.outliers = TRUE)
runDiffExp(data.file = "mydata.rds", result.extent = "DSS",
           Rmdfunction = "DSS.createRmd",
           output.directory = ".", norm.method = "quantile",
           disp.trend = TRUE)
runDiffExp(data.file = "mydata.rds", result.extent = "EBSeq",
           Rmdfunction = "EBSeq.createRmd",
           output.directory = ".", norm.method = "median")
runDiffExp(data.file = "mydata.rds", result.extent = "edgeR.exact",
           Rmdfunction = "edgeR.exact.createRmd",
           output.directory = ".", norm.method = "TMM",
           trend.method = "movingave", disp.type = "tagwise")
runDiffExp(data.file = "mydata.rds", result.extent = "edgeR.GLM",
           Rmdfunction = "edgeR.GLM.createRmd",
           output.directory = ".", norm.method = "TMM",
           disp.type = "tagwise", disp.method = "CoxReid",
           trended = TRUE)
runDiffExp(data.file = "mydata.rds", result.extent = "logcpm.limma",
           Rmdfunction = "logcpm.limma.createRmd",
           output.directory = ".", norm.method = "TMM")
runDiffExp(data.file = "mydata.rds", result.extent = "NBPSeq",
           Rmdfunction = "NBPSeq.createRmd",
           output.directory = ".", norm.method = "TMM",
           disp.method = "NBP")
runDiffExp(data.file = "mydata.rds", result.extent = "NOISeq",
           Rmdfunction = "NOISeq.prenorm.createRmd",
           output.directory = ".", norm.method = "TMM")
runDiffExp(data.file = "mydata.rds", result.extent = "sqrtcpm.limma",
           Rmdfunction = "sqrtcpm.limma.createRmd",
           output.directory = ".", norm.method = "TMM")
runDiffExp(data.file = "mydata.rds", result.extent = "TCC",
           Rmdfunction = "TCC.createRmd",
           output.directory = ".", norm.method = "tmm",
           test.method = "edger", iteration = 3,
           normFDR = 0.1, floorPDEG = 0.05)
runDiffExp(data.file = "mydata.rds", result.extent = "ttest",
           Rmdfunction = "ttest.createRmd",
           output.directory = ".", norm.method = "TMM")
runDiffExp(data.file = "mydata.rds", result.extent = "voom.limma",
           Rmdfunction = "voom.limma.createRmd",
           output.directory = ".", norm.method = "TMM")
runDiffExp(data.file = "mydata.rds", result.extent = "voom.ttest",
           Rmdfunction = "voom.ttest.createRmd",
           output.directory = ".", norm.method = "TMM")
}
}
\author{
Charlotte Soneson
}
