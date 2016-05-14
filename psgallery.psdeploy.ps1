Deploy POSHOrigin {
    By PSGalleryModule ToPSGallery {
        FromSource '.\POSHOrigin'
        To 'PSGallery'
        WithOptions @{
            ApiKey = $env:PSGALLERY_API_KEY
        }
    }
}