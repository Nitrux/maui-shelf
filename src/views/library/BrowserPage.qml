import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

import org.mauikit.controls as Maui
import org.mauikit.filebrowsing as FB
import org.mauikit.documents as Poppler

import org.maui.shelf as Shelf

// ── Internal model for the active collection filter ──────────────────────────
// sources are set by the filter TabBar below; defaults to "collection:///".

Maui.PageLayout
{
    id: root

    required property var viewerSettings
    required property var windowRoot

    signal openFileRequested(string path)

    background: null
    altHeader: Maui.Handy.isMobile
    headerMargins: Maui.Style.defaultPadding

    property bool selectionMode: false

    LibraryMenu
    {
        id: _menu
        index: _browser.currentIndex
        model: _libraryModel
    }

    // ── Continue Reading section ──────────────────────────────────────────
    // Shown as a floating strip at the top of the scroll area when there are
    // recently opened files tracked by ReadingProgress.
    Component
    {
        id: _continueReadingComponent

        Item
        {
            id: _continueReading
            implicitHeight: _recentLabel.implicitHeight
                            + Maui.Style.space.small
                            + _recentList.implicitHeight
                            + Maui.Style.space.medium

            Label
            {
                id: _recentLabel
                anchors.top: parent.top
                anchors.left: parent.left
                anchors.leftMargin: Maui.Style.space.medium
                anchors.topMargin: Maui.Style.space.small
                text: i18n("Continue Reading")
                font.bold: true
                opacity: 0.7
            }

            ListView
            {
                id: _recentList
                anchors.top: _recentLabel.bottom
                anchors.topMargin: Maui.Style.space.small
                anchors.left: parent.left
                anchors.right: parent.right
                implicitHeight: 160
                clip: true
                orientation: ListView.Horizontal
                spacing: Maui.Style.space.medium
                leftMargin: Maui.Style.space.medium
                rightMargin: Maui.Style.space.medium

                model: Shelf.ReadingProgress.recentFiles

                delegate: Maui.GridBrowserDelegate
                {
                    height: _recentList.height
                    width: 148

                    imageSource: viewerSettings.showThumbnails ? (modelData.preview || "") : ""
                    iconSource: modelData.icon || "application-pdf"
                    iconSizeHint: Maui.Style.iconSizes.big
                    imageHeight: 80
                    imageWidth: 148

                    label1.text: modelData.label || ""
                    label2.text: modelData.page > 0
                                 ? (modelData.totalPages > 0
                                    ? i18n("p. %1 / %2", modelData.page + 1, modelData.totalPages)
                                    : i18n("p. %1", modelData.page + 1))
                                 : ""
                    template.fillMode: Image.PreserveAspectFit
                    template.labelSizeHint: 28

                    onClicked: root.openFileRequested(modelData.url || modelData.path)
                }
            }

            Connections
            {
                target: Shelf.ReadingProgress
                function onRecentFilesChanged()
                {
                    _recentList.model = Shelf.ReadingProgress.recentFiles
                }
            }
        }
    }

    leftContent: [
        Maui.ToolButtonMenu
        {
            icon.name: viewerSettings.viewType === Maui.AltBrowser.ViewType.List ? "view-list-details" : "view-list-icons"

            MenuItem
            {
                text: i18n("List")
                checkable: true
                icon.name: "view-list-details"
                checked: viewerSettings.viewType === Maui.AltBrowser.ViewType.List
                onTriggered: viewerSettings.viewType = Maui.AltBrowser.ViewType.List
            }

            MenuItem
            {
                text: i18n("Grid")
                checkable: true
                icon.name: "view-list-icons"
                checked: viewerSettings.viewType === Maui.AltBrowser.ViewType.Grid
                onTriggered: viewerSettings.viewType = Maui.AltBrowser.ViewType.Grid
            }

            MenuSeparator {}

            MenuItem
            {
                text: i18n("Title")
                checkable: true
                checked: _libraryModel.sort === "label"
                onTriggered: _libraryModel.sort = "label"
            }

            MenuItem
            {
                text: i18n("Date")
                checkable: true
                checked: _libraryModel.sort === "modified"
                onTriggered: _libraryModel.sort = "modified"
            }

            MenuItem
            {
                text: i18n("Size")
                checkable: true
                checked: _libraryModel.sort === "size"
                onTriggered: _libraryModel.sort = "size"
            }

            MenuSeparator {}

            MenuItem
            {
                text: i18n("Ascending")
                checked: _libraryModel.sortOrder === Qt.AscendingOrder
                onTriggered: _libraryModel.sortOrder = Qt.AscendingOrder
            }

            MenuItem
            {
                text: i18n("Descending")
                checked: _libraryModel.sortOrder === Qt.DescendingOrder
                onTriggered: _libraryModel.sortOrder = Qt.DescendingOrder
            }
        },

        ToolSeparator
        {
            bottomPadding: 10
            topPadding: 10
        },

        Maui.SearchField
        {
            placeholderText: i18n("Filter...")
            implicitWidth: 200
            onAccepted: _browser.model.filter = text
            onCleared: _libraryModel.clearFilters()
        }
    ]

    rightContent: [

        Label
        {
            text: i18n("Show")
            font.weight: Font.DemiBold
            verticalAlignment: Text.AlignVCenter
        },

        ComboBox
        {
            id: _typeFilter
            implicitWidth: 120

            model: [i18n("All"), i18n("PDFs"), i18n("Comics"), i18n("Text")]

            readonly property var _sources: [
                ["collection:///"],
                ["documents:///"],
                ["comics:///"],
                ["text:///"]
            ]

            onActivated: (idx) => _libraryList.sources = _sources[idx]
        },

        ToolSeparator
        {
            bottomPadding: 10
            topPadding: 10
        },

        Maui.ToolButtonMenu
        {
            icon.name: "overflow-menu"

            MenuItem
            {
                text: i18n("Preferences")
                icon.name: "settings-configure"
                onTriggered: windowRoot.openSettingsDialog()
            }

            MenuItem
            {
                text: i18n("About")
                icon.name: "documentinfo"
                onTriggered: windowRoot.about()
            }
        }
    ]

    // Root layout that stacks the continue-reading strip and the browser
    ColumnLayout
    {
        anchors.fill: parent
        spacing: 0

        // ── Continue Reading strip (only when recent files exist) ─────────
        Loader
        {
            id: _continueLoader
            Layout.fillWidth: true
            active: Shelf.ReadingProgress.recentFiles.length > 0
            visible: active
            asynchronous: true
            sourceComponent: _continueReadingComponent

            Connections
            {
                target: Shelf.ReadingProgress
                function onRecentFilesChanged()
                {
                    _continueLoader.active = Shelf.ReadingProgress.recentFiles.length > 0
                }
            }
        }

        // Thin separator below the strip when it is visible
        Rectangle
        {
            visible: _continueLoader.active && _continueLoader.status === Loader.Ready
            Layout.fillWidth: true
            height: 1
            color: Maui.Theme.separatorColor
        }

        // ── Main browser ──────────────────────────────────────────────────
        Maui.AltBrowser
        {
            id: _browser
            Layout.fillWidth: true
            Layout.fillHeight: true
            background: null
            headBar.visible: false
            viewType: viewerSettings.viewType
        enableLassoSelection: true
        gridView.itemSize: Math.min(180, Math.floor(gridView.availableWidth / 3))
        gridView.itemHeight: 220

        Connections
        {
            target: _browser.currentView
            function onItemsSelected(indexes)
            {
                for (var i in indexes)
                {
                    const item = _browser.model.get(indexes[i])
                    _selectionbar.append(item.path, item)
                }
            }
        }

        holder.visible: _browser.count === 0
        holder.title: i18n("Nothing here!")
        holder.body: i18n("Add sources to manage your documents.")
        holder.emoji: "qrc:/assets/document-new.svg"
        holder.actions: [
            Action
            {
                text: i18n("Add sources")
                onTriggered: windowRoot.openSettingsDialog()
            }
        ]

        model: Maui.BaseModel
        {
            id: _libraryModel
            sort: "modified"
            sortOrder: Qt.DescendingOrder
            recursiveFilteringEnabled: true
            sortCaseSensitivity: Qt.CaseInsensitive
            filterCaseSensitivity: Qt.CaseInsensitive
            list: Shelf.LibraryList
            {
                id: _libraryList
            }
        }

        gridDelegate: Item
        {
            height: GridView.view.cellHeight
            width: GridView.view.cellWidth

            Maui.GridBrowserDelegate
            {
                id: _gridTemplate
                anchors.fill: parent
                anchors.margins: !windowRoot.isWide ? Maui.Style.space.tiny : Maui.Style.space.big
                imageHeight: _browser.gridView.itemSize
                imageWidth: _browser.gridView.itemSize
                isCurrentItem: parent.GridView.isCurrentItem || checked
                label1.text: model.label
                label2.text: Maui.Handy.formatSize(model.size)
                imageSource: viewerSettings.showThumbnails ? model.preview : ""
                iconSource: model.icon
                iconSizeHint: Maui.Style.iconSizes.huge
                template.labelSizeHint: 32
                template.fillMode: Image.PreserveAspectFit
                checkable: root.selectionMode
                checked: _selectionbar.contains(model.path)
                onToggled: _selectionbar.append(model.path, _browser.model.get(index))

                Connections
                {
                    target: _selectionbar
                    function onUriRemoved(uri)
                    {
                        if (uri === model.path)
                            _gridTemplate.checked = false
                    }

                    function onUriAdded(uri)
                    {
                        if (uri === model.path)
                            _gridTemplate.checked = true
                    }

                    function onCleared()
                    {
                        _gridTemplate.checked = false
                    }
                }

                onClicked: (mouse) =>
                {
                    _browser.currentIndex = index
                    const item = _browser.model.get(_browser.currentIndex)

                    if (root.selectionMode || (mouse.button === Qt.LeftButton && (mouse.modifiers & Qt.ControlModifier)))
                    {
                        _selectionbar.append(item.path, item)
                    }
                    else if (Maui.Handy.singleClick)
                    {
                        root.openFileRequested(item.url)
                    }
                }

                onDoubleClicked:
                {
                    _browser.currentIndex = index
                    if (!Maui.Handy.singleClick && !root.selectionMode)
                    {
                        const item = _browser.model.get(_browser.currentIndex)
                        root.openFileRequested(item.url)
                    }
                }

                onPressAndHold:
                {
                    _browser.currentIndex = index
                    _menu.show()
                }

                onRightClicked:
                {
                    _browser.currentIndex = index
                    _menu.show()
                }
            }
        }

        listDelegate: Maui.ListBrowserDelegate
        {
            id: _listDelegate
            isCurrentItem: ListView.isCurrentItem || checked
            height: Math.floor(Maui.Style.rowHeight * 1.6)
            width: ListView.view.width
            label1.text: model.label
            label2.text: Maui.Handy.formatSize(model.size)
            label3.text: Qt.formatDateTime(new Date(model.modified), "d MMM yyyy")
            imageSource: viewerSettings.showThumbnails ? model.preview : ""
            iconSource: model.icon
            iconSizeHint: Maui.Style.iconSizes.medium
            checkable: root.selectionMode
            checked: _selectionbar.contains(model.path)
            onToggled: _selectionbar.append(model.path, _browser.model.get(index))

            Connections
            {
                target: _selectionbar
                function onUriRemoved(uri)
                {
                    if (uri === model.path)
                        _listDelegate.checked = false
                }

                function onUriAdded(uri)
                {
                    if (uri === model.path)
                        _listDelegate.checked = true
                }

                function onCleared()
                {
                    _listDelegate.checked = false
                }
            }

            onClicked: (mouse) =>
            {
                _browser.currentIndex = index
                const item = _browser.model.get(_browser.currentIndex)

                if (root.selectionMode || (mouse.button === Qt.LeftButton && (mouse.modifiers & Qt.ControlModifier)))
                {
                    _selectionbar.append(item.path, item)
                }
                else if (Maui.Handy.singleClick)
                {
                    root.openFileRequested(item.url)
                }
            }

            onDoubleClicked:
            {
                _browser.currentIndex = index
                if (!Maui.Handy.singleClick && !root.selectionMode)
                {
                    const item = _browser.model.get(_browser.currentIndex)
                    root.openFileRequested(item.url)
                }
            }

            onPressAndHold:
            {
                _browser.currentIndex = index
                _menu.show()
            }

            onRightClicked:
            {
                _browser.currentIndex = index
                _menu.show()
            }
        }
    }

    } // end ColumnLayout

    footer: Maui.SelectionBar
    {
        id: _selectionbar
        anchors.horizontalCenter: parent.horizontalCenter
        width: Math.min(parent.width - (Maui.Style.space.medium * 2), implicitWidth)
        maxListHeight: root.height - Maui.Style.space.medium

        listDelegate: Maui.ListBrowserDelegate
        {
            width: Maui.Style.iconSizes.big + Maui.Style.space.medium
            height: Maui.Style.iconSizes.big + Maui.Style.space.small
            label1.text: ""
            label2.text: ""
            imageSource: viewerSettings.showThumbnails ? model.preview : ""
            iconSource: model.icon
            iconSizeHint: Maui.Style.iconSizes.big
            checked: true
            checkable: true
            background: Item {}
            onToggled: _selectionbar.removeAtIndex(index)
        }

        onExitClicked:
        {
            clear()
            root.selectionMode = false
        }

        Action
        {
            text: ""
            icon.name: "edit-delete"
            Maui.Theme.textColor: Maui.Theme.negativeTextColor
            onTriggered:
            {
                removeFiles(_selectionbar.uris)
                _selectionbar.clear()
                root.selectionMode = false
            }
        }
    }

    function filterSelection(url)
    {
        if (_selectionbar.contains(url))
            return _selectionbar.uris

        return [url]
    }

    function openFolders(paths)
    {
        _libraryList.sources = paths
    }

    function removeFiles(urls)
    {
        _libraryList.removeFiles(urls)
    }

}
