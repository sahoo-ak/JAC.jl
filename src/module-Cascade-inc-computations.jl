
    # Functions and methods for cascade computation


    """
    `Cascade.computeDecayProbabilities(outcome::DecayYield.Outcome, linesR::Array{PhotoEmission.Line,1}, 
                                       linesA::Array{AutoIonization.Line,1}, settings::DecayYield.Settings)` 
        ... to compute the decay probabilities for all pairs and triple of subshells; these probabilities only depend
            on the holes in different subshells and average over all final levels that share the same subshell occupation.
            The results are printed in neat tables to screen but nothing is returned otherwise.
    """
    function computeDecayProbabilities(outcome::DecayYield.Outcome, linesR::Array{PhotoEmission.Line,1}, 
                                       linesA::Array{AutoIonization.Line,1}, settings::DecayYield.Settings)
        #
        # Determine the leading configuration and shells of the initial level
        subshList = Basics.extractRelativisticSubshellList(outcome.level)
        confs     = Basics.extractNonrelativisticConfigurations(outcome.level.basis)
        ## @show subshList, confs
        #
        # Initialize and fill dictionaries for collection the radiative and Auger rates;
        # a 1s hole is assumed initially
        if  subshList[1] != Subshell("1s_1/2")    error("stop a")     end
        println("\n Probabilities are determined for an initial 1s hole, starting from the configurations \n  $(confs)")
        rProbabilities = Dict{Subshell,Float64}()
        aProbabilities = Dict{Tuple{Subshell,Subshell},Float64}()
        for  (i,subshi) in enumerate(subshList)
            if i > 1   rProbabilities[subshi] = 0.   end 
            for  (j,subshj) in enumerate(subshList)
                if j >= i > 1  aProbabilities[(subshi, subshj)] = 0.   end 
            end
        end
        #
        @show rProbabilities
        @show aProbabilities
        #
        # Calculate the total rate and convert the dictionaries into probabilities
        # First, identify the level key of the given level also in the lists of radiative and Auger lines
        level = outcome.level;    levelKey = LevelKey( LevelSymmetry(level.J, level.parity), level.index, level.energy, 0.)
        similarKey = LevelKey();  rateR = 0.;    rateA = 0.;   NoPhotonLines = 0;   NoAugerLines = 0
        for  line in linesR
            compareKey = LevelKey( LevelSymmetry(line.initialLevel.J, line.initialLevel.parity), line.initialLevel.index, line.initialLevel.energy, 0.)
            if   Basics.isSimilar(levelKey, compareKey, 1.0e-3)    println("** compareKey = $compareKey");   similarKey = deepcopy(compareKey)    end
        end
        if   similarKey == LevelKey()    error("No similar level found !")   end
        
        for  line in linesR
            if  similarKey == LevelKey( LevelSymmetry(line.initialLevel.J, line.initialLevel.parity), line.initialLevel.index, line.initialLevel.energy, 0.)
                rateR = rateR + line.photonRate;   NoPhotonLines = NoPhotonLines + 1  
                # Extract the subshells that make the difference between the initial and final levels; terminate if NO 1s_1/2 occurs
                confi = Basics.extractLeadingConfigurationR(line.initialLevel)
                conff = Basics.extractLeadingConfigurationR(line.finalLevel)
                @show confi, conff, line.photonRate.Babushkin
                occDiffs = Basics.extractShellOccupationDifference(confi, conff);   subshList = Subshell[]
                for  diff in occDiffs
                    # 1s_1/2 subshell must differ by -1
                    if diff[1] == Subshell(1,-1)
                        if diff[2] == -1     else   error("stop b")    end
                    end
                    if     diff[2] ==  1     push!(subshList, diff[1])                                end       
                    if     diff[2] ==  2     push!(subshList, diff[1]);    push!(subshList, diff[1])  end       
                end
                if   length(subshList)  != 1   error("stop c")    end
                rProbabilities[ subshList[1] ] = rProbabilities[ subshList[1] ] + line.photonRate.Babushkin
            end
        end
        # @show rProbabilities
        for  line in linesA
            if  similarKey == LevelKey( LevelSymmetry(line.initialLevel.J, line.initialLevel.parity), line.initialLevel.index, line.initialLevel.energy, 0.)
                rateA = rateA + line.totalRate;   NoAugerLines = NoAugerLines + 1    
                # Extract the subshells that make the difference between the initial and final levels; terminate if NO 1s_1/2 occurs
                confi = Basics.extractLeadingConfigurationR(line.initialLevel)
                conff = Basics.extractLeadingConfigurationR(line.finalLevel)
                ##x @show confi, conff
                occDiffs = Basics.extractShellOccupationDifference(confi, conff);   subshList = Subshell[]
                for  diff in occDiffs
                    # 1s_1/2 subshell must differ by -1
                    if diff[1] == Subshell(1,-1)
                        if diff[2] == -1     else   error("stop d")    end
                    end
                    if     diff[2] ==  1     push!(subshList, diff[1])                                end       
                    if     diff[2] ==  2     push!(subshList, diff[1]);    push!(subshList, diff[1])  end       
                end
                if   length(subshList)  != 2   error("stop e")    end
                aProbabilities[ (subshList[1], subshList[2]) ] = aProbabilities[ (subshList[1], subshList[2]) ] + line.totalRate
            end
        end
        # @show aProbabilities
        #
        # Add all rates, convert to probabilities and print these dictionaries into a neat table
        rate = 0.
        for (k,v) in rProbabilities   rate = rate + v   end
        for (k,v) in aProbabilities   rate = rate + v   end
        @show outcome.rateR + outcome.rateA, rate
        #
        for (k,v) in rProbabilities   rProbabilities[k] = v/rate   end
        for (k,v) in aProbabilities   aProbabilities[k] = v/rate   end
        #
        Cascade.displayDecayProbabilities(stdout, outcome, rProbabilities, aProbabilities, settings)
   
        return( nothing )
    end
    

    """
    `Cascade.computeDecayYieldOutcome(outcome::DecayYield.Outcome, linesR::Array{PhotoEmission.Line,1}, 
                                      linesA::Array{AutoIonization.Line,1}, settings::DecayYield.Settings)` 
        ... to compute the flourescence and Auger yields for a single decay yield outcome as specified by the corresponding
            level; an outcome::DecayYield.Outcome is returned in which all physical parameters are now specified for the given
            decay-yield.
    """
    function computeDecayYieldOutcome(outcome::DecayYield.Outcome, linesR::Array{PhotoEmission.Line,1}, 
                                      linesA::Array{AutoIonization.Line,1}, settings::DecayYield.Settings)
        # Identify the level key of the given level also in the lists of radiative and Auger lines
        level = outcome.level;    levelKey = LevelKey( LevelSymmetry(level.J, level.parity), level.index, level.energy, 0.)
        similarKey = LevelKey();  rateR = 0.;    rateA = 0.;   NoPhotonLines = 0;   NoAugerLines = 0
        for  line in linesR
            compareKey = LevelKey( LevelSymmetry(line.initialLevel.J, line.initialLevel.parity), line.initialLevel.index, line.initialLevel.energy, 0.)
            if   Basics.isSimilar(levelKey, compareKey, 1.0e-3)    println("** compareKey = $compareKey");   similarKey = deepcopy(compareKey)    end
        end
        if   similarKey == LevelKey()    error("No similar level found !")   end
        
        for  line in linesR
            if  similarKey == LevelKey( LevelSymmetry(line.initialLevel.J, line.initialLevel.parity), line.initialLevel.index, line.initialLevel.energy, 0.)
                rateR = rateR + line.photonRate;   NoPhotonLines = NoPhotonLines + 1    
            end
        end
        for  line in linesA
            if  similarKey == LevelKey( LevelSymmetry(line.initialLevel.J, line.initialLevel.parity), line.initialLevel.index, line.initialLevel.energy, 0.)
                rateA = rateA + line.totalRate;   NoAugerLines = NoAugerLines + 1    
            end
        end
        
        omegaR     = rateR / (rateR + rateA);   omegaA = rateA / (rateR + rateA)
        newOutcome = DecayYield.Outcome(level, NoPhotonLines, NoAugerLines, rateR, rateA, omegaR, omegaA)
        return( newOutcome )
    end


    """
    `Cascade.computeTotalAugerRate(level::Cascade.Level)` 
        ... computes the total Auger rate of level as given by its daugther levels; a rate::Float64 is returned.
    """
    function computeTotalAugerRate(level::Cascade.Level)
        rate = 0.
        for daugther in level.daugthers
            if  daugther.process != Basics.Auger();      continue   end
            aLine   = daugther.lineSet.linesA[daugther.index]
            rate    = rate + aLine.totalRate
        end
        return( rate )
    end


    """
    `Cascade.computeTotalPhotonRate(level::Cascade.Level)` 
        ... computes the total photon (radiative) rate of level as given by its daugther levels; a rate::EmProperty is returned.
    """
    function computeTotalPhotonRate(level::Cascade.Level)
        rate = Basics.EmProperty(0.)
        for daugther in level.daugthers
            if  daugther.process != Basics.Radiative();      continue   end
            rLine   = daugther.lineSet.linesR[daugther.index]
            rate    = rate + rLine.photonRate
        end
        
        return( rate )
    end



    """
    `Cascade.displayBlocks(stream::IO, blockList::Array{Cascade.Block,1}; sa::String="")` 
        ... group & display the blocks of the cascade with same No. of electrons; this blocks are displayed with the
            minimum and maximum energy of each multiplet. The optional sa::String can be used to display some details
            about the given blocks. nothing is returned.
    """
    function displayBlocks(stream::IO, blockList::Array{Cascade.Block,1}; sa::String="")
        #
        nx = 150
        println(stream, "\n* Configuration 'blocks' (multiplets): " * sa * "\n")
        println(stream, "  ", TableStrings.hLine(nx))
        println(stream, "      No.   Configurations                                                                       " *
                        "      No. CSF  ",
                        "      Range of total energies " * TableStrings.inUnits("energy") ) 
        println(stream, "  ", TableStrings.hLine(nx))
        i = 0
        for  block  in  blockList
            i = i + 1;    
            sa = "   " * TableStrings.flushright( 6, string(i); na=2)
            sb = " ";         for conf  in blockList[i].confs   sb = sb * string(conf) * ", "    end
            en = Float64[];   for level in  block.multiplet.levels    push!(en, level.energy)    end
            minEn = minimum(en);   minEn = Defaults.convertUnits("energy: from atomic", minEn)
            maxEn = maximum(en);   maxEn = Defaults.convertUnits("energy: from atomic", maxEn)
            sa = sa * TableStrings.flushleft(87, sb[1:end-2]; na=2) 
            sb = "          " * string( length(block.multiplet.levels) )
            sa = sa * sb[end-9:end] * "        "
            sa = sa * TableStrings.flushleft(30, string( round(minEn)) * " ... " * string( round(maxEn)); na=2)
            println(stream, sa)
        end
        println(stream, "  ", TableStrings.hLine(nx))

        return( nothing )
    end
   

    """
    `Cascade.displayDecayProbabilities(stream::IO, outcome::DecayYield.Outcome, rProbabilities::Dict{Subshell,Float64},
                                       aProbabilities::Dict{Tuple{Subshell,Subshell},Float64}, settings::DecayYield.Settings)`  
        ... displays the decay probabilities due to the geant4 optional output of DecayYields; this procedure is rather
            specific in that a 1s hole is initially assumed and that the many-electron rates are brought back
            to a single-particle shell notation. A neat table is printed but nothing is returned.
    """
    function displayDecayProbabilities(stream::IO, outcome::DecayYield.Outcome, rProbabilities::Dict{Subshell,Float64},
                                       aProbabilities::Dict{Tuple{Subshell,Subshell},Float64}, settings::DecayYield.Settings)
        # Extract and sort the list of subshells in rProbabilities and aProbabilities
        subshList = Subshell[]
        for (k,v) in rProbabilities   if  k in subshList     else   push!(subshList, k)    end    end
        for (k,v) in aProbabilities   if  k[1] in subshList  else  push!(subshList, k[1])  end 
                                      if  k[2] in subshList  else  push!(subshList, k[2])  end 
        end
        subshList = sort(subshList)
        ##x @show subshList
        
        nx = 28
        println(stream, " ")
        println(stream, "  Fluorescence and Auger decay probabilities:")
        println(stream, " ")
        println(stream, "    + Level: $(outcome.level.index) with symmetry $(LevelSymmetry( outcome.level.J, outcome.level.parity)) ")
        println(stream, "    + $(outcome.NoPhotonLines)           ... number of photon lines. ")
        println(stream, "    + $(outcome.NoAugerLines )           ... number of Auger lines. ")
        if    settings.approach in ["AverageSCA", "SCA"]
        println(stream, "    + Approach:  $(settings.approach)  ... all decay probabilities only in Babushkin gauge. ")
        end
        #
        println(stream, " ")
        println(stream, "  ", TableStrings.hLine(nx))
        sa = " "
        sa = sa * TableStrings.center(10, "Shell"; na=2);     
        sa = sa * TableStrings.center(16, "p (radiative)";   na=4)
        println(stream, sa);    println(stream, "  ", TableStrings.hLine(nx)) 
        #
        for subsh in subshList
            if  haskey(rProbabilities, subsh)
                sa  = "    $subsh     ";    sa = sa * @sprintf("%.6e", rProbabilities[subsh]);     println(stream, sa )
            end
        end
        println(stream, "  ", TableStrings.hLine(nx), "\n")
        #  
        sa = " ";       nx = 38
        sa = sa * TableStrings.center(10, "Shell"; na=0) * TableStrings.center(10, "Shell"; na=2);     
        sa = sa * TableStrings.center(16, "p (Auger)";   na=4)
        println(stream, sa);    println(stream, "  ", TableStrings.hLine(nx)) 
        #
        for subsha in subshList
            for subshb in subshList
                if  haskey(aProbabilities, (subsha, subshb) )
                    sa  = "    $subsha    $subshb       ";    sa = sa * @sprintf("%.6e", aProbabilities[(subsha, subshb)]);   println(stream, sa )
                end
            end
        end
        println(stream, "  ", TableStrings.hLine(nx), "\n")

        return( nothing )
    end
   

    """
    `Cascade.displayLevels(stream::IO, multiplets::Array{Multiplet,1}; sa::String="")`  
        ... display on stream the initial configurations as well as the calculated levels for all initial multiplets.
    """
    function displayLevels(stream::IO, multiplets::Array{Multiplet,1}; sa::String="")
        nx = 44
        println(stream, " ")
        println(stream, "* Configurations and levels for all given " * sa * "multiplets of the cascade, relative to the lowest:")
        for  multiplet  in multiplets
            println(stream, "  ")
            confList = Basics.extractNonrelativisticConfigurations(multiplet.levels[1].basis)
            for  conf in confList
                println(stream, "  $conf")
            end
            println(stream, "  ", TableStrings.hLine(nx))
            println(stream, "    Level  J Parity          Energy " * TableStrings.inUnits("energy") ) 
            println(stream, "  ", TableStrings.hLine(nx))
            for  i = 1:length(multiplet.levels)
                lev = multiplet.levels[i]
                en  = lev.energy - multiplet.levels[1].energy;    en_requested = Defaults.convertUnits("energy: from atomic", en)
                sc  = "   "  * TableStrings.level(i) * "     " * string(LevelSymmetry(lev.J, lev.parity)) * "     "
                @printf(stream, "%s %.15e %s", sc, en_requested, "\n")
            end
            println(stream, "  ", TableStrings.hLine(nx))
        end
        return( nothing )
    end
   

    """
    `Cascade.displaySteps(stream::IO, steps::Array{Cascade.Step,1}; sa::String="")` 
        ... displays all predefined steps in a neat table and supports to delete individual steps from the list.
            sa::String can be used to display details about the given steps
    """
    function displaySteps(stream::IO, steps::Array{Cascade.Step,1}; sa::String="")
       nx = 170
        println(stream, " ")
        println(stream, "* Steps that are defined for the current " * sa * "cascade due to the given approach:")
        println(stream, " ")
        println(stream, "  ", TableStrings.hLine(nx))
        sa = "  "
        sa = sa * TableStrings.center( 9, "Step-No"; na=2)
        sa = sa * TableStrings.flushleft(11, "Process"; na=1)
        sa = sa * TableStrings.flushleft(55, "Initial:  No CSF, configuration(s)"; na=4)
        sa = sa * TableStrings.flushleft(55, "Final:  No CSF, configuration(s)"; na=4)
        sa = sa * TableStrings.flushleft(40, "Energies from ... to in " * TableStrings.inUnits("energy"); na=4)
        println(stream, sa)
        println(stream, "  ", TableStrings.hLine(nx))
        #
        for  i = 1:length(steps)
            sa = " " * TableStrings.flushright( 7, string(i); na=5)
            sa = sa  * TableStrings.flushleft( 11, string(steps[i].process); na=1)
            sb = "";   for conf in steps[i].initialConfigs   sb = sb * string(conf) * ", "    end
            sa = sa  * TableStrings.flushright( 5, string( length(steps[i].initialMultiplet.levels[1].basis.csfs) )*", "; na=0) 
            sa = sa  * TableStrings.flushleft( 50, sb[1:end-2]; na=4)
            sb = "";   for conf in steps[i].finalConfigs     sb = sb * string(conf) * ", "    end
            sa = sa  * TableStrings.flushright( 5, string( length(steps[i].finalMultiplet.levels[1].basis.csfs) )*", "; na=0) 
            sa = sa  * TableStrings.flushleft( 50, sb[1:end-2]; na=4)
            minEn = 1000.;   maxEn = -1000.;
            for  p = 1:length(steps[i].initialMultiplet.levels),  q = 1:length(steps[i].finalMultiplet.levels)
                minEn = min(minEn, steps[i].initialMultiplet.levels[p].energy - steps[i].finalMultiplet.levels[q].energy)
                maxEn = max(maxEn, steps[i].initialMultiplet.levels[p].energy - steps[i].finalMultiplet.levels[q].energy)
            end
            minEn = Defaults.convertUnits("energy: from atomic", minEn);   maxEn = Defaults.convertUnits("energy: from atomic", maxEn)
            sa = sa * string( round(minEn)) * " ... " * string( round(maxEn))
            println(stream, sa)
        end
        println(stream, "  ", TableStrings.hLine(nx))
    end
    
    
    """
    `Cascade.generateBlocks(comp::Cascade.Computation, confs::Array{Configuration,1}, initalOrbitals::Dict{Subshell, Orbital}; 
                            sa::String="", printout::Bool=true)`  
        ... generate all block::Cascade.Block's, that need to be computed for this cascade, and compute also the corresponding multiplets.
            The different cascade approches enables one to realized follow different strategies how these block are selected and computed. 
            A blockList::Array{Cascade.Block,1} is returned.
    """
    function generateBlocks(comp::Cascade.Computation, confs::Array{Configuration,1}, initalOrbitals::Dict{Subshell, Orbital}; 
                            sa::String="", printout::Bool=true)
        blockList = Cascade.Block[]
        printSummary, iostream = Defaults.getDefaults("summary flag/stream")
        #
        if    comp.approach == AverageSCA()
            if  printout
            println("\n* Generate blocks " * sa)
            println("\n  In the cascade approach $(comp.approach), the following assumptions/simplifications are made: ")
            println("    + orbitals from the initial multiplet are applied throughout; ")
            println("    + all blocks (multiplets) are generated from single-CSF levels and without any configuration mixing even in the SC; ")
            println("    + only E1 dipole transitions are applied in all radiative decay stets; ")
            println("    + for each decay step, a (single) set of continuum orbitals with an configuration averaged energy is applied " *
                           "for all transitions of the same step. \n")
            if  printSummary   
            println(iostream, "\n* Generate blocks " * sa)
            println(iostream, "\n* In the cascade approach $(comp.approach), the following assumptions/simplifications are made: ")
            println(iostream, "    + orbitals from the initial multiplet are applied throughout; ")
            println(iostream, "    + all blocks (multiplets) are generated from single-CSF levels and without any configuration mixing even in the SC; ")
            println(iostream, "    + only E1 dipole transitions are applied in all radiative decay stets; ")
            println(iostream, "    + for each decay step, a (single) set of continuum orbitals with an configuration averaged energy is applied " *
                              "for all transitions of the same step. \n")
            end
            end     # printout
            #
            for  confa  in confs
                print("  Multiplet computations for $(string(confa)[1:end]) with $(confa.NoElectrons) electrons ... ")
                if  printSummary   println(iostream, "\n*  Multiplet computations for $(string(confa)[1:end]) with $(confa.NoElectrons) electrons ... ")   end
                multiplet = Basics.perform("computation: mutiplet from orbitals, no CI, CSF diagonal", [confa],  initalOrbitals, 
                                           comp.nuclearModel, comp.grid, comp.asfSettings; printout=false)
                # Shift the total energies of all levels if requested for the StepwiseDecayScheme
                if  typeof(comp.scheme) == StepwiseDecayScheme   &&   haskey(comp.scheme.chargeStateShifts, confa.NoElectrons)
                    energyShift = comp.scheme.chargeStateShifts[confa.NoElectrons]
                    multiplet   = Basics.shiftTotalEnergies(multiplet, energyShift)
                    print("shift all levels by $energyShift [a.u.] ... ")
                end
                push!( blockList, Cascade.Block(confa.NoElectrons, [confa], true, multiplet) )
                println("and $(length(multiplet.levels[1].basis.csfs)) CSF done. ")
            end
        elseif    comp.approach == SCA()
            if printout
            println("\n* Generate blocks " * sa)
            println("\n  In the cascade approach $(comp.approach), the following assumptions/simplifications are made: ")
            println("    + orbitals are generated independently for each multiplet (block); ")
            println("    + configuration interaction is included for each block; ")
            println("    + only E1 dipole transitions are applied in all radiative decay stets; \n")
            if  printSummary   
            println(iostream, "\n* Generate blocks " * sa)
            println(iostream, "\n* In the cascade approach $(comp.approach), the following assumptions/simplifications are made: ")
            println(iostream, "    + orbitals are generated independently for each multiplet (block); ")
            println(iostream, "    + configuration interaction is included for each block; ")
            println(iostream, "    + only E1 dipole transitions are applied in all radiative decay stets; \n")
            end
            end     # printout
            #
            i = 0
            for  confa  in confs
                ## i = i + 1;    if   i in [1,2, 4,5,6,7,8,9,10,11,12,13,14]  ||  i > 15   println("  Block $i omitted.");    continue    end
                ## i = i + 1;    if   i < 11  ||  i > 11   println("  Block $i omitted.");    continue    end
                print("  Multiplet computations for $(string(confa)[1:end]) with $(confa.NoElectrons) electrons ... ")
                if  printSummary   print(iostream, "* Multiplet computations for $(string(confa)[1:end]) with $(confa.NoElectrons) electrons ... ")   end
                basis     = Basics.performSCF([confa], comp.nuclearModel, comp.grid, comp.asfSettings; printout=false)
                multiplet = Basics.performCI(basis, comp.nuclearModel, comp.grid, comp.asfSettings; printout=false)
                # Shift the total energies of all levels if requested for the StepwiseDecayScheme
                if  typeof(comp.scheme) == StepwiseDecayScheme   &&   haskey(comp.scheme.chargeStateShifts, confa.NoElectrons)
                    energyShift = comp.scheme.chargeStateShifts[confa.NoElectrons]
                    multiplet   = Basics.shiftTotalEnergies(multiplet, energyShift)
                    print("shift all levels by $energyShift [a.u.] ... ")
                end
                push!( blockList, Cascade.Block(confa.NoElectrons, [confa], true, multiplet) )
                println("and $(length(multiplet.levels[1].basis.csfs)) CSF done. ")
            end
        else  error("Unsupported cascade approach.")
        end

        return( blockList )
    end
    

    """
    `Cascade.generateConfigurationList(multiplets::Array{Multiplet,1}, further::Int64, NoShake::Int64)`  
        ... generates all possible (decay) configurations with up to further holes and with NoShake displacements with regard
            to the given multiplets. First, all configuratons are generated for which the hole is either moved 'outwards' or 
            is moved and a second 'outer' hole is created; this step is repated further + 2 times to make sure that all relevant
            configurations are met. From the generated list, however, only those configurations are kept eventually with 
            up to further holes, when compared to the configurations of the given multiplets. A confList::Array{Configuration,1} 
            is returned.
    """
    function generateConfigurationList(multiplets::Array{Multiplet,1}, further::Int64, NoShake::Int64)
        # Determine all (different) configurations from multiplets
        confList = Configuration[]
        for mp  in  multiplets   
            cfList = Basics.extractNonrelativisticConfigurations(mp.levels[1].basis)
            for  cf in cfList   if  cf in confList   nothing   else   push!(confList, cf)      end      end
        end
        cList = copy(confList);   initialNoElectrons = multiplets[1].levels[1].basis.NoElectrons
        # First, move and generate new 'outer' hole without displacements
        for  fur = 1:further+1
            newConfList = Configuration[]
            for conf  in cList
                holeList = Basics.determineHoleShells(conf)
                for  holeShell in holeList
                    wa = generateConfigurationsWith1OuterHole(conf,  holeShell);   append!(newConfList, wa)
                    wa = generateConfigurationsWith2OuterHoles(conf, holeShell);   append!(newConfList, wa)
                end
            end
            newConfList = unique(newConfList)
            cList = newConfList
            append!(confList, newConfList)
        end
        # Make sure that only configurations with up to further holes are returned
        newConfList = Configuration[]
        for   conf in confList   
            if  conf.NoElectrons + further >= initialNoElectrons   push!(newConfList, conf)    end
        end
        # Add further shake-displacements if appropriate
        newConfList = unique(newConfList)
        return( newConfList )
    end


    """
    `Cascade.generateConfigurationsWith1OuterHole(conf,  holeShell)`  
        ... generates all possible (decay) configurations where the hole in holeShell is moved 'outwards'. 
            A confList::Array{Configuration,1} is returned.
    """
    function generateConfigurationsWith1OuterHole(conf::Configuration,  holeShell::Shell)
        shList = Basics.generate("shells: ordered list for NR configurations", [conf]);   i0 = 0
        for  i = 1:length(shList)
            if   holeShell == shList[i]    i0 = i;    break    end
        end
        if  i0 == 0   error("stop a")   end
        #
        # Now move the hole 'outwards'
        confList = Configuration[]
        for  i = i0+1:length(shList)
            if  haskey(conf.shells, shList[i])  &&  conf.shells[ shList[i] ] >= 1  
                newshells = copy( conf.shells )
                newshells[ shList[i] ] = newshells[ shList[i] ] - 1
                newshells[ holeShell ] = newshells[ holeShell ] + 1
                if  newshells[ holeShell ]  >  2*(2*holeShell.l + 1)    continue    end
                push!(confList, Configuration( newshells, conf.NoElectrons ) )
            end
        end

        return( confList )
    end


    """
    `Cascade.generateConfigurationsWith1OuterHole(configs::Array{Configuration,1},  holeShells::Array{Shell,1})`  
        ... generates all possible (decay) configurations where one hole from holeShells is moved 'outwards'. 
            A confList::Array{Configuration,1} is returned.
    """
    function generateConfigurationsWith1OuterHole(configs::Array{Configuration,1},  holeShells::Array{Shell,1})
        nconfList = Configuration[]
        for  conf in configs
            for  shell in holeShells
                dcs = Cascade.generateConfigurationsWith1OuterHole(conf, shell)
                append!(nconfList, dcs)
            end
        end
        nconfList = unique(nconfList)
        return(nconfList)
    end
    
    
    #==
    """
    `Cascade.generateConfigurationsWith2OuterHoles(conf,  holeShell)`  
        ... generates all possible (decay) configurations where the hole in holeShell is moved 'outwards'. 
            A confList::Array{Configuration,1} is returned.
    """
    function generateConfigurationsWith2OuterHoles(conf::Configuration,  holeShell::Shell)
         shList = Basics.generate("shells: ordered list for NR configurations", [conf]);   i0 = 0
         for  i = 1:length(shList)
             if   holeShell == shList[i]    i0 = i;    break    end
         end
         if  i0 == 0   error("stop a")   end
         #
         # Now move the hole 'outwards'
         confList = Configuration[]
         for  i = i0+1:length(shList)
             if  haskey(conf.shells, shList[i])  &&  conf.shells[ shList[i] ] >= 2  
                 newshells = copy( conf.shells )
                 newshells[ shList[i] ] = newshells[ shList[i] ] - 2
                 newshells[ holeShell ] = newshells[ holeShell ] + 1
                 if  newshells[ holeShell ]  >  2*(2*holeShell.l + 1)    continue    end
                 push!(confList, Configuration( newshells, conf.NoElectrons - 1 ) )
             end
             #
             for  j = i0+1:length(shList)
                 if  i != j   &&   haskey(conf.shells, shList[i])  &&  conf.shells[ shList[i] ] >= 1   &&
                                   haskey(conf.shells, shList[j])  &&  conf.shells[ shList[j] ] >= 1 
                     newshells = copy( conf.shells )
                     newshells[ shList[i] ] = newshells[ shList[i] ] - 1
                     newshells[ shList[j] ] = newshells[ shList[j] ] - 1
                     newshells[ holeShell ] = newshells[ holeShell ] + 1
                     if  newshells[ holeShell ]  >  2*(2*holeShell.l + 1)    continue    end
                     push!(confList, Configuration( newshells, conf.NoElectrons - 1 ) )
                 end
             end
         end
        #

        return( confList )
    end                          ==#
    
    
    """
    `Cascade.generateConfigurationsWith2OuterHoles(conf,  holeShell)`  
        ... generates all possible (decay) configurations where the hole in holeShell is moved 'outwards'. 
            A confList::Array{Configuration,1} is returned.
    """
    function generateConfigurationsWith2OuterHoles(conf::Configuration,  holeShell::Shell)
        shList = Basics.generate("shells: ordered list for NR configurations", [conf]);    i0 = 0
        if  !(holeShell in shList)     error("stop a")   end
        #
        for  (i,shell) in enumerate(shList)
            if   holeShell == shell    i0 = i;    break    end
        end
        #
        holes = Tuple{Int64, Int64}[]
        for  i = i0+1:length(shList)
            for  j = i:length(shList)   push!(holes, (i,j))     end
        end
        # Now create configurations with the new holes
        confList       = Configuration[]
        #
        for (i,j) in holes
            shells = copy(conf.shells)
            shells[holeShell] = shells[holeShell] + 1       # fill holeShell by an electron
            if  shells[holeShell]  >  2*(2*holeShell.l + 1) continue   end
            if  shells[ shList[i] ] - 1             < 0     continue   end
            if  shells[ shList[j] ] - 1             < 0     continue   end
            if  i == j  &&  shells[ shList[i] ] - 2 < 0     continue   end
            shells[ shList[i] ] = shells[ shList[i] ] - 1
            shells[ shList[j] ] = shells[ shList[j] ] - 1
            #
            push!(confList, Configuration(shells, conf.NoElectrons - 1))
        end
        #

        return( confList )
    end


    """
    `Cascade.generateConfigurationsWith2OuterHoles(configs::Array{Configuration,1},  holeShells::Array{Shell,1})`  
        ... generates all possible (decay) configurations where two holes from holeShells are moved 'outwards'. 
            A confList::Array{Configuration,1} is returned.
    """
    function generateConfigurationsWith2OuterHoles(configs::Array{Configuration,1},  holeShells::Array{Shell,1})
        nconfList = Configuration[]
        for  conf in configs
            for  shell in holeShells
                dcs = Cascade.generateConfigurationsWith2OuterHoles(conf, shell)
                append!(nconfList, dcs)
            end
        end
        nconfList = unique(nconfList)
        return(nconfList)
    end



    """
    `Cascade.groupDisplayConfigurationList(Z::Float64, confs::Array{Configuration,1}; sa::String="")` 
        ... group & display the configuration list into sublists with the same No. of electrons; this lists are displayed together 
            with an estimated total energy. An ordered confList::Array{Configuration,1} is returned with configurations of decreasing
            number of electrons.
    """
    function groupDisplayConfigurationList(Z::Float64, confs::Array{Configuration,1}; sa::String="")
        minNoElectrons = 1000;   maxNoElectrons = 0  
        for  conf in confs
            minNoElectrons = min(minNoElectrons, conf.NoElectrons)
            maxNoElectrons = max(maxNoElectrons, conf.NoElectrons)
        end
        #
        printSummary, iostream = Defaults.getDefaults("summary flag/stream")
        #
        println("\n* Electron configuration(s) used:    " * sa)
        ## @warn "*** Limit to just 4 configurations for each No. of electrons. ***"                       ## delete nxx
        if  printSummary   println(iostream, "\n* Electron configuration(s) used:    " * sa)    end
        confList = Configuration[];   nc = 0
        for  n = maxNoElectrons:-1:minNoElectrons
            nxx = 0                                                                                        ## delete nxx
            println("\n  Configuration(s) with $n electrons:")
            if  printSummary   println(iostream, "\n    Configuration(s) with $n electrons:")      end
            nd = 0
            for  conf in confs  nd = max(nd, length("      " * string(conf)))   end
            for  conf in confs
                if n == conf.NoElectrons  
                    ## nxx = nxx + 1;    if nxx > 4   break    end                                         ## delete nxx
                    nc = nc + 1
                    push!(confList, conf ) 
                    if  Z > 36.0    wa = 0.
                    else            wa = Semiempirical.estimate("binding energy", round(Int64, Z), conf);    
                                    wa = Defaults.convertUnits("energy: from atomic", wa)
                    end
                    sb = "   av. BE = "  * string( round(-wa) ) * "  " * TableStrings.inUnits("energy")
                    sd = "      " * string(conf) * "                                "
                    println(sd[1:nd+3] * sb * "      ($nc)" )
                    if  printSummary   println(iostream, sd[1:nd+3] * sb * "      ($nc)")      end
                end  
            end
        end
        
        println("\n  A total of $nc configuration have been defined for this " * sa * "cascade, and selected configurations could be " *
                "removed here:  [currently not supported]")
        if  printSummary   println(iostream, "\n* A total of $nc configuration have been defined for this cascade, and selected " *
                                             "configurations could be removed here:  [currently not supported]")      end
        return( confList )
    end


    """
    `Cascade.modifySteps(stepList::Array{Cascade.Step,1})` 
        ... allows the user to modify the steps, for instance, by deleting selected steps of the cascade or by modifying the settings of
            one or several steps. A newStepList::Array{Cascade.Step,1} for which the transition data are eventually computed.
    """
    function modifySteps(stepList::Array{Cascade.Step,1})
        #
        newStepList = Cascade.Step[]
        #
        println("\n* Here, modify the individual steps explicitly in the code, if needed, ...... and just do it !!")
        # 
        #  Delete individual steps from stepList
        #  if  i in [1,2,5, ...] modify the particular settings, etc.
        for  i = 1:length(stepList)
            step = stepList[i]
            #
            if  i in []
                println("  Modify step $i :")
                newStep = Cascade.Step(step.process, step.settings, step.initialConfs, step.finalConfs, step.initialMultiplet, step.initialMultiplet)
                push!(newStepList, newStep)
            else
                push!(newStepList, step)
            end
        end
        #
        # wa = [1,2,3]
        # delete from list
        #
        println("\n  A total of $(length(newStepList)) steps are still defined in the cascade.")
        printSummary, iostream = Defaults.getDefaults("summary flag/stream")
        if  printSummary   println(iostream, "\n* A total of $(length(newStepList)) steps are still defined in the cascade.")    end      
        
        return( newStepList )
    end
