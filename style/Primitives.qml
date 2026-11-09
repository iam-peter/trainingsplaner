pragma Singleton
import QtQuick

// The raw values of the design: every colour the program uses, and the
// steps for spacing, radii, strokes and sizes. Nothing here says what a
// value is for; TokenInterface gives them their roles per colour scheme,
// and the control styles use those roles.
//
// A colour is named by its family and its lightness from 0 (black) to
// 1000 (white), so neutral_973 is a light grey and red_453 a mid red.
QtObject {
    id: root

    component Neutrals: QtObject {
        readonly property color neutral_000: "#000000"
        readonly property color neutral_118: "#1e1e1e"
        readonly property color neutral_141: "#242424"
        readonly property color neutral_149: "#262626"
        readonly property color neutral_165: "#2a2a2a"
        readonly property color neutral_173: "#2c2c2c"
        readonly property color neutral_180: "#2e2e2e"
        readonly property color neutral_196: "#323232"
        readonly property color neutral_200: "#333333"
        readonly property color neutral_227: "#3a3a3a"
        readonly property color neutral_271: "#454545"
        readonly property color neutral_322: "#525252"
        readonly property color neutral_431: "#6e6e6e"
        readonly property color neutral_451: "#737373"
        readonly property color neutral_604: "#9a9a9a"
        readonly property color neutral_627: "#a0a0a0"
        readonly property color neutral_831: "#d4d4d4"
        readonly property color neutral_855: "#dadada"
        readonly property color neutral_878: "#e0e0e0"
        readonly property color neutral_894: "#e4e4e4"
        readonly property color neutral_902: "#e6e6e6"
        readonly property color neutral_933: "#eeeeee"
        readonly property color neutral_941: "#f0f0f0"
        readonly property color neutral_969: "#f7f7f7"
        readonly property color neutral_973: "#f8f8f8"
        readonly property color neutral_980: "#fafafa"
        readonly property color neutral_1000: "#ffffff"
    }
    readonly property Neutrals neutrals: Neutrals {}

    component Accents: QtObject {
        // The old program under Windows XP: its blues, its warm greys and
        // the yellow of its session boxes
        readonly property color navy_225: "#003c73"
        readonly property color blue_482: "#316ac5"
        readonly property color blue_845: "#c1d2ee"
        readonly property color blue_935: "#e3ecfa"
        readonly property color steel_612: "#7f9db9"
        readonly property color beige_418: "#716f64"
        readonly property color beige_637: "#aca899"
        readonly property color beige_886: "#ece9d8"
        readonly property color beige_953: "#f7f3ef"
        readonly property color yellow_814: "#ffeda0"
        readonly property color yellow_869: "#fff4bc"

        // Danger
        readonly property color red_439: "#c42b1c"
        readonly property color red_453: "#e7000b"
        readonly property color red_631: "#f05252"

        // Chart series
        readonly property color orange_480: "#f54a00"
        readonly property color amber_498: "#fe9a00"
        readonly property color yellow_500: "#ffb900"
        readonly property color teal_294: "#009689"
        readonly property color pine_227: "#104e64"
        readonly property color green_369: "#00bc7d"
        readonly property color cobalt_490: "#1447e6"
        readonly property color violet_637: "#ad46ff"
        readonly property color rose_563: "#ff2056"
    }
    readonly property Accents accents: Accents {}

    // Spacing in steps of 4 px; sp100 is 8 px
    component Spacing: QtObject {
        readonly property int sp025: 2
        readonly property int sp050: 4
        readonly property int sp075: 6
        readonly property int sp100: 8
        readonly property int sp125: 10
        readonly property int sp150: 12
        readonly property int sp200: 16
    }
    readonly property Spacing spacing: Spacing {}

    // Corners stay small: never more than 4 px, 2 px for small items in a
    // rounded container
    component Radius: QtObject {
        readonly property int r2: 2
        readonly property int r3: 3
        readonly property int r4: 4
    }
    readonly property Radius radius: Radius {}

    component Stroke: QtObject {
        readonly property int s1: 1
        readonly property int s2: 2

        readonly property int thin: s1
        readonly property int thick: s2
    }
    readonly property Stroke stroke: Stroke {}

    component Size: QtObject {
        readonly property int s4: 4
        readonly property int s6: 6
        readonly property int s8: 8
        readonly property int s14: 14
        readonly property int s16: 16
        readonly property int s20: 20
        readonly property int s24: 24
        readonly property int s32: 32
        readonly property int s36: 36
        readonly property int s64: 64
        readonly property int s160: 160
    }
    readonly property Size size: Size {}

    component FontWeight: QtObject {
        readonly property int regular: Font.Normal
        readonly property int medium: Font.Medium
        readonly property int semiBold: Font.DemiBold
        readonly property int bold: Font.Bold
    }
    readonly property FontWeight fontWeight: FontWeight {}

    // A colour with another opacity
    function alpha(c: color, a: real): color {
        return Qt.rgba(c.r, c.g, c.b, a)
    }
}
