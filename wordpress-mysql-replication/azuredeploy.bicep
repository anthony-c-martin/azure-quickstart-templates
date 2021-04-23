@description('wordpress site name')
param siteName string

@description('website host plan')
param hostingPlanName string

@allowed([
  'Basic'
  'Standard'
  'Premium'
])
@description('website sku')
param sku string = 'Standard'

@allowed([
  '0'
  '1'
  '2'
])
@description('website worker size')
param workerSize string = '1'

@description('Connect to your cluster using dnsName.location.cloudapp.azure.com')
param dnsName string

@description('public IP name for MySQL loadbalancer')
param publicIPName string = 'mysqlIP01'

@description('user name to ssh to the VMs')
param vmUserName string

@description('mysql root user password')
@secure()
param mysqlRootPassword string

@description('mysql replication user password')
@secure()
param mysqlReplicationPassword string

@description('mysql probe password')
@secure()
param mysqlProbePassword string

@description('size for the VMs')
param vmSize string = 'Standard_D2'

@description('New or Existing Virtual network name for the cluster')
param virtualNetworkName string = 'mysqlvnet'

@allowed([
  'new'
  'existing'
])
@description('Identifies whether to use new or existing Virtual Network')
param vnetNewOrExisting string = 'new'

@description('If using existing VNet, specifies the resource group for the existing VNet')
param vnetExistingResourceGroupName string = ''

@description('subnet name for the MySQL nodes')
param dbSubnetName string = 'default'

@description('IP address in CIDR for virtual network')
param vnetAddressPrefix string = '10.0.0.0/16'

@description('IP address in CIDR for db subnet')
param dbSubnetAddressPrefix string = '10.0.1.0/24'

@description('Start IP address for the VMs in db subnet')
param dbSubnetStartAddress string = '10.0.1.4'

@allowed([
  'OpenLogic'
])
@description('publisher for the VM OS image')
param imagePublisher string = 'OpenLogic'

@allowed([
  'CentOS'
])
@description('VM OS name')
param imageOffer string = 'CentOS'

@allowed([
  '6.5'
  '6.6'
])
@description('VM OS version')
param imageSKU string = '6.6'

@description('MySQL public port')
param mysqlFrontEndPort0 int = 3306

@description('MySQL public port')
param mysqlFrontEndPort1 int = 3307

@description('public ssh port for VM1')
param sshNatRuleFrontEndPort0 int = 64001

@description('public ssh port for VM2')
param sshNatRuleFrontEndPort1 int = 64002

@description('MySQL public port master')
param mysqlProbePort0 int = 9200

@description('MySQL public port slave')
param mysqlProbePort1 int = 9201

@allowed([
  'sshPublicKey'
  'password'
])
@description('Type of authentication to use on the Virtual Machine. SSH key is recommended.')
param authenticationType string = 'sshPublicKey'

@description('SSH Key or password for the Virtual Machine. SSH key is recommended.')
@secure()
param adminPasswordOrKey string

@description('The base URI where artifacts required by this template are located. When the template is deployed using the accompanying scripts, a private location in the subscription will be used and this value will be automatically generated.')
param artifactsLocation string = 'https://raw.githubusercontent.com/Azure/azure-quickstart-templates/master/wordpress-mysql-replication/'

@description('The sasToken required to access _artifactsLocation.  When the template is deployed using the accompanying scripts, a sasToken will be automatically generated.')
@secure()
param artifactsLocationSasToken string = ''

var templateAPIVersion = '2015-01-01'
var resourceAPIVersion = '2015-06-15'
var wpdbname = '${uniqueString(resourceGroup().id)}wordpress'

module mysql '?' /*TODO: replace with correct path to [uri(parameters('_artifactsLocation'), concat('nested/mysql-replication.json', parameters('_artifactsLocationSasToken')))]*/ = {
  name: 'mysql'
  params: {
    dnsName: dnsName
    vmUserName: vmUserName
    mysqlRootPassword: mysqlRootPassword
    mysqlReplicationPassword: mysqlReplicationPassword
    mysqlProbePassword: mysqlProbePassword
    vmSize: vmSize
    virtualNetworkName: virtualNetworkName
    vnetNewOrExisting: vnetNewOrExisting
    vnetExistingResourceGroupName: vnetExistingResourceGroupName
    dbSubnetName: dbSubnetName
    vnetAddressPrefix: vnetAddressPrefix
    dbSubnetAddressPrefix: dbSubnetAddressPrefix
    dbSubnetStartAddress: dbSubnetStartAddress
    imagePublisher: imagePublisher
    imageOffer: imageOffer
    imageSKU: imageSKU
    mysqlFrontEndPort0: mysqlFrontEndPort0
    mysqlFrontEndPort1: mysqlFrontEndPort1
    sshNatRuleFrontEndPort0: sshNatRuleFrontEndPort0
    sshNatRuleFrontEndPort1: sshNatRuleFrontEndPort1
    mysqlProbePort0: mysqlProbePort0
    mysqlProbePort1: mysqlProbePort1
    publicIPName: publicIPName
    authenticationType: authenticationType
    adminPasswordOrKey: adminPasswordOrKey
    '_artifactsLocation': artifactsLocation
    '_artifactsLocationSasToken': artifactsLocationSasToken
  }
}

module website '?' /*TODO: replace with correct path to [uri(parameters('_artifactsLocation'), concat('nested/website.json', parameters('_artifactsLocationSasToken')))]*/ = {
  name: 'website'
  params: {
    siteName: siteName
    hostingPlanName: hostingPlanName
    sku: sku
    workerSize: workerSize
    DbServer: '${dnsName}.${resourceGroup().location}.cloudapp.azure.com:${mysqlFrontEndPort0}'
    DbName: wpdbname
    DbAdminPassword: mysqlRootPassword
  }
  dependsOn: [
    mysql
  ]
}