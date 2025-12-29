vim.filetype.add {
  extension = {
    nu = "nu",
    dockerfile = "dockerfile",
  },
  filename = {
    ["Dockerfile"] = "dockerfile",
  },
  pattern = {
    ["Dockerfile.*"] = "dockerfile",
  },
}

