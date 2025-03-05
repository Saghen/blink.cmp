return {
  -- stylua: ignore
  blocked_filetypes = {
    'sql', 'ruby', 'perl', 'lisp', 'scheme', 'clojure',
    'prolog', 'vb', 'elixir', 'smalltalk', 'applescript',
    'elm', 'rust', 'nu'
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
    context = { '[', ']' },

    -- languages with curly brackets
    tex = { '{', '}' },
    plaintex = { '{', '}' },
  },
  exceptions = {
    by_filetype = {
      -- ignore `use` imports
      rust = function(ctx) return ctx.line:find('^%s*use%s') == nil end,
      -- ignore `from` and `import` statements
      python = function(ctx) return ctx.line:find('^%s*import%s') == nil and ctx.line:find('^%s*from%s') == nil end,
    },
  },
}
