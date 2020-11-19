param vmname string {
  metadata: {
    description: 'Name of the virtual machine'
  }
  default: 'myVM'
}
param vmsize string {
  metadata: {
    description: 'Size of the virtual machine'
  }
  default: 'Standard_D2s_v3'
}
param vnetname string {
  metadata: {
    description: 'Name of the virtual network'
  }
  default: 'myVnet'
}
param subnetname string {
  metadata: {
    description: 'Name of the subnet for virtual network'
  }
  default: 'mySubnet'
}
param vnetaddressspace string {
  metadata: {
    description: 'Address space for virtual network'
  }
  default: '192.168.0.0/16'
}
param vnetsubnetprefix string {
  metadata: {
    description: 'Subnet prefix for virtual network'
  }
  default: '192.168.0.0/24'
}
param natgatewayname string {
  metadata: {
    description: 'Name of the NAT gateway'
  }
  default: 'myNATgateway'
}
param networkinterfacename string {
  metadata: {
    description: 'Name of the virtual machine nic'
  }
  default: 'myvmNIC'
}
param publicipname string {
  metadata: {
    description: 'Name of the NAT gateway public IP'
  }
  default: 'myPublicIP'
}
param nsgname string {
  metadata: {
    description: 'Name of the virtual machine NSG'
  }
  default: 'myVMnsg'
}
param publicipvmname string {
  metadata: {
    description: 'Name of the virtual machine public IP'
  }
  default: 'myPublicIPVM'
}
param publicipprefixname string {
  metadata: {
    description: 'Name of the NAT gateway public IP'
  }
  default: 'myPublicIPPrefix'
}
param adminusername string {
  metadata: {
    description: 'Administrator username for virtual machine'
  }
}
param adminpassword string {
  metadata: {
    description: 'Administrator password for virtual machine'
  }
  secure: true
}
param location string {
  metadata: {
    description: 'Name of resource group'
  }
  default: resourceGroup().location
}

resource nsgname_resource 'Microsoft.Network/networkSecurityGroups@2020-06-01' = {
  name: nsgname
  location: location
  properties: {
    securityRules: [
      {
        name: 'SSH'
        properties: {
          protocol: 'TCP'
          sourcePortRange: '*'
          destinationPortRange: '22'
          sourceAddressPrefix: '*'
          destinationAddressPrefix: '*'
          access: 'Allow'
          priority: 300
          direction: 'Inbound'
        }
      }
    ]
  }
}

resource publicipname_resource 'Microsoft.Network/publicIPAddresses@2020-06-01' = {
  name: publicipname
  location: location
  sku: {
    name: 'Standard'
  }
  properties: {
    publicIPAddressVersion: 'IPv4'
    publicIPAllocationMethod: 'Static'
    idleTimeoutInMinutes: 4
  }
}

resource publicipvmname_resource 'Microsoft.Network/publicIPAddresses@2020-06-01' = {
  name: publicipvmname
  location: location
  sku: {
    name: 'Standard'
  }
  properties: {
    publicIPAddressVersion: 'IPv4'
    publicIPAllocationMethod: 'Static'
    idleTimeoutInMinutes: 4
  }
}

resource publicipprefixname_resource 'Microsoft.Network/publicIPPrefixes@2020-06-01' = {
  name: publicipprefixname
  location: location
  sku: {
    name: 'Standard'
  }
  properties: {
    prefixLength: 31
    publicIPAddressVersion: 'IPv4'
  }
}

resource vmname_resource 'Microsoft.Compute/virtualMachines@2020-06-01' = {
  name: vmname
  location: location
  properties: {
    hardwareProfile: {
      vmSize: vmsize
    }
    storageProfile: {
      imageReference: {
        publisher: 'Canonical'
        offer: 'UbuntuServer'
        sku: '18.04-LTS'
        version: 'latest'
      }
      osDisk: {
        osType: 'Linux'
        name: '${vmname}_disk1'
        createOption: 'FromImage'
        caching: 'ReadWrite'
        managedDisk: {
          storageAccountType: 'Premium_LRS'
        }
        diskSizeGB: 30
      }
    }
    osProfile: {
      computerName: vmname
      adminUsername: adminusername
      adminPassword: adminpassword
      linuxConfiguration: {
        disablePasswordAuthentication: false
        provisionVMAgent: true
      }
      allowExtensionOperations: true
    }
    networkProfile: {
      networkInterfaces: [
        {
          id: networkinterfacename_resource.id
        }
      ]
    }
  }
  dependsOn: [
    networkinterfacename_resource
  ]
}

resource vnetname_resource 'Microsoft.Network/virtualNetworks@2020-06-01' = {
  name: vnetname
  location: location
  properties: {
    addressSpace: {
      addressPrefixes: [
        vnetaddressspace
      ]
    }
    subnets: [
      {
        name: subnetname
        properties: {
          addressPrefix: vnetsubnetprefix
          natGateway: {
            id: natgatewayname_resource.id
          }
          privateEndpointNetworkPolicies: 'Enabled'
          privateLinkServiceNetworkPolicies: 'Enabled'
        }
      }
    ]
    enableDdosProtection: false
    enableVmProtection: false
  }
  dependsOn: [
    natgatewayname_resource
  ]
}

resource natgatewayname_resource 'Microsoft.Network/natGateways@2020-06-01' = {
  name: natgatewayname
  location: location
  sku: {
    name: 'Standard'
  }
  properties: {
    idleTimeoutInMinutes: 4
    publicIpAddresses: [
      {
        id: publicipname_resource.id
      }
    ]
    publicIpPrefixes: [
      {
        id: publicipprefixname_resource.id
      }
    ]
  }
  dependsOn: [
    publicipname_resource
    publicipprefixname_resource
  ]
}

resource vnetname_mySubnet 'Microsoft.Network/virtualNetworks/subnets@2020-05-01' = {
  name: '${vnetname}/mySubnet'
  properties: {
    addressPrefix: vnetsubnetprefix
    natGateway: {
      id: natgatewayname_resource.id
    }
    privateEndpointNetworkPolicies: 'Enabled'
    privateLinkServiceNetworkPolicies: 'Enabled'
  }
  dependsOn: [
    vnetname_resource
    natgatewayname_resource
  ]
}

resource networkinterfacename_resource 'Microsoft.Network/networkInterfaces@2020-06-01' = {
  name: networkinterfacename
  location: location
  properties: {
    ipConfigurations: [
      {
        name: 'ipconfig1'
        properties: {
          privateIPAddress: '192.168.0.4'
          privateIPAllocationMethod: 'Dynamic'
          publicIPAddress: {
            id: publicipvmname_resource.id
          }
          subnet: {
            id: vnetname_mySubnet.id
          }
          primary: true
          privateIPAddressVersion: 'IPv4'
        }
      }
    ]
    enableAcceleratedNetworking: false
    enableIPForwarding: false
    networkSecurityGroup: {
      id: nsgname_resource.id
    }
  }
  dependsOn: [
    publicipvmname_resource
    vnetname_mySubnet
    nsgname_resource
  ]
}