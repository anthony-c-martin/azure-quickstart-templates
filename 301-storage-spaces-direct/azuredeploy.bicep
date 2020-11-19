param namePrefix string {
  minLength: 3
  maxLength: 8
  metadata: {
    description: 'Naming prefix for each new resource created. 3-char min, 8-char max, lowercase alphanumeric'
  }
}
param storageAccountType string {
  allowed: [
    'Standard_LRS'
    'Standard_GRS'
    'Standard_RAGRS'
    'Premium_LRS'
  ]
  metadata: {
    description: 'Type of new Storage Accounts (Standard_LRS, Standard_GRS, Standard_RAGRS or Premium_LRS) to be created to store VM disks'
  }
  default: 'Premium_LRS'
}
param vmSize string {
  metadata: {
    description: 'Size of the S2D VMs to be created'
  }
  default: 'Standard_DS1_v2'
}
param vmCount int {
  minValue: 2
  maxValue: 3
  metadata: {
    description: 'Number of S2D VMs to be created in cluster (Min=2, Max=3)'
  }
  default: 2
}
param vmDiskSize int {
  minValue: 128
  maxValue: 1023
  metadata: {
    description: 'Size of each data disk in GB on each S2D VM (Min=128, Max=1023)'
  }
  default: 1023
}
param vmDiskCount int {
  minValue: 2
  maxValue: 32
  metadata: {
    description: 'Number of data disks on each S2D VM (Min=2, Max=32). Ensure that the VM size you\'ve selected will support this number of data disks.'
  }
  default: 2
}
param existingDomainName string {
  metadata: {
    description: 'DNS domain name for existing Active Directory domain'
  }
}
param adminUsername string {
  metadata: {
    description: 'Name of the Administrator of the existing Active Directory Domain'
  }
}
param adminPassword string {
  minLength: 12
  metadata: {
    description: 'Password for the Administrator account of the existing Active Directory Domain'
  }
  secure: true
}
param existingVirtualNetworkRGName string {
  metadata: {
    description: 'Resource Group Name for the existing VNET.'
  }
}
param existingVirtualNetworkName string {
  metadata: {
    description: 'Name of the existing VNET.'
  }
}
param existingSubnetName string {
  metadata: {
    description: 'Name of the existing subnet in the existing VNET to which the S2D VMs should be deployed'
  }
}
param sofsName string {
  metadata: {
    description: 'Name of clustered Scale-Out File Server role'
  }
  default: 'fs01'
}
param shareName string {
  metadata: {
    description: 'Name of shared data folder on clustered Scale-Out File Server role'
  }
  default: 'data'
}
param artifactsLocation string {
  metadata: {
    description: 'Location of resources that the script is dependent on such as linked templates and DSC modules'
  }
  default: 'https://raw.githubusercontent.com/Azure/azure-quickstart-templates/master/301-storage-spaces-direct'
}
param artifactsLocationSasToken string {
  metadata: {
    description: 'The sasToken required to access _artifactsLocation.  When the template is deployed using the accompanying scripts, a sasToken will be automatically generated.'
  }
  secure: true
  default: ''
}

var subnetRef = resourceId(existingVirtualNetworkRGName, 'Microsoft.Network/virtualNetworks/subnets', existingVirtualNetworkName, existingSubnetName)
var deployS2DClusterTemplateURL = '${artifactsLocation}/nestedtemplates/deploy-s2d-cluster.json${artifactsLocationSasToken}'
var deployS2DCluster = 'deployS2DCluster'

module deployS2DCluster_resource '<failed to parse [variables(\'deployS2DClusterTemplateURL\')]>' = {
  name: deployS2DCluster
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

output sofsPath string = '\\\\${reference(deployS2DCluster).outputs.sofsName.value}\\${reference(deployS2DCluster).outputs.shareName.value}'