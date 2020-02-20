FROM mcr.microsoft.com/windows/servercore/iis:windowsservercore-ltsc2019

SHELL ["powershell", "-Command", "$ErrorActionPreference = 'Stop'; $ProgressPreference = 'SilentlyContinue';"]

WORKDIR /Users/ContainerAdministrator/Downloads

# Visual C++ 2015 Redistributable
RUN (new-object System.Net.WebClient).DownloadFile('http://10.20.1.4:8081/artifactory/windows-server-local/test/vc_redist.x64.exe','vc_redist.x64.exe'); \
    Start-Process '.\vc_redist.x64.exe' '/install /passive /norestart' -Wait; \
    Remove-Item vc_redist.x64.exe;

# Install PHP
RUN (new-object System.Net.WebClient).DownloadFile('http://10.20.1.4:8081/artifactory/windows-server-local/test/php-7.4.3-Win32-vc15-x64.zip','php.zip'); \
    Expand-Archive -Path php.zip -DestinationPath c:\php\ -Force; \
    [Environment]::SetEnvironmentVariable('PATH', $env:Path + ';C:\php', [EnvironmentVariableTarget]::Machine); \
    $env:PATH = [Environment]::GetEnvironmentVariable('PATH', [EnvironmentVariableTarget]::Machine); \
    Remove-Item php.zip; \
    php --version;

COPY stage/ /

RUN (new-object System.Net.WebClient).DownloadFile('http://10.20.1.4:8081/artifactory/windows-server-local/test/composer-setup.php ','C:\php\composer-setup.php'); \
    cd 'C:\php'; \
    php composer-setup.php; \
    # mv composer.phar C:\php; \
    Remove-Item composer-setup.php; \
    composer about;

# Configure IIS
COPY config/ ./
RUN .\configure_iis.ps1; \
    Remove-Item configure_iis.ps1;

# Expose the Site
RUN New-WebSite -Name 'www' -PhysicalPath C:\www -Port 80

# Change working directory to web root
WORKDIR /www
