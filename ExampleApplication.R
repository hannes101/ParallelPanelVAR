library(panelvar)
library(data.table)
library(microbenchmark)

# Parallel Processing Setup 
library(foreach)
library(doSNOW)
library(parallel)
#Define number of cores to use. By default the maximum available number minus one core is used
cl <- makeSOCKcluster(max(1, detectCores() - 1))
registerDoSNOW(cl)

# Creation of the model
model <- pvargmm(dependent_vars = c("log_sales", "log_price"),
                               lags = 1,
                               predet_vars = c("log_ndi"),
                               exog_vars = c("cpi", "log_pop16"),
                               transformation = "fod",
                               data = dt.Cigar,
                               panel_identifier= c("state", "year"),
                               steps = c("twostep"),
                               system_instruments = TRUE,
                               max_instr_dependent_vars = 10,
                               max_instr_predet_vars = 10,
                               min_instr_dependent_vars = 2L,
                               min_instr_predet_vars = 1L,
                               collapse = TRUE
)


# Application of the Bootstrap procedure
 my.bootstrap_irf(model = model, typeof_irf = "GIRF", n.ahead = 8, nof_Nstar_draws = 20, confidence.band = 0.95)
 
# Code for the comparison of the two procedures
microbenchmark(
		a = (my.bootstrap_irf(model = model, typeof_irf = "GIRF", n.ahead = 8, nof_Nstar_draws = 20, confidence.band = 0.95))
      , b = (bootstrap_irf(model = model, typeof_irf = "GIRF", n.ahead = 8, nof_Nstar_draws = 20, confidence.band = 0.95))
      , times = 10
)