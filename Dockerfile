FROM microsoft/iis:windowsservercore

SHELL ["powershell", "-Command", "$ErrorActionPreference = 'Stop'; $ProgressPreference = 'SilentlyContinue';"]

WORKDIR /Users/ContainerAdministrator/Downloads

# Visual C++ 2015 Redistributable
RUN "(New-Object System.Net.WebClient).DownloadFile('http://docker-lab:8081/artifactory/windows-server-local/test/vc_redist.x64.exe', 'c:\tmp\vc_redist.x64.exe')"" \
    # Invoke-WebRequest 'http://docker-lab:8081/artifactory/windows-server-local/test/vc_redist.x64.exe' -OutFile 'vc_redist.x64.exe'; \
    # Start-Process '.\vc_redist.x64.exe' '/install /passive /norestart' -Wait; \
    Start-Process 'c:\tmp\vc_redist.x64.exe' '/install /passive /norestart' -Wait; \
    Remove-Item c:\tmp\vc_redist.x64.exe;

# Install PHP
RUN [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12; \
    $fullurl = 'http://docker-lab:8081/artifactory/windows-server-local/test/php-7.3.4-Win32-VC15-x64.zip'; \
    Invoke-WebRequest -Uri $fullurl -OutFile php.zip; \
    # if ((Get-FileHash php.zip -Algorithm sha1).Hash -ne $sum) {exit 1} ; \
    Expand-Archive -Path php.zip -DestinationPath c:\php; \
    [Environment]::SetEnvironmentVariable('PATH', $env:Path + ';C:\php', [EnvironmentVariableTarget]::Machine); \
    $env:PATH = [Environment]::GetEnvironmentVariable('PATH', [EnvironmentVariableTarget]::Machine); \
    Remove-Item php.zip; \
    php --version;

COPY stage/ /

# Install Composer
RUN Invoke-WebRequest 'https://getcomposer.org/installer' -OutFile 'C:\php\composer-setup.php'; \
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
