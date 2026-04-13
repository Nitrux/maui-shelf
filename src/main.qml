import QtQuick
import QtCore
import QtQuick.Controls

import org.mauikit.controls as Maui
import org.mauikit.filebrowsing as FB
import org.mauikit.documents as Poppler

import org.maui.shelf as Shelf

import "views"
import "views/library/"
import "views/Viewer/"

Maui.ApplicationWindow
{
    id: root
    title: viewerView.title.length > 0 ? viewerView.title + " - " + i18n("Shelf") : i18n("Shelf")

    color: "transparent"
    background: null

    Settings
    {
        id: appSettings
        property bool autoScan : true
        property bool showThumbnails: true
        property int viewType : Maui.AltBrowser.ViewType.Grid
    }

    Component
    {
        id: _settingsDialogComponent

        SettingsDialog
        {
            onClosed: destroy()
        }
    }

    Component
    {
        id: _fileDialog
        FB.FileDialog
        {
            mode: FB.FileDialog.Open
            onClosed: destroy()
        }
    }

    Maui.WindowBlur
    {
        view: root
        geometry: Qt.rect(0, 0, root.width, root.height)
        windowRadius: Maui.Style.radiusV
        enabled: true
    }

    Rectangle
    {
        anchors.fill: parent
        color: Maui.Theme.backgroundColor
        opacity: 0.76
        radius: Maui.Style.radiusV
        border.color: Qt.rgba(1, 1, 1, 0)
        border.width: 1
    }

    StackView
    {
        id: _stackView
        anchors.fill: parent
        background: null

        initialItem: initModule === "viewer" ? viewerView : browserPageComponent

        Viewer
        {
            id: viewerView
            readonly property bool active : StackView.status === StackView.Active
            Maui.Controls.showCSD: true
            clip: true
        }

        Component
        {
            id: browserPageComponent

            BrowserPage
            {
                viewerSettings: appSettings
                windowRoot: root
                Maui.Controls.showCSD: true
                clip: true
                onOpenFileRequested: (path) => viewerView.open(path)
            }
        }
    }

    Connections
    {
        target: Shelf.Library
        ignoreUnknownSignals: true

        function onRequestedFiles(files)
        {
            for (var file of files)
                viewerView.open(file)
        }
    }

    function openSettingsDialog()
    {
        var dialog = _settingsDialogComponent.createObject(root)
        dialog.open()
    }

    function toggleViewer()
    {
        if (viewerView.active)
        {
            if (_stackView.depth === 1)
            {
                _stackView.replace(viewerView, browserPageComponent)
            }
            else
            {
                _stackView.pop()
            }
        }
        else
        {
            _stackView.push(viewerView)
        }

        _stackView.currentItem.forceActiveFocus()
    }
}
