import QtQuick 2.0

QtObject {

    property var fun;
    property var signl;

    Component.onCompleted: {
        signl.connect(fun);
    }

    Component.onDestruction: {
        signl.disconnect(fun);
    }

}

