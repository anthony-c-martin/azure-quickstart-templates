param vnetAddressPrefix string {
  metadata: {
    description: 'address prefix'
  }
  default: '10.0.0.0/16'
}
param subnetPrefix string {
  metadata: {
    description: 'Subnet prefix'
  }
  default: '10.0.0.0/24'
}
param location string {
  metadata: {
    description: 'Location for all resources.'
  }
  default: resourceGroup().location
}

var virtualNetworkName = 'virtualNetwork1'
var subnetName = 'subnet1'
var loadBalancerName = 'loadBalancer1'
var nicName = 'networkInterface1'
var subnetRef = resourceId('Microsoft.Network/virtualNetworks/subnets', virtualNetworkName, subnetName)

resource virtualNetworkName_resource 'Microsoft.Network/virtualNetworks@2020-05-01' = {
  name: virtualNetworkName
  location: location
  properties: {
    addressSpace: {
      addressPrefixes: [
        vnetAddressPrefix
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
              id: resourceId('Microsoft.Network/loadBalancers/backendAddressPools', loadBalancerName, 'loadBalancerBackEnd')
            }
          ]
        }
      }
    ]
  }
  dependsOn: [
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
          subnet: {
            id: subnetRef
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
        properties: {
          frontendIPConfiguration: {
            id: resourceId('Microsoft.Network/loadBalancers/frontendIpConfigurations', loadBalancerName, 'loadBalancerFrontEnd')
          }
          backendAddressPool: {
            id: resourceId('Microsoft.Network/loadBalancers/backendAddressPools', loadBalancerName, 'loadBalancerBackEnd')
          }
          probe: {
            id: resourceId('Microsoft.Network/loadBalancers/probes', loadBalancerName, 'lbprobe')
          }
          protocol: 'Tcp'
          frontendPort: 80
          backendPort: 80
          idleTimeoutInMinutes: 15
        }
        name: 'lbrule'
      }
    ]
    probes: [
      {
        properties: {
          protocol: 'Tcp'
          port: 80
          intervalInSeconds: 15
          numberOfProbes: 2
        }
        name: 'lbprobe'
      }
    ]
  }
  dependsOn: [
    virtualNetworkName_resource
  ]
}