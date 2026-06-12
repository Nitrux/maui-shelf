import QtQuick.Controls

import org.mauikit.controls as Maui

Maui.SettingsDialog
{
    id: control

    Maui.Controls.title: i18n("Shortcuts")

    Maui.SectionGroup
    {
        title: i18n("Reader")

        Maui.FlexSectionItem
        {
            label1.text: i18n("Back to Browser")

            Maui.ToolActions
            {
                checkable: false
                autoExclusive: false
                Action { text: "Alt" }
                Action { text: i18n("Left") }
            }
        }

        Maui.FlexSectionItem
        {
            label1.text: i18n("Close Tab")

            Maui.ToolActions
            {
                checkable: false
                autoExclusive: false
                Action { text: "Ctrl" }
                Action { text: "W" }
            }
        }

        Maui.FlexSectionItem
        {
            label1.text: i18n("Previous Tab")

            Maui.ToolActions
            {
                checkable: false
                autoExclusive: false
                Action { text: "Ctrl" }
                Action { text: "Shift" }
                Action { text: "Tab" }
            }
        }

        Maui.FlexSectionItem
        {
            label1.text: i18n("Next Tab")

            Maui.ToolActions
            {
                checkable: false
                autoExclusive: false
                Action { text: "Ctrl" }
                Action { text: "Tab" }
            }
        }

        Maui.FlexSectionItem
        {
            label1.text: i18n("Fullscreen")

            Maui.ToolActions
            {
                checkable: false
                autoExclusive: false
                Action { text: "F11" }
            }
        }
    }

    Maui.SectionGroup
    {
        title: i18n("Document")

        Maui.FlexSectionItem
        {
            label1.text: i18n("Previous Page")

            Maui.ToolActions
            {
                checkable: false
                autoExclusive: false
                Action { text: "Page" }
                Action { text: i18n("Up") }
            }
        }

        Maui.FlexSectionItem
        {
            label1.text: i18n("Next Page")

            Maui.ToolActions
            {
                checkable: false
                autoExclusive: false
                Action { text: "Page" }
                Action { text: i18n("Down") }
            }
        }

        Maui.FlexSectionItem
        {
            label1.text: i18n("First Page")

            Maui.ToolActions
            {
                checkable: false
                autoExclusive: false
                Action { text: "Home" }
            }
        }

        Maui.FlexSectionItem
        {
            label1.text: i18n("Last Page")

            Maui.ToolActions
            {
                checkable: false
                autoExclusive: false
                Action { text: "End" }
            }
        }

        Maui.FlexSectionItem
        {
            label1.text: i18n("Toggle Contents")

            Maui.ToolActions
            {
                checkable: false
                autoExclusive: false
                Action { text: "F4" }
            }
        }

        Maui.FlexSectionItem
        {
            label1.text: i18n("Search")

            Maui.ToolActions
            {
                checkable: false
                autoExclusive: false
                Action { text: "Ctrl" }
                Action { text: "F" }
            }
        }

        Maui.FlexSectionItem
        {
            label1.text: i18n("Zoom Out")

            Maui.ToolActions
            {
                checkable: false
                autoExclusive: false
                Action { text: "Ctrl" }
                Action { text: "-" }
            }
        }

        Maui.FlexSectionItem
        {
            label1.text: i18n("Zoom In")

            Maui.ToolActions
            {
                checkable: false
                autoExclusive: false
                Action { text: "Ctrl" }
                Action { text: "+" }
            }
        }

        Maui.FlexSectionItem
        {
            label1.text: i18n("Browse Horizontally")

            Maui.ToolActions
            {
                checkable: false
                autoExclusive: false
                Action { text: "F6" }
            }
        }
    }
}
