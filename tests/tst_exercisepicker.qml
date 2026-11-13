import QtQuick
import QtTest
import Trainingsplaner

// The picker's title names the chosen exercise with its number from the
// start, the one under the pointer while hovering, and the chosen one
// again when the pointer leaves
Item {
    width: 800
    height: 600

    ExercisePicker {
        id: picker
        current: 2
    }

    TestCase {
        name: "ExercisePicker"
        when: windowShown

        function test_titleWithNumber() {
            picker.open()
            tryCompare(picker, "opened", true)
            // The buttons are made on the first open: wait for their layout
            waitForRendering(picker.contentItem)
            const title = findChild(picker.contentItem, "pickerTitle")
            compare(title.text, "2  " + Store.exerciseName(2))
            const other = findChild(picker.contentItem, "exercise5")
            mouseMove(other, other.width / 2, other.height / 2)
            tryCompare(title, "text", "5  " + Store.exerciseName(5))
            mouseMove(picker.contentItem, 2, 2)
            tryCompare(title, "text", "2  " + Store.exerciseName(2))
            picker.close()
        }
    }
}
