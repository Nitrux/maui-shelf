# Copyright 2018-2020 Camilo Higuita <milo.h@aol.com>
# Copyright 2018-2020 Nitrux Latinoamericana S.C.
#
# SPDX-License-Identifier: GPL-3.0-or-later

remove_definitions(-DQT_NO_CAST_FROM_ASCII -DQT_STRICT_ITERATORS -DQT_NO_CAST_FROM_BYTEARRAY -DQT_NO_URL_CAST_FROM_STRING)

set(shelf_SRCS
    main.cpp
    library.cpp
    models/library/librarymodel.cpp)

set(shelf_ASSETS
    lib_assets.qrc)

qt_add_executable(${PROJECT_NAME}
    ${shelf_SRCS}
    ${shelf_ASSETS})

qt_add_qml_module(${PROJECT_NAME} URI app.maui.shelf
    NO_PLUGIN
    QML_FILES
    main.qml
    views/library/LibraryView.qml
    views/library/BrowserPage.qml
    views/library/FloatingViewer.qml
    views/library/LibraryMenu.qml
    views/Viewer/Viewer.qml
    views/Viewer/Viewer_TXT.qml
    views/Viewer/Viewer_EPUB.qml
    views/SettingsDialog.qml
    views/Viewer/Viewer_CB.qml)

target_compile_definitions(${PROJECT_NAME}
    PRIVATE $<$<OR:$<CONFIG:Debug>,$<CONFIG:RelWithDebInfo>>:QT_QML_DEBUG>)

target_link_libraries(${PROJECT_NAME}
    PRIVATE
    MauiKit4
    MauiKit4::FileBrowsing
    MauiKit4::Documents
    Qt6::Core
    Qt6::Gui
    Qt6::Quick
    Qt6::Qml
    Qt6::Sql
    Qt6::Multimedia
    KF6::CoreAddons
    KF6::I18n)

install(TARGETS ${PROJECT_NAME} ${KDE_INSTALL_TARGETS_DEFAULT_ARGS})
install(FILES assets/shelf.svg DESTINATION ${KDE_INSTALL_ICONDIR}/hicolor/scalable/apps)

qt_finalize_target(${PROJECT_NAME})
