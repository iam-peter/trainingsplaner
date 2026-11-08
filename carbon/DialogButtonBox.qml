import QtQuick
import QtQuick.Templates as T

// Carbon modal footer: the buttons share the full width without gaps,
// the cancelling ones secondary on the left, the confirming one primary
// on the right, a destructive one red. A single button takes the right
// half. The kind follows the button's role: the box resets highlighted.
T.DialogButtonBox {
    id: control

    property int visibleCount: 0
    readonly property real slotWidth: visibleCount === 1 ? availableWidth / 2
                                                        : availableWidth / Math.max(1, visibleCount)

    implicitWidth: Math.max(implicitBackgroundWidth + leftInset + rightInset,
                            (contentItem as ListView)?.contentWidth + leftPadding + rightPadding)
    implicitHeight: Math.max(implicitBackgroundHeight + topInset + bottomInset,
                             Tokens.modalButtonHeight + topPadding + bottomPadding)

    spacing: 0
    padding: 0
    // Cancel on the left, confirm on the right, on every system
    buttonLayout: T.DialogButtonBox.GnomeLayout

    // The buttons already given their size and kind
    property var arranged: []

    function kindFor(role) {
        if (role === T.DialogButtonBox.AcceptRole || role === T.DialogButtonBox.YesRole
                || role === T.DialogButtonBox.ApplyRole)
            return "primary"
        if (role === T.DialogButtonBox.DestructiveRole)
            return "danger"
        return "secondary"
    }

    function recount() {
        let n = 0
        for (let i = 0; i < count; ++i) {
            const it = itemAt(i)
            if (it && it.visible)
                ++n
        }
        visibleCount = n
    }

    function arrange() {
        for (let i = 0; i < count; ++i) {
            const it = itemAt(i)
            if (!it || arranged.indexOf(it) >= 0)
                continue
            arranged.push(it)
            it.visibleChanged.connect(control.recount)
            it.width = Qt.binding(() => it.visible ? control.slotWidth : 0)
            it.height = Qt.binding(() => Tokens.modalButtonHeight)
            // Buttons the program adds itself, by their role
            if (it.kind !== undefined && it.standard !== true)
                it.kind = Qt.binding(() => control.kindFor(it.DialogButtonBox.buttonRole))
        }
        recount()
    }

    onCountChanged: Qt.callLater(arrange)
    Component.onCompleted: Qt.callLater(arrange)

    delegate: Button {
        readonly property bool standard: true
        kind: control.kindFor(T.DialogButtonBox.buttonRole)
    }

    contentItem: ListView {
        implicitWidth: contentWidth
        model: control.contentModel
        spacing: control.spacing
        orientation: ListView.Horizontal
        boundsBehavior: Flickable.StopAtBounds
        interactive: false
        // A single button sits on the right
        leftMargin: control.visibleCount === 1 ? control.availableWidth / 2 : 0
    }

    background: Item {
        implicitHeight: Tokens.modalButtonHeight
    }
}
