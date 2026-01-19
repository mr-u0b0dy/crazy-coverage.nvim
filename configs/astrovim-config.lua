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
          display = "sign",               -- Display mode: 'eol', 'inline', 'overlay', 'right_align', or 'sign'
          show_by_default = true,        -- Show hit counts by default when overlay is enabled
        },
        
        -- Other display options
      })
    end,
    keys = {
      -- Coverage overlay toggle (auto-loads and watches for file changes)
      { "<Leader>lt", "<cmd>CoverageToggle<cr>", desc = "Toggle coverage overlay" },
      
      -- Hit count display toggle (enable/disable)
      { "<Leader>lh", "<cmd>CoverageToggleHitCount<cr>", desc = "Toggle hit count display (enable/disable)" },

      -- Branch overlay toggle (floating window above code)
      { "<Leader>lb", "<cmd>CoverageToggleBranchOverlay<cr>", desc = "Toggle branch coverage soverlay" },

      -- Navigation: coverage lines
      { "]cc", "<cmd>CoverageNextCovered<cr>", desc = "Next covered line" },
      { "[cc", "<cmd>CoveragePrevCovered<cr>", desc = "Prev covered line" },
      
      { "]cp", "<cmd>CoverageNextPartial<cr>", desc = "Next partial line" },
      { "[cp", "<cmd>CoveragePrevPartial<cr>", desc = "Prev partial line" },
      
      { "]cu", "<cmd>CoverageNextUncovered<cr>", desc = "Next uncovered line" },
      { "[cu", "<cmd>CoveragePrevUncovered<cr>", desc = "Prev uncovered line" },
    },
  },
}
