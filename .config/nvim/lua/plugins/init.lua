return {

  -- {
  --   "NvChad/NvChad",
  --   lazy = false,
  --   branch = "v2.5",
  -- },

  ------------------------------------------------------------------
  --- NVChad
  ------------------------------------------------------------------

  {
    "nvchad/base46",
    build = function()
      require("base46").load_all_highlights()
    end,
  },

  -- currently only needed for the custom LSP renamer and the tabufline and status bar
  {
    "nvchad/ui",
    lazy = false,
    config = function()
      require "nvchad"
    end,
  },

  -- { "nvzone/volt", lazy = true },
  -- { "nvzone/menu", lazy = true },
  -- { "nvzone/minty", cmd = { "Huefy", "Shades" } },

  {
    "nvim-tree/nvim-web-devicons",
    opts = function()
      dofile(vim.g.base46_cache .. "devicons")
      return { override = require "nvchad.icons.devicons" }
    end,
  },

  -- file managing , picker etc
  {
    "nvim-tree/nvim-tree.lua",
    cmd = { "NvimTreeToggle", "NvimTreeFocus" },
    opts = {
      filters = {
        dotfiles = false,
        git_ignored = true,
      },
      disable_netrw = true,
      hijack_cursor = true,
      sync_root_with_cwd = true,
      update_focused_file = {
        enable = true,
        update_root = false,
      },
      actions = {
        open_file = {
          quit_on_open = true,
        },
      },
      view = {
        width = 30,
        preserve_window_proportions = true,
      },
      renderer = {
        root_folder_label = false,
        highlight_git = true,
        indent_markers = { enable = true },
        icons = {
          glyphs = {
            default = "󰈚",
            folder = {
              default = "",
              empty = "",
              empty_open = "",
              open = "",
              symlink = "",
            },
            git = { unmerged = "" },
          },
        },
      },
      on_attach = function(bufnr)
        local api = require "nvim-tree.api"

        -- Default mappings
        api.config.mappings.default_on_attach(bufnr)

        -- Remove the - keymap
        vim.keymap.del("n", "-", { buffer = bufnr })

        -- press F to search in directory
        vim.keymap.set("n", "F", function()
          local node = api.tree.get_node_under_cursor()
          if not node then
            return
          end
          local path = node.absolute_path
          -- If it's a file, use its parent directory
          if node.type == "file" then
            path = vim.fn.fnamemodify(path, ":h")
          end
          require("snacks").picker.grep { cwd = path }
        end, { buffer = bufnr, noremap = true, silent = true, desc = "Live grep in directory" })
      end,
    },
  },

  {
    "folke/which-key.nvim",
    keys = { "<leader>", "<c-w>", '"', "'", "`", "c", "v", "g" },
    cmd = "WhichKey",
    opts = function()
      dofile(vim.g.base46_cache .. "whichkey")
      return {}
    end,
  },

  ------------------------------------------------------------------
  --- Formatting
  ------------------------------------------------------------------

  {
    "stevearc/conform.nvim",
    event = "BufWritePre", -- format on save
    opts = function()
      local opts = require "configs.conform"

      opts.formatters_by_ft = vim.tbl_deep_extend("force", opts.formatters_by_ft or {}, {
        rust = { "rustfmt_nightly" },
        solidity = { "forge_fmt" },
        lua = { "stylua" },
        json = { "jq" },
        toml = { "taplo" },
      })

      opts.formatters = vim.tbl_deep_extend("force", opts.formatters or {}, {
        rustfmt_nightly = {
          command = "rustfmt",
          options = {
            default_edition = "2021",
          },
          env = { RUSTUP_TOOLCHAIN = "nightly" },
          args = function(self, ctx)
            local args = {
              "--emit=stdout",
              "--unstable-features",
            }
            -- Get the edition from Cargo.toml or use default
            local edition = require("conform.util").parse_rust_edition(ctx.dirname) or self.options.default_edition
            table.insert(args, "--edition=" .. edition)
            return args
          end,
          stdin = true,
          cwd = require("conform.util").root_file {
            "Cargo.toml",
            "rustfmt.toml",
            ".rustfmt.toml",
          },
        },
      })

      opts.format_on_save = {
        lsp_format = "fallback",
        timeout_ms = 2000,
      }

      return opts
    end,
  },

  ------------------------------------------------------------------
  --- LSP stuff
  ------------------------------------------------------------------

  {
    "neovim/nvim-lspconfig",
    event = "User FilePost",
    opts = { diagnostics = { virtual_text = false } }, -- required for tiny-inline-diagnostic
    config = function()
      require "configs.lspconfig"
    end,
  },

  {
    "mason-org/mason.nvim",
    cmd = { "Mason", "MasonInstall", "MasonUpdate", "MasonUninstall" },
    opts = {
      PATH = "append", -- use stuff that already exists on $PATH
      ensure_installed = {
        "lua-language-server",
        "html-lsp",
        "prettier",
        "stylua",
        "gopls",
        "rust-analyzer",
        "solhint",
        "nomicfoundation-solidity-language-server",
        "copilot-language-server",
      },
    },
  },

  ------------------------------------------------------------------
  --- Git stuff
  ------------------------------------------------------------------

  {
    "lewis6991/gitsigns.nvim",
    event = "User FilePost",
    opts = {
      signs = {
        delete = { text = "󰍵" },
        changedelete = { text = "󱕖" },
      },
      current_line_blame = true,
      on_attach = function(bufnr)
        local gitsigns = require "gitsigns"

        local function map(mode, l, r, opts)
          opts = opts or {}
          opts.buffer = bufnr
          vim.keymap.set(mode, l, r, opts)
        end

        -- Navigation
        map("n", "]", function()
          if vim.wo.diff then
            vim.cmd.normal { "]c", bang = true }
          else
            ---@diagnostic disable-next-line: param-type-mismatch
            gitsigns.nav_hunk "next"
          end
        end)

        map("n", "[", function()
          if vim.wo.diff then
            vim.cmd.normal { "[c", bang = true }
          else
            ---@diagnostic disable-next-line: param-type-mismatch
            gitsigns.nav_hunk "prev"
          end
        end)

        -- Actions
        map("n", "<leader>hs", gitsigns.stage_hunk, { desc = "Git: Stage Hunk" })
        map("n", "<leader>hr", gitsigns.reset_hunk, { desc = "Git: Revert Hunk" })

        map("v", "<leader>hs", function()
          gitsigns.stage_hunk { vim.fn.line ".", vim.fn.line "v" }
        end, { desc = "Git: Stage Hunk" })

        map("v", "<leader>hr", function()
          gitsigns.reset_hunk { vim.fn.line ".", vim.fn.line "v" }
        end, { desc = "Git: Reset Hunk" })

        map("n", "<leader>hS", gitsigns.stage_buffer, { desc = "Git: Stage Buffer" })
        map("n", "<leader>hR", gitsigns.reset_buffer, { desc = "Git: Revert Buffer" })
        map("n", "<leader>hp", gitsigns.preview_hunk, { desc = "Git: Preview Hunk" })
        map("n", "<leader>hi", gitsigns.preview_hunk_inline, { desc = "Git: Preview Hunk Inline" })

        map("n", "<leader>hd", gitsigns.diffthis)

        map("n", "<leader>hD", function()
          ---@diagnostic disable-next-line: param-type-mismatch
          gitsigns.diffthis "~"
        end)

        map("n", "<leader>hQ", function()
          ---@diagnostic disable-next-line: param-type-mismatch
          gitsigns.setqflist "all"
        end)
        map("n", "<leader>hq", gitsigns.setqflist)

        -- Toggles
        map("n", "<leader>tb", gitsigns.toggle_current_line_blame, { desc = "gitsigns: toggle current line blame" })
        map("n", "<leader>tw", gitsigns.toggle_word_diff, { desc = "gitsigns: toggle word diff" })

        -- Text object
        map({ "o", "x" }, "ih", gitsigns.select_hunk)
      end,
    },
  },

  { "sindrets/diffview.nvim", lazy = false },

  {
    "NeogitOrg/neogit",
    lazy = false,
    dependencies = {
      "nvim-lua/plenary.nvim", -- required
      "sindrets/diffview.nvim", -- optional - Diff integration

      -- Only one of these is needed.
      -- "nvim-telescope/telescope.nvim", -- optional
      -- "ibhagwan/fzf-lua",              -- optional
      -- "echasnovski/mini.pick", -- optional
      "folke/snacks.nvim", -- optional
    },

    config = function()
      -- NOTE: need to re-apply these theme changes, otherwise they will disappear
      dofile(vim.g.base46_cache .. "syntax")
      -- dofile(vim.g.base46_cache .. "git")

      require("neogit").setup {
        disable_commit_confirmation = true,
        integrations = {
          diffview = true,
          snacks = true,
        },
      }
    end,
  },

  {
    "akinsho/git-conflict.nvim",
    version = "*",
    lazy = false,
    config = function()
      -- vim.api.nvim_set_hl(0, "GitConflictCurrent", { bg = "#4a2632", fg = "#ff9eb3" })
      -- vim.api.nvim_set_hl(0, "GitConflictIncoming", { bg = "#2d4a3a", fg = "#a3ff9e" })

      vim.api.nvim_set_hl(0, "GitConflictCurrent", { bg = "#4a2632", fg = "#ffddee" })
      vim.api.nvim_set_hl(0, "GitConflictIncoming", { bg = "#2d4a3a", fg = "#ddffee" })
      vim.api.nvim_set_hl(0, "GitConflictAncestor", { bg = "#4a4a2d", fg = "#ffffdd" })

      require("git-conflict").setup {
        default_mappings = true, -- disable buffer local mapping created by this plugin
        default_commands = true, -- disable commands created by this plugin
        disable_diagnostics = false, -- This will disable the diagnostics in a buffer whilst it is conflicted
        list_opener = "copen", -- command or function to open the conflicts list
        highlights = { -- They must have background color, otherwise the default color will be used
          incoming = "GitConflictIncoming",
          current = "GitConflictCurrent",
          ancestor = "GitConflictAncestor",
        },
        debug = false,
      }
    end,

    --- default mappings:
    -- co — choose ours
    -- ct — choose theirs
    -- cb — choose both
    -- c0 — choose none
    -- ]x — move to previous conflict
    -- [x — move to next conflict
  },

  ------------------------------------------------------------------
  --- Autocompletion
  ------------------------------------------------------------------

  -- compatibility layer for blink.cmp sources
  {
    "saghen/blink.compat",
    -- use v2.* for blink.cmp v1.*
    version = "2.*",
    -- lazy.nvim will automatically load the plugin when it's required by blink.cmp
    lazy = true,
    -- make sure to set opts so that lazy.nvim calls blink.compat's setup
    opts = {},
  },

  {
    "saghen/blink.cmp",
    lazy = false,
    -- optional: provides snippets for the snippet source
    dependencies = {
      --"rafamadriz/friendly-snippets"
      "saecki/crates.nvim",
    },

    -- use a release tag to download pre-built binaries
    version = "1.*",
    -- AND/OR build from source, requires nightly: https://rust-lang.github.io/rustup/concepts/channels.html#working-with-nightly-rust
    -- build = 'cargo build --release',
    -- If you use nix, you can build from source using latest nightly rust with:
    -- build = 'nix run .#build-plugin',

    ---@module 'blink.cmp'
    ---@type blink.cmp.Config
    opts = {
      -- 'default' (recommended) for mappings similar to built-in completions (C-y to accept)
      -- 'super-tab' for mappings similar to vscode (tab to accept)
      -- 'enter' for enter to accept
      -- 'none' for no mappings
      --
      -- All presets have the following mappings:
      -- C-space: Open menu or open docs if already open
      -- C-n/C-p or Up/Down: Select next/previous item
      -- C-e: Hide menu
      -- C-k: Toggle signature help (if signature.enabled = true)
      --
      -- See :h blink-cmp-config-keymap for defining your own keymap
      keymap = { preset = "enter" },

      appearance = {
        -- 'mono' (default) for 'Nerd Font Mono' or 'normal' for 'Nerd Font'
        -- Adjusts spacing to ensure icons are aligned
        nerd_font_variant = "mono",
      },

      signature = {
        enabled = false, -- TODO this is experimental, can enable later, it looks good
        window = {
          border = "single",
          show_documentation = true,
        },
      },

      -- (Default) Only show the documentation popup when manually triggered
      completion = {
        documentation = {
          auto_show = true,
          auto_show_delay_ms = 200,
          window = {
            border = "single",
            -- focusable = false,
          },
        },
        -- menu = require("nvchad.blink").menu,
        menu = {
          scrollbar = true,
          border = "single",
          draw = {
            padding = { 1, 1 },
            columns = { { "label" }, { "kind_icon" }, { "kind" } },
            components = {
              kind_icon = {
                text = function(ctx)
                  local icons = require "nvchad.icons.lspkind"
                  local icon = (icons[ctx.kind] or "󰈚")
                  return icon
                end,
              },

              kind = {
                highlight = function(ctx)
                  return ctx.kind
                end,
              },
            },
          },
        },
      },

      -- Default list of enabled providers defined so that you can extend it
      -- elsewhere in your config, without redefining it, due to `opts_extend`
      -- TODO check if integration with autopairs is good
      sources = {
        default = { "lsp", "path", "snippets", "buffer", "crates" },
        providers = {
          crates = {
            name = "crates",
            module = "blink.compat.source",
          },
          -- magenta = {
          --   name = "magenta",
          --   module = "blink.compat.source",
          -- },
        },
      },

      -- (Default) Rust fuzzy matcher for typo resistance and significantly better performance
      -- You may use a lua implementation instead by using `implementation = "lua"` or fallback to the lua implementation,
      -- when the Rust fuzzy matcher is not available, by using `implementation = "prefer_rust"`
      --
      -- See the fuzzy documentation for more information
      fuzzy = { implementation = "prefer_rust_with_warning" },
      -- cmdline = { enabled = false },
    },
    opts_extend = { "sources.default" },
  },

  {
    "supermaven-inc/supermaven-nvim",
    lazy = false,
    opts = {
      keymaps = {
        accept_suggestion = "<Tab>",
        -- clear_suggestion = "<C-S-h>",
        -- accept_word = "<S-l>",
      },
      color = {
        suggestion_color = "#7a7e85",
        cterm = 244,
      },
    },
  },

  ------------------------------------------------------------------
  --- MISC
  ------------------------------------------------------------------
  -- {
  --   "rachartier/tiny-glimmer.nvim",
  --   lazy = false,
  --   event = "VeryLazy",
  --   priority = 10, -- Low priority to catch other plugins' keybindings
  --   config = function()
  --     require("tiny-glimmer").setup()
  --   end,
  -- },

  { "powerman/vim-plugin-AnsiEsc", lazy = false },

  { "mbbill/undotree", lazy = false },

  {
    "nvim-treesitter/nvim-treesitter",
    event = { "BufReadPost", "BufNewFile" },
    cmd = { "TSInstall", "TSBufEnable", "TSBufDisable", "TSModuleInfo" },
    build = ":TSUpdate",
    opts = {
      ensure_installed = { "lua", "luadoc", "printf", "vim", "vimdoc", "nu" },

      highlight = {
        enable = true,
        use_languagetree = true,
      },

      indent = { enable = true },
    },
    config = function(_, opts)
      require("nvim-treesitter.configs").setup(opts)

      -- Set up folding via FileType autocmd (after filetype is detected)
      vim.api.nvim_create_autocmd("FileType", {
        callback = function()
          vim.opt_local.foldmethod = "expr"
          vim.opt_local.foldexpr = "v:lua.vim.treesitter.foldexpr()"
          vim.opt_local.foldlevel = 99
          vim.opt_local.foldlevelstart = 99
          vim.opt_local.foldenable = true
        end,
      })
    end,
  },

  {
    "jake-stewart/multicursor.nvim",
    lazy = false,
    branch = "1.0",
    config = function()
      local mc = require "multicursor-nvim"
      mc.setup()

      local set = vim.keymap.set

      -- Add or skip cursor above/below the main cursor.
      -- set({ "n", "x" }, "<up>", function()
      --   mc.lineAddCursor(-1)
      -- end)
      -- set({ "n", "x" }, "<down>", function()
      --   mc.lineAddCursor(1)
      -- end)
      -- set({ "n", "x" }, "<leader><up>", function()
      --   mc.lineSkipCursor(-1)
      -- end)
      -- set({ "n", "x" }, "<leader><down>", function()
      --   mc.lineSkipCursor(1)
      -- end)

      -- Add or skip adding a new cursor by matching word/selection
      set({ "n", "x" }, "m", function()
        mc.matchAddCursor(1)
      end)
      set({ "n", "x" }, "M", function()
        mc.matchAddCursor(-1)
      end)
      -- set({ "n", "x" }, "<leader>s", function()
      --   mc.matchSkipCursor(1)
      -- end)
      -- set({ "n", "x" }, "<leader>S", function()
      --   mc.matchSkipCursor(-1)
      -- end)

      -- Add and remove cursors with control + left click.
      set("n", "<c-leftmouse>", mc.handleMouse)
      set("n", "<c-leftdrag>", mc.handleMouseDrag)
      set("n", "<c-leftrelease>", mc.handleMouseRelease)

      -- Disable and enable cursors.
      set({ "n", "x" }, "<c-q>", mc.toggleCursor)

      -- Mappings defined in a keymap layer only apply when there are
      -- multiple cursors. This lets you have overlapping mappings.
      mc.addKeymapLayer(function(layerSet)
        -- Select a different cursor as the main one.
        layerSet({ "n", "x" }, "<left>", mc.prevCursor)
        layerSet({ "n", "x" }, "<right>", mc.nextCursor)

        -- Delete the main cursor.
        layerSet({ "n", "x" }, "<leader>x", mc.deleteCursor)

        -- Enable and clear cursors using escape.
        layerSet("n", "<esc>", function()
          if not mc.cursorsEnabled() then
            mc.enableCursors()
          else
            mc.clearCursors()
          end
        end)
      end)

      -- Customize how cursors look.
      local hl = vim.api.nvim_set_hl
      hl(0, "MultiCursorCursor", { reverse = true })
      hl(0, "MultiCursorVisual", { link = "Visual" })
      hl(0, "MultiCursorSign", { link = "SignColumn" })
      hl(0, "MultiCursorMatchPreview", { link = "Search" })
      hl(0, "MultiCursorDisabledCursor", { reverse = true })
      hl(0, "MultiCursorDisabledVisual", { link = "Visual" })
      hl(0, "MultiCursorDisabledSign", { link = "SignColumn" })
    end,
  },

  -- VScode-like breadcrumbs
  {
    "Bekaboo/dropbar.nvim",
    lazy = false,
    config = function()
      local dropbar_api = require "dropbar.api"
      vim.keymap.set("n", "<Leader>;", dropbar_api.pick, { desc = "Pick symbols in winbar" })
      -- vim.keymap.set("n", "[;", dropbar_api.goto_context_start, { desc = "Go to start of current context" })
      vim.keymap.set("n", "<C-S-.>", dropbar_api.select_next_context, { desc = "Select next context" })
    end,
    opts = {
      bar = { hover = false },
    },
  },

  -- lazy loads lua projects to LUA_LSP as they are required
  {
    "folke/lazydev.nvim",
    ft = "lua", -- only load on lua files
    opts = {
      library = {
        -- See the configuration section for more details
        -- Load luvit types when the `vim.uv` word is found
        { path = "${3rd}/luv/library", words = { "vim%.uv" } },
      },
    },
  },

  {
    "rmagatti/auto-session",
    lazy = false,
    ---@module "auto-session"
    ---@type AutoSession.Config
    opts = {
      suppressed_dirs = { "~/Downloads", "/" },
      -- log_level = 'debug',
    },
  },

  {
    "leath-dub/snipe.nvim",
    keys = {
      {
        "gb",
        function()
          require("snipe").open_buffer_menu()
        end,
        desc = "Open Snipe buffer menu",
      },
    },
    opts = {},
  },

  {
    "folke/todo-comments.nvim",
    lazy = false,
    dependencies = { "nvim-lua/plenary.nvim" },
    opts = {
      keywords = {
        FIX = {
          icon = " ", -- icon used for the sign, and in search results
          color = "error", -- can be a hex color, or a named color (see below)
          alt = { "FIXME", "BUG", "FIXIT", "ISSUE" }, -- a set of other keywords that all map to this FIX keywords
          -- signs = false, -- configure signs for some keywords individually
        },
        TODO = { icon = " ", color = "info" },
        HACK = { icon = " ", color = "warning" },
        WARN = { icon = " ", color = "warning", alt = { "WARNING", "XXX" } },
        PERF = { icon = " ", alt = { "OPTIM", "PERFORMANCE", "OPTIMIZE" } },
        NOTE = { icon = " ", color = "hint", alt = { "INFO" } },
        -- TEST = { icon = "⏲ ", color = "test", alt = { "TESTING", "PASSED", "FAILED" } },
      },
      merge_keywords = false,
      highlight = {
        multiline = true,
        pattern = [[.*<(KEYWORDS)\s*]],
        keyword = "fg",
        after = "fg",
      },
      colors = {
        error = { "DiagnosticError", "ErrorMsg", "#DC2626" },
        warning = { "DiagnosticWarn", "WarningMsg", "#FBBF24" },
        info = { "DiagnosticInfo", "#2563EB" },
        hint = { "#f28d11", "DiagnosticHint", "#10B981" },
        default = { "Identifier", "#7C3AED" },
        -- test = { "Identifier", "#FF00FF" },
      },
      search = {
        pattern = [[\b(KEYWORDS)\b]], -- match without the extra colon. You'll likely get false positives
      },
    },
  },

  {
    "folke/trouble.nvim",
    -- optional = true,
    -- specs = {
    --   "folke/snacks.nvim",
    --   opts = function(_, opts)
    --     return vim.tbl_deep_extend("force", opts or {}, {
    --       picker = {
    --         actions = require("trouble.sources.snacks").actions,
    --         win = {
    --           input = {
    --             keys = {
    --               ["<c-t>"] = {
    --                 "trouble_open",
    --                 mode = { "n", "i" },
    --               },
    --             },
    --           },
    --         },
    --       },
    --     })
    --   end,
    -- },
    --
    opts = {},
    cmd = "Trouble",
    keys = {
      {
        "<leader>tx",
        "<cmd>Trouble diagnostics toggle<cr>",
        desc = "Diagnostics (Trouble)",
      },
      {
        "<leader>tX",
        "<cmd>Trouble diagnostics toggle filter.buf=0<cr>",
        desc = "Buffer Diagnostics (Trouble)",
      },
      {
        "<leader>cs",
        "<cmd>Trouble symbols toggle focus=false<cr>",
        desc = "Symbols (Trouble)",
      },
      {
        "<leader>cl",
        "<cmd>Trouble lsp toggle focus=false win.position=right<cr>",
        desc = "LSP Definitions / references / ... (Trouble)",
      },
      {
        "<leader>tL",
        "<cmd>Trouble loclist toggle<cr>",
        desc = "Location List (Trouble)",
      },
      {
        "<leader>tQ",
        "<cmd>Trouble qflist toggle<cr>",
        desc = "Quickfix List (Trouble)",
      },
      {
        "<leader>tD",
        "<cmd>Trouble todo filter = {tag = {TODO,FIX,FIXME}}<cr>",
        desc = "TODO List (Trouble)",
      },
      {
        "<leader>j",
        function()
          ---@diagnostic disable-next-line: missing-parameter, missing-fields
          require("trouble").next { skip_groups = true, jump = true }
        end,
        desc = "Jump to next location",
      },
      {
        "<leader>k",
        function()
          ---@diagnostic disable-next-line: missing-parameter, missing-fields
          require("trouble").prev { skip_groups = true, jump = true }
        end,
        desc = "Jump to previous location",
      },
    },
  },

  {
    "rachartier/tiny-inline-diagnostic.nvim",
    event = "VeryLazy",
    priority = 1000,
    config = function()
      require("tiny-inline-diagnostic").setup()
      vim.diagnostic.config { virtual_text = false } -- Disable Neovim's default virtual text diagnostics
    end,
  },

  {
    "Goose97/timber.nvim",
    version = "*", -- Use for stability; omit to use `main` branch for the latest features
    event = "VeryLazy",
    config = function()
      require("timber").setup {
        -- Configuration here, or leave empty to use defaults
      }
    end,
  },

  {
    "unblevable/quick-scope",
    lazy = false,
    init = function()
      vim.g.qs_highlight_on_keys = { "f", "F", "t", "T" }
    end,
  },

  -- {
  --   "MagicDuck/grug-far.nvim",
  --   -- Note (lazy loading): grug-far.lua defers all it's requires so it's lazy by default
  --   -- additional lazy config to defer loading is not really needed...
  --   init = function()
  --     -- optional setup call to override plugin options
  --     -- alternatively you can set options with vim.g.grug_far = { ... }
  --     require("grug-far").setup {
  --       -- options, see Configuration section below
  --       -- there are no required options atm
  --     }
  --   end,
  -- },

  -- {
  --   "stevearc/oil.nvim",
  --   opts = {},
  --   -- Optional dependencies
  --   -- dependencies = { { "echasnovski/mini.icons", opts = {} } },
  --   dependencies = { "nvim-tree/nvim-web-devicons" }, -- use if you prefer nvim-web-devicons
  --   -- Lazy loading is not recommended because it is very tricky to make it work correctly in all situations.
  --   lazy = false,
  --   init = function()
  --     require("oil").setup()
  --   end,
  -- },

  {
    "nvim-mini/mini.nvim",
    version = "*",
    init = function()
      require("mini.cursorword").setup()
    end,
  },

  {
    "folke/snacks.nvim",
    priority = 1000,
    lazy = false,
    opts = {
      -- your configuration comes here
      -- or leave it empty to use the default settings
      -- refer to the configuration section below
      -- bigfile = { enabled = true },
      -- dashboard = { enabled = true },
      explorer = { enabled = true },
      indent = { enabled = true, animate = { enabled = false } },
      input = { enabled = true },
      picker = {
        enabled = true,
        win = {
          input = {
            keys = {
              ["<Up>"] = { "history_back", mode = { "i", "n" } },
              ["<Down>"] = { "history_forward", mode = { "i", "n" } },
            },
          },
        },
        formatters = {
          file = {
            filename_first = true, -- display filename before the file path
            --- * left: truncate the beginning of the path
            --- * center: truncate the middle of the path
            --- * right: truncate the end of the path
            ---@type "left"|"center"|"right"
            truncate = "center",
            min_width = 100, -- minimum length of the truncated path
            filename_only = false, -- only show the filename
            icon_width = 2, -- width of the icon (in characters)
            git_status_hl = true, -- use the git status highlight group for the filename
          },
        },
        previewers = {
          diff = {
            -- fancy: Snacks fancy diff (borders, multi-column line numbers, syntax highlighting)
            -- syntax: Neovim's built-in diff syntax highlighting
            -- terminal: external command (git's pager for git commands, `cmd` for other diffs)
            style = "fancy", ---@type "fancy"|"syntax"|"terminal"
            cmd = { "delta" }, -- example for using `delta` as the external diff command
            ---@type vim.wo?|{} window options for the fancy diff preview window
            wo = {
              breakindent = true,
              wrap = true,
              linebreak = true,
              showbreak = "",
            },
          },
          git = {
            args = {}, -- additional arguments passed to the git command. Useful to set pager options usin `-c ...`
          },
          file = {
            max_size = 1024 * 1024, -- 1MB
            max_line_length = 500, -- max line length
            ft = nil, ---@type string? filetype for highlighting. Use `nil` for auto detect
          },
          man_pager = nil, ---@type string? MANPAGER env to use for `man` preview
        },
      },
      notifier = { enabled = true },
      quickfile = { enabled = true },
      scope = { enabled = true },
      -- scroll = { enabled = true },
      statuscolumn = { enabled = true },
      words = { enabled = true },
    },
  },

  -- {
  --   "folke/noice.nvim",
  --   event = "VeryLazy",
  --   opts = {
  --     -- add any options here
  --   },
  --   dependencies = {
  --     -- if you lazy-load any plugin below, make sure to add proper `module="..."` entries
  --     "MunifTanjim/nui.nvim",
  --     -- OPTIONAL:
  --     --   `nvim-notify` is only needed, if you want to use the notification view.
  --     --   If not available, we use `mini` as the fallback
  --     "rcarriga/nvim-notify",
  --   },
  -- },

  -- {
  --   "ThePrimeagen/harpoon",
  --   branch = "harpoon2",
  --   dependencies = { "nvim-lua/plenary.nvim" },
  --   init = function()
  --     local harpoon = require "harpoon"
  --     harpoon:setup()
  --     local conf = require("telescope.config").values
  --     -- add to the list
  --     vim.keymap.set("n", "<leader>a", function()
  --       harpoon:list():add()
  --     end, { desc = "add file to harpoon" })
  --
  --     vim.keymap.set("n", "=", function()
  --       harpoon.ui:toggle_quick_menu(harpoon:list())
  --     end)
  --     -- toggle harpoon menu
  --     vim.keymap.set("n", "-", function()
  --       local make_finder = function()
  --         local paths = {}
  --         for _, item in ipairs(harpoon:list()) do
  --           table.insert(paths, item.value)
  --         end
  --         return require("telescope.finders").new_table {
  --           results = paths,
  --         }
  --       end
  --
  --       require("telescope.pickers")
  --         .new({}, {
  --           prompt_title = "Harpoon",
  --           finder = make_finder(),
  --           previewer = conf.file_previewer {},
  --           sorter = conf.generic_sorter {},
  --           attach_mappings = function(prompt_buffer_number, map)
  --             -- delete entries from the telescope list
  --             map("i", "<C-d>", function()
  --               local state = require "telescope.actions.state"
  --               local selected_entry = state.get_selected_entry()
  --               local current_picker = state.get_current_picker(prompt_buffer_number)
  --               harpoon:list():remove(selected_entry)
  --               current_picker:refresh(make_finder())
  --             end)
  --
  --             return true
  --           end,
  --         })
  --         :find()
  --     end, { noremap = true, desc = "Open harpoon window" })
  --   end,
  -- },

  {
    "dmtrKovalenko/fff.nvim",
    build = "cargo build --release",
    lazy = false,
    opts = {
      layout = {
        prompt_position = "top",
      },
      frecency = {
        enabled = true,
      },
    },
    keys = {
      {
        "<C-->",
        function()
          require("fff").find_files() -- or find_in_git_root() if you only want git files
        end,
        desc = "Open file picker",
      },
      {
        "-",
        function()
          require("fff").find_in_git_root()
        end,
        desc = "Open file picker",
      },
    },
  },

  ------------------------------------------------------------------
  --- MARKDOWN
  ------------------------------------------------------------------

  -- {
  --   "MeanderingProgrammer/render-markdown.nvim",
  --   lazy = false,
  --   dependencies = { "nvim-treesitter/nvim-treesitter", "echasnovski/mini.nvim" }, -- if you use the mini.nvim suite
  --   -- dependencies = { 'nvim-treesitter/nvim-treesitter', 'echasnovski/mini.icons' }, -- if you use standalone mini plugins
  --   -- dependencies = { "nvim-treesitter/nvim-treesitter", "nvim-tree/nvim-web-devicons" }, -- if you prefer nvim-web-devicons
  --   ---@module 'render-markdown'
  --   ---@type render.md.UserConfig
  --   opts = {},
  -- },

  ------------------------------------------------------------------
  --- RUST
  ------------------------------------------------------------------
  {
    -- NOTE: must use rust-analyzer from rustup `rustup component add rust-analyzer`
    "mrcjkb/rustaceanvim",
    version = "^6",
    lazy = false,
    dependencies = {
      "mason-org/mason.nvim",
    },
    init = function()
      vim.g.rustaceanvim = {
        -- Disable if you have issues
        tools = {
          hover_actions = {
            auto_focus = false,
          },
          enable_nextest = false,
          -- test_executor = "background"
          -- test_executor = function(cmd:string, args:string[], cwd:string|nil, opts?: rustaceanvim.ExecutorOpts)
          --   -- Add custom parameters like --show-output
          --   local custom_args = vim.list_extend({}, args)
          --   table.insert(custom_args, "--show-output")
          --
          --   -- Set up custom environment variables
          --   local env = vim.tbl_extend("force", vim.fn.environ(), {
          --     RUST_LOG = "debug",
          --     RUST_BACKTRACE = "1",
          --   })
          --
          --   -- Execute the command with custom args and env
          --   vim.fn.jobstart({cmd, unpack(custom_args)}, {
          --     cwd = cwd,
          --     env = env,
          --     on_stdout = function(_, data, _)
          --       if data then
          --         for _, line in ipairs(data) do
          --           if line ~= "" then
          --             print(line)
          --           end
          --         end
          --       end
          --     end,
          --     on_stderr = function(_, data, _)
          --       if data then
          --         for _, line in ipairs(data) do
          --           if line ~= "" then
          --             vim.notify(line, vim.log.levels.ERROR)
          --           end
          --         end
          --       end
          --     end,
          --   })
          -- end
        },
        server = {
          -- on_attach = function(client, bufnr) end,
          default_settings = {
            ["rust-analyzer"] = {
              cargo = {
                allFeatures = true,
                buildScripts = {
                  enable = true,
                },
              },
              checkOnSave = true,
              check = {
                command = "clippy",
              },
              procMacro = {
                enable = true,
              },
            },
          },
        },
      }
    end,
  },

  {
    "nvim-neotest/neotest",
    dependencies = {
      "nvim-neotest/nvim-nio",
      "nvim-lua/plenary.nvim",
      "antoinemadec/FixCursorHold.nvim",
      "nvim-treesitter/nvim-treesitter",
    },
    config = function()
      ---@diagnostic disable-next-line: missing-fields
      require("neotest").setup {
        adapters = {
          require "rustaceanvim.neotest",
        },
      }
    end,
  },

  {
    "mfussenegger/nvim-dap",
    config = function()
      local dap, dapui = require "dap", require "dapui"
      dap.listeners.before.attach.dapui_config = function()
        dapui.open()
      end
      dap.listeners.before.launch.dapui_config = function()
        dapui.open()
      end
      dap.listeners.before.event_terminated.dapui_config = function()
        dapui.close()
      end
      dap.listeners.before.event_exited.dapui_config = function()
        dapui.close()
      end
      dap.adapters.codelldb = {
        type = "executable",
        command = "codelldb",
      }
    end,
  },

  {
    "rcarriga/nvim-dap-ui",
    dependencies = { "mfussenegger/nvim-dap", "nvim-neotest/nvim-nio" },
    config = function()
      require("dapui").setup()
    end,
  },

  {
    "saecki/crates.nvim",
    tag = "stable",
    event = { "BufRead Cargo.toml" },
    config = function()
      require("crates").setup {
        completion = {
          cmp = {
            enabled = true,
          },
        },
      }
    end,
  },

  ------------------------------------------------------------------
  --- TYPESCRIPT
  ------------------------------------------------------------------
  { "dmmulroy/ts-error-translator.nvim" },

  ------------------------------------------------------------------
  --- AI
  ------------------------------------------------------------------

  -- {
  --   "coder/claudecode.nvim",
  --   dependencies = { "folke/snacks.nvim" },
  --   config = true,
  --   opts = {
  --     terminal = {
  --       provider = "snacks",
  --     },
  --   },
  --   keys = {
  --     { "<leader>a", nil, desc = "AI/Claude Code" },
  --     { "<leader>ac", "<cmd>ClaudeCode<cr>", desc = "Toggle Claude" },
  --     { "<leader>af", "<cmd>ClaudeCodeFocus<cr>", desc = "Focus Claude" },
  --     { "<leader>ar", "<cmd>ClaudeCode --resume<cr>", desc = "Resume Claude" },
  --     { "<leader>aC", "<cmd>ClaudeCode --continue<cr>", desc = "Continue Claude" },
  --     { "<leader>am", "<cmd>ClaudeCodeSelectModel<cr>", desc = "Select Claude model" },
  --     { "<leader>ab", "<cmd>ClaudeCodeAdd %<cr>", desc = "Add current buffer" },
  --     { "<leader>as", "<cmd>ClaudeCodeSend<cr>", mode = "v", desc = "Send to Claude" },
  --     {
  --       "<leader>as",
  --       "<cmd>ClaudeCodeTreeAdd<cr>",
  --       desc = "Add file",
  --       ft = { "NvimTree", "neo-tree", "oil", "minifiles" },
  --     },
  --     -- Diff management
  --     { "<leader>aa", "<cmd>ClaudeCodeDiffAccept<cr>", desc = "Accept diff" },
  --     { "<leader>ad", "<cmd>ClaudeCodeDiffDeny<cr>", desc = "Deny diff" },
  --   },
  -- },
  --

  {
    "folke/sidekick.nvim",
    lazy = false,
    opts = {
      -- add any options here
      cli = {
        mux = {
          backend = "zellij",
          enabled = true,
        },
      },
    },
    keys = {
      {
        "<tab>",
        function()
          -- if there is a next edit, jump to it, otherwise apply it if any
          if not require("sidekick").nes_jump_or_apply() then
            return "<Tab>" -- fallback to normal tab
          end
        end,
        expr = true,
        desc = "Goto/Apply Next Edit Suggestion",
      },
      {
        "<c-a>",
        function()
          require("sidekick.cli").toggle()
        end,
        desc = "Sidekick Toggle",
        mode = { "n", "t", "i", "x" },
      },
      {
        "<leader>aa",
        function()
          require("sidekick.cli").toggle()
        end,
        desc = "Sidekick Toggle CLI",
      },
      {
        "<leader>as",
        function()
          require("sidekick.cli").select()
        end,
        -- Or to select only installed tools:
        -- require("sidekick.cli").select({ filter = { installed = true } })
        desc = "Select CLI",
      },
      {
        "<leader>ad",
        function()
          require("sidekick.cli").close()
        end,
        desc = "Detach a CLI Session",
      },
      {
        "<leader>at",
        function()
          require("sidekick.cli").send { msg = "{this}" }
        end,
        mode = { "x", "n" },
        desc = "Send This",
      },
      {
        "<leader>af",
        function()
          require("sidekick.cli").send { msg = "{file}" }
        end,
        desc = "Send File",
      },
      {
        "<leader>av",
        function()
          require("sidekick.cli").send { msg = "{selection}" }
        end,
        mode = { "x" },
        desc = "Send Visual Selection",
      },
      {
        "<leader>ap",
        function()
          require("sidekick.cli").prompt()
        end,
        mode = { "n", "x" },
        desc = "Sidekick Select Prompt",
      },
      -- Example of a keybinding to open Claude directly
      -- {
      --   "<leader>ac",
      --   function() require("sidekick.cli").toggle({ name = "claude", focus = true }) end,
      --   desc = "Sidekick Toggle Claude",
      -- },
    },
  },
}
