@description('Azure Key Vault name where the certificate is stored.')
param vaultName string

@description('Name of the certificate in the Azure Key Vault.')
param certificateName string

@description('AD application Id used to access the certificate.')
param applicationId string

@description('AD application password.')
@secure()
param applicationPassword string

@description('Tenant Id for whom the Secure Principal account was created.')
param tenantId string

@description('Name of the RD Connection Broker VM resource in the deployment (the configure certificates script is executed on this VM).')
param brokerVmName string = 'cb-vm'

@description('The FQDN of the AD domain')
param existingDomainName string

@description('Name of the domain account with administrative priviledges in the RDS deployment')
param existingAdminUsername string

@description('The password for the administrator account of the new VM and the domain')
@secure()
param existingAdminPassword string

@description('The base URI where artifacts required by this template are located. When the template is deployed using the accompanying scripts, a private location in the subscription will be used and this value will be automatically generated.')
param artifactsLocation string = 'https://raw.githubusercontent.com/Azure/Azure-QuickStart-Templates/master/rds-update-certificate'

@description('The sasToken required to access _artifactsLocation.  When the template is deployed using the accompanying scripts, a sasToken will be automatically generated.')
@secure()
param artifactsLocationSasToken string = ''

@description('Location for all resources.')
param location string = resourceGroup().location

var p = {
  appid: ' -appId ${applicationId}'
  apppassword: ' -appPassword ${applicationPassword}'
  tenantid: ' -tenantId ${tenantId}'
  vault: ' -vaultName ${vaultName}'
  secret: ' -secretName ${certificateName}'
  adminUsername: ' -adminUsername ${existingAdminUsername}'
  adminPassword: ' -adminPassword ${existingAdminPassword}'
  adDomainName: ' -adDomainName ${existingDomainName}'
}
var scriptParameters = concat(p.appid, p.apppassword, p.tenantid, p.vault, p.secret, p.adminUsername, p.adminPassword, p.adDomainName)
var scriptFolder = 'Scripts'
var scriptFileName = 'Script.ps1'
var impersonateScript = 'https://gallery.technet.microsoft.com/scriptcenter/Impersonate-a-User-9bfeff82/file/127189/1/New-ImpersonateUser.ps1'
var setPublishedNameScript = 'https://gallery.technet.microsoft.com/Change-published-FQDN-for-2a029b80/file/103829/2/Set-RDPublishedName.ps1'

resource brokerVmName_customscript 'Microsoft.Compute/virtualMachines/extensions@2015-06-15' = {
  name: '${brokerVmName}/customscript'
  location: location
  tags: {
    displayName: 'script'
  }
  properties: {
    publisher: 'Microsoft.Compute'
    type: 'CustomScriptExtension'
    typeHandlerVersion: '1.8'
    autoUpgradeMinorVersion: true
    settings: {
      fileUris: [
        impersonateScript
        setPublishedNameScript
        '${artifactsLocation}/${scriptFolder}/${scriptFileName}${artifactsLocationSasToken}'
      ]
    }
    protectedSettings: {
      commandToExecute: 'powershell -noninteractive -executionpolicy bypass -file ${scriptFileName}${scriptParameters} >> script.log 2>&1'
    }
  }
}