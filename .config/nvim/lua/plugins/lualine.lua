-- statusline by post: https://www.reddit.com/r/neovim/comments/1ahk9qo/lualine_showing_file_permissions_and_green_color/

return {
  {
    "nvim-lualine/lualine.nvim",
    event = "VeryLazy",

    --  lualine showing file permissions and green color if owner has rwx
    opts = function(_, opts)
      local fg_color = "#36454F" -- Foreground color for the text

      -- Function to determine file permissions and appropriate background color
      local function get_permissions_color()
        local file = vim.fn.expand("%:p")
        if file == "" or file == nil then
          return "No File", "#0099ff" -- Default blue for no or non-existing file
        else
          local permissions = vim.fn.getfperm(file)
          -- Check only the first three characters for 'rwx' to determine owner permissions
          local owner_permissions = permissions:sub(1, 3)
          -- Green for owner 'rwx', blue otherwise
          return permissions, owner_permissions == "rwx" and "#00ff00" or "#0099ff"
        end
      end

      local function get_file_owner()
        local file = vim.fn.expand("%:p")

        if file == "" or file == nil then
          return ""
        else
          local handle = io.popen('ls -l "' .. file .. '"')
          if handle == nil then
            return ""
          else
            local result = handle:read("*a")
            handle:close()

            -- Parse the output to extract the owner
            local owner = result:match("^%S+%s+%S+%s+(%S+)")
            return owner
          end
        end
      end

      -- Decide background color based on hostname's last character
      local function decide_color()
        local hostname = vim.fn.systemlist("hostname")[1]
        local last_char = hostname:sub(-1)
        local bg_color = "#A6AAF1" -- Default pink

        if last_char == "1" then
          bg_color = "#0DFFAE"
        elseif last_char == "2" then
          bg_color = "#FF6200"
        elseif last_char == "3" then
          bg_color = "#DBF227"
        end

        return bg_color
      end

      -- Hostname component with dynamically decided background color
      local bg_color = decide_color()

      -- Insert hostname component into lualine_x
      table.insert(opts.sections.lualine_x, 1, {
        -- "hostname",
        function()
          return get_file_owner()
        end,
        color = { fg = fg_color, bg = bg_color, gui = "bold" },
        -- separator = { left = "", right = "" },
        -- separator = { left = "", right = "" },
        -- separator = { left = "", right = "" },
        separator = { left = "", right = "" },
        -- separator = { left = "", right = "" },
        padding = 1,
      })

      -- File permissions component with dynamic background color
      -- Insert file permissions component into lualine_x
      table.insert(opts.sections.lualine_x, 1, {
        function()
          local permissions, _ = get_permissions_color() -- Ignore bg_color here if unused
          return permissions
        end,
        color = function()
          local _, bg_color = get_permissions_color() -- Use bg_color for dynamic coloring
          return { fg = fg_color, bg = bg_color, gui = "bold" }
        end,
        -- separator = { left = "", right = "" },
        -- separator = { left = "", right = "" },
        -- separator = { left = "", right = "" },
        -- separator = { left = "", right = "" },
        -- separator = { left = "", right = "" },
        separator = { left = "", right = "" },
        -- separator = { left = "", right = "" },
        -- separator = { left = "", right = "" },
        padding = 1,
      })
    end,
  },
}
