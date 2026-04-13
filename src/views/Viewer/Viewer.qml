import QtQuick
import QtQuick.Controls
import QtQuick.Window

import org.mauikit.controls as Maui
import org.mauikit.filebrowsing as FB

import org.maui.shelf as Shelf

Item
{
    id: control

    readonly property string currentPath : _tabView.currentItem ? _tabView.currentItem.path : ""
    readonly property alias currentViewer: _tabView.currentItem
    readonly property alias tabView : _tabView
    readonly property string title : _tabView.currentItem ? _tabView.currentItem.title : ""

    // Maps file path → tab index so we can switch to an already-open document
    // rather than opening it again. Updated in open() and onCloseTabClicked.
    property var _openPaths: ({})
    //    onGoBackTriggered: _stackView.pop()

    Component
    {
        id: _doodleComponent
        Maui.Doodle
        {
            sourceItem: currentViewer.currentItem
            hint: 1
            onClosed: destroy()
        }
    }

    Loader
    {
        anchors.fill: parent
        active: !currentViewer
        visible: active
        asynchronous: true

        sourceComponent: Maui.Holder
        {
            emoji: "qrc:/assets/draw-watercolor.svg"
            title : i18n("Nothing here")
            body: i18n("Drop or open a document to view.")
        }
    }

    Maui.TabView
    {
        id: _tabView
        anchors.fill: parent

        Maui.Controls.showCSD: control.Maui.Controls.showCSD
        onCloseTabClicked:
        {
            // Remove the closing entry, shift down every index above it,
            // and remove the document from the Continue Reading list.
            var closing = index
            var updated = {}
            var closingPath = ""
            for (var p in _openPaths)
            {
                var i = _openPaths[p]
                if (i === closing) { closingPath = p; continue }
                updated[p] = i > closing ? i - 1 : i
            }
            _openPaths = updated
            if (closingPath)
                Shelf.ReadingProgress.removeFromRecent(closingPath)
            _tabView.closeTab(closing)
        }
        tabBar.visible: true
        tabBar.showNewTabButton: false
        tabBarMargins: Maui.Style.defaultPadding
        holder.title: i18n("Nothing here")
        holder.body: i18n("Open a document file to view it")
        holder.emoji: "folder-open"

        tabBar.leftContent: ToolButton
        {
            icon.name: "go-previous"
            display: ToolButton.IconOnly
            Maui.Controls.toolTipText: i18n("Back to browser")
            onClicked: toggleViewer()
        }

        onCurrentIndexChanged: console.log("VIEWER CURRENT INDEX CHANGED", currentIndex)

        tabBar.rightContent: [

            Loader
            {
                asynchronous: true
                sourceComponent: Maui.ToolButtonMenu
                {
                    icon.name: "overflow-menu"

                    Maui.MenuItemActionRow
                    {
                        Action
                        {
                            icon.name: "tool_pen"
                            text: i18n("Doodle")

                            onTriggered:
                            {
                                var dialog = _doodleComponent.createObject(root)
                                dialog.open()
                            }
                        }

                        Action
                        {
                            icon.name: "document-share"
                            text: i18n("Share")

                            onTriggered:
                            {
                                Maui.Platform.shareFiles([control.currentPath])
                            }
                        }
                    }

                    MenuSeparator {}

                    MenuItem
                    {
                        icon.name: "view-right-new"
                        text: i18n("Browse Horizontally")

                        checkable: true
                        checked:  currentViewer.orientation === ListView.Horizontal
                        onClicked:
                        {
                            currentViewer.orientation = currentViewer.orientation === ListView.Horizontal ? ListView.Vertical : ListView.Horizontal
                        }
                    }

                    //            MenuItem
                    //            {
                    //                icon.name:  "zoom-fit-width"
                    //                text: i18n("Fill")
                    //                checkable: true
                    //                checked: currentViewer.fitWidth
                    //                onTriggered:
                    //                {
                    //                    currentViewer.fitWidth= !currentViewer.fitWidth
                    //                }
                    //            }

                    MenuItem
                    {
                        text: i18n("Fullscreen")
                        checkable: true
                        checked: root.visibility === Window.FullScreen
                        icon.name: "view-fullscreen"
                        onTriggered: root.visibility = (root.visibility === Window.FullScreen  ? Window.Windowed : Window.FullScreen)
                    }
                }
            }
        ]
    }

    Component
    {
        id: _pdfComponent

        Viewer_PDF
        {
            Maui.Controls.title: title
            Maui.Controls.toolTipText: path
        }
    }

    Component
    {
        id: _txtComponent

        Viewer_TXT {}
    }

    Component
    {
        id: _epubComponent

        Viewer_EPUB {}
    }

    Component
    {
        id: _CBComponent

        Viewer_CB
        {
            Maui.Controls.title: title
            Maui.Controls.toolTipText: path

            onGoBackTriggered: _stackView.pop()
        }
    }

    function open(path)
    {
        // Normalise to file:// URL so the _openPaths key always matches
        // regardless of whether the caller passed a local path or a URL.
        if (path.indexOf("://") < 0)
            path = "file://" + path

        if (!FB.FM.fileExists(path))
            return

        // If the document is already open, switch to its tab instead
        if (_openPaths.hasOwnProperty(path))
        {
            _tabView.currentIndex = _openPaths[path]
            if (!viewerView.active)
                toggleViewer()
            return
        }

        if (!viewerView.active)
            toggleViewer()

        if (Shelf.Library.isPDF(path))
            _tabView.addTab(_pdfComponent, {'path': path})
        else if (Shelf.Library.isPlainText(path))
            _tabView.addTab(_txtComponent, {'path': path})
        else if (Shelf.Library.isEpub(path))
            _tabView.addTab(_epubComponent, {'path': path})
        else if (Shelf.Library.isCommicBook(path))
            _tabView.addTab(_CBComponent, {'path': path})
        else
            return

        // Record the new tab's index (addTab makes it current)
        _openPaths[path] = _tabView.currentIndex
    }
}
