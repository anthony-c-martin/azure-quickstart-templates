param existingVNETName string {
  metadata: {
    description: 'Existing VNET that contains the domain controller'
  }
}
param existingSubnetName string {
  metadata: {
    description: 'Existing subnet that contains the domain controller'
  }
}
param dnsLabelPrefix string {
  metadata: {
    description: 'Unique public DNS prefix for the deployment. The fqdn will look something like \'<dnsname>.westus.cloudapp.azure.com\'. Up to 62 chars, digits or dashes, lowercase, should start with a letter: must conform to \'^[a-z][a-z0-9-]{1,61}[a-z0-9]$\'.'
  }
}
param vmSize string {
  metadata: {
    description: 'The size of the virtual machines'
  }
  default: 'Standard_A2'
}
param domainToJoin string {
  metadata: {
    description: 'The FQDN of the AD domain'
  }
}
param domainUsername string {
  metadata: {
    description: 'Username of the account on the domain'
  }
}
param domainPassword string {
  metadata: {
    description: 'Password of the account on the domain'
  }
  secure: true
}
param ouPath string {
  metadata: {
    description: 'Specifies an organizational unit (OU) for the domain account. Enter the full distinguished name of the OU in quotation marks. Example: "OU=testOU; DC=domain; DC=Domain; DC=com"'
  }
  default: ''
}
param domainJoinOptions int {
  metadata: {
    description: 'Set of bit flags that define the join options. Default value of 3 is a combination of NETSETUP_JOIN_DOMAIN (0x00000001) & NETSETUP_ACCT_CREATE (0x00000002) i.e. will join the domain and create the account on the domain. For more information see https://msdn.microsoft.com/en-us/library/aa392154(v=vs.85).aspx'
  }
  default: 3
}
param vmAdminUsername string {
  metadata: {
    description: 'The name of the administrator of the new VM and the domain. Exclusion list: \'admin\',\'administrator'
  }
}
param vmAdminPassword string {
  metadata: {
    description: 'The password for the administrator account of the new VM and the domain'
  }
  secure: true
}
param location string {
  metadata: {
    description: 'Location for all resources.'
  }
  default: resourceGroup().location
}

var storageAccountName_var = concat(uniqueString(resourceGroup().id, deployment().name))
var imagePublisher = 'MicrosoftWindowsServer'
var imageOffer = 'WindowsServer'
var windowsOSVersion = '2016-Datacenter'
var nicName_var = '${dnsLabelPrefix}Nic'
var publicIPName_var = '${dnsLabelPrefix}Pip'
var subnetId = resourceId(resourceGroup().name, 'Microsoft.Network/virtualNetworks/subnets', existingVNETName, existingSubnetName)

resource publicIPName 'Microsoft.Network/publicIPAddresses@2015-06-15' = {
  name: publicIPName_var
  location: location
  properties: {
    publicIPAllocationMethod: 'Dynamic'
    dnsSettings: {
      domainNameLabel: dnsLabelPrefix
    }
  }
}

resource storageAccountName 'Microsoft.Storage/storageAccounts@2015-06-15' = {
  name: storageAccountName_var
  location: location
  properties: {
    accountType: 'Standard_LRS'
  }
}

resource nicName 'Microsoft.Network/networkInterfaces@2015-06-15' = {
  name: nicName_var
  location: location
  properties: {
    ipConfigurations: [
      {
        name: 'ipconfig'
        properties: {
          privateIPAllocationMethod: 'Dynamic'
          publicIPAddress: {
            id: publicIPName.id
          }
          subnet: {
            id: subnetId
          }
        }
      }
    ]
  }
}

resource dnsLabelPrefix_res 'Microsoft.Compute/virtualMachines@2017-03-30' = {
  name: dnsLabelPrefix
  location: location
  properties: {
    hardwareProfile: {
      vmSize: vmSize
    }
    osProfile: {
      computerName: dnsLabelPrefix
      adminUsername: vmAdminUsername
      adminPassword: vmAdminPassword
    }
    storageProfile: {
      imageReference: {
        publisher: imagePublisher
        offer: imageOffer
        sku: windowsOSVersion
        version: 'latest'
      }
      osDisk: {
        name: '${dnsLabelPrefix}_OsDisk'
        caching: 'ReadWrite'
        createOption: 'FromImage'
      }
      dataDisks: [
        {
          name: '${dnsLabelPrefix}_dataDisk1'
          caching: 'None'
          createOption: 'Empty'
          diskSizeGB: '1000'
          lun: 0
        }
      ]
    }
    networkProfile: {
      networkInterfaces: [
        {
          id: nicName.id
        }
      ]
    }
    diagnosticsProfile: {
      bootDiagnostics: {
        enabled: true
        storageUri: reference('Microsoft.Storage/storageAccounts/${storageAccountName_var}', '2015-06-15').primaryEndpoints.blob
      }
    }
  }
  dependsOn: [
    storageAccountName
  ]
}

resource dnsLabelPrefix_joindomain 'Microsoft.Compute/virtualMachines/extensions@2015-06-15' = {
  name: '${dnsLabelPrefix}/joindomain'
  location: location
  properties: {
    publisher: 'Microsoft.Compute'
    type: 'JsonADDomainExtension'
    typeHandlerVersion: '1.3'
    autoUpgradeMinorVersion: true
    settings: {
      Name: domainToJoin
      OUPath: ouPath
      User: '${domainToJoin}\\${domainUsername}'
      Restart: 'true'
      Options: domainJoinOptions
    }
    protectedSettings: {
      Password: domainPassword
    }
  }
  dependsOn: [
    dnsLabelPrefix_res
  ]
}