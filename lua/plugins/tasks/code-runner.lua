return {
  {
    main = "sniprun",
    id = "sniprun",
    source = "michaelb/sniprun",
    version = "master",
    enabled = false,

    build = { "sh", "install.sh" },
    opts = {},
  },
}
