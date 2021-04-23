@description('Name of the VNet')
param virtualNetwork_name string

@description('Name of the Web Farm')
param serverFarm_name string = 'ServerFarm1'

@description('Web App name must be unique DNS name worldwide')
param site_name string

@description('CIDR of your VNet')
param virtualNetwork_CIDR string = '10.200.0.0/16'

@description('Name of the Subnet')
param subnet1_name string

@description('CIDR of your subnet')
param subnet1_CIDR string = '10.200.1.0/24'

@description('Location for all resources.')
param location string = resourceGroup().location

@description('SKU name, must be minimum P1v2')
param SKU_name string = 'P1v2'

@description('SKU tier, must be Premium')
param SKU_tier string = 'PremiumV2'

@description('SKU size, must be minimum P1v2')
param SKU_size string = 'P1v2'

@description('SKU family, must be minimum P1v2')
param SKU_family string = 'P1v2'

@description('Name of your Private Endpoint')
param privateEndpoint_name string

@description('Link name between your Private Endpoint and your Web App')
param privateLinkConnection_name string

@description('Name must be privatelink.azurewebsites.net')
param privateDNSZone_name string = 'privatelink.azurewebsites.net'

@description('Name must be privatelink.azurewebsites.net')
param webapp_dns_name string = '.azurewebsites.net'

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

resource site_name_resource 'Microsoft.Web/sites@2019-08-01' = {
  name: site_name
  location: location
  kind: 'app'
  properties: {
    enabled: true
    hostNameSslStates: [
      {
        name: concat(site_name, webapp_dns_name)
        sslState: 'Disabled'
        hostType: 'Standard'
      }
      {
        name: '${site_name}.scm${webapp_dns_name}'
        sslState: 'Disabled'
        hostType: 'Repository'
      }
    ]
    serverFarmId: serverFarm_name_resource.id
  }
}

resource site_name_web 'Microsoft.Web/sites/config@2019-08-01' = {
  parent: site_name_resource
  name: 'web'
  location: location
  properties: {
    ftpsState: 'AllAllowed'
  }
}

resource site_name_site_name_webapp_dns_name 'Microsoft.Web/sites/hostNameBindings@2019-08-01' = {
  parent: site_name_resource
  name: '${site_name}${webapp_dns_name}'
  location: location
  properties: {
    siteName: site_name
    hostNameType: 'Verified'
  }
}

resource privateEndpoint_name_resource 'Microsoft.Network/privateEndpoints@2019-04-01' = {
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
          privateLinkServiceId: site_name_resource.id
          groupIds: [
            'sites'
          ]
        }
      }
    ]
  }
}

resource privateDNSZone_name_resource 'Microsoft.Network/privateDnsZones@2018-09-01' = {
  name: privateDNSZone_name
  location: 'global'
  dependsOn: [
    virtualNetwork_name_resource
  ]
}

resource privateDNSZone_name_privateDNSZone_name_link 'Microsoft.Network/privateDnsZones/virtualNetworkLinks@2018-09-01' = {
  parent: privateDNSZone_name_resource
  name: '${privateDNSZone_name}-link'
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
          privateDnsZoneId: privateDNSZone_name_resource.id
        }
      }
    ]
  }
}