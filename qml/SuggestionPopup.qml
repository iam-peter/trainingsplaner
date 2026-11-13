import QtQuick
import QtQuick.Controls
import Trainingsplaner
import TrainingsplanerStyle as Styles

// Earlier entries offered under a text field while it has the focus: the
// ones containing what is typed (or, with prefix, starting with it). The
// focus stays in the field: ↓ / ↑ choose, Enter takes one, Esc closes; a
// click takes one too.
//
// Declared inside its field; the field passes its keys with
// Keys.onPressed: (event) => popup.handleKey(event)
Popup {
    id: popup

    required property Item field
    property var suggestions: []    // [{ text, ... }]
    property bool prefix: false
    // Offered only while this holds (for weights: the line still empty)
    property bool active: true

    signal chosen(var item)

    readonly property var matches: {
        const typed = field.text.trim().toLowerCase()
        return suggestions.filter(s => {
            const t = s.text.toLowerCase()
            return t !== typed && (typed === "" || (prefix ? t.startsWith(typed) : t.indexOf(typed) >= 0))
        }).slice(0, 8)
    }
    property int current: -1

    // Opened or closed after a change of focus, text or list
    function update() {
        if (field.activeFocus && active && matches.length > 0) {
            current = Math.min(current, matches.length - 1)
            open()
        } else {
            close()
        }
    }

    function choose(i) {
        if (i < 0 || i >= matches.length)
            return
        const item = matches[i]
        close()
        chosen(item)
    }

    function handleKey(event) {
        if (!visible)
            return
        if (event.key === Qt.Key_Down) {
            current = Math.min(matches.length - 1, current + 1)
            event.accepted = true
        } else if (event.key === Qt.Key_Up) {
            current = Math.max(-1, current - 1)
            event.accepted = true
        } else if ((event.key === Qt.Key_Return || event.key === Qt.Key_Enter) && current >= 0) {
            choose(current)
            event.accepted = true
        } else if (event.key === Qt.Key_Escape) {
            close()
            event.accepted = true
        }
    }

    onMatchesChanged: if (visible || field.activeFocus) update()
    onActiveChanged: update()
    onClosed: current = -1

    property Connections fieldChanges: Connections {
        target: popup.field
        function onActiveFocusChanged() { popup.update() }
    }

    y: field.height + 2
    width: Math.max(field.width, 220)
    padding: 2
    // The field keeps the focus and its typing
    focus: false
    closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutsideParent

    contentItem: ListView {
        objectName: "suggestions"
        implicitHeight: contentHeight
        clip: true
        model: popup.matches
        boundsBehavior: Flickable.StopAtBounds
        delegate: ItemDelegate {
            required property var modelData
            required property int index
            width: ListView.view.width
            focusPolicy: Qt.NoFocus
            highlighted: index === popup.current
            text: modelData.text + (modelData.totalReps > 0 ? "   (WH " + modelData.totalReps + ")" : "")
            onClicked: popup.choose(index)
        }
    }
}
