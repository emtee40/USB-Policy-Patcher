patch_xml() {
  if [ "$(xmlstarlet sel -t -m "$2" -c . $1)" ]; then
    [ "$(xmlstarlet sel -t -m "$2" -c . $1 | sed -r "s/.*samplingRates=\"([0-9]*)\".*/\1/")" == "48000" ] && return
    xmlstarlet ed -L -i "$2" -t elem -n "$MODID" $1
    local LN=$(sed -n "/<$MODID\/>/=" $1)
    for i in ${LN}; do
      sed -i "$i d" $1
      sed -i "$i p" $1
      sed -ri "${i}s/(^ *)(.*)/\1<!--$MODID\2$MODID-->/" $1
      sed -i "$((i+1))s/$/<!--$MODID-->/" $1
    done
    xmlstarlet ed -L -u "$2/@samplingRates" -v "48000" $1
  else
    local NP=$(echo "$2" | sed -r "s|(^.*)/.*$|\1|")
    local SNP=$(echo "$2" | sed -r "s|(^.*)\[.*$|\1|")
    local SN=$(echo "$2" | sed -r "s|^.*/.*/(.*)\[.*$|\1|")
    xmlstarlet ed -L -s "$NP" -t elem -n "$SN-$MODID" -i "$SNP-$MODID" -t attr -n "name" -v "" -i "$SNP-$MODID" -t attr -n "format" -v "AUDIO_FORMAT_PCM_16_BIT" -i "$SNP-$MODID" -t attr -n "samplingRates" -v "48000" -i "$SNP-$MODID" -t attr -n "channelMasks" -v "AUDIO_CHANNEL_OUT_STEREO" $1
    xmlstarlet ed -L -r "$SNP-$MODID" -v "$SN" $1
    xmlstarlet ed -L -i "$2" -t elem -n "$MODID" $1
    local LN=$(sed -n "/<$MODID\/>/=" $1)
    for i in ${LN}; do
      sed -i "$i d" $1
      sed -ri "${i}s/$/<!--$MODID-->/" $1
    done 
  fi
  local LN=$(sed -n "/^ *<!--$MODID-->$/=" $1 | tac)
  for i in ${LN}; do
    sed -i "$i d" $1
    sed -ri "$((i-1))s/$/<!--$MODID-->/" $1
  done 
}

# Tell user aml is needed if applicable
if $MAGISK && ! $SYSOVERRIDE; then
  if $BOOTMODE; then LOC="/sbin/.core/img/*/system $MOUNTPATH/*/system"; else LOC="$MOUNTPATH/*/system"; fi
  FILES=$(find $LOC -type f -name "usb_audio_policy_configuration.xml" -o -name "*audio_*policy*.conf" 2>/dev/null)
  if [ ! -z "$FILES" ] && [ ! "$(echo $FILES | grep '/aml/')" ]; then
    ui_print " "
    ui_print "   ! Conflicting audio mod found!"
    ui_print "   ! You will need to install !"
    ui_print "   ! Audio Modification Library !"
    sleep 3
  fi
fi

ui_print "   Decompressing files..."
tar -xf $INSTALLER/common/xmlstarlet.tar.xz -C $INSTALLER/common 2>/dev/null
chmod -R 755 $INSTALLER/common/xmlstarlet/$ARCH32
echo $PATH | grep -q "^$INSTALLER/common/xmlstarlet/$ARCH32" || export PATH=$INSTALLER/common/xmlstarlet/$ARCH32:$PATH
cp_ch $INSTALLER/common/xmlstarlet/$ARCH32/xmlstarlet $INSTALLER/system/bin/xmlstarlet

ui_print "   Patching usb policy files..."
if [ "$UPCS" ]; then
  for OFILE in ${UPCS}; do
    FILE="$UNITY$(echo $OFILE | sed "s|^/vendor|/system/vendor|g")"
    cp_ch -nn $ORIGDIR$OFILE $FILE
    grep -iE " name=\"usb[ _]+.* output\"" $FILE | sed -r "s/.*ame=\"([A-Za-z_ ]*)\".*/\1/" | while read i; do
      patch_xml $FILE "/module/mixPorts/mixPort[@name=\"$i\"]/profile[@name=\"\"]"
    done
    grep -iE "tagName=\"usb[ _]+.* out\"" $FILE | sed -r "s/.*ame=\"([A-Za-z_ ]*)\".*/\1/" | while read i; do
      patch_xml $FILE "/module/devicePorts/devicePort[@tagName=\"$i\"]/profile[@name=\"\"]"
    done
  done
else
  for OFILE in ${APS}; do
    FILE="$UNITY$(echo $OFILE | sed "s|^/vendor|/system/vendor|g")"
    cp_ch -nn $ORIGDIR$OFILE $FILE
    SPACES=$(sed -n "/^ *usb {/p" $FILE | sed -r "s/^( *).*/\1/")
    sed -i "/^$SPACES\usb {/,/^$SPACES}/ {/sampling_rates/p; s/\(^ *\)\(sampling_rates .*$\)/\1<!--$MODID\2$MODID-->/g;}" $FILE
    sed -i "/^$SPACES\usb {/,/^$SPACES}/ s/\(^ *\)sampling_rates .*/\1sampling_rates 48000<!--$MODID-->/g" $FILE
  done
fi

$MAGISK && ! $SYSOVERRIDE && cp_ch -nn $INSTALLER/common/aml.sh $UNITY/.aml.sh
