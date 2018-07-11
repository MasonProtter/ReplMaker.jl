
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

# Examples
## Example 1: Expr Mode
Suppose we want to make a very simple repl mode which just takes whatever input we provide and returns its
quoted `Expr` form. We first make a parsing function,

```julia
julia> using ReplMaker

julia> function parse_to_expr(s)
           quote parse($s) end
       end
test_parser (generic function with 1 method)
```

Now, we can simply provide that parser to the `initrepl` function

```julia
julia> initrepl(parse_to_expr, 
                prompt_text="Expr> ",
                prompt_color = :blue, 
                start_key=')', 
                mode_name="Expr_mode")
REPL mode Expr_mode initialized. Press ) to enter and backspace to exit.
```

As instructed, we simply press the `)` key and julia prompt is replaced
```
Expr>  
```
and as desired, we now can enter julia code and be showed its quoted version.
```
Expr> 1 + 1
:(1 + 1)

Expr> x ^ 2 + 5
:(x ^ 2 + 5)
```

## Example 2: Bad Parser Mode
Lets say we're feeling a bit maniacal and want an insane version of julia where any input has multiplication and addition switched. 

We first just make a function which takes expressions and if the first argument is `:+` replaces it with `:*` and vice versa. On all other inputs, this function is just an identity operation
```jula
function switch_mult_add(expr::Expr)
    if expr.args[1] == :+
        expr.args[1] = :*
        return expr
    elseif expr.args[1] == :*
        expr.args[1] = :+
        return expr
    else
        return expr
    end
end
switch_mult_add(s) = s
```
We now just borrow the `postwalk` function from MacroTools and use it in our parsing function to recursively look through and input expression tree and apply `switch_mult_add` and use that parser in a new REPL mode.
```julia
using MacroTools.postwalk

function bad_julia_parser(s)
    expr = parse(s)
    postwalk(ex -> switch_mult_add(ex), expr)
end

initrepl(bad_julia_parser, 
         prompt_text="bad_parser> ",
         prompt_color = :red, 
         start_key='}', 
         mode_name="bad_parser_mode")
```
now by pressing `}` we enter `bad_parser_mode`!
```julia
bad_parser> 5 + 5
25

bad_parser> (5 * 5)^2
100
```
