import QtQuick
import Trainingsplaner
import TrainingsplanerStyle as Styles
import QtQuick.Controls
import QtQuick.Layouts

// The dialog all screens use: modal, centred in the window, and the window
// behind it clearly dimmed, so it is obvious that the dialog has the focus.
// The dim layer is anchored to the
// overlay, so it always covers the whole window, also after resizing.
// A dialog opened from another dialog does not add a second dim layer.
// The dialog takes the keyboard focus, so Esc closes it, and Enter answers
// Yes/OK in a dialog that asks for that. The standard buttons are labelled
// in German without depending on Qt's translation files being installed.
Dialog {
    id: root

    // Set while opening: another AppDialog is already open
    property bool nested: false
    property bool counted: false
    // Position in the stack of open dialogs; the topmost one takes Enter
    property int level: 0
    readonly property bool enterAccepts: (standardButtons & (Dialog.Yes | Dialog.Ok)) !== 0

    function labelButtons() {
        const labels = [[Dialog.Ok, "OK"], [Dialog.Cancel, "Abbrechen"], [Dialog.Yes, "Ja"],
                        [Dialog.No, "Nein"], [Dialog.Close, "Schließen"], [Dialog.Save, "Speichern"],
                        [Dialog.Discard, "Verwerfen"], [Dialog.Apply, "Anwenden"]]
        for (const [which, text] of labels) {
            const button = standardButton(which)
            if (button)
                button.text = text
        }
        // "Speichern" has the save icon everywhere, like the program's own
        // save buttons (emphasis comes from the styles, by the button's role)
        const save = standardButton(Dialog.Save)
        if (save) {
            save.icon.source = Theme.icon("save")
            save.icon.width = 16
            save.icon.height = 16
            // No colour: the style tints the icon in its own text colour
        }
    }
    Component.onCompleted: {
        labelButtons()
        // The content into a scroll area, which shows a bar only when the
        // content is taller than the dialog may be
        if (!scrollsContent || !contentItem)
            return
        const inner = contentItem
        const scroller = scrollerComponent.createObject(null, { inner: inner })
        contentItem = scroller
        inner.parent = scroller.contentItem
        // It kept its place as the dialog's content, inside the padding
        inner.x = 0
        inner.y = 0
        inner.visible = true
        inner.width = Qt.binding(() => scroller.width)
        inner.height = Qt.binding(() => scroller.innerHeight)
    }
    onStandardButtonsChanged: labelButtons()

    parent: Overlay.overlay
    anchors.centerIn: parent

    // The natural width from the title text and the buttons themselves,
    // not from the title label and the button row: the styles size those
    // from the dialog's width (a lone button gets half of it), so taking
    // their natural widths made a binding loop whenever the content grew.
    TextMetrics {
        id: titleMetrics
        font: root.header ? root.header.font : root.font
        text: root.title
    }
    readonly property real titleWidth: root.title === "" || !root.header ? 0
        : titleMetrics.advanceWidth + root.header.leftPadding + root.header.rightPadding + 2
    readonly property real buttonsWidth: {
        const box = footer
        if (!box || !box.visible || box.count === undefined || box.count === 0)
            return 0
        let w = 0
        let n = 0
        for (let i = 0; i < box.count; ++i) {
            const it = box.itemAt(i)
            if (it && it.visible) {
                w += it.implicitWidth
                ++n
            }
        }
        // The styles give a lone button the right half of the row
        if (n === 1)
            w *= 2
        return w + Math.max(0, n - 1) * box.spacing + box.leftPadding + box.rightPadding
               + (box.leadingWidth || 0)
    }
    implicitWidth: Math.max(implicitBackgroundWidth + leftInset + rightInset,
                            implicitContentWidth + leftPadding + rightPadding,
                            titleWidth,
                            buttonsWidth)
    modal: true
    // Blocking: a click on the dimmed window does nothing (Qt's dialogs
    // close on it by default, losing what was entered); the dialog's
    // buttons or Esc close it
    closePolicy: Popup.CloseOnEscape
    focus: true

    // A dialog is as high as its content, growing and shrinking with it,
    // up to the window's height less 40 px; content beyond that scrolls.
    // Tab pages that are not shown are laid out before it opens, so the
    // tallest one counts and switching tabs keeps the height.
    // false: the dialog has a fixed height and scrolls its content itself
    property bool scrollsContent: true

    Component {
        id: scrollerComponent
        Flickable {
            id: scroller
            property Item inner
            // Layouts report their size; the plain content item of a dialog
            // without one takes its children's, as Qt's dialogs do (their
            // natural size, not where they are: a child that fills it would
            // otherwise depend on the height it gets from here)
            function natural(item, vertical) {
                if (!item)
                    return 0
                const own = vertical ? item.implicitHeight : item.implicitWidth
                if (own > 0)
                    return own
                let n = 0
                for (const c of item.children) {
                    if (c.visible)
                        n = Math.max(n, vertical ? c.implicitHeight : c.implicitWidth)
                }
                return n
            }
            readonly property real innerHeight: natural(inner, true)
            implicitWidth: natural(inner, false)
            implicitHeight: innerHeight
            contentWidth: width
            contentHeight: innerHeight
            clip: true
            boundsBehavior: Flickable.StopAtBounds
            // In the dialog's right padding, beside the content: making room
            // for it inside would narrow the content, which then wraps
            // taller and decides anew whether the bar shows (a loop)
            ScrollBar.vertical: AppScrollBar {
                parent: scroller.parent
                x: scroller.x + scroller.width + Math.max(0, (root.rightPadding - width) / 2)
                y: scroller.y
                height: scroller.height
            }
        }
    }

    function layoutHidden(item) {
        // Hidden pages of a StackLayout have no width yet, so wrapped text
        // would be measured too short: give them the layout's width
        const stack = String(item).startsWith("QQuickStackLayout")
        if (stack && item.width > 0) {
            for (let i = 0; i < item.children.length; ++i) {
                if (!item.children[i].visible)
                    item.children[i].width = item.width
            }
        }
        for (let i = 0; i < item.children.length; ++i)
            layoutHidden(item.children[i])
        if (typeof item.forceLayout === "function")
            item.forceLayout()
        // A StackLayout reports only its current page's height; it gets the
        // tallest page's, also when a page grows later
        if (stack) {
            item.Layout.preferredHeight = Qt.binding(() => {
                let tallest = 0
                for (let i = 0; i < item.children.length; ++i)
                    tallest = Math.max(tallest, item.children[i].implicitHeight)
                return tallest
            })
        }
    }

    height: Math.min(parent ? parent.height - 40 : 100000, implicitHeight)

    onAboutToShow: {
        layoutHidden(contentItem)
        nested = DialogStack.open > 0
        if (!counted) {
            DialogStack.open += 1
            counted = true
        }
        level = DialogStack.open
    }

    // Enter and Esc work from the moment the dialog shows, also before it
    // has the keyboard focus
    Shortcut {
        sequences: ["Return", "Enter"]
        enabled: root.visible && root.enterAccepts && root.level === DialogStack.open
        onActivated: root.accept()
    }
    Shortcut {
        sequences: [StandardKey.Cancel]
        enabled: root.visible && (root.closePolicy & Popup.CloseOnEscape) && root.level === DialogStack.open
        onActivated: root.reject()
    }
    onClosed: {
        if (counted) {
            DialogStack.open -= 1
            counted = false
        }
    }
    Component.onDestruction: {
        if (counted)
            DialogStack.open -= 1
    }

    Overlay.modal: Rectangle {
        objectName: "dialogDim"
        anchors.fill: parent
        color: root.nested ? "transparent" : Styles.TokenInterface.semantics.dim
    }
}
