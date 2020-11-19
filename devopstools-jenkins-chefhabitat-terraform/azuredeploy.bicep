param adminUsername string {
  metadata: {
    description: 'username for the virtual machines.'
  }
}
param authenticationType string {
  metadata: {
    description: 'authentication type for the virtual machines.'
  }
  default: 'sshPublicKey'
}
param adminPassword string {
  metadata: {
    description: 'password for elk,vmss and mongodbterraform virtual machines'
  }
  secure: true
}
param sshPublicKey string {
  metadata: {
    description: 'generate ssh public key'
  }
}
param jenkinsVmSize string {
  metadata: {
    description: 'vm size'
  }
  default: 'Standard_DS2_v2'
}
param buildInstanceVmSize string {
  metadata: {
    description: 'vm size'
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
    description: 'kibana web ui password, the password should have alphanumeric values only'
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
param artifactsLocation string {
  metadata: {
    description: 'The base uri where artifacts required by this template are located. when the template is deployed using the accompanying scripts, a private location in the subscription will be used and this value will be automatically generated.'
  }
  default: 'https://raw.githubusercontent.com/Azure/azure-quickstart-templates/master/devopstools-jenkins-chefhabitat-terraform'
}
param artifactsLocationSasToken string {
  metadata: {
    description: 'The sastoken required to access _artifactslocation.  when the template is deployed using the accompanying scripts, a sasToken will be automatically generated.'
  }
  secure: true
  default: ''
}

var networkSettings = {
  location: location
  networkApiVersion: '2016-03-30'
  virtualNetworkName: 'OSS'
  addressPrefix: '10.0.0.0/16'
  subnet1Name: 'Jenkins'
  subnet1Prefix: '10.0.0.0/24'
  subnet2Name: 'Applicationnode'
  subnet2Prefix: '10.0.1.0/24'
  subnet3Name: 'ELK'
  subnet3Prefix: '10.0.2.0/24'
  subnet4Name: 'DB'
  subnet4Prefix: '10.0.3.0/24'
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
var azureSubscriptionId = subscription().subscriptionId
var azureTenantId = subscription().tenantId
var resourceGroupName_var = resourceGroup().name
var packerStorageAccountName_var = 'packerstrg${suffix}'
var publicIpAddressType = 'Dynamic'
var location = resourceGroup().location
var suffix = substring(uniqueString(resourceGroup().id), 0, 5)

resource packerStorageAccountName 'Microsoft.Storage/storageAccounts@2017-06-01' = {
  name: packerStorageAccountName_var
  location: location
  sku: {
    name: 'Standard_LRS'
  }
  kind: 'Storage'
  properties: {}
}

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
      {
        name: networkSettings.subnet4Name
        properties: {
          addressPrefix: networkSettings.subnet4Prefix
        }
      }
    ]
  }
}

module Jenkins '?' /*TODO: replace with correct path to [concat(parameters('_artifactsLocation'),'/nested/jenkins.json', parameters('_artifactsLocationSasToken'))]*/ = {
  name: 'Jenkins'
  params: {
    jenkinsSettings: jenkinsSettings
    networkSettings: networkSettings
    packerStorageAccountName: packerStorageAccountName_var
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
    AzureSubscriptionId: azureSubscriptionId
    AzureApplicationId: azureApplicationId
    AzureClientSecret: azureClientSecret
    AzureTenantId: azureTenantId
    packerStorageAccName: packerStorageAccountName_var
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
output StorageAccountName string = packerStorageAccountName_var
output BuildinstanceFQDN string = reference('BuildInstance').outputs.buildInstanceDNS.value
output buildInstanceUsername string = buildInstanceSettings.adminUsername