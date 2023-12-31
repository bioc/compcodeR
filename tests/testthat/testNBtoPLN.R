context("Negative Binomial to Poisson Log Normal")

test_that("NB to PLN simple", {
  set.seed(18420318)
  
  n <- 20000000
  
  ## NB
  mean_nb <- 500
  dispersion_nb <- 0.2
  
  sd_nb <- sqrt(mean_nb + dispersion_nb * mean_nb^2)
  
  sample_nb <- rnbinom(n = n,
                       mu = mean_nb, 
                       size = 1 / dispersion_nb)
  
  ## PLN
  params_PLN <- NB_to_PLN(mean_nb, dispersion_nb)
  
  sample_ln <- rnorm(n = n,
                      mean = params_PLN$log_means_pln,
                      sd = sqrt(params_PLN$log_variances_pln))
  sample_pln <- rpois(n, exp(sample_ln))
  
  ## Comparison
  expect_equal(mean(sample_nb) - mean_nb, 0, tolerance = 0.05)
  expect_equal(sd(sample_nb) - sd_nb, 0, tolerance = 0.05)
  
  expect_equal(mean(sample_pln) - mean_nb, 0, tolerance = 0.05)
  expect_equal(sd(sample_pln) - sd_nb, 0, tolerance = 0.07)
})

test_that("NB to PLN phylo - errors", {
  skip_if_not_installed("phylolm")
  
  set.seed(18420318)
  
  ## Parameters
  n <- 20
  ntaxa <- 8
  
  ## Tree
  tree <- ape::read.tree(text = "(((A1:0,A2:0,A3:0):1,B1:1):1,((C1:0,C2:0):1.5,(D1:0,D2:0):1.5):0.5);")

  ## NB
  mean_nb <- 1:ntaxa * 100
  dispersion_nb <- 1:ntaxa/2 / 100
  
  sd_nb <- sqrt(mean_nb + dispersion_nb * mean_nb^2)
  
  sample_nb <- t(matrix(rnbinom(n = ntaxa * n,
                                mu = mean_nb, 
                                size = 1 / dispersion_nb), nrow = ntaxa))
  
  ## PLN
  names(mean_nb) <- tree$tip.label
  names(dispersion_nb) <- tree$tip.label
  
  expect_error(get_poisson_log_normal_parameters(rep(1, n) %*% t(mean_nb), rep(1, n) %*% t(dispersion_nb), 1.2),
               "`prop.var.tree` should be between 0 and 1.")
  
  expect_error(get_poisson_log_normal_parameters(rep(1, n) %*% t(mean_nb), rep(1, n) %*% t(dispersion_nb), c(0.1, 0.2)),
               "should be a vector of length the number of genes")
  
  expect_error(get_poisson_log_normal_parameters(rep(1, n) %*% t(mean_nb), rep(1, n) %*% t(dispersion_nb), matrix(0.1, 2, 2)),
               "`prop.var.tree` should be a vector")
  
  params_PLN <- get_poisson_log_normal_parameters(rep(1, n) %*% t(mean_nb), rep(1, n) %*% t(dispersion_nb), 1.0)
  
  expect_error(simulatePhyloPoissonLogNormal(tree, params_PLN$log_means[1:10, ], params_PLN$log_variance_phylo, params_PLN$log_variance_sample),
               "`log_means` and `log_variance_sample should have as many rows as the length of `log_variance_phylo`.")
  
  expect_error(simulatePhyloPoissonLogNormal(tree, params_PLN$log_means[, 3:8], params_PLN$log_variance_phylo, params_PLN$log_variance_sample),
               "log means` should have as many columns as the number of taxa in the tree.")
  
  expect_warning(simulatePhyloPoissonLogNormal(tree, params_PLN$log_means[, c(2, 1, 3:8)], params_PLN$log_variance_phylo, params_PLN$log_variance_sample),
               "`log means` was not sorted in the correct order, when compared with the tips label. I am re-ordering it.")
  
  pplm <- params_PLN$log_means
  colnames(pplm) <- c("W", colnames(params_PLN$log_means[, 2:8]))
  expect_error(simulatePhyloPoissonLogNormal(tree, pplm, params_PLN$log_variance_phylo, params_PLN$log_variance_sample),
                 "`log means` names do not match the tip labels.")
  
  
})

test_that("NB to PLN phylo - star tree", {
  skip_if_not_installed("phangorn")
  skip_if_not_installed("phylolm")
  
  set.seed(18420318)
  
  ## Parameters
  n <- 200000
  ntaxa <- 4
  
  ## Tree
  tree <- ape::stree(ntaxa, type = "star")
  tree <- ape::compute.brlen(tree, runif, min = 0, max = 1)
  tree <- phangorn::nnls.tree(ape::cophenetic.phylo(tree), tree, rooted = TRUE, trace = 0) # force ultrametric
  tree$edge.length <- tree$edge.length / max(ape::node.depth.edgelength(tree))
  
  ## NB
  mean_nb <- 1:ntaxa * 100
  dispersion_nb <- 1:ntaxa/2 / 100
  
  sd_nb <- sqrt(mean_nb + dispersion_nb * mean_nb^2)
  
  sample_nb <- t(matrix(rnbinom(n = ntaxa * n,
                                mu = mean_nb, 
                                size = 1 / dispersion_nb), nrow = ntaxa))
  
  ## PLN
  names(mean_nb) <- tree$tip.label
  names(dispersion_nb) <- tree$tip.label
  
  params_PLN <- get_poisson_log_normal_parameters(rep(1, n) %*% t(mean_nb), rep(1, n) %*% t(dispersion_nb), 1.0)
  
  sample_ppln <- simulatePhyloPoissonLogNormal(tree, params_PLN$log_means, params_PLN$log_variance_phylo, params_PLN$log_variance_sample)
  
  sample_ln <- sample_ppln$log_lambda
  sample_pln <- sample_ppln$counts
  rm(sample_ppln)
  
  mean_ln <- params_PLN$log_means[1, ]
  sd_ln <- sqrt((params_PLN$log_variance_phylo + params_PLN$log_variance_sample)[1, ])
  
  ## Comparisons NB
  expect_equivalent(colMeans(sample_nb) - mean_nb, rep(0, ntaxa), tolerance = 0.05)
  expect_equivalent(matrixStats::colSds(sample_nb) - sd_nb, rep(0, ntaxa), tolerance = 0.05)
  
  ## Comparison log lambda
  expect_equivalent(colMeans(sample_ln) - mean_ln, rep(0, ntaxa), tolerance = 0.05)
  expect_equivalent(matrixStats::colSds(sample_ln) - sd_ln, rep(0, ntaxa), tolerance = 0.05)
  
  ## Comparisons PLN
  expect_equivalent(colMeans(sample_pln) - mean_nb, rep(0, ntaxa), tolerance = 0.1)
  expect_equivalent(matrixStats::colSds(sample_pln) - sd_nb, rep(0, ntaxa), tolerance = 0.1)
})

test_that("NB to PLN phylo - random tree", {
  skip_if_not_installed("phangorn")
  skip_if_not_installed("phylolm")
  
  set.seed(18420318)
  
  ## Parameters
  n <- 1000000
  ntaxa <- 4
  
  ## Tree
  tree <- ape::rtree(ntaxa)
  tree <- ape::compute.brlen(tree, runif, min = 0, max = 1)
  tree <- phangorn::nnls.tree(ape::cophenetic.phylo(tree), tree, rooted = TRUE, trace = 0) # force ultrametric
  tree$edge.length <- tree$edge.length / max(ape::node.depth.edgelength(tree))
  
  ## NB
  mean_nb <- 1:ntaxa * 100
  dispersion_nb <- 1:ntaxa/2 / 100
  
  sd_nb <- sqrt(mean_nb + dispersion_nb * mean_nb^2)
  
  sample_nb <- t(matrix(rnbinom(n = ntaxa * n,
                                mu = mean_nb, 
                                size = 1 / dispersion_nb), nrow = ntaxa))
  
  ## PLN
  names(mean_nb) <- tree$tip.label
  names(dispersion_nb) <- tree$tip.label
  
  prop.var.tree <- 1.0
  
  params_PLN <- get_poisson_log_normal_parameters(rep(1, n) %*% t(mean_nb), rep(1, n) %*% t(dispersion_nb), prop.var.tree)
  
  sample_ppln <- simulatePhyloPoissonLogNormal(tree, params_PLN$log_means, params_PLN$log_variance_phylo, params_PLN$log_variance_sample)
  
  sample_ln <- sample_ppln$log_lambda
  sample_pln <- sample_ppln$counts
  rm(sample_ppln)
  
  mean_ln <- params_PLN$log_means[1, ]
  sd_ln <- sqrt((params_PLN$log_variance_phylo + params_PLN$log_variance_sample)[1, ])
  
  ## Comparisons NB
  expect_equivalent(colMeans(sample_nb) - mean_nb, rep(0, ntaxa), tolerance = 0.05)
  expect_equivalent(matrixStats::colSds(sample_nb) - sd_nb, rep(0, ntaxa), tolerance = 0.05)
  
  ## Comparison log lambda
  expect_equivalent(colMeans(sample_ln) - mean_ln, rep(0, ntaxa), tolerance = 0.05)
  expect_equivalent(matrixStats::colSds(sample_ln) - sd_ln, rep(0, ntaxa), tolerance = 0.05)
  
  ## Comparisons PLN
  expect_equivalent(colMeans(sample_pln) - mean_nb, rep(0, ntaxa), tolerance = 0.1)
  expect_equivalent(matrixStats::colSds(sample_pln) - sd_nb, rep(0, ntaxa), tolerance = 0.1)
  
  ## Phylogenetic covariances
  C_tree <- ape::vcv(tree)
  V_ln <- C_tree * params_PLN$log_variance_phylo[1] + diag(params_PLN$log_variance_sample[1, ])
  for (i in 1:(ntaxa-1)) {
    for (j in (i+1):ntaxa) {
      if (V_ln[i, j] != 0) {
        expect_equivalent(cov(sample_ln[, i], sample_ln[, j]), V_ln[i, j], tolerance = 0.0001, scale = V_ln[i, j])
      } else {
        expect_equivalent(cov(sample_ln[, i], sample_ln[, j]) - V_ln[i, j], 0, tolerance = 0.0001)
      }
    }
  }
  
  ## Phylogenetic covariances - Pagel
  V_ln_pagel <- (params_PLN$log_variance_phylo[1] + params_PLN$log_variance_sample[1, 1]) * ape::vcv(phylolm::transf.branch.lengths(tree, model = "lambda", list(lambda = prop.var.tree))$tree)
  for (i in 1:(ntaxa-1)) {
    for (j in (i+1):ntaxa) {
      expect_equal(V_ln_pagel[i, j], V_ln[i, j], scale = V_ln[i, j])
    }
  }
  
  ## Phylogenetic covariances for Counts
  V_tot <- (exp(V_ln) - 1) * mean_nb %*% t(mean_nb)
  for (i in 1:(ntaxa-1)) {
    for (j in (i+1):ntaxa) {
      if (V_tot[i, j] != 0) {
        expect_equivalent(cov(sample_pln[, i], sample_pln[, j]), V_tot[i, j], tolerance = 0.1, scale = V_tot[i, j])
      } else {
        expect_equivalent(cov(sample_pln[, i], sample_pln[, j]) - V_tot[i, j], 0, tolerance = 1.0)
      }
    }
  }
})

test_that("NB to PLN phylo - star tree with repetitions", {
  skip_if_not_installed("phangorn")
  skip_if_not_installed("phytools")
  skip_if_not_installed("phylolm")
  
  set.seed(18420318)
  
  ## Parameters
  n <- 3000000
  ntaxa <- 2
  
  ## Tree
  tree <- ape::stree(ntaxa, type = "star")
  tree <- ape::compute.brlen(tree, 1.0)
  
  ## Repetitions
  r <- 2
  ntaxa <- r * ntaxa
  
  tree <- add_replicates(tree, r)
  
  ## NB
  mean_nb <- 1:ntaxa * 100
  dispersion_nb <- 1:ntaxa/2 / 100
  
  sd_nb <- sqrt(mean_nb + dispersion_nb * mean_nb^2)
  
  sample_nb <- t(matrix(rnbinom(n = ntaxa * n,
                                mu = mean_nb, 
                                size = 1 / dispersion_nb), nrow = ntaxa))
  
  ## PLN
  names(mean_nb) <- tree$tip.label
  names(dispersion_nb) <- tree$tip.label
  
  prop.var.tree <- 0.5
  
  params_PLN <- get_poisson_log_normal_parameters(rep(1, n) %*% t(mean_nb), rep(1, n) %*% t(dispersion_nb), prop.var.tree)
  
  sample_ppln <- simulatePhyloPoissonLogNormal(tree, params_PLN$log_means, params_PLN$log_variance_phylo, params_PLN$log_variance_sample)
  
  sample_ln <- sample_ppln$log_lambda
  sample_pln <- sample_ppln$counts
  rm(sample_ppln)
  
  mean_ln <- params_PLN$log_means[1, ]
  sd_ln <- sqrt((params_PLN$log_variance_phylo + params_PLN$log_variance_sample)[1, ])
  
  ## Comparisons NB
  expect_equivalent(colMeans(sample_nb) - mean_nb, rep(0, ntaxa), tolerance = 0.05)
  expect_equivalent(matrixStats::colSds(sample_nb) - sd_nb, rep(0, ntaxa), tolerance = 0.05)
  
  ## Comparison log lambda
  expect_equivalent(colMeans(sample_ln) - mean_ln, rep(0, ntaxa), tolerance = 0.05)
  expect_equivalent(matrixStats::colSds(sample_ln) - sd_ln, rep(0, ntaxa), tolerance = 0.05)
  
  ## Comparisons PLN
  expect_equivalent(colMeans(sample_pln) - mean_nb, rep(0, ntaxa), tolerance = 0.1)
  expect_equivalent(matrixStats::colSds(sample_pln) - sd_nb, rep(0, ntaxa), tolerance = 0.1)
  
  ## Phylogenetic covariances
  C_tree <- ape::vcv(tree)
  V_ln <- C_tree * params_PLN$log_variance_phylo[1] + diag(params_PLN$log_variance_sample[1, ])
  for (i in 1:(ntaxa-1)) {
    for (j in (i+1):ntaxa) {
      if (V_ln[i, j] != 0) {
        expect_equivalent(cov(sample_ln[, i], sample_ln[, j]), V_ln[i, j], tolerance = 0.0001, scale = V_ln[i, j])
      } else {
        expect_equivalent(cov(sample_ln[, i], sample_ln[, j]) - V_ln[i, j], 0, tolerance = 0.0001)
      }
    }
  }
  
  ## Phylogenetic covariances - Pagel
  V_ln_pagel <- (params_PLN$log_variance_phylo[1] + params_PLN$log_variance_sample[1, 1]) * ape::vcv(phylolm::transf.branch.lengths(tree, model = "lambda", list(lambda = prop.var.tree))$tree)
  for (i in 1:(ntaxa-1)) {
    for (j in (i+1):ntaxa) {
        expect_equal(V_ln_pagel[i, j], V_ln[i, j], scale = V_ln[i, j])
    }
  }
  
  ## Phylogenetic covariances for Counts
  V_tot <- (exp(V_ln) - 1) * mean_nb %*% t(mean_nb)
  for (i in 1:(ntaxa-1)) {
    for (j in (i+1):ntaxa) {
      if (V_tot[i, j] != 0) {
        expect_equivalent(cov(sample_pln[, i], sample_pln[, j]), V_tot[i, j], tolerance = 0.05, scale = V_tot[i, j])
      } else {
        expect_equivalent(cov(sample_pln[, i], sample_pln[, j]) - V_tot[i, j], 0, tolerance = 0.6)
      }
    }
  }
})

test_that("NB to PLN phylo - random tree - OU", {
  skip_if_not_installed("phangorn")
  skip_if_not_installed("phylolm")
  
  set.seed(18420318)
  
  ## Parameters
  n <- 3000000
  ntaxa <- 4
  selection.strength <- 1
  
  ## Tree
  tree <- ape::rtree(ntaxa)
  tree <- ape::compute.brlen(tree, runif, min = 0, max = 1)
  tree <- phangorn::nnls.tree(ape::cophenetic.phylo(tree), tree, rooted = TRUE, trace = 0) # force ultrametric
  tree_height <- ape::vcv(tree)[1, 1]
  
  ## NB
  mean_nb <- 1:ntaxa * 100
  dispersion_nb <- 1:ntaxa/2 / 100
  
  sd_nb <- sqrt(mean_nb + dispersion_nb * mean_nb^2)
  
  sample_nb <- t(matrix(rnbinom(n = ntaxa * n,
                                mu = mean_nb, 
                                size = 1 / dispersion_nb), nrow = ntaxa))
  
  ## PLN
  names(mean_nb) <- tree$tip.label
  names(dispersion_nb) <- tree$tip.label
  
  prop.var.tree <- 0.7
  
  params_PLN <- get_poisson_log_normal_parameters(rep(1, n) %*% t(mean_nb), rep(1, n) %*% t(dispersion_nb), prop.var.tree)
  
  sample_ppln <- simulatePhyloPoissonLogNormal(tree,
                                               params_PLN$log_means,
                                               params_PLN$log_variance_phylo,
                                               params_PLN$log_variance_sample,
                                               model.process = "OU",
                                               selection.strength = selection.strength)
  
  sample_ln <- sample_ppln$log_lambda
  sample_pln <- sample_ppln$counts
  rm(sample_ppln)
  
  mean_ln <- params_PLN$log_means[1, ]
  sd_ln <- sqrt((params_PLN$log_variance_phylo + params_PLN$log_variance_sample)[1, ])
  
  ## Comparisons NB
  expect_equivalent(colMeans(sample_nb) - mean_nb, rep(0, ntaxa), tolerance = 0.05)
  expect_equivalent(matrixStats::colSds(sample_nb) - sd_nb, rep(0, ntaxa), tolerance = 0.05)
  
  ## Comparison log lambda
  expect_equivalent(colMeans(sample_ln) - mean_ln, rep(0, ntaxa), tolerance = 0.05)
  expect_equivalent(matrixStats::colSds(sample_ln) - sd_ln, rep(0, ntaxa), tolerance = 0.05)
  
  ## Comparisons PLN
  expect_equivalent(colMeans(sample_pln) - mean_nb, rep(0, ntaxa), tolerance = 0.1)
  expect_equivalent(matrixStats::colSds(sample_pln) - sd_nb, rep(0, ntaxa), tolerance = 0.1)
  
  ## Phylogenetic covariances
  C_tree <- ape::vcv(phylolm::transf.branch.lengths(tree, model = "OUfixedRoot", parameters = list(alpha = selection.strength))$tree)
  V_ln <- C_tree * params_PLN$log_variance_phylo[1] / -expm1(-2 * selection.strength * tree_height) + diag(params_PLN$log_variance_sample[1, ])
  for (i in 1:(ntaxa-1)) {
    for (j in (i+1):ntaxa) {
      if (V_ln[i, j] != 0) {
        expect_equivalent(cov(sample_ln[, i], sample_ln[, j]), V_ln[i, j], tolerance = 0.00001, scale = V_ln[i, j])
      } else {
        expect_equivalent(cov(sample_ln[, i], sample_ln[, j]) - V_ln[i, j], 0, tolerance = 0.0001)
      }
    }
  }
  
  ## Phylogenetic covariances for Counts
  V_tot <- (exp(V_ln) - 1) * mean_nb %*% t(mean_nb)
  for (i in 1:(ntaxa-1)) {
    for (j in (i+1):ntaxa) {
      if (V_tot[i, j] != 0) {
        expect_equivalent(cov(sample_pln[, i], sample_pln[, j]), V_tot[i, j], tolerance = 0.06, scale = V_tot[i, j])
      } else {
        expect_equivalent(cov(sample_pln[, i], sample_pln[, j]) - V_tot[i, j], 0, tolerance = 1.0)
      }
    }
  }
})

test_that("NB to PLN phylo - random tree - Not Unit Length", {
  skip_if_not_installed("phangorn")
  skip_if_not_installed("phylolm")
  
  set.seed(18420318)
  
  ## Parameters
  n <- 4000000
  ntaxa <- 4
  selection.strength <- 1
  
  ## Tree
  tree <- ape::rtree(ntaxa)
  tree <- ape::compute.brlen(tree, runif, min = 0, max = 1)
  tree <- phangorn::nnls.tree(ape::cophenetic.phylo(tree), tree, rooted = TRUE, trace = 0) # force ultrametric
  tree_height <- ape::vcv(tree)[1, 1]

  ## NB
  mean_nb <- 1:ntaxa * 100
  dispersion_nb <- 1:ntaxa/2 / 100
  
  sd_nb <- sqrt(mean_nb + dispersion_nb * mean_nb^2)
  
  sample_nb <- t(matrix(rnbinom(n = ntaxa * n,
                                mu = mean_nb, 
                                size = 1 / dispersion_nb), nrow = ntaxa))
  
  ## PLN
  names(mean_nb) <- tree$tip.label
  names(dispersion_nb) <- tree$tip.label
  
  prop.var.tree <- 1.0
  
  params_PLN <- get_poisson_log_normal_parameters(rep(1, n) %*% t(mean_nb), rep(1, n) %*% t(dispersion_nb), prop.var.tree)
  
  sample_ppln <- simulatePhyloPoissonLogNormal(tree,
                                               params_PLN$log_means,
                                               params_PLN$log_variance_phylo,
                                               params_PLN$log_variance_sample)
  
  sample_ln <- sample_ppln$log_lambda
  sample_pln <- sample_ppln$counts
  rm(sample_ppln)
  
  mean_ln <- params_PLN$log_means[1, ]
  sd_ln <- sqrt((params_PLN$log_variance_phylo + params_PLN$log_variance_sample)[1, ])
  
  ## Comparisons NB
  expect_equivalent(colMeans(sample_nb) - mean_nb, rep(0, ntaxa), tolerance = 0.05)
  expect_equivalent(matrixStats::colSds(sample_nb) - sd_nb, rep(0, ntaxa), tolerance = 0.05)
  
  ## Comparison log lambda
  expect_equivalent(colMeans(sample_ln) - mean_ln, rep(0, ntaxa), tolerance = 0.05)
  expect_equivalent(matrixStats::colSds(sample_ln) - sd_ln, rep(0, ntaxa), tolerance = 0.05)
  
  ## Comparisons PLN
  expect_equivalent(colMeans(sample_pln) - mean_nb, rep(0, ntaxa), tolerance = 0.1)
  expect_equivalent(matrixStats::colSds(sample_pln) - sd_nb, rep(0, ntaxa), tolerance = 0.1)
  
  ## Phylogenetic covariances
  C_tree <- ape::vcv(tree)
  V_ln <- C_tree * params_PLN$log_variance_phylo[1] / tree_height + diag(params_PLN$log_variance_sample[1, ])
  for (i in 1:(ntaxa-1)) {
    for (j in (i+1):ntaxa) {
      if (V_ln[i, j] != 0) {
        expect_equivalent(cov(sample_ln[, i], sample_ln[, j]), V_ln[i, j], tolerance = 0.0001, scale = V_ln[i, j])
      } else {
        expect_equivalent(cov(sample_ln[, i], sample_ln[, j]) - V_ln[i, j], 0, tolerance = 0.0001)
      }
    }
  }
  
  ## Phylogenetic covariances - Pagel
  V_ln_pagel <- (params_PLN$log_variance_phylo[1] * tree_height / prop.var.tree) * ape::vcv(phylolm::transf.branch.lengths(tree, model = "lambda", list(lambda = prop.var.tree))$tree)
  for (i in 1:(ntaxa-1)) {
    for (j in (i+1):ntaxa) {
      expect_equal(V_ln_pagel[i, j], V_ln[i, j], tolerance = 1e-4)
    }
  }
  
  ## Phylogenetic covariances for Counts
  V_tot <- (exp(V_ln) - 1) * mean_nb %*% t(mean_nb)
  for (i in 1:(ntaxa-1)) {
    for (j in (i+1):ntaxa) {
      if (V_tot[i, j] != 0) {
        expect_equivalent(cov(sample_pln[, i], sample_pln[, j]), V_tot[i, j], tolerance = 0.06, scale = V_tot[i, j])
      } else {
        expect_equivalent(cov(sample_pln[, i], sample_pln[, j]) - V_tot[i, j], 0, tolerance = 1.0)
      }
    }
  }
})

test_that("NB to PLN phylo - random tree - Not Unit Length - With Rep - Uniform disp", {
  skip_if_not_installed("phangorn")
  skip_if_not_installed("phylolm")
  
  set.seed(18420318)
  
  ## Parameters
  n <- 1
  ntaxa <- 10
  selection.strength <- 1
  
  ## Tree
  tree <- ape::rtree(ntaxa)
  tree <- ape::compute.brlen(tree, runif, min = 0, max = 1)
  tree <- phangorn::nnls.tree(ape::cophenetic.phylo(tree), tree, rooted = TRUE, trace = 0) # force ultrametric
  tree_height <- ape::vcv(tree)[1, 1]
  
  ## Repetitions
  r <- 2
  ntaxa <- r * ntaxa
  tree <- add_replicates(tree, r)
  
  ## NB
  mean_nb <- 1:ntaxa * 100
  dispersion_nb <- rep(1,ntaxa)/2 / 100
  
  sd_nb <- sqrt(mean_nb + dispersion_nb * mean_nb^2)
  
  sample_nb <- t(matrix(rnbinom(n = ntaxa * n,
                                mu = mean_nb, 
                                size = 1 / dispersion_nb), nrow = ntaxa))
  
  ## PLN
  names(mean_nb) <- tree$tip.label
  names(dispersion_nb) <- tree$tip.label
  
  prop.var.tree <- 0.6
  
  params_PLN <- get_poisson_log_normal_parameters(rep(1, n) %*% t(mean_nb), rep(1, n) %*% t(dispersion_nb), prop.var.tree)
  
  sample_ppln <- simulatePhyloPoissonLogNormal(tree,
                                               params_PLN$log_means,
                                               params_PLN$log_variance_phylo,
                                               params_PLN$log_variance_sample)
  
  sample_ln <- sample_ppln$log_lambda
  sample_pln <- sample_ppln$counts
  rm(sample_ppln)
  
  mean_ln <- params_PLN$log_means[1, ]
  sd_ln <- sqrt((params_PLN$log_variance_phylo + params_PLN$log_variance_sample)[1, ])
  

  ## Phylogenetic covariances
  C_tree <- ape::vcv(tree)
  V_ln <- C_tree * params_PLN$log_variance_phylo[1] / tree_height + diag(params_PLN$log_variance_sample[1, ])
  
  ## Phylogenetic covariances - Pagel
  V_ln_pagel <- (params_PLN$log_variance_phylo[1] / tree_height / prop.var.tree) * ape::vcv(phylolm::transf.branch.lengths(tree, model = "lambda", list(lambda = prop.var.tree))$tree)
  expect_equal(V_ln_pagel, V_ln)
  
})

test_that("NB to PLN phylo - random tree - OU - Not Unit Length - With Rep - Uniform disp", {
  skip_if_not_installed("phangorn")
  skip_if_not_installed("phylolm")
  
  set.seed(18420318)
  
  ## Parameters
  n <- 1
  ntaxa <- 10
  selection.strength <- 1
  
  ## Tree
  tree <- ape::rtree(ntaxa)
  tree <- ape::compute.brlen(tree, runif, min = 0, max = 1)
  tree <- phangorn::nnls.tree(ape::cophenetic.phylo(tree), tree, rooted = TRUE, trace = 0) # force ultrametric
  tree_height <- ape::vcv(tree)[1, 1]
  
  ## Repetitions
  r <- 2
  ntaxa <- r * ntaxa
  tree <- add_replicates(tree, r)
  
  ## NB
  mean_nb <- 1:ntaxa * 100
  dispersion_nb <- rep(1,ntaxa)/2 / 100
  
  sd_nb <- sqrt(mean_nb + dispersion_nb * mean_nb^2)
  
  sample_nb <- t(matrix(rnbinom(n = ntaxa * n,
                                mu = mean_nb, 
                                size = 1 / dispersion_nb), nrow = ntaxa))
  
  ## PLN
  names(mean_nb) <- tree$tip.label
  names(dispersion_nb) <- tree$tip.label
  
  prop.var.tree <- 0.6
  
  params_PLN <- get_poisson_log_normal_parameters(rep(1, n) %*% t(mean_nb), rep(1, n) %*% t(dispersion_nb), prop.var.tree)
  
  sample_ppln <- simulatePhyloPoissonLogNormal(tree,
                                               params_PLN$log_means,
                                               params_PLN$log_variance_phylo,
                                               params_PLN$log_variance_sample,
                                               model.process = "OU",
                                               selection.strength = selection.strength)
  
  sample_ln <- sample_ppln$log_lambda
  sample_pln <- sample_ppln$counts
  rm(sample_ppln)
  
  mean_ln <- params_PLN$log_means[1, ]
  sd_ln <- sqrt((params_PLN$log_variance_phylo + params_PLN$log_variance_sample)[1, ])
  
  
  ## Phylogenetic covariances
  C_tree <- ape::vcv(phylolm::transf.branch.lengths(tree, model = "OUfixedRoot", parameters = list(alpha = selection.strength))$tree)
  V_ln <- C_tree * params_PLN$log_variance_phylo[1] / -expm1(-2 * selection.strength * tree_height) + diag(params_PLN$log_variance_sample[1, ])
  
  ## Phylogenetic covariances - Pagel
  tree_ou <- phylolm::transf.branch.lengths(tree, model = "OUfixedRoot", list(alpha = selection.strength))$tree
  V_ln_pagel <- (params_PLN$log_variance_phylo[1] / -expm1(-2 * selection.strength * tree_height) / prop.var.tree) * ape::vcv(phylolm::transf.branch.lengths(tree_ou, model = "lambda", list(lambda = prop.var.tree))$tree)
  
  expect_equal(V_ln_pagel, V_ln)
  
})

test_that("NB to PLN phylo - random tree - variable prop.var.tree", {
  skip_if_not_installed("phangorn")
  skip_if_not_installed("phylolm")
  
  set.seed(18420318)
  
  ## Parameters
  n <- 10000
  ntaxa <- 4
  
  ## Tree
  tree <- ape::rtree(ntaxa)
  tree <- ape::compute.brlen(tree, runif, min = 0, max = 1)
  tree <- phangorn::nnls.tree(ape::cophenetic.phylo(tree), tree, rooted = TRUE, trace = 0) # force ultrametric
  tree$edge.length <- tree$edge.length / max(ape::node.depth.edgelength(tree))
  
  ## NB
  mean_nb <- 1:ntaxa * 100
  dispersion_nb <- 1:ntaxa/2 / 100
  
  sd_nb <- sqrt(mean_nb + dispersion_nb * mean_nb^2)
  
  sample_nb <- t(matrix(rnbinom(n = ntaxa * n,
                                mu = mean_nb, 
                                size = 1 / dispersion_nb), nrow = ntaxa))
  
  ## PLN
  names(mean_nb) <- tree$tip.label
  names(dispersion_nb) <- tree$tip.label
  
  prop.var.tree <- runif(n)
  
  params_PLN <- get_poisson_log_normal_parameters(rep(1, n) %*% t(mean_nb), rep(1, n) %*% t(dispersion_nb), prop.var.tree)
  
  sample_ppln <- simulatePhyloPoissonLogNormal(tree, params_PLN$log_means, params_PLN$log_variance_phylo, params_PLN$log_variance_sample)
  
  sample_ln <- sample_ppln$log_lambda
  sample_pln <- sample_ppln$counts
  rm(sample_ppln)
  
  mean_ln <- params_PLN$log_means[1, ]
  sd_ln <- sqrt((params_PLN$log_variance_phylo + params_PLN$log_variance_sample)[1, ])
  
  ## Comparisons NB
  expect_equivalent(colMeans(sample_nb), mean_nb, tolerance = 0.001)
  expect_equivalent(matrixStats::colSds(sample_nb), sd_nb, tolerance = 0.01)
  
  ## Comparison log lambda
  expect_equivalent(colMeans(sample_ln),mean_ln, tolerance = 0.001)
  expect_equivalent(matrixStats::colSds(sample_ln), sd_ln, tolerance = 0.01)
  
  ## Comparisons PLN
  expect_equivalent(colMeans(sample_pln), mean_nb, tolerance = 0.001)
  expect_equivalent(matrixStats::colSds(sample_pln), sd_nb, tolerance = 0.05)
  
  ## Always the same total variance
  for (i in 1:ntaxa) {
    expect_equivalent(params_PLN$log_variance_phylo + params_PLN$log_variance_sample[, i],
                      rep(params_PLN$log_variance_phylo[1] + params_PLN$log_variance_sample[1, i], n))
  }
  
  ## Phylogenetic covariances - Pagel
  C_tree <- ape::vcv(tree)
  for (ng in sample(n, 100)) { ## test for only 100 genes at random
    V_ln <- C_tree * params_PLN$log_variance_phylo[ng] + diag(params_PLN$log_variance_sample[ng, ])
    V_ln_pagel <- (params_PLN$log_variance_phylo[ng] + params_PLN$log_variance_sample[ng, 1]) * ape::vcv(phylolm::transf.branch.lengths(tree, model = "lambda", list(lambda = prop.var.tree[ng]))$tree)
    for (i in 1:(ntaxa-1)) {
      for (j in (i+1):ntaxa) {
        expect_equal(V_ln_pagel[i, j], V_ln[i, j], scale = V_ln[i, j])
      }
    }
  }

})
