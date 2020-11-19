param vmAdminUsername string {
  metadata: {
    description: 'Username for the Virtual Machine.'
  }
}
param vmAdminPassword string {
  metadata: {
    description: 'Password for the Virtual Machine. The password must be at least 12 characters long and have lower case, upper characters, digit and a special character (Regex match)'
  }
  secure: true
}
param vmSize string {
  metadata: {
    description: 'The size of the VM'
  }
  default: 'Standard_D2_v2'
}
param location string {
  metadata: {
    description: 'Location for all resources.'
  }
  default: resourceGroup().location
}

var vnetName = 'myVirtualNetwork'
var vnetConsumerName = 'myPEVnet'
var vnetAddressPrefix = '10.0.0.0/16'
var frontendSubnetPrefix = '10.0.1.0/24'
var frontendSubnetName = 'frontendSubnet'
var backendSubnetPrefix = '10.0.2.0/24'
var backendSubnetName = 'backendSubnet'
var consumerSubnetPrefix = '10.0.0.0/24'
var consumerSubnetName = 'myPESubnet'
var loadbalancername = 'myILB'
var backendpoolname = 'myBackEndPool'
var loadBalancerFrontEndIpConfigurationName = 'myFrontEnd'
var healthProbeName = 'myHealthProbe'
var privateEndpointName = 'myPrivateEndpoint'
var vmName = take('myVm${uniqueString(resourceGroup().id)}', 15)
var networkInterfaceName = '${vmName}NetInt'
var vmConsumerName = take('myConsumerVm${uniqueString(resourceGroup().id)}', 15)
var publicIpAddressConsumerName = '${vmConsumerName}PublicIP'
var networkInterfaceConsumerName = '${vmConsumerName}NetInt'
var osDiskType = 'Standard_LRS'
var privatelinkservicename = 'myPLS'
var loadbalancerId = loadbalancername_resource.id

resource vnetName_resource 'Microsoft.Network/virtualNetworks@2020-06-01' = {
  name: vnetName
  location: location
  properties: {
    addressSpace: {
      addressPrefixes: [
        vnetAddressPrefix
      ]
    }
    subnets: [
      {
        name: frontendSubnetName
        properties: {
          addressPrefix: frontendSubnetPrefix
          privateLinkServiceNetworkPolicies: 'Disabled'
        }
      }
      {
        name: backendSubnetName
        properties: {
          addressPrefix: backendSubnetPrefix
        }
      }
    ]
  }
}

resource loadbalancername_resource 'Microsoft.Network/loadBalancers@2020-06-01' = {
  name: loadbalancername
  location: location
  sku: {
    name: 'Standard'
  }
  properties: {
    frontendIPConfigurations: [
      {
        name: loadBalancerFrontEndIpConfigurationName
        properties: {
          privateIPAllocationMethod: 'Dynamic'
          subnet: {
            id: resourceId('Microsoft.Network/virtualNetworks/subnets', vnetName, frontendSubnetName)
          }
        }
      }
    ]
    backendAddressPools: [
      {
        name: backendpoolname
      }
    ]
    inboundNatRules: [
      {
        name: 'RDP-VM0'
        properties: {
          frontendIPConfiguration: {
            id: resourceId('Microsoft.Network/loadBalancers/frontendIpConfigurations', loadbalancername, loadBalancerFrontEndIpConfigurationName)
          }
          protocol: 'Tcp'
          frontendPort: 3389
          backendPort: 3389
          enableFloatingIP: false
        }
      }
    ]
    loadBalancingRules: [
      {
        Name: 'myHTTPRule'
        properties: {
          frontendIPConfiguration: {
            id: resourceId('Microsoft.Network/loadBalancers/frontendIpConfigurations', loadbalancername, loadBalancerFrontEndIpConfigurationName)
          }
          backendAddressPool: {
            id: resourceId('Microsoft.Network/loadBalancers/backendAddressPools', loadbalancername, backendpoolname)
          }
          probe: {
            id: resourceId('Microsoft.Network/loadBalancers/probes', loadbalancername, healthProbeName)
          }
          protocol: 'Tcp'
          frontendPort: 80
          backendPort: 80
          idleTimeoutInMinutes: 15
        }
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
        name: healthProbeName
      }
    ]
  }
  dependsOn: [
    vnetName_resource
  ]
}

resource networkInterfaceName_resource 'Microsoft.Network/networkInterfaces@2020-06-01' = {
  name: networkInterfaceName
  location: location
  tags: {
    displayName: networkInterfaceName
  }
  properties: {
    ipConfigurations: [
      {
        name: 'ipConfig1'
        properties: {
          privateIPAllocationMethod: 'Dynamic'
          subnet: {
            id: resourceId('Microsoft.Network/virtualNetworks/subnets', vnetName, backendSubnetName)
          }
          loadBalancerBackendAddressPools: [
            {
              id: resourceId('Microsoft.Network/loadBalancers/backendAddressPools', loadbalancername, backendpoolname)
            }
          ]
          loadBalancerInboundNatRules: [
            {
              id: resourceId('Microsoft.Network/loadBalancers/inboundNatRules/', loadbalancername, 'RDP-VM0')
            }
          ]
        }
      }
    ]
  }
  dependsOn: [
    loadbalancername_resource
  ]
}

resource vmName_resource 'Microsoft.Compute/virtualMachines@2020-06-01' = {
  name: vmName
  location: location
  tags: {
    displayName: vmName
  }
  properties: {
    hardwareProfile: {
      vmSize: vmSize
    }
    osProfile: {
      computerName: vmName
      adminUsername: vmAdminUsername
      adminPassword: vmAdminPassword
    }
    storageProfile: {
      imageReference: {
        publisher: 'MicrosoftWindowsServer'
        offer: 'WindowsServer'
        sku: '2019-Datacenter'
        version: 'latest'
      }
      osDisk: {
        name: '${vmName}OsDisk'
        caching: 'ReadWrite'
        createOption: 'FromImage'
        managedDisk: {
          storageAccountType: osDiskType
        }
        diskSizeGB: 128
      }
    }
    networkProfile: {
      networkInterfaces: [
        {
          id: networkInterfaceName_resource.id
        }
      ]
    }
  }
  dependsOn: [
    networkInterfaceName_resource
  ]
}

resource vmName_installcustomscript 'Microsoft.Compute/virtualMachines/extensions@2020-06-01' = {
  name: '${vmName}/installcustomscript'
  location: location
  tags: {
    displayName: 'install software for Windows VM'
  }
  properties: {
    publisher: 'Microsoft.Compute'
    type: 'CustomScriptExtension'
    typeHandlerVersion: '1.9'
    autoUpgradeMinorVersion: true
    protectedSettings: {
      commandToExecute: 'powershell -ExecutionPolicy Unrestricted Install-WindowsFeature -Name Web-Server'
    }
  }
  dependsOn: [
    vmName_resource
  ]
}

resource privatelinkservicename_resource 'Microsoft.Network/privateLinkServices@2020-06-01' = {
  name: privatelinkservicename
  location: location
  properties: {
    enableProxyProtocol: false
    loadBalancerFrontendIpConfigurations: [
      {
        id: resourceId('Microsoft.Network/loadBalancers/frontendIpConfigurations', loadbalancername, loadBalancerFrontEndIpConfigurationName)
      }
    ]
    ipConfigurations: [
      {
        name: 'snet-provider-default-1'
        properties: {
          privateIPAllocationMethod: 'Dynamic'
          privateIPAddressVersion: 'IPv4'
          subnet: {
            id: reference(loadbalancerId, '2019-06-01').frontendIPConfigurations[0].properties.subnet.id
          }
          primary: false
        }
      }
    ]
  }
}

resource vnetConsumerName_resource 'Microsoft.Network/virtualNetworks@2020-06-01' = {
  name: vnetConsumerName
  location: location
  properties: {
    addressSpace: {
      addressPrefixes: [
        vnetAddressPrefix
      ]
    }
    subnets: [
      {
        name: consumerSubnetName
        properties: {
          addressPrefix: consumerSubnetPrefix
          privateEndpointNetworkPolicies: 'Disabled'
        }
      }
      {
        name: backendSubnetName
        properties: {
          addressPrefix: backendSubnetPrefix
        }
      }
    ]
  }
}

resource publicIpAddressConsumerName_resource 'Microsoft.Network/publicIPAddresses@2020-06-01' = {
  name: publicIpAddressConsumerName
  location: location
  tags: {
    displayName: publicIpAddressConsumerName
  }
  properties: {
    publicIPAllocationMethod: 'Dynamic'
    dnsSettings: {
      domainNameLabel: toLower(vmConsumerName)
    }
  }
}

resource networkInterfaceConsumerName_resource 'Microsoft.Network/networkInterfaces@2020-06-01' = {
  name: networkInterfaceConsumerName
  location: location
  tags: {
    displayName: networkInterfaceConsumerName
  }
  properties: {
    ipConfigurations: [
      {
        name: 'ipConfig1'
        properties: {
          privateIPAllocationMethod: 'Dynamic'
          publicIPAddress: {
            id: publicIpAddressConsumerName_resource.id
          }
          subnet: {
            id: resourceId('Microsoft.Network/virtualNetworks/subnets', vnetConsumerName, consumerSubnetName)
          }
        }
      }
    ]
  }
  dependsOn: [
    vnetConsumerName_resource
    publicIpAddressConsumerName_resource
  ]
}

resource vmConsumerName_resource 'Microsoft.Compute/virtualMachines@2020-06-01' = {
  name: vmConsumerName
  location: location
  tags: {
    displayName: vmConsumerName
  }
  properties: {
    hardwareProfile: {
      vmSize: vmSize
    }
    osProfile: {
      computerName: vmConsumerName
      adminUsername: vmAdminUsername
      adminPassword: vmAdminPassword
    }
    storageProfile: {
      imageReference: {
        publisher: 'MicrosoftWindowsServer'
        offer: 'WindowsServer'
        sku: '2019-Datacenter'
        version: 'latest'
      }
      osDisk: {
        name: '${vmConsumerName}OsDisk'
        caching: 'ReadWrite'
        createOption: 'FromImage'
        managedDisk: {
          storageAccountType: osDiskType
        }
        diskSizeGB: 128
      }
    }
    networkProfile: {
      networkInterfaces: [
        {
          id: networkInterfaceConsumerName_resource.id
        }
      ]
    }
  }
  dependsOn: [
    networkInterfaceConsumerName_resource
  ]
}

resource privateEndpointName_resource 'Microsoft.Network/privateEndpoints@2020-06-01' = {
  name: privateEndpointName
  location: location
  properties: {
    subnet: {
      id: resourceId('Microsoft.Network/virtualNetworks/subnets', vnetConsumerName, consumerSubnetName)
    }
    privateLinkServiceConnections: [
      {
        name: privateEndpointName
        properties: {
          privateLinkServiceId: privatelinkservicename_resource.id
        }
      }
    ]
  }
  dependsOn: [
    vnetConsumerName_resource
    privatelinkservicename_resource
  ]
}