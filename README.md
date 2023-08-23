# @johnlindquist/mac-panel-window

Get the panel-window application on macOS

```js
import { getpanel-windowApp } from "@johnlindquist/mac-panel-window"

console.log(getpanel-windowApp())
```

```js
/* Example return type:
{
  localizedName: 'iTerm2',
  bundleIdentifier: 'com.googlecode.iterm2',
  bundleURLPath: '/Applications/iTerm.app',
  executableURLPath: '/Applications/iTerm.app/Contents/MacOS/iTerm2',
  isFinishedLaunching: true,
  processIdentifier: 92918,
  x: 45,
  y: 72,
  width: 885,
  height: 849
}
*/
```
