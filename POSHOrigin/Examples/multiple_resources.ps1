resource 'poshorigin:poshfolder' 'folder01' @{
    description = 'this is an exmaple folder'
    ensure = 'present'
    path = 'c:\'
}

resource 'poshorigin:poshfile' 'file1' @{
    name = 'file1.txt'
    description = 'this is an example file'
    ensure = 'present'
    path = 'c:\folder01'
    contents = 'this is some content'
    dependson = '[poshfolder]folder01'
}

resource 'poshorigin:poshfile' 'file2' @{
    name = 'file2.txt'
    description = 'this is another example file'
    ensure = 'present'
    path = 'c:\folder01'
    contents = 'this is some more content'
    dependson = '[poshfolder]folder01'
}
