param artifactsLocation string {
  metadata: {
    description: 'The base URI where artifacts required by this template are located. When the template is deployed using the accompanying scripts, a private location in the subscription will be used and this value will be automatically generated.'
  }
  default: 'https://raw.githubusercontent.com/Azure/azure-quickstart-templates/master/kubernetes-on-ubuntu-vmss/'
}
param artifactsLocationSasToken string {
  metadata: {
    description: 'The sasToken required to access _artifactsLocation.  When the template is deployed using the accompanying scripts, a sasToken will be automatically generated.'
  }
  secure: true
  default: ''
}
param vmName string {
  metadata: {
    description: 'The name of your VM master node.'
  }
}
param vmssName string {
  metadata: {
    description: 'The name of your VMSS cluster.'
  }
}
param location string {
  metadata: {
    description: 'Location for all resources.'
  }
  default: resourceGroup().location
}
param adminUsername string {
  metadata: {
    description: 'Username for the Virtual Machine.'
  }
}
param adminKey string {
  metadata: {
    description: 'SSH Key for the Virtual Machine.'
  }
  secure: true
}
param defaultNodeCount int {
  metadata: {
    description: 'The initial node size of your VMSS cluster.'
  }
  default: 1
}
param minNodeCount int {
  metadata: {
    description: 'The min node size of your VMSS cluster.'
  }
  default: 1
}
param maxNodeCount int {
  metadata: {
    description: 'The max node size of your VMSS cluster.'
  }
  default: 20
}
param spClientId string {
  metadata: {
    description: 'ServicePrincipal ClientID'
  }
}
param spClientSecret string {
  metadata: {
    description: 'ServicePrincipal Secret'
  }
  secure: true
}
param dnsLabelPrefix string {
  metadata: {
    description: 'Unique DNS Name for the Public IP used to access the Virtual Machine.'
  }
  default: toLower('k8s-cluster-${uniqueString(resourceGroup().id)}')
}
param vmssDnsLabelPrefix string {
  metadata: {
    description: 'Unique DNS Name for the Public IP used to access the VMSS.'
  }
  default: toLower('k8s-vmss-cluster-${uniqueString(resourceGroup().id)}')
}
param vmSize string {
  metadata: {
    description: 'The size of the VM'
  }
  default: 'Standard_DS2_v2'
}
param virtualNetworkName string {
  metadata: {
    description: 'Name of the VNET'
  }
  default: 'vNet'
}
param subnetName string {
  metadata: {
    description: 'Name of the subnet in the virtual network'
  }
  default: 'Subnet'
}
param vmssSubnetName string {
  metadata: {
    description: 'Name of the VMSS subnet in the virtual network'
  }
  default: 'VMSSSubnet'
}

var publicIpAddressName = '${vmName}PublicIP'
var vmssPublicIpAddressName = '${vmssName}PublicIP'
var networkInterfaceName = '${vmName}NetInt'
var subnetRef = resourceId('Microsoft.Network/virtualNetworks/subnets', virtualNetworkName, subnetName)
var vmssSubnetRef = resourceId('Microsoft.Network/virtualNetworks/subnets', virtualNetworkName, vmssSubnetName)
var osDiskType = 'Standard_LRS'
var scriptsDir = 'scripts'
var masterScriptFileName = 'cloud-init-master.sh'
var vmssScriptFileName = 'cloud-init-vmss.sh'
var subscriptionId = subscription().subscriptionId
var tenantId = subscription().tenantId

resource networkInterfaceName_resource 'Microsoft.Network/networkInterfaces@2019-11-01' = {
  name: networkInterfaceName
  location: location
  properties: {
    ipConfigurations: [
      {
        name: 'ipconfig1'
        properties: {
          subnet: {
            id: subnetRef
          }
          privateIPAllocationMethod: 'Dynamic'
          publicIpAddress: {
            id: publicIpAddressName_resource.id
          }
        }
      }
    ]
  }
  dependsOn: [
    virtualNetworkName_resource
    publicIpAddressName_resource
  ]
}

resource virtualNetworkName_resource 'Microsoft.Network/virtualNetworks@2019-11-01' = {
  name: virtualNetworkName
  location: location
  properties: {
    addressSpace: {
      addressPrefixes: [
        '10.0.0.0/16'
      ]
    }
    subnets: [
      {
        name: vmssSubnetName
        properties: {
          addressPrefix: '10.0.0.0/24'
        }
      }
      {
        name: subnetName
        properties: {
          addressPrefix: '10.0.1.0/24'
        }
      }
    ]
  }
}

resource publicIpAddressName_resource 'Microsoft.Network/publicIPAddresses@2019-11-01' = {
  name: publicIpAddressName
  location: location
  properties: {
    publicIPAllocationMethod: 'Dynamic'
    publicIPAddressVersion: 'IPv4'
    dnsSettings: {
      domainNameLabel: dnsLabelPrefix
    }
    idleTimeoutInMinutes: 10
  }
}

resource vmName_resource 'Microsoft.Compute/virtualMachines@2019-07-01' = {
  name: vmName
  location: location
  properties: {
    hardwareProfile: {
      vmSize: vmSize
    }
    storageProfile: {
      osDisk: {
        createOption: 'FromImage'
        managedDisk: {
          storageAccountType: osDiskType
        }
      }
      imageReference: {
        publisher: 'Canonical'
        offer: 'UbuntuServer'
        sku: '18.04-LTS'
        version: 'latest'
      }
    }
    networkProfile: {
      networkInterfaces: [
        {
          id: networkInterfaceName_resource.id
        }
      ]
    }
    osProfile: {
      computerName: vmName
      adminUsername: adminUsername
      adminPassword: adminKey
      linuxConfiguration: {
        disablePasswordAuthentication: true
        ssh: {
          publicKeys: [
            {
              path: '/home/${adminUsername}/.ssh/authorized_keys'
              keyData: adminKey
            }
          ]
        }
      }
    }
  }
  dependsOn: [
    networkInterfaceName_resource
  ]
}

resource vmName_customScript 'Microsoft.Compute/virtualMachines/extensions@2019-07-01' = {
  name: '${vmName}/customScript'
  location: location
  properties: {
    publisher: 'Microsoft.Azure.Extensions'
    type: 'CustomScript'
    typeHandlerVersion: '2.0'
    autoUpgradeMinorVersion: true
    protectedSettings: {
      commandToExecute: 'bash ${masterScriptFileName} ${spClientId} ${spClientSecret} ${resourceGroup().name} ${subscriptionId} ${tenantId}'
      fileUris: [
        '${artifactsLocation}${scriptsDir}/${masterScriptFileName}${artifactsLocationSasToken}'
      ]
    }
  }
  dependsOn: [
    vmName_resource
  ]
}

resource vmssName_resource 'Microsoft.Compute/virtualMachineScaleSets@2019-07-01' = {
  name: vmssName
  tags: {
    'cluster-autoscaler-enabled': 'true'
    'cluster-autoscaler-name': resourceGroup().name
    min: minNodeCount
    max: maxNodeCount
    poolName: vmssName
  }
  location: location
  sku: {
    name: vmSize
    tier: 'Standard'
    capacity: defaultNodeCount
  }
  properties: {
    overprovision: false
    upgradePolicy: {
      mode: 'Manual'
    }
    virtualMachineProfile: {
      storageProfile: {
        osDisk: {
          createOption: 'FromImage'
          caching: 'ReadWrite'
        }
        imageReference: {
          publisher: 'Canonical'
          offer: 'UbuntuServer'
          sku: '18.04-LTS'
          version: 'latest'
        }
      }
      osProfile: {
        computerNamePrefix: vmssName
        adminUsername: adminUsername
        adminPassword: adminKey
        linuxConfiguration: {
          disablePasswordAuthentication: true
          ssh: {
            publicKeys: [
              {
                path: '/home/${adminUsername}/.ssh/authorized_keys'
                keyData: adminKey
              }
            ]
          }
        }
      }
      networkProfile: {
        networkInterfaceConfigurations: [
          {
            name: 'nic${vmssName}'
            properties: {
              primary: true
              ipConfigurations: [
                {
                  name: 'ipconfigVmss${vmssName}'
                  properties: {
                    subnet: {
                      id: vmssSubnetRef
                    }
                    publicIPAddressConfiguration: {
                      name: vmssPublicIpAddressName
                      properties: {
                        idleTimeoutInMinutes: 10
                        dnsSettings: {
                          domainNameLabel: vmssDnsLabelPrefix
                        }
                      }
                    }
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
            name: 'customVmssScript'
            properties: {
              publisher: 'Microsoft.Azure.Extensions'
              type: 'CustomScript'
              typeHandlerVersion: '2.0'
              autoUpgradeMinorVersion: true
              protectedSettings: {
                commandToExecute: 'bash ${vmssScriptFileName} ${spClientId} ${spClientSecret} ${resourceGroup().name} ${subscriptionId} ${tenantId} ${location} ${vmssSubnetName} ${virtualNetworkName}'
                fileUris: [
                  '${artifactsLocation}${scriptsDir}/${vmssScriptFileName}${artifactsLocationSasToken}'
                ]
              }
            }
          }
        ]
      }
    }
  }
  dependsOn: [
    networkInterfaceName_resource
  ]
}

output adminUsername_output string = adminUsername
output hostname string = reference(publicIpAddressName).dnsSettings.fqdn
output sshCommand string = 'ssh ${adminUsername}@${reference(publicIpAddressName).dnsSettings.fqdn}'