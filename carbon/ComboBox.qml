import QtQuick
import QtQuick.Controls.impl
import QtQuick.Templates as T

// Carbon dropdown: a field with a chevron; the list opens below with the
// selected item marked
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

    delegate: T.ItemDelegate {
        id: item
        required property var model
        required property int index

        width: ListView.view.width
        implicitHeight: Tokens.controlHeight
        leftPadding: 12
        rightPadding: 36
        hoverEnabled: control.hoverEnabled
        highlighted: control.highlightedIndex === index
        text: model[control.textRole] ?? ""

        contentItem: Text {
            text: item.text
            font: item.font
            elide: Text.ElideRight
            verticalAlignment: Text.AlignVCenter
            color: item.highlighted || control.currentIndex === item.index ? Tokens.textPrimary : Tokens.textSecondary
        }
        background: Rectangle {
            color: control.currentIndex === item.index ? (item.highlighted ? Tokens.layerSelectedHover : Tokens.layerSelected)
                   : item.highlighted ? Tokens.layerHover : "transparent"
            ColorImage {
                anchors.right: parent.right
                anchors.rightMargin: 12
                anchors.verticalCenter: parent.verticalCenter
                visible: control.currentIndex === item.index
                source: "qrc:/qt/qml/Carbon/images/check.svg"
                color: Tokens.iconPrimary
            }
        }
    }

    indicator: ColorImage {
        x: control.mirrored ? 12 : control.width - width - 12
        y: (control.height - height) / 2
        source: "qrc:/qt/qml/Carbon/images/chevron-down.svg"
        color: control.enabled ? Tokens.iconPrimary : Tokens.textDisabled
        rotation: control.popup.visible ? 180 : 0
    }

    contentItem: T.TextField {
        leftPadding: control.editable ? 12 : 0
        topPadding: 6
        bottomPadding: 6

        text: control.editable ? control.editText : control.displayText

        enabled: control.editable
        autoScroll: control.editable
        readOnly: control.down
        inputMethodHints: control.inputMethodHints
        validator: control.validator
        selectByMouse: control.selectTextByMouse

        font: control.font
        color: control.enabled ? Tokens.textPrimary : Tokens.textDisabled
        selectionColor: Tokens.highlight
        selectedTextColor: Tokens.textPrimary
        verticalAlignment: Text.AlignVCenter
    }

    background: Rectangle {
        implicitWidth: 160
        implicitHeight: Tokens.fieldHeight
        color: control.hovered && control.enabled ? Tokens.fieldHover : Tokens.field
        Rectangle {
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            height: 1
            color: control.enabled ? Tokens.borderStrong : "transparent"
            visible: !control.activeFocus
        }
        FocusRing {
            anchors.fill: parent
            visible: control.activeFocus
        }
    }

    popup: T.Popup {
        y: control.height
        width: control.width
        height: Math.min(contentItem.implicitHeight + topPadding + bottomPadding,
                         control.Window.height - topMargin - bottomMargin)
        topMargin: 6
        bottomMargin: 6
        padding: 0

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
            color: Tokens.layer01
            // Carbon's menus float on a soft shadow
            Rectangle {
                z: -1
                anchors.fill: parent
                anchors.topMargin: 2
                anchors.bottomMargin: -4
                anchors.leftMargin: -1
                anchors.rightMargin: -1
                color: Tokens.shadow
                opacity: 0.35
            }
        }
    }
}
