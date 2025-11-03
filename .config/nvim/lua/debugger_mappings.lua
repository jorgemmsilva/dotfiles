-- Debug keymappings using <leader>d prefix
local map = vim.keymap.set

-- Toggle breakpoint
map("n", "<leader>db", function()
  require("dap").toggle_breakpoint()
end, { desc = "Debug: Toggle breakpoint" })

-- Set conditional breakpoint
map("n", "<leader>dB", function()
  require("dap").set_breakpoint(vim.fn.input "Breakpoint condition: ")
end, { desc = "Debug: Set conditional breakpoint" })

-- Set log point
map("n", "<leader>dl", function()
  require("dap").set_breakpoint(nil, nil, vim.fn.input "Log point message: ")
end, { desc = "Debug: Set log point" })

-- Start/Continue debugging
map("n", "<leader>dc", function()
  require("dap").continue()
end, { desc = "Debug: Start/Continue" })

-- Run last configuration
map("n", "<leader>dr", function()
  require("dap").run_last()
end, { desc = "Debug: Run last" })

-- Restart debugging session
map("n", "<leader>dR", function()
  require("dap").restart()
end, { desc = "Debug: Restart" })

-- Step over
map("n", "<leader>do", function()
  require("dap").step_over()
end, { desc = "Debug: Step over" })

-- Step into
map("n", "<leader>di", function()
  require("dap").step_into()
end, { desc = "Debug: Step into" })

-- Step out
map("n", "<leader>dO", function()
  require("dap").step_out()
end, { desc = "Debug: Step out" })

-- Terminate/Stop debugging
map("n", "<leader>dt", function()
  require("dap").terminate()
end, { desc = "Debug: Terminate" })

-- Pause debugging
map("n", "<leader>dp", function()
  require("dap").pause()
end, { desc = "Debug: Pause" })

-- Toggle DAP UI
map("n", "<leader>du", function()
  require("dapui").toggle()
end, { desc = "Debug: Toggle UI" })

-- Open DAP UI
map("n", "<leader>dU", function()
  require("dapui").open()
end, { desc = "Debug: Open UI" })

-- Close DAP UI
map("n", "<leader>dC", function()
  require("dapui").close()
end, { desc = "Debug: Close UI" })

-- Evaluate expression
map("n", "<leader>de", function()
  require("dap").eval()
end, { desc = "Debug: Evaluate expression" })

-- Evaluate expression (prompt)
map("n", "<leader>dE", function()
  require("dap").eval(vim.fn.input "Expression: ")
end, { desc = "Debug: Evaluate expression (prompt)" })

-- Run to cursor
map("n", "<leader>dg", function()
  require("dap").run_to_cursor()
end, { desc = "Debug: Run to cursor" })

-- Go to line (without executing)
map("n", "<leader>dj", function()
  require("dap").goto_()
end, { desc = "Debug: Go to line" })

-- Show hover information
map("n", "<leader>dh", function()
  require("dap.ui.widgets").hover()
end, { desc = "Debug: Hover" })

-- Preview variable
map("n", "<leader>dv", function()
  require("dap.ui.widgets").preview()
end, { desc = "Debug: Preview" })

-- Show frames
map("n", "<leader>df", function()
  local widgets = require "dap.ui.widgets"
  widgets.centered_float(widgets.frames)
end, { desc = "Debug: Frames" })

-- Show scopes
map("n", "<leader>ds", function()
  local widgets = require "dap.ui.widgets"
  widgets.centered_float(widgets.scopes)
end, { desc = "Debug: Scopes" })

-- Clear all breakpoints
map("n", "<leader>dx", function()
  require("dap").clear_breakpoints()
end, { desc = "Debug: Clear all breakpoints" })

-- List breakpoints
map("n", "<leader>dL", function()
  require("dap").list_breakpoints()
end, { desc = "Debug: List breakpoints" })
