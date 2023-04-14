# svea-lz

SVEA Compression for Dual Universe

# Test Dependencies

## First time setup

To get luarocks working properly with dependencies on Windows, here's one way to do it.

- Open Powershell and install scoop.sh
- `Set-ExecutionPolicy RemoteSigned -Scope CurrentUser` _Optional: Needed to run a remote script the first time_
- `irm get.scoop.sh | iex`
- `scoop install luarocks` _Installs luarocks, a lua packaging manager_
- `luarocks install busted` _Installs busted, a test runner framework_
- `luarocks install luacov` _Installs luacov, a test coverage reporter_
- `luarocks install cluacov` _Installs cluacov, a native (faster) addon for luacov_
- Close Powershell and restart any Visual Studio Code project you want busted to work in
- Open Visual Studio Code and open its Terminal (see file menu at top)
- `chcp` _Shows your current code page, for example 850_
- `chcp 65001` _Changes your code page to Utf-8, so you can see busteds output more clearly_

## Running tests

- `busted` _Runs all tests defined in the `./.busted` file_
- `busted -t [#end-to-end]` _Runs all tests tagged as `#end-to-end` (see `/src/compression/LZWS_spec.lua` for example)_
- `busted -v` _Verbose mode_
- `busted -c` _Generates `./luacov.stats.out`_
- `luacov` _Generates `./luacov.report.out`_