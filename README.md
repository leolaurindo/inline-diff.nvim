# inline-diff.nvim

![Demo](/.github/assets/diff.gif)

A fork of [cvlmtg/inline-diff.nvim](https://github.com/cvlmtg/inline-diff.nvim). It preserves the original `inline-diff` module and command API while adding workspace mode, hunk navigation, additional comparison sources and other maintenance improvements.

`Inline-diff.nvim` shows Git changes directly inside the current Neovim buffer, with deleted
lines rendered as virtual lines and changed words highlighted inline.

This keeps the original plugin's focused design: it is a live visualization
for the buffer you are editing, not a replacement for a full split-based diff
or pull-request review interface.

## Features

- Live inline diff updates while typing
- Word-level highlighting for modified lines
- Deleted lines displayed as virtual lines
- Line diffs powered by Neovim's built-in `vim.diff()`
- Debounced updates with configurable highlighting
- Compare against `HEAD`, the index, any local Git ref, or an empty snapshot
- Workspace mode for automatically enabling diffs in normal file buffers
- Hunk navigation with `:InlineDiffNext` and `:InlineDiffPrev`
- Untracked files displayed as additions
- No dependencies beyond Neovim 0.11+ and Git

## Fork changes

- Workspace-wide enablement for normal file buffers
- Next/previous hunk navigation
- Configurable strikethrough for deleted words
- Modular left-hand sources for Git refs, the index, and empty snapshots
- Untracked files rendered as additions

See [`CHANGELOG.md`](CHANGELOG.md) for the project history.

## Comparison model

The plugin always renders onto the current in-memory buffer. The comparison is
therefore:

```text
selected source -> current buffer
```

The current buffer normally represents the worktree, but can also include unsaved
changes.

| Command or source | Comparison |
| --- | --- |
| `:InlineDiff` | `HEAD -> current buffer` |
| `:InlineDiff HEAD~1` | `HEAD~1 -> current buffer` |
| `:InlineDiff staged` | `index -> current buffer` |
| `:InlineDiff origin/main` | `origin/main -> current buffer` |


## Installation

### lazy.nvim

```lua
{
  "leolaurindo/inline-diff.nvim",
  opts = {},
}
```

### packer.nvim

```lua
use {
  "leolaurindo/inline-diff.nvim",
  config = function()
    require("inline-diff").setup()
  end,
}
```

### Native package directory

Neovim 0.11+ can load the plugin as a native package:

```bash
mkdir -p ~/.local/share/nvim/site/pack/plugins/start
git clone https://github.com/leolaurindo/inline-diff.nvim \
  ~/.local/share/nvim/site/pack/plugins/start/inline-diff.nvim
```

### `vim.pack`

Neovim 0.12+ users can use the built-in package manager:

```lua
vim.pack.add({
  { src = "https://github.com/leolaurindo/inline-diff.nvim" },
})
```

Then call `setup()` in your Neovim configuration:

```lua
require("inline-diff").setup()
```

## Usage

Toggle the current buffer:

```vim
:InlineDiff
:InlineDiff HEAD~1
:InlineDiff staged
```

Choose a keymap:

```lua
vim.keymap.set("n", "<leader>gd", "<cmd>InlineDiff<cr>", {
  desc = "Toggle inline diff",
})
```

Enable workspace mode for normal file buffers:

```vim
:InlineDiffWorkspace HEAD
:InlineDiffWorkspace staged
:InlineDiffWorkspaceDisable
```

Workspace mode enables buffers as they are entered; it does not enumerate every
file in the repository.

Navigate between changed hunks:

```lua
vim.keymap.set("n", "]c", "<cmd>InlineDiffNext<cr>", { desc = "Next change" })
vim.keymap.set("n", "[c", "<cmd>InlineDiffPrev<cr>", { desc = "Previous change" })
```

## Lua API

```lua
local inline_diff = require("inline-diff")

inline_diff.setup({
  debounce_ms = 150,
  word_del_strikethrough = true,
})

inline_diff.enable(0, "HEAD")
inline_diff.disable(0)
inline_diff.next_hunk(0)
inline_diff.prev_hunk(0)
```

The second argument to `enable()` may also be an explicit source table:

```lua
inline_diff.enable(0, { type = "git", ref = "HEAD~1" })
inline_diff.enable(0, { type = "index" })
inline_diff.enable(0, { type = "empty" })
```

`"staged"` is the shorthand for the index source. A path missing from a Git
snapshot is treated as empty, so an untracked file is shown as an addition.

For the complete command, API, configuration, and highlight-group reference,
see `:help inline-diff`.

## Pull requests

There is no provider-specific PR integration. To inspect a checked-out PR
branch against its base, fetch the base ref and compare against it:

```vim
:InlineDiff origin/main
```

The remote ref must already exist locally, and the command applies to the
current buffer. Use a full diff UI for changed-file lists, review comments, or
comparisons where neither side is the current buffer.

## Fork and versioning

This fork retains the upstream history and remains compatible with the
`inline-diff` module and commands. It is based on upstream `v3.0.0`; fork
releases continue from that version rather than resetting the version history.

Upstream project: <https://github.com/cvlmtg/inline-diff.nvim>
