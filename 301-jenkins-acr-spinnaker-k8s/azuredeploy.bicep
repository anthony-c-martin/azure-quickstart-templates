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
var storageAccountName = concat(resourcePrefix, uniqueString(resourceGroup().id))
var acrStorageAccountName = 'registry${uniqueString(resourceGroup().id)}'
var acrName = uniqueString(resourceGroup().id)
var nicName = '${resourcePrefix}VMNic'
var subnetName = '${resourcePrefix}Subnet'
var publicIPAddressName = '${resourcePrefix}PublicIP'
var vmName = '${resourcePrefix}VM'
var virtualNetworkName = '${resourcePrefix}VNET'
var vmExtensionName = '${resourcePrefix}Init'
var frontEndNSGName = '${resourcePrefix}NSG'
var kubernetesName = 'containerservice-${resourceGroup().name}'
var kubernetesDnsPrefix = 'k8s${uniqueString(resourceGroup().id)}'
var pipelinePort = '8000'
var artifactsLocation = 'https://raw.githubusercontent.com/Azure/azure-devops-utils/v0.24.0/'
var extensionScript = '301-jenkins-acr-spinnaker-k8s.sh'
var artifactsLocationSasToken = ''

resource storageAccountName_resource 'Microsoft.Storage/storageAccounts@2016-01-01' = {
  name: storageAccountName
  location: location
  sku: {
    name: 'Standard_LRS'
  }
  kind: 'Storage'
  properties: {}
}

resource acrStorageAccountName_resource 'Microsoft.Storage/storageAccounts@2016-01-01' = {
  name: acrStorageAccountName
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

resource acrName_resource 'Microsoft.ContainerRegistry/registries@2017-03-01' = {
  name: acrName
  location: location
  sku: {
    name: 'Basic'
    tier: 'Basic'
  }
  properties: {
    adminUserEnabled: false
    storageAccount: {
      name: acrStorageAccountName
      accessKey: listKeys(acrStorageAccountName_resource.id, '2016-01-01').keys[0].value
    }
  }
  dependsOn: [
    acrStorageAccountName_resource
  ]
}

resource publicIPAddressName_resource 'Microsoft.Network/publicIPAddresses@2016-09-01' = {
  name: publicIPAddressName
  location: location
  properties: {
    publicIPAllocationMethod: 'Dynamic'
    dnsSettings: {
      domainNameLabel: devopsDnsPrefix
    }
  }
}

resource frontEndNSGName_resource 'Microsoft.Network/networkSecurityGroups@2015-06-15' = {
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
    ]
  }
}

resource virtualNetworkName_resource 'Microsoft.Network/virtualNetworks@2016-09-01' = {
  name: virtualNetworkName
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
            id: frontEndNSGName_resource.id
          }
        }
      }
    ]
  }
  dependsOn: [
    frontEndNSGName_resource
  ]
}

resource nicName_resource 'Microsoft.Network/networkInterfaces@2016-09-01' = {
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
            id: '${virtualNetworkName_resource.id}/subnets/${subnetName}'
          }
        }
      }
    ]
  }
  dependsOn: [
    publicIPAddressName_resource
    virtualNetworkName_resource
  ]
}

resource vmName_resource 'Microsoft.Compute/virtualMachines@2017-03-30' = {
  name: vmName
  location: location
  properties: {
    hardwareProfile: {
      vmSize: 'Standard_D1_v2'
    }
    osProfile: {
      computerName: vmName
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
        name: '${vmName}_OSDisk'
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
          id: nicName_resource.id
        }
      ]
    }
  }
  dependsOn: [
    nicName_resource
  ]
}

resource vmName_vmExtensionName 'Microsoft.Compute/virtualMachines/extensions@2015-06-15' = {
  name: '${vmName}/${vmExtensionName}'
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
      commandToExecute: './${extensionScript} -ai "${servicePrincipalAppId}" -ak "${servicePrincipalAppKey}" -si "${subscription().subscriptionId}" -ti "${subscription().tenantId}" -un "${adminUsername}" -gr "${gitRepository}" -rg "${resourceGroup().name}" -mf "${kubernetesName_resource.properties.masterProfile.fqdn}" -san "${storageAccountName}" -sak "${listKeys(storageAccountName_resource.id, '2016-01-01').keys[0].value}" -acr "${acrName_resource.properties.loginServer}" -dr "${dockerRepository}" -pp "${pipelinePort}" -jf "${reference(publicIPAddressName).dnsSettings.fqdn}" -al "${artifactsLocation}" -st "${artifactsLocationSasToken}"'
    }
  }
  dependsOn: [
    vmName_resource
    acrName_resource
    kubernetesName_resource
  ]
}

resource kubernetesName_resource 'Microsoft.ContainerService/containerServices@2016-09-30' = {
  location: location
  name: kubernetesName
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
      ClientId: servicePrincipalAppId
      Secret: servicePrincipalAppKey
    }
  }
}

output devopsVmFQDN string = reference(publicIPAddressName).dnsSettings.fqdn
output jenkinsURL string = 'http://${reference(publicIPAddressName).dnsSettings.fqdn}'
output SSH string = 'ssh -L 8080:localhost:8080 -L 9000:localhost:9000 -L 8084:localhost:8084 -L 8001:localhost:8001 ${adminUsername}@${reference(publicIPAddressName).dnsSettings.fqdn}'
output azureContainerRegistryUrl string = acrName_resource.properties.loginServer
output kubernetesMasterFQDN string = kubernetesName_resource.properties.masterProfile.fqdn
output kubernetesMasterSsh string = 'ssh ${adminUsername}@${kubernetesName_resource.properties.masterProfile.fqdn}'