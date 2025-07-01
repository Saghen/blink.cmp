local typescript_exceptions = function(ctx) return ctx.line:find('^%s*import%s') == nil end

return {
  -- stylua: ignore
  blocked_filetypes = {
    'sql', 'ruby', 'perl', 'lisp', 'scheme', 'clojure',
    'prolog', 'vb', 'elixir', 'smalltalk', 'applescript',
    'elm', 'rust', 'nu', 'cpp', 'fennel', 'janet', 'ps1',
    'racket'
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
    lean = { ' ', '' },

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
      -- ignore `from`, `import`, and `except` statements
      python = function(ctx)
        return ctx.line:find('^%s*import%s') == nil
          and ctx.line:find('^%s*from%s') == nil
          and ctx.line:find('^%s*except%s') == nil
      end,
      -- ignore `import ...` statements
      javascript = typescript_exceptions,
      javascriptreact = typescript_exceptions,
      typescript = typescript_exceptions,
      typescriptreact = typescript_exceptions,
    },
  },
}
