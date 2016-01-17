resource 'poshorigin:poshfolder' 'folder01' @{
    defaults = '.\folder_defaults.psd1'
}

resource 'poshorigin:poshfile' 'file1.txt' @{
    defaults = '.\file_defaults.psd1'
    description = 'this is an example file'
}

resource 'poshorigin:poshfile' 'file2.txt' @{
    defaults = '.\file_defaults.psd1'
    description = 'this is another example file'
}
