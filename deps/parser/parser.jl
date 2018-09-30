using JSON

typestring = "PolymakeWrap.Polymake."
## Needs to be there, because apparently nobody thought about having ${} or something
undotted_typestring = typestring[1:length(typestring)-1]

type_translate_list = Dict(
    "BigObject"          => typestring * "pm_perl_Object",
    "OptionSet"          => typestring * "pm_perl_OptionSet",
    "Matrix"             => typestring * "pm_Matrix{T} where T",
    "Matrix<Rational>"   => typestring * "pm_Matrix{" * typestring * "pm_Rational}",
    "Matrix<Integer>"    => typestring * "pm_Matrix{" * typestring * "pm_Integer}",
    "Vector"             => typestring * "pm_Vector{T} where T",
    "Vector<Rational>"   => typestring * "pm_Vector{" * typestring * "pm_Rational}",
    "Vector<Integer>"    => typestring * "pm_Vector{" * typestring * "pm_Integer}",
    "Integer"            => typestring * "pm_Integer",
    "Rational"           => typestring * "pm_Rational",
    "Set"                => typestring * "pm_Set",
    "Anything"           => "Any"
)

function julia_function_string(julia_name::String, polymake_name::String, app_name::String, julia_args::String, call_args::String, parameter_string::String )
    return """
function $julia_name( $julia_args )
    $undotted_typestring.application( $app_name )
    return $undotted_typestring.call_function( "$polymake_name$parameter_string", Array{Any,1}([ $call_args ]) )
end
"""
end

function julia_method_string(julia_name::String, polymake_name::String, app_name::String, julia_args::String, call_args::String, parameter_string::String )
    return """
function $julia_name( $julia_args )
    $undotted_typestring.application( $app_name )
    return $undotted_typestring.call_method( "$polymake_name$parameter_string", dispatch_obj, Array{Any,1}([ $call_args ]) )
end
"""
end

function create_argument_string_from_type( type_string::String, number::Int64 )
    ## Special case for BigObject (we do not care 'bout the type here)
    if startswith(typestring,"BigObject")
        return "arg" * string(number) * "::" * type_translate_list["BigObject"]
    end
    ## We only translate the known cases
    if !haskey(type_translate_list,type_string)
        println("Unknown type: " * type_string)
        return false
    end
    return "arg" * string(number) * "::" * type_translate_list[type_string]
end

function parse_function_definition(method_dict::Dict, app_name::String)
    name = method_dict["name"]
    arguments = method_dict["arguments"]
    mandatory = method_dict["mandatory"]
    type_params = method_dict["type_params"]
    is_method = haskey(method_dict,"method_of")
    ## for now, we use the same name for Julia and Polymake
    julia_name = name
    polymake_name = name

    ## Check for option set
    has_option_set = last(arguments) == "OptionSet"

    ## Make type parameters
    param_list_header = Array{String,1}()
    param_list = Array{String,1}()
    for i in 1:type_params
        push!(param_list_header,"param$i::String")
        push!(param_list,"\$param$i")
    end
    parameter_string = "<" * join(param_list,",") * ">"

    ## Compute the argument range
    max_argument_number = length(arguments) - (has_option_set ? 1 : 0)
    min_argument_number = mandatory

    ## Option set parameter
    option_set_argument = "option_set::" * type_translate_list["OptionSet"]
    option_set_parameter = "option_set"

    ## Real arguments
    if is_method
        argument_list_header = Array{String,1}(["dispatch_obj::$undotted_typestring.pm_perl_Object"])
        ## Fixme: good?
        min_argument_number = min_argument_number + 1
        max_argument_number = max_argument_number + 1
    else
        argument_list_header = Array{String,1}()
    end
    argument_list = Array{String,1}()

    for i in 1:max_argument_number
        push!(argument_list_header,create_argument_string_from_type(arguments[i],i))
        push!(argument_list,"arg$i")
    end

    if contains(==,argument_list_header, false)
        for i in 1:length(argument_list_header)
            if argument_list_header[i] == false
                if i <= min_argument_number
                    println("Cannot parse function " * name * " due to unparsable argument")
                    return false
                else
                    println("Ignoring " * string(max_argument_number-i) * " arguments of function " * name)
                    max_argument_number = i - 1
                end
            end
        end
    end

    return_string = ""

    if is_method
        function_string_creator = julia_function_string
    else
        function_string_creator = julia_method_string
    end

    julia_argument_list = vcat(param_list_header,argument_list_header)
    for number_arguments in min_argument_number:max_argument_number
        julia_args = join(julia_argument_list[1:number_arguments+type_params],",")
        if is_method
            call_args = join(argument_list[1:number_arguments - 1],",")
        else
            call_args = join(argument_list[1:number_arguments],",")
        end
        append!(return_string,function_string_creator(julia_name,polymake_name,app_name,julia_args,call_args,parameter_string))
        if has_option_set
            julia_args = julia_args * "," * option_set_argument
            call_args = call_args * "," * option_set_parameter
            append!(return_string,function_string_creator(julia_name,polymake_name,app_name,julia_args,call_args,parameter_string))
        end
    end
    return return_string
end

function parse_app_definitions(filename::String,outputfilename::String)
    println("Parsing "*filename)
    parsed_dict = JSON.Parser.parsefile(filename)
    app_name = parsed_dict["app"]
    return_string = """
module $app_name
"""
    for current_function in parsed_dict["functions"]
        return_value = parse_function_definition(current_function,app_name)
        if return_value == false
            println("Unable to parse " * string(current_function))
        else
            append!(return_string,return_value)
        end
    end
    append!(return_string,"\nend\n")
    open(outputfilename,"w") do outputfile
        print(outputfile,return_string)
    end
end

# println("Parsing "*filename)
# parsed_dict = JSON.Parser.parsefile(filename)

# wrapper_files = filter(y->contains(y,"wrap-"),filter(x->contains(x,".cpperl"), readdir("/home/sebastian/Software/polymake_devel_git/apps/polytope/cpperl")))

# filenames_list = []

# open( abspath( "src/generated") * "/function_calls.cpp", "w") do function_calls
# open( abspath( "src/generated") * "/forwards.cpp","w") do forwards
# println(forwards,"namespace polymake{ namespace polytope{")
# for filename in wrapper_files
#     wrapper_name = replace(filename,".cpperl","")
#     filename_cpp = "additional_wrappers_"*wrapper_name*".cpp"
#     push!(filenames_list,filename_cpp)
#     open( abspath( "src/generated") * "/" * filename_cpp,"w") do wrappers
#         filename_origin = "/home/sebastian/Software/polymake_devel_git/apps/polytope/cpperl/$filename"
#         result = parse_cpperl_file(filename_origin)
#         println(wrappers,"#define POLYMAKE_NO_EMBEDDED_RULES 1")
#         for current_line in result[1]
#             println(wrappers,current_line)
#         end
        
#         println(wrappers,"#include \"jlcxx/jlcxx.hpp\"")
#         println(wrappers,"namespace polymake{ namespace polytope{ ")
        
#         wrapper_name = replace(wrapper_name,"-","_")
#         println(wrappers,"void adder_$wrapper_name(jlcxx::Module& polymake){")

#         for current_line in result[2]
#             println(wrappers,current_line)
#         end
#         println(wrappers,"}")
#         println(wrappers,"}}")
#         println(function_calls,"polymake::polytope::adder_$wrapper_name(polymake);")
#         println(forwards,"extern void adder_$wrapper_name(jlcxx::Module&);")
#     end
# end
# println(forwards,"}}")
# end
# end

# open( abspath( "src/generated") * "/" * "CMakeLists.txt", "w") do files
#     print(files,"set(GENERATED_SRCS \"")
#     for current_line in filenames_list
#         print(files,"\${CMAKE_CURRENT_SOURCE_DIR}/"*current_line*" ")
#     end
#     print(files,"\" PARENT_SCOPE)")
# end