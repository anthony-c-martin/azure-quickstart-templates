@allowed([
  '2016-Datacenter'
  '2019-Datacenter'
  'Linux CentOS'
])
@description('Operating System to install')
param OS string = '2016-Datacenter'

@allowed([
  2
  3
  4
])
@description('number of VM nodes to create')
param clusterNodes int = 2

@description('the VM size for all nodes')
param vmSize string = 'Standard_A2_v2'

@description('User for the Virtual Machines.')
param adminUser string

@description('Password for the Virtual Machines.')
@secure()
param adminPassword string

@description('Public VIP dns label. VIP fqdn will be like <vipdnslabel>.<location>.cloudapp.azure.com and must be globally unique.')
param VIPDnsLabel string = '${uniqueString(resourceGroup().id)}vip'

@description('Public VM IP dns label prefix. VM fqdn will be like <vmdnsprefix>vm<i>.<location>.cloudapp.azure.com and must be unique.')
param VMDnsPrefix string = uniqueString(resourceGroup().id)

@allowed([
  'yes'
  'no'
])
@description('install azure powershell module (optional)')
param azurePwsh string = 'no'

@allowed([
  'centralus'
  'eastus2'
  'francecentral'
  'northeurope'
  'southeastasia'
  'westeurope'
  'westus2'
])
@description('resources location (region must support Availability Zones)')
param location string

@description('url of SafeKit package (optional, default to the appropriate Evidian website url).')
param safekitFileUri string = 'default'

@description('base URL of deployment resources (template,subtemplates,scripts)')
param artifactsLocation string = 'https://raw.githubusercontent.com/Azure/azure-quickstart-templates/master/safekit-cluster-farm/'

@description('The sasToken required to access _artifactsLocation.  When the template is deployed using the accompanying scripts, a sasToken will be automatically generated. Use the defaultValue if the staging location is not secured.')
@secure()
param artifactsLocationSasToken string = ''

var clusternodes_var = clusterNodes
var vmname = 'VM1'
var moduleName = 'farm'
var cltemplate = uri(artifactsLocation, 'nestedtemplates/cluster.json')
var ostype = ((OS == 'Linux CentOS') ? 'linux' : 'windows')
var skcfgmoduletemplate = concat(uri(artifactsLocation, 'nestedtemplates/cfgFarm.json'), artifactsLocationSasToken)
var safekitpkgUrl = {
  windows: 'https://support.evidian.com/solutions/downloads/safekit/cloud/platforms/windows/current_versions/safekit_cloud.msi'
  linux: 'https://support.evidian.com/solutions/downloads/safekit/cloud/platforms/linux/current_versions/safekit_cloud.bin'
}
var farmUrl = {
  windows: 'https://support.evidian.com/solutions/downloads/safekit/cloud/application_modules/windows/farm.safe'
  linux: 'https://support.evidian.com/solutions/downloads/safekit/cloud/application_modules/linux/farm.safe'
}

module safekitCluster 'nestedtemplates/cluster.bicep' = {
  name: 'safekitCluster'
  params: {
    OS: OS
    clusterNodes: clusternodes_var
    vmSize: vmSize
    adminUser: adminUser
    adminPassword: adminPassword
    moduleUrl: farmUrl[ostype]
    moduleName: moduleName
    VIPDnsLabel: VIPDnsLabel
    VMDnsPrefix: VMDnsPrefix
    Loadbalancer: 'External'
    location: location
    safekitFileUri: ((safekitFileUri == 'default') ? safekitpkgUrl[ostype] : safekitFileUri)
    '_artifactsLocation': artifactsLocation
    '_artifactsLocationSasToken': artifactsLocationSasToken
  }
}

module safekitModuleConfig 'nestedtemplates/cfgFarm.bicep' = {
  name: 'safekitModuleConfig'
  params: {
    vmname: vmname
    ostype: ostype
    moduleName: moduleName
    location: location
    '_artifactsLocation': artifactsLocation
    '_artifactsLocationSasToken': artifactsLocationSasToken
  }
  dependsOn: [
    safekitCluster
  ]
}

output FIRST_GET_THE_CREDENTIALS string = reference('safekitCluster').outputs.Credentials Url.value
output LOGIN_TO_GET_THE_CREDENTIALS string = reference('safekitCluster').outputs.Credentials Url Login.value
output START_THE_CONSOLE string = '${reference('safekitCluster').outputs.Console Url.value}?firewallDialog=false'
output TEST_THE_VIRTUAL_IP string = reference('safekitCluster').outputs.Mosaic URL.value
output ADMINUSER string = adminUser
output VM1 string = reference('safekitCluster').outputs.fqdn.value