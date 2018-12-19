RUNONCE=true
[ -f "$MOUNTPATH/upp/system/bin/xmlstarlet" ] && alias xmlstarlet=$MOUNTPATH/upp/system/bin/xmlstarlet

patch_xml() {
  if [ "$(xmlstarlet sel -t -m "$2" -c . $1)" ]; then
    [ "$(xmlstarlet sel -t -m "$2" -c . $1 | sed -r "s/.*samplingRates=\"([0-9]*)\".*/\1/")" == "48000" ] && return
    xmlstarlet ed -L -u "$2/@samplingRates" -v "48000" $1
  else
    local NP=$(echo "$2" | sed -r "s|(^.*)/.*$|\1|")
    local SNP=$(echo "$2" | sed -r "s|(^.*)\[.*$|\1|")
    local SN=$(echo "$2" | sed -r "s|^.*/.*/(.*)\[.*$|\1|")
    xmlstarlet ed -L -s "$NP" -t elem -n "$SN-$MODID" -i "$SNP-$MODID" -t attr -n "name" -v "" -i "$SNP-$MODID" -t attr -n "format" -v "AUDIO_FORMAT_PCM_16_BIT" -i "$SNP-$MODID" -t attr -n "samplingRates" -v "48000" -i "$SNP-$MODID" -t attr -n "channelMasks" -v "AUDIO_CHANNEL_OUT_STEREO" $1
    xmlstarlet ed -L -r "$SNP-$MODID" -v "$SN" $1
  fi
}

if [ "$(find $MODPATH/system -type f -name "usb_audio_policy_configuration.xml")" ]; then
  for FILE in $(find $MODPATH/system -type f -name "usb_audio_policy_configuration.xml"); do
    grep -iE " name=\"usb[ _]+.* output\"" $FILE | sed -r "s/.*ame=\"([A-Za-z_ ]*)\".*/\1/" | while read i; do
      patch_xml $FILE "/module/mixPorts/mixPort[@name=\"$i\"]/profile[@name=\"\"]"
    done
    grep -iE "tagName=\"usb[ _]+.* out\"" $FILE | sed -r "s/.*ame=\"([A-Za-z_ ]*)\".*/\1/" | while read i; do
      patch_xml $FILE "/module/devicePorts/devicePort[@tagName=\"$i\"]/profile[@name=\"\"]"
    done
  done
else
  for FILE in $(find $MODPATH/system -type f -name "*audio_*policy*.conf"); do
    SPACES=$(sed -n "/^ *usb {/p" $FILE | sed -r "s/^( *).*/\1/")
    sed -i "/^$SPACES\usb {/,/^$SPACES}/ s/\(^ *\)sampling_rates .*/\1sampling_rates 48000/g" $FILE
  done
fi
