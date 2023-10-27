import bindings from "bindings"
const addon = bindings("mac-panel-window.node")

const isMac = process.platform === "darwin"

export const makeKeyWindow = window => {
  if (!isMac) return
  return addon.makeKeyWindow(window.getNativeWindowHandle())
}

export const makePanel = window => {
  if (!isMac) return
  return addon.makePanel(window.getNativeWindowHandle())
}

export const makeWindow = window => {
  if (!isMac) return
  return addon.makeKeyWindow(window.getNativeWindowHandle())
}

export const setAlwaysOnTop = (window, shouldSet) => {
  if (!isMac) return
  return addon.setAlwaysOnTop(window.getNativeWindowHandle(), shouldSet)
}

export const bringToFront = window => {
  if (!isMac) return
  return addon.bringToFront(window.getNativeWindowHandle())
}
