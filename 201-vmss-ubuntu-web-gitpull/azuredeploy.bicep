param vmSku string {
  metadata: {
    description: 'Size of VMs in the VM Scale Set.'
  }
  default: 'Standard_A1'
}
param vmssName string {
  maxLength: 61
  metadata: {
    description: 'String used as a base for naming resources. Must be 3-61 characters in length and globally unique across Azure. A hash is prepended to this string for some resources, and resource-specific information is appended.'
  }
}
param capacity int {
  maxValue: 100
  metadata: {
    description: 'Number of VM instances (100 or less).'
  }
}
param adminUsername string {
  metadata: {
    description: 'Admin username on all VMs.'
  }
}
param artifactsLocation string {
  metadata: {
    description: 'The base URI where artifacts required by this template are located. When the template is deployed using the accompanying scripts, a private location in the subscription will be used and this value will be automatically generated.'
  }
  default: 'https://raw.githubusercontent.com/Azure/azure-quickstart-templates/master/201-vmss-ubuntu-web-gitpull'
}
param artifactsLocationSasToken string {
  metadata: {
    description: 'The sasToken required to access _artifactsLocation.  When the template is deployed using the accompanying scripts, a sasToken will be automatically generated.'
  }
  secure: true
  default: ''
}
param scriptFileName string {
  metadata: {
    description: 'the file name of the script configuring the VMs in the scale set'
  }
}
param gitSshPrivateKey string {
  metadata: {
    description: 'SSH Private Key to authenticate against the git repo'
  }
}
param gitRepoName string {
  metadata: {
    description: 'Repo in form user@repo.gitservice.com'
  }
}
param gitUserName string {
  metadata: {
    description: 'Repo in form user@repo.gitservice.com'
  }
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

var namingInfix = toLower(substring(concat(vmssName, uniqueString(resourceGroup().id)), 0, 9))
var addressPrefix = '10.0.0.0/16'
var subnetPrefix = '10.0.0.0/24'
var virtualNetworkName = '${namingInfix}vnet'
var subnetName = '${namingInfix}subnet'
var lbName = '${namingInfix}lb'
var bepoolName = '${lbName}bepool'
var fepoolName = '${lbName}fepool'
var lbID = lbName_resource.id
var bepoolID = '${lbID}/backendAddressPools/${bepoolName}'
var feIpConfigName = '${fepoolName}IpConfig'
var feIpConfigId = '${lbID}/frontendIPConfigurations/${feIpConfigName}'
var pipName = '${namingInfix}pip'
var nicName = '${namingInfix}nic'
var natPoolName = '${lbName}natpool'
var ipConfigName = '${namingInfix}ipconfig'
var httpProbeName = 'httpProbe'
var httpsProbeName = 'httpsProbe'
var osType = {
  publisher: 'Canonical'
  offer: 'UbuntuServer'
  sku: '14.04.4-LTS'
  version: 'latest'
}
var imageReference = osType
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

resource virtualNetworkName_resource 'Microsoft.Network/virtualNetworks@2016-03-30' = {
  name: virtualNetworkName
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
        }
      }
    ]
  }
}

resource pipName_resource 'Microsoft.Network/publicIPAddresses@2016-03-30' = {
  name: pipName
  location: location
  properties: {
    publicIPAllocationMethod: 'Dynamic'
    dnsSettings: {
      domainNameLabel: namingInfix
    }
  }
}

resource lbName_resource 'Microsoft.Network/loadBalancers@2016-03-30' = {
  name: lbName
  location: location
  tags: {
    displayName: 'Load Balancer'
  }
  properties: {
    frontendIPConfigurations: [
      {
        name: feIpConfigName
        properties: {
          publicIPAddress: {
            id: pipName_resource.id
          }
        }
      }
    ]
    backendAddressPools: [
      {
        name: bepoolName
      }
    ]
    inboundNatPools: [
      {
        name: natPoolName
        properties: {
          frontendIPConfiguration: {
            id: feIpConfigId
          }
          protocol: 'Tcp'
          frontendPortRangeStart: 10022
          frontendPortRangeEnd: 11022
          backendPort: 22
        }
      }
    ]
    loadBalancingRules: [
      {
        name: 'HTTPRule'
        properties: {
          loadDistribution: 'Default'
          frontendIPConfiguration: {
            id: feIpConfigId
          }
          backendAddressPool: {
            id: bepoolID
          }
          protocol: 'Tcp'
          frontendPort: 80
          backendPort: 80
          enableFloatingIP: false
          idleTimeoutInMinutes: 5
          probe: {
            id: '${lbID}/probes/${httpProbeName}'
          }
        }
      }
      {
        name: 'HTTPSRule'
        properties: {
          loadDistribution: 'Default'
          frontendIPConfiguration: {
            id: feIpConfigId
          }
          backendAddressPool: {
            id: bepoolID
          }
          protocol: 'Tcp'
          frontendPort: 443
          backendPort: 443
          enableFloatingIP: false
          idleTimeoutInMinutes: 5
          probe: {
            id: '${lbName_resource.id}/probes/${httpsProbeName}'
          }
        }
      }
    ]
    probes: [
      {
        name: httpProbeName
        properties: {
          protocol: 'Tcp'
          port: 80
          intervalInSeconds: 5
          numberOfProbes: 2
        }
      }
      {
        name: httpsProbeName
        properties: {
          protocol: 'Tcp'
          port: 443
          intervalInSeconds: 5
          numberOfProbes: 2
        }
      }
    ]
  }
  dependsOn: [
    pipName_resource
  ]
}

resource namingInfix_resource 'Microsoft.Compute/virtualMachineScaleSets@2016-04-30-preview' = {
  name: namingInfix
  location: location
  sku: {
    name: vmSku
    tier: 'Standard'
    capacity: capacity
  }
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
        imageReference: imageReference
      }
      osProfile: {
        computerNamePrefix: namingInfix
        adminUsername: adminUsername
        adminPassword: adminPasswordOrKey
        linuxConfiguration: ((authenticationType == 'password') ? json('null') : linuxConfiguration)
      }
      networkProfile: {
        networkInterfaceConfigurations: [
          {
            name: nicName
            properties: {
              primary: true
              ipConfigurations: [
                {
                  name: ipConfigName
                  properties: {
                    subnet: {
                      id: '${virtualNetworkName_resource.id}/subnets/${subnetName}'
                    }
                    loadBalancerBackendAddressPools: [
                      {
                        id: '/subscriptions/${subscription().subscriptionId}/resourceGroups/${resourceGroup().name}/providers/Microsoft.Network/loadBalancers/${lbName}/backendAddressPools/${bepoolName}'
                      }
                    ]
                    loadBalancerInboundNatPools: [
                      {
                        id: '/subscriptions/${subscription().subscriptionId}/resourceGroups/${resourceGroup().name}/providers/Microsoft.Network/loadBalancers/${lbName}/inboundNatPools/${natPoolName}'
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
            name: 'lapextension'
            properties: {
              publisher: 'Microsoft.Azure.Extensions'
              type: 'CustomScript'
              typeHandlerVersion: '2.0'
              autoUpgradeMinorVersion: false
              settings: {
                fileUris: [
                  '${artifactsLocation}/${scriptFileName}${artifactsLocationSasToken}'
                ]
              }
              protectedSettings: {
                commandToExecute: 'bash ${scriptFileName} ${base64(gitSshPrivateKey)} ${gitRepoName} ${gitUserName}'
              }
            }
          }
        ]
      }
    }
  }
  dependsOn: [
    lbName_resource
    virtualNetworkName_resource
  ]
}

output fqdn string = reference(pipName_resource.id, '2016-03-30').dnsSettings.fqdn