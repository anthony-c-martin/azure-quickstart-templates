@description('Name of the App Service Environment')
param aseName string

@description('The resource group name that contains the vnet')
param vnetResourceGroupName string

@description('The name of the vnet')
param vnetResourceName string

@description('Subnet name that will contain the App Service Environment')
param subnetName string

@description('Specific parameter used because the ASE api can\'t handle the resource group location')
param aseLocation string = 'West US'

@allowed([
  0
  1
  2
  3
])
@description('0 = public VIP only, 1 = only ports 80/443 are mapped to ILB VIP, 2 = only FTP ports are mapped to ILB VIP, 3 = both ports 80/443 and FTP ports are mapped to an ILB VIP.')
param internalLoadBalancingMode int = 3

@description('Used when deploying an ILB enabled ASE.  Set this to the root domain associated with the ASE.  For example: contoso.com')
param dnsSuffix string

@description('The name of the web app that will be created.')
param siteName string

@description('The name of the App Service plan to use for hosting the web app.')
param appServicePlanName string

@description('The owner of the resource will be used for tagging.')
param owner string

@allowed([
  '1'
  '2'
  '3'
])
@description('Defines which worker pool\'s (WP1, WP2 or WP3) resources will be used for the app service plan.')
param workerPool string = '1'

@description('Defines the number of workers from the worker pool that will be used by the app service plan.')
param numberOfWorkersFromWorkerPool int = 1

var vnetID = resourceId(vnetResourceGroupName, 'Microsoft.Network/virtualNetworks', vnetResourceName)

resource aseName_resource 'Microsoft.Web/hostingEnvironments@2016-09-01' = {
  name: aseName
  kind: 'ASEV2'
  location: aseLocation
  tags: {
    displayName: 'ASE Environment'
    usage: 'Hosting PaaS applications'
    category: 'Environment'
    owner: owner
  }
  properties: {
    name: aseName
    location: aseLocation
    ipsslAddressCount: 0
    internalLoadBalancingMode: internalLoadBalancingMode
    dnsSuffix: dnsSuffix
    virtualNetwork: {
      id: vnetID
      subnet: subnetName
    }
  }
}

resource appServicePlanName_resource 'Microsoft.Web/serverfarms@2016-09-01' = {
  name: appServicePlanName
  location: aseLocation
  tags: {
    displayName: 'ASE Hosting Plan'
    usage: 'Hosting Plan within ASE'
    category: 'Hosting'
    owner: owner
  }
  properties: {
    name: appServicePlanName
    hostingEnvironmentProfile: {
      id: aseName_resource.id
    }
  }
  sku: {
    name: 'I${workerPool}'
    tier: 'Isolated'
    size: 'I${workerPool}'
    family: 'I'
    capacity: numberOfWorkersFromWorkerPool
  }
}

resource siteName_resource 'Microsoft.Web/sites@2016-08-01' = {
  name: siteName
  location: resourceGroup().location
  tags: {
    displayName: 'ASE Web App'
    usage: 'Web App Hosted within ASE'
    category: 'Web App'
    owner: owner
  }
  properties: {
    name: siteName
    serverFarmId: appServicePlanName_resource.id
    hostingEnvironmentProfile: {
      id: aseName_resource.id
    }
  }
}