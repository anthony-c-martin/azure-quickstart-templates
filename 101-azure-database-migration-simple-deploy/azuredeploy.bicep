param serviceName string {
  metadata: {
    description: 'Name of the new migration service.'
  }
}
param location string {
  metadata: {
    description: 'Location where the resources will be deployed.'
  }
  default: resourceGroup().location
}
param vnetName string {
  metadata: {
    description: 'Name of the new virtual network.'
  }
}
param subnetName string {
  metadata: {
    description: 'Name of the new subnet associated with the virtual network.'
  }
}

resource vnetName_res 'Microsoft.Network/virtualNetworks@2020-06-01' = {
  name: vnetName
  location: location
  properties: {
    addressSpace: {
      addressPrefixes: [
        '10.0.0.0/16'
      ]
    }
  }
}

resource vnetName_subnetName 'Microsoft.Network/virtualNetworks/subnets@2020-06-01' = {
  name: '${vnetName}/${subnetName}'
  properties: {
    addressPrefix: '10.0.0.0/24'
  }
  dependsOn: [
    vnetName_res
  ]
}

resource serviceName_res 'Microsoft.DataMigration/services@2018-07-15-preview' = {
  name: serviceName
  location: location
  sku: {
    tier: 'Standard'
    size: '1 vCores'
    name: 'Standard_1vCores'
  }
  properties: {
    virtualSubnetId: vnetName_subnetName.id
  }
}