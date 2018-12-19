if ! $MAGISK || $SYSOVERRIDE; then
  for OFILE in ${UPCS}; do
    FILE="$UNITY$(echo $OFILE | sed "s|^/vendor|/system/vendor|g")"
    sed -i "/<!--$MODID-->/d" $FILE
    sed -i -e "s|<!--$MODID\(.*\)|\1|g" -e "s|\(.*\)$MODID-->|\1|g" $FILE
  done
  for OFILE in ${APS}; do
    FILE="$UNITY$(echo $OFILE | sed "s|^/vendor|/system/vendor|g")"
    sed -i "/<!--$MODID-->/d" $FILE
    sed -i -e "s|<!--$MODID\(.*\)|\1|g" -e "s|\(.*\)$MODID-->|\1|g" $FILE
  done
fi
