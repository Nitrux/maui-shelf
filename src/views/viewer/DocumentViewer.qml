import QtQuick
import QtQuick.Controls
import QtQuick.Window

import org.mauikit.controls as Maui
import org.mauikit.filebrowsing as FB
import org.mauikit.documents as Docs

import org.maui.shelf as Shelf

Item
{
    id: control

    readonly property string currentPath : _tabView.currentItem ? _tabView.currentItem.path : ""
    readonly property alias currentViewer: _tabView.currentItem
    readonly property alias tabView : _tabView
    readonly property bool hasOpenTabs: !!_tabView.currentItem
    readonly property string title : _tabView.currentItem ? _tabView.currentItem.title : ""
    property bool suppressHolderWhileExiting: false
    readonly property int _stackStatus: StackView.status

    function tabPath(index)
    {
        if (index < 0 || index >= _tabView.count || !_tabView.contentModel)
            return ""

        var tab = _tabView.contentModel.get(index)
        return tab && tab.path ? tab.path : ""
    }

    function indexOfPath(path)
    {
        if (!_tabView.contentModel)
            return -1

        for (var i = 0; i < _tabView.count; i++)
        {
            if (tabPath(i) === path)
                return i
        }

        return -1
    }

    function closeTab(index)
    {
        if (index < 0)
            return

        const closingLastVisibleTab = (_tabView.count === 1 && viewerView.active)

        var closingPath = tabPath(index)
        if (closingPath)
            Shelf.ReadingProgress.removeFromRecent(closingPath)

        if (closingLastVisibleTab)
        {
            suppressHolderWhileExiting = true

            // Keep the last tab alive during the navigation transition so the
            // TabView holder does not flash for a frame.
            toggleViewer()

            Qt.callLater(() =>
            {
                if (_tabView.count !== 1)
                    return

                if (_tabView.contentModel && typeof _tabView.contentModel.remove === "function")
                {
                    _tabView.contentModel.remove(0, 1)
                    _tabView.currentIndex = -1
                }
                else
                {
                    _tabView.closeTab(0)
                }

                control.suppressHolderWhileExiting = false
            })

            return
        }

        // Maui.TabView.closeTab() tries to focus currentItem after removal.
        // When closing the last tab currentItem becomes null, so remove it
        // directly from the model to avoid that null-focus path.
        if (_tabView.count === 1 && _tabView.contentModel && typeof _tabView.contentModel.remove === "function")
        {
            _tabView.contentModel.remove(index, 1)
            if (_tabView.count === 0)
            {
                _tabView.currentIndex = -1
            }
            else
            {
                _tabView.closeTab(index)
            }
        }
        else
        {
            _tabView.closeTab(index)
        }

        if (_tabView.count === 0 && viewerView.active)
            Qt.callLater(() =>
            {
                if (_tabView.count === 0 && viewerView.active)
                    toggleViewer()
            })
    }

    function prepareForShutdown()
    {
        suppressHolderWhileExiting = true
        _tabView.tabBar.visible = false

        if (!_tabView.contentModel || typeof _tabView.contentModel.remove !== "function")
            return

        while (_tabView.count > 0)
            _tabView.contentModel.remove(_tabView.count - 1, 1)

        _tabView.currentIndex = -1
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
        showDefaultMenuEntries: false
        onCloseTabClicked: (index) => control.closeTab(index)
        tabBar.visible: true
        tabBar.showNewTabButton: false
        tabBarMargins: Maui.Style.defaultPadding
        holder.visible: !_tabView.count && !control.suppressHolderWhileExiting && control._stackStatus !== StackView.Deactivating
        holder.title: i18n("Nothing here")
        holder.body: i18n("Open a document file to view it")
        holder.emoji: "folder-open"

        tabViewButton: Maui.TabButton
        {
            id: _tabButton
            property Item tabView: _tabView
            // Keep a stable fallback index from the Repeater context.
            property int delegateIndex: (typeof index != "undefined" && index >= 0) ? index : -1
            readonly property int mindex:
                ((typeof _tabButton.TabBar.index !== "undefined" && _tabButton.TabBar.index >= 0)
                    ? _tabButton.TabBar.index
                    : (_tabButton.delegateIndex >= 0
                        ? _tabButton.delegateIndex
                        : ((typeof index !== "undefined" && index >= 0) ? index : -1)))
            // Force reevaluation of model-derived bindings after tab moves.
            readonly property int _modelPulse: _tabButton.tabView ? (_tabButton.tabView.currentIndex + _tabButton.tabView.count) : 0
            readonly property var tabInfo:
            {
                const _pulse = _tabButton._modelPulse
                const item = tabView && tabView.contentModel && mindex >= 0 ? tabView.contentModel.get(mindex) : null
                return item && item.Maui && item.Maui.Controls ? item.Maui.Controls : ({})
            }
            readonly property var _tabMenuActions:
            {
                const actions = []
                if (_tabButton.mindex > 0)
                    actions.push(_moveTabLeftAction)
                if (_tabButton.mindex >= 0 && _tabButton.mindex < (_tabButton.tabView.count - 1))
                    actions.push(_moveTabRightAction)
                return actions
            }

            autoExclusive: true
            width: tabView.mobile ? ListView.view.width : Math.max(160, Math.min(260, implicitWidth))
            checked: mindex === tabView.currentIndex
            text: tabInfo.title || ""
            icon.name: tabInfo.iconName || ""
            Maui.Controls.badgeText: tabInfo.badgeText
            Maui.Controls.status: tabInfo.status

            onClicked:
            {
                if (_tabButton.mindex < 0)
                    return

                _tabView.setCurrentIndex(_tabButton.mindex)
                if (_tabView.currentItem)
                    _tabView.currentItem.forceActiveFocus()
            }

            onRightClicked:
            {
                if (_tabButton._tabMenuActions.length > 0)
                {
                    _tabMenu.show()
                }
            }

            onCloseClicked:
            {
                if (_tabButton.mindex >= 0)
                    _tabView.closeTabClicked(_tabButton.mindex)
            }

            Action
            {
                id: _moveTabLeftAction
                text: i18n("Move Left")
                icon.name: "go-previous"
                onTriggered:
                {
                    const from = _tabButton.mindex
                    if (from > 0)
                        _tabView.moveTab(from, from - 1)
                }
            }

            Action
            {
                id: _moveTabRightAction
                text: i18n("Move Right")
                icon.name: "go-next"
                onTriggered:
                {
                    const from = _tabButton.mindex
                    if (from >= 0 && from < (_tabView.count - 1))
                        _tabView.moveTab(from, from + 1)
                }
            }

            Maui.ContextualMenu
            {
                id: _tabMenu

                Repeater
                {
                    model: _tabButton._tabMenuActions
                    delegate: MenuItem
                    {
                        action: modelData
                    }
                }
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
            },

            ToolButton
            {
                text: _tabView.count
                visible: _tabView.count > 1
                display: ToolButton.TextOnly
                font.bold: true
                font.pointSize: Maui.Style.fontSizes.small
                onClicked: _tabView.openOverview()
                background: Rectangle
                {
                    color: Maui.Theme.alternateBackgroundColor
                    radius: Maui.Style.radiusV
                }
            },

            ToolSeparator
            {
                visible: _tabView.count > 1
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
                        enabled: !!currentViewer && currentViewer.hasOwnProperty("orientation")
                        checked: enabled && currentViewer.orientation === ListView.Horizontal
                        onClicked:
                        {
                            if (!enabled)
                                return

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

        Docs.ComicViewer
        {
            Maui.Controls.title: title
            Maui.Controls.toolTipText: path
        }
    }

    function open(path)
    {
        if (path.indexOf("://") < 0)
            path = "file://" + path

        if (!FB.FM.fileExists(path))
            return

        const openIndex = indexOfPath(path)
        if (openIndex >= 0)
        {
            _tabView.currentIndex = openIndex
            if (!viewerView.active)
                toggleViewer()
            return
        }

        if (!viewerView.active)
            toggleViewer()

        if (Shelf.Library.isPDF(path))
            _tabView.addTab(_pdfComponent, {'path': path})
        else if (Shelf.Library.isEpub(path))
            _tabView.addTab(_epubComponent, {'path': path})
        else if (Shelf.Library.isCommicBook(path))
            _tabView.addTab(_CBComponent, {'path': path})
        else
            return

        Shelf.ReadingProgress.markOpened(path)
    }
}
