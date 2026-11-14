#!/bin/sh
set -eu
if [ "$#" -ne 1 ]; then
    echo 'Usage: publish-wiki.sh /path/to/pvim.wiki' >&2
    exit 2
fi
source_dir=$(CDPATH= cd "$(dirname "$0")/.." && pwd)
wiki_dir=$(CDPATH= cd "$1" && pwd)
if [ -n "$(git -C "$wiki_dir" status --porcelain)" ]; then
    echo 'Wiki checkout is dirty; refusing to overwrite local work.' >&2
    exit 1
fi
git -C "$wiki_dir" pull --ff-only
perl "$source_dir/tools/wiki.pl" --output "$wiki_dir"
git -C "$wiki_dir" add --all
if git -C "$wiki_dir" diff --cached --quiet; then
    echo 'Wiki already current.'
    exit 0
fi
version=$(perl "$source_dir/pvim" --version | cut -d' ' -f2)
revision=$(git -C "$source_dir" rev-parse --short HEAD)
git -C "$wiki_dir" -c user.name='Brett Estrade' -c user.email='69679854+oodler577@users.noreply.github.com' commit -m "Update pvim $version documentation from $revision"
git -C "$wiki_dir" push
