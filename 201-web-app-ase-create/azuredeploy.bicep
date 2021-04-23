@description('Name of the App Service Environment')
param aseName string

@description('Location of the App Service Environment')
param location string = resourceGroup().location

@description('Number of IP addresses for the IP-SSL address pool.')
param ipSslAddressCount int = 1

@description('Subnet name that will contain the App Service Environment')
param subnetName string

@description('Subnet Id that will contain the App Service Environment')
param subnetId string

@allowed([
  'Medium'
  'Large'
  'ExtraLarge'
])
@description('Instance size for the front-end pool.  Maps to P2,P3,P4.')
param frontEndSize string = 'Medium'

@description('Number of instances in the front-end pool.  Minimum of two.')
param frontEndCount int = 2

@allowed([
  'Small'
  'Medium'
  'Large'
  'ExtraLarge'
])
@description('Instance size for worker pool one.  Maps to P1,P2,P3,P4.')
param workerPoolOneInstanceSize string = 'Small'

@description('Number of instances in worker pool one.  Minimum of two.')
param workerPoolOneInstanceCount int = 2

@allowed([
  'Small'
  'Medium'
  'Large'
  'ExtraLarge'
])
@description('Instance size for worker pool two.  Maps to P1,P2,P3,P4.')
param workerPoolTwoInstanceSize string = 'Small'

@description('Number of instances in worker pool two.  Can be zero if not using worker pool two.')
param workerPoolTwoInstanceCount int = 0

@allowed([
  'Small'
  'Medium'
  'Large'
  'ExtraLarge'
])
@description('Instance size for worker pool three.  Maps to P1,P2,P3,P4.')
param workerPoolThreeInstanceSize string = 'Small'

@description('Number of instances in worker pool three.  Can be zero if not using worker pool three.')
param workerPoolThreeInstanceCount int = 0

resource aseName_resource 'Microsoft.Web/hostingEnvironments@2020-06-01' = {
  name: aseName
  location: location
  properties: {
    name: aseName
    location: location
    ipsslAddressCount: ipSslAddressCount
    virtualNetwork: {
      id: subnetId
      subnet: subnetName
    }
    multiSize: frontEndSize
    multiRoleCount: frontEndCount
    workerPools: [
      {
        workerSizeId: 0
        workerSize: workerPoolOneInstanceSize
        workerCount: workerPoolOneInstanceCount
      }
      {
        workerSizeId: 1
        workerSize: workerPoolTwoInstanceSize
        workerCount: workerPoolTwoInstanceCount
      }
      {
        workerSizeId: 2
        workerSize: workerPoolThreeInstanceSize
        workerCount: workerPoolThreeInstanceCount
      }
    ]
  }
}