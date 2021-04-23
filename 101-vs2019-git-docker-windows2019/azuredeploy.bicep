@description('Unique Storage Account name')
param storagename string = 'labvmstrg${uniqueString(resourceGroup().id)}'

@description('VM DNS Label prefix')
param vm_dns string = 'labvm-${uniqueString(resourceGroup().id)}'

@description('Admin Username for Lab VM')
param adminUser string

@description('Password for admin user')
@secure()
param adminPassword string

@allowed([
  'Standard_D4s_v3'
  'Standard_D8s_v3'
  'Standard_D8s_v4'
])
@description('VM Size for lab-vm')
param vmsize string = 'Standard_D8s_v3'

@description('Location to deploy current resource')
param location string = resourceGroup().location

@description('The base URI where artifacts required by this template are located including a trailing \'/\'')
param artifactsLocation string = deployment().properties.templateLink.uri

@description('SAS Token for accessing script path')
@secure()
param artifactsLocationSasToken string = ''

var scriptUrl = uri(artifactsLocation, 'installscript.ps1${artifactsLocationSasToken}')

resource storagename_resource 'Microsoft.Storage/storageAccounts@2019-06-01' = {
  name: toLower(storagename)
  location: location
  sku: {
    name: 'Standard_LRS'
  }
  kind: 'Storage'
  tags: {
    displayName: 'VS LabVM Storage Account'
  }
}

resource vslab_PublicIP 'Microsoft.Network/publicIPAddresses@2019-11-01' = {
  name: 'vslab-PublicIP'
  location: location
  tags: {
    displayName: 'PublicIPAddress'
  }
  properties: {
    publicIPAllocationMethod: 'Dynamic'
    dnsSettings: {
      domainNameLabel: vm_dns
    }
  }
}

resource vslab_nsg 'Microsoft.Network/networkSecurityGroups@2020-04-01' = {
  name: 'vslab-nsg'
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

resource vslab_VirtualNetwork 'Microsoft.Network/virtualNetworks@2020-04-01' = {
  name: 'vslab-VirtualNetwork'
  location: location
  tags: {
    displayName: 'vslab-VirtualNetwork'
  }
  properties: {
    addressSpace: {
      addressPrefixes: [
        '10.0.0.0/16'
      ]
    }
    subnets: [
      {
        name: 'vslab-vnet-subnet'
        properties: {
          addressPrefix: '10.0.0.0/24'
          networkSecurityGroup: {
            id: vslab_nsg.id
          }
        }
      }
    ]
  }
}

resource vslab_nic 'Microsoft.Network/networkInterfaces@2020-04-01' = {
  name: 'vslab-nic'
  location: location
  tags: {
    displayName: 'VSLab Network Interface'
  }
  properties: {
    ipConfigurations: [
      {
        name: 'ipConfig1'
        properties: {
          privateIPAllocationMethod: 'Dynamic'
          publicIPAddress: {
            id: vslab_PublicIP.id
          }
          subnet: {
            id: resourceId('Microsoft.Network/virtualNetworks/subnets', 'vslab-VirtualNetwork', 'vslab-vnet-subnet')
          }
        }
      }
    ]
  }
  dependsOn: [
    vslab_VirtualNetwork
  ]
}

resource vsLab 'Microsoft.Compute/virtualMachines@2019-07-01' = {
  name: 'vsLab'
  location: location
  tags: {
    displayName: 'VS2019 Lab VM'
  }
  properties: {
    hardwareProfile: {
      vmSize: vmsize
    }
    osProfile: {
      computerName: 'LabVM'
      adminUsername: adminUser
      adminPassword: adminPassword
    }
    storageProfile: {
      imageReference: {
        publisher: 'MicrosoftVisualStudio'
        offer: 'VisualStudio2019latest'
        sku: 'vs-2019-comm-latest-ws2019'
        version: 'latest'
      }
      osDisk: {
        name: 'LabVMOSDisk'
        caching: 'ReadWrite'
        createOption: 'FromImage'
      }
    }
    networkProfile: {
      networkInterfaces: [
        {
          id: vslab_nic.id
        }
      ]
    }
    diagnosticsProfile: {
      bootDiagnostics: {
        enabled: true
        storageUri: reference(resourceId('Microsoft.Storage/storageAccounts/', storagename)).primaryEndpoints.blob
      }
    }
  }
  dependsOn: [
    resourceId('Microsoft.Storage/storageAccounts', storagename)
  ]
}

resource vsLab_installscript1 'Microsoft.Compute/virtualMachines/extensions@2019-07-01' = {
  parent: vsLab
  name: 'installscript1'
  location: location
  tags: {
    displayName: 'Install script for LabVM'
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
      commandToExecute: 'powershell -ExecutionPolicy Bypass -file installscript.ps1 -UserName ${adminUser}'
    }
  }
}

output lab_vm_dns string = vslab_PublicIP.properties.dnsSettings.fqdn