param workspaceName string {
  metadata: {
    description: 'The name of the Azure Databricks workspace to create.'
  }
}
param pricingTier string {
  allowed: [
    'standard'
    'premium'
  ]
  metadata: {
    description: 'The pricing tier of workspace.'
  }
  default: 'premium'
}
param vnetAddressPrefix string {
  metadata: {
    description: 'The first 2 octets of the virtual network /16 address range (e.g., \'10.139\' for the address range 10.139.0.0/16).'
  }
  default: '10.139'
}
param location string {
  metadata: {
    description: 'Location for all resources.'
  }
  default: resourceGroup().location
}

var managedResourceGroupName = 'databricks-rg-${workspaceName}-${uniqueString(workspaceName, resourceGroup().id)}'

resource workspaceName_res 'Microsoft.Databricks/workspaces@2018-04-01' = {
  name: workspaceName
  location: location
  sku: {
    name: pricingTier
  }
  properties: {
    managedResourceGroupId: subscriptionResourceId('Microsoft.Resources/resourceGroups', managedResourceGroupName)
    parameters: {
      vnetAddressPrefix: {
        value: vnetAddressPrefix
      }
    }
  }
}

output workspace object = workspaceName_res.properties