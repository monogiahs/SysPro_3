TEMPLATE = app
CONFIG += console c++11
CONFIG -= app_bundle
CONFIG -= qt

SOURCES += \
    webserver.c \
    command_line_utils.c

HEADERS += \
    command_line_utils.h

