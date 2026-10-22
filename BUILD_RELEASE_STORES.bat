@echo off
setlocal
rem Optional production keys (set before running):
rem   set ADMOB_BANNER, ADMOB_INTERSTITIAL, ADMOB_REWARDED, ADMOB_APP_OPEN, RC_GOOGLE_KEY
rem Also replace the AdMob APP ID in android\app\src\main\AndroidManifest.xml and create android\key.properties.
set DEFS=
if defined ADMOB_BANNER set DEFS=%DEFS% --dart-define=ADMOB_BANNER=%ADMOB_BANNER%
if defined ADMOB_INTERSTITIAL set DEFS=%DEFS% --dart-define=ADMOB_INTERSTITIAL=%ADMOB_INTERSTITIAL%
if defined ADMOB_REWARDED set DEFS=%DEFS% --dart-define=ADMOB_REWARDED=%ADMOB_REWARDED%
if defined ADMOB_APP_OPEN set DEFS=%DEFS% --dart-define=ADMOB_APP_OPEN=%ADMOB_APP_OPEN%
if defined RC_GOOGLE_KEY set DEFS=%DEFS% --dart-define=RC_GOOGLE_KEY=%RC_GOOGLE_KEY%

echo [1/3] Google Play App Bundle (.aab)
call flutter build appbundle --release %DEFS%
echo [2/3] Universal APK for Samsung Galaxy Store / Amazon Appstore
call flutter build apk --release %DEFS%
echo [3/3] Web / PWA
call flutter build web --release --no-tree-shake-icons

echo AAB: build\app\outputs\bundle\release\app-release.aab
echo APK: build\app\outputs\flutter-apk\app-release.apk
echo Web: build\web
pause
