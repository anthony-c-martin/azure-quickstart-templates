@minLength(3)
@maxLength(3)
@description('SAP System ID.')
param sapSystemId string = 'DEV'

@allowed([
  'Windows Server 2012 Datacenter'
  'Windows Server 2012 R2 Datacenter'
  'Windows Server 2016 Datacenter'
  'SLES 12'
  'SLES 12 BYOS'
  'RHEL 7'
  'Oracle Linux 7'
])
@description('The type of the operating system you want to deploy.')
param osType string = 'Windows Server 2016 Datacenter'

@allowed([
  'Demo'
  'Small < 30.000 SAPS'
  'Medium < 70.000 SAPS'
  'Large < 180.000 SAPS'
  'X-Large < 250.000 SAPS'
])
@description('The size of the SAP System you want to deploy.')
param sapSystemSize string = 'Small < 30.000 SAPS'

@allowed([
  'HA'
  'Not HA'
])
@description('Determines whether this is a high available deployment or not. A HA deployment contains multiple instances of single point of failures.')
param systemAvailability string = 'Not HA'

@description('Username for the Virtual Machine.')
param adminUsername string

@allowed([
  'password'
  'sshPublicKey'
])
@description('Type of authentication to use on the Virtual Machine.')
param authenticationType string = 'password'

@description('Password or ssh key for the Virtual Machine.')
@secure()
param adminPasswordOrKey string

@description('The id of the subnet you want to use.')
param subnetId string = ''

@description('Location for all resources.')
param location string = resourceGroup().location

@description('The base URI where artifacts required by this template are located. When the template is deployed using the accompanying scripts, a private location in the subscription will be used and this value will be automatically generated.')
param artifactsLocation string = 'https://raw.githubusercontent.com/Azure/azure-quickstart-templates/master/sap-3-tier-marketplace-image-multi-sid-apps-md/'

@description('The sasToken required to access _artifactsLocation.  When the template is deployed using the accompanying scripts, a sasToken will be automatically generated.')
@secure()
param artifactsLocationSasToken string = ''

var images = {
  'Windows Server 2012 Datacenter': {
    sku: '2012-Datacenter'
    offer: 'WindowsServer'
    publisher: 'MicrosoftWindowsServer'
    version: 'latest'
    OSType: 'Windows'
    Plan: {}
    UsePlan: false
  }
  'Windows Server 2012 R2 Datacenter': {
    sku: '2012-R2-Datacenter'
    offer: 'WindowsServer'
    publisher: 'MicrosoftWindowsServer'
    version: 'latest'
    OSType: 'Windows'
    Plan: {}
    UsePlan: false
  }
  'Windows Server 2016 Datacenter': {
    sku: '2016-Datacenter'
    offer: 'WindowsServer'
    publisher: 'MicrosoftWindowsServer'
    version: 'latest'
    OSType: 'Windows'
    Plan: {}
    UsePlan: false
  }
  'SLES 12': {
    sku: '12-SP3'
    offer: 'SLES-SAP'
    publisher: 'SUSE'
    version: 'latest'
    OSType: 'Linux'
    Plan: {}
    UsePlan: false
  }
  'SLES 12 BYOS': {
    sku: '12-SP3'
    offer: 'SLES-SAP-BYOS'
    publisher: 'SUSE'
    version: 'latest'
    OSType: 'Linux'
    Plan: {}
    UsePlan: false
  }
  'RHEL 7': {
    sku: '7.4'
    offer: 'RHEL'
    publisher: 'RedHat'
    version: 'latest'
    OSType: 'Linux'
    Plan: {}
    UsePlan: false
  }
  'Oracle Linux 7': {
    sku: '7.3'
    offer: 'Oracle-Linux'
    publisher: 'Oracle'
    version: 'latest'
    OSType: 'Linux'
    Plan: {}
    UsePlan: false
  }
}
var internalOSType = images[osType].OSType
var linuxConfiguration = {
  disablePasswordAuthentication: true
  ssh: {
    publicKeys: [
      {
        path: '/home/${adminUsername}/.ssh/authorized_keys'
        keyData: adminPasswordOrKey
      }
    ]
  }
}
var csExtension = {
  Windows: {
    Publisher: 'Microsoft.Compute'
    Name: 'CustomScriptExtension'
    Version: '1.7'
    script: uri(artifactsLocation, 'scripts/noop.ps1${artifactsLocationSasToken}')
    scriptCall: 'powershell.exe -ExecutionPolicy bypass -File noop.ps1'
  }
  Linux: {
    Publisher: 'Microsoft.Azure.Extensions'
    Name: 'CustomScript'
    Version: '2.0'
    script: uri(artifactsLocation, 'scripts/noop.sh${artifactsLocationSasToken}')
    scriptCall: 'sh noop.sh'
  }
}
var cseExtPublisher = csExtension[internalOSType].Publisher
var cseExtName = csExtension[internalOSType].Name
var cseExtVersion = csExtension[internalOSType].Version
var csExtensionScript = csExtension[internalOSType].script
var csExtensionscriptCall = csExtension[internalOSType].scriptCall
var vmSizes = {
  Demo: {
    'Not HA': {
      diserversize: 'Standard_DS2_v2'
      diservercount: 1
    }
    HA: {
      diserversize: 'Standard_DS2_v2'
      diservercount: 2
    }
  }
  'Small < 30.000 SAPS': {
    'Not HA': {
      diserversize: 'Standard_DS13_v2'
      diservercount: 1
    }
    HA: {
      diserversize: 'Standard_DS13_v2'
      diservercount: 2
    }
  }
  'Medium < 70.000 SAPS': {
    'Not HA': {
      diserversize: 'Standard_DS13_v2'
      diservercount: 4
    }
    HA: {
      diserversize: 'Standard_DS13_v2'
      diservercount: 4
    }
  }
  'Large < 180.000 SAPS': {
    'Not HA': {
      diserversize: 'Standard_DS14_v2'
      diservercount: 6
    }
    HA: {
      diserversize: 'Standard_DS14_v2'
      diservercount: 6
    }
  }
  'X-Large < 250.000 SAPS': {
    'Not HA': {
      diserversize: 'Standard_DS14_v2'
      diservercount: 10
    }
    HA: {
      diserversize: 'Standard_DS14_v2'
      diservercount: 10
    }
  }
}
var divmSize = vmSizes[sapSystemSize][systemAvailability].diserversize
var divmCount = vmSizes[sapSystemSize][systemAvailability].diservercount
var sidlower = toLower(sapSystemId)
var publicIpNameDB_var = '${sidlower}-pip-di'
var vnetName_var = '${sidlower}-vnet'
var subnetName = 'Subnet'
var subnets = {
  true: resourceId('Microsoft.Network/virtualNetworks/subnets', vnetName_var, subnetName)
  false: subnetId
}
var selectedSubnetId = subnets[string((length(subnetId) == 0))]
var nsgName_var = '${sidlower}-nsg'
var vmName = sidlower
var osSecurityRules = {
  Windows: [
    {
      name: 'RDP'
      properties: {
        description: 'Allow RDP Subnet'
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
  Linux: [
    {
      name: 'SSH'
      properties: {
        description: 'Allow SSH Subnet'
        protocol: 'Tcp'
        sourcePortRange: '*'
        destinationPortRange: '22'
        sourceAddressPrefix: '*'
        destinationAddressPrefix: '*'
        access: 'Allow'
        priority: 100
        direction: 'Inbound'
      }
    }
  ]
}
var selectedSecurityRules = osSecurityRules[internalOSType]
var avSetNameDI_var = '${sidlower}-avset-di'
var nicNameDI_var = '${sidlower}-nic-di'
var vmNameDI_var = '${vmName}-di'

resource nsgName 'Microsoft.Network/networkSecurityGroups@2018-04-01' = if (length(subnetId) == 0) {
  name: concat(nsgName_var)
  location: location
  properties: {
    securityRules: selectedSecurityRules
  }
}

resource vnetName 'Microsoft.Network/virtualNetworks@2018-04-01' = if (length(subnetId) == 0) {
  name: vnetName_var
  location: location
  properties: {
    addressSpace: {
      addressPrefixes: [
        '10.0.0.0/16'
      ]
    }
    subnets: [
      {
        name: subnetName
        properties: {
          addressPrefix: '10.0.0.0/24'
          networkSecurityGroup: {
            id: nsgName.id
          }
        }
      }
    ]
  }
}

resource avSetNameDI 'Microsoft.Compute/availabilitySets@2017-03-30' = {
  name: avSetNameDI_var
  location: location
  sku: {
    name: 'Aligned'
  }
  properties: {
    platformFaultDomainCount: 3
    platformUpdateDomainCount: 20
  }
}

resource publicIpNameDB 'Microsoft.Network/publicIPAddresses@2018-04-01' = [for i in range(0, divmCount): if (length(subnetId) == 0) {
  name: '${publicIpNameDB_var}-${i}'
  location: location
  properties: {
    publicIPAllocationMethod: 'Dynamic'
  }
  dependsOn: [
    vnetName
  ]
}]

resource nicNameDI 'Microsoft.Network/networkInterfaces@2017-06-01' = [for i in range(0, divmCount): {
  name: '${nicNameDI_var}-${i}'
  location: location
  properties: {
    ipConfigurations: [
      {
        name: 'ipconfig1'
        properties: {
          privateIPAllocationMethod: 'Dynamic'
          publicIPAddress: ((length(subnetId) == 0) ? json('{"id": "${resourceId('Microsoft.Network/publicIPAddresses', '${publicIpNameDB_var}-${i}')}"}') : json('null'))
          subnet: {
            id: selectedSubnetId
          }
        }
      }
    ]
  }
  dependsOn: [
    publicIpNameDB
    vnetName
  ]
}]

resource vmNameDI 'Microsoft.Compute/virtualMachines@2017-03-30' = [for i in range(0, divmCount): {
  name: '${vmNameDI_var}-${i}'
  location: location
  properties: {
    availabilitySet: {
      id: avSetNameDI.id
    }
    hardwareProfile: {
      vmSize: divmSize
    }
    osProfile: {
      computerName: '${vmNameDI_var}-${i}'
      adminUsername: adminUsername
      adminPassword: adminPasswordOrKey
      linuxConfiguration: ((authenticationType == 'password') ? json('null') : linuxConfiguration)
    }
    storageProfile: {
      imageReference: {
        publisher: images[osType].publisher
        offer: images[osType].offer
        sku: images[osType].sku
        version: images[osType].version
      }
      osDisk: {
        name: '${vmNameDI_var}-${i}-osdisk'
        caching: 'ReadWrite'
        createOption: 'FromImage'
        managedDisk: {
          storageAccountType: 'Premium_LRS'
        }
      }
      dataDisks: [for j in range(0, 1): {
        lun: 0
        createOption: 'Empty'
        diskSizeGB: 128
      }]
    }
    networkProfile: {
      networkInterfaces: [
        {
          id: resourceId('Microsoft.Network/networkInterfaces', '${nicNameDI_var}-${i}')
        }
      ]
    }
  }
  dependsOn: [
    nicNameDI
    avSetNameDI
  ]
}]

resource vmNameDI_cseExtName 'Microsoft.Compute/virtualMachines/extensions@2017-12-01' = [for i in range(0, divmCount): {
  name: '${vmNameDI_var}-${i}/${cseExtName}'
  location: location
  properties: {
    publisher: cseExtPublisher
    type: cseExtName
    typeHandlerVersion: cseExtVersion
    autoUpgradeMinorVersion: true
    settings: {
      fileUris: [
        csExtensionScript
      ]
      commandToExecute: csExtensionscriptCall
    }
  }
  dependsOn: [
    vmNameDI
  ]
}]