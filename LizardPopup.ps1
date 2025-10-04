# Lizard Popup Script
# Displays lizard image and plays sound every 0.5 seconds
# Press Ctrl+C in the console to stop the script

Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing


# Get the script directory to find the files
$scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Path
$imagePath = Join-Path $scriptPath "lizard.png"
$soundPath = Join-Path $scriptPath "lizard.mp3"

# Check if files exist
if (-not (Test-Path $imagePath)) {
    Write-Error "Image file not found: $imagePath"
    exit
}

if (-not (Test-Path $soundPath)) {
    Write-Error "Sound file not found: $soundPath"
    exit
}

# Initialize a reusable Windows Media Player COM object to minimize audio start latency
$global:mediaPlayer = New-Object -ComObject "WMPlayer.OCX.7"
$global:mediaPlayer.settings.volume = 100

# Global variables to track active popups and audio jobs
$global:activeForms = @()
$global:audioJobs = @()
$global:shouldStop = $false

# Function to close all active popups and stop audio
function Close-AllLizardPopups {
    Write-Host "Closing $($global:activeForms.Count) active popup(s)..."
    
    # Close all active forms
    foreach ($form in $global:activeForms) {
        if ($form -and -not $form.IsDisposed) {
            try {
                $form.Close()
            } catch {
                # Form might already be closed
            }
        }
    }
    $global:activeForms.Clear()
    
    # Stop all audio jobs
    Write-Host "Stopping $($global:audioJobs.Count) active audio job(s)..."
    foreach ($job in $global:audioJobs) {
        if ($job.State -eq "Running") {
            Stop-Job $job -Force
        }
        Remove-Job $job -Force
    }
    $global:audioJobs.Clear()
    
    # Clean up any remaining jobs
    Get-Job | Where-Object { $_.Name -like "*LizardAudio*" } | Remove-Job -Force
    
    Write-Host "All lizard popups and sounds stopped!"
}


Write-Host "Lizard popup script started!"
Write-Host "Controls:"
Write-Host "   • Press Ctrl+C to stop the script completely"
Write-Host "Files:"
Write-Host "   • Image: $imagePath"
Write-Host "   • Sound: $soundPath"
Write-Host ""


# Function to show image popup
function Show-LizardPopup {
    param($ImagePath)
    
    try {
        # Create form
        $form = New-Object System.Windows.Forms.Form
        $form.StartPosition = "Manual"
        $form.TopMost = $true
        $form.FormBorderStyle = "None"
        $form.MaximizeBox = $false
        $form.MinimizeBox = $false
        $form.ControlBox = $false
        $form.ShowInTaskbar = $false
        
        # Add to active forms list
        # Add to active forms list
        $global:activeForms += $form
        
        # Load and resize image
        $image = [System.Drawing.Image]::FromFile($ImagePath)
        $maxWidth = 400
        $maxHeight = 400
        
        $ratio = [Math]::Min($maxWidth / $image.Width, $maxHeight / $image.Height)
        $newWidth = [int]($image.Width * $ratio)
        $newHeight = [int]($image.Height * $ratio)
        
        # Create PictureBox
        $pictureBox = New-Object System.Windows.Forms.PictureBox
        $pictureBox.Image = $image
        $pictureBox.SizeMode = "StretchImage"
        $pictureBox.Dock = 'Fill'
        
        # Set client size to exactly match image (no borders/title)
        $form.ClientSize = New-Object System.Drawing.Size($newWidth, $newHeight)
        
        # Randomize position within the primary screen working area
        $bounds = [System.Windows.Forms.Screen]::PrimaryScreen.WorkingArea
        $maxX = [Math]::Max(0, $bounds.Width - $form.Width)
        $maxY = [Math]::Max(0, $bounds.Height - $form.Height)
        $randX = Get-Random -Minimum 0 -Maximum ($maxX + 1)
        $randY = Get-Random -Minimum 0 -Maximum ($maxY + 1)
        $form.Location = New-Object System.Drawing.Point(($bounds.X + $randX), ($bounds.Y + $randY))
        
        # Add controls to form
        $form.Controls.Add($pictureBox)
        
        # Auto-close after 3 seconds
        $timer = New-Object System.Windows.Forms.Timer
        $timer.Interval = 3000  # 3 seconds
        $timer.Add_Tick({
            $timer.Stop()
            $form.Close()
        })
        $timer.Start()
        
        # Handle form closing to remove from active list
        $form.Add_FormClosed({
            $global:activeForms = $global:activeForms | Where-Object { $_ -ne $form }
        })
        
        # Show form
        $form.Add_Shown({ $form.Activate() })
        $form.ShowDialog() | Out-Null
        
        # Cleanup
        $image.Dispose()
        $form.Dispose()
        
    } catch {
        Write-Host "Error showing popup: $_"
    }
}

# Main loop
try {
    while ($true) {
        # Fixed interval: 0.5 seconds
        $ms = 500
        Write-Host "$(Get-Date -Format 'HH:mm:ss.fff') - Waiting 0.5 seconds..."
        
        Start-Sleep -Milliseconds $ms
        
        Write-Host "$(Get-Date -Format 'HH:mm:ss.fff') - LIZARD ATTACK!"
        
        # Play sound with minimal latency using pre-initialized player
        $global:mediaPlayer.URL = $soundPath
        $global:mediaPlayer.controls.play()
        
        # Show popup
        Show-LizardPopup -ImagePath $imagePath
        
    }
} catch {
    Write-Host "Script interrupted or error occurred: $_"
} finally {
    Write-Host "Cleaning up..."
    
    # Close all remaining popups
    Close-AllLizardPopups
    
    # Clean up any remaining jobs (including non-tracked ones)
    Get-Job | Where-Object { $_.Name -like "*LizardAudio*" -or $_.Name -eq "" } | Remove-Job -Force

    # Stop and release media player
    if ($global:mediaPlayer) {
        try { $global:mediaPlayer.controls.stop() } catch {}
        [void][System.Runtime.InteropServices.Marshal]::ReleaseComObject($global:mediaPlayer)
        $global:mediaPlayer = $null
    }
    
    Write-Host "Lizard popup script stopped."
}
