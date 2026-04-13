import QtQuick
import QtQuick.Controls

import org.mauikit.controls as Maui
import org.mauikit.filebrowsing as FB

Maui.ContextualMenu
{
    id: control

    property int index: -1
    property Maui.BaseModel model: null
    readonly property var item: (model && index >= 0) ? model.get(index) : null

    enabled: !!item

    title: item ? item.label : ""
    Maui.Controls.subtitle: item ? Maui.Handy.formatSize(item.size) : ""
    icon.source: item ? item.url : ""

    MenuItem
    {
        text: i18n("Open Location")
        icon.name: "folder-open"
        enabled: !!item
        onTriggered: Qt.openUrlExternally(FB.FM.fileDir(item.url))
    }

    MenuSeparator {}

    MenuItem
    {
        text: i18n("Delete")
        icon.name: "edit-delete"
        enabled: !!item
        Maui.Controls.status: Maui.Controls.Negative
        onTriggered: removeFiles(filterSelection(item.url))
    }
}
