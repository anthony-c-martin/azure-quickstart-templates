@description('SSH public key for the Virtual Machines.')
@secure()
param sshPublicKey string

@description('Number of Swarm worker nodes in the cluster.')
param nodeCount int = 3

@description('Location for all resources.')
param location string = resourceGroup().location

var masterCount = 3
var adminUsername = 'azureuser'
var vmNameMaster_var = 'swarm-master-'
var vmNameNode_var = 'swarm-node-'
var vmSizeMaster = 'Standard_A0'
var vmSizeNode = 'Standard_A2'
var availabilitySetMasters_var = 'swarm-masters-set'
var availabilitySetNodes_var = 'swarm-nodes-set'
var osImagePublisher = 'CoreOS'
var osImageOffer = 'CoreOS'
var osImageSKU = 'Beta'
var managementPublicIPAddrName_var = 'swarm-lb-masters-ip'
var nodesPublicIPAddrName_var = 'swarm-lb-nodes-ip'
var virtualNetworkName_var = 'swarm-vnet'
var subnetNameMasters = 'subnet-masters'
var subnetNameNodes = 'subnet-nodes'
var addressPrefixMasters = '10.0.0.0/16'
var addressPrefixNodes = '192.168.0.0/16'
var subnetPrefixMasters = '10.0.0.0/24'
var subnetPrefixNodes = '192.168.0.0/24'
var subnetRefMaster = '${virtualNetworkName.id}/subnets/${subnetNameMasters}'
var subnetRefNodes = '${virtualNetworkName.id}/subnets/${subnetNameNodes}'
var mastersNsgName_var = 'swarm-masters-firewall'
var nodesNsgName_var = 'swarm-nodes-firewall'
var mastersNsgID = mastersNsgName.id
var nodesNsgID = nodesNsgName.id
var newStorageAccountName_var = uniqueString(resourceGroup().id, deployment().name)
var clusterFqdn = 'swarm-${uniqueString(resourceGroup().id, deployment().name)}'
var storageAccountType = 'Standard_LRS'
var vhdBlobContainer = 'vhds'
var mastersLbName_var = 'swarm-lb-masters'
var mastersLbID = mastersLbName.id
var mastersLbIPConfigName = 'MastersLBFrontEnd'
var mastersLbIPConfigID = '${mastersLbID}/frontendIPConfigurations/${mastersLbIPConfigName}'
var mastersLbBackendPoolName = 'swarm-masters-pool'
var nodesLbName_var = 'swarm-lb-nodes'
var nodesLbID = nodesLbName.id
var nodesLbBackendPoolName = 'swarm-nodes-pool'
var sshKeyPath = '/home/${adminUsername}/.ssh/authorized_keys'
var consulServerArgs = [
  '-advertise 10.0.0.4 -bootstrap-expect 3 -retry-join 10.0.0.5 -retry-join 10.0.0.6'
  '-advertise 10.0.0.5 -retry-join 10.0.0.4 -retry-join 10.0.0.6'
  '-advertise 10.0.0.6 -retry-join 10.0.0.4 -retry-join 10.0.0.5'
]

resource newStorageAccountName 'Microsoft.Storage/storageAccounts@2015-06-15' = {
  name: newStorageAccountName_var
  location: location
  properties: {
    accountType: storageAccountType
  }
}

resource availabilitySetMasters 'Microsoft.Compute/availabilitySets@2017-12-01' = {
  name: availabilitySetMasters_var
  location: location
  sku: {
    name: 'Aligned'
  }
  properties: {
    platformFaultDomainCount: 2
    platformUpdateDomainCount: 5
  }
}

resource availabilitySetNodes 'Microsoft.Compute/availabilitySets@2017-12-01' = {
  name: availabilitySetNodes_var
  location: location
  sku: {
    name: 'Aligned'
  }
  properties: {
    platformFaultDomainCount: 2
    platformUpdateDomainCount: 5
  }
}

resource managementPublicIPAddrName 'Microsoft.Network/publicIPAddresses@2015-06-15' = {
  name: managementPublicIPAddrName_var
  location: location
  properties: {
    publicIPAllocationMethod: 'Dynamic'
    dnsSettings: {
      domainNameLabel: '${clusterFqdn}-manage'
    }
  }
}

resource nodesPublicIPAddrName 'Microsoft.Network/publicIPAddresses@2015-06-15' = {
  name: nodesPublicIPAddrName_var
  location: location
  properties: {
    publicIPAllocationMethod: 'Dynamic'
    dnsSettings: {
      domainNameLabel: clusterFqdn
    }
  }
}

resource virtualNetworkName 'Microsoft.Network/virtualNetworks@2015-06-15' = {
  name: virtualNetworkName_var
  location: location
  properties: {
    addressSpace: {
      addressPrefixes: [
        addressPrefixMasters
        addressPrefixNodes
      ]
    }
    subnets: [
      {
        name: subnetNameMasters
        properties: {
          addressPrefix: subnetPrefixMasters
          networkSecurityGroup: {
            id: mastersNsgID
          }
        }
      }
      {
        name: subnetNameNodes
        properties: {
          addressPrefix: subnetPrefixNodes
          networkSecurityGroup: {
            id: nodesNsgID
          }
        }
      }
    ]
  }
  dependsOn: [
    mastersNsgID
    nodesNsgID
  ]
}

resource mastersNsgName 'Microsoft.Network/networkSecurityGroups@2015-06-15' = {
  name: mastersNsgName_var
  location: location
  properties: {
    securityRules: [
      {
        name: 'ssh'
        properties: {
          description: ''
          protocol: 'Tcp'
          sourcePortRange: '*'
          destinationPortRange: '22'
          sourceAddressPrefix: '*'
          destinationAddressPrefix: '*'
          access: 'Allow'
          priority: 1000
          direction: 'Inbound'
        }
      }
    ]
  }
}

resource nodesNsgName 'Microsoft.Network/networkSecurityGroups@2015-06-15' = {
  name: nodesNsgName_var
  location: location
  properties: {
    securityRules: [
      {
        name: 'AllowAny'
        properties: {
          description: 'Swarm node ports need to be configured on the load balancer to be reachable'
          protocol: '*'
          sourcePortRange: '*'
          destinationPortRange: '*'
          sourceAddressPrefix: '*'
          destinationAddressPrefix: '*'
          access: 'Allow'
          priority: 1000
          direction: 'Inbound'
        }
      }
    ]
  }
}

resource vmNameMaster_nic 'Microsoft.Network/networkInterfaces@2015-06-15' = [for i in range(0, masterCount): {
  name: '${vmNameMaster_var}${i}-nic'
  location: location
  properties: {
    ipConfigurations: [
      {
        name: 'ipConfigMaster'
        properties: {
          privateIPAllocationMethod: 'Static'
          privateIPAddress: '10.0.0.${(i + 4)}'
          subnet: {
            id: subnetRefMaster
          }
          loadBalancerBackendAddressPools: [
            {
              id: '${mastersLbID}/backendAddressPools/${mastersLbBackendPoolName}'
            }
          ]
          loadBalancerInboundNatRules: [
            {
              id: '${mastersLbID}/inboundNatRules/SSH-${vmNameMaster_var}${i}'
            }
          ]
        }
      }
    ]
  }
  dependsOn: [
    mastersLbName
    virtualNetworkName
    'Microsoft.Network/loadBalancers/${mastersLbName_var}/inboundNatRules/SSH-${vmNameMaster_var}${i}'
  ]
}]

resource mastersLbName 'Microsoft.Network/loadBalancers@2015-06-15' = {
  name: mastersLbName_var
  location: location
  properties: {
    frontendIPConfigurations: [
      {
        name: mastersLbIPConfigName
        properties: {
          publicIPAddress: {
            id: managementPublicIPAddrName.id
          }
        }
      }
    ]
    backendAddressPools: [
      {
        name: mastersLbBackendPoolName
      }
    ]
  }
}

resource mastersLbName_SSH_vmNameMaster 'Microsoft.Network/loadBalancers/inboundNatRules@2015-06-15' = [for i in range(0, masterCount): {
  name: '${mastersLbName_var}/SSH-${vmNameMaster_var}${i}'
  location: location
  properties: {
    frontendIPConfiguration: {
      id: mastersLbIPConfigID
    }
    protocol: 'Tcp'
    frontendPort: (i + 2200)
    backendPort: 22
    enableFloatingIP: false
  }
  dependsOn: [
    mastersLbName
  ]
}]

resource nodesLbName 'Microsoft.Network/loadBalancers@2015-06-15' = {
  name: nodesLbName_var
  location: location
  properties: {
    frontendIPConfigurations: [
      {
        name: 'LoadBalancerFrontEnd'
        properties: {
          publicIPAddress: {
            id: nodesPublicIPAddrName.id
          }
        }
      }
    ]
    backendAddressPools: [
      {
        name: nodesLbBackendPoolName
      }
    ]
  }
}

resource vmNameNode_nic 'Microsoft.Network/networkInterfaces@2015-06-15' = [for i in range(0, nodeCount): {
  name: '${vmNameNode_var}${i}-nic'
  location: location
  properties: {
    ipConfigurations: [
      {
        name: 'ipConfigNode'
        properties: {
          privateIPAllocationMethod: 'Dynamic'
          subnet: {
            id: subnetRefNodes
          }
          loadBalancerBackendAddressPools: [
            {
              id: '${nodesLbID}/backendAddressPools/${nodesLbBackendPoolName}'
            }
          ]
        }
      }
    ]
  }
  dependsOn: [
    nodesLbName
    virtualNetworkName
  ]
}]

resource vmNameMaster 'Microsoft.Compute/virtualMachines@2017-03-30' = [for i in range(0, masterCount): {
  name: concat(vmNameMaster_var, i)
  location: location
  properties: {
    availabilitySet: {
      id: availabilitySetMasters.id
    }
    hardwareProfile: {
      vmSize: vmSizeMaster
    }
    osProfile: {
      computerName: concat(vmNameMaster_var, i)
      adminUsername: adminUsername
      linuxConfiguration: {
        disablePasswordAuthentication: true
        ssh: {
          publicKeys: [
            {
              path: sshKeyPath
              keyData: sshPublicKey
            }
          ]
        }
      }
    }
    storageProfile: {
      imageReference: {
        publisher: osImagePublisher
        offer: osImageOffer
        sku: osImageSKU
        version: 'latest'
      }
      osDisk: {
        name: '${vmNameMaster_var}${i}_OSDisk'
        caching: 'ReadWrite'
        createOption: 'FromImage'
      }
    }
    networkProfile: {
      networkInterfaces: [
        {
          id: resourceId('Microsoft.Network/networkInterfaces', '${vmNameMaster_var}${i}-nic')
        }
      ]
    }
  }
  dependsOn: [
    newStorageAccountName
    'Microsoft.Network/networkInterfaces/${vmNameMaster_var}${i}-nic'
    availabilitySetMasters
  ]
}]

resource vmNameNode 'Microsoft.Compute/virtualMachines@2017-03-30' = [for i in range(0, nodeCount): {
  name: concat(vmNameNode_var, i)
  location: location
  properties: {
    availabilitySet: {
      id: availabilitySetNodes.id
    }
    hardwareProfile: {
      vmSize: vmSizeNode
    }
    osProfile: {
      computerName: concat(vmNameNode_var, i)
      adminUsername: adminUsername
      linuxConfiguration: {
        disablePasswordAuthentication: true
        ssh: {
          publicKeys: [
            {
              path: sshKeyPath
              keyData: sshPublicKey
            }
          ]
        }
      }
    }
    storageProfile: {
      imageReference: {
        publisher: osImagePublisher
        offer: osImageOffer
        sku: osImageSKU
        version: 'latest'
      }
      osDisk: {
        name: '${vmNameNode_var}${i}_OSDisk'
        caching: 'ReadWrite'
        createOption: 'FromImage'
      }
    }
    networkProfile: {
      networkInterfaces: [
        {
          id: resourceId('Microsoft.Network/networkInterfaces', '${vmNameNode_var}${i}-nic')
        }
      ]
    }
  }
  dependsOn: [
    newStorageAccountName
    'Microsoft.Network/networkInterfaces/${vmNameNode_var}${i}-nic'
  ]
}]

resource vmNameMaster_DockerExtension 'Microsoft.Compute/virtualMachines/extensions@2015-06-15' = [for i in range(0, masterCount): {
  name: '${vmNameMaster_var}${i}/DockerExtension'
  location: location
  properties: {
    publisher: 'Microsoft.Azure.Extensions'
    type: 'DockerExtension'
    typeHandlerVersion: '1.0'
    autoUpgradeMinorVersion: true
    settings: {
      compose: {
        consul: {
          image: 'progrium/consul'
          command: '-server -node master${i} ${consulServerArgs[i]}'
          ports: [
            '8500:8500'
            '8300:8300'
            '8301:8301'
            '8301:8301/udp'
            '8302:8302'
            '8302:8302/udp'
            '8400:8400'
          ]
          volumes: [
            '/data/consul:/data'
          ]
          restart: 'always'
        }
        swarm: {
          image: 'swarm'
          command: 'manage --replication --advertise ${reference('${vmNameMaster_var}${i}-nic').ipConfigurations[0].properties.privateIPAddress}:2375 --discovery-opt kv.path=docker/nodes consul://10.0.0.4:8500'
          ports: [
            '2375:2375'
          ]
          links: [
            'consul'
          ]
          volumes: [
            '/etc/docker:/etc/docker'
          ]
          restart: 'always'
        }
      }
    }
  }
  dependsOn: [
    'Microsoft.Compute/virtualMachines/${vmNameMaster_var}${i}'
  ]
}]

resource vmNameNode_DockerExtension 'Microsoft.Compute/virtualMachines/extensions@2015-06-15' = [for i in range(0, nodeCount): {
  name: '${vmNameNode_var}${i}/DockerExtension'
  location: location
  properties: {
    publisher: 'Microsoft.Azure.Extensions'
    type: 'DockerExtension'
    typeHandlerVersion: '1.0'
    autoUpgradeMinorVersion: true
    settings: {
      docker: {
        port: '2375'
        options: [
          '--cluster-store=consul://10.0.0.4:8500'
          '--cluster-advertise=eth0:2375'
        ]
      }
    }
  }
  dependsOn: [
    'Microsoft.Compute/virtualMachines/${vmNameNode_var}${i}'
  ]
}]

output sshTunnelCmd string = 'ssh -L 2375:swarm-master-0:2375 -N ${adminUsername}@${reference(managementPublicIPAddrName_var).dnsSettings.fqdn} -p 2200'
output dockerCmd string = 'docker -H tcp://localhost:2375 info'
output swarmNodesLoadBalancerAddress string = reference(nodesPublicIPAddrName_var).dnsSettings.fqdn
output sshMaster0 string = 'ssh ${adminUsername}@${reference(managementPublicIPAddrName_var).dnsSettings.fqdn} -A -p 2200'
output sshMaster1 string = 'ssh ${adminUsername}@${reference(managementPublicIPAddrName_var).dnsSettings.fqdn} -A -p 2201'
output sshMaster2 string = 'ssh ${adminUsername}@${reference(managementPublicIPAddrName_var).dnsSettings.fqdn} -A -p 2202'