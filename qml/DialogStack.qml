pragma Singleton
import QtQuick

// How many AppDialogs are open, so a dialog opened from another one does
// not dim the window a second time.
QtObject {
    property int open: 0
}
