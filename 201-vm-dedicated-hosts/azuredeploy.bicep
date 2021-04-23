@description('Location for the resources.')
param location string = resourceGroup().location

@description('How many Zone to use. Use 0 for non zonal deployment.')
param numberOfZoness int = 0

@description('How many hosts to create per zone.')
param numberofHostsPerZone int = 2

@description('How many fault domains to use. ')
param numberOfFDs int = 2

@description('Name (prefix) for your host group.')
param dhgNamePrefix string = 'myHostGroup'

@description('Name (prefix) for your host .')
param dhNamePrefix string = 'myHost'

@description('The type (family and generation) for your host .')
param dhSKU string = 'DSv3-Type1'

var numberOfHosts = ((numberOfZoness == 0) ? numberofHostsPerZone : (numberOfZoness * numberofHostsPerZone))

resource dhgNamePrefix_resource 'Microsoft.Compute/HostGroups@2018-10-01' = [for i in range(0, ((numberOfZoness == 0) ? 1 : numberOfZoness)): {
  name: concat(dhgNamePrefix, i)
  location: location
  zones: ((numberOfZoness == 0) ? json('null') : array((i + 1)))
  properties: {
    platformFaultDomainCount: numberOfFDs
  }
}]

resource dhgNamePrefix_numberofHostsPerZone_dhNamePrefix_numberofHostsPerZone_numberofHostsPerZone 'Microsoft.Compute/Hostgroups/hosts@2018-10-01' = [for i in range(0, numberOfHosts): {
  name: '${dhgNamePrefix}${(i / numberofHostsPerZone)}/${dhNamePrefix}${(i / numberofHostsPerZone)}${(i % numberofHostsPerZone)}'
  location: location
  sku: {
    name: dhSKU
  }
  properties: {
    platformFaultDomain: (i % numberOfFDs)
  }
  dependsOn: [
    'Microsoft.Compute/hostGroups/${dhgNamePrefix}${(i / numberofHostsPerZone)}'
  ]
}]

output hostCount int = numberOfHosts