@description('Number of LAB-VM tobe deployed')
param vmCount int

@description('DNS Prefix used by LabVM Public IP')
param dns_prefix string

@description('Admin Username for Lab VM')
param adminUser string

@description('Password for admin user')
@secure()
param adminPassword string

@description('VM Size for all lab-vms. ')
param vmsize string = 'Standard_D4s_v3'

@description('Location to deploy current resource')
param location string = resourceGroup().location

@description('The base URI where artifacts required by this template are located including a trailing \'/\'')
param artifactsLocation string = deployment().properties.templateLink.uri

@description('SAS Token for accessing script path')
@secure()
param artifactsLocationSasToken string = ''

@allowed([
  'jenkins-java8.ps1'
  'az-500.ps1'
  'container-lab.ps1'
  'container-vs2019-lab.ps1'
])
@description('Choose script to launch from list of available scripts')
param scriptFilename string = 'jenkins-java8.ps1'

var strname_var = toLower('labvmstg${uniqueString(resourceGroup().id)}')
var scriptUrl = uri(artifactsLocation, concat(scriptFilename, artifactsLocationSasToken))

resource strname 'Microsoft.Storage/storageAccounts@2019-06-01' = {
  name: strname_var
  location: location
  sku: {
    name: 'Standard_LRS'
  }
  kind: 'StorageV2'
  tags: {
    displayName: 'labvm Storage Account'
  }
  properties: {
    accessTier: 'Hot'
  }
}

resource labvm_pip_1 'Microsoft.Network/publicIPAddresses@2019-11-01' = [for i in range(0, vmCount): {
  name: 'labvm-pip-${(i + 1)}'
  location: location
  tags: {
    displayName: 'PublicIPAddress'
  }
  properties: {
    publicIPAllocationMethod: 'Dynamic'
    dnsSettings: {
      domainNameLabel: toLower('${dns_prefix}-${(i + 1)}')
    }
  }
}]

resource labvm_nsg 'Microsoft.Network/networkSecurityGroups@2019-04-01' = {
  name: 'labvm-nsg'
  location: location
  properties: {
    securityRules: [
      {
        name: 'nsgRule1'
        properties: {
          description: 'description'
          protocol: 'Tcp'
          sourcePortRange: '*'
          destinationPortRange: '3389'
          sourceAddressPrefix: '*'
          destinationAddressPrefix: '*'
          access: 'Allow'
          priority: 100
          direction: 'Inbound'
        }
      }
    ]
  }
}

resource labvm_vnet 'Microsoft.Network/virtualNetworks@2019-11-01' = {
  name: 'labvm-vnet'
  location: location
  tags: {
    displayName: 'labvm-vnet'
  }
  properties: {
    addressSpace: {
      addressPrefixes: [
        '30.0.0.0/16'
      ]
    }
    subnets: [
      {
        name: 'labvm-Subnet'
        properties: {
          addressPrefix: '30.0.0.0/24'
          networkSecurityGroup: {
            id: labvm_nsg.id
          }
        }
      }
    ]
  }
}

resource labvm_nic_1 'Microsoft.Network/networkInterfaces@2019-11-01' = [for i in range(0, vmCount): {
  name: 'labvm-nic-${(i + 1)}'
  location: location
  tags: {
    displayName: 'labvm Network Interface'
  }
  properties: {
    ipConfigurations: [
      {
        name: 'ipConfig1'
        properties: {
          privateIPAllocationMethod: 'Dynamic'
          publicIPAddress: {
            id: resourceId('Microsoft.Network/publicIPAddresses', 'labvm-pip-${(i + 1)}')
          }
          subnet: {
            id: resourceId('Microsoft.Network/virtualNetworks/subnets', 'labvm-vnet', 'labvm-Subnet')
          }
        }
      }
    ]
  }
  dependsOn: [
    labvm_pip_1
    labvm_vnet
  ]
}]

resource labvm_1 'Microsoft.Compute/virtualMachines@2019-07-01' = [for i in range(0, vmCount): {
  name: 'labvm-${(i + 1)}'
  location: location
  tags: {
    displayName: 'labvm'
  }
  properties: {
    hardwareProfile: {
      vmSize: vmsize
    }
    osProfile: {
      computerName: 'labvm-${(i + 1)}'
      adminUsername: adminUser
      adminPassword: adminPassword
    }
    storageProfile: {
      imageReference: {
        publisher: 'MicrosoftWindowsServer'
        offer: 'WindowsServer'
        sku: '2019-Datacenter'
        version: 'latest'
      }
      osDisk: {
        name: 'labvm${(i + 1)}OSDisk'
        caching: 'ReadWrite'
        createOption: 'FromImage'
      }
    }
    networkProfile: {
      networkInterfaces: [
        {
          id: resourceId('Microsoft.Network/networkInterfaces', 'labvm-nic-${(i + 1)}')
        }
      ]
    }
    diagnosticsProfile: {
      bootDiagnostics: {
        enabled: true
        storageUri: strname.properties.primaryEndpoints.blob
      }
    }
  }
  dependsOn: [
    strname
    labvm_pip_1
    labvm_nic_1
  ]
}]

resource labvm_1_installScript 'Microsoft.Compute/virtualMachines/extensions@2019-07-01' = [for i in range(0, vmCount): {
  name: 'labvm-${(i + 1)}/installScript'
  location: location
  tags: {
    displayName: 'customScript1 for Windows VM'
  }
  properties: {
    publisher: 'Microsoft.Compute'
    type: 'CustomScriptExtension'
    typeHandlerVersion: '1.10'
    autoUpgradeMinorVersion: true
    settings: {
      fileUris: [
        scriptUrl
      ]
    }
    protectedSettings: {
      commandToExecute: 'powershell -ExecutionPolicy Bypass -file  ${scriptFilename}'
    }
  }
  dependsOn: [
    labvm_1
  ]
}]