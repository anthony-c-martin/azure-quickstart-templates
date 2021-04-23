@allowed([
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
])
@description('Deployment location of where Apigee will be installed')
param location string = 'westus'

@description('base uri for your git repo')
param baseUri string = 'https://raw.githubusercontent.com/Azure/azure-quickstart-templates/master/pivotalcloudfoundry-apigee/'

@description('User name for the Stack')
param adminUsername string

@description('Public SSH key to add to admin user.')
@secure()
param adminSSHKey string

@description('ID of the tenant. See https://github.com/cloudfoundry-incubator/bosh-azure-cpi-release/blob/master/docs/guidance.md')
param tenantID string = 'TENANT-ID'

@description('ID of the client. See https://github.com/cloudfoundry-incubator/bosh-azure-cpi-release/blob/master/docs/guidance.md')
param clientID string = 'CLIENT-ID'

@description('secret of the client. See https://github.com/cloudfoundry-incubator/bosh-azure-cpi-release/blob/master/docs/guidance.md')
@secure()
param clientSecret string = 'CLIENT-SECRET'

@description('API Token for Pivotal Network')
param pivnetAPIToken string = ''

@description('Unique DNS Name for the Storage Account prefix where the Virtual Machine\'s disks will be placed. It can not be more than 10 characters in length and use numbers and lower-case letters only.')
param storageAccountNamePrefixString string

@description('name of the virtual network')
param virtualNetworkName string = 'boshvnet-crp'

@description('name of the subnet for Bosh')
param subnetNameForBosh string = 'Bosh'

@description('name of the security group for Bosh')
param NSGNameForBosh string = 'BoshSecurityGroup'

@description('name of the subnet for CloudFoundy')
param subnetNameForCloudFoundry string = 'CloudFoundry'

@description('name of the security group for CF')
param NSGNameForCF string = 'CFSecurityGroup'

@allowed([
  true
  false
])
@description('A default DNS will be setup in the devbox if it is true.')
param enableDNSOnDevbox bool = true

@allowed([
  'ApigeeRequired'
  'ApigeeNotRequired'
])
@description('Select if you want to deploy Apigee Edge Gateway and Apigee Service Broker')
param apigeeEdge string

@description('Deployment Name It can not be more than 10 characters in length and use numbers and lower-case letters only.')
param apigeeDeploymentName string = 'apigee'

@description('Apigee Admin Password')
@secure()
param apigeeAdminPassword string

@description('email address used as super admin of Apigee deployment')
param apigeeAdminEmail string

@description('License file that is given to your organization by Apigee. Paste the content of the file here')
@secure()
param licenseFileText string

var api_version = '2015-06-15'
var extensionName = 'initdevbox'
var newStorageAccountName = concat(storageAccountNamePrefixString, uniqueString(resourceGroup().id, deployment().name))
var vmName = 'myjumpbox${uniqueString(resourceGroup().id, deployment().name)}'
var location_var = location
var storageAccountType = 'Standard_GRS'
var vmStorageAccountContainerName = 'vhds'
var storageid = resourceId('Microsoft.Storage/storageAccounts', newStorageAccountName)
var virtualNetworkName_var = virtualNetworkName
var sshKeyPath = '/home/${adminUsername}/.ssh/authorized_keys'
var addressPrefix = '10.0.0.0/16'
var vnetID = resourceId('Microsoft.Network/virtualNetworks', virtualNetworkName_var)
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
var baseUri_var = baseUri
var apigeeTemplateLink = '${baseUri_var}Apigee/${apigeeEdge}.json'
var pcfTemplateLink = '${baseUri_var}pcf/pcfdeploy.json'
var managementPublicIPDNSName = '${apigeeDeploymentName}${uniqueString(resourceGroup().id, deployment().name)}-management'
var managementUI = 'http://${managementPublicIPDNSName}.${toLower(replace(location_var, ' ', ''))}.cloudapp.azure.com:9000'
var managementDNSName = 'https://${managementPublicIPDNSName}.${toLower(replace(location_var, ' ', ''))}.cloudapp.azure.com'
var managementDNSAlias = '${managementPublicIPDNSName}.${toLower(replace(location_var, ' ', ''))}.cloudapp.azure.com'
var managementPublicIPAddressName = 'ApigeeManagementPublicIP-${apigeeDeploymentName}'
var managementPublicIPResourceId = resourceId('Microsoft.Network/publicIPAddresses', managementPublicIPAddressName)
var runtimePublicIPDNSName = '${apigeeDeploymentName}${uniqueString(resourceGroup().id, deployment().name)}-runtime'
var runtimePublicDNSName = 'https://${runtimePublicIPDNSName}.${toLower(replace(location_var, ' ', ''))}.cloudapp.azure.com'
var runtimePublicDNSAlias = '${runtimePublicIPDNSName}.${toLower(replace(location_var, ' ', ''))}.cloudapp.azure.com'
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
    managementUI: managementUI
    managementDNSName: managementDNSName
    runtimePublicDNSName: runtimePublicDNSName
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
    location: location_var
    apigeeAdminPassword: apigeeAdminPassword
    apigeeAdminEmail: apigeeAdminEmail
  }
}

module apigeeEdge_resource '?' /*TODO: replace with correct path to [variables('apigeeTemplateLink')]*/ = {
  name: 'apigeeEdge'
  params: {
    tshirtSize: tshirtSize
    location: location_var
    apigeeDeploymentName: apigeeDeploymentName
    adminUsername: adminUsername
    apigeeAdminEmail: apigeeAdminEmail
    apigeeAdminPassword: apigeeAdminPassword
    licenseFileText: licenseFileText
    sshKey: sshKey
    sshPrivateKey: sshPrivateKey
    templateLocation: templateLocation
    managementPublicIPDNSName: managementPublicIPDNSName
    managementUI: managementUI
    managementDNSName: managementDNSName
    managementDNSAlias: managementDNSAlias
    managementPublicIPAddressName: managementPublicIPAddressName
    managementPublicIPResourceId: managementPublicIPResourceId
    runtimePublicIPDNSName: runtimePublicIPDNSName
    runtimePublicDNSName: runtimePublicDNSName
    runtimePublicDNSAlias: runtimePublicDNSAlias
    runtimePublicIPAddressName: runtimePublicIPAddressName
    runtimePublicIPResourceId: runtimePublicIPResourceId
    publicIPDNSName: runtimePublicIPResourceId
  }
}

output managementPublicDNSName string = managementDNSName
output runtimePublicDNSName string = runtimePublicDNSName
output managementUI string = managementUI
output scriptoutput string = reference('pcf').outputs.scriptoutput.value
output ProgressMonitorURL string = reference('pcf').outputs.ProgressMonitorURL.value
output JumpboxFQDN string = reference('pcf').outputs.JumpboxFQDN.value