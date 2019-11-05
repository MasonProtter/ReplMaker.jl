module ReplMaker

import REPL
import REPL.LineEdit

export initrepl, enter_mode!

"""
```
         initrepl(parser::Function;
                  prompt_text = "myrepl> ",
                  prompt_color = :blue,
                  start_key = ')',
                  repl = Base.active_repl,
                  mode_name = :mylang,
                  valid_input_checker::Function = (s -> true),
                  keymap::Dict = REPL.LineEdit.default_keymap_dict,
                  completion_provider = REPL.REPLCompletionProvider(),
                  sticky = true,
                  startup_text=true
                  )
```
creates a custom repl mode which takes in code and parses it according to whatever parsing function you
provide in the argument `parser`. Choose which key initializes the repl mode with `start_key`, the name of
your repl mode with `mode_name` and optionally provide a function which checks if a given repl input is valid
before parsing with `valid_input_checker`. Autocompletion options are supplied through the argument
`completion_provider` which defaults to the standard julia REPL TAB completions.
"""
function initrepl(parser::Function;
                  prompt_text = "myrepl> ",
                  prompt_color = :blue,
                  start_key = ')',
                  repl = Base.active_repl,
                  mode_name = :mylang,
                  valid_input_checker::Function = (s -> true),
                  keymap::Dict = REPL.LineEdit.default_keymap_dict,
                  completion_provider = REPL.REPLCompletionProvider(),
                  sticky_mode = true,
                  startup_text=true
                  )

    color = Base.text_colors[prompt_color]

    julia_mode = repl.interface.modes[1]
    prefix = repl.hascolor ? color : ""
    suffix = repl.hascolor ? (repl.envcolors ? Base.input_color : repl.input_color()) : ""

    lang_mode = LineEdit.Prompt(prompt_text;
                                prompt_prefix    = prefix,
                                prompt_suffix    = suffix,
                                keymap_dict      = keymap,
                                on_enter         = valid_input_checker,
                                complete         = completion_provider,
                                sticky           = sticky_mode
                                )

    lang_mode.on_done = REPL.respond(parser, repl, lang_mode)

    push!(repl.interface.modes, lang_mode)

    hp                     = julia_mode.hist
    hp.mode_mapping[mode_name |> Symbol] = lang_mode
    lang_mode.hist         = hp

    search_prompt, skeymap = LineEdit.setup_search_keymap(hp)

    mk = REPL.mode_keymap(julia_mode)

    lang_keymap = Dict(
    start_key => (s, args...) ->
      if isempty(s) || position(LineEdit.buffer(s)) == 0
        enter_mode!(s, lang_mode)
      else
        LineEdit.edit_insert(s, start_key)
      end
    )

    lang_mode.keymap_dict = LineEdit.keymap(Dict[
        skeymap,
        mk,
        LineEdit.history_keymap,
        LineEdit.default_keymap,
        LineEdit.escape_defaults,
    ])
    if start_key in keys(julia_mode.keymap_dict)
        @warn "REPL key '$start_key' overwritten."
    end

    julia_mode.keymap_dict = LineEdit.keymap_merge(julia_mode.keymap_dict, lang_keymap)

    startup_text && println("REPL mode $mode_name initialized. Press $start_key to enter and backspace to exit.")

  lang_mode
end

"""
an extension of `REPL.LineEdit.transition` to achieve handy use.

When
- giving 3 arguments(action, mistate, mode),
  it equals to `REPL.LineEdit.transition`.

- giving 2 arguments(mistate, mode),
  there is a default 'action' copying the
  current buffer to the target REPL mode.

- giving 1 argument(mode),
  the action is the same as the case of 2 arguments,
  and 'mistate' is default to be `Base.active_repl.mistate`
"""
function enter_mode!(f, s :: LineEdit.MIState, lang_mode)
  LineEdit.transition(f, s, lang_mode)
end

function enter_mode!(s :: LineEdit.MIState, lang_mode)
  function default_trans_action()
    buf = copy(LineEdit.buffer(s))
    LineEdit.state(s, lang_mode).input_buffer = buf
  end
  enter_mode!(default_trans_action, s, lang_mode)
end

function enter_mode!(lang_mode)
  enter_mode!(Base.active_repl.mistate, lang_mode)
end

end
