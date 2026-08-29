-- All Neovim configuration lives in this file.
vim.g.mapleader = " "
vim.g.maplocalleader = " "

vim.opt.number = true
vim.opt.relativenumber = true
vim.opt.tabstop = 4
vim.opt.shiftwidth = 4
vim.opt.expandtab = true
vim.opt.mouse = "a"

local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not vim.uv.fs_stat(lazypath) then
  vim.api.nvim_echo({ { "lazy.nvim is missing; clone it into " .. lazypath, "ErrorMsg" } }, true, {})
  return
end
vim.opt.rtp:prepend(lazypath)

require("lazy").setup({
  {
    "catppuccin/nvim",
    name = "catppuccin",
    priority = 1000,
    lazy = false,
    config = function()
      vim.cmd.colorscheme("catppuccin-mocha")
    end,
  },
  { "ellisonleao/gruvbox.nvim", priority = 1000 },

  {
    "nvim-treesitter/nvim-treesitter",
    lazy = false,
    build = ":TSUpdate",
    opts = {},
  },
  {
    "folke/snacks.nvim",
    priority = 1000,
    lazy = false,
    opts = {
      explorer = { enabled = true, replace_netrw = true },
      picker = { enabled = true },
    },
    keys = {
      { "<leader>e", function() Snacks.picker.explorer() end, desc = "Explorer" },
    },
  },
  {
    "nvim-telescope/telescope.nvim",
    branch = "0.1.x",
    dependencies = { "nvim-lua/plenary.nvim" },
    keys = {
      { "<leader>ff", function() require("telescope.builtin").find_files() end, desc = "Find files" },
      { "<leader>fg", function() require("telescope.builtin").live_grep() end, desc = "Find text" },
      { "<leader>fb", function() require("telescope.builtin").buffers() end, desc = "Buffers" },
      { "<leader>fh", function() require("telescope.builtin").help_tags() end, desc = "Help tags" },
    },
  },
  { "lewis6991/gitsigns.nvim", opts = {} },
  { "nvim-lualine/lualine.nvim", opts = { options = { theme = "auto" } } },
  { "folke/which-key.nvim", opts = {} },
  {
    "stevearc/conform.nvim",
    opts = {
      format_on_save = { timeout_ms = 500, lsp_format = "fallback" },
    },
  },
}, {
  checker = { enabled = true },
  change_detection = { notify = false },
})
