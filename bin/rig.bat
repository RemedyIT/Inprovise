@echo off
if not "%~f0" == "~f0" goto WinNT
ruby -Sx "%0" %1 %2 %3 %4 %5 %6 %7 %8 %9
goto endofruby
:WinNT
if not exist "%~d0%~p0ruby" goto rubyfrompath
if exist "%~d0%~p0ruby" "%~d0%~p0ruby" -x "%~dp0\rig" %*
goto endofruby
:rubyfrompath
ruby -x "%~dp0\rig" %*
goto endofruby
#!/bin/ruby
#
Kernel.system('ruby', '-Sx', File.join(File.dirname(__FILE__), FILE.basename(__FILE__, '.*')), *ARGV)
:endofruby
