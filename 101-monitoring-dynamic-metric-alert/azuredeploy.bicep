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
  'GreaterThan'
  'LessThan'
  'GreaterOrLessThan'
])
@description('Operator comparing the current value with the threshold value.')
param operator string = 'GreaterOrLessThan'

@allowed([
  'High'
  'Medium'
  'Low'
])
@description('Tunes how \'noisy\' the Dynamic Thresholds alerts will be: \'High\' will result in more alerts while \'Low\' will result in fewer alerts.')
param alertSensitivity string = 'Medium'

@description('The number of periods to check in the alert evaluation.')
param numberOfEvaluationPeriods string = '4'

@description('The number of unhealthy periods to alert on (must be lower or equal to numberOfEvaluationPeriods).')
param minFailingPeriodsToAlert string = '3'

@description('Use this option to set the date from which to start learning the metric historical data and calculate the dynamic thresholds (in ISO8601 format, e.g. \'2019-12-31T22:00:00Z\').')
param ignoreDataBefore string = ''

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
  'PT5M'
  'PT15M'
  'PT30M'
  'PT1H'
])
@description('Period of time used to monitor alert activity based on the threshold. Must be between five minutes and one hour. ISO 8601 duration format.')
param windowSize string = 'PT5M'

@allowed([
  'PT5M'
  'PT15M'
  'PT30M'
  'PT1H'
])
@description('how often the metric alert is evaluated represented in ISO 8601 duration format')
param evaluationFrequency string = 'PT5M'

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
      'odata.type': 'Microsoft.Azure.Monitor.MultipleResourceMultipleMetricCriteria'
      allOf: [
        {
          criterionType: 'DynamicThresholdCriterion'
          name: '1st criterion'
          metricName: metricName
          operator: operator
          alertSensitivity: alertSensitivity
          failingPeriods: {
            numberOfEvaluationPeriods: numberOfEvaluationPeriods
            minFailingPeriodsToAlert: minFailingPeriodsToAlert
          }
          ignoreDataBefore: ignoreDataBefore
          timeAggregation: timeAggregation
        }
      ]
    }
  }
}