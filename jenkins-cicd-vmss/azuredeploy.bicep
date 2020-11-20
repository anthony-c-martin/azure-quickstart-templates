param jenkinsVMAdminUsername string {
  minLength: 1
  metadata: {
    description: 'User name for the Jenkins Virtual Machine.'
  }
}
param jenkinsDnsPrefix string {
  minLength: 3
  metadata: {
    description: 'Unique DNS Name for the Public IP used to access the Jenkins Virtual Machine.'
  }
}
param jenkinsReleaseType string {
  allowed: [
    'LTS'
    'weekly'
    'verified'
  ]
  metadata: {
    description: 'The Jenkins release type.'
  }
  default: 'LTS'
}
param repositoryUrl string {
  minLength: 1
  metadata: {
    description: 'GitHub repository URL for the source code.'
  }
  default: 'https://github.com/Azure/azure-quickstart-templates'
}
param clientId string {
  minLength: 1
  metadata: {
    description: 'Client id for Azure service principal.'
  }
}
param clientSecret string {
  minLength: 1
  metadata: {
    description: 'Client secret for Azure service principal.'
  }
}
param VMDnsPrefix string {
  minLength: 3
  metadata: {
    description: 'Unique DNS Name for the new Tomcat Virtual Machine.'
  }
}
param VMAdminUsername string {
  minLength: 3
  metadata: {
    description: 'Username for the new Tomcat Virtual Machine.'
  }
}
param VMAdminPassword string {
  minLength: 6
  metadata: {
    description: 'Password for the new Tomcat Virtual Machine.'
  }
  secure: true
}
param OMSWorkspaceName string {
  minLength: 3
  metadata: {
    description: 'OMS workspace name.'
  }
}
param artifactsLocation string {
  metadata: {
    description: 'The base URI where artifacts required by this template are located. When the template is deployed using the accompanying scripts, a private location in the subscription will be used and this value will be automatically generated.'
  }
  default: 'https://raw.githubusercontent.com/Azure/azure-quickstart-templates/master/jenkins-cicd-vmss/'
}
param artifactsLocationSasToken string {
  metadata: {
    description: 'The sasToken required to access _artifactsLocation.  When the template is deployed using the accompanying scripts, a sasToken will be automatically generated.'
  }
  secure: true
  default: ''
}
param authenticationType string {
  allowed: [
    'sshPublicKey'
    'password'
  ]
  metadata: {
    description: 'Type of authentication to use on the Virtual Machine. SSH key is recommended.'
  }
  default: 'sshPublicKey'
}
param adminPasswordOrKey string {
  metadata: {
    description: 'SSH Key or password for the Virtual Machine. SSH key is recommended.'
  }
  secure: true
}

var VMResourceGroup = '${take(resourceGroup().name, 70)}VMSS${uniqueString(resourceGroup().id)}'

resource OMSWorkspaceName_res 'Microsoft.OperationalInsights/workspaces@2017-04-26-preview' = {
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
    OMSWorkspaceId: reference(OMSWorkspaceName_res.id, '2017-04-26-preview').customerId
    OMSWorkspaceKey: listKeys(OMSWorkspaceName_res.id, '2017-04-26-preview').primarySharedKey
    '_artifactsLocation': artifactsLocation
    '_artifactsLocationSasToken': artifactsLocationSasToken
    authenticationType: authenticationType
    adminPasswordOrKey: adminPasswordOrKey
  }
  dependsOn: [
    OMSWorkspaceName_res
  ]
}

output jenkinsURL string = reference('jenkinsDeployment').outputs.jenkinsURL.value
output jenkinsSSH string = reference('jenkinsDeployment').outputs.jenkinsSSH.value
output VMSSResourceGroup string = VMResourceGroup