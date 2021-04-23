@minValue(1)
@maxValue(50)
@description('Number of master node in VMSS; if singlePlacementGroup is true (the default), then this value must be 100 or less; if singlePlacementGroup is false, then ths value must be 50 or less')
param masterNodeCount int

@description('Size of VMs in the VM Scale Set for master node.')
param masterNodeSku string = 'Standard_A1'

@description('Size of VMs in the VM Scale Set for data node.')
param dataNodeSku string = 'Standard_D4S_v3'

@minValue(1)
@maxValue(100)
@description('Number of data nodes in VMSS; if singlePlacementGroup is true (the default), then this value must be 100 or less; if singlePlacementGroup is false, then ths value must be 100 or less')
param dataNodeCount int

@description('Admin username on all VMs.')
param adminUsername string

@description('Maps to the publisher in the Azure Stack Platform Image Repository manifest file.')
param osImagePublisher string = 'OpenLogic'

@description('Maps to the Offer in the Azure Stack Platform Image Repository manifest file.')
param osImageOffer string = 'CentOS'

@description('The CentOS version for the VM. This will pick a fully patched image of this given CentOS version. Default value: 7.4')
param osImageSku string = '7.4'

@description('Location for all resources.')
param location string = resourceGroup().location

@allowed([
  'sshPublicKey'
  'password'
])
@description('Type of authentication to use on the Virtual Machine. SSH key is recommended.')
param authenticationType string = 'sshPublicKey'

@description('SSH Key or password for the Virtual Machine. SSH key is recommended.')
@secure()
param adminPasswordOrKey string

var vmssName = 'vmss${uniqueString(resourceGroup().id, deployment().name)}'
var vnetName_var = 'vnet-${vmssName}'
var subnetMaster = 'mastersubnet-${vmssName}'
var subnetData = 'datasubnet-${vmssName}'
var masterPublicIPAddressName_var = toLower('pip-master${vmssName}')
var dataPublicIPAddressName_var = toLower('pip-data${vmssName}')
var vmssDomainName = toLower('pubdns${vmssName}')
var masterNodeLoadBalancerName_var = 'LB-MasterN${vmssName}'
var dataNodeLoadBalancerName_var = 'LB-DataN${vmssName}'
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

resource vnetName 'Microsoft.Network/virtualNetworks@2017-06-01' = {
  name: vnetName_var
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

resource masterPublicIPAddressName 'Microsoft.Network/publicIPAddresses@2017-06-01' = {
  name: masterPublicIPAddressName_var
  location: location
  properties: {
    publicIPAllocationMethod: 'Dynamic'
    dnsSettings: {
      domainNameLabel: '${vmssDomainName}-master-node'
    }
  }
}

resource dataPublicIPAddressName 'Microsoft.Network/publicIPAddresses@2017-06-01' = {
  name: dataPublicIPAddressName_var
  location: location
  properties: {
    publicIPAllocationMethod: 'Dynamic'
    dnsSettings: {
      domainNameLabel: '${vmssDomainName}-data-node'
    }
  }
}

resource masterNodeLoadBalancerName 'Microsoft.Network/loadBalancers@2017-06-01' = {
  name: masterNodeLoadBalancerName_var
  location: location
  properties: {
    frontendIPConfigurations: [
      {
        name: masterNodeLoadBalancerFrontEndName
        properties: {
          publicIPAddress: {
            id: masterPublicIPAddressName.id
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
            id: resourceId('Microsoft.Network/loadBalancers/frontendIPConfigurations', masterNodeLoadBalancerName_var, masterNodeLoadBalancerFrontEndName)
          }
          backendAddressPool: {
            id: resourceId('Microsoft.Network/loadBalancers/backendAddressPools', masterNodeLoadBalancerName_var, masterNodeLoadBalancerBackEndName)
          }
          protocol: 'Tcp'
          frontendPort: 80
          backendPort: 80
          enableFloatingIP: false
          idleTimeoutInMinutes: 5
          probe: {
            id: resourceId('Microsoft.Network/loadBalancers/probes', masterNodeLoadBalancerName_var, masterNodeLoadBalancerProbeName)
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
            id: resourceId('Microsoft.Network/loadBalancers/frontendIPConfigurations', masterNodeLoadBalancerName_var, masterNodeLoadBalancerFrontEndName)
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
    vnetName
  ]
}

resource dataNodeLoadBalancerName 'Microsoft.Network/loadBalancers@2017-06-01' = {
  name: dataNodeLoadBalancerName_var
  location: location
  properties: {
    frontendIPConfigurations: [
      {
        name: dataNodeLoadBalancerFrontEndName
        properties: {
          publicIPAddress: {
            id: dataPublicIPAddressName.id
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
            id: resourceId('Microsoft.Network/loadBalancers/frontendIPConfigurations', dataNodeLoadBalancerName_var, dataNodeLoadBalancerFrontEndName)
          }
          backendAddressPool: {
            id: resourceId('Microsoft.Network/loadBalancers/backendAddressPools', dataNodeLoadBalancerName_var, dataNodeLoadBalancerBackEndName)
          }
          protocol: 'Tcp'
          frontendPort: 80
          backendPort: 80
          enableFloatingIP: false
          idleTimeoutInMinutes: 5
          probe: {
            id: resourceId('Microsoft.Network/loadBalancers/probes', dataNodeLoadBalancerName_var, dataNodeLoadBalancerProbeName)
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
            id: resourceId('Microsoft.Network/loadBalancers/frontendIPConfigurations', dataNodeLoadBalancerName_var, dataNodeLoadBalancerFrontEndName)
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
    vnetName
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
                      id: resourceId('Microsoft.Network/virtualNetworks/subnets', vnetName_var, subnetMaster)
                    }
                    loadBalancerBackendAddressPools: [
                      {
                        id: resourceId('Microsoft.Network/loadBalancers/backendAddressPools', masterNodeLoadBalancerName_var, masterNodeLoadBalancerBackEndName)
                      }
                    ]
                    loadBalancerInboundNatPools: [
                      {
                        id: resourceId('Microsoft.Network/loadBalancers/inboundNatPools', masterNodeLoadBalancerName_var, masterNodeLoadBalancerNatPoolName)
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
    vnetName
    masterNodeLoadBalancerName
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
                      id: resourceId('Microsoft.Network/virtualNetworks/subnets', vnetName_var, subnetData)
                    }
                    loadBalancerBackendAddressPools: [
                      {
                        id: resourceId('Microsoft.Network/loadBalancers/backendAddressPools', dataNodeLoadBalancerName_var, dataNodeLoadBalancerBackEndName)
                      }
                    ]
                    loadBalancerInboundNatPools: [
                      {
                        id: resourceId('Microsoft.Network/loadBalancers/inboundNatPools', dataNodeLoadBalancerName_var, dataNodeLoadBalancerNatPoolName)
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
    vnetName
    dataNodeLoadBalancerName
  ]
}