return {
  -- stylua: ignore
  blocked_filetypes = {
    'rust', 'sql', 'ruby', 'perl', 'lisp', 'scheme', 'clojure',
    'prolog', 'vb', 'elixir', 'smalltalk', 'applescript'
  },
  per_filetype = {
    -- languages with a space
    haskell = { ' ', '' },
    fsharp = { ' ', '' },
    ocaml = { ' ', '' },
    erlang = { ' ', '' },
    tcl = { ' ', '' },
    nix = { ' ', '' },
    helm = { ' ', '' },

    shell = { ' ', '' },
    sh = { ' ', '' },
    bash = { ' ', '' },
    fish = { ' ', '' },
    zsh = { ' ', '' },
    powershell = { ' ', '' },

    make = { ' ', '' },

    -- languages with square brackets
    wl = { '[', ']' },
    wolfram = { '[', ']' },
    mma = { '[', ']' },
    mathematica = { '[', ']' },
  },
}
