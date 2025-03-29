local fuzzy_config = require('blink.cmp.config').fuzzy
local download_config = fuzzy_config.prebuilt_binaries
local async = require('blink.cmp.lib.async')
local git = require('blink.cmp.fuzzy.download.git')
local files = require('blink.cmp.fuzzy.download.files')
local system = require('blink.cmp.fuzzy.download.system')

local download = {}

---@type boolean Have we passed UIEnter?
local _ui_entered = false
---@type function[] List of notifications.
local _msg_callbacks = {}

--- Fancy notification wrapper.
---@param msg [ string, string? ][]
---@param fallback string
local function _notify(msg, fallback, lvl)
  if vim.api.nvim_echo then
    if _ui_entered then
      --- After UIEnter emit message
      --- immediately.
      vim.api.nvim_echo(msg, true, {
        verbose = false,
      })
    else
      --- Queue notification for the
      --- UIEnter event.
      table.insert(
        _msg_callbacks,
        function()
          vim.api.nvim_echo(msg, true, {
            verbose = false,
          })
        end
      )
    end
  elseif fallback then
    vim.notify_once(fallback, lvl or vim.log.levels.WARN, { title = 'blink.cmp' })
  end
end

vim.api.nvim_create_autocmd('UIEnter', {
  callback = function()
    _ui_entered = true

    for _, fn in ipairs(_msg_callbacks) do
      pcall(fn)
    end
  end,
})

--- @param callback fun(err: string | nil, fuzzy_implementation?: 'lua' | 'rust')
function download.ensure_downloaded(callback)
  callback = vim.schedule_wrap(callback)

  if fuzzy_config.implementation == 'lua' then return callback(nil, 'lua') end

  async.task
    .await_all({ git.get_version(), files.get_version() })
    :map(function(results)
      return {
        git = results[1],
        current = results[2],
      }
    end)
    :map(function(version)
      -- no version file found, and found the shared rust library, user manually placed the .so file
      if version.current.missing and pcall(require, 'blink.cmp.fuzzy.rust') then return end

      local target_git_tag = download_config.force_version or version.git.tag

      -- built locally
      if version.current.sha ~= nil then
        -- up to date or version ignored, ignore
        if version.current.sha == version.git.sha or download_config.ignore_version_mismatch then return end

        -- out of date
        vim.schedule(
          function()
            _notify({
              { ' blink.cmp ', 'DiagnosticVirtualTextWarn' },
              { ': Found an ', 'Comment' },
              { 'outdated version', 'DiagnosticWarn' },
              { ' of the locally built ', 'Comment' },
              { 'fuzzy matching library', 'DiagnosticHint' },
              { '.', 'Comment' },
            }, '[blink.cmp]: Found an outdated version of the locally built fuzzy matching library.')
          end
        )

        -- downloading enabled but not on a git tag, error
        if download_config.download and target_git_tag == nil then
          if target_git_tag == nil then
            _notify(
              {
                { ' blink.cmp ', 'DiagnosticVirtualTextWarn' },
                { ": Couldn't update the ", 'Comment' },
                { 'outdated version', 'DiagnosticWarn' },
                { ' of the ', 'Comment' },
                { 'fuzzy matching library', 'DiagnosticHint' },
                { ' due to not being in a ', 'Comment' },
                { 'git tag', 'DiagnosticHint' },
                { '. Try running ', 'Comment' },
                { ' cargo build --release ', 'DiagnosticVirtualTextHint' },
                { ' or enable ', 'Comment' },
                { 'fuzzy.prebuilt_binaries.', 'DiagnosticHint' },
                { 'ignore_version_mismatch', 'DiagnosticOk' },
                { ' or ', 'Comment' },
                { 'fuzzy.prebuilt_binaries.', 'DiagnosticHint' },
                { 'force_version', 'DiagnosticOk' },
                { ' .', 'Comment' },
              },
              '[blink.cmp]: Couldn\'t update the "outdated version" of the fuzzy matching library due to not being in a "git tag". Try running "cargo build --release" or enable "fuzzy.prebuilt_binaries.ignore_version_mismatch" or "fuzzy.prebuilt_binaries.force_version".'
            )
          end

        -- downloading is disabled, error
        else
          _notify(
            {
              { ' blink.cmp ', 'DiagnosticVirtualTextWarn' },
              { ": Couldn't update the ", 'Comment' },
              { 'outdated version', 'DiagnosticWarn' },
              { ' of the ', 'Comment' },
              { 'fuzzy matching library', 'DiagnosticHint' },
              { ' due to github downloads being ', 'Comment' },
              { 'disabled', 'DiagnosticHint' },
              { '. Try running ', 'Comment' },
              { ' cargo build --release ', 'DiagnosticVirtualTextHint' },
              { ' or enable ', 'Comment' },
              { 'fuzzy.prebuilt_binaries.', 'DiagnosticHint' },
              { 'ignore_version_mismatch', 'DiagnosticOk' },
              { ' or ', 'Comment' },
              { 'fuzzy.prebuilt_binaries.', 'DiagnosticHint' },
              { 'force_version', 'DiagnosticOk' },
              { '.', 'Comment' },
            },
            '[blink.cmp]: Couldn\'t update the "outdated version" of the fuzzy matching library due to github downloads being "disabled". Try running "cargo build --release" or enable "fuzzy.prebuilt_binaries.ignore_version_mismatch" or "fuzzy.prebuilt_binaries.force_version".'
          )
        end
      end

      -- downloading disabled but not built locally
      if not download_config.download then
        ---@type boolean Have we already raised the error?
        local raised_error = false

        -- Fallback, just check if the shared rust library exists
        vim.schedule(function()
          if raised_error then return end

          _notify({
            { ' blink.cmp ', 'DiagnosticVirtualTextError' },
            { ': No Fuzzy matching library found!', 'Comment' },
          }, '[blink.cmp]: No Fuzzy matching library found!')
        end)

        _notify(
          {
            { ' blink.cmp ', 'DiagnosticVirtualTextWarn' },
            { ': No fuzzy matching library found!', 'Comment' },
            { '. Try running ', 'Comment' },
            { ' cargo build --release ', 'DiagnosticVirtualTextHint' },
            { ' or enable ', 'Comment' },
            { 'fuzzy.prebuilt_binaries.', 'DiagnosticHint' },
            { 'download', 'DiagnosticOk' },
            { ' .', 'Comment' },
          },
          'blink.cmp : No fuzzy matching library found!. Try running "cargo build --release" or enable "fuzzy.prebuilt_binaries.download".'
        )
        raised_error = true
      end

      -- downloading enabled but not on a git tag
      if target_git_tag == nil then
        ---@type boolean Have we already raised the error?
        local raised_error = false

        vim.schedule(function()
          if raised_error then return end

          _notify({
            { ' blink.cmp ', 'DiagnosticVirtualTextError' },
            { ': No Fuzzy matching library found!', 'Comment' },
          }, '[blink.cmp]: No Fuzzy matching library found!')
        end)

        _notify(
          {
            { ' blink.cmp ', 'DiagnosticVirtualTextWarn' },
            { ': No fuzzy matching library found!', 'Comment' },
            { '. Try running ', 'Comment' },
            { ' cargo build --release ', 'DiagnosticVirtualTextHint' },
            { ' or switch to a ', 'Comment' },
            { ' git tag ', 'DiagnosticVirtualTextHint' },
            { ' or enable ', 'Comment' },
            { 'fuzzy.prebuilt_binaries.', 'DiagnosticHint' },
            { 'force_version', 'DiagnosticOk' },
            { ' .', 'Comment' },
          },
          'blink.cmp : No fuzzy matching library found! Try running "cargo build --release" or switch tp a "git tag" or enable "fuzzy.prebuilt_binaries.force_version".'
        )
        raised_error = true
      end

      -- already downloaded and the correct version, just verify the checksum, and re-download if checksum fails
      if version.current.tag == target_git_tag then
        return files.verify_checksum():catch(function(err)
          vim.schedule(
            function()
              _notify({
                { ' blink.cmp ', 'DiagnosticVirtualTextInfo' },
                { 'Pre-built binary checksum verification failed, ', 'Comment' },
                { err, 'DiagnosticError' },
              }, '[blink.cmp]: Pre-built binary checksum verification failed, ' .. err, vim.log.levels.ERROR)
            end
          )
          return download.download(target_git_tag)
        end)
      end

      -- download as per usual
      vim.schedule(
        function()
          _notify({
            { ' blink.cmp ', 'DiagnosticVirtualTextInfo' },
            { ': Downloading pre-built binary.', 'Comment' },
          }, '[blink.cmp]: Downloading pre-built binaries.', vim.log.levels.INFO)
        end
      )
      return download.download(target_git_tag)
    end)
    :map(function()
      -- clear cached module first since we call it in the pcall above
      package.loaded['blink.cmp.fuzzy.rust'] = nil

      callback(nil, 'rust')
    end)
    :catch(function(err)
      -- fallback to lua implementation
      if fuzzy_config.implementation == 'prefer_rust' then
        callback(nil, 'lua')

      -- fallback to lua implementation and emit warning
      elseif fuzzy_config.implementation == 'prefer_rust_with_warning' then
        vim.schedule(
          function()
            _notify(
              {
                { ' blink.cmp ', 'DiagnosticVirtualTextWarn' },
                { ': Falling back to ', 'Comment' },
                { ' Lua implementation ', 'DiagnosticHint' },
                { ' due to error while downloading pre-built binary, set ', 'Comment' },
                { 'fuzzy.', 'DiagnosticHint' },
                { 'implementation', 'DiagnosticOk' },
                { ' to ', 'Comment' },
                { ' "prefer_rust" ', 'DiagnosticVirtualTextHint' },
                { ' or ', 'Comment' },
                { ' "lua" ', 'DiagnosticVirtualTextHint' },
                { ' to hide this, ', 'Comment' },
                { err or '', 'DiagnosticError' },
              },
              '[blink.cmp]: Falling back to "Lua implementation" due to error while downloading pre-built binary, set "fuzzy.implementation" to "prefer_rust" or "lua" to hide this,'
                .. (err or '')
            )
          end
        )
        callback(nil, 'lua')
      else
        callback(err)
      end
    end)
end

function download.download(version)
  -- NOTE: we set the version to 'v0.0.0' to avoid a failure causing the pre-built binary being marked as locally built
  return files
    .set_version('v0.0.0')
    :map(function() return download.from_github(version) end)
    :map(function() return files.verify_checksum() end)
    :map(function() return files.set_version(version) end)
end

--- @param tag string
--- @return blink.cmp.Task
function download.from_github(tag)
  return system.get_triple():map(function(system_triple)
    if not system_triple then
      _notify(
        {
          { ' blink.cmp ', 'DiagnosticVirtualTextWarn' },
          { ': Your system is not supported by ', 'Comment' },
          { ' pre-built binary ', 'DiagnosticVirtualTextInfo' },
          { ', You should run ', 'Comment' },
          { ' cargo build --release ', 'DiagnosticVirtualTextHint' },
          { ' with ', 'Comment' },
          { ' Rust nightly ', 'DiagnosticVirtualTextHint' },
          { '.', 'Comment' },
        },
        '[blink.cmp]: Your system is not supported by "pre-built library", you must run "cargo build --release" with "Rust nightly".'
      )
      return
    end

    local base_url = 'https://github.com/saghen/blink.cmp/releases/download/' .. tag .. '/'
    local library_url = base_url .. system_triple .. files.get_lib_extension()
    local checksum_url = base_url .. system_triple .. files.get_lib_extension() .. '.sha256'

    return async
      .task
      .await_all({
        download.download_file(library_url, files.lib_filename .. '.tmp'),
        download.download_file(checksum_url, files.checksum_filename),
      })
      -- Mac caches the library in the kernel, so updating in place causes a crash
      -- We instead write to a temporary file and rename it, as mentioned in:
      -- https://developer.apple.com/documentation/security/updating-mac-software
      :map(
        function()
          return files.rename(
            files.lib_folder .. '/' .. files.lib_filename .. '.tmp',
            files.lib_folder .. '/' .. files.lib_filename
          )
        end
      )
  end)
end

--- @param url string
--- @param filename string
--- @return blink.cmp.Task
function download.download_file(url, filename)
  return async.task.new(function(resolve, reject)
    local args = { 'curl' }

    -- Use https proxy if available
    if download_config.proxy.url ~= nil then
      vim.list_extend(args, { '--proxy', download_config.proxy.url })
    elseif download_config.proxy.from_env then
      local proxy_url = os.getenv('HTTPS_PROXY')
      if proxy_url ~= nil then vim.list_extend(args, { '--proxy', proxy_url }) end
    end

    vim.list_extend(args, download_config.extra_curl_args)
    vim.list_extend(args, {
      '--fail', -- Fail on 4xx/5xx
      '--location', -- Follow redirects
      '--silent', -- Don't show progress
      '--show-error', -- Show errors, even though we're using --silent
      '--create-dirs',
      '--output',
      files.lib_folder .. '/' .. filename,
      url,
    })

    vim.system(args, {}, function(out)
      if out.code ~= 0 then
        reject('Failed to download ' .. filename .. 'for pre-built binaries: ' .. out.stderr)
      else
        resolve()
      end
    end)
  end)
end

return download
