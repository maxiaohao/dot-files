return {
  {
    "nvim-lualine/lualine.nvim",
    opts = {
      options = {
        theme = "iceberg_dark", -- "iceberg_dark" / "gruvbox_dark"
        section_separators = "",
        component_separators = "",
      },
      sections = {
        lualine_z = {
          function()
            return ""
          end,
        },
      },
    },
  },
}
