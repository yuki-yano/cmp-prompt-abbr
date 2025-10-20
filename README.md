# cmp-prompt-abbr

cmp-prompt-abbr is a completion source for [nvim-cmp](https://github.com/hrsh7th/nvim-cmp) that turns short prompts into rich text snippets. Define an explicit table of abbreviations, show them as completion candidates, and insert the expanded text when a match is confirmed.

## Features

- Simple table-driven configuration (`source` → `target`) with optional labels and documentation.
- Flexible matching modes: prefix, substring, or Lua patterns for advanced use cases.
- Per-source overrides from `cmp.setup{ sources = { { name = 'prompt_abbr', option = {...} } } }` while keeping shared defaults.

## Requirements

- Neovim 0.8 or later
- [hrsh7th/nvim-cmp](https://github.com/hrsh7th/nvim-cmp)

Make sure `cmp-prompt-abbr` loads **after** `nvim-cmp` so the source can register itself.

## Installation

### lazy.nvim

```lua
{
  'yuki-yano/cmp-prompt-abbr',
  dependencies = { 'hrsh7th/nvim-cmp' },
  config = function()
    require('cmp_prompt_abbr').setup({
      mappings = {
        { source = 'afaik', target = 'as far as I know', label = 'afaik → as far as I know' },
        { source = ':wave:', target = '👋', label = 'wave emoji', doc = 'Add a friendly greeting.' },
      },
      matching = 'prefix',
      case_sensitive = false,
      keyword_length = 2,
    })
  end,
}
```

## Quick Start

1. Call `require('cmp_prompt_abbr').setup({ mappings = {...} })` somewhere after `nvim-cmp` is available.
2. Add the source to your cmp configuration:

   ```lua
   local cmp = require('cmp')

   cmp.setup({
     sources = cmp.config.sources({
       { name = 'prompt_abbr', option = { keyword_length = 1 } },
       { name = 'buffer' },
       { name = 'path' },
     }),
   })
   ```

3. Type the source text (e.g. `afaik`). When you confirm the completion item, the target text replaces the source.

## Configuration

`cmp_prompt_abbr.setup` accepts the following top-level keys:

| Option | Type | Default | Description |
| --- | --- | --- | --- |
| `mappings` | table[] | `{}` | Array of mapping tables, each with a required `source` and `target`, and optional `label` and `doc` fields. |
| `matching` | string | `'prefix'` | Matching strategy. One of `'prefix'`, `'substring'`, or `'lua_pattern'`. For patterns, the source text is matched using Lua patterns. |
| `case_sensitive` | boolean | `false` | If `false`, comparisons are case-insensitive (pattern mode lowercases both the source text and the typed word). |
| `keyword_length` | number | `1` | Minimum length of the word under the cursor before suggestions appear. |
| `priority` | number or `nil` | `nil` | Optional priority forwarded to the completion items to influence sorting. |

Example mapping entry:

```lua
{
  source = 'eta',
  target = 'estimated time of arrival',
  label = 'eta → estimated time of arrival',
  doc = [[Short expansion frequently used in project updates.]],
}
```

## Per-source Overrides

You can override any option (including `mappings`) per source entry inside `cmp.setup`:

```lua
cmp.setup.filetype('markdown', {
  sources = cmp.config.sources({
    {
      name = 'prompt_abbr',
      option = {
        case_sensitive = true,
        mappings = {
          { source = 'cc', target = 'Creative Commons License (CC-BY-SA 4.0)' },
        },
      },
    },
    { name = 'buffer' },
  }),
})
```

Per-source options are validated with the same rules as global settings, so configuration mistakes raise a helpful Lua error.

## API Reference

- `require('cmp_prompt_abbr').setup(opts)` — configure defaults and register the source.
- `require('cmp_prompt_abbr').get_config()` — return a deep copy of the current effective configuration (handy for debugging or sharing with other plugins).
- `require('cmp_prompt_abbr').new_source()` — build a new source instance; mostly useful if you need to register manually with `cmp.register_source`.

## Tips

- When using `matching = 'lua_pattern'` with `case_sensitive = false`, both the source text and the typed word are lowercased before matching. Adjust pattern character classes accordingly (`%a` vs `%l`).
- Keep your abbreviation list in a separate Lua module and `require` it to keep your configuration tidy when the list grows large.
- Combine this source with [`cmp-buffer`](https://github.com/hrsh7th/cmp-buffer) or snippet sources to cover both strict replacements and free-form suggestions.
- If the characters immediately preceding the source text are ASCII letters, the plugin suppresses the suggestion; multi-byte characters (e.g., Japanese) act as boundaries, so `あいうbar` still expands while `foobar` does not.

## License

Distributed under the MIT License. See [LICENSE](LICENSE) for details.
