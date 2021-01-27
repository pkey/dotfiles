CURRENTDATEONLY=$(date -d "+10 days")
YEAR=`date +"%Y"`
MONTH=`date +"%m"`

echo $CURRENTDATEONLY
#open "bear://x-callback-url/create?title=${CURRENTDATEONLY}&open_note=yes&new_window=no&show_window=yes&edit=yes&tags=journal/${YEAR}/${MONTH}"
