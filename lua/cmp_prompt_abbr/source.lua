local Config = require('cmp_prompt_abbr.config')

local Source = {}
Source.__index = Source

local function get_current_before(context)
  return context.cursor_before_line or ''
end

local function build_terms(before)
  local terms = {}

  local function append_term(text)
    if not text or text == '' then
      return
    end

    local start_byte = #before - #text + 1
    table.insert(terms, {
      text = text,
      start_byte = start_byte,
    })
  end

  append_term(before:match('(%S+)$'))

  local first_text = terms[1] and terms[1].text or nil

  local ascii_suffix = before:match('([%a]+)$')
  if ascii_suffix and ascii_suffix ~= first_text then
    append_term(ascii_suffix)
  end

  return terms
end

local function is_ascii_letter_byte(byte)
  if not byte then
    return false
  end
  return (byte >= string.byte('A') and byte <= string.byte('Z'))
    or (byte >= string.byte('a') and byte <= string.byte('z'))
end

local function should_skip_term(before, term)
  if term.start_byte <= 1 then
    return false
  end

  local prev_byte = before:byte(term.start_byte - 1)
  return is_ascii_letter_byte(prev_byte)
end

local function matches(config, word, source_text)
  if word == '' then
    return false
  end

  if config.matching == 'lua_pattern' then
    local subject = source_text
    local pattern = word
    if not config.case_sensitive then
      subject = subject:lower()
      pattern = pattern:lower()
    end

    local ok, start_index = pcall(string.find, subject, pattern)
    if not ok then
      return false
    end
    return start_index ~= nil
  end

  local candidate = source_text
  local needle = word

  if not config.case_sensitive then
    needle = needle:lower()
    candidate = candidate:lower()
  end

  if config.matching == 'substring' then
    return candidate:find(needle, 1, true) ~= nil
  end

  return candidate:sub(1, #needle) == needle
end

local function build_documentation(mapping)
  if mapping.doc and mapping.doc ~= '' then
    return {
      kind = 'markdown',
      value = mapping.doc,
    }
  end

  if mapping.target:find('\n', 1, true) then
    return {
      kind = 'markdown',
      value = string.format('```text\n%s\n```', mapping.target),
    }
  end

  return nil
end

local function build_item(config, mapping)
  local item = {
    word = mapping.target,
    label = mapping.label or mapping.source,
    insertText = mapping.target,
    filterText = mapping.source,
    user_data = {
      prompt_abbr = {
        source = mapping.source,
      },
    },
  }

  item.documentation = build_documentation(mapping)

  if config.priority then
    item.priority = config.priority
  end

  return item
end

function Source.new(config)
  local self = setmetatable({}, Source)
  self._config = Config.copy(config or Config.defaults)
  return self
end

function Source:get_debug_name()
  return 'prompt_abbr'
end

function Source:get_keyword_pattern()
  return '\\k\\+'
end

function Source:is_available()
  return true
end

function Source:complete(params, callback)
  local cfg = Config.extend(self._config, params.option)

  if #cfg.mappings == 0 then
    callback({})
    return
  end

  local context = params.context or {}
  local before = get_current_before(context)
  local candidate_terms = {}
  for _, term in ipairs(build_terms(before)) do
    if #term.text >= cfg.keyword_length and not should_skip_term(before, term) then
      table.insert(candidate_terms, term)
    end
  end

  if #candidate_terms == 0 then
    callback({})
    return
  end

  local items = {}
  for _, mapping in ipairs(cfg.mappings) do
    local matched = false
    for _, term in ipairs(candidate_terms) do
      if matches(cfg, term.text, mapping.source) then
        matched = true
        break
      end
    end

    if matched then
      table.insert(items, build_item(cfg, mapping))
    end
  end

  callback(items)
end

function Source:resolve(completion_item, callback)
  callback(completion_item)
end

function Source:execute(completion_item, callback)
  callback(completion_item)
end

return Source
