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
        virt_text_pos = "eol",           -- "eol", "inline", "overlay", "right_align"
        default_show_hit_count = true,   -- Show hit counts by default when overlay is enabled
        show_hit_count = true,           -- Current hit count display state
        show_branch_summary = false,     -- Show branch coverage as b:taken/total
        enable_line_hl = true,           -- Enable line highlighting
      })
    end,
    keys = {
      -- Coverage overlay toggle (auto-loads and watches for file changes)
      { "<Leader>lt", "<cmd>CoverageToggle<cr>", desc = "Toggle coverage overlay" },
      
      -- Toggle hit count display
      { "<Leader>lh", "<cmd>CoverageToggleHitCount<cr>", desc = "Toggle hit count display" },

      -- Navigation: {/} then c, then c/p/u for prev/next covered/partial/uncovered
      { "}cc", "<cmd>CoverageNextCovered<cr>", desc = "Next covered line" },
      { "{cc", "<cmd>CoveragePrevCovered<cr>", desc = "Prev covered line" },
      
      { "}cp", "<cmd>CoverageNextPartial<cr>", desc = "Next partial line" },
      { "{cp", "<cmd>CoveragePrevPartial<cr>", desc = "Prev partial line" },
      
      { "}cu", "<cmd>CoverageNextUncovered<cr>", desc = "Next uncovered line" },
      { "{cu", "<cmd>CoveragePrevUncovered<cr>", desc = "Prev uncovered line" },
    },
  },
}
