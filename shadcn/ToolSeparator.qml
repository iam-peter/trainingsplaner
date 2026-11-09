import QtQuick
import QtQuick.Templates as T

T.ToolSeparator {
    id: control

    implicitWidth: Math.max(implicitBackgroundWidth + leftInset + rightInset,
                            implicitContentWidth + leftPadding + rightPadding)
    implicitHeight: Math.max(implicitBackgroundHeight + topInset + bottomInset,
                             implicitContentHeight + topPadding + bottomPadding)

    padding: vertical ? Tokens.space1 : 0
    verticalPadding: vertical ? 0 : Tokens.space1

    contentItem: Rectangle {
        implicitWidth: control.vertical ? 1 : 20
        implicitHeight: control.vertical ? 18 : 1
        color: Tokens.border
    }
}
