param virtualNetwork_name string {
  metadata: {
    description: 'Name of the VNet'
  }
}
param serverFarm_name string {
  metadata: {
    description: 'Name of the Web Farm'
  }
  default: 'ServerFarm1'
}
param site_name string {
  metadata: {
    description: 'Web App name must be unique DNS name worldwide'
  }
}
param virtualNetwork_CIDR string {
  metadata: {
    description: 'CIDR of your VNet'
  }
  default: '10.200.0.0/16'
}
param subnet1_name string {
  metadata: {
    description: 'Name of the Subnet'
  }
}
param subnet1_CIDR string {
  metadata: {
    description: 'CIDR of your subnet'
  }
  default: '10.200.1.0/24'
}
param location string {
  metadata: {
    description: 'Location for all resources.'
  }
  default: resourceGroup().location
}
param SKU_name string {
  metadata: {
    description: 'SKU name, must be minimum P1v2'
  }
  default: 'P1v2'
}
param SKU_tier string {
  metadata: {
    description: 'SKU tier, must be Premium'
  }
  default: 'PremiumV2'
}
param SKU_size string {
  metadata: {
    description: 'SKU size, must be minimum P1v2'
  }
  default: 'P1v2'
}
param SKU_family string {
  metadata: {
    description: 'SKU family, must be minimum P1v2'
  }
  default: 'P1v2'
}
param privateEndpoint_name string {
  metadata: {
    description: 'Name of your Private Endpoint'
  }
}
param privateLinkConnection_name string {
  metadata: {
    description: 'Link name between your Private Endpoint and your Web App'
  }
}
param privateDNSZone_name string {
  metadata: {
    description: 'Name must be privatelink.azurewebsites.net'
  }
  default: 'privatelink.azurewebsites.net'
}
param webapp_dns_name string {
  metadata: {
    description: 'Name must be privatelink.azurewebsites.net'
  }
  default: '.azurewebsites.net'
}

resource virtualNetwork_name_res 'Microsoft.Network/virtualNetworks@2020-04-01' = {
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
  name: '${virtualNetwork_name}/${subnet1_name}'
  properties: {
    addressPrefix: subnet1_CIDR
    privateEndpointNetworkPolicies: 'Disabled'
  }
  dependsOn: [
    virtualNetwork_name_res
  ]
}

resource serverFarm_name_res 'Microsoft.Web/serverfarms@2019-08-01' = {
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

resource site_name_res 'Microsoft.Web/sites@2019-08-01' = {
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
    serverFarmId: serverFarm_name_res.id
  }
}

resource site_name_web 'Microsoft.Web/sites/config@2019-08-01' = {
  name: '${site_name}/web'
  location: location
  properties: {
    ftpsState: 'AllAllowed'
  }
  dependsOn: [
    site_name_res
  ]
}

resource site_name_site_name_webapp_dns_name 'Microsoft.Web/sites/hostNameBindings@2019-08-01' = {
  name: '${site_name}/${site_name}${webapp_dns_name}'
  location: location
  properties: {
    siteName: site_name
    hostNameType: 'Verified'
  }
  dependsOn: [
    site_name_res
  ]
}

resource privateEndpoint_name_res 'Microsoft.Network/privateEndpoints@2019-04-01' = {
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
          privateLinkServiceId: site_name_res.id
          groupIds: [
            'sites'
          ]
        }
      }
    ]
  }
}

resource privateDNSZone_name_res 'Microsoft.Network/privateDnsZones@2018-09-01' = {
  name: privateDNSZone_name
  location: 'global'
  dependsOn: [
    virtualNetwork_name_res
  ]
}

resource privateDNSZone_name_privateDNSZone_name_link 'Microsoft.Network/privateDnsZones/virtualNetworkLinks@2018-09-01' = {
  name: '${privateDNSZone_name}/${privateDNSZone_name}-link'
  location: 'global'
  properties: {
    registrationEnabled: false
    virtualNetwork: {
      id: virtualNetwork_name_res.id
    }
  }
  dependsOn: [
    privateDNSZone_name_res
  ]
}

resource privateEndpoint_name_dnsgroupname 'Microsoft.Network/privateEndpoints/privateDnsZoneGroups@2020-03-01' = {
  name: '${privateEndpoint_name}/dnsgroupname'
  location: location
  properties: {
    privateDnsZoneConfigs: [
      {
        name: 'config1'
        properties: {
          privateDnsZoneId: privateDNSZone_name_res.id
        }
      }
    ]
  }
  dependsOn: [
    privateEndpoint_name_res
  ]
}