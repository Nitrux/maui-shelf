import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

import org.mauikit.controls as Maui
import org.mauikit.documents as Poppler
import org.maui.shelf as Shelf

Item
{
    id: control

    property string path
    property alias orientation: _pdfViewer.orientation
    property alias currentItem: _pdfViewer.currentItem
    readonly property int currentPage: _pdfViewer.currentPage

    readonly property string title:
    {
        if (control.path.length === 0)
            return ""
        var lastSlash = control.path.lastIndexOf("/")
        var fname = lastSlash >= 0 ? control.path.substring(lastSlash + 1) : control.path
        var lastDot = fname.lastIndexOf(".")
        return lastDot > 0 ? fname.substring(0, lastDot) : fname
    }

    Timer
    {
        id: _restoreTimer
        interval: 150
        onTriggered:
        {
            const savedPage = Shelf.ReadingProgress.getProgress(control.path)
            if (savedPage > 0)
                _pdfViewer.goTo({ page: savedPage, top: 0 })
        }
    }

    RowLayout
    {
        anchors.fill: parent
        spacing: 0

        Maui.Page
        {
            id: _tocPanel
            visible: _tocToggle.checked && _pdfViewer.tocModel && _pdfViewer.tocModel.count > 0
            Layout.preferredWidth: 260
            Layout.fillHeight: true
            Layout.minimumWidth: 180

            Maui.Controls.showCSD: false
            headBar.visible: true
            title: i18n("Contents")
            padding: 0

            headBar.rightContent: ToolButton
            {
                icon.name: "sidebar-collapse-left"
                onClicked: _tocToggle.checked = false
                Maui.Controls.toolTipText: i18n("Close sidebar")
            }

            Maui.ListBrowser
            {
                anchors.fill: parent
                model: _pdfViewer.tocModel

                delegate: Maui.ListDelegate
                {
                    width: ListView.view.width

                    template.label1.text: model.title || model.name || i18n("(untitled)")
                    template.label2.text: model.page !== undefined
                                          ? i18n("Page %1", model.page + 1)
                                          : ""

                    onClicked:
                    {
                        if (model.page !== undefined && model.page >= 0)
                            _pdfViewer.goTo({ page: model.page, top: 0 })
                    }
                }
            }
        }

        Rectangle
        {
            visible: _tocPanel.visible
            Layout.preferredWidth: 1
            Layout.fillHeight: true
            color: Maui.Theme.separatorColor
        }

        Item
        {
            id: _viewerArea
            Layout.fillWidth: true
            Layout.fillHeight: true

            readonly property int toolBarsSpacing: Maui.Style.space.small
            readonly property int toolBarsMargins: Maui.Style.defaultPadding
            readonly property int toolBarsHeight: _bottomBars.implicitHeight + (toolBarsMargins * 2)

            Poppler.PDFViewer
            {
                id: _pdfViewer
                anchors.fill: parent
                anchors.bottomMargin: _viewerArea.toolBarsHeight

                path: control.path
                showSearchControls: false
                headBar.visible: false
                footBar.visible: false

                Connections
                {
                    target: _pdfViewer.document
                    function onPagesLoaded()
                    {
                        _restoreTimer.start()
                    }
                }

                onCurrentPageChanged:
                {
                    Shelf.ReadingProgress.saveProgress(control.path,
                                                       _pdfViewer.currentPage,
                                                       _pdfViewer.totalPages || 0)
                }
            }

            ColumnLayout
            {
                id: _bottomBars
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.bottom: parent.bottom
                anchors.margins: _viewerArea.toolBarsMargins
                spacing: _viewerArea.toolBarsSpacing

                Maui.ToolBar
                {
                    id: _footerSearchBar
                    visible: _pdfViewer.searchVisible
                    Layout.fillWidth: true
                    position: ToolBar.Footer

                    middleContent: Maui.SearchField
                    {
                        id: _searchField
                        Layout.fillWidth: true
                        Layout.maximumWidth: 500
                        Layout.alignment: Qt.AlignHCenter
                        text: _pdfViewer.currentSearchTerm

                        onAccepted: _pdfViewer.search(text)
                        onCleared: _pdfViewer.search("")

                        actions: [
                            Action
                            {
                                text: i18n("Case sensitive")
                                checkable: true
                                icon.name: "format-text-uppercase"
                                checked: _pdfViewer.searchSensitivity === Qt.CaseSensitive
                                onTriggered: _pdfViewer.searchSensitivity = checked ? Qt.CaseSensitive : Qt.CaseInsensitive
                            }
                        ]
                    }
                }

                Maui.ToolBar
                {
                    id: _footerMainBar
                    Layout.fillWidth: true
                    position: ToolBar.Footer
                    forceCenterMiddleContent: false

                    leftContent: [
                        ToolButton
                        {
                            id: _tocToggle
                            icon.name: "view-sidetree"
                            checkable: true
                            checked: false
                            visible: _pdfViewer.tocModel && _pdfViewer.tocModel.count > 0
                            Maui.Controls.toolTipText: checked ? i18n("Hide table of contents") : i18n("Show table of contents")
                        },

                        ToolSeparator
                        {
                            visible: _tocToggle.visible
                            topPadding: 10
                            bottomPadding: 10
                        },

                        Maui.ToolActions
                        {
                            expanded: true
                            autoExclusive: false
                            checkable: false

                            Action
                            {
                                enabled: _pdfViewer.pageScale > 1.0
                                icon.name: "list-remove"
                                onTriggered: _pdfViewer.pageScale = Math.max(1.0, _pdfViewer.pageScale - 0.25)
                            }

                            Action
                            {
                                enabled: _pdfViewer.pageScale < 4.0
                                icon.name: "list-add"
                                onTriggered: _pdfViewer.pageScale = Math.min(4.0, _pdfViewer.pageScale + 0.25)
                            }
                        }
                    ]

                    middleContent: Maui.ToolActions
                    {
                        id: _pageNav
                        Layout.alignment: Qt.AlignHCenter | Qt.AlignVCenter
                        expanded: true
                        autoExclusive: false
                        checkable: false

                        Action
                        {
                            enabled: _pdfViewer.currentPage > 0
                            icon.name: _pdfViewer.orientation === ListView.Horizontal ? "go-previous" : "go-up"
                            onTriggered: _pdfViewer.previousPage()
                        }

                        Action
                        {
                            text: (_pdfViewer.currentPage + 1) + " / " + _pdfViewer.totalPages
                        }

                        Action
                        {
                            enabled: _pdfViewer.currentPage + 1 < _pdfViewer.totalPages
                            icon.name: _pdfViewer.orientation === ListView.Horizontal ? "go-next" : "go-down"
                            onTriggered: _pdfViewer.nextPage()
                        }
                    }

                    rightContent: ToolButton
                    {
                        icon.name: "search"
                        checkable: true
                        checked: _pdfViewer.searchVisible
                        Maui.Controls.toolTipText: checked ? i18n("Hide search bar") : i18n("Search in document")
                        onToggled: _pdfViewer.searchVisible = checked
                    }
                }
            }
        }
    }

    Component.onCompleted:
    {
        Shelf.ReadingProgress.markOpened(control.path)
    }
}
