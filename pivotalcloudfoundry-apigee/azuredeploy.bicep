param location string {
  allowed: [
    'brazilsouth'
    'eastasia'
    'eastus'
    'japaneast'
    'japanwest'
    'northcentralus'
    'northeurope'
    'southcentralus'
    'westeurope'
    'westus'
    'southeastasia'
    'centralus'
    'eastus2'
  ]
  metadata: {
    description: 'Deployment location of where Apigee will be installed'
  }
  default: 'westus'
}
param baseUri string {
  metadata: {
    description: 'base uri for your git repo'
  }
  default: 'https://raw.githubusercontent.com/Azure/azure-quickstart-templates/master/pivotalcloudfoundry-apigee/'
}
param adminUsername string {
  metadata: {
    description: 'User name for the Stack'
  }
}
param adminSSHKey string {
  metadata: {
    description: 'Public SSH key to add to admin user.'
  }
  secure: true
}
param tenantID string {
  metadata: {
    description: 'ID of the tenant. See https://github.com/cloudfoundry-incubator/bosh-azure-cpi-release/blob/master/docs/guidance.md'
  }
  default: 'TENANT-ID'
}
param clientID string {
  metadata: {
    description: 'ID of the client. See https://github.com/cloudfoundry-incubator/bosh-azure-cpi-release/blob/master/docs/guidance.md'
  }
  default: 'CLIENT-ID'
}
param clientSecret string {
  metadata: {
    description: 'secret of the client. See https://github.com/cloudfoundry-incubator/bosh-azure-cpi-release/blob/master/docs/guidance.md'
  }
  secure: true
  default: 'CLIENT-SECRET'
}
param pivnetAPIToken string {
  metadata: {
    description: 'API Token for Pivotal Network'
  }
  default: ''
}
param storageAccountNamePrefixString string {
  metadata: {
    description: 'Unique DNS Name for the Storage Account prefix where the Virtual Machine\'s disks will be placed. It can not be more than 10 characters in length and use numbers and lower-case letters only.'
  }
}
param virtualNetworkName string {
  metadata: {
    description: 'name of the virtual network'
  }
  default: 'boshvnet-crp'
}
param subnetNameForBosh string {
  metadata: {
    description: 'name of the subnet for Bosh'
  }
  default: 'Bosh'
}
param NSGNameForBosh string {
  metadata: {
    description: 'name of the security group for Bosh'
  }
  default: 'BoshSecurityGroup'
}
param subnetNameForCloudFoundry string {
  metadata: {
    description: 'name of the subnet for CloudFoundy'
  }
  default: 'CloudFoundry'
}
param NSGNameForCF string {
  metadata: {
    description: 'name of the security group for CF'
  }
  default: 'CFSecurityGroup'
}
param enableDNSOnDevbox bool {
  allowed: [
    true
    false
  ]
  metadata: {
    description: 'A default DNS will be setup in the devbox if it is true.'
  }
  default: true
}
param apigeeEdge string {
  allowed: [
    'ApigeeRequired'
    'ApigeeNotRequired'
  ]
  metadata: {
    description: 'Select if you want to deploy Apigee Edge Gateway and Apigee Service Broker'
  }
}
param apigeeDeploymentName string {
  metadata: {
    description: 'Deployment Name It can not be more than 10 characters in length and use numbers and lower-case letters only.'
  }
  default: 'apigee'
}
param apigeeAdminPassword string {
  metadata: {
    description: 'Apigee Admin Password'
  }
  secure: true
}
param apigeeAdminEmail string {
  metadata: {
    description: 'email address used as super admin of Apigee deployment'
  }
}
param licenseFileText string {
  metadata: {
    description: 'License file that is given to your organization by Apigee. Paste the content of the file here'
  }
  secure: true
}

var api_version = '2015-06-15'
var extensionName = 'initdevbox'
var newStorageAccountName = concat(storageAccountNamePrefixString, uniqueString(resourceGroup().id, deployment().name))
var vmName = 'myjumpbox${uniqueString(resourceGroup().id, deployment().name)}'
var location_variable = location
var storageAccountType = 'Standard_GRS'
var vmStorageAccountContainerName = 'vhds'
var storageid = resourceId('Microsoft.Storage/storageAccounts', newStorageAccountName)
var virtualNetworkName_variable = virtualNetworkName
var sshKeyPath = '/home/${adminUsername}/.ssh/authorized_keys'
var addressPrefix = '10.0.0.0/16'
var vnetID = resourceId('Microsoft.Network/virtualNetworks', virtualNetworkName_variable)
var subnet1Name = subnetNameForBosh
var subnet1Prefix = '10.0.0.0/24'
var subnet1Ref = '${vnetID}/subnets/${subnet1Name}'
var subnet1NSG = NSGNameForBosh
var subnet2Name = subnetNameForCloudFoundry
var subnet2Prefix = '10.0.16.0/20'
var subnet2NSG = NSGNameForCF
var nicName = vmName
var devboxPrivateIPAddress = '10.0.0.100'
var devboxPublicIPAddressID = resourceId('Microsoft.Network/publicIPAddresses', '${vmName}-devbox')
var imagePublisher = 'Canonical'
var imageOffer = 'UbuntuServer'
var ubuntuOSVersion = '14.04.5-LTS'
var webSessionPassword = uniqueString(adminSSHKey)
var installSize = 'Small'
var vmSize = 'Standard_D2_v2'
var baseUri_variable = baseUri
var apigeeTemplateLink = '${baseUri_variable}Apigee/${apigeeEdge}.json'
var pcfTemplateLink = '${baseUri_variable}pcf/pcfdeploy.json'
var managementPublicIPDNSName = '${apigeeDeploymentName}${uniqueString(resourceGroup().id, deployment().name)}-management'
var managementUI_variable = 'http://${managementPublicIPDNSName}.${toLower(replace(location_variable, ' ', ''))}.cloudapp.azure.com:9000'
var managementDNSName = 'https://${managementPublicIPDNSName}.${toLower(replace(location_variable, ' ', ''))}.cloudapp.azure.com'
var managementDNSAlias = '${managementPublicIPDNSName}.${toLower(replace(location_variable, ' ', ''))}.cloudapp.azure.com'
var managementPublicIPAddressName = 'ApigeeManagementPublicIP-${apigeeDeploymentName}'
var managementPublicIPResourceId = resourceId('Microsoft.Network/publicIPAddresses', managementPublicIPAddressName)
var runtimePublicIPDNSName = '${apigeeDeploymentName}${uniqueString(resourceGroup().id, deployment().name)}-runtime'
var runtimePublicDNSName_variable = 'https://${runtimePublicIPDNSName}.${toLower(replace(location_variable, ' ', ''))}.cloudapp.azure.com'
var runtimePublicDNSAlias = '${runtimePublicIPDNSName}.${toLower(replace(location_variable, ' ', ''))}.cloudapp.azure.com'
var runtimePublicIPAddressName = 'ApigeeRuntimePublicIP-${apigeeDeploymentName}'
var runtimePublicIPResourceId = resourceId('Microsoft.Network/publicIPAddresses', runtimePublicIPAddressName)
var publicIPDNSName = '${apigeeDeploymentName}-management'
var sshKey = adminSSHKey
var sshPrivateKey = ' '
var templateLocation = 'https://raw.githubusercontent.com/sysgain/azurequickstarts/master/PivtoalCloudFoundry-Concourse-Apigee-AzureMetaService/pivotal-P2P/Apigee'
var tshirtSize = 'XSmall'

module pcf 'pcf/pcfdeploy.bicep' = {
  name: 'pcf'
  params: {
    apigeeEdge: apigeeEdge
    managementUI: managementUI_variable
    managementDNSName: managementDNSName
    runtimePublicDNSName: runtimePublicDNSName_variable
    storageAccountNamePrefixString: storageAccountNamePrefixString
    virtualNetworkName: virtualNetworkName
    subnetNameForBosh: subnetNameForBosh
    NSGNameForBosh: NSGNameForBosh
    subnetNameForCloudFoundry: subnetNameForCloudFoundry
    NSGNameForCF: NSGNameForCF
    vmSize: vmSize
    adminUsername: adminUsername
    adminSSHKey: adminSSHKey
    enableDNSOnDevbox: enableDNSOnDevbox
    tenantID: tenantID
    clientID: clientID
    clientSecret: clientSecret
    pivnetAPIToken: pivnetAPIToken
    installSize: installSize
    location: location_variable
    apigeeAdminPassword: apigeeAdminPassword
    apigeeAdminEmail: apigeeAdminEmail
  }
}

module apigeeEdge_resource '<failed to parse [variables(\'apigeeTemplateLink\')]>' = {
  name: 'apigeeEdge'
  params: {
    tshirtSize: tshirtSize
    location: location_variable
    apigeeDeploymentName: apigeeDeploymentName
    adminUsername: adminUsername
    apigeeAdminEmail: apigeeAdminEmail
    apigeeAdminPassword: apigeeAdminPassword
    licenseFileText: licenseFileText
    sshKey: sshKey
    sshPrivateKey: sshPrivateKey
    templateLocation: templateLocation
    managementPublicIPDNSName: managementPublicIPDNSName
    managementUI: managementUI_variable
    managementDNSName: managementDNSName
    managementDNSAlias: managementDNSAlias
    managementPublicIPAddressName: managementPublicIPAddressName
    managementPublicIPResourceId: managementPublicIPResourceId
    runtimePublicIPDNSName: runtimePublicIPDNSName
    runtimePublicDNSName: runtimePublicDNSName_variable
    runtimePublicDNSAlias: runtimePublicDNSAlias
    runtimePublicIPAddressName: runtimePublicIPAddressName
    runtimePublicIPResourceId: runtimePublicIPResourceId
    publicIPDNSName: runtimePublicIPResourceId
  }
}

output managementPublicDNSName string = managementDNSName
output runtimePublicDNSName string = runtimePublicDNSName_variable
output managementUI string = managementUI_variable
output scriptoutput string = reference('pcf').outputs.scriptoutput.value
output ProgressMonitorURL string = reference('pcf').outputs.ProgressMonitorURL.value
output JumpboxFQDN string = reference('pcf').outputs.JumpboxFQDN.value