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
var publicIPAddressName1 = 'publicIp1'
var publicIPAddressName2 = 'publicIp2'
var subnetName = 'subnet1'
var loadBalancerName = 'loadBalancer1'
var nicName = 'networkInterface1'
var subnetRef = resourceId('Microsoft.Network/virtualNetworks/subnets', virtualNetworkName, subnetName)
var publicIPAddressID1 = publicIPAddressName1_resource.id
var publicIPAddressID2 = publicIPAddressName2_resource.id
var lbBackendPoolID = resourceId('Microsoft.Network/loadBalancers/backendAddressPools', loadBalancerName, 'loadBalancerBackend')
var lbProbeID = resourceId('Microsoft.Network/loadBalancers/probes', loadBalancerName, 'tcpProbe')
var frontEndIPConfigID1 = resourceId('Microsoft.Network/loadBalancers/frontendIPConfigurations', loadBalancerName, 'loadBalancerFrontEnd1')
var frontEndIPConfigID2 = resourceId('Microsoft.Network/loadBalancers/frontendIPConfigurations', loadBalancerName, 'loadBalancerFrontEnd2')

resource publicIPAddressName1_resource 'Microsoft.Network/publicIPAddresses@2020-05-01' = {
  name: publicIPAddressName1
  location: location
  properties: {
    publicIPAllocationMethod: publicIPAddressType
    dnsSettings: {
      domainNameLabel: dnsNameforLBIP
    }
  }
}

resource publicIPAddressName2_resource 'Microsoft.Network/publicIPAddresses@2020-05-01' = {
  name: publicIPAddressName2
  location: location
  properties: {
    publicIPAllocationMethod: publicIPAddressType
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
              id: resourceId('Microsoft.Network/loadBalancers/backendAddressPools/', loadBalancerName, 'loadBalancerBackEnd')
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
        name: 'loadBalancerFrontEnd1'
        properties: {
          publicIPAddress: {
            id: publicIPAddressID1
          }
        }
      }
      {
        name: 'loadBalancerFrontEnd2'
        properties: {
          publicIPAddress: {
            id: publicIPAddressID2
          }
        }
      }
    ]
    backendAddressPools: [
      {
        name: 'loadBalancerBackEnd'
      }
    ]
    loadBalancingRules: [
      {
        name: 'LBRuleForVIP1'
        properties: {
          frontendIPConfiguration: {
            id: frontEndIPConfigID1
          }
          backendAddressPool: {
            id: lbBackendPoolID
          }
          protocol: 'Tcp'
          frontendPort: 443
          backendPort: 443
          probe: {
            id: lbProbeID
          }
        }
      }
      {
        name: 'LBRuleForVIP2'
        properties: {
          frontendIPConfiguration: {
            id: frontEndIPConfigID2
          }
          backendAddressPool: {
            id: lbBackendPoolID
          }
          protocol: 'Tcp'
          frontendPort: 443
          backendPort: 444
          probe: {
            id: lbProbeID
          }
        }
      }
    ]
    probes: [
      {
        name: 'tcpProbe'
        properties: {
          protocol: 'Tcp'
          port: 445
          intervalInSeconds: 5
          numberOfProbes: 2
        }
      }
    ]
  }
  dependsOn: [
    publicIPAddressName1_resource
    publicIPAddressName2_resource
  ]
}