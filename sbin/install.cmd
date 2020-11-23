@echo off
setlocal
cd /d "%~dp0"

  whoami /priv | find "SeLoadDriverPrivilege" > nul
  if %ERRORLEVEL% neq 0 (
    exit /b 1
  )

  set "HOME=%USERPROFILE%"
  setx HOME "%HOME%"

  call :INST_CYGWIN
  call :INST_HOME

endlocal
exit /b 0

::----------------------------------------------------------------
:INST_CYGWIN
:: https://cygwin.com/faq.html#faq.setup.cli
setlocal

  set "pkg=procps"
  set "pkg=%pkg%,bash-completion"
  set "pkg=%pkg%,bind-utils"
  set "pkg=%pkg%,whois"
  set "pkg=%pkg%,ping"
  set "pkg=%pkg%,socat"
  set "pkg=%pkg%,nc"
  set "pkg=%pkg%,curl"
  set "pkg=%pkg%,wget"
  set "pkg=%pkg%,fish"
  set "pkg=%pkg%,vim"
  set "pkg=%pkg%,tmux"
  set "pkg=%pkg%,git"
  set "pkg=%pkg%,tig"

  set "filename=setup-x86_64.exe"
  set "url=https://www.cygwin.com/%filename%"

  set "inst_dir=%HOME%\home\opt\cygwin"
  set "cache_dir=%HOME%\home\var\cache\com.cygwin"

  mkdir "%cache_dir%" > nul 2>&1

  PowerShell -Command "& {[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::TLS12; Invoke-WebRequest \"%url%\" -OutFile \"%cache_dir%\%filename%\"}"
::  curl --silent --show-error --create-dirs ^
::    --location "%url%" ^
::    --output "%cache_dir%\%filename%"

  "%cache_dir%\%filename%" ^
    --site "http://ftp.iij.ad.jp/pub/cygwin/" ^
    --local-package-dir "%cache_dir%" ^
    --packages "%pkg%" ^
    --root "%inst_dir%" ^
    --no-admin ^
    --quiet-mode ^
    --no-shortcuts

::  rem TODO: d•¡“o˜^–hŽ~
::  set "win=%HOME:\=/%"
::  set "win=%win: =\040%"
::  set "cyg=/home/%USERNAME: =\040%"
::  "%inst_dir%\bin\echo.exe" "%win% %cyg% ntfs binary,noacl 0 0" >> "%inst_dir%\etc\fstab"

  rem TODO: “ú–{ŒêƒpƒX‘Î‰ž
  assoc .sh="ShellScript"
  ftype ShellScript="%inst_dir%\bin\mintty.exe" "/bin/bash" --login -i -e "%%1"

endlocal
exit /b 0

::----------------------------------------------------------------
:INST_HOME
setlocal

  "%HOME%\home\opt\cygwin\bin\bash.exe" --login -c "( curl --connect-timeout 3 https://raw.githubusercontent.com/tkyz/home/master/sbin/install.sh || curl --connect-timeout 3 https://install.tkyz.jp/ ) | bash"

  reg add "HKEY_CURRENT_USER\Software\Microsoft\Command Processor" ^
    /v AutoRun ^
    /t REG_SZ ^
    /d "\"%%HOME%%\home\.dotfiles\.cmdrc.cmd\"" ^
    /f

::certutil -addstore ROOT "%HOME%\home\sbin\ca.crt"

endlocal
exit /b 0
