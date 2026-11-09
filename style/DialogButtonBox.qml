import QtQuick
import QtQuick.Templates as T

// Dialog footer: the buttons on the right with a small gap, the
// cancelling ones outlined, the confirming one filled, a destructive one
// red. The kind follows the button's role: the box resets highlighted.
T.DialogButtonBox {
    id: control

    implicitWidth: Math.max(implicitBackgroundWidth + leftInset + rightInset,
                            (contentItem as ListView)?.contentWidth + leftPadding + rightPadding)
    implicitHeight: Math.max(implicitBackgroundHeight + topInset + bottomInset,
                             implicitContentHeight + topPadding + bottomPadding)
    contentWidth: (contentItem as ListView)?.contentWidth

    spacing: Tokens.space2
    padding: Tokens.space4
    topPadding: 0
    alignment: Qt.AlignRight
    // Cancel on the left, confirm on the right, on every system
    buttonLayout: T.DialogButtonBox.GnomeLayout

    // The buttons already given their kind
    property var arranged: []

    function kindFor(role) {
        if (role === T.DialogButtonBox.AcceptRole || role === T.DialogButtonBox.YesRole
                || role === T.DialogButtonBox.ApplyRole)
            return "default"
        if (role === T.DialogButtonBox.DestructiveRole)
            return "destructive"
        return "outline"
    }

    function arrange() {
        for (let i = 0; i < count; ++i) {
            const it = itemAt(i)
            if (!it || arranged.indexOf(it) >= 0)
                continue
            arranged.push(it)
            // Buttons the program adds itself, by their role
            if (it.kind !== undefined && it.standard !== true)
                it.kind = Qt.binding(() => control.kindFor(it.DialogButtonBox.buttonRole))
        }
    }

    onCountChanged: Qt.callLater(arrange)
    Component.onCompleted: Qt.callLater(arrange)

    delegate: Button {
        readonly property bool standard: true
        kind: control.kindFor(T.DialogButtonBox.buttonRole)
    }

    contentItem: ListView {
        implicitWidth: contentWidth
        implicitHeight: 32
        model: control.contentModel
        spacing: control.spacing
        orientation: ListView.Horizontal
        boundsBehavior: Flickable.StopAtBounds
        interactive: false
        snapMode: ListView.SnapToItem
    }

    background: Item {}
}
