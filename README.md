[![Build Status](https://travis-ci.org/MasonProtter/ReplMaker.jl.svg?branch=master)](https://travis-ci.org/MasonProtter/ReplMaker.jl)

# REPLMaker
The idea here is to make a tool for people making (domain specific) languages in julia. 
A user of this package will be required to give a function that parses code from whatever langauge the user has 
implemented and turns it into Julia code which is then executed by Julia. ReplMaker will then create a repl mode where end users 
just type code from the implemented language and have it be parsed into Julia code automatically. 

My hope is for this to be useful to someone who implements a full language or DSL in Julia that uses syntax not supported by Julia's parser and doesn't want to deal with the headache of making their own REPL mode. 

To add it,
```
pkg> add ReplMaker
```

# Examples
## Example 1: Expr Mode

<details>
 <summaryClick me! ></summary>
<p>
           
         
Suppose we want to make a very simple REPL mode which just takes whatever input we provide and returns its
quoted `Expr` form. We first make a parsing function,

```julia
julia> using ReplMaker

julia> function parse_to_expr(s)
           quote Meta.parse($s) end
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

As instructed, we simply press the `)` key and the `julia>` prompt is replaced
```
Expr>  
```
and as desired, we now can enter Julia code and be shown its quoted version.
```
Expr> 1 + 1
:(1 + 1)

Expr> x ^ 2 + 5
:(x ^ 2 + 5)
```
</p>
</details>

## Example 2: Bad Parser Mode
<details>
 <summaryClick me! ></summary>
<p>
           
Lets say we're feeling a bit sneaky and want a version of Julia where any input has multiplication and addition switched. 

We first just make a function which takes expressions and if the first argument is `:+` replaces it with `:*` and vice versa. On all other inputs, this function is just an identity operation
```julia
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
using MacroTools: postwalk

function bad_julia_parser(s)
    expr = Meta.parse(s)
    postwalk(switch_mult_add, expr)
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

</p>
</details>

## Example 3: Big Mode
<details>
 <summaryClick me! ></summary>
<p>
           
For performance reasons, Julia defaults to 64 bit precision but sometimes you don't care about speed and you don't
want to juggle the limitations of 64 bit precision in your head. You could just start wrapping every number in your 
code with `big` but that sounds like something the REPL should be able to do for you. Fortunately, it is!
```julia
using ReplMaker 

function Big_parse(str)
    Meta.parse(replace(str, r"[\+\-]?\d+(?:\.\d+)?(?:[ef][\+\-]?\d+)?" => x -> "big\"$x\""))
end

julia> initrepl(Big_parse, 
                prompt_text="BigJulia> ",
                prompt_color = :red, 
                start_key='>', 
                mode_name="Big-Mode")
REPL mode Big-Mode initialized. Press > to enter and backspace to exit.
```
Now press `>` at the repl to enter `Big-Mode`
```julia
BigJulia>  factorial(100)
93326215443944152681699238856266700490715968264381621468592963895217599993229915608941463976156518286253697920827223758251185210916864000000000000000000000000

BigJulia>  factorial(100.0)
9.332621544394415268169923885626670049071596826438162146859296389521759999323012e+157

BigJulia>  factorial(100.0)^2
8.709782489089480079416590161944485865569720643940840134215932536243379996346655e+315
```
</p>
</details>

## Example 4: Lisp Mode
<details>
 <summaryClick me! ></summary>
<p>
           
The package [ListpSyntax.jl](https://github.com/swadey/LispSyntax.jl) provides a string macro for
parsing lisp-style code into julia code which is then evaluated, essentially creating a lispy langauge
embedded in julia. 

```julia
julia> lisp"(defn fib [a] (if (< a 2) a (+ (fib (- a 1)) (fib (- a 2)))))"
fib (generic function with 1 method)

julia> lisp"(fib 30)"
832040
```
Awesome! To make this really feel like it's own language, it'd be nice if it had a special REPL mode, so
let's make one. For this, we're going need a helper function `valid_sexpr` to tell ReplMaker if we pressed 
`return` because we were done writing our input or if we wanted to write a multi-line S-expression

```julia
using LispSyntax, ReplMaker
using REPL: REPL, LineEdit; using LispSyntax: ParserCombinator

lisp_parser = LispSyntax.lisp_eval_helper

function valid_sexpr(s)
  try
    LispSyntax.read(String(take!(copy(LineEdit.buffer(s)))))
    true
  catch err
    isa(err, ParserCombinator.ParserException) || rethrow(err)
    false
  end
end
```
Great, now we can create our repl mode using the function `LispSyntax.lisp_eval_helper` 
to parse input text and we'll use `valid_sexpr` as our `valid_input_checker`.
```julia

julia> initrepl(LispSyntax.lisp_eval_helper,
                valid_input_checker=valid_sexpr,
                prompt_text="λ> ",
                prompt_color=:red,
                start_key=")",
                mode_name="Lisp Mode")
REPL mode Lisp Mode initialized. Press ) to enter and backspace to exit.

λ> (defn fib [a] 
    (if (< a 2) 
      a 
      (+ (fib (- a 1)) (fib (- a 2)))))
fib (generic function with 1 method)

λ> (fib 10)
55
```

Tada!

</p>
</details>
