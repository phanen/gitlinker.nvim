local M = {}

local git = require("gitlinker.git")
local buffer = require("gitlinker.buffer")
local cfg = require("gitlinker.config")

-- public
M.hosts = require("gitlinker.hosts")

--- Setup the plugin configuration
--
-- Sets the options
-- Sets the hosts callbacks
--
-- @param config table with the schema
-- {
--   opts = {
--    remote = "<remotename>", -- force the use of a specific remote
--    add_current_line_on_normal_mode = true/false, -- add the line nr to the url
--    url_callback = <func> -- what to do with the url
--   }, -- check gitlinker/opts for the default values
--  callbacks = {
--    ["githostname.tld"] = <func> -- where <func> is a function that takes a
--    url_data table and returns the url
--   },
-- }
-- @param user_opts a table to override options passed in M.setup()

function M.setup(opts)
  if opts then
    cfg.setup(opts)
    M.hosts.callbacks =
      vim.tbl_deep_extend("force", M.hosts.callbacks, opts.callbacks or {})
  else
    cfg.setup()
  end
end

local parse_mode = function(mode)
  mode = mode or vim.api.nvim_get_mode().mode
  if not vim.tbl_contains({ "v", "V", "\022" }, mode) then
    return mode
  end
  return "v"
end

local function get_buf_range_url_data(user_opts)
  local git_root = git.get_git_root()
  if not git_root then
    vim.notify("Not in a git repository", vim.log.levels.ERROR)
    return nil
  end
  local remote = eval(user_opts.remote)
  local repo_url_data = git.get_repo_data(remote)
  if not repo_url_data then
    return nil
  end

  local rev = git.get_closest_remote_compatible_rev(remote)
  if not rev then
    return nil
  end

  local buf_repo_path = buffer.get_relative_path(git_root)
  if not git.is_file_in_rev(buf_repo_path, rev) then
    vim.notify(
      string.format("'%s' does not exist in remote '%s'", buf_repo_path, remote),
      vim.log.levels.ERROR
    )
    return nil
  end

  local buf_path = buffer.get_relative_path()

  local mode = parse_mode()
  if
    git.has_file_changed(buf_path, rev)
    and (mode == "v" or user_opts.add_current_line_on_normal_mode)
  then
    vim.notify(
      string.format(
        "Computed Line numbers are probably wrong because '%s' has changes",
        buf_path
      ),
      vim.log.levels.WARN
    )
  end
  local range =
    buffer.get_range(mode, user_opts.add_current_line_on_normal_mode)

  return vim.tbl_extend("force", repo_url_data, {
    rev = rev,
    file = buf_repo_path,
    lstart = range.lstart,
    lend = range.lend,
  })
end

--- Retrieves the url for the selected buffer range
--
-- Gets the url data elements
-- Passes it to the matching host callback
-- Retrieves the url from the host callback
-- Passes the url to the url callback
-- Prints the url
--
-- @param user_opts a table to override options passed
--
-- @returns The url string
function M.get_buf_range_url(user_opts)
  user_opts = vim.tbl_deep_extend("force", cfg.get(), user_opts or {})

  local url_data = get_buf_range_url_data(user_opts)
  if not url_data then
    return nil
  end

  local matching_callback = M.hosts.get_matching_callback(url_data.host)
  if not matching_callback then
    return nil
  end

  local url = matching_callback(url_data)

  if user_opts.action_callback then
    user_opts.action_callback(url)
  end
  if user_opts.print_url then
    vim.notify(url)
  end

  return url
end

function M.get_repo_url(user_opts)
  user_opts = vim.tbl_deep_extend("force", cfg.get(), user_opts or {})

  local repo_url_data = git.get_repo_data(eval(user_opts.remote))
  if not repo_url_data then
    return nil
  end

  local matching_callback = M.hosts.get_matching_callback(repo_url_data.host)
  if not matching_callback then
    return nil
  end

  local url = matching_callback(repo_url_data)

  if user_opts.action_callback then
    user_opts.action_callback(url)
  end
  if user_opts.print_url then
    vim.notify(url)
  end

  return url
end

return M
