@description('Azure Virtual WAN Name')
param vWANname string

@description('Azure Region for the first Hub')
param hub1_location string

@description('Azure Region for the second Hub')
param hub2_location string

@description('Scale Units for Site-to-Site (S2S) VPN Gateway in the first Hub')
param Hub1_S2SvpnGatewayScaleUnit int = 1

@description('Scale Units for Site-to-Site (S2S) VPN Gateway in the second Hub')
param Hub2_S2SvpnGatewayScaleUnit int = 1

@description('Scale Units for Express Route Gateway in the first Hub')
param Hub1_ExpressRouteGatewayScaleUnit int = 1

@description('Scale Units for Express Route Gateway in the second Hub')
param Hub2_ExpressRouteGatewayScaleUnit int = 1

@description('Scale Units for Point-to-Site (P2S) VPN Gateway in the first Hub')
param Hub1_P2SvpnGatewayScaleUnit int = 1

@description('Scale Units for Point-to-Site (P2S) VPN Gateway in the second Hub')
param Hub2_P2SvpnGatewayScaleUnit int = 1

@description('Sample Public Certificate content for Point-to-Site (P2S) authentication in the first Hub (please provide your own once deployment is completed) ')
param Hub1_PublicCertificateDataForP2S string

@description('Sample Public Certificate content for Point-to-Site (P2S) authentication in the second Hub (please provide your own once deployment is completed) ')
param Hub2_PublicCertificateDataForP2S string

var vwan_cfg = {
  type: 'Standard'
}
var virtual_hub1_cfg = {
  name: 'vhubvnet1'
  addressSpacePrefix: '192.168.0.0/24'
  Hub1_P2SvpnClientAddressPoolPrefix: '10.4.3.0/24'
}
var virtual_hub2_cfg = {
  name: 'vhubvnet2'
  addressSpacePrefix: '192.168.1.0/24'
  Hub2_P2SvpnClientAddressPoolPrefix: '10.5.3.0/24'
}
var vnet1_cfg = {
  name: 'VNET1'
  addressSpacePrefix: '10.1.0.0/24'
  subnetName: 'subnet1'
  subnetPrefix: '10.1.0.0/24'
}
var vnet2_cfg = {
  name: 'VNET2'
  addressSpacePrefix: '10.1.1.0/24'
  subnetName: 'subnet1'
  subnetPrefix: '10.1.1.0/24'
}
var vnet3_cfg = {
  name: 'VNET3'
  addressSpacePrefix: '10.2.0.0/24'
  subnetName: 'subnet1'
  subnetPrefix: '10.2.0.0/24'
}
var vnet4_cfg = {
  name: 'VNET4'
  addressSpacePrefix: '10.2.1.0/24'
  subnetName: 'subnet1'
  subnetPrefix: '10.2.1.0/24'
}

resource vWANname_resource 'Microsoft.Network/virtualWans@2020-05-01' = {
  name: vWANname
  location: hub1_location
  properties: {
    allowVnetToVnetTraffic: true
    allowBranchToBranchTraffic: true
    type: vwan_cfg.type
  }
}

resource virtual_hub1_cfg_name 'Microsoft.Network/virtualHubs@2020-05-01' = {
  name: virtual_hub1_cfg.name
  location: hub1_location
  properties: {
    addressPrefix: virtual_hub1_cfg.addressSpacePrefix
    virtualWan: {
      id: vWANname_resource.id
    }
  }
}

resource virtual_hub2_cfg_name 'Microsoft.Network/virtualHubs@2020-05-01' = {
  name: virtual_hub2_cfg.name
  location: hub2_location
  properties: {
    addressPrefix: virtual_hub2_cfg.addressSpacePrefix
    virtualWan: {
      id: vWANname_resource.id
    }
  }
}

resource virtual_hub1_cfg_name_defaultRouteTable 'Microsoft.Network/virtualHubs/hubRouteTables@2020-05-01' = {
  name: '${virtual_hub1_cfg.name}/defaultRouteTable'
  properties: {
    labels: [
      'default'
    ]
  }
  dependsOn: [
    virtual_hub1_cfg_name
    virtual_hub1_cfg_name_S2SvpnGW
  ]
}

resource virtual_hub1_cfg_name_noneRouteTable 'Microsoft.Network/virtualHubs/hubRouteTables@2020-05-01' = {
  name: '${virtual_hub1_cfg.name}/noneRouteTable'
  properties: {
    labels: [
      'none'
    ]
  }
  dependsOn: [
    virtual_hub1_cfg_name
    virtual_hub1_cfg_name_S2SvpnGW
  ]
}

resource virtual_hub1_cfg_name_HUB1_RT_SHARED 'Microsoft.Network/virtualHubs/hubRouteTables@2020-05-01' = {
  name: '${virtual_hub1_cfg.name}/HUB1_RT_SHARED'
  properties: {
    labels: [
      'LBL_RT_SHARED'
    ]
  }
  dependsOn: [
    virtual_hub1_cfg_name
    virtual_hub1_cfg_name_S2SvpnGW
  ]
}

resource virtual_hub2_cfg_name_defaultRouteTable 'Microsoft.Network/virtualHubs/hubRouteTables@2020-05-01' = {
  name: '${virtual_hub2_cfg.name}/defaultRouteTable'
  properties: {
    labels: [
      'default'
    ]
  }
  dependsOn: [
    virtual_hub2_cfg_name
    virtual_hub2_cfg_name_S2SvpnGW
  ]
}

resource virtual_hub2_cfg_name_noneRouteTable 'Microsoft.Network/virtualHubs/hubRouteTables@2020-05-01' = {
  name: '${virtual_hub2_cfg.name}/noneRouteTable'
  properties: {
    labels: [
      'none'
    ]
  }
  dependsOn: [
    virtual_hub2_cfg_name
    virtual_hub2_cfg_name_S2SvpnGW
  ]
}

resource virtual_hub2_cfg_name_HUB2_RT_SHARED 'Microsoft.Network/virtualHubs/hubRouteTables@2020-05-01' = {
  name: '${virtual_hub2_cfg.name}/HUB2_RT_SHARED'
  properties: {
    labels: [
      'LBL_RT_SHARED'
    ]
  }
  dependsOn: [
    virtual_hub2_cfg_name
    virtual_hub2_cfg_name_S2SvpnGW
  ]
}

resource vnet1_cfg_name 'Microsoft.Network/virtualNetworks@2020-05-01' = {
  name: vnet1_cfg.name
  location: hub1_location
  properties: {
    addressSpace: {
      addressPrefixes: [
        vnet1_cfg.addressSpacePrefix
      ]
    }
    subnets: [
      {
        name: vnet1_cfg.subnetName
        properties: {
          addressPrefix: vnet1_cfg.subnetPrefix
        }
      }
    ]
  }
}

resource vnet2_cfg_name 'Microsoft.Network/virtualNetworks@2020-05-01' = {
  name: vnet2_cfg.name
  location: hub1_location
  properties: {
    addressSpace: {
      addressPrefixes: [
        vnet2_cfg.addressSpacePrefix
      ]
    }
    subnets: [
      {
        name: vnet2_cfg.subnetName
        properties: {
          addressPrefix: vnet2_cfg.subnetPrefix
        }
      }
    ]
  }
}

resource vnet3_cfg_name 'Microsoft.Network/virtualNetworks@2020-05-01' = {
  name: vnet3_cfg.name
  location: hub2_location
  properties: {
    addressSpace: {
      addressPrefixes: [
        vnet3_cfg.addressSpacePrefix
      ]
    }
    subnets: [
      {
        name: vnet3_cfg.subnetName
        properties: {
          addressPrefix: vnet3_cfg.subnetPrefix
        }
      }
    ]
  }
}

resource vnet4_cfg_name 'Microsoft.Network/virtualNetworks@2020-05-01' = {
  name: vnet4_cfg.name
  location: hub2_location
  properties: {
    addressSpace: {
      addressPrefixes: [
        vnet4_cfg.addressSpacePrefix
      ]
    }
    subnets: [
      {
        name: vnet4_cfg.subnetName
        properties: {
          addressPrefix: vnet4_cfg.subnetPrefix
        }
      }
    ]
  }
}

resource virtual_hub1_cfg_name_vnet1_cfg_name_connection 'Microsoft.Network/virtualHubs/hubVirtualNetworkConnections@2020-05-01' = {
  name: '${virtual_hub1_cfg.name}/${vnet1_cfg.name}_connection'
  properties: {
    routingConfiguration: {
      associatedRouteTable: {
        id: virtual_hub1_cfg_name_defaultRouteTable.id
      }
      propagatedRouteTables: {
        labels: [
          'default'
          'LBL_RT_SHARED'
        ]
        ids: [
          {
            id: virtual_hub1_cfg_name_defaultRouteTable.id
          }
          {
            id: virtual_hub1_cfg_name_HUB1_RT_SHARED.id
          }
        ]
      }
    }
    remoteVirtualNetwork: {
      id: vnet1_cfg_name.id
    }
    allowHubToRemoteVnetTransit: true
    allowRemoteVnetToUseHubVnetGateways: true
    enableInternetSecurity: true
  }
  dependsOn: [
    virtual_hub1_cfg_name
  ]
}

resource virtual_hub1_cfg_name_vnet2_cfg_name_connection 'Microsoft.Network/virtualHubs/hubVirtualNetworkConnections@2020-05-01' = {
  name: '${virtual_hub1_cfg.name}/${vnet2_cfg.name}_connection'
  properties: {
    routingConfiguration: {
      associatedRouteTable: {
        id: virtual_hub1_cfg_name_HUB1_RT_SHARED.id
      }
      propagatedRouteTables: {
        labels: [
          'default'
        ]
        ids: [
          {
            id: virtual_hub1_cfg_name_defaultRouteTable.id
          }
        ]
      }
    }
    remoteVirtualNetwork: {
      id: vnet2_cfg_name.id
    }
    allowHubToRemoteVnetTransit: true
    allowRemoteVnetToUseHubVnetGateways: true
    enableInternetSecurity: true
  }
  dependsOn: [
    virtual_hub1_cfg_name

    virtual_hub1_cfg_name_vnet1_cfg_name_connection
  ]
}

resource virtual_hub2_cfg_name_vnet3_cfg_name_connection 'Microsoft.Network/virtualHubs/hubVirtualNetworkConnections@2020-05-01' = {
  name: '${virtual_hub2_cfg.name}/${vnet3_cfg.name}_connection'
  properties: {
    routingConfiguration: {
      associatedRouteTable: {
        id: virtual_hub2_cfg_name_HUB2_RT_SHARED.id
      }
      propagatedRouteTables: {
        labels: [
          'default'
        ]
        ids: [
          {
            id: virtual_hub2_cfg_name_defaultRouteTable.id
          }
        ]
      }
    }
    remoteVirtualNetwork: {
      id: vnet3_cfg_name.id
    }
    allowHubToRemoteVnetTransit: true
    allowRemoteVnetToUseHubVnetGateways: true
    enableInternetSecurity: true
  }
  dependsOn: [
    virtual_hub2_cfg_name
  ]
}

resource virtual_hub2_cfg_name_vnet4_cfg_name_connection 'Microsoft.Network/virtualHubs/hubVirtualNetworkConnections@2020-05-01' = {
  name: '${virtual_hub2_cfg.name}/${vnet4_cfg.name}_connection'
  properties: {
    routingConfiguration: {
      associatedRouteTable: {
        id: virtual_hub2_cfg_name_HUB2_RT_SHARED.id
      }
      propagatedRouteTables: {
        labels: [
          'default'
        ]
        ids: [
          {
            id: virtual_hub2_cfg_name_defaultRouteTable.id
          }
        ]
      }
    }
    remoteVirtualNetwork: {
      id: vnet4_cfg_name.id
    }
    allowHubToRemoteVnetTransit: true
    allowRemoteVnetToUseHubVnetGateways: true
    enableInternetSecurity: true
  }
  dependsOn: [
    virtual_hub2_cfg_name

    virtual_hub2_cfg_name_vnet3_cfg_name_connection
  ]
}

resource virtual_hub1_cfg_name_S2SvpnGW 'Microsoft.Network/vpnGateways@2020-05-01' = {
  name: '${virtual_hub1_cfg.name}_S2SvpnGW'
  location: hub1_location
  properties: {
    vpnGatewayScaleUnit: Hub1_S2SvpnGatewayScaleUnit
    virtualHub: {
      id: virtual_hub1_cfg_name.id
    }
    bgpSettings: {
      asn: 65515
    }
  }
}

resource virtual_hub2_cfg_name_S2SvpnGW 'Microsoft.Network/vpnGateways@2020-05-01' = {
  name: '${virtual_hub2_cfg.name}_S2SvpnGW'
  location: hub2_location
  properties: {
    vpnGatewayScaleUnit: Hub2_S2SvpnGatewayScaleUnit
    virtualHub: {
      id: virtual_hub2_cfg_name.id
    }
    bgpSettings: {
      asn: 65515
    }
  }
}

resource virtual_hub1_cfg_name_ERGW 'Microsoft.Network/expressRouteGateways@2020-05-01' = {
  name: '${virtual_hub1_cfg.name}_ERGW'
  location: hub1_location
  properties: {
    virtualHub: {
      id: virtual_hub1_cfg_name.id
    }
    autoScaleConfiguration: {
      bounds: {
        min: Hub1_ExpressRouteGatewayScaleUnit
      }
    }
  }
  dependsOn: [
    virtual_hub1_cfg_name_S2SvpnGW
  ]
}

resource virtual_hub2_cfg_name_ERGW 'Microsoft.Network/expressRouteGateways@2020-05-01' = {
  name: '${virtual_hub2_cfg.name}_ERGW'
  location: hub2_location
  properties: {
    virtualHub: {
      id: virtual_hub2_cfg_name.id
    }
    autoScaleConfiguration: {
      bounds: {
        min: Hub2_ExpressRouteGatewayScaleUnit
      }
    }
  }
  dependsOn: [
    virtual_hub2_cfg_name_S2SvpnGW
  ]
}

resource virtual_hub1_cfg_name_P2SvpnServerConfiguration 'Microsoft.Network/vpnServerConfigurations@2020-05-01' = {
  name: '${virtual_hub1_cfg.name}_P2SvpnServerConfiguration'
  location: hub1_location
  properties: {
    vpnProtocols: [
      'IkeV2'
      'OpenVPN'
    ]
    vpnAuthenticationTypes: [
      'Certificate'
    ]
    vpnClientRootCertificates: [
      {
        name: 'P2SRootCertHub1'
        publicCertData: Hub1_PublicCertificateDataForP2S
      }
    ]
  }
  dependsOn: [
    virtual_hub1_cfg_name_ERGW
  ]
}

resource virtual_hub2_cfg_name_P2SvpnServerConfiguration 'Microsoft.Network/vpnServerConfigurations@2020-05-01' = {
  name: '${virtual_hub2_cfg.name}_P2SvpnServerConfiguration'
  location: hub2_location
  properties: {
    vpnProtocols: [
      'IkeV2'
      'OpenVPN'
    ]
    vpnAuthenticationTypes: [
      'Certificate'
    ]
    vpnClientRootCertificates: [
      {
        name: 'P2SRootCertHub2'
        publicCertData: Hub2_PublicCertificateDataForP2S
      }
    ]
  }
  dependsOn: [
    virtual_hub2_cfg_name_ERGW
  ]
}

resource virtual_hub1_cfg_name_P2Sgateway 'Microsoft.Network/p2sVpnGateways@2020-05-01' = {
  name: '${virtual_hub1_cfg.name}_P2Sgateway'
  location: hub1_location
  properties: {
    virtualHub: {
      id: virtual_hub1_cfg_name.id
    }
    vpnServerConfiguration: {
      id: virtual_hub1_cfg_name_P2SvpnServerConfiguration.id
    }
    p2SConnectionConfigurations: [
      {
        name: 'Hub1_P2SConnectionConfigDefault'
        properties: {
          routingConfiguration: {
            associatedRouteTable: {
              id: virtual_hub1_cfg_name_defaultRouteTable.id
            }
            propagatedRouteTables: {
              labels: [
                'LBL_RT_SHARED'
                'default'
              ]
              ids: [
                {
                  id: virtual_hub1_cfg_name_defaultRouteTable.id
                }
                {
                  id: virtual_hub1_cfg_name_HUB1_RT_SHARED.id
                }
              ]
            }
          }
          vpnClientAddressPool: {
            addressPrefixes: [
              virtual_hub1_cfg.Hub1_P2SvpnClientAddressPoolPrefix
            ]
          }
        }
      }
    ]
    vpnGatewayScaleUnit: Hub1_P2SvpnGatewayScaleUnit
  }
}

resource virtual_hub2_cfg_name_P2Sgateway 'Microsoft.Network/p2sVpnGateways@2020-05-01' = {
  name: '${virtual_hub2_cfg.name}_P2Sgateway'
  location: hub2_location
  properties: {
    virtualHub: {
      id: virtual_hub2_cfg_name.id
    }
    vpnServerConfiguration: {
      id: virtual_hub2_cfg_name_P2SvpnServerConfiguration.id
    }
    p2SConnectionConfigurations: [
      {
        name: 'Hub2_P2SConnectionConfigDefault'
        properties: {
          routingConfiguration: {
            associatedRouteTable: {
              id: virtual_hub2_cfg_name_defaultRouteTable.id
            }
            propagatedRouteTables: {
              labels: [
                'LBL_RT_SHARED'
                'default'
              ]
              ids: [
                {
                  id: virtual_hub2_cfg_name_defaultRouteTable.id
                }
                {
                  id: virtual_hub2_cfg_name_HUB2_RT_SHARED.id
                }
              ]
            }
          }
          vpnClientAddressPool: {
            addressPrefixes: [
              virtual_hub2_cfg.Hub2_P2SvpnClientAddressPoolPrefix
            ]
          }
        }
      }
    ]
    vpnGatewayScaleUnit: Hub2_P2SvpnGatewayScaleUnit
  }
}