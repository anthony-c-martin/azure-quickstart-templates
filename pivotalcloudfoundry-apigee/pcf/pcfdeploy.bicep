param apigeeEdge string
param managementUI string
param managementDNSName string
param runtimePublicDNSName string
param apigeeAdminPassword string {
  secure: true
}
param apigeeAdminEmail string
param storageAccountNamePrefixString string {
  metadata: {
    description: 'Unique DNS Name for the Storage Account prefix where the Virtual Machine\'s disks will be placed. It can not be more than 10 characters in length and use numbers and lower-case letters only.'
  }
}
param virtualNetworkName string {
  metadata: {
    description: 'name of the virtual network'
  }
  default: 'boshvnet-crp'
}
param subnetNameForBosh string {
  metadata: {
    description: 'name of the subnet for Bosh'
  }
  default: 'Bosh'
}
param NSGNameForBosh string {
  metadata: {
    description: 'name of the security group for Bosh'
  }
  default: 'BoshSecurityGroup'
}
param subnetNameForCloudFoundry string {
  metadata: {
    description: 'name of the subnet for CloudFoundy'
  }
  default: 'CloudFoundry'
}
param NSGNameForCF string {
  metadata: {
    description: 'name of the security group for CF'
  }
  default: 'CFSecurityGroup'
}
param vmSize string {
  metadata: {
    description: 'Size of vm'
  }
  default: 'Standard_D2_v2'
}
param adminUsername string {
  metadata: {
    description: 'User name for the Virtual Machine.'
  }
  default: 'pivotal'
}
param adminSSHKey string {
  metadata: {
    description: 'Public SSH key to add to admin user.'
  }
  secure: true
}
param enableDNSOnDevbox bool {
  allowed: [
    true
    false
  ]
  metadata: {
    description: 'A default DNS will be setup in the devbox if it is true.'
  }
  default: true
}
param tenantID string {
  metadata: {
    description: 'ID of the tenant. See https://github.com/cloudfoundry-incubator/bosh-azure-cpi-release/blob/master/docs/guidance.md'
  }
  default: 'TENANT-ID'
}
param clientID string {
  metadata: {
    description: 'ID of the client. See https://github.com/cloudfoundry-incubator/bosh-azure-cpi-release/blob/master/docs/guidance.md'
  }
  default: 'CLIENT-ID'
}
param clientSecret string {
  metadata: {
    description: 'secret of the client. See https://github.com/cloudfoundry-incubator/bosh-azure-cpi-release/blob/master/docs/guidance.md'
  }
  secure: true
  default: 'CLIENT-SECRET'
}
param pivnetAPIToken string {
  metadata: {
    description: 'API Token for Pivotal Network'
  }
  default: ''
}
param metabrokerEnvironment string {
  metadata: {
    description: 'AzureCloud or AzureChinaCloud'
  }
  default: 'AzureCloud'
}
param installSize string {
  metadata: {
    description: 'Size of the install'
  }
  default: 'Small'
}
param location string {
  metadata: {
    description: 'location where you want to deploy resources'
  }
  default: 'westus'
}

var api_version = '2015-06-15'
var extensionName = 'initdevbox'
var newStorageAccountName_var = concat(storageAccountNamePrefixString, uniqueString(resourceGroup().id, deployment().name))
var databaseAccountName_var = 'docdb${uniqueString(resourceGroup().id, deployment().name)}'
var sqlServerAdminLogin = 'sqladmin'
var sqlServerAdminPassword = concat(clientSecret, uniqueString(resourceGroup().id, deployment().name))
var sqlServerName_var = 'sqlserver${uniqueString(resourceGroup().id, deployment().name)}'
var sqlDatabaseName = 'azuremetabroker'
var vmName_var = 'myjumpbox${uniqueString(resourceGroup().id, deployment().name)}'
var location_var = location
var storageAccountType = 'Standard_GRS'
var vmStorageAccountContainerName = 'vhds'
var storageid = newStorageAccountName.id
var virtualNetworkName_var = virtualNetworkName
var sshKeyPath = '/home/${adminUsername}/.ssh/authorized_keys'
var addressPrefix = '10.0.0.0/16'
var vnetID = virtualNetworkName_res.id
var subnet1Name = subnetNameForBosh
var subnet1Prefix = '10.0.0.0/24'
var subnet1Ref = '${vnetID}/subnets/${subnet1Name}'
var subnet1NSG_var = NSGNameForBosh
var subnet2Name = subnetNameForCloudFoundry
var subnet2Prefix = '10.0.16.0/20'
var subnet2NSG_var = NSGNameForCF
var nicName_var = vmName_var
var devboxPrivateIPAddress = '10.0.0.100'
var devboxPublicIPAddressID = vmName_devbox.id
var imagePublisher = 'Canonical'
var imageOffer = 'UbuntuServer'
var ubuntuOSVersion = '14.04.5-LTS'
var webSessionPassword = uniqueString(adminSSHKey)

resource newStorageAccountName 'Microsoft.Storage/storageAccounts@2015-06-15' = {
  name: newStorageAccountName_var
  location: location_var
  properties: {
    accountType: storageAccountType
  }
}

resource vmName_devbox 'Microsoft.Network/publicIPAddresses@2015-06-15' = {
  name: '${vmName_var}-devbox'
  location: location_var
  properties: {
    publicIPAllocationMethod: 'dynamic'
    dnsSettings: {
      domainNameLabel: vmName_var
    }
  }
}

resource vmName_bosh 'Microsoft.Network/publicIPAddresses@2015-06-15' = {
  name: '${vmName_var}-bosh'
  location: location_var
  properties: {
    publicIPAllocationMethod: 'static'
  }
}

resource vmName_cf 'Microsoft.Network/publicIPAddresses@2015-06-15' = {
  name: '${vmName_var}-cf'
  location: location_var
  properties: {
    publicIPAllocationMethod: 'static'
  }
}

resource subnet1NSG 'Microsoft.Network/networkSecurityGroups@2015-06-15' = {
  name: subnet1NSG_var
  location: location_var
  properties: {
    securityRules: [
      {
        name: 'allow-ssh-to-jumpbox'
        properties: {
          description: 'Allow Inbound SSH To Jumpbox'
          protocol: '*'
          sourcePortRange: '*'
          destinationPortRange: '22'
          sourceAddressPrefix: '*'
          destinationAddressPrefix: '${devboxPrivateIPAddress}/32'
          access: 'Allow'
          priority: 1000
          direction: 'Inbound'
        }
      }
      {
        name: 'allow-https-to-jumpbox'
        properties: {
          description: 'Allow Inbound HTTPS To Jumpbox'
          protocol: '*'
          sourcePortRange: '*'
          destinationPortRange: '443'
          sourceAddressPrefix: '*'
          destinationAddressPrefix: '${devboxPrivateIPAddress}/32'
          access: 'Allow'
          priority: 1100
          direction: 'Inbound'
        }
      }
    ]
  }
}

resource subnet2NSG 'Microsoft.Network/networkSecurityGroups@2015-06-15' = {
  name: subnet2NSG_var
  location: location_var
}

resource virtualNetworkName_res 'Microsoft.Network/virtualNetworks@2015-06-15' = {
  name: virtualNetworkName_var
  location: location_var
  properties: {
    addressSpace: {
      addressPrefixes: [
        addressPrefix
      ]
    }
    subnets: [
      {
        name: subnet1Name
        properties: {
          addressPrefix: subnet1Prefix
          networkSecurityGroup: {
            id: subnet1NSG.id
          }
        }
      }
      {
        name: subnet2Name
        properties: {
          addressPrefix: subnet2Prefix
          networkSecurityGroup: {
            id: subnet2NSG.id
          }
        }
      }
    ]
  }
}

resource nicName 'Microsoft.Network/networkInterfaces@2015-06-15' = {
  name: nicName_var
  location: location_var
  properties: {
    ipConfigurations: [
      {
        name: 'ipconfig1'
        properties: {
          privateIPAllocationMethod: 'Static'
          privateIPAddress: devboxPrivateIPAddress
          publicIPAddress: {
            id: vmName_devbox.id
          }
          subnet: {
            id: subnet1Ref
          }
        }
      }
    ]
  }
  dependsOn: [
    'Microsoft.Network/publicIPAddresses/${vmName_var}-devbox'
  ]
}

resource vmName 'Microsoft.Compute/virtualMachines@2017-03-30' = {
  name: vmName_var
  location: location_var
  properties: {
    hardwareProfile: {
      vmSize: vmSize
    }
    osProfile: {
      computerName: vmName_var
      adminUsername: adminUsername
      linuxConfiguration: {
        disablePasswordAuthentication: true
        ssh: {
          publicKeys: [
            {
              path: sshKeyPath
              keyData: adminSSHKey
            }
          ]
        }
      }
    }
    storageProfile: {
      imageReference: {
        publisher: imagePublisher
        offer: imageOffer
        sku: ubuntuOSVersion
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
}

resource databaseAccountName 'Microsoft.DocumentDB/databaseAccounts@2015-04-08' = {
  name: databaseAccountName_var
  location: resourceGroup().location
  tags: {
    displayName: 'DocumentDB'
  }
  properties: {
    name: databaseAccountName_var
    databaseAccountOfferType: 'Standard'
  }
}

resource sqlServerName 'Microsoft.Sql/servers@2014-04-01-preview' = {
  name: sqlServerName_var
  location: resourceGroup().location
  tags: {
    displayName: 'SQL Server'
  }
  properties: {
    administratorLogin: sqlServerAdminLogin
    administratorLoginPassword: sqlServerAdminPassword
    version: '12.0'
  }
  dependsOn: []
}

resource sqlServerName_AllowAllWindowsAzureIps 'Microsoft.Sql/servers/firewallrules@2014-04-01-preview' = {
  name: '${sqlServerName_var}/AllowAllWindowsAzureIps'
  location: resourceGroup().location
  properties: {
    startIpAddress: '0.0.0.0'
    endIpAddress: '0.0.0.0'
  }
}

resource sqlServerName_sqlDatabaseName 'Microsoft.Sql/servers/databases@2014-04-01-preview' = {
  name: '${sqlServerName_var}/${sqlDatabaseName}'
  location: resourceGroup().location
  tags: {
    displayName: 'SQL Database'
  }
}

resource vmName_initdevbox 'Microsoft.Compute/virtualMachines/extensions@2015-06-15' = {
  name: '${vmName_var}/initdevbox'
  location: location_var
  properties: {
    publisher: 'Microsoft.OSTCExtensions'
    type: 'CustomScriptForLinux'
    typeHandlerVersion: '1.4'
    autoUpgradeMinorVersion: false
    settings: {
      fileUris: [
        'https://s3-us-west-2.amazonaws.com/test-epsilon/bootstrap.py'
      ]
      managementUI: managementUI
      apigeeEdge: apigeeEdge
      managementDNSName: managementDNSName
      runtimePublicDNSName: runtimePublicDNSName
      adminUsername: adminUsername
      apigeeAdminPassword: apigeeAdminPassword
      apigeeAdminEmail: apigeeAdminEmail
      adminSSHKey: adminSSHKey
      commandToExecute: 'python ./bootstrap.py ${installSize} ${webSessionPassword}'
      location: location_var
      'VNET-NAME': virtualNetworkName_var
      'SUBNET-NAME': subnet1Name
      'SUBNET-NAME-FOR-CF': subnet2Name
      'NSG-NAME-FOR-CF': subnet2NSG_var
      'NSG-NAME-FOR-BOSH': subnet1NSG_var
      'SUBSCRIPTION-ID': subscription().subscriptionId
      'STORAGE-ACCOUNT-NAME': newStorageAccountName_var
      'STORAGE-ACCESS-KEY': listKeys(storageid, api_version).key1
      'RESOURCE-GROUP-NAME': resourceGroup().name
      'TENANT-ID': tenantID
      'CLIENT-ID': clientID
      'CLIENT-SECRET': clientSecret
      'cf-ip': reference('${vmName_var}-cf').ipAddress
      'bosh-ip': reference('${vmName_var}-bosh').ipAddress
      username: adminUsername
      'enable-dns': enableDNSOnDevbox
      databaseAccountName: databaseAccountName_var
      'documentdb-endpoint': reference('Microsoft.DocumentDb/databaseAccounts/${databaseAccountName_var}').documentEndpoint
      'documentdb-masterkey': listKeys(databaseAccountName.id, '2015-04-08').primaryMasterKey
      sqlServerAdminLogin: sqlServerAdminLogin
      sqlServerAdminPassword: sqlServerAdminPassword
      sqlServerName: sqlServerName_var
      sqlDatabaseName: sqlDatabaseName
      sqlServerFQDN: reference('Microsoft.Sql/servers/${sqlServerName_var}').fullyQualifiedDomainName
      metabrokerenvironment: metabrokerEnvironment
      'pivnet-api-token': pivnetAPIToken
    }
    protectedSettings: {
      'CLIENT-SECRET': clientSecret
    }
  }
}

output scriptoutput string = split(split(reference(resourceId('Microsoft.Compute/virtualMachines/extensions', vmName_var, extensionName), '2015-06-15').instanceView.statuses[0].message, '---')[2], '###QUOTACHECK###')[1]
output ProgressMonitorURL string = 'https://gamma:${webSessionPassword}@${reference('${vmName_var}-devbox').dnsSettings.fqdn}'
output JumpboxFQDN string = reference('${vmName_var}-devbox').dnsSettings.fqdn