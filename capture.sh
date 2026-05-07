#!/bin/sh

# Update the distributed files based on my config. Heuristically
# replace all occurrences of '/home/melislg/.mail' with '${MAILDIR}'.

base=$(realpath "$(dirname "$0")")
files=${base}/files/

rm -rf "${files}"
mkdir "${files}"
cd ~
for file in .mbsyncrc \
            .dovecot.conf \
            bin/monitor-resume \
            bin/mbsync-gmail-full \
            .config/goimapnotify/goimapnotify.yaml \
            .config/systemd/user/*.{service,timer}; do
    cp -a --parents "${file}" "${files}"
    sed -i -e "s|/home/melisgl/\.mail|\${MAILDIR}|g" -e "s|Bin|Trash|" \
        "${files}/${file}"
done
