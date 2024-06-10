return {
  {
    "nvim-neotest/neotest",
    opts = {
      adapters = {
        ["neotest-go"] = {
          args = { "-count=1", "-timeout=3s" },
        },
      },
    },
  },
}
