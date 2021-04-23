@description('AVSet name the VM will belong to')
param availabilitySetName string = 'AvSet1'

@description('Location for all resources.')
param location string = resourceGroup().location

resource availabilitySetName_resource 'Microsoft.Compute/availabilitySets@2017-12-01' = {
  name: availabilitySetName
  location: location
  sku: {
    name: 'Aligned'
  }
  properties: {
    platformFaultDomainCount: 2
    platformUpdateDomainCount: 5
  }
}