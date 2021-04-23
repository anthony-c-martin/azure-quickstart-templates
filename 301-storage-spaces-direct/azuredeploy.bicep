@minLength(3)
@maxLength(8)
@description('Naming prefix for each new resource created. 3-char min, 8-char max, lowercase alphanumeric')
param namePrefix string

@allowed([
  'Standard_LRS'
  'Standard_GRS'
  'Standard_RAGRS'
  'Premium_LRS'
])
@description('Type of new Storage Accounts (Standard_LRS, Standard_GRS, Standard_RAGRS or Premium_LRS) to be created to store VM disks')
param storageAccountType string = 'Premium_LRS'

@description('Size of the S2D VMs to be created')
param vmSize string = 'Standard_DS1_v2'

@minValue(2)
@maxValue(3)
@description('Number of S2D VMs to be created in cluster (Min=2, Max=3)')
param vmCount int = 2

@minValue(128)
@maxValue(1023)
@description('Size of each data disk in GB on each S2D VM (Min=128, Max=1023)')
param vmDiskSize int = 1023

@minValue(2)
@maxValue(32)
@description('Number of data disks on each S2D VM (Min=2, Max=32). Ensure that the VM size you\'ve selected will support this number of data disks.')
param vmDiskCount int = 2

@description('DNS domain name for existing Active Directory domain')
param existingDomainName string

@description('Name of the Administrator of the existing Active Directory Domain')
param adminUsername string

@minLength(12)
@description('Password for the Administrator account of the existing Active Directory Domain')
@secure()
param adminPassword string

@description('Resource Group Name for the existing VNET.')
param existingVirtualNetworkRGName string

@description('Name of the existing VNET.')
param existingVirtualNetworkName string

@description('Name of the existing subnet in the existing VNET to which the S2D VMs should be deployed')
param existingSubnetName string

@description('Name of clustered Scale-Out File Server role')
param sofsName string = 'fs01'

@description('Name of shared data folder on clustered Scale-Out File Server role')
param shareName string = 'data'

@description('Location of resources that the script is dependent on such as linked templates and DSC modules')
param artifactsLocation string = 'https://raw.githubusercontent.com/Azure/azure-quickstart-templates/master/301-storage-spaces-direct'

@description('The sasToken required to access _artifactsLocation.  When the template is deployed using the accompanying scripts, a sasToken will be automatically generated.')
@secure()
param artifactsLocationSasToken string = ''

var subnetRef = resourceId(existingVirtualNetworkRGName, 'Microsoft.Network/virtualNetworks/subnets', existingVirtualNetworkName, existingSubnetName)
var deployS2DClusterTemplateURL = '${artifactsLocation}/nestedtemplates/deploy-s2d-cluster.json${artifactsLocationSasToken}'
var deployS2DCluster_var = 'deployS2DCluster'

module deployS2DCluster '?' /*TODO: replace with correct path to [variables('deployS2DClusterTemplateURL')]*/ = {
  name: deployS2DCluster_var
  params: {
    namePrefix: namePrefix
    domainName: existingDomainName
    adminUsername: adminUsername
    adminPassword: adminPassword
    storageAccountType: storageAccountType
    nicSubnetUri: subnetRef
    vmSize: vmSize
    vmCount: vmCount
    vmDiskSize: vmDiskSize
    vmDiskCount: vmDiskCount
    sofsName: sofsName
    shareName: shareName
    '_artifactsLocation': artifactsLocation
    '_artifactsLocationSasToken': artifactsLocationSasToken
  }
  dependsOn: []
}

output sofsPath string = '\\\\${reference(deployS2DCluster_var).outputs.sofsName.value}\\${reference(deployS2DCluster_var).outputs.shareName.value}'