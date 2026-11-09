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

    leftPadding: control.editable ? 0 : Tokens.space3
    rightPadding: Tokens.space3 + (indicator ? indicator.width + Tokens.space2 : 0)
    hoverEnabled: true
    opacity: enabled ? 1 : 0.5

    delegate: T.ItemDelegate {
        id: item
        required property var model
        required property int index

        width: ListView.view.width
        implicitHeight: Tokens.controlHeight
        leftPadding: Tokens.space2
        rightPadding: Tokens.space2 + 16 + Tokens.space2
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
                anchors.rightMargin: Tokens.space2
                anchors.verticalCenter: parent.verticalCenter
                visible: control.currentIndex === item.index
                source: "qrc:/qt/qml/Shadcn/images/check.svg"
                sourceSize: Qt.size(16, 16)
                color: Tokens.foreground
            }
        }
    }

    indicator: ColorImage {
        x: control.mirrored ? Tokens.space3 : control.width - width - Tokens.space3
        y: (control.height - height) / 2
        source: "qrc:/qt/qml/Shadcn/images/chevron-down.svg"
        sourceSize: Qt.size(16, 16)
        color: Tokens.mutedForeground
        opacity: 0.8
        // Points up while the list is open
        rotation: control.popup.visible ? 180 : 0
    }

    contentItem: T.TextField {
        leftPadding: control.editable ? Tokens.space3 : 0
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
    }

    // Nothing to choose: the list does not show at all
    popup: T.Popup {
        onOpened: if (control.count === 0) close()
        y: control.height + Tokens.space1
        width: control.width
        height: Math.min(contentItem.implicitHeight + topPadding + bottomPadding,
                         control.Window.height - topMargin - bottomMargin)
        topMargin: Tokens.space2
        bottomMargin: Tokens.space2
        padding: Tokens.space1

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
            visible: control.count > 0
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
