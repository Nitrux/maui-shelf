import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

import org.mauikit.controls as Maui
import org.mauikit.documents as Poppler
import org.maui.shelf as Shelf

/**
 * Wrapper around Poppler.PDFViewer that adds:
 *  - A collapsible TOC sidebar driven by a secondary Document instance
 *  - Reading-progress persistence via Shelf.ReadingProgress
 */
Item
{
    id: control

    property string path
    property alias orientation: _pdfViewer.orientation
    property alias currentItem: _pdfViewer.currentItem
    readonly property int currentPage: _pdfViewer.currentPage

    // Use the filename (without extension) as the tab title.
    // PDF internal metadata titles are often wrong (e.g. "Microsoft Word – Document1").
    readonly property string title:
    {
        if (control.path.length === 0)
            return ""
        var lastSlash = control.path.lastIndexOf("/")
        var fname = lastSlash >= 0 ? control.path.substring(lastSlash + 1) : control.path
        var lastDot = fname.lastIndexOf(".")
        return lastDot > 0 ? fname.substring(0, lastDot) : fname
    }

    // ── Secondary Document used ONLY for tocModel / page count ────────────
    Poppler.Document
    {
        id: _tocDoc
        path: control.path

        onPagesLoaded:
        {
            // Restore the last saved reading position once the document is ready
            _restoreTimer.start()
        }
    }

    // Small delay so the ListView inside PDFViewer has time to fully populate
    Timer
    {
        id: _restoreTimer
        interval: 150
        onTriggered:
        {
            const savedPage = Shelf.ReadingProgress.getProgress(control.path)
            if (savedPage > 0)
            {
                // __goTo navigates to the correct page; the secondary line in
                // that function may log a harmless JS error if poppler.pages is
                // an integer rather than an array – navigation still succeeds.
                _pdfViewer.__goTo({ page: savedPage, top: 0 })
            }
        }
    }

    // ── Layout: optional TOC panel + main PDF viewer ──────────────────────
    RowLayout
    {
        anchors.fill: parent
        spacing: 0

        // TOC sidebar ──────────────────────────────────────────────────────
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

                    // tocModel items expose "title" for chapter name and
                    // "page" for the 0-indexed destination page.
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

        // Thin separator between panel and viewer
        Rectangle
        {
            visible: _tocPanel.visible
            Layout.preferredWidth: 1
            Layout.fillHeight: true
            color: Maui.Theme.separatorColor
        }

        // PDF viewer (vendored) ───────────────────────────────────────────
        PDFViewer
        {
            id: _pdfViewer
            Layout.fillWidth: true
            Layout.fillHeight: true

            path: control.path
            headBar.visible: false

            // Inject the TOC toggle into the footer's left side.
            // The vendored PDFViewer leaves footBar.leftContent empty for callers.
            footBar.leftContent: ToolButton
            {
                id: _tocToggle
                icon.name: "view-sidetree"
                checkable: true
                checked: false
                visible: _tocDoc.tocModel && _tocDoc.tocModel.count > 0
                Maui.Controls.toolTipText: checked ? i18n("Hide table of contents") : i18n("Show table of contents")
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
