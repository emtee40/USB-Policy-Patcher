RUNONCE=true
[ -f "$MOUNTPATH/upp/system/bin/xmlstarlet" ] && alias xmlstarlet=$MOUNTPATH/upp/system/bin/xmlstarlet

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
