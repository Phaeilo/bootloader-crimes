Set-ExecutionPolicy Bypass -Scope Process -Force

[Flags()] enum UsabilityFlags {
	ShowFileExtensions = 1
	ShowHiddenFiles = 2
	ShowSuperHiddenFiles = 4
	LeftAlignTaskbar = 8

	DisableLogonBackground = 32
	DisablePowerTimeouts = 64
	DisableHibernation = 128
	ShowPathInExplorerTitle = 256
	CompactExplorerView = 512
	DisablePasswordExpiration = 1024
	FullContextMenus = 2048
}
$ps_usability = [UsabilityFlags] $ps_usability

[Flags()] enum PrivacyFlags {
	TelemetryLowestLevel = 1
	DisableAppTelemetry = 2
	DisableAdvertisingID = 4

	DisableTailoredExperiences = 16
	DisableInputDataCollection = 32
	DisableSpeechRecognition = 64
	DisableLocationServices = 128
	DisableDefenderTelemetry = 256

	DisableErrorReporting = 1024
	DisableAppLaunchTracking = 2048
	DisableContentDeliveryManager = 4096
	DisableFeedback = 8192
	DisableOnlineSearch = 16384

}
$ps_privacy = [PrivacyFlags] $ps_privacy

[Flags()] enum HardeningFlags {
	InstallUpdates = 1
	DisableSMB1 = 2
	DisableLLMNR = 4
	DisableNetBios = 8
	DisableWPAD = 16
}
$ps_hardening = [HardeningFlags] $ps_hardening

[Flags()] enum BloatFlags {
	DisableOneDrive = 1
	DisableP2PDownloads = 2
	DisableCortana = 4
	DisableXbox = 8
	DisableWidgets = 16
	DisableTeamsIcon = 32
}
$ps_bloat = [BloatFlags] $ps_bloat

function Set-Dword {
	param ($path, $value)
	$tmp = $path.split("\")
	$path = $tmp[0..($tmp.Length-2)] -join "\"
	$name = $tmp[-1]
	if (!(Test-Path -Path $path)) {
		New-Item -Path $path
	}
	Set-ItemProperty -Path $path -Name $name -Value $value -Type DWord
}

$username = [System.Security.Principal.WindowsIdentity]::GetCurrent().Name
$username_short = $username.Split("\")[1]


if ($ps_usability.HasFlag([UsabilityFlags]::ShowFileExtensions)) {
	Set-Dword "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced\HideFileExt" 0
}
if ($ps_usability.HasFlag([UsabilityFlags]::ShowHiddenFiles)) {
	Set-Dword "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced\Hidden" 1
}
if ($ps_usability.HasFlag([UsabilityFlags]::ShowSuperHiddenFiles)) {
	Set-Dword "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced\ShowSuperHidden" 1
}
if ($ps_usability.HasFlag([UsabilityFlags]::ShowPathInExplorerTitle)) {
	Set-Dword "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\CabinetState\FullPath" 1
}
if ($ps_usability.HasFlag([UsabilityFlags]::CompactExplorerView)) {
	Set-Dword "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced\UseCompactMode" 1
}
if ($ps_usability.HasFlag([UsabilityFlags]::LeftAlignTaskbar)) {
	Set-Dword "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced\TaskbarAl" 0
}
if ($ps_usability.HasFlag([UsabilityFlags]::DisableLogonBackground)) {
	Set-Dword "HKLM:\Software\Policies\Microsoft\Windows\System\DisableLogonBackgroundImage" 1
}
if ($ps_usability.HasFlag([UsabilityFlags]::DisablePowerTimeouts)) {
	& "powercfg.exe" @("-x", "-monitor-timeout-ac", "0")
	& "powercfg.exe" @("-x", "-monitor-timeout-dc", "0")
}
if ($ps_usability.HasFlag([UsabilityFlags]::DisableHibernation)) {
	Set-Dword "HKLM:\SYSTEM\CurrentControlSet\Control\Power\HiberFileSizePercent" 0
	Set-Dword -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Power\HibernateEnabled" 0
}
if ($ps_usability.HasFlag([UsabilityFlags]::DisablePasswordExpiration)) {
	Set-LocalUser -Name $username_short -PasswordNeverExpires:$true
}
if ($ps_usability.HasFlag([UsabilityFlags]::FullContextMenus)) {
	New-Item -Path "HKCU:\Software\Classes\CLSID\{86ca1aa0-34aa-4e8b-a509-50c905bae2a2}\InprocServer32"
	Set-ItemProperty -Path "HKCU:\Software\Classes\CLSID\{86ca1aa0-34aa-4e8b-a509-50c905bae2a2}\InprocServer32" -Name "(default)" -Value "" -Type String
}

if ($ps_privacy.HasFlag([PrivacyFlags]::TelemetryLowestLevel)) {
	Set-Dword "HKLM:\Software\Policies\Microsoft\Windows\DataCollection\AllowTelemetry" 0
}
if ($ps_privacy.HasFlag([PrivacyFlags]::DisableAppTelemetry)) {
	# TODO check if still relevant in W11
	Set-Dword "HKLM:\Software\Policies\Microsoft\Windows\AppCompat\AITEnable" 0
	Set-Dword "HKLM:\Software\Policies\Microsoft\Windows\AppCompat\DisableUAR" 1
}
if ($ps_privacy.HasFlag([PrivacyFlags]::DisableAdvertisingID)) {
	Set-Dword "HKLM:\Software\Policies\Microsoft\Windows\AdvertisingInfo\DisabledByGroupPolicy" 1
}
if ($ps_privacy.HasFlag([PrivacyFlags]::DisableTailoredExperiences)) {
	Set-Dword "HKCU:\Software\Policies\Microsoft\Windows\CloudContent\DisableTailoredExperiencesWithDiagnosticData" 1
}
if ($ps_privacy.HasFlag([PrivacyFlags]::DisableInputDataCollection)) {
	Set-Dword "HKCU:\Software\Microsoft\Windows\CurrentVersion\CPSS\Store\InkingAndTypingPersonalization" 0
	Set-Dword "HKCU:\Software\Microsoft\Personalization\Settings\AcceptedPrivacyPolicy" 0
	Set-Dword "HKCU:\Software\Microsoft\InputPersonalization\RestrictImplicitInkCollection" 1
	Set-Dword "HKCU:\Software\Microsoft\InputPersonalization\RestrictImplicitTextCollection" 1

	# TODO needed?
	Set-Dword "HKLM:\Software\Microsoft\Windows\CurrentVersion\Policies\TextInput\AllowLinguisticDataCollection" 0
	Set-Dword "HKCU:\Software\Microsoft\InputPersonalization\TrainedDataStore\HarvestContacts" 0
}
if ($ps_privacy.HasFlag([PrivacyFlags]::DisableFeedback)) {
	# TODO validate in W11
	Set-Dword "HKCU:\Software\Microsoft\Siuf\Rules\NumberOfSIUFInPeriod" 0
	Set-Dword "HKCU:\Software\Microsoft\Siuf\Rules\PeriodInNanoSeconds" 0
}
if ($ps_privacy.HasFlag([PrivacyFlags]::DisableOnlineSearch)) {
	Set-Dword "HKCU:\Software\Policies\Microsoft\Windows\Explorer\DisableSearchBoxSuggestions" 1
}
if ($ps_privacy.HasFlag([PrivacyFlags]::DisableSpeechRecognition)) {
	Set-Dword "HKLM:\Software\Policies\Microsoft\InputPersonalization\AllowInputPersonalization" 0
}
if ($ps_privacy.HasFlag([PrivacyFlags]::DisableLocationServices)) {
	Set-Dword "HKLM:\Software\Policies\Microsoft\FindMyDevice" 0
	Set-Dword "HKLM:\Software\Policies\Microsoft\Windows\LocationAndSensors\DisableLocation" 1
	Set-Dword "HKLM:\Software\Policies\Microsoft\Windows\LocationAndSensors\DisableSensors" 1
}
if ($ps_privacy.HasFlag([PrivacyFlags]::DisableDefenderTelemetry)) {
	Set-Dword "HKLM:\Software\Policies\Microsoft\Windows Defender\Spynet\SpynetReporting" 0
	Set-Dword "HKLM:\Software\Policies\Microsoft\Windows Defender\Spynet\DisableBlockAtFirstSeen" 0
	Set-Dword "HKLM:\Software\Policies\Microsoft\Windows Defender\Spynet\SubmitSamplesConsent" 2
	Set-Dword "HKLM:\Software\Policies\Microsoft\Windows Defender\Reporting\DisableGenericRePorts" 1
}
if ($ps_privacy.HasFlag([PrivacyFlags]::DisableErrorReporting)) {
	Set-Dword "HKLM:\Software\Policies\Microsoft\Windows\Windows Error Reporting\Disabled" 1
}
if ($ps_privacy.HasFlag([PrivacyFlags]::DisableAppLaunchTracking)) {
	Set-Dword "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced\Start_TrackProgs" 0
}
if ($ps_privacy.HasFlag([PrivacyFlags]::DisableContentDeliveryManager)) {
	Set-Dword "HKLM:\Software\Policies\Microsoft\Windows\CurrentVersion\ContentDeliveryManager\ContentDeliveryAllowed" 0
	Set-Dword "HKLM:\Software\Policies\Microsoft\Windows\CurrentVersion\ContentDeliveryManager\FeatureManagementEnabled" 0
	Set-Dword "HKLM:\Software\Policies\Microsoft\Windows\CurrentVersion\ContentDeliveryManager\OemPreInstalledAppsEnabled" 0
	Set-Dword "HKLM:\Software\Policies\Microsoft\Windows\CurrentVersion\ContentDeliveryManager\PreInstalledAppsEnabled" 0
	Set-Dword "HKLM:\Software\Policies\Microsoft\Windows\CurrentVersion\ContentDeliveryManager\PreInstalledAppsEverEnabled" 0
	Set-Dword "HKLM:\Software\Policies\Microsoft\Windows\CurrentVersion\ContentDeliveryManager\RotatingLockScreenEnabled" 0
	Set-Dword "HKLM:\Software\Policies\Microsoft\Windows\CurrentVersion\ContentDeliveryManager\RotatingLockScreenOverlayEnabled" 0
	Set-Dword "HKLM:\Software\Policies\Microsoft\Windows\CurrentVersion\ContentDeliveryManager\SlideshowEnabled" 0
	Set-Dword "HKLM:\Software\Policies\Microsoft\Windows\CurrentVersion\ContentDeliveryManager\SilentInstalledAppsEnabled" 0
	Set-Dword "HKLM:\Software\Policies\Microsoft\Windows\CurrentVersion\ContentDeliveryManager\SoftLandingEnabled" 0
	Set-Dword "HKLM:\Software\Policies\Microsoft\Windows\CurrentVersion\ContentDeliveryManager\SystemPaneSuggestionsEnabled" 0
}

if ($ps_bloat.HasFlag([BloatFlags]::DisableOneDrive)) {
	Set-Dword "HKLM:\Software\Policies\Microsoft\Windows\OneDrive\DisableFileSyncNGSC" 1
}
if ($ps_bloat.HasFlag([BloatFlags]::DisableP2PDownloads)) {
	Set-Dword "HKLM:\Software\Policies\Microsoft\Windows\DeliveryOptimization\DODownloadMode" 0
}
if ($ps_bloat.HasFlag([BloatFlags]::DisableCortana)) {
	Get-AppxPackage -AllUsers Microsoft.549981C3F5F10 | Remove-AppPackage
}
if ($ps_bloat.HasFlag([BloatFlags]::DisableXbox)) {
	Get-AppxPackage -AllUsers Microsoft.Xbox* | Remove-AppPackage
}
if ($ps_bloat.HasFlag([BloatFlags]::DisableWidgets)) {
	Set-Dword "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced\TaskbarDa" 0
}
if ($ps_bloat.HasFlag([BloatFlags]::DisableTeamsIcon)) {
	Set-Dword "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced\TaskbarMn" 0
}

if ($ps_hardening.HasFlag([HardeningFlags]::DisableSMB1)) {
	Set-SmbServerConfiguration -EnableSMB1Protocol $false -Force
	Disable-WindowsOptionalFeature -NoRestart -Online -FeatureName smb1protocol
}
if ($ps_hardening.HasFlag([HardeningFlags]::DisableLLMNR)) {
	Set-Dword "HKLM:\Software\Policies\Microsoft\Windows NT\DNSClient\EnableMulticast" 0
}
if ($ps_hardening.HasFlag([HardeningFlags]::DisableNetBios)) {
	(gwmi win32_networkadapterconfiguration) | %{ $_.settcpipnetbios(2) }
}
if ($ps_hardening.HasFlag([HardeningFlags]::DisableWPAD)) {
	Add-Content -Path "$env:SystemRoot\System32\drivers\etc\hosts" -Value "\n255.255.255.255 wpad\n255.255.255.255 wpad.\n"
}


$ps_choco = $ps_choco.Split("|")
if ($ps_choco.length -gt 0) {
	[System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072
	iex ((New-Object System.Net.WebClient).DownloadString("https://community.chocolatey.org/install.ps1"))

	for ($i = 0; $i -lt $ps_choco.length; $i += 2) {
		$pkg = $ps_choco[$i]
		$ver = $ps_choco[$i+1]
		if ($ver -ne "") {
			choco install $pkg --version $ver -y
		} else {
			choco install $pkg -y
		}
	}
}


if ($ps_hardening.HasFlag([HardeningFlags]::InstallUpdates)) {
	Install-PackageProvider -Name NuGet -Force
	Install-Module -Name PSWindowsUpdate -Force

	$action = New-ScheduledTaskAction -Execute "powershell" -Argument "-NoLogo -ExecutionPolicy RemoteSigned c:\upd.ps1"
	$trigger = New-ScheduledTaskTrigger -AtLogon
	$principal = New-ScheduledTaskPrincipal -UserID $username -LogonType Interactive -RunLevel Highest
	$settings = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries
	$task = New-ScheduledTask -Action $action -Principal $principal -Trigger $trigger -Settings $settings
	Register-ScheduledTask -TaskName "mywinupd" -InputObject $task | Out-Null

@'
Import-Module PSWindowsUpdate
if ($(Get-WindowsUpdate).Count -eq 0) {
	Unregister-ScheduledTask -TaskName "mywinupd" -Confirm:$false
	Remove-Item -Path $MyInvocation.MyCommand.Source
	exit 0
}
Install-WindowsUpdate -AcceptAll -IgnoreReboot
shutdown -r -t 5
'@ > C:\upd.ps1
}


Remove-Item -Path "$env:SystemRoot\System32\Sysprep\unattend.xml"
Remove-Item -Path $MyInvocation.MyCommand.Source
shutdown -r -t 5
