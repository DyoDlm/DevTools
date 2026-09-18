export data=find . -name *cache
if [[ $data ]] ; then 
	echo nothing found
else
	echo files found
fi


