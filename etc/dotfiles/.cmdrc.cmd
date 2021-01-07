@echo off

rem インクルードガード
if defined CMDRC goto :eof
set CMDRC=1

rem ----------------------------------------------------------------

::chcp 65001

set "PATH=%PATH%;%HOME%\home\bin"
set "PATH=%PATH%;%HOME%\home\local\bin"

set "CLASSPATH=."
set "CLASSPATH=%CLASSPATH%;.*"
set "CLASSPATH=%CLASSPATH%;%HOME%\home\lib\*"
set "CLASSPATH=%CLASSPATH%;%HOME%\home\local\lib\*"

set "JAVA_HOME=%HOME%\home\opt\openjdk"
set "PATH=%PATH%;%HOME%\home\opt\cygwin\bin"
set "PATH=%PATH%;%JAVA_HOME%\bin"
set "PATH=%PATH%;%HOME%\home\opt\apache-ant\bin"
set "PATH=%PATH%;%HOME%\home\opt\apache-drill\bin"
set "PATH=%PATH%;%HOME%\home\opt\apache-jmeter\bin"
set "PATH=%PATH%;%HOME%\home\opt\apache-maven\bin"
set "PATH=%PATH%;%HOME%\home\opt\mariadb\bin"
set "PATH=%PATH%;%HOME%\home\opt\mysql\bin"
set "PATH=%PATH%;%HOME%\home\opt\pgsql\bin"
