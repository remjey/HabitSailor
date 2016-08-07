import QtQuick 2.0
import Sailfish.Silica 1.0
import "../components"
import "../model.js" as Model

Page {
    id: root

    property var subtasks: ({})

    ListView {
        id: list
        anchors.fill: parent

        header: PageHeader {
            title: "To-Dos"
        }

        VerticalScrollDecorator {}

        // TODO placeholder for empty ListElement

        delegate: TaskItemStupid {
            subtasks: root.subtasks[model.id]
        }
    }

    ListModel { id: todosModel }

    function update() {
        var todos = Model.listTodos();
        list.model = null
        todosModel.clear();
        subtasks = {}
        for (var i in todos) {
            var task = todos[i];
            subtasks[task.id] = task.checklist;
            task.cltotal = task.checklist.length;
            var count = 0;
            task.checklist.forEach(function (item) { if (item.completed) count++; });
            task.clcompleted = count;
            todosModel.append(task);
        }
        list.model = todosModel
    }

    Component.onCompleted: {
        update();
    }

    SignalConnect {
        signl: Model.signals.updateTasks
        fun: update
    }

    SignalConnect {
        signl: Model.signals.setSubtask
        fun: function (taskId, subtaskId, checked) {
            for (var i = 0; i < todosModel.count; i++) {
                var todo = todosModel.get(i);
                if (todo.id !== taskId) continue;
                todosModel.setProperty(i, "clcompleted", todo.clcompleted + (checked ? 1 : -1))
                break;
            }
        }
    }

}

