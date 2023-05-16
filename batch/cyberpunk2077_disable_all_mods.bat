@ECHO OFF
setlocal enabledelayedexpansion

REM helper script for troubleshooting: https://wiki.redmodding.org/cyberpunk-2077-modding/help/users-troubleshooting
REM Up-to-date with 1.6.2_hotfix after the DLSS patch

REM for indenting user output
set "tab=    "
set separator=--------------------------------------------------------------------------------------

REM =================================================================
REM Make sure that we're in the cyberpunk directory
REM yell at user if we aren't
REM =================================================================

if "%~1" == "" (
  pushd %~dp0
  set "CYBERPUNKDIR=!CD!"
  popd
) else (
  set param=%*
  :: remove potential quotes from string
  set param=!param:"=!
  set "CYBERPUNKDIR=!param!"
)


REM make sure that we're inside the cyberpunk dir
if not exist "!CYBERPUNKDIR!\REDprelauncher.exe" (
  echo.
  echo !separator!
  echo !tab!File not found !CYBERPUNKDIR!\REDprelauncher.exe
  echo !tab!Either start this script in your Cyberpunk 2077 folder,
  echo !tab!or drag and drop it from Windows Explorer on this file.
  echo.
  echo !tab!Aborting...
  echo !separator!
  pause
  goto :eof
)


REM =================================================================
REM the files that we want to remove/rename
REM =================================================================

set "rename_paths=archive\pc\mod mods bin\x64\plugins r6\scripts r6\tweaks red4ext engine\tools"
set "delete_paths=bin\x64\d3d11.dll bin\x64\global.ini bin\x64\powrprof.dll bin\x64\winmm.dll bin\x64\version.dll engine\config engine\tools r6\cache r6\config r6\inputs V2077"


REM =================================================================
REM check for existing backups
REM =================================================================
for %%P in (%rename_paths%) do (
  set "absolute_path=!CYBERPUNKDIR!\%%~P"
    if exist "!absolute_path!" (
      set "new_path=!absolute_path!_"
      call :delete_file_or_folder_with_prompt "!new_path!"
    ) 
)

REM =================================================================
REM do the actual work: rename / delete files and folders
REM =================================================================

REM pop them in an array for proper iterating
set numRenamedFiles=0
set "renamed_paths_list="

for %%P in (%rename_paths%) do (
  set "absolute_path=!CYBERPUNKDIR!\%%~P"
    if exist "!absolute_path!" (
        set "new_path=!absolute_path!_"
        if exist "!new_path!" (
          xcopy /s /q /y "!absolute_path!" "!new_path!"
          call :delete_file_or_folder_without_prompt "!absolute_path!"
          mkdir "!absolute_path!"
        ) else (
          for %%i in ("!absolute_path!") do set "foldername=%%~ni"
          ren "!absolute_path!" "!foldername!_"
          mkdir "!absolute_path!"
        )
        
        REM append it to array so we can print it later
        set /A numRenamedFiles+=1
        set renamed_paths_list[!numRenamedFiles!]=!new_path!
    )
)

REM pop them in an array for proper iterating
set numDeletedFiles=0
set "deleted_paths_list="

for %%P in (!delete_paths!) do (  
    set "absolute_path=!CYBERPUNKDIR!\%%~P"
    if exist "!absolute_path!" (
      REM append it to array so we can print it later
      set /A numDeletedFiles+=1
      set deleted_paths_list[!numDeletedFiles!]=!absolute_path!
      call :delete_file_or_folder_without_prompt "!absolute_path!"    
    )    
)

REM =================================================================
REM show user feedback
REM =================================================================

if (!numRenamedFiles!) gtr (0) (
  echo.
  echo Your installation has been reset. Your mods and settings have been backed up:
  echo !separator!
  for /L %%i in (1,1,%numRenamedFiles%) do echo !tab!!renamed_paths_list[%%i]!
  echo.
) else (
  echo.
  echo !separator!
  echo !tab!Your installation has been reset.
)


if (!numDeletedFiles!) gtr (0) (
  echo The following files were deleted:
  echo !separator!
  for /L %%i in (1,1,%numDeletedFiles%) do echo !tab!!deleted_paths_list[%%i]!
  echo.
)

echo !separator!
echo !tab!Please verify your game files now.
echo !separator!
echo.
pause

goto :eof


:delete_file_or_folder_with_prompt
  set "file=%*"
  if not exist !file! goto :eof

  set /p user_input="!file! already exists, earlier files will be overwritten. You can type [DELETE] to delete it now, or press return to proceed    "
  if /i not "%user_input%"=="DELETE" goto :eof

  call :delete_file_or_folder_without_prompt !file!
  
  goto :eof
  
:delete_file_or_folder_without_prompt
  set "file=%*"
  if not exist !file! goto :eof
  
  if exist !file!\* (
    rd /s /q !file!
  ) else (      
   del /f /q !file!
  )
  goto :eof  

endlocal
