return {
  s({ trig = "date", desc = "Date" }, { t(os.date("%Y.%m.%d")) }),
  s({ trig = "datetime", desc = "Date & time" }, { t(os.date("%Y.%m.%d %H:%M:%S")) }),
}
