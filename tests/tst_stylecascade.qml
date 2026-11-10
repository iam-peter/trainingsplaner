import QtQuick
import QtTest
import QtQuick.Controls as Controls
import Trainingsplaner
import TrainingsplanerStyle

// How a cascade resolves styles: rules by state, includes, the order of
// the layers, parts with their own rules, and the padding shorthands
Item {
    Style {
        id: base
        background: "#111111"
        text.color: "#222222"
        padding.value: 8
        Style {
            state: StyleState.Hover
            background: "#333333"
        }
        Style {
            part: StylePart.Indicator
            accent: "#444444"
            Style {
                state: StyleState.Active
                accent: "#555555"
            }
        }
    }
    Style {
        id: wide
        padding.horizontal: 12
    }
    Style {
        id: ghost
        includes: [wide]
        background: "transparent"
        Style {
            state: StyleState.Hover
            background: "#666666"
        }
    }
    Style {
        id: square
        radius.value: 4
        radius.topLeft: 0
    }

    StyleCascade {
        id: control
        base: [base]
    }
    StyleCascade {
        id: indicator
        parentCascade: control
        part: StylePart.Indicator
    }
    StyleCascade {
        id: chosen
        base: [base]
        styles: [ghost]
        overrides: [square]
    }

    Controls.Button {
        id: button
        text: "Speichern"
    }
    SignalSpy {
        id: chosenChanged
        target: chosen
        signalName: "changed"
    }

    TestCase {
        name: "StyleCascade"
        when: windowShown

        function test_states() {
            control.state = StyleState.Idle
            compare(control.background, "#111111")
            control.state = StyleState.Hover
            compare(control.background, "#333333")
            control.state = StyleState.Disable
            compare(control.background, "#111111")
        }

        function test_layers() {
            // styles over base, its include before its own values
            chosen.state = StyleState.Idle
            compare(chosen.background, "#00000000")
            compare(chosen.padding.left, 12)
            compare(chosen.padding.top, 8)
            chosen.state = StyleState.Hover
            compare(chosen.background, "#666666")
            // overrides last; a corner beats the value
            compare(chosen.radius.value, 4)
            compare(chosen.radius.topLeft, 0)
            compare(chosen.radius.bottomRight, 4)
        }

        function test_parts() {
            // A part takes the control's rules for it, in the control's
            // state, and its text from the control
            control.state = StyleState.Idle
            compare(indicator.accent, "#444444")
            compare(indicator.text.color, "#222222")
            // What no style sets reads as its default, with a warning
            ignoreWarning(/No style sets background/)
            compare(indicator.background, "#00000000")
            control.state = StyleState.Active
            compare(indicator.accent, "#555555")
        }

        function test_changes() {
            // A changed value reaches the cascades, also through parts
            control.state = StyleState.Idle
            base.background = "#777777"
            compare(control.background, "#777777")
            base.background = "#111111"
            base.rules[1].accent = "#888888"
            compare(indicator.accent, "#888888")
            base.rules[1].accent = "#444444"
        }

        // A control's colours follow the colour scheme while it shows
        function test_followsScheme() {
            const before = Store.colorScheme
            Store.colorScheme = "light"
            tryCompare(button.styleCascade, "background", TokenInterface.lightScheme.outline_default)
            Store.colorScheme = "dark"
            tryCompare(button.styleCascade, "background", TokenInterface.darkScheme.outline_default)
            compare(button.background.color, TokenInterface.darkScheme.outline_default)
            Store.colorScheme = before
        }

        // QML fills a list by clearing and appending: the cascade is told
        // once, when the list is complete, and then has the new values
        function test_listReassigned() {
            chosen.state = StyleState.Idle
            compare(chosen.padding.left, 12)
            chosenChanged.clear()
            chosen.styles = [square]
            compare(chosenChanged.count, 0)
            tryCompare(chosenChanged, "count", 1)
            compare(chosen.padding.left, 8)
            compare(chosen.background, "#111111")
            chosen.styles = [ghost]
            // Read before the cascade is told, it already resolves the new list
            compare(chosen.padding.left, 12)
        }
    }
}
