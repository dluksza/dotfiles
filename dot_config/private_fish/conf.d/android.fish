set --export ANDROID $HOME/Library/Android
set --export ANDROID_HOME $ANDROID/sdk
set -gx PATH $ANDROID_HOME/tools $PATH
set -gx PATH $ANDROID_HOME/tools/bin $PATH
set -gx PATH $ANDROID_HOME/platform-tools $PATH
set -gx PATH $ANDROID_HOME/emulator $PATH

set --export JAVA_HOME /Applications/Android\ Studio.app/Contents/jbr/Contents/Home
set -gx PATH $JAVA_HOME/bin $PATH
