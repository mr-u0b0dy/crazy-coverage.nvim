-- AstroVim Configuration for crazy-coverage.nvim
-- Place this file in ~/.config/nvim/lua/plugins/crazy-coverage.lua

---@type LazySpec
return {
  {
    "mr-u0b0dy/crazy-coverage.nvim",
    -- For local development, use:
    -- dev = true,
    -- dir = "/path/to/crazy-coverage.nvim",
    lazy = false, -- Load on startup
    config = function()
      require("crazy-coverage").setup({
        virt_text_pos = "eol",        -- "eol", "inline", "overlay", "right_align"
        show_hit_count = true,         -- Show hit counts inline
        show_branch_summary = false,   -- Show branch coverage as b:taken/total
        auto_load = true,              -- Auto-load coverage on file open
        enable_line_hl = false,        -- Enable line highlighting (optional)
      })
    end,
    keys = {
      -- Coverage loading and management (<leader>l prefix)
      { "<Leader>ll", "<cmd>CoverageLoad<cr>", desc = "Load coverage file" },
      { "<Leader>lt", "<cmd>CoverageToggle<cr>", desc = "Toggle coverage overlay" },
      { "<Leader>le", "<cmd>CoverageEnable<cr>", desc = "Enable coverage overlay" },
      { "<Leader>ld", "<cmd>CoverageDisable<cr>", desc = "Disable coverage overlay" },
      { "<Leader>lc", "<cmd>CoverageClear<cr>", desc = "Clear coverage data" },
      { "<Leader>la", "<cmd>CoverageAutoLoad<cr>", desc = "Auto-load coverage" },

      -- Navigation shortcuts for covered lines
      { "}c", "<cmd>CoverageNextCovered<cr>", desc = "Next covered line" },
      { "{c", "<cmd>CoveragePrevCovered<cr>", desc = "Previous covered line" },

      -- Navigation shortcuts for partially covered lines
      { "}p", "<cmd>CoverageNextPartial<cr>", desc = "Next partially covered line" },
      { "{p", "<cmd>CoveragePrevPartial<cr>", desc = "Previous partially covered line" },

      -- Navigation shortcuts for uncovered lines
      { "}u", "<cmd>CoverageNextUncovered<cr>", desc = "Next uncovered line" },
      { "{u", "<cmd>CoveragePrevUncovered<cr>", desc = "Previous uncovered line" },
    },
  },
}
