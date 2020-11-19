param namePrefix string {
  maxLength: 8
  metadata: {
    description: 'Naming prefix for each new resource created. 8-char max, lowercase alphanumeric'
  }
}
param diskType string {
  allowed: [
    'Standard_LRS'
    'Premium_LRS'
  ]
  metadata: {
    description: 'Type of Storage to be used for VM disks'
  }
  default: 'Premium_LRS'
}
param sqlVMSize string {
  metadata: {
    description: 'Size of the SQL VMs to be created'
  }
  default: 'Standard_DS3_V2'
}
param sqlWitnessVMSize string {
  metadata: {
    description: 'Size of the Witness VM to be created'
  }
  default: 'Standard_DS1_V2'
}
param existingDomainName string {
  metadata: {
    description: 'DNS domain name for existing Active Directory domain'
  }
  default: 'contoso.com'
}
param adminUsername string {
  metadata: {
    description: 'Name of the Administrator of the existing Active Directory Domain'
  }
}
param adminPassword string {
  metadata: {
    description: 'Password for the Administrator account of the existing Active Directory Domain'
  }
  secure: true
}
param sqlServerServiceAccountUserName string {
  metadata: {
    description: 'The SQL Server Service account name'
  }
}
param sqlServerServiceAccountPassword string {
  metadata: {
    description: 'The SQL Server Service account password'
  }
  secure: true
}
param existingVirtualNetworkId string {
  metadata: {
    description: 'Resource ID of the existing VNET. You can find the Resource ID for the VNET on the Properties blade of the VNET.'
  }
}
param existingSqlSubnetName string {
  metadata: {
    description: 'Name of the existing subnet in the existing VNET to which the SQL & Witness VMs should be deployed'
  }
  default: 'default'
}
param existingAdPDCVMName string {
  maxLength: 15
  metadata: {
    description: 'Computer name of the existing Primary AD domain controller & DNS server'
  }
}
param sqlLBIPAddress string {
  metadata: {
    description: 'IP address of ILB for the SQL Server AlwaysOn listener to be created'
  }
  default: '10.0.1.10'
}
param artifactsLocation string {
  metadata: {
    description: 'Location of resources that the script is dependent on such as linked templates and DSC modules'
  }
  default: 'https://raw.githubusercontent.com/Azure/azure-quickstart-templates/master/sql-server-2014-alwayson-existing-vnet-and-ad'
}
param artifactsLocationSasToken string {
  metadata: {
    description: 'The sasToken required to access _artifactsLocation.  When the template is deployed using the accompanying scripts, a sasToken will be automatically generated.'
  }
  secure: true
  default: ''
}
param location string {
  metadata: {
    description: 'Location for all resources.'
  }
  default: resourceGroup().location
}

var sqlSubnetRef = '${existingVirtualNetworkId}/subnets/${existingSqlSubnetName}'
var deploySqlClusterTemplateURL = '${artifactsLocation}/nested/deploy-sql-cluster.json${artifactsLocationSasToken}'
var deploySqlCluster = 'deploySqlCluster'

module deploySqlCluster_resource '<failed to parse [variables(\'deploySqlClusterTemplateURL\')]>' = {
  name: deploySqlCluster
  params: {
    namePrefix: namePrefix
    domainName: existingDomainName
    dnsServerName: existingAdPDCVMName
    adminUsername: adminUsername
    adminPassword: adminPassword
    sqlServerServiceAccountUserName: sqlServerServiceAccountUserName
    sqlServerServiceAccountPassword: sqlServerServiceAccountPassword
    storageAccountType: 'Standard_LRS'
    nicSubnetUri: sqlSubnetRef
    lbSubnetUri: sqlSubnetRef
    sqlLBIPAddress: sqlLBIPAddress
    sqlVMSize: sqlVMSize
    sqlWitnessVMSize: sqlWitnessVMSize
    '_artifactsLocation': artifactsLocation
    '_artifactsLocationSasToken': artifactsLocationSasToken
  }
  dependsOn: []
}