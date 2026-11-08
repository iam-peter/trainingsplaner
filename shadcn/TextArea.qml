import QtQuick
import QtQuick.Controls.impl
import QtQuick.Templates as T

T.TextArea {
    id: control

    implicitWidth: Math.max(contentWidth + leftPadding + rightPadding,
                            implicitBackgroundWidth + leftInset + rightInset,
                            placeholder.implicitWidth + leftPadding + rightPadding)
    implicitHeight: Math.max(contentHeight + topPadding + bottomPadding,
                             implicitBackgroundHeight + topInset + bottomInset,
                             placeholder.implicitHeight + topPadding + bottomPadding)

    padding: 8
    leftPadding: 12
    rightPadding: 12
    hoverEnabled: true
    opacity: enabled ? 1 : 0.5

    color: Tokens.foreground
    selectionColor: Tokens.primary
    selectedTextColor: Tokens.primaryForeground
    placeholderTextColor: Tokens.mutedForeground

    PlaceholderText {
        id: placeholder
        x: control.leftPadding
        y: control.topPadding
        width: control.width - (control.leftPadding + control.rightPadding)
        height: control.height - (control.topPadding + control.bottomPadding)

        text: control.placeholderText
        font: control.font
        color: control.placeholderTextColor
        verticalAlignment: control.verticalAlignment
        visible: !control.length && !control.preeditText && (!control.activeFocus || control.horizontalAlignment !== Qt.AlignHCenter)
        elide: Text.ElideRight
        renderType: control.renderType
    }

    background: Rectangle {
        implicitWidth: 200
        implicitHeight: 64
        radius: Tokens.radiusMd
        color: control.readOnly ? "transparent" : Tokens.inputBackground
        border.color: control.activeFocus && !control.readOnly ? Tokens.ring : Tokens.input
        Shadow {
            z: -1
            anchors.fill: parent
            radius: parent.radius
            depth: 1
            visible: !control.readOnly
        }
        FocusRing {
            baseRadius: parent.radius
            visible: control.activeFocus && !control.readOnly
        }
    }
}
