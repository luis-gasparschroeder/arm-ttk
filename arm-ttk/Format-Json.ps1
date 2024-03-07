Function Format-Json {
    <#
    .SYNOPSIS
        Takes results from ARMTTK and exports them as a JSON blob, grouped by file path.

    .DESCRIPTION
        Takes results from ARMTTK and exports them as JSON. The test cases include the filename, name of the test,
        whether the test was successful, and help text for how to resolve the error if the test failed. Test results are 
        grouped by their respective file paths.

    #>
    [CmdletBinding()]
    Param (
        # Object containing a single test result or an array of test results
        [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
        [psobject]$TestResult
    )

    Begin {
        # Initialize the hashtable to collect processed test cases grouped by file paths
        $TestCasesGrouped = @{}
    }

    Process {
        # Process each TestResult item one by one as they come from the pipeline
        $TestCase = @{
            filepath = $TestResult.file.fullpath
            name = $TestResult.name
            success = $TestResult.Passed
        }

        if ($TestResult.Passed) {
            $TestCase.optional = $false
        }
        elseif ($null -ne $TestResult.Warnings) {
            $TestCase.optional = $true
            $TestCase.message = "$($TestResult.Warnings.Message.Replace('"', '\"')) in template file $($TestResult.file.name)"
        }
        elseif ($null -ne $TestResult.Errors) {
            $TestCase.optional = $false
            $TestCase.message = "$($TestResult.Errors.Exception.Message.Replace('"', '\"')) in template file $($TestResult.file.name)"
        }
        else {
            $TestCase.optional = $true
            $TestCase.message = "Unknown error in template file " + $TestResult.file.name
        }

        # Check if the filepath key exists in the hashtable, if not create an array for it
        if (-not $TestCasesGrouped.ContainsKey($TestCase.filepath)) {
            $TestCasesGrouped[$TestCase.filepath] = @()
        }

        # Add the test case to the array for this filepath
        $TestCasesGrouped[$TestCase.filepath] += $TestCase
    }

    End {
        # Iterate over each group in the hashtable and convert each group to JSON
        $JSON = $TestCasesGrouped.GetEnumerator() | ForEach-Object {
            @{ 
                filepath = $_.Key
                tests = $_.Value
            }
        } | ConvertTo-Json -Depth 5

        # Print the JSON string to the console
        Write-Output $JSON
    }
}
