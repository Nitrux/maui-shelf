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

    Poppler.Document
    {
        id: _tocDoc
        path: control.path

        onPagesLoaded:
        {
            _restoreTimer.start()
        }
    }

    Timer
    {
        id: _restoreTimer
        interval: 150
        onTriggered:
        {
            const savedPage = Shelf.ReadingProgress.getProgress(control.path)
            if (savedPage > 0)
                _pdfViewer.__goTo({ page: savedPage, top: 0 })
        }
    }

    RowLayout
    {
        anchors.fill: parent
        spacing: 0

        Maui.Page
        {
            id: _tocPanel
            visible: _tocToggle.checked && _tocDoc.tocModel && _tocDoc.tocModel.count > 0
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
                model: _tocDoc.tocModel

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
                            _pdfViewer.__goTo({ page: model.page, top: 0 })
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

        PdfViewerContent
        {
            id: _pdfViewer
            Layout.fillWidth: true
            Layout.fillHeight: true

            path: control.path
            headBar.visible: false

            footBar.leftContent: ToolButton
            {
                id: _tocToggle
                icon.name: "view-sidetree"
                checkable: true
                checked: false
                visible: _tocDoc.tocModel && _tocDoc.tocModel.count > 0
                Maui.Controls.toolTipText: checked ? i18n("Hide table of contents") : i18n("Show table of contents")
            }

            footBar.middleContent: Item
            {
                Layout.fillWidth: true
                implicitHeight: _pageNav.implicitHeight

                RowLayout
                {
                    anchors.left: parent.left
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: Maui.Style.space.medium

                    Label
                    {
                        text: i18n("Zoom")
                        font.weight: Font.DemiBold
                        verticalAlignment: Text.AlignVCenter
                        Layout.alignment: Qt.AlignVCenter
                    }

                    ToolButton
                    {
                        icon.name: "list-remove"
                        display: ToolButton.IconOnly
                        enabled: _pdfViewer.pageScale > 1.0
                        Layout.alignment: Qt.AlignVCenter
                        onClicked: _pdfViewer.pageScale = Math.max(1.0, _pdfViewer.pageScale - 0.25)
                    }

                    Slider
                    {
                        from: 1.0
                        to: 4.0
                        stepSize: 0.25
                        value: _pdfViewer.pageScale
                        implicitWidth: 100
                        Layout.alignment: Qt.AlignVCenter
                        Layout.preferredWidth: implicitWidth
                        onMoved: _pdfViewer.pageScale = value
                    }

                    ToolButton
                    {
                        icon.name: "list-add"
                        display: ToolButton.IconOnly
                        enabled: _pdfViewer.pageScale < 4.0
                        Layout.alignment: Qt.AlignVCenter
                        onClicked: _pdfViewer.pageScale = Math.min(4.0, _pdfViewer.pageScale + 0.25)
                    }
                }

                Maui.ToolActions
                {
                    id: _pageNav
                    anchors.centerIn: parent
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
            }

            onCurrentPageChanged:
            {
                Shelf.ReadingProgress.saveProgress(control.path,
                                                   _pdfViewer.currentPage,
                                                   _tocDoc.pages || 0)
            }
        }
    }

    Component.onCompleted:
    {
        Shelf.ReadingProgress.markOpened(control.path)
    }
}
