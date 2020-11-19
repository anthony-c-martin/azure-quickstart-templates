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
var newStorageAccountName = concat(storageAccountNamePrefixString, uniqueString(resourceGroup().id, deployment().name))
var databaseAccountName = 'docdb${uniqueString(resourceGroup().id, deployment().name)}'
var sqlServerAdminLogin = 'sqladmin'
var sqlServerAdminPassword = concat(clientSecret, uniqueString(resourceGroup().id, deployment().name))
var sqlServerName = 'sqlserver${uniqueString(resourceGroup().id, deployment().name)}'
var sqlDatabaseName = 'azuremetabroker'
var vmName = 'myjumpbox${uniqueString(resourceGroup().id, deployment().name)}'
var location_variable = location
var storageAccountType = 'Standard_GRS'
var vmStorageAccountContainerName = 'vhds'
var storageid = newStorageAccountName_resource.id
var virtualNetworkName_variable = virtualNetworkName
var sshKeyPath = '/home/${adminUsername}/.ssh/authorized_keys'
var addressPrefix = '10.0.0.0/16'
var vnetID = virtualNetworkName_resource.id
var subnet1Name = subnetNameForBosh
var subnet1Prefix = '10.0.0.0/24'
var subnet1Ref = '${vnetID}/subnets/${subnet1Name}'
var subnet1NSG = NSGNameForBosh
var subnet2Name = subnetNameForCloudFoundry
var subnet2Prefix = '10.0.16.0/20'
var subnet2NSG = NSGNameForCF
var nicName = vmName
var devboxPrivateIPAddress = '10.0.0.100'
var devboxPublicIPAddressID = vmName_devbox.id
var imagePublisher = 'Canonical'
var imageOffer = 'UbuntuServer'
var ubuntuOSVersion = '14.04.5-LTS'
var webSessionPassword = uniqueString(adminSSHKey)

resource newStorageAccountName_resource 'Microsoft.Storage/storageAccounts@2015-06-15' = {
  name: newStorageAccountName
  location: location_variable
  properties: {
    accountType: storageAccountType
  }
}

resource vmName_devbox 'Microsoft.Network/publicIPAddresses@2015-06-15' = {
  name: '${vmName}-devbox'
  location: location_variable
  properties: {
    publicIPAllocationMethod: 'dynamic'
    dnsSettings: {
      domainNameLabel: vmName
    }
  }
}

resource vmName_bosh 'Microsoft.Network/publicIPAddresses@2015-06-15' = {
  name: '${vmName}-bosh'
  location: location_variable
  properties: {
    publicIPAllocationMethod: 'static'
  }
}

resource vmName_cf 'Microsoft.Network/publicIPAddresses@2015-06-15' = {
  name: '${vmName}-cf'
  location: location_variable
  properties: {
    publicIPAllocationMethod: 'static'
  }
}

resource subnet1NSG_resource 'Microsoft.Network/networkSecurityGroups@2015-06-15' = {
  name: subnet1NSG
  location: location_variable
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

resource subnet2NSG_resource 'Microsoft.Network/networkSecurityGroups@2015-06-15' = {
  name: subnet2NSG
  location: location_variable
}

resource virtualNetworkName_resource 'Microsoft.Network/virtualNetworks@2015-06-15' = {
  name: virtualNetworkName_variable
  location: location_variable
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
            id: subnet1NSG_resource.id
          }
        }
      }
      {
        name: subnet2Name
        properties: {
          addressPrefix: subnet2Prefix
          networkSecurityGroup: {
            id: subnet2NSG_resource.id
          }
        }
      }
    ]
  }
  dependsOn: [
    subnet1NSG_resource
    subnet2NSG_resource
  ]
}

resource nicName_resource 'Microsoft.Network/networkInterfaces@2015-06-15' = {
  name: nicName
  location: location_variable
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
    'Microsoft.Network/publicIPAddresses/${vmName}-devbox'
    virtualNetworkName_resource
  ]
}

resource vmName_resource 'Microsoft.Compute/virtualMachines@2017-03-30' = {
  name: vmName
  location: location_variable
  properties: {
    hardwareProfile: {
      vmSize: vmSize
    }
    osProfile: {
      computerName: vmName
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
        name: '${vmName}_OSDisk'
        caching: 'ReadWrite'
        createOption: 'FromImage'
      }
    }
    networkProfile: {
      networkInterfaces: [
        {
          id: nicName_resource.id
        }
      ]
    }
  }
  dependsOn: [
    newStorageAccountName_resource
    nicName_resource
  ]
}

resource databaseAccountName_resource 'Microsoft.DocumentDB/databaseAccounts@2015-04-08' = {
  name: databaseAccountName
  location: resourceGroup().location
  tags: {
    displayName: 'DocumentDB'
  }
  properties: {
    name: databaseAccountName
    databaseAccountOfferType: 'Standard'
  }
}

resource sqlServerName_resource 'Microsoft.Sql/servers@2014-04-01-preview' = {
  name: sqlServerName
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
  name: '${sqlServerName}/AllowAllWindowsAzureIps'
  location: resourceGroup().location
  properties: {
    startIpAddress: '0.0.0.0'
    endIpAddress: '0.0.0.0'
  }
  dependsOn: [
    sqlServerName_resource
  ]
}

resource sqlServerName_sqlDatabaseName 'Microsoft.Sql/servers/databases@2014-04-01-preview' = {
  name: '${sqlServerName}/${sqlDatabaseName}'
  location: resourceGroup().location
  tags: {
    displayName: 'SQL Database'
  }
  dependsOn: [
    sqlServerName_resource
  ]
}

resource vmName_initdevbox 'Microsoft.Compute/virtualMachines/extensions@2015-06-15' = {
  name: '${vmName}/initdevbox'
  location: location_variable
  properties: {
    publisher: 'Microsoft.OSTCExtensions'
    type: 'CustomScriptForLinux'
    typeHandlerVersion: '1.4'
    autoupgradeMinorVersion: false
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
      location: location_variable
      'VNET-NAME': virtualNetworkName_variable
      'SUBNET-NAME': subnet1Name
      'SUBNET-NAME-FOR-CF': subnet2Name
      'NSG-NAME-FOR-CF': subnet2NSG
      'NSG-NAME-FOR-BOSH': subnet1NSG
      'SUBSCRIPTION-ID': subscription().subscriptionId
      'STORAGE-ACCOUNT-NAME': newStorageAccountName
      'STORAGE-ACCESS-KEY': listKeys(storageid, api_version).key1
      'RESOURCE-GROUP-NAME': resourceGroup().name
      'TENANT-ID': tenantID
      'CLIENT-ID': clientID
      'CLIENT-SECRET': clientSecret
      'cf-ip': reference('${vmName}-cf').ipAddress
      'bosh-ip': reference('${vmName}-bosh').ipAddress
      username: adminUsername
      'enable-dns': enableDNSOnDevbox
      databaseAccountName: databaseAccountName
      'documentdb-endpoint': reference('Microsoft.DocumentDb/databaseAccounts/${databaseAccountName}').documentEndpoint
      'documentdb-masterkey': listKeys(databaseAccountName_resource.id, '2015-04-08').primaryMasterKey
      sqlServerAdminLogin: sqlServerAdminLogin
      sqlServerAdminPassword: sqlServerAdminPassword
      sqlServerName: sqlServerName
      sqlDatabaseName: sqlDatabaseName
      sqlServerFQDN: reference('Microsoft.Sql/servers/${sqlServerName}').fullyQualifiedDomainName
      metabrokerenvironment: metabrokerEnvironment
      'pivnet-api-token': pivnetAPIToken
    }
    protectedSettings: {
      'CLIENT-SECRET': clientSecret
    }
  }
  dependsOn: [
    vmName_resource
  ]
}

output scriptoutput string = split(split(reference(resourceId('Microsoft.Compute/virtualMachines/extensions', vmName, extensionName), '2015-06-15').instanceView.statuses[0].message, '---')[2], '###QUOTACHECK###')[1]
output ProgressMonitorURL string = 'https://gamma:${webSessionPassword}@${reference('${vmName}-devbox').dnsSettings.fqdn}'
output JumpboxFQDN string = reference('${vmName}-devbox').dnsSettings.fqdn