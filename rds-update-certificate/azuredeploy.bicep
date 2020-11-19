param vaultName string {
  metadata: {
    description: 'Azure Key Vault name where the certificate is stored.'
  }
}
param certificateName string {
  metadata: {
    description: 'Name of the certificate in the Azure Key Vault.'
  }
}
param applicationId string {
  metadata: {
    description: 'AD application Id used to access the certificate.'
  }
}
param applicationPassword string {
  metadata: {
    description: 'AD application password.'
  }
  secure: true
}
param tenantId string {
  metadata: {
    description: 'Tenant Id for whom the Secure Principal account was created.'
  }
}
param brokerVmName string {
  metadata: {
    description: 'Name of the RD Connection Broker VM resource in the deployment (the configure certificates script is executed on this VM).'
  }
  default: 'cb-vm'
}
param existingDomainName string {
  metadata: {
    description: 'The FQDN of the AD domain'
  }
}
param existingAdminUsername string {
  metadata: {
    description: 'Name of the domain account with administrative priviledges in the RDS deployment'
  }
}
param existingAdminPassword string {
  metadata: {
    description: 'The password for the administrator account of the new VM and the domain'
  }
  secure: true
}
param artifactsLocation string {
  metadata: {
    description: 'The base URI where artifacts required by this template are located. When the template is deployed using the accompanying scripts, a private location in the subscription will be used and this value will be automatically generated.'
  }
  default: 'https://raw.githubusercontent.com/Azure/Azure-QuickStart-Templates/master/rds-update-certificate'
}
param artifactsLocationSasToken string {
  metadata: {
    description: 'The sasToken required to access _artifactsLocation.  When the template is deployed using the accompanying scripts, a sasToken will be automatically generated.'
  }
  secure: true
  default: ''
}
param location string {
  metadata: {
    description: 'Location for all resources.'
  }
  default: resourceGroup().location
}

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