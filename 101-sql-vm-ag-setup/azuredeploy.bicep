@maxLength(15)
@description('Specify the Windows Failover Cluster Name')
param failoverClusterName string

@description('Specify comma separated list of names of SQL Server VM\'s to participate in the Availability Group (e.g. SQLVM1, SQLVM2). OS underneath should be at least WS 2016.')
param existingVmList string

@allowed([
  'PAYG'
  'AHUB'
])
@description('Specify the SQL Server License type for all VM\'s.')
param sqlServerLicenseType string

@description('Specify resourcegroup name for existing Vms.')
param existingVmResourceGroup string = resourceGroup().name

@allowed([
  'SQL2017-WS2016'
  'SQL2016-WS2016'
  'SQL2019-WS2019'
])
@description('Select the version of SQL Server Image type')
param sqlServerImageType string

@description('Specify the Fully Qualified Domain Name under which the Failover Cluster will be created. The VM\'s should already be joined to it. (e.g. contoso.com)')
param existingFullyQualifiedDomainName string

@description('Specify an optional Organizational Unit (OU) on AD Domain where the CNO (Computer Object for Cluster Name) will be created (e.g. OU=testou,OU=testou2,DC=contoso,DC=com). Default is empty.')
param existingOuPath string = ''

@description('Specify the account for WS failover cluster creation in UPN format (e.g. example@contoso.com). This account can either be a Domain Admin or at least have permissions to create Computer Objects in default or specified OU.')
param existingDomainAccount string

@description('Specify the password for the domain account')
@secure()
param domainAccountPassword string

@description('Specify the domain account under which SQL Server service will run for AG setup in UPN format (e.g. sqlservice@contoso.com)')
param existingSqlServiceAccount string

@description('Specify the password for Sql Server service account')
@secure()
param sqlServicePassword string

@description('Specify the name of the storage account to be used for creating Cloud Witness for Windows server failover cluster')
param cloudWitnessName string = 'clwitness${uniqueString(resourceGroup().id)}'

@description('Location of resources that the script is dependent on such as linked templates and DSC modules')
param artifactsLocation string = 'https://raw.githubusercontent.com/Azure/azure-quickstart-templates/master/101-sql-vm-ag-setup/'

@description('The sasToken required to access _artifactsLocation.  When the template is deployed using the accompanying scripts, a sasToken will be automatically generated.')
@secure()
param artifactsLocationSasToken string = ''

@description('Location for all resources.')
param location string = resourceGroup().location

var existingVMListArray_var = split(existingVmList, ',')
var GroupResourceId = failoverClusterName_resource.id
var joinClusterTemplateURL = '${artifactsLocation}/nested/join-cluster.json${artifactsLocationSasToken}'

resource existingVMListArray 'Microsoft.SqlVirtualMachine/SqlVirtualMachines@2017-03-01-preview' = [for item in existingVMListArray_var: {
  name: trim(item)
  location: location
  properties: {
    virtualMachineResourceId: resourceId(existingVmResourceGroup, 'Microsoft.Compute/virtualMachines', trim(item))
    sqlServerLicenseType: sqlServerLicenseType
  }
}]

resource cloudWitnessName_resource 'Microsoft.Storage/storageAccounts@2018-07-01' = {
  name: cloudWitnessName
  sku: {
    name: 'Standard_LRS'
  }
  kind: 'StorageV2'
  location: location
  properties: {
    accessTier: 'Hot'
    supportsHttpsTrafficOnly: true
  }
}

resource failoverClusterName_resource 'Microsoft.SqlVirtualMachine/SqlVirtualMachineGroups@2017-03-01-preview' = {
  name: failoverClusterName
  location: location
  properties: {
    sqlImageOffer: sqlServerImageType
    sqlImageSku: 'Enterprise'
    wsfcDomainProfile: {
      domainFqdn: existingFullyQualifiedDomainName
      ouPath: existingOuPath
      clusterBootstrapAccount: existingDomainAccount
      clusterOperatorAccount: existingDomainAccount
      sqlServiceAccount: existingSqlServiceAccount
      storageAccountUrl: reference(cloudWitnessName_resource.id, '2018-07-01').primaryEndpoints.blob
      storageAccountPrimaryKey: listKeys(cloudWitnessName_resource.id, '2018-07-01').keys[0].value
    }
  }
}

module joincluster '?' /*TODO: replace with correct path to [variables('joinClusterTemplateURL')]*/ = {
  name: 'joincluster'
  params: {
    existingVirtualMachineNames: existingVMListArray_var
    location: location
    sqlServerLicenseType: sqlServerLicenseType
    existingVmResourceGroup: existingVmResourceGroup
    groupResourceId: GroupResourceId
    domainAccountPassword: domainAccountPassword
    sqlServicePassword: sqlServicePassword
  }
  dependsOn: [
    cloudWitnessName_resource
    existingVMListArray
  ]
}