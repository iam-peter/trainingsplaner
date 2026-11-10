import QtQuick
import QtQuick.Controls
import QtTest
import TrainingsplanerStyle as Styles

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

    Row {
        y: 260
        spacing: -1
        Button { id: first; text: "<"; groupPosition: Styles.GroupStyle.Position.First }
        TextField { id: middle; text: "46/2026"; groupPosition: Styles.GroupStyle.Position.Middle }
        Button { id: last; text: ">"; groupPosition: Styles.GroupStyle.Position.Last }
    }
    TextField { id: wrong; y: 300; text: "1.13.2001"; error: true }
    ComboBox { id: editableBox; y: 340; width: 240; editable: true; model: ["Bundeskader", "Landeskader"] }

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

        // A group's inner corners are square, its outer ones round
        function test_groupCorners() {
            const r = Styles.Primitives.radius.r4
            compare(first.styleCascade.radius.topLeft, r)
            compare(first.styleCascade.radius.topRight, 0)
            compare(middle.styleCascade.radius.topLeft, 0)
            compare(middle.styleCascade.radius.bottomRight, 0)
            compare(last.styleCascade.radius.bottomLeft, 0)
            compare(last.styleCascade.radius.bottomRight, r)
            compare(first.background.topRightRadius, 0)
        }

        // An error shows in the border, also with the focus
        function test_errorBorder() {
            const danger = Styles.TokenInterface.semantics.danger_default
            compare(wrong.background.border.color, danger)
            wrong.forceActiveFocus()
            compare(wrong.background.border.color, danger)
            compare(plain.styleCascade.border.color, Styles.TokenInterface.semantics.stroke_field)
        }

        // Dragging over an editable box's text selects it, as in a field
        function test_editableSelectsByMouse() {
            const field = editableBox.contentItem
            mouseDrag(field, 4, field.height / 2, field.width / 2, 0)
            verify(field.selectedText.length > 0)
            verify(!editableBox.popup.visible)
        }
    }
}
