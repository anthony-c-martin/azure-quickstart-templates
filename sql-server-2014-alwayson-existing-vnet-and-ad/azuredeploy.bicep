@maxLength(8)
@description('Naming prefix for each new resource created. 8-char max, lowercase alphanumeric')
param namePrefix string

@allowed([
  'Standard_LRS'
  'Premium_LRS'
])
@description('Type of Storage to be used for VM disks')
param diskType string = 'Premium_LRS'

@description('Size of the SQL VMs to be created')
param sqlVMSize string = 'Standard_DS3_V2'

@description('Size of the Witness VM to be created')
param sqlWitnessVMSize string = 'Standard_DS1_V2'

@description('DNS domain name for existing Active Directory domain')
param existingDomainName string = 'contoso.com'

@description('Name of the Administrator of the existing Active Directory Domain')
param adminUsername string

@description('Password for the Administrator account of the existing Active Directory Domain')
@secure()
param adminPassword string

@description('The SQL Server Service account name')
param sqlServerServiceAccountUserName string

@description('The SQL Server Service account password')
@secure()
param sqlServerServiceAccountPassword string

@description('Resource ID of the existing VNET. You can find the Resource ID for the VNET on the Properties blade of the VNET.')
param existingVirtualNetworkId string

@description('Name of the existing subnet in the existing VNET to which the SQL & Witness VMs should be deployed')
param existingSqlSubnetName string = 'default'

@maxLength(15)
@description('Computer name of the existing Primary AD domain controller & DNS server')
param existingAdPDCVMName string

@description('IP address of ILB for the SQL Server AlwaysOn listener to be created')
param sqlLBIPAddress string = '10.0.1.10'

@description('Location of resources that the script is dependent on such as linked templates and DSC modules')
param artifactsLocation string = 'https://raw.githubusercontent.com/Azure/azure-quickstart-templates/master/sql-server-2014-alwayson-existing-vnet-and-ad'

@description('The sasToken required to access _artifactsLocation.  When the template is deployed using the accompanying scripts, a sasToken will be automatically generated.')
@secure()
param artifactsLocationSasToken string = ''

@description('Location for all resources.')
param location string = resourceGroup().location

var sqlSubnetRef = '${existingVirtualNetworkId}/subnets/${existingSqlSubnetName}'
var deploySqlClusterTemplateURL = '${artifactsLocation}/nested/deploy-sql-cluster.json${artifactsLocationSasToken}'
var deploySqlCluster_var = 'deploySqlCluster'

module deploySqlCluster '?' /*TODO: replace with correct path to [variables('deploySqlClusterTemplateURL')]*/ = {
  name: deploySqlCluster_var
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