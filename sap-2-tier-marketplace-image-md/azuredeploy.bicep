@minLength(3)
@maxLength(3)
@description('SAP System ID.')
param sapSystemId string = 'DEQ'

@allowed([
  'Windows Server 2012 Datacenter'
  'Windows Server 2012 R2 Datacenter'
  'Windows Server 2016 Datacenter'
  'SLES 12'
  'RHEL 7'
  'Oracle Linux 7'
])
@description('The type of the operating system you want to deploy.')
param osType string = 'Windows Server 2016 Datacenter'

@allowed([
  'SQL'
  'HANA'
  'other'
])
@description('The type of the database')
param dbtype string = 'other'

@allowed([
  'Demo'
  'Small < 2.000 SAPS'
  'Medium < 9.000 SAPS'
  'Large < 18.000 SAPS'
  'X-Large < 40.000 SAPS'
])
@description('The size of the SAP System you want to deploy.')
param sapSystemSize string = 'Small < 2.000 SAPS'

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

@minValue(0)
@maxValue(3)
@description('Zone number. Set to 0 if you do not want to use Availability Zones')
param availabilityZone int = 0

@description('Location for all resources.')
param location string = resourceGroup().location

@description('The base URI where artifacts required by this template are located. When the template is deployed using the accompanying scripts, a private location in the subscription will be used and this value will be automatically generated.')
param artifactsLocation string = 'https://raw.githubusercontent.com/Azure/azure-quickstart-templates/master/sap-2-tier-marketplace-image-md/'

@description('The sasToken required to access _artifactsLocation.  When the template is deployed using the accompanying scripts, a sasToken will be automatically generated.')
@secure()
param artifactsLocationSasToken string = ''

var selectedZones = ((availabilityZone == 0) ? json('null') : array(availabilityZone))
var images = {
  'Windows Server 2012 Datacenter': {
    sku: '2012-Datacenter'
    offer: 'WindowsServer'
    publisher: 'MicrosoftWindowsServer'
    OSType: 'Windows'
  }
  'Windows Server 2012 R2 Datacenter': {
    sku: '2012-R2-Datacenter'
    offer: 'WindowsServer'
    publisher: 'MicrosoftWindowsServer'
    OSType: 'Windows'
  }
  'Windows Server 2016 Datacenter': {
    sku: '2016-Datacenter'
    offer: 'WindowsServer'
    publisher: 'MicrosoftWindowsServer'
    OSType: 'Windows'
  }
  'SLES 12': {
    sku: '12-SP3'
    offer: 'SLES-SAP'
    publisher: 'SUSE'
    OSType: 'Linux'
  }
  'RHEL 7': {
    sku: '7.5'
    offer: 'RHEL-SAP'
    publisher: 'RedHat'
    OSType: 'Linux'
  }
  'Oracle Linux 7': {
    sku: '7.5'
    offer: 'Oracle-Linux'
    publisher: 'Oracle'
    OSType: 'Linux'
  }
}
var internalOSType = images[osType].OSType
var csExtension = {
  Windows: {
    Publisher: 'Microsoft.Compute'
    Name: 'CustomScriptExtension'
    Version: '1.7'
    script: uri(artifactsLocation, 'scripts/diskConfig.ps1${artifactsLocationSasToken}')
    scriptCall: 'powershell.exe -ExecutionPolicy bypass -File diskConfig.ps1'
  }
  Linux: {
    Publisher: 'Microsoft.Azure.Extensions'
    Name: 'CustomScript'
    Version: '2.0'
    script: uri(artifactsLocation, 'scripts/diskConfig.sh${artifactsLocationSasToken}')
    scriptCall: 'sh diskConfig.sh'
  }
}
var sizes = {
  Demo: {
    HANA: {
      vmSize: 'Standard_E4s_v3'
      disks: [
        {
          lun: 0
          caching: 'ReadOnly'
          createOption: 'Empty'
          diskSizeGB: 128
        }
        {
          lun: 1
          caching: 'ReadOnly'
          createOption: 'Empty'
          diskSizeGB: 128
        }
        {
          lun: 2
          caching: 'None'
          createOption: 'Empty'
          diskSizeGB: 128
        }
        {
          lun: 3
          caching: 'None'
          createOption: 'Empty'
          diskSizeGB: 128
        }
        {
          lun: 4
          caching: 'ReadOnly'
          createOption: 'Empty'
          diskSizeGB: 128
        }
        {
          lun: 5
          caching: 'ReadOnly'
          createOption: 'Empty'
          diskSizeGB: 128
        }
        {
          lun: 6
          caching: 'ReadOnly'
          createOption: 'Empty'
          diskSizeGB: 128
        }
        {
          lun: 7
          caching: 'ReadOnly'
          createOption: 'Empty'
          diskSizeGB: 128
        }
      ]
      scriptArguments: {
        Linux: '-luns \'0,1#2,3#4#5#6,7\' -names \'data#log#shared#usrsap#backup\' -paths \'/hana/data#/hana/log#/hana/shared#/usr/sap#/hana/backup\'  -sizes \'100#100#100#100#100\''
      }
      useFastNetwork: false
    }
    SQL: {
      vmSize: 'Standard_E2s_v3'
      disks: [
        {
          lun: 0
          caching: 'ReadOnly'
          createOption: 'Empty'
          diskSizeGB: 128
        }
        {
          lun: 1
          caching: 'ReadOnly'
          createOption: 'Empty'
          diskSizeGB: 128
        }
      ]
      scriptArguments: {
        Windows: '-luns "0#1" -names "data#sap" -paths "C:\\sql\\data,C:\\sql\\log#S"  -sizes "70,100#100"'
      }
      useFastNetwork: false
    }
    other: {
      vmSize: 'Standard_E2s_v3'
      disks: [
        {
          lun: 0
          caching: 'ReadOnly'
          createOption: 'Empty'
          diskSizeGB: 128
        }
        {
          lun: 1
          caching: 'ReadOnly'
          createOption: 'Empty'
          diskSizeGB: 128
        }
      ]
      scriptArguments: {
        Linux: '-luns \'0\' -names \'usrsap\' -paths \'/usr/sap\'  -sizes \'100\''
        Windows: '-luns "0" -names "sap" -paths "S"  -sizes "100"'
      }
      useFastNetwork: false
    }
  }
  'Small < 2.000 SAPS': {
    HANA: {
      vmSize: 'Standard_E32s_v3'
      disks: [
        {
          lun: 0
          caching: 'ReadOnly'
          createOption: 'Empty'
          diskSizeGB: 512
        }
        {
          lun: 1
          caching: 'ReadOnly'
          createOption: 'Empty'
          diskSizeGB: 512
        }
        {
          lun: 2
          caching: 'ReadOnly'
          createOption: 'Empty'
          diskSizeGB: 512
        }
        {
          lun: 3
          caching: 'ReadOnly'
          createOption: 'Empty'
          diskSizeGB: 512
        }
        {
          lun: 4
          caching: 'ReadOnly'
          createOption: 'Empty'
          diskSizeGB: 64
        }
        {
          lun: 5
          caching: 'None'
          createOption: 'Empty'
          diskSizeGB: 512
        }
      ]
      scriptArguments: {
        Linux: '-luns \'0,1,2#3#4#5\' -names \'datalog#shared#usrsap#backup\' -paths \'/hana/data,/hana/log#/hana/shared#/usr/sap#/hana/backup\' -sizes \'70,100#100#100#100\''
      }
      useFastNetwork: true
    }
    SQL: {
      vmSize: 'Standard_D4s_v3'
      disks: [
        {
          lun: 0
          caching: 'None'
          createOption: 'Empty'
          diskSizeGB: 512
        }
        {
          lun: 1
          caching: 'None'
          createOption: 'Empty'
          diskSizeGB: 512
        }
        {
          lun: 2
          caching: 'None'
          createOption: 'Empty'
          diskSizeGB: 512
        }
        {
          lun: 3
          caching: 'None'
          createOption: 'Empty'
          diskSizeGB: 512
        }
        {
          lun: 4
          caching: 'None'
          createOption: 'Empty'
          diskSizeGB: 512
        }
        {
          lun: 5
          caching: 'None'
          createOption: 'Empty'
          diskSizeGB: 128
        }
      ]
      scriptArguments: {
        Windows: '-luns "0,1,2,3#4#5" -names "data#log#sap" -paths "C:\\sql\\data#C:\\sql\\log#S"  -sizes "100#100#100"'
      }
      useFastNetwork: true
    }
    other: {
      vmSize: 'Standard_D4s_v3'
      disks: [
        {
          lun: 0
          caching: 'ReadOnly'
          createOption: 'Empty'
          diskSizeGB: 128
        }
        {
          lun: 1
          caching: 'ReadOnly'
          createOption: 'Empty'
          diskSizeGB: 128
        }
      ]
      scriptArguments: {
        Linux: '-luns \'0\' -names \'usrsap\' -paths \'/usr/sap\'  -sizes \'100\''
        Windows: '-luns "0" -names "sap" -paths "S"  -sizes "100"'
      }
      useFastNetwork: true
    }
  }
  'Medium < 9.000 SAPS': {
    HANA: {
      vmSize: 'Standard_E64s_v3'
      disks: [
        {
          lun: 0
          caching: 'ReadOnly'
          createOption: 'Empty'
          diskSizeGB: 512
        }
        {
          lun: 1
          caching: 'ReadOnly'
          createOption: 'Empty'
          diskSizeGB: 512
        }
        {
          lun: 2
          caching: 'ReadOnly'
          createOption: 'Empty'
          diskSizeGB: 512
        }
        {
          lun: 3
          caching: 'ReadOnly'
          createOption: 'Empty'
          diskSizeGB: 512
        }
        {
          lun: 4
          caching: 'ReadOnly'
          createOption: 'Empty'
          diskSizeGB: 64
        }
        {
          lun: 5
          caching: 'None'
          createOption: 'Empty'
          diskSizeGB: 1024
        }
      ]
      scriptArguments: {
        Linux: '-luns \'0,1,2#3#4#5\' -names \'datalog#shared#usrsap#backup\' -paths \'/hana/data,/hana/log#/hana/shared#/usr/sap#/hana/backup\' -sizes \'70,100#100#100#100\''
      }
      useFastNetwork: true
    }
    SQL: {
      vmSize: 'Standard_D32s_v3'
      disks: [
        {
          lun: 0
          caching: 'None'
          createOption: 'Empty'
          diskSizeGB: 512
        }
        {
          lun: 1
          caching: 'None'
          createOption: 'Empty'
          diskSizeGB: 512
        }
        {
          lun: 2
          caching: 'None'
          createOption: 'Empty'
          diskSizeGB: 512
        }
        {
          lun: 3
          caching: 'None'
          createOption: 'Empty'
          diskSizeGB: 512
        }
        {
          lun: 4
          caching: 'None'
          createOption: 'Empty'
          diskSizeGB: 512
        }
        {
          lun: 5
          caching: 'None'
          createOption: 'Empty'
          diskSizeGB: 512
        }
        {
          lun: 6
          caching: 'None'
          createOption: 'Empty'
          diskSizeGB: 512
        }
        {
          lun: 7
          caching: 'None'
          createOption: 'Empty'
          diskSizeGB: 512
        }
        {
          lun: 8
          caching: 'None'
          createOption: 'Empty'
          diskSizeGB: 128
        }
      ]
      scriptArguments: {
        Windows: '-luns "0,1,2,3,4,5,6#7#8" -names "data#log#sap" -paths "C:\\sql\\data#C:\\sql\\log#S"  -sizes "100#100#100"'
      }
      useFastNetwork: true
    }
    other: {
      vmSize: 'Standard_D32s_v3'
      disks: [
        {
          lun: 0
          caching: 'ReadOnly'
          createOption: 'Empty'
          diskSizeGB: 128
        }
        {
          lun: 1
          caching: 'ReadOnly'
          createOption: 'Empty'
          diskSizeGB: 128
        }
      ]
      scriptArguments: {
        Linux: '-luns \'0\' -names \'usrsap\' -paths \'/usr/sap\'  -sizes \'100\''
        Windows: '-luns "0" -names "sap" -paths "S"  -sizes "100"'
      }
      useFastNetwork: true
    }
  }
  'Large < 18.000 SAPS': {
    HANA: {
      vmSize: 'Standard_M64s'
      disks: [
        {
          lun: 0
          caching: 'ReadOnly'
          createOption: 'Empty'
          diskSizeGB: 512
        }
        {
          lun: 1
          caching: 'ReadOnly'
          createOption: 'Empty'
          diskSizeGB: 512
        }
        {
          lun: 2
          caching: 'ReadOnly'
          createOption: 'Empty'
          diskSizeGB: 512
        }
        {
          lun: 3
          caching: 'ReadOnly'
          createOption: 'Empty'
          diskSizeGB: 512
        }
        {
          lun: 4
          caching: 'None'
          writeAcceleratorEnabled: 'true'
          createOption: 'Empty'
          diskSizeGB: 512
        }
        {
          lun: 5
          caching: 'None'
          writeAcceleratorEnabled: 'true'
          createOption: 'Empty'
          diskSizeGB: 512
        }
        {
          lun: 6
          caching: 'ReadOnly'
          createOption: 'Empty'
          diskSizeGB: 1024
        }
        {
          lun: 7
          caching: 'ReadOnly'
          createOption: 'Empty'
          diskSizeGB: 64
        }
        {
          lun: 8
          caching: 'ReadOnly'
          createOption: 'Empty'
          diskSizeGB: 1024
        }
        {
          lun: 9
          caching: 'ReadOnly'
          createOption: 'Empty'
          diskSizeGB: 1024
        }
      ]
      scriptArguments: {
        Linux: '-luns \'0,1,2,3#4,5#6#7#8,9\' -names \'data#log#shared#usrsap#backup\' -paths \'/hana/data#/hana/log#/hana/shared#/usr/sap#/hana/backup\' -sizes \'100#100#100#100#100\''
      }
      useFastNetwork: true
    }
    SQL: {
      vmSize: 'Standard_D64s_v3'
      disks: [
        {
          lun: 0
          caching: 'None'
          createOption: 'Empty'
          diskSizeGB: 1024
        }
        {
          lun: 1
          caching: 'None'
          createOption: 'Empty'
          diskSizeGB: 1024
        }
        {
          lun: 2
          caching: 'None'
          createOption: 'Empty'
          diskSizeGB: 1024
        }
        {
          lun: 3
          caching: 'None'
          createOption: 'Empty'
          diskSizeGB: 1024
        }
        {
          lun: 4
          caching: 'None'
          createOption: 'Empty'
          diskSizeGB: 1024
        }
        {
          lun: 5
          caching: 'None'
          createOption: 'Empty'
          diskSizeGB: 512
        }
        {
          lun: 6
          caching: 'None'
          createOption: 'Empty'
          diskSizeGB: 128
        }
      ]
      scriptArguments: {
        Windows: '-luns "0,1,2,3,4#5#6" -names "data#log#sap" -paths "C:\\sql\\data#C:\\sql\\log#S"  -sizes "100#100#100"'
      }
      useFastNetwork: true
    }
    other: {
      vmSize: 'Standard_D64s_v3'
      disks: [
        {
          lun: 0
          caching: 'ReadOnly'
          createOption: 'Empty'
          diskSizeGB: 128
        }
        {
          lun: 1
          caching: 'ReadOnly'
          createOption: 'Empty'
          diskSizeGB: 128
        }
      ]
      scriptArguments: {
        Linux: '-luns \'0\' -names \'usrsap\' -paths \'/usr/sap\'  -sizes \'100\''
        Windows: '-luns "0" -names "sap" -paths "S"  -sizes "100"'
      }
      useFastNetwork: true
    }
  }
  'X-Large < 40.000 SAPS': {
    HANA: {
      vmSize: 'Standard_M128s'
      disks: [
        {
          lun: 0
          caching: 'ReadOnly'
          createOption: 'Empty'
          diskSizeGB: 1024
        }
        {
          lun: 1
          caching: 'ReadOnly'
          createOption: 'Empty'
          diskSizeGB: 1024
        }
        {
          lun: 2
          caching: 'ReadOnly'
          createOption: 'Empty'
          diskSizeGB: 1024
        }
        {
          lun: 3
          caching: 'None'
          writeAcceleratorEnabled: 'true'
          createOption: 'Empty'
          diskSizeGB: 512
        }
        {
          lun: 4
          caching: 'None'
          writeAcceleratorEnabled: 'true'
          createOption: 'Empty'
          diskSizeGB: 512
        }
        {
          lun: 5
          caching: 'ReadOnly'
          createOption: 'Empty'
          diskSizeGB: 1024
        }
        {
          lun: 6
          caching: 'ReadOnly'
          createOption: 'Empty'
          diskSizeGB: 64
        }
        {
          lun: 7
          caching: 'ReadOnly'
          createOption: 'Empty'
          diskSizeGB: 2048
        }
        {
          lun: 8
          caching: 'ReadOnly'
          createOption: 'Empty'
          diskSizeGB: 2048
        }
      ]
      scriptArguments: {
        Linux: '-luns \'0,1,2#3,4#5#6#7,8\' -names \'data#log#shared#usrsap#backup\' -paths \'/hana/data#/hana/log#/hana/shared#/usr/sap#/hana/backup\' -sizes \'100#100#100#100#100\''
      }
      useFastNetwork: true
    }
    SQL: {
      vmSize: 'Standard_E64s_v3'
      disks: [
        {
          lun: 0
          caching: 'None'
          createOption: 'Empty'
          diskSizeGB: 1024
        }
        {
          lun: 1
          caching: 'None'
          createOption: 'Empty'
          diskSizeGB: 1024
        }
        {
          lun: 2
          caching: 'None'
          createOption: 'Empty'
          diskSizeGB: 1024
        }
        {
          lun: 3
          caching: 'None'
          createOption: 'Empty'
          diskSizeGB: 1024
        }
        {
          lun: 4
          caching: 'None'
          createOption: 'Empty'
          diskSizeGB: 1024
        }
        {
          lun: 5
          caching: 'None'
          createOption: 'Empty'
          diskSizeGB: 1024
        }
        {
          lun: 6
          caching: 'None'
          createOption: 'Empty'
          diskSizeGB: 1024
        }
        {
          lun: 7
          caching: 'None'
          createOption: 'Empty'
          diskSizeGB: 1024
        }
        {
          lun: 8
          caching: 'None'
          createOption: 'Empty'
          diskSizeGB: 128
        }
      ]
      scriptArguments: {
        Windows: '-luns "0,1,2,3,4,5,6#7#8" -names "data#log#sap" -paths "C:\\sql\\data#C:\\sql\\log#S"  -sizes "100#100#100"'
      }
      useFastNetwork: true
    }
    other: {
      vmSize: 'Standard_E64s_v3'
      disks: [
        {
          lun: 0
          caching: 'ReadOnly'
          createOption: 'Empty'
          diskSizeGB: 128
        }
        {
          lun: 1
          caching: 'ReadOnly'
          createOption: 'Empty'
          diskSizeGB: 128
        }
      ]
      scriptArguments: {
        Linux: '-luns \'0\' -names \'usrsap\' -paths \'/usr/sap\'  -sizes \'100\''
        Windows: '-luns "0" -names "sap" -paths "S"  -sizes "100"'
      }
      useFastNetwork: true
    }
  }
}
var sidlower = toLower(sapSystemId)
var vmName_var = '${sidlower}-servercs'
var vnetName_var = '${sidlower}-vnet'
var publicIpName_var = '${sidlower}-pib'
var nicName_var = '${sidlower}-nic'
var nsgName_var = '${sidlower}-nsg-cs'
var subnetName = 'Subnet'
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
var subnets = {
  true: resourceId('Microsoft.Network/virtualNetworks/subnets', vnetName_var, subnetName)
  false: subnetId
}
var selectedSubnetId = subnets[string((length(subnetId) == 0))]

resource nsgName 'Microsoft.Network/networkSecurityGroups@2018-10-01' = if (length(subnetId) == 0) {
  name: concat(nsgName_var)
  location: location
  properties: {
    securityRules: selectedSecurityRules
  }
}

resource vnetName 'Microsoft.Network/virtualNetworks@2018-10-01' = if (length(subnetId) == 0) {
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

resource publicIpName 'Microsoft.Network/publicIPAddresses@2018-10-01' = if (length(subnetId) == 0) {
  name: publicIpName_var
  location: location
  properties: {
    publicIPAllocationMethod: 'Dynamic'
  }
  dependsOn: [
    vnetName
  ]
}

resource nicName 'Microsoft.Network/networkInterfaces@2018-10-01' = {
  name: nicName_var
  location: location
  properties: {
    ipConfigurations: [
      {
        name: 'ipconfig1'
        properties: {
          privateIPAllocationMethod: 'Dynamic'
          publicIPAddress: ((length(subnetId) == 0) ? json('{"id": "${publicIpName.id}"}') : json('null'))
          subnet: {
            id: selectedSubnetId
          }
        }
      }
    ]
    enableAcceleratedNetworking: sizes[sapSystemSize][dbtype].useFastNetwork
  }
  dependsOn: [
    vnetName
  ]
}

resource vmName 'Microsoft.Compute/virtualMachines@2018-10-01' = {
  name: vmName_var
  zones: selectedZones
  location: location
  properties: {
    hardwareProfile: {
      vmSize: sizes[sapSystemSize][dbtype].vmSize
    }
    osProfile: {
      computerName: vmName_var
      adminUsername: adminUsername
      adminPassword: adminPasswordOrKey
      linuxConfiguration: ((authenticationType == 'password') ? json('null') : linuxConfiguration)
    }
    storageProfile: {
      imageReference: {
        publisher: images[osType].publisher
        offer: images[osType].offer
        sku: images[osType].sku
        version: 'latest'
      }
      osDisk: {
        name: '${vmName_var}-osdisk'
        caching: 'ReadWrite'
        createOption: 'FromImage'
        managedDisk: {
          storageAccountType: 'Premium_LRS'
        }
      }
      dataDisks: sizes[sapSystemSize][dbtype].disks
    }
    networkProfile: {
      networkInterfaces: [
        {
          id: nicName.id
        }
      ]
    }
  }
}

resource vmName_csExtension_internalOSType_Name 'Microsoft.Compute/virtualMachines/extensions@2018-10-01' = {
  parent: vmName
  name: '${csExtension[internalOSType].Name}'
  location: location
  properties: {
    publisher: csExtension[internalOSType].Publisher
    type: csExtension[internalOSType].Name
    typeHandlerVersion: csExtension[internalOSType].Version
    autoUpgradeMinorVersion: true
    settings: {
      fileUris: [
        csExtension[internalOSType].script
      ]
      commandToExecute: '${csExtension[internalOSType].scriptCall} ${sizes[sapSystemSize][dbtype].scriptArguments[internalOSType]}'
    }
  }
}