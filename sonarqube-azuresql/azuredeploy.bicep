@minLength(1)
@description('Name of the VM that SonarQube will be installed upon')
param sqVM_AppName string = 'sonarqube-vm'

@minLength(1)
@maxLength(32)
@description('The prefix of the public URL for the VM on the Internet. It should be unique across all Azure and match with the following regular expression: ^[a-z][a-z0-9-]{1,61}[a-z0-9]$ or it will raise an error.')
param sq_PublicIP_DnsPrefix string = 'sonar-${uniqueString(resourceGroup().id)}'

@minLength(3)
@description('Admin account name for the SonarQube VM')
param sqVM_AppAdmin_UserName string

@description('Password for the SonarQube VM Admin account')
@secure()
param sqVM_AppAdmin_Password string

@minLength(1)
@description('Admin account name for Azure SQL Server')
param sqDB_Admin_UserName string

@description('Password for Azure SQL Server Admin account')
@secure()
param sqDB_Admin_Password string

@minLength(1)
@maxLength(10)
@description('Name of Azure SQL Server (limit to 10 chars or less)')
param sqDB_ServerName string = 'sonarsql'

@minLength(1)
@description('Name of the SonarQube DB on the Azure SQL Server')
param sqDB_DBName string = 'sonar'

@allowed([
  'Basic'
  'Standard'
  'Premium'
])
@description('Edition of Azure SQL Database to create')
param sqDB_DBEdition string = 'Basic'

@allowed([
  'StandardSSD_LRS'
  'Standard_LRS'
  'Premium_LRS'
])
@description('Type of Azure Storage Acct to create')
param diskType string = 'StandardSSD_LRS'

@allowed([
  'Secure'
  'Nonsecure'
])
@description('Type of SonarQube installation, Secure (HTTPS) or non-secure (HTTP)')
param sqVM_Installation_Type string = 'Secure'

@allowed([
  'IIS'
])
@description('Type of Reverse Proxy to secure SonarQube')
param sqVM_ReverseProxy_Type string = 'IIS'

@allowed([
  'sonarqube-8.4.1.35646'
  'sonarqube-8.3.1.34397'
  'sonarqube-8.2.0.32929'
  'sonarqube-8.1.0.31237'
  'sonarqube-8.0'
  'sonarqube-7.9.3'
  'sonarqube-6.7.7'
  'sonarqube-5.6.7'
])
@description('Version of SonarQube to install')
param sqVM_LTS_Version string = 'sonarqube-8.4.1.35646'

@description('Location to download the installation binary of SonarQube from')
param sonarQubeDownloadRoot string = 'https://binaries.sonarsource.com/Distribution/sonarqube/'

@description('The base URI where artifacts required by this template are located. When the template is deployed using the accompanying scripts, a private location in the subscription will be used and this value will be automatically generated.')
param artifactsLocation string = 'https://raw.githubusercontent.com/Azure/azure-quickstart-templates/master/sonarqube-azuresql/'

@description('Location for all resources.')
param location string = resourceGroup().location

@description('The sasToken required to access _artifactsLocation.  When the template is deployed using the accompanying scripts, a sasToken will be automatically generated.')
@secure()
param artifactsLocationSasToken string = ''

@description('Size fo the VM')
param SQvmAppVmSize string = 'Standard_DS1_v2'

var SQvnetPrefix = '10.0.0.0/16'
var SQvnetExternalSubnetName = 'Subnet-External'
var SQvnetExternalSubnetPrefix = '10.0.0.0/24'
var SQvnetInternalSubnetPrefix = '10.0.1.0/24'
var SQvmAppImagePublisher = 'MicrosoftWindowsServer'
var SQvmAppImageOffer = 'WindowsServer'
var SQvmAppWindowsOSVersion = '2019-Datacenter'
var SQvmAppSubnetRef = resourceId('Microsoft.Network/virtualNetworks/subnets', 'SQvnet', SQvnetExternalSubnetName)
var SQvmAppNicName_var = '${sqVM_AppName}NetworkInterface'
var SQpublicIPName_var = 'SQpublicIP'
var dscZipFile = 'DSC/SQdscAppConfiguration.ps1.zip'
var SQdscAppConfigurationFunction = 'SQdscAppConfiguration.ps1\\Main'
var AzureSqlServerName = concat(sqDB_ServerName, uniqueString(resourceGroup().id))
var SQDBTemplateLocation = uri(artifactsLocation, 'nested/azureDBDeploy.json${artifactsLocationSasToken}')

module deploySQLDB '?' /*TODO: replace with correct path to [variables('SQDBTemplateLocation')]*/ = {
  name: 'deploySQLDB'
  params: {
    adminLogin: sqDB_Admin_UserName
    adminPassword: sqDB_Admin_Password
    sonarSqlName: AzureSqlServerName
    sonarDbName: sqDB_DBName
    sonarEdition: sqDB_DBEdition
    location: location
  }
}

resource SQvnet 'Microsoft.Network/virtualNetworks@2020-05-01' = {
  name: 'SQvnet'
  location: location
  tags: {
    displayName: 'SQvnet'
  }
  properties: {
    addressSpace: {
      addressPrefixes: [
        SQvnetPrefix
      ]
    }
    subnets: [
      {
        name: SQvnetExternalSubnetName
        properties: {
          addressPrefix: SQvnetExternalSubnetPrefix
          networkSecurityGroup: {
            id: SQnsgApp.id
          }
        }
      }
    ]
  }
}

resource SQvmAppNicName 'Microsoft.Network/networkInterfaces@2020-05-01' = {
  name: SQvmAppNicName_var
  location: location
  tags: {
    displayName: 'SQvmAppNic'
  }
  properties: {
    ipConfigurations: [
      {
        name: 'ipconfig1'
        properties: {
          privateIPAllocationMethod: 'Dynamic'
          subnet: {
            id: SQvmAppSubnetRef
          }
          publicIPAddress: {
            id: SQpublicIPName.id
          }
        }
      }
    ]
  }
  dependsOn: [
    SQvnet
  ]
}

resource sqVM_AppName_resource 'Microsoft.Compute/virtualMachines@2020-06-01' = {
  name: sqVM_AppName
  location: location
  tags: {
    displayName: 'SQvmApp'
  }
  properties: {
    hardwareProfile: {
      vmSize: SQvmAppVmSize
    }
    osProfile: {
      computerName: sqVM_AppName
      adminUsername: sqVM_AppAdmin_UserName
      adminPassword: sqVM_AppAdmin_Password
    }
    storageProfile: {
      imageReference: {
        publisher: SQvmAppImagePublisher
        offer: SQvmAppImageOffer
        sku: SQvmAppWindowsOSVersion
        version: 'latest'
      }
      osDisk: {
        name: '${sqVM_AppName}_OSDisk'
        caching: 'ReadWrite'
        createOption: 'FromImage'
        managedDisk: {
          storageAccountType: diskType
        }
      }
    }
    networkProfile: {
      networkInterfaces: [
        {
          id: SQvmAppNicName.id
        }
      ]
    }
  }
}

resource sqVM_AppName_configureAppVM_DSC 'Microsoft.Compute/virtualMachines/extensions@2020-06-01' = {
  parent: sqVM_AppName_resource
  name: 'configureAppVM_DSC'
  location: location
  properties: {
    publisher: 'Microsoft.Powershell'
    type: 'DSC'
    typeHandlerVersion: '2.9'
    autoUpgradeMinorVersion: true
    protectedSettings: {
      modulesUrl: uri(artifactsLocation, concat(dscZipFile, artifactsLocationSasToken))
      configurationFunction: SQdscAppConfigurationFunction
      properties: {
        nodeName: sqVM_AppName
        sqVM_AppAdmin_UserName: sqVM_AppAdmin_UserName
        connectionString: reference('deploySQLDB').outputs.jdbcConnString.value
        connectionUsername: sqDB_Admin_UserName
        connectionPassword: sqDB_Admin_Password
        sqVmAdminPwd: sqVM_AppAdmin_Password
        sqLtsVersion: sqVM_LTS_Version
        sonarQubeDownloadRoot: sonarQubeDownloadRoot
      }
    }
  }
}

resource sqVM_AppName_secureSonarQube 'Microsoft.Compute/virtualMachines/extensions@2020-06-01' = {
  parent: sqVM_AppName_resource
  name: 'secureSonarQube'
  location: location
  tags: {
    displayName: 'secureSonarQube'
  }
  properties: {
    publisher: 'Microsoft.Compute'
    type: 'CustomScriptExtension'
    typeHandlerVersion: '1.4'
    autoUpgradeMinorVersion: true
    settings: {
      fileUris: [
        uri(artifactsLocation, 'secureSonarQube.ps1${artifactsLocationSasToken}')
      ]
      commandToExecute: 'powershell -ExecutionPolicy Unrestricted -File secureSonarQube.ps1 -serverName ${reference(SQpublicIPName_var).dnsSettings.fqdn} -websiteName SonarQubeProxy -installationType ${sqVM_Installation_Type} -reverseProxyType ${sqVM_ReverseProxy_Type}'
    }
  }
  dependsOn: [
    sqVM_AppName_configureAppVM_DSC
  ]
}

resource SQpublicIPName 'Microsoft.Network/publicIPAddresses@2020-05-01' = {
  name: SQpublicIPName_var
  location: location
  tags: {
    displayName: 'SQpublicIP'
  }
  properties: {
    publicIPAllocationMethod: 'Dynamic'
    dnsSettings: {
      domainNameLabel: sq_PublicIP_DnsPrefix
    }
  }
}

resource SQnsgApp 'Microsoft.Network/networkSecurityGroups@2020-05-01' = {
  name: 'SQnsgApp'
  location: location
  tags: {
    displayName: 'SQnsgApp'
  }
  properties: {
    securityRules: [
      {
        name: 'Allow_RDP_In'
        properties: {
          description: 'Allow RDP In'
          protocol: 'Tcp'
          sourcePortRange: '*'
          destinationPortRange: '3389'
          sourceAddressPrefix: 'Internet'
          destinationAddressPrefix: '*'
          access: 'Allow'
          priority: 100
          direction: 'Inbound'
        }
      }
      {
        name: 'Allow_HTTPS_In'
        properties: {
          description: 'Allow HTTPS In'
          protocol: 'Tcp'
          sourcePortRange: '*'
          destinationPortRange: '443'
          sourceAddressPrefix: 'Internet'
          destinationAddressPrefix: '*'
          access: 'Allow'
          priority: 101
          direction: 'Inbound'
        }
      }
      {
        name: 'Allow_RDP_Out'
        properties: {
          description: 'Allow RDP Out'
          protocol: 'Tcp'
          sourcePortRange: '*'
          destinationPortRange: '3389'
          sourceAddressPrefix: SQvnetExternalSubnetPrefix
          destinationAddressPrefix: SQvnetInternalSubnetPrefix
          access: 'Allow'
          priority: 100
          direction: 'Outbound'
        }
      }
      {
        name: 'Allow_SonarQube_In'
        properties: {
          description: 'Allow SonarQube In'
          protocol: 'Tcp'
          sourcePortRange: '*'
          destinationPortRange: '9000'
          sourceAddressPrefix: 'Internet'
          destinationAddressPrefix: '*'
          access: 'Allow'
          priority: 102
          direction: 'Inbound'
        }
      }
      {
        name: 'Block_All_In'
        properties: {
          description: 'Block everything else'
          protocol: '*'
          sourcePortRange: '*'
          destinationPortRange: '*'
          sourceAddressPrefix: 'Internet'
          destinationAddressPrefix: '*'
          access: 'Deny'
          priority: 200
          direction: 'Inbound'
        }
      }
    ]
  }
}

output HTTP_Url string = '${reference(SQpublicIPName_var).dnsSettings.fqdn}:9000'
output HTTPS_Url string = 'https://${reference(SQpublicIPName_var).dnsSettings.fqdn}'