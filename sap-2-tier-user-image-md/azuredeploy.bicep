@minLength(3)
@maxLength(3)
@description('SAP System ID.')
param sapSystemId string

@allowed([
  'Windows'
  'Linux'
])
@description('The type of the operating system you want to deploy.')
param osType string

@allowed([
  'Small < 2.000 SAPS'
  'Medium < 9.000 SAPS'
  'Large < 18.000 SAPS'
  'X-Large < 40.000 SAPS'
])
@description('The size of the SAP System you want to deploy.')
param sapSystemSize string = 'Small < 2.000 SAPS'

@allowed([
  'Premium'
  'Standard'
])
@description('The storage type that should be used for the virtual machine.')
param storageType string = 'Standard'

@description('Id of the user image.')
param userImageId string

@description('Username for the Virtual Machine.')
param adminUsername string

@description('Password for the Virtual Machine.')
@secure()
param adminPassword string

@allowed([
  'new'
  'existing'
])
@description('Determines whether a new virtual network and subnet should be created or an existing subnet should be used.')
param newOrExistingSubnet string = 'new'

@description('The id of the subnet you want to use.')
param subnetId string = ''

@description('Location for all resources.')
param location string = resourceGroup().location

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
var nicName_var = '${sidlower}-nic'
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
var nestedDeploymentName_var = 'nestedTemplate'
var nestedDeploymentNameProf_var = '${nestedDeploymentName_var}prof'
var nestedDeploymentNameVnet_var = '${nestedDeploymentName_var}vnet'
var nestedDeploymentNameNSG_var = '${nestedDeploymentName_var}nsg'
var nestedDeploymentNameNIC_var = '${nestedDeploymentName_var}nic'
var nestedDeploymentNamePIP_var = '${nestedDeploymentName_var}pip'
var osDiskType = 'userImage'

module nestedDeploymentNameVnet '?' /*TODO: replace with correct path to [concat(variables('github'), parameters('newOrExistingSubnet'), 'vnet.json')]*/ = {
  name: nestedDeploymentNameVnet_var
  params: {
    vnetName: vnetName
    addressPrefix: addressPrefix
    subnetName: subnetName
    subnetPrefix: subnetPrefix
  }
}

module nestedDeploymentNameNIC '?' /*TODO: replace with correct path to [concat(variables('github'), 'nic-config.json')]*/ = {
  name: nestedDeploymentNameNIC_var
  params: {
    vnetName: vnetName
    subnetName: subnetName
    publicIpName: publicIpName
    nsgName: nsgName
    newOrExistingSubnet: newOrExistingSubnet
    subnetId: subnetId
  }
}

module nestedDeploymentNameProf '?' /*TODO: replace with correct path to [concat(variables('github'), 'os-disk-parts-md.json')]*/ = {
  name: nestedDeploymentNameProf_var
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

module nestedDeploymentNamePIP '?' /*TODO: replace with correct path to [concat(variables('github'), parameters('newOrExistingSubnet'), 'pip.json')]*/ = {
  name: nestedDeploymentNamePIP_var
  params: {
    publicIpName: publicIpName
    publicIPAddressType: publicIPAddressType
  }
}

module nestedDeploymentNameNSG '?' /*TODO: replace with correct path to [concat(variables('github'), parameters('newOrExistingSubnet'), 'nsg.json')]*/ = {
  name: nestedDeploymentNameNSG_var
  params: {
    nsgName: nsgName
    osType: internalOsType
  }
}

resource nicName 'Microsoft.Network/networkInterfaces@2017-06-01' = {
  name: nicName_var
  location: location
  properties: {
    networkSecurityGroup: reference(nestedDeploymentNameNIC_var).outputs.selectedConfiguration.value.networkSecurityGroup
    ipConfigurations: [
      {
        name: 'ipconfig1'
        properties: {
          privateIPAllocationMethod: 'Dynamic'
          publicIPAddress: reference(nestedDeploymentNameNIC_var).outputs.selectedConfiguration.value.publicIPAddress
          subnet: reference(nestedDeploymentNameNIC_var).outputs.selectedConfiguration.value.subnet
        }
      }
    ]
  }
  dependsOn: [
    nestedDeploymentNameVnet
    nestedDeploymentNameNIC
    nestedDeploymentNamePIP
    nestedDeploymentNameNSG
  ]
}

module nestedDeploymentName '?' /*TODO: replace with correct path to [concat(variables('github'), 'server-md.json')]*/ = {
  name: nestedDeploymentName_var
  params: {
    imageReference: reference(nestedDeploymentNameProf_var).outputs.imageReference.value
    osDisk: reference(nestedDeploymentNameProf_var).outputs.osDisk.value
    osDiskType: osDiskType
    vmName: vmName
    vmSize: vmSize
    adminUsername: adminUsername
    adminPassword: adminPassword
    csExtensionScript: internalExtensionScript
    csExtensionscriptCall: internalExtensionScriptCall
    csExtensionscriptArgs: internalExtensionScriptCallArgs
    avSetObj: {}
    nicName: nicName_var
    dataDisksObj: {
      dataDisks: [for (item, j) in dataDiskSizes: {
        lun: j
        createOption: 'Empty'
        diskSizeGB: item.size
      }]
    }
    osType: internalOsType
  }
  dependsOn: [
    nestedDeploymentNameProf
    nicName
  ]
}