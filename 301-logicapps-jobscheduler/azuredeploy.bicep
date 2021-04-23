@description('Location for all resources.')
param location string = resourceGroup().location

@minLength(1)
@description('The name of the logic app that creates timer jobs.')
param CreateTimerJobLogicAppName string = 'CreateTimerJob'

@minLength(1)
@description('The name of the logic app that runs timer jobs.')
param TimerJobLogicAppName string = 'TimerJob'

resource CreateTimerJobLogicAppName_resource 'Microsoft.Logic/workflows@2019-05-01' = {
  name: CreateTimerJobLogicAppName
  location: location
  tags: {
    displayName: 'LogicApp'
  }
  properties: {
    state: 'Enabled'
    definition: {
      '$schema': 'https://schema.management.azure.com/providers/Microsoft.Logic/schemas/2016-06-01/workflowdefinition.json#'
      contentVersion: '1.0.0.0'
      triggers: {
        manual: {
          correlation: {
            clientTrackingId: '@triggerBody()[\'timerjobid\']'
          }
          type: 'Request'
          kind: 'Http'
          inputs: {
            schema: {
              properties: {
                jobRecurrence: {
                  properties: {
                    count: {
                      minimum: -1
                      title: 'count (jobRecurrence)'
                      type: 'integer'
                    }
                    endTime: {
                      title: 'endTime (jobRecurrence)'
                      type: 'string'
                    }
                    frequency: {
                      enum: [
                        'second'
                        'minute'
                        'hour'
                        'day'
                        'week'
                        'month'
                      ]
                      title: 'frequency (jobRecurrence)'
                      type: 'string'
                    }
                    interval: {
                      title: 'interval (jobRecurrence)'
                      type: 'integer'
                    }
                  }
                  required: [
                    'frequency'
                    'interval'
                  ]
                  type: 'object'
                }
                jobStatus: {
                  properties: {
                    executionCount: {
                      title: 'executionCount (jobStatus)'
                      type: 'integer'
                    }
                    faultedCount: {
                      title: 'faultedCount (jobStatus)'
                      type: 'integer'
                    }
                    lastExecutionTime: {
                      title: 'lastExecutionTime (jobStatus)'
                      type: 'string'
                    }
                    nextExecutionTime: {
                      title: 'nextExecutionTime (jobStatus)'
                      type: 'string'
                    }
                  }
                  type: 'object'
                }
                startTime: {
                  type: 'string'
                }
                timerjobid: {
                  type: 'string'
                }
              }
              required: [
                'jobRecurrence'
                'timerjobid'
              ]
              type: 'object'
            }
          }
        }
      }
      actions: {
        If_not_past_endTime_or_exceeds_count: {
          actions: {
            Catch_TimerJob_error: {
              actions: {
                Terminate_failed_to_create_job: {
                  runAfter: {
                    Timer_job_failed_response: [
                      'Succeeded'
                    ]
                  }
                  type: 'Terminate'
                  inputs: {
                    runError: {
                      message: 'Failed to create timer job'
                    }
                    runStatus: 'Failed'
                  }
                }
                Timer_job_failed_response: {
                  type: 'Response'
                  kind: 'Http'
                  inputs: {
                    body: 'Failed to create timer job'
                    statusCode: 400
                  }
                }
              }
              runAfter: {
                TimerJob: [
                  'Failed'
                  'TimedOut'
                ]
              }
              type: 'Scope'
            }
            Created_Response: {
              runAfter: {
                TimerJob: [
                  'Succeeded'
                ]
              }
              type: 'Response'
              kind: 'Http'
              inputs: {
                body: 'Next execution time will be at @{variables(\'nextTime\')}'
                statusCode: 201
              }
            }
            TimerJob: {
              type: 'Workflow'
              inputs: {
                body: {
                  jobRecurrence: {
                    count: '@triggerBody()?[\'jobRecurrence\']?[\'count\']'
                    endTime: '@triggerBody()?[\'jobRecurrence\']?[\'endTime\']'
                    frequency: '@triggerBody()?[\'jobRecurrence\']?[\'frequency\']'
                    interval: '@triggerBody()?[\'jobRecurrence\']?[\'interval\']'
                  }
                  jobStatus: {
                    executionCount: '@triggerBody()?[\'jobStatus\']?[\'executionCount\']'
                    faultedCount: '@triggerBody()?[\'jobStatus\']?[\'faultedCount\']'
                    lastExecutionTime: '@triggerBody()?[\'jobStatus\']?[\'lastExecutionTime\']'
                    nextExecutionTime: '@variables(\'nextTime\')'
                  }
                  startTime: '@triggerBody()?[\'startTime\']'
                  timerjobid: '@triggerBody()[\'timerjobid\']'
                }
                host: {
                  triggerName: 'manual'
                  workflow: {
                    id: TimerJobLogicAppName_resource.id
                  }
                }
              }
            }
          }
          runAfter: {
            Initialize_nextTime: [
              'Succeeded'
            ]
          }
          else: {
            actions: {
              Cancelled: {
                runAfter: {
                  Exceeded_Criteria_Response: [
                    'Succeeded'
                  ]
                }
                type: 'Terminate'
                inputs: {
                  runStatus: 'Cancelled'
                }
              }
              Exceeded_Criteria_Response: {
                type: 'Response'
                kind: 'Http'
                inputs: {
                  body: 'Job completion criteria met.\nDetails: \nEither\nendTime(@{triggerBody()?[\'jobRecurrence\']?[\'endTime\']}) < Next execution time(@{variables(\'nextTime\')})\nOR\ncount(@{triggerBody()?[\'jobRecurrence\']?[\'count\']}) > execution count (@{triggerBody()?[\'jobStatus\']?[\'executionCount\']})'
                  statusCode: 409
                }
              }
            }
          }
          expression: {
            and: [
              {
                or: [
                  {
                    equals: [
                      '@coalesce(triggerBody()?[\'jobRecurrence\']?[\'endTime\'],-1)'
                      -1
                    ]
                  }
                  {
                    less: [
                      '@variables(\'nextTime\')'
                      '@{triggerBody()?[\'jobRecurrence\']?[\'endTime\']}'
                    ]
                  }
                ]
              }
              {
                or: [
                  {
                    equals: [
                      '@coalesce(triggerBody()?[\'jobRecurrence\']?[\'count\'],-1)'
                      -1
                    ]
                  }
                  {
                    greater: [
                      '@coalesce(triggerBody()?[\'jobRecurrence\']?[\'count\'],1)'
                      '@coalesce(triggerBody()?[\'jobStatus\']?[\'executionCount\'],0)'
                    ]
                  }
                ]
              }
            ]
          }
          type: 'If'
        }
        Initialize_nextTime: {
          runAfter: {
            Initialize_startTime: [
              'Succeeded'
            ]
          }
          type: 'InitializeVariable'
          inputs: {
            variables: [
              {
                name: 'nextTime'
                type: 'string'
                value: '@{addToTime(coalesce(triggerBody()?[\'jobStatus\']?[\'lastExecutionTime\'],variables(\'startTime\')),triggerBody()[\'jobRecurrence\'][\'interval\'],triggerBody()[\'jobRecurrence\'][\'frequency\'])}'
              }
            ]
          }
        }
        Initialize_startTime: {
          type: 'InitializeVariable'
          inputs: {
            variables: [
              {
                name: 'startTime'
                type: 'string'
                value: '@{if(less(coalesce(triggerBody()?[\'startTime\'],utcNow()),utcNow()),utcNow(),coalesce(triggerBody()?[\'startTime\'],utcNow()))}'
              }
            ]
          }
        }
      }
    }
  }
}

resource TimerJobLogicAppName_resource 'Microsoft.Logic/workflows@2019-05-01' = {
  name: TimerJobLogicAppName
  location: location
  tags: {
    displayName: 'LogicApp'
  }
  properties: {
    state: 'Enabled'
    definition: {
      '$schema': 'https://schema.management.azure.com/providers/Microsoft.Logic/schemas/2016-06-01/workflowdefinition.json#'
      contentVersion: '1.0.0.0'
      triggers: {
        manual: {
          correlation: {
            clientTrackingId: '@triggerBody()[\'timerjobid\']'
          }
          type: 'Request'
          kind: 'Http'
          inputs: {
            schema: {
              properties: {
                jobRecurrence: {
                  properties: {
                    count: {
                      minimum: -1
                      title: 'count (jobRecurrence)'
                      type: 'integer'
                    }
                    endTime: {
                      title: 'endTime (jobRecurrence)'
                      type: 'string'
                    }
                    frequency: {
                      enum: [
                        'second'
                        'minute'
                        'hour'
                        'day'
                        'week'
                        'month'
                      ]
                      title: 'frequency (jobRecurrence)'
                      type: 'string'
                    }
                    interval: {
                      title: 'interval (jobRecurrence)'
                      type: 'integer'
                    }
                  }
                  required: [
                    'frequency'
                    'interval'
                  ]
                  type: 'object'
                }
                jobStatus: {
                  properties: {
                    executionCount: {
                      title: 'executionCount (jobStatus)'
                      type: 'integer'
                    }
                    faultedCount: {
                      title: 'faultedCount (jobStatus)'
                      type: 'integer'
                    }
                    lastExecutionTime: {
                      title: 'lastExecutionTime (jobStatus)'
                      type: 'string'
                    }
                    nextExecutionTime: {
                      title: 'nextExecutionTime (jobStatus)'
                      type: 'string'
                    }
                  }
                  required: [
                    'nextExecutionTime'
                  ]
                  type: 'object'
                }
                startTime: {
                  type: 'string'
                }
                timerjobid: {
                  type: 'string'
                }
              }
              required: [
                'timerjobid'
                'jobRecurrence'
                'jobStatus'
              ]
              type: 'object'
            }
          }
        }
      }
    }
  }
}

module nestedTemplate './nested_nestedTemplate.bicep' = {
  name: 'nestedTemplate'
  params: {
    resourceId_Microsoft_Logic_workflows_parameters_CreateTimerJobLogicAppName: CreateTimerJobLogicAppName_resource.id
    TimerJobLogicAppName: TimerJobLogicAppName
    location: location
  }
}