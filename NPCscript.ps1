.".\NpcCompletions.ps1"

# カレントディレクトリにあるテンプレートファイルとCSVファイルのパスを指定します
$currentDirectory = Get-Location
$auth_key_file_path = Join-Path $currentDirectory "auth_key.dat"

Add-Type -AssemblyName System.Windows.Forms

# ポップアップを表示する関数
function ShowPopup($message) {
    [System.Windows.Forms.MessageBox]::Show($message)
}

# ファイル読み込みダイアログを表示する関数
function OpenFileDialog($title, $filter) {
    $openFileDialog = New-Object System.Windows.Forms.OpenFileDialog
    $openFileDialog.Title = $title
    $openFileDialog.Filter = $filter

    $result = $openFileDialog.ShowDialog()
    if ($result -eq "OK") {
        return $openFileDialog.FileName
    } else {
        return $null
    }
}

# タスクメッセージを選択する
ShowPopup("Select the task message file")
Write-Host "Select the task message file"
$taskmessageFilePath = OpenFileDialog "Select task message file" "Text Files (*.task)|*.task|All Files (*.*)|*.*"
if ($null -eq $taskmessageFilePath) {
    Write-Host "No task message file selected. Exiting..."
    exit
}

# テンプレートファイルを選択する
ShowPopup("Select the template file")
Write-Host "Select the template file"
$templateFilePath = OpenFileDialog "Select the template file" "Text Files (*.txt)|*.txt|All Files (*.*)|*.*"
if ($null -eq $templateFilePath) {
    Write-Host "No template file selected. Exiting..."
    exit
}

# CSVファイルを選択する
ShowPopup("Select the CSV file")
Write-Host "Select the CSV file"
$csvFilePath = OpenFileDialog "Select the CSV file" "CSV Files (*.csv)|*.csv|All Files (*.*)|*.*"
if ($null -eq $csvFilePath) {
    Write-Host "No CSV file selected. Exiting..."
    exit
}

# Auth_keyを読み込む
$auth_key = Get-Content $auth_key_file_path -Raw

# タスクメッセージを読み込む
$task_message = Get-Content $taskmessageFilePath -Raw

# テンプレートファイルを読み込む
$templateContent = Get-Content $templateFilePath -Raw -Encoding UTF8

# CSVファイルを読み込む
$csvContent = Get-Content $csvFilePath

# タウン情報を取得する
$town_name = ($csvContent[0] -split "\t")[1]
$town_information = ($csvContent[0] -split "\t")[1] + ":" + ($csvContent[0] -split "\t")[2]

# Townnameディレクトリを作成する
$townnameDirectoryPath = Join-Path $currentDirectory $town_name
if (-not (Test-Path $townnameDirectoryPath)) {
    New-Item -ItemType Directory -Path $townnameDirectoryPath
}

# CSVファイルの2行目から各行を処理する
$csvContent | Select-Object -Skip 1 | ForEach-Object {
    $rowData = $_ -split "\t"

    # NpcCompletions関数を呼び出す
    Write-Host "Request GPT..."
    $npc_name = $rowData[1]
    $npc_information = $rowData[2]
    $responses = NpcCompletions -task_message $task_message -town_information $town_information -npc_name $npc_name -npc_information $npc_information -auth_key $auth_key

    # 置換処理
    $replacedContent = $templateContent
    for ($i = 0; $i -lt $responses.Count; $i++) {
        $responseWithEscapedNewlines = $responses[$i] -replace "`n", '\n'
        $responseWithEscapedNewlines = $responseWithEscapedNewlines -replace '\\n\\n', '\n'
        $replacedContent = $replacedContent -creplace [regex]::Escape("<<__SPEACH__[$($i)]>>"), $responseWithEscapedNewlines
    }

    Write-Host "Create script file..."
    # 置換後の内容を新しいファイルに保存する
    $outputFilePath = Join-Path $townnameDirectoryPath "$($rowData[0]).txt"
    Set-Content -Path $outputFilePath -Value $replacedContent -Encoding UTF8 -NoNewline
}

Write-Host "All processes have been completed."
pause