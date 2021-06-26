###########################################################################
#
# NAME: Sync Cyberark Account into an application within Idaptive
#
# AUTHOR:  Timo Wember and Jan-Patrick Vöhrs
#
# COMMENT: 
#
# VERSION HISTORY:
# 1.0 26/06/2021 - Initial release
#
###########################################################################

param
(
	[Parameter(Mandatory=$true,HelpMessage="Enter the Idaptive Tenant")]
	[Alias("tenant")]
	[String]$IdaptiveTenant,
	[Parameter(Mandatory=$true,ValueFromPipelineByPropertyName=$true,HelpMessage="Enter the Account, which shall be set for the application.")]
    [string]$IdaptiveServiceAccount,
    [Parameter(Mandatory=$true,ValueFromPipelineByPropertyName=$true,HelpMessage="Enter the Application Id of the idaptive application.")]
    [string]$IdaptiveApplicationId,
    [Parameter(Mandatory=$true,HelpMessage="Enter the Application ID for CyberArk Secrets Management.")]
	[String]$ProviderAppId,  
	[Parameter(Mandatory=$true,HelpMessage="Enter the Account, which connects to the API, which is stored in the Vault.")]
	[String]$IdaptiveAPIAccount
)

Function Get-ApiKey {
    Write-Host "Retrieve ApiKey from Credential provider"
	return (& "C:\Program Files (x86)\CyberArk\ApplicationPasswordSdk\CLIPasswordSDK.exe" GetPassword /p AppDescs.AppID=$ProviderAppId /p Query="Object=$IdaptiveAPIAccount" /o Password)
}

Function Get-ServiceAccount {
    Write-Host "Retrieve Service Account from Credential provider"
	return (& "C:\Program Files (x86)\CyberArk\ApplicationPasswordSdk\CLIPasswordSDK.exe" GetPassword /p AppDescs.AppID=$ProviderAppId /p Query="Object=$IdaptiveServiceAccount" /o Password,PassProps.UserName)
}

Function Get-Token {
param($apiKey)
$GetToken = @{
 "URI"            = "https://$IdaptiveTenant.my.idaptive.app/OAuth2/Token/APITest"
 "Method" = 'Post'
 "Headers" = @{ Authorization = "Basic $apiKey" }
	 "Body" = @{
		"grant_type" = "client_credentials"
		"scope" = "RestAPI"
	}
}

Write-Host "Login with ApiKey to get a token" 
$AccessToken = Invoke-RestMethod @GetToken

$TOKEN = $AccessToken.psobject.properties["access_token"].value
return $TOKEN
}

Function Get-AppInfo {
param($token)
$GetUPData = @{
 "URI"            = "https://$IdaptiveTenant.my.idaptive.app//UPRest/GetAppByKey?appkey=$IdaptiveApplicationId"
 "Method" = 'Post'
 "Headers" = @{ Authorization = "Bearer $token"}
}
Invoke-RestMethod @GetUPData -ContentType "application/json"	
}

Function Update-AppInfo {
param($token,$username,$password)
$URI            = "https://$IdaptiveTenant.my.idaptive.app/SaasManage/UpdateApplicationDE"

$Method = 'Post'

$Headers = @{ 'Authorization' = "Bearer $token"
'X-IDAP-NATIVE-CLIENT' = 'true'
}

$Body =  @{
	ADAttribute = "userprinciplename"
    _RowKey = "$IdaptiveApplicationId"
    Name = "Managed App"
	UserName = "$username"
	Password = "$password"
	UserNameArg = "$username"
	UserNameStrategy = "Fixed"
	UserMapScript = ""
} | ConvertTo-Json
Write-Host "Updating the application" 
Invoke-RestMethod -Verbose -URI $URI -Headers $Headers -Body $Body -Method $Method -ContentType "application/json" 
	
}

$apiKey = Get-ApiKey 
$token = Get-Token -apiKey $apiKey
$appInfo = Get-AppInfo -token $token
$serviceAccount = (Get-ServiceAccount).split(",")
$updateInfo = Update-AppInfo -token $token -username $serviceAccount[1] -password $serviceAccount[0]
$newInfo = Get-AppInfo -token $token
$newInfo

