# ParallelPanelVAR
Functions to parallelize the computational demanding functions of the panelvar package. These functions are only extensions to the work done by Sigmund and Ferstl (2018).
The code is now available on CRAN, please see https://cran.r-project.org/package=panelvar

Initially only the bootstrapping procedure for the impulse response functions is parallelized in order to facilitate its calculation. Please don't hesitate to create pull requests for additional functions, which might be possible to speed up.


The speed improvements are quite considerable and the results should be the same. It is important to note that in case of a lot of cores the RAM becomes the bottleneck. So please be advised that there might occur swapping, slowing the parallel processing down considerably.
Short comparison using the Cigar PanelVAR
  
    microbenchmark(
              a = (my.bootstrap_irf(model = model, typeof_irf = "GIRF", n.ahead = 8, nof_Nstar_draws = 20, confidence.band = 0.95))
            , b = (bootstrap_irf(model = model, typeof_irf = "GIRF", n.ahead = 8, nof_Nstar_draws = 20, confidence.band = 0.95))
            , times = 10
                )
  
    Unit: seconds                                                             
    expr       min        lq     mean    median        uq       max neval cld
    a  46.34114  49.85494  51.8946  50.51108  51.36918  65.30517    10  a 
    b 168.19021 174.67670 175.3993 176.27962 177.25603 180.04718    10   b

I've only tested it on Windows, but this should also work on Linux.

Panel Vector Autoregression in R with the Package Panelvar by Michael Sigmund and Robert Ferstl https://papers.ssrn.com/sol3/papers.cfm?abstract_id=2896087
