param deploymentPrefix string {
  metadata: {
    description: 'Deployment Name of the Stack'
  }
}
param desktopUsername string {
  metadata: {
    description: 'Desktop Administrator Name'
  }
}
param desktopAdminPassword string {
  metadata: {
    description: 'Desktop Administrator Password'
  }
  secure: true
}
param asperaUsername string {
  metadata: {
    description: 'Aspera Server Administrator Name'
  }
}
param asperaAdminPassword string {
  metadata: {
    description: 'Aspera Server Administrator Password'
  }
  secure: true
}
param wowzaUsername string {
  metadata: {
    description: 'Wowza Streaming Server Administrator Name'
  }
}
param automationAccountName string {
  metadata: {
    description: 'The account name must not be empty, and must not exceed 50 characters in length.  The account name must start with a letter or number.  The account name can contain letters, numbers, and dashes.  The final character must be a letter or a number. '
  }
  default: 'auto'
}
param jobId string {
  metadata: {
    description: 'Generate a Job ID (GUID) from https://www.guidgenerator.com/online-guid-generator.aspx '
  }
  default: '24b18f62-aa2c-4528-ac10-1e3602eb4053'
}
param location string {
  metadata: {
    description: 'Location for all resources.'
  }
  default: resourceGroup().location
}
param artifactsLocation string {
  metadata: {
    description: 'The base URI where artifacts required by this template are located. When the template is deployed using the accompanying scripts, a private location in the subscription will be used and this value will be automatically generated.'
  }
  default: 'https://raw.githubusercontent.com/Azure/azure-quickstart-templates/master/vod-aspera-wowza-azuremediaservices/'
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

var automationAccountName_variable = concat(automationAccountName, uniqueString(resourceGroup().id))

module ams '<failed to parse [uri(parameters(\'_artifactsLocation\'), concat(\'ams/ams.json\', parameters(\'_artifactsLocationSasToken\')))]>' = {
  name: 'ams'
  params: {}
}

module automationjob '<failed to parse [uri(parameters(\'_artifactsLocation\'), concat(\'ams/automationjob.json\', parameters(\'_artifactsLocationSasToken\')))]>' = {
  name: 'automationjob'
  params: {
    automationAccountName: automationAccountName_variable
    jobId: jobId
    MediaServices_Name: reference('ams').outputs.MediaServices_Name.value
    MediaServices_Keys: reference('ams').outputs.MediaServices_Keys.value
    Input_StorageAccounts_Name: reference('ams').outputs.Input_StorageAccounts_Name.value
    Input_StorageAccounts_Keys: reference('ams').outputs.Input_StorageAccounts_Keys.value
    Ouput_StorageAccounts_Name: reference('ams').outputs.Ouput_StorageAccounts_Name.value
    Output_StorageAccounts_Keys: reference('ams').outputs.Output_StorageAccounts_Keys.value
    MediaService_StorageAccounts_Name: reference('ams').outputs.MediaService_StorageAccounts_Name.value
    MediaService_StorageAccounts_Keys: reference('ams').outputs.MediaService_StorageAccounts_Keys.value
    '_artifactsLocation': artifactsLocation
    '_artifactsLocationSasToken': artifactsLocationSasToken
  }
  dependsOn: [
    ams
  ]
}

module desktop '<failed to parse [uri(parameters(\'_artifactsLocation\'), concat(\'desktop/desktop.json\', parameters(\'_artifactsLocationSasToken\')))]>' = {
  name: 'desktop'
  params: {
    deploymentPrefix: deploymentPrefix
    storageAccountName: reference('ams').outputs.Input_StorageAccounts_Name.value
    storageAccountKey: reference('ams').outputs.Input_StorageAccounts_Keys.value
    containerName: 'videos'
    desktopUsername: desktopUsername
    desktopAdminPassword: desktopAdminPassword
  }
  dependsOn: [
    ams
  ]
}

module aspera '<failed to parse [uri(parameters(\'_artifactsLocation\'), concat(\'aspera/aspera.json\', parameters(\'_artifactsLocationSasToken\')))]>' = {
  name: 'aspera'
  params: {
    deploymentPrefix: deploymentPrefix
    asperaUsername: asperaUsername
    asperaAdminPassword: asperaAdminPassword
    '_artifactsLocation': artifactsLocation
    '_artifactsLocationSasToken': artifactsLocationSasToken
  }
  dependsOn: [
    ams
  ]
}

module wowza '<failed to parse [uri(parameters(\'_artifactsLocation\'), concat(\'wowza/wowza.json\', parameters(\'_artifactsLocationSasToken\')))]>' = {
  name: 'wowza'
  params: {
    deploymentPrefix: deploymentPrefix
    storageAccountName: reference('ams').outputs.Ouput_StorageAccounts_Name.value
    storageAccountKey: reference('ams').outputs.Output_StorageAccounts_Keys.value
    containerName: 'videos'
    wowzaUsername: wowzaUsername
    '_artifactsLocation': artifactsLocation
    '_artifactsLocationSasToken': artifactsLocationSasToken
    authenticationType: authenticationType
    adminPasswordOrKey: adminPasswordOrKey
  }
  dependsOn: [
    ams
  ]
}

output Input_StorageAccounts_Name string = reference('ams').outputs.Input_StorageAccounts_Name.value
output Input_StorageAccounts_Keys string = reference('ams').outputs.Input_StorageAccounts_Keys.value
output Ouput_StorageAccounts_Name string = reference('ams').outputs.Ouput_StorageAccounts_Name.value
output Output_StorageAccounts_Keys string = reference('ams').outputs.Output_StorageAccounts_Keys.value
output desktopURL string = reference('desktop').outputs.desktopURL.value
output desktopUsername_output string = desktopUsername
output desktopAdminPassword_output string = desktopAdminPassword
output asperaURL string = reference('aspera').outputs.asperaURL.value
output asperaUsername_output string = asperaUsername
output asperaAdminPassword_output string = asperaAdminPassword
output wowzaURL string = reference('wowza').outputs.wowzaURL.value
output wowzaUsername_output string = wowzaUsername