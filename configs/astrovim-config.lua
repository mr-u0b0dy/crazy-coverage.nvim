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
        -- Hit count display options
        hit_count = {
          display = "eol",               -- Display mode: 'eol', 'inline', 'overlay', 'right_align', or 'sign'
          show_by_default = true,        -- Show hit counts by default when overlay is enabled
        },
        
        -- Other display options
      })
    end,
    keys = {
      -- Coverage overlay toggle (auto-loads and watches for file changes)
      { "<Leader>lt", "<cmd>CoverageToggle<cr>", desc = "Coverage: Toggle overlay" },
      
      -- Hit count display toggle (enable/disable)
      { "<Leader>lh", "<cmd>CoverageToggleHitCount<cr>", desc = "Coverage: Toggle hit count display" },

      -- Neo-tree coverage toggle
      { "<Leader>lT", "<cmd>CoverageToggleNeoTree<cr>", desc = "Coverage: Toggle Neo-tree coverage" },

      -- Branch overlay toggle (floating window above code)
      { "<Leader>lb", "<cmd>CoverageToggleBranchOverlay<cr>", desc = "Coverage: Toggle branch overlay" },

      -- Coverage summary popup
      { "<Leader>lm", "<cmd>CoverageSummary<cr>", desc = "Coverage: Summary" },

      -- Navigation: coverage lines
      { "]cc", "<cmd>CoverageNextCovered<cr>", desc = "Coverage: Next covered line" },
      { "[cc", "<cmd>CoveragePrevCovered<cr>", desc = "Coverage: Prev covered line" },
      
      { "]cp", "<cmd>CoverageNextPartial<cr>", desc = "Coverage: Next partial line" },
      { "[cp", "<cmd>CoveragePrevPartial<cr>", desc = "Coverage: Prev partial line" },
      
      { "]cu", "<cmd>CoverageNextUncovered<cr>", desc = "Coverage: Next uncovered line" },
      { "[cu", "<cmd>CoveragePrevUncovered<cr>", desc = "Coverage: Prev uncovered line" },
    },
  },
}
