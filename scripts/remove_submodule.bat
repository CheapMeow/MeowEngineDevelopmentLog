@echo off
setlocal
if "%~1"=="" (
    echo Usage: %~nx0 path\to\submodule
    exit /b 1
)
set SUBPATH=%~1
git submodule deinit -f "%SUBPATH%"
git rm -f "%SUBPATH%"
rd /s /q ".git\modules\%SUBPATH%"
endlocal
