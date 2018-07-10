
# REPLMaker
The idea here is to make a tool for people making (domain specific) languages in julia. 
A user of this package will be required to give a function that parses code from whatever langauge the user has 
implemented and turns it into julia code which is then executed by julia. LangKit will then create a repl mode where end users 
just type code from the implemented language and have it be parsed into julia code automatically. 

My hope is for this to be useful to someone who implements a full language or DSL in julia that uses syntax not supported by julia's parser and doesn't want to deal with the headache of making their own repl mode. 

To use this pacakge
```julia
Pkg.clone("git@github.com:MasonProtter/ReplMaker.jl.git")
```

The code here is mostly just a massaged version of that written by Michael Hatherly for [LispREPL](https://github.com/swadey/LispREPL.jl) under MIT license. 

# Example
Suppose we want to make a very simple repl mode which just takes whatever input we provide and returns its
quoted `Expr` form. We first make a parsing function,

```julia
julia> using ReplMaker

julia> function test_parser(s)
           quote parse($s) end
       end
test_parser (generic function with 1 method)
```

Now, we can simply provide that parser to the `initrepl` function

```julia
julia> initrepl(test_parser, 
                prompt_text="parser> ",
                prompt_color = :blue, 
                start_key=')', 
                mode_name="parser_mode")
REPL mode parser_mode initialized. Press ) to enter and backspace to exit.
```

As instructed, we simply press the `)` key and julia prompt is replaced
```
parser>  
```
and as desired, we now can enter julia code and be showed its quoted version.
```
parser> 1 + 1
:(1 + 1)

parser> x ^ 2 + 5
:(x ^ 2 + 5)
```
