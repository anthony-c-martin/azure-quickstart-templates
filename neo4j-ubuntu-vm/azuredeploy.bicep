@minLength(1)
@description('Virtual machine name.')
param vmName string

@description('Virtual machine size. Make sure VM size supports disk type.')
param vmSize string = 'Standard_DS1_v2'

@allowed([
  '18.04-LTS'
])
@description('Ubuntu OS image version.')
param vmUbuntuOSVersion string = '18.04-LTS'

@minLength(1)
@description('User name for the virtual machine.')
param vmAdminUsername string

@description('SSH rsa public key file as a string.')
param sshKeyData string

@allowed([
  'neo4j'
  'neo4j-enterprise'
  'neo4j=3.2.1'
  'neo4j-enterprise=3.2.1'
  'neo4j=3.2.5'
  'neo4j-enterprise=3.2.5'
  'neo4j=3.3.0'
  'neo4j-enterprise=3.3.0'
])
@description('Neo4J edition and version to install.')
param neo4jEdition string = 'neo4j'

@minLength(1)
@description('Unique DNS name for public IP Address. As in: publicIPAddressDns.location.cloudapp.azure.com')
param publicIPAddressDns string

@description('The base URI where artifacts required by this template are located. When the template is deployed using the accompanying scripts, a private location in the subscription will be used and this value will be automatically generated.')
param artifactsLocation string = 'https://raw.githubusercontent.com/Azure/azure-quickstart-templates/master/neo4j-ubuntu-vm/'

@description('The sasToken required to access _artifactsLocation.  When the template is deployed using the accompanying scripts, a sasToken will be automatically generated.')
@secure()
param artifactsLocationSasToken string = ''

@description('Location for all resources.')
param location string = resourceGroup().location

var sshKeyPath = '/home/${vmAdminUsername}/.ssh/authorized_keys'
var scriptsFolder = 'scripts/'
var virtualNetworkName_var = '${vmName}-vnet'
var networkSecurityGroupName_var = '${vmName}-nsg'
var networkInterfaceName_var = '${vmName}-nic'
var publicIPAddressName_var = '${vmName}-ip'
var virtualNetworkPrefix = '10.0.0.0/16'
var virtualNetworkSubnetName = 'default'
var virtualNetworkSubnetPrefix = '10.0.0.0/24'
var networkInterfaceSubnetRef = resourceId('Microsoft.Network/virtualNetworks/subnets', virtualNetworkName_var, virtualNetworkSubnetName)

resource virtualNetworkName 'Microsoft.Network/virtualNetworks@2017-09-01' = {
  name: virtualNetworkName_var
  location: location
  tags: {
    displayName: virtualNetworkName_var
  }
  properties: {
    addressSpace: {
      addressPrefixes: [
        virtualNetworkPrefix
      ]
    }
    subnets: [
      {
        name: virtualNetworkSubnetName
        properties: {
          addressPrefix: virtualNetworkSubnetPrefix
          networkSecurityGroup: {
            id: networkSecurityGroupName.id
          }
        }
      }
    ]
  }
}

resource networkSecurityGroupName 'Microsoft.Network/networkSecurityGroups@2017-09-01' = {
  name: networkSecurityGroupName_var
  location: location
  properties: {
    securityRules: [
      {
        name: 'default-allow-ssh'
        properties: {
          description: 'Allow secure shell connections'
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
      {
        name: 'neo4j-allow-bolt'
        properties: {
          description: 'Allow Bolt protocol connections'
          protocol: 'Tcp'
          sourcePortRange: '*'
          destinationPortRange: '7687'
          sourceAddressPrefix: '*'
          destinationAddressPrefix: '*'
          access: 'Allow'
          priority: 1010
          direction: 'Inbound'
        }
      }
      {
        name: 'neo4j-allow-http'
        properties: {
          description: 'Allow HTTP connections'
          protocol: 'Tcp'
          sourcePortRange: '*'
          destinationPortRange: '7474'
          sourceAddressPrefix: '*'
          destinationAddressPrefix: '*'
          access: 'Allow'
          priority: 1020
          direction: 'Inbound'
        }
      }
      {
        name: 'neo4j-allow-https'
        properties: {
          description: 'Allow HTTPS connections'
          protocol: 'Tcp'
          sourcePortRange: '*'
          destinationPortRange: '7473'
          sourceAddressPrefix: '*'
          destinationAddressPrefix: '*'
          access: 'Allow'
          priority: 1030
          direction: 'Inbound'
        }
      }
    ]
  }
}

resource networkInterfaceName 'Microsoft.Network/networkInterfaces@2017-09-01' = {
  name: networkInterfaceName_var
  location: location
  tags: {
    displayName: networkInterfaceName_var
  }
  properties: {
    ipConfigurations: [
      {
        name: 'ipconfig1'
        properties: {
          privateIPAllocationMethod: 'Dynamic'
          subnet: {
            id: networkInterfaceSubnetRef
          }
          publicIPAddress: {
            id: publicIPAddressName.id
          }
        }
      }
    ]
  }
  dependsOn: [
    virtualNetworkName
  ]
}

resource publicIPAddressName 'Microsoft.Network/publicIPAddresses@2017-09-01' = {
  name: publicIPAddressName_var
  location: location
  tags: {
    displayName: publicIPAddressName_var
  }
  properties: {
    publicIPAllocationMethod: 'Dynamic'
    dnsSettings: {
      domainNameLabel: publicIPAddressDns
    }
  }
  dependsOn: []
}

resource vmName_resource 'Microsoft.Compute/virtualMachines@2017-03-30' = {
  name: vmName
  location: location
  tags: {
    displayName: vmName
  }
  properties: {
    hardwareProfile: {
      vmSize: vmSize
    }
    osProfile: {
      computerName: vmName
      adminUsername: vmAdminUsername
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
        publisher: 'Canonical'
        offer: 'UbuntuServer'
        sku: vmUbuntuOSVersion
        version: 'latest'
      }
      osDisk: {
        name: '${vmName}_OSDisk'
        caching: 'ReadWrite'
        createOption: 'FromImage'
        managedDisk: {
          storageAccountType: 'Premium_LRS'
        }
      }
    }
    networkProfile: {
      networkInterfaces: [
        {
          id: networkInterfaceName.id
        }
      ]
    }
  }
}

resource vmName_installneo4j 'Microsoft.Compute/virtualMachines/extensions@2017-03-30' = {
  parent: vmName_resource
  name: 'installneo4j'
  location: location
  tags: {
    displayName: 'installneo4j'
  }
  properties: {
    publisher: 'Microsoft.OSTCExtensions'
    type: 'CustomScriptForLinux'
    typeHandlerVersion: '1.4'
    autoUpgradeMinorVersion: true
    settings: {
      fileUris: [
        '${artifactsLocation}${scriptsFolder}install-neo4j.sh${artifactsLocationSasToken}'
      ]
    }
    protectedSettings: {
      commandToExecute: 'sh install-neo4j.sh ${neo4jEdition}'
    }
  }
}

output hostname string = reference(publicIPAddressName_var).dnsSettings.fqdn