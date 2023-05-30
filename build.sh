#!/bin/bash

ASSET_DIR="example/assets/"
OUTPUT_FILE="lib/sound_edit_asset_list.dart"

echo "final List<String> soundEditAssetList = [" > $OUTPUT_FILE

for file in $(find $ASSET_DIR -type f); do
  asset_path=$(echo $file | sed "s|\\\\|/|g")
  echo "  '$asset_path'," >> $OUTPUT_FILE
done

echo "];" >> $OUTPUT_FILE
