@description('The name of the Visual Studio Team Services account, if it doesn\'t exist it will be created.')
param accountName string

@description('The name of the Visual Studio Team Services project.')
param projectName string

@allowed([
  '6B724908-EF14-45CF-84F8-768B5384DA45'
  'ADCC42AB-9882-485E-A3ED-7678F01F66BC'
  '27450541-8E31-4150-9947-DC59F998FC01'
])
@description('Scrum: 6B724908-EF14-45CF-84F8-768B5384DA45 / Agile: ADCC42AB-9882-485E-A3ED-7678F01F66BC / CMMI: 27450541-8E31-4150-9947-DC59F998FC01')
param processTemplateId string = '6B724908-EF14-45CF-84F8-768B5384DA45'

@allowed([
  'Git'
  'Tfvc'
])
@description('The version control of the Visual Studio Team Services project\'s source code: Git or Tfvc.')
param versionControlOption string = 'Git'

@description('Location for all resources.')
param location string = resourceGroup().location

resource accountName_resource 'microsoft.visualstudio/account@2014-04-01-preview' = {
  name: accountName
  location: location
  properties: {
    operationType: 'Create'
    accountName: accountName
  }
}

resource accountName_projectName 'microsoft.visualstudio/account/project@2014-04-01-preview' = {
  parent: accountName_resource
  name: '${projectName}'
  location: location
  properties: {
    ProcessTemplateId: processTemplateId
    VersionControlOption: versionControlOption
  }
}