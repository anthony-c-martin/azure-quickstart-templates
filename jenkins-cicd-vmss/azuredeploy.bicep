@minLength(1)
@description('User name for the Jenkins Virtual Machine.')
param jenkinsVMAdminUsername string

@minLength(3)
@description('Unique DNS Name for the Public IP used to access the Jenkins Virtual Machine.')
param jenkinsDnsPrefix string

@allowed([
  'LTS'
  'weekly'
  'verified'
])
@description('The Jenkins release type.')
param jenkinsReleaseType string = 'LTS'

@minLength(1)
@description('GitHub repository URL for the source code.')
param repositoryUrl string = 'https://github.com/Azure/azure-quickstart-templates'

@minLength(1)
@description('Client id for Azure service principal.')
param clientId string

@minLength(1)
@description('Client secret for Azure service principal.')
param clientSecret string

@minLength(3)
@description('Unique DNS Name for the new Tomcat Virtual Machine.')
param VMDnsPrefix string

@minLength(3)
@description('Username for the new Tomcat Virtual Machine.')
param VMAdminUsername string

@minLength(6)
@description('Password for the new Tomcat Virtual Machine.')
@secure()
param VMAdminPassword string

@minLength(3)
@description('OMS workspace name.')
param OMSWorkspaceName string

@description('The base URI where artifacts required by this template are located. When the template is deployed using the accompanying scripts, a private location in the subscription will be used and this value will be automatically generated.')
param artifactsLocation string = 'https://raw.githubusercontent.com/Azure/azure-quickstart-templates/master/jenkins-cicd-vmss/'

@description('The sasToken required to access _artifactsLocation.  When the template is deployed using the accompanying scripts, a sasToken will be automatically generated.')
@secure()
param artifactsLocationSasToken string = ''

@allowed([
  'sshPublicKey'
  'password'
])
@description('Type of authentication to use on the Virtual Machine. SSH key is recommended.')
param authenticationType string = 'sshPublicKey'

@description('SSH Key or password for the Virtual Machine. SSH key is recommended.')
@secure()
param adminPasswordOrKey string

var VMResourceGroup = '${take(resourceGroup().name, 70)}VMSS${uniqueString(resourceGroup().id)}'

resource OMSWorkspaceName_resource 'Microsoft.OperationalInsights/workspaces@2017-04-26-preview' = {
  name: OMSWorkspaceName
  location: 'eastus'
  properties: {
    sku: {
      name: 'pernode'
    }
  }
}

module jenkinsDeployment '?' /*TODO: replace with correct path to [uri(parameters('_artifactsLocation'), concat('nested/jenkins.json', parameters('_artifactsLocationSasToken')))]*/ = {
  name: 'jenkinsDeployment'
  params: {
    adminUsername: jenkinsVMAdminUsername
    dnsPrefix: jenkinsDnsPrefix
    jenkinsReleaseType: jenkinsReleaseType
    repositoryUrl: repositoryUrl
    clientId: clientId
    clientSecret: clientSecret
    VMResourceGroup: VMResourceGroup
    VMDnsPrefix: VMDnsPrefix
    VMAdminUsername: VMAdminUsername
    VMAdminPassword: VMAdminPassword
    OMSWorkspaceId: reference(OMSWorkspaceName_resource.id, '2017-04-26-preview').customerId
    OMSWorkspaceKey: listKeys(OMSWorkspaceName_resource.id, '2017-04-26-preview').primarySharedKey
    '_artifactsLocation': artifactsLocation
    '_artifactsLocationSasToken': artifactsLocationSasToken
    authenticationType: authenticationType
    adminPasswordOrKey: adminPasswordOrKey
  }
}

output jenkinsURL string = reference('jenkinsDeployment').outputs.jenkinsURL.value
output jenkinsSSH string = reference('jenkinsDeployment').outputs.jenkinsSSH.value
output VMSSResourceGroup string = VMResourceGroup