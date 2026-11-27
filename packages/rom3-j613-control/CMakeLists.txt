cmake_minimum_required(VERSION 3.20)
project(rom3-j613-control LANGUAGES CXX)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_AUTOMOC OFF)

find_package(Qt6 REQUIRED COMPONENTS Widgets)

add_executable(rom3-j613-control main.cpp)
target_link_libraries(rom3-j613-control PRIVATE Qt6::Widgets)

install(TARGETS rom3-j613-control RUNTIME DESTINATION bin)
install(FILES rom3-j613-control.desktop
        DESTINATION share/applications)
