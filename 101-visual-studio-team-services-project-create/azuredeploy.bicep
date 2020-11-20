param accountName string {
  metadata: {
    description: 'The name of the Visual Studio Team Services account, if it doesn\'t exist it will be created.'
  }
}
param projectName string {
  metadata: {
    description: 'The name of the Visual Studio Team Services project.'
  }
}
param processTemplateId string {
  allowed: [
    '6B724908-EF14-45CF-84F8-768B5384DA45'
    'ADCC42AB-9882-485E-A3ED-7678F01F66BC'
    '27450541-8E31-4150-9947-DC59F998FC01'
  ]
  metadata: {
    description: 'Scrum: 6B724908-EF14-45CF-84F8-768B5384DA45 / Agile: ADCC42AB-9882-485E-A3ED-7678F01F66BC / CMMI: 27450541-8E31-4150-9947-DC59F998FC01'
  }
  default: '6B724908-EF14-45CF-84F8-768B5384DA45'
}
param versionControlOption string {
  allowed: [
    'Git'
    'Tfvc'
  ]
  metadata: {
    description: 'The version control of the Visual Studio Team Services project\'s source code: Git or Tfvc.'
  }
  default: 'Git'
}
param location string {
  metadata: {
    description: 'Location for all resources.'
  }
  default: resourceGroup().location
}

resource accountName_res 'microsoft.visualstudio/account@2014-04-01-preview' = {
  name: accountName
  location: location
  properties: {
    operationType: 'Create'
    accountName: accountName
  }
}

resource accountName_projectName 'microsoft.visualstudio/account/project@2014-04-01-preview' = {
  name: '${accountName}/${projectName}'
  location: location
  properties: {
    ProcessTemplateId: processTemplateId
    VersionControlOption: versionControlOption
  }
  dependsOn: [
    accountName_res
  ]
}