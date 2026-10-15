@echo off
rem SONIQ publisher: pushes code, removes the bad "Spicetify" tag/release,
rem and creates a proper versioned release that triggers the build workflow.
rem Usage: publish.bat [version]   e.g.  publish.bat 2.42.0
setlocal EnableExtensions
cd /d "%~dp0"

set "VERSION=%~1"
if "%VERSION%"=="" set "VERSION=2.42.0"
if "%VERSION:~0,1%"=="v" set "VERSION=%VERSION:~1%"
set "TAG=v%VERSION%"

where git >nul 2>&1 || (echo ERROR: git not found on PATH. & exit /b 1)

echo [1/5] Checking required files...
if not exist ".github\assets\soniq-logo.png" (echo ERROR: logo missing: .github\assets\soniq-logo.png & exit /b 1)
if not exist "soniq.go" (echo ERROR: run this from the SONIQ repo root. & exit /b 1)

echo [2/5] Committing and pushing code...
git rev-parse --git-dir >nul 2>&1 || (
  echo (not a git repo yet, initializing...)
  git init -b main
  git remote get-url origin >nul 2>&1 || git remote add origin https://github.com/Bazw39/soniq.git
)
git add -A
git config user.email >nul 2>&1 || (
  echo (setting local git identity...)
  git config user.name "Bazw39"
  git config user.email "Bazw39@users.noreply.github.com"
)
if exist ".git\rebase-merge" (
  git -c core.editor=true rebase --continue 2>nul || (
    echo (clearing stale rebase state...)
    rmdir /s /q ".git\rebase-merge" 2>nul
    rmdir /s /q ".git\rebase-apply" 2>nul
  )
)
git commit -m "SONIQ release %TAG%" 2>nul || echo (nothing new to commit)
for /f "delims=" %%b in ('git branch --show-current 2^>nul') do set "BRANCH=%%b"
if "%BRANCH%"=="" set "BRANCH=main"
git push -u origin "%BRANCH%" 2>nul || (
  echo (push rejected, syncing with remote first...)
  git pull --rebase --allow-unrelated-histories origin "%BRANCH%" || (
    echo.
    echo Sync conflicted. Resolve it with:
    echo   git status                      ^(see which files conflict^)
    echo   git checkout --theirs -- README.md   ^(keep YOUR readme; repeat for other files you want to keep^)
    echo   git add -A
    echo   git -c core.editor=true rebase --continue
    echo then re-run publish.bat.
    exit /b 1
  )
  git push -u origin "%BRANCH%" || (echo ERROR: git push failed. & exit /b 1)
)

where gh >nul 2>&1 || (
  echo.
  echo gh CLI not found. Install it ^(winget install GitHub.cli^), run 'gh auth login',
  echo then re-run this script. Remaining manual steps:
  echo   - Delete release/tag 'Spicetify' on GitHub
  echo   - Create release '%TAG%' so the build workflow attaches binaries
  exit /b 1
)

echo [3/5] Deleting bad 'Spicetify' release and tag...
gh release delete Spicetify --cleanup-tag --yes 2>nul || echo (no 'Spicetify' release found, continuing)
git tag -d Spicetify 2>nul
git push origin :refs/tags/Spicetify 2>nul

echo [4/5] Creating release %TAG% ...
gh release delete "%TAG%" --cleanup-tag --yes 2>nul || echo (no existing '%TAG%' release, continuing)
git push origin :refs/tags/%TAG% 2>nul
gh release create "%TAG%" --title "SONIQ v%VERSION%" --generate-notes || (echo ERROR: release creation failed. & exit /b 1)

echo [5/5] Done. The 'SONIQ Build' workflow is now compiling assets.
echo Watch it at: https://github.com/Bazw39/soniq/actions
echo When it finishes, the README badge and installers will go live.
endlocal
