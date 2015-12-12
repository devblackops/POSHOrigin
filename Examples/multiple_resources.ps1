resource 'example:file' 'file1.txt' @{
    description = 'this is an example file'
    ensure = 'present'
    path = 'c:\'
    contents = 'this is some content'
}

resource 'example:file' 'file2.txt' @{
    description = 'this is another example file'
    ensure = 'present'
    path = 'c:\'
    contents = 'this is some more content'
}
