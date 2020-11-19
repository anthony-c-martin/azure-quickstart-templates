param powerbiWorkspaceName string {
  minLength: 3
  maxLength: 63
  metadata: {
    description: 'A unique name for the PowerBI workspace collection. It should match with the following regular expression: ^(?:[a-zA-Z0-9]+-?)+$ or it will raise an error. '
  }
}
param sku string {
  allowed: [
    'S1'
    's1'
  ]
  metadata: {
    description: 'provide the sku for powerbi workspace collection.'
  }
}
param location string {
  metadata: {
    description: 'Location for all resources.'
  }
  default: resourceGroup().location
}

resource powerbiWorkspaceName_res 'Microsoft.PowerBI/workspaceCollections@2016-01-29' = {
  name: powerbiWorkspaceName
  location: location
  sku: {
    name: sku
  }
  tags: {
    ObjectName: powerbiWorkspaceName
  }
}

output powerbiWorkspaceName_out string = powerbiWorkspaceName