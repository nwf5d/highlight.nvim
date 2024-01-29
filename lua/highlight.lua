local highlights = {}

vim.cmd([[
    highlight SourceInsight ctermbg=yellow guibg=yellow
]])

local function tabLength(T)
    local count = 0
    for _ in pairs(T) do
        count = count + 1
    end
    return count
end

local function exitCurrentMode()
    local esc = vim.api.nvim_replace_termcodes("<esc>", true, false, true)
    vim.api.nvim_feedkeys(esc, "x", false)
end

local function bufVtext()
    local a_org = vim.fn.getreg("a")
    local mode = vm.fn.mode()
    if mode ~= "v" and mode ~= "V" then
        -- vim.cmd([[normal! gv]])
        vim.cmd([[normal! viw]])
    end
    -- vim.cmd([[silent! normal "aygv]])
    vim.cmd([[silent! normal! "ayw]])
    local text = vim.fn.getreg("a")
    vim.fn.setreg("a", a_org)
    return text
end

-- CopyFrom https://github.com/ibnagwan/fzf-lua
local function getSelectedText()
    -- this will exit visual mode
    -- use 'gv' to reselect the text
    local _, csrow, cscol, cerow, cecol
    local mode = vim.fn.mode()
    if mode == "v" or mode == "V" or mode == "" then
        -- if we are in visual mode use the live position
        _, csrow, cscol, _ = unpack(vim.fn.getpos("."))
        _, cerow, cecol, _ = unpack(vim.fn.getpos("v"))
        if mode == "V" then
            -- visual line doesn't provide columns
            cscol, cecol = 0, 999
        end
        exitCurrentMode()
    else
        --otherwise, use the last known visual position
        _, csrow, cscol, _ = unpack(vim.fn.getpost("'<"))
        _, cerow, cecol, _ = unpack(vim.fn.getpos("'>"))
    end

    -- swap vars if needed
    if cerow < csrow then
        csrow, cerow = cerow, csrow
    end
    if cecol < cscol then
        cscol, cecol = cecol, cscol
    end
    local lines = vim.fn.getline(csrow, cerow)
    local n = tableLength(lines)
    if n <= 0 then
        return ""
    end
    lines[n] = string.sub(lines[n], 1, cecol)
    lines[1] = string.sub(lines[1], cscol)
    return table.concat(lines, "\n")
end

local function highlightShow()
    if next(highlights) == nil then
        vim.api.nvim_command('echo "highlights empty"')
        return
    end

    local lines = {}
    for key, _ in pairs(highlights) do
        table.insert(lines, key)
    end

    local bufnr = vim.api.nvim_create_buf(false, true)
    vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, lines)

    local win_id = vim.api.nvim_open_win(bufnr, true, {
        relative = 'cursor',
        width = 20,
        height = #lines,
        row = 1,
        col = 1,
        style = 'minimal',
        border = 'single'
    })
end

local function doHighlightEnable(text)
    if highlights[text] == nil then
        local hl_id = vim.fn.matchadd("SourceInsight", text)
        highlights[text] = hl_id
    end
end

local function highlightEnable(symbol)
    local text = string.len(symbol.args) > 0 and symbol.args or nil
    if text then
        doHighlightEnable(text)
    end
end

local function doHighlightDismiss(text)
    if highlights[text] ~= nil then
        vim.fn.matchdelete(highlights[text])
        highlights[text] = nil
    end
end

local function highlightDismiss(symbol)
    local text = string.len(symbol.args) > 0 and symbol.args or nil
    if text then
        doHighlightDismiss(text)
    end
end

local function highlightDismissAll()
    for key, _ in pairs(highlights) do
        doHighlightDismiss(key)
    end
end

local function highlightToggle()
    local text = nil
    local mode = vim.fn.mode()

    if mode == "v" or mode == "V" then
        text = getSelectedText()
    else
        text = bufVtext()
    end

    if highlights[text] == nil then
        doHighlightEnable(text)
    else
        doHighlightDismiss(text)
    end
end

local wk = require("which-key")
wk.register({
    ["<leader>h"] = {
        mode = { "n", "v" },
        name = "+highlight",
        t = { function() highlightToggle() end, "toggle highlight" },
        s = { function() highlightShow() end, "show all highlight" },
        d = { function() highlightDismissAll() end, "dismiss all highlight" },
    },
})

vim.api.nvim_create_user_command("HlToggle", function() highlightToggle() end, {})
vim.api.nvim_create_user_command("HlShow", function() highlightShow() end, {})
vim.api.nvim_create_user_command("HlEnable", function() highlightEnable() end, {})
vim.api.nvim_create_user_command("HlDismiss", function() highlightDismiss() end, {})
vim.api.nvim_create_user_command("HlDismissAll", function() highlightDismissAll() end, {})

