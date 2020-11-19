param adminPassword string {
  metadata: {
    description: 'Admin password.'
  }
  secure: true
}
param adminUsername string {
  metadata: {
    description: 'Admin username.'
  }
}
param dnsNameforLBIP string {
  metadata: {
    description: 'DNS for Load Balancer IP.'
  }
}
param location string {
  metadata: {
    description: 'Location for all resources.'
  }
  default: resourceGroup().location
}
param storageAccountName string {
  metadata: {
    description: 'Name of storage account.'
  }
  default: 'storage${uniqueString(resourceGroup().id)}'
}
param vmSize string {
  metadata: {
    description: 'Size of the virtual machine.'
  }
  default: 'Standard_D2_v2'
}

var addressPrefix = '10.0.0.0/16'
var imageOffer = 'WindowsServer'
var imagePublisher = 'MicrosoftWindowsServer'
var imageSKU = '2019-Datacenter'
var lbName = 'myLB'
var networkSecurityGroupName = '${subnetName}-nsg'
var nic1NamePrefix = 'nic1'
var nic2NamePrefix = 'nic2'
var publicIPAddressName = 'myPublicIP'
var publicIPAddressType = 'Dynamic'
var storageAccountType = 'Standard_LRS'
var subnetName = 'Subnet-1'
var subnetPrefix = '10.0.0.0/24'
var vmNamePrefix = 'myVM'
var vnetName = 'myVNET'

resource storageAccountName_resource 'Microsoft.Storage/storageAccounts@2019-06-01' = {
  name: storageAccountName
  location: location
  sku: {
    name: storageAccountType
  }
  kind: 'StorageV2'
}

resource lbName_resource 'Microsoft.Network/loadBalancers@2020-05-01' = {
  name: lbName
  location: location
  properties: {
    frontendIPConfigurations: [
      {
        name: 'LoadBalancerFrontEnd'
        properties: {
          publicIPAddress: {
            id: publicIPAddressName_resource.id
          }
        }
      }
    ]
    backendAddressPools: [
      {
        name: 'BackendPool1'
      }
    ]
    inboundNatRules: [
      {
        name: 'RDP-VM0'
        properties: {
          frontendIPConfiguration: {
            id: resourceId('Microsoft.Network/loadBalancers/frontendIPConfigurations', lbName, 'LoadBalancerFrontEnd')
          }
          protocol: 'Tcp'
          frontendPort: 50001
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

resource networkSecurityGroupName_resource 'Microsoft.Network/networkSecurityGroups@2020-05-01' = {
  name: networkSecurityGroupName
  location: location
  properties: {}
}

resource nic1NamePrefix_resource 'Microsoft.Network/networkInterfaces@2020-05-01' = {
  name: nic1NamePrefix
  location: location
  properties: {
    ipConfigurations: [
      {
        name: 'ipconfig1'
        properties: {
          privateIPAllocationMethod: 'Dynamic'
          subnet: {
            id: resourceId('Microsoft.Network/virtualNetworks/subnets', vnetName, subnetName)
          }
          loadBalancerBackendAddressPools: [
            {
              id: resourceId('Microsoft.Network/loadBalancers/backendAddressPools', lbName, 'BackendPool1')
            }
          ]
          loadBalancerInboundNatRules: [
            {
              id: resourceId('Microsoft.Network/loadBalancers/inboundNatRules', lbName, 'RDP-VM0')
            }
          ]
        }
      }
    ]
  }
  dependsOn: [
    vnetName_resource
    lbName_resource
  ]
}

resource nic2NamePrefix_resource 'Microsoft.Network/networkInterfaces@2020-05-01' = {
  name: nic2NamePrefix
  location: location
  properties: {
    ipConfigurations: [
      {
        name: 'ipconfig1'
        properties: {
          privateIPAllocationMethod: 'Dynamic'
          subnet: {
            id: resourceId('Microsoft.Network/virtualNetworks/subnets', vnetName, subnetName)
          }
        }
      }
    ]
  }
  dependsOn: [
    vnetName_resource
  ]
}

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

resource vmNamePrefix_resource 'Microsoft.Compute/virtualMachines@2019-12-01' = {
  name: vmNamePrefix
  location: location
  properties: {
    hardwareProfile: {
      vmSize: vmSize
    }
    osProfile: {
      computerName: vmNamePrefix
      adminUsername: adminUsername
      adminPassword: adminPassword
    }
    storageProfile: {
      imageReference: {
        publisher: imagePublisher
        offer: imageOffer
        sku: imageSKU
        version: 'latest'
      }
      osDisk: {
        createOption: 'FromImage'
      }
    }
    networkProfile: {
      networkInterfaces: [
        {
          properties: {
            primary: true
          }
          id: nic1NamePrefix_resource.id
        }
        {
          properties: {
            primary: false
          }
          id: nic2NamePrefix_resource.id
        }
      ]
    }
    diagnosticsProfile: {
      bootDiagnostics: {
        enabled: true
        storageUri: reference(storageAccountName, '2019-06-01').primaryEndpoints.blob
      }
    }
  }
  dependsOn: [
    storageAccountName_resource
    nic1NamePrefix_resource
    nic2NamePrefix_resource
  ]
}

resource vnetName_resource 'Microsoft.Network/virtualNetworks@2020-05-01' = {
  name: vnetName
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
          networkSecurityGroup: {
            id: networkSecurityGroupName_resource.id
          }
        }
      }
    ]
  }
  dependsOn: [
    networkSecurityGroupName_resource
  ]
}