#!/bin/sh
get_earthcam_entropy_image () (
  # The first argument is a positive integer (0 inclusive) that sets an offset of N hours beyond 24 hours ago.
  OFFSET_HOURS=${1:-0}

  # The second argument is a string that sets a custom basename for the final output file.
  OUTPUT_BASENAME=${2:-final}

  # The route used by the EarthCam networks' thumbnail archives.
  EARTHCAM_ADDR="https://www.earthcam.com/cams/includes/images/archivethumbs/network"

  # Specific network IDs used by this function.
  # NOTE: The order of these IDs is important!
  NETWORK_IDS=" \
    17832 9602 4054 \
    16812 15629 ceuta1 \
    19706 19986 21250 \
    19159 17605 14191 \
    20223 meprd_garch 15041 \
    14789 8939 19902 \
    14561 9392 13004 \
    9299 7132 4515 \
    nabtrcam1 19407 moscowHD1 \
    485 16763 17101 \
    16852 16823 6405 \
    8174 15200 oneandonlylsg \
    14179 6593 10610 \
  "

  # Destination path for saved image files.
  IMAGE_DIR="${HOME}/.gnupg/images"

  # Create the destination path if it doesn't exist yet.
  [ ! -d "${IMAGE_DIR}" ] && mkdir -p "${IMAGE_DIR}"

  # Initialize variables used to generate XOR data.
  A=0; B=0; C=0; D=0; E=0; F=0;

  # Iterate across the network IDs.
  for ID in $NETWORK_IDS; do
    # Exception that occurs when the 13th "C" file is leftover.
    EXCEPT_E=
    # Parse the image file URI based on date information.
    IMAGE_URL_PATH="$( \
      date -d "-$(( 24 + $OFFSET_HOURS )) hours" +'/%Y/%m/%d/%H.jpg' \
    )"
    # Test to see if a given network is live on EarthCam with an image file available.
    RES=$( \
      wget --spider "${EARTHCAM_ADDR}/${ID}/${IMAGE_URL_PATH}" 2>&1 | \
      tr '\n' ' ' \
    )
    # If we got a successful response...
    if [ ! -z "$( echo -n "${RES}" | grep -o "exists" )" ]; then
      # Build toward our final output image one wget at a time.
      case $A in
        0)
          wget \
            -cq "${EARTHCAM_ADDR}/${ID}/${IMAGE_URL_PATH}" \
            -O "${IMAGE_DIR}/a${A}.jpg"
          ;;
        1)
          wget \
            -cq "${EARTHCAM_ADDR}/${ID}/${IMAGE_URL_PATH}" \
            -O "${IMAGE_DIR}/a${A}.jpg"
          convert \
            "${IMAGE_DIR}/a$(( $A - 1 )).jpg" \
            "${IMAGE_DIR}/a$(( $A - 0 )).jpg" \
            -fx "(((255*u)&(255*(1-v)))|((255*(1-u))&(255*v)))/255" \
            "${IMAGE_DIR}/b${B}.jpg"
          rm -f \
            "${IMAGE_DIR}/a$(( $A - 1 )).jpg" \
            "${IMAGE_DIR}/a$(( $A - 0 )).jpg"
          B=$(( $B + 1 ))
          ;;
        2)
          if [[ $B -eq 1 && $C -eq 0 && $D -eq 0 && $E -eq 1 && $F -eq 1 ]]; then
            EXCEPT_E=1
            wget \
              -cq "${EARTHCAM_ADDR}/${ID}/${IMAGE_URL_PATH}" \
              -O "${IMAGE_DIR}/e${E}.jpg"
            E=$(( $E + 1 ))
          else
            wget \
              -cq "${EARTHCAM_ADDR}/${ID}/${IMAGE_URL_PATH}" \
              -O "${IMAGE_DIR}/b${B}.jpg"
            convert \
              "${IMAGE_DIR}/b$(( $B - 1 )).jpg" \
              "${IMAGE_DIR}/b$(( $B - 0 )).jpg" \
              -fx "(((255*u)&(255*(1-v)))|((255*(1-u))&(255*v)))/255" \
              "${IMAGE_DIR}/c${C}.jpg"
            rm -f \
              "${IMAGE_DIR}/b$(( $B - 1 )).jpg" \
              "${IMAGE_DIR}/b$(( $B - 0 )).jpg"
            C=$(( $C + 1 ))
            B=0
            A=-1
          fi
          ;;
      esac

      if [ $C -eq 2 ]; then
        convert \
          "${IMAGE_DIR}/c$(( $C - 2 )).jpg" \
          "${IMAGE_DIR}/c$(( $C - 1 )).jpg" \
          -fx "(((255*u)&(255*(1-v)))|((255*(1-u))&(255*v)))/255" \
          "${IMAGE_DIR}/d${D}.jpg"
        rm -f \
          "${IMAGE_DIR}/c$(( $C - 2 )).jpg" \
          "${IMAGE_DIR}/c$(( $C - 1 )).jpg"
        D=$(( $D + 1 ))
        C=0
      fi

      if [ -z "${EXCEPT_E}" ]; then
        if [ $D -eq 2 ]; then
          convert \
            "${IMAGE_DIR}/d$(( $D - 2 )).jpg" \
            "${IMAGE_DIR}/d$(( $D - 1 )).jpg" \
            -fx "(((255*u)&(255*(1-v)))|((255*(1-u))&(255*v)))/255" \
            "${IMAGE_DIR}/e${E}.jpg"
          rm -f \
            "${IMAGE_DIR}/d$(( $D - 2 )).jpg" \
            "${IMAGE_DIR}/d$(( $D - 1 )).jpg"
          E=$(( $E + 1 ))
          D=0
        fi
      fi

      if [ $E -eq 2 ]; then
        convert \
          "${IMAGE_DIR}/e$(( $E - 2 )).jpg" \
          "${IMAGE_DIR}/e$(( $E - 1 )).jpg" \
          -fx "(((255*u)&(255*(1-v)))|((255*(1-u))&(255*v)))/255" \
          "${IMAGE_DIR}/f${F}.jpg"
        rm -f \
          "${IMAGE_DIR}/e$(( $E - 2 )).jpg" \
          "${IMAGE_DIR}/e$(( $E - 1 )).jpg"
        F=$(( $F + 1 ))
        E=0
      fi

      if [ $F -eq 2 ]; then
        convert \
          "${IMAGE_DIR}/f$(( $F - 2 )).jpg" \
          "${IMAGE_DIR}/f$(( $F - 1 )).jpg" \
          -fx "(((255*u)&(255*(1-v)))|((255*(1-u))&(255*v)))/255" \
          "${IMAGE_DIR}/${OUTPUT_BASENAME}.jpg"
        rm -f \
          "${IMAGE_DIR}/f$(( $F - 2 )).jpg" \
          "${IMAGE_DIR}/f$(( $F - 1 )).jpg"
        for FILE in $( ls -A ${IMAGE_DIR} ); do
          if [ -z "$( echo -n $FILE | grep -o "${OUTPUT_BASENAME}" )" ]; then
            rm -f "${IMAGE_DIR}/${FILE}"
          fi
        done
        # Break out of this loop because our work is done.
        break
      fi

      A=$(( $A + 1 ))
    fi
  done
  echo "${IMAGE_DIR}/${OUTPUT_BASENAME}.jpg"
)