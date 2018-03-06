@echo Off
IOinit.exe
shiptool.exe
@if "%ERRORLEVEL%" == "0" goto end
:fail
echo "Please plug out AC"
PAUSE
goto end

:end


