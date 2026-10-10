-- Compile config chunks without executing plugins or downloading dependencies.
local root = vim.env.DOTFILES_CHECK_ROOT
local files = vim.fn.globpath(root .. "/config/nvim", "**/*.lua", false, true)
for _, file in ipairs(files) do
  local chunk, err = loadfile(file)
  if not chunk then
    io.stderr:write(err .. "\n")
    vim.cmd("cquit 1")
  end
end
