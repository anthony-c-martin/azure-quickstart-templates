@description('The name of the cluster.')
param clusterName string = 'es-azure'

@maxLength(61)
@description('String used as a base for naming resources. Must be 3-61 characters in length and globally unique across Azure. A hash is prepended to this string for some resources, and resource-specific information is appended.')
param vmssName string

@maxValue(200)
@description('Number of VM instances (200 or less).')
param instanceCount int = 2

@description('Admin username on all VMs.')
param adminUsername string

@description('Location for all resources.')
param location string = resourceGroup().location

@description('Change this value to your repo name if deploying from a fork')
param artifactsLocation string = 'https://raw.githubusercontent.com/Azure/azure-quickstart-templates/master/elasticsearch-vmss/'

@description('Auto-generated token to access _artifactsLocation')
@secure()
param artifactsLocationSasToken string = ''

@allowed([
  'sshPublicKey'
  'password'
])
@description('Type of authentication to use on the Virtual Machine. SSH key is recommended.')
param authenticationType string = 'sshPublicKey'

@description('SSH Key or password for the Virtual Machine. SSH key is recommended.')
@secure()
param adminPasswordOrKey string

var storageAccountType = 'Premium_LRS'
var addressPrefix = '10.0.0.0/16'
var subnetPrefix = '10.0.0.0/24'
var namingInfix_var = toLower(vmssName)
var domainNameLabel = namingInfix_var
var virtualNetworkName_var = '${namingInfix_var}-vnet'
var publicIpAddressName_var = '${namingInfix_var}-pip'
var publicIpAddressId = publicIpAddressName.id
var loadBalancerName_var = '${namingInfix_var}-lb'
var loadBalancerId = loadBalancerName.id
var backendPoolName = '${namingInfix_var}-bepool'
var nicName_var = '${namingInfix_var}-nic'
var masterName_var = '${namingInfix_var}-master'
var availabilitySetName_var = '${namingInfix_var}-master-set'
var nsgName_var = '${namingInfix_var}-master-nsg'
var ipConfigName = '${namingInfix_var}-ipconfig'
var frontendIpConfigId = '${loadBalancerId}/frontendIPConfigurations/loadBalancerFrontEnd'
var loadBalancerPoolId = '${loadBalancerId}/backendAddressPools/${backendPoolName}'
var loadBalancerProbeId = '${loadBalancerId}/probes/tcpProbe'
var sshProbeId = '${loadBalancerId}/probes/sshProbe'
var subnetName = '${namingInfix_var}-subnet'
var masterSize = 'Standard_DS2_v2'
var vmSku = 'Standard_DS2_v2'
var imageReference = {
  publisher: 'Canonical'
  offer: 'UbuntuServer'
  sku: '18.04-LTS'
  version: 'latest'
}
var elasticSetupScriptUrl = uri(artifactsLocation, 'install-elasticsearch.sh${artifactsLocationSasToken}')
var diskSetupScriptUrl = 'https://raw.githubusercontent.com/Azure/azure-quickstart-templates/master/shared_scripts/ubuntu/vm-disk-utils-0.1.sh'
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

resource nsgName 'Microsoft.Network/networkSecurityGroups@2018-07-01' = {
  name: nsgName_var
  location: location
  properties: {
    securityRules: [
      {
        name: 'ssh'
        properties: {
          description: 'Allows inbound ssh traffic'
          protocol: 'Tcp'
          sourcePortRange: '*'
          destinationPortRange: '22'
          sourceAddressPrefix: '*'
          destinationAddressPrefix: '*'
          access: 'Allow'
          priority: 100
          direction: 'Inbound'
        }
      }
      {
        name: 'Elasticsearch'
        properties: {
          description: 'Allows inbound HTTP traffic from anyone'
          protocol: 'Tcp'
          sourcePortRange: '*'
          destinationPortRange: '5601'
          sourceAddressPrefix: '*'
          destinationAddressPrefix: '*'
          access: 'Allow'
          priority: 200
          direction: 'Inbound'
        }
      }
    ]
  }
}

resource virtualNetworkName 'Microsoft.Network/virtualNetworks@2018-07-01' = {
  name: virtualNetworkName_var
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

resource publicIpAddressName 'Microsoft.Network/publicIPAddresses@2018-07-01' = {
  name: publicIpAddressName_var
  location: location
  properties: {
    publicIPAllocationMethod: 'Dynamic'
    dnsSettings: {
      domainNameLabel: domainNameLabel
    }
  }
}

resource loadBalancerName 'Microsoft.Network/loadBalancers@2018-07-01' = {
  name: loadBalancerName_var
  location: location
  properties: {
    frontendIPConfigurations: [
      {
        name: 'LoadBalancerFrontEnd'
        properties: {
          publicIPAddress: {
            id: publicIpAddressId
          }
        }
      }
    ]
    backendAddressPools: [
      {
        name: backendPoolName
      }
    ]
    loadBalancingRules: [
      {
        name: 'LBRule'
        properties: {
          frontendIPConfiguration: {
            id: frontendIpConfigId
          }
          backendAddressPool: {
            id: loadBalancerPoolId
          }
          protocol: 'Tcp'
          frontendPort: 5601
          backendPort: 5601
          enableFloatingIP: false
          idleTimeoutInMinutes: 5
          probe: {
            id: loadBalancerProbeId
          }
        }
      }
      {
        name: 'ssh'
        properties: {
          frontendIPConfiguration: {
            id: frontendIpConfigId
          }
          backendAddressPool: {
            id: loadBalancerPoolId
          }
          protocol: 'Tcp'
          frontendPort: 22
          backendPort: 22
          enableFloatingIP: false
          idleTimeoutInMinutes: 5
          probe: {
            id: sshProbeId
          }
        }
      }
    ]
    probes: [
      {
        name: 'tcpProbe'
        properties: {
          protocol: 'Tcp'
          port: 9200
          intervalInSeconds: 30
          numberOfProbes: 2
        }
      }
      {
        name: 'sshProbe'
        properties: {
          protocol: 'Tcp'
          port: 22
          intervalInSeconds: 30
          numberOfProbes: 2
        }
      }
    ]
  }
}

resource availabilitySetName 'Microsoft.Compute/availabilitySets@2018-06-01' = {
  name: availabilitySetName_var
  location: location
  properties: {
    platformUpdateDomainCount: 3
    platformFaultDomainCount: 3
  }
  sku: {
    name: 'Aligned'
  }
}

resource nicName 'Microsoft.Network/networkInterfaces@2018-07-01' = [for i in range(0, 3): {
  name: concat(nicName_var, i)
  location: location
  properties: {
    ipConfigurations: [
      {
        name: 'ipconfigmaster'
        properties: {
          privateIPAllocationMethod: 'Static'
          privateIPAddress: '10.0.0.1${i}'
          subnet: {
            id: '${virtualNetworkName.id}/subnets/${subnetName}'
          }
          loadBalancerBackendAddressPools: [
            {
              id: '${loadBalancerName.id}/backendAddressPools/${backendPoolName}'
            }
          ]
        }
      }
    ]
    networkSecurityGroup: {
      id: nsgName.id
    }
  }
  dependsOn: [
    publicIpAddressName
    nsgName
  ]
}]

resource masterName 'Microsoft.Compute/virtualMachines@2018-06-01' = [for i in range(0, 3): {
  name: concat(masterName_var, i)
  location: location
  properties: {
    availabilitySet: {
      id: availabilitySetName.id
    }
    hardwareProfile: {
      vmSize: masterSize
    }
    osProfile: {
      computerName: 'master-vm${i}'
      adminUsername: adminUsername
      adminPassword: adminPasswordOrKey
      linuxConfiguration: ((authenticationType == 'password') ? json('null') : linuxConfiguration)
    }
    storageProfile: {
      imageReference: imageReference
      osDisk: {
        createOption: 'FromImage'
        caching: 'ReadWrite'
        managedDisk: {
          storageAccountType: storageAccountType
        }
      }
    }
    networkProfile: {
      networkInterfaces: [
        {
          id: resourceId('Microsoft.Network/networkInterfaces', concat(nicName_var, i))
        }
      ]
    }
  }
  dependsOn: [
    'Microsoft.Network/networkInterfaces/${nicName_var}${i}'
    availabilitySetName
  ]
}]

resource masterName_installelasticsearch 'Microsoft.Compute/virtualMachines/extensions@2017-03-30' = [for i in range(0, 3): {
  name: '${masterName_var}${i}/installelasticsearch'
  location: location
  properties: {
    publisher: 'Microsoft.Azure.Extensions'
    type: 'CustomScript'
    typeHandlerVersion: '2.0'
    autoUpgradeMinorVersion: true
    settings: {
      fileUris: [
        elasticSetupScriptUrl
        diskSetupScriptUrl
      ]
      commandToExecute: 'bash install-elasticsearch.sh -m -n ${clusterName}'
    }
  }
  dependsOn: [
    'Microsoft.Compute/virtualMachines/${masterName_var}${i}'
  ]
}]

resource namingInfix 'Microsoft.Compute/virtualMachineScaleSets@2018-06-01' = {
  name: namingInfix_var
  location: location
  sku: {
    name: vmSku
    tier: 'Standard'
    capacity: instanceCount
  }
  properties: {
    largeScaleEnabled: 'true'
    overprovision: 'true'
    upgradePolicy: {
      mode: 'Manual'
    }
    virtualMachineProfile: {
      storageProfile: {
        osDisk: {
          createOption: 'FromImage'
        }
        imageReference: imageReference
        dataDisks: [
          {
            lun: 0
            createOption: 'Empty'
            diskSizeGB: 128
            caching: 'ReadWrite'
            managedDisk: {
              storageAccountType: storageAccountType
            }
          }
        ]
      }
      osProfile: {
        computerNamePrefix: namingInfix_var
        adminUsername: adminUsername
        adminPassword: adminPasswordOrKey
        linuxConfiguration: ((authenticationType == 'password') ? json('null') : linuxConfiguration)
      }
      networkProfile: {
        networkInterfaceConfigurations: [
          {
            name: nicName_var
            properties: {
              primary: true
              ipConfigurations: [
                {
                  name: ipConfigName
                  properties: {
                    subnet: {
                      id: '${virtualNetworkName.id}/subnets/${subnetName}'
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
            name: 'elasticsearch'
            properties: {
              publisher: 'Microsoft.Azure.Extensions'
              type: 'CustomScript'
              typeHandlerVersion: '2.0'
              autoUpgradeMinorVersion: true
              settings: {
                fileUris: [
                  elasticSetupScriptUrl
                ]
                commandToExecute: 'bash install-elasticsearch.sh -n ${clusterName}'
              }
            }
          }
        ]
      }
    }
  }
  dependsOn: [
    masterName
  ]
}

output kibana_url string = 'http://${publicIpAddressName.properties.dnsSettings.fqdn}:5601/app/monitoring#/elasticsearch'
output ssh_connection string = 'ssh ${adminUsername}@${publicIpAddressName.properties.dnsSettings.fqdn}'