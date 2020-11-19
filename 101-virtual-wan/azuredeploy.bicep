param location string {
  metadata: {
    description: 'Location where all resources will be created.'
  }
  default: resourceGroup().location
}
param wanname string {
  metadata: {
    description: 'Name of the Virtual Wan.'
  }
  default: 'SampleVirtualWan'
}
param wansku string {
  allowed: [
    'Standard'
    'Basic'
  ]
  metadata: {
    description: 'Sku of the Virtual Wan.'
  }
  default: 'Standard'
}
param hubname string {
  metadata: {
    description: 'Name of the Virtual Hub. A virtual hub is created inside a virtual wan.'
  }
  default: 'SampleVirtualHub'
}
param vpngatewayname string {
  metadata: {
    description: 'Name of the Vpn Gateway. A vpn gateway is created inside a virtual hub.'
  }
  default: 'SampleVpnGateway'
}
param vpnsitename string {
  metadata: {
    description: 'Name of the vpnsite. A vpnsite represents the on-premise vpn device. A public ip address is mandatory for a vpn site creation.'
  }
  default: 'SampleVpnSite'
}
param connectionName string {
  metadata: {
    description: 'Name of the vpnconnection. A vpn connection is established between a vpnsite and a vpn gateway.'
  }
  default: 'SampleVpnsiteVpnGwConnection'
}
param vpnsiteAddressspaceList array {
  metadata: {
    description: 'A list of static routes corresponding to the vpn site. These are configured on the vpn gateway.'
  }
  default: []
}
param vpnsitePublicIPAddress string {
  metadata: {
    description: 'The public IP address of a vpn site.'
  }
}
param vpnsiteBgpAsn int {
  metadata: {
    description: 'The bgp asn number of a vpnsite.'
  }
}
param vpnsiteBgpPeeringAddress string {
  metadata: {
    description: 'The bgp peer IP address of a vpnsite.'
  }
}
param addressPrefix string {
  metadata: {
    description: 'The hub address prefix. This address prefix will be used as the address prefix for the hub vnet'
  }
  default: '192.168.0.0/24'
}
param enableBgp string {
  allowed: [
    'true'
    'false'
  ]
  metadata: {
    description: 'This needs to be set to true if BGP needs to enabled on the vpn connection.'
  }
  default: 'false'
}

resource wanname_res 'Microsoft.Network/virtualWans@2020-05-01' = {
  name: wanname
  location: location
  properties: {
    type: wansku
  }
}

resource hubname_res 'Microsoft.Network/virtualHubs@2020-05-01' = {
  name: hubname
  location: location
  properties: {
    addressPrefix: addressPrefix
    virtualWan: {
      id: wanname_res.id
    }
  }
}

resource vpnsitename_res 'Microsoft.Network/vpnSites@2020-05-01' = {
  name: vpnsitename
  location: location
  properties: {
    addressSpace: {
      addressPrefixes: vpnsiteAddressspaceList
    }
    bgpProperties: {
      asn: vpnsiteBgpAsn
      bgpPeeringAddress: vpnsiteBgpPeeringAddress
      peerWeight: 0
    }
    deviceProperties: {
      linkSpeedInMbps: 0
    }
    ipAddress: vpnsitePublicIPAddress
    virtualWan: {
      id: wanname_res.id
    }
  }
}

resource vpngatewayname_res 'Microsoft.Network/vpnGateways@2020-05-01' = {
  name: vpngatewayname
  location: location
  properties: {
    connections: [
      {
        name: connectionName
        properties: {
          connectionBandwidth: 10
          enableBgp: enableBgp
          remoteVpnSite: {
            id: vpnsitename_res.id
          }
        }
      }
    ]
    virtualHub: {
      id: hubname_res.id
    }
    bgpSettings: {
      asn: 65515
    }
  }
}