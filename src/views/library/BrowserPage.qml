import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

import org.mauikit.controls as Maui
import org.mauikit.filebrowsing as FB
import org.mauikit.documents as Poppler

import org.maui.shelf as Shelf

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
        }
    ]

    middleContent: Maui.SearchField
    {
        Layout.fillWidth: true
        Layout.maximumWidth: 500
        Layout.alignment: Qt.AlignCenter
        placeholderText: i18n("Filter...")
        onAccepted: _browser.model.filter = text
        onCleared: _libraryModel.clearFilters()
    }

    rightContent: [
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

    Maui.AltBrowser
    {
        id: _browser
        anchors.fill: parent
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
