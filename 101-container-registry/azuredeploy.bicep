param acrName string {
  minLength: 5
  maxLength: 50
  metadata: {
    description: 'Name of your Azure Container Registry'
  }
}
param acrAdminUserEnabled bool {
  metadata: {
    description: 'Enable admin user that have push / pull permission to the registry.'
  }
  default: false
}
param location string {
  metadata: {
    description: 'Location for all resources.'
  }
  default: resourceGroup().location
}
param acrSku string {
  allowed: [
    'Basic'
    'Standard'
    'Premium'
  ]
  metadata: {
    description: 'Tier of your Azure Container Registry.'
  }
  default: 'Basic'
}

resource acrName_resource 'Microsoft.ContainerRegistry/registries@2019-12-01-preview' = {
  name: acrName
  location: location
  tags: {
    displayName: 'Container Registry'
    'container.registry': acrName
  }
  sku: {
    name: acrSku
    tier: acrSku
  }
  properties: {
    adminUserEnabled: acrAdminUserEnabled
  }
}

output acrLoginServer string = reference(acrName_resource.id, '2019-12-01-preview').loginServer