param workspaceName string {
  metadata: {
    description: 'Specify the name of the OMS workspace'
  }
}
param workspaceRegion string {
  metadata: {
    description: 'Specify the region of the OMS workspace'
  }
}
param pricingTier string {
  metadata: {
    description: 'Specify the pricing tier'
  }
  default: 'Free'
}
param automationName string {
  metadata: {
    description: 'Specify the name of the Azure Automation account'
  }
}
param automationRegion string {
  metadata: {
    description: 'Specify the region of the Azure Automation account'
  }
}
param vmmServers string {
  metadata: {
    description: 'Specify the comma seperated list of the on-prem VMM server(s)'
  }
}

var omsSolutions = {
  customSolution: {
    name: 'VMM Analytics'
    solutionName: 'VMMAnalytics[${workspaceName}]'
    publisher: 'veharshv@microsoft.com'
    displayName: 'VMM Analytics'
    description: 'Monitor and analyze your VMM jobs'
    author: 'veharshv@microsoft.com'
  }
}
var omsWorkspaceId = 'workspaceId'
var omsWorkspaceKey = 'workspaceKey'
var vmmServersVariable = 'vmmServers'
var lastRunTimeVariable = 'lastRunTime'
var runbooks = {
  vmmAnalytics: {
    name: 'vmmanalytics'
    version: '1.0.0.0'
    description: 'Runbook to automatically ingest VMM Job data and events into OMS Log Analytics'
    type: 'PowerShell'
    Id: ''
    uri: 'https://raw.githubusercontent.com/krnese/AzureDeploy/master/OMS/MSOMS/Solutions/vmm/scripts/vmmanalytics.ps1'
  }
}

resource workspaceName_res 'Microsoft.OperationalInsights/workspaces@2015-11-01-preview' = {
  name: workspaceName
  location: workspaceRegion
  properties: {
    sku: {
      name: pricingTier
    }
  }
}

resource workspaceName_omsSolutions_customSolution_name 'Microsoft.OperationalInsights/workspaces/views@2015-11-01-preview' = {
  name: '${workspaceName}/${omsSolutions.customSolution.name}'
  location: workspaceRegion
  properties: {
    Name: omsSolutions.customSolution.name
    DisplayName: omsSolutions.customSolution.displayName
    Description: omsSolutions.customSolution.description
    Author: omsSolutions.customSolution.author
    Source: 'Local'
    Dashboard: [
      {
        Id: 'SingleQueryDonutBuilderBladeV1'
        Type: 'Blade'
        Version: 0
        Configuration: {
          General: {
            title: 'Error Distribution by VMM Server'
            newGroup: false
            icon: ''
            useIcon: false
          }
          Header: {
            Title: 'Errors'
            Subtitle: ''
          }
          Donut: {
            Query: 'Type=VMMjobs_CL ErrorInfo_s!="Success (0)" | measure count() by VMMServer_s'
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
            Query: 'Type=VMMjobs_CL ErrorInfo_s!="Success (0)" |measure count() by VMMServer_s'
            HideGraph: false
            enableSparklines: true
            operation: 'Summary'
            ColumnsTitle: {
              Name: 'VMM Server'
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
            NavigationQuery: 'Type=VMMjobs_CL ErrorInfo_s!= "Success (0)" {selected item}'
          }
        }
      }
      {
        Id: 'LineChartCalloutBuilderBlade'
        Type: 'Blade'
        Version: 0
        Configuration: {
          General: {
            title: 'Errors over time'
            newGroup: false
            icon: ''
            useIcon: false
          }
          Header: {
            Title: 'Errors over time'
            Subtitle: ''
          }
          LineChart: {
            Query: 'Type=VMMjobs_CL ErrorInfo_s!= "Success (0)"  | measure count() by ErrorInfo_s| display linechart '
            Callout: {
              Title: 'Avg per 30'
              Series: ''
              Operation: 'Average'
            }
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
            Query: 'Type=VMMjobs_CL ErrorInfo_s!= "Success (0)"  | measure count() by ErrorInfo_s'
            HideGraph: false
            enableSparklines: false
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
        Id: 'LineChartBuilderBlade'
        Type: 'Blade'
        Version: 0
        Configuration: {
          General: {
            title: 'Data type distribution'
            newGroup: false
            icon: ''
            useIcon: false
          }
          Header: {
            Title: 'Data types over time'
            Subtitle: ''
          }
          LineChart: {
            Query: 'Type=VMMjobs_CL ErrorInfo_s!= "Success (0)" |measure count() by TimeGenerated, ErrorInfo_s, VMMServer_s interval 15minutes | display linechart'
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
            Query: 'Type=VMMjobs_CL ErrorInfo_s!= "Success (0)" |measure count() by TimeGenerated, ErrorInfo_s, VMMServer_s interval 15minutes | display linechart'
            HideGraph: false
            enableSparklines: false
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
            NavigationQuery: 'Type=VMMjobs_CL ErrorInfo_s!= "Success (0)" {selected item}'
          }
        }
      }
      {
        Id: 'SingleQueryDonutBuilderBladeV1'
        Type: 'Blade'
        Version: 0
        Configuration: {
          General: {
            title: 'VMM Failed Jobs'
            newGroup: false
            icon: ''
            useIcon: false
          }
          Header: {
            Title: 'Failed Jobs'
            Subtitle: ''
          }
          Donut: {
            Query: 'Type=VMMjobs_CL ErrorInfo_s!= "Success (0)" | measure count() by JobName_s'
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
            Query: 'Type=VMMjobs_CL ErrorInfo_s!= "Success (0)" | measure count() by JobName_s'
            HideGraph: false
            enableSparklines: false
            operation: 'Summary'
            ColumnsTitle: {
              Name: 'Jobs'
              Value: 'Failed'
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
            NavigationQuery: 'Type=VMMjobs_CL ErrorInfo_s!= "Success (0)" {selected item}'
          }
        }
      }
      {
        Id: 'SingleQueryDonutBuilderBladeV1'
        Type: 'Blade'
        Version: 0
        Configuration: {
          General: {
            title: 'Distribution by Errors'
            newGroup: false
            icon: ''
            useIcon: false
          }
          Header: {
            Title: 'Total Errors'
            Subtitle: ''
          }
          Donut: {
            Query: 'Type=VMMjobs_CL ErrorInfo_s!= "Success (0)" | measure count() by ErrorInfo_s'
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
            Query: 'Type=VMMjobs_CL ErrorInfo_s!= "Success (0)" | measure count() by ErrorInfo_s'
            HideGraph: false
            enableSparklines: true
            operation: 'Summary'
            ColumnsTitle: {
              Name: 'Errors'
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
            NavigationQuery: 'Type=VMMjobs_CL {selected item}'
          }
        }
      }
      {
        Id: 'SingleQueryDonutBuilderBladeV1'
        Type: 'Blade'
        Version: 0
        Configuration: {
          General: {
            title: 'VMM Insights - Jobs'
            newGroup: false
            icon: ''
            useIcon: false
          }
          Header: {
            Title: 'Total Jobs'
            Subtitle: ''
          }
          Donut: {
            Query: 'Type:VMMjobs_CL | measure Count() by JobName_s'
            CenterLegend: {
              Text: 'Jobs'
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
            Query: 'Type=VMMjobs_CL | measure Count() by JobName_s'
            HideGraph: false
            enableSparklines: false
            operation: 'Summary'
            ColumnsTitle: {
              Name: 'Jobs'
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
        Id: 'NotableQueriesBuilderBlade'
        Type: 'Blade'
        Version: 0
        Configuration: {
          General: {
            title: 'List of queries'
            newGroup: false
            preselectedFilters: 'Type, Computer'
            renderMode: 'default'
          }
          queries: [
            {
              query: 'Type=VMMjobs_CL | measure count(), percentile25(Duration_d) as Perc25, percentile50(Duration_d) as Perc50,  percentile75(Duration_d) as Perc75, percentile90(Duration_d) as Perc90 by JobName_s'
              displayName: 'Performance analysis (All runs)'
            }
            {
              query: 'Type=VMMjobs_CL AND ErrorInfo_s= "Success (0)" | measure count(), percentile25(Duration_d) as Perc25, percentile50(Duration_d) as Perc50,  percentile75(Duration_d) as Perc75, percentile90(Duration_d) as Perc90 by JobName_s'
              displayName: 'Performance analysis (Successful runs)'
            }
            {
              query: 'Type=VMMjobs_CL | measure count() by VMMServer_s, JobName_s, Status_s | sort VMMServer_s, JobName_s, Status_s'
              displayName: 'Job failure analysis for each job type and host'
            }
          ]
        }
      }
    ]
    OverviewTile: {
      Id: 'SingleQueryDonutBuilderTileV1'
      Type: 'OverviewTile'
      Version: 0
      Configuration: {
        Donut: {
          Query: 'Type=VMMjobs_CL  | measure count() by Type'
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
    workspaceResourceId: workspaceName_res.id
    referencedResources: []
    containedResources: [
      workspaceName_omsSolutions_customSolution_name.id
    ]
  }
}

resource automationName_res 'Microsoft.Automation/automationAccounts@2015-10-31' = {
  name: automationName
  location: automationRegion
  properties: {
    sku: {
      name: 'Basic'
    }
  }
}

resource automationName_omsWorkspaceId 'Microsoft.Automation/automationAccounts/variables@2015-10-31' = {
  name: '${automationName}/${omsWorkspaceId}'
  location: automationRegion
  properties: {
    description: 'OMS Workspace Id'
    value: '"${reference(workspaceName_res.id, '2015-11-01-preview').customerId}"'
  }
}

resource automationName_lastRunTimeVariable 'Microsoft.Automation/automationAccounts/variables@2015-10-31' = {
  name: '${automationName}/${lastRunTimeVariable}'
  location: automationRegion
  properties: {
    description: 'LastRunTime variable'
    value: ''
  }
}

resource automationName_vmmServersVariable 'Microsoft.Automation/automationAccounts/variables@2015-10-31' = {
  name: '${automationName}/${vmmServersVariable}'
  location: automationRegion
  properties: {
    description: 'VMMServers'
    value: '"${vmmServers}"'
  }
}

resource automationName_omsWorkspaceKey 'Microsoft.Automation/automationAccounts/variables@2015-10-31' = {
  name: '${automationName}/${omsWorkspaceKey}'
  location: automationRegion
  properties: {
    description: 'OMS Workspace key'
    value: '"${listKeys(workspaceName_res.id, '2015-11-01-preview').primarySharedKey}"'
  }
}

resource automationName_runbooks_vmmAnalytics_name 'Microsoft.Automation/automationAccounts/runbooks@2015-10-31' = {
  name: '${automationName}/${runbooks.vmmAnalytics.name}'
  location: automationRegion
  tags: {}
  properties: {
    runbookType: runbooks.vmmAnalytics.type
    logProgress: false
    logVerbose: false
    description: runbooks.vmmAnalytics.description
    publishContentLink: {
      uri: runbooks.vmmAnalytics.uri
      version: runbooks.vmmAnalytics.version
    }
  }
}