import QtQuick

// The roles of the colours in one colour scheme. TokenInterface holds one
// set per scheme, each made of Primitives, and passes on the one in use;
// the control styles and the program's pages only ever use these roles.
QtObject {
    // Text and icons
    property color text_default
    property color text_muted
    property color text_inactive        // tabs that are not chosen
    property color text_on_primary
    property color text_on_danger

    // The accent: filled buttons, selections, the tooltip
    property color primary_default

    property color danger_default       // text and lines
    property color danger_fill          // filled buttons

    // Surfaces
    property color background_default   // the window
    property color background_elevated  // cards, panels, popups
    property color background_muted
    property color background_secondary // secondary buttons
    property color background_accent    // chosen rows, quiet highlights
    property color background_hover     // flat buttons under the pointer

    // Fields: text fields, combo boxes, the chosen tab
    property color field_default
    property color field_hover

    // Outlined buttons
    property color outline_default
    property color outline_hover

    // Lines
    property color stroke_subtle        // panels, separators
    property color stroke_field         // the border of fields
    property color stroke_focus         // keyboard focus
    property color stroke_outline       // outlined buttons
    property color stroke_tab           // the chosen tab

    property color switch_thumb
    property color switch_thumb_checked
    property color scroll_thumb

    // The pickers (date, week, time): the chosen entry and the one under
    // the pointer
    property color picker_chosen
    property color picker_hover

    // The week's session boxes
    property color cell_default
    property color cell_hover
    property color cell_border

    property list<color> chart_series
    property color chart_muted

    property color dim                  // behind a modal dialog
    property color dim_subtle           // behind a dialog that leaves the window usable
    property real shadow_strength
}
