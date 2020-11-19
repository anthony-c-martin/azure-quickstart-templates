param sqVM_AppName string {
  minLength: 1
  metadata: {
    description: 'Name of the VM that SonarQube will be installed upon'
  }
  default: 'sonarqube-vm'
}
param sq_PublicIP_DnsPrefix string {
  minLength: 1
  maxLength: 32
  metadata: {
    description: 'The prefix of the public URL for the VM on the Internet. It should be unique across all Azure and match with the following regular expression: ^[a-z][a-z0-9-]{1,61}[a-z0-9]$ or it will raise an error.'
  }
  default: 'sonar-${uniqueString(resourceGroup().id)}'
}
param sqVM_AppAdmin_UserName string {
  minLength: 3
  metadata: {
    description: 'Admin account name for the SonarQube VM'
  }
}
param sqVM_AppAdmin_Password string {
  metadata: {
    description: 'Password for the SonarQube VM Admin account'
  }
  secure: true
}
param sqDB_Admin_UserName string {
  minLength: 1
  metadata: {
    description: 'Admin account name for Azure SQL Server'
  }
}
param sqDB_Admin_Password string {
  metadata: {
    description: 'Password for Azure SQL Server Admin account'
  }
  secure: true
}
param sqDB_ServerName string {
  minLength: 1
  maxLength: 10
  metadata: {
    description: 'Name of Azure SQL Server (limit to 10 chars or less)'
  }
  default: 'sonarsql'
}
param sqDB_DBName string {
  minLength: 1
  metadata: {
    description: 'Name of the SonarQube DB on the Azure SQL Server'
  }
  default: 'sonar'
}
param sqDB_DBEdition string {
  allowed: [
    'Basic'
    'Standard'
    'Premium'
  ]
  metadata: {
    description: 'Edition of Azure SQL Database to create'
  }
  default: 'Basic'
}
param diskType string {
  allowed: [
    'StandardSSD_LRS'
    'Standard_LRS'
    'Premium_LRS'
  ]
  metadata: {
    description: 'Type of Azure Storage Acct to create'
  }
  default: 'StandardSSD_LRS'
}
param sqVM_Installation_Type string {
  allowed: [
    'Secure'
    'Nonsecure'
  ]
  metadata: {
    description: 'Type of SonarQube installation, Secure (HTTPS) or non-secure (HTTP)'
  }
  default: 'Secure'
}
param sqVM_ReverseProxy_Type string {
  allowed: [
    'IIS'
  ]
  metadata: {
    description: 'Type of Reverse Proxy to secure SonarQube'
  }
  default: 'IIS'
}
param sqVM_LTS_Version string {
  allowed: [
    'sonarqube-8.4.1.35646'
    'sonarqube-8.3.1.34397'
    'sonarqube-8.2.0.32929'
    'sonarqube-8.1.0.31237'
    'sonarqube-8.0'
    'sonarqube-7.9.3'
    'sonarqube-6.7.7'
    'sonarqube-5.6.7'
  ]
  metadata: {
    description: 'Version of SonarQube to install'
  }
  default: 'sonarqube-8.4.1.35646'
}
param sonarQubeDownloadRoot string {
  metadata: {
    description: 'Location to download the installation binary of SonarQube from'
  }
  default: 'https://binaries.sonarsource.com/Distribution/sonarqube/'
}
param artifactsLocation string {
  metadata: {
    description: 'The base URI where artifacts required by this template are located. When the template is deployed using the accompanying scripts, a private location in the subscription will be used and this value will be automatically generated.'
  }
  default: 'https://raw.githubusercontent.com/Azure/azure-quickstart-templates/master/sonarqube-azuresql/'
}
param location string {
  metadata: {
    description: 'Location for all resources.'
  }
  default: resourceGroup().location
}
param artifactsLocationSasToken string {
  metadata: {
    description: 'The sasToken required to access _artifactsLocation.  When the template is deployed using the accompanying scripts, a sasToken will be automatically generated.'
  }
  secure: true
  default: ''
}
param SQvmAppVmSize string {
  metadata: {
    description: 'Size fo the VM'
  }
  default: 'Standard_DS1_v2'
}

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
}

resource sqVM_AppName_res 'Microsoft.Compute/virtualMachines@2020-06-01' = {
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
  name: '${sqVM_AppName}/configureAppVM_DSC'
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
  name: '${sqVM_AppName}/secureSonarQube'
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