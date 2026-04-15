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

    Component
    {
        id: _continueReadingComponent

        Item
        {
            id: _continueReading
            // implicitHeight drives the outer container's preferred height:
            // label + gap + desired flickable area + bottom margin
            implicitHeight: _recentLabel.implicitHeight
                            + Maui.Style.space.medium
                            + 172
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

            ToolButton
            {
                icon.name: "edit-clear-all"
                text: i18n("Clear")
                display: ToolButton.TextBesideIcon
                anchors.right: parent.right
                anchors.rightMargin: Maui.Style.space.medium
                anchors.verticalCenter: _recentLabel.verticalCenter
                Maui.Controls.toolTipText: i18n("Clear list")
                onClicked: Shelf.ReadingProgress.clearRecent()
            }

            Flickable
            {
                id: _recentList
                anchors.top: _recentLabel.bottom
                anchors.topMargin: Maui.Style.space.medium
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.bottom: parent.bottom
                anchors.bottomMargin: Maui.Style.space.medium
                clip: true
                contentWidth: _recentRow.width + (horizontalPadding * 2)
                contentHeight: height
                boundsBehavior: Flickable.StopAtBounds
                flickableDirection: Flickable.HorizontalFlick
                leftMargin: horizontalPadding
                rightMargin: horizontalPadding

                readonly property int delegateWidth: 148
                readonly property int delegateSpacing: Maui.Style.space.medium
                readonly property int horizontalPadding: Maui.Style.space.medium

                ScrollBar.horizontal: ScrollBar
                {
                    policy: ScrollBar.AsNeeded
                    visible: _recentList.contentWidth > _recentList.width
                }

                Row
                {
                    id: _recentRow
                    x: _recentList.horizontalPadding
                    height: _recentList.height - (_recentList.ScrollBar.horizontal && _recentList.ScrollBar.horizontal.visible ? _recentList.ScrollBar.horizontal.height : 0)
                    spacing: _recentList.delegateSpacing

                    Repeater
                    {
                        model: Shelf.ReadingProgress.recentFiles

                        delegate: Maui.GridBrowserDelegate
                        {
                            required property var modelData

                            height: _recentRow.height
                            width: _recentList.delegateWidth

                            imageSource: viewerSettings.showThumbnails ? (modelData.preview || modelData.thumbnail || "") : ""
                            iconSource: modelData.icon || "application-pdf"
                            iconSizeHint: Maui.Style.iconSizes.big
                            imageHeight: 80
                            imageWidth: _recentList.delegateWidth

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
            placeholderText: i18n("Search...")
            implicitWidth: 200
            onAccepted: _libraryModel.filter = text
            onCleared: _libraryModel.filter = ""
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

    readonly property bool hasRecentFiles: Shelf.ReadingProgress.recentFiles.length > 0
    readonly property int recentSectionPadding: Maui.Style.space.medium
    readonly property int recentSectionHeight: hasRecentFiles
                                              ? Math.min(440, Math.max(156, Math.ceil((_continueLoader.item ? _continueLoader.item.implicitHeight : 220) + (recentSectionPadding * 2))))
                                              : 0

    ColumnLayout
    {
        anchors.fill: parent
        spacing: Maui.Style.space.medium

        Item
        {
            visible: root.hasRecentFiles
            Layout.fillWidth: true
            Layout.preferredHeight: visible ? root.recentSectionHeight : 0
            Layout.minimumHeight: 0
            Layout.maximumHeight: 440
            clip: true

            Rectangle
            {
                anchors.fill: parent
                anchors.leftMargin: Maui.Style.space.medium
                anchors.rightMargin: Maui.Style.space.medium
                anchors.topMargin: Maui.Style.space.small
                anchors.bottomMargin: Maui.Style.space.small
                radius: Maui.Style.radiusV
                color: Maui.Theme.backgroundColor
                opacity: 0.62
                border.width: 1
                border.color: Qt.rgba(1, 1, 1, 0.08)
            }

            Loader
            {
                id: _continueLoader
                anchors.fill: parent
                anchors.margins: root.recentSectionPadding
                active: root.hasRecentFiles
                visible: active
                asynchronous: true
                sourceComponent: _continueReadingComponent

                Connections
                {
                    target: Shelf.ReadingProgress
                    function onRecentFilesChanged()
                    {
                        _continueLoader.active = root.hasRecentFiles
                    }
                }
            }
        }

        Item
        {
            Layout.fillWidth: true
            Layout.fillHeight: true
            clip: true

            Maui.AltBrowser
            {
                id: _browser
                anchors.fill: parent
                clip: true
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
                model: Maui.BaseModel
                {
                    id: _libraryModel
                    sort: "modified"
                    sortOrder: Qt.DescendingOrder
                    filterRole: "label"
                    recursiveFilteringEnabled: true
                    sortCaseSensitivity: Qt.CaseInsensitive
                    filterCaseSensitivity: Qt.CaseInsensitive
                    list: Shelf.LibraryList
                    {
                        id: _libraryList
                        autoScan: viewerSettings.autoScan
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
                        imageSource: viewerSettings.showThumbnails ? (model.thumbnail || model.preview || "") : ""
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
                    imageSource: viewerSettings.showThumbnails ? (model.thumbnail || model.preview || "") : ""
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
            imageSource: viewerSettings.showThumbnails ? (model.thumbnail || model.preview || "") : ""
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
