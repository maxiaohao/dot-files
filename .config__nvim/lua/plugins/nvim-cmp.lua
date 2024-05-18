return {
  {
    "hrsh7th/nvim-cmp",
    opts = {
      window = {
        completion = require("cmp").config.window.bordered(),
        documentation = require("cmp").config.window.bordered(),
      },
      mapping = require("cmp").mapping.preset.insert({
        ["<Tab>"] = require("cmp").mapping.confirm({ select = true }),
      }),
    },
  },
}
