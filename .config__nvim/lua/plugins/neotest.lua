return {
  {
    "nvim-neotest/neotest",
    opts = {
      adapters = {
        ["neotest-golang"] = {
          go_test_args = { "-v", "-race", "-count=1", "-timeout=3s" },
        },
      },
    },
  },
}
