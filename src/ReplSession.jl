"""
ReplSession - module for interactive working.

in session1:

using ReplSession

f(x)=x+1

save() # - will save (1 by default) last REPL command to ./repl.session.jl

f(x,y)=x+y

f(x,y,z)=x+y-z

save(2) # N=2 - count of last REPL commans to save

in session 2:

using ReplSession

recall() # - print content of session file

comment() # comment all lines in session file

use other session file:

save( \"try1\") # will save in repl.session.try1.jl

session_files() # ask for all sessions files

recall(\"repl.session.try1.jl\")

incl(\"repl.session.try1.jl\")

incl(\"repl.session.try1.jl\", \"MOD1\") # wrap included file in 'module MOD1 ... end'

"""
module ReplSession


"Returns current session file name"
function session_name( suffix="")::AbstractString
 re = join( filter( noempty, [ s"repl\.session", suffix, "jl"]), s"\.") |> Regex
 found_files = session_files( re)
 name = isempty( found_files)? "repl.session.jl": first( found_files)
 !isfile(name) && touch(name)
 name
end

"return true if x is not empty"
noempty(x)=!isempty(x)


"returns list of sessions files in current dir matched for regex"
function session_files( regex=r"repl\.session" )::Vector{String}
 filter(readdir()) do name
    ismatch( regex, name)
 end
end
export session_files


print_with_color( :magenta, STDERR, """ReplSession: use \"? ReplSession\" for help.\n""")


"Returns julia history file name"
history_name()::AbstractString = homedir()*"/.julia_history"


function last_lines( f::AbstractString=history_name(), n::Int=1)::Array 
 ll = []
 cmd = []
 for l in eachline(f)
    if ismatch( r"\# time\:\s", l) && !isempty(cmd)
        push!(ll, join(cmd,""))
        cmd=[]
        continue
    end
    ismatch( r"\# mode\:\s", l) && continue
    push!( cmd, replace( l, r"\t", ""))
 end
 reverse!(ll)
 rv = take(ll,n)|>collect
end

"Saves last n[=1] REPL line to session_name"
function save( n::Int=1, suffix::AbstractString="")::Void 
 s = session_name( strip( suffix))
 h = history_name()::AbstractString
 ll = last_lines( h,n)::Array 

 open( s, "a") do wio
    for l in ll
        println(wio,l) 
    end
 end

 recall(s)
end
export save

save(suffix::AbstractString) = save( 1, suffix)

"comment all lines in session file"
function comment( s = session_name()::AbstractString)::Void
 ll = readlines(s)
 isempty(ll) && return
 open( s, "w") do wio
    for l in ll
        print(wio, "# $l")
    end
 end
end
export comment

"print all current session lines without comments"
function recall( s = session_name()::AbstractString)::Void
 for l in s|>eachline
    ismatch(r"^\s*?\#", l) && continue 
    print(l) 
 end  
end 
export recall


"includes current session file"
incl( s = session_name()::AbstractString) = s|>include

function incl( s::AbstractString, as::AbstractString)
        try
            content = readlines(s)
            unshift!(content, "module $as\n")
            push!(content, "end\n")
            join(content,"") |>parse |>eval
        catch e
            info("Error while try include $s as module $as: $e")
        end
end
export incl


end # module
