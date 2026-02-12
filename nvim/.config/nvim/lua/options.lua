local opt = vim.opt

opt.number = true
opt.relativenumber = true

opt.tabstop = 4
opt.shiftwidth = 4
opt.expandtab = true
opt.autoindent = true
opt.smartindent = true

opt.wrap = false

opt.ignorecase = true
opt.smartcase = true

opt.cursorline = true

opt.termguicolors = true
opt.background = "light"
opt.signcolumn = "yes"

opt.backspace = "indent,eol,start"

opt.clipboard = "unnamedplus"

opt.splitright = true
opt.splitbelow = true

opt.swapfile = false
opt.backup = false
opt.undofile = true

opt.updatetime = 250
opt.timeoutlen = 300

opt.scrolloff = 8
opt.sidescrolloff = 8

opt.hlsearch = true
opt.incsearch = true

opt.mouse = "a"

opt.showmode = false

vim.cmd("colorscheme zellner")
