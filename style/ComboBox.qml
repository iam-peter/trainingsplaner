import QtQuick
import QtQuick.Controls.impl
import QtQuick.Templates as T

// Select: an input-like trigger with a faint chevron; the list is
// a popover with rounded items and a check at the selected one
T.ComboBox {
    id: control

    property list<Style> styles
    readonly property alias styleCascade: cascade

    StyleCascade {
        id: cascade
        base: [FieldStyle.base, FieldStyle.comboBox]
        styles: control.styles
        overrides: [control.activeFocus ? FieldStyle.focus : null,
                    control.editable ? FieldStyle.editable : null]
        state: !control.enabled ? StyleState.Disable
               : control.hovered ? StyleState.Hover : StyleState.Idle
    }

    implicitWidth: Math.max(implicitBackgroundWidth + leftInset + rightInset,
                            implicitContentWidth + leftPadding + rightPadding)
    implicitHeight: Math.max(implicitBackgroundHeight + topInset + bottomInset,
                             implicitContentHeight + topPadding + bottomPadding,
                             implicitIndicatorHeight + topPadding + bottomPadding)

    leftPadding: cascade.padding.left
    rightPadding: cascade.padding.right + (indicator ? indicator.width + cascade.spacing : 0)
    hoverEnabled: true
    opacity: cascade.opacity

    delegate: T.ItemDelegate {
        id: item
        required property var model
        required property int index

        // Lights up only as the list's highlighted row, which follows
        // the pointer and the keys
        StyleCascade {
            id: itemStyle
            base: [ItemStyle.base, ItemStyle.comboItem]
            overrides: [item.highlighted ? ItemStyle.highlighted : null]
            state: !item.enabled ? StyleState.Disable : StyleState.Idle
        }

        width: ListView.view.width
        implicitHeight: itemStyle.height
        leftPadding: itemStyle.padding.left
        rightPadding: itemStyle.padding.right
        hoverEnabled: control.hoverEnabled
        highlighted: control.highlightedIndex === index
        text: model[control.textRole] ?? ""

        contentItem: Text {
            text: item.text
            font: item.font
            elide: Text.ElideRight
            verticalAlignment: Text.AlignVCenter
            color: itemStyle.text.color
        }
        background: Rectangle {
            radius: itemStyle.radius.value
            color: itemStyle.background
            ColorImage {
                anchors.right: parent.right
                anchors.rightMargin: itemStyle.spacing
                anchors.verticalCenter: parent.verticalCenter
                visible: control.currentIndex === item.index
                source: "qrc:/qt/qml/TrainingsplanerStyle/images/check.svg"
                sourceSize: Qt.size(itemStyle.icon.size, itemStyle.icon.size)
                color: itemStyle.icon.color
            }
        }
    }

    indicator: ColorImage {
        x: control.mirrored ? cascade.padding.right : control.width - width - cascade.padding.right
        y: (control.height - height) / 2
        source: "qrc:/qt/qml/TrainingsplanerStyle/images/chevron-down.svg"
        sourceSize: Qt.size(arrowStyle.icon.size, arrowStyle.icon.size)
        color: arrowStyle.icon.color
        opacity: arrowStyle.opacity

        StyleCascade {
            id: arrowStyle
            parentCascade: cascade
            part: StylePart.Arrow
        }
        // Points up while the list is open
        rotation: control.popup.visible ? 180 : 0
    }

    contentItem: T.TextField {
        leftPadding: control.editable ? cascade.padding.right : 0
        topPadding: cascade.padding.top
        bottomPadding: cascade.padding.bottom

        text: control.editable ? control.editText : control.displayText

        enabled: control.editable
        autoScroll: control.editable
        readOnly: control.down
        inputMethodHints: control.inputMethodHints
        validator: control.validator
        selectByMouse: control.selectTextByMouse

        font: control.font
        color: cascade.text.color
        selectionColor: cascade.selection
        selectedTextColor: cascade.selectedText
        verticalAlignment: Text.AlignVCenter
    }

    background: Rectangle {
        implicitWidth: cascade.width
        implicitHeight: cascade.height
        radius: cascade.radius.value
        color: cascade.background
        border.width: cascade.border.width
        border.color: cascade.border.color
    }

    // Nothing to choose: the list does not show at all
    popup: T.Popup {
        // A click outside only closes the list
        modal: true
        dim: false
        onOpened: if (control.count === 0) close()
        y: control.height + listStyle.spacing
        width: control.width
        height: Math.min(contentItem.implicitHeight + topPadding + bottomPadding,
                         control.Window.height - topMargin - bottomMargin)
        topMargin: 2 * listStyle.spacing
        bottomMargin: 2 * listStyle.spacing
        padding: listStyle.padding.value

        StyleCascade {
            id: listStyle
            base: [PopupStyle.list]
        }

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
            color: listStyle.background
            radius: listStyle.radius.value
            border.width: listStyle.border.width
            border.color: listStyle.border.color
            Shadow {
                z: -1
                anchors.fill: parent
                radius: parent.radius
                depth: 3
            }
        }
    }
}
