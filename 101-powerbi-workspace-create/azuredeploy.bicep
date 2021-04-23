@minLength(3)
@maxLength(63)
@description('A unique name for the PowerBI workspace collection. It should match with the following regular expression: ^(?:[a-zA-Z0-9]+-?)+$ or it will raise an error. ')
param powerbiWorkspaceName string

@allowed([
  'S1'
  's1'
])
@description('provide the sku for powerbi workspace collection.')
param sku string

@description('Location for all resources.')
param location string = resourceGroup().location

resource powerbiWorkspaceName_resource 'Microsoft.PowerBI/workspaceCollections@2016-01-29' = {
  name: powerbiWorkspaceName
  location: location
  sku: {
    name: sku
  }
  tags: {
    ObjectName: powerbiWorkspaceName
  }
}

output powerbiWorkspaceName string = powerbiWorkspaceName