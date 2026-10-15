project('shelf', 'cpp', version: '4.0.5', meson_version: '>=1.12.0', default_options: ['cpp_std=c++17', 'buildtype=release'])
qt6 = import('qt6')
cpp_compiler = meson.get_compiler('cpp')
if cpp_compiler.get_id() == 'gcc' and cpp_compiler.has_argument('-Wno-sfinae-incomplete')
    add_project_arguments('-Wno-sfinae-incomplete', language: 'cpp')
endif
qt = dependency('qt6', version: '>=6.9', modules: ['Core', 'Gui', 'Sql', 'Multimedia', 'Qml', 'Quick'])
kf6_core = dependency('KF6CoreAddons', version: '>=6.13')
kf6_i18n = declare_dependency(
    include_directories: include_directories(get_option('prefix') / 'include' / 'KF6' / 'KI18n'),
    dependencies: [cpp_compiler.find_library('KF6I18n'), cpp_compiler.find_library('KF6I18nQml')],
)
mauikit = dependency('MauiKit4', version: '>=4.0.5')
filebrowsing = dependency('MauiKitFileBrowsing4', version: '>=4.0.5')
documents = declare_dependency(
    include_directories: include_directories(get_option('prefix') / 'include' / 'MauiKit4' / 'Documents'),
    dependencies: [cpp_compiler.find_library('MauiKitDocuments4')],
)
cpp_args = []
if host_machine.cpu_family() == 'x86_64'
    cpp_args += ['-march=x86-64-v3']
endif
shelf_version = configure_file(
    input: 'meson-content.in',
    output: 'shelf_version.h',
    configuration: {'CONTENT': ('''#pragma once
#define SHELF_VERSION_STRING "4.0.5"
#define GIT_BRANCH "Stable"
#define GIT_COMMIT_HASH "4.0.5"
''')}
)
shelf_includes = include_directories('src')
qt_sources = qt6.preprocess(qresources: ['src/lib_assets.qrc', 'src/qml.qrc'], moc_headers: ['src/library.h', 'src/models/library/librarymodel.h', 'src/models/readingprogress.h'])
executable('shelf', ['src/main.cpp', 'src/library.cpp', 'src/models/library/librarymodel.cpp', 'src/models/readingprogress.cpp'] + qt_sources + [shelf_version], dependencies: [qt, kf6_core, kf6_i18n, mauikit, filebrowsing, documents], include_directories: shelf_includes, cpp_args: cpp_args, install: true)
install_data('org.maui.shelf.desktop', install_dir: get_option('datadir') / 'applications')
install_data('org.maui.shelf.metainfo.xml', install_dir: get_option('datadir') / 'metainfo')
install_data('src/assets/shelf.svg', install_dir: get_option('datadir') / 'icons' / 'hicolor' / 'scalable' / 'apps')
