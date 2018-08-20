using Test

using ReplMaker

function parse_to_expr(s)
    quote Meta.parse($s) end
end

function __init__(_)
    try
        @async begin
            while !isdefined(Base, :active_repl)
                sleep(0.05)
            end
            sleep(1) # for extra safety
            initrepl(parse_to_expr, 
                     prompt_text="Expr> ",
                     prompt_color = :blue, 
                     start_key=')', 
                     mode_name="Expr_mode")

            @test Base.active_repl.interface.modes[end].prompt == "Expr> "
            @test Base.active_repl.interface.modes[end].sticky == true
            @test 1 == 2
            exit()
        end
    catch e
        println(e)
        exit()
    end
end

atreplinit(__init__)


# using Test

# atreplinit((_) -> begin
#            @test 1 == 2
#            exit()
#            end
#            )
