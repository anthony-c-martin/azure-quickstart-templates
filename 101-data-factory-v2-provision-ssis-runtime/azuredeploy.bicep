@description('Name of the data factory. Must be globally unique.')
param dataFactoryName string

@description('Location of the data factory.')
param location string = resourceGroup().location

@description('Name of your Azure virtual network.')
param virtualNetworkName string

@description('Name of the subnet in the virtual network.')
param subNetName string

@description('Location of the data factory.')
param nodeSize string = 'Standard_D2_v3'

@description('Number of nodes in the cluster.')
param nodeNumber int = 1

@description('Maximum number of parallel executions per node in the cluster.')
param maximumParallelExecutionsPerNode int = 1

@description('Name of the Azure SQL server that hosts the SSISDB database (SSIS Catalog). Example: servername.database.windows.net')
param azureSqlServerName string

@description('Name of the Azure SQL database user.')
param databaseAdminUsername string

@description('Password for the database user.')
@secure()
param databaseAdminPassword string

@description('Pricing tier of the SSIS Catalog (SSISDB datbase)')
param catalogPricingTier string = 'Basic'

resource dataFactoryName_resource 'Microsoft.DataFactory/factories@2018-06-01' = {
  name: dataFactoryName
  location: location
  properties: {}
}

resource dataFactoryName_SPAzureSsisIR 'Microsoft.DataFactory/factories/integrationRuntimes@2018-06-01' = {
  parent: dataFactoryName_resource
  name: 'SPAzureSsisIR'
  properties: {
    type: 'Managed'
    typeProperties: {
      computeProperties: {
        location: location
        nodeSize: nodeSize
        numberOfNodes: nodeNumber
        maxParallelExecutionsPerNode: maximumParallelExecutionsPerNode
        vNetProperties: {
          vNetId: resourceId('Microsoft.Network/virtualNetworks', virtualNetworkName)
          subnet: subNetName
        }
      }
      ssisProperties: {
        catalogInfo: {
          catalogServerEndpoint: azureSqlServerName
          catalogAdminUserName: databaseAdminUsername
          catalogAdminPassword: {
            type: 'SecureString'
            value: databaseAdminPassword
          }
          catalogPricingTier: catalogPricingTier
        }
      }
    }
  }
}