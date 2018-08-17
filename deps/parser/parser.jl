using JSON

function parse_cpperl_file(filename::String)
    println(filename)
    parsed_dict = JSON.Parser.parsefile(filename)
    include_file = parsed_dict["embed"]
    app_name = parsed_dict["app"]
    include_statements = ["#include <apps/$app_name/src/$include_file>"]
    method_definitions = []
    julia_translation = []
    for current_item in parsed_dict["inst"]
        if current_item == nothing || !haskey(current_item,"func")
            break
        end
        if haskey(current_item,"include")
            for current_include in current_item["include"]
                push!(include_statements,"#include <"*current_include*">")
            end
        end
        function_name = current_item["func"]
        nr_args = length(current_item["args"])
        if !haskey(current_item,"tp")
            nr_tp = 0
        else
            nr_tp = parse(Int64,current_item["tp"])
        end
        templates = current_item["args"][1:nr_tp]
        argument_names = current_item["args"][nr_tp+1:end]
        templates_types = join(templates,",")
        templates_name = join(templates,"_")
        if templates_name != ""
            template_func = "<"*templates_name*" >"
        else
            template_func = ""
        end
        has_option_set = endswith( current_item["sig"], "o" )
        if has_option_set
            nr_args = nr_args - nr_tp - 1
        else
            nr_args = nr_args - nr_tp
        end
        arguments = map(i->"pm::perl::Value a$i",1:nr_args)
        arguments_function = []
        to_continue = false
        for i in 1:nr_args
            if argument_names[i] == "void"
                push!(arguments_function,"a$i")
            else
                if contains(argument_names[i],"perl::Canned")
                    to_continue = true
                    break
                end
                push!(arguments_function,"a"*"$i"*".template get<"*argument_names[i]*">()")
            end
        end
        if to_continue
            continue
        end
        if has_option_set
            push!(arguments,"pm::perl::OptionSet opt")
            push!(arguments_function,"opt")
        end
        arguments = join(arguments,", ")
        arguments_function = join( arguments_function, ", ")
        wrap_name = function_name*"_"*templates_name
        wrap_name = replace( wrap_name, "<", "_" )
        wrap_name = replace( wrap_name, ">", "_" )
        wrap_name = replace( wrap_name, " ", "" )
        wrap_name = replace( wrap_name, ",", "_" )
        call_string = "polymake.method(\""*wrap_name*"\",[]("*arguments*"){ return "*function_name*template_func*"( "*arguments_function*"); });"
        push!(method_definitions,call_string)
        push!(julia_translation, Dict( "wrap_name" => wrap_name, "templates" => templates, "function" => function_name ) )
    end
    method_definitions = unique(method_definitions)
    julia_translation = unique(julia_translation)
    include_statements = unique(include_statements)
    return (include_statements,method_definitions,julia_translation)
end

wrapper_files = filter(y->contains(y,"wrap-"),filter(x->contains(x,".cpperl"), readdir("/home/sebastian/Software/polymake_devel_git/apps/polytope/cpperl")))

all_include_statements = []

open("../src/generated/additional_wrappers.cpp","w") do wrappers

    for filename in wrapper_files[1:10]

        filename = "/home/sebastian/Software/polymake_devel_git/apps/polytope/cpperl/$filename"

        result = parse_cpperl_file(filename)

        append!(all_include_statements,result[1])
        
        for current_line in result[2]
            println(wrappers,current_line)
        end
    end

end

all_include_statements = unique(all_include_statements)

open("../src/generated/additional_includes.h","w") do headers
    for current_line in all_include_statements
        println(headers,current_line)
    end
    println(headers, "using namespace pm;")
    println(headers, "using namespace polymake::polytope;")
end
