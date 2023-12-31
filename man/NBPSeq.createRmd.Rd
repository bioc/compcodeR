% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/generateRmdCodeDiffExp.R
\name{NBPSeq.createRmd}
\alias{NBPSeq.createRmd}
\title{Generate a \code{.Rmd} file containing code to perform differential expression analysis with NBPSeq}
\usage{
NBPSeq.createRmd(data.path, result.path, codefile, norm.method, disp.method)
}
\arguments{
\item{data.path}{The path to a .rds file containing the \code{compData} object that will be used for the differential expression analysis.}

\item{result.path}{The path to the file where the result object will be saved.}

\item{codefile}{The path to the file where the code will be written.}

\item{norm.method}{The between-sample normalization method used to compensate for varying library sizes and composition in the differential expression analysis. The normalization factors are calculated using the \code{calcNormFactors} function from the \code{edgeR} package. Possible values are \code{"TMM"}, \code{"RLE"}, \code{"upperquartile"} and \code{"none"}.}

\item{disp.method}{The method to use to estimate the dispersion values. Possible values are \code{"NBP"} and \code{"NB2"}.}
}
\value{
The function generates a \code{.Rmd} file containing the code for performing the differential expression analysis. This file can be executed using e.g. the \code{knitr} package.
}
\description{
A function to generate code that can be run to perform differential expression analysis of RNAseq data (comparing two conditions) using \code{NBPSeq}. The code is written to a \code{.Rmd} file. This function is generally not called by the user, the main interface for performing differential expression analysis is the \code{\link{runDiffExp}} function.
}
\details{
For more information about the methods and the interpretation of the parameters, see the \code{NBPSeq} and \code{edgeR} packages and the corresponding publications.
}
\examples{
try(
if (require(NBPSeq)) {
tmpdir <- normalizePath(tempdir(), winslash = "/")
mydata.obj <- generateSyntheticData(dataset = "mydata", n.vars = 1000,
                                    samples.per.cond = 5, n.diffexp = 100,
                                    output.file = file.path(tmpdir, "mydata.rds"))
runDiffExp(data.file = file.path(tmpdir, "mydata.rds"), result.extent = "NBPSeq",
           Rmdfunction = "NBPSeq.createRmd",
           output.directory = tmpdir, norm.method = "TMM", disp.method = "NBP")
})
}
\references{
Robinson MD, McCarthy DJ and Smyth GK (2010): edgeR: a Bioconductor package for differential expression analysis of digital gene expression data. Bioinformatics 26, 139-140

Robinson MD and Oshlack A (2010): A scaling normalization method for differential expression analysis of RNA-seq data. Genome Biology 11:R25

Di Y, Schafer DW, Cumbie JS, and Chang JH (2011): The NBP Negative Binomial Model for Assessing Differential Gene Expression from RNA-Seq. Statistical Applications in Genetics and Molecular Biology 10(1), 1-28
}
\author{
Charlotte Soneson
}
