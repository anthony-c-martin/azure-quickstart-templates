@description('The name of the VM to create')
param vmName string = 'tfsvm'

@description('The size of the VM to create')
param vmSize string = 'Standard_D4_v3'

@description('The name of the administrator account.  This account must have permissions to domain join the new VM')
param adminUsername string

@description('The password for the Administrator account')
@secure()
param adminPassword string

@description('The FQDN of the existing Active Directory Domain')
param existingDomainName string

@description('Specifies an organizational unit (OU) for the domain account. Enter the full distinguished name of the OU in quotation marks. Example: \'OU=testOU; DC=domain; DC=Domain; DC=com\'')
param OUPath string = ''

@description('The name of the Virtual Network to connect to')
param existingVnetName string

@description('Resource Group Name for the Virtual Network to connect to')
param existingVnetResourceGroupName string

@description('The name of the subnet to connect to')
param existingSubnetName string

@description('The name of the SQL server to use for TFS')
param existingSqlInstance string

@description('The base URI where artifacts required by this template are located. When the template is deployed using the accompanying scripts, a private location in the subscription will be used and this value will be automatically generated.')
param artifactsLocation string = 'https://raw.githubusercontent.com/Azure/azure-quickstart-templates/master/tfs-standard-existingsql/'

@description('The sasToken required to access _artifactsLocation.  When the template is deployed using the accompanying scripts, a sasToken will be automatically generated.')
@secure()
param artifactsLocationSasToken string = ''

@description('Location for all resources.')
param location string = resourceGroup().location

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

resource vmName_resource 'Microsoft.Compute/virtualMachines@2019-03-01' = {
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
  parent: vmName_resource
  name: 'JoinDomain'
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
}

resource vmName_ConfigureTfs 'Microsoft.Compute/virtualMachines/extensions@2019-03-01' = {
  parent: vmName_resource
  name: 'ConfigureTfs'
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