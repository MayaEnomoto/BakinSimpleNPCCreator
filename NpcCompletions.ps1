function NpcCompletions {
    Param(
        [String]$task_message = "",
        [String]$town_information = "",
        [String]$npc_name = "",
        [String]$npc_information = "",
        [String]$language = "",
        [String]$auth_key = "",
        [String]$model = "gpt-3.5-turbo",
        [float]$temperature = 0.5,
        [Int]$contentnum = 3
    )

    $Token = $auth_key
    $Uri = 'https://api.openai.com/v1/chat/completions'
    $PostBody = @{
        model = $model
        temperature = $temperature
        n = $contentnum
    }

    $PostBody.messages = @(
        @{
            role = 'user'
            content = $task_message
        },
        @{
            role = 'user'
            content = "Current location : " + $town_information
        },
        @{
            role = 'user'
            content = "Role : " + $npc_name
        },
        @{
            role = 'user'
            content = "Specific description of NPC : " + $npc_information
        },
        @{
            role = 'user'
            content = "Hellow." + $npc_information
        }
    )

    $headers = @{Authorization = "Bearer $($Token)"}
    $Response = Invoke-WebRequest `
        -Method Post `
        -Uri $Uri `
        -ContentType 'application/json' `
        -Headers $headers `
        -UseBasicParsing `
        -Body ([System.Text.Encoding]::UTF8.GetBytes(($PostBody | ConvertTo-Json -Compress)))

    $Content = [System.Text.Encoding]::UTF8.GetString([System.Text.Encoding]::GetEncoding('ISO-8859-1').GetBytes($Response.Content))
    $Answers = ($Content | ConvertFrom-Json).choices.message.content

    $Answers
}
