@description('Traffic Manager profile DNS name. Must be unique in .trafficmanager.net')
param dnsName string

@allowed([
  'East Asia'
  'Southeast Asia'
  'Central US'
  'East US'
  'East US 2'
  'West US'
  'North Central US'
  'South Central US'
  'North Europe'
  'West Europe'
  'Japan West'
  'Japan East'
  'Brazil South'
  'Canada Central'
  'Canada East'
])
@description('Location of the primary endpoint')
param primarylocation string = 'East US'

@allowed([
  'East Asia'
  'Southeast Asia'
  'Central US'
  'East US'
  'East US 2'
  'West US'
  'North Central US'
  'South Central US'
  'North Europe'
  'West Europe'
  'Japan West'
  'Japan East'
  'Brazil South'
  'Canada Central'
  'Canada East'
])
@description('Location of the secondary endpoint')
param secondarylocation string = 'West US'

@allowed([
  'Priority'
  'Weighted'
  'Performance'
])
@description('Traffic routing methods available in Traffic Manager')
param trafficRoutingMethod string = 'Priority'

@minLength(1)
@description('User name for the backend Web servers')
param adminUsername string

@description('Password for the backend Web servers')
@secure()
param adminPassword string

@description('The base URI where artifacts required by this template are located.')
param artifactsLocation string = 'https://raw.githubusercontent.com/Azure/azure-quickstart-templates/master/traffic-manager-application-gateway-demo-setup/'

@description('Location for all resources.')
param location string = resourceGroup().location

var virtualNetworkName_var = 'virtualNetwork1'
var subnetName = 'subnet1'
var addressPrefix = '10.0.0.0/16'
var subnetPrefix = '10.0.0.0/28'
var nestedTemplatesFolder = 'nested'
var appGwTemplateName = 'azuredeployappgw.json'
var location_var = [
  primarylocation
  secondarylocation
]

module appgw_1 'nested/azuredeployappgw.bicep' = [for i in range(0, 2): {
  name: 'appgw${(i + 1)}'
  params: {
    adminUsername: adminUsername
    adminPassword: adminPassword
    location: location_var[i]
    appGwName: 'appgw${(i + 1)}'
    '_artifactsLocation': '${artifactsLocation}/${nestedTemplatesFolder}'
  }
}]

resource virtualNetworkName 'Microsoft.Network/virtualNetworks@2015-06-15' = {
  name: virtualNetworkName_var
  location: location
  properties: {
    addressSpace: {
      addressPrefixes: [
        addressPrefix
      ]
    }
    subnets: [
      {
        name: subnetName
        properties: {
          addressPrefix: subnetPrefix
        }
      }
    ]
  }
}

resource trafficManagerDemo 'Microsoft.Network/trafficManagerProfiles@2015-11-01' = {
  name: 'trafficManagerDemo'
  location: 'global'
  properties: {
    profileStatus: 'Enabled'
    trafficRoutingMethod: trafficRoutingMethod
    dnsConfig: {
      relativeName: dnsName
      ttl: 30
    }
    monitorConfig: {
      protocol: 'HTTP'
      port: 80
      path: '/'
    }
    endpoints: [
      {
        name: 'endpoint1'
        type: 'Microsoft.Network/trafficManagerProfiles/azureEndpoints'
        properties: {
          targetResourceId: reference('appgw1').outputs.ipId.value
          endpointStatus: 'Enabled'
          weight: 1
        }
      }
      {
        name: 'endpoint2'
        type: 'Microsoft.Network/trafficManagerProfiles/azureEndpoints'
        properties: {
          targetResourceId: reference('appgw2').outputs.ipId.value
          endpointStatus: 'Enabled'
          weight: 1
        }
      }
    ]
  }
  dependsOn: [
    virtualNetworkName
    appgw_1
  ]
}