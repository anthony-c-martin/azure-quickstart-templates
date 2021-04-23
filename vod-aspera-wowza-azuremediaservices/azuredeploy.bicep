@description('Deployment Name of the Stack')
param deploymentPrefix string

@description('Desktop Administrator Name')
param desktopUsername string

@description('Desktop Administrator Password')
@secure()
param desktopAdminPassword string

@description('Aspera Server Administrator Name')
param asperaUsername string

@description('Aspera Server Administrator Password')
@secure()
param asperaAdminPassword string

@description('Wowza Streaming Server Administrator Name')
param wowzaUsername string

@description('The account name must not be empty, and must not exceed 50 characters in length.  The account name must start with a letter or number.  The account name can contain letters, numbers, and dashes.  The final character must be a letter or a number. ')
param automationAccountName string = 'auto'

@description('Generate a Job ID (GUID) from https://www.guidgenerator.com/online-guid-generator.aspx ')
param jobId string = '24b18f62-aa2c-4528-ac10-1e3602eb4053'

@description('Location for all resources.')
param location string = resourceGroup().location

@description('The base URI where artifacts required by this template are located. When the template is deployed using the accompanying scripts, a private location in the subscription will be used and this value will be automatically generated.')
param artifactsLocation string = 'https://raw.githubusercontent.com/Azure/azure-quickstart-templates/master/vod-aspera-wowza-azuremediaservices/'

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

var automationAccountName_var = concat(automationAccountName, uniqueString(resourceGroup().id))

module ams '?' /*TODO: replace with correct path to [uri(parameters('_artifactsLocation'), concat('ams/ams.json', parameters('_artifactsLocationSasToken')))]*/ = {
  name: 'ams'
  params: {}
}

module automationjob '?' /*TODO: replace with correct path to [uri(parameters('_artifactsLocation'), concat('ams/automationjob.json', parameters('_artifactsLocationSasToken')))]*/ = {
  name: 'automationjob'
  params: {
    automationAccountName: automationAccountName_var
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

module desktop '?' /*TODO: replace with correct path to [uri(parameters('_artifactsLocation'), concat('desktop/desktop.json', parameters('_artifactsLocationSasToken')))]*/ = {
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

module aspera '?' /*TODO: replace with correct path to [uri(parameters('_artifactsLocation'), concat('aspera/aspera.json', parameters('_artifactsLocationSasToken')))]*/ = {
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

module wowza '?' /*TODO: replace with correct path to [uri(parameters('_artifactsLocation'), concat('wowza/wowza.json', parameters('_artifactsLocationSasToken')))]*/ = {
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
output desktopUsername string = desktopUsername
output desktopAdminPassword string = desktopAdminPassword
output asperaURL string = reference('aspera').outputs.asperaURL.value
output asperaUsername string = asperaUsername
output asperaAdminPassword string = asperaAdminPassword
output wowzaURL string = reference('wowza').outputs.wowzaURL.value
output wowzaUsername string = wowzaUsername