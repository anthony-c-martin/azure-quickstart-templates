@description('The base URI where artifacts required by this template are located. When the template is deployed using the accompanying scripts, a private location in the subscription will be used and this value will be automatically generated.')
param artifactsLocation string = 'https://raw.githubusercontent.com/Azure/azure-quickstart-templates/master/mahara-autoscale-cache/'

@description('The sasToken required to access _artifactsLocation.  When the template is deployed using the accompanying scripts, a sasToken will be automatically generated.')
@secure()
param artifactsLocationSasToken string = ''

@description('Switch to process or bypass all scripts/extensions')
param applyScriptsSwitch bool = true

@description('Location for all resources')
param location string = resourceGroup().location

@description('Switch to configure AzureBackup and enlist VM\'s')
param azureBackupSwitch bool = false

@description('Switch to deploy a virtual network gateway or not')
param vnetGwDeploySwitch bool = false

@description('Switch to create a local copy of /mahara/html or not')
param htmlLocalCopySwitch bool = true

@allowed([
  'VMSS'
  'None'
])
@description('Indicates where https termination occurs. \'VMSS\' is for https termination at the VMSS instance VMs (using nginx https proxy). \'None\' is for testing only with no https. \'None\' may not be used with a separately configured https termination layer. If you want to use the \'None\' option with your separately configured https termination layer, you\'ll need to update your Mahara config.php manually for $cfg->wwwroot and $cfg->sslproxy.')
param httpsTermination string = 'VMSS'

@description('URL for Mahara site')
param siteURL string = 'www.example.org'

@allowed([
  '17.10_STABLE'
  '17.04_STABLE'
])
@description('The Mahara version you want to install.')
param maharaVersion string = '17.10_STABLE'

@description('ssh public key')
param sshPublicKey string

@description('ssh user name')
param sshUsername string

@description('VM size for the controller VM')
param controllerVmSku string = 'Standard_DS1_v2'

@allowed([
  'apache'
  'nginx'
])
@description('Web server type')
param webServerType string = 'apache'

@description('VM size for autoscaled web VMs')
param autoscaleVmSku string = 'Standard_DS2_v2'

@description('Maximum number of autoscaled web VMs')
param autoscaleVmCount int = 10

@allowed([
  'postgres'
  'mysql'
])
@description('Database type')
param dbServerType string = 'mysql'

@description('Database admin username')
param dbLogin string

@allowed([
  1
  2
  4
  8
  16
  32
])
@description('MySql/Postgresql vCores. For Basic tier, only 1 & 2 are allowed. For GeneralPurpose tier, 2, 4, 8, 16, 32 are allowed. For MemoryOptimized, 2, 4, 8, 16 are allowed.')
param mysqlPgresVcores int = 2

@minValue(5)
@maxValue(1024)
@description('MySql/Postgresql storage size in GB. Minimum 5GB, increase by 1GB, up to 1TB (1024 GB)')
param mysqlPgresStgSizeGB int = 125

@allowed([
  'Basic'
  'GeneralPurpose'
  'MemoryOptimized'
])
@description('MySql/Postgresql sku tier')
param mysqlPgresSkuTier string = 'GeneralPurpose'

@allowed([
  'Gen4'
  'Gen5'
])
@description('MySql/Postgresql sku hardware family')
param mysqlPgresSkuHwFamily string = 'Gen4'

@allowed([
  '5.6'
  '5.7'
])
@description('Mysql version')
param mysqlVersion string = '5.7'

@allowed([
  '9.5'
  '9.6'
])
@description('Postgresql version')
param postgresVersion string = '9.6'

@allowed([
  'Disabled'
  'Enabled'
])
@description('MySql/Postgresql SSL connection')
param sslEnforcement string = 'Disabled'

@allowed([
  'gluster'
  'nfs'
])
@description('File server type: GlusterFS, NFS--not yet highly available. Gluster uses premium managed disks therefore premium skus are required.')
param fileServerType string = 'nfs'

@description('Size per disk for gluster nodes or nfs server')
param fileServerDiskSize int = 127

@minValue(2)
@maxValue(8)
@description('Number of disks in raid0 per gluster node or nfs server')
param fileServerDiskCount int = 4

@description('VM size for the gluster nodes')
param glusterVmSku string = 'Standard_DS2_v2'

@description('Azure Resource Manager resource ID of the Key Vault in case you stored your SSL cert in an Azure Key Vault (Note that this Key Vault must have been pre-created on the same Azure region where this template is being deployed). Leave this blank if you didn\'t. Resource ID example: /subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/xxx/providers/Microsoft.KeyVault/vaults/yyy. This value can be obtained from keyvault.sh output if you used the script to store your SSL cert in your Key Vault.')
param keyVaultResourceId string = ''

@description('Azure Key Vault URL for your stored SSL cert. This value can be obtained from keyvault.sh output if you used the script to store your SSL cert in your Key Vault. This parameter is ignored if the keyVaultResourceId parameter is blank.')
param sslCertKeyVaultURL string = ''

@description('Thumbprint of your stored SSL cert. This value can be obtained from keyvault.sh output if you used the script to store your SSL cert in your Key Vault. This parameter is ignored if the keyVaultResourceId parameter is blank.')
param sslCertThumbprint string = ''

@description('Azure Key Vault URL for your stored CA (Certificate Authority) cert. This value can be obtained from keyvault.sh output if you used the script to store your CA cert in your Key Vault. This parameter is ignored if the keyVaultResourceId parameter is blank.')
param caCertKeyVaultURL string = ''

@description('Thumbprint of your stored CA cert. This value can be obtained from keyvault.sh output if you used the script to store your CA cert in your Key Vault. This parameter is ignored if the keyVaultResourceId parameter is blank.')
param caCertThumbprint string = ''

@allowed([
  'Standard_LRS'
  'Standard_GRS'
  'Standard_ZRS'
])
@description('Storage Account type')
param storageAccountType string = 'Standard_LRS'

@allowed([
  'none'
  'elastic'
])
@description('options of mahara global search')
param searchType string = 'none'

@description('VM size for the elastic search nodes')
param elasticVmSku string = 'Standard_DS2_v2'

@description('Address range for the Mahara virtual network - presumed /16 - further subneting during vnet creation')
param vNetAddressSpace string = '172.31.0.0'

@allowed([
  'GatewaySubnet'
  'MaharaGatewaySubnet'
  'MyMaharaGatewaySubnet'
])
@description('name for Virtual network gateway subnet')
param gatewaySubnet string = 'GatewaySubnet'

@allowed([
  'Vpn'
  'ER'
])
@description('Virtual network gateway type')
param gatewayType string = 'Vpn'

@allowed([
  'RouteBased'
  'PolicyBased'
])
@description('Virtual network gateway vpn type')
param vpnType string = 'RouteBased'

var documentation01 = 'This main-template calls multiple sub-templates to create the mahara system'
var documentation02 = '    recoveryservices0   - dummy template (see next statement)'
var documentation03 = '    recoveryservices1   - creates a recovery vault that will be subsequently used by the VM Backup - a paramter swtich controls whethe is is called or bypassed'
var documentation04 = '    postgres / mysql  - creates a postgresql / mysql server'
var documentation05 = '    vnet                - creates a virtual network with three subnets'
var documentation0j = '    elastic             - creates a elastic search cluster on a vm farm'
var documentation07 = '    gluster             - creates a gluster file system on a vm farm'
var documentation08 = '    webvmss             - creates a vm scale set'
var documentation09 = '    controller          - creates a controller VM and deploys code'
var documentation10 = 'GlusterFS Sizing guidance'
var maharaCommon = {
  location: location
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
  dbDNS: '${dbServerType}-${resourceprefix}.${dbServerType}.database.azure.com'
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
  htmlLocalCopySwitch: htmlLocalCopySwitch
  httpsTermination: httpsTermination
  ctlrNicName: 'controller-vm-nic-${resourceprefix}'
  ctlrNsgName: 'controller-nsg-${resourceprefix}'
  ctlrPipName: 'controller-pubip-${resourceprefix}'
  ctlrVmName: 'controller-vm-${resourceprefix}'
  ctlrVmSecrets: take(ctlrVmSecretsArray, (empty(keyVaultResourceId) ? 0 : 1))
  lbName: 'lb-${resourceprefix}'
  lbPipName: 'lb-pubip-${resourceprefix}'
  maharaAdminPass: '${toUpper('xl')}${substring(uniqueString(resourceGroup().id, deployment().name), 6, 7)},1*8'
  maharaDbName: 'mahara'
  maharaDbPass: '9#36^${substring(uniqueString(resourceGroup().id, deployment().name), 5, 8)}${toUpper('ercq')}'
  maharaDbUser: 'mahara'
  maharaDbUserAzure: 'mahara@${dbServerType}-${resourceprefix}'
  maharaInstallScriptFilename: 'install_mahara.sh'
  maharaVersion: maharaVersion
  mysqlPgresSkuHwFamily: mysqlPgresSkuHwFamily
  mysqlPgresSkuName: '${((mysqlPgresSkuTier == 'Basic') ? 'B' : ((mysqlPgresSkuTier == 'GeneralPurpose') ? 'GP' : 'MO'))}_${mysqlPgresSkuHwFamily}_${string(mysqlPgresVcores)}'
  mysqlPgresSkuTier: mysqlPgresSkuTier
  mysqlPgresStgSizeGB: mysqlPgresStgSizeGB
  mysqlPgresVcores: mysqlPgresVcores
  mysqlVersion: mysqlVersion
  osType: {
    offer: 'UbuntuServer'
    publisher: 'Canonical'
    sku: '16.04-LTS'
    version: 'latest'
  }
  policyName: 'policy-${resourceprefix}'
  postgresVersion: postgresVersion
  resourcesPrefix: resourceprefix
  searchType: searchType
  serverName: '${dbServerType}-${resourceprefix}'
  siteURL: siteURL
  sshPublicKey: sshPublicKey
  sshUsername: sshUsername
  sslEnforcement: sslEnforcement
  storageAccountName: toLower('abs${resourceprefix}')
  storageAccountType: storageAccountType
  subnetElastic: 'elastic-subnet-${resourceprefix}'
  subnetElasticPrefix: '${octets[0]}.${octets[1]}.${string((int(octets[2]) + 4))}'
  subnetElasticRange: '${octets[0]}.${octets[1]}.${string((int(octets[2]) + 4))}.0/24'
  subnetSan: 'san-subnet-${resourceprefix}'
  subnetSanPrefix: '${octets[0]}.${octets[1]}.${string((int(octets[2]) + 1))}'
  subnetSanRange: '${octets[0]}.${octets[1]}.${string((int(octets[2]) + 1))}.0/24'
  subnetWeb: 'web-subnet-${resourceprefix}'
  subnetWebPrefix: '${octets[0]}.${octets[1]}.${string((int(octets[2]) + 0))}'
  subnetWebRange: '${octets[0]}.${octets[1]}.${string((int(octets[2]) + 0))}.0/24'
  thumbprintSslCert: ((empty(keyVaultResourceId) || empty(sslCertThumbprint)) ? 'None' : sslCertThumbprint)
  thumbprintCaCert: ((empty(keyVaultResourceId) || empty(caCertThumbprint)) ? 'None' : caCertThumbprint)
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
var certUrlArray = [
  {
    certificateUrl: sslCertKeyVaultURL
  }
  {
    certificateUrl: caCertKeyVaultURL
  }
]
var ctlrVmSecretsArray = [
  {
    sourceVault: {
      id: keyVaultResourceId
    }
    vaultCertificates: take(certUrlArray, (empty(caCertKeyVaultURL) ? 1 : 2))
  }
]
var octets = split(vNetAddressSpace, '.')
var resourceprefix = substring(uniqueString(resourceGroup().id, deployment().name), 3, 6)

module dbTemplate '?' /*TODO: replace with correct path to [concat(variables('maharaCommon').baseTemplateUrl, parameters('dbServerType'), '.json', parameters('_artifactsLocationSasToken'))]*/ = {
  name: 'dbTemplate'
  params: {
    maharaCommon: maharaCommon
    lbPubIp: reference('networkTemplate').outputs.lbPubIp.value
    ctlrPubIp: reference('networkTemplate').outputs.ctlrPubIp.value
  }
  dependsOn: [
    networkTemplate
  ]
}

module recoveryTemplate '?' /*TODO: replace with correct path to [concat(variables('maharaCommon').baseTemplateUrl,'recoveryservices.json',parameters('_artifactsLocationSasToken'))]*/ = if (azureBackupSwitch) {
  name: 'recoveryTemplate'
  params: {
    maharaCommon: maharaCommon
  }
}

module networkTemplate '?' /*TODO: replace with correct path to [concat(variables('maharaCommon').baseTemplateUrl,'network.json',parameters('_artifactsLocationSasToken'))]*/ = {
  name: 'networkTemplate'
  params: {
    maharaCommon: maharaCommon
  }
}

module searchTemplate '?' /*TODO: replace with correct path to [concat(variables('maharaCommon').baseTemplateUrl, parameters('searchType'), '-search.json', parameters('_artifactsLocationSasToken'))]*/ = {
  name: 'searchTemplate'
  params: {
    maharaCommon: maharaCommon
  }
  dependsOn: [
    networkTemplate
    recoveryTemplate
  ]
}

module glusterTemplate '?' /*TODO: replace with correct path to [concat(variables('maharaCommon').baseTemplateUrl,'gluster.json',parameters('_artifactsLocationSasToken'))]*/ = if (fileServerType == 'gluster') {
  name: 'glusterTemplate'
  params: {
    maharaCommon: maharaCommon
  }
  dependsOn: [
    networkTemplate
    recoveryTemplate
  ]
}

module controllerTemplate '?' /*TODO: replace with correct path to [concat(variables('maharaCommon').baseTemplateUrl,'controller.json',parameters('_artifactsLocationSasToken'))]*/ = {
  name: 'controllerTemplate'
  params: {
    maharaCommon: maharaCommon
    ctlrPubIpId: reference('networkTemplate').outputs.ctlrPubIpId.value
    siteFQDN: reference('networkTemplate').outputs.siteFQDN.value
  }
  dependsOn: [
    glusterTemplate
    recoveryTemplate
    networkTemplate
    dbTemplate
    searchTemplate
    storageAccountTemplate
  ]
}

module scaleSetTemplate '?' /*TODO: replace with correct path to [concat(variables('maharaCommon').baseTemplateUrl,'webvmss.json',parameters('_artifactsLocationSasToken'))]*/ = {
  name: 'scaleSetTemplate'
  params: {
    maharaCommon: maharaCommon
    siteFQDN: reference('networkTemplate').outputs.siteFQDN.value
  }
  dependsOn: [
    controllerTemplate
    networkTemplate
    dbTemplate
  ]
}

module storageAccountTemplate '?' /*TODO: replace with correct path to [concat(variables('maharaCommon').baseTemplateUrl,'storageAccount.json',parameters('_artifactsLocationSasToken'))]*/ = {
  name: 'storageAccountTemplate'
  params: {
    maharaCommon: maharaCommon
  }
}

output siteURL string = ((maharaCommon.siteURL == 'www.example.org') ? reference('networkTemplate').outputs.siteFQDN.value : 'www.example.org')
output controllerInstanceIP string = reference('controllerTemplate').outputs.controllerIP.value
output databaseDNS string = maharaCommon.dbDNS
output databaseAdminUsername string = maharaCommon.dbUsername
output databaseAdminPassword string = maharaCommon.dbLoginPassword
output firstFrontendVmIP string = reference('scaleSetTemplate').outputs.webvm1IP.value
output maharaAdminPassword string = maharaCommon.maharaAdminPass
output maharaDbUsername string = maharaCommon.maharaDbUserAzure
output maharaDbPassword string = maharaCommon.maharaDbPass
output sshUsername string = maharaCommon.sshUsername
output loadBalancerDNS string = reference('networkTemplate').outputs.siteFQDN.value