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
    }
}
