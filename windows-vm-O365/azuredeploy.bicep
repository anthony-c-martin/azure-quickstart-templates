param vmName string {
  metadata: {
    description: 'Local name for the VM can be whatever you want'
  }
  default: 'O365VM'
}
param vmAdminUserName string {
  metadata: {
    description: 'VM admin user name'
  }
}
param vmAdminPassword string {
  metadata: {
    description: 'VM admin password. The supplied password must be between 8-123 characters long and must satisfy at least 3 of password complexity requirements from the following: 1) Contains an uppercase character 2) Contains a lowercase character 3) Contains a numeric digit 4) Contains a special character.'
  }
  secure: true
}
param vmSize string {
  metadata: {
    description: 'Desired Size of the VM.'
  }
  default: 'Standard_DS2'
}
param vmOSVersion string {
  allowed: [
    'Windows-10-N-x64'
    'Win7-SP1-Ent-N-x64'
    'Win81-Ent-N-x64'
  ]
  metadata: {
    description: 'Which version of Windows would like to deploy'
  }
  default: 'Windows-10-N-x64'
}
param vmOsSkuVersion string {
  metadata: {
    description: 'VM Image SKU Version'
  }
  default: '2019.10.14'
}
param dnsLabelPrefix string {
  metadata: {
    description: 'DNS Label for the Public IP. Must be lowercase. It should match with the following regular expression: ^[a-z][a-z0-9-]{1,61}[a-z0-9]$ or it will raise an error.'
  }
}
param officeVersion string {
  allowed: [
    'Office2016'
    'Office2013'
  ]
  metadata: {
    description: 'Which version of Office would you would like to deploy'
  }
  default: 'Office2016'
}
param setupOfficeScriptFileName string {
  metadata: {
    description: 'PowerShell script name to execute'
  }
  default: 'DeployO365SilentWithVersion.ps1'
}
param artifactsLocation string {
  metadata: {
    description: 'The base URI where artifacts required by this template are located. When the template is deployed using the accompanying scripts, a private location in the subscription will be used and this value will be automatically generated.'
  }
  default: 'https://raw.githubusercontent.com/Azure/azure-quickstart-templates/master/windows-vm-O365/'
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

var vnet01Prefix = '10.0.0.0/16'
var vnet01Subnet1Name = 'Subnet-1'
var vnet01Subnet1Prefix = '10.0.0.0/24'
var vmImagePublisher = 'MicrosoftVisualStudio'
var vmImageOffer = 'Windows'
var vmSubnetRef = resourceId('Microsoft.Network/virtualNetworks/subnets', vnetName_var, vnet01Subnet1Name)
var vmNicName_var = '${vmName}NetworkInterface'
var vmIP01Name_var = 'VMIP01'
var vnetName_var = 'VNet01'

resource vnetName 'Microsoft.Network/virtualNetworks@2019-06-01' = {
  name: vnetName_var
  location: location
  tags: {
    displayName: 'variables(\'vnetName\')'
  }
  properties: {
    addressSpace: {
      addressPrefixes: [
        vnet01Prefix
      ]
    }
    subnets: [
      {
        name: vnet01Subnet1Name
        properties: {
          addressPrefix: vnet01Subnet1Prefix
        }
      }
    ]
  }
}

resource vmNicName 'Microsoft.Network/networkInterfaces@2019-06-01' = {
  name: vmNicName_var
  location: location
  tags: {
    displayName: 'VMNic01'
  }
  properties: {
    ipConfigurations: [
      {
        name: 'ipconfig1'
        properties: {
          privateIPAllocationMethod: 'Dynamic'
          subnet: {
            id: vmSubnetRef
          }
          publicIPAddress: {
            id: vmIP01Name.id
          }
        }
      }
    ]
  }
  dependsOn: [
    vnetName
  ]
}

resource vmName_res 'Microsoft.Compute/virtualMachines@2019-03-01' = {
  name: vmName
  location: location
  tags: {
    displayName: 'VM01'
  }
  properties: {
    hardwareProfile: {
      vmSize: vmSize
    }
    osProfile: {
      computerName: vmName
      adminUsername: vmAdminUserName
      adminPassword: vmAdminPassword
    }
    storageProfile: {
      imageReference: {
        publisher: vmImagePublisher
        offer: vmImageOffer
        sku: vmOSVersion
        version: vmOsSkuVersion
      }
      osDisk: {
        name: '${vmName}_OSDisk'
        caching: 'ReadWrite'
        createOption: 'FromImage'
      }
    }
    networkProfile: {
      networkInterfaces: [
        {
          id: vmNicName.id
        }
      ]
    }
  }
}

resource vmName_SetupOffice 'Microsoft.Compute/virtualMachines/extensions@2019-03-01' = {
  name: '${vmName}/SetupOffice'
  location: location
  tags: {
    displayName: 'SetupOffice'
  }
  properties: {
    publisher: 'Microsoft.Compute'
    type: 'CustomScriptExtension'
    typeHandlerVersion: '1.9'
    autoUpgradeMinorVersion: true
    settings: {
      fileUris: [
        uri(artifactsLocation, 'scripts/${setupOfficeScriptFileName}${artifactsLocationSasToken}')
        'https://raw.githubusercontent.com/officedev/Office-IT-Pro-Deployment-Scripts/master/Office-ProPlus-Deployment/Deploy-OfficeClickToRun/DefaultConfiguration.xml'
        'https://raw.githubusercontent.com/officedev/Office-IT-Pro-Deployment-Scripts/master/Office-ProPlus-Deployment/Deploy-OfficeClickToRun/Office2013Setup.exe'
        'https://raw.githubusercontent.com/officedev/Office-IT-Pro-Deployment-Scripts/master/Office-ProPlus-Deployment/Deploy-OfficeClickToRun/Office2016Setup.exe'
        'https://raw.githubusercontent.com/officedev/Office-IT-Pro-Deployment-Scripts/master/Office-ProPlus-Deployment/Deploy-OfficeClickToRun/Edit-OfficeConfigurationFile.ps1'
        'https://raw.githubusercontent.com/officedev/Office-IT-Pro-Deployment-Scripts/master/Office-ProPlus-Deployment/Deploy-OfficeClickToRun/Generate-ODTConfigurationXML.ps1'
        'https://raw.githubusercontent.com/officedev/Office-IT-Pro-Deployment-Scripts/master/Office-ProPlus-Deployment/Deploy-OfficeClickToRun/Install-OfficeClickToRun.ps1'
      ]
      commandToExecute: 'powershell -ExecutionPolicy bypass -File ${setupOfficeScriptFileName} -OfficeVersion ${officeVersion}'
    }
  }
  dependsOn: [
    vmName_res
  ]
}

resource vmIP01Name 'Microsoft.Network/publicIPAddresses@2019-06-01' = {
  name: vmIP01Name_var
  location: location
  tags: {
    displayName: 'VMIP01'
  }
  properties: {
    publicIPAllocationMethod: 'Dynamic'
    dnsSettings: {
      domainNameLabel: dnsLabelPrefix
    }
  }
}