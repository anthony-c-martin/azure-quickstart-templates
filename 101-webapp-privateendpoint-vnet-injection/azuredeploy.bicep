@description('Name of the VNet')
param virtualNetwork_name string = 'vnet1'

@description('Name of the Web Farm')
param serverFarm_name string = 'serverfarm'

@description('Web App 1 name must be unique DNS name worldwide')
param site1_name string = 'webapp1${uniqueString(resourceGroup().id)}'

@description('Web App 2 name must be unique DNS name worldwide')
param site2_name string = 'webapp2${uniqueString(resourceGroup().id)}'

@description('CIDR of your VNet')
param virtualNetwork_CIDR string = '10.200.0.0/16'

@description('Name of the subnet')
param subnet1_name string = 'Subnet1'

@description('Name of the subnet')
param subnet2_name string = 'Subnet2'

@description('CIDR of your subnet')
param subnet1_CIDR string = '10.200.1.0/24'

@description('CIDR of your subnet')
param subnet2_CIDR string = '10.200.2.0/24'

@description('Location for all resources.')
param location string = resourceGroup().location

@allowed([
  'P1v2'
  'P2v2'
  'P3v2'
])
@description('SKU name, must be minimum P1v2')
param SKU_name string = 'P1v2'

@allowed([
  'P1v2'
  'P2v2'
  'P3v2'
])
@description('SKU size, must be minimum P1v2')
param SKU_size string = 'P1v2'

@allowed([
  'P1v2'
  'P2v2'
  'P3v2'
])
@description('SKU family, must be minimum P1v2')
param SKU_family string = 'P1v2'

@description('Name of your Private Endpoint')
param privateEndpoint_name string = 'PrivateEndpoint1'

@description('Link name between your Private Endpoint and your Web App')
param privateLinkConnection_name string = 'PrivateEndpointLink1'

var webapp_dns_name = '.azurewebsites.net'
var privateDNSZone_name_var = 'privatelink.azurewebsites.net'
var SKU_tier = 'PremiumV2'

resource virtualNetwork_name_resource 'Microsoft.Network/virtualNetworks@2020-04-01' = {
  name: virtualNetwork_name
  location: location
  properties: {
    addressSpace: {
      addressPrefixes: [
        virtualNetwork_CIDR
      ]
    }
  }
}

resource virtualNetwork_name_subnet1_name 'Microsoft.Network/virtualNetworks/subnets@2020-04-01' = {
  parent: virtualNetwork_name_resource
  name: '${subnet1_name}'
  properties: {
    addressPrefix: subnet1_CIDR
    privateEndpointNetworkPolicies: 'Disabled'
  }
}

resource virtualNetwork_name_subnet2_name 'Microsoft.Network/virtualNetworks/subnets@2020-04-01' = {
  parent: virtualNetwork_name_resource
  name: '${subnet2_name}'
  properties: {
    addressPrefix: subnet2_CIDR
    delegations: [
      {
        name: 'delegation'
        properties: {
          serviceName: 'Microsoft.Web/serverfarms'
        }
      }
    ]
    privateEndpointNetworkPolicies: 'Enabled'
  }
  dependsOn: [
    virtualNetwork_name_subnet1_name
  ]
}

resource serverFarm_name_resource 'Microsoft.Web/serverfarms@2019-08-01' = {
  name: serverFarm_name
  location: location
  sku: {
    name: SKU_name
    tier: SKU_tier
    size: SKU_size
    family: SKU_family
    capacity: 1
  }
  kind: 'app'
}

resource site1_name_resource 'Microsoft.Web/sites@2019-08-01' = {
  name: site1_name
  location: location
  kind: 'app'
  properties: {
    serverFarmId: serverFarm_name_resource.id
  }
}

resource site2_name_resource 'Microsoft.Web/sites@2019-08-01' = {
  name: site2_name
  location: location
  kind: 'app'
  properties: {
    serverFarmId: serverFarm_name_resource.id
  }
}

resource site2_name_appsettings 'Microsoft.Web/sites/config@2018-11-01' = {
  parent: site2_name_resource
  name: 'appsettings'
  properties: {
    WEBSITE_DNS_SERVER: '168.63.129.16'
    WEBSITE_VNET_ROUTE_ALL: '1'
  }
}

resource site1_name_web 'Microsoft.Web/sites/config@2019-08-01' = {
  parent: site1_name_resource
  name: 'web'
  location: location
  properties: {
    ftpsState: 'AllAllowed'
  }
}

resource site2_name_web 'Microsoft.Web/sites/config@2019-08-01' = {
  parent: site2_name_resource
  name: 'web'
  location: location
  properties: {
    ftpsState: 'AllAllowed'
  }
}

resource site1_name_site1_name_webapp_dns_name 'Microsoft.Web/sites/hostNameBindings@2019-08-01' = {
  parent: site1_name_resource
  name: '${site1_name}${webapp_dns_name}'
  location: location
  properties: {
    siteName: site1_name
    hostNameType: 'Verified'
  }
}

resource site2_name_site2_name_webapp_dns_name 'Microsoft.Web/sites/hostNameBindings@2019-08-01' = {
  parent: site2_name_resource
  name: '${site2_name}${webapp_dns_name}'
  location: location
  properties: {
    siteName: site2_name
    hostNameType: 'Verified'
  }
}

resource site2_name_VirtualNetwork 'Microsoft.Web/sites/networkConfig@2019-08-01' = {
  parent: site2_name_resource
  name: 'virtualNetwork'
  location: location
  properties: {
    subnetResourceId: virtualNetwork_name_subnet2_name.id
  }
}

resource privateEndpoint_name_resource 'Microsoft.Network/privateEndpoints@2020-05-01' = {
  name: privateEndpoint_name
  location: location
  properties: {
    subnet: {
      id: virtualNetwork_name_subnet1_name.id
    }
    privateLinkServiceConnections: [
      {
        name: privateLinkConnection_name
        properties: {
          privateLinkServiceId: site1_name_resource.id
          groupIds: [
            'sites'
          ]
        }
      }
    ]
  }
}

resource privateDNSZone_name 'Microsoft.Network/privateDnsZones@2018-09-01' = {
  name: privateDNSZone_name_var
  location: 'global'
  dependsOn: [
    virtualNetwork_name_resource
  ]
}

resource privateDNSZone_name_privateDNSZone_name_link 'Microsoft.Network/privateDnsZones/virtualNetworkLinks@2018-09-01' = {
  parent: privateDNSZone_name
  name: '${privateDNSZone_name_var}-link'
  location: 'global'
  properties: {
    registrationEnabled: false
    virtualNetwork: {
      id: virtualNetwork_name_resource.id
    }
  }
}

resource privateEndpoint_name_dnsgroupname 'Microsoft.Network/privateEndpoints/privateDnsZoneGroups@2020-03-01' = {
  parent: privateEndpoint_name_resource
  name: 'dnsgroupname'
  location: location
  properties: {
    privateDnsZoneConfigs: [
      {
        name: 'config1'
        properties: {
          privateDnsZoneId: privateDNSZone_name.id
        }
      }
    ]
  }
}