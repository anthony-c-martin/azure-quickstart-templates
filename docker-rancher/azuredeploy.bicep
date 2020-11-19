param adminUsername string {
  metadata: {
    description: 'Username for the Virtual Machine.'
  }
}
param adminPassword string {
  metadata: {
    description: 'Password for the Virtual Machine.'
  }
  secure: true
}
param uniqueDeployPrefix string {
  metadata: {
    description: 'The unique prefix used for the nodes & dns. Must be lowercase. It should match with the following regular expression: ^[a-z][a-z0-9-]{1,61}[a-z0-9]$ or it will raise an error.'
  }
}
param vmSize string {
  metadata: {
    description: 'The size of the virtual machine used for the deployment'
  }
  default: 'Standard_A2_v2'
}
param deploymentType string {
  allowed: [
    'Nodes'
    'Server'
  ]
  metadata: {
    description: 'Choose if you want to add nodes to an existing server or deploy a server without any nodes.'
  }
  default: 'Server'
}
param nodesApi string {
  metadata: {
    description: '(Ignored for deploymentType server) The api link to your RancherHost.'
  }
  default: ''
}
param nodesCount int {
  minValue: 1
  maxValue: 5
  metadata: {
    description: '(Ignored for deploymentType server) The amount of nodes to be provisioned'
  }
  default: 1
}
param artifactsLocation string {
  metadata: {
    description: 'The base URI where artifacts required by this template are located. For example, if stored on a public GitHub repo, you\'d use the following URI: https://raw.githubusercontent.com/Azure/azure-quickstart-templates/master/docker-rancher/.'
  }
  default: 'https://raw.githubusercontent.com/Azure/azure-quickstart-templates/master/docker-rancher/'
}
param artifactsLocationSasToken string {
  metadata: {
    description: 'The sasToken required to access _artifactsLocation.  If your artifacts are stored on a public repo or public storage account you can leave this blank.'
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

var deployTypeParam = {
  Nodes: 'nodes.json'
  Server: 'server.json'
}
var deployTypeParamValue = deployTypeParam[deploymentType]
var templateDeployUrl = uri(artifactsLocation, concat(deployTypeParamValue, artifactsLocationSasToken))

module rancherdeploy '?' /*TODO: replace with correct path to [variables('templateDeployUrl')]*/ = {
  name: 'rancherdeploy'
  params: {
    adminUsername: adminUsername
    adminPassword: adminPassword
    rancherApi: nodesApi
    rancherName: uniqueDeployPrefix
    rancherVmSize: vmSize
    rancherCount: nodesCount
    location: location
  }
}