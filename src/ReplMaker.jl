__precompile__()

module ReplMaker

import Base: LineEdit, REPL

export initrepl

function initrepl(parser::Function;
                  text = "myrepl> ",
                  text_color = :blue,
                  start_key = ')',
                  repl = Base.active_repl,
                  mode_mapping = :mylang,
                  valid_input_checker::Function = (s -> true),
                  completion_provider = REPL.REPLCompletionProvider()
                  )

    color = Base.text_colors[text_color]
    
    julia_mode = repl.interface.modes[1]
    prefix = repl.hascolor ? color : ""
    suffix = repl.hascolor ? (repl.envcolors ? Base.input_color : repl.input_color) : ""

    lang_mode = LineEdit.Prompt(text;
    prompt_prefix    = prefix,
    prompt_suffix    = suffix,
    keymap_func_data = repl,
    on_enter         = valid_input_checker,
    complete         = completion_provider,
    )
    lang_mode.on_done = REPL.respond(parser, repl, lang_mode)

    push!(repl.interface.modes, lang_mode)

    hp                     = julia_mode.hist
    hp.mode_mapping[mode_mapping] = lang_mode
    lang_mode.hist         = hp

    search_prompt, skeymap = LineEdit.setup_search_keymap(hp)

    mk = REPL.mode_keymap(julia_mode)

    lang_keymap = Dict(
    start_key => (s, args...) ->
      if isempty(s) || position(LineEdit.buffer(s)) == 0
        buf = copy(LineEdit.buffer(s))
        LineEdit.transition(s, lang_mode) do
          LineEdit.state(s, lang_mode).input_buffer = buf
        end
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
    julia_mode.keymap_dict = LineEdit.keymap_merge(julia_mode.keymap_dict, lang_keymap)

    println("REPL mode $mode_mapping initialized. Press $start_key to enter and backspace to exit.")

  nothing
end

end
