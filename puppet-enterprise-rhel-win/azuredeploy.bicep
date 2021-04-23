@description('User name for the user of Virtual Machine. Used for both Linux and Windows machines')
param vmUsername string

@minLength(12)
@description('Password for the user of Virtual Machine. Used for both Linux and Windows machines.')
@secure()
param vmPassword string

@minLength(8)
@description('Password for the Puppet Enterprise Console.')
@secure()
param puppetConsolePassword string

@minValue(1)
@maxValue(20)
@description('Number of Windows Puppet Agents to deploy. Deploys Windows Server 2016.')
param windowsAgentCount int = 2

@minValue(1)
@maxValue(20)
@description('Number of Linux Puppet Agents to deploy. Deploys RHEL 7.2')
param linuxAgentCount int = 2

@minLength(7)
@description('Enter Public IP CIDR Allowed for accessing the deployment.Enter in 0.0.0.0/0 format. You can always modify these later in NSG Settings')
param remoteAllowedCIDR string = '0.0.0.0/0'

@description('The base URI where artifacts required by this template are located. When the template is deployed using the accompanying scripts, a private location in the subscription will be used and this value will be automatically generated.')
param artifactsLocation string = 'https://raw.githubusercontent.com/Azure/azure-quickstart-templates/master/puppet-enterprise-rhel-win/'

@description('The sasToken required to access _artifactsLocation.  When the template is deployed using the accompanying scripts, a sasToken will be automatically generated.Leave blank if unsure')
@secure()
param artifactsLocationSasToken string = ''

@description('Location for all resources.')
param location string = resourceGroup().location

var puppetNsgName_var = 'puppet-nsg'
var linuxAgentNsgName_var = 'linux-agent-nsg'
var windowsAgentNsgName_var = 'windows-agent-nsg'
var diagStorageAccountName_var = 'diagstor${uniqueString(resourceGroup().id)}'
var virtualNetworkName_var = 'puppet-vnet'
var linuxSubnetName = 'linux-agent-subnet'
var windowsSubnetName = 'windows-agent-subnet'
var puppetSubnetName = 'puppet-subnet'
var addressPrefix = '10.0.0.0/16'
var puppetSubnetPrefix = '10.0.1.0/24'
var linuxSubnetPrefix = '10.0.2.0/24'
var linuxPrivateIpAddressStart = '10.0.2.2'
var windowsSubnetPrefix = '10.0.3.0/24'
var winPrivateIpAddressStart = '10.0.3.2'
var publicIPAddressNamePuppetMaster_var = 'puppet-master-pip'
var dnsNamePuppetMaster = 'puppet${uniqueString(resourceGroup().id)}'
var loadBalancerName_var = 'agent-lb'
var lbIPAddressName_var = 'lb-pip'
var lbIPAddressDNSName = 'agent${uniqueString(resourceGroup().id)}'
var puppetMasterNicName_var = 'puppet-master-nic'
var puppetMasterVmName_var = 'vm-puppet-master'
var vmWinAgentName = 'vm-windows-agent'
var vmLinAgentName = 'vm-linux-agent'
var vmWinAgentNicName = 'vm-windows-agent-nic-'
var vmLinAgentNicName = 'vm-linux-agent-nic-'
var scriptClose = '\''
var scriptFileName2 = 'installpuppetagent.sh'
var scriptStart = 'su -c\'sh '
var customScriptCommand2 = '${scriptStart}${scriptFileName2} '
var redHatTags = {
  type: 'object'
  provider: '9d2c71fc-96ba-4b4a-93b3-14def5bc96fc'
}
var puppetTags = {
  type: 'object'
  provider: '8D5B50DB-4F4A-4112-A0D2-1385BD3BB64E'
}
var quickstartTags = {
  type: 'object'
  name: 'puppet-enterprise-rhel-win'
}

resource master_avset 'Microsoft.Compute/availabilitySets@2017-12-01' = {
  name: 'master-avset'
  location: location
  tags: {
    displayName: 'Availability Set Puppet Master'
    quickstartName: quickstartTags.name
    provider: puppetTags.provider
  }
  sku: {
    name: 'Aligned'
  }
  properties: {
    platformFaultDomainCount: 2
    platformUpdateDomainCount: 5
  }
}

resource agent_avset 'Microsoft.Compute/availabilitySets@2017-12-01' = {
  name: 'agent-avset'
  location: location
  tags: {
    displayName: 'Puppet Agents Availability Set'
    quickstartName: quickstartTags.name
    provider: redHatTags.provider
  }
  sku: {
    name: 'Aligned'
  }
  properties: {
    platformFaultDomainCount: 2
    platformUpdateDomainCount: 5
  }
}

resource puppetNsgName 'Microsoft.Network/networkSecurityGroups@2016-03-30' = {
  name: puppetNsgName_var
  location: location
  tags: {
    displayName: 'Puppet NSG'
    quickstartName: quickstartTags.name
    provider: puppetTags.provider
  }
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
        name: 'allow-8080'
        properties: {
          description: 'Allow 8080'
          protocol: 'Tcp'
          sourcePortRange: '*'
          destinationPortRange: '8080'
          sourceAddressPrefix: '*'
          destinationAddressPrefix: '*'
          access: 'Allow'
          priority: 131
          direction: 'Inbound'
        }
      }
      {
        name: 'allow-80'
        properties: {
          description: 'Allow 80'
          protocol: 'Tcp'
          sourcePortRange: '*'
          destinationPortRange: '80'
          sourceAddressPrefix: '*'
          destinationAddressPrefix: '*'
          access: 'Allow'
          priority: 120
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

resource linuxAgentNsgName 'Microsoft.Network/networkSecurityGroups@2016-03-30' = {
  name: linuxAgentNsgName_var
  location: location
  tags: {
    displayName: 'Linux Agent NSG'
    quickstartName: quickstartTags.name
    provider: redHatTags.provider
  }
  properties: {
    securityRules: [
      {
        name: 'puppet'
        properties: {
          protocol: 'Tcp'
          sourcePortRange: '*'
          destinationPortRange: '8140'
          sourceAddressPrefix: remoteAllowedCIDR
          destinationAddressPrefix: '*'
          access: 'Allow'
          priority: 100
          direction: 'Inbound'
        }
      }
      {
        name: 'allow-8080'
        properties: {
          description: 'Allow 8080'
          protocol: 'Tcp'
          sourcePortRange: '*'
          destinationPortRange: '8080'
          sourceAddressPrefix: remoteAllowedCIDR
          destinationAddressPrefix: '*'
          access: 'Allow'
          priority: 131
          direction: 'Inbound'
        }
      }
      {
        name: 'allow-80'
        properties: {
          description: 'Allow 80'
          protocol: 'Tcp'
          sourcePortRange: '*'
          destinationPortRange: '80'
          sourceAddressPrefix: remoteAllowedCIDR
          destinationAddressPrefix: '*'
          access: 'Allow'
          priority: 120
          direction: 'Inbound'
        }
      }
      {
        name: 'ssh'
        properties: {
          description: 'Allow SSH'
          protocol: 'Tcp'
          sourcePortRange: '*'
          destinationPortRange: '22'
          sourceAddressPrefix: remoteAllowedCIDR
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
          sourceAddressPrefix: remoteAllowedCIDR
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
          sourceAddressPrefix: remoteAllowedCIDR
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
          sourceAddressPrefix: remoteAllowedCIDR
          destinationAddressPrefix: '*'
          access: 'Allow'
          priority: 104
          direction: 'Inbound'
        }
      }
    ]
  }
}

resource windowsAgentNsgName 'Microsoft.Network/networkSecurityGroups@2016-03-30' = {
  name: windowsAgentNsgName_var
  location: location
  tags: {
    displayName: 'Windows Agent NSG'
    quickstartName: quickstartTags.name
    provider: redHatTags.provider
  }
  properties: {
    securityRules: [
      {
        name: 'puppet'
        properties: {
          protocol: 'Tcp'
          sourcePortRange: '*'
          destinationPortRange: '8140'
          sourceAddressPrefix: remoteAllowedCIDR
          destinationAddressPrefix: '*'
          access: 'Allow'
          priority: 100
          direction: 'Inbound'
        }
      }
      {
        name: 'allow-8080'
        properties: {
          description: 'Allow 8080'
          protocol: 'Tcp'
          sourcePortRange: '*'
          destinationPortRange: '8080'
          sourceAddressPrefix: remoteAllowedCIDR
          destinationAddressPrefix: '*'
          access: 'Allow'
          priority: 121
          direction: 'Inbound'
        }
      }
      {
        name: 'allow-80'
        properties: {
          description: 'Allow 80'
          protocol: 'Tcp'
          sourcePortRange: '*'
          destinationPortRange: '80'
          sourceAddressPrefix: remoteAllowedCIDR
          destinationAddressPrefix: '*'
          access: 'Allow'
          priority: 120
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
          sourceAddressPrefix: remoteAllowedCIDR
          destinationAddressPrefix: '*'
          access: 'Allow'
          priority: 101
          direction: 'Inbound'
        }
      }
      {
        name: 'ssh'
        properties: {
          description: 'Allow SSH'
          protocol: 'Tcp'
          sourcePortRange: '*'
          destinationPortRange: '22'
          sourceAddressPrefix: remoteAllowedCIDR
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
          sourceAddressPrefix: remoteAllowedCIDR
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
          sourceAddressPrefix: remoteAllowedCIDR
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
          sourceAddressPrefix: remoteAllowedCIDR
          destinationAddressPrefix: '*'
          access: 'Allow'
          priority: 104
          direction: 'Inbound'
        }
      }
    ]
  }
}

resource diagStorageAccountName 'Microsoft.Storage/storageAccounts@2015-06-15' = {
  name: diagStorageAccountName_var
  location: location
  tags: {
    displayName: 'Diagnostics Storage Account'
    quickstartName: quickstartTags.name
    provider: redHatTags.provider
  }
  properties: {
    accountType: 'Standard_LRS'
  }
}

resource virtualNetworkName 'Microsoft.Network/virtualNetworks@2016-03-30' = {
  name: virtualNetworkName_var
  location: location
  tags: {
    displayName: 'Puppet Virtual Network'
    quickstartName: quickstartTags.name
    provider: redHatTags.provider
  }
  properties: {
    addressSpace: {
      addressPrefixes: [
        addressPrefix
      ]
    }
    subnets: [
      {
        name: puppetSubnetName
        properties: {
          addressPrefix: puppetSubnetPrefix
          networkSecurityGroup: {
            id: puppetNsgName.id
          }
        }
      }
      {
        name: windowsSubnetName
        properties: {
          addressPrefix: windowsSubnetPrefix
          networkSecurityGroup: {
            id: windowsAgentNsgName.id
          }
        }
      }
      {
        name: linuxSubnetName
        properties: {
          addressPrefix: linuxSubnetPrefix
          networkSecurityGroup: {
            id: linuxAgentNsgName.id
          }
        }
      }
    ]
  }
}

resource publicIPAddressNamePuppetMaster 'Microsoft.Network/publicIPAddresses@2016-03-30' = {
  name: publicIPAddressNamePuppetMaster_var
  location: location
  tags: {
    displayName: 'Public IP - Puppet Master'
    quickstartName: quickstartTags.name
    provider: redHatTags.provider
  }
  properties: {
    publicIPAllocationMethod: 'Static'
    dnsSettings: {
      domainNameLabel: dnsNamePuppetMaster
    }
  }
}

resource lbIPAddressName 'Microsoft.Network/publicIPAddresses@2016-03-30' = {
  name: lbIPAddressName_var
  location: location
  tags: {
    displayName: 'LB Public IP'
    quickstartName: quickstartTags.name
    provider: redHatTags.provider
  }
  properties: {
    publicIPAllocationMethod: 'Static'
    idleTimeoutInMinutes: 4
    dnsSettings: {
      domainNameLabel: lbIPAddressDNSName
    }
  }
}

resource loadBalancerName 'Microsoft.Network/loadBalancers@2015-06-15' = {
  name: loadBalancerName_var
  location: location
  tags: {
    displayName: 'Load Balancer'
    quickstartName: quickstartTags.name
    provider: redHatTags.provider
  }
  properties: {
    frontendIPConfigurations: [
      {
        name: 'loadBalancerFrontEnd'
        properties: {
          publicIPAddress: {
            id: lbIPAddressName.id
          }
        }
      }
    ]
    backendAddressPools: [
      {
        name: 'loadBalancerBackEnd1'
      }
      {
        name: 'loadBalancerBackEnd2'
      }
    ]
  }
}

resource loadBalancerName_RDPVM_1 'Microsoft.Network/loadBalancers/inboundNatRules@2015-06-15' = [for i in range(0, windowsAgentCount): {
  name: '${loadBalancerName_var}/RDPVM${(i + 1)}'
  location: location
  tags: {
    displayName: 'LB nat rules-RDP'
    quickstartName: quickstartTags.name
    provider: redHatTags.provider
  }
  properties: {
    frontendIPConfiguration: {
      id: '${loadBalancerName.id}/frontendIPConfigurations/loadBalancerFrontEnd'
    }
    protocol: 'Tcp'
    frontendPort: (i + 5001)
    backendPort: 3389
    enableFloatingIP: false
  }
  dependsOn: [
    loadBalancerName
  ]
}]

resource loadBalancerName_SSHVM_1 'Microsoft.Network/loadBalancers/inboundNatRules@2015-06-15' = [for i in range(0, linuxAgentCount): {
  name: '${loadBalancerName_var}/SSHVM${(i + 1)}'
  location: location
  tags: {
    displayName: 'LB nat rules-SSH'
    quickstartName: quickstartTags.name
    provider: redHatTags.provider
  }
  properties: {
    frontendIPConfiguration: {
      id: '${loadBalancerName.id}/frontendIPConfigurations/loadBalancerFrontEnd'
    }
    protocol: 'Tcp'
    frontendPort: (i + 6001)
    backendPort: 22
    enableFloatingIP: false
  }
  dependsOn: [
    loadBalancerName
  ]
}]

resource puppetMasterNicName 'Microsoft.Network/networkInterfaces@2016-03-30' = {
  name: puppetMasterNicName_var
  location: location
  tags: {
    displayName: 'Puppet Master NIC'
    quickstartName: quickstartTags.name
    provider: puppetTags.provider
  }
  properties: {
    ipConfigurations: [
      {
        name: 'ipconfig1'
        properties: {
          privateIPAllocationMethod: 'Static'
          privateIPAddress: '10.0.1.21'
          publicIPAddress: {
            id: publicIPAddressNamePuppetMaster.id
          }
          subnet: {
            id: resourceId('Microsoft.Network/virtualNetworks/subnets/', virtualNetworkName_var, puppetSubnetName)
          }
        }
      }
    ]
  }
  dependsOn: [
    virtualNetworkName
  ]
}

resource vmLinAgentNicName_1 'Microsoft.Network/networkInterfaces@2016-03-30' = [for i in range(0, linuxAgentCount): {
  name: concat(vmLinAgentNicName, (i + 1))
  location: location
  tags: {
    displayName: 'Linux Agent NICs'
    quickstartName: quickstartTags.name
    provider: redHatTags.provider
  }
  properties: {
    ipConfigurations: [
      {
        name: 'ipconfig1'
        properties: {
          privateIPAllocationMethod: 'Static'
          privateIPAddress: concat(linuxPrivateIpAddressStart, (i + 1))
          subnet: {
            id: resourceId('Microsoft.Network/virtualNetworks/subnets/', virtualNetworkName_var, linuxSubnetName)
          }
          loadBalancerBackendAddressPools: [
            {
              id: '${loadBalancerName.id}/backendAddressPools/LoadBalancerBackend2'
            }
          ]
          loadBalancerInboundNatRules: [
            {
              id: '${loadBalancerName.id}/inboundNatRules/SSHVM${(i + 1)}'
            }
          ]
        }
      }
    ]
  }
  dependsOn: [
    virtualNetworkName
    loadBalancerName
    'Microsoft.Network/loadBalancers/${loadBalancerName_var}/inboundNatRules/SSHVM${(i + 1)}'
  ]
}]

resource vmWinAgentNicName_1 'Microsoft.Network/networkInterfaces@2016-03-30' = [for i in range(0, windowsAgentCount): {
  name: concat(vmWinAgentNicName, (i + 1))
  location: location
  tags: {
    displayName: 'Windows Agent NICs'
    quickstartName: quickstartTags.name
    provider: redHatTags.provider
  }
  properties: {
    ipConfigurations: [
      {
        name: 'ipconfig1'
        properties: {
          privateIPAllocationMethod: 'Static'
          privateIPAddress: concat(winPrivateIpAddressStart, (i + 1))
          subnet: {
            id: resourceId('Microsoft.Network/virtualNetworks/subnets/', virtualNetworkName_var, windowsSubnetName)
          }
          loadBalancerBackendAddressPools: [
            {
              id: '${loadBalancerName.id}/backendAddressPools/LoadBalancerBackend1'
            }
          ]
          loadBalancerInboundNatRules: [
            {
              id: '${loadBalancerName.id}/inboundNatRules/RDPVM${(i + 1)}'
            }
          ]
        }
      }
    ]
  }
  dependsOn: [
    virtualNetworkName
    loadBalancerName
    'Microsoft.Network/loadBalancers/${loadBalancerName_var}/inboundNatRules/RDPVM${(i + 1)}'
  ]
}]

resource puppetMasterVmName 'Microsoft.Compute/virtualMachines@2017-03-30' = {
  name: puppetMasterVmName_var
  location: location
  tags: {
    displayName: 'Puppet Master VM'
    quickstartName: quickstartTags.name
    provider: puppetTags.provider
  }
  plan: {
    name: '2016-1'
    product: 'puppet-enterprise'
    publisher: 'puppet'
  }
  properties: {
    availabilitySet: {
      id: master_avset.id
    }
    hardwareProfile: {
      vmSize: 'Standard_D2_v2'
    }
    osProfile: {
      computerName: puppetMasterVmName_var
      adminUsername: vmUsername
      adminPassword: vmPassword
      customData: base64('#!/bin/bash\n\ncat <<EOF >/tmp/puppet_override.answers\nazure_externalFQDN=${reference(publicIPAddressNamePuppetMaster.id, '2016-03-30').dnsSettings.fqdn}\nazure_internalFQDN=$(hostname -f)\n\nq_puppet_enterpriseconsole_auth_password=${puppetConsolePassword}\nq_database_host=\\\${azure_externalFQDN}\nq_puppet_enterpriseconsole_master_hostname=\\\${azure_externalFQDN}\nq_puppet_enterpriseconsole_smtp_host=\\\${azure_externalFQDN}\nq_puppetagent_certname=\\\${azure_externalFQDN}\nq_puppetmaster_dnsaltnames=puppet,$(hostname),\\\${azure_internalFQDN},\\\${azure_externalFQDN}\nq_puppetagent_server=\\\${azure_externalFQDN}\nq_puppetdb_hostname=\\\${azure_externalFQDN}\nq_puppetmaster_certname=\\\${azure_externalFQDN}\necho "deb [trusted=yes] file:/usr/bin/puppet-init/puppet-enterprise-2016.1.2-ubuntu-14.04-amd64/packages/ubuntu-14.04-amd64 ./" > /etc/apt/sources.list.d/puppet-enterprise.list\nEOF\nchmod +x /tmp/puppet_override.answers\n')
    }
    storageProfile: {
      imageReference: {
        publisher: 'Puppet'
        offer: 'Puppet-Enterprise'
        sku: '2017-2'
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
          id: puppetMasterNicName.id
        }
      ]
    }
    diagnosticsProfile: {
      bootDiagnostics: {
        enabled: true
        storageUri: reference('Microsoft.Storage/storageAccounts/${diagStorageAccountName_var}', '2015-06-15').primaryEndpoints.blob
      }
    }
  }
}

resource puppetMasterVmName_CustomScriptPuppet 'Microsoft.Compute/virtualMachines/extensions@2016-03-30' = {
  parent: puppetMasterVmName
  name: 'CustomScriptPuppet'
  location: location
  tags: {
    displayName: 'Puppet Master VM Extension'
    quickstartName: quickstartTags.name
    provider: puppetTags.provider
  }
  properties: {
    publisher: 'Microsoft.Azure.Extensions'
    type: 'CustomScript'
    typeHandlerVersion: '2.0'
    autoUpgradeMinorVersion: true
    settings: {
      fileUris: [
        '${artifactsLocation}scripts/wait.sh${artifactsLocationSasToken}'
      ]
    }
    protectedSettings: {
      commandToExecute: './wait.sh'
    }
  }
}

resource vmWinAgentName_1 'Microsoft.Compute/virtualMachines@2017-03-30' = [for i in range(0, windowsAgentCount): {
  name: concat(vmWinAgentName, (i + 1))
  location: location
  tags: {
    displayName: 'Windows Agent VMs'
    quickstartName: quickstartTags.name
    provider: redHatTags.provider
  }
  properties: {
    availabilitySet: {
      id: agent_avset.id
    }
    hardwareProfile: {
      vmSize: 'Standard_D1_v2'
    }
    osProfile: {
      computerName: 'vmWinAgent${(i + 1)}'
      adminUsername: vmUsername
      adminPassword: vmPassword
    }
    storageProfile: {
      imageReference: {
        publisher: 'MicrosoftWindowsServer'
        offer: 'WindowsServer'
        sku: '2016-Datacenter'
        version: 'latest'
      }
      osDisk: {
        name: 'vmWinAgent${(i + 1)}os-disk'
        caching: 'ReadWrite'
        createOption: 'FromImage'
      }
    }
    networkProfile: {
      networkInterfaces: [
        {
          id: resourceId('Microsoft.Network/networkInterfaces', concat(vmWinAgentNicName, (i + 1)))
        }
      ]
    }
    diagnosticsProfile: {
      bootDiagnostics: {
        enabled: true
        storageUri: reference('Microsoft.Storage/storageAccounts/${diagStorageAccountName_var}', '2015-06-15').primaryEndpoints.blob
      }
    }
  }
  dependsOn: [
    'Microsoft.Network/networkInterfaces/${vmWinAgentNicName}${(i + 1)}'
  ]
}]

resource vmWinAgentName_1_puppetExtension 'Microsoft.Compute/virtualMachines/extensions@2016-03-30' = [for i in range(0, windowsAgentCount): {
  name: '${vmWinAgentName}${(i + 1)}/puppetExtension'
  location: location
  tags: {
    displayName: 'Windows Agent VM Extension'
    quickstartName: quickstartTags.name
    provider: redHatTags.provider
  }
  properties: {
    publisher: 'Puppet'
    type: 'PuppetAgent'
    typeHandlerVersion: '1.5'
    autoUpgradeMinorVersion: true
    protectedSettings: {
      PUPPET_MASTER_SERVER: reference(publicIPAddressNamePuppetMaster.id, '2016-03-30').dnsSettings.fqdn
    }
  }
  dependsOn: [
    'Microsoft.Compute/virtualMachines/${vmWinAgentName}${(i + 1)}'
    puppetMasterVmName_CustomScriptPuppet
  ]
}]

resource vmLinAgentName_1 'Microsoft.Compute/virtualMachines@2017-03-30' = [for i in range(0, linuxAgentCount): {
  name: concat(vmLinAgentName, (i + 1))
  location: location
  tags: {
    displayName: 'Linux Agent VMs'
    quickstartName: quickstartTags.name
    provider: redHatTags.provider
  }
  properties: {
    availabilitySet: {
      id: agent_avset.id
    }
    hardwareProfile: {
      vmSize: 'Standard_D1_v2'
    }
    osProfile: {
      computerName: concat(vmLinAgentName, (i + 1))
      adminUsername: vmUsername
      adminPassword: vmPassword
    }
    storageProfile: {
      imageReference: {
        publisher: 'RedHat'
        offer: 'RHEL'
        sku: '7.2'
        version: 'latest'
      }
      osDisk: {
        name: 'vmLinAgent${(i + 1)}os-disk'
        caching: 'ReadWrite'
        createOption: 'FromImage'
      }
    }
    networkProfile: {
      networkInterfaces: [
        {
          id: resourceId('Microsoft.Network/networkInterfaces', concat(vmLinAgentNicName, (i + 1)))
        }
      ]
    }
    diagnosticsProfile: {
      bootDiagnostics: {
        enabled: true
        storageUri: reference('Microsoft.Storage/storageAccounts/${diagStorageAccountName_var}', '2015-06-15').primaryEndpoints.blob
      }
    }
  }
  dependsOn: [
    'Microsoft.Network/networkInterfaces/${vmLinAgentNicName}${(i + 1)}'
  ]
}]

resource vmLinAgentName_1_CustomScriptLinuxAgent 'Microsoft.Compute/virtualMachines/extensions@2016-03-30' = [for i in range(0, linuxAgentCount): {
  name: '${vmLinAgentName}${(i + 1)}/CustomScriptLinuxAgent'
  location: location
  tags: {
    displayName: 'Linux Agent VM Extension'
    quickstartName: quickstartTags.name
    provider: puppetTags.provider
  }
  properties: {
    publisher: 'Microsoft.Azure.Extensions'
    type: 'CustomScript'
    typeHandlerVersion: '2.0'
    autoUpgradeMinorVersion: true
    settings: {
      fileUris: [
        '${artifactsLocation}scripts/${scriptFileName2}${artifactsLocationSasToken}'
      ]
    }
    protectedSettings: {
      commandToExecute: '${customScriptCommand2}${publicIPAddressNamePuppetMaster.properties.ipAddress} ${reference(publicIPAddressNamePuppetMaster.id, '2016-03-30').dnsSettings.fqdn}${scriptClose}'
    }
  }
  dependsOn: [
    'Microsoft.Compute/virtualMachines/${vmLinAgentName}${(i + 1)}'
    puppetMasterVmName_CustomScriptPuppet
  ]
}]

output Puppet_Enterprise_Console_FQDN string = reference(publicIPAddressNamePuppetMaster.id, '2016-03-30').dnsSettings.fqdn
output Puppet_Enterprise_Console_IP string = publicIPAddressNamePuppetMaster.properties.ipAddress
output Load_Balancer_Public_IP string = lbIPAddressName.properties.ipAddress