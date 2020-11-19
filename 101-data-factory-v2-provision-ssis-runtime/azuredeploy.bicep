param dataFactoryName string {
  metadata: {
    description: 'Name of the data factory. Must be globally unique.'
  }
}
param location string {
  metadata: {
    description: 'Location of the data factory.'
  }
  default: resourceGroup().location
}
param virtualNetworkName string {
  metadata: {
    description: 'Name of your Azure virtual network.'
  }
}
param subNetName string {
  metadata: {
    description: 'Name of the subnet in the virtual network.'
  }
}
param nodeSize string {
  metadata: {
    description: 'Location of the data factory.'
  }
  default: 'Standard_D2_v3'
}
param nodeNumber int {
  metadata: {
    description: 'Number of nodes in the cluster.'
  }
  default: 1
}
param maximumParallelExecutionsPerNode int {
  metadata: {
    description: 'Maximum number of parallel executions per node in the cluster.'
  }
  default: 1
}
param azureSqlServerName string {
  metadata: {
    description: 'Name of the Azure SQL server that hosts the SSISDB database (SSIS Catalog). Example: servername.database.windows.net'
  }
}
param databaseAdminUsername string {
  metadata: {
    description: 'Name of the Azure SQL database user.'
  }
}
param databaseAdminPassword string {
  metadata: {
    description: 'Password for the database user.'
  }
  secure: true
}
param catalogPricingTier string {
  metadata: {
    description: 'Pricing tier of the SSIS Catalog (SSISDB datbase)'
  }
  default: 'Basic'
}

resource dataFactoryName_res 'Microsoft.DataFactory/factories@2018-06-01' = {
  name: dataFactoryName
  location: location
  properties: {}
}

resource dataFactoryName_SPAzureSsisIR 'Microsoft.DataFactory/factories/integrationRuntimes@2018-06-01' = {
  name: '${dataFactoryName}/SPAzureSsisIR'
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
  dependsOn: [
    dataFactoryName_res
  ]
}