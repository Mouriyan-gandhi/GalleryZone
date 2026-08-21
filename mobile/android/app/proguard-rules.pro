# Flutter's own engine rules come from the Gradle plugin; this file is for
# anything this app adds on top.
#
# Empty on purpose. fl_chart and intl are pure Dart. image_picker and
# url_launcher ship consumer ProGuard rules in their own AARs, which R8 merges
# automatically — re-declaring them here would rot the first time either
# package changes its internals.
#
# If a release build crashes with a ClassNotFoundException that a debug build
# does not, add the keep rule here rather than switching minification off.
