param labName string {
  metadata: {
    description: 'The name of the new lab instance to be created'
  }
}
param location string {
  metadata: {
    description: 'Location for all resources.'
  }
  default: resourceGroup().location
}
param vmName string {
  metadata: {
    description: 'The name of the vm to be created.'
  }
}
param vmSize string {
  metadata: {
    description: 'The size of the vm to be created.'
  }
  default: 'Standard_D3_v2'
}
param userName string {
  metadata: {
    description: 'The username for the local account that will be created on the new vm.'
  }
}
param password string {
  metadata: {
    description: 'The password for the local account that will be created on the new vm.'
  }
  secure: true
}

var labSubnetName = '${labVirtualNetworkName}Subnet'
var labVirtualNetworkId = labName_labVirtualNetworkName.id
var labVirtualNetworkName = 'Dtl${labName}'

resource labName_res 'Microsoft.DevTestLab/labs@2018-10-15-preview' = {
  name: labName
  location: location
}

resource labName_labVirtualNetworkName 'Microsoft.DevTestLab/labs/virtualNetworks@2018-10-15-preview' = {
  name: '${labName}/${labVirtualNetworkName}'
}

resource labName_vmName 'Microsoft.DevTestLab/labs/virtualMachines@2018-10-15-preview' = {
  name: '${labName}/${vmName}'
  location: location
  properties: {
    userName: userName
    password: password
    labVirtualNetworkId: labVirtualNetworkId
    labSubnetName: labSubnetName
    size: vmSize
    allowClaim: 'true'
    galleryImageReference: {
      offer: 'WindowsServer'
      publisher: 'MicrosoftWindowsServer'
      sku: '2019-Datacenter'
      osType: 'Windows'
      version: 'latest'
    }
  }
}

output labId string = labName_res.id