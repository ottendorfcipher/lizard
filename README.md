# Lizard Popup (PowerShell)

A tiny PowerShell script that pops a lizard image at random screen positions and plays a sound every 0.5 seconds. Each popup auto-closes after ~3 seconds. Press Ctrl+C in the console to stop.

## Requirements
- Windows 10/11
- PowerShell 5.1 or 7+
- Windows Media Player available (WMPlayer COM object)
- Files in the same folder: `LizardPopup.ps1`, `lizard.png`, `lizard.mp3`

## Run
- PowerShell 7+:
  - `pwsh -File .\LizardPopup.ps1`
- Windows PowerShell 5.1:
  - `powershell -ExecutionPolicy Bypass -File .\LizardPopup.ps1`

Stop anytime with Ctrl+C.

## Notes
- Change the popup interval by editing `$ms` (in milliseconds) in the script.
- Adjust volume by changing `$global:mediaPlayer.settings.volume` (0–100).
- This is intentionally disruptive (popups + sound). Use responsibly.
