param location string {
  metadata: {
    description: 'Location for all resources.'
  }
  default: resourceGroup().location
}

resource availabilitySet1 'Microsoft.Compute/availabilitySets@2020-06-01' = {
  name: 'availabilitySet1'
  location: location
  properties: {
    platformFaultDomainCount: 3
    platformUpdateDomainCount: 20
  }
}