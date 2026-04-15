import QtQuick
import QtQuick.Controls

import org.mauikit.controls as Maui

import org.maui.shelf as Shelf

Maui.Page
{
    id: control

    property string path
    property int currentPage: _textArea.cursorPosition

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

    Menu
    {
        id: _contextMenu

        MenuItem
        {
            text: i18n("Copy")
            enabled: _textArea.selectedText.length > 0
            onTriggered: _textArea.copy()
        }

        MenuItem
        {
            text: i18n("Select All")
            onTriggered: _textArea.selectAll()
        }
    }

    ScrollView
    {
        anchors.fill: parent
        clip: true

        TextArea
        {
            id: _textArea
            readOnly: true
            selectByMouse: true
            wrapMode: TextEdit.NoWrap
            textFormat: TextEdit.PlainText
            font.family: "monospace"
            leftPadding: Maui.Style.space.medium
            rightPadding: Maui.Style.space.medium
            topPadding: Maui.Style.space.medium
            bottomPadding: Maui.Style.space.medium
            background: null
            text: control.path.length > 0 ? Shelf.Library.readTextFile(control.path) : ""
        }

        TapHandler
        {
            acceptedButtons: Qt.RightButton
            onTapped: (eventPoint) => _contextMenu.popup(eventPoint.position.x, eventPoint.position.y)
        }
    }

    Component.onCompleted: Shelf.ReadingProgress.markOpened(control.path)
}
