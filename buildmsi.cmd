pushd %~dp0
set PATH=%PATH%;%WINDIR%\Microsoft.NET\Framework\v4.0.30319\
msbuild /t:Clean SketchUpPluginsStandalone.wixproj
msbuild SketchUpPluginsStandalone.wixproj
popd
pause