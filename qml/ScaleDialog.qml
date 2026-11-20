import QtQuick
import TrainingsplanerStyle as Styles
import QtQuick.Controls
import QtQuick.Layouts
import Trainingsplaner

// Scales the plan in the grid by a factor, e.g. 90 % after an illness:
// the chosen weeks and values of the exercises the grid shows. In an ITP
// MHG and BW are rounded to the weight step, in a RO to whole percent.
AppDialog {
    id: dialog
    objectName: "scaleDialog"
    title: "Werte skalieren"

    property string owner
    property string fromMonday
    property int weeks: 0
    property var exercises: []
    property string setName
    property bool percent: false

    readonly property string lastMonday: weeks > 0 ? Store.addWeeks(fromMonday, weeks - 1) : fromMonday
    readonly property bool valid: fromField.monday !== "" && toField.monday !== ""
                                  && fromField.monday <= toField.monday
                                  && fromField.monday >= fromMonday && toField.monday <= lastMonday
                                  && (whBox.checked || mhgBox.checked || bwBox.checked)
    property string error

    // Every time: all weeks of the grid, all values, 90 %
    onAboutToShow: {
        fromField.text = Store.weekLabel(fromMonday)
        toField.text = Store.weekLabel(lastMonday)
        whBox.checked = true
        mhgBox.checked = true
        bwBox.checked = true
        factor.value = 90
        error = ""
    }

    function apply() {
        const n = Plan.scaleTargets({ owner: owner, from: fromField.monday, to: toField.monday,
                                      exercises: exercises, wh: whBox.checked, mhg: mhgBox.checked,
                                      bw: bwBox.checked, percent: factor.value })
        if (n < 0) {
            error = "Die Werte ließen sich nicht ändern."
            return
        }
        close()
    }

    GridLayout {
        columns: 2
        columnSpacing: 12
        rowSpacing: 8

        Label { text: "Wochen" }
        RowLayout {
            spacing: 8
            WeekField { id: fromField; objectName: "scaleFrom" }
            Label { text: "bis" }
            WeekField { id: toField; objectName: "scaleTo" }
        }

        Label { text: "Werte" }
        RowLayout {
            spacing: 12
            CheckBox { id: whBox; objectName: "scaleWh"; text: "WH"; checked: true }
            CheckBox { id: mhgBox; objectName: "scaleMhg"; text: "MHG"; checked: true }
            CheckBox { id: bwBox; objectName: "scaleBw"; text: "BW"; checked: true }
        }

        Label { text: "Übungen" }
        Label {
            text: dialog.setName + " (wie im Raster)"
        }

        Label { text: "Faktor" }
        RowLayout {
            spacing: 8
            SpinBox {
                id: factor
                objectName: "scaleFactor"
                from: 10
                to: 200
                editable: true
                value: 90
            }
            Label {
                text: factor.value === 100 ? "%, unverändert"
                                           : "%, also " + (factor.value < 100 ? (100 - factor.value) + " % weniger"
                                                                              : (factor.value - 100) + " % mehr")
            }
        }

        Label {
            Layout.columnSpan: 2
            Layout.preferredWidth: 420
            wrapMode: Text.Wrap
            font.pixelSize: 11
            color: Styles.TokenInterface.semantics.text_muted
            text: (dialog.percent ? "MHG und BW werden auf ganze Prozent gerundet"
                                  : "MHG und BW werden auf den Gewichtsschritt gerundet")
                  + ", WH auf ganze Wiederholungen. K1-7 und K1-5 folgen den Komplexen; die Laststufen bleiben, wie sie sind."
        }
        Label {
            Layout.columnSpan: 2
            visible: dialog.error !== "" || (fromField.monday !== "" && toField.monday !== "" && !dialog.valid)
            color: Styles.TokenInterface.semantics.danger_default
            text: dialog.error !== "" ? dialog.error
                  : !(whBox.checked || mhgBox.checked || bwBox.checked) ? "Bitte mindestens einen Wert wählen."
                  : "Bitte Wochen im Zeitraum des Plans wählen."
        }
    }

    footer: DialogButtons {
        Button {
            text: "Abbrechen"
            DialogButtonBox.buttonRole: DialogButtonBox.RejectRole
            onClicked: dialog.close()
        }
        Button {
            objectName: "scaleApply"
            text: "Skalieren"
            enabled: dialog.valid
            DialogButtonBox.buttonRole: DialogButtonBox.AcceptRole
            onClicked: dialog.apply()
        }
    }
}
