import QtQuick

import org.mauikit.controls as Maui

import org.maui.shelf as Shelf

Maui.Page
{
    id: control

    property string path

    readonly property string title:
    {
        if (path.length === 0)
            return ""

        var lastSlash = path.lastIndexOf("/")
        var fileName = lastSlash >= 0 ? path.substring(lastSlash + 1) : path
        var lastDot = fileName.lastIndexOf(".")
        return lastDot > 0 ? fileName.substring(0, lastDot) : fileName
    }

    headBar.visible: false

    Component.onCompleted: Shelf.ReadingProgress.markOpened(control.path)

    Maui.Holder
    {
        anchors.fill: parent
        emoji: "book-open"
        title: i18n("EPUB support is unavailable")
        body: i18n("Shelf does not currently provide an EPUB reader.")
    }
}
