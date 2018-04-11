
my.bootstrap_irf <- function (model, typeof_irf = c("OIRF", "GIRF"), n.ahead, nof_Nstar_draws, 
          confidence.band = 0.95) 
{
        # all the data used in the estimation of the model
        dt.Data_initial <- data.table(model$Set_Vars)
        
        size_Nstar_draws <- length(model$instruments)
        Nstar_draws <- list()
        possible.draws <- length(unique(model$Set_Vars[, c("category")]))
        x <- unique(model$Set_Vars[, c("category")])
        prob.x <- rep(1/possible.draws, possible.draws)
        # Replaced the for loop with a lapply to speed up the creation of the resampled list
        Nstar_draws <- lapply(1:nof_Nstar_draws, function(i){sample(x, size = size_Nstar_draws, 
                                                                    replace = TRUE, prob = prob.x)})
        
        # for loops to select the resampled data and calculate the panelvar and irf
       pvar_irf <- foreach(i0 = 1:nof_Nstar_draws) %dopar% {
                library(panelvar)
                dt.data_resampled <- dt.Data_initial[category == Nstar_draws[[i0]][1],]
                dt.data_resampled[, category := as.factor(1)]
                
                for (i1 in 2:size_Nstar_draws) { # creation of the dataframe with the resampled data
                        dt.zwischen <-   dt.Data_initial[category == Nstar_draws[[i0]][i1],]
                        dt.zwischen[, category := as.factor(i1)]
                        dt.data_resampled <- rbindlist(list(dt.data_resampled, dt.zwischen)
                                                       , use.names = FALSE
                                                       , fill = FALSE
                                                       , idcol = FALSE)
                }
                # Function arguments
                fct_agr_list <- list(dependent_vars = model$dependent_vars, 
                                     lags = model$lags, predet_vars = model$predet_vars, 
                                     exog_vars = model$exog_vars, transformation = model$transformation
                                     , data = dt.data_resampled
                                     , panel_identifier = c("category","period")
                                     , steps = model$steps
                                     , system_instruments = model$system_instruments, 
                                     max_instr_dependent_vars = model$max_instr_predet_vars, 
                                     max_instr_predet_vars = model$max_instr_predet_vars, 
                                     min_instr_dependent_vars = model$min_instr_predet_vars, 
                                     min_instr_predet_vars = model$min_instr_predet_vars, 
                                     collapse = model$collapse, tol = model$tol, progressbar = FALSE)
                if (is.null(model$predet_vars) == TRUE) {
                        fct_agr_list$predet_vars = model$predet_vars
                }
                if (is.null(model$exog_vars) == TRUE) {
                        fct_agr_list$exog_vars = model$exog_vars
                }
                if (is.null(model$tol) == TRUE) {
                        fct_agr_list$tol = model$tol
                }
                # Calculation of the panelvar model
                pvar_zwischen <- suppressWarnings(do.call(pvargmm, fct_agr_list))
                pvar_zwischen$second_step
                # Calculation of the irf from the pvar with the resampled data
                if (typeof_irf == c("OIRF")) {
                        return(oirf(model = pvar_zwischen, n.ahead = n.ahead))
                }
                if (typeof_irf == c("GIRF")) {
                        return(girf(model = pvar_zwischen, n.ahead = n.ahead, 
                                               ma_approx_steps = n.ahead))
                }
        }
        two_sided_bound <- 1 - confidence.band
        lower <- two_sided_bound/2
        upper <- 1 - lower
        mat.l <- matrix(NA, nrow = n.ahead, ncol = ncol(pvar_irf[[1]][[1]]))
        mat.u <- matrix(NA, nrow = n.ahead, ncol = ncol(pvar_irf[[1]][[1]]))
        Lower <- list()
        Upper <- list()
        idx1 <- length(pvar_irf[[1]])
        idx2 <- ncol(pvar_irf[[1]][[1]])
        idx3 <- n.ahead
        temp <- rep(NA, length(pvar_irf))
        for (j in 1:idx1) {
                for (m in 1:idx2) {
                        for (l in 1:idx3) {
                                for (i in 1:nof_Nstar_draws) {
                                        if (idx2 > 1) {
                                                temp[i] <- pvar_irf[[i]][[j]][l, m]
                                        }
                                        else {
                                                temp[i] <- matrix(pvar_irf[[i]][[j]])[l, 
                                                                                      m]
                                        }
                                }
                                mat.l[l, m] <- quantile(temp, lower, na.rm = TRUE)
                                mat.u[l, m] <- quantile(temp, upper, na.rm = TRUE)
                        }
                }
                colnames(mat.l) <- model$dependent_vars
                colnames(mat.u) <- model$dependent_vars
                Lower[[j]] <- mat.l
                Upper[[j]] <- mat.u
        }
        names(Lower) <- model$dependent_vars
        names(Upper) <- model$dependent_vars
        return(list(Lower = Lower, Upper = Upper, Nstar_draws = Nstar_draws, 
                    CI = confidence.band))
}
