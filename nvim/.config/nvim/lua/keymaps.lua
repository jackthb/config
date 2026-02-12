vim.g.mapleader = " "
vim.g.maplocalleader = " "

local keymap = vim.keymap.set

keymap("n", "<Esc>", "<cmd>nohlsearch<CR>")

keymap("n", "<C-h>", "<C-w>h")
keymap("n", "<C-j>", "<C-w>j")
keymap("n", "<C-k>", "<C-w>k")
keymap("n", "<C-l>", "<C-w>l")

keymap("v", "J", ":m '>+1<CR>gv=gv")
keymap("v", "K", ":m '<-2<CR>gv=gv")

keymap("n", "J", "mzJ`z")

keymap("n", "<C-d>", "<C-d>zz")
keymap("n", "<C-u>", "<C-u>zz")
keymap("n", "n", "nzzzv")
keymap("n", "N", "Nzzzv")

keymap("x", "<leader>p", '"_dP')

keymap({ "n", "v" }, "<leader>y", '"+y')
keymap("n", "<leader>Y", '"+Y')

keymap({ "n", "v" }, "<leader>d", '"_d')

keymap("n", "<leader>w", "<cmd>w<CR>")
keymap("n", "<leader>q", "<cmd>q<CR>")

keymap("n", "<leader>e", vim.cmd.Ex)
