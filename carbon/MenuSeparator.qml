import QtQuick
import QtQuick.Templates as T

T.MenuSeparator {
    id: control

    implicitWidth: Math.max(implicitBackgroundWidth + leftInset + rightInset,
                            implicitContentWidth + leftPadding + rightPadding)
    implicitHeight: Math.max(implicitBackgroundHeight + topInset + bottomInset,
                             implicitContentHeight + topPadding + bottomPadding)

    padding: 0
    verticalPadding: 4

    contentItem: Rectangle {
        implicitWidth: 188
        implicitHeight: 1
        color: Tokens.borderSubtle
    }
}
