@description('Specify the workspace region')
param location string = resourceGroup().location

@description('Specify the workspace name')
param workspaceName string

@description('The base URI where artifacts required by this template are located')
param artifactsLocation string = 'https://raw.githubusercontent.com/Azure/azure-quickstart-templates/master/101-backup-la-reporting/'

@description('The sasToken required to access _artifactsLocation.  When the template is deployed using the accompanying scripts, a sasToken will be automatically generated')
@secure()
param artifactsLocationSasToken string = ''

var nestedTemplates = {
  backup_jobs_non_log: uri(artifactsLocation, 'nestedtemplates/backup_jobs_non_log.json${artifactsLocationSasToken}')
  backup_jobs_log: uri(artifactsLocation, 'nestedtemplates/backup_jobs_log.json${artifactsLocationSasToken}')
  restore_jobs: uri(artifactsLocation, 'nestedtemplates/restore_jobs.json${artifactsLocationSasToken}')
  azure_alerts: uri(artifactsLocation, 'nestedtemplates/azure_alerts.json${artifactsLocationSasToken}')
  on_prem_alerts: uri(artifactsLocation, 'nestedtemplates/on_prem_alerts.json${artifactsLocationSasToken}')
  backup_items: uri(artifactsLocation, 'nestedtemplates/backup_items.json${artifactsLocationSasToken}')
  cloud_storage: uri(artifactsLocation, 'nestedtemplates/cloud_storage.json${artifactsLocationSasToken}')
}

module backup_jobs_non_log '?' /*TODO: replace with correct path to [variables('nestedTemplates').backup_jobs_non_log]*/ = {
  name: 'backup_jobs_non_log'
  scope: resourceGroup(resourceGroup().name)
  params: {
    location: location
    workspaceName: workspaceName
  }
}

module backup_jobs_log '?' /*TODO: replace with correct path to [variables('nestedTemplates').backup_jobs_log]*/ = {
  name: 'backup_jobs_log'
  scope: resourceGroup(resourceGroup().name)
  params: {
    location: location
    workspaceName: workspaceName
  }
}

module restore_jobs '?' /*TODO: replace with correct path to [variables('nestedTemplates').restore_jobs]*/ = {
  name: 'restore_jobs'
  scope: resourceGroup(resourceGroup().name)
  params: {
    location: location
    workspaceName: workspaceName
  }
}

module azure_alerts '?' /*TODO: replace with correct path to [variables('nestedTemplates').azure_alerts]*/ = {
  name: 'azure_alerts'
  scope: resourceGroup(resourceGroup().name)
  params: {
    location: location
    workspaceName: workspaceName
  }
}

module on_prem_alerts '?' /*TODO: replace with correct path to [variables('nestedTemplates').on_prem_alerts]*/ = {
  name: 'on_prem_alerts'
  scope: resourceGroup(resourceGroup().name)
  params: {
    location: location
    workspaceName: workspaceName
  }
}

module backup_items '?' /*TODO: replace with correct path to [variables('nestedTemplates').backup_items]*/ = {
  name: 'backup_items'
  scope: resourceGroup(resourceGroup().name)
  params: {
    location: location
    workspaceName: workspaceName
  }
}

module cloud_storage '?' /*TODO: replace with correct path to [variables('nestedTemplates').cloud_storage]*/ = {
  name: 'cloud_storage'
  scope: resourceGroup(resourceGroup().name)
  params: {
    location: location
    workspaceName: workspaceName
  }
}