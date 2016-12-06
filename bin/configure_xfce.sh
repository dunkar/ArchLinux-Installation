#Configure Thunar
xfconf-query --channel thunar --property /misc-full-path-in-title --create --type bool --set true
xfconf-query --channel thunar --property /default-view --create --type string --set ThunarDetailsView

#Configure xfce panel
xfconf-query --create --channel xfce4-panel --property /plugins/plugin-8/timezone --create --type string --set US/Central

#
