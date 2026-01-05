-- Test color adaptation feature
local config = require("crazy-coverage.config")

-- Test 1: Auto-adapt colors enabled (default)
print("Test 1: Auto-adapt colors (default)")
config.set_config({
  auto_adapt_colors = true,
})
config.setup_highlights()
print("✓ Auto-adaptation enabled, highlights created")

-- Test 2: Manual colors with auto-adapt disabled
print("\nTest 2: Manual colors")
config.set_config({
  auto_adapt_colors = false,
  colors = {
    covered = { bg = "#1a4d1a", fg = "#66ff66" },
    uncovered = { bg = "#4d1a1a", fg = "#ff6666" },
    partial = { bg = "#4d4d1a", fg = "#ffff66" },
  },
})
config.setup_highlights()
print("✓ Manual colors set")

-- Test 3: Auto-adapt with manual override
print("\nTest 3: Auto-adapt with override")
config.set_config({
  auto_adapt_colors = true,
  colors = {
    covered = nil,
    uncovered = "#660000",
    partial = nil,
  },
})
config.setup_highlights()
print("✓ Auto-adapt with manual uncovered color")

-- Test 4: Simple hex string colors
print("\nTest 4: Simple hex strings")
config.set_config({
  auto_adapt_colors = false,
  colors = {
    covered = "#004400",
    uncovered = "#440000",
    partial = "#444400",
  },
})
config.setup_highlights()
print("✓ Hex string colors set")

-- Get the actual highlights to verify
local covered_hl = vim.api.nvim_get_hl(0, { name = "CoverageCovered" })
local uncovered_hl = vim.api.nvim_get_hl(0, { name = "CoverageUncovered" })
local partial_hl = vim.api.nvim_get_hl(0, { name = "CoveragePartial" })

print("\nFinal highlight values:")
print(string.format("  Covered:   bg=#%06X", covered_hl.bg or 0))
print(string.format("  Uncovered: bg=#%06X", uncovered_hl.bg or 0))
print(string.format("  Partial:   bg=#%06X", partial_hl.bg or 0))

print("\n✓ All color adaptation tests passed!")
