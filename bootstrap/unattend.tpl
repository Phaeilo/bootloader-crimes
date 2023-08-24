cat <<EOF
<?xml version="1.0" encoding="utf-8"?>
<unattend xmlns="urn:schemas-microsoft-com:unattend">
    <settings pass="oobeSystem">
        <component name="Microsoft-Windows-International-Core" processorArchitecture="amd64" publicKeyToken="31bf3856ad364e35" language="neutral" versionScope="nonSxS" xmlns:wcm="http://schemas.microsoft.com/WMIConfig/2002/State" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
            <InputLocale>${UA_INPUT_LOCALE}</InputLocale>
            <SystemLocale>${UA_SYSTEM_LOCALE}</SystemLocale>
            <UILanguage>${UA_UI_LANGUAGE}</UILanguage>
            <UserLocale>${UA_USER_LOCALE}</UserLocale>
        </component>
        <component name="Microsoft-Windows-Shell-Setup" processorArchitecture="amd64" publicKeyToken="31bf3856ad364e35" language="neutral" versionScope="nonSxS" xmlns:wcm="http://schemas.microsoft.com/WMIConfig/2002/State" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
            <AutoLogon>
                <Password>
                    <Value>${UA_PASSWORD}</Value>
                    <PlainText>true</PlainText>
                </Password>
                <Username>${UA_USERNAME}</Username>
                <Enabled>${UA_AUTOLOGON}</Enabled>
            </AutoLogon>
            <FirstLogonCommands>
                <SynchronousCommand wcm:action="add">
                    <CommandLine>powershell -NoLogo -ExecutionPolicy RemoteSigned -File c:\firstlogon.ps1</CommandLine>
                    <Description>Run first logon command</Description>
                    <Order>1</Order>
                    <RequiresUserInput>true</RequiresUserInput>
                </SynchronousCommand>
            </FirstLogonCommands>
            <OOBE>
                <HideEULAPage>true</HideEULAPage>
                <HideWirelessSetupInOOBE>true</HideWirelessSetupInOOBE>
                <HideOnlineAccountScreens>true</HideOnlineAccountScreens>
                <HideOEMRegistrationScreen>true</HideOEMRegistrationScreen>
                <HideLocalAccountScreen>true</HideLocalAccountScreen>
                <NetworkLocation>Other</NetworkLocation>
                <ProtectYourPC>1</ProtectYourPC>
            </OOBE>
            <UserAccounts>
                <LocalAccounts>
                    <LocalAccount wcm:action="add">
                        <Password>
                            <Value>${UA_PASSWORD}</Value>
                            <PlainText>true</PlainText>
                        </Password>
                        <Description>VM User</Description>
                        <DisplayName>${UA_USERNAME}</DisplayName>
                        <Group>Administrators</Group>
                        <Name>${UA_USERNAME}</Name>
                    </LocalAccount>
                </LocalAccounts>
            </UserAccounts>
        </component>
    </settings>
    <settings pass="specialize">
        <component name="Microsoft-Windows-Shell-Setup" processorArchitecture="amd64" publicKeyToken="31bf3856ad364e35" language="neutral" versionScope="nonSxS" xmlns:wcm="http://schemas.microsoft.com/WMIConfig/2002/State" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
            <ComputerName>${UA_HOSTNAME}</ComputerName>
            <RegisteredOrganization>Contonso</RegisteredOrganization>
            <TimeZone>${UA_TIMEZONE}</TimeZone>
        </component>
        <component name="Microsoft-Windows-Security-SPP-UX" processorArchitecture="amd64" publicKeyToken="31bf3856ad364e35" language="neutral" versionScope="nonSxS" xmlns:wcm="http://schemas.microsoft.com/WMIConfig/2002/State" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
            <SkipAutoActivation>true</SkipAutoActivation>
        </component>
    </settings>
</unattend>
EOF
