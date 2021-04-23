@description('Name of the of the storage account for VM OS Disk')
param newStorageAccountName string

@description('Domain name associated with the load balancer public IP')
param publicDomainName string

@description('Instance size for the VMs')
param vmSize string = 'Standard_A2_v2'

@description('Username to login to the VMs')
param adminUsername string

@description('Public key for SSH authentication')
param sshKeyData string

@description('Base64-encoded cloud-config.yaml file to deploy and start Fleet')
param customData string

@description('Number of member nodes')
param numberOfNodes int = '3'

@description('Size in GB of the Docker volume.')
param dockerVolumeSize int = '100'

@description('Version of CoreOS to deploy.')
param coreosVersion string

var addressPrefix = '10.0.0.0/16'
var subnet1Name = 'Subnet-1'
var subnet1Prefix = '10.0.0.0/24'
var publicIPAddressType = 'Dynamic'
var storageAccountType = 'Standard_LRS'
var imagePublisher = 'CoreOS'
var imageOffer = 'CoreOS'
var imageSKU = 'Stable'
var vmNamePrefix_var = 'deisNode'
var virtualNetworkName_var = 'deisvNet'
var availabilitySetName_var = 'deisAvailabilitySet'
var loadBalancerName_var = 'loadBalancer'
var loadBalancerAPIRuleName = 'loadBalancerAPIRule'
var loadBalancerBuilderRuleName = 'loadBalancerBuildRule'
var loadBalancerPublicIPName_var = 'loadBalanerIP'
var loadBalancerIPConfigName = 'loadBalancerIPConfig'
var lbBackendAddressPoolName = 'lbBackendAddressPool'
var apiProbeName = 'apiProbe'
var builderProbeName = 'builderProbe'
var sshKeyPath = '/home/${adminUsername}/.ssh/authorized_keys'
var vnetID = virtualNetworkName.id
var subnet1Ref = '${vnetID}/subnets/${subnet1Name}'
var lbID = loadBalancerName.id
var lbAPIRuleID = '${lbID}/loadBalancingRules/${loadBalancerAPIRuleName}'
var lbBuilderRuleID = '${lbID}/loadBalancingRules/${loadBalancerBuilderRuleName}'
var lbIPConfig = '${lbID}/frontendIPConfigurations/${loadBalancerIPConfigName}'
var apiProbeID = '${lbID}/probes/${apiProbeName}'
var builderProbeID = '${lbID}/probes/${builderProbeName}'
var lbPoolID = '${lbID}/backendAddressPools/${lbBackendAddressPoolName}'
var networkSecurityGroupName_var = '${subnet1Name}-nsg'

resource availabilitySetName 'Microsoft.Compute/availabilitySets@2017-12-01' = {
  name: availabilitySetName_var
  location: resourceGroup().location
  sku: {
    name: 'Aligned'
  }
  properties: {
    platformFaultDomainCount: 2
    platformUpdateDomainCount: 5
  }
}

resource newStorageAccountName_resource 'Microsoft.Storage/storageAccounts@2015-05-01-preview' = {
  name: newStorageAccountName
  location: resourceGroup().location
  properties: {
    accountType: storageAccountType
  }
}

resource loadBalancerPublicIPName 'Microsoft.Network/publicIPAddresses@2015-05-01-preview' = {
  name: loadBalancerPublicIPName_var
  location: resourceGroup().location
  properties: {
    publicIPAllocationMethod: 'Dynamic'
    dnsSettings: {
      domainNameLabel: publicDomainName
    }
  }
}

resource loadBalancerName 'Microsoft.Network/loadBalancers@2015-05-01-preview' = {
  name: loadBalancerName_var
  location: resourceGroup().location
  properties: {
    frontendIPConfigurations: [
      {
        name: loadBalancerIPConfigName
        properties: {
          publicIPAddress: {
            id: loadBalancerPublicIPName.id
          }
        }
      }
    ]
    backendAddressPools: [
      {
        name: lbBackendAddressPoolName
        properties: {
          loadBalancingRules: [
            {
              id: lbBuilderRuleID
            }
          ]
        }
      }
    ]
    loadBalancingRules: [
      {
        name: loadBalancerBuilderRuleName
        dependsOn: [
          lbIPConfig
        ]
        properties: {
          frontendIPConfiguration: {
            id: lbIPConfig
          }
          backendAddressPool: {
            id: lbPoolID
          }
          protocol: 'Tcp'
          frontendPort: '2222'
          backendPort: '2222'
          enableFloatingIP: false
          idleTimeoutInMinutes: '10'
        }
      }
    ]
    inboundNatRules: [
      {
        name: 'SSH-VM0'
        properties: {
          frontendIPConfiguration: {
            id: lbIPConfig
          }
          protocol: 'Tcp'
          frontendPort: 2223
          backendPort: 22
          enableFloatingIP: false
        }
      }
      {
        name: 'SSH-VM1'
        properties: {
          frontendIPConfiguration: {
            id: lbIPConfig
          }
          protocol: 'Tcp'
          frontendPort: 2224
          backendPort: 22
          enableFloatingIP: false
        }
      }
      {
        name: 'SSH-VM2'
        properties: {
          frontendIPConfiguration: {
            id: lbIPConfig
          }
          protocol: 'Tcp'
          frontendPort: 2225
          backendPort: 22
          enableFloatingIP: false
        }
      }
    ]
    probes: [
      {
        name: apiProbeName
        properties: {
          protocol: 'Http'
          port: '80'
          intervalInSeconds: '5'
          numberOfProbes: '2'
          requestPath: '/health-check'
        }
      }
    ]
  }
}

resource networkSecurityGroupName 'Microsoft.Network/networkSecurityGroups@2019-08-01' = {
  name: networkSecurityGroupName_var
  location: resourceGroup().location
  properties: {}
}

resource virtualNetworkName 'Microsoft.Network/virtualNetworks@2015-05-01-preview' = {
  name: virtualNetworkName_var
  location: resourceGroup().location
  properties: {
    addressSpace: {
      addressPrefixes: [
        addressPrefix
      ]
    }
    subnets: [
      {
        name: subnet1Name
        properties: {
          addressPrefix: subnet1Prefix
          networkSecurityGroup: {
            id: networkSecurityGroupName.id
          }
        }
      }
    ]
  }
}

resource nic 'Microsoft.Network/networkInterfaces@2015-05-01-preview' = [for i in range(0, numberOfNodes): {
  name: 'nic${i}'
  location: resourceGroup().location
  properties: {
    ipConfigurations: [
      {
        name: 'ipconfig1'
        properties: {
          privateIPAllocationMethod: 'Dynamic'
          subnet: {
            id: subnet1Ref
          }
          loadBalancerBackendAddressPools: [
            {
              id: lbPoolID
            }
          ]
          loadBalancerInboundNatRules: [
            {
              id: '${lbID}/inboundNatRules/SSH-VM${i}'
            }
          ]
        }
      }
    ]
  }
  dependsOn: [
    virtualNetworkName
    lbID
  ]
}]

resource vmNamePrefix 'Microsoft.Compute/virtualMachines@2017-03-30' = [for i in range(0, numberOfNodes): {
  name: concat(vmNamePrefix_var, i)
  location: resourceGroup().location
  properties: {
    availabilitySet: {
      id: availabilitySetName.id
    }
    hardwareProfile: {
      vmSize: vmSize
    }
    osProfile: {
      computerName: concat(vmNamePrefix_var, i)
      adminUsername: adminUsername
      customData: customData
      linuxConfiguration: {
        disablePasswordAuthentication: true
        ssh: {
          publicKeys: [
            {
              path: sshKeyPath
              keyData: sshKeyData
            }
          ]
        }
      }
    }
    storageProfile: {
      imageReference: {
        publisher: imagePublisher
        offer: imageOffer
        sku: imageSKU
        version: coreosVersion
      }
      dataDisks: [
        {
          name: '${vmNamePrefix_var}${i}_dockerdisk'
          diskSizeGB: dockerVolumeSize
          lun: 0
          createOption: 'Empty'
        }
      ]
      osDisk: {
        name: '${vmNamePrefix_var}${i}_OSDisk'
        caching: 'ReadWrite'
        createOption: 'FromImage'
      }
    }
    networkProfile: {
      networkInterfaces: [
        {
          id: resourceId('Microsoft.Network/networkInterfaces', 'nic${i}')
        }
      ]
    }
  }
  dependsOn: [
    newStorageAccountName_resource
    'Microsoft.Network/networkInterfaces/nic${i}'
    availabilitySetName
  ]
}]