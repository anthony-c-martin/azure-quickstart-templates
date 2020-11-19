param devopsDnsPrefix string {
  metadata: {
    description: 'Unique DNS Name for the Public IP used to access the combined Jenkins and Spinnaker Virtual Machine.'
  }
}
param adminUsername string {
  metadata: {
    description: 'Username for the DevOps Virtual Machine, the Jenkins instance, and the VM Scale Sets deployed by Spinnaker.'
  }
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
param sshPublicKey string {
  metadata: {
    description: 'Configure the linux machine with the SSH public key string. Your key should include three parts, for example\'ssh-rsa AAAAB...snip...UcyupgH azureuser@linuxvm\''
  }
  default: ''
}
param adminPassword string {
  metadata: {
    description: 'Password for the Virtual Machine or the Jenkins instance.'
  }
  secure: true
  default: ''
}
param servicePrincipalAppId string {
  metadata: {
    description: 'Service Principal App ID (also called Client ID) that has contributor rights to the subscription used for this deployment. It is used by Spinnaker to dynamically manage resources.'
  }
}
param servicePrincipalAppKey string {
  metadata: {
    description: 'Service Principal App Key (also called Client Secret) that has contributor rights to the subscription used for this deployment. It is used by Spinnaker to dynamically manage resources.'
  }
  secure: true
}
param location string {
  metadata: {
    description: 'Location for all resources.'
  }
  default: resourceGroup().location
}
param aksClusterName string {
  metadata: {
    description: 'AKS cluster name'
  }
  default: ''
}
param aksResourceGroup string {
  metadata: {
    description: 'AKS resource group'
  }
  default: ''
}

var scenarioPrefix = 'devops'
var storageAccountName = concat(scenarioPrefix, uniqueString(resourceGroup().id))
var keyVaultName = 'vault${uniqueString(resourceGroup().id)}'
var vnetName = '${scenarioPrefix}Vnet'
var subnet0Name = '${scenarioPrefix}Subnet0'
var subnet1Name = '${scenarioPrefix}Subnet1'
var subnet2Name = '${scenarioPrefix}Subnet2'
var frontEndNSGName = '${scenarioPrefix}NSG'
var nicName = '${scenarioPrefix}Nic'
var publicIPAddressName = '${scenarioPrefix}PublicIP'
var vmName = '${scenarioPrefix}VM'
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
var useSshPublicKey_variable = ((authenticationType == 'password') ? 'false' : 'true')

resource storageAccountName_resource 'Microsoft.Storage/storageAccounts@2019-04-01' = {
  name: storageAccountName
  location: location
  kind: 'Storage'
  sku: {
    name: 'Standard_LRS'
  }
  properties: {}
}

resource keyVaultName_resource 'Microsoft.KeyVault/vaults@2018-02-14' = {
  name: keyVaultName
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
  name: '${keyVaultName}/VMUsername'
  properties: {
    value: adminUsername
  }
  dependsOn: [
    keyVaultName_resource
  ]
}

resource keyVaultName_VMPassword 'Microsoft.KeyVault/vaults/secrets@2018-02-14' = {
  name: '${keyVaultName}/VMPassword'
  properties: {
    value: ((authenticationType == 'password') ? adminVMPassword : adminVMPassword.ssh.publicKeys[0].keyData)
  }
  dependsOn: [
    keyVaultName_resource
  ]
}

resource keyVaultName_VMSshPublicKey 'Microsoft.KeyVault/vaults/secrets@2018-02-14' = {
  name: '${keyVaultName}/VMSshPublicKey'
  properties: {
    value: sshPublicKey
  }
  dependsOn: [
    keyVaultName_resource
  ]
}

resource vnetName_resource 'Microsoft.Network/virtualNetworks@2018-11-01' = {
  name: vnetName
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
            id: frontEndNSGName_resource.id
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
  dependsOn: [
    frontEndNSGName_resource
  ]
}

resource publicIPAddressName_resource 'Microsoft.Network/publicIPAddresses@2018-11-01' = {
  name: publicIPAddressName
  location: location
  properties: {
    publicIPAllocationMethod: 'Dynamic'
    dnsSettings: {
      domainNameLabel: devopsDnsPrefix
    }
  }
}

resource frontEndNSGName_resource 'Microsoft.Network/networkSecurityGroups@2018-11-01' = {
  name: frontEndNSGName
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

resource nicName_resource 'Microsoft.Network/networkInterfaces@2018-11-01' = {
  name: nicName
  location: location
  properties: {
    ipConfigurations: [
      {
        name: 'ipconfig1'
        properties: {
          privateIPAllocationMethod: 'Dynamic'
          publicIPAddress: {
            id: publicIPAddressName_resource.id
          }
          subnet: {
            id: resourceId('Microsoft.Network/virtualNetworks/subnets', vnetName, subnet0Name)
          }
        }
      }
    ]
  }
  dependsOn: [
    publicIPAddressName_resource
    vnetName_resource
  ]
}

resource vmName_resource 'Microsoft.Compute/virtualMachines@2019-03-01' = {
  name: vmName
  location: location
  properties: {
    hardwareProfile: {
      vmSize: 'Standard_D4_v2'
    }
    osProfile: {
      computerName: vmName
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
    nicName_resource
    storageAccountName_resource
  ]
}

resource vmName_vmExtensionName 'Microsoft.Compute/virtualMachines/extensions@2019-03-01' = {
  name: '${vmName}/${vmExtensionName}'
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
      commandToExecute: './${extensionScript} -u "${adminUsername}" -jp \'${adminJenkinsPassword}\' -ai "${servicePrincipalAppId}" -ak "${servicePrincipalAppKey}" -ti "${subscription().tenantId}" -si "${subscription().subscriptionId}" -rg "${resourceGroup().name}" -vn "${keyVaultName}" -san "${storageAccountName}" -sak "${listKeys(storageAccountName_resource.id, '2019-04-01').keys[0].value}" -vf "${reference(publicIPAddressName).dnsSettings.fqdn}" -r "${location}" -uspk "${useSshPublicKey_variable}" -acn "${aksClusterName}" -arg "${aksResourceGroup}" -al "${artifactsLocation}" -st ""'
    }
  }
  dependsOn: [
    vmName_resource
  ]
}

output devopsVmFQDN string = reference(publicIPAddressName).dnsSettings.fqdn
output jenkinsURL string = 'http://${reference(publicIPAddressName).dnsSettings.fqdn}'
output SSH string = 'ssh -L 8084:localhost:8084 -L 9000:localhost:9000 ${(empty(aksClusterName) ? '-L 8082:localhost:8082 ' : '-L 8080:localhost:8080 -L 8087:localhost:8087 ')}${adminUsername}@${reference(publicIPAddressName).dnsSettings.fqdn}'
output useSshPublicKey string = useSshPublicKey_variable