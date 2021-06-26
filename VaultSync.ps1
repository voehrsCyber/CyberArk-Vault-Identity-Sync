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
param($token)
$URI            = "https://$IdaptiveTenant.my.idaptive.app/SaasManage/UpdateApplicationDE"

$Method = 'Post'

$Headers = @{ 'Authorization' = "Bearer $token"
'X-IDAP-NATIVE-CLIENT' = 'true'
}

$Body =  @{
	ADAttribute = "userprinciplename"
    _RowKey = "$IdaptiveApplicationId"
    Name = "Managed App"
	UserName = "Kommt noch"
	Password = "Aus dem CP"
	UserNameArg = "Kommt noch"
	UserNameStrategy = "Fixed"
	UserMapScript = ""
} | ConvertTo-Json

Invoke-RestMethod -Verbose -URI $URI -Headers $Headers -Body $Body -Method $Method -ContentType "application/json" 
	
}

$token = Get-Token -apiKey 
$appInfo = Get-AppInfo -token $token
$newInfo = Update-AppInfo -token $token
$newInfo = Get-AppInfo -token $token
$newInfo

