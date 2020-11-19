param newStorageAccountName string {
  metadata: {
    description: 'Name of the Storage Account'
  }
}
param adminUsername string {
  metadata: {
    description: 'Username for the Administrator of the VM'
  }
}
param imagePublisher string {
  metadata: {
    description: 'Image Publisher'
  }
  default: 'Canonical'
}
param imageOffer string {
  metadata: {
    description: 'Image Offer'
  }
  default: 'UbuntuServer'
}
param imageSKU string {
  metadata: {
    description: 'Image SKU'
  }
  default: '14.04.5-LTS'
}
param vmDnsName string {
  metadata: {
    description: 'DNS Name for the Public IP. Must be lowercase.'
  }
}
param administratorLogin string {
  metadata: {
    description: 'Admin username for SQL Database'
  }
}
param administratorLoginPassword string {
  metadata: {
    description: 'Admin password for SQL Database'
  }
  secure: true
}
param collation string {
  metadata: {
    description: 'SQL Collation'
  }
  default: 'SQL_Latin1_General_CP1_CI_AS'
}
param databaseName string {
  metadata: {
    description: 'Name of your SQL Database'
  }
}
param edition string {
  allowed: [
    'Basic'
    'Standard'
    'Premium'
  ]
  metadata: {
    description: 'SQL Database Edition'
  }
}
param maxSizeBytes string {
  metadata: {
    description: 'Max DB size in bytes'
  }
  default: '268435456000'
}
param requestedServiceObjectiveId string {
  metadata: {
    description: 'Requested Service Objective ID'
  }
  default: 'f1173c43-91bd-4aaa-973c-54e79e15235b'
}
param serverName string {
  metadata: {
    description: 'Unique name of your SQL Server'
  }
}
param firewallStartIP string {
  metadata: {
    description: 'Start IP for your firewall rule, for example 0.0.0.0'
  }
}
param firewallEndIP string {
  metadata: {
    description: 'End IP for your firewall rule, for example 255.255.255.255'
  }
}
param version string {
  metadata: {
    description: 'SQL Version'
  }
  default: '12.0'
}
param location string {
  metadata: {
    description: 'Location for all resources.'
  }
  default: resourceGroup().location
}
param authenticationType string {
  allowed: [
    'sshPublicKey'
    'password'
  ]
  metadata: {
    description: 'Type of authentication to use on the Virtual Machine. SSH key is recommended.'
  }
  default: 'sshPublicKey'
}
param adminPasswordOrKey string {
  metadata: {
    description: 'SSH Key or password for the Virtual Machine. SSH key is recommended.'
  }
  secure: true
}

var nicName_var = 'myVMNic'
var addressPrefix = '10.0.0.0/16'
var subnetName = 'Subnet-1'
var subnetPrefix = '10.0.0.0/24'
var storageAccountType = 'Standard_LRS'
var publicIPAddressName_var = 'myPublicIP'
var publicIPAddressType = 'Dynamic'
var vmStorageAccountContainerName = 'vhds'
var vmName_var = vmDnsName
var vmSize = 'Standard_A0'
var virtualNetworkName_var = 'MyVNET'
var subnetRef = resourceId('Microsoft.Network/virtualNetworks/subnets', virtualNetworkName_var, subnetName)
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

resource serverName_res 'Microsoft.Sql/servers@2014-04-01-preview' = {
  location: location
  name: serverName
  properties: {
    administratorLogin: administratorLogin
    administratorLoginPassword: administratorLoginPassword
    version: version
  }
}

resource serverName_databaseName 'Microsoft.Sql/servers/databases@2014-04-01-preview' = {
  location: location
  name: '${serverName}/${databaseName}'
  properties: {
    collation: collation
    edition: edition
    maxSizeBytes: maxSizeBytes
    requestedServiceObjectiveId: requestedServiceObjectiveId
  }
  dependsOn: [
    serverName_res
  ]
}

resource serverName_FirewallRule1 'Microsoft.Sql/servers/firewallrules@2014-04-01-preview' = {
  location: location
  name: '${serverName}/FirewallRule1'
  properties: {
    endIpAddress: firewallEndIP
    startIpAddress: firewallStartIP
  }
  dependsOn: [
    serverName_res
  ]
}

resource newStorageAccountName_res 'Microsoft.Storage/storageAccounts@2015-05-01-preview' = {
  name: newStorageAccountName
  location: location
  properties: {
    accountType: storageAccountType
  }
}

resource publicIPAddressName 'Microsoft.Network/publicIPAddresses@2015-05-01-preview' = {
  name: publicIPAddressName_var
  location: location
  properties: {
    publicIPAllocationMethod: publicIPAddressType
    dnsSettings: {
      domainNameLabel: vmDnsName
    }
  }
}

resource virtualNetworkName 'Microsoft.Network/virtualNetworks@2015-05-01-preview' = {
  name: virtualNetworkName_var
  location: location
  properties: {
    addressSpace: {
      addressPrefixes: [
        addressPrefix
      ]
    }
    subnets: [
      {
        name: subnetName
        properties: {
          addressPrefix: subnetPrefix
        }
      }
    ]
  }
}

resource nicName 'Microsoft.Network/networkInterfaces@2015-05-01-preview' = {
  name: nicName_var
  location: location
  properties: {
    ipConfigurations: [
      {
        name: 'ipconfig1'
        properties: {
          privateIPAllocationMethod: 'Dynamic'
          publicIPAddress: {
            id: publicIPAddressName.id
          }
          subnet: {
            id: subnetRef
          }
        }
      }
    ]
  }
  dependsOn: [
    virtualNetworkName
  ]
}

resource vmName 'Microsoft.Compute/virtualMachines@2017-03-30' = {
  name: vmName_var
  location: location
  properties: {
    hardwareProfile: {
      vmSize: vmSize
    }
    osProfile: {
      computerName: vmName_var
      adminUsername: adminUsername
      adminPassword: adminPasswordOrKey
      linuxConfiguration: ((authenticationType == 'password') ? json('null') : linuxConfiguration)
    }
    storageProfile: {
      imageReference: {
        publisher: imagePublisher
        offer: imageOffer
        sku: imageSKU
        version: 'latest'
      }
      osDisk: {
        name: '${vmName_var}_OSDisk'
        caching: 'ReadWrite'
        createOption: 'FromImage'
      }
    }
    networkProfile: {
      networkInterfaces: [
        {
          id: nicName.id
        }
      ]
    }
  }
  dependsOn: [
    newStorageAccountName_res
  ]
}

resource vmName_newuserscript 'Microsoft.Compute/virtualMachines/extensions@2015-05-01-preview' = {
  name: '${vmName_var}/newuserscript'
  location: location
  properties: {
    publisher: 'Microsoft.Azure.Extensions'
    type: 'CustomScript'
    typeHandlerVersion: '2.0'
    autoUpgradeMinorVersion: true
    settings: {
      fileUris: [
        'https://raw.githubusercontent.com/meet-bhagdev/templates/master/django-sql-app/install_django.sh'
      ]
    }
    protectedSettings: {
      commandToExecute: 'sh install_django.sh ${vmDnsName} ${serverName} ${administratorLogin} ${administratorLoginPassword} ${databaseName}'
    }
  }
  dependsOn: [
    vmName
  ]
}