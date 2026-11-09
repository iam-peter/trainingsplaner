import QtQuick
import QtQuick.Controls
import QtTest

// What a field can have besides its text: a leading icon, trailing items
// and a unit; an icon beside a check box's or radio button's label
Item {
    width: 600
    height: 400

    TextField { id: plain; width: 200 }
    TextField {
        id: field
        y: 40
        width: 200
        text: "61,4"
        unit: "kg"
        leadingIcon: "qrc:/qt/qml/Trainingsplaner/icons/calculator.svg"
        trailingItems: Rectangle { id: trailing; width: 20; height: 20 }
    }
    SpinBox { id: plainSpin; y: 80; width: 160; value: 12 }
    SpinBox {
        id: spin
        y: 120
        width: 160
        value: 12
        unit: "mm"
        leadingIcon: "qrc:/qt/qml/Trainingsplaner/icons/clock.svg"
    }
    CheckBox { id: plainCheck; y: 160; text: "Querformat" }
    CheckBox { id: check; y: 200; text: "Querformat"; icon.source: "qrc:/qt/qml/Trainingsplaner/icons/printer.svg" }

    TestCase {
        name: "FieldParts"
        when: windowShown

        function unitOf(control) {
            for (const c of control.children)
                if (c.text === control.unit && c.color !== undefined)
                    return c
            return null
        }

        function test_leadingMakesRoom() {
            verify(field.leftPadding > plain.leftPadding)
            verify(spin.leftPadding > plainSpin.leftPadding)
        }

        function test_unitAfterTheValue() {
            const unit = unitOf(field)
            verify(unit && unit.visible)
            // Right after the text, inside the field
            verify(unit.x > field.leftPadding + field.contentWidth)
            verify(unit.x + unit.width <= field.width - trailing.width)
            const spinUnit = unitOf(spin)
            verify(spinUnit.x > spin.leftPadding + spin.contentItem.contentWidth)
            verify(spinUnit.x + spinUnit.width <= spin.down.indicator.x)
        }

        function test_hiddenTrailingGivesRoomBack() {
            const withItem = field.rightPadding
            trailing.visible = false
            waitForItemPolished(trailing.parent)
            verify(field.rightPadding < withItem)
            trailing.visible = true
        }

        function test_iconBesideLabel() {
            verify(check.contentItem.leftPadding > plainCheck.contentItem.leftPadding)
            verify(check.implicitWidth > plainCheck.implicitWidth)
        }
    }
}
