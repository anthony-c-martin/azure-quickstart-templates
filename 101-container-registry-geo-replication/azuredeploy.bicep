param acrName string {
  minLength: 5
  maxLength: 50
  metadata: {
    description: 'Globally unique name of your Azure Container Registry'
  }
  default: 'acr${uniqueString(resourceGroup().id)}'
}
param acrAdminUserEnabled bool {
  metadata: {
    description: 'Enable admin user that has push / pull permission to the registry.'
  }
  default: false
}
param location string {
  metadata: {
    description: 'Location for registry home replica.'
  }
  default: resourceGroup().location
}
param acrSku string {
  allowed: [
    'Premium'
  ]
  metadata: {
    description: 'Tier of your Azure Container Registry. Geo-replication requires Premium SKU.'
  }
  default: 'Premium'
}
param acrReplicaLocation string {
  metadata: {
    description: 'Short name for registry replica location.'
  }
}

resource acrName_res 'Microsoft.ContainerRegistry/registries@2019-12-01-preview' = {
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
  name: '${acrName}/${acrReplicaLocation}'
  location: acrReplicaLocation
  properties: {}
}

output acrLoginServer string = reference(acrName_res.id, '2019-12-01-preview').loginServer