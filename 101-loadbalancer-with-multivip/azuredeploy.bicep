@description('Unique DNS name')
param dnsNameforLBIP string

@description('Address Prefix')
param addressPrefix string = '10.0.0.0/16'

@description('Subnet Prefix')
param subnetPrefix string = '10.0.0.0/24'

@allowed([
  'Dynamic'
  'Static'
])
@description('Public IP type')
param publicIPAddressType string = 'Dynamic'

@description('Location for all resources.')
param location string = resourceGroup().location

var virtualNetworkName_var = 'virtualNetwork1'
var publicIPAddressName1_var = 'publicIp1'
var publicIPAddressName2_var = 'publicIp2'
var subnetName = 'subnet1'
var loadBalancerName_var = 'loadBalancer1'
var nicName_var = 'networkInterface1'
var subnetRef = resourceId('Microsoft.Network/virtualNetworks/subnets', virtualNetworkName_var, subnetName)
var publicIPAddressID1 = publicIPAddressName1.id
var publicIPAddressID2 = publicIPAddressName2.id
var lbBackendPoolID = resourceId('Microsoft.Network/loadBalancers/backendAddressPools', loadBalancerName_var, 'loadBalancerBackend')
var lbProbeID = resourceId('Microsoft.Network/loadBalancers/probes', loadBalancerName_var, 'tcpProbe')
var frontEndIPConfigID1 = resourceId('Microsoft.Network/loadBalancers/frontendIPConfigurations', loadBalancerName_var, 'loadBalancerFrontEnd1')
var frontEndIPConfigID2 = resourceId('Microsoft.Network/loadBalancers/frontendIPConfigurations', loadBalancerName_var, 'loadBalancerFrontEnd2')

resource publicIPAddressName1 'Microsoft.Network/publicIPAddresses@2020-05-01' = {
  name: publicIPAddressName1_var
  location: location
  properties: {
    publicIPAllocationMethod: publicIPAddressType
    dnsSettings: {
      domainNameLabel: dnsNameforLBIP
    }
  }
}

resource publicIPAddressName2 'Microsoft.Network/publicIPAddresses@2020-05-01' = {
  name: publicIPAddressName2_var
  location: location
  properties: {
    publicIPAllocationMethod: publicIPAddressType
  }
}

resource virtualNetworkName 'Microsoft.Network/virtualNetworks@2020-05-01' = {
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

resource nicName 'Microsoft.Network/networkInterfaces@2020-05-01' = {
  name: nicName_var
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
              id: resourceId('Microsoft.Network/loadBalancers/backendAddressPools/', loadBalancerName_var, 'loadBalancerBackEnd')
            }
          ]
        }
      }
    ]
  }
  dependsOn: [
    virtualNetworkName
    loadBalancerName
  ]
}

resource loadBalancerName 'Microsoft.Network/loadBalancers@2020-05-01' = {
  name: loadBalancerName_var
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
}