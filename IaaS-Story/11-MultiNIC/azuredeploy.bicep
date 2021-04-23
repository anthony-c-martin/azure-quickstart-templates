@description('Name for the new VNet.')
param vnetName string = 'WTestVNet'

@description('Name for the back end subnet.')
param backEndSubnetName string = 'BackEnd'

@description('Name for the NSG used to allow DB access, and block Internet.')
param backEndNSGName string = 'NSG-BackEnd'

@description('Name for the NSG used to allow remote access.')
param remoteAccessNSGName string = 'NSG-RemoteAccess'

@allowed([
  'Windows'
  'Ubuntu'
])
@description('Type of OS to use for VMs: Windows or Ubuntu.')
param osType string = 'Windows'

@description('Username for local admin account.')
param adminUsername string

@description('Password for local admin account.')
@secure()
param adminPassword string

@description('Number of database VMs to be deployed to the backend end subnet.')
param dbCount int = 2

@description('Name of resource group containing vnet and front end resources.')
param parentRG string = 'IaaSStory'

@description('Location for all resources.')
param location string = resourceGroup().location

var dbVMSettings = {
  Windows: {
    vmSize: 'Standard_DS3'
    publisher: 'MicrosoftSQLServer'
    offer: 'SQL2014SP1-WS2012R2'
    sku: 'Standard'
    version: 'latest'
    vmName: 'DB'
    osdisk: 'osdiskdb'
    datadisk: 'datadiskdb'
    nicName: 'NICDB'
    ipAddress: '192.168.2.'
    extensionDeployment: ''
    avsetName: 'ASDB'
    remotePort: 3389
    dbPort: 1433
  }
  Ubuntu: {
    vmSize: 'Standard_DS3'
    publisher: 'Canonical'
    offer: 'UbuntuServer'
    sku: '14.04.5-LTS'
    version: 'latest'
    vmName: 'DB'
    osdisk: 'osdiskdb'
    datadisk: 'datadiskdb'
    nicName: 'NICDB'
    ipAddress: '192.168.2.'
    extensionDeployment: ''
    avsetName: 'ASDB'
    remotePort: 22
    dbPort: 1433
  }
}
var backEndSubnetRef = resourceId('Microsoft.Network/virtualNetworks/subnets/', vnetName, backEndSubnetName)
var dbVMSetting = dbVMSettings[osType]

resource dbVMSetting_nicName_DA_1 'Microsoft.Network/networkInterfaces@2015-06-15' = [for i in range(0, dbCount): {
  name: '${dbVMSetting.nicName}-DA-${(i + 1)}'
  location: location
  tags: {
    displayName: 'NetworkInterfaces - DB DA'
  }
  properties: {
    ipConfigurations: [
      {
        name: 'ipconfig1'
        properties: {
          privateIPAllocationMethod: 'Static'
          privateIPAddress: concat(dbVMSetting.ipAddress, (i + 4))
          subnet: {
            id: backEndSubnetRef
          }
        }
      }
    ]
  }
}]

resource dbVMSetting_nicName_RA_1 'Microsoft.Network/networkInterfaces@2015-06-15' = [for i in range(0, dbCount): {
  name: '${dbVMSetting.nicName}-RA-${(i + 1)}'
  location: location
  tags: {
    displayName: 'NetworkInterfaces - DB RA'
  }
  properties: {
    ipConfigurations: [
      {
        name: 'ipconfig1'
        properties: {
          networkSecurityGroup: {
            id: resourceId('Microsoft.Network/networkSecurityGroups', remoteAccessNSGName)
          }
          privateIPAllocationMethod: 'Static'
          privateIPAddress: concat(dbVMSetting.ipAddress, (i + 54))
          subnet: {
            id: backEndSubnetRef
          }
        }
      }
    ]
  }
}]

resource dbVMSetting_avsetName 'Microsoft.Compute/availabilitySets@2017-12-01' = {
  name: dbVMSetting.avsetName
  location: location
  tags: {
    displayName: 'AvailabilitySet - DB'
  }
}

resource dbVMSetting_vmName_1 'Microsoft.Compute/virtualMachines@2017-03-30' = [for i in range(0, dbCount): {
  name: concat(dbVMSetting.vmName, (i + 1))
  location: location
  tags: {
    displayName: 'VMs - DB'
  }
  properties: {
    availabilitySet: {
      id: dbVMSetting_avsetName.id
    }
    hardwareProfile: {
      vmSize: dbVMSetting.vmSize
    }
    osProfile: {
      computerName: concat(dbVMSetting.vmName, (i + 1))
      adminUsername: adminUsername
      adminPassword: adminPassword
    }
    storageProfile: {
      imageReference: {
        publisher: dbVMSetting.publisher
        offer: dbVMSetting.offer
        sku: dbVMSetting.sku
        version: dbVMSetting.version
      }
      osDisk: {
        name: concat(dbVMSetting.osdisk, (i + 1))
        caching: 'ReadWrite'
        createOption: 'FromImage'
        managedDisk: {
          storageAccountType: 'Premium_LRS'
        }
      }
      dataDisks: [
        {
          name: '${dbVMSetting.datadisk}${(i + 1)}-data-disk1'
          diskSizeGB: 127
          createOption: 'Empty'
          lun: 0
          managedDisk: {
            storageAccountType: 'Premium_LRS'
          }
        }
        {
          name: '${dbVMSetting.datadisk}${(i + 1)}-data-disk2'
          diskSizeGB: 127
          createOption: 'Empty'
          lun: 1
          managedDisk: {
            storageAccountType: 'Premium_LRS'
          }
        }
      ]
    }
    networkProfile: {
      networkInterfaces: [
        {
          id: resourceId('Microsoft.Network/networkInterfaces', '${dbVMSetting.nicName}-DA-${(i + 1)}')
          properties: {
            primary: true
          }
        }
        {
          id: resourceId('Microsoft.Network/networkInterfaces', '${dbVMSetting.nicName}-RA-${(i + 1)}')
          properties: {
            primary: false
          }
        }
      ]
    }
  }
  dependsOn: [
    'Microsoft.Network/networkInterfaces/${dbVMSetting.nicName}-DA-${(i + 1)}'
    'Microsoft.Network/networkInterfaces/${dbVMSetting.nicName}-RA-${(i + 1)}'
    dbVMSetting_avsetName
  ]
}]