vim.g.mapleader = " "

local keymap = vim.keymap 

keymap.set("n", "<leader>+", "<C-a>", { desc = "Increment number" })
keymap.set("n", "<leader>-", "<C-x>", { desc = "Decrement number" })

keymap.set("n", "<leader>to", "<cmd>tabnew<CR>", { desc = "Open new teb" })
keymap.set("n", "<leader>tx", "<cmd>tabclse<CR>", { desc = "Close current tab" })
keymap.set("n", "<leader>tn", "<cmd>tabn<CR>", { desc = "Go to next tab" })
keymap.set("n", "<leader>tp", "<cmd>tabp<CR>", { desc = "Go to previous tab" })
keymap.set("n", "<leader>tf", "<cmd>tabnew %<CR>", { desc = "Open current buffer in new tab" })

keymap.set("n", "<leader><leader>", "<cmd>Explore<CR>", { desc = "Open Explorer" })
