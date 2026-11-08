import QtQuick
import QtQuick.Controls.impl
import QtQuick.Templates as T

// shadcn select: an input-like trigger with a faint chevron; the list is
// a popover with rounded items and a check at the selected one
T.ComboBox {
    id: control

    implicitWidth: Math.max(implicitBackgroundWidth + leftInset + rightInset,
                            implicitContentWidth + leftPadding + rightPadding)
    implicitHeight: Math.max(implicitBackgroundHeight + topInset + bottomInset,
                             implicitContentHeight + topPadding + bottomPadding,
                             implicitIndicatorHeight + topPadding + bottomPadding)

    leftPadding: control.editable ? 0 : 12
    rightPadding: 12 + (indicator ? indicator.width + 8 : 0)
    hoverEnabled: true
    opacity: enabled ? 1 : 0.5

    delegate: T.ItemDelegate {
        id: item
        required property var model
        required property int index

        width: ListView.view.width
        implicitHeight: 30
        leftPadding: 8
        rightPadding: 32
        hoverEnabled: control.hoverEnabled
        highlighted: control.highlightedIndex === index
        text: model[control.textRole] ?? ""

        contentItem: Text {
            text: item.text
            font: item.font
            elide: Text.ElideRight
            verticalAlignment: Text.AlignVCenter
            color: item.highlighted ? Tokens.accentForeground : Tokens.foreground
        }
        background: Rectangle {
            radius: Tokens.radiusSm
            color: item.highlighted ? Tokens.accent : "transparent"
            ColorImage {
                anchors.right: parent.right
                anchors.rightMargin: 8
                anchors.verticalCenter: parent.verticalCenter
                visible: control.currentIndex === item.index
                source: "qrc:/qt/qml/Shadcn/images/check.svg"
                sourceSize: Qt.size(16, 16)
                color: Tokens.foreground
            }
        }
    }

    indicator: ColorImage {
        x: control.mirrored ? 12 : control.width - width - 12
        y: (control.height - height) / 2
        source: "qrc:/qt/qml/Shadcn/images/chevron-down.svg"
        sourceSize: Qt.size(16, 16)
        color: Tokens.mutedForeground
        opacity: 0.8
    }

    contentItem: T.TextField {
        leftPadding: control.editable ? 12 : 0
        topPadding: 4
        bottomPadding: 4

        text: control.editable ? control.editText : control.displayText

        enabled: control.editable
        autoScroll: control.editable
        readOnly: control.down
        inputMethodHints: control.inputMethodHints
        validator: control.validator
        selectByMouse: control.selectTextByMouse

        font: control.font
        color: Tokens.foreground
        selectionColor: Tokens.primary
        selectedTextColor: Tokens.primaryForeground
        verticalAlignment: Text.AlignVCenter
    }

    background: Rectangle {
        implicitWidth: 160
        implicitHeight: Tokens.controlHeight
        radius: Tokens.radiusMd
        color: control.hovered && Tokens.dark ? Tokens.inputHover : Tokens.inputBackground
        border.color: control.activeFocus ? Tokens.ring : Tokens.input
        Shadow {
            z: -1
            anchors.fill: parent
            radius: parent.radius
            depth: 1
        }
        FocusRing {
            baseRadius: parent.radius
            visible: control.activeFocus
        }
    }

    popup: T.Popup {
        y: control.height + 4
        width: control.width
        height: Math.min(contentItem.implicitHeight + topPadding + bottomPadding,
                         control.Window.height - topMargin - bottomMargin)
        topMargin: 6
        bottomMargin: 6
        padding: 4

        contentItem: ListView {
            clip: true
            implicitHeight: contentHeight
            model: control.delegateModel
            currentIndex: control.highlightedIndex
            highlightMoveDuration: 0
            boundsBehavior: Flickable.StopAtBounds
            T.ScrollIndicator.vertical: ScrollIndicator {}
        }

        background: Rectangle {
            color: Tokens.popover
            radius: Tokens.radiusMd
            border.color: Tokens.border
            Shadow {
                z: -1
                anchors.fill: parent
                radius: parent.radius
                depth: 3
            }
        }
    }
}
