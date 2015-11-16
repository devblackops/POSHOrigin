function _MakeObject { 
     param ( 
         [Parameter(  
             Position = 0,   
             Mandatory = $true,   
             ValueFromPipeline = $true,  
             ValueFromPipelineByPropertyName = $true  
         )] [object[]]$hashtable 
     )
     
     begin { $i = 0 } 
     
     process { 
         foreach ($myHashtable in $hashtable) { 
             if ($myHashtable.GetType().Name -eq 'hashtable') { 
                 $output = New-Object -TypeName PsObject
                 Add-Member -InputObject $output -MemberType ScriptMethod -Name AddNote -Value {  
                     Add-Member -InputObject $this -MemberType NoteProperty -Name $args[0] -Value $args[1]
                 } 
                 $myHashtable.Keys | Sort-Object | ForEach-Object {  
                     $output.AddNote($_, $myHashtable.$_) 
                 } 
                 $output
             } else { 
                 Write-Warning -Message "Index $i is not of type [hashtable]"
             } 
             $i += 1
         } 
     } 
} 