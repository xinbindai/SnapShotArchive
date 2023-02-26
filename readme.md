# SnapShotArchive

The script will call rsync to do snapshot backup. Each call to the script will generate a snapshot subfolder in destination side for current source data. All unmodified files will be hard-linked to previous snapshot to save space and backup time.

# Usage Example

    snapshot.sh root@s1.my.org:/ /data/s20/ 56 weekly "--exclude core.\* --include /opt --include /home --include /var/lib/mysql --exclude session/ --exclude /\*"
    if [[ $? -ne 0 ]];then echo "Failed to remotely backup s1.my.org"

# License

View [license information](https://www.apache.org/licenses/) for the software contained in this image.
