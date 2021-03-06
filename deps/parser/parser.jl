using JSON

struct UnparsablePolymakeFunction <: Exception
    msg::String
    UnparsablePolymakeFunction(function_name) = new("Cannot parse function: $function_name")
end

jsonfolder = joinpath(@__DIR__, "json")
filenames_list = filter(x->endswith(x,"json"), readdir(jsonfolder))


outputfolder = abspath(joinpath(@__DIR__, "..", "..", "src","generated"))
include_file = abspath(joinpath(@__DIR__, "..", "..", "src","generated","includes.jl"))
additional_json_files_path = abspath(joinpath(@__DIR__, "..", "..", "JSON" ) )
isfile(include_file) && rm(include_file)


function julia_function_string(julia_name::String, polymake_name::String, app_name::String )

    return """
function $julia_name(args...; keep_PropertyValue=false, call_as_void=false, kwargs...)
    application( \"$app_name\" )
    if call_as_void
        internal_call_function_void( \"$polymake_name\", c_arguments(args...;kwargs...))
        return
    else
        return_value = internal_call_function( \"$polymake_name\", c_arguments(args...;kwargs...))
    end
    if keep_PropertyValue
        return return_value
    else
        return convert_from_property_value(return_value)
    end
end

"""
end

function julia_method_string(julia_name::String, polymake_name::String, app_name::String )
    return """
function $julia_name(dispatch_object,args...; keep_PropertyValue=false, call_as_void=false, kwargs...)
    application( \"$app_name\" )
    if call_as_void
        internal_call_method_void( \"$polymake_name\", dispatch_object, c_arguments(args...;kwargs...))
        return
    else
        return_value = internal_call_method( \"$polymake_name\", dispatch_object, c_arguments(args...;kwargs...))
    end
    if keep_PropertyValue
        return return_value
    else
        return convert_from_property_value(return_value)
    end
end

"""
end

function parse_definition(method_dict::Dict, app_name::String, uniqueness_checker)
    name = method_dict["name"]
    is_method = haskey(method_dict,"method_of")

    ## for now, we use the same name for Julia and Polymake
    julia_name = name
    polymake_name = name

    if julia_name in uniqueness_checker
        return "",uniqueness_checker
    end
    push!(uniqueness_checker,julia_name)
    if is_method
        function_string_creator = julia_method_string
    else
        function_string_creator = julia_function_string
    end
    return function_string_creator(julia_name,polymake_name,app_name),uniqueness_checker

end

function parse_app_definitions(filename::String,outputfileposition::String,include_file::String,additional_json_files_path::String)
    println("Parsing "*filename)
    parsed_dict = JSON.Parser.parsefile(filename)
    app_name = parsed_dict["app"]
    additional_json_file_name = abspath( joinpath( additional_json_files_path, app_name*".json" ) )
    if isfile(additional_json_file_name)
        additional_dict = JSON.Parser.parsefile(additional_json_file_name)
        if additional_dict["app"] != parsed_dict["app"]
            @warn("Parsed wrong additional dict")
        end
        for i in additional_dict["functions"]
            push!(parsed_dict["functions"],i)
        end
    end
    return_string = """
module $app_name

import ..internal_call_function, ..internal_call_method,
       ..internal_call_function_void, ..internal_call_method_void,
       ..convert_from_property_value, ..c_arguments, ..application

"""
    uniqueness_checker = []
    for current_function in parsed_dict["functions"]
        return_value = ""
        try
            (return_value,uniqueness_checker) = parse_definition(current_function,app_name,uniqueness_checker)
        catch exception
            if exception isa UnparsablePolymakeFunction
                @warn(exception.msg)
            end
        end
        return_string = return_string * return_value
    end
    return_string = return_string * "\n\nend\nexport $app_name\n"
    open(abspath(joinpath(outputfileposition, app_name * ".jl" )),"w") do outputfile
        print(outputfile,return_string)
    end
    open(abspath(include_file),"a") do outputfile
        print(outputfile,"include(\"$app_name.jl\")\n")
    end
end


for current_file in filenames_list
    parse_app_definitions(joinpath(jsonfolder,current_file), outputfolder, include_file,additional_json_files_path)
end
