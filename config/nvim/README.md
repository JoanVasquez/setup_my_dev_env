# Neovim setup

The UI uses Tokyo Night (night), a matching global statusline, compact buffer tabs,
and rounded completion and search panels. A Nerd Font is recommended for icons.
Code opens without wrapping; `<leader>tw` toggles wrapping.

Requires Neovim 0.11.3+, Git, Node.js/npm, Python 3 with venv support, Go (for sqls installation),
a C compiler and tree-sitter CLI for parser installation, and a recent JDK
for JDTLS. Selecting `nvim` in the dotfiles setup/packages installer installs these
requirements plus make, ripgrep, fd, clipboard helpers, and download/archive utilities.
Debian, Arch and Fedora have separate package mappings for these runtimes.
Arch/Fedora use distro Tree-sitter CLI packages; Debian uses an upstream binary.
Setup supplies an upstream user Neovim runtime if the distro editor is older than
0.11.3 (Linux x86_64/aarch64). JDTLS needs JDK 21+; check the distro JDK version.
Use `:checkhealth` to diagnose missing dependencies.

Plugins are managed by Lazy and tools by Mason. Normal `dotfiles setup` installs
missing plugins, tools and parsers after linking the config, then verifies them.
For config-only installs, run `:Lazy install`, `:MasonToolsInstallSync`, and
`:TreesitterInstall!` manually. Opening files does not install language tools.
The committed lockfile seeds `stdpath("state")/lazy-lock.json`; plugin operations
write the user copy, leaving the checkout unchanged. Use `:Lazy restore` to
restore the plugin versions in that user lockfile,
`:MasonToolsUpdate` to update tools, and `:TSUpdate` to update installed parsers.

| Files | Completion and diagnostics | Formatting |
| --- | --- | --- |
| Python, FastAPI, Django, data science and AI code | BasedPyright + Ruff | Ruff imports + format |
| JavaScript, TypeScript, React | TypeScript LSP + project ESLint | Prettier |
| HTML, CSS, SCSS | HTML/CSS LSP, Emmet, project Tailwind | Prettier |
| Django HTML under `templates/` | HTML LSP + Emmet | djLint |
| Bash | Bash LSP + ShellCheck | shfmt |
| Dockerfile | Docker LSP + Hadolint | No external formatter |
| Docker Compose | Compose LSP + YAML schemas | Prettier |
| SQL | sqls completion | SQLFluff with project configuration |
| Java, Spring Boot | JDTLS, Maven/Gradle project import | JDTLS |
| XML, Maven POM | LemMinX | LemMinX |
| JSON, YAML | LSP + SchemaStore | Prettier |

Python recognizes an active `VIRTUAL_ENV` or `CONDA_PREFIX`, then `.venv` or
`venv` in the project root. Create the environment before opening Neovim.
To change it in a running session, use `:PythonInterpreter /path/to/bin/python`.
Install FastAPI, Django, NumPy, pandas, PyTorch, or other project dependencies
in that environment so completion can find them. Python tooling supports
scripts and modules; an interactive Jupyter notebook interface is not included.

Ruff reads `pyproject.toml` or `ruff.toml`. ESLint and Tailwind need their
project dependencies and configuration. Prettier uses project configuration.
SQLFluff runs only in a configured project; add a `.sqlfluff` file such as:

```ini
[sqlfluff]
dialect = postgres
```

SQLFluff also recognizes SQLFluff sections in `pyproject.toml` and supported INI
files. A Python project file without those sections does not enable SQL formatting.

SQL schema completion needs a project `sqls.yml` connection configuration.
Keep credentials out of version control. See the
[sqls configuration](https://github.com/sqls-server/sqls#db-configuration).

Open Java files inside a Maven or Gradle project for build classpath support.
Each project gets its own JDTLS workspace. Spring Boot uses Java completion
and diagnostics plus YAML/XML support; dedicated Spring property completion
and Java debug/test extensions are not included.

The existing Minuet configuration provides inline AI completion through local
Ollama at `127.0.0.1:11434`, using `qwen2.5-coder:7b`. Start Ollama and install
that model separately. `<leader>at` toggles suggestions for the current buffer,
including before entering Insert mode. AI starts correctly in the first opened
code file and skips automatic requests for generated, large, and special buffers.
Insert-mode `Ctrl-l` accepts a suggestion and `Ctrl-g` accepts one line.

Useful commands and keys (leader is Space):

- `<leader>cf`: format buffer or selection (moved from `<leader>f` to keep file-search shortcuts responsive).
- `<leader>sn`: save once without formatting; other save hooks still run.
- `:FormatDisable`: disable formatting on save for the session.
- `:FormatDisable!`: disable formatting on save for the current buffer.
- `:FormatEnable`: enable session and current-buffer formatting on save.
- `:FormatEnable!`: clear the current buffer's disable flag; session settings still apply.
- Insert-mode `Ctrl-Space`: trigger completion; `Ctrl-j` / `Ctrl-k`: choose a completion.
- Insert-mode `Tab` / `Shift-Tab`: completion or snippet navigation.
- `K`: documentation; insert-mode `Ctrl-s`: signature help.
- `grd`, `grr`, `gri`: definitions, references, implementations.
- `grn`, `gra`: rename and code actions.
- `[d`, `]d`, `<leader>ld`: previous/next diagnostic and diagnostic details.
- `:ConformInfo`, `:checkhealth vim.lsp`, `:Mason`: inspect development tools.

Formatting on save skips `node_modules`, `vendor`, `.venv`, `venv`, and `.git`.
Buffers larger than 1 MiB or 20,000 lines skip automatic formatting, completion,
AI requests, linting, and Treesitter highlighting on open. Manual formatting
remains available. Swap recovery, persistent undo, and temporary write backups
protect work; Neovim stores recovery files in its standard data/state directories.
Web files use two-space indentation; Python and Java retain four spaces.
Lua uses tabs with a width of four, matching `.stylua.toml`.
Project `.editorconfig` files can override editor settings.

Navigation (leader is Space):

- `<leader>e`: toggle the file explorer (also works in LSP buffers).
- `<leader>ff`, `<leader>fg`, `<leader>fb`, `<leader>fr`: find files, search text, switch buffers, recent files.
- `<Tab>` / `<S-Tab>`: next / previous buffer.
- `<leader>x`: close a buffer; unsaved changes are protected.
- `<leader>a`: close all listed editing buffers; refuses if any are modified.
- `<leader>wv`, `<leader>ws`, `<leader>wd`, `<leader>w=`: split, close, equalize windows.
- `<Esc>`: clear search highlighting.
- Pause after Space to see available shortcuts.
