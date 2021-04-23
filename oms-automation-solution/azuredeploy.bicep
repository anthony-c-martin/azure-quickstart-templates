@description('Specify the workspace region')
param workspaceRegion string = ''

@description('Specify the workspace name')
param workspaceName string = ''

@allowed([
  'free'
  'pernode'
  'standard'
])
@description('Select the SKU for your workspace')
param workspaceSku string = 'standard'

var omsSolutions = {
  customSolution: {
    name: 'AzureAutomationJobMonitoring'
    solutionName: 'AzureAutomationJobMonitoring[${workspaceName}]'
    publisher: 'cameron.fuller@catapultsystems.com'
    displayName: 'Azure Automation Job Monitoring'
    description: 'Monitor automation runbook jobs'
    author: 'cameron.fuller@catapultsystems.com'
  }
}

resource workspaceName_resource 'Microsoft.OperationalInsights/workspaces@2015-11-01-preview' = {
  name: workspaceName
  location: workspaceRegion
  properties: {
    sku: {
      name: workspaceSku
    }
  }
}

resource workspaceName_omsSolutions_customSolution_name 'Microsoft.OperationalInsights/workspaces/views@2015-11-01-preview' = {
  parent: workspaceName_resource
  name: '${omsSolutions.customSolution.name}'
  location: workspaceRegion
  properties: {
    Id: 'Azure Automation Job Monitoring'
    Name: 'Azure Automation Job Monitoring'
    Author: 'cameron.fuller@catapultsystems.com'
    Source: 'Local'
    Dashboard: [
      {
        Id: 'SingleQueryDonutBuilderBladeV1'
        Type: 'Blade'
        Version: 0
        Configuration: {
          General: {
            title: 'Recent Azure Automation Jobs'
            newGroup: false
            icon: ''
            useIcon: false
          }
          Header: {
            Title: 'Jobs run'
            Subtitle: ''
          }
          Donut: {
            Query: 'Category=JobLogs  | measure count() by RunbookName_s'
            CenterLegend: {
              Text: 'Total'
              Operation: 'Sum'
              ArcsToSelect: []
            }
            Options: {
              colors: [
                '#00188f'
                '#0072c6'
                '#00bcf2'
              ]
              valueColorMapping: []
            }
          }
          List: {
            Query: 'Category=JobLogs  | measure count() by RunbookName_s'
            HideGraph: false
            enableSparklines: true
            operation: 'Summary'
            ColumnsTitle: {
              Name: 'Name'
              Value: 'Count'
            }
            Color: '#0072c6'
            thresholds: {
              isEnabled: false
              values: [
                {
                  name: 'Normal'
                  threshold: 'Default'
                  color: '#009e49'
                  isDefault: true
                }
                {
                  name: 'Warning'
                  threshold: '60'
                  color: '#fcd116'
                  isDefault: false
                }
                {
                  name: 'Error'
                  threshold: '90'
                  color: '#ba141a'
                  isDefault: false
                }
              ]
            }
            NameDSVSeparator: ''
            NavigationQuery: '{selected item}'
          }
        }
      }
      {
        Id: 'LineChartBuilderBlade'
        Type: 'Blade'
        Version: 0
        Configuration: {
          General: {
            title: 'Recent Azure Automation Jobs'
            newGroup: false
            icon: ''
            useIcon: false
          }
          Header: {
            Title: 'Jobs run'
            Subtitle: ''
          }
          LineChart: {
            Query: 'Category=JobLogs NOT(ResultType="started") | measure Count() by RunbookName_s | display linechart'
            yAxis: {
              isLogarithmic: false
              units: {
                baseUnitType: ''
                baseUnit: ''
                displayUnit: ''
              }
              customLabel: ''
            }
          }
          List: {
            Query: 'Category=JobLogs NOT(ResultType="started") | measure Count() by RunbookName_s'
            HideGraph: false
            enableSparklines: true
            operation: 'Summary'
            ColumnsTitle: {
              Name: 'Type'
              Value: 'Count'
            }
            Color: '#0072c6'
            thresholds: {
              isEnabled: false
              values: [
                {
                  name: 'Normal'
                  threshold: 'Default'
                  color: '#009e49'
                  isDefault: true
                }
                {
                  name: 'Warning'
                  threshold: '60'
                  color: '#fcd116'
                  isDefault: false
                }
                {
                  name: 'Error'
                  threshold: '90'
                  color: '#ba141a'
                  isDefault: false
                }
              ]
            }
            NameDSVSeparator: ''
            NavigationQuery: '{selected item}'
          }
        }
      }
      {
        Id: 'SingleQueryDonutBuilderBladeV1'
        Type: 'Blade'
        Version: 0
        Configuration: {
          General: {
            title: 'Recent Azure Automation Job'
            newGroup: false
            icon: ''
            useIcon: false
          }
          Header: {
            Title: 'Result'
            Subtitle: ''
          }
          Donut: {
            Query: 'Category=JobLogs  | measure count() by ResultType'
            CenterLegend: {
              Text: 'Total'
              Operation: 'Sum'
              ArcsToSelect: []
            }
            Options: {
              colors: [
                '#00188f'
                '#0072c6'
                '#00bcf2'
              ]
              valueColorMapping: []
            }
          }
          List: {
            Query: 'Category=JobLogs  | measure count() by ResultType'
            HideGraph: false
            enableSparklines: false
            operation: 'Summary'
            ColumnsTitle: {
              Name: 'Results'
              Value: 'Count'
            }
            Color: '#0072c6'
            thresholds: {
              isEnabled: false
              values: [
                {
                  name: 'Normal'
                  threshold: 'Default'
                  color: '#009e49'
                  isDefault: true
                }
                {
                  name: 'Warning'
                  threshold: '60'
                  color: '#fcd116'
                  isDefault: false
                }
                {
                  name: 'Error'
                  threshold: '90'
                  color: '#ba141a'
                  isDefault: false
                }
              ]
            }
            NameDSVSeparator: ''
            NavigationQuery: '{selected item}'
          }
        }
      }
      {
        Id: 'SingleQueryDonutBuilderBladeV1'
        Type: 'Blade'
        Version: 0
        Configuration: {
          General: {
            title: 'Recent Azure Automation Job Streams'
            newGroup: false
            icon: ''
            useIcon: false
          }
          Header: {
            Title: 'Job Streams'
            Subtitle: ''
          }
          Donut: {
            Query: 'Category=JobStreams | measure count() by RunbookName_s'
            CenterLegend: {
              Text: 'Total'
              Operation: 'Sum'
              ArcsToSelect: []
            }
            Options: {
              colors: [
                '#00188f'
                '#0072c6'
                '#00bcf2'
              ]
              valueColorMapping: []
            }
          }
          List: {
            Query: 'Category=JobStreams | measure count() by RunbookName_s'
            HideGraph: false
            enableSparklines: false
            operation: 'Summary'
            ColumnsTitle: {
              Name: 'Computer'
              Value: 'Count'
            }
            Color: '#0072c6'
            thresholds: {
              isEnabled: false
              values: [
                {
                  name: 'Normal'
                  threshold: 'Default'
                  color: '#009e49'
                  isDefault: true
                }
                {
                  name: 'Warning'
                  threshold: '60'
                  color: '#fcd116'
                  isDefault: false
                }
                {
                  name: 'Error'
                  threshold: '90'
                  color: '#ba141a'
                  isDefault: false
                }
              ]
            }
            NameDSVSeparator: ''
            NavigationQuery: '{selected item}'
          }
        }
      }
    ]
    OverviewTile: {
      Id: 'SingleQueryDonutBuilderTileV1'
      Type: 'OverviewTile'
      Version: 0
      Configuration: {
        Donut: {
          Query: 'Category=JobLogs  | measure count() by RunbookName_s'
          CenterLegend: {
            Text: 'Total'
            Operation: 'Sum'
            ArcsToSelect: []
          }
          Options: {
            colors: [
              '#00188f'
              '#0072c6'
              '#00bcf2'
            ]
            valueColorMapping: []
          }
        }
        Advanced: {
          DataFlowVerification: {
            Enabled: false
            Query: '*'
            Message: ''
          }
        }
      }
    }
  }
}

resource omsSolutions_customSolution_solutionName 'Microsoft.OperationsManagement/solutions@2015-11-01-preview' = {
  name: omsSolutions.customSolution.solutionName
  location: workspaceRegion
  plan: {
    name: omsSolutions.customSolution.solutionName
    product: omsSolutions.customSolution.name
    publisher: omsSolutions.customSolution.publisher
    promotionCode: ''
  }
  properties: {
    workspaceResourceId: workspaceName_resource.id
    referencedResources: []
    containedResources: [
      workspaceName_omsSolutions_customSolution_name.id
    ]
  }
}