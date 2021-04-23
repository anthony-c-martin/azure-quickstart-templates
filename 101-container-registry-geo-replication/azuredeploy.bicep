@minLength(5)
@maxLength(50)
@description('Globally unique name of your Azure Container Registry')
param acrName string = 'acr${uniqueString(resourceGroup().id)}'

@description('Enable admin user that has push / pull permission to the registry.')
param acrAdminUserEnabled bool = false

@description('Location for registry home replica.')
param location string = resourceGroup().location

@allowed([
  'Premium'
])
@description('Tier of your Azure Container Registry. Geo-replication requires Premium SKU.')
param acrSku string = 'Premium'

@description('Short name for registry replica location.')
param acrReplicaLocation string

resource acrName_resource 'Microsoft.ContainerRegistry/registries@2019-12-01-preview' = {
  name: acrName
  location: location
  sku: {
    name: acrSku
    tier: acrSku
  }
  tags: {
    displayName: 'Container Registry'
    'container.registry': acrName
  }
  properties: {
    adminUserEnabled: acrAdminUserEnabled
  }
}

resource acrName_acrReplicaLocation 'Microsoft.ContainerRegistry/registries/replications@2019-12-01-preview' = {
  parent: acrName_resource
  name: '${acrReplicaLocation}'
  location: acrReplicaLocation
  properties: {}
}

output acrLoginServer string = reference(acrName_resource.id, '2019-12-01-preview').loginServer