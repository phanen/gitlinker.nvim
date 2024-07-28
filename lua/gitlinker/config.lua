local M = {}

local defaults = {
  remote = "origin", -- force the use of a specific remote
  add_current_line_on_normal_mode = true, -- if true adds the line nr in the url for normal mode
  url_callback = function(url)
    api.nvim_command("let @+ = '" .. url .. "'")
  end, -- callback for what to do with the url
  print_url = true, -- print the url after action
  -- callbacks = { ["githostname.tld"] = function(url_data) url end },
}

local opts

function M.setup(user_opts)
  if not opts then
    opts = vim.tbl_deep_extend("force", {}, defaults)
  end
  opts = vim.tbl_deep_extend("force", opts, user_opts or {})
end

function M.get()
  if not opts then
    opts = vim.tbl_deep_extend("force", {}, defaults)
  end
  return opts
end

return M
