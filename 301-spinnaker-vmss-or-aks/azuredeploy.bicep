@description('Unique DNS Name for the Public IP used to access the combined Jenkins and Spinnaker Virtual Machine.')
param devopsDnsPrefix string

@description('Username for the DevOps Virtual Machine, the Jenkins instance, and the VM Scale Sets deployed by Spinnaker.')
param adminUsername string

@allowed([
  'sshPublicKey'
  'password'
])
@description('Type of authentication to use on the Virtual Machine. SSH key is recommended.')
param authenticationType string = 'sshPublicKey'

@description('Configure the linux machine with the SSH public key string. Your key should include three parts, for example\'ssh-rsa AAAAB...snip...UcyupgH azureuser@linuxvm\'')
param sshPublicKey string = ''

@description('Password for the Virtual Machine or the Jenkins instance.')
@secure()
param adminPassword string = ''

@description('Service Principal App ID (also called Client ID) that has contributor rights to the subscription used for this deployment. It is used by Spinnaker to dynamically manage resources.')
param servicePrincipalAppId string

@description('Service Principal App Key (also called Client Secret) that has contributor rights to the subscription used for this deployment. It is used by Spinnaker to dynamically manage resources.')
@secure()
param servicePrincipalAppKey string

@description('Location for all resources.')
param location string = resourceGroup().location

@description('AKS cluster name')
param aksClusterName string = ''

@description('AKS resource group')
param aksResourceGroup string = ''

var scenarioPrefix = 'devops'
var storageAccountName_var = concat(scenarioPrefix, uniqueString(resourceGroup().id))
var keyVaultName_var = 'vault${uniqueString(resourceGroup().id)}'
var vnetName_var = '${scenarioPrefix}Vnet'
var subnet0Name = '${scenarioPrefix}Subnet0'
var subnet1Name = '${scenarioPrefix}Subnet1'
var subnet2Name = '${scenarioPrefix}Subnet2'
var frontEndNSGName_var = '${scenarioPrefix}NSG'
var nicName_var = '${scenarioPrefix}Nic'
var publicIPAddressName_var = '${scenarioPrefix}PublicIP'
var vmName_var = '${scenarioPrefix}VM'
var vmExtensionName = '${scenarioPrefix}Init'
var artifactsLocation = 'https://raw.githubusercontent.com/Azure/azure-devops-utils/master/'
var extensionScript = '101-spinnaker-install-selection.sh'
var linuxConfiguration = {
  disablePasswordAuthentication: true
  ssh: {
    publicKeys: [
      {
        path: '/home/${adminUsername}/.ssh/authorized_keys'
        keyData: sshPublicKey
      }
    ]
  }
}
var adminVMPassword = ((authenticationType == 'password') ? adminPassword : linuxConfiguration)
var adminJenkinsPassword = (empty(aksClusterName) ? adminPassword : '')
var useSshPublicKey = ((authenticationType == 'password') ? 'false' : 'true')

resource storageAccountName 'Microsoft.Storage/storageAccounts@2019-04-01' = {
  name: storageAccountName_var
  location: location
  kind: 'Storage'
  sku: {
    name: 'Standard_LRS'
  }
  properties: {}
}

resource keyVaultName 'Microsoft.KeyVault/vaults@2018-02-14' = {
  name: keyVaultName_var
  location: location
  properties: {
    enabledForTemplateDeployment: true
    tenantId: subscription().tenantId
    accessPolicies: [
      {
        tenantId: subscription().tenantId
        objectId: servicePrincipalAppId
        permissions: {
          keys: [
            'all'
          ]
          secrets: [
            'get'
          ]
        }
      }
    ]
    sku: {
      name: 'standard'
      family: 'A'
    }
  }
}

resource keyVaultName_VMUsername 'Microsoft.KeyVault/vaults/secrets@2018-02-14' = {
  parent: keyVaultName
  name: 'VMUsername'
  properties: {
    value: adminUsername
  }
}

resource keyVaultName_VMPassword 'Microsoft.KeyVault/vaults/secrets@2018-02-14' = {
  parent: keyVaultName
  name: 'VMPassword'
  properties: {
    value: ((authenticationType == 'password') ? adminVMPassword : adminVMPassword.ssh.publicKeys[0].keyData)
  }
}

resource keyVaultName_VMSshPublicKey 'Microsoft.KeyVault/vaults/secrets@2018-02-14' = {
  parent: keyVaultName
  name: 'VMSshPublicKey'
  properties: {
    value: sshPublicKey
  }
}

resource vnetName 'Microsoft.Network/virtualNetworks@2018-11-01' = {
  name: vnetName_var
  location: location
  properties: {
    addressSpace: {
      addressPrefixes: [
        '10.0.0.0/16'
      ]
    }
    subnets: [
      {
        name: subnet0Name
        properties: {
          addressPrefix: '10.0.0.0/24'
          networkSecurityGroup: {
            id: frontEndNSGName.id
          }
        }
      }
      {
        name: subnet1Name
        properties: {
          addressPrefix: '10.0.1.0/24'
        }
      }
      {
        name: subnet2Name
        properties: {
          addressPrefix: '10.0.2.0/24'
        }
      }
    ]
  }
}

resource publicIPAddressName 'Microsoft.Network/publicIPAddresses@2018-11-01' = {
  name: publicIPAddressName_var
  location: location
  properties: {
    publicIPAllocationMethod: 'Dynamic'
    dnsSettings: {
      domainNameLabel: devopsDnsPrefix
    }
  }
}

resource frontEndNSGName 'Microsoft.Network/networkSecurityGroups@2018-11-01' = {
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
      {
        name: 'aptly-rule'
        properties: {
          description: 'Allow HTTP for aptly'
          protocol: 'Tcp'
          sourcePortRange: '*'
          destinationPortRange: '9999'
          sourceAddressPrefix: 'Internet'
          destinationAddressPrefix: '*'
          access: 'Allow'
          priority: 102
          direction: 'Inbound'
        }
      }
    ]
  }
}

resource nicName 'Microsoft.Network/networkInterfaces@2018-11-01' = {
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
            id: resourceId('Microsoft.Network/virtualNetworks/subnets', vnetName_var, subnet0Name)
          }
        }
      }
    ]
  }
  dependsOn: [
    vnetName
  ]
}

resource vmName 'Microsoft.Compute/virtualMachines@2019-03-01' = {
  name: vmName_var
  location: location
  properties: {
    hardwareProfile: {
      vmSize: 'Standard_D4_v2'
    }
    osProfile: {
      computerName: vmName_var
      adminUsername: adminUsername
      adminPassword: ((authenticationType == 'password') ? adminVMPassword : json('null'))
      linuxConfiguration: ((authenticationType == 'password') ? json('null') : adminVMPassword)
    }
    storageProfile: {
      imageReference: {
        publisher: 'Canonical'
        offer: 'UbuntuServer'
        sku: '16.04-LTS'
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
    storageAccountName
  ]
}

resource vmName_vmExtensionName 'Microsoft.Compute/virtualMachines/extensions@2019-03-01' = {
  parent: vmName
  name: '${vmExtensionName}'
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
      commandToExecute: './${extensionScript} -u "${adminUsername}" -jp \'${adminJenkinsPassword}\' -ai "${servicePrincipalAppId}" -ak "${servicePrincipalAppKey}" -ti "${subscription().tenantId}" -si "${subscription().subscriptionId}" -rg "${resourceGroup().name}" -vn "${keyVaultName_var}" -san "${storageAccountName_var}" -sak "${listKeys(storageAccountName.id, '2019-04-01').keys[0].value}" -vf "${reference(publicIPAddressName_var).dnsSettings.fqdn}" -r "${location}" -uspk "${useSshPublicKey}" -acn "${aksClusterName}" -arg "${aksResourceGroup}" -al "${artifactsLocation}" -st ""'
    }
  }
}

output devopsVmFQDN string = reference(publicIPAddressName_var).dnsSettings.fqdn
output jenkinsURL string = 'http://${reference(publicIPAddressName_var).dnsSettings.fqdn}'
output SSH string = 'ssh -L 8084:localhost:8084 -L 9000:localhost:9000 ${(empty(aksClusterName) ? '-L 8082:localhost:8082 ' : '-L 8080:localhost:8080 -L 8087:localhost:8087 ')}${adminUsername}@${reference(publicIPAddressName_var).dnsSettings.fqdn}'
output useSshPublicKey string = useSshPublicKey