resource 'example:folder' 'folder01' @{
    defaults = '.\folder_defaults.psd1'
}

resource 'example:file' 'file1.txt' @{
    defaults = '.\file_defaults.psd1'
    description = 'this is an example file'
}

resource 'example:file' 'file2.txt' @{
    defaults = '.\file_defaults.psd1'
    description = 'this is another example file'
}
