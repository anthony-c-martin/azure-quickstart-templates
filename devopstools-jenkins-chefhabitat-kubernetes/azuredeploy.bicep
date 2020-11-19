param adminUsername string {
  metadata: {
    description: 'user name for the virtual machines.'
  }
}
param azureUsername string {
  metadata: {
    description: 'azure portal login username'
  }
}
param azurePassword string {
  metadata: {
    description: 'azure portal login password'
  }
  secure: true
}
param sshPublicKey string {
  metadata: {
    description: 'generate ssh public key'
  }
}
param adminPassword string {
  metadata: {
    description: 'password for elk and vmss virtual machines'
  }
  secure: true
}
param jenkinsVmSize string {
  metadata: {
    description: 'vm size of jenkins server'
  }
  default: 'Standard_DS2_v2'
}
param buildInstanceVmSize string {
  metadata: {
    description: 'vm size of build instance'
  }
  default: 'Standard_DS1_v2'
}
param kibanaWebUIUsername string {
  metadata: {
    description: 'kibana web ui username'
  }
}
param kibanaWebUIPassword string {
  metadata: {
    description: 'kibana web ui password'
  }
  secure: true
}
param azureApplicationId string {
  metadata: {
    description: 'ad application id'
  }
}
param azureClientSecret string {
  metadata: {
    description: 'ad clientsecret'
  }
  secure: true
}
param kubernetesClusterName string {
  metadata: {
    description: 'name of kubernetes cluster'
  }
}
param agentCount string {
  metadata: {
    description: 'number of agents'
  }
  default: '3'
}
param agentVmSize string {
  metadata: {
    description: 'size of agent vm'
  }
  default: 'Standard_DS1_v2'
}
param masterCount string {
  metadata: {
    description: 'number of agents'
  }
  default: '1'
}
param masterVmSize string {
  metadata: {
    description: 'size of master vm'
  }
  default: 'Standard_DS1_v2'
}
param artifactsLocation string {
  metadata: {
    description: 'The base uri where artifacts required by this template are located. when the template is deployed using the accompanying scripts, a private location in the subscription will be used and this value will be automatically generated.'
  }
  default: 'https://raw.githubusercontent.com/Azure/azure-quickstart-templates/master/devopstools-jenkins-chefhabitat-kubernetes'
}
param artifactsLocationSasToken string {
  metadata: {
    description: 'The sastoken required to access _artifactslocation.  when the template is deployed using the accompanying scripts, a sasToken will be automatically generated.'
  }
  default: ''
}

var networkSettings = {
  location: location
  virtualNetworkName: 'OSS'
  addressPrefix: '10.0.0.0/16'
  subnet1Name: 'Jenkins'
  subnet1Prefix: '10.0.0.0/24'
  subnet2Name: 'kubernetes'
  subnet2Prefix: '10.0.1.0/24'
  subnet3Name: 'ELK'
  subnet3Prefix: '10.0.2.0/24'
}
var jenkinsSettings = {
  location: location
  jenkinsDiagnosticsStorageAccountName: 'jenkinsstrg${suffix}'
  jenkinsPipName: 'jenkins-pip'
  publicIpAddressType: publicIpAddressType
  jenkinsDnsLabelPrefix: 'jenkinsserver${suffix}'
  jenkinsfrontEndNSGName: 'jenkins-nsg'
  jenkinsNicName: 'jenkins-nic'
  jenkinsVmPrivateIP: '10.0.0.5'
  jenkinsVmName: 'jenkinsserver'
  adminUsername: adminUsername
  password: adminPassword
  kibanaWebUIUsername: kibanaWebUIUsername
  kibanaWebUIPassword: kibanaWebUIPassword
  authenticationType: authenticationType
  sshPublicKey: sshPublicKey
  jenkinsVmSize: jenkinsVmSize
  ubuntuSku: '16.04-LTS'
  storageAccountType: 'Standard_LRS'
  installJenkinsScriptName: 'install_jenkins.sh'
  jenkinsReleaseType: 'LTS'
  '_artifactsLocation': artifactsLocation
  '_artifactsLocationSasToken': artifactsLocationSasToken
  installJenkinsScriptUrl: '${artifactsLocation}/scripts/install_jenkins.sh${artifactsLocationSasToken}'
  installJenkinsjobsScriptUrl: '${artifactsLocation}/scripts/jenkins_deploy.sh${artifactsLocationSasToken}'
  elkfqdn: 'elk${suffix}'
  suffix: suffix
}
var buildInstanceSettings = {
  location: location
  buildInstanceDiagnosticsStorageAccountName: 'buildstrg${suffix}'
  buildInstancePipName: 'build-pip'
  publicIpAddressType: publicIpAddressType
  buildInstanceDnsLabelPrefix: 'buildserver${suffix}'
  buildInstanceNsgName: 'build-nsg'
  buildInstanceNicName: 'build-nic'
  buildInstanceVmName: 'buildinstance'
  adminUsername: adminUsername
  authenticationType: authenticationType
  sshPublicKey: sshPublicKey
  buildInstanceVmSize: buildInstanceVmSize
  ubuntuSku: '16.04-LTS'
  buildScriptUrl: '${artifactsLocation}/scripts/build.sh${artifactsLocationSasToken}'
}
var kubernetesSettings = {
  kubDnsLabelPrefix: concat(kubernetesDnsPrefix, suffix)
  kubernetesClusterName: kubernetesClusterName
  agentCount: agentCount
  agentVmSize: agentVmSize
  masterCount: masterCount
  masterVmSize: masterVmSize
  AzureUsername: azureUsername
  AzurePassword: azurePassword
  containerRegistry: concat(containerRegistry, suffix)
}
var authenticationType = 'sshPublicKey'
var resourceGroupName_var = resourceGroup().name
var kubernetesDnsPrefix = 'kub'
var containerRegistry = 'osscr'
var azureSubscriptionId = subscription().subscriptionId
var azureTenantId = subscription().tenantId
var publicIpAddressType = 'Dynamic'
var location = resourceGroup().location
var suffix = substring(uniqueString(resourceGroup().id), 0, 5)

resource jenkinsSettings_jenkinsfrontEndNSGName 'Microsoft.Network/networkSecurityGroups@2017-04-01' = {
  name: jenkinsSettings.jenkinsfrontEndNSGName
  location: jenkinsSettings.location
  properties: {
    securityRules: [
      {
        name: 'ssh-rule'
        properties: {
          access: 'Allow'
          description: 'Allow SSH'
          destinationAddressPrefix: '*'
          destinationPortRange: '22'
          direction: 'Inbound'
          priority: 100
          protocol: 'Tcp'
          sourceAddressPrefix: 'Internet'
          sourcePortRange: '*'
        }
      }
      {
        name: 'http-rule'
        properties: {
          access: 'Allow'
          description: 'Allow HTTP'
          destinationAddressPrefix: '*'
          destinationPortRange: '80'
          direction: 'Inbound'
          priority: 101
          protocol: 'Tcp'
          sourceAddressPrefix: 'Internet'
          sourcePortRange: '*'
        }
      }
      {
        name: 'Port_8080'
        properties: {
          access: 'Allow'
          description: 'Allow'
          destinationAddressPrefix: '*'
          destinationPortRange: '8080'
          direction: 'Inbound'
          priority: 102
          protocol: 'Tcp'
          sourceAddressPrefix: 'Internet'
          sourcePortRange: '*'
        }
      }
    ]
  }
}

resource networkSettings_virtualNetworkName 'Microsoft.Network/virtualNetworks@2017-04-01' = {
  name: networkSettings.virtualNetworkName
  location: networkSettings.location
  properties: {
    addressSpace: {
      addressPrefixes: [
        networkSettings.addressPrefix
      ]
    }
    subnets: [
      {
        name: networkSettings.subnet1Name
        properties: {
          addressPrefix: networkSettings.subnet1Prefix
          networkSecurityGroup: {
            id: jenkinsSettings_jenkinsfrontEndNSGName.id
          }
        }
      }
      {
        name: networkSettings.subnet2Name
        properties: {
          addressPrefix: networkSettings.subnet2Prefix
        }
      }
      {
        name: networkSettings.subnet3Name
        properties: {
          addressPrefix: networkSettings.subnet3Prefix
        }
      }
    ]
  }
}

module Jenkins '?' /*TODO: replace with correct path to [concat(parameters('_artifactsLocation'),'/nested/jenkins.json', parameters('_artifactsLocationSasToken'))]*/ = {
  name: 'Jenkins'
  params: {
    kubernetesSettings: kubernetesSettings
    jenkinsSettings: jenkinsSettings
    networkSettings: networkSettings
    resourceGroupName: resourceGroupName_var
    AzureSubscriptionId: azureSubscriptionId
    AzureApplicationId: azureApplicationId
    AzureClientSecret: azureClientSecret
    AzureTenantId: azureTenantId
    '_artifactsLocation': artifactsLocation
    '_artifactsLocationSasToken': artifactsLocationSasToken
  }
  dependsOn: [
    jenkinsSettings_jenkinsfrontEndNSGName
    networkSettings_virtualNetworkName
  ]
}

module BuildInstance '?' /*TODO: replace with correct path to [concat(parameters('_artifactsLocation'),'/nested/build-instance.json', parameters('_artifactsLocationSasToken'))]*/ = {
  name: 'BuildInstance'
  params: {
    buildInstanceSettings: buildInstanceSettings
    networkSettings: networkSettings
    AzureApplicationId: azureApplicationId
    AzureClientSecret: azureClientSecret
    AzureTenantId: azureTenantId
  }
  dependsOn: [
    networkSettings_virtualNetworkName
  ]
}

output ResourceGroupName string = resourceGroupName_var
output VirtualNetworkName string = networkSettings.virtualNetworkName
output JenkinsFQDN string = reference('Jenkins').outputs.jenkinsDNS.value
output JenkinsWebUIURL string = '${reference('Jenkins').outputs.jenkinsDNS.value}:8080'
output KibanaWebUIUsername_out string = kibanaWebUIUsername
output KibanaWebUIPassword_out string = kibanaWebUIPassword
output BuildinstanceFQDN string = reference('BuildInstance').outputs.buildInstanceDNS.value
output buildInstanceUsername string = buildInstanceSettings.adminUsername