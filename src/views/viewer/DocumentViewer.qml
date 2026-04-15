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

    property var _openPaths: ({})

    function closeTab(index)
    {
        if (index < 0)
            return

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

        if (_tabView.count === 0 && viewerView.active)
            toggleViewer()
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

    Shortcut
    {
        sequence: "Ctrl+W"
        context: Qt.WindowShortcut
        enabled: viewerView.active && _tabView.count > 0
        onActivated: control.closeTab(_tabView.currentIndex)
    }

    Maui.TabView
    {
        id: _tabView
        anchors.fill: parent

        Maui.Controls.showCSD: control.Maui.Controls.showCSD
        onCloseTabClicked: (index) => control.closeTab(index)
        tabBar.visible: true
        tabBar.showNewTabButton: false
        tabBarMargins: Maui.Style.defaultPadding
        holder.title: i18n("Nothing here")
        holder.body: i18n("Open a document file to view it")
        holder.emoji: "folder-open"

        tabViewButton: Component
        {
            Maui.TabViewButton
            {
                id: _tabButton
                tabView: _tabView
                closeButtonVisible: !_tabView.mobile

                onClicked: _tabView.setCurrentIndex(_tabButton.mindex)

                onRightClicked: {} // suppress useless platform/accessibility menu

                onCloseClicked: _tabView.closeTabClicked(_tabButton.mindex)
            }
        }

        tabBar.leftContent: [
            ToolButton
            {
                icon.name: "go-previous"
                display: ToolButton.IconOnly
                Maui.Controls.toolTipText: i18n("Back to browser")
                onClicked: toggleViewer()
            },

            ToolSeparator
            {
                topPadding: 10
                bottomPadding: 10
            }
        ]

        tabBar.rightContent: [

            ToolSeparator
            {
                topPadding: 10
                bottomPadding: 10
            },

            Loader
            {
                asynchronous: true
                sourceComponent: Maui.ToolButtonMenu
                {
                    icon.name: "overflow-menu"

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

        PdfViewer
        {
            Maui.Controls.title: title
            Maui.Controls.toolTipText: path
        }
    }

    Component
    {
        id: _txtComponent

        TextViewer
        {
            Maui.Controls.title: title
            Maui.Controls.toolTipText: path
        }
    }

    Component
    {
        id: _epubComponent

        EpubViewer
        {
            Maui.Controls.title: title
            Maui.Controls.toolTipText: path
        }
    }

    Component
    {
        id: _CBComponent

        ComicViewer
        {
            Maui.Controls.title: title
            Maui.Controls.toolTipText: path

            onGoBackTriggered: _stackView.pop()
        }
    }

    function open(path)
    {
        if (path.indexOf("://") < 0)
            path = "file://" + path

        if (!FB.FM.fileExists(path))
            return

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

        _openPaths[path] = _tabView.currentIndex
    }
}
