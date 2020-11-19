param artifactsLocation string {
  metadata: {
    description: 'The base URI where artifacts required by this template are located. When the template is deployed using the accompanying scripts, a private location in the subscription will be used and this value will be automatically generated.'
  }
  default: 'https://raw.githubusercontent.com/Azure/azure-quickstart-templates/master/qlik-sense-enterprise'
}
param artifactsLocationSasToken string {
  metadata: {
    description: 'The sasToken required to access _artifactsLocation.  When the template is deployed using the accompanying scripts, a sasToken will be automatically generated.'
  }
  secure: true
  default: ''
}
param virtualMachineName string {
  metadata: {
    description: 'Name of virtual machine to create. Has to be unique in subscription.'
  }
  default: 'qlik-sense'
}
param adminUsername string {
  metadata: {
    description: 'Username for the Virtual Machine.'
  }
}
param adminPassword string {
  metadata: {
    description: 'Password for the Virtual Machine.'
  }
  secure: true
}
param dnsLabelPrefix string {
  metadata: {
    description: 'Unique DNS Name for the Public IP used to access the Virtual Machine.'
  }
}
param qlikSenseVersion string {
  allowed: [
    'Qlik Sense November 2017'
    'Qlik Sense September 2017 Patch 1'
    'Qlik Sense September 2017'
    'Qlik Sense June 2017 Patch 3'
    'Qlik Sense June 2017 Patch 2'
    'Qlik Sense June 2017 Patch 1'
    'Qlik Sense June 2017'
    'Qlik Sense 3.2 SR5'
    'Qlik Sense 3.2 SR4'
  ]
  metadata: {
    description: 'Version of Qlik Sense to provision.'
  }
  default: 'Qlik Sense November 2017'
}
param qlikSenseServiceAccount string {
  metadata: {
    description: 'User to run the Qlik Sense services.'
  }
  default: 'qService'
}
param qlikSenseServiceAccountPassword string {
  minLength: 12
  metadata: {
    description: 'Password for the Qlik Sense service account.'
  }
  secure: true
}
param qlikSenseRepositoryPassword string {
  metadata: {
    description: 'Password for the Qlik Sense Repository user.'
  }
  secure: true
}
param qlikSenseSerial string {
  metadata: {
    description: 'Password for the Qlik Sense Repository user. Replace with your license details to license server during provisioning.'
  }
  default: 'defaultValue'
}
param qlikSenseControl string {
  metadata: {
    description: 'Control key for Qlik Sense license. Replace with your license details to license server during provisioning.'
  }
  secure: true
  default: 'defaultValue'
}
param qlikSenseOrganization string {
  metadata: {
    description: 'Organization owner of license. Replace with your license details to license server during provisioning.'
  }
  default: 'defaultValue'
}
param qlikSenseName string {
  metadata: {
    description: 'Name of licensed organization. Replace with your license details to license server during provisioning.'
  }
  default: 'defaultValue'
}
param virtualMachineSize string {
  allowed: [
    'Standard_DS1_v2'
    'Standard_DS2_v2'
    'Standard_DS3_v2'
    'Standard_DS4_v2'
    'Standard_DS5_v2'
    'Standard_DS11_v2'
    'Standard_DS12_v2'
    'Standard_DS13_v2'
    'Standard_DS14_v2'
    'Standard_DS15_v2'
  ]
  metadata: {
    description: 'Size of VM to be created. Recommended start size is Standard_DS3_V2'
  }
  default: 'Standard_DS3_v2'
}
param windowsOSVersion string {
  allowed: [
    '2012-Datacenter'
    '2012-R2-Datacenter'
    '2016-Datacenter-with-Containers'
    '2016-Datacenter'
  ]
  metadata: {
    description: 'The Windows version for the VM. This will pick a fully patched image of this given Windows version.'
  }
  default: '2016-Datacenter'
}
param location string {
  metadata: {
    description: 'Location for all resources.'
  }
  default: resourceGroup().location
}

var storageAccountName_var = '${uniqueString(resourceGroup().id)}sawinvm'
var nicName_var = 'myVMNic'
var addressPrefix = '10.0.0.0/16'
var subnetName = 'Subnet'
var subnetPrefix = '10.0.0.0/24'
var publicIPAddressName_var = 'myPublicIP'
var OSDiskName = 'osdiskforwindows'
var vhdStorageContainerName = 'vhds'
var vmName_var = virtualMachineName
var virtualNetworkName_var = 'MyVNET'
var networkSecurityGroupName_var = 'qlikSenseSecurityGroup'
var subnetRef = resourceId('Microsoft.Network/virtualNetworks/subnets', virtualNetworkName_var, subnetName)
var scriptFolder = '.'
var scriptInstallFileName = 'qs-install.ps1'
var scriptBootStrapFileName = 'qs-bootstrap.ps1'

resource networkSecurityGroupName 'Microsoft.Network/networkSecurityGroups@2016-03-30' = {
  name: networkSecurityGroupName_var
  location: location
  tags: {
    displayName: networkSecurityGroupName_var
  }
  properties: {
    securityRules: [
      {
        name: 'http'
        properties: {
          description: 'http endpoint'
          protocol: 'Tcp'
          sourcePortRange: '*'
          destinationPortRange: '80'
          sourceAddressPrefix: '*'
          destinationAddressPrefix: '*'
          access: 'Allow'
          priority: 100
          direction: 'Inbound'
        }
      }
      {
        name: 'httpAuth'
        properties: {
          description: 'http Windows Auth endpoint'
          protocol: 'Tcp'
          sourcePortRange: '*'
          destinationPortRange: '4248'
          sourceAddressPrefix: '*'
          destinationAddressPrefix: '*'
          access: 'Allow'
          priority: 1100
          direction: 'Inbound'
        }
      }
      {
        name: 'https'
        properties: {
          description: 'https endpoint'
          protocol: 'Tcp'
          sourcePortRange: '*'
          destinationPortRange: '443'
          sourceAddressPrefix: '*'
          destinationAddressPrefix: '*'
          access: 'Allow'
          priority: 1200
          direction: 'Inbound'
        }
      }
      {
        name: 'httpsAuth'
        properties: {
          description: 'https Windows Auth endpoint'
          protocol: 'Tcp'
          sourcePortRange: '*'
          destinationPortRange: '4244'
          sourceAddressPrefix: '*'
          destinationAddressPrefix: '*'
          access: 'Allow'
          priority: 1300
          direction: 'Inbound'
        }
      }
      {
        name: 'rdp'
        properties: {
          description: 'rdp endpoint'
          protocol: 'Tcp'
          sourcePortRange: '*'
          destinationPortRange: '3389'
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

resource storageAccountName 'Microsoft.Storage/storageAccounts@2016-01-01' = {
  name: storageAccountName_var
  location: location
  sku: {
    name: 'Standard_LRS'
  }
  kind: 'Storage'
  properties: {}
}

resource publicIPAddressName 'Microsoft.Network/publicIPAddresses@2016-03-30' = {
  name: publicIPAddressName_var
  location: location
  properties: {
    publicIPAllocationMethod: 'Dynamic'
    dnsSettings: {
      domainNameLabel: dnsLabelPrefix
    }
  }
}

resource virtualNetworkName 'Microsoft.Network/virtualNetworks@2017-06-01' = {
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
            id: networkSecurityGroupName.id
          }
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

resource vmName 'Microsoft.Compute/virtualMachines@2017-03-30' = {
  name: vmName_var
  location: location
  properties: {
    hardwareProfile: {
      vmSize: virtualMachineSize
    }
    osProfile: {
      computerName: vmName_var
      adminUsername: adminUsername
      adminPassword: adminPassword
    }
    storageProfile: {
      imageReference: {
        publisher: 'MicrosoftWindowsServer'
        offer: 'WindowsServer'
        sku: windowsOSVersion
        version: 'latest'
      }
      osDisk: {
        name: '${vmName_var}_OSDisk'
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
        storageUri: storageAccountName.properties.primaryEndpoints.blob
      }
    }
  }
}

resource vmName_qlikSenseBootstrap 'Microsoft.Compute/virtualMachines/extensions@2016-03-30' = {
  name: '${vmName_var}/qlikSenseBootstrap'
  location: location
  tags: {
    displayName: 'QlikSenseBootstrap'
  }
  properties: {
    publisher: 'Microsoft.Compute'
    type: 'CustomScriptExtension'
    typeHandlerVersion: '1.9'
    autoUpgradeMinorVersion: true
    settings: {
      fileUris: [
        '${artifactsLocation}/${scriptFolder}/${scriptBootStrapFileName}${artifactsLocationSasToken}'
        '${artifactsLocation}/${scriptFolder}/${scriptInstallFileName}${artifactsLocationSasToken}'
      ]
    }
    protectedSettings: {
      commandToExecute: 'powershell -ExecutionPolicy Unrestricted -File ${scriptFolder}/${scriptBootStrapFileName} "${adminUsername}" "${adminPassword}" "${qlikSenseServiceAccount}" "${qlikSenseServiceAccountPassword}" "${qlikSenseRepositoryPassword}" "${qlikSenseVersion}" "${qlikSenseSerial}" "${qlikSenseControl}" "${qlikSenseOrganization}" "${qlikSenseName}" "${artifactsLocation}"'
    }
  }
  dependsOn: [
    vmName
  ]
}

output hostname string = reference(publicIPAddressName_var).dnsSettings.fqdn