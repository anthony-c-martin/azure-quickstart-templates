param aseName string {
  metadata: {
    description: 'Name of the App Service Environment'
  }
}
param location string {
  metadata: {
    description: 'Location of the App Service Environment'
  }
  default: resourceGroup().location
}
param existingVirtualNetworkName string {
  metadata: {
    description: 'Name of the existing VNET'
  }
}
param existingVirtualNetworkResourceGroup string {
  metadata: {
    description: 'Name of the existing VNET resource group'
  }
}
param subnetName string {
  metadata: {
    description: 'Subnet name that will contain the App Service Environment'
  }
}
param internalLoadBalancingMode int {
  allowed: [
    0
    1
    2
    3
  ]
  metadata: {
    description: '0 = public VIP only, 1 = only ports 80/443 are mapped to ILB VIP, 2 = only FTP ports are mapped to ILB VIP, 3 = both ports 80/443 and FTP ports are mapped to an ILB VIP.'
  }
  default: 3
}

resource aseName_res 'Microsoft.Web/hostingEnvironments@2020-06-01' = {
  name: aseName
  kind: 'ASEV2'
  location: location
  properties: {
    name: aseName
    location: location
    ipsslAddressCount: 0
    internalLoadBalancingMode: internalLoadBalancingMode
    virtualNetwork: {
      id: resourceId(existingVirtualNetworkResourceGroup, 'Microsoft.Network/virtualNetworks/subnets', existingVirtualNetworkName, subnetName)
    }
  }
}