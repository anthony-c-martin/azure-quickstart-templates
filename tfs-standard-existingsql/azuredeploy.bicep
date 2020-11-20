param vmName string {
  metadata: {
    description: 'The name of the VM to create'
  }
  default: 'tfsvm'
}
param vmSize string {
  metadata: {
    description: 'The size of the VM to create'
  }
  default: 'Standard_D4_v3'
}
param adminUsername string {
  metadata: {
    description: 'The name of the administrator account.  This account must have permissions to domain join the new VM'
  }
}
param adminPassword string {
  metadata: {
    description: 'The password for the Administrator account'
  }
  secure: true
}
param existingDomainName string {
  metadata: {
    description: 'The FQDN of the existing Active Directory Domain'
  }
}
param OUPath string {
  metadata: {
    description: 'Specifies an organizational unit (OU) for the domain account. Enter the full distinguished name of the OU in quotation marks. Example: \'OU=testOU; DC=domain; DC=Domain; DC=com\''
  }
  default: ''
}
param existingVnetName string {
  metadata: {
    description: 'The name of the Virtual Network to connect to'
  }
}
param existingVnetResourceGroupName string {
  metadata: {
    description: 'Resource Group Name for the Virtual Network to connect to'
  }
}
param existingSubnetName string {
  metadata: {
    description: 'The name of the subnet to connect to'
  }
}
param existingSqlInstance string {
  metadata: {
    description: 'The name of the SQL server to use for TFS'
  }
}
param artifactsLocation string {
  metadata: {
    description: 'The base URI where artifacts required by this template are located. When the template is deployed using the accompanying scripts, a private location in the subscription will be used and this value will be automatically generated.'
  }
  default: 'https://raw.githubusercontent.com/Azure/azure-quickstart-templates/master/tfs-standard-existingsql/'
}
param artifactsLocationSasToken string {
  metadata: {
    description: 'The sasToken required to access _artifactsLocation.  When the template is deployed using the accompanying scripts, a sasToken will be automatically generated.'
  }
  secure: true
  default: ''
}
param location string {
  metadata: {
    description: 'Location for all resources.'
  }
  default: resourceGroup().location
}

var networkInterfaceName_var = '${vmName}nic'
var subnetRef = resourceId(existingVnetResourceGroupName, 'Microsoft.Network/virtualNetworks/subnets', existingVnetName, existingSubnetName)

resource networkInterfaceName 'Microsoft.Network/networkInterfaces@2019-09-01' = {
  name: networkInterfaceName_var
  location: location
  properties: {
    ipConfigurations: [
      {
        name: 'ipconfig1'
        properties: {
          privateIPAllocationMethod: 'Dynamic'
          subnet: {
            id: subnetRef
          }
        }
      }
    ]
  }
}

resource vmName_res 'Microsoft.Compute/virtualMachines@2019-03-01' = {
  name: vmName
  location: location
  properties: {
    hardwareProfile: {
      vmSize: vmSize
    }
    osProfile: {
      computerName: vmName
      adminUsername: adminUsername
      adminPassword: adminPassword
    }
    storageProfile: {
      imageReference: {
        publisher: 'MicrosoftWindowsServer'
        offer: 'WindowsServer'
        sku: '2016-Datacenter'
        version: 'latest'
      }
      osDisk: {
        name: 'tfsManagedOSDisk'
        caching: 'ReadWrite'
        createOption: 'FromImage'
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

resource vmName_JoinDomain 'Microsoft.Compute/virtualMachines/extensions@2019-03-01' = {
  name: '${vmName}/JoinDomain'
  location: location
  properties: {
    publisher: 'Microsoft.Compute'
    type: 'JsonADDomainExtension'
    typeHandlerVersion: '1.3'
    autoUpgradeMinorVersion: true
    settings: {
      Name: existingDomainName
      OUPath: OUPath
      User: '${existingDomainName}\\${adminUsername}'
      Restart: 'true'
      Options: '3'
    }
    protectedSettings: {
      Password: adminPassword
    }
  }
  dependsOn: [
    vmName_res
  ]
}

resource vmName_ConfigureTfs 'Microsoft.Compute/virtualMachines/extensions@2019-03-01' = {
  name: '${vmName}/ConfigureTfs'
  location: location
  tags: {
    displayName: 'Configure TFS'
  }
  properties: {
    publisher: 'Microsoft.Compute'
    type: 'CustomScriptExtension'
    typeHandlerVersion: '1.9'
    autoUpgradeMinorVersion: true
    settings: {
      fileUris: [
        uri(artifactsLocation, 'ConfigureTfsRemoteSql.ps1${artifactsLocationSasToken}')
      ]
    }
    protectedSettings: {
      commandToExecute: 'powershell -ExecutionPolicy Unrestricted -File ConfigureTfsRemoteSql.ps1 ${existingSqlInstance} ${existingDomainName}\\${adminUsername} ${adminPassword}'
    }
  }
  dependsOn: [
    vmName_JoinDomain
  ]
}