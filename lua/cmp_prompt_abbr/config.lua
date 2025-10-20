local Config = {}

Config.defaults = {
  mappings = {},
  matching = 'prefix',
  case_sensitive = false,
  keyword_length = 1,
  priority = nil,
}

local function deep_copy(value)
  if type(value) ~= 'table' then
    return value
  end

  local copy = {}
  for key, item in pairs(value) do
    copy[key] = deep_copy(item)
  end
  return copy
end

local function copy_mapping(entry, index)
  if type(entry) ~= 'table' then
    error(string.format('cmp_prompt_abbr: mappings[%d] must be a table', index))
  end

  if type(entry.source) ~= 'string' or entry.source == '' then
    error(string.format('cmp_prompt_abbr: mappings[%d].source must be a non-empty string', index))
  end

  if type(entry.target) ~= 'string' or entry.target == '' then
    error(string.format('cmp_prompt_abbr: mappings[%d].target must be a non-empty string', index))
  end

  local normalized = {
    source = entry.source,
    target = entry.target,
  }

  if entry.label ~= nil then
    if type(entry.label) ~= 'string' then
      error(string.format('cmp_prompt_abbr: mappings[%d].label must be a string', index))
    end
    normalized.label = entry.label
  end

  if entry.doc ~= nil then
    if type(entry.doc) ~= 'string' then
      error(string.format('cmp_prompt_abbr: mappings[%d].doc must be a string', index))
    end
    normalized.doc = entry.doc
  end

  return normalized
end

local function validate_matching(value)
  local allowed = { prefix = true, substring = true, lua_pattern = true }
  if not allowed[value] then
    local keys = table.concat(vim.tbl_keys(allowed), ', ')
    error(string.format('cmp_prompt_abbr: matching must be one of: %s', keys))
  end
end

local function validate_common_fields(config)
  if type(config.keyword_length) ~= 'number' or config.keyword_length < 0 then
    error('cmp_prompt_abbr: keyword_length must be a non-negative number')
  end

  if type(config.case_sensitive) ~= 'boolean' then
    error('cmp_prompt_abbr: case_sensitive must be a boolean')
  end

  if config.priority ~= nil and type(config.priority) ~= 'number' then
    error('cmp_prompt_abbr: priority must be nil or a number')
  end

  validate_matching(config.matching)
end

function Config.copy(value)
  return deep_copy(value)
end

function Config.normalize(user_config)
  local merged = vim.tbl_deep_extend('force', {}, Config.defaults, user_config or {})

  validate_common_fields(merged)

  local normalized_mappings = {}
  for index, entry in ipairs(merged.mappings) do
    table.insert(normalized_mappings, copy_mapping(entry, index))
  end
  merged.mappings = normalized_mappings

  return merged
end

function Config.extend(base, override)
  if override == nil or next(override) == nil then
    return Config.copy(base)
  end

  local merged = vim.tbl_deep_extend('force', {}, base, override)
  return Config.normalize(merged)
end

return Config
