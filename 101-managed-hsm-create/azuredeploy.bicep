@description('String specifying the name of the managed HSM.')
param managedHSMName string

@allowed([
  'eastus2'
  'northeurope'
  'southcentralus'
  'westeurope'
])
@description('String specifying the Azure location where the managed HSM should be created.')
param location string

@description('Array specifying the objectIDs associated with a list of initial administrators.')
param initialAdminObjectIds array = [
  'objectid1'
  'objectid2'
]

@description('String specifying the Azure Active Directory tenant ID that should be used for authenticating requests to the managed HSM.')
param tenantId string = subscription().tenantId

resource managedHSMName_resource 'Microsoft.KeyVault/managedHSMs@2020-04-01-preview' = {
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