param masterNodeCount int {
  minValue: 1
  maxValue: 50
  metadata: {
    description: 'Number of master node in VMSS; if singlePlacementGroup is true (the default), then this value must be 100 or less; if singlePlacementGroup is false, then ths value must be 50 or less'
  }
}
param masterNodeSku string {
  metadata: {
    description: 'Size of VMs in the VM Scale Set for master node.'
  }
  default: 'Standard_A1'
}
param dataNodeSku string {
  metadata: {
    description: 'Size of VMs in the VM Scale Set for data node.'
  }
  default: 'Standard_D4S_v3'
}
param dataNodeCount int {
  minValue: 1
  maxValue: 100
  metadata: {
    description: 'Number of data nodes in VMSS; if singlePlacementGroup is true (the default), then this value must be 100 or less; if singlePlacementGroup is false, then ths value must be 100 or less'
  }
}
param adminUsername string {
  metadata: {
    description: 'Admin username on all VMs.'
  }
}
param osImagePublisher string {
  metadata: {
    description: 'Maps to the publisher in the Azure Stack Platform Image Repository manifest file.'
  }
  default: 'OpenLogic'
}
param osImageOffer string {
  metadata: {
    description: 'Maps to the Offer in the Azure Stack Platform Image Repository manifest file.'
  }
  default: 'CentOS'
}
param osImageSku string {
  metadata: {
    description: 'The CentOS version for the VM. This will pick a fully patched image of this given CentOS version. Default value: 7.4'
  }
  default: '7.4'
}
param location string {
  metadata: {
    description: 'Location for all resources.'
  }
  default: resourceGroup().location
}
param authenticationType string {
  allowed: [
    'sshPublicKey'
    'password'
  ]
  metadata: {
    description: 'Type of authentication to use on the Virtual Machine. SSH key is recommended.'
  }
  default: 'sshPublicKey'
}
param adminPasswordOrKey string {
  metadata: {
    description: 'SSH Key or password for the Virtual Machine. SSH key is recommended.'
  }
  secure: true
}

var vmssName = 'vmss${uniqueString(resourceGroup().id, deployment().name)}'
var vnetName = 'vnet-${vmssName}'
var subnetMaster = 'mastersubnet-${vmssName}'
var subnetData = 'datasubnet-${vmssName}'
var masterPublicIPAddressName = toLower('pip-master${vmssName}')
var dataPublicIPAddressName = toLower('pip-data${vmssName}')
var vmssDomainName = toLower('pubdns${vmssName}')
var masterNodeLoadBalancerName = 'LB-MasterN${vmssName}'
var dataNodeLoadBalancerName = 'LB-DataN${vmssName}'
var masterNodeLoadBalancerFrontEndName = 'LBFrontEnd${vmssName}'
var dataNodeLoadBalancerFrontEndName = 'LBFrontEnd${vmssName}'
var masterNodeLoadBalancerBackEndName = 'LBBackEnd${vmssName}'
var dataNodeLoadBalancerBackEndName = 'LBBackEnd${vmssName}'
var masterNodeLoadBalancerProbeName = 'LBHttpProbe${vmssName}'
var dataNodeLoadBalancerProbeName = 'LBHttpProbe${vmssName}'
var masterNodeLoadBalancerNatPoolName = 'LBNatPool${vmssName}'
var dataNodeLoadBalancerNatPoolName = 'LBNatPool${vmssName}'
var linuxConfiguration = {
  disablePasswordAuthentication: true
  ssh: {
    publicKeys: [
      {
        path: '/home/${adminUsername}/.ssh/authorized_keys'
        keyData: adminPasswordOrKey
      }
    ]
  }
}

resource vnetName_resource 'Microsoft.Network/virtualNetworks@2017-06-01' = {
  name: vnetName
  location: location
  properties: {
    addressSpace: {
      addressPrefixes: [
        '10.0.0.0/16'
      ]
    }
    subnets: [
      {
        name: subnetMaster
        properties: {
          addressPrefix: '10.0.0.0/24'
        }
      }
      {
        name: subnetData
        properties: {
          addressPrefix: '10.0.1.0/24'
        }
      }
    ]
  }
}

resource masterPublicIPAddressName_resource 'Microsoft.Network/publicIPAddresses@2017-06-01' = {
  name: masterPublicIPAddressName
  location: location
  properties: {
    publicIPAllocationMethod: 'Dynamic'
    dnsSettings: {
      domainNameLabel: '${vmssDomainName}-master-node'
    }
  }
}

resource dataPublicIPAddressName_resource 'Microsoft.Network/publicIPAddresses@2017-06-01' = {
  name: dataPublicIPAddressName
  location: location
  properties: {
    publicIPAllocationMethod: 'Dynamic'
    dnsSettings: {
      domainNameLabel: '${vmssDomainName}-data-node'
    }
  }
}

resource masterNodeLoadBalancerName_resource 'Microsoft.Network/loadBalancers@2017-06-01' = {
  name: masterNodeLoadBalancerName
  location: location
  properties: {
    frontendIPConfigurations: [
      {
        name: masterNodeLoadBalancerFrontEndName
        properties: {
          publicIPAddress: {
            id: masterPublicIPAddressName_resource.id
          }
        }
      }
    ]
    backendAddressPools: [
      {
        name: masterNodeLoadBalancerBackEndName
      }
    ]
    loadBalancingRules: [
      {
        name: 'roundRobinLBRule'
        properties: {
          frontendIPConfiguration: {
            id: resourceId('Microsoft.Network/loadBalancers/frontendIPConfigurations', masterNodeLoadBalancerName, masterNodeLoadBalancerFrontEndName)
          }
          backendAddressPool: {
            id: resourceId('Microsoft.Network/loadBalancers/backendAddressPools', masterNodeLoadBalancerName, masterNodeLoadBalancerBackEndName)
          }
          protocol: 'Tcp'
          frontendPort: 80
          backendPort: 80
          enableFloatingIP: false
          idleTimeoutInMinutes: 5
          probe: {
            id: resourceId('Microsoft.Network/loadBalancers/probes', masterNodeLoadBalancerName, masterNodeLoadBalancerProbeName)
          }
        }
      }
    ]
    probes: [
      {
        name: masterNodeLoadBalancerProbeName
        properties: {
          protocol: 'Tcp'
          port: 80
          intervalInSeconds: 5
          numberOfProbes: 2
        }
      }
    ]
    inboundNatPools: [
      {
        name: masterNodeLoadBalancerNatPoolName
        properties: {
          frontendIPConfiguration: {
            id: resourceId('Microsoft.Network/loadBalancers/frontendIPConfigurations', masterNodeLoadBalancerName, masterNodeLoadBalancerFrontEndName)
          }
          protocol: 'Tcp'
          frontendPortRangeStart: 50000
          frontendPortRangeEnd: 50019
          backendPort: 22
        }
      }
    ]
  }
  dependsOn: [
    vnetName_resource
    masterPublicIPAddressName_resource
  ]
}

resource dataNodeLoadBalancerName_resource 'Microsoft.Network/loadBalancers@2017-06-01' = {
  name: dataNodeLoadBalancerName
  location: location
  properties: {
    frontendIPConfigurations: [
      {
        name: dataNodeLoadBalancerFrontEndName
        properties: {
          publicIPAddress: {
            id: dataPublicIPAddressName_resource.id
          }
        }
      }
    ]
    backendAddressPools: [
      {
        name: dataNodeLoadBalancerBackEndName
      }
    ]
    loadBalancingRules: [
      {
        name: 'roundRobinLBRule'
        properties: {
          frontendIPConfiguration: {
            id: resourceId('Microsoft.Network/loadBalancers/frontendIPConfigurations', dataNodeLoadBalancerName, dataNodeLoadBalancerFrontEndName)
          }
          backendAddressPool: {
            id: resourceId('Microsoft.Network/loadBalancers/backendAddressPools', dataNodeLoadBalancerName, dataNodeLoadBalancerBackEndName)
          }
          protocol: 'Tcp'
          frontendPort: 80
          backendPort: 80
          enableFloatingIP: false
          idleTimeoutInMinutes: 5
          probe: {
            id: resourceId('Microsoft.Network/loadBalancers/probes', dataNodeLoadBalancerName, dataNodeLoadBalancerProbeName)
          }
        }
      }
    ]
    probes: [
      {
        name: dataNodeLoadBalancerProbeName
        properties: {
          protocol: 'Tcp'
          port: 80
          intervalInSeconds: 5
          numberOfProbes: 2
        }
      }
    ]
    inboundNatPools: [
      {
        name: dataNodeLoadBalancerNatPoolName
        properties: {
          frontendIPConfiguration: {
            id: resourceId('Microsoft.Network/loadBalancers/frontendIPConfigurations', dataNodeLoadBalancerName, dataNodeLoadBalancerFrontEndName)
          }
          protocol: 'Tcp'
          frontendPortRangeStart: 50000
          frontendPortRangeEnd: 50019
          backendPort: 22
        }
      }
    ]
  }
  dependsOn: [
    vnetName_resource
    dataPublicIPAddressName_resource
  ]
}

resource vmssName_master_node 'Microsoft.Compute/virtualMachineScaleSets@2017-12-01' = {
  sku: {
    name: masterNodeSku
    tier: 'Standard'
    capacity: masterNodeCount
  }
  name: '${vmssName}-master-node'
  location: location
  properties: {
    upgradePolicy: {
      mode: 'Manual'
    }
    virtualMachineProfile: {
      storageProfile: {
        osDisk: {
          caching: 'ReadWrite'
          createOption: 'FromImage'
        }
        imageReference: {
          publisher: osImagePublisher
          offer: osImageOffer
          sku: osImageSku
          version: 'latest'
        }
      }
      osProfile: {
        computerNamePrefix: vmssName
        adminUsername: adminUsername
        adminPassword: adminPasswordOrKey
        linuxConfiguration: ((authenticationType == 'password') ? json('null') : linuxConfiguration)
      }
      networkProfile: {
        networkInterfaceConfigurations: [
          {
            name: 'nic'
            properties: {
              primary: true
              ipConfigurations: [
                {
                  name: 'ipconfig'
                  properties: {
                    subnet: {
                      id: resourceId('Microsoft.Network/virtualNetworks/subnets', vnetName, subnetMaster)
                    }
                    loadBalancerBackendAddressPools: [
                      {
                        id: resourceId('Microsoft.Network/loadBalancers/backendAddressPools', masterNodeLoadBalancerName, masterNodeLoadBalancerBackEndName)
                      }
                    ]
                    loadBalancerInboundNatPools: [
                      {
                        id: resourceId('Microsoft.Network/loadBalancers/inboundNatPools', masterNodeLoadBalancerName, masterNodeLoadBalancerNatPoolName)
                      }
                    ]
                  }
                }
              ]
            }
          }
        ]
      }
      extensionProfile: {
        extensions: [
          {
            type: 'Microsoft.Compute/virtualMachines/extensions'
            name: '${vmssName}-LinuxCustomScriptExtension'
            properties: {
              publisher: 'Microsoft.OSTCExtensions'
              type: 'CustomScriptForLinux'
              typeHandlerVersion: '1.3'
              autoUpgradeMinorVersion: true
              settings: {
                commandToExecute: 'touch test1.txt'
              }
            }
          }
        ]
      }
    }
  }
  dependsOn: [
    vnetName_resource
    masterNodeLoadBalancerName_resource
  ]
}

resource vmssName_data_node 'Microsoft.Compute/virtualMachineScaleSets@2017-12-01' = {
  sku: {
    name: dataNodeSku
    tier: 'Standard'
    capacity: dataNodeCount
  }
  name: '${vmssName}-data-node'
  location: location
  properties: {
    upgradePolicy: {
      mode: 'Manual'
    }
    virtualMachineProfile: {
      storageProfile: {
        osDisk: {
          caching: 'ReadWrite'
          createOption: 'FromImage'
        }
        imageReference: {
          publisher: osImagePublisher
          offer: osImageOffer
          sku: osImageSku
          version: 'latest'
        }
      }
      osProfile: {
        computerNamePrefix: vmssName
        adminUsername: adminUsername
        adminPassword: adminPasswordOrKey
        linuxConfiguration: ((authenticationType == 'password') ? json('null') : linuxConfiguration)
      }
      networkProfile: {
        networkInterfaceConfigurations: [
          {
            name: 'nic'
            properties: {
              primary: true
              ipConfigurations: [
                {
                  name: 'ipconfig'
                  properties: {
                    subnet: {
                      id: resourceId('Microsoft.Network/virtualNetworks/subnets', vnetName, subnetData)
                    }
                    loadBalancerBackendAddressPools: [
                      {
                        id: resourceId('Microsoft.Network/loadBalancers/backendAddressPools', dataNodeLoadBalancerName, dataNodeLoadBalancerBackEndName)
                      }
                    ]
                    loadBalancerInboundNatPools: [
                      {
                        id: resourceId('Microsoft.Network/loadBalancers/inboundNatPools', dataNodeLoadBalancerName, dataNodeLoadBalancerNatPoolName)
                      }
                    ]
                  }
                }
              ]
            }
          }
        ]
      }
      extensionProfile: {
        extensions: [
          {
            type: 'Microsoft.Compute/virtualMachines/extensions'
            name: '${vmssName}-LinuxCustomScriptExtension'
            properties: {
              publisher: 'Microsoft.OSTCExtensions'
              type: 'CustomScriptForLinux'
              typeHandlerVersion: '1.3'
              autoUpgradeMinorVersion: true
              settings: {
                commandToExecute: 'touch test2.txt'
              }
            }
          }
        ]
      }
    }
  }
  dependsOn: [
    vnetName_resource
    dataNodeLoadBalancerName_resource
  ]
}