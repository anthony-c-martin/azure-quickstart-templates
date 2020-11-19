param vnetName string {
  metadata: {
    description: 'Name for the new VNet.'
  }
  default: 'WTestVNet'
}
param vnetPrefix string {
  metadata: {
    description: 'CIDR prefix for the VNet address space.'
  }
  default: '192.168.0.0/16'
}
param frontEndSubnetName string {
  metadata: {
    description: 'Name for the front end subnet.'
  }
  default: 'FrontEnd'
}
param frontEndSubnetPrefix string {
  metadata: {
    description: 'CIDR address prefix for the front end subnet.'
  }
  default: '192.168.1.0/24'
}
param osType string {
  allowed: [
    'Windows'
    'Ubuntu'
  ]
  metadata: {
    description: 'Type of OS to use for VMs: Windows or Ubuntu.'
  }
  default: 'Windows'
}
param adminUsername string {
  metadata: {
    description: 'Username for local admin account.'
  }
}
param adminPassword string {
  metadata: {
    description: 'Password for local admin account.'
  }
  secure: true
}
param location string {
  metadata: {
    description: 'Location for all resources.'
  }
  default: resourceGroup().location
}

var webVMSettings = {
  Windows: {
    vmSize: 'Standard_A1'
    publisher: 'MicrosoftWindowsServer'
    offer: 'WindowsServer'
    sku: '2012-R2-Datacenter'
    version: 'latest'
    vmName: 'WEB1'
    osdisk: 'osdiskweb'
    nicName: 'NICWEB1'
    pipName: 'PIPWEB1'
    ipAddress: '192.168.1.101'
  }
  Ubuntu: {
    vmSize: 'Standard_A1'
    publisher: 'Canonical'
    offer: 'UbuntuServer'
    sku: '14.04.5-LTS'
    version: 'latest'
    vmName: 'WEB1'
    osdisk: 'osdiskweb'
    nicName: 'NICWEB1'
    pipName: 'PIPWEB1'
    ipAddress: '192.168.1.101'
  }
}
var vmStorageAccountContainerName = 'vhds'
var frontEndSubnetRef = resourceId('Microsoft.Network/virtualNetworks/subnets/', vnetName, frontEndSubnetName)
var webVMSetting = webVMSettings[osType]

resource vnetName_res 'Microsoft.Network/virtualNetworks@2015-06-15' = {
  name: vnetName
  location: location
  tags: {
    displayName: 'VNet'
  }
  properties: {
    addressSpace: {
      addressPrefixes: [
        vnetPrefix
      ]
    }
    subnets: [
      {
        name: frontEndSubnetName
        properties: {
          addressPrefix: frontEndSubnetPrefix
        }
      }
    ]
  }
}

resource webVMSetting_pipName 'Microsoft.Network/publicIPAddresses@2015-06-15' = {
  name: webVMSetting.pipName
  location: location
  properties: {
    publicIPAllocationMethod: 'Static'
  }
  tags: {
    displayName: 'PublicIPAddress - Web'
  }
}

resource webVMSetting_nicName 'Microsoft.Network/networkInterfaces@2015-06-15' = {
  name: webVMSetting.nicName
  location: location
  tags: {
    displayName: 'NetworkInterface - Web'
  }
  properties: {
    ipConfigurations: [
      {
        name: 'ipconfig1'
        properties: {
          privateIPAllocationMethod: 'Static'
          privateIPAddress: webVMSetting.ipAddress
          publicIPAddress: {
            id: webVMSetting_pipName.id
          }
          subnet: {
            id: frontEndSubnetRef
          }
        }
      }
    ]
  }
  dependsOn: [
    vnetName_res
  ]
}

resource webVMSetting_vmName 'Microsoft.Compute/virtualMachines@2017-03-30' = {
  name: webVMSetting.vmName
  location: location
  tags: {
    displayName: 'VM - Web'
  }
  properties: {
    hardwareProfile: {
      vmSize: webVMSetting.vmSize
    }
    osProfile: {
      computerName: webVMSetting.vmName
      adminUsername: adminUsername
      adminPassword: adminPassword
    }
    storageProfile: {
      imageReference: {
        publisher: webVMSetting.publisher
        offer: webVMSetting.offer
        sku: webVMSetting.sku
        version: webVMSetting.version
      }
      osDisk: {
        name: '${webVMSetting.vmName}_OSDisk'
        caching: 'ReadWrite'
        createOption: 'FromImage'
      }
    }
    networkProfile: {
      networkInterfaces: [
        {
          id: webVMSetting_nicName.id
        }
      ]
    }
  }
}