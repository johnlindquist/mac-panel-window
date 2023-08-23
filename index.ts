import bindings from "bindings"
const NativeExtension = bindings("mac-panel-window.node")

const isMac = process.platform === "darwin"
export const makeKeyWindow = window => {
  if (!isMac) return
  return NativeExtension.MakeKeyWindow(window.getNativeWindowHandle())
}
export const makePanel = window => {
  if (!isMac) return
  return NativeExtension.MakePanel(window.getNativeWindowHandle())
}
export const makeWindow = window => {
  if (!isMac) return
  return NativeExtension.MakeWindow(window.getNativeWindowHandle())
}
