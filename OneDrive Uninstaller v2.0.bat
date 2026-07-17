@rem ============================================================================
@rem  OneDrive TOTAL Uninstaller for Windows 10 & 11
@rem  Run as Administrator to completely remove ALL traces of OneDrive from
@rem  every user profile on the machine and block it from ever reinstalling.
@rem
@rem  V2.0 by TERRA Operative - 2026/07/17.
@rem  Consolidated cleanup, ownership/permission handling,
@rem  startup + scheduled-task scanning, Active Setup removal, all-user-profile
@rem  cleanup (incl. offline registry hives), environment variables, cached
@rem  credentials, Known Folder redirect repair, prefetch, and a reinstall block.
@rem
@rem  Feel free to distribute freely as long as you leave the attribution intact,
@rem  and if you make changes and adaptions, don't be a dick about not attributing
@rem  where due. And most importantly, peace out and keep it real.
@rem
@rem  ############################  IMPORTANT  ###################################
@rem  This performs a TOTAL wipe of OneDrive across ALL user accounts, and will
@rem  DELETE the contents of any folder that lived inside OneDrive (Desktop /
@rem  Documents / Pictures etc. if Folder Backup / Known Folder Move was on).
@rem  BACK UP EVERYTHING FIRST. It also blocks OneDrive from reinstalling.
@rem  It is normal to REBOOT and run this a SECOND time to clear locked items.
@rem  ###########################################################################
@rem ============================================================================

@echo OFF
SETLOCAL EnableDelayedExpansion

@rem ---- The File Explorer namespace CLSID for "OneDrive" (personal) ----
set "ODCLSID={018D5C66-4533-4307-9B53-224DE2ED1FE6}"

@rem ---- Administrators group SID (language independent) for icacls ----
set "ADMINSID=*S-1-5-32-544"

@rem ---- Temp mount point used when loading offline user registry hives ----
set "HIVEMOUNT=HKU\ODCLEAN_TEMP"

@REM ---- Set variables for coloured text ----
for /F "tokens=1,2 delims=#" %%a in ('"prompt #$H#$E# & echo on & for %%b in (1) do rem"') do (
  set "DEL=%%a"
)

   echo ------ Windows 10/11 OneDrive TOTAL Uninstaller V2.0 ------
   echo.

@rem ---------------------------------------------------------------------------
@rem  Require administrator privileges
@rem ---------------------------------------------------------------------------
NET SESSION >nul 2>&1
IF %ERRORLEVEL% EQU 0 (
   echo        Administrator Privileges Detected!
   echo.
) ELSE (
   echo.
   call :colorEcho 0C "########### ERROR - ADMINISTRATOR PRIVILEGES REQUIRED #############"
   echo.
   call :colorEcho 07 "    This script must be run as administrator to work properly."
   echo.
   call :colorEcho 07 "    Right click the file and select 'Run As Administrator'."
   echo.
   call :colorEcho 0C "###################################################################"
   echo.
   echo.
   PAUSE
   EXIT /B 1
)

@rem ---------------------------------------------------------------------------
@rem  Warning / confirmation
@rem ---------------------------------------------------------------------------
   echo -----------------------------------------------
   call :colorEcho 0C "                    WARNING"
   echo.
   call :colorEcho 0C "  This performs a TOTAL removal of OneDrive"
   echo.
   call :colorEcho 0C "     from EVERY user account on this PC,"
   echo.
   call :colorEcho 0C "   deletes anything stored inside OneDrive,"
   echo.
   call :colorEcho 0C "     and blocks it from reinstalling."
   echo.
   call :colorEcho 0C "     BACK UP ALL FILES before proceeding."
   echo.
   echo -----------------------------------------------
   echo.

   SET "M="
   SET /P M=  Press 'Y' to continue or any other key to exit.
   if /I not "!M!"=="Y" EXIT /B 1

@rem ===========================================================================
@rem  MAIN SEQUENCE
@rem ===========================================================================
   call :PROCESSKILL
   call :UNINSTALL
   call :STARTUP
   call :SCHTASKS
   call :ACTIVESETUP
   call :ALLUSERS
   call :CLEANFILES
   call :ENVVARS
   call :CREDS
   call :SHELLFOLDERS
   call :PREFETCH
   call :CLEANREG
   call :PREVENT

   echo.
   echo -----------------------------------------------
   call :colorEcho 0A "  OneDrive TOTAL removal completed."
   echo.
   echo -----------------------------------------------
   echo.
   call :colorEcho 0E "  If you saw any 'access denied' or 'in use' messages above,"
   echo.
   call :colorEcho 0E "  REBOOT and run this script one more time to finish the job."
   echo.
   echo.
   echo   Press any key to quit . . .
   PAUSE >nul
   echo.
   echo   So long and thanks for all the fish...
   PING -n 2 127.0.0.1 >nul
   EXIT /B 0


@rem ===========================================================================
@rem  :PROCESSKILL  -  Terminate all OneDrive-related processes
@rem ===========================================================================
:PROCESSKILL
   echo.
   echo === Terminating OneDrive processes ===
   for %%P in (OneDrive.exe OneDriveSetup.exe OneDriveStandaloneUpdater.exe FileCoAuth.exe FileSyncHelper.exe Microsoft.SharePoint.exe) do (
      taskkill /f /im "%%P" >nul 2>&1 && echo   Terminated %%P
   )
   echo   Done.
goto :eof


@rem ===========================================================================
@rem  :UNINSTALL  -  Run every OneDrive uninstaller we can find
@rem ===========================================================================
:UNINSTALL
   echo.
   echo === Running OneDrive uninstallers ===
   if exist "%SystemRoot%\System32\OneDriveSetup.exe" (
      echo   Uninstalling via System32\OneDriveSetup.exe
      "%SystemRoot%\System32\OneDriveSetup.exe" /uninstall
   )
   if exist "%SystemRoot%\SysWOW64\OneDriveSetup.exe" (
      echo   Uninstalling via SysWOW64\OneDriveSetup.exe
      "%SystemRoot%\SysWOW64\OneDriveSetup.exe" /uninstall
   )
   if exist "%LocalAppData%\Microsoft\OneDrive\OneDrive.exe" (
      echo   Uninstalling via LocalAppData OneDrive.exe
      "%LocalAppData%\Microsoft\OneDrive\OneDrive.exe" /uninstall
   )
   for /d %%V in ("%LocalAppData%\Microsoft\OneDrive\*") do (
      if exist "%%~V\OneDriveSetup.exe" (
         echo   Uninstalling via %%~nxV\OneDriveSetup.exe
         "%%~V\OneDriveSetup.exe" /uninstall
      )
   )
   PING -n 3 127.0.0.1 >nul
   echo   Done.
goto :eof


@rem ===========================================================================
@rem  :STARTUP  -  Scan Windows startup for OneDrive entries and remove them
@rem ===========================================================================
:STARTUP
   echo.
   echo === Scanning startup for OneDrive entries ===
   for %%K in (
      "HKCU\Software\Microsoft\Windows\CurrentVersion\Run"
      "HKCU\Software\Microsoft\Windows\CurrentVersion\RunOnce"
      "HKLM\Software\Microsoft\Windows\CurrentVersion\Run"
      "HKLM\Software\Microsoft\Windows\CurrentVersion\RunOnce"
      "HKLM\Software\Wow6432Node\Microsoft\Windows\CurrentVersion\Run"
      "HKLM\Software\Wow6432Node\Microsoft\Windows\CurrentVersion\RunOnce"
      "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\StartupApproved\Run"
      "HKLM\Software\Microsoft\Windows\CurrentVersion\Explorer\StartupApproved\Run"
      "HKLM\Software\Wow6432Node\Microsoft\Windows\CurrentVersion\Explorer\StartupApproved\Run"
   ) do (
      for /f "tokens=1,*" %%A in ('reg query %%K 2^>nul ^| findstr /i "OneDrive"') do (
         echo   Removing startup value "%%A" from %%~K
         reg delete %%K /v "%%A" /f >nul 2>&1
      )
   )
   for %%D in (
      "%AppData%\Microsoft\Windows\Start Menu\Programs\Startup"
      "%ProgramData%\Microsoft\Windows\Start Menu\Programs\Startup"
   ) do (
      if exist "%%~D\*OneDrive*.lnk" (
         echo   Removing startup shortcut in %%~D
         del /f /q "%%~D\*OneDrive*.lnk" >nul 2>&1
      )
   )
   echo   Done.
goto :eof


@rem ===========================================================================
@rem  :SCHTASKS  -  Scan scheduled tasks for OneDrive and delete them
@rem ===========================================================================
:SCHTASKS
   echo.
   echo === Scanning scheduled tasks for OneDrive entries ===
   for /f "tokens=1 delims=," %%T in ('schtasks /query /fo csv /nh 2^>nul ^| findstr /i "OneDrive"') do (
      echo   Deleting scheduled task %%~T
      schtasks /delete /tn "%%~T" /f >nul 2>&1
   )
   echo   Done.
goto :eof


@rem ===========================================================================
@rem  :ACTIVESETUP  -  Remove OneDrive Active Setup entries.
@rem  These re-run OneDriveSetup.exe the first time ANY user logs in, so they
@rem  must go or OneDrive comes back for new accounts.
@rem ===========================================================================
:ACTIVESETUP
   echo.
   echo === Removing Active Setup entries (blocks reinstall for new users) ===
   for %%R in (
      "HKLM\SOFTWARE\Microsoft\Active Setup\Installed Components"
      "HKLM\SOFTWARE\Wow6432Node\Microsoft\Active Setup\Installed Components"
   ) do (
      for /f "delims=" %%K in ('reg query %%R 2^>nul') do (
         reg query "%%K" /v StubPath 2>nul | findstr /i "OneDrive" >nul && (echo   Removing Active Setup: %%K& reg delete "%%K" /f >nul 2>&1)
      )
   )
   echo   Done.
goto :eof


@rem ===========================================================================
@rem  :ALLUSERS  -  Clean OneDrive from EVERY user profile on the machine,
@rem  including per-profile files and their OFFLINE registry hive (NTUSER.DAT).
@rem  The currently-logged-on user's live hive is handled elsewhere (HKCU).
@rem ===========================================================================
:ALLUSERS
   echo.
   echo === Cleaning all user profiles ===
   reg unload "%HIVEMOUNT%" >nul 2>&1
   for /d %%U in ("%SystemDrive%\Users\*") do (
      if /i not "%%~nxU"=="Public" if /i not "%%~nxU"=="All Users" (
         echo   Profile: %%~nxU
         call :forceDelDir "%%~U\OneDrive"
         call :forceDelDir "%%~U\OneDrive - Personal"
         call :forceDelDir "%%~U\AppData\Local\Microsoft\OneDrive"
         call :forceDelDir "%%~U\AppData\Roaming\Microsoft\OneDrive"
         call :forceDelFile "%%~U\AppData\Roaming\Microsoft\Windows\Start Menu\Programs\OneDrive.lnk"
         if exist "%%~U\NTUSER.DAT" (
            reg load "%HIVEMOUNT%" "%%~U\NTUSER.DAT" >nul 2>&1
            if not errorlevel 1 (
               reg delete "%HIVEMOUNT%\Software\Microsoft\OneDrive" /f >nul 2>&1
               reg delete "%HIVEMOUNT%\Software\Microsoft\Windows\CurrentVersion\Run" /v OneDrive /f >nul 2>&1
               reg delete "%HIVEMOUNT%\Software\Microsoft\Windows\CurrentVersion\Run" /v OneDriveSetup /f >nul 2>&1
               reg delete "%HIVEMOUNT%\Software\Classes\CLSID\%ODCLSID%" /f >nul 2>&1
               reg delete "%HIVEMOUNT%\Environment" /v OneDrive /f >nul 2>&1
               reg delete "%HIVEMOUNT%\Environment" /v OneDriveConsumer /f >nul 2>&1
               reg delete "%HIVEMOUNT%\Environment" /v OneDriveCommercial /f >nul 2>&1
               reg unload "%HIVEMOUNT%" >nul 2>&1
            )
         )
      )
   )
   echo   Done.
goto :eof


@rem ===========================================================================
@rem  :CLEANFILES  -  Remove machine-wide OneDrive files & folders.
@rem  Per-user folders are handled by :ALLUSERS. Each removal takes ownership
@rem  and grants Administrators full control first so locked items delete.
@rem ===========================================================================
:CLEANFILES
   echo.
   echo === Removing machine-wide OneDrive files and folders ===
   call :forceDelDir "%ProgramData%\Microsoft OneDrive"
   call :forceDelDir "%ProgramFiles%\Microsoft OneDrive"
   call :forceDelDir "%ProgramFiles(x86)%\Microsoft OneDrive"
   call :forceDelDir "%SystemDrive%\OneDriveTemp"
   call :forceDelFile "%SystemRoot%\System32\OneDriveSetup.exe"
   call :forceDelFile "%SystemRoot%\SysWOW64\OneDriveSetup.exe"
   call :forceDelFile "%SystemRoot%\System32\OneDrive.ico"
   call :forceDelFile "%SystemRoot%\SysWOW64\OneDrive.ico"
   call :forceDelFile "%ProgramData%\Microsoft\Windows\Start Menu\Programs\OneDrive.lnk"
   echo   Done.
goto :eof


@rem ===========================================================================
@rem  :ENVVARS  -  Remove OneDrive environment variables (current user)
@rem ===========================================================================
:ENVVARS
   echo.
   echo === Removing OneDrive environment variables ===
   for %%E in (OneDrive OneDriveConsumer OneDriveCommercial) do (
      reg delete "HKCU\Environment" /v %%E /f >nul 2>&1
   )
   echo   Done.
goto :eof


@rem ===========================================================================
@rem  :CREDS  -  Best-effort removal of cached OneDrive credentials
@rem ===========================================================================
:CREDS
   echo.
   echo === Removing cached OneDrive credentials ===
   for /f "tokens=1,*" %%A in ('cmdkey /list 2^>nul ^| findstr /i /r "Target:.*OneDrive"') do (
      echo   Removing credential %%B
      cmdkey /delete:"%%B" >nul 2>&1
   )
   echo   Done.
goto :eof


@rem ===========================================================================
@rem  :SHELLFOLDERS  -  If Known Folder Move redirected Desktop/Documents/etc.
@rem  into OneDrive, reset those pointers back to the local profile defaults so
@rem  the folders are not left pointing at a deleted OneDrive path.
@rem ===========================================================================
:SHELLFOLDERS
   echo.
   echo === Checking for redirected (Known Folder Move) shell folders ===
   reg query "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\User Shell Folders" 2>nul | findstr /i "OneDrive" >nul
   if errorlevel 1 (
      echo   No OneDrive folder redirection found.
      goto :eof
   )
   echo   OneDrive redirection found - resetting folders to local defaults.
   call :fixKF "Desktop"   "%%USERPROFILE%%\Desktop"   "%USERPROFILE%\Desktop"
   call :fixKF "Personal"  "%%USERPROFILE%%\Documents" "%USERPROFILE%\Documents"
   call :fixKF "My Pictures" "%%USERPROFILE%%\Pictures" "%USERPROFILE%\Pictures"
   call :fixKF "My Music"  "%%USERPROFILE%%\Music"     "%USERPROFILE%\Music"
   call :fixKF "My Video"  "%%USERPROFILE%%\Videos"    "%USERPROFILE%\Videos"
   call :fixKF "Favorites" "%%USERPROFILE%%\Favorites" "%USERPROFILE%\Favorites"
   call :fixKF "{374DE290-123F-4565-9164-39C4925E467B}" "%%USERPROFILE%%\Downloads" "%USERPROFILE%\Downloads"
   echo   Done. (Sign out/in or reboot for Explorer to pick up the change.)
goto :eof

@rem  :fixKF <valueName> <expandSzData> <plainData>
:fixKF
   if not exist "%~3" mkdir "%~3" >nul 2>&1
   reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\User Shell Folders" /v "%~1" /t REG_EXPAND_SZ /d "%~2" /f >nul 2>&1
   reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Shell Folders" /v "%~1" /t REG_SZ /d "%~3" /f >nul 2>&1
goto :eof


@rem ===========================================================================
@rem  :PREFETCH  -  Remove OneDrive prefetch traces
@rem ===========================================================================
:PREFETCH
   echo.
   echo === Removing OneDrive prefetch files ===
   del /f /q "%SystemRoot%\Prefetch\ONEDRIVE*.pf" >nul 2>&1
   del /f /q "%SystemRoot%\Prefetch\ONEDRIVESETUP*.pf" >nul 2>&1
   echo   Done.
goto :eof


@rem ===========================================================================
@rem  :CLEANREG  -  Remove machine-wide + current-user OneDrive registry entries
@rem ===========================================================================
:CLEANREG
   echo.
   echo === Removing OneDrive registry keys ===

   @rem --- Explorer namespace (removes OneDrive from the File Explorer tree) ---
   reg delete "HKCR\CLSID\%ODCLSID%" /f >nul 2>&1
   reg delete "HKCR\Wow6432Node\CLSID\%ODCLSID%" /f >nul 2>&1
   reg delete "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Desktop\NameSpace\%ODCLSID%" /f >nul 2>&1
   reg delete "HKLM\SOFTWARE\Wow6432Node\Microsoft\Windows\CurrentVersion\Explorer\Desktop\NameSpace\%ODCLSID%" /f >nul 2>&1
   reg delete "HKCU\Software\Classes\CLSID\%ODCLSID%" /f >nul 2>&1

   @rem Belt-and-suspenders: if a namespace key survives, hide it instead
   reg add "HKCR\CLSID\%ODCLSID%" /v System.IsPinnedToNameSpaceTree /t REG_DWORD /d 0 /f >nul 2>&1
   reg add "HKCR\Wow6432Node\CLSID\%ODCLSID%" /v System.IsPinnedToNameSpaceTree /t REG_DWORD /d 0 /f >nul 2>&1

   @rem --- Application / sync client settings ---
   reg delete "HKCU\Software\Microsoft\OneDrive" /f >nul 2>&1
   reg delete "HKLM\SOFTWARE\Microsoft\OneDrive" /f >nul 2>&1
   reg delete "HKLM\SOFTWARE\Wow6432Node\Microsoft\OneDrive" /f >nul 2>&1

   @rem --- Uninstall entry ---
   reg delete "HKCU\Software\Microsoft\Windows\CurrentVersion\Uninstall\OneDriveSetup.exe" /f >nul 2>&1

   @rem --- Autorun / setup leftovers (current user) ---
   reg delete "HKCU\Software\Microsoft\Windows\CurrentVersion\Run" /v OneDrive /f >nul 2>&1
   reg delete "HKCU\Software\Microsoft\Windows\CurrentVersion\Run" /v OneDriveSetup /f >nul 2>&1

   echo   Done.
goto :eof


@rem ===========================================================================
@rem  :PREVENT  -  Block OneDrive from reinstalling / running via group policy
@rem ===========================================================================
:PREVENT
   echo.
   echo === Blocking OneDrive from reinstalling (DisableFileSyncNGSC) ===
   reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\OneDrive" /v DisableFileSyncNGSC /t REG_DWORD /d 1 /f >nul 2>&1
   reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\OneDrive" /v DisableFileSync /t REG_DWORD /d 1 /f >nul 2>&1
   echo   Done.
goto :eof


@rem ===========================================================================
@rem  :forceDelDir "<path>"  -  Take ownership, grant access, and delete a folder
@rem ===========================================================================
:forceDelDir
   if "%~1"=="" goto :eof
   if exist "%~1\" (
      echo   Removing folder: "%~1"
      takeown /f "%~1" /r /d y >nul 2>&1
      icacls "%~1" /grant %ADMINSID%:F /t /c /q >nul 2>&1
      rd /s /q "%~1" >nul 2>&1
      if exist "%~1\" (
         call :colorEcho 0C "    Locked - could not fully remove. Reboot and run again."
         echo.
      )
   )
goto :eof


@rem ===========================================================================
@rem  :forceDelFile "<path>"  -  Take ownership, grant access, and delete a file
@rem ===========================================================================
:forceDelFile
   if "%~1"=="" goto :eof
   if exist "%~1" (
      echo   Removing file: "%~1"
      takeown /f "%~1" >nul 2>&1
      icacls "%~1" /grant %ADMINSID%:F /c /q >nul 2>&1
      del /f /q "%~1" >nul 2>&1
      if exist "%~1" (
         call :colorEcho 0C "    Locked - could not fully remove. Reboot and run again."
         echo.
      )
   )
goto :eof


@rem ===========================================================================
@rem  :colorEcho <hexcolor> "<text>"  -  Print coloured text without a newline
@rem ===========================================================================
:colorEcho
   echo off
   <nul set /p ".=%DEL%" > "%~2"
   findstr /v /a:%1 /R "^$" "%~2" nul
   del "%~2" > nul 2>&1
goto :eof