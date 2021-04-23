@description('Enter the Module(s) to install including the Version')
param modules array = [
  {
    name: 'AzureRM'
    version: '5.6.0'
  }
  {
    name: 'AzureAD'
    version: '2.0.1.3'
  }
  {
    name: 'Bitbucket.v2'
    version: '1.1.2'
  }
  {
    name: 'GetPassword'
    version: '1.0.0.0'
  }
  {
    name: 'posh-git'
    version: '0.7.1'
  }
]

@description('Enter a DNS name to resolve to the Public IP Address')
param publicIPDnsName string

@description('The name of the Administrator Account to be created')
param vmAdminUser string

@minLength(12)
@description('The password for the Admin Account. Must be at least 12 characters long')
@secure()
param vmAdminPassword string

@description('Specifiy the size of VM required for the VM(s)')
param vmSize string = 'Standard_D1_v2'

@description('The Visual Studio Team Services account name, that is, the first part of your VSTSAccount.visualstudio.com')
param vstsAccount string

@allowed([
  1
  2
  3
  4
])
@description('The number of Visual Studio Team Services agents to be configured on the Virtual Machine. Default is 3')
param vstsAgentCount int = 3

@description('The personal access token to connect to VSTS')
@secure()
param vstsPersonalAccessToken string

@description('The Visual Studio Team Services build agent pool for this build agent to join. Use \'Default\' if you don\'t have a separate pool.')
param vstsPoolName string = 'Default'

@description('The base URI where artifacts required by this template are located. When the template is deployed using the accompanying scripts, a private location in the subscription will be used and this value will be automatically generated.')
param artifactsLocation string = 'https://raw.githubusercontent.com/Azure/azure-quickstart-templates/master/201-vm-vsts-agent'

@description('The sasToken required to access _artifactsLocation.  When the template is deployed using the accompanying scripts, a sasToken will be automatically generated.')
@secure()
param artifactsLocationSasToken string = ''

@description('Location for all resources.')
param location string = resourceGroup().location

@description('Specifiy the publisher of the vm image')
param imagePublisher string = 'MicrosoftVisualStudio'

@allowed([
  'VisualStudio'
  'visualstudio2019'
])
@description('Specifiy the Offer of the vm image')
param imageOffer string = 'VisualStudio'

@allowed([
  'VS-2017-Ent-WS2016'
  'vs-2019-ent-ws2019'
])
@description('Specifiy the Offer of the vm image')
param imageSKU string = 'VS-2017-Ent-WS2016'

var ids = {
  avs: names_avs.id
  nic: names_nic.id
  pip: names_pip.id
  subnet: '${names_vnet_name.id}/subnets/${names.vnet.subnet}'
}
var names = {
  avs: 'avs-vsts-${uniqueString(resourceGroup().id)}'
  nic: 'nic-vsts-${uniqueString(resourceGroup().id)}'
  pip: 'pip-vsts-${uniqueString(resourceGroup().id)}'
  vm: 'vm-vsts-${substring(uniqueString(resourceGroup().id), 0, 6)}'
  vnet: {
    name: 'vn-vsts-${uniqueString(resourceGroup().id)}'
    addressPrefix: '10.0.0.0/16'
    subnet: 'subnet-0'
    subnetPrefix: '10.0.0.0/24'
  }
  vsts: 'agent-${uniqueString(resourceGroup().id)}'
}
var powerShell = {
  script: 'InstallVstsAgent.ps1'
  folder: 'scripts'
  parameters: '-vstsAccount ${vstsAccount} -personalAccessToken ${vstsPersonalAccessToken} -AgentName ${names.vsts} -PoolName ${vstsPoolName} -AgentCount ${vstsAgentCount} -AdminUser ${vmAdminUser} -Modules ${modules_var}'
}
var singleQuote = '\''
var modules_var = replace(replace(replace(replace(replace(string(modules), '[{"', '@(@{'), '":"', ' = ${singleQuote}'), '","', '${singleQuote}; '), '"},{"', '${singleQuote}}, @{'), '"}]', '${singleQuote}})')
var networkSecurityGroupName_var = 'default-NSG'

resource names_avs 'Microsoft.Compute/availabilitySets@2017-12-01' = {
  name: names.avs
  location: location
  tags: {
    displayName: 'availabilitySets'
  }
  properties: {
    platformUpdateDomainCount: 5
    platformFaultDomainCount: 2
  }
  sku: {
    name: 'Aligned'
  }
  dependsOn: []
}

resource names_pip 'Microsoft.Network/publicIPAddresses@2017-10-01' = {
  name: names.pip
  location: location
  tags: {
    displayName: 'publicIP'
  }
  properties: {
    dnsSettings: {
      domainNameLabel: publicIPDnsName
    }
    idleTimeoutInMinutes: 4
    publicIPAddressVersion: 'IPv4'
    publicIPAllocationMethod: 'Dynamic'
  }
  dependsOn: []
}

resource networkSecurityGroupName 'Microsoft.Network/networkSecurityGroups@2019-08-01' = {
  name: networkSecurityGroupName_var
  location: location
  properties: {
    securityRules: [
      {
        name: 'default-allow-3389'
        properties: {
          priority: 1000
          access: 'Allow'
          direction: 'Inbound'
          destinationPortRange: '3389'
          protocol: 'Tcp'
          sourceAddressPrefix: '*'
          sourcePortRange: '*'
          destinationAddressPrefix: '*'
        }
      }
    ]
  }
}

resource names_vnet_name 'Microsoft.Network/virtualNetworks@2017-10-01' = {
  name: names.vnet.name
  location: location
  tags: {
    displayName: 'virtualNetwork'
  }
  properties: {
    addressSpace: {
      addressPrefixes: [
        names.vnet.addressPrefix
      ]
    }
    subnets: [
      {
        name: names.vnet.subnet
        properties: {
          addressPrefix: names.vnet.subnetPrefix
          networkSecurityGroup: {
            id: networkSecurityGroupName.id
          }
        }
      }
    ]
  }
}

resource names_nic 'Microsoft.Network/networkInterfaces@2017-10-01' = {
  name: names.nic
  location: location
  tags: {
    displayName: 'networkInterfaces'
  }
  properties: {
    ipConfigurations: [
      {
        name: 'ipconfig1'
        properties: {
          privateIPAllocationMethod: 'Dynamic'
          publicIPAddress: {
            id: ids.pip
          }
          subnet: {
            id: ids.subnet
          }
        }
      }
    ]
    dnsSettings: {
      dnsServers: []
    }
    enableIPForwarding: false
  }
}

resource names_vm 'Microsoft.Compute/virtualMachines@2017-12-01' = {
  name: names.vm
  location: location
  tags: {
    displayName: 'virtualMachines'
  }
  properties: {
    availabilitySet: {
      id: ids.avs
    }
    hardwareProfile: {
      vmSize: vmSize
    }
    osProfile: {
      computerName: names.vm
      adminUsername: vmAdminUser
      adminPassword: vmAdminPassword
      windowsConfiguration: {
        provisionVMAgent: true
        enableAutomaticUpdates: true
      }
    }
    storageProfile: {
      imageReference: {
        publisher: imagePublisher
        offer: imageOffer
        sku: imageSKU
        version: 'latest'
      }
      osDisk: {
        createOption: 'FromImage'
        managedDisk: {
          storageAccountType: 'Standard_LRS'
        }
      }
    }
    networkProfile: {
      networkInterfaces: [
        {
          id: ids.nic
        }
      ]
    }
  }
}

resource names_vm_vstsAgent 'Microsoft.Compute/virtualMachines/extensions@2017-12-01' = {
  name: '${names.vm}/vstsAgent'
  location: location
  properties: {
    publisher: 'Microsoft.Compute'
    type: 'CustomScriptExtension'
    typeHandlerVersion: '1.9'
    settings: {
      fileUris: [
        uri(artifactsLocation, '${powerShell.folder}/${powerShell.script}${artifactsLocationSasToken}')
      ]
    }
    protectedSettings: {
      commandToExecute: 'powershell.exe -ExecutionPolicy Unrestricted -Command "& {./${powerShell.script} ${powerShell.parameters}}"'
    }
  }
  dependsOn: [
    names_vm
  ]
}

output Modules string = modules_var