# inline-diff.nvim

Lua Neovim plugin for live inline Git diffs. Runtime dependencies: Neovim 0.11+
and Git. Plenary is test-only.

## Checks

```bash
nvim --headless -u tests/minimal_init.lua -c "PlenaryBustedDirectory tests/ {minimal_init = 'tests/minimal_init.lua'}" -c "qa"
nvim --headless -u tests/minimal_init.lua -c "PlenaryBustedFile tests/path_to_spec.lua" -c "qa"
luacheck lua/
stylua lua/
```

## Architecture

- `lua/inline-diff/init.lua`: public API and buffer lifecycle.
- `lua/inline-diff/source.lua`: left-hand Git-ref, index, and empty snapshots.
- `lua/inline-diff/diff.lua`: line/word diff engine and legacy source wrapper.
- `lua/inline-diff/render.lua`: extmarks, highlights, and virtual lines.
- `lua/inline-diff/highlight.lua`: derived highlight groups.
- `lua/inline-diff/state.lua`: per-buffer state and caches.
- `plugin/inline-diff.lua`: user commands.
- `tests/`: Plenary-based tests.

The renderer compares a selected source with the current in-memory buffer. It
must not modify buffer text: deletions are virtual lines, while additions and
word changes are extmarks. Unsaved edits are part of the target.

Live refreshes are debounced. Async callbacks must verify buffer validity and
generation/source freshness before rendering. Preserve the string-ref API,
keep runtime dependencies minimal, add tests for behavior changes, and run the
suite before reporting completion.

Word-level colors are derived at runtime by shifting the HSL lightness and saturation of `DiffAdd`/`DiffDelete`. Groups are re-derived on `ColorScheme`. Deleted lines render as `virt_lines`.
