param sapSystemId string {
  minLength: 3
  maxLength: 3
  metadata: {
    description: 'SAP System ID.'
  }
}
param osType string {
  allowed: [
    'Windows'
    'Linux'
  ]
  metadata: {
    description: 'The type of the operating system you want to deploy.'
  }
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
param userImageId string {
  metadata: {
    description: 'Id of the user image.'
  }
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
var csExtension = {
  Windows: {
    script: '${github}configureSAPVM.ps1'
    scriptCall: 'powershell.exe -File configureSAPVM.ps1'
  }
  Linux: {
    script: '${github}configureSAPVM.sh'
    scriptCall: 'sh configureSAPVM.sh'
  }
}
var vmSizes = {
  'Small < 2.000 SAPS': {
    Premium: {
      size: 'Standard_DS11'
      disks: [
        {
          size: 512
        }
        {
          size: 512
        }
        {
          size: 128
        }
      ]
      scriptArgs: ' -DBDataLUNS \'0,1\' -DBLogLUNS \'2\''
    }
    Standard: {
      size: 'Standard_D11'
      disks: [
        {
          size: 1023
        }
        {
          size: 1023
        }
        {
          size: 1023
        }
        {
          size: 1023
        }
      ]
      scriptArgs: ' -DBDataLUNS \'0,1,2\' -DBLogLUNS \'3\''
    }
  }
  'Medium < 9.000 SAPS': {
    Premium: {
      size: 'Standard_DS13'
      disks: [
        {
          size: 512
        }
        {
          size: 512
        }
        {
          size: 512
        }
        {
          size: 128
        }
      ]
      scriptArgs: ' -DBDataLUNS \'0,1,2\' -DBLogLUNS \'3\''
    }
    Standard: {
      size: 'Standard_D13'
      disks: [
        {
          size: 1023
        }
        {
          size: 1023
        }
        {
          size: 1023
        }
        {
          size: 1023
        }
        {
          size: 1023
        }
        {
          size: 1023
        }
      ]
      scriptArgs: ' -DBDataLUNS \'0,1,2,3\' -DBLogLUNS \'4,5\''
    }
  }
  'Large < 18.000 SAPS': {
    Premium: {
      size: 'Standard_DS14'
      disks: [
        {
          size: 1023
        }
        {
          size: 1023
        }
        {
          size: 1023
        }
        {
          size: 512
        }
      ]
      scriptArgs: ' -DBDataLUNS \'0,1,2\' -DBLogLUNS \'3\''
    }
    Standard: {
      size: 'Standard_D14'
      disks: [
        {
          size: 1023
        }
        {
          size: 1023
        }
        {
          size: 1023
        }
        {
          size: 1023
        }
        {
          size: 1023
        }
        {
          size: 1023
        }
      ]
      scriptArgs: ' -DBDataLUNS \'0,1,2,3\' -DBLogLUNS \'4,5\''
    }
  }
  'X-Large < 40.000 SAPS': {
    Premium: {
      size: 'Standard_GS5'
      disks: [
        {
          size: 1023
        }
        {
          size: 1023
        }
        {
          size: 1023
        }
        {
          size: 1023
        }
        {
          size: 512
        }
      ]
      scriptArgs: ' -DBDataLUNS \'0,1,2,3\' -DBLogLUNS \'4\''
    }
    Standard: {
      size: 'Standard_D14'
      disks: [
        {
          size: 1023
        }
        {
          size: 1023
        }
        {
          size: 1023
        }
        {
          size: 1023
        }
        {
          size: 1023
        }
        {
          size: 1023
        }
      ]
      scriptArgs: ' -DBDataLUNS \'0,1,2,3\' -DBLogLUNS \'4,5\''
    }
  }
}
var vmSize = vmSizes[sapSystemSize][storageType].size
var dataDiskSizes = vmSizes[sapSystemSize][storageType].disks
var internalOsType = osType
var internalExtensionScript = csExtension[osType].script
var internalExtensionScriptCall = csExtension[osType].scriptCall
var internalExtensionScriptCallArgs = vmSizes[sapSystemSize][storageType].scriptArgs
var sidlower = toLower(sapSystemId)
var vmName = '${sidlower}-servercs'
var vnetName = '${sidlower}-vnet'
var publicIpName = '${sidlower}-pip'
var nicName = '${sidlower}-nic'
var nsgName = '${sidlower}-nsg-cs'
var storageTypes = {
  Premium: 'Premium_LRS'
  Standard: 'Standard_LRS'
}
var internalStorageType = storageTypes[storageType]
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
var osDiskType = 'userImage'

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

module nestedDeploymentNameProf_resource '<failed to parse [concat(variables(\'github\'), \'os-disk-parts-md.json\')]>' = {
  name: nestedDeploymentNameProf
  params: {
    imageSku: ''
    imagePublisher: ''
    imageOffer: ''
    osDiskType: osDiskType
    osType: internalOsType
    sidlower: sidlower
    vmName: vmName
    storageType: internalStorageType
    managedDiskId: userImageId
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
    osType: internalOsType
  }
}

resource nicName_resource 'Microsoft.Network/networkInterfaces@2017-06-01' = {
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

module nestedDeploymentName_resource '<failed to parse [concat(variables(\'github\'), \'server-md.json\')]>' = {
  name: nestedDeploymentName
  params: {
    imageReference: reference(nestedDeploymentNameProf).outputs.imageReference.value
    osDisk: reference(nestedDeploymentNameProf).outputs.osDisk.value
    osDiskType: osDiskType
    vmName: vmName
    vmSize: vmSize
    adminUsername: adminUsername
    adminPassword: adminPassword
    csExtensionScript: internalExtensionScript
    csExtensionscriptCall: internalExtensionScriptCall
    csExtensionscriptArgs: internalExtensionScriptCallArgs
    avSetObj: {}
    nicName: nicName
    dataDisksObj: {
      copy: [
        {
          name: 'dataDisks'
          count: length(dataDiskSizes)
          input: {
            lun: copyIndex('dataDisks')
            createOption: 'Empty'
            diskSizeGB: dataDiskSizes[copyIndex('dataDisks')].size
          }
        }
      ]
    }
    osType: internalOsType
  }
  dependsOn: [
    nestedDeploymentNameProf_resource
    nicName_resource
  ]
}