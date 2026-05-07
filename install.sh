#!/bin/sh
maildir=${1:-~/.mail}

base=$(realpath "$(dirname "$0")")
files=${base}/files

cp -r "${files}/." ~/
mkdir -p "${maildir}"
cd "${files}"
find . -type f -print0 | while IFS= read -r -d '' src_file; do
    dest_file="$HOME/${src_file}"
    sed -i "s|\${MAILDIR}|${maildir}|g" "${dest_file}"
done

systemctl --user daemon-reload
systemctl --user enable --now goimapnotify.service
systemctl --user enable --now monitor-resume.timer
systemctl --user enable --now mbsync.timer
