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
      })
    end,
    keys = {
      -- Coverage management (<leader>c prefix)
      { "<Leader>cl", "<cmd>CoverageLoad<cr>", desc = "Load coverage file" },
      { "<Leader>ct", "<cmd>CoverageToggle<cr>", desc = "Toggle coverage overlay" },
      { "<Leader>cc", "<cmd>CoverageClear<cr>", desc = "Clear coverage data" },
      { "<Leader>ca", "<cmd>CoverageAutoLoad<cr>", desc = "Auto-load coverage" },
      
      -- Display toggles (<leader>c prefix)
      { "<Leader>ch", "<cmd>CoverageToggleHitCount<cr>", desc = "Toggle hit count display" },
      { "<Leader>cd", "<cmd>CoverageToggleLineDisplay<cr>", desc = "Toggle line highlighting" },

      -- Navigation: {/} then c/p/u for prev/next covered/partial/uncovered
      { "}c", "<cmd>CoverageNextCovered<cr>", desc = "Next covered line" },
      { "{c", "<cmd>CoveragePrevCovered<cr>", desc = "Prev covered line" },
      
      { "}p", "<cmd>CoverageNextPartial<cr>", desc = "Next partial line" },
      { "{p", "<cmd>CoveragePrevPartial<cr>", desc = "Prev partial line" },
      
      { "}u", "<cmd>CoverageNextUncovered<cr>", desc = "Next uncovered line" },
      { "{u", "<cmd>CoveragePrevUncovered<cr>", desc = "Prev uncovered line" },
    },
  },
}
