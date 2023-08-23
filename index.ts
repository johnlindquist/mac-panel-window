import bindings from "bindings"
const addon = bindings("mac-panel-window.node")

const isMac = process.platform === "darwin"
export const makeKeyWindow = window => {
  if (!isMac) return
  return addon.MakeKeyWindow(window.getNativeWindowHandle())
}
export const makePanel = window => {
  if (!isMac) return
  return addon.MakePanel(window.getNativeWindowHandle())
}
export const makeWindow = window => {
  if (!isMac) return
  return addon.MakeWindow(window.getNativeWindowHandle())
}
