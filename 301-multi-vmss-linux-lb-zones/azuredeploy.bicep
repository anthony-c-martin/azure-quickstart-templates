@allowed([
  'CentralUS'
  'FranceCentral'
])
@description('Location for the VM, only certain regions support Availability Zones')
param location string = 'CentralUS'

@description('Username for the Virtual Machine.')
param adminUsername string

@minLength(3)
@maxLength(61)
@description('String used as a base for naming resources. Must be 3-61 characters in length and globally unique across Azure. A hash is prepended to this string for some resources and resource-specific information is appended.')
param dnsName string

@description('The number of VMs to deploy in each VMSS.')
param numberOfVms int = 3

@allowed([
  'sshPublicKey'
  'password'
])
@description('Type of authentication to use on the Virtual Machine. SSH key is recommended.')
param authenticationType string = 'sshPublicKey'

@description('SSH Key or password for the Virtual Machine. SSH key is recommended.')
@secure()
param adminPasswordOrKey string

var virtualNetworkName_var = '${dnsName}-vnet'
var subnetName = 'Subnet-1'
var networkSecurityGroupName_var = 'allowRemoting'
var publicIPAddressName_var = 'lbPublicIp'
var publicIPAddressID = publicIPAddressName.id
var frontEndIPConfigID = '${lbID}/frontendIPConfigurations/loadBalancerFrontEnd'
var lbName_var = 'lb-${dnsName}'
var lbID = lbName.id
var lbBE = 'lbBE'
var lbNAT = 'lbNAT'
var myZones = [
  '1'
  '2'
  '3'
]
var linuxImage = {
  publisher: 'Canonical'
  offer: 'UbuntuServer'
  sku: '16.04.0-LTS'
  version: 'latest'
}
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

resource virtualNetworkName 'Microsoft.Network/virtualNetworks@2017-08-01' = {
  name: virtualNetworkName_var
  location: location
  properties: {
    addressSpace: {
      addressPrefixes: [
        '10.0.0.0/16'
      ]
    }
    subnets: [
      {
        name: subnetName
        properties: {
          addressPrefix: '10.0.0.0/24'
        }
      }
    ]
  }
}

resource networkSecurityGroupName 'Microsoft.Network/networkSecurityGroups@2016-03-30' = {
  name: networkSecurityGroupName_var
  location: location
  properties: {
    securityRules: [
      {
        name: 'remoteConnection'
        properties: {
          description: 'Allow SSH traffic'
          protocol: 'Tcp'
          sourcePortRange: '*'
          destinationPortRange: '22'
          sourceAddressPrefix: '*'
          destinationAddressPrefix: '*'
          access: 'Allow'
          priority: 101
          direction: 'Inbound'
        }
      }
      {
        name: 'webTraffic'
        properties: {
          description: 'Allow web traffic'
          protocol: 'Tcp'
          sourcePortRange: '80'
          destinationPortRange: '80'
          sourceAddressPrefix: '*'
          destinationAddressPrefix: '*'
          access: 'Allow'
          priority: 100
          direction: 'Inbound'
        }
      }
    ]
  }
}

resource publicIPAddressName 'Microsoft.Network/publicIPAddresses@2017-08-01' = {
  name: publicIPAddressName_var
  location: location
  sku: {
    name: 'Standard'
  }
  properties: {
    publicIPAllocationMethod: 'Static'
    dnsSettings: {
      domainNameLabel: dnsName
    }
  }
}

resource lbName 'Microsoft.Network/loadBalancers@2017-08-01' = {
  name: lbName_var
  location: location
  sku: {
    name: 'Standard'
  }
  properties: {
    frontendIPConfigurations: [
      {
        name: 'LoadBalancerFrontEnd'
        properties: {
          publicIPAddress: {
            id: publicIPAddressID
          }
        }
      }
    ]
    backendAddressPools: [
      {
        name: lbBE
      }
    ]
    loadBalancingRules: [
      {
        name: 'lbrule1'
        properties: {
          frontendIPConfiguration: {
            id: frontEndIPConfigID
          }
          backendAddressPool: {
            id: resourceId('Microsoft.Network/loadBalancers/backendAddressPools', lbName_var, lbBE)
          }
          protocol: 'Tcp'
          frontendPort: 80
          backendPort: 80
          probe: {
            id: '${lbName.id}/probes/tcpProbe'
          }
        }
      }
    ]
    probes: [
      {
        name: 'tcpProbe'
        properties: {
          protocol: 'Tcp'
          port: 80
          intervalInSeconds: '5'
          numberOfProbes: '2'
        }
      }
    ]
    inboundNatPools: [
      {
        name: '${lbNAT}1'
        properties: {
          frontendIPConfiguration: {
            id: frontEndIPConfigID
          }
          protocol: 'Tcp'
          frontendPortRangeStart: 50100
          frontendPortRangeEnd: 50199
          backendPort: 22
        }
      }
      {
        name: '${lbNAT}2'
        properties: {
          frontendIPConfiguration: {
            id: frontEndIPConfigID
          }
          protocol: 'Tcp'
          frontendPortRangeStart: 50200
          frontendPortRangeEnd: 50299
          backendPort: 22
        }
      }
      {
        name: '${lbNAT}3'
        properties: {
          frontendIPConfiguration: {
            id: frontEndIPConfigID
          }
          protocol: 'Tcp'
          frontendPortRangeStart: 50300
          frontendPortRangeEnd: 50399
          backendPort: 22
        }
      }
    ]
  }
}

resource myScaleset_zone_myZones 'Microsoft.Compute/virtualMachineScaleSets@2017-03-30' = [for (item, i) in myZones: {
  name: 'myScaleset-zone${item}'
  location: location
  zones: [
    item
  ]
  sku: {
    name: 'Standard_A2_v2'
    capacity: numberOfVms
  }
  properties: {
    singlePlacementGroup: true
    upgradePolicy: {
      mode: 'Manual'
    }
    virtualMachineProfile: {
      storageProfile: {
        osDisk: {
          createOption: 'FromImage'
        }
        imageReference: linuxImage
        dataDisks: [
          {
            lun: 1
            createOption: 'Empty'
            diskSizeGB: 50
          }
        ]
      }
      osProfile: {
        computerNamePrefix: 'vm'
        adminUsername: adminUsername
        adminPassword: adminPasswordOrKey
        customData: base64(item)
        linuxConfiguration: ((authenticationType == 'password') ? json('null') : linuxConfiguration)
      }
      networkProfile: {
        networkInterfaceConfigurations: [
          {
            name: 'myNic'
            properties: {
              networkSecurityGroup: {
                id: networkSecurityGroupName.id
              }
              primary: true
              ipConfigurations: [
                {
                  name: 'myIpConfig'
                  properties: {
                    subnet: {
                      id: resourceId('Microsoft.Network/virtualNetworks/subnets', virtualNetworkName_var, subnetName)
                    }
                    loadBalancerBackendAddressPools: [
                      {
                        id: resourceId('Microsoft.Network/loadBalancers/backendAddressPools', lbName_var, lbBE)
                      }
                    ]
                    loadBalancerInboundNatPools: [
                      {
                        id: resourceId('Microsoft.Network/loadBalancers/inboundNatPools', lbName_var, concat(lbNAT, (i + 1)))
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
            name: 'AppInstall'
            properties: {
              publisher: 'Microsoft.Azure.Extensions'
              type: 'CustomScript'
              typeHandlerVersion: '2.0'
              autoUpgradeMinorVersion: true
              settings: {
                fileUris: [
                  'https://raw.githubusercontent.com/Azure-Samples/compute-automation-configurations/master/automate_nginx.sh'
                ]
                commandToExecute: 'bash automate_nginx.sh'
              }
            }
          }
        ]
      }
    }
  }
  dependsOn: [
    virtualNetworkName
    lbName
    networkSecurityGroupName
  ]
}]