import QtQuick
import QtTest
import Trainingsplaner

// Projects: one database file each. A new one starts empty, another one
// opens in place of the open one, "Speichern unter" works on in a copy,
// and the program comes back to the one it started with.
Item {
    width: 1366
    height: 900

    Component {
        id: mainComponent
        Main {}
    }

    TestCase {
        name: "Projects"
        when: windowShown

        property string original
        property string folder

        function initTestCase() {
            original = Store.databasePath
            folder = original.replace(/[\\/][^\\/]*$/, "")
        }

        function cleanup() {
            compare(Store.openProject(original), "")
        }

        function test_newProjectStartsEmpty() {
            verify(Store.athletes.some(a => a.id === "test_tina"))
            const monday = Store.mondayOf(Store.today())
            Store.copyWeek("test_tina", monday, "plan")
            verify(Store.clipboardLabel !== "")

            compare(Store.newProject(folder + "/leer"), "")
            compare(Store.projectName, "leer")
            verify(Store.databasePath.endsWith("leer.trainingsplaner"))
            compare(Store.athletes.length, 0)
            // The copied week was the other file's
            compare(Store.clipboardLabel, "")
            // The one before is offered to go back to
            verify(Store.recentProjects.some(p => p.name === "qml"))

            const id = Store.saveAthlete({ lastName: "Neu", firstName: "Nina", sex: 1 })
            compare(Store.openProject(original), "")
            verify(Store.athletes.some(a => a.id === "test_tina"))
            verify(!Store.athletes.some(a => a.id === id))
            verify(Store.recentProjects.some(p => p.name === "leer"))

            // The new one is kept
            compare(Store.openProject(folder + "/leer.trainingsplaner"), "")
            compare(Store.athletes.map(a => a.id), [id])
        }

        // A new project never replaces a file
        function test_newProjectNeedsNewName() {
            compare(Store.newProject(folder + "/zweimal"), "")
            compare(Store.openProject(original), "")
            verify(Store.newProject(folder + "/zweimal.trainingsplaner").indexOf("gibt es schon") > 0)
            verify(Store.athletes.some(a => a.id === "test_tina"))
        }

        // What cannot be opened leaves the open project open
        function test_openRefused() {
            verify(Store.openProject(folder + "/fehlt.trainingsplaner").indexOf("gibt es nicht") > 0)
            verify(Store.openProject(folder).indexOf("lässt sich nicht öffnen") >= 0)
            compare(Store.databasePath, original)
            verify(Store.athletes.some(a => a.id === "test_tina"))
        }

        function test_saveAs() {
            const before = Store.athletes.length
            compare(Store.saveProjectAs("file://" + folder + "/kopie"), "")
            compare(Store.projectName, "kopie")
            compare(Store.athletes.length, before)
            // Changes go into the copy only
            const id = Store.saveAthlete({ lastName: "Kopie", firstName: "Karl", sex: 0 })
            compare(Store.openProject(original), "")
            verify(!Store.athletes.some(a => a.id === id))
        }

        // The window follows: its title names the project, the pages show
        // the other file's athletes, a new project brings the welcome dialog
        function test_windowFollows() {
            const w = createTemporaryObject(mainComponent, null)
            verify(w.title.indexOf("qml – ") === 0)
            verify(w.athlete !== "")
            verify(w.switchProject(() => Store.newProject(folder + "/fenster")))
            compare(w.title.indexOf("fenster – "), 0)
            compare(w.athlete, "")
            compare(findChild(w, "weekPage").athleteId, "")
            const id = Store.saveAthlete({ lastName: "Fenster", firstName: "Fritz", sex: 0 })
            compare(w.athlete, id)
            verify(w.switchProject(() => Store.openProject(original)))
            verify(w.athlete !== id && w.athlete !== "")
            compare(findChild(w, "weekPage").athleteId, w.athlete)

            // An error is shown, and the project stays
            verify(!w.switchProject(() => Store.openProject(folder + "/fehlt.trainingsplaner")))
            const error = findChild(w, "projectError")
            tryCompare(error, "opened", true)
            error.close()
            compare(Store.databasePath, original)
        }
    }
}
