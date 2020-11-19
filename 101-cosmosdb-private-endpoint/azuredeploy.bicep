param location string {
  metadata: {
    description: 'Location for all resources.'
  }
  default: resourceGroup().location
}
param virtualNetworkName string {
  metadata: {
    description: 'Virtual network name'
  }
}
param accountName string {
  metadata: {
    description: 'Cosmos DB account name, max length 44 characters'
  }
}
param publicNetworkAccess string {
  allowed: [
    'Enabled'
    'Disabled'
  ]
  metadata: {
    description: 'Enable public network traffic to access the account; if set to Disabled, public network traffic will be blocked even before the private endpoint is created'
  }
  default: 'Enabled'
}
param privateEndpointName string {
  metadata: {
    description: 'Private endpoint name'
  }
}

var accountName_variable = toLower(accountName)
var locations = [
  {
    locationName: location
    failoverPriority: 0
    isZoneRedundant: false
  }
]

resource virtualNetworkName_resource 'Microsoft.Network/VirtualNetworks@2019-09-01' = {
  name: virtualNetworkName
  location: location
  properties: {
    addressSpace: {
      addressPrefixes: [
        '172.20.0.0/16'
      ]
    }
    subnets: [
      {
        name: 'default'
        properties: {
          addressPrefix: '172.20.0.0/24'
          privateEndpointNetworkPolicies: 'Disabled'
        }
      }
    ]
  }
}

resource accountName_resource 'Microsoft.DocumentDB/databaseAccounts@2020-03-01' = {
  name: accountName_variable
  kind: 'GlobalDocumentDB'
  location: location
  properties: {
    consistencyPolicy: {
      Session: {
        defaultConsistencyLevel: 'Session'
      }
    }
    locations: locations
    databaseAccountOfferType: 'Standard'
    enableAutomaticFailover: false
    enableMultipleWriteLocations: false
    publicNetworkAccess: publicNetworkAccess
  }
}

resource privateEndpointName_resource 'Microsoft.Network/privateEndpoints@2019-04-01' = {
  name: privateEndpointName
  location: location
  properties: {
    subnet: {
      id: resourceId('Microsoft.Network/VirtualNetworks/subnets', virtualNetworkName, 'Default')
    }
    privateLinkServiceConnections: [
      {
        name: 'MyConnection'
        properties: {
          privateLinkServiceId: accountName_resource.id
          groupIds: [
            'Sql'
          ]
        }
      }
    ]
  }
  dependsOn: [
    accountName_resource
    virtualNetworkName_resource
  ]
}