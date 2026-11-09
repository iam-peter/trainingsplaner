import QtQuick
import QtQuick.Controls

// A combo box that shows a value of the program's state (an athlete, a
// MAZ) and reports a pick with chosen(value). It looks the value up again
// after every change of the value or of its list, once the list is built:
// an index bound to the value was computed before a changed list had its
// entries, and the box then reset it to the first entry and showed
// another choice than the page had.
ComboBox {
    id: box

    property var value
    signal chosen(var value)

    textRole: "displayName"
    valueRole: "id"

    function sync() {
        const i = indexOfValue(value)
        if (currentIndex !== i)
            currentIndex = i
    }

    onValueChanged: sync()
    onModelChanged: Qt.callLater(sync)
    onCountChanged: Qt.callLater(sync)
    Component.onCompleted: sync()
    onActivated: chosen(currentValue)
}
