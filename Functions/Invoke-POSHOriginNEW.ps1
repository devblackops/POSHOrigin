function Invoke-POSHOriginNEW {
    [cmdletbinding()]
    param(
        [parameter(Mandatory,ValueFromPipeline)]
        [psobject[]]$Resource,

        [switch]$WhatIf
    )

    begin {
        function Write-ResourceStatus {
            param (
                [string]$Resource,
                [string]$Name,
                [ValidateSet('Test', 'Get', 'Set')]
                [string]$State
            )
            $cmd = {
                switch ($State) {
                    'Test' {
                        Write-Host -Object "Testing resource "  -ForegroundColor Cyan -NoNewLine
                    }
                    'Get' {
                        Write-Host -Object "Getting resource "  -ForegroundColor Cyan -NoNewLine
                    }
                    'Set' {
                        Write-Host -Object "Setting resource "  -ForegroundColor Cyan -NoNewLine
                    }
                }
                Write-Host -Object "[$Resource" -ForegroundColor Magenta -NoNewLine
                Write-Host -Object "[$Name]" -ForegroundColor Green -NoNewLine
                Write-Host -Object "]" -ForegroundColor Magenta
            }

            Invoke-Command -ScriptBlock $cmd
        }
    }

    process {
        $results = @()

        foreach ($item in $Resource) {

            # Derive the resource type and module from the resource properties
            $module = $item.Resource.Split(':')[0]
            $resource = $item.Resource.Split(':')[1]

            # Try to find the DSC resource
            $dscResource = Get-DscResource -Name $resource -Module $module -ErrorAction SilentlyContinue
            if (-Not $dscResource) {
                $dscResource = Get-DscResource -Name $resource -Module "POSHOrigin_$module" -ErrorAction SilentlyContinue
            }

            if ($dscResource) {

                # Construct resource parameters
                if ($null -eq $item.Options.Ensure) {
                    $item.Options | Add-Member -Type NoteProperty -Name 'Ensure' -Value 'Present'
                }
                $invokePath = Join-Path -Path $dscResource.ParentPath -ChildPath 'Invoke.ps1'
                $hash = (& $invokePath -Options $item)
                $params = @{
                    Name = $dscResource.Name
                    ModuleName = $dscResource.ModuleName
                    Property = $hash
                }

                Write-Host ($params.Property | Format-List * | Out-String)

                Write-Host ($Params | Format-List * | Out-String)

                if ($PSBoundParameters.ContainsKey('WhatIf')) {
                    # Just test the resource
                    Write-ResourceStatus -Resource $dscResource.Name -Name $hash.Name -State Test
                    $testResult = Invoke-DscResource -Method Test @params -Verbose:$VerbosePreference
                    $result = "" | Select Resource, InDesiredState
                    Write-ResourceStatus -Resource $dscResource.Name -Name $hash.Name -State Get
                    $result.Resource = Invoke-DscResource -Method Get @params -Verbose:$VerbosePreference
                    $result.InDesiredState = $testResult.InDesiredState
                    $results += $result
                } else {
                    # Invoke the resource
                    Write-ResourceStatus -Resource $dscResource.Name -Name $hash.Name -State Test
                    $pass = Invoke-DscResource -Method Test @params -Verbose:$VerbosePreference
                    if (-Not $pass) {
                        Write-ResourceStatus -Resource $dscResource.Name -Name $hash.Name -State Set
                        Invoke-DscResource -Method Set @params -Verbose:$VerbosePreference
                    }
                    Write-ResourceStatus -Resource $dscResource.Name -Name $hash.Name -State Get
                    $setResult = Invoke-DscResource -Method Get @params -Verbose:$VerbosePreference
                    $results += $setResult
                }
            } else {
                Write-Error -Message "Unable to find DSC resource: $($item.Resource)"
            }
        }
        $results
    }
}
