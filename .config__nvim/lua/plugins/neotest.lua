return {
  {
    "nvim-neotest/neotest",
    opts = {
      adapters = {
        ["neotest-golang"] = {
          args = { "-count=1", "-timeout=3s" },
        },
      },
    },
  },
}
