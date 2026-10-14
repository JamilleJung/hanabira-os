cmake_minimum_required(VERSION 3.22)
project(hanabira-shell VERSION 0.1.0 LANGUAGES CXX)

set(CMAKE_CXX_STANDARD 20)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_AUTOMOC ON)

find_package(Qt6 6.4 REQUIRED COMPONENTS Core Gui Qml Quick QuickControls2 DBus)
find_package(PkgConfig REQUIRED)
pkg_check_modules(GIO REQUIRED IMPORTED_TARGET gio-2.0)
pkg_check_modules(GIO_UNIX REQUIRED IMPORTED_TARGET gio-unix-2.0)
find_package(LayerShellQt CONFIG QUIET)

option(HANABIRA_REQUIRE_LAYER_SHELL "Require layer-shell-qt for a real Wayland desktop build" OFF)
if(HANABIRA_REQUIRE_LAYER_SHELL AND NOT LayerShellQt_FOUND)
    message(FATAL_ERROR "LayerShellQt is required for the ISO shell package")
endif()

qt_add_executable(hanabira-shell
    src/main.cpp
    src/shellbackend.cpp
    src/shellbackend.h
)

qt_add_resources(hanabira-shell "hde-ui"
    PREFIX "/"
    FILES
        qml/Theme.js
        qml/FlowerMark.qml
        qml/Wallpaper.qml
        qml/Panel.qml
        qml/Dock.qml
        qml/Launcher.qml
        qml/QuickSettings.qml
        qml/Preview.qml
        assets/celestial-blue.png
)

target_link_libraries(hanabira-shell PRIVATE
    Qt6::Core Qt6::Gui Qt6::Qml Qt6::Quick Qt6::QuickControls2 Qt6::DBus
    PkgConfig::GIO PkgConfig::GIO_UNIX
)

if(LayerShellQt_FOUND)
    target_compile_definitions(hanabira-shell PRIVATE HANABIRA_HAVE_LAYER_SHELL=1)
    target_link_libraries(hanabira-shell PRIVATE LayerShellQt::Interface)
endif()

install(TARGETS hanabira-shell RUNTIME DESTINATION bin)
install(FILES assets/celestial-blue.png DESTINATION share/hanabira/shell)
