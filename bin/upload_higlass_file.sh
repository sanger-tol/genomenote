#!/usr/bin/env bash   
   
pod_name=$1
project_name=$2
file_name=$3
file_type=$4
file_ext=$5
uid=$6
assembly=$7

# add file type as a suffix to the tileset uid
uid="${uid}_${file_type}"

file_upload="${file_name}_${file_type}"

# Check to see if a tileset with the same name already exists and delete it if so
tilesets=$(kubectl exec $pod_name -- python /home/higlass/projects/higlass-server/manage.py list_tilesets | (grep $file_upload || [ "$?" == "1" ] ) | awk '{print substr($NF, 1, length($NF)-1)}')

for f in $tilesets; do
    echo "Deleting $f"
    kubectl exec $pod_name --  python /home/higlass/projects/higlass-server/manage.py delete_tileset --uuid $f
done

# Upload the file
echo "Loading ${file_upload}${file_ext} file"

if [[ $file_ext == '.mcool' ]]
then 
    kubectl exec $pod_name --  python /home/higlass/projects/higlass-server/manage.py ingest_tileset --filename /higlass-temp/${project_name}/${file_name}.mcool --filetype cooler --datatype matrix --project-name ${project_name} --name ${file_upload} --uid ${uid}
elif [[ $file_ext == '.genome' ]]
then
    kubectl exec $pod_name --  python /home/higlass/projects/higlass-server/manage.py ingest_tileset --filename /higlass-temp/${project_name}/${file_name}.genome --filetype chromsizes-tsv --datatype chromsizes --coordSystem ${assembly}_assembly --project-name ${project_name} --name ${file_upload} --uid ${uid}
fi

echo "$file_upload loaded"

