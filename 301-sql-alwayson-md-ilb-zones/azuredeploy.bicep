@description('Azure region that supports Availability Zones')
param location string

@minLength(3)
@maxLength(8)
@description('Naming prefix for each new resource created. 3-char min, 8-char max, lowercase alphanumeric')
param namePrefix string

@description('Size of the SQL Server VMs to be created')
param vmSize string = 'Standard_DS3_v2'

@allowed([
  'SQL2016SP1-WS2016'
  'SQL2016SP1-WS2016-BYOL'
  'SQL2017-WS2016'
  'SQL2017-WS2016-BYOL'
])
@description('VM Image Offer to use for provisioning SQL VMs')
param sqlVMImage string = 'SQL2016SP1-WS2016'

@description('SQL Image Sku')
param sqlVMImageSku string = 'SQLDEV'

@minValue(2)
@maxValue(9)
@description('Number of SQL Server VMs to be created in AlwaysOn Availability Group cluster (Min=2, Max=9)')
param vmCount int = 2

@minValue(128)
@maxValue(1023)
@description('Size of each data disk in GB on each SQL Server VM (Min=128, Max=1023)')
param vmDiskSize int = 1023

@minValue(2)
@maxValue(32)
@description('Number of data disks on each SQL Server VM (Min=2, Max=32). Ensure that the VM size you\'ve selected will support this number of data disks.')
param vmDiskCount int = 2

@description('DNS domain name for existing Active Directory domain')
param existingDomainName string

@description('Name of the Administrator of the existing Active Directory Domain')
param adminUsername string

@minLength(12)
@description('Password for the Administrator account of the existing Active Directory Domain')
@secure()
param adminPassword string

@description('Name of the user account to be used for the SQL Server service account. Do not use the same account speficied in adminUsername parameter')
param sqlServiceAccount string

@minLength(12)
@description('Password to be used for the SQL Server service account')
@secure()
param sqlServicePassword string

@description('Resource Group Name for the existing VNET.')
param existingVirtualNetworkRGName string

@description('Name of the existing VNET.')
param existingVirtualNetworkName string

@description('Name of the existing subnet in the existing VNET to which the SQL Server VMs should be deployed')
param existingSubnetName string = 'sqlSubnet'

@allowed([
  'Yes'
  'No'
])
@description('Enable outbound Internet access via source NAT to support ongoing VM Agent extension communication needs')
param enableOutboundInternet string = 'No'

@allowed([
  'GENERAL'
  'OLTP'
  'DW'
])
@description('SQL DB workload type: GENERAL - General workload; DW - Data Warehouse workload; OLTP - Transactional Processing workload')
param workloadType string = 'GENERAL'

@description('Location of resources that the script is dependent on such as linked templates and DSC modules')
param artifactsLocation string = 'https://raw.githubusercontent.com/Azure/azure-quickstart-templates/master/301-sql-alwayson-md-ilb-zones/'

@description('The sasToken required to access _artifactsLocation.  When the template is deployed using the accompanying scripts, a sasToken will be automatically generated.')
@secure()
param artifactsLocationSasToken string = ''

var subnetId = resourceId(existingVirtualNetworkRGName, 'Microsoft.Network/virtualNetworks/subnets', existingVirtualNetworkName, existingSubnetName)
var deploySqlClusterTemplateURL = uri(artifactsLocation, 'nestedtemplates/deploy-sql-cluster.json${artifactsLocationSasToken}')
var deploySqlCluster_var = 'deploySqlCluster'

module deploySqlCluster '?' /*TODO: replace with correct path to [variables('deploySqlClusterTemplateURL')]*/ = {
  name: deploySqlCluster_var
  params: {
    location: location
    namePrefix: namePrefix
    domainName: existingDomainName
    adminUsername: adminUsername
    adminPassword: adminPassword
    sqlServiceAccount: sqlServiceAccount
    sqlServicePassword: sqlServicePassword
    subnetId: subnetId
    enableOutboundInternet: enableOutboundInternet
    vmSize: vmSize
    imageOffer: sqlVMImage
    imageSKU: sqlVMImageSku
    vmCount: vmCount
    vmDiskSize: vmDiskSize
    vmDiskCount: vmDiskCount
    workloadType: workloadType
    '_artifactsLocation': artifactsLocation
    '_artifactsLocationSasToken': artifactsLocationSasToken
  }
}

output agListenerName string = reference(deploySqlCluster_var).outputs.agListenerName.value