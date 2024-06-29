
"""
`module  JAC.Plasma`  
... a submodel of JAC that contains all methods to set-up and process (simple) plasma computations 
    and simulations.
"""
module Plasma

using  Dates, JLD2, Printf 
using  ..AtomicState, ..Basics, ..Bsplines, ..Defaults, ..ManyElectron, ..Nuclear, ..Radial, ..RadialIntegrals, 
       ..Semiempirical, ..TableStrings, ..FormFactor, ..PhotoEmission, ..PhotoIonization, ..AutoIonization


"""
`abstract type Plasma.AbstractPlasmaScheme` 
    ... defines an abstract type to distinguish different kinds of plasma computations; see also:
    
    + struct AverageAtomScheme    
        ... to perform an average-atom computation.
    + struct LineShiftScheme    
        ... to compute the energy shifts and properties of atomic/ionic lines in some selected plasma model.
    + struct SahaBoltzmannScheme    
        ... to compute thermodynamic properties of a Saha-Boltzmann LTE mixture.
"""
abstract type  AbstractPlasmaScheme       end


"""
`struct  Plasma.AverageAtomScheme  <:  Plasma.AbstractPlasmaScheme`  
    ... a struct to perform an average-atom computation.

    + nMax                  ::Int64                ... maximum principal quantum number for the subshells of the AA model.
    + lMax                  ::Int64                ... maximum orbital quantum number for the subshells of the AA model.
    + scField               ::AbstractScField      ... maximum orbital quantum number for the subshells of the AA model.
    + calcPhotoionizationCs ::Bool                 ... True, if photoionization cross sections are to be calculated.
    + calcFormFactor        ::Bool                 ... True, if the form factor need to be calculated.
    + calcScatteringFactor  ::Bool                 ... True, if scattering factor need to be calculated.
    + piSubshells           ::Array{Subshell,1}    ... Bound subshells to be included into the photoionization cross sections.
    + omegas                ::Array{Float64,1}     ... energies for the photoionization & scattering factors [in a.u.].
    + qValues               ::Array{Float64,1}     ... q-values for calculating the form factor [in a.u.].
"""
struct   AverageAtomScheme  <:  Plasma.AbstractPlasmaScheme
    nMax                    ::Int64
    lMax                    ::Int64
    scField                 ::AbstractScField
    calcPhotoionizationCs   ::Bool          
    calcFormFactor          ::Bool             
    calcScatteringFactor    ::Bool              
    piSubshells             ::Array{Subshell,1} 
    omegas                  ::Array{Float64,1} 
    qValues                 ::Array{Float64,1} 
end  


"""
`Plasma.AverageAtomScheme()`  ... constructor for an 'default' instance of a Plasma.AverageAtomScheme.
"""
function AverageAtomScheme()
    AverageAtomScheme( 1, 0, Basics.AaHSField(), false, false, false, Subshell[], Float64[], Float64[] )
end


# `Base.string(scheme::AverageAtomScheme)`  ... provides a String notation for the variable scheme::AverageAtomScheme.
function Base.string(scheme::AverageAtomScheme)
    sa = "Average-atom computation with nMax =$(scheme.nMax) and lMax =$(scheme.lMax):"
    return( sa )
end


# `Base.show(io::IO, scheme::AverageAtomScheme)`  ... prepares a proper printout of the scheme::AverageAtomScheme.
function Base.show(io::IO, scheme::AverageAtomScheme)
    sa = Base.string(scheme);                print(io, sa)
    println(io, "\nscField:                  $(scheme.scField)  ")
    println(io, "calcPhotoionizationCs:      $(scheme.calcPhotoionizationCs)  ")
    println(io, "calcFormFactor:             $(scheme.calcFormFactor)  ")
    println(io, "calcScatteringFactor:       $(scheme.calcScatteringFactor)  ")
    println(io, "piSubshells:                $(scheme.piSubshells)  ")
    println(io, "omegas:                     $(scheme.scField)  ")
    println(io, "qValues:                    $(scheme.qValues)  ")
end


"""
`struct  Plasma.LineShiftScheme  <:  Plasma.AbstractPlasmaScheme`  
    ... defines a type for the details and parameters of computing level energies with plasma interactions.

    + plasmaModel      ::AbstractPlasmaModel        ... Specify a particular plasma model, e.g. ion-sphere, debye.
    + lambdaDebye      ::Float64                    ... The lambda parameter of different plasma models.
    + ionSphereR0      ::Float64                    ... The effective radius of the ion-sphere model.
    + NoBoundElectrons ::Int64                      ... Effective number of bound electrons.
"""
struct LineShiftScheme  <:  Plasma.AbstractPlasmaScheme
    plasmaModel        ::AbstractPlasmaModel
    lambdaDebye        ::Float64 
    ionSphereR0        ::Float64
    NoBoundElectrons   ::Int64
end 


"""
`Plasma.LineShiftScheme()`  ... constructor for a standard instance of Plasma.LineShiftScheme.
"""
function LineShiftScheme()
    LineShiftScheme(DebyeHueckel(), 0.25, 0., 0)
end


# `Base.show(io::IO, scheme::Plasma.LineShiftScheme)`  ... prepares a proper printout of the scheme::Plasma.LineShiftScheme.
function Base.show(io::IO, scheme::Plasma.LineShiftScheme)
    println(io, "plasmaModel:            $(scheme.plasmaModel)  ")
    println(io, "lambdaDebye:            $(scheme.lambdaDebye)  ")
    println(io, "ionSphereR0:            $(scheme.ionSphereR0)  ")
    println(io, "NoBoundElectrons:       $(scheme.NoBoundElectrons)  ")
end


"""
`struct  Plasma.SahaBoltzmannScheme  <:  Plasma.AbstractPlasmaScheme`  
    ... a struct to thermodynamic properties of a Saha-Boltzmann LTE mixture..

    + calcLTE               ::Bool                 ... True, if the Saha-Boltzmann equilibrium densities should be calculated.         
    + maxNoIonLevels        ::Int64                ... (maximum) No of ionic levels for any charge state of the ions in the mixture.
    + NoChargeStates        ::Int64                
        ... No of the ions in the ionic mixture that are taken to be into account. These charge states are `centered' around those 
            charge state with an ionisation potential that is closest to kT.
    + NoExcitations         ::Int64                
        ... No of excitations (S, D, T) that are taken into account with regard to the reference (ground) configuration of the ions.
            This number is taken as a second qualifier to characterize the quality of the ionic-level data. Usually, NoExcitations = 1,2.
    + upperShellNo         ::Int64                
        ... upper-most princicpal quantum number n for which orbitals are taken into account into the ionic-level computations;
            this is often chosen upperShellNo= 4..8.
    + isotopicMixture      ::Array{Basics.IsotopicFraction,1}   
        ... List of (non-normlized) isotopic fractions that form the requested mixture; the fractions will first be renormalized
            to 1 in course of the Saha-Boltzmann LTE computations.
    + isotopeFilenames      ::Array{String,1}     
        ... set of files names from which the ionic-level data can be read in for the different isotopes (Z,A) in the mixture.
    
"""
struct  SahaBoltzmannScheme  <:  Plasma.AbstractPlasmaScheme
    calcLTE                 ::Bool        
    maxNoIonLevels          ::Int64 
    NoChargeStates          ::Int64                
    NoExcitations           ::Int64                
    upperShellNo            ::Int64                
    isotopicMixture         ::Array{Basics.IsotopicFraction,1}   
    isotopeFilenames        ::Array{String,1}     
end  


"""
`Plasma.SahaBoltzmannScheme()`  ... constructor for an 'default' instance of a Plasma.SahaBoltzmannScheme.
"""
function SahaBoltzmannScheme()
    SahaBoltzmannScheme( false, 0., 0., 0., 0., IsotopicFraction[], String[] )
end


# `Base.string(scheme::SahaBoltzmannScheme)`  ... provides a String notation for the variable scheme::SahaBoltzmannScheme.
function Base.string(scheme::SahaBoltzmannScheme)
    sa = "Saha-Boltzmann computation with of an ionic mixture:"
    return( sa )
end


# `Base.show(io::IO, scheme::SahaBoltzmannScheme)`  ... prepares a proper printout of the scheme::SahaBoltzmannScheme.
function Base.show(io::IO, scheme::SahaBoltzmannScheme)
    sa = Base.string(scheme);             println(io, sa)
    println(io, "calcLTE:           $(scheme.calcLTE)  ")
    println(io, "maxNoIonLevels:    $(scheme.maxNoIonLevels)  ")
    println(io, "NoChargeStates:    $(scheme.NoChargeStates)  ")
    println(io, "NoExcitations:     $(scheme.NoExcitations)  ")
    println(io, "upperShellNo:      $(scheme.upperShellNo)  ")
    println(io, "isotopicMixture:   $(scheme.isotopicMixture)  ")
    println(io, "isotopeFilenames:  $(scheme.isotopeFilenames)  ")
end


"""
`struct  Plasma.Settings`  ... defines a type for the details and parameters of computing photoionization lines.

    + temperature               ::Float64     ... Plasma temperature in [K].
    + density                   ::Float64     ... Plasma density in [g/cm^3].
    + useNumberDensity          ::Bool    
        ... true, if the density above is taken as (total ion) number density ni, and false otherwise.
"""
struct Settings 
    temperature                 ::Float64     
    density                     ::Float64 
    useNumberDensity            ::Bool     
end 


"""
`Plasma.Settings()`  ... constructor for the default values of plasma computations
"""
function Settings()
    Settings(0., 0., false)
end


"""
`Plasma.Settings(set::Plasma.Settings;`

        temperature=..,         density=..,         useNumberDensity =..)
                    
    ... constructor for modifying the given Plasma.Settings by 'overwriting' the previously selected parameters.
"""
function Settings(set::Plasma.Settings;    
    temperature::Union{Nothing,Float64}=nothing,                            density::Union{Nothing,Float64}=nothing,
    useNumberDensity::Union{Nothing,Bool}=nothing)  
    
    if  temperature      == nothing   temperaturex      = set.temperature        else  temperaturex      = temperature       end 
    if  density          == nothing   densityx          = set.density            else  densityx          = density           end 
    if  useNumberDensity == nothing   useNumberDensityx = set.useNumberDensity   else  useNumberDensityx = useNumberDensity  end 

    Settings( temperaturex, densityx, useNumberDensityx )
end


# `Base.show(io::IO, settings::Plasma.Settings)`  ... prepares a proper printout of the variable settings::Plasma.Settings.
function Base.show(io::IO, settings::Plasma.Settings) 
    println(io, "temperature:               $(settings.temperature)  ")
    println(io, "density:                   $(settings.density)  ")
    println(io, "useNumberDensity:          $(settings.useNumberDensity)  ")
end


"""
`struct  Computation`  
    ... defines a type for defining  (simple) plasma computation for atoms and ions in a given set of
        reference configurations. It also support different atomic processes under plasma conditions.
        The plasma environment is typical described in terms of its temperature, density, etc.

    + scheme                         ::AbstractPlasmaScheme            ... Scheme (kind) of plasma computation.
    + nuclearModel                   ::Nuclear.Model                   ... Model, charge and parameters of the nucleus.
    + grid                           ::Radial.Grid                     ... The radial grid to be used for the computation.
    + refConfigs                     ::Array{Configuration,1}          ... A list of non-relativistic configurations.
    + asfSettings                    ::AsfSettings                     
        ... Provides the settings for the SCF process (under plasma conditions) and the associated CI calculations.
    + initialMultiplet               ::Multiplet                       ... An initial multiplet for plasma processes.
    + finalMultiplet                 ::Multiplet                       ... A final multiplet for plasma processes.
    + processSettings                ::Basics.AbstractProcessSettings  
        ... Provides the settings for the selected process; they are the same as in the atomic case ... but might
            include plasma-specific extensions.
    + settings                       ::Plasma.Settings                 ... communicates the properties of the plasma
"""
struct  Computation
    scheme                           ::AbstractPlasmaScheme 
    nuclearModel                     ::Nuclear.Model
    grid                             ::Radial.Grid
    refConfigs                       ::Array{Configuration,1}
    asfSettings                      ::AsfSettings                     
    initialMultiplet                 ::Multiplet 
    finalMultiplet                   ::Multiplet  
    processSettings                  ::Basics.AbstractProcessSettings  
    settings                         ::Plasma.Settings
end 


"""
`Plasma.Computation()`  ... constructor for an 'empty' instance::Plasma.Computation.
"""
function Computation()
    Computation(AverageAtomScheme(), Nuclear.Model(1.), Radial.Grid(), Configuration[], AsfSettings(), Multiplet(), Multiplet(), 
                Basics.NoProcessSettings(), Plasma.Settings() )
end


"""
`Plasma.Computation(comp::Plasma.Computation;`

    scheme=..,                  nuclearModel=..,            grid=..,                refConfigs=..,              asfSettings=..,     
    initialMultiplet=..,        finalMultiplet=..,      processSettings=..,         settings=..,
    printout::Bool=false)
                    
    ... constructor for modifying the given Plasma.Computation by 'overwriting' the previously selected parameters.
"""
function Computation(comp::Plasma.Computation;
    scheme::Union{Nothing,Plasma.AbstractPlasmaScheme}=nothing,                  
    nuclearModel::Union{Nothing,Nuclear.Model}=nothing,                         grid::Union{Nothing,Radial.Grid}=nothing,      
    refConfigs::Union{Nothing,Array{Configuration,1}}=nothing,                  asfSettings::Union{Nothing,AsfSettings}=nothing, 
    initialMultiplet::Union{Nothing,Multiplet}=nothing,                         finalMultiplet::Union{Nothing,Multiplet}=nothing, 
    processSettings::Union{Nothing,Any}=nothing,                                settings::Union{Nothing,Plasma.Settings}=nothing, 
    printout::Bool=false)
    
    if  scheme                  == nothing  schemex                  = comp.scheme                  else  schemex                  = scheme                   end 
    if  nuclearModel            == nothing  nuclearModelx            = comp.nuclearModel            else  nuclearModelx            = nuclearModel             end 
    if  grid                    == nothing  gridx                    = comp.grid                    else  gridx                    = grid                     end 
    if  refConfigs              == nothing  refConfigsx              = comp.refConfigs              else  refConfigsx              = refConfigs               end 
    if  asfSettings             == nothing  asfSettingsx             = comp.asfSettings             else  asfSettingsx             = asfSettings              end 
    if  initialMultiplet        == nothing  initialMultipletx        = comp.initialMultiplet        else  initialMultipletx        = initialMultiplet         end 
    if  finalMultiplet          == nothing  finalMultipletx          = comp.finalMultiplet          else  finalMultipletx          = finalMultiplet           end 
    if  processSettings         == nothing  prsx                     = comp.processSettings         else  prsx                     = processSettings          end 
    if  settings                == nothing  settingsx                = comp.settings                else  settingsx                = settings                 end 
    
    
    cp = Computation(schemex, nuclearModelx, gridx, refConfigsx, asfSettingsx, initialMultipletx, finalMultipletx,  
                        prsx, settingsx) 
                        
    if printout  Base.show(cp)      end
    return( cp )
end


"""
`Plasma.Computation( ... example for plasma SCF computations)`  

        grid     = Radial.Grid(true)
        nuclearM = Nuclear.Model(18., "Fermi")
        ...
        refConfigs  = [Configuration("[Ne] 3s^2 3p^5")]
        Plasma.Computation(Plasma.Computation(), grid=grid, nuclearModel=nuclearM, refConfigs=refConfigs, asfSettings=... )
    
    ... These simple examples can be further improved by overwriting the corresponding parameters.
"""
function Computation(wa::Bool)    
    Plasma.Computation()    
end


# `Base.string(comp::Plasma.Computation)`  ... provides a String notation for the variable comp::Plasma.Computation.
function Base.string(comp::Plasma.Computation)
    sa = "Plasma computation:  for Z = $(comp.nuclearModel.Z), "
    if  comp.processSettings != Nothing   
        sa = sa * "for the plasma scheme   \n$(comp.scheme)"
        sa = sa * "\nreference configs       $(comp.refConfigs) "
        sa = sa * "\ninital multiplet        $(comp.initialMultiplet.name) "
        sa = sa * "\nfinal multiplet         $(comp.finalMultiplet.name) "
        sa = sa * "\nprocess settings        $(typeof(comp.processSettings)) " ##   with \n$(comp.processSettings) "
    end
    return( sa )
end


# `Base.show(io::IO, comp::Plasma.Computation)`  ... prepares a printout of comp::Plasma.Computation.
function Base.show(io::IO, comp::Plasma.Computation)
    sa = Base.string(comp);             print(io, sa, "\n")
    println(io, "nuclearModel:          $(comp.nuclearModel)  ")
    println(io, "grid:                  $(comp.grid)  ")
    #
    # For the computation of some given atomic process
    if  comp.processSettings != Nothing
    println(io, "processSettings:              \n$(comp.processSettings)  ")
    #
    end
end

#==  ... This can be used to establish other Plasma.AbstractPlasmaScheme's
"""
`Plasma.perform(computation::Plasma.Computation)`  
    ... to perform the computation as prescribed by comp. All relevant intermediate and final results are printed to screen (stdout). 
        The procedure always performs an average-atom SCF and CI computation and generates the associated basis.
        Nothing is returned.

`Plasma.perform(scheme:Plasma.AbstractPlasmaScheme, computation::Plasma.Computation; output=true)`  
    ... to perform the same but to return the complete output in a dictionary; the particular output depends on the type and 
        specifications of the computations but can easily accessed by the keys of this dictionary.
"""
function  perform(scheme::Plasma.AbstractPlasmaScheme, computation::Plasma.Computation; output::Bool=false)
    if  output    results = Dict{String, Any}()    else    results = nothing    end
    nModel = computation.nuclearModel

    # Perform an average-atom computation
    if  typeof(scheme) == Plasma.AbstractPlasmaScheme
        #
        #
    elseif  false 
        # Another scheme,  not yet worked out
        ## if  length(computation.refConfigs) != 0
        basis     = AverageAtom.performSCF(computation.refConfigs, nModel, computation.grid, computation.asfSettings)
        multiplet = AverageAtom.performCI( basis, nModel, computation.grid, computation.asfSettings)
        #
        if output    results = Base.merge( results, Dict("multiplet:" => multiplet) ) 
                        results = Base.merge( results, Dict("grid:"      => computation.grid) )  end
        
        # Now compute all requested properties
        if      typeof(computation.propertySettings) == Einstein.Settings
            outcome = Einstein.computeLines(multiplet,        computation.grid, computation.propertySettings)    
            if output    results = Base.merge( results, Dict("plasma Einstein lines:" => outcome) )         end
            #
        elseif  typeof(computation.propertySettings)) == FormFactor.Settings 
            outcome = FormFactor.computeOutcomes(multiplet, nModel, computation.grid, settings)         
            if output    results = Base.merge( results, Dict("plasma form factor outcomes:" => outcome) )   end
        end
        
    elseif  false 
        # Another scheme,  not yet worked out
        if  length(computations.initialMultiplet.levels) == 0     error("Missing initialMultiplet ... ")    end
        if  length(computations.finalMultiplet.levels)   == 0     error("Missing finalMultiplet ... ")      end
            
        # Calculate a small set of processes with these initial and final multiplets; the user has to make sure that
        # these multiplets are appropriate for the given plasma environment.
        if      typeof(computation.processSettings) == AutoIonization.Settings 
            outcome = AutoIonization.computeLines(finalMultiplet, initialMultiplet, nModel, computation.grid, computation.processSettings) 
            if output    results = Base.merge( results, Dict("plasma autoIonization lines:" => outcome) )   end
        elseif  typeof(computation.processSettings) == PhotoIonization.Settings   
            outcome = PhotoIonization.computeLines(finalMultiplet, initialMultiplet, nModel, computation.grid, computation.processSettings) 
            if output    results = Base.merge( results, Dict("plasma photoionization lines:" => outcome) )  end
        elseif  typeof(computation.processSettings) == PhotoEmission.Settings
            outcome = PhotoEmission.computeLines(finalMultiplet, initialMultiplet, computation.grid, computation.processSettings) 
            if output    results = Base.merge( results, Dict("plasma radiative lines:" => outcome) )        end
        else
            error("stop b")
        end
    end
    
    Defaults.warn(PrintWarnings())
    Defaults.warn(ResetWarnings())
    return( results )
end  ==#


"""
`struct  Plasma.PartialWaveData`  
    ... defines a type to collect for partial-waves (kappa) cross sections, rates, etc. at different energies

    + kappa    ::Int64                            ... kappa
    + pairs    ::Vector{Tuple{Float64, Float64}}  
        ... vector of pairs, for instance (energy, cs), to later combine data in a proper manner.
"""
struct PartialWaveData 
    kappa     ::Int64      
    pairs     ::Vector{Tuple{Float64, Float64}}  
end 


"""
`Plasma.PartialWaveData()`  ... constructor for the default values of Plasma.PartialWaveData set
"""
function PartialWaveData()
    PartialWaveData( -1, Tuple{Float64, Float64}[] )
end


# `Base.show(io::IO, data::Plasma.PartialWaveData)`  ... prepares a proper printout of the variable settings::Plasma.PartialWaveData.
function Base.show(io::IO, data::Plasma.PartialWaveData) 
    println(io, "kappa:          $(data.kappa)  ")
    println(io, "pairs:          $(data.pairs)  ")
end



include("module-Plasma-inc-average-atom.jl")
include("module-Plasma-inc-line-shifts.jl")
include("module-Plasma-inc-saha-boltzmann-mixture.jl")


end # module
