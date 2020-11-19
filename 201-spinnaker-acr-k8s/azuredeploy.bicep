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
param spinnakerDnsPrefix string {
  metadata: {
    description: 'Unique DNS Name for the Public IP used to access the Spinnaker Virtual Machine.'
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
param kubernetesPipeline string {
  allowed: [
    'Include'
    'Exclude'
  ]
  metadata: {
    description: 'If included, a pipeline will be created in your Spinnaker instance. This also creates a dev (private) load balancer and prod (public) load balancer in your Kubernetes cluster.'
  }
  default: 'Include'
}
param pipelineRegistry string {
  allowed: [
    '<Azure Container Registry created by this template>'
    'index.docker.io'
  ]
  metadata: {
    description: 'If including a pipeline, the registry used to trigger the pipeline. You can either target Docker Hub or the Azure Container Registry created by this template.'
  }
  default: 'index.docker.io'
}
param pipelineRepository string {
  metadata: {
    description: 'If including a pipeline, the repository in your registry used to trigger the pipeline. It will only be triggered when a new tag is pushed.'
  }
  default: 'lwander/spin-kub-demo'
}
param location string {
  metadata: {
    description: 'Location for all resources.'
  }
  default: resourceGroup().location
}

var resourcePrefix = 'spinnaker'
var kubernetesName_var = 'containerservice-${resourceGroup().name}'
var storageAccountName_var = concat(resourcePrefix, uniqueString(resourceGroup().id))
var OSDiskName = '${resourcePrefix}OSDisk'
var nicName_var = '${resourcePrefix}VMNic'
var subnetName = '${resourcePrefix}Subnet'
var publicIPAddressName_var = '${resourcePrefix}PublicIP'
var vmStorageAccountContainerName = 'vhds'
var vmName_var = '${resourcePrefix}VM'
var virtualNetworkName_var = '${resourcePrefix}VNET'
var vmExtensionName = '${resourcePrefix}Init'
var acrPrefix_var = uniqueString(resourceGroup().id)
var acrStorageAccountName_var = 'registry${uniqueString(resourceGroup().id)}'
var kubernetesDnsPrefix = 'k8s${uniqueString(resourceGroup().id)}'
var pipelinePort = '8000'
var artifactsLocation = 'https://raw.githubusercontent.com/Azure/azure-devops-utils/v0.12.0/'
var extensionScript = '201-spinnaker-acr-k8s.sh'
var artifactsLocationSasToken = ''

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
        vmSize: 'Standard_D2_v2'
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

resource storageAccountName 'Microsoft.Storage/storageAccounts@2016-01-01' = {
  name: storageAccountName_var
  location: location
  sku: {
    name: 'Standard_LRS'
  }
  kind: 'Storage'
  properties: {}
}

resource publicIPAddressName 'Microsoft.Network/publicIPAddresses@2016-09-01' = {
  name: publicIPAddressName_var
  location: location
  properties: {
    publicIPAllocationMethod: 'Dynamic'
    dnsSettings: {
      domainNameLabel: spinnakerDnsPrefix
    }
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
      vmSize: 'Standard_D3_v2'
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
      }
    }
    networkProfile: {
      networkInterfaces: [
        {
          id: nicName.id
        }
      ]
    }
    diagnosticsProfile: {
      bootDiagnostics: {
        enabled: true
        storageUri: concat(reference(storageAccountName.id, '2016-01-01').primaryEndpoints.blob)
      }
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
      commandToExecute: './${extensionScript} -ai "${servicePrincipalAppId}" -ak "${servicePrincipalAppKey}" -si "${subscription().subscriptionId}" -ti "${subscription().tenantId}" -un "${adminUsername}" -rg "${resourceGroup().name}" -mf "${kubernetesName.properties.masterProfile.fqdn}" -san "${storageAccountName_var}" -sak "${listKeys(storageAccountName.id, '2016-01-01').keys[0].value}" -acr "${acrPrefix.properties.loginServer}" -ikp $(expr "${kubernetesPipeline}" == "Include") -prg "${pipelineRegistry}" -prp "${pipelineRepository}" -pp "${pipelinePort}" -al "${artifactsLocation}" -st "${artifactsLocationSasToken}"'
    }
  }
  dependsOn: [
    vmName
  ]
}

resource acrStorageAccountName 'Microsoft.Storage/storageAccounts@2016-01-01' = {
  name: acrStorageAccountName_var
  location: location
  kind: 'Storage'
  sku: {
    name: 'Standard_LRS'
  }
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

resource acrPrefix 'Microsoft.ContainerRegistry/registries@2017-03-01' = {
  name: acrPrefix_var
  location: location
  sku: {
    name: 'Basic'
  }
  properties: {
    adminUserEnabled: false
    storageAccount: {
      name: acrStorageAccountName_var
      accessKey: listKeys(acrStorageAccountName.id, '2016-01-01').keys[0].value
    }
  }
}

output spinnakerVmFQDN string = reference(publicIPAddressName_var).dnsSettings.fqdn
output SSH string = 'ssh -L 9000:localhost:9000 -L 8084:localhost:8084 -L 8001:localhost:8001 ${adminUsername}@${reference(publicIPAddressName_var).dnsSettings.fqdn}'
output kubernetesMasterFQDN string = kubernetesName.properties.masterProfile.fqdn
output kubernetesMasterSsh string = 'ssh ${adminUsername}@${kubernetesName.properties.masterProfile.fqdn}'
output azureContainerRegistryName string = acrPrefix.properties.loginServer