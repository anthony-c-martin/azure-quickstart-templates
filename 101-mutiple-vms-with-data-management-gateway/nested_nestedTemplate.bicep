@description('your existing data factory name')
param existingDataFactoryName string

@description('Gateway name must be unique in subscription')
param GatewayName string

resource existingDataFactoryName_GatewayName 'Microsoft.DataFactory/dataFactories/gateways@2015-10-01' = {
  name: '${existingDataFactoryName}/${GatewayName}'
  properties: {
    multiNodeSupportEnabled: true
    description: 'my gateway'
  }
}