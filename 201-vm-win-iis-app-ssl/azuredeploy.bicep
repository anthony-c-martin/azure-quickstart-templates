@minLength(1)
@description('Set this value for the VM name')
param appVMName string

@minLength(1)
@description('Set this value for the VM admin user name')
param appVMAdminUserName string

@description('Set this value for the VM admin user password')
@secure()
param appVMAdminPassword string

@allowed([
  '2008-R2-SP1'
  '2012-Datacenter'
  '2012-R2-Datacenter'
  'Windows-Server-Technical-Preview'
])
@description('Set this value for the VM Windows OS Version')
param appVMWindowsOSVersion string = '2012-R2-Datacenter'

@minLength(1)
@description('Set this value for the dns name of the public ip')
param appPublicIPDnsName string

@description('This value must be changed from a previous deployment to ensure the extension will run')
param appDSCUpdateTagVersion string = '1.0'

@description('Set this value for the signed uri to download the deployment package')
param appWebPackage string = 'https://computeteststore.blob.core.windows.net/deploypackage/deployPackage.zip?sv=2015-04-05&ss=bfqt&srt=sco&sp=r&se=2099-10-16T02:03:39Z&st=2016-10-15T18:03:39Z&spr=https&sig=aSH6yNPEGPWXk6PxTPzS6fyEXMD1ZYIkI0j5E9Hu5%2Fk%3D'

@allowed([
  'Standard_D1'
  'Standard_D2'
  'Standard_D3'
  'Standard_D4'
  'Standard_D5'
])
@description('Set this value for the VM size')
param appVMVmSize string = 'Standard_D2'

@description('Auto-generated container in staging storage account to receive post-build staging folder upload')
param artifactsLocation string

@description('Auto-generated token to access _artifactsLocation')
@secure()
param artifactsLocationSasToken string

@description('The Azure Key vault where SSL certificates are stored')
param vaultName string

@description('Resource Group of the key vault')
param vaultResourceGroup string

@description('full Key Vault Id to the secret that stores the SSL cert')
param httpssecretUrlWithVersion string

@description('full Key Vault Id to the secret that stores the CA cert')
param httpssecretCaUrlWithVersion string

@description('name of the certificate key secret')
param certificateStore string

@description('name of the domain the certificate is created for')
param certificateDomain string

@description('Location for all resources.')
param location string = resourceGroup().location

var appVnetPrefix = '10.0.0.0/16'
var appVnetSubnet1Name = 'FrontEndSubNet'
var appVnetSubnet1Prefix = '10.0.0.0/24'
var appVnetSubnet2Name = 'DatabaseSubNet'
var appVnetSubnet2Prefix = '10.0.1.0/24'
var appVMImagePublisher = 'MicrosoftWindowsServer'
var appVMImageOffer = 'WindowsServer'
var appVMVmSize_var = appVMVmSize
var appVMVnetID = appVnet.id
var appVMSubnetRef = 'appVMresourceId(\'Microsoft.Network/virtualNetworks/subnets\', parameters(\'virtualNetworkName\'), variables(\'appVMVnetID\'), \'/subnets/\', variables(\'appVnetSubnet1Name\'))]'
var appVMNicName_var = '${appVMName}NetworkInterface'
var appPublicIPName_var = 'appPublicIP'
var appDSCArchiveFolder = 'dsc'
var appDSCArchiveFileName = 'appDSC.zip'
var appDSCSqlArchiveFolder = 'dsc'
var appDSCSqlArchiveFileName = 'appDSCSql.zip'

resource appNetworkSecurityGroup 'Microsoft.Network/networkSecurityGroups@2015-06-15' = {
  name: 'appNetworkSecurityGroup'
  location: location
  properties: {
    securityRules: [
      {
        name: 'webrule'
        properties: {
          description: 'This rule allows traffic in on port 80'
          protocol: 'Tcp'
          sourcePortRange: '*'
          destinationPortRange: '80'
          sourceAddressPrefix: 'INTERNET'
          destinationAddressPrefix: '10.0.0.0/24'
          access: 'Allow'
          priority: 100
          direction: 'Inbound'
        }
      }
      {
        name: 'httpsrule'
        properties: {
          description: 'This rule allows traffic in on port 443'
          protocol: 'Tcp'
          sourcePortRange: '*'
          destinationPortRange: '443'
          sourceAddressPrefix: 'INTERNET'
          destinationAddressPrefix: '10.0.0.0/24'
          access: 'Allow'
          priority: 110
          direction: 'Inbound'
        }
      }
      {
        name: 'rdprule'
        properties: {
          description: 'This rule allows traffic on port 3389 from the web'
          protocol: 'Tcp'
          sourcePortRange: '*'
          destinationPortRange: '3389'
          sourceAddressPrefix: 'INTERNET'
          destinationAddressPrefix: '10.0.0.0/24'
          access: 'Allow'
          priority: 200
          direction: 'Inbound'
        }
      }
    ]
  }
}

resource appVnet 'Microsoft.Network/virtualNetworks@2015-06-15' = {
  name: 'appVnet'
  location: location
  tags: {
    displayName: 'appVnet'
  }
  properties: {
    addressSpace: {
      addressPrefixes: [
        appVnetPrefix
      ]
    }
    subnets: [
      {
        name: appVnetSubnet1Name
        properties: {
          addressPrefix: appVnetSubnet1Prefix
          networkSecurityGroup: {
            id: appNetworkSecurityGroup.id
          }
        }
      }
      {
        name: appVnetSubnet2Name
        properties: {
          addressPrefix: appVnetSubnet2Prefix
        }
      }
    ]
  }
}

resource appVMNicName 'Microsoft.Network/networkInterfaces@2015-06-15' = {
  name: appVMNicName_var
  location: location
  tags: {
    displayName: 'appVMNic'
  }
  properties: {
    ipConfigurations: [
      {
        name: 'ipconfig1'
        properties: {
          privateIPAllocationMethod: 'Dynamic'
          subnet: {
            id: appVMSubnetRef
          }
          publicIPAddress: {
            id: appPublicIPName.id
          }
        }
      }
    ]
  }
  dependsOn: [
    appVnet
  ]
}

resource appVMName_resource 'Microsoft.Compute/virtualMachines@2017-03-30' = {
  name: appVMName
  location: location
  tags: {
    displayName: 'appVM'
  }
  properties: {
    hardwareProfile: {
      vmSize: appVMVmSize_var
    }
    osProfile: {
      computerName: appVMName
      adminUsername: appVMAdminUserName
      adminPassword: appVMAdminPassword
      secrets: [
        {
          sourceVault: {
            id: resourceId(vaultResourceGroup, 'Microsoft.KeyVault/vaults', vaultName)
          }
          vaultCertificates: [
            {
              certificateUrl: httpssecretUrlWithVersion
              certificateStore: certificateStore
            }
          ]
        }
      ]
    }
    storageProfile: {
      imageReference: {
        publisher: appVMImagePublisher
        offer: appVMImageOffer
        sku: appVMWindowsOSVersion
        version: 'latest'
      }
      osDisk: {
        name: '${appVMName}_OSDisk'
        caching: 'ReadWrite'
        createOption: 'FromImage'
      }
    }
    networkProfile: {
      networkInterfaces: [
        {
          id: appVMNicName.id
        }
      ]
    }
  }
}

resource appVMName_Microsoft_Powershell_DSC 'Microsoft.Compute/virtualMachines/extensions@2015-06-15' = {
  parent: appVMName_resource
  name: 'Microsoft.Powershell.DSC'
  location: location
  tags: {
    displayName: 'appDSC'
  }
  properties: {
    publisher: 'Microsoft.Powershell'
    type: 'DSC'
    typeHandlerVersion: '2.9'
    autoUpgradeMinorVersion: true
    forceUpdateTag: appDSCUpdateTagVersion
    settings: {
      configuration: {
        url: '${artifactsLocation}/${appDSCArchiveFolder}/${appDSCArchiveFileName}'
        script: 'appDSC.ps1'
        function: 'Main'
      }
      configurationArguments: {
        nodeName: appVMName
        webDeployPackage: appWebPackage
        certStoreName: certificateStore
        certDomain: certificateDomain
      }
    }
    protectedSettings: {
      configurationUrlSasToken: artifactsLocationSasToken
    }
  }
}

resource appPublicIPName 'Microsoft.Network/publicIPAddresses@2015-06-15' = {
  name: appPublicIPName_var
  location: location
  tags: {
    displayName: 'appPublicIP'
  }
  properties: {
    publicIPAllocationMethod: 'Dynamic'
    dnsSettings: {
      domainNameLabel: appPublicIPDnsName
    }
  }
  dependsOn: []
}