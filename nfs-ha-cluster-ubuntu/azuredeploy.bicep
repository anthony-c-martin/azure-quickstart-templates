@description('The base URI where artifacts required by this template are located. When the template is deployed using the accompanying scripts, a private location in the subscription will be used and this value will be automatically generated.')
param artifactsLocation string = 'https://raw.githubusercontent.com/Azure/azure-quickstart-templates/master/nfs-ha-cluster-ubuntu/'

@description('The sasToken required to access _artifactsLocation.  When the template is deployed using the accompanying scripts, a sasToken will be automatically generated.')
@secure()
param artifactsLocationSasToken string = ''

@description('Azure location where this template is to be deployed')
param location string = resourceGroup().location

@description('Azure resource ID of the subnet where this NFS-HA cluster is to be deployed')
param subnetId string

@description('IP address of node 0 (statically assigned). E.g., 10.0.0.11. Must belong to the IP range of the specified subnet')
param node0IPAddr string

@description('IP address of node 1 (statically assigned). E.g., 10.0.0.22. Must belong to the IP range of the specified subnet')
param node1IPAddr string

@description('IP range of the allowed NFS clients. E.g., 10.0.0.0/24')
param nfsClientsIPRange string

@description('IP address of the load balancer front-end (statically assigned). E.g., 10.0.0.100. Must belong to the IP range of the specified subnet')
param lbFrontEndIpAddr string

@description('Switch to enable Azure Accelerated Networking (Note: this feature is NOT available for D1-level VM SKU)')
param enableAccelNwSwitch bool = false

@description('Azure VM SKU for the NFS HA VMs')
param vmSku string = 'Standard_DS2_v2'

@description('VM admin user name')
param adminUserName string = 'azureadmin'

@description('SSH public key for the admin user')
param sshPublicKey string

@description('OS type (offer/publisher/sku/version) info')
param osType object = {
  offer: 'UbuntuServer'
  publisher: 'Canonical'
  sku: '16.04-LTS'
  version: 'latest'
}

@allowed([
  'Premium_LRS'
  'Standard_LRS'
])
@description('Azure storage type for all VMs\' OS disks. With htmlLocalCopySwith true, Premium_LRS (SSD) is strongly recommended, as PHP files will be served from OS disks.')
param osDiskStorageType string = 'Premium_LRS'

@minValue(1)
@maxValue(8)
@description('Number of data disks per VM. 2 or more disks will be configured as RAID0')
param dataDiskCountPerVM int = 1

@description('Size per disk in an NFS server')
param dataDiskSizeInGB int = 32

@description('Unique string of fixed length (e.g., 6) identifying related resources')
param resourcesUniqueString string = substring(uniqueString(resourceGroup().id, deployment().name), 3, 6)

module pid_38a42e4d_89db_4159_9b75_9113b6eae9b6 './nested_pid_38a42e4d_89db_4159_9b75_9113b6eae9b6.bicep' = {
  name: 'pid-38a42e4d-89db-4159-9b75-9113b6eae9b6'
  params: {}
}

module nfs_ha_deployment '?' /*TODO: replace with correct path to [concat(parameters('_artifactsLocation'), 'nested/nfs-ha.json', parameters('_artifactsLocationSasToken'))]*/ = {
  name: 'nfs-ha-deployment'
  params: {
    '_artifactsLocation': artifactsLocation
    '_artifactsLocationSasToken': artifactsLocationSasToken
    location: location
    subnetId: subnetId
    node0IPAddr: node0IPAddr
    node1IPAddr: node1IPAddr
    nfsClientsIPRange: nfsClientsIPRange
    lbFrontEndIpAddr: lbFrontEndIpAddr
    enableAccelNwSwitch: enableAccelNwSwitch
    vmSku: vmSku
    adminUserName: adminUserName
    sshPublicKey: sshPublicKey
    osType: osType
    osDiskStorageType: osDiskStorageType
    dataDiskCountPerVM: dataDiskCountPerVM
    dataDiskSizeInGB: dataDiskSizeInGB
    resourcesUniqueString: resourcesUniqueString
  }
}