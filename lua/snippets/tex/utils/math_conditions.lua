--- Copied from `https://github.com/L3MON4D3/LuaSnip/wiki/Misc#mathematical-context-detection-for-conditional-expansion-without-relying-on-vimtexs-in_mathzone`
--- Modified to fit my usages

--- Original comments:
--[[  
Optimized Mathematical Context Detection Module for LuaSnip's autosnippets.  

Features:  
- Configurable caching mechanism  
- Configurable incremental parsing  
- Robust math environment detection  
- Multiple fallback strategies  

Last updated: 2025-05-25  
]]

-- Module table
local M = {}
M.fn = {}

------------------------------------------------------------------------------
-- UNIFIED CACHE MECHANISM (Configurable)
------------------------------------------------------------------------------
local function create_unified_cache(options)
  -- Default configuration with options handling
  local config = {
    max_size = (options and options.max_size) or 100, -- Maximum cache size
    on_evict = (options and options.on_evict) or function() end,
    on_miss = (options and options.on_miss) or function() end,
    eviction_strategy = (options and options.eviction_strategy) or "lru",
  }

  -- Cache storage structure
  local cache = {
    items = {}, -- Cached items
    access_count = {}, -- Access frequency tracking
    last_access = {}, -- Last accessed timestamp tracking
    config = config, -- Cache configuration
  }

  -- Update access tracking
  local access_clock = 0
  local function update_access_tracking(full_key)
    cache.access_count[full_key] = (cache.access_count[full_key] or 0) + 1
    access_clock = access_clock + 1
    cache.last_access[full_key] = access_clock
  end

  -- Eviction strategies
  local eviction_strategies
  eviction_strategies = {
    lru = function()
      local oldest_key, oldest_time = nil, math.huge
      for key, access_time in pairs(cache.last_access) do
        if access_time < oldest_time then
          oldest_key, oldest_time = key, access_time
        end
      end
      return oldest_key
    end,
    lfu = function()
      local least_used_key, least_count = nil, math.huge
      for key, count in pairs(cache.access_count) do
        if count < least_count then
          least_used_key, least_count = key, count
        end
      end
      return least_used_key
    end,
    arc = function()
      local lru_key = eviction_strategies.lru()
      local lfu_key = eviction_strategies.lfu()
      return lru_key or lfu_key -- Combine LRU and LFU strategies
    end,
  }

  -- Namespace-aware cache getter method
  function cache:get(namespace, key)
    local full_key = string.format("%s:%s", namespace, tostring(key))
    local value = self.items[full_key]

    if value ~= nil then
      update_access_tracking(full_key) -- Update access tracking
      return value
    else
      config.on_miss(namespace, key) -- Trigger cache miss callback
      return nil
    end
  end

  -- Namespace-aware cache setter method
  function cache:set(namespace, key, value)
    local full_key = string.format("%s:%s", namespace, tostring(key))

    -- Eviction logic
    if config.max_size <= 0 then
      return false
    end
    if self.items[full_key] == nil and #vim.tbl_keys(self.items) >= config.max_size then
      local evict_strategy = eviction_strategies[config.eviction_strategy] or eviction_strategies.lru
      local key_to_evict = evict_strategy()

      if key_to_evict then
        config.on_evict(key_to_evict, self.items[key_to_evict]) -- Trigger eviction callback
        -- Remove evicted item
        self.items[key_to_evict] = nil
        self.access_count[key_to_evict] = nil
        self.last_access[key_to_evict] = nil
      end
    end

    -- Add or update cache item
    self.items[full_key] = value
    update_access_tracking(full_key)

    return true
  end

  -- Utility methods
  function cache:clear()
    self.items = {}
    self.access_count = {}
    self.last_access = {}
  end

  function cache:size()
    return #vim.tbl_keys(self.items) -- Return the number of cached items
  end

  function cache:stats()
    return {
      total_items = #vim.tbl_keys(self.items),
      max_size = config.max_size,
      eviction_strategy = config.eviction_strategy,
    }
  end

  return cache
end

------------------------------------------------------------------------------
-- CONFIGURATION AND SETUP
------------------------------------------------------------------------------
M.config = {
  -- Performance and parsing settings
  cache_size = 300,
  use_cache = true, -- Enable/disable the caching mechanism
  incremental_parsing = {
    enabled = true, -- Enable/disable incremental parsing
    max_lines_for_full_parse = 1000, -- Max lines for full parse
    partial_update_threshold = 50, -- Threshold for partial updates
  },

  -- Logging and debugging
  debug = false, -- Enable debug logging

  -- Detection method priorities
  detection_strategies = {
    "cache", -- Fastest
    "treesitter", -- Intermediate speed
    "regex", -- Slower fallback
    "environment", -- Slowest
  },

  -- Math environment definitions
  math_environments = {
    latex = {
      equation = true,
      ["equation*"] = true,
      align = true,
      displaymath = true,
      gather = true,
      multline = true,
    },
    context = {
      formula = true,
      subformulas = true,
      placeformula = true,
    },
    markdown = {
      inline = true, -- $...$
      display = true, -- $$...$$
    },
  },
}

-- Initialize the unified cache only if caching is enabled
if M.config.use_cache then
  M.cache = create_unified_cache({
    max_size = M.config.cache_size,
    on_evict = function(key, value)
      if M.config.debug then
        vim.notify(string.format("Evicting cache key: %s (value: %s)", key, tostring(value)), vim.log.levels.DEBUG)
      end
    end,
    on_miss = function(namespace, key)
      if M.config.debug then
        vim.notify(string.format("Cache miss in namespace %s for key %s", namespace, key), vim.log.levels.DEBUG)
      end
    end,
    eviction_strategy = M.config.eviction_strategy or "lru", -- Default eviction strategy
  })
else
  M.cache = nil -- Disable caching
end

------------------------------------------------------------------------------
-- CONFIGURATION SETUP
------------------------------------------------------------------------------
function M.setup(user_config)
  -- Deep merge user configurations
  M.config = vim.tbl_deep_extend("force", M.config, user_config or {})

  -- Validate incremental parsing settings
  if type(M.config.incremental_parsing.enabled) ~= "boolean" then
    M.config.incremental_parsing.enabled = false

    if M.config.debug then
      vim.notify("Invalid incremental parsing setting. Defaulting to false.", vim.log.levels.WARN)
    end
  end

  -- Reinitialize cache if caching is enabled
  if M.config.use_cache then
    M.cache = create_unified_cache({
      max_size = M.config.cache_size,
      on_evict = function(key, value)
        if M.config.debug then
          vim.notify(string.format("Evicting cache key: %s (value: %s)", key, tostring(value)), vim.log.levels.DEBUG)
        end
      end,
      on_miss = function(namespace, key)
        if M.config.debug then
          vim.notify(string.format("Cache miss in namespace %s for key %s", namespace, key), vim.log.levels.DEBUG)
        end
      end,
      eviction_strategy = M.config.eviction_strategy or "lru",
    })
  else
    M.cache = nil -- Disable caching
  end

  -- Optional debug logging
  if M.config.debug then
    vim.notify("Math Detection Config: " .. vim.inspect(M.config), vim.log.levels.DEBUG)
  end
end

------------------------------------------------------------------------------
-- INCREMENTAL PARSING HELPER
------------------------------------------------------------------------------
local function get_incremental_parser(buffer, language)
  local ok, parser = pcall(vim.treesitter.get_parser, buffer, language)
  if not ok or not parser then
    return nil
  end

  local config = M.config.incremental_parsing
  if not config.enabled then
    local line_count = vim.api.nvim_buf_line_count(buffer)

    -- Determine max_lines_for_full_parse if it's a function
    local max_lines = type(config.max_lines_for_full_parse) == "function" and config.max_lines_for_full_parse()
      or config.max_lines_for_full_parse

    if line_count > max_lines then
      if not pcall(parser.parse, parser, true) then
        return nil
      end
    end
  end

  return parser
end

local function get_root(parser)
  if not parser then
    return nil
  end
  local ok, trees = pcall(parser.parse, parser)
  if ok and trees and trees[1] then
    return trees[1]:root()
  end
end

local function context_key(with_cursor)
  local buffer = vim.api.nvim_get_current_buf()
  local key = string.format("%d:%d:%s", buffer, vim.api.nvim_buf_get_changedtick(buffer), vim.bo.filetype)
  if with_cursor then
    local cursor = vim.api.nvim_win_get_cursor(0)
    key = string.format("%s:%d:%d", key, cursor[1], cursor[2])
  end
  return key
end

local function cached(namespace, key)
  if M.config.use_cache and M.cache then
    return M.cache:get(namespace, key)
  end
end

------------------------------------------------------------------------------
-- HELPER FUNCTIONS
------------------------------------------------------------------------------
local function get_cursor_pos()
  local cursor = vim.api.nvim_win_get_cursor(0) -- Get cursor position
  return cursor[1], cursor[2] + 1 -- Return 1-indexed row and column
end

-------------------------------------------------------------------------------
-- MATH ZONE DETECTION
-------------------------------------------------------------------------------
local function create_math_query()
  local cached_query = {}
  return function(lang)
    lang = lang or vim.bo.filetype
    if not cached_query[lang] then
      if lang == "latex" then
        cached_query[lang] = vim.treesitter.query.parse(
          "latex",
          [[
            (math_environment
              (begin
                (curly_group_text
                  (text) @env_name
                )
              )
            )
            (inline_formula) @inline
            (displayed_equation) @display
          ]]
        )
      elseif lang == "markdown" or lang == "markdown_inline" then
        -- Only if markdown Treesitter supports math nodes (optional)
        cached_query[lang] = vim.treesitter.query.parse(
          "markdown_inline",
          [[
            ; (inline_math) @inline
            ; (display_math) @display
            (latex_block) @display
            ; (displayed_equation) @display
          ]]
        )
      end
    end
    return cached_query[lang]
  end
end

local get_math_query = create_math_query()

function M.is_mathzone()
  local current_row, current_col = get_cursor_pos()
  local cache_key = context_key(true)
  local lang = vim.bo.filetype
  if lang == "tex" then
    lang = "latex" -- Normalize filetype for TeX files
  end
  if lang == "markdown" then
    lang = "markdown_inline"
  end

  -- Check cache first if caching is enabled
  local cached_result = cached("mathzone", cache_key)
  if cached_result ~= nil then
    return cached_result
  end

  -- Store numeric ranges, not nodes tied to a potentially stale parse tree.
  local tree_key = context_key(false)
  local ranges = cached("math_ranges", tree_key)
  if not ranges then
    local root = get_root(get_incremental_parser(0, lang))
    local ok, query = pcall(get_math_query, lang)
    if not root or not ok or not query then
      return M.is_mathzone_fallback()
    end
    ranges = {}
    for id, node in query:iter_captures(root, 0) do
      local capture = query.captures[id]
      if capture == "env_name" then
        local name = vim.treesitter.get_node_text(node, 0)
        node = M.config.math_environments.latex[name] and node:parent():parent():parent() or nil
      elseif capture ~= "inline" and capture ~= "display" then
        node = nil
      end
      if node then
        ranges[#ranges + 1] = { node:range() }
      end
    end
    if M.config.use_cache then
      M.cache:set("math_ranges", tree_key, ranges)
    end
  end

  local row, col = current_row - 1, current_col - 1
  for _, range in ipairs(ranges) do
    if
      (row > range[1] or row == range[1] and col >= range[2])
      and (row < range[3] or row == range[3] and col < range[4])
    then
      if M.config.use_cache then
        M.cache:set("mathzone", cache_key, true)
      end
      return true
    end
  end

  if M.config.use_cache then
    M.cache:set("mathzone", cache_key, false)
  end

  return false
end

------------------------------------------------------------------------------
-- REGEX-BASED DETECTION
------------------------------------------------------------------------------
local function safe_regex_matcher(line)
  local matches = {}
  local patterns = {
    { pattern = "()%$(.-)%$()", type = "inline" },
    { pattern = "()%$%$(.-)%$%$()", type = "display" },
    { pattern = "()\\%((.-)\\%)()", type = "latex_inline" },
    { pattern = "()\\%[(.-)\\%]()", type = "latex_display" },
    { pattern = "()\\math{(.-)}()", type = "sile_inline" },
  }

  for _, pat in ipairs(patterns) do
    for start, content, stop in line:gmatch(pat.pattern) do
      table.insert(matches, {
        type = pat.type,
        start = start,
        stop = stop,
        content = content,
      })
    end
  end

  return matches
end

function M.is_mathzone_fallback()
  local current_row, current_col = get_cursor_pos()
  local cache_key = context_key(true)

  -- Check cache first if caching is enabled
  if M.config.use_cache then
    local cached_result = M.cache:get("fallback", cache_key)
    if cached_result ~= nil then
      return cached_result
    end
  end

  local line = vim.api.nvim_buf_get_lines(0, current_row - 1, current_row, false)[1] or ""
  local matches = safe_regex_matcher(line)

  -- Check for math zones in the current line
  for _, zone in ipairs(matches) do
    if current_col >= zone.start and current_col < zone.stop then
      -- Cache the result if caching is enabled
      if M.config.use_cache then
        M.cache:set("fallback", cache_key, true)
      end
      return true
    end
  end

  -- Cache the result as false if no match was found
  if M.config.use_cache then
    M.cache:set("fallback", cache_key, false)
  end

  return false
end

------------------------------------------------------------------------------
-- ENVIRONMENT DETECTION
------------------------------------------------------------------------------

local function in_environment(env_name)
  local current_row = get_cursor_pos()

  -- Check cache first if caching is enabled
  local cache_key = context_key(true) .. ":" .. env_name
  local cached_result = cached("environment", cache_key)
  if cached_result ~= nil then
    return cached_result
  end

  local start_patterns = {
    "\\begin{" .. env_name .. "}",
    "\\start" .. env_name,
  }

  local end_patterns = {
    "\\end{" .. env_name .. "}",
    "\\stop" .. env_name,
  }

  local last_start_marker = nil
  for line_num = current_row, 1, -1 do
    local text = vim.api.nvim_buf_get_lines(0, line_num - 1, line_num, false)[1] or ""

    for _, pat in ipairs(start_patterns) do
      if text:find(pat, 1, true) then
        last_start_marker = line_num
        break -- Break after finding a start marker
      end
    end

    if last_start_marker then
      break
    end
  end

  if not last_start_marker then
    if M.config.use_cache then
      M.cache:set("environment", cache_key, false)
    end
    return false
  end

  for line_num = last_start_marker, vim.api.nvim_buf_line_count(0) do
    local text = vim.api.nvim_buf_get_lines(0, line_num - 1, line_num, false)[1] or ""

    for _, pat in ipairs(end_patterns) do
      if text:find(pat, 1, true) then
        local result = line_num > current_row and last_start_marker < current_row
        if M.config.use_cache then
          M.cache:set("environment", cache_key, result)
        end
        return result
      end
    end
  end

  local result = last_start_marker < current_row
  if M.config.use_cache then
    M.cache:set("environment", cache_key, result)
  end
  return result
end

local document_query
local document_query_source = [[
    (class_include
      (curly_group_path
        (path) @document_type
      )
    )
  ]]

local function document_type()
  if vim.bo.filetype ~= "tex" then
    return nil -- Only applies to TeX files, not markdown or others
  end

  local key = context_key(false)
  local result = cached("document_type", key)
  if result ~= nil then
    return result or nil
  end
  local root = get_root(get_incremental_parser(0, "latex"))
  if not root then
    return nil
  end
  if not document_query then
    local ok, query = pcall(vim.treesitter.query.parse, "latex", document_query_source)
    if not ok or not query then
      return nil
    end
    document_query = query
  end

  for id, node in document_query:iter_captures(root, 0) do
    local capture_name = document_query.captures[id]

    if capture_name == "document_type" then
      local doc_type = vim.treesitter.get_node_text(node, 0)
      if M.config.use_cache then
        M.cache:set("document_type", key, doc_type)
      end
      return doc_type
    end
  end

  if M.config.use_cache then
    M.cache:set("document_type", key, false)
  end
  return nil
end

local function in_environment_ts(env_name)
  if vim.bo.filetype ~= "tex" then
    return false -- Only applies to TeX files, not markdown or others
  end

  local parser = get_incremental_parser(0, "latex")
  if not parser then
    return in_environment(env_name) -- Fallback to regex-based detection
  end

  local ok, node = pcall(vim.treesitter.get_node)
  if not ok or not node then
    return in_environment(env_name)
  end

  while node do
    if node:type() == "generic_environment" or node:type() == "math_environment" then
      local begin_node = node:field("begin")[1] -- Tree-sitter fields often return a list
      if begin_node then
        local name_node = begin_node:field("name")[1]
        if name_node then
          -- Get text and strip potential curly braces if necessary
          -- But usually get_node_text on the 'text' node is cleanest
          local current_env = vim.treesitter.get_node_text(name_node, 0)

          -- LaTeX names in curly_group_text often include the braces in the text
          -- or have a nested 'text' node. We strip braces to be safe.
          current_env = current_env:gsub("[{}]", "")

          if current_env == env_name then
            return true
          end
        end
      end
    end
    node = node:parent()
  end

  return false
end
------------------------------------------------------------------------------
-- SPECIFIC ENVIRONMENT CHECKS
------------------------------------------------------------------------------
M.fn.in_math = function()
  return M.fn.math_mode()
end

-- M.fn.in_text = function()
--   return in_environment("text") and not M.fn.math_mode()
-- end

M.fn.in_beamer = function()
  if vim.bo.filetype ~= "tex" then
    return false -- Only applies to TeX files, not markdown or others
  end
  local doc_type = document_type()
  return doc_type == "beamer" or doc_type == "ctexbeamer"
end

M.fn.in_align = function()
  return vim.bo.filetype == "tex"
    and (in_environment_ts("align") or in_environment_ts("align*") or in_environment_ts("aligned"))
end

M.fn.in_tikz = function()
  return vim.bo.filetype == "tex" and (in_environment("tikzpicture"))
end

M.fn.in_figure = function()
  -- Only check for figure environments in TeX files, not markdown or others
  return vim.bo.filetype == "tex" and (in_environment_ts("figure") or in_environment_ts("figure*"))
end

M.fn.in_bullets = function()
  return vim.bo.filetype == "tex" and (in_environment_ts("itemize") or in_environment_ts("enumerate"))
end

M.fn.in_MPcode = function()
  return vim.bo.filetype == "tex" and in_environment("MPcode")
end

local function is_math_range()
  local math_ranges = {
    "formula",
    "placeformula",
    "subformulas",
    "equation",
    "align",
    "displaymath",
    "gather",
    "multline",
  }

  for _, env in ipairs(math_ranges) do
    if in_environment(env) then
      return true
    end
  end

  return false
end

function M.is_in_sile_display_math()
  local current_row = get_cursor_pos()
  local cache_key = context_key(true)

  -- Check cache first
  if M.config.use_cache then
    local cached_result = M.cache:get("sile_display_math", cache_key)
    if cached_result ~= nil then
      return cached_result
    end
  end

  -- Look for the begin marker above the current row
  local begin_row = nil
  for row = current_row, 1, -1 do
    local line = vim.api.nvim_buf_get_lines(0, row - 1, row, false)[1] or ""
    if line:match("\\begin%[mode=display%]{math}") then
      begin_row = row
      break
    end
  end

  -- Return false if no begin marker is found
  if not begin_row then
    if M.config.use_cache then
      M.cache:set("sile_display_math", cache_key, false)
    end
    return false
  end

  -- Look for end marker below the last found begin marker
  local end_row = nil
  for row = begin_row, vim.api.nvim_buf_line_count(0) do
    local line = vim.api.nvim_buf_get_lines(0, row - 1, row, false)[1] or ""
    if line:match("\\end{math}") then
      end_row = row
      break
    end
  end

  -- Check if the cursor is within the display math environment
  local result = begin_row <= current_row and (not end_row or current_row <= end_row)

  if M.config.use_cache then
    M.cache:set("sile_display_math", cache_key, result)
  end
  return result
end

------------------------------------------------------------------------------
-- TEXT COMMAND DETECTION
------------------------------------------------------------------------------
local function is_cursor_in_text_command()
  if vim.bo.filetype ~= "tex" then
    return false -- Only applies to TeX files, not markdown or others
  end

  local current_row, current_col = get_cursor_pos()
  local cache_key = context_key(true)

  -- Check cache for result if caching is enabled
  local cached_result = cached("text_command", cache_key)
  if cached_result ~= nil then
    return cached_result
  end

  local line = vim.api.nvim_buf_get_lines(0, current_row - 1, current_row, false)[1] or ""
  local result = false
  for text_start, content_start in line:gmatch("()\\text{()") do
    local group = line:sub(content_start - 1):match("^%b{}")
    local text_end = group and content_start + #group - 2 or #line + 1
    if text_start < current_col and current_col < text_end then
      result = true
      break
    end
  end
  if M.config.use_cache then
    M.cache:set("text_command", cache_key, result) -- Store result in cache
  end
  return result
end

------------------------------------------------------------------------------
-- MATH MODE DETECTION
------------------------------------------------------------------------------
function M.fn.math_mode()
  -- TeX uses structural context; Markdown retains its own parser/fallbacks.
  if (vim.bo.filetype == "tex" or vim.bo.filetype == "plaintex") and package.loaded["tex-tools"] then
    local in_math, err = require("tex-tools").in_math()
    if not err then
      return in_math
    end
  end
  return (M.is_mathzone() or M.is_mathzone_fallback() or is_math_range() or M.is_in_sile_display_math())
    and not is_cursor_in_text_command()
end

local function false_fn()
  return false
end
M.fn.false_fn = false_fn

local function true_fn()
  return true
end
M.fn.true_fn = true_fn

function M.fn.is_latex()
  return vim.bo.filetype == "tex"
end

local cond_obj = require("luasnip.extras.conditions")
M.obj = {}
-- traverse all key-value pairs in M.fn
for k, v in pairs(M.fn) do
  M.obj[k] = cond_obj.make_condition(v)
end

------------------------------------------------------------------------------
-- NEOVIM INTEGRATION
------------------------------------------------------------------------------
vim.api.nvim_create_user_command("CheckCursorMathZone", function()
  if M.fn.math_mode() then
    print("Cursor is in a math mode")
  else
    print("Cursor is NOT in a math mode")
  end
end, {})

-- Initialize with default settings
M.setup({
  cache_size = 500,
  use_cache = false, -- Enable or disable caching
  eviction_strategy = "arc",
  incremental_parsing = {
    enabled = true,
    max_lines_for_full_parse = function()
      local line_count = vim.api.nvim_buf_line_count(0)
      return math.max(line_count, 1000) -- Minimum 1000 lines for full parse
    end,
    -- partial_update_threshold = 50, -- Lines for partial updates
  },
  debug = false, -- Enable debug logging
})

vim.api.nvim_create_user_command("DebugSileMath", function()
  local current_row, current_col = get_cursor_pos()
  local cursor = vim.api.nvim_win_get_cursor(0) -- Get cursor position
  local line = vim.api.nvim_buf_get_lines(0, current_row - 1, current_row, false)[1] or ""

  print("SILE Math Debug")
  print("Current line:", line)
  print("Cursor position:", current_row, current_col)
  print("Cursor position (nvim):", unpack(cursor))
  print("In math mode:", M.obj.math_mode())
  print("In math environment:", in_environment("math"))
  print("In SILE display math:", M.is_in_sile_display_math())

  -- Test pattern matching
  local test_string = "\\begin[mode=display]{math}"
  print("Test string:", test_string)
  print("Matches pattern \\begin%[mode=display%]{math}:", test_string:match("\\begin%[mode=display%]{math}") ~= nil)
end, {})

return M
