[
  import_deps: [:ecto, :ecto_sql, :phoenix],
  subdirectories: ["priv/*/migrations"],
  plugins: [Phoenix.LiveView.HTMLFormatter],
  inputs: ["mix.exs", "{config,lib,test}/**/*.{heex,ex,exs}", "priv/repo/migrations/*.exs", "priv/repo/optional_migrations/**/*.exs", "priv/scrubbers/*.ex"]
]
