@description('User name for the Virtual Machine. Used for both SSH and RDP access.')
param adminUsername string

@description('Password for the Virtual Machine. Used for both SSH and RDP access.')
@secure()
param adminPassword string

@description('Password for the Puppet Enterprise Console.')
@secure()
param consolePassword string

@minValue(1)
@maxValue(100)
@description('Number of Windows Puppet Agents to deploy. Assumes Windows Server 2012 R2.')
param windowsAgentCount int = 1

@minValue(1)
@maxValue(100)
@description('Number of Linux Puppet Agents to deploy. Assumes Ubuntu 14.04-LTS.')
param linuxAgentCount int = 1

@description('Size of Puppet agent VMs')
param vmSize string = 'Standard_D1_v2'

@description('The base URI where artifacts required by this template are located. When the template is deployed using the accompanying scripts, a private location in the subscription will be used and this value will be automatically generated.')
param artifactsLocation string = 'https://raw.githubusercontent.com/Azure/azure-quickstart-templates/master/puppet-enterprise-cluster/'

@description('The sasToken required to access _artifactsLocation.  When the template is deployed using the accompanying scripts, a sasToken will be automatically generated.')
@secure()
param artifactsLocationSasToken string = ''

@description('Location for all resources.')
param location string = resourceGroup().location

var puppetAgentCount = (windowsAgentCount + linuxAgentCount)
var newStorageAccountName_var = 'str${uniqueString(resourceGroup().id, deployment().name)}'
var dnsNameForPublicIP = 'dns${uniqueString(resourceGroup().id, deployment().name)}'
var imagePublisher = 'Puppet'
var imageOffer = 'Puppet-Enterprise'
var imageSku = '2016-1'
var OSDiskName = 'puppetMasterDisk'
var nicName_var = 'puppetmasterNic'
var addressPrefix = '10.0.0.0/16'
var subnetName = 'Subnet'
var subnetPrefix = '10.0.0.0/24'
var storageAccountType = 'Standard_LRS'
var publicIPAddressName_var = 'myPublicIP'
var publicIPAddressType = 'Dynamic'
var vmStorageAccountContainerName = 'vhds'
var puppetMasterVmName_var = 'puppetmaster'
var virtualNetworkName_var = 'vnet1'
var subnetRef = resourceId('Microsoft.Network/virtualNetworks/subnets', virtualNetworkName_var, subnetName)

resource newStorageAccountName 'Microsoft.Storage/storageAccounts@2016-01-01' = {
  name: newStorageAccountName_var
  location: location
  sku: {
    name: storageAccountType
  }
  kind: 'Storage'
  properties: {}
}

resource publicIPAddressName 'Microsoft.Network/publicIPAddresses@2016-03-30' = {
  name: publicIPAddressName_var
  location: location
  properties: {
    publicIPAllocationMethod: publicIPAddressType
    dnsSettings: {
      domainNameLabel: dnsNameForPublicIP
    }
  }
}

resource peagentip 'Microsoft.Network/publicIPAddresses@2016-03-30' = [for i in range(0, puppetAgentCount): {
  name: 'peagentip${i}'
  location: location
  properties: {
    publicIPAllocationMethod: 'Dynamic'
    dnsSettings: {
      domainNameLabel: concat(dnsNameForPublicIP, i)
    }
  }
}]

resource virtualNetworkName 'Microsoft.Network/virtualNetworks@2016-03-30' = {
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
          networkSecurityGroup: {
            id: puppetNetworkSecurityGroup.id
          }
        }
      }
    ]
  }
}

resource puppetNetworkSecurityGroup 'Microsoft.Network/networkSecurityGroups@2016-03-30' = {
  name: 'puppetNetworkSecurityGroup'
  location: location
  properties: {
    securityRules: [
      {
        name: 'puppet'
        properties: {
          protocol: 'Tcp'
          sourcePortRange: '*'
          destinationPortRange: '8140'
          sourceAddressPrefix: '*'
          destinationAddressPrefix: '*'
          access: 'Allow'
          priority: 100
          direction: 'Inbound'
        }
      }
      {
        name: 'rdp'
        properties: {
          description: 'Allow RDP'
          protocol: 'Tcp'
          sourcePortRange: '*'
          destinationPortRange: '3389'
          sourceAddressPrefix: '*'
          destinationAddressPrefix: '*'
          access: 'Allow'
          priority: 101
          direction: 'Inbound'
        }
      }
      {
        name: 'ssh'
        properties: {
          description: 'Allow RDP'
          protocol: 'Tcp'
          sourcePortRange: '*'
          destinationPortRange: '22'
          sourceAddressPrefix: '*'
          destinationAddressPrefix: '*'
          access: 'Allow'
          priority: 201
          direction: 'Inbound'
        }
      }
      {
        name: 'MCollective'
        properties: {
          description: 'MCollective'
          protocol: 'Tcp'
          sourcePortRange: '*'
          destinationPortRange: '61613'
          sourceAddressPrefix: '*'
          destinationAddressPrefix: '*'
          access: 'Allow'
          priority: 102
          direction: 'Inbound'
        }
      }
      {
        name: 'https'
        properties: {
          description: 'MCollective'
          protocol: 'Tcp'
          sourcePortRange: '*'
          destinationPortRange: '443'
          sourceAddressPrefix: '*'
          destinationAddressPrefix: '*'
          access: 'Allow'
          priority: 103
          direction: 'Inbound'
        }
      }
      {
        name: 'orchestrator'
        properties: {
          protocol: 'Tcp'
          sourcePortRange: '*'
          destinationPortRange: '8142'
          sourceAddressPrefix: '*'
          destinationAddressPrefix: '*'
          access: 'Allow'
          priority: 104
          direction: 'Inbound'
        }
      }
    ]
  }
}

resource nicName 'Microsoft.Network/networkInterfaces@2016-03-30' = {
  name: nicName_var
  location: location
  properties: {
    ipConfigurations: [
      {
        name: 'ipconfig1'
        properties: {
          privateIPAllocationMethod: 'Dynamic'
          publicIPAddress: {
            id: publicIPAddressName.id
          }
          subnet: {
            id: subnetRef
          }
        }
      }
    ]
  }
  dependsOn: [
    virtualNetworkName
  ]
}

resource peAgentNic 'Microsoft.Network/networkInterfaces@2016-03-30' = [for i in range(0, puppetAgentCount): {
  name: 'peAgentNic${i}'
  location: location
  properties: {
    ipConfigurations: [
      {
        name: 'ipconfig1'
        properties: {
          privateIPAllocationMethod: 'Dynamic'
          publicIPAddress: {
            id: resourceId('Microsoft.Network/publicIPAddresses', 'peagentip${i}')
          }
          subnet: {
            id: subnetRef
          }
        }
      }
    ]
  }
  dependsOn: [
    'Microsoft.Network/publicIPAddresses/peagentip${i}'
    virtualNetworkName
  ]
}]

resource puppetMasterVmName 'Microsoft.Compute/virtualMachines@2017-03-30' = {
  name: puppetMasterVmName_var
  location: location
  plan: {
    name: '2016-1'
    product: 'puppet-enterprise'
    publisher: 'puppet'
  }
  properties: {
    hardwareProfile: {
      vmSize: vmSize
    }
    osProfile: {
      computerName: puppetMasterVmName_var
      adminUsername: adminUsername
      adminPassword: adminPassword
      customData: base64('#!/bin/bash\n\ncat <<EOF >/tmp/puppet_override.answers\nazure_externalFQDN=${reference(publicIPAddressName.id, '2016-03-30').dnsSettings.fqdn}\nazure_internalFQDN=$(hostname -f)\n\nq_puppet_enterpriseconsole_auth_password=${consolePassword}\nq_database_host=\\\${azure_externalFQDN}\nq_puppet_enterpriseconsole_master_hostname=\\\${azure_externalFQDN}\nq_puppet_enterpriseconsole_smtp_host=\\\${azure_externalFQDN}\nq_puppetagent_certname=\\\${azure_externalFQDN}\nq_puppetmaster_dnsaltnames=puppet,$(hostname),\\\${azure_internalFQDN},\\\${azure_externalFQDN}\nq_puppetagent_server=\\\${azure_externalFQDN}\nq_puppetdb_hostname=\\\${azure_externalFQDN}\nq_puppetmaster_certname=\\\${azure_externalFQDN}\nEOF\nchmod +x /tmp/puppet_override.answers\n')
    }
    storageProfile: {
      imageReference: {
        publisher: imagePublisher
        offer: imageOffer
        sku: imageSku
        version: 'latest'
      }
      osDisk: {
        name: '${puppetMasterVmName_var}_OSDisk'
        caching: 'ReadWrite'
        createOption: 'FromImage'
      }
    }
    networkProfile: {
      networkInterfaces: [
        {
          id: nicName.id
        }
      ]
    }
    diagnosticsProfile: {
      bootDiagnostics: {
        enabled: true
        storageUri: 'http://${newStorageAccountName_var}.blob.core.windows.net'
      }
    }
  }
  dependsOn: [
    newStorageAccountName
  ]
}

resource puppetMasterVmName_CustomScriptExtension 'Microsoft.Compute/virtualMachines/extensions@2016-03-30' = {
  parent: puppetMasterVmName
  name: 'CustomScriptExtension'
  location: location
  properties: {
    publisher: 'Microsoft.Azure.Extensions'
    type: 'CustomScript'
    typeHandlerVersion: '2.0'
    autoUpgradeMinorVersion: true
    settings: {
      fileUris: [
        '${artifactsLocation}wait.sh'
      ]
      commandToExecute: './wait.sh'
    }
  }
}

resource WindowsAgentVM 'Microsoft.Compute/virtualMachines@2017-03-30' = [for i in range(0, windowsAgentCount): {
  name: 'WindowsAgentVM${i}'
  location: location
  properties: {
    hardwareProfile: {
      vmSize: vmSize
    }
    osProfile: {
      computerName: 'windowsAgentVM${i}'
      adminUsername: adminUsername
      adminPassword: adminPassword
    }
    storageProfile: {
      imageReference: {
        publisher: 'MicrosoftWindowsServer'
        offer: 'WindowsServer'
        sku: '2012-R2-Datacenter'
        version: 'latest'
      }
      osDisk: {
        name: 'WindowsAgentVM${i}_OSDisk'
        caching: 'ReadWrite'
        createOption: 'FromImage'
      }
    }
    networkProfile: {
      networkInterfaces: [
        {
          id: resourceId('Microsoft.Network/networkInterfaces', 'peAgentNic${i}')
        }
      ]
    }
    diagnosticsProfile: {
      bootDiagnostics: {
        enabled: true
        storageUri: 'http://${newStorageAccountName_var}.blob.core.windows.net'
      }
    }
  }
  dependsOn: [
    newStorageAccountName
    'Microsoft.Network/networkInterfaces/peAgentNic${i}'
  ]
}]

resource WindowsAgentVm_puppetExtension 'Microsoft.Compute/virtualMachines/extensions@2016-03-30' = [for i in range(0, windowsAgentCount): {
  name: 'WindowsAgentVm${i}/puppetExtension'
  location: location
  properties: {
    publisher: 'Puppet'
    type: 'PuppetAgent'
    typeHandlerVersion: '1.5'
    autoUpgradeMinorVersion: 'true'
    protectedSettings: {
      PUPPET_MASTER_SERVER: reference(publicIPAddressName_var, '2015-06-15').dnsSettings.fqdn
    }
  }
  dependsOn: [
    'Microsoft.Compute/virtualMachines/WindowsAgentVm${i}'
    puppetMasterVmName_CustomScriptExtension
  ]
}]

resource UbuntuAgentVM 'Microsoft.Compute/virtualMachines@2017-03-30' = [for i in range(0, linuxAgentCount): {
  name: 'UbuntuAgentVM${i}'
  location: location
  properties: {
    hardwareProfile: {
      vmSize: vmSize
    }
    osProfile: {
      computerName: 'UbuntuAgentVM${i}'
      adminUsername: adminUsername
      adminPassword: adminPassword
    }
    storageProfile: {
      imageReference: {
        publisher: 'canonical'
        offer: 'ubuntuserver'
        sku: '14.04.5-LTS'
        version: 'latest'
      }
      osDisk: {
        name: 'UbuntuAgentVM${i}_OSDisk'
        caching: 'ReadWrite'
        createOption: 'FromImage'
      }
    }
    networkProfile: {
      networkInterfaces: [
        {
          id: resourceId('Microsoft.Network/networkInterfaces', 'peAgentNic${(i + windowsAgentCount)}')
        }
      ]
    }
    diagnosticsProfile: {
      bootDiagnostics: {
        enabled: true
        storageUri: 'http://${newStorageAccountName_var}.blob.core.windows.net'
      }
    }
  }
  dependsOn: [
    newStorageAccountName
    'Microsoft.Network/networkInterfaces/peAgentNic${(i + windowsAgentCount)}'
  ]
}]

resource UbuntuAgentVM_CustomScriptExtension 'Microsoft.Compute/virtualMachines/extensions@2016-03-30' = [for i in range(0, linuxAgentCount): {
  name: 'UbuntuAgentVM${i}/CustomScriptExtension'
  location: location
  properties: {
    publisher: 'Microsoft.Azure.Extensions'
    type: 'CustomScript'
    typeHandlerVersion: '2.0'
    autoUpgradeMinorVersion: true
    settings: {
      fileUris: [
        '${artifactsLocation}install_puppet_agent.sh'
      ]
      commandToExecute: './install_puppet_agent.sh ${reference(publicIPAddressName.id, '2016-03-30').dnsSettings.fqdn}'
    }
  }
  dependsOn: [
    'Microsoft.Compute/virtualMachines/UbuntuAgentVm${i}'
    puppetMasterVmName_CustomScriptExtension
  ]
}]

output Puppet_Enterprise_Console_FQDN string = reference(publicIPAddressName.id, '2016-03-30').dnsSettings.fqdn