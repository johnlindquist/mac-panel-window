import bindings from "bindings"
import { BrowserWindow } from "electron"

const addon = bindings("mac-panel-window.node")
const isMac = process.platform === "darwin"

export const makeKeyWindow = (window: BrowserWindow) => {
  if (!isMac) return
  return addon.makeKeyWindow(window.getNativeWindowHandle())
}

export const makePanel = (window: BrowserWindow) => {
  if (!isMac) return
  return addon.makePanel(window.getNativeWindowHandle())
}

export const makeWindow = (window: BrowserWindow) => {
  if (!isMac) return
  return addon.makeWindow(window.getNativeWindowHandle())
}

export const hideInstant = (window: BrowserWindow) => {
  if (!isMac) return
  return addon.hideInstant(window.getNativeWindowHandle())
}

export const getWindowBackgroundColor = () => {
  if (!isMac) return
  return addon.getWindowBackgroundColor()
}

export const getLabelColor = () => {
  if (!isMac) return
  return addon.getLabelColor()
}

export const getTextColor = () => {
  if (!isMac) return
  return addon.getTextColor()
}
