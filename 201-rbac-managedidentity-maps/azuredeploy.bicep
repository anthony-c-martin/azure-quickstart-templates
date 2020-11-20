param location string {
  metadata: {
    description: 'location for the the resources to deploy.'
  }
  default: resourceGroup().location
}
param userAssignedIdentityName string {
  metadata: {
    description: 'the name of the Managed Identity resource.'
  }
}
param mapsAccountName string {
  metadata: {
    description: 'the name of the Azure Map Account'
  }
}
param guid string {
  metadata: {
    description: 'Input string for new GUID associated with assigning built in role types'
  }
  default: guid(resourceGroup().id)
}

var Azure_Maps_Data_Reader = subscriptionResourceId('Microsoft.Authorization/roleDefinitions', '423170ca-a8f6-4b0f-8487-9e4eb8f49bfa')

resource userAssignedIdentityName_res 'Microsoft.ManagedIdentity/userAssignedIdentities@2018-11-30' = {
  name: userAssignedIdentityName
  location: location
}

resource mapsAccountName_res 'Microsoft.Maps/accounts@2018-05-01' = {
  name: mapsAccountName
  location: 'global'
  sku: {
    name: 'S0'
  }
}

resource mapsAccountName_Microsoft_Authorization_guid 'Microsoft.Maps/accounts/providers/roleAssignments@2018-09-01-preview' = {
  name: '${mapsAccountName}/Microsoft.Authorization/${guid}'
  properties: {
    roleDefinitionId: Azure_Maps_Data_Reader
    principalId: reference(userAssignedIdentityName).principalId
    principalType: 'ServicePrincipal'
  }
  dependsOn: [
    mapsAccountName_res
    userAssignedIdentityName_res
  ]
}