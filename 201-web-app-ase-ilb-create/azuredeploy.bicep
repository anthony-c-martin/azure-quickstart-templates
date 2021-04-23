@description('Name of the App Service Environment')
param aseName string

@allowed([
  'Central US'
  'East US'
  'East US 2'
  'North Central US'
  'South Central US'
  'West US'
  'Canada Central'
  'North Europe'
  'West Europe'
  'East Asia'
  'Southeast Asia'
  'Japan East'
  'Japan West'
  'Brazil South'
  'Australia East'
  'Australia Southeast'
  'West India'
  'Central India'
  'South India'
])
@description('Location of the App Service Environment')
param aseLocation string

@description('Number of IP addresses for the IP-SSL address pool.  This value *must* be zero when internalLoadBalancing mode is set to either 1 or 3.')
param ipSslAddressCount int = 0

@description('ARM Url reference for the virtual network that will contain the ASE.  Use Microsoft.Network for ARM vnets.  Use Microsoft.ClassicNetwork for older ASM vnets.  /subscriptions/subIDGoesHere/resourceGroups/rgNameGoesHere/providers/Microsoft.Network/virtualNetworks/vnetnamegoeshere')
param existingVnetResourceId string

@description('Subnet name that will contain the App Service Environment')
param subnetName string

@description('0 = public VIP only, 1 = only ports 80/443 are mapped to ILB VIP, 2 = only FTP ports are mapped to ILB VIP, 3 = both ports 80/443 and FTP ports are mapped to an ILB VIP.')
param internalLoadBalancingMode int = 3

@description('Used *only* when deploying an ILB enabled ASE.  Set this to the root domain associated with the ASE.  For example: contoso.com')
param dnsSuffix string

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

resource aseName_resource 'Microsoft.Web/hostingEnvironments@2015-08-01' = {
  name: aseName
  location: aseLocation
  properties: {
    name: aseName
    location: aseLocation
    ipSslAddressCount: ipSslAddressCount
    internalLoadBalancingMode: internalLoadBalancingMode
    dnsSuffix: dnsSuffix
    virtualNetwork: {
      Id: existingVnetResourceId
      Subnet: subnetName
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