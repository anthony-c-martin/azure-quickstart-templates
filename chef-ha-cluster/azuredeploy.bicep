param artifactsLocation string {
  metadata: {
    description: 'The base URI where artifacts required by this template are located. When the template is deployed using the accompanying scripts, a private location in the subscription will be used and this value will be automatically generated.'
  }
  default: 'https://raw.githubusercontent.com/Azure/azure-quickstart-templates/master/chef-ha-cluster/scripts'
}
param artifactsLocationSasToken string {
  metadata: {
    description: 'The sasToken required to access _artifactsLocation.  When the template is deployed using the accompanying scripts, a sasToken will be automatically generated.'
  }
  secure: true
  default: ''
}
param secretsLocation string {
  metadata: {
    description: 'URL of the Standard storage account blob container to receive shared secrets and config files. (ie. https://mystandardstorage.blob.core.windows.net/artifactsfolder )'
  }
}
param secretsLocationSasToken string {
  metadata: {
    description: 'Generated Shared Acccess Signature token to access _secretsLocation'
  }
  secure: true
}
param adminUsername string {
  minLength: 1
  metadata: {
    description: 'Administrator username on all VMs'
  }
  default: 'ubuntu'
}
param chefBEType string {
  allowed: [
    'Standard_LRS'
    'Standard_ZRS'
    'Standard_GRS'
    'Standard_RAGRS'
    'Premium_LRS'
  ]
  metadata: {
    description: 'Chef BE VM Storage Type must match chefBEvmSize'
  }
  default: 'Standard_LRS'
}
param chefBEvmSize string {
  allowed: [
    'Standard_DS1'
    'Standard_DS2'
    'Standard_DS3'
    'Standard_DS4'
    'Standard_DS1_v2'
    'Standard_DS2_v2'
    'Standard_DS3_v2'
    'Standard_DS4_v2'
    'Standard_D1'
    'Standard_D2'
    'Standard_D3'
    'Standard_D4'
    'Standard_D1_v2'
    'Standard_D2_v2'
    'Standard_D3_v2'
    'Standard_D4_v2'
    'Standard_D5_v2'
    'Standard_A0'
    'Standard_A1'
    'Standard_A2'
    'Standard_A3'
    'Standard_A4'
    'Standard_A5'
  ]
  minLength: 1
  metadata: {
    description: 'Chef BE VM Size must match chefBEType'
  }
  default: 'Standard_D3_v2'
}
param chefDNSName string {
  minLength: 3
  maxLength: 61
  metadata: {
    description: 'DNS name used for public IP addresses and as base for naming other resources. Must be globally unique and 3 to 61 characters long.'
  }
}
param chefFEType string {
  allowed: [
    'Standard_LRS'
    'Standard_ZRS'
    'Standard_GRS'
    'Standard_RAGRS'
    'Premium_LRS'
  ]
  metadata: {
    description: 'Chef FE VM Storage Type must match chefFEvmSize'
  }
  default: 'Standard_LRS'
}
param chefFEvmSize string {
  allowed: [
    'Standard_F1'
    'Standard_F2'
    'Standard_F4'
    'Standard_F16'
    'Standard_DS1'
    'Standard_DS2'
    'Standard_DS3'
    'Standard_DS4'
    'Standard_DS1_v2'
    'Standard_DS2_v2'
    'Standard_DS3_v2'
    'Standard_DS4_v2'
    'Standard_D1'
    'Standard_D2'
    'Standard_D3'
    'Standard_D4'
    'Standard_D1_v2'
    'Standard_D2_v2'
    'Standard_D3_v2'
    'Standard_D4_v2'
    'Standard_D5_v2'
    'Standard_A0'
    'Standard_A1'
    'Standard_A2'
    'Standard_A3'
    'Standard_A4'
    'Standard_A5'
  ]
  minLength: 1
  metadata: {
    description: 'Chef FE VM Size must match chefFEType'
  }
  default: 'Standard_F4'
}
param sshKeyData string {
  metadata: {
    description: 'SSH rsa public key file as a string.'
  }
}
param storageURL string {
  metadata: {
    description: 'URL for Azure Storage should need changing for regional only'
  }
  default: 'core.windows.net'
}
param ubuntuVersion string {
  metadata: {
    description: 'Ubuntu version'
  }
  default: '14.04.5-LTS'
}

var addressPrefix = '10.0.0.0/16'
var bePoolName = 'chefpool'
var BEStorageAccountContainerName = 'vhds'
var ChefBEAvailName = 'BEAvail'
var chefbeName = 'chefbe${uniqueString(resourceGroup().id)}'
var ChefFEAvailName = 'FEAvail'
var cheffeName = 'cheffe${uniqueString(resourceGroup().id)}'
var FE0setupscriptScriptFileName = 'FE0Setup.sh'
var FEsetupscriptScriptFileName = 'FESetup.sh'
var FEStorageAccountContainerName = 'vhds'
var FollowerSetupScriptFileName = 'BEFollowerSetup.sh'
var frontEndIPConfigID = '${lbID}/frontendIPConfigurations/loadBalancerFrontEnd'
var imageReference = osType
var lbID = loadBalancerName_resource.id
var lbProbeID = '${lbID}/probes/https'
var LeaderSetupScriptFileName = 'BELeaderSetup.sh'
var loadBalancerName = 'cheffelb'
var location = resourceGroup().location
var osType = {
  publisher: 'Canonical'
  offer: 'UbuntuServer'
  sku: ubuntuVersion
  version: 'latest'
}
var publicIPAddressID = publicIPAddressName_resource.id
var publicIPAddressName = 'chefpublicip'
var sshKeyPath = '/home/${adminUsername}/.ssh/authorized_keys'
var subnetName = 'chefsubnet'
var subnetPrefix = '10.0.0.0/24'
var subnetRef = resourceId('Microsoft.Network/virtualNetworks/subnets', virtualNetworkName, subnetName)
var virtualNetworkName = 'chefvnet'
var tagvalues = {
  provider: toUpper('33194f91-eb5f-4110-827a-e95f640a9e46')
}

resource virtualNetworkName_resource 'Microsoft.Network/virtualNetworks@2015-06-15' = {
  name: virtualNetworkName
  location: location
  tags: {
    displayName: 'ChefVirtualNetwork'
    provider: tagvalues.provider
  }
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

resource chefbeName_resource 'Microsoft.Storage/storageAccounts@2015-06-15' = {
  name: chefbeName
  location: resourceGroup().location
  tags: {
    displayName: 'BEStorage'
    provider: tagvalues.provider
  }
  properties: {
    accountType: chefBEType
  }
  dependsOn: []
}

resource cheffeName_resource 'Microsoft.Storage/storageAccounts@2015-06-15' = {
  name: cheffeName
  location: resourceGroup().location
  tags: {
    displayName: 'FEStorage'
    provider: tagvalues.provider
  }
  properties: {
    accountType: chefFEType
  }
  dependsOn: []
}

resource publicIPAddressName_resource 'Microsoft.Network/publicIPAddresses@2015-06-15' = {
  name: publicIPAddressName
  location: location
  tags: {
    displayName: 'FEPublicIP'
    provider: tagvalues.provider
  }
  properties: {
    publicIPAllocationMethod: 'Dynamic'
    dnsSettings: {
      domainNameLabel: toLower(chefDNSName)
    }
  }
}

resource loadBalancerName_resource 'Microsoft.Network/loadBalancers@2015-06-15' = {
  name: loadBalancerName
  location: location
  tags: {
    displayName: 'FELoadBalancer'
    provider: tagvalues.provider
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
        name: bePoolName
      }
    ]
    inboundNatRules: [
      {
        name: 'ssh-fe0'
        properties: {
          frontendIPConfiguration: {
            id: frontEndIPConfigID
          }
          protocol: 'Tcp'
          frontendPort: 50000
          backendPort: 22
          enableFloatingIP: false
        }
      }
      {
        name: 'ssh-fe1'
        properties: {
          frontendIPConfiguration: {
            id: frontEndIPConfigID
          }
          protocol: 'Tcp'
          frontendPort: 50001
          backendPort: 22
          enableFloatingIP: false
        }
      }
      {
        name: 'ssh-fe2'
        properties: {
          frontendIPConfiguration: {
            id: frontEndIPConfigID
          }
          protocol: 'Tcp'
          frontendPort: 50002
          backendPort: 22
          enableFloatingIP: false
        }
      }
    ]
    probes: [
      {
        name: 'https'
        properties: {
          protocol: 'Tcp'
          port: 443
        }
      }
    ]
    loadBalancingRules: [
      {
        name: 'https'
        properties: {
          protocol: 'Tcp'
          backendAddressPool: {
            id: '/subscriptions/${subscription().subscriptionId}/resourceGroups/${resourceGroup().name}/providers/Microsoft.Network/loadBalancers/${loadBalancerName}/backendAddressPools/${bePoolName}'
          }
          backendPort: 443
          frontendIPConfiguration: {
            id: frontEndIPConfigID
          }
          frontendPort: 443
          probe: {
            id: lbProbeID
          }
          loadDistribution: 'SourceIPProtocol'
        }
      }
      {
        name: 'http'
        properties: {
          protocol: 'Tcp'
          backendAddressPool: {
            id: '/subscriptions/${subscription().subscriptionId}/resourceGroups/${resourceGroup().name}/providers/Microsoft.Network/loadBalancers/${loadBalancerName}/backendAddressPools/${bePoolName}'
          }
          backendPort: 80
          frontendIPConfiguration: {
            id: frontEndIPConfigID
          }
          frontendPort: 80
          probe: {
            id: lbProbeID
          }
          loadDistribution: 'SourceIPProtocol'
        }
      }
    ]
  }
  dependsOn: [
    publicIPAddressName_resource
  ]
}

resource ChefBEAvailName_resource 'Microsoft.Compute/availabilitySets@2017-12-01' = {
  name: ChefBEAvailName
  location: resourceGroup().location
  tags: {
    displayName: 'BEAvailSet'
    provider: tagvalues.provider
  }
  sku: {
    name: 'Aligned'
  }
  properties: {
    platformUpdateDomainCount: 3
    platformFaultDomainCount: 3
  }
  dependsOn: []
}

resource ChefFEAvailName_resource 'Microsoft.Compute/availabilitySets@2017-12-01' = {
  name: ChefFEAvailName
  location: resourceGroup().location
  tags: {
    displayName: 'FEAvailSet'
    provider: tagvalues.provider
  }
  sku: {
    name: 'Aligned'
  }
  properties: {
    platformUpdateDomainCount: 3
    platformFaultDomainCount: 3
  }
  dependsOn: []
}

resource BE0Nic 'Microsoft.Network/networkInterfaces@2015-06-15' = {
  name: 'BE0Nic'
  location: location
  tags: {
    displayName: 'BE0Nic'
    provider: tagvalues.provider
  }
  properties: {
    ipConfigurations: [
      {
        name: 'ipconfig1'
        properties: {
          privateIPAllocationMethod: 'Static'
          subnet: {
            id: subnetRef
          }
          privateIPAddress: '10.0.0.10'
        }
      }
    ]
  }
  dependsOn: [
    virtualNetworkName_resource
  ]
}

resource BE0 'Microsoft.Compute/virtualMachines@2017-03-30' = {
  name: 'BE0'
  location: location
  tags: {
    displayName: 'BE0'
    provider: tagvalues.provider
  }
  properties: {
    hardwareProfile: {
      vmSize: chefBEvmSize
    }
    osProfile: {
      computerName: 'be0'
      adminUsername: adminUsername
      linuxConfiguration: {
        disablePasswordAuthentication: true
        ssh: {
          publicKeys: [
            {
              keyData: sshKeyData
              path: sshKeyPath
            }
          ]
        }
      }
    }
    storageProfile: {
      imageReference: imageReference
      osDisk: {
        name: 'BE0_OSDisk'
        caching: 'ReadWrite'
        createOption: 'FromImage'
      }
    }
    networkProfile: {
      networkInterfaces: [
        {
          id: BE0Nic.id
        }
      ]
    }
    availabilitySet: {
      id: ChefBEAvailName_resource.id
    }
  }
  dependsOn: [
    chefbeName_resource
    BE0Nic
    ChefBEAvailName_resource
  ]
}

resource BE0_BE0Setup 'Microsoft.Compute/virtualMachines/extensions@2015-06-15' = {
  name: 'BE0/BE0Setup'
  location: location
  tags: {
    displayName: 'BE0Setup'
  }
  properties: {
    publisher: 'Microsoft.Azure.Extensions'
    type: 'CustomScript'
    typeHandlerVersion: '2.0'
    autoUpgradeMinorVersion: true
    settings: {
      fileUris: [
        '${artifactsLocation}/${LeaderSetupScriptFileName}${artifactsLocationSasToken}'
      ]
    }
    protectedSettings: {
      commandToExecute: 'sh ${LeaderSetupScriptFileName} "${secretsLocation}" "${secretsLocationSasToken}"'
    }
  }
  dependsOn: [
    BE0
  ]
}

resource BE1Nic 'Microsoft.Network/networkInterfaces@2015-06-15' = {
  name: 'BE1Nic'
  location: location
  tags: {
    displayName: 'BE1Nic'
    provider: tagvalues.provider
  }
  properties: {
    ipConfigurations: [
      {
        name: 'ipconfig1'
        properties: {
          privateIPAllocationMethod: 'Static'
          subnet: {
            id: subnetRef
          }
          privateIPAddress: '10.0.0.11'
        }
      }
    ]
  }
  dependsOn: [
    virtualNetworkName_resource
  ]
}

resource BE1 'Microsoft.Compute/virtualMachines@2017-03-30' = {
  name: 'BE1'
  location: location
  tags: {
    displayName: 'BE1'
    provider: tagvalues.provider
  }
  properties: {
    hardwareProfile: {
      vmSize: chefBEvmSize
    }
    osProfile: {
      computerName: 'be1'
      adminUsername: adminUsername
      linuxConfiguration: {
        disablePasswordAuthentication: true
        ssh: {
          publicKeys: [
            {
              keyData: sshKeyData
              path: sshKeyPath
            }
          ]
        }
      }
    }
    storageProfile: {
      imageReference: imageReference
      osDisk: {
        name: 'BE1_OSDisk'
        caching: 'ReadWrite'
        createOption: 'FromImage'
      }
    }
    networkProfile: {
      networkInterfaces: [
        {
          id: BE1Nic.id
        }
      ]
    }
    availabilitySet: {
      id: ChefBEAvailName_resource.id
    }
  }
  dependsOn: [
    chefbeName_resource
    BE1Nic
    ChefBEAvailName_resource
  ]
}

resource BE1_BE1Setup 'Microsoft.Compute/virtualMachines/extensions@2015-06-15' = {
  name: 'BE1/BE1Setup'
  location: location
  tags: {
    displayName: 'BE1Setup'
  }
  properties: {
    publisher: 'Microsoft.Azure.Extensions'
    type: 'CustomScript'
    typeHandlerVersion: '2.0'
    autoUpgradeMinorVersion: true
    settings: {
      fileUris: [
        '${artifactsLocation}/${FollowerSetupScriptFileName}${artifactsLocationSasToken}'
      ]
    }
    protectedSettings: {
      commandToExecute: 'sh ${FollowerSetupScriptFileName} "${secretsLocation}" "${secretsLocationSasToken}"'
    }
  }
  dependsOn: [
    BE1
    BE0_BE0Setup
  ]
}

resource BE2Nic 'Microsoft.Network/networkInterfaces@2015-06-15' = {
  name: 'BE2Nic'
  location: location
  tags: {
    displayName: 'BE2Nic'
    provider: tagvalues.provider
  }
  properties: {
    ipConfigurations: [
      {
        name: 'ipconfig1'
        properties: {
          privateIPAllocationMethod: 'Static'
          subnet: {
            id: subnetRef
          }
          privateIPAddress: '10.0.0.12'
        }
      }
    ]
  }
  dependsOn: [
    virtualNetworkName_resource
  ]
}

resource BE2 'Microsoft.Compute/virtualMachines@2017-03-30' = {
  name: 'BE2'
  location: location
  tags: {
    displayName: 'BE2'
    provider: tagvalues.provider
  }
  properties: {
    hardwareProfile: {
      vmSize: chefBEvmSize
    }
    osProfile: {
      computerName: 'be2'
      adminUsername: adminUsername
      linuxConfiguration: {
        disablePasswordAuthentication: true
        ssh: {
          publicKeys: [
            {
              keyData: sshKeyData
              path: sshKeyPath
            }
          ]
        }
      }
    }
    storageProfile: {
      imageReference: imageReference
      osDisk: {
        name: 'BE2_OSDisk'
        caching: 'ReadWrite'
        createOption: 'FromImage'
      }
    }
    networkProfile: {
      networkInterfaces: [
        {
          id: BE2Nic.id
        }
      ]
    }
    availabilitySet: {
      id: ChefBEAvailName_resource.id
    }
  }
  dependsOn: [
    chefbeName_resource
    BE2Nic
    ChefBEAvailName_resource
  ]
}

resource BE2_BE2Setup 'Microsoft.Compute/virtualMachines/extensions@2015-06-15' = {
  name: 'BE2/BE2Setup'
  location: location
  tags: {
    displayName: 'BE2Setup'
  }
  properties: {
    publisher: 'Microsoft.Azure.Extensions'
    type: 'CustomScript'
    typeHandlerVersion: '2.0'
    autoUpgradeMinorVersion: true
    settings: {
      fileUris: [
        '${artifactsLocation}/${FollowerSetupScriptFileName}${artifactsLocationSasToken}'
      ]
    }
    protectedSettings: {
      commandToExecute: 'sh ${FollowerSetupScriptFileName} "${secretsLocation}" "${secretsLocationSasToken}"'
    }
  }
  dependsOn: [
    BE2
    BE0_BE0Setup
    BE1_BE1Setup
  ]
}

resource FE0Nic 'Microsoft.Network/networkInterfaces@2015-06-15' = {
  name: 'FE0Nic'
  location: location
  tags: {
    displayName: 'FE0Nic'
    provider: tagvalues.provider
  }
  properties: {
    ipConfigurations: [
      {
        name: 'ipconfig1'
        properties: {
          privateIPAllocationMethod: 'Static'
          subnet: {
            id: subnetRef
          }
          privateIPAddress: '10.0.0.50'
          loadBalancerBackendAddressPools: [
            {
              id: '/subscriptions/${subscription().subscriptionId}/resourceGroups/${resourceGroup().name}/providers/Microsoft.Network/loadBalancers/${loadBalancerName}/backendAddressPools/${bePoolName}'
            }
          ]
          loadBalancerInboundNatRules: [
            {
              id: '/subscriptions/${subscription().subscriptionId}/resourceGroups/${resourceGroup().name}/providers/Microsoft.Network/loadBalancers/${loadBalancerName}/inboundNatRules/ssh-fe0'
            }
          ]
        }
      }
    ]
  }
  dependsOn: [
    virtualNetworkName_resource
    loadBalancerName_resource
  ]
}

resource FE0 'Microsoft.Compute/virtualMachines@2017-03-30' = {
  name: 'FE0'
  location: location
  tags: {
    displayName: 'FE0'
    provider: tagvalues.provider
  }
  properties: {
    hardwareProfile: {
      vmSize: chefFEvmSize
    }
    osProfile: {
      computerName: 'fe0'
      adminUsername: adminUsername
      linuxConfiguration: {
        disablePasswordAuthentication: true
        ssh: {
          publicKeys: [
            {
              keyData: sshKeyData
              path: sshKeyPath
            }
          ]
        }
      }
    }
    storageProfile: {
      imageReference: imageReference
      osDisk: {
        name: 'FE0_OSDisk'
        caching: 'ReadWrite'
        createOption: 'FromImage'
      }
    }
    networkProfile: {
      networkInterfaces: [
        {
          id: FE0Nic.id
        }
      ]
    }
    availabilitySet: {
      id: ChefFEAvailName_resource.id
    }
  }
  dependsOn: [
    cheffeName_resource
    FE0Nic
    ChefFEAvailName_resource
  ]
}

resource FE0_FE0Setup 'Microsoft.Compute/virtualMachines/extensions@2015-06-15' = {
  name: 'FE0/FE0Setup'
  location: location
  tags: {
    displayName: 'FE0Setup'
  }
  properties: {
    publisher: 'Microsoft.Azure.Extensions'
    type: 'CustomScript'
    typeHandlerVersion: '2.0'
    autoUpgradeMinorVersion: true
    settings: {
      fileUris: [
        '${artifactsLocation}/${FE0setupscriptScriptFileName}${artifactsLocationSasToken}'
      ]
    }
    protectedSettings: {
      commandToExecute: 'sh ${FE0setupscriptScriptFileName} "${secretsLocation}" "${secretsLocationSasToken}"'
    }
  }
  dependsOn: [
    FE0
    BE0_BE0Setup
    BE1_BE1Setup
    BE2_BE2Setup
  ]
}

resource FE1Nic 'Microsoft.Network/networkInterfaces@2015-06-15' = {
  name: 'FE1Nic'
  location: location
  tags: {
    displayName: 'FE1Nic'
    provider: tagvalues.provider
  }
  properties: {
    ipConfigurations: [
      {
        name: 'ipconfig1'
        properties: {
          privateIPAllocationMethod: 'Static'
          subnet: {
            id: subnetRef
          }
          privateIPAddress: '10.0.0.51'
          loadBalancerBackendAddressPools: [
            {
              id: '/subscriptions/${subscription().subscriptionId}/resourceGroups/${resourceGroup().name}/providers/Microsoft.Network/loadBalancers/${loadBalancerName}/backendAddressPools/${bePoolName}'
            }
          ]
          loadBalancerInboundNatRules: [
            {
              id: '/subscriptions/${subscription().subscriptionId}/resourceGroups/${resourceGroup().name}/providers/Microsoft.Network/loadBalancers/${loadBalancerName}/inboundNatRules/ssh-fe1'
            }
          ]
        }
      }
    ]
  }
  dependsOn: [
    virtualNetworkName_resource
    loadBalancerName_resource
  ]
}

resource FE1 'Microsoft.Compute/virtualMachines@2017-03-30' = {
  name: 'FE1'
  location: location
  tags: {
    displayName: 'FE1'
    provider: tagvalues.provider
  }
  properties: {
    hardwareProfile: {
      vmSize: chefFEvmSize
    }
    osProfile: {
      computerName: 'fe1'
      adminUsername: adminUsername
      linuxConfiguration: {
        disablePasswordAuthentication: true
        ssh: {
          publicKeys: [
            {
              keyData: sshKeyData
              path: sshKeyPath
            }
          ]
        }
      }
    }
    storageProfile: {
      imageReference: imageReference
      osDisk: {
        name: 'FE1_OSDisk'
        caching: 'ReadWrite'
        createOption: 'FromImage'
      }
    }
    networkProfile: {
      networkInterfaces: [
        {
          id: FE1Nic.id
        }
      ]
    }
    availabilitySet: {
      id: ChefFEAvailName_resource.id
    }
  }
  dependsOn: [
    cheffeName_resource
    FE1Nic
    ChefFEAvailName_resource
  ]
}

resource FE1_FE1Setup 'Microsoft.Compute/virtualMachines/extensions@2015-06-15' = {
  name: 'FE1/FE1Setup'
  location: location
  tags: {
    displayName: 'FE1Setup'
  }
  properties: {
    publisher: 'Microsoft.Azure.Extensions'
    type: 'CustomScript'
    typeHandlerVersion: '2.0'
    autoUpgradeMinorVersion: true
    settings: {
      fileUris: [
        '${artifactsLocation}/${FEsetupscriptScriptFileName}${artifactsLocationSasToken}'
      ]
    }
    protectedSettings: {
      commandToExecute: 'sh ${FEsetupscriptScriptFileName} "${secretsLocation}" "${secretsLocationSasToken}"'
    }
  }
  dependsOn: [
    FE1
    FE0_FE0Setup
  ]
}

resource FE2Nic 'Microsoft.Network/networkInterfaces@2015-06-15' = {
  name: 'FE2Nic'
  location: location
  tags: {
    displayName: 'FE2Nic'
    provider: tagvalues.provider
  }
  properties: {
    ipConfigurations: [
      {
        name: 'ipconfig1'
        properties: {
          privateIPAllocationMethod: 'Static'
          subnet: {
            id: subnetRef
          }
          privateIPAddress: '10.0.0.52'
          loadBalancerBackendAddressPools: [
            {
              id: '/subscriptions/${subscription().subscriptionId}/resourceGroups/${resourceGroup().name}/providers/Microsoft.Network/loadBalancers/${loadBalancerName}/backendAddressPools/${bePoolName}'
            }
          ]
          loadBalancerInboundNatRules: [
            {
              id: '/subscriptions/${subscription().subscriptionId}/resourceGroups/${resourceGroup().name}/providers/Microsoft.Network/loadBalancers/${loadBalancerName}/inboundNatRules/ssh-fe2'
            }
          ]
        }
      }
    ]
  }
  dependsOn: [
    virtualNetworkName_resource
    loadBalancerName_resource
  ]
}

resource FE2 'Microsoft.Compute/virtualMachines@2017-03-30' = {
  name: 'FE2'
  location: location
  tags: {
    displayName: 'FE2'
    provider: tagvalues.provider
  }
  properties: {
    hardwareProfile: {
      vmSize: chefFEvmSize
    }
    osProfile: {
      computerName: 'fe2'
      adminUsername: adminUsername
      linuxConfiguration: {
        disablePasswordAuthentication: true
        ssh: {
          publicKeys: [
            {
              keyData: sshKeyData
              path: sshKeyPath
            }
          ]
        }
      }
    }
    storageProfile: {
      imageReference: imageReference
      osDisk: {
        name: 'FE2_OSDisk'
        caching: 'ReadWrite'
        createOption: 'FromImage'
      }
    }
    networkProfile: {
      networkInterfaces: [
        {
          id: FE2Nic.id
        }
      ]
    }
    availabilitySet: {
      id: ChefFEAvailName_resource.id
    }
  }
  dependsOn: [
    cheffeName_resource
    FE2Nic
    ChefFEAvailName_resource
  ]
}

resource FE2_FE2Setup 'Microsoft.Compute/virtualMachines/extensions@2015-06-15' = {
  name: 'FE2/FE2Setup'
  location: location
  tags: {
    displayName: 'FE2Setup'
  }
  properties: {
    publisher: 'Microsoft.Azure.Extensions'
    type: 'CustomScript'
    typeHandlerVersion: '2.0'
    autoUpgradeMinorVersion: true
    settings: {
      fileUris: [
        '${artifactsLocation}/${FEsetupscriptScriptFileName}${artifactsLocationSasToken}'
      ]
    }
    protectedSettings: {
      commandToExecute: 'sh ${FEsetupscriptScriptFileName} "${secretsLocation}" "${secretsLocationSasToken}"'
    }
  }
  dependsOn: [
    FE2
    FE0_FE0Setup
  ]
}