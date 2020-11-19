param adminUsername string {
  metadata: {
    description: 'User name for the Virtual Machine.'
  }
}
param jenkinsDnsPrefix string {
  metadata: {
    description: 'Unique DNS Name for the Public IP used to access the Jenkins Virtual Machine.'
  }
}
param servicePrincipalAppId string {
  metadata: {
    description: 'Service Principal App ID (also called Client ID) used by Jenkins to push the docker image to Azure Container Registry.'
  }
}
param servicePrincipalAppKey string {
  metadata: {
    description: 'Service Principal App Key (also called Client Secret) used by Jenkins to push the docker image to Azure Container Registry.'
  }
  secure: true
}
param gitRepository string {
  metadata: {
    description: 'URL to a public git repository that includes a Dockerfile.'
  }
  default: 'https://github.com/azure-devops/spin-kub-demo.git'
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
param virtualMachineSize string {
  allowed: [
    'Standard_DS1_v2'
  ]
  metadata: {
    description: 'The virtual machine size.'
  }
  default: 'Standard_DS1_v2'
}

var resourcePrefix = 'jenkins'
var acrStorageAccountName_var = 'registry${uniqueString(resourceGroup().id)}'
var acrName_var = uniqueString(resourceGroup().id)
var nicName_var = '${resourcePrefix}VMNic'
var subnetName = '${resourcePrefix}Subnet'
var publicIPAddressName_var = '${resourcePrefix}PublicIP'
var vmName_var = '${resourcePrefix}VM'
var vmExtensionName = '${resourcePrefix}Init'
var virtualNetworkName_var = '${resourcePrefix}VNET'
var frontEndNSGName_var = '${resourcePrefix}NSG'
var artifactsLocation = 'https://raw.githubusercontent.com/Azure/azure-devops-utils/v0.30.0/'
var extensionScript = '201-jenkins-acr.sh'
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
var subnetRef = resourceId('Microsoft.Network/virtualNetworks/subnets', virtualNetworkName_var, subnetName)

resource acrStorageAccountName 'Microsoft.Storage/storageAccounts@2019-04-01' = {
  name: acrStorageAccountName_var
  location: location
  sku: {
    name: 'Standard_LRS'
  }
  kind: 'Storage'
  properties: {
    encryption: {
      services: {
        blob: {
          enabled: true
        }
      }
      keySource: 'Microsoft.Storage'
    }
  }
}

resource acrName 'Microsoft.ContainerRegistry/registries@2017-10-01' = {
  name: acrName_var
  location: location
  sku: {
    name: 'Basic'
    tier: 'Basic'
  }
  properties: {
    adminUserEnabled: false
  }
}

resource publicIPAddressName 'Microsoft.Network/publicIPAddresses@2019-04-01' = {
  name: publicIPAddressName_var
  location: location
  properties: {
    publicIPAllocationMethod: 'Dynamic'
    dnsSettings: {
      domainNameLabel: jenkinsDnsPrefix
    }
  }
}

resource frontEndNSGName 'Microsoft.Network/networkSecurityGroups@2019-04-01' = {
  name: frontEndNSGName_var
  location: location
  tags: {
    displayName: 'NSG - Front End'
  }
  properties: {
    securityRules: [
      {
        name: 'ssh-rule'
        properties: {
          description: 'Allow SSH'
          protocol: 'Tcp'
          sourcePortRange: '*'
          destinationPortRange: '22'
          sourceAddressPrefix: 'Internet'
          destinationAddressPrefix: '*'
          access: 'Allow'
          priority: 100
          direction: 'Inbound'
        }
      }
      {
        name: 'http-rule'
        properties: {
          description: 'Allow HTTP'
          protocol: 'Tcp'
          sourcePortRange: '*'
          destinationPortRange: '80'
          sourceAddressPrefix: 'Internet'
          destinationAddressPrefix: '*'
          access: 'Allow'
          priority: 101
          direction: 'Inbound'
        }
      }
    ]
  }
}

resource virtualNetworkName 'Microsoft.Network/virtualNetworks@2019-04-01' = {
  name: virtualNetworkName_var
  location: location
  properties: {
    addressSpace: {
      addressPrefixes: [
        '10.0.0.0/16'
      ]
    }
    subnets: [
      {
        name: subnetName
        properties: {
          addressPrefix: '10.0.0.0/24'
          networkSecurityGroup: {
            id: frontEndNSGName.id
          }
        }
      }
    ]
  }
}

resource nicName 'Microsoft.Network/networkInterfaces@2019-04-01' = {
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
}

resource vmName 'Microsoft.Compute/virtualMachines@2019-03-01' = {
  name: vmName_var
  location: location
  properties: {
    hardwareProfile: {
      vmSize: virtualMachineSize
    }
    osProfile: {
      computerName: vmName_var
      adminUsername: adminUsername
      adminPassword: adminPasswordOrKey
      linuxConfiguration: ((authenticationType == 'password') ? json('null') : linuxConfiguration)
    }
    storageProfile: {
      imageReference: {
        publisher: 'Canonical'
        offer: 'UbuntuServer'
        sku: '16.04-LTS'
        version: 'latest'
      }
      osDisk: {
        name: 'osdisk'
        caching: 'ReadWrite'
        createOption: 'FromImage'
        managedDisk: {
          storageAccountType: 'Standard_LRS'
        }
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

resource vmName_vmExtensionName 'Microsoft.Compute/virtualMachines/extensions@2019-03-01' = {
  name: '${vmName_var}/${vmExtensionName}'
  location: location
  properties: {
    publisher: 'Microsoft.Azure.Extensions'
    type: 'CustomScript'
    typeHandlerVersion: '2.0'
    autoUpgradeMinorVersion: true
    settings: {
      fileUris: [
        uri(artifactsLocation, 'quickstart_template/${extensionScript}')
      ]
    }
    protectedSettings: {
      commandToExecute: './${extensionScript} -jf "${reference(publicIPAddressName_var).dnsSettings.fqdn}" -u "${adminUsername}" -g "${gitRepository}" -r "https://${acrName.properties.loginServer}" -ru "${servicePrincipalAppId}" -rp "${servicePrincipalAppKey}" -al "${artifactsLocation}"'
    }
  }
}

output jenkinsURL string = 'http://${reference(publicIPAddressName_var).dnsSettings.fqdn}'
output SSH string = 'ssh -L 8080:localhost:8080 ${adminUsername}@${reference(publicIPAddressName_var).dnsSettings.fqdn}'
output azureContainerRegistryUrl string = acrName.properties.loginServer