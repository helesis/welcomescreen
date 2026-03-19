@echo off
setlocal EnableDelayedExpansion
REM === URL: GitHub Pages veya yerel dosya ===
set "URL=https://helesis.github.io/welcomescreen/"
REM Yerel: set "URL=file:///C:/VoyageScreen/index.html"
REM === Tarayici yolunu bul (Chrome veya Edge) ===
set "BROWSER="
REM Chrome - Program Files (cogunlukla bu calisir)
if exist "C:\Program Files\Google\Chrome\Application\chrome.exe" set "BROWSER=C:\Program Files\Google\Chrome\Application\chrome.exe"
if exist "C:\Program Files (x86)\Google\Chrome\Application\chrome.exe" set "BROWSER=C:\Program Files (x86)\Google\Chrome\Application\chrome.exe"
REM Chrome - Kullanici kurulumu
if "%BROWSER%"=="" if exist "%LOCALAPPDATA%\Google\Chrome\Application\chrome.exe" set "BROWSER=%LOCALAPPDATA%\Google\Chrome\Application\chrome.exe"
REM Edge (Windows 10/11 - genelde yuklu gelir)
if "%BROWSER%"=="" if exist "C:\Program Files (x86)\Microsoft\Edge\Application\msedge.exe" set "BROWSER=C:\Program Files (x86)\Microsoft\Edge\Application\msedge.exe"
if "%BROWSER%"=="" if exist "C:\Program Files\Microsoft\Edge\Application\msedge.exe" set "BROWSER=C:\Program Files\Microsoft\Edge\Application\msedge.exe"
REM Elle yol tanimlama: Bu satirdaki yolu kendi makinenize gore degistirin
REM set "BROWSER=C:\Tam\Yol\chrome.exe"
if "%BROWSER%"=="" (
echo.
echo Tarayici bulunamadi. Asagidakileri deneyin:
echo.
echo 1. Dosya gezgininde Chrome veya Edge arayin, sag tik ^> "Dosya konumunu ac"
echo 2. Bu dosyada "REM set" satirindaki REM'i kaldirip yolu yazin
echo 3. CMD de calistirin: dir /s /b C:\chrome.exe 2^>nul
echo.
pause
exit /b 1
)
REM === Kiosk modunda baslat ===
start "" "!BROWSER!" ^
  --kiosk ^
  --profile-directory="Default" ^
  --disable-infobars ^
  --no-first-run ^
  --disable-session-crashed-bubble ^
  --disable-restore-session-state ^
  --start-fullscreen ^
  --autoplay-policy=no-user-gesture-required ^
"%URL%"
echo Kiosk baslatildi: !BROWSER!