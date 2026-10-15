@echo off
rem SONIQ publisher: verifies, pushes code and cuts a versioned release that
rem triggers the build workflow. Usage:
rem   publish.bat            bump patch from latest tag (v2.42.0 -^> v2.42.1)
rem   publish.bat 2.43.0     release a specific version
rem   publish.bat major      bump major, publish.bat minor = bump minor
setlocal EnableExtensions EnableDelayedExpansion
cd /d "%~dp0"

set "BUMP=%~1"
if not defined BUMP goto :auto_bump
if /i "%BUMP%"=="major" goto :major_bump
if /i "%BUMP%"=="minor" goto :minor_bump
set "VERSION=%BUMP%"
if "%VERSION:~0,1%"=="v" set "VERSION=%VERSION:~1%"
goto :have_version

:auto_bump
set "LASTTAG="
for /f "delims=" %%t in ('git describe --tags --abbrev^=0 2^>nul') do set "LASTTAG=%%t"
if not defined LASTTAG set "LASTTAG=v2.42.0"
set "LASTTAG=%LASTTAG:~1%"
echo (latest tag found, bumping patch...)
for /f "tokens=1-3 delims=." %%a in ("%LASTTAG%") do set "PB_A=%%a" & set "PB_B=%%b" & set "PB_C=%%c"
set /a "PB_C=%PB_C%+1"
if "%PB_A%"=="" set "PB_A=2"
if "%PB_B%"=="" set "PB_B=42"
if "%PB_C%"=="" set "PB_C=1"
set "VERSION=%PB_A%.%PB_B%.%PB_C%"
goto :have_version

:major_bump
set "LASTTAG="
for /f "delims=" %%t in ('git describe --tags --abbrev^=0 2^>nul') do set "LASTTAG=%%t"
if not defined LASTTAG set "LASTTAG=v2.42.0"
for /f "tokens=1 delims=." %%a in ("%LASTTAG%") do set "MJ=%%a"
set "MJ=%MJ:v=%"
set /a "MJ=%MJ%+1"
set "VERSION=%MJ%.0.0"
goto :have_version

:minor_bump
set "LASTTAG="
for /f "delims=" %%t in ('git describe --tags --abbrev^=0 2^>nul') do set "LASTTAG=%%t"
if not defined LASTTAG set "LASTTAG=v2.42.0"
set "LASTTAG=%LASTTAG:~1%"
for /f "tokens=1-2 delims=." %%a in ("%LASTTAG%") do set "MN_A=%%a" & set "MN_B=%%b"
set /a "MN_B=%MN_B%+1"
set "VERSION=%MN_A%.%MN_B%.0"
goto :have_version

:have_version
set "TAG=v%VERSION%"
echo Releasing SONIQ %TAG%
if exist ".last-publish" (
  set /p LASTPUB=<.last-publish
  echo Last published: !LASTPUB!
) else (
  echo Last published: never
)

where git >nul 2>&1 || (echo ERROR: git not found on PATH. & exit /b 1)

echo [1/6] Checking required files...
if not exist ".github\assets\soniq-logo.png" (echo ERROR: logo missing: .github\assets\soniq-logo.png & exit /b 1)
if not exist "soniq.go" (echo ERROR: run this from the SONIQ repo root. & exit /b 1)
where node >nul 2>&1 && (
  node --check Extensions/soniqStore.js || (echo ERROR: soniqStore.js has a syntax error. & exit /b 1)
  node --check CustomApps/soniq-store/index.js || (echo ERROR: store index.js has a syntax error. & exit /b 1)
  node --check CustomApps/soniq-store/catalog.js || (echo ERROR: store catalog.js has a syntax error. & exit /b 1)
)

echo [2/6] Committing and pushing code...
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

echo [3/6] Deleting bad 'Spicetify' release and tag...
gh release delete Spicetify --cleanup-tag --yes 2>nul || echo (no 'Spicetify' release found, continuing)
git tag -d Spicetify 2>nul
git push origin :refs/tags/Spicetify 2>nul

echo [4/6] Creating release %TAG% ...
gh release delete "%TAG%" --cleanup-tag --yes 2>nul || echo (no existing '%TAG%' release, continuing)
git push origin :refs/tags/%TAG% 2>nul
gh release create "%TAG%" --title "SONIQ v%VERSION%" --generate-notes || (echo ERROR: release creation failed. & exit /b 1)

echo [5/6] Done. The 'SONIQ Build' workflow is now compiling assets.
echo Watch it at: https://github.com/Bazw39/soniq/actions
echo When it finishes, the README badge and installers will go live.
for /f "delims=" %%d in ('powershell -NoProfile -Command "Get-Date -Format 'yyyy-MM-dd HH:mm:ss'" 2^>nul') do set "STAMP=%%d"
if not defined STAMP set "STAMP=%DATE% %TIME%"
echo %TAG% published at %STAMP% > .last-publish
echo Published %TAG% at %STAMP% (saved to .last-publish)
endlocal
