param spClientId string {
  metadata: {
    description: 'Service Principal Client ID used by Jenkins and Azure Container Service (AKS).'
  }
}
param spClientSecret string {
  metadata: {
    description: 'Service Principal Client Secret used by Jenkins and Azure Container Service(AKS).'
  }
  secure: true
}
param linuxAdminUsername string {
  metadata: {
    description: 'User name for the Linux Virtual Machines (Jenkins and Kubernetes).'
  }
}
param linuxAdminPassword string {
  metadata: {
    description: 'Password for the Jenkins and Grafana Virtual Machines.'
  }
  secure: true
}
param linuxSSHPublicKey string {
  metadata: {
    description: 'Configure all linux machines with the SSH RSA public key string. Your key should include three parts, for example \'ssh-rsa AAAAB...snip...UcyupgH azureuser@linuxvm\''
  }
}
param cosmosDbName string {
  metadata: {
    description: 'Name of the CosmosDB.'
  }
}
param acrName string {
  metadata: {
    description: 'Name of the Azure Container Registery. The name may contain alpha numeric characters only and must be between 5 and 50 characters.'
  }
}
param jenkinsDnsPrefix string {
  metadata: {
    description: 'Unique DNS Name for the Public IP used to access the Jenkins Virtual Machine.'
  }
}
param grafanaDnsPrefix string {
  metadata: {
    description: 'Unique DNS Name for the Public IP used to access the Grafana Virtual Machine.'
  }
}
param grafanaVMSize string {
  metadata: {
    description: 'The size of the Kubernetes host virtual machine.'
  }
  default: 'Standard_DS2_v2'
}
param jenkinsVMSize string {
  metadata: {
    description: 'The size of the Kubernetes host virtual machine.'
  }
  default: 'Standard_DS2_v2'
}
param kubernetesDnsPrefix string {
  metadata: {
    description: 'Optional DNS prefix to use with hosted Kubernetes API server FQDN.'
  }
}
param kubernetesClusterName string {
  metadata: {
    description: 'The name of the Managed Cluster resource.'
  }
}
param kubernetesAgentCount int {
  minValue: 1
  maxValue: 50
  metadata: {
    description: 'The number of nodes for the cluster.'
  }
  default: 1
}
param kubernetesAgentVMSize string {
  metadata: {
    description: 'The size of the Kubernetes host virtual machine.'
  }
  default: 'Standard_DS2_v2'
}
param kubernetesVersion string {
  allowed: [
    '1.14.8'
    '1.14.7'
    '1.13.12'
    '1.13.11'
    '1.12.8'
    '1.12.7'
    '1.11.10'
    '1.11.9'
    '1.10.13'
    '1.10.12'
  ]
  metadata: {
    description: 'The version of Kubernetes.'
  }
  default: '1.14.8'
}
param gitRepository string {
  metadata: {
    description: 'URL to a public git repository that includes a Dockerfile.'
  }
  default: 'https://github.com/Azure/azure-quickstart-templates'
}
param artifactsLocation string {
  metadata: {
    description: 'The base URI where artifacts required by this template are located. When the template is deployed using the accompanying scripts, a private location in the subscription will be used and this value will be automatically generated.'
  }
  default: 'https://raw.githubusercontent.com/Azure/azure-quickstart-templates/master/jenkins-cicd-container/'
}
param artifactsLocationSasToken string {
  metadata: {
    description: 'The sasToken required to access _artifactsLocation.  When the template is deployed using the accompanying scripts, a sasToken will be automatically generated.'
  }
  secure: true
  default: ''
}
param location string {
  metadata: {
    description: 'Location for all resources.'
  }
  default: resourceGroup().location
}

var jenkinsVMName = 'jenkins'
var grafanaVMName = 'grafana'
var cosmosDbName_var = cosmosDbName
var acrName_var = acrName
var virtualNetworkName_var = 'virtual-network'
var subnetName = 'default-subnet'

resource acrName_res 'Microsoft.ContainerRegistry/registries@2019-05-01' = {
  name: acrName_var
  location: location
  sku: {
    name: 'Basic'
  }
  properties: {
    adminUserEnabled: true
  }
}

resource cosmosDbName_res 'Microsoft.DocumentDb/databaseAccounts@2016-03-31' = {
  kind: 'MongoDB'
  name: cosmosDbName_var
  location: location
  properties: {
    databaseAccountOfferType: 'Standard'
  }
}

resource virtualNetworkName 'Microsoft.Network/virtualNetworks@2019-06-01' = {
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

module jenkinsDeployment '?' /*TODO: replace with correct path to [uri(parameters('_artifactsLocation'), concat('nested/jenkins.json', parameters('_artifactsLocationSasToken')))]*/ = {
  name: 'jenkinsDeployment'
  params: {
    jenkinsVMName: jenkinsVMName
    jenkinsVMSize: jenkinsVMSize
    spClientId: spClientId
    spClientSecret: spClientSecret
    linuxAdminUsername: linuxAdminUsername
    linuxAdminPassword: linuxAdminPassword
    dnsPrefix: jenkinsDnsPrefix
    subnetId: resourceId('Microsoft.Network/virtualNetworks/subnets', virtualNetworkName_var, subnetName)
    gitRepository: gitRepository
    acrServer: acrName_res.properties.loginServer
    acrUsername: listCredentials(acrName_res.id, '2019-05-01').username
    acrPassword: listCredentials(acrName_res.id, '2019-05-01').passwords[0].value
    mongoDbURI: 'mongodb://${cosmosDbName_var}:${uriComponent(listKeys(cosmosDbName_res.id, '2016-03-31').primaryMasterKey)}@${cosmosDbName_var}.documents.azure.com:10255/?ssl=true&replicaSet=globaldb'
    kubernetesResourceGroupName: resourceGroup().name
    kubernetesClusterName: kubernetesClusterName
    '_artifactsLocation': artifactsLocation
    '_artifactsLocationSasToken': artifactsLocationSasToken
    location: location
  }
  dependsOn: [
    acrName_res
    virtualNetworkName
    cosmosDbName_res
  ]
}

resource kubernetesClusterName_res 'Microsoft.ContainerService/managedClusters@2019-10-01' = {
  location: location
  name: kubernetesClusterName
  properties: {
    kubernetesVersion: kubernetesVersion
    dnsPrefix: kubernetesDnsPrefix
    agentPoolProfiles: [
      {
        name: 'agentpool'
        osDiskSizeGB: 0
        count: kubernetesAgentCount
        vmSize: kubernetesAgentVMSize
        osType: 'Linux'
        storageProfile: 'ManagedDisks'
      }
    ]
    linuxProfile: {
      adminUsername: linuxAdminUsername
      ssh: {
        publicKeys: [
          {
            keyData: linuxSSHPublicKey
          }
        ]
      }
    }
    servicePrincipalProfile: {
      clientId: spClientId
      secret: spClientSecret
    }
  }
}

module grafanaDeployment '?' /*TODO: replace with correct path to [uri(parameters('_artifactsLocation'), concat('nested/grafana.json', parameters('_artifactsLocationSasToken')))]*/ = {
  name: 'grafanaDeployment'
  params: {
    grafanaVMName: grafanaVMName
    grafanaVMSize: grafanaVMSize
    spClientId: spClientId
    spClientSecret: spClientSecret
    linuxAdminUsername: linuxAdminUsername
    linuxAdminPassword: linuxAdminPassword
    dnsPrefix: grafanaDnsPrefix
    subnetId: resourceId('Microsoft.Network/virtualNetworks/subnets', virtualNetworkName_var, subnetName)
    cosmosDbName: cosmosDbName
    kubernetesClusterName: kubernetesClusterName
    '_artifactsLocation': artifactsLocation
    '_artifactsLocationSasToken': artifactsLocationSasToken
    location: location
  }
  dependsOn: [
    cosmosDbName_res
    kubernetesClusterName_res
  ]
}

output jenkinsURL string = reference('jenkinsDeployment').outputs.jenkinsURL.value
output jenkinsSSH string = reference('jenkinsDeployment').outputs.jenkinsSSH.value
output azureContainerRegistryUrl string = acrName_res.properties.loginServer
output kubernetesControlPlaneFQDN string = reference('Microsoft.ContainerService/managedClusters/${kubernetesClusterName}').fqdn
output grafanaUrl string = reference('grafanaDeployment').outputs.grafanaURL.value