param adminUsername string {
  metadata: {
    description: 'User name for the Virtual Machine.'
  }
}
param sshPublicKey string {
  metadata: {
    description: 'Configure all linux machines with the SSH public key string.  Your key should include three parts, for example \'ssh-rsa AAAAB...snip...UcyupgH azureuser@linuxvm\''
  }
}
param devopsDnsPrefix string {
  metadata: {
    description: 'Unique DNS Name for the Public IP used to access the combined Jenkins and Spinnaker Virtual Machine.'
  }
}
param servicePrincipalAppId string {
  metadata: {
    description: 'Service Principal App ID (also called Client ID) that has contributor rights to the subscription used for this deployment. It is used by the Kubernetes cluster to dynamically manage resources (e.g. user-defined load balancers).'
  }
}
param servicePrincipalAppKey string {
  metadata: {
    description: 'Service Principal App Key (also called Client Secret) that has contributor rights to the subscription used for this deployment. It is used by the Kubernetes cluster to dynamically manage resources (e.g. user-defined load balancers).'
  }
  secure: true
}
param gitRepository string {
  metadata: {
    description: 'The URL to a public git repository used for the default Jenkins job. It must include a Dockerfile at the root of the repo.'
  }
  default: 'https://github.com/azure-devops/spin-kub-demo.git'
}
param dockerRepository string {
  metadata: {
    description: 'The repository name used by the default Jenkins job and Spinnaker pipeline. This repository will be created in your Azure Container Registry.'
  }
  default: 'azure-devops/spin-kub-demo'
}
param location string {
  metadata: {
    description: 'Location for all resources.'
  }
  default: resourceGroup().location
}

var resourcePrefix = 'devops'
var storageAccountName_var = concat(resourcePrefix, uniqueString(resourceGroup().id))
var acrStorageAccountName_var = 'registry${uniqueString(resourceGroup().id)}'
var acrName_var = uniqueString(resourceGroup().id)
var nicName_var = '${resourcePrefix}VMNic'
var subnetName = '${resourcePrefix}Subnet'
var publicIPAddressName_var = '${resourcePrefix}PublicIP'
var vmName_var = '${resourcePrefix}VM'
var virtualNetworkName_var = '${resourcePrefix}VNET'
var vmExtensionName = '${resourcePrefix}Init'
var frontEndNSGName_var = '${resourcePrefix}NSG'
var kubernetesName_var = 'containerservice-${resourceGroup().name}'
var kubernetesDnsPrefix = 'k8s${uniqueString(resourceGroup().id)}'
var pipelinePort = '8000'
var artifactsLocation = 'https://raw.githubusercontent.com/Azure/azure-devops-utils/v0.24.0/'
var extensionScript = '301-jenkins-acr-spinnaker-k8s.sh'
var artifactsLocationSasToken = ''

resource storageAccountName 'Microsoft.Storage/storageAccounts@2016-01-01' = {
  name: storageAccountName_var
  location: location
  sku: {
    name: 'Standard_LRS'
  }
  kind: 'Storage'
  properties: {}
}

resource acrStorageAccountName 'Microsoft.Storage/storageAccounts@2016-01-01' = {
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

resource acrName 'Microsoft.ContainerRegistry/registries@2017-03-01' = {
  name: acrName_var
  location: location
  sku: {
    name: 'Basic'
    tier: 'Basic'
  }
  properties: {
    adminUserEnabled: false
    storageAccount: {
      name: acrStorageAccountName_var
      accessKey: listKeys(acrStorageAccountName.id, '2016-01-01').keys[0].value
    }
  }
}

resource publicIPAddressName 'Microsoft.Network/publicIPAddresses@2016-09-01' = {
  name: publicIPAddressName_var
  location: location
  properties: {
    publicIPAllocationMethod: 'Dynamic'
    dnsSettings: {
      domainNameLabel: devopsDnsPrefix
    }
  }
}

resource frontEndNSGName 'Microsoft.Network/networkSecurityGroups@2015-06-15' = {
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

resource virtualNetworkName 'Microsoft.Network/virtualNetworks@2016-09-01' = {
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

resource nicName 'Microsoft.Network/networkInterfaces@2016-09-01' = {
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
            id: '${virtualNetworkName.id}/subnets/${subnetName}'
          }
        }
      }
    ]
  }
}

resource vmName 'Microsoft.Compute/virtualMachines@2017-03-30' = {
  name: vmName_var
  location: location
  properties: {
    hardwareProfile: {
      vmSize: 'Standard_D1_v2'
    }
    osProfile: {
      computerName: vmName_var
      adminUsername: adminUsername
      linuxConfiguration: {
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
    }
    storageProfile: {
      imageReference: {
        publisher: 'Canonical'
        offer: 'UbuntuServer'
        sku: '14.04.5-LTS'
        version: 'latest'
      }
      osDisk: {
        name: '${vmName_var}_OSDisk'
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

resource vmName_vmExtensionName 'Microsoft.Compute/virtualMachines/extensions@2015-06-15' = {
  name: '${vmName_var}/${vmExtensionName}'
  location: location
  properties: {
    publisher: 'Microsoft.Azure.Extensions'
    type: 'CustomScript'
    typeHandlerVersion: '2.0'
    autoUpgradeMinorVersion: true
    settings: {
      fileUris: [
        '${artifactsLocation}quickstart_template/${extensionScript}${artifactsLocationSasToken}'
      ]
    }
    protectedSettings: {
      commandToExecute: './${extensionScript} -ai "${servicePrincipalAppId}" -ak "${servicePrincipalAppKey}" -si "${subscription().subscriptionId}" -ti "${subscription().tenantId}" -un "${adminUsername}" -gr "${gitRepository}" -rg "${resourceGroup().name}" -mf "${kubernetesName.properties.masterProfile.fqdn}" -san "${storageAccountName_var}" -sak "${listKeys(storageAccountName.id, '2016-01-01').keys[0].value}" -acr "${acrName.properties.loginServer}" -dr "${dockerRepository}" -pp "${pipelinePort}" -jf "${reference(publicIPAddressName_var).dnsSettings.fqdn}" -al "${artifactsLocation}" -st "${artifactsLocationSasToken}"'
    }
  }
  dependsOn: [
    vmName
  ]
}

resource kubernetesName 'Microsoft.ContainerService/containerServices@2016-09-30' = {
  location: location
  name: kubernetesName_var
  properties: {
    orchestratorProfile: {
      orchestratorType: 'Kubernetes'
    }
    masterProfile: {
      count: 1
      dnsPrefix: '${kubernetesDnsPrefix}mgmt'
    }
    agentPoolProfiles: [
      {
        name: 'agentpools'
        count: 1
        vmSize: 'Standard_DS11_v2'
        dnsPrefix: '${kubernetesDnsPrefix}agents'
      }
    ]
    linuxProfile: {
      adminUsername: adminUsername
      ssh: {
        publicKeys: [
          {
            keyData: sshPublicKey
          }
        ]
      }
    }
    servicePrincipalProfile: {
      clientId: servicePrincipalAppId
      secret: servicePrincipalAppKey
    }
  }
}

output devopsVmFQDN string = reference(publicIPAddressName_var).dnsSettings.fqdn
output jenkinsURL string = 'http://${reference(publicIPAddressName_var).dnsSettings.fqdn}'
output SSH string = 'ssh -L 8080:localhost:8080 -L 9000:localhost:9000 -L 8084:localhost:8084 -L 8001:localhost:8001 ${adminUsername}@${reference(publicIPAddressName_var).dnsSettings.fqdn}'
output azureContainerRegistryUrl string = acrName.properties.loginServer
output kubernetesMasterFQDN string = kubernetesName.properties.masterProfile.fqdn
output kubernetesMasterSsh string = 'ssh ${adminUsername}@${kubernetesName.properties.masterProfile.fqdn}'