hs.dockicon.hide()

if hs.application.find("AeroSpace") or hs.fs.attributes(os.getenv("HOME") .. "/.config/aerospace") then
  require("aerospace-hints").start()
end
