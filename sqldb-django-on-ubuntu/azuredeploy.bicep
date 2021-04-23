@description('Name of the Storage Account')
param newStorageAccountName string

@description('Username for the Administrator of the VM')
param adminUsername string

@description('Image Publisher')
param imagePublisher string = 'Canonical'

@description('Image Offer')
param imageOffer string = 'UbuntuServer'

@description('Image SKU')
param imageSKU string = '14.04.5-LTS'

@description('DNS Name for the Public IP. Must be lowercase.')
param vmDnsName string

@description('Admin username for SQL Database')
param administratorLogin string

@description('Admin password for SQL Database')
@secure()
param administratorLoginPassword string

@description('SQL Collation')
param collation string = 'SQL_Latin1_General_CP1_CI_AS'

@description('Name of your SQL Database')
param databaseName string

@allowed([
  'Basic'
  'Standard'
  'Premium'
])
@description('SQL Database Edition')
param edition string

@description('Max DB size in bytes')
param maxSizeBytes string = '268435456000'

@description('Requested Service Objective ID')
param requestedServiceObjectiveId string = 'f1173c43-91bd-4aaa-973c-54e79e15235b'

@description('Unique name of your SQL Server')
param serverName string

@description('Start IP for your firewall rule, for example 0.0.0.0')
param firewallStartIP string

@description('End IP for your firewall rule, for example 255.255.255.255')
param firewallEndIP string

@description('SQL Version')
param version string = '12.0'

@description('Location for all resources.')
param location string = resourceGroup().location

@allowed([
  'sshPublicKey'
  'password'
])
@description('Type of authentication to use on the Virtual Machine. SSH key is recommended.')
param authenticationType string = 'sshPublicKey'

@description('SSH Key or password for the Virtual Machine. SSH key is recommended.')
@secure()
param adminPasswordOrKey string

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

resource serverName_resource 'Microsoft.Sql/servers@2014-04-01-preview' = {
  location: location
  name: serverName
  properties: {
    administratorLogin: administratorLogin
    administratorLoginPassword: administratorLoginPassword
    version: version
  }
}

resource serverName_databaseName 'Microsoft.Sql/servers/databases@2014-04-01-preview' = {
  parent: serverName_resource
  location: location
  name: '${databaseName}'
  properties: {
    collation: collation
    edition: edition
    maxSizeBytes: maxSizeBytes
    requestedServiceObjectiveId: requestedServiceObjectiveId
  }
}

resource serverName_FirewallRule1 'Microsoft.Sql/servers/firewallrules@2014-04-01-preview' = {
  parent: serverName_resource
  location: location
  name: 'FirewallRule1'
  properties: {
    endIpAddress: firewallEndIP
    startIpAddress: firewallStartIP
  }
}

resource newStorageAccountName_resource 'Microsoft.Storage/storageAccounts@2015-05-01-preview' = {
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
    newStorageAccountName_resource
  ]
}

resource vmName_newuserscript 'Microsoft.Compute/virtualMachines/extensions@2015-05-01-preview' = {
  parent: vmName
  name: 'newuserscript'
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
}