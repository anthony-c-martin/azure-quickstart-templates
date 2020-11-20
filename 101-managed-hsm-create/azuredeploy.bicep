param managedHSMName string {
  metadata: {
    description: 'String specifying the name of the managed HSM.'
  }
}
param location string {
  allowed: [
    'eastus2'
    'northeurope'
    'southcentralus'
    'westeurope'
  ]
  metadata: {
    description: 'String specifying the Azure location where the managed HSM should be created.'
  }
}
param initialAdminObjectIds array {
  metadata: {
    description: 'Array specifying the objectIDs associated with a list of initial administrators.'
  }
  default: [
    'objectid1'
    'objectid2'
  ]
}
param tenantId string {
  metadata: {
    description: 'String specifying the Azure Active Directory tenant ID that should be used for authenticating requests to the managed HSM.'
  }
  default: subscription().tenantId
}

resource managedHSMName_res 'Microsoft.KeyVault/managedHSMs@2020-04-01-preview' = {
  name: managedHSMName
  location: location
  tags: {
    resourceType: 'MHSM'
    Environment: 'PROD'
  }
  sku: {
    name: 'Standard_B1'
    family: 'B'
  }
  properties: {
    enableSoftDelete: true
    softDeleteRetentionInDays: 90
    enablePurgeProtection: false
    tenantId: tenantId
    initialAdminObjectIds: initialAdminObjectIds
  }
}