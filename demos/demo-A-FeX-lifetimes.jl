
#==

Task:  Compute the photoemission transition probabilities for chlorine-like Fe X ions between the 
-----  excited and ground configurations:
      
       [Ne] (3s 3p^6 + 3s^2 3p^4 3d)  -->  [Ne] 3s^2 3p^5
      
       in velocity (Coulomb) and length (Babushkin) gauge and by including electric and magnetic (E1, M1)
       multipole transitions.
       
       All the subsequent lines can be invoked also `line-by-line' to better understand the set-up of 
       the computations. This input has been adapted from ../examples/example-Da.jl
==#

setDefaults("unit: energy", "Kayser")
setDefaults("unit: rate", "1/s")
grid          = Radial.Grid(true)
photoSettings = PhotoEmission.Settings()
photoSettings = PhotoEmission.Settings(photoSettings, multipoles=[E1], gauges=[UseCoulomb,UseBabushkin], printBefore=true)

comp = Atomic.Computation(Atomic.Computation(), name="Energies and Einstein coefficients for the spectrum Fe X",  
                          grid = grid,  nuclearModel = Nuclear.Model(26.);
                          initialConfigs  = [Configuration("[Ne] 3s 3p^6"), Configuration("[Ne] 3s^2 3p^4 3d")],
                          finalConfigs    = [Configuration("[Ne] 3s^2 3p^5")], 
                          processSettings = photoSettings ); 

perform(comp)         



#==
Main output:  
------------
 
  Einstein coefficients, transition rates and oscillator strengths:
 
  -----------------------------------------------------------------------------------------------------------------------------------------------------------------
       i-level-f           i--J^P--f           Energy        Multipole   Gauge             A--Einstein--B          Osc. strength    Decay widths    Line strength    
                                              [Kayser]                                    [1/s]          [1/s]                        [Kayser]         [a.u.]       
  -----------------------------------------------------------------------------------------------------------------------------------------------------------------
         1 --    1      1/2 + --> 3/2 -     2.790741e+05        E1       Coulomb      1.321486e+10  3.948899e+00    1.271895e-01    7.015554e-02    9.531906e-04    
         1 --    1      1/2 + --> 3/2 -     2.790741e+05        E1       Babushkin    1.212234e+10  3.622429e+00    1.166743e-01    6.435553e-02    8.743870e-04    
         1 --    2      1/2 + --> 1/2 -     2.628199e+05        E1       Coulomb      1.627959e+10  5.824259e+00    3.533335e-01    8.642570e-02    7.029338e-04    
         1 --    2      1/2 + --> 1/2 -     2.628199e+05        E1       Babushkin    1.047458e+10  3.747431e+00    2.273410e-01    5.560782e-02    4.522800e-04    
         3 --    1      5/2 + --> 3/2 -     3.804147e+05        E1       Coulomb      1.900610e+10  2.242296e+00    2.953435e-01    1.009003e-01    5.412486e-04    
         3 --    1      5/2 + --> 3/2 -     3.804147e+05        E1       Babushkin    1.384651e+10  1.633580e+00    2.151666e-01    7.350888e-02    3.943157e-04    
         4 --    1      3/2 + --> 3/2 -     3.816514e+05        E1       Coulomb      2.036331e+09  2.379138e-01    2.095909e-02    1.081055e-02    5.742797e-05    
         4 --    1      3/2 + --> 3/2 -     3.816514e+05        E1       Babushkin    1.510723e+09  1.765047e-01    1.554923e-02    8.020185e-03    4.260495e-05    
         4 --    2      3/2 + --> 1/2 -     3.653972e+05        E1       Coulomb      5.694997e+09  7.581753e-01    1.278942e-01    3.023381e-02    9.150471e-05    
         4 --    2      3/2 + --> 1/2 -     3.653972e+05        E1       Babushkin    3.818190e+09  5.083159e-01    8.574620e-02    2.027015e-02    6.134900e-05    
         5 --    1      1/2 + --> 3/2 -     3.832116e+05        E1       Coulomb      3.194867e+06  3.687300e-04    1.630809e-05    1.696103e-05    8.900456e-08    
         5 --    1      1/2 + --> 3/2 -     3.832116e+05        E1       Babushkin    1.875824e+06  2.164950e-04    9.575083e-06    9.958447e-06    5.225787e-08    
         5 --    2      1/2 + --> 1/2 -     3.669575e+05        E1       Coulomb      3.998122e+06  5.255096e-04    4.451254e-05    2.122538e-05    6.342412e-08    
         5 --    2      1/2 + --> 1/2 -     3.669575e+05        E1       Babushkin    3.669424e+06  4.823058e-04    4.085302e-05    1.948037e-05    5.820982e-08    
         8 --    1      1/2 + --> 3/2 -     4.179381e+05        E1       Coulomb      5.673038e+09  5.047211e-01    2.434554e-02    3.011724e-02    1.218303e-04    
         8 --    1      1/2 + --> 3/2 -     4.179381e+05        E1       Babushkin    4.874770e+09  4.337005e-01    2.091982e-02    2.587936e-02    1.046872e-04    
         8 --    2      1/2 + --> 1/2 -     4.016840e+05        E1       Coulomb      1.532585e+08  1.535829e-02    1.424011e-03    8.136246e-04    1.853603e-06    
         8 --    2      1/2 + --> 1/2 -     4.016840e+05        E1       Babushkin    1.193471e+08  1.195997e-02    1.108921e-03    6.335944e-04    1.443458e-06    
         9 --    1      5/2 + --> 3/2 -     4.196282e+05        E1       Coulomb      2.949948e+10  2.592939e+00    3.767334e-01    1.566079e-01    6.258871e-04    
         9 --    1      5/2 + --> 3/2 -     4.196282e+05        E1       Babushkin    2.630442e+10  2.312100e+00    3.359297e-01    1.396459e-01    5.580978e-04    
        10 --    1      3/2 + --> 3/2 -     4.213290e+05        E1       Coulomb      5.258695e+09  4.566525e-01    4.441126e-02    2.791756e-02    1.102274e-04    
        10 --    1      3/2 + --> 3/2 -     4.213290e+05        E1       Babushkin    4.737306e+09  4.113764e-01    4.000798e-02    2.514959e-02    9.929860e-05    
        10 --    2      3/2 + --> 1/2 -     4.050748e+05        E1       Coulomb      3.008552e+10  2.939840e+00    5.497621e-01    1.597191e-01    3.548113e-04    
        10 --    2      3/2 + --> 1/2 -     4.050748e+05        E1       Babushkin    2.501020e+10  2.443899e+00    4.570192e-01    1.327751e-01    2.949559e-04    
        11 --    1      3/2 + --> 3/2 -     4.259902e+05        E1       Coulomb      3.247993e+09  2.728903e-01    2.683327e-02    1.724307e-02    6.587065e-05    
        11 --    1      3/2 + --> 3/2 -     4.259902e+05        E1       Babushkin    3.008257e+09  2.527481e-01    2.485269e-02    1.597035e-02    6.100870e-05    
        11 --    2      3/2 + --> 1/2 -     4.097360e+05        E1       Coulomb      9.156853e+09  8.645809e-01    1.635406e-01    4.861224e-02    1.043469e-04    
        11 --    2      3/2 + --> 1/2 -     4.097360e+05        E1       Babushkin    7.757267e+09  7.324334e-01    1.385442e-01    4.118207e-02    8.839790e-05    
        12 --    1      1/2 + --> 3/2 -     4.301665e+05        E1       Coulomb      5.479390e+10  4.470893e+00    2.219662e-01    2.908919e-01    1.079190e-03    
        12 --    1      1/2 + --> 3/2 -     4.301665e+05        E1       Babushkin    4.988868e+10  4.070653e+00    2.020955e-01    2.648509e-01    9.825798e-04    
        12 --    2      1/2 + --> 1/2 -     4.139123e+05        E1       Coulomb      1.812187e+07  1.659777e-03    1.585784e-04    9.620606e-05    2.003196e-07    
        12 --    2      1/2 + --> 1/2 -     4.139123e+05        E1       Babushkin    3.847324e+07  3.523753e-03    3.366664e-04    2.042482e-04    4.252842e-07    
        13 --    1      3/2 + --> 3/2 -     4.310289e+05        E1       Coulomb      5.153016e+10  4.179403e+00    4.158211e-01    2.735653e-01    1.008830e-03    
        13 --    1      3/2 + --> 3/2 -     4.310289e+05        E1       Babushkin    4.838355e+10  3.924194e+00    3.904296e-01    2.568604e-01    9.472274e-04    
        13 --    2      3/2 + --> 1/2 -     4.147747e+05        E1       Coulomb      1.459507e+09  1.328437e-01    2.543720e-02    7.748284e-03    1.603300e-05    
        13 --    2      3/2 + --> 1/2 -     4.147747e+05        E1       Babushkin    1.267426e+09  1.153606e-01    2.208949e-02    6.728558e-03    1.392295e-05    
        14 --    1      3/2 + --> 3/2 -     4.358804e+05        E1       Coulomb      1.241277e+10  9.735059e-01    9.794717e-02    6.589740e-02    2.349862e-04    
        14 --    1      3/2 + --> 3/2 -     4.358804e+05        E1       Babushkin    1.190733e+10  9.338650e-01    9.395879e-02    6.321408e-02    2.254176e-04    
        14 --    2      3/2 + --> 1/2 -     4.196263e+05        E1       Coulomb      7.329497e+08  6.442554e-02    1.248063e-02    3.891111e-03    7.775563e-06    
        14 --    2      3/2 + --> 1/2 -     4.196263e+05        E1       Babushkin    6.553777e+08  5.760704e-02    1.115974e-02    3.479294e-03    6.952634e-06    
        16 --    1      5/2 + --> 3/2 -     4.379253e+05        E1       Coulomb      4.294836e+09  3.321379e-01    5.036115e-02    2.280059e-02    8.017191e-05    
        16 --    1      5/2 + --> 3/2 -     4.379253e+05        E1       Babushkin    4.177817e+09  3.230883e-01    4.898898e-02    2.217935e-02    7.798751e-05    
        17 --    1      5/2 + --> 3/2 -     4.408627e+05        E1       Coulomb      9.655409e+08  7.318675e-02    1.117154e-02    5.125900e-03    1.766592e-05    
        17 --    1      5/2 + --> 3/2 -     4.408627e+05        E1       Babushkin    9.258042e+08  7.017476e-02    1.071178e-02    4.914944e-03    1.693888e-05    
        20 --    1      5/2 + --> 3/2 -     4.520940e+05        E1       Coulomb      1.203615e+09  8.460054e-02    1.324278e-02    6.389795e-03    2.042100e-05    
        20 --    1      5/2 + --> 3/2 -     4.520940e+05        E1       Babushkin    1.250551e+09  8.789962e-02    1.375919e-02    6.638972e-03    2.121733e-05    
        21 --    1      5/2 + --> 3/2 -     4.829056e+05        E1       Coulomb      4.272145e+10  2.463946e+00    4.119747e-01    2.268012e-01    5.947506e-04    
        21 --    1      5/2 + --> 3/2 -     4.829056e+05        E1       Babushkin    5.049629e+10  2.912357e+00    4.869496e-01    2.680766e-01    7.029888e-04    
        23 --    1      3/2 + --> 3/2 -     5.191559e+05        E1       Coulomb      1.719211e+10  7.980089e-01    9.562940e-02    9.127012e-02    1.926245e-04    
        23 --    1      3/2 + --> 3/2 -     5.191559e+05        E1       Babushkin    2.359102e+10  1.095028e+00    1.312227e-01    1.252409e-01    2.643194e-04    
        23 --    2      3/2 + --> 1/2 -     5.029017e+05        E1       Coulomb      4.380991e+10  2.237149e+00    5.193905e-01    2.325797e-01    2.700031e-04    
        23 --    2      3/2 + --> 1/2 -     5.029017e+05        E1       Babushkin    5.620630e+10  2.870169e+00    6.663563e-01    2.983901e-01    3.464027e-04    
        24 --    1      5/2 + --> 3/2 -     5.237859e+05        E1       Coulomb      7.576315e+09  3.424274e-01    6.210113e-02    4.022142e-02    8.265560e-05    
        24 --    1      5/2 + --> 3/2 -     5.237859e+05        E1       Babushkin    1.053356e+10  4.760865e-01    8.634095e-02    5.592098e-02    1.149184e-04    
        25 --    1      1/2 + --> 3/2 -     5.741279e+05        E1       Coulomb      1.679215e+10  5.763048e-01    3.818711e-02    8.914680e-02    1.391092e-04    
        25 --    1      1/2 + --> 3/2 -     5.741279e+05        E1       Babushkin    5.180083e+10  1.777799e+00    1.178005e-01    2.750022e-01    4.291275e-04    
        25 --    2      1/2 + --> 1/2 -     5.578737e+05        E1       Coulomb      1.582115e+08  5.918372e-03    7.621213e-04    8.399194e-04    7.142924e-07    
        25 --    2      1/2 + --> 1/2 -     5.578737e+05        E1       Babushkin    4.120200e+09  1.541283e-01    1.984743e-02    2.187347e-02    1.860185e-05    
        26 --    1      3/2 + --> 3/2 -     5.790473e+05        E1       Coulomb      9.204073e+08  3.079001e-02    4.115378e-03    4.886292e-03    7.432135e-06    
        26 --    1      3/2 + --> 3/2 -     5.790473e+05        E1       Babushkin    2.164194e+09  7.239790e-02    9.676670e-03    1.148936e-02    1.747551e-05    
        26 --    2      3/2 + --> 1/2 -     5.627931e+05        E1       Coulomb      4.155778e+07  1.514181e-03    3.934075e-04    2.206235e-04    1.827476e-07    
        26 --    2      3/2 + --> 1/2 -     5.627931e+05        E1       Babushkin    4.645815e+07  1.692729e-03    4.397969e-04    2.466388e-04    2.042966e-07    
        27 --    1      1/2 + --> 3/2 -     5.850737e+05        E1       Coulomb      1.073180e+09  3.480269e-02    2.350062e-03    5.697339e-03    8.400721e-06    
        27 --    1      1/2 + --> 3/2 -     5.850737e+05        E1       Babushkin    4.396848e+08  1.425876e-02    9.628267e-04    2.334215e-03    3.441798e-06    
        27 --    2      1/2 + --> 1/2 -     5.688195e+05        E1       Coulomb      7.880377e+10  2.780964e+00    3.651370e-01    4.183564e-01    3.356365e-04    
        27 --    2      1/2 + --> 1/2 -     5.688195e+05        E1       Babushkin    1.232115e+11  4.348101e+00    5.709000e-01    6.541098e-01    5.247753e-04    
        28 --    1      5/2 + --> 3/2 -     5.955992e+05        E1       Coulomb      8.836513e+09  2.716379e-01    5.601724e-02    4.691161e-02    6.556834e-05    
        28 --    1      5/2 + --> 3/2 -     5.955992e+05        E1       Babushkin    1.804268e+10  5.546393e-01    1.143778e-01    9.578567e-02    1.338796e-04    
        29 --    1      3/2 + --> 3/2 -     6.092438e+05        E1       Coulomb      6.680739e+08  1.918770e-02    2.698361e-03    3.546696e-03    4.631553e-06    
        29 --    1      3/2 + --> 3/2 -     6.092438e+05        E1       Babushkin    1.093552e+09  3.140782e-02    4.416873e-03    5.805490e-03    7.581264e-06    
        29 --    2      3/2 + --> 1/2 -     5.929897e+05        E1       Coulomb      2.253349e+10  7.018737e-01    1.921419e-01    1.196266e-01    8.470962e-05    
        29 --    2      3/2 + --> 1/2 -     5.929897e+05        E1       Babushkin    4.338474e+10  1.351349e+00    3.699394e-01    2.303225e-01    1.630952e-04    
  -----------------------------------------------------------------------------------------------------------------------------------------------------------------
 
  PhotoEmission lifetimes (as derived from these computations):
 
  ---------------------------------------------------------------------------------------------------------
     Level        J^P        Level energy    Used Gauge                Lifetime             Decay widths    
                              [Kayser]                          [a.u.]          [sec]         [Kayser]      
  ---------------------------------------------------------------------------------------------------------
         1       1/2 +      -2.724722e+08    Coulomb          1.401666e+06  3.390468e-11    1.565812e-01
                                             Babushkin        1.829514e+06  4.425382e-11    1.199634e-01
         3       5/2 +      -2.723709e+08    Coulomb          2.175164e+06  5.261469e-11    1.009003e-01
                                             Babushkin        2.985689e+06  7.222036e-11    7.350888e-02
         4       3/2 +      -2.723696e+08    Coulomb          5.347254e+06  1.293439e-10    4.104436e-02
                                             Babushkin        7.757936e+06  1.876555e-10    2.829034e-02
         5       1/2 +      -2.723681e+08    Coulomb          5.747454e+09  1.390243e-07    3.818641e-05
                                             Babushkin        7.455279e+09  1.803346e-07    2.943882e-05
         8       1/2 +      -2.723334e+08    Coulomb          7.095652e+06  1.716356e-10    3.093086e-02
                                             Babushkin        8.278014e+06  2.002356e-10    2.651296e-02
         9       5/2 +      -2.723317e+08    Coulomb          1.401427e+06  3.389890e-11    1.566079e-01
                                             Babushkin        1.571651e+06  3.801643e-11    1.396459e-01
        10       3/2 +      -2.723300e+08    Coulomb          1.169679e+06  2.829318e-11    1.876367e-01
                                             Babushkin        1.389743e+06  3.361627e-11    1.579247e-01
        11       3/2 +      -2.723253e+08    Coulomb          3.332679e+06  8.061366e-11    6.585531e-02
                                             Babushkin        3.840164e+06  9.288912e-11    5.715241e-02
        12       1/2 +      -2.723211e+08    Coulomb          7.542391e+05  1.824417e-11    2.909881e-01
                                             Babushkin        8.280339e+05  2.002918e-11    2.650551e-01
        13       3/2 +      -2.723203e+08    Coulomb          7.801780e+05  1.887160e-11    2.813135e-01
                                             Babushkin        8.326397e+05  2.014059e-11    2.635890e-01
        14       3/2 +      -2.723154e+08    Coulomb          3.144853e+06  7.607036e-11    6.978851e-02
                                             Babushkin        3.290801e+06  7.960067e-11    6.669337e-02
        16       5/2 +      -2.723134e+08    Coulomb          9.625832e+06  2.328377e-10    2.280059e-02
                                             Babushkin        9.895449e+06  2.393595e-10    2.217935e-02
        17       5/2 +      -2.723104e+08    Coulomb          4.281680e+07  1.035689e-09    5.125900e-03
                                             Babushkin        4.465455e+07  1.080142e-09    4.914944e-03
        20       5/2 +      -2.722992e+08    Coulomb          3.434768e+07  8.308306e-10    6.389795e-03
                                             Babushkin        3.305853e+07  7.996475e-10    6.638972e-03
        21       5/2 +      -2.722684e+08    Coulomb          9.676959e+05  2.340744e-11    2.268012e-01
                                             Babushkin        8.187012e+05  1.980344e-11    2.680766e-01
        23       3/2 +      -2.722321e+08    Coulomb          6.777049e+05  1.639290e-11    3.238498e-01
                                             Babushkin        5.180797e+05  1.253175e-11    4.236310e-01
        24       5/2 +      -2.722275e+08    Coulomb          5.456660e+06  1.319903e-10    4.022142e-02
                                             Babushkin        3.924728e+06  9.493462e-11    5.592098e-02
        25       1/2 +      -2.721772e+08    Coulomb          2.438967e+06  5.899578e-11    8.998672e-02
                                             Babushkin        7.392814e+05  1.788236e-11    2.968756e-01
        26       3/2 +      -2.721723e+08    Coulomb          4.297596e+07  1.039539e-09    5.106916e-03
                                             Babushkin        1.870098e+07  4.523551e-10    1.173599e-02
        27       1/2 +      -2.721662e+08    Coulomb          5.175632e+05  1.251926e-11    4.240538e-01
                                             Babushkin        3.343387e+05  8.087266e-12    6.564440e-01
        28       5/2 +      -2.721557e+08    Coulomb          4.678471e+06  1.131668e-10    4.691161e-02
                                             Babushkin        2.291310e+06  5.542413e-11    9.578567e-02
        29       3/2 +      -2.721421e+08    Coulomb          1.781835e+06  4.310054e-11    1.231733e-01
                                             Babushkin        9.294730e+05  2.248288e-11    2.361280e-01
  ---------------------------------------------------------------------------------------------------------

==#
