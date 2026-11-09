import QtQuick
import QtQuick.Controls.impl
import QtQuick.Templates as T

// shadcn input: bordered, rounded, a soft ring when focused
T.TextField {
    id: control

    // With the normal padding, not the actual one, which depends on the width
    implicitWidth: implicitBackgroundWidth + leftInset + rightInset
                   || Math.max(contentWidth, placeholder.implicitWidth) + 24
    implicitHeight: Math.max(implicitBackgroundHeight + topInset + bottomInset,
                             contentHeight + topPadding + bottomPadding,
                             placeholder.implicitHeight + topPadding + bottomPadding)

    // Narrow fields (a number of reps) keep room for their text
    leftPadding: width > 0 && width < 64 ? Tokens.space1 : Tokens.space3
    rightPadding: leftPadding
    topPadding: Tokens.space1
    bottomPadding: Tokens.space1
    verticalAlignment: TextInput.AlignVCenter
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
        implicitWidth: 160
        implicitHeight: Tokens.controlHeight
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
    }
}
