
# REPLMaker
The idea here is to make a tool for people making (domain specific) languages in julia. 
A user of this package will be required to give a function that parses code from whatever langauge the user has 
implemented and turns it into julia code which is then executed by julia. LangKit will then create a repl mode where end users 
just type code from the implemented language and have it be parsed into julia code automatically. 


# Example
Suppose we want to make a very simple repl mode which just takes whatever input we provide and returns its
quoted `Expr` form. We first make a parsing function,

```julia-repl
julia> using ReplMaker

julia> function test_parser(s)
           quote parse($s) end
       end
test_parser (generic function with 1 method)
```

Now, we can simply provide that parser to the `initrepl` function

```julia-repl
julia> initrepl(test_parser, 
                prompt_text="parser> ",
                prompt_color = :blue, 
                start_key=')', 
                mode_name="my_mode")
REPL mode my_mode initialized. Press ) to enter and backspace to exit.
```

As instructed, we simply press the `)` key and julia prompt is replaced
```
<span style="color:blue">parser> </span> 
```
and as desired, we now can enter julia code and be showed its quoted version.
```
<span style="color:blue">parser> </span> 1 + 1
:(1 + 1)

<span style="color:blue">parser> </span> x ^ 2 + 5
:(x ^ 2 + 5)
```

