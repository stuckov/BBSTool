@echo Off
IOinit.exe
shiptool.exe
@if "%ERRORLEVEL%" == "0" goto good
:fail
echo "Please unplug AC adapter."
PAUSE
goto end

:good
shiptool.exe 1

:end


