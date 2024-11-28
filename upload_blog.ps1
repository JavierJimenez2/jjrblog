# PowerShell Script for Windows

# Set variables for Obsidian to Hugo copy
$sourcePath = "C:\Users\javip\OneDrive - UPV\blog"
$destinationPath = "C:\Users\javip\OneDrive - UPV\blog-site\blogjjr"

# Set Github repo 
$myrepo = "https://github.com/JavierJimenez2/jjrblog.git"

# Set error handling
$ErrorActionPreference = "Stop"
Set-StrictMode -Version Latest

# Change to the script's directory
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Definition
Set-Location $ScriptDir

# Check for required commands
$requiredCommands = @('git', 'hugo')

# Check for Python command (python or python3)
if (Get-Command 'python' -ErrorAction SilentlyContinue) {
    $pythonCommand = 'python'
} elseif (Get-Command 'python3' -ErrorAction SilentlyContinue) {
    $pythonCommand = 'python3'
} else {
    Write-Error "Python is not installed or not in PATH."
    exit 1
}

foreach ($cmd in $requiredCommands) {
    if (-not (Get-Command $cmd -ErrorAction SilentlyContinue)) {
        Write-Error "$cmd is not installed or not in PATH."
        exit 1
    }
}

# Step 1: Check if Git is initialized, and initialize if necessary
# if (-not (Test-Path ".git")) {
#     Write-Host "Initializing Git repository..."
#     # git init
#     git remote add origin $myrepo
# } else {
#     Write-Host "Git repository already initialized."
#     $remotes = git remote
#     if (-not ($remotes -contains 'origin')) {
#         Write-Host "Adding remote origin..."
#         git remote add origin $myrepo
#     }
# }

# Step 2: Sync posts from Obsidian to Hugo content folder using Robocopy
Write-Host "Syncing posts from Obsidian..."

if (-not (Test-Path $sourcePath)) {
    Write-Error "Source path does not exist: $sourcePath"
    exit 1
}

if (-not (Test-Path $destinationPath)) {
    Write-Error "Destination path does not exist: $destinationPath"
    exit 1
}

$sourcePath1 = $sourcePath + "\posts"
$destinationPath1 = $destinationPath + "\content\posts"

# Use Robocopy to mirror the directories
$robocopyOptions = @('/MIR', '/Z', '/W:5', '/R:3')
$robocopyResult = robocopy $sourcePath1 $destinationPath1 @robocopyOptions

if ($LASTEXITCODE -ge 8) {
    Write-Error "Robocopy failed with exit code $LASTEXITCODE"
    exit 1
}

# Step 3: Process Markdown files with Python script to handle image links
# Write-Host "Processing image links in Markdown files..."
# if (-not (Test-Path "images.py")) {
#     Write-Error "Python script images.py not found."
#     exit 1
# }

# # Execute the Python script
# try {
#     & $pythonCommand images.py
# } catch {
#     Write-Error "Failed to process image links."
#     exit 1
# }

# Step 4: Build the Hugo site
Write-Host "Building the Hugo site..."
try {
    hugo
} catch {
    Write-Error "Hugo build failed."
    exit 1
}

# Step 5: Add changes to Git
Write-Host "Staging changes for Git..."
$hasChanges = (git status --porcelain) -ne ""
if (-not $hasChanges) {
    Write-Host "No changes to stage."
} else {
    git add .
}

# Step 6: Commit changes with a dynamic message
$commitMessage = "New Blog Post on $(Get-Date -Format 'dd/MM/yyyy HH:mm:ss')"
$hasStagedChanges = (git diff --cached --name-only) -ne ""
if (-not $hasStagedChanges) {
    Write-Host "No changes to commit."
} else {
    Write-Host "Committing changes..."
    git commit -m "$commitMessage"
}

# Step 7: Push all changes to the main branch
Write-Host "Deploying to GitHub Master..."
try {
    git push origin main
} catch {
    Write-Error "Failed to push to Master branch."
    exit 1
}



Write-Host "All done! Site synced, processed, committed, built, and deployed."