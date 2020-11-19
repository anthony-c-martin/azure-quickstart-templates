param location string {
  allowed: [
    'eastus'
    'northcentralus'
    'northeurope'
    'southcentralus'
    'westeurope'
    'westus'
    'centralus'
    'eastus2'
    'westus2'
  ]
  metadata: {
    description: 'The location where the solution will be deployed.'
  }
  default: 'westus'
}
param jenkinsDnsNameForPublicIP string {
  metadata: {
    description: 'Unique DNS Name for the Public IP used to access the Jenkins Operations Center Web Front-End.'
  }
  default: 'ocdns'
}
param jenkinsUsername string {
  metadata: {
    description: 'Admin User name for SSH Cloudbees Jenkins related Virtual Machines.'
  }
  default: 'ashuser'
}
param jenkinsPassword string {
  metadata: {
    description: 'Admin Password for SSH Cloudbees Jenkins related Virtual Machines.'
  }
  secure: true
  default: ''
}
param jenkinsAdminPassword string {
  metadata: {
    description: 'Password for the \'admin\' user on jenkins initial security setup.'
  }
  secure: true
}
param size string {
  metadata: {
    description: 'Size of your CloudBees Jenkins Platform deployment.'
  }
  default: 'Project'
}
param ucpControllerCount int {
  metadata: {
    description: 'Number of UCP Controller VMs'
  }
  default: 3
}
param ucpNodeCount int {
  metadata: {
    description: 'Number of UCP node VMs'
  }
  default: 3
}
param ucpDtrNodeCount int {
  metadata: {
    description: 'Number of DTR node VMs'
  }
  default: 3
}
param dockerAdminUsername string {
  metadata: {
    description: 'OS Admin User Name for UCP Controller Nodes, UCP Nodes and DTR Nodes'
  }
  default: 'ucpadmin'
}
param dockerAdminPassword string {
  metadata: {
    description: 'OS Admin password'
  }
  secure: true
  default: ''
}
param controllerLbPublicIpDnsName string {
  metadata: {
    description: 'DNS label of Public IP for Controller Load Balancer'
  }
  default: 'dockercontrdns'
}
param nodeLbPublicIpDnsName string {
  metadata: {
    description: 'DNS label for UCP Nodes Load Balancer'
  }
  default: 'ucpnodedns'
}
param nodeDtrLbPublicIpDnsName string {
  metadata: {
    description: 'DNS label of Public IP for DTR Load Balancer'
  }
  default: 'dtrnodedns'
}
param ucpLicenseKey string {
  metadata: {
    description: 'License Key for UCP (Url)'
  }
  default: ''
}
param ucpAdminPassword string {
  metadata: {
    description: 'Password for UCP Admin Account'
  }
  secure: true
}
param artifactsLocation string {
  metadata: {
    description: 'The base URI where artifacts required by this template are located. When the template is deployed using the accompanying scripts, a private location in the subscription will be used and this value will be automatically generated.'
  }
  default: 'https://raw.githubusercontent.com/Azure/azure-quickstart-templates/master/cloudbeesjenkins-dockerdatacenter/'
}
param artifactsLocationSasToken string {
  metadata: {
    description: 'The sasToken required to access _artifactsLocation.  When the template is deployed using the accompanying scripts, a sasToken will be automatically generated.'
  }
  secure: true
  default: ''
}

var networkApiVersion = '2015-06-15'
var storageAccountNameCloudbees = 'cbstor${uniqueString}'
var storageAccountType = 'Standard_LRS'
var virtualNetworkName = 'MyVnet'
var virtualNetworkAddressPrefix = '10.0.0.0/16'
var jenkinsSubnetName = 'jenkins-subnet'
var jenkinsSubnetPrefix = '10.0.0.0/24'
var ucpControllerSubnetName = 'ucp-controller-subnet'
var ucpControllerSubnetPrefix = '10.0.1.0/24'
var ucpdtrNodeSubnetName = 'ucp-node-subnet'
var ucpdtrnodeSubnetPrefix = '10.0.2.0/24'
var vmSize = 'Standard_A2'
var uniqueString = uniqueString(resourceGroup().id)
var dockerDataCenterClusterPrefix = 'ucpclus'
var ucpControllerSize = 'Standard_DS2_v2'
var ucpNodeSize = 'Standard_DS2_v2'
var ucpDtrNodeSize = 'Standard_DS2_v2'
var dockerAuthenticationType = 'password'
var dockersshPublicKey = ''
var controllerLbPublicIpAddress = 'clbpip'
var nodeLbPublicIpAddress = 'nlbpip'
var nodeDtrLbPublicIpAddress = 'dlbpip'
var vnetDeploymentURI = uri(artifactsLocation, 'nested/newvnet.json${artifactsLocationSasToken}')
var cloubeesDeploymnetURI = uri(artifactsLocation, 'nested/cloudbees-jenkins-deployment.json${artifactsLocationSasToken}')
var dockerDataCenterDeploymentURI = uri(artifactsLocation, 'nested/docker-data-center-deployment.json${artifactsLocationSasToken}')
var cloudbeesLocation = location
var jenkinsPublicIPName = 'jenkinsPublicIP'
var jenkinsPublicIPNewOrExisting = 'new'
var jenkinsTemplateBaseUrl = 'https://gallery.azure.com/artifact/20151001/cloudbees.jenkins-platformjenkins-platform.1.0.14/Artifacts'
var jenkinsDnsNameForPublicIP_variable = concat(jenkinsDnsNameForPublicIP, uniqueString)
var jenkinsAuthenticationType = 'password'
var jenkinssshPublicKey = ''
var dockerTags = {
  type: 'object'
  provider: '8CF0E79C-DF97-4992-9B59-602DB544D354'
}
var cloudbeesTags = {
  type: 'object'
  provider: '9F392E29-83D7-4569-AE61-608E2708A010'
}
var quickstartTags = {
  type: 'object'
  name: 'cloudbeesjenkins-dockerdatacenter'
}

module virtualNetworkDeployment '<failed to parse [variables(\'vnetDeploymentURI\')]>' = {
  name: 'virtualNetworkDeployment'
  params: {
    location: location
    virtualNetworkName: virtualNetworkName
    virtualNetworkAddressPrefix: virtualNetworkAddressPrefix
    jenkinsSubnetName: jenkinsSubnetName
    jenkinsSubnetPrefix: jenkinsSubnetPrefix
    controllerSubnetName: ucpControllerSubnetName
    controllerSubnetPrefix: ucpControllerSubnetPrefix
    nodeSubnetName: ucpdtrNodeSubnetName
    nodeSubnetPrefix: ucpdtrnodeSubnetPrefix
    apiVersion: networkApiVersion
    dockerTags: dockerTags
    cloudbeesTags: cloudbeesTags
    quickstartTags: quickstartTags
  }
}

module cloudbeesDeployment '<failed to parse [variables(\'cloubeesDeploymnetURI\')]>' = {
  name: 'cloudbeesDeployment'
  params: {
    templateBaseUrl: jenkinsTemplateBaseUrl
    location: cloudbeesLocation
    storageAccountName: storageAccountNameCloudbees
    storageAccountType: storageAccountType
    publicIPNewOrExisting: jenkinsPublicIPNewOrExisting
    publicIPName: jenkinsPublicIPName
    dnsNameForPublicIP: jenkinsDnsNameForPublicIP_variable
    authenticationType: jenkinsAuthenticationType
    sshPublicKey: jenkinssshPublicKey
    adminUsername: jenkinsUsername
    adminPassword: jenkinsPassword
    jenkinsAdminPassword: jenkinsAdminPassword
    vmSize: vmSize
    size: size
    subnetName: jenkinsSubnetName
    dockerTags: dockerTags
    cloudbeesTags: cloudbeesTags
    quickstartTags: quickstartTags
  }
  dependsOn: [
    virtualNetworkDeployment
  ]
}

module dockerDatacenterDeployment '<failed to parse [variables(\'dockerDataCenterDeploymentURI\')]>' = {
  name: 'dockerDatacenterDeployment'
  params: {
    '_artifactsLocation': artifactsLocation
    '_artifactsLocationSasToken': artifactsLocationSasToken
    location: location
    clusterPrefix: dockerDataCenterClusterPrefix
    ucpControllerSize: ucpControllerSize
    ucpControllerCount: ucpControllerCount
    ucpNodeSize: ucpNodeSize
    ucpNodeCount: ucpNodeCount
    ucpDtrNodeSize: ucpDtrNodeSize
    ucpDtrNodeCount: ucpDtrNodeCount
    adminUsername: dockerAdminUsername
    authenticationType: dockerAuthenticationType
    adminPassword: dockerAdminPassword
    sshPublicKey: dockersshPublicKey
    virtualNetworkName: virtualNetworkName
    controllerSubnetName: ucpControllerSubnetName
    nodeSubnetName: ucpdtrNodeSubnetName
    controllerLbPublicIpAddress: controllerLbPublicIpAddress
    controllerLbPublicIpDnsName: concat(controllerLbPublicIpDnsName, uniqueString)
    nodeLbPublicIpAddress: nodeLbPublicIpAddress
    nodeLbPublicIpDnsName: concat(nodeLbPublicIpDnsName, uniqueString)
    nodeDtrLbPublicIpAddress: nodeDtrLbPublicIpAddress
    nodeDtrLbPublicIpDnsName: concat(nodeDtrLbPublicIpDnsName, uniqueString)
    ucpLicenseKey: ucpLicenseKey
    ucpAdminPassword: ucpAdminPassword
    dockerTags: dockerTags
    cloudbeesTags: cloudbeesTags
    quickstartTags: quickstartTags
  }
  dependsOn: [
    virtualNetworkDeployment
  ]
}

output Cloudbees_Operations_Center_URL string = 'http://${reference('cloudbeesDeployment').outputs.operationsCenter.value}'
output Jenkins_Portal_Username string = reference('cloudbeesDeployment').outputs.jenkinsApplicationUsername.value
output Jenkins_Portal_Password string = reference('cloudbeesDeployment').outputs.jenkinsApplicationPassword.value
output UCP_Console_URL string = reference('dockerDatacenterDeployment').outputs.ucpConsoleAddress.value
output DTR_Console_URL string = reference('dockerDatacenterDeployment').outputs.dtrConsoleAddress.value
output UCP_Loadbalancer_DNS string = reference('dockerDatacenterDeployment').outputs.ucpNodeLoadBalancer.value