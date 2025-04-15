DisplayColorSyncApp is a macOS background utility that automatically detects changes in the display configuration and reapplies the appropriate ICC color profiles to ensure consistent color management across all connected displays.

### Background

On MacBook Pro 14–16 inch models with Apple Silicon, as well as Apple displays such as Studio Display and Pro Display XDR, users no longer have the ability to manually select ICC profiles. Instead, macOS provides predefined "Reference Modes". These modes, while useful, reset the internal VCGT (video card gamma tables) to default whenever the user logs in, connects or disconnects an external display, or changes the reference mode. This causes the ICC calibration — such as white point adjustments and tone curve — to be ignored, leading to inaccurate display rendering.

### Features

- Detects when displays are connected, disconnected, or change resolution and automatically reapplies the ICC profile assigned to each display (as well as VCGT)
- Periodically reapplies ICC profiles every 5 seconds to restore LUT (VCGT), similar to how DisplayCAL's loader operates

### Usage

1. Calibrate your display using any color calibration software of your choice and install the resulting ICC profile.
2. You can also manually assign an ICC profile using the built-in ColorSync Utility on macOS.
3. Copy DisplayColorSyncApp into your `/Applications` folder.
4. Add the app to **Login Items** in System Settings → General → Login Items to make sure it starts automatically every time you log in.

The app will run silently in the background, requiring no further user interaction.

### Limitations

- macOS does not provide a public API to detect Reference Mode changes directly. Therefore, the app uses periodic reapplication to work around this limitation.
- No graphical interface is provided; all actions are automatic and background-based.
- Not work with Duplicate (Mirror) when using multi monitors.
- Not yet test with macOS 11 (Big Sur), Apple Studio Display and Pro Display XDR (but it should works)

### Possible Improvements

- GUI with manual ICC selection and push notification when reapply event occours
- Adjustable reapplication interval
- Preferences window for user configuration
