param dnsNameforLBIP string {
  metadata: {
    description: 'Unique DNS name'
  }
}
param addressPrefix string {
  metadata: {
    description: 'Address Prefix'
  }
  default: '10.0.0.0/16'
}
param subnetPrefix string {
  metadata: {
    description: 'Subnet Prefix'
  }
  default: '10.0.0.0/24'
}
param publicIPAddressType string {
  allowed: [
    'Dynamic'
    'Static'
  ]
  metadata: {
    description: 'Public IP type'
  }
  default: 'Dynamic'
}
param location string {
  metadata: {
    description: 'Location for all resources.'
  }
  default: resourceGroup().location
}

var virtualNetworkName = 'virtualNetwork1'
var publicIPAddressName = 'publicIp1'
var subnetName = 'subnet1'
var loadBalancerName = 'loadBalancer1'
var nicName = 'networkInterface1'
var subnetRef = resourceId('Microsoft.Network/virtualNetworks/subnets', virtualNetworkName, subnetName)
var publicIPAddressID = publicIPAddressName_resource.id
var frontEndIPConfigID = resourceId('Microsoft.Network/loadBalancers/frontendIPConfigurations', loadBalancerName, 'loadBalancerFrontEnd')

resource publicIPAddressName_resource 'Microsoft.Network/publicIPAddresses@2020-05-01' = {
  name: publicIPAddressName
  location: location
  properties: {
    publicIPAllocationMethod: publicIPAddressType
    dnsSettings: {
      domainNameLabel: dnsNameforLBIP
    }
  }
}

resource virtualNetworkName_resource 'Microsoft.Network/virtualNetworks@2020-05-01' = {
  name: virtualNetworkName
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

resource nicName_resource 'Microsoft.Network/networkInterfaces@2020-05-01' = {
  name: nicName
  location: location
  properties: {
    ipConfigurations: [
      {
        name: 'ipconfig1'
        properties: {
          privateIPAllocationMethod: 'Dynamic'
          subnet: {
            id: subnetRef
          }
          loadBalancerBackendAddressPools: [
            {
              id: resourceId('Microsoft.Network/loadBalancers/backendAddressPools', loadBalancerName, 'LoadBalancerBackend')
            }
          ]
          loadBalancerInboundNatRules: [
            {
              id: resourceId('Microsoft.Network/loadBalancers/inboundNatRules', loadBalancerName, 'RDP')
            }
          ]
        }
      }
    ]
  }
  dependsOn: [
    virtualNetworkName_resource
    loadBalancerName_resource
  ]
}

resource loadBalancerName_resource 'Microsoft.Network/loadBalancers@2020-05-01' = {
  name: loadBalancerName
  location: location
  properties: {
    frontendIPConfigurations: [
      {
        name: 'loadBalancerFrontEnd'
        properties: {
          publicIPAddress: {
            id: publicIPAddressID
          }
        }
      }
    ]
    backendAddressPools: [
      {
        name: 'loadBalancerBackEnd'
      }
    ]
    inboundNatRules: [
      {
        name: 'RDP'
        properties: {
          frontendIPConfiguration: {
            id: frontEndIPConfigID
          }
          protocol: 'Tcp'
          frontendPort: 3389
          backendPort: 3389
          enableFloatingIP: false
        }
      }
    ]
  }
  dependsOn: [
    publicIPAddressName_resource
  ]
}