[![Build Status](https://travis-ci.org/MasonProtter/ReplMaker.jl.svg?branch=master)](https://travis-ci.org/MasonProtter/ReplMaker.jl)

# REPLMaker
The idea behind ReplMaker.jl is to make a tool for building (domain specific) languages in julia. 

Suppose you've invented some language called MyLang and you've implemented a parser that turns MyLang code into julia code which is then supposed to be executed by the julia runtime. With ReplMaker.jl, you can simply hook your parser into the package and ReplMaker will then create a REPL mode where end users just type MyLang code and have it be executed automatically. 

My hope is for this to be useful to someone who implements a full language or DSL in Julia that uses syntax not supported by Julia's parser and doesn't want to deal with the headache of making their own REPL mode. 

To download ReplMaker, simply do 
```
pkg> add ReplMaker
```

# Examples
## Example 1: Expr Mode

<details>
 <summary> Click me! </summary>
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

Next, we might notice that if we try to do a multiline expression, the REPL mode craps out on us:
```julia
Expr> function f(x)
:($(Expr(:incomplete, "incomplete: premature end of input")))
```
This is because we haven't told our REPL mode what constitutes a valid, complete line. ReplMaker.jl exports a function `complete_julia` that will tell you if a given expression is a complete julia-expression. If you are using ReplMaker.jl for a DSL that has different parsing semantics from julia, you may need to roll your own analogous function if you want to have multi-line inputs.

To use `complete_julia` to check if an expression is complete, we just pass it as a keyword argument to to `initrepl`:
```julia
julia> initrepl(parse_to_expr,
                prompt_text="Expr> ",
                prompt_color = :blue,
                start_key=')',
                mode_name="Expr_mode",
                valid_input_checker=complete_julia)
┌ Warning: REPL key ')' overwritten.
└ @ ReplMaker ~/.julia/packages/ReplMaker/pwo5w/src/ReplMaker.jl:86
REPL mode Expr_mode initialized. Press ) to enter and backspace to exit.

Expr> function f(x)
          x + 1
      end
:(function f(x)
      #= none:2 =#
      x + 1
  end)
```

</p>
</details>

## Example 2: Reverse Mode
<details>
 <summary> Click me! </summary>
<p>

This is an example of using a custom REPL mode to not change the meaning of the input code but instead of how results are shown. Suppose we have our own `show`-like function which is just `Base.show`, but will print `Vector`s and `Tuple`s backwards
```julia
backwards_show(io, M, x) = (show(io, M, x); println(io))
backwards_show(io, M, v::Union{Vector, Tuple}) = (show(io, M, reverse(v)); println(io))
```
We can make a quick and dirty REPL mode that uses this rather than `Base.show` directly:

```julia
julia> initrepl(Meta.parse,
                show_function = backwards_show,
                prompt_text = "reverse_julia> ",
                start_key = ')',
                mode_name = "reverse mode")
REPL mode reverse mode initialized. Press ) to enter and backspace to exit.

reverse_julia> x = [1, 2, 3, 4]
4-element Array{Int64,1}:
 4
 3
 2
 1
```
The printing was reversed, but we can check to make sure the variable itself was not:
```
julia> x
4-element Array{Int64,1}:
 1
 2
 3
 4
```

</p>
</details>

## Example 3: Big Mode
<details>
 <summary> Click me! </summary>
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
 <summary> Click me! </summary>
<p>
           
The package [LispSyntax.jl](https://github.com/swadey/LispSyntax.jl) provides a string macro for
parsing lisp-style code into julia code which is then evaluated, essentially creating a lispy language
embedded in julia. 

```julia
julia> lisp"(defn fib [a] (if (< a 2) a (+ (fib (- a 1)) (fib (- a 2)))))"
fib (generic function with 1 method)

julia> lisp"(fib 30)"
832040
```
Awesome! To make this really feel like its own language, it'd be nice if it had a special REPL mode, so
let's make one. For this, we're going need a helper function `valid_sexpr` to tell ReplMaker if we pressed 
`return` because we were done writing our input or if we wanted to write a multi-line S-expression.

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

# Modifier keys
<details>
 <summary> Click me! </summary>
<p>
           
Arbitrary key combinations to enter REPL modes are not yet allowed, but you can currently use the `CTRL` and `ALT` (also known as `META`) keys as modifiers for entering REPL modes. For example, passing the keyword argument `start_key="\\C-g"` to the `initrepl` function will make it so that holding down on the `CTRL` key and pressing `g` enters the specified mode. 

Likewise, specifying `start_key="\\M-u"` will make it so that holding `ALT` (aka `META`) and pressing `u` will enter the desired mode. 

</p>
</details>
 
# Creating a REPL mode at startup time

To add a custom REPL mode whenever Julia starts, add to `~/.julia/config/startup.jl` code like:

```julia
atreplinit() do repl
    try
        @eval using ReplMaker
        @async initrepl(
            apropos;
            prompt_text="search> ",
            prompt_color=:magenta,
            start_key=')',
            mode_name="search_mode"
        )
        catch
        end
    end
end
```

# Packages using ReplMaker.jl

* [AbstractLogic.jl](https://github.com/EconometricsBySimulation/AbstractLogic.jl): A package for logic programming in julia.
* [JML.jl](https://github.com/thautwarm/JML.jl):  A dialect of the [ML programming language](https://en.wikipedia.org/wiki/ML_(programming_language)) family embedded in julia.
* [APL.jl](https://github.com/shashi/APL.jl): A small implementation of [APL](https://en.wikipedia.org/wiki/APL_(programming_language)) in julia.
* [GitCommand.jl](https://github.com/bcbi/GitCommand.jl): uses ReplMaker.jl to provide a Git REPL mode
* [RemoteREPL.jl](https://github.com/c42f/RemoteREPL.jl): Remotely share a REPL session with another user.
