@description('The base URI where artifacts required by this template are located. When the template is deployed using the accompanying scripts, a private location in the subscription will be used and this value will be automatically generated.')
param artifactsLocation string = 'https://raw.githubusercontent.com/Azure/azure-quickstart-templates/master/moodle-scalable-cluster-ubuntu/'

@description('The sasToken required to access _artifactsLocation.  When the template is deployed using the accompanying scripts, a sasToken will be automatically generated.')
@secure()
param artifactsLocationSasToken string = ''

@description('Switch to process or bypass all scripts/extensions')
param applyScriptsSwitch bool = true

@description('Switch to configure AzureBackup and enlist VM\'s')
param azureBackupSwitch bool = false

@description('Switch to deploy a virtual network gateway or not')
param vnetGwDeploySwitch bool = false

@description('Switch to install Moodle Office 365 plugins')
param installO365pluginsSwitch bool = false

@description('Switch to install Moodle ElasticSearch plugins & VMs')
param installElasticSearchSwitch bool = false

@allowed([
  'Standard_LRS'
  'Standard_GRS'
  'Standard_ZRS'
])
@description('Storage Account type')
param storageAccountType string = 'Standard_LRS'

@allowed([
  'mysql'
  'postgres'
])
@description('Database type')
param dbServerType string = 'mysql'

@allowed([
  'gluster'
  'nfs'
])
@description('File server type: GlusterFS, Azure Files (CIFS)--disabled due to too slow perf, NFS--not highly available')
param fileServerType string = 'gluster'

@allowed([
  'apache'
  'nginx'
])
@description('Web server type')
param webServerType string = 'apache'

@description('VM size for the controller node')
param controllerVmSku string = 'Standard_DS1_v2'

@description('VM size for autoscaled nodes')
param autoscaleVmSku string = 'Standard_DS2_v2'

@description('Maximum number of autoscaled nodes')
param autoscaleVmCount int = 10

@description('VM size for the elastic search nodes')
param elasticVmSku string = 'Standard_DS2_v2'

@description('Database firewall rule name')
param firewallRuleName string = 'open-to-the-world'

@allowed([
  'GatewaySubnet'
])
@description('name for Virtual network gateway subnet')
param gatewaySubnet string = 'GatewaySubnet'

@allowed([
  'Vpn'
  'ER'
])
@description('Virtual network gateway type')
param gatewayType string = 'Vpn'

@description('VM size for the gluster nodes')
param glusterVmSku string = 'Standard_DS2_v2'

@description('Size per disk for gluster nodes or nfs server')
param fileServerDiskSize int = 127

@minValue(2)
@maxValue(8)
@description('Number of disks in raid0 per gluster node or nfs server')
param fileServerDiskCount int = 4

@allowed([
  'MOODLE_34_STABLE'
  'MOODLE_33_STABLE'
  'MOODLE_32_STABLE'
  'MOODLE_31_STABLE'
  'MOODLE_30_STABLE'
  'MOODLE_29_STABLE'
])
@description('The Moodle version you want to install.')
param moodleVersion string = 'MOODLE_34_STABLE'

@description('Database admin username')
param dbLogin string = 'dbadmin'

@description('URL for Moodle site')
param siteURL string = 'www.example.org'

@description('MySql/Postgresql database trasaction units')
param skuCapacityDTU int

@description('MySql/Postgresql sku family')
param skuFamily string = 'SkuFamily'

@description('MySql/Postgresql sku name')
param skuName string

@description('MySql/Postgresql sku size in MB. For Basic tier, minimum 50GB, increased by 125GB up to 1TB. For Standard tier, minimum 125GB, increase by 125GB up to 1TB')
param skuSizeMB int = 51200

@allowed([
  'Basic'
  'Standard'
])
@description('MySql/Postgresql sku tier')
param skuTier string = 'Basic'

@description('ssh public key')
param sshPublicKey string

@description('ssh user name')
param sshUsername string = 'azureadmin'

@allowed([
  'Disabled'
  'Enabled'
])
@description('MySql/Postgresql SSL connection')
param sslEnforcement string = 'Disabled'

@allowed([
  '9.5'
  '9.6'
])
@description('Postgresql version')
param postgresVersion string = '9.6'

@allowed([
  '5.6'
  '5.7'
])
@description('Mysql version')
param mysqlVersion string = '5.7'

@description('Address range for the Moodle virtual network - presumed /16 - further subneting during vnet creation')
param vNetAddressSpace string = '172.31.0.0'

@allowed([
  'RouteBased'
  'PolicyBased'
])
@description('Virtual network gateway vpn type')
param vpnType string = 'RouteBased'

@description('Location for all resources.')
param location string = resourceGroup().location

var documentation01 = 'This main-template calls multiple sub-templates to create the moodle system'
var documentation02 = '    recoveryservices0   - dummy template (see next statement)'
var documentation03 = '    recoveryservices1   - creates a recovery vault that will be subsequently used by the VM Backup - a paramter swtich controls whethe is is called or bypassed'
var documentation04 = '    redis               - creates a redis cache'
var documentation05 = '    postgres / mysql  - creates a postgresql / mysql server'
var documentation06 = '    vnet                - creates a virtual network with three subnets'
var documentation07 = '    elastic             - creates a elastic search cluster on a vm farm'
var documentation08 = '    gluster             - creates a gluster file system on a vm farm'
var documentation09 = '    webvmss             - creates a vm scale set'
var documentation10 = '    controller          - creates a jumpbox and deploys code'
var documentation11 = 'GlusterFS Sizing guidance'
var moodleCommon = {
  baseTemplateUrl: '${artifactsLocation}nested/'
  scriptLocation: '${artifactsLocation}scripts/'
  artifactsSasToken: artifactsLocationSasToken
  applyScriptsSwitch: applyScriptsSwitch
  autoscaleVmCount: autoscaleVmCount
  autoscaleVmSku: autoscaleVmSku
  azureBackupSwitch: azureBackupSwitch
  commonFunctionsScriptUri: '${artifactsLocation}scripts/helper_functions.sh${artifactsLocationSasToken}'
  controllerVmSku: controllerVmSku
  dbLogin: dbLogin
  dbLoginPassword: '${substring(uniqueString(resourceGroup().id, deployment().name), 2, 11)}*7${toUpper('pfiwb')}'
  dbServerType: dbServerType
  dbUsername: '${dbLogin}@${dbServerType}-${resourceprefix}'
  elasticVmSku: elasticVmSku
  elasticAvailabilitySetName: 'elastic-avset-${resourceprefix}'
  elasticClusterName: 'es-cluster-${resourceprefix}'
  elasticNicName1: 'elastic-vm-nic-01-${resourceprefix}'
  elasticNicName2: 'elastic-vm-nic-02-${resourceprefix}'
  elasticNicName3: 'elastic-vm-nic-03-${resourceprefix}'
  elasticScriptFilename: 'install_elastic.sh'
  elasticVm1IP: '${octets[0]}.${octets[1]}.${string((int(octets[2]) + 4))}.20'
  elasticVm2IP: '${octets[0]}.${octets[1]}.${string((int(octets[2]) + 4))}.21'
  elasticVm3IP: '${octets[0]}.${octets[1]}.${string((int(octets[2]) + 4))}.22'
  elasticVmName: 'elastic-vm-${resourceprefix}'
  elasticVmName1: 'elastic-vm-01-${resourceprefix}'
  elasticVmName2: 'elastic-vm-02-${resourceprefix}'
  elasticVmName3: 'elastic-vm-03-${resourceprefix}'
  extBeName: 'lb-backend-${resourceprefix}'
  extFeName: 'lb-frontend-${resourceprefix}'
  extNatPool: 'lb-natpool-${resourceprefix}'
  extProbe: 'lb-probe-${resourceprefix}'
  fileServerDiskCount: fileServerDiskCount
  fileServerDiskSize: fileServerDiskSize
  fileServerType: fileServerType
  firewallRuleName: firewallRuleName
  gatewayName: 'vnet-gateway-${resourceprefix}'
  gatewayPublicIPName: 'vnet-gw-ip-${resourceprefix}'
  gatewaySubnet: gatewaySubnet
  gatewaySubnetPrefix: '${octets[0]}.${octets[1]}.${string((int(octets[2]) + 2))}'
  gatewaySubnetRange: '${octets[0]}.${octets[1]}.${string((int(octets[2]) + 2))}.0/24'
  gatewayType: gatewayType
  gfsNameRoot: 'gluster-vm-${resourceprefix}'
  gfxAvailabilitySetName: 'gluster-avset-${resourceprefix}'
  glusterScriptFilename: 'install_gluster.sh'
  glusterVmCount: 2
  glusterVmSku: glusterVmSku
  installO365pluginsSwitch: installO365pluginsSwitch
  installElasticSearchSwitch: installElasticSearchSwitch
  jboxNicName: 'jumpbox-vm-nic-${resourceprefix}'
  jboxNsgName: 'jumpbox-nsg-${resourceprefix}'
  jboxPipName: 'jumpbox-pubip-${resourceprefix}'
  jboxVmName: 'jumpbox-vm-${resourceprefix}'
  lbDns: 'lb-${resourceprefix}.${location}.cloudapp.azure.com'
  lbName: 'lb-${resourceprefix}'
  lbPipName: 'lb-pubip-${resourceprefix}'
  moodleAdminPass: '${toUpper('xl')}${substring(uniqueString(resourceGroup().id, deployment().name), 6, 7)},1*8'
  moodleDbName: 'moodle'
  moodleDbPass: '9#36^${substring(uniqueString(resourceGroup().id, deployment().name), 5, 8)}${toUpper('ercq')}'
  moodleDbUser: 'moodle'
  moodleDbUserAzure: 'moodle@${dbServerType}-${resourceprefix}'
  moodleInstallScriptFilename: 'install_moodle.sh'
  moodleVersion: moodleVersion
  mysqlVersion: mysqlVersion
  osType: {
    offer: 'UbuntuServer'
    publisher: 'Canonical'
    sku: '16.04-LTS'
    version: 'latest'
  }
  policyName: 'policy-${resourceprefix}'
  postgresVersion: postgresVersion
  redisCacheName: 'redis-${resourceprefix}'
  redisDns: 'redis-${resourceprefix}.redis.cache.windows.net'
  resourcesPrefix: resourceprefix
  serverName: '${dbServerType}-${resourceprefix}'
  siteURL: ((empty(siteURL) || (siteURL == 'www.example.org')) ? 'lb-${resourceprefix}.${location}.cloudapp.azure.com' : siteURL)
  skuCapacityDTU: skuCapacityDTU
  skuFamily: skuFamily
  skuName: skuName
  skuSizeMB: skuSizeMB
  skuTier: skuTier
  sshPublicKey: sshPublicKey
  sshUsername: sshUsername
  sslEnforcement: sslEnforcement
  storageAccountName: toLower('abs${resourceprefix}')
  storageAccountType: storageAccountType
  subnetElastic: 'elastic-subnet-${resourceprefix}'
  subnetElasticPrefix: '${octets[0]}.${octets[1]}.${string((int(octets[2]) + 4))}'
  subnetElasticRange: '${octets[0]}.${octets[1]}.${string((int(octets[2]) + 4))}.0/24'
  subnetRedis: 'redis-subnet-${resourceprefix}'
  subnetRedisPrefix: '${octets[0]}.${octets[1]}.${string((int(octets[2]) + 3))}'
  subnetRedisRange: '${octets[0]}.${octets[1]}.${string((int(octets[2]) + 3))}.0/24'
  subnetSan: 'san-subnet-${resourceprefix}'
  subnetSanPrefix: '${octets[0]}.${octets[1]}.${string((int(octets[2]) + 1))}'
  subnetSanRange: '${octets[0]}.${octets[1]}.${string((int(octets[2]) + 1))}.0/24'
  subnetWeb: 'web-subnet-${resourceprefix}'
  subnetWebPrefix: '${octets[0]}.${octets[1]}.${string((int(octets[2]) + 0))}'
  subnetWebRange: '${octets[0]}.${octets[1]}.${string((int(octets[2]) + 0))}.0/24'
  vNetAddressSpace: vNetAddressSpace
  vaultName: 'vault-${resourceprefix}'
  vmssName: 'vmss-${resourceprefix}'
  vmssdStorageAccounttName: 'vmss${uniqueString(resourceGroup().id)}'
  vnetGwDeploySwitch: vnetGwDeploySwitch
  vnetName: 'vnet-${resourceprefix}'
  vpnType: vpnType
  webServerSetupScriptFilename: 'setup_webserver.sh'
  webServerType: webServerType
}
var octets = split(vNetAddressSpace, '.')
var resourceprefix = substring(uniqueString(resourceGroup().id, deployment().name), 3, 6)

module pid_738e3eec_68d4_4667_8377_c05c77c21f1b './nested_pid_738e3eec_68d4_4667_8377_c05c77c21f1b.bicep' = {
  name: 'pid-738e3eec-68d4-4667-8377-c05c77c21f1b'
  params: {}
}

module dbTemplate '?' /*TODO: replace with correct path to [concat(variables('moodleCommon').baseTemplateUrl, parameters('dbServerType'), '.json', parameters('_artifactsLocationSasToken'))]*/ = {
  name: 'dbTemplate'
  params: {
    moodleCommon: moodleCommon
  }
}

module recoveryTemplate '?' /*TODO: replace with correct path to [concat(variables('moodleCommon').baseTemplateUrl,'recoveryservices.json',parameters('_artifactsLocationSasToken'))]*/ = if (azureBackupSwitch) {
  name: 'recoveryTemplate'
  params: {
    moodleCommon: moodleCommon
  }
}

module redisTemplate '?' /*TODO: replace with correct path to [concat(variables('moodleCommon').baseTemplateUrl,'redis.json',parameters('_artifactsLocationSasToken'))]*/ = {
  name: 'redisTemplate'
  params: {
    moodleCommon: moodleCommon
  }
  dependsOn: [
    networkTemplate
  ]
}

module networkTemplate '?' /*TODO: replace with correct path to [concat(variables('moodleCommon').baseTemplateUrl,'network.json',parameters('_artifactsLocationSasToken'))]*/ = {
  name: 'networkTemplate'
  params: {
    moodleCommon: moodleCommon
  }
}

module elasticTemplate '?' /*TODO: replace with correct path to [concat(variables('moodleCommon').baseTemplateUrl,'elastic.json',parameters('_artifactsLocationSasToken'))]*/ = if (installElasticSearchSwitch) {
  name: 'elasticTemplate'
  params: {
    moodleCommon: moodleCommon
  }
  dependsOn: [
    networkTemplate
    recoveryTemplate
  ]
}

module glusterTemplate '?' /*TODO: replace with correct path to [concat(variables('moodleCommon').baseTemplateUrl,'gluster.json',parameters('_artifactsLocationSasToken'))]*/ = if (fileServerType == 'gluster') {
  name: 'glusterTemplate'
  params: {
    moodleCommon: moodleCommon
  }
  dependsOn: [
    networkTemplate
    recoveryTemplate
  ]
}

module controllerTemplate '?' /*TODO: replace with correct path to [concat(variables('moodleCommon').baseTemplateUrl,'controller.json',parameters('_artifactsLocationSasToken'))]*/ = {
  name: 'controllerTemplate'
  params: {
    moodleCommon: moodleCommon
  }
  dependsOn: [
    elasticTemplate
    glusterTemplate
    recoveryTemplate
    redisTemplate
    storageAccountTemplate
  ]
}

module scaleSetTemplate '?' /*TODO: replace with correct path to [concat(variables('moodleCommon').baseTemplateUrl,'webvmss.json',parameters('_artifactsLocationSasToken'))]*/ = {
  name: 'scaleSetTemplate'
  params: {
    moodleCommon: moodleCommon
  }
  dependsOn: [
    controllerTemplate
    redisTemplate
    dbTemplate
  ]
}

module storageAccountTemplate '?' /*TODO: replace with correct path to [concat(variables('moodleCommon').baseTemplateUrl,'storageAccount.json',parameters('_artifactsLocationSasToken'))]*/ = {
  name: 'storageAccountTemplate'
  params: {
    moodleCommon: moodleCommon
  }
}

output siteURL string = moodleCommon.siteURL
output controllerInstanceIP string = reference('controllerTemplate').outputs.controllerIP.value
output databaseDNS string = '${moodleCommon.dbServerType}-${moodleCommon.resourcesPrefix}.${moodleCommon.dbServerType}.database.azure.com'
output databaseAdminUsername string = moodleCommon.dbUsername
output databaseAdminPassword string = moodleCommon.dbLoginPassword
output firstFrontendVmIP string = reference('scaleSetTemplate').outputs.webvm1IP.value
output moodleAdminPassword string = moodleCommon.moodleAdminPass
output moodleDbUsername string = moodleCommon.moodleDbUserAzure
output moodleDbPassword string = moodleCommon.moodleDbPass
output loadBalancerDNS string = moodleCommon.lbDns