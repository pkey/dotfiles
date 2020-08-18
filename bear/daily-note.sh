CURRENTDATEONLY=`date +"%b %d, %Y"`
YEAR=`date +"%Y"`
MONTH=`date +"%m"`

open "bear://x-callback-url/create?title=${CURRENTDATEONLY}&open_note=yes&new_window=no&show_window=yes&edit=yes&tags=journal/${YEAR}/${MONTH}"
