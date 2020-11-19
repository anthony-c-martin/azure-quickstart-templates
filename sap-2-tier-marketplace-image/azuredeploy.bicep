param sapSystemId string {
  minLength: 3
  maxLength: 3
  metadata: {
    description: 'SAP System ID.'
  }
}
param osType string {
  allowed: [
    'Windows Server 2012 Datacenter'
    'Windows Server 2012 R2 Datacenter'
    'Windows Server 2016 Datacenter'
    'SLES 12'
    'RHEL 7.2'
  ]
  metadata: {
    description: 'The type of the operating system you want to deploy.'
  }
  default: 'Windows Server 2012 R2 Datacenter'
}
param sapSystemSize string {
  allowed: [
    'Small < 2.000 SAPS'
    'Medium < 9.000 SAPS'
    'Large < 18.000 SAPS'
    'X-Large < 40.000 SAPS'
  ]
  metadata: {
    description: 'The size of the SAP System you want to deploy.'
  }
  default: 'Small < 2.000 SAPS'
}
param storageType string {
  allowed: [
    'Premium'
    'Standard'
  ]
  metadata: {
    description: 'The storage type that should be used for the virtual machine.'
  }
  default: 'Standard'
}
param adminUsername string {
  metadata: {
    description: 'Username for the Virtual Machine.'
  }
}
param adminPassword string {
  minLength: 12
  metadata: {
    description: 'Password for the Virtual Machine.'
  }
  secure: true
}
param newOrExistingSubnet string {
  allowed: [
    'new'
    'existing'
  ]
  metadata: {
    description: 'Determines whether a new virtual network and subnet should be created or an existing subnet should be used.'
  }
  default: 'new'
}
param subnetId string {
  metadata: {
    description: 'The id of the subnet you want to use.'
  }
  default: ''
}
param location string {
  metadata: {
    description: 'Location for all resources.'
  }
  default: resourceGroup().location
}

var github = 'https://raw.githubusercontent.com/Azure/azure-quickstart-templates/master/sap-2-tier-marketplace-image/shared/'
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
    sku: '12-SP1'
    offer: 'SLES-SAP'
    publisher: 'SUSE'
    OSType: 'Linux'
  }
  'RHEL 7.2': {
    sku: '7.2'
    offer: 'RHEL'
    publisher: 'RedHat'
    OSType: 'Linux'
  }
}
var imageSku = images[osType].sku
var imagePublisher = images[osType].publisher
var imageOffer = images[osType].offer
var internalOSType = images[osType].OSType
var csExtension = {
  Windows: {
    Publisher: 'Microsoft.Compute'
    Name: 'CustomScriptExtension'
    Version: '1.7'
    script: '${github}configureSAPVM.ps1'
    scriptCall: 'powershell.exe -ExecutionPolicy bypass -File configureSAPVM.ps1'
  }
  Linux: {
    Publisher: 'Microsoft.Azure.Extensions'
    Name: 'CustomScript'
    Version: '2.0'
    script: '${github}configureSAPVM.sh'
    scriptCall: 'sh configureSAPVM.sh'
  }
}
var cseExtPublisher = csExtension[internalOSType].Publisher
var cseExtName = csExtension[internalOSType].Name
var cseExtVersion = csExtension[internalOSType].Version
var storageTypes = {
  Premium: 'Premium_LRS'
  Standard: 'Standard_LRS'
}
var internalStorageType = storageTypes[storageType]
var vmSizes = {
  'Small < 2.000 SAPS': {
    Premium: {
      size: 'Standard_DS11'
    }
    Standard: {
      size: 'Standard_D11'
    }
  }
  'Medium < 9.000 SAPS': {
    Premium: {
      size: 'Standard_DS13'
    }
    Standard: {
      size: 'Standard_D13'
    }
  }
  'Large < 18.000 SAPS': {
    Premium: {
      size: 'Standard_DS14'
    }
    Standard: {
      size: 'Standard_D14'
    }
  }
  'X-Large < 40.000 SAPS': {
    Premium: {
      size: 'Standard_GS5'
    }
    Standard: {
      size: 'Standard_D14'
    }
  }
}
var vmSize = vmSizes[sapSystemSize][storageType].size
var nicConfigurations = {
  new: {
    countPublicIp: 1
    countNSG: 1
  }
  existing: {
    countPublicIp: 0
    countNSG: 0
  }
}
var countPublicIp = nicConfigurations[newOrExistingSubnet].countPublicIp
var countNSG = nicConfigurations[newOrExistingSubnet].countNSG
var sidlower = toLower(sapSystemId)
var vmName = '${sidlower}-servercs'
var storageAccountName = concat(sidlower, uniqueString(sidlower, resourceGroup().id))
var vnetName = '${sidlower}-vnet'
var publicIpName = '${sidlower}-pib'
var nicName = '${sidlower}-nic'
var nsgName = '${sidlower}-nsg-cs'
var publicIPAddressType = 'Dynamic'
var addressPrefix = '10.0.0.0/16'
var subnetName = 'Subnet'
var subnetPrefix = '10.0.0.0/24'
var nestedDeploymentName = 'nestedTemplate'
var nestedDeploymentNameProf = '${nestedDeploymentName}prof'
var nestedDeploymentNameVnet = '${nestedDeploymentName}vnet'
var nestedDeploymentNameNSG = '${nestedDeploymentName}nsg'
var nestedDeploymentNameNIC = '${nestedDeploymentName}nic'
var nestedDeploymentNamePIP = '${nestedDeploymentName}pip'
var osDiskType = 'image'
var apiVerion = '2015-06-15'
var apiVerionRm = '2015-01-01'

resource storageAccountName_resource 'Microsoft.Storage/storageAccounts@2015-06-15' = {
  name: storageAccountName
  location: location
  properties: {
    accountType: internalStorageType
  }
}

module nestedDeploymentNameVnet_resource '<failed to parse [concat(variables(\'github\'), parameters(\'newOrExistingSubnet\'), \'vnet.json\')]>' = {
  name: nestedDeploymentNameVnet
  params: {
    vnetName: vnetName
    addressPrefix: addressPrefix
    subnetName: subnetName
    subnetPrefix: subnetPrefix
  }
}

module nestedDeploymentNameNIC_resource '<failed to parse [concat(variables(\'github\'), \'nic-config.json\')]>' = {
  name: nestedDeploymentNameNIC
  params: {
    vnetName: vnetName
    subnetName: subnetName
    publicIpName: publicIpName
    nsgName: nsgName
    newOrExistingSubnet: newOrExistingSubnet
    subnetId: subnetId
  }
}

module nestedDeploymentNameProf_resource '<failed to parse [concat(variables(\'github\'), \'os-disk-parts.json\')]>' = {
  name: nestedDeploymentNameProf
  params: {
    imageSku: imageSku
    imagePublisher: imagePublisher
    imageOffer: imageOffer
    userImageVhdUri: ''
    userImageStorageAccount: ''
    osDiskVhdUri: ''
    osDiskType: osDiskType
    osType: internalOSType
    sidlower: sidlower
    vmName: vmName
    storageAccountName: storageAccountName
  }
}

module nestedDeploymentNamePIP_resource '<failed to parse [concat(variables(\'github\'), parameters(\'newOrExistingSubnet\'), \'pip.json\')]>' = {
  name: nestedDeploymentNamePIP
  params: {
    publicIpName: publicIpName
    publicIPAddressType: publicIPAddressType
  }
}

module nestedDeploymentNameNSG_resource '<failed to parse [concat(variables(\'github\'), parameters(\'newOrExistingSubnet\'), \'nsg.json\')]>' = {
  name: nestedDeploymentNameNSG
  params: {
    nsgName: nsgName
    osType: internalOSType
  }
}

resource nicName_resource 'Microsoft.Network/networkInterfaces@2015-06-15' = {
  name: nicName
  location: location
  properties: {
    networkSecurityGroup: reference(nestedDeploymentNameNIC).outputs.selectedConfiguration.value.networkSecurityGroup
    ipConfigurations: [
      {
        name: 'ipconfig1'
        properties: {
          privateIPAllocationMethod: 'Dynamic'
          publicIPAddress: reference(nestedDeploymentNameNIC).outputs.selectedConfiguration.value.publicIPAddress
          subnet: reference(nestedDeploymentNameNIC).outputs.selectedConfiguration.value.subnet
        }
      }
    ]
  }
  dependsOn: [
    nestedDeploymentNameVnet_resource
    nestedDeploymentNameNIC_resource
    nestedDeploymentNamePIP_resource
    nestedDeploymentNameNSG_resource
  ]
}

module nestedDeploymentName_resource '<failed to parse [concat(variables(\'github\'), \'cs-server-\', variables(\'vmSize\'), \'_multiNIC_No.json\')]>' = {
  name: nestedDeploymentName
  params: {
    imageReference: reference(nestedDeploymentNameProf).outputs.imageReference.value
    osDisk: reference(nestedDeploymentNameProf).outputs.osDisk.value
    osDiskType: osDiskType
    sidlower: sidlower
    vmName: vmName
    vmSize: vmSize
    adminUsername: adminUsername
    adminPassword: adminPassword
    storageAccountName: storageAccountName
    nicName: nicName
  }
  dependsOn: [
    storageAccountName_resource
    nestedDeploymentNameProf_resource
    nicName_resource
  ]
}

resource vmName_cseExtName 'Microsoft.Compute/virtualMachines/extensions@2015-06-15' = {
  name: '${vmName}/${cseExtName}'
  location: location
  properties: {
    publisher: cseExtPublisher
    type: cseExtName
    typeHandlerVersion: cseExtVersion
    autoUpgradeMinorVersion: true
    settings: {
      fileUris: [
        csExtension[internalOSType].script
      ]
      commandToExecute: '${csExtension[internalOSType].scriptCall} -DBDataLUNS "${reference(nestedDeploymentName).outputs.dbDataLUNs.value}" -DBLogLUNS "${reference(nestedDeploymentName).outputs.dbLogLUNs.value}"'
    }
  }
  dependsOn: [
    nestedDeploymentName_resource
  ]
}