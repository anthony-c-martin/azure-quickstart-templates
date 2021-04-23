@minLength(3)
@maxLength(3)
@description('SAP System ID.')
param sapSystemId string = 'DEQ'

@minLength(3)
@description('The computer name. This parameter is also used as virtual machine name. It is required if you want to deploy this template using SAP LaMa.')
param computerName string = 'deq-app-0'

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
  'OTHER'
])
@description('The type of the database. If you select SQL Server, you can provide the path to the ODBC driver which is then automatically installed.')
param dbType string = 'OTHER'

@allowed([
  'Demo'
  'Small < 2.000 SAPS'
  'Medium < 9.000 SAPS'
  'Large < 18.000 SAPS'
  'X-Large < 40.000 SAPS'
])
@description('The size of the SAP System you want to deploy.')
param sapSystemSize string = 'Small < 2.000 SAPS'

@description('Username for the virtual machine.')
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

@description('You can deploy an empty target if you want to use the virtual machine as a target for an instance relocate or similar. In this case, no additional disks or IP configurations are attached.')
param deployEmptyTarget bool = false

@description('The location of the SAR archives. The location should contain archives for SAPCAR, SAP Host Agent, SAPACEXT,  Microsoft Visual C++ Redistributable and the Microsoft ODBC driver for SQL Server.')
param sapArtifactsLocation string = ''

@description('The sasToken required to access sapArtifactsLocation.')
@secure()
param sapArtifactsLocationSasToken string = ''

@description('The filename for the sapcar application that matches the operating system you deploy. sapcar is used to extract the archives you provide in other parameters.')
param sapcarFilename string = ''

@description('The filename of the SAP Host Agent archive. SAP Host Agent is deployed as part of this template depoyment.')
param sapHostAgentArchiveFilename string = ''

@description('The filename of the SAP Adaptive Extensions. SAP Note 2343511 lists the minimum patch level required for Azure.')
param sapacExtArchiveFilename string = ''

@description('The filename of the VC Runtime that is required to install the SAP Adaptive Extensions. This parameter is only required for Windows.')
param vcRedistFilename string = ''

@description('The filename of the ODBC driver you want to install. Only Microsoft ODBC driver for SQL Server is supported.')
param odbcDriverFilename string = ''

@description('The password for the sapadm user.')
@secure()
param sapadmPassword string = ''

@description('The Linux User Id of the sapadm user. Not required for Windows.')
param sapadmId int = 790

@description('The Linux group id of the sapsys group. Not required for Windows.')
param sapsysGid int = 79

@minValue(0)
@maxValue(3)
@description('Zone number. Set to 0 if you do not want to use Availability Zones')
param availabilityZone int = 0

@description('Location for all resources.')
param location string = resourceGroup().location

@description('The base URI where artifacts required by this template are located. When the template is deployed using the accompanying scripts, a private location in the subscription will be used and this value will be automatically generated.')
param artifactsLocation string = 'https://raw.githubusercontent.com/Azure/azure-quickstart-templates/master/sap-lama-apps/'

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
    osDiskSize: 128
  }
  'Windows Server 2012 R2 Datacenter': {
    sku: '2012-R2-Datacenter'
    offer: 'WindowsServer'
    publisher: 'MicrosoftWindowsServer'
    OSType: 'Windows'
    osDiskSize: 128
  }
  'Windows Server 2016 Datacenter': {
    sku: '2016-Datacenter'
    offer: 'WindowsServer'
    publisher: 'MicrosoftWindowsServer'
    OSType: 'Windows'
    osDiskSize: 128
  }
  'SLES 12': {
    sku: '12-SP3'
    offer: 'SLES-SAP'
    publisher: 'SUSE'
    OSType: 'Linux'
    osDiskSize: 128
  }
  'RHEL 7': {
    sku: '7.3'
    offer: 'RHEL'
    publisher: 'RedHat'
    OSType: 'Linux'
    osDiskSize: 128
  }
  'Oracle Linux 7': {
    sku: '7.3'
    offer: 'Oracle-Linux'
    publisher: 'Oracle'
    OSType: 'Linux'
    osDiskSize: 128
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
var osConfigs = {
  Windows: {
    Publisher: 'Microsoft.Compute'
    Name: 'CustomScriptExtension'
    Version: '1.7'
    script: uri(artifactsLocation, 'scripts/diskConfig.ps1${artifactsLocationSasToken}')
    scriptCall: 'powershell.exe -ExecutionPolicy bypass -File diskConfig.ps1'
    disks: [
      {
        lun: 0
        name: '${computerName}-${sidlower}-apps'
        caching: 'ReadOnly'
        createOption: 'Empty'
        diskSizeGB: 128
      }
    ]
    scriptArguments: '-luns "0" -names "sap" -paths "C:\\usr\\sap\\${sapSystemId}"  -sizes "100"'
  }
  Linux: {
    Publisher: 'Microsoft.Azure.Extensions'
    Name: 'CustomScript'
    Version: '2.0'
    script: uri(artifactsLocation, 'scripts/diskConfig.sh${artifactsLocationSasToken}')
    scriptCall: 'sh diskConfig.sh'
    disks: []
    scriptArguments: ''
  }
}
var cseExtPublisher = osConfigs[internalOSType].Publisher
var cseExtName = osConfigs[internalOSType].Name
var cseExtVersion = osConfigs[internalOSType].Version
var csExtensionScript = osConfigs[internalOSType].script
var csExtensionscriptCall = osConfigs[internalOSType].scriptCall
var sizes = {
  Demo: {
    Linux: {
      vmSize: 'Standard_E2s_v3'
      useFastNetwork: false
    }
    Windows: {
      vmSize: 'Standard_E2s_v3'
      useFastNetwork: false
    }
  }
  'Small < 2.000 SAPS': {
    Linux: {
      vmSize: 'Standard_E2s_v3'
      useFastNetwork: false
    }
    Windows: {
      vmSize: 'Standard_E2s_v3'
      useFastNetwork: false
    }
  }
  'Medium < 9.000 SAPS': {
    Linux: {
      vmSize: 'Standard_E2s_v3'
      useFastNetwork: false
    }
    Windows: {
      vmSize: 'Standard_E2s_v3'
      useFastNetwork: false
    }
  }
  'Large < 18.000 SAPS': {
    Linux: {
      vmSize: 'Standard_E4s_v3'
      useFastNetwork: true
    }
    Windows: {
      vmSize: 'Standard_E4s_v3'
      useFastNetwork: true
    }
  }
  'X-Large < 40.000 SAPS': {
    Linux: {
      vmSize: 'Standard_E4s_v3'
      useFastNetwork: true
    }
    Windows: {
      vmSize: 'Standard_E4s_v3'
      useFastNetwork: true
    }
  }
}
var vmName_var = computerName
var nicName_var = '${vmName_var}-nic'
var sidlower = toLower(sapSystemId)
var vnetName_var = '${sidlower}-vnet'
var nsgName_var = '${sidlower}-nsg'
var subnetName = 'Subnet'
var subnets = {
  true: resourceId('Microsoft.Network/virtualNetworks/subnets', vnetName_var, subnetName)
  false: subnetId
}
var selectedSubnetId = subnets[string((length(subnetId) == 0))]
var basicIPConfig = [
  {
    name: 'ipconfig-vm'
    properties: {
      privateIPAllocationMethod: 'Dynamic'
      subnet: {
        id: selectedSubnetId
      }
      primary: true
    }
  }
]
var databaseIPConfig = {
  Linux: [
    {
      name: 'ipconfig-di'
      properties: {
        privateIPAllocationMethod: 'Dynamic'
        subnet: {
          id: selectedSubnetId
        }
        primary: false
      }
    }
  ]
  Windows: [
    {
      name: 'ipconfig-di'
      properties: {
        privateIPAllocationMethod: 'Dynamic'
        subnet: {
          id: selectedSubnetId
        }
        primary: false
      }
    }
  ]
}
var selectedIPConfig = concat(basicIPConfig, (deployEmptyTarget ? json('[]') : databaseIPConfig[internalOSType]))
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

resource nicName 'Microsoft.Network/networkInterfaces@2017-06-01' = {
  name: nicName_var
  location: location
  properties: {
    ipConfigurations: selectedIPConfig
    enableAcceleratedNetworking: sizes[sapSystemSize][internalOSType].useFastNetwork
  }
  dependsOn: [
    vnetName
  ]
}

resource vmName 'Microsoft.Compute/virtualMachines@2017-12-01' = {
  name: concat(vmName_var)
  zones: selectedZones
  location: location
  properties: {
    hardwareProfile: {
      vmSize: sizes[sapSystemSize][internalOSType].vmSize
    }
    osProfile: {
      computerName: computerName
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
        diskSizeGB: images[osType].osDiskSize
        managedDisk: {
          storageAccountType: 'Premium_LRS'
        }
      }
      dataDisks: (deployEmptyTarget ? json('[]') : osConfigs[internalOSType].disks)
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

resource vmName_cseExtName 'Microsoft.Compute/virtualMachines/extensions@2017-12-01' = if ((!deployEmptyTarget) && (internalOSType == 'Windows')) {
  name: '${vmName_var}/${cseExtName}'
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
    }
    protectedSettings: {
      commandToExecute: '${csExtensionscriptCall} ${osConfigs[internalOSType].scriptArguments}'
    }
  }
  dependsOn: [
    vmName
  ]
}

module name_odbc '?' /*TODO: replace with correct path to [uri(parameters('_artifactsLocation'), concat('nestedtemplates/runCommand.json', parameters('_artifactsLocationSasToken')))]*/ = if (dbType == 'SQL') {
  name: '${deployment().name}-odbc'
  params: {
    vmName: vmName_var
    command: '%SystemRoot%\\System32\\msiexec.exe /i msodbcsql.msi /quiet /norestart /log c:\\windows\\sql4sap.msi.log IACCEPTMSODBCSQLLICENSETERMS=YES MSIRESTARTMANAGERCONTROL=Disable'
    files: [
      uri(sapArtifactsLocation, concat(odbcDriverFilename, sapArtifactsLocationSasToken))
    ]
    osType: internalOSType
    location: location
  }
  dependsOn: [
    vmName_cseExtName
  ]
}

module name_installsaphostagent '?' /*TODO: replace with correct path to [uri(parameters('_artifactsLocation'), concat('nestedtemplates/installHostAgent.json', parameters('_artifactsLocationSasToken')))]*/ = if (length(sapHostAgentArchiveFilename) > 0) {
  name: '${deployment().name}-installsaphostagent'
  params: {
    vmName: vmName_var
    cseExtName: cseExtName
    cseExtPublisher: cseExtPublisher
    cseExtVersion: cseExtVersion
    sapArtifactsLocation: sapArtifactsLocation
    sapArtifactsLocationSasToken: sapArtifactsLocationSasToken
    sapcarFilename: sapcarFilename
    sapHostAgentArchiveFilename: sapHostAgentArchiveFilename
    sapacExtArchiveFilename: sapacExtArchiveFilename
    vcRedistFilename: vcRedistFilename
    sapadmPassword: sapadmPassword
    sapadmId: sapadmId
    sapsysGid: sapsysGid
    osType: internalOSType
    location: location
  }
  dependsOn: [
    'Microsoft.Resources/deployments/${deployment().name}-odbc'
  ]
}