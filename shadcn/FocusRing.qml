import QtQuick

// shadcn's focus: a soft 3 px ring around the control (ring-[3px]
// ring-ring/50); the control draws its own border in the ring colour
Rectangle {
    property real baseRadius: 0
    anchors.fill: parent
    anchors.margins: -3
    radius: baseRadius + 3
    color: "transparent"
    border.width: 3
    border.color: Tokens.ringSoft
}
