local Config = require('cmp_prompt_abbr.config')
local Source = require('cmp_prompt_abbr.source')

local M = {}

local config = Config.normalize({})

local function maybe_register_source()
  local ok, cmp = pcall(require, 'cmp')
  if not ok then
    return
  end

  cmp.register_source('prompt_abbr', M.new_source())
end

function M.setup(user_config)
  config = Config.normalize(user_config)
  maybe_register_source()
  return M.get_config()
end

function M.get_config()
  return Config.copy(config)
end

function M.new_source()
  return Source.new(M.get_config())
end

return M
