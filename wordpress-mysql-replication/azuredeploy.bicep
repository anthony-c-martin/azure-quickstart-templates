param siteName string {
  metadata: {
    description: 'wordpress site name'
  }
}
param hostingPlanName string {
  metadata: {
    description: 'website host plan'
  }
}
param sku string {
  allowed: [
    'Basic'
    'Standard'
    'Premium'
  ]
  metadata: {
    description: 'website sku'
  }
  default: 'Standard'
}
param workerSize string {
  allowed: [
    '0'
    '1'
    '2'
  ]
  metadata: {
    description: 'website worker size'
  }
  default: '1'
}
param dnsName string {
  metadata: {
    description: 'Connect to your cluster using dnsName.location.cloudapp.azure.com'
  }
}
param publicIPName string {
  metadata: {
    description: 'public IP name for MySQL loadbalancer'
  }
  default: 'mysqlIP01'
}
param vmUserName string {
  metadata: {
    description: 'user name to ssh to the VMs'
  }
}
param mysqlRootPassword string {
  metadata: {
    description: 'mysql root user password'
  }
  secure: true
}
param mysqlReplicationPassword string {
  metadata: {
    description: 'mysql replication user password'
  }
  secure: true
}
param mysqlProbePassword string {
  metadata: {
    description: 'mysql probe password'
  }
  secure: true
}
param vmSize string {
  metadata: {
    description: 'size for the VMs'
  }
  default: 'Standard_D2'
}
param virtualNetworkName string {
  metadata: {
    description: 'New or Existing Virtual network name for the cluster'
  }
  default: 'mysqlvnet'
}
param vnetNewOrExisting string {
  allowed: [
    'new'
    'existing'
  ]
  metadata: {
    description: 'Identifies whether to use new or existing Virtual Network'
  }
  default: 'new'
}
param vnetExistingResourceGroupName string {
  metadata: {
    description: 'If using existing VNet, specifies the resource group for the existing VNet'
  }
  default: ''
}
param dbSubnetName string {
  metadata: {
    description: 'subnet name for the MySQL nodes'
  }
  default: 'default'
}
param vnetAddressPrefix string {
  metadata: {
    description: 'IP address in CIDR for virtual network'
  }
  default: '10.0.0.0/16'
}
param dbSubnetAddressPrefix string {
  metadata: {
    description: 'IP address in CIDR for db subnet'
  }
  default: '10.0.1.0/24'
}
param dbSubnetStartAddress string {
  metadata: {
    description: 'Start IP address for the VMs in db subnet'
  }
  default: '10.0.1.4'
}
param imagePublisher string {
  allowed: [
    'OpenLogic'
  ]
  metadata: {
    description: 'publisher for the VM OS image'
  }
  default: 'OpenLogic'
}
param imageOffer string {
  allowed: [
    'CentOS'
  ]
  metadata: {
    description: 'VM OS name'
  }
  default: 'CentOS'
}
param imageSKU string {
  allowed: [
    '6.5'
    '6.6'
  ]
  metadata: {
    description: 'VM OS version'
  }
  default: '6.6'
}
param mysqlFrontEndPort0 int {
  metadata: {
    description: 'MySQL public port'
  }
  default: 3306
}
param mysqlFrontEndPort1 int {
  metadata: {
    description: 'MySQL public port'
  }
  default: 3307
}
param sshNatRuleFrontEndPort0 int {
  metadata: {
    description: 'public ssh port for VM1'
  }
  default: 64001
}
param sshNatRuleFrontEndPort1 int {
  metadata: {
    description: 'public ssh port for VM2'
  }
  default: 64002
}
param mysqlProbePort0 int {
  metadata: {
    description: 'MySQL public port master'
  }
  default: 9200
}
param mysqlProbePort1 int {
  metadata: {
    description: 'MySQL public port slave'
  }
  default: 9201
}
param authenticationType string {
  allowed: [
    'sshPublicKey'
    'password'
  ]
  metadata: {
    description: 'Type of authentication to use on the Virtual Machine. SSH key is recommended.'
  }
  default: 'sshPublicKey'
}
param adminPasswordOrKey string {
  metadata: {
    description: 'SSH Key or password for the Virtual Machine. SSH key is recommended.'
  }
  secure: true
}
param artifactsLocation string {
  metadata: {
    description: 'The base URI where artifacts required by this template are located. When the template is deployed using the accompanying scripts, a private location in the subscription will be used and this value will be automatically generated.'
  }
  default: 'https://raw.githubusercontent.com/Azure/azure-quickstart-templates/master/wordpress-mysql-replication/'
}
param artifactsLocationSasToken string {
  metadata: {
    description: 'The sasToken required to access _artifactsLocation.  When the template is deployed using the accompanying scripts, a sasToken will be automatically generated.'
  }
  secure: true
  default: ''
}

var templateAPIVersion = '2015-01-01'
var resourceAPIVersion = '2015-06-15'
var wpdbname = '${uniqueString(resourceGroup().id)}wordpress'

module mysql '<failed to parse [uri(parameters(\'_artifactsLocation\'), concat(\'nested/mysql-replication.json\', parameters(\'_artifactsLocationSasToken\')))]>' = {
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

module website '<failed to parse [uri(parameters(\'_artifactsLocation\'), concat(\'nested/website.json\', parameters(\'_artifactsLocationSasToken\')))]>' = {
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