@description('Number of IP addresses for the IP-SSL address pool.')
param ASE_ipSslAddressCount int = 1

@allowed([
  'Medium'
  'Large'
  'ExtraLarge'
])
@description('Instance size for the front-end pool.  Maps to P2,P3,P4.')
param ASE_frontEndSize string = 'Medium'

@minValue(2)
@maxValue(100)
@description('Number of instances in the front-end pool.  Minimum of two.')
param ASE_frontEndCount int = 2

@allowed([
  'Small'
  'Medium'
  'Large'
  'ExtraLarge'
])
@description('Instance size for worker pool one.  Maps to P1,P2,P3,P4.')
param ASE_workerPoolOneInstanceSize string = 'Small'

@minValue(2)
@maxValue(100)
@description('Number of instances in worker pool one.  Minimum of two.')
param ASE_workerPoolOneInstanceCount int = 2

@allowed([
  'Small'
  'Medium'
  'Large'
  'ExtraLarge'
])
@description('Instance size for worker pool two.  Maps to P1,P2,P3,P4.')
param ASE_workerPoolTwoInstanceSize string = 'Small'

@description('Number of instances in worker pool two.  Can be zero if not using worker pool two.')
param ASE_workerPoolTwoInstanceCount int = 0

@allowed([
  'Small'
  'Medium'
  'Large'
  'ExtraLarge'
])
@description('Instance size for worker pool three.  Maps to P1,P2,P3,P4.')
param ASE_workerPoolThreeInstanceSize string = 'Small'

@description('Number of instances in worker pool three.  Can be zero if not using worker pool three.')
param ASE_workerPoolThreeInstanceCount int = 0

@allowed([
  '1'
  '2'
  '3'
])
@description('Defines which worker pool\'s (WP1, WP2 or WP3) resources will be used for the app service plan.')
param ASE_APP_SERVICE_workerPool string = '1'

@description('Defines the number of workers from the worker pool that will be used by the app service plan.')
param ASE_APP_SERVICE_numberOfWorkersFromWorkerPool int = 1

@description('Location for all resources.')
param location string = resourceGroup().location

var ASE_VNETPrefix = '10.0.0.0/16'
var ASE_VNETSubnet1Name = 'Subnet-1'
var ASE_VNETSubnet1Prefix = '10.0.0.0/24'
var ASE_VNETSubnet2Name = 'Subnet-2'
var ASE_VNETSubnet2Prefix = '10.0.1.0/24'
var ASE_WEB_APP_Name_var = 'ASE-WEB-APP${uniqueString(resourceGroup().id)}'
var ASE_Name_var = 'ASE${uniqueString(resourceGroup().id)}'
var ASE_VNET_Name_var = 'ASE-VNET${uniqueString(resourceGroup().id)}'
var ASE_SERVICE_Name_var = 'ASE-SERVICE${uniqueString(resourceGroup().id)}'

resource ASE_VNET_Name 'Microsoft.Network/virtualNetworks@2020-05-01' = {
  name: ASE_VNET_Name_var
  location: location
  tags: {
    displayName: 'ASE-VNET'
  }
  properties: {
    addressSpace: {
      addressPrefixes: [
        ASE_VNETPrefix
      ]
    }
    subnets: [
      {
        name: ASE_VNETSubnet1Name
        properties: {
          addressPrefix: ASE_VNETSubnet1Prefix
        }
      }
      {
        name: ASE_VNETSubnet2Name
        properties: {
          addressPrefix: ASE_VNETSubnet2Prefix
        }
      }
    ]
  }
}

resource ASE_Name 'Microsoft.Web/hostingEnvironments@2019-08-01' = {
  name: ASE_Name_var
  location: location
  tags: {
    'hidden-related:${ASE_SERVICE_Name.id}': 'Resource'
    'hidden-related:${ASE_WEB_APP_Name.id}': 'Resource'
    displayName: 'ASE'
  }
  properties: {
    name: ASE_Name_var
    location: location
    ipsslAddressCount: ASE_ipSslAddressCount
    virtualNetwork: {
      id: resourceId('Microsoft.Network/virtualNetworks/subnets', ASE_VNET_Name_var, ASE_VNETSubnet1Name)
    }
    multiSize: ASE_frontEndSize
    multiRoleCount: ASE_frontEndCount
    workerPools: [
      {
        workerSizeId: 0
        workerSize: ASE_workerPoolOneInstanceSize
        workerCount: ASE_workerPoolOneInstanceCount
      }
      {
        workerSizeId: 1
        workerSize: ASE_workerPoolTwoInstanceSize
        workerCount: ASE_workerPoolTwoInstanceCount
      }
      {
        workerSizeId: 2
        workerSize: ASE_workerPoolThreeInstanceSize
        workerCount: ASE_workerPoolThreeInstanceCount
      }
    ]
  }
  dependsOn: [
    ASE_VNET_Name
  ]
}

resource ASE_SERVICE_Name 'Microsoft.Web/serverfarms@2019-08-01' = {
  name: ASE_SERVICE_Name_var
  location: location
  tags: {
    displayName: 'ASE-APP-SERVICE-APP'
  }
  properties: {
    name: ASE_SERVICE_Name_var
    hostingEnvironment: ASE_Name_var
    hostingEnvironmentId: ASE_Name.id
  }
  sku: {
    name: 'P${ASE_APP_SERVICE_workerPool}'
    tier: 'Premium'
    size: 'P${ASE_APP_SERVICE_workerPool}'
    family: 'P'
    capacity: ASE_APP_SERVICE_numberOfWorkersFromWorkerPool
  }
}

resource ASE_WEB_APP_Name 'Microsoft.Web/sites@2019-08-01' = {
  name: ASE_WEB_APP_Name_var
  location: location
  tags: {
    'hidden-related:${ASE_SERVICE_Name.id}': 'Resource'
    displayName: 'ASE-WEB-APP'
  }
  properties: {
    name: ASE_WEB_APP_Name_var
    serverFarmId: ASE_SERVICE_Name.id
    hostingEnvironment: ASE_Name_var
    hostingEnvironmentId: ASE_Name.id
  }
}