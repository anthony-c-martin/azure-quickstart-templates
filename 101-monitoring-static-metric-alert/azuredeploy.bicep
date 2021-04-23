@minLength(1)
@description('Name of the alert')
param alertName string

@description('Description of alert')
param alertDescription string = 'This is a metric alert'

@allowed([
  0
  1
  2
  3
  4
])
@description('Severity of alert {0,1,2,3,4}')
param alertSeverity int = 3

@description('Specifies whether the alert is enabled')
param isEnabled bool = true

@minLength(1)
@description('Full Resource ID of the resource emitting the metric that will be used for the comparison. For example /subscriptions/00000000-0000-0000-0000-0000-00000000/resourceGroups/ResourceGroupName/providers/Microsoft.compute/virtualMachines/VM_xyz')
param resourceId string

@minLength(1)
@description('Name of the metric used in the comparison to activate the alert.')
param metricName string = 'Percentage CPU'

@allowed([
  'Equals'
  'NotEquals'
  'GreaterThan'
  'GreaterThanOrEqual'
  'LessThan'
  'LessThanOrEqual'
])
@description('Operator comparing the current value with the threshold value.')
param operator string = 'GreaterThan'

@description('The threshold value at which the alert is activated.')
param threshold string = '0'

@allowed([
  'Average'
  'Minimum'
  'Maximum'
  'Total'
  'Count'
])
@description('How the data that is collected should be combined over time.')
param timeAggregation string = 'Average'

@allowed([
  'PT1M'
  'PT5M'
  'PT15M'
  'PT30M'
  'PT1H'
  'PT6H'
  'PT12H'
  'PT24H'
])
@description('Period of time used to monitor alert activity based on the threshold. Must be between one minute and one day. ISO 8601 duration format.')
param windowSize string = 'PT5M'

@allowed([
  'PT1M'
  'PT5M'
  'PT15M'
  'PT30M'
  'PT1H'
])
@description('how often the metric alert is evaluated represented in ISO 8601 duration format')
param evaluationFrequency string = 'PT1M'

resource alertName_resource 'Microsoft.Insights/metricAlerts@2018-03-01' = {
  name: alertName
  location: 'global'
  properties: {
    description: alertDescription
    severity: alertSeverity
    enabled: isEnabled
    scopes: [
      resourceId
    ]
    evaluationFrequency: evaluationFrequency
    windowSize: windowSize
    criteria: {
      'odata.type': 'Microsoft.Azure.Monitor.SingleResourceMultipleMetricCriteria'
      allOf: [
        {
          name: '1st criterion'
          metricName: metricName
          operator: operator
          threshold: threshold
          timeAggregation: timeAggregation
        }
      ]
    }
  }
}