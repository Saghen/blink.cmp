local async = require('blink.cmp.lib.async')
local utils = require('blink.cmp.lib.utils')
local log_file = require('blink.cmp.fuzzy.build.log')

local build = {}

--- Gets the path to the blink.cmp root directory (parent of lua/)
--- @return string
local function get_project_root()
  local current_file = debug.getinfo(1, 'S').source:sub(2)
  -- Go up from lua/blink.cmp/fuzzy/build/init.lua to the project root
  return vim.fn.fnamemodify(current_file, ':p:h:h:h:h:h:h')
end

--- @param cmd string[]
--- @return blink.cmp.Task<vim.SystemCompleted>
local async_system = function(cmd, opts)
  return async.task.new(function(resolve, reject)
    local proc = vim.system(
      cmd,
      vim.tbl_extend('force', {
        cwd = get_project_root(),
        text = true,
      }, opts or {}),
      vim.schedule_wrap(function(out)
        if out.code == 0 then
          resolve(out)
        else
          reject(out)
        end
      end)
    )

    return function() return proc:kill('TERM') end
  end)
end

--- Detects if cargo supports +nightly
--- @return blink.cmp.Task<boolean>
local function supports_rustup()
  return async_system({ 'cargo', '+nightly', '--version' })
    :map(function() return true end)
    :catch(function() return false end)
end

--- Detect if cargo supports nightly
--- (defaulted to nightly in rustup or globally installed without rustup)
--- @return blink.cmp.Task<boolean>
local function supports_nightly()
  return async_system({ 'cargo', '--version' })
    :map(function(out) return out.stdout:match('nightly') end)
    :catch(function() return false end)
end

local function get_cargo_cmd()
  return async.task.all({ supports_rustup(), supports_nightly() }):map(function(results)
    local rustup = results[1]
    local nightly = results[2]

    if rustup then return { 'cargo', '+nightly', 'build', '--release' } end
    if nightly then return { 'cargo', 'build', '--release' } end

    utils.notify({
      { 'Rust ' },
      { 'nightly', 'DiagnosticInfo' },
      { ' not available via ' },
      { 'cargo --version', 'DiagnosticInfo' },
      { ' and rustup not detected via ' },
      { 'cargo +nightly --version', 'DiagnosticInfo' },
      { '. Cannot build fuzzy matching library' },
    }, vim.log.levels.ERROR)
  end)
end

--- Builds the rust binary from source
--- @return blink.cmp.Task
function build.build()
  utils.notify({ { 'Building fuzzy matching library from source...' } }, vim.log.levels.INFO)

  local log = log_file.create()
  log.write('Working Directory: ' .. get_project_root())

  return get_cargo_cmd()
    --- @param cmd string[]
    :map(function(cmd)
      log.write('Command: ' .. table.concat(cmd, ' ') .. '\n')
      log.write('\n\n---\n\n')

      return async_system(cmd, {
        stdout = function(_, data) log.write(data or '') end,
        stderr = function(_, data) log.write(data or '') end,
      })
    end)
    :map(
      function()
        utils.notify({
          { 'Successfully built fuzzy matching library. ' },
          { ':BlinkCmp build-log', 'DiagnosticInfo' },
        }, vim.log.levels.INFO)
      end
    )
    :catch(
      function()
        utils.notify({
          { 'Failed to build fuzzy matching library! ', 'DiagnosticError' },
          { ':BlinkCmp build-log', 'DiagnosticInfo' },
        }, vim.log.levels.ERROR)
      end
    )
    :map(function() log.close() end)
end

function build.build_log() log_file.open() end

return build
