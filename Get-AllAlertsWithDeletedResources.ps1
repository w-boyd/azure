function Get-AllAlertsWithDeletedResources {
    [CmdletBinding()]
    param(
    )
    Begin {
        [array]$allSubscriptions = Get-AzSubscription -WarningAction SilentlyContinue -Verbose
    }
    Process {
        foreach ($item in $allSubscriptions) {
            Select-AzSubscription $item -WarningAction SilentlyContinue -Verbose | Set-AzContext -Verbose | Out-Null
            $rules = Get-AzMetricAlertRuleV2 -WarningAction SilentlyContinue -Verbose
            if ($rules) {
                [array]$allRules += @{
                    Name  = $item.Name
                    Id    = $item.Id
                    Rules = $rules
                }
            }
        }
        foreach ($item in $allRules) {
            Select-AzSubscription $item.Id -WarningAction SilentlyContinue -Verbose | Set-AzContext -Verbose | Out-Null
            foreach ($rule in $item.Rules) {
                $deletedScopes = @()
                $scopeCount = ($rule.Scopes).Count
                Write-Verbose "Number of scopes:'$scopeCount' Rule Id: $($rule.Id)"
                foreach ($scope in $rule.Scopes) {
                    $testResource = Get-AzResource -ResourceId $scope -Verbose -WarningAction SilentlyContinue
                    if ($null -eq $testResource) {
                        [array]$deletedScopes += $scope
                    }
                }
                if ($deletedScopes) {
                    [array]$rulesToRemove += @{
                        Id = $rule.Id
                        DeletedScopes = $deletedScopes
                    }
                }
            }
        }
    }
    End {
        return $rulesToRemove
    }
}

 

$rulesWithDeletedResources = Get-AllAlertsWithDeletedResources -Verbose