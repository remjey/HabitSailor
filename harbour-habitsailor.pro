# NOTICE:
#
# Application name defined in TARGET has a corresponding QML filename.
# If name defined in TARGET is changed, the following needs to be done
# to match new name:
#   - corresponding QML filename must be changed
#   - desktop icon filename must be changed
#   - desktop filename must be changed
#   - icon definition filename in desktop file must be changed
#   - translation filenames have to be changed

# The name of your application
TARGET = harbour-habitsailor

CONFIG += sailfishapp

SOURCES += \
    src/habitsailor.cpp

CODECFORSRC = UTF-8

lupdate_only{

SOURCES += \
    qml/*.js \
    qml/*.qml \
    qml/components/*.qml \
    qml/cover/*.qml \
    qml/pages/*.qml \

}

OTHER_FILES += \
    translations/*.ts \
    harbour-habitsailor.desktop

SAILFISHAPP_ICONS = 86x86 108x108 128x128 256x256

# to disable building translations every time, comment out the
# following CONFIG line
CONFIG += sailfishapp_i18n

TRANSLATIONS += \
    translations/harbour-habitsailor-fr.ts \
    translations/harbour-habitsailor.ts

DISTFILES += \
    qml/pages/Main.qml \
    qml/assets/habitica.png \
    qml/pages/Init.qml \
    qml/pages/Login.qml \
    qml/rpc.js \
    README.md \
    habitsailor.desktop \
    qml/pages/Habits.qml \
    qml/utils.js \
    qml/components/Bar.qml \
    qml/components/Stat.qml \
    qml/components/MenuButton.qml \
    qml/pages/Revive.qml \
    qml/components/HabitButton.qml \
    rpm/harbour-habitsailor.yaml \
    rpm/harbour-habitsailor.changes.in \
    qml/harbour-habitsailor.qml \
    qml/components/TaskItem.qml \
    qml/cover/CoverPage.qml \
    qml/pages/Tasks.qml \
    qml/pages/TaskDetails.qml \
    qml/pages/TaskEdit.qml \
    qml/components/DatePickerButton.qml \
    qml/pages/About.qml \
    qml/assets/gpl-3.0-standalone.html \
    qml/assets/gpl-3.0.txt \
    qml/Model.qml \
    qml/qmldir \
    qml/Signals.qml \
    qml/components/EmptyListHint.qml \
    qml/pages/TaskNewFromCover.qml

