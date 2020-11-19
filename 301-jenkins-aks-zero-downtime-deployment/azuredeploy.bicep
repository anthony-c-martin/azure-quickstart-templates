param adminUsername string {
  metadata: {
    description: 'User name for the Virtual Machine.'
  }
  default: 'azureuser'
}
param sshPublicKey string {
  metadata: {
    description: 'Configure all linux machines with the SSH public key string, for example \'ssh-rsa AAAAB...snip...UcyupgH azureuser@linuxvm\''
  }
}
param virtualMachineSize string {
  allowed: [
    'Standard_B2s'
    'Standard_B2ms'
    'Standard_D2s_v3'
    'Standard_D2_v3'
    'Standard_DS2_v2'
    'Standard_D2_v2'
    'Standard_DS2'
    'Standard_D2'
    'Standard_A2_v2'
    'Standard_A2'
  ]
  metadata: {
    description: 'The virutal machine size to use. We picked out the sizes with 2 vCPUs, but in real world projects you can choose other sizes as you desired.'
  }
  default: 'Standard_DS2_v2'
}
param kubernetesVersion string {
  allowed: [
    '1.10.13'
    '1.11.10'
    '1.12.8'
    '1.13.10'
    '1.14.6'
  ]
  metadata: {
    description: 'The version of Kubernetes.'
  }
  default: '1.14.6'
}
param jenkinsDnsPrefix string {
  metadata: {
    description: 'Unique DNS Name prefix for the Public IP used to access the Jenkins Virtual Machine. Azure will form the final DNS name as \'<prefix>.<region>.cloudapp.azure.com\'.'
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
param location string {
  metadata: {
    description: 'Location for all resources.'
  }
  default: resourceGroup().location
}

var resourcePrefix = 'jenkins'
var OSDiskName = '${resourcePrefix}-os-disk'
var nicName_var = '${resourcePrefix}-nic'
var subnetName = '${resourcePrefix}-subnet'
var publicIPAddressName_var = '${resourcePrefix}-ip'
var vmName_var = '${resourcePrefix}-vm'
var virtualNetworkName_var = '${resourcePrefix}-vnet'
var vmExtensionName = '${resourcePrefix}-init'
var frontEndNSGName_var = '${resourcePrefix}-nsg'
var aksName_var = 'aks'
var aksDnsPrefix = 'aks${uniqueString(resourceGroup().id)}'
var artifactsLocation = 'https://raw.githubusercontent.com/Azure/jenkins/master'
var extensionScript = '301-jenkins-aks-zero-downtime-deployment.sh'
var artifactsLocationSasToken = ''

resource vmName 'Microsoft.Compute/virtualMachines@2016-04-30-preview' = {
  name: vmName_var
  location: location
  properties: {
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
    hardwareProfile: {
      vmSize: virtualMachineSize
    }
    storageProfile: {
      imageReference: {
        publisher: 'Canonical'
        offer: 'UbuntuServer'
        sku: '16.04-LTS'
        version: 'latest'
      }
      osDisk: {
        name: OSDiskName
        createOption: 'FromImage'
        managedDisk: {
          storageAccountType: 'Standard_LRS'
        }
      }
      dataDisks: []
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
        '${artifactsLocation}/quickstart_templates/zero_downtime_deployment/${extensionScript}${artifactsLocationSasToken}'
      ]
    }
    protectedSettings: {
      commandToExecute: './${extensionScript} --app_id "${servicePrincipalAppId}" --app_key "${servicePrincipalAppKey}" --subscription_id "${subscription().subscriptionId}" --tenant_id "${subscription().tenantId}" --resource_group "${resourceGroup().name}" --aks_name "${aksName_var}" --jenkins_fqdn "${reference(publicIPAddressName_var).dnsSettings.fqdn}" --artifacts_location "${artifactsLocation}" --sas_token "${artifactsLocationSasToken}"'
    }
  }
}

resource virtualNetworkName 'Microsoft.Network/virtualNetworks@2016-12-01' = {
  name: virtualNetworkName_var
  location: location
  properties: {
    addressSpace: {
      addressPrefixes: [
        '10.89.0.0/16'
      ]
    }
    subnets: [
      {
        name: subnetName
        properties: {
          addressPrefix: '10.89.0.0/24'
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
          subnet: {
            id: resourceId('Microsoft.Network/virtualNetworks/subnets', virtualNetworkName_var, subnetName)
          }
          privateIPAllocationMethod: 'Dynamic'
          publicIPAddress: {
            id: publicIPAddressName.id
          }
        }
      }
    ]
    networkSecurityGroup: {
      id: frontEndNSGName.id
    }
  }
}

resource publicIPAddressName 'Microsoft.Network/publicIPAddresses@2017-06-01' = {
  name: publicIPAddressName_var
  location: location
  properties: {
    publicIPAllocationMethod: 'Dynamic'
    dnsSettings: {
      domainNameLabel: jenkinsDnsPrefix
    }
  }
}

resource frontEndNSGName 'Microsoft.Network/networkSecurityGroups@2017-06-01' = {
  name: frontEndNSGName_var
  location: location
  properties: {
    securityRules: [
      {
        name: 'default-allow-ssh'
        properties: {
          priority: 1000
          protocol: 'Tcp'
          access: 'Allow'
          direction: 'Inbound'
          sourceAddressPrefix: '*'
          sourcePortRange: '*'
          destinationAddressPrefix: '*'
          destinationPortRange: '22'
        }
      }
      {
        name: 'allow-jenkins-http'
        properties: {
          priority: 1001
          protocol: 'Tcp'
          access: 'Allow'
          direction: 'Inbound'
          sourceAddressPrefix: '*'
          sourcePortRange: '*'
          destinationAddressPrefix: '*'
          destinationPortRange: '80'
        }
      }
    ]
  }
}

resource aksName 'Microsoft.ContainerService/managedClusters@2017-08-31' = {
  location: location
  name: aksName_var
  properties: {
    kubernetesVersion: kubernetesVersion
    dnsPrefix: aksDnsPrefix
    agentPoolProfiles: [
      {
        name: 'agentpool'
        count: 2
        vmSize: virtualMachineSize
        osType: 'Linux'
        storageProfile: 'ManagedDisks'
      }
    ]
    linuxProfile: {
      adminUsername: adminUsername
      ssh: {
        publicKeys: [
          {
            path: '/home/${adminUsername}/.ssh/authorized_keys'
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

output admin_username string = adminUsername
output jenkins_vm_fqdn string = reference(publicIPAddressName_var).dnsSettings.fqdn
output jenkins_url string = 'http://${reference(publicIPAddressName_var).dnsSettings.fqdn}'
output SSH string = 'ssh -L 8080:localhost:8080 ${adminUsername}@${reference(publicIPAddressName_var).dnsSettings.fqdn}'
output kubernetes_master_fqdn string = aksName.properties.fqdn