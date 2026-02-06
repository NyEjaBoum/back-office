@echo off
setlocal enabledelayedexpansion

set "work_dir=C:\Users\NyEja\Documents\itu\mrNaina\back-office"
set "lib=%work_dir%\lib"
set "src=%work_dir%\src"
set "webapp=%work_dir%\src\main\webapp"
set "web_xml=%work_dir%\src\main\webapp\WEB-INF\web.xml"
set "temp=C:\Users\NyEja\Documents\itu\mrNaina\back-office\build"

set "war_name=voiture"
set "web_apps=C:\Program Files\Apache Software Foundation\Tomcat 10.1\webapps"

@REM --- CREATE TEMP FOLDER ---
echo * Deleting temp folder...
if exist "%temp%" (
    rd /s /q "%temp%"
)

echo * Re-Creating temp folder...
mkdir "%temp%\WEB-INF\lib"
mkdir "%temp%\WEB-INF\classes"

:: Copy webapp content (JSP, CSS, etc.) to temp folder
if exist "%webapp%" (
    echo * Copying webapp content to temp folder...
    xcopy /s /y "%webapp%\*.*" "%temp%"
)

:: Copy .jar files in lib to temp/WEB-INF/lib
echo * Copying .jar files in lib to temp/WEB-INF/lib...
xcopy /s /y "%lib%\*.jar" "%temp%\WEB-INF\lib"

echo Done, temp folder created.
echo ---

@REM --- COMPILATION JAVA ---
echo * Compiling java files...
dir /s /B "%src%\*.java" > sources.txt
if not exist sources.txt (
    echo No .java files found in the src directory.
    exit /b 1
)

dir /s /B "%lib%\*.jar" > libs.txt

set "classpath="
for /F "delims=" %%i in (libs.txt) do set "classpath=!classpath!.;%%i;"

where javac >nul 2>nul
if %errorlevel% neq 0 (
    echo Error: javac not found in the PATH.
    exit /b 1
)

javac  -d "%temp%\WEB-INF\classes" -cp "%classpath%" @sources.txt

del sources.txt
del libs.txt

echo Done, java files compiled.
echo ---

@REM --- CREATE WAR FILE ---
echo * Creating "%war_name%.war" file...
cd "%temp%"
jar cf "%work_dir%\%war_name%.war" *
cd %work_dir%

echo Done, "%war_name%.war" file created.

@REM --- DEPLOY WAR FILE ---
echo * Deploying "%war_name%.war" file...
copy /y "%work_dir%\%war_name%.war" "%web_apps%"
echo Done, "%war_name%.war" file deployed.

del /f /q "%work_dir%\%war_name%.war"

echo ---
echo Deployment completed successfully.
echo `(^^_^^)`