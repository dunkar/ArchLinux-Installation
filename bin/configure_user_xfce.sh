#Configure Thunar
xfconf-query --channel thunar --property /misc-full-path-in-title --create --type bool --set true
xfconf-query --channel thunar --property /default-view --create --type string --set ThunarDetailsView
xfconf-query --channel thunar --property /last-details-view-visible-columns -type string --set THUNAR_COLUMN_DATE_MODIFIED,THUNAR_COLUMN_GROUP,THUNAR_COLUMN_NAME,THUNAR_COLUMN_OWNER,THUNAR_COLUMN_PERMISSIONS,THUNAR_COLUMN_SIZE,THUNAR_COLUMN_TYPE
xfconf-query --channel thunar --property /last-details-view-column-order -type string --set THUNAR_COLUMN_NAME,THUNAR_COLUMN_SIZE,THUNAR_COLUMN_TYPE,THUNAR_COLUMN_OWNER,THUNAR_COLUMN_GROUP,THUNAR_COLUMN_PERMISSIONS,THUNAR_COLUMN_DATE_MODIFIED,THUNAR_COLUMN_DATE_ACCESSED,THUNAR_COLUMN_MIME_TYPE
xfconf-query --channel thunar --property /last-details-view-column-widths -type string --set 50,136,77,50,204,80,122,83,153

#Configure xfce panel
xfconf-query --create --channel xfce4-panel --property /plugins/plugin-8/timezone --create --type string --set US/Central

#Configure desktop
xfconf-query --channel xfce4-desktop --property /backdrop/screen0/monitor0/workspace0/image-style --type integer --set 0
xfconf-query --channel xfce4-desktop --property /backdrop/screen0/monitor0/workspace1/image-style --type integer --set 0
xfconf-query --channel xfce4-desktop --property /backdrop/screen0/monitor0/workspace2/image-style --type integer --set 0
xfconf-query --channel xfce4-desktop --property /backdrop/screen0/monitor0/workspace3/image-style --type integer --set 0
xfconf-query --channel xfce4-desktop --property /desktop-icons/file-icons/show-filesystem --type bool --set false
xfconf-query --channel xfce4-desktop --property /desktop-icons/file-icons/show-home --type bool --set false
xfconf-query --channel xfce4-desktop --property /desktop-icons/file-icons/show-trash --type bool --set false
