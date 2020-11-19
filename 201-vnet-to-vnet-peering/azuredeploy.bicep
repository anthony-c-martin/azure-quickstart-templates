param location string {
  metadata: {
    description: 'Location of the resources'
  }
  default: resourceGroup().location
}
param vNet1Name string {
  metadata: {
    description: 'Name for vNet 1'
  }
  default: 'vNet1'
}
param vNet2Name string {
  metadata: {
    description: 'Name for vNet 2'
  }
  default: 'vNet2'
}

var vNet1 = {
  addressSpacePrefix: '10.0.0.0/24'
  subnetName: 'subnet1'
  subnetPrefix: '10.0.0.0/24'
}
var vNet2 = {
  addressSpacePrefix: '192.168.0.0/24'
  subnetName: 'subnet1'
  subnetPrefix: '192.168.0.0/24'
}
var vNet1tovNet2PeeringName = '${vNet1Name}-${vNet2Name}'
var vNet2tovNet1PeeringName = '${vNet2Name}-${vNet1Name}'

resource vNet1Name_res 'Microsoft.Network/virtualNetworks@2020-05-01' = {
  name: vNet1Name
  location: location
  properties: {
    addressSpace: {
      addressPrefixes: [
        vNet1.addressSpacePrefix
      ]
    }
    subnets: [
      {
        name: vNet1.subnetName
        properties: {
          addressPrefix: vNet1.subnetPrefix
        }
      }
    ]
  }
}

resource vNet1Name_vNet1tovNet2PeeringName 'Microsoft.Network/virtualNetworks/virtualNetworkPeerings@2020-05-01' = {
  name: '${vNet1Name}/${vNet1tovNet2PeeringName}'
  location: location
  properties: {
    allowVirtualNetworkAccess: true
    allowForwardedTraffic: false
    allowGatewayTransit: false
    useRemoteGateways: false
    remoteVirtualNetwork: {
      id: vNet2Name_res.id
    }
  }
}

resource vNet2Name_res 'Microsoft.Network/virtualNetworks@2020-05-01' = {
  name: vNet2Name
  location: location
  properties: {
    addressSpace: {
      addressPrefixes: [
        vNet2.addressSpacePrefix
      ]
    }
    subnets: [
      {
        name: vNet2.subnetName
        properties: {
          addressPrefix: vNet2.subnetPrefix
        }
      }
    ]
  }
}

resource vNet2Name_vNet2tovNet1PeeringName 'Microsoft.Network/virtualNetworks/virtualNetworkPeerings@2020-05-01' = {
  name: '${vNet2Name}/${vNet2tovNet1PeeringName}'
  location: location
  properties: {
    allowVirtualNetworkAccess: true
    allowForwardedTraffic: false
    allowGatewayTransit: false
    useRemoteGateways: false
    remoteVirtualNetwork: {
      id: vNet1Name_res.id
    }
  }
}