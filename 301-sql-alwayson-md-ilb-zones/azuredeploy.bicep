param location string {
  metadata: {
    description: 'Azure region that supports Availability Zones'
  }
  default: 'eastus2'
}
param namePrefix string {
  minLength: 3
  maxLength: 8
  metadata: {
    description: 'Naming prefix for each new resource created. 3-char min, 8-char max, lowercase alphanumeric'
  }
}
param vmSize string {
  metadata: {
    description: 'Size of the SQL Server VMs to be created'
  }
  default: 'Standard_DS3_v2'
}
param sqlVMImage string {
  allowed: [
    'SQL2016SP1-WS2016'
    'SQL2016SP1-WS2016-BYOL'
    'SQL2017-WS2016'
    'SQL2017-WS2016-BYOL'
  ]
  metadata: {
    description: 'VM Image Offer to use for provisioning SQL VMs'
  }
  default: 'SQL2016SP1-WS2016'
}
param sqlVMImageSku string {
  metadata: {
    description: 'SQL Image Sku'
  }
  default: 'SQLDEV'
}
param vmCount int {
  minValue: 2
  maxValue: 9
  metadata: {
    description: 'Number of SQL Server VMs to be created in AlwaysOn Availability Group cluster (Min=2, Max=9)'
  }
  default: 2
}
param vmDiskSize int {
  minValue: 128
  maxValue: 1023
  metadata: {
    description: 'Size of each data disk in GB on each SQL Server VM (Min=128, Max=1023)'
  }
  default: 1023
}
param vmDiskCount int {
  minValue: 2
  maxValue: 32
  metadata: {
    description: 'Number of data disks on each SQL Server VM (Min=2, Max=32). Ensure that the VM size you\'ve selected will support this number of data disks.'
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
param sqlServiceAccount string {
  metadata: {
    description: 'Name of the user account to be used for the SQL Server service account. Do not use the same account speficied in adminUsername parameter'
  }
}
param sqlServicePassword string {
  minLength: 12
  metadata: {
    description: 'Password to be used for the SQL Server service account'
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
    description: 'Name of the existing subnet in the existing VNET to which the SQL Server VMs should be deployed'
  }
  default: 'sqlSubnet'
}
param enableOutboundInternet string {
  allowed: [
    'Yes'
    'No'
  ]
  metadata: {
    description: 'Enable outbound Internet access via source NAT to support ongoing VM Agent extension communication needs'
  }
  default: 'No'
}
param workloadType string {
  allowed: [
    'GENERAL'
    'OLTP'
    'DW'
  ]
  metadata: {
    description: 'SQL DB workload type: GENERAL - General workload; DW - Data Warehouse workload; OLTP - Transactional Processing workload'
  }
  default: 'GENERAL'
}
param artifactsLocation string {
  metadata: {
    description: 'Location of resources that the script is dependent on such as linked templates and DSC modules'
  }
  default: 'https://raw.githubusercontent.com/Azure/azure-quickstart-templates/master/301-sql-alwayson-md-ilb-zones/'
}
param artifactsLocationSasToken string {
  metadata: {
    description: 'The sasToken required to access _artifactsLocation.  When the template is deployed using the accompanying scripts, a sasToken will be automatically generated.'
  }
  secure: true
  default: ''
}

var vnetRef = resourceId(existingVirtualNetworkRGName, 'Microsoft.Network/virtualNetworks', existingVirtualNetworkName)
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
    nicVnetUri: vnetRef
    existingSubnetName: existingSubnetName
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
  dependsOn: []
}

output agListenerName string = reference(deploySqlCluster_var).outputs.agListenerName.value