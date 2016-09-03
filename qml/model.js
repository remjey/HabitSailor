/*
  Copyright 2016 Jérémy Farnaud

  This file is part of HabitSailor.

  HabitSailor is free software: you can redistribute it and/or modify
  it under the terms of the GNU General Public License as published by
  the Free Software Foundation, either version 3 of the License, or
  (at your option) any later version.

  HabitSailor is distributed in the hope that it will be useful,
  but WITHOUT ANY WARRANTY; without even the implied warranty of
  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
  GNU General Public License for more details.

  You should have received a copy of the GNU General Public License
  along with Foobar.  If not, see <http://www.gnu.org/licenses/>
*/

.pragma library
.import "rpc.js" as Rpc
.import "utils.js" as Utils
.import QtQuick.Signals 2.0 as QS
.import QtQuick.LocalStorage 2.0 as Sql

// Init, login
var init, login, isLogged, logout;

// Update local cache from server
var update;

// Read local data
var getName, getLevel, getHp, getHpMax, getMp, getMpMax, getXp, getXpNext,
        getGold, getGems, isSleeping;
var listHabits, listTodos, listDailies;
var getTaskForEdit;
var getProfilePictureUrl;

// Mutate local and remote data
var habitClick;
var setTask, setSubtask, saveTask, deleteTask;
var toggleSleep, revive;
var buyHealthPotion;

// Utils
var formatDate, getLastCronDate

// Signals
var signals = Qt.createQmlObject("\
    import QtQuick 2.0;
    QtObject {
        signal start()
        signal logout()
        signal updateStats()
        signal updateTasks()
        signal showMessage(string msg)
        signal setSubtask(string taskId, string subtaskId, bool checked)
    }", Qt.application, "signals");

(function () {

    var weekDays = [ "su", "m", "t", "w", "th", "f", "s" ];

    var db;
    var configCache = {};
    var configDefaults = {
        apiUrl: "https://habitica.com",
    };
    var data = {};

    function setupRpc() {
        if (configGet("apiUser")) {
            Rpc.apiUrl = configGet("apiUrl");
            Rpc.apiUser = configGet("apiUser");
            Rpc.apiKey = configGet("apiKey");
        }
    }

    function colorForValue(value) {
        // Colors inspired by those used in HabitRPG/common/script/libs/taskClasses.js
        if (value < -20) {
            return "#cc5f49"; // "#e6b8af";
        } else if (value < -10) {
            return "#db6060"; // "#f4cccc";
        } else if (value < -1) {
            return "#e2a25d"; // "#fce5cd";
        } else if (value < 1) {
            return "#e5c35b"; // "#fff2cc";
        } else if (value < 5) {
            return "#84d168"; // "#d9ead3";
        } else if (value < 10) {
            return "#68bac9"; // "#d0e0e3";
        } else {
            return "#5a8add"; // "#c9daf8";
        }
    }

    function sortTasks(ids, tasks) {
        var r = [];
        ids.forEach(function (id) {
            tasks.forEach(function (task) {
                if (task.id === id) r.push(task);
            })
        })
        return r;
    }

    formatDate = function (date) {
        if (data && data.dateFormat) return date.format(data.dateFormat);
        else return date.toLocaleDateString();
    }

    getLastCronDate = function (date) {
        if (data && data.lastCron) return data.lastCron;
        else return new Date();
    }

    init = function () {
        db = Sql.LocalStorage.openDatabaseSync("HabitSailor", "", "HabitSailor", 1000000);
        print("DB: version: " + db.version)
        if (db.version === "") {
            db.changeVersion(db.version, "0.0.1", function (tx) {
                print("DB: updating to 0.0.1")
                tx.executeSql("create table config (k text primary key, v text)");
            });
        }
        db.readTransaction(function (tx) {
            var r = tx.executeSql("select k, v from config");
            for (var i = 0; i < r.rows.length; i++) {
                configCache[r.rows.item(i).k] = r.rows.item(i).v;
            }
        })
        setupRpc();
        signals.start();
    }

    // TODO signal connect for updates

    function configGet(key) {
        return configCache[key];
    }

    function configSet(key, value, tx) {
        if (configCache[key] !== value) {
            configCache[key] = value;
            db.transaction(function (tx) {
                tx.executeSql("insert or replace into config (k, v) values (?, ?)", [ key, value ]);
            });
        }
    }

    isLogged = function () {
        return !!(configGet("apiUser") && configGet("apiKey"));
    }

    function prepareTask(item) {
        item.color = colorForValue(item.value);
        item.activeToday = true;
        item.missedDueDate = false;
        switch (item.type) {
        case "todo":
            if (item.date) {
                var dueDate = new Date(item.date);
                item.missedDueDate = item.date && dueDate.getTime() < data.lastCron.getTime();
                item.dueDateFormatted = dueDate.format(data.dateFormat);
            }
            break;
        case "daily":
            if (item.startDate) {
                var startDate = new Date(item.startDate);
                item.activeToday = startDate <= data.lastCron;
                if (item.activeToday) {
                    if (item.everyX === 1) {
                        item.activeToday = item.repeat[weekDays[data.lastCron.getDay()]]
                    } else {
                        var days = Math.floor((data.lastCron.getTime() - Date.parse(item.startDate)) / 86400000);
                        item.activeToday = (days % item.everyX == 0);
                    }
                } else {
                    item.startDateFormatted = startDate.format(data.dateFormat);
                }
            } else {
                item.activeToday = false;
            }
            break;
        default:
        }
        return item;
    }

    update = function (cb) {
        var cs = new Rpc.CallSeq(function (o) {
            signals.showMessage(qsTr("Bad or no response from server: %1").arg(o.message))
            if (cb) cb(false);
        });
        cs.autofail = true;
        cs.push("/user", "get", {}, function (ok, r) {
            data.sleeping = r.preferences.sleep;
            data.dateFormat = r.preferences.dateFormat;
            data.lastCron = new Date(r.lastCron);
            data.tasksOrder = r.tasksOrder;
            data.balance = r.balance;
            data.name = r.profile.name;
            data.stats = r.stats;
            return true;
        });
        cs.push("/tasks/user", "get", {}, function (ok, r) {
            data.habits = [];
            data.tasks = [];
            data.rewards = [];
            r.forEach(function (item) {
                prepareTask(item);
                switch (item.type) {
                case "habit":
                    data.habits.push(item);
                    break;
                case "todo":
                case "daily":
                    data.tasks.push(item);
                    break;
                case "reward":
                    data.rewards.push(item);
                    break;
                }
            });
            data.habits = sortTasks(data.tasksOrder.habits, data.habits)
            data.rewards = sortTasks(data.tasksOrder.rewards, data.rewards)

            signals.updateStats();
            signals.updateTasks();
            if (cb) cb(true);
            return true;
        });
        cs.run();
    }

    getName = function () { return data.name; }
    getLevel = function () { return data.stats.lvl; }
    getHp = function () { return data.stats.hp; }
    getHpMax = function () { return data.stats.maxHealth; }
    getMp = function () { return data.stats.mp; }
    getMpMax = function () { return data.stats.maxMP; }
    getXp = function () { return data.stats.exp; }
    getXpNext = function () { return data.stats.toNextLevel; }
    getGold = function () { return data.stats.gp; }
    getGems = function () { return data.balance * 4; }

    isSleeping = function () { return data.sleeping; }

    listHabits = function () { return data.habits; }
    listTodos = function () {
        return sortTasks(
                    data.tasksOrder.todos,
                    data.tasks.filter(function (item) { return item.type === "todo"; }));
    }
    listDailies = function () {
        return sortTasks(
                    data.tasksOrder.dailys, // Yes this is dailys
                    data.tasks.filter(function (item) { return item.type === "daily"; }));
    }

    getProfilePictureUrl = function () {
        return configGet("apiUrl") + "/export/avatar-" + configGet("apiUser") + ".png"
    }

    login = function (url, login, password, success, error) {
        url = url || configDefaults.apiUrl;
        Rpc.apiUrl = url;
        Rpc.call("/user/auth/local/login", "post",
                 { username: login, password: password },
                 function (ok, r) {
                     if (ok) {
                         configSet("apiUrl", url);
                         configSet("apiUser", r.id);
                         configSet("apiKey", r.apiToken);
                         setupRpc();
                         success();
                     } else {
                         error(Rpc.err(r));
                     }
                 });
    }

    logout = function () {
        configSet("apiUrl", null);
        configSet("apiUser", null);
        configSet("apiKey", null);
        signals.logout();
    }

    function addStatDiff(list, name, a, b) {
        if (a === b) return;
        list.push(name + " " + ((b > a) ? "+" : "") + (Math.round(100 * (b - a)) / 100));
    }

    function remindDead() {
        signals.showMessage(qsTr("You must first refill your health from the profile page before you can do this!"));
    }

    function partialStatsUpdate(stats) {
        var msgs = [];
        var lvlChange = stats.hasOwnProperty("lvl") && stats.lvl !== data.stats.lvl;
        [{p:"lvl", n:qsTr("Level")},
        {p:"hp", n:qsTr("Health")},
        {p:"mp", n:qsTr("Mana")},
        {p:"exp", n:qsTr("Experience")},
        {p:"gp", n:qsTr("Gold")}].every(function (item) {
            if (stats.hasOwnProperty(item.p)) {
                if (item.p !== "exp" || !lvlChange)
                    addStatDiff(msgs, item.n, data.stats[item.p], stats[item.p]);
                data.stats[item.p] = stats[item.p];
            }
            return true;
        });
        if (data.stats.hp === 0) {
            signals.showMessage(qsTr("Sorry, you ran out of health... Refill your health on the profile page to continue!"));
        } else {
            if (msgs.length > 0) signals.showMessage(msgs.join(" ∙ "));
        }
        if (lvlChange) {
            update();
        } else {
            signals.updateStats();
        }
    }

    habitClick = function (tid, orientation, cb) {
        var habit;
        if (data.habits.every(function (item) { return item.id !== tid || !(habit = item); })) return;

        if (data.stats.hp === 0) {
            remindDead()
            return;
        }

        Rpc.call("/tasks/:tid/score/:dir", "post-no-body", { tid: tid, dir: orientation }, function (ok, o) {
            if (ok) {
                habit.value += o.delta;
                partialStatsUpdate(o);
                if (cb)
                    cb(true, colorForValue(habit.value));
            } else if (cb) {
                signals.showMessage(qsTr("Cannot update habit: %1").arg(o.message))
                cb(false);
            }
        });
    }

    toggleSleep = function (cb) {
        Rpc.call("/user/sleep", "post-no-body", {}, function (ok, o) {
            if (ok) {
                data.sleeping = o;
                signals.updateStats();
                if (cb) cb(true, o);
            } else {
                signals.showMessage(qsTr("Cannot toggle sleeping status: %1").arg(o.message))
                if (cb) cb(false);
            }
        });
    }

    revive = function (cb) {
        if (data.stats.hp !== 0) return;
        Rpc.call("/user/revive", "post-no-body", {}, function (ok, o) {
            if (ok) {
                update(cb);
            } else {
                signals.showMessage(qsTr("Cannot refill health: %1").arg(o.message))
                if (cb) cb(false);
            }
        });
    }

    buyHealthPotion = function (cb) {
        if (data.stats.hp === 0) remindDead()
        Rpc.call("/user/buy-health-potion", "post-no-body", {}, function (ok, o) {
            if (ok) {
                partialStatsUpdate(o)
                if (cb) cb(true)
            } else {
                signals.showMessage(qsTr("Cannot buy Health Potion: %1").arg(o.message))
                if (cb) cb(false)
            }
        });
    }

    setSubtask = function (taskId, subtaskId, cb) {
        // TODO everywhere: call cb(false) when fun returns because of bad args
        var task;
        if (data.tasks.every(function (item) { return item.id !== taskId || !(task = item); })) return;
        var clitem;
        if (task.checklist.every(function (item) { return item.id !== subtaskId || !(clitem = item); })) return;

        // TODO take checked and enforce this value instead of returning the value on the server
        Rpc.call("/tasks/:taskId/checklist/:subtaskId/score", "post-no-body",
                 { taskId: taskId, subtaskId: subtaskId },
                 function (ok, o) {
                     if (!ok) {
                         signals.showMessage(qsTr("Cannot update subtask: %1").arg(o.message))
                         if (cb) cb(false);
                         return;
                     }
                     var previousCompletedValue = clitem.completed
                     o.checklist.every(function (item) {
                         return item.id !== subtaskId || ((clitem.completed = item.completed) && false);
                     });
                     cb(true, clitem.completed);
                     if (clitem.completed !== previousCompletedValue)
                        signals.setSubtask(taskId, subtaskId, clitem.completed);
                 });
    }

    setTask = function (taskId, checked, cb) {
        var task, taskIndex;
        var taskNotFound = data.tasks.every(function (item, itemIndex) {
            if (item.id === taskId) { task = item; taskIndex = itemIndex; return false; } return true;
        });
        if (taskNotFound) return;

        Rpc.call("/tasks/:tid/score/:dir", "post-no-body", { tid: taskId, dir: checked ? "up" : "down" }, function (ok, o) {
            if (ok) {
                if (task.type === "todo") data.tasks.splice(taskIndex, 1);
                else task.completed = checked
                partialStatsUpdate(o);
                if (cb) cb(true);
            } else {
                signals.showMessage(qsTr("Cannot update task: %1").arg(o.message));
                if (cb) cb(false);
            }
        });
    }

    var taskPriorities = [ 0.1, 1, 1.5, 2 ];
    var repeatEveryDay = { m: true, t: true, w: true, th: true, f: true, s: true, su: true };
    var repeatNever = { m: false, t: false, w: false, th: false, f: false, s: false, su: false };

    function compareWeekdays(model, subject) {
        for (var i in model) {
            if (subject[i] !== model[i]) return false;
        }
        return true;
    }

    getTaskForEdit = function (taskId) {
        function taskFinder(item) { return item.id === taskId; }
        var task = data.habits.findItem(taskFinder) || data.tasks.findItem(taskFinder);
        var r = {
            type: task.type,
            title: task.text,
            notes: task.notes,
            difficulty: taskPriorities.find(function (o) { return o === task.priority; }, 1),
            up: !!task.up,
            down: !!task.down,
            startDate: new Date(task.startDate || 0),
            dueDate: (task.date ? new Date(task.date) : null),
            checklist: task.checklist || [],
            repeatType: "daily",
            period: 1,
            weekDays: repeatEveryDay,
        }

        if (task.type === "daily") {
            if (task.frequency === "daily") {
                r.repeatType = "period";
                r.period = task.everyX;
            } else if (compareWeekdays(repeatNever, task.repeat)) {
                r.repeatType = "never";
            } else if (!compareWeekdays(repeatEveryDay, task.repeat)) {
                r.repeatType = "weekly";
                r.weekDays = task.repeat;
            }
        }
        return r;
    }

    saveTask = function (type, o, cb) {
        //TODO other types
        var task = {
            id: o.id,
            type: type,
            text: o.title,
            notes: o.notes,
            priority: taskPriorities[o.difficulty],
        };

        if (type === "habit") {
            task.up = o.up;
            task.down = o.down;
        } else if (type === "daily") {
            task.startDate = o.startDate;
            if (o.repeatType === "daily") {
                task.frequency = "weekly";
                task.everyX = 1;
                task.repeat = repeatEveryDay;
            } else if (o.repeatType === "weekly") {
                task.frequency = "weekly";
                task.everyX = 1;
                task.repeat = o.weekDays;
            } else if (o.repeatType === "period") {
                task.frequency = "daily";
                task.everyX = o.period;
                task.repeat = repeatEveryDay;
            } else if (o.repeatType === "never") {
                task.frequency = "weekly";
                task.everyX = 1;
                task.repeat = repeatNever;
            }
        } else if (type === "todo") {
            task.date = o.dueDate;
        } else {
            //TODO runtime error
            return;
        }

        if (type === "daily" || type === "todo") {
            task.checklist = o.checklist;
        }

        if (task.id) {
            // Save task
            Rpc.call("/tasks/:id", "put", task, function (ok, o) {
                if (ok) {
                    if (type === "habit") {
                        prepareTask(o);
                        data.habits.some(function (item, i) {
                            return item.id === o.id && (data.habits[i] = o);
                        });
                    } else if (type === "daily" || type === "todo") {
                        prepareTask(o);
                        data.tasks.some(function (item, i) {
                            return item.id === o.id && (data.tasks[i] = o);
                        });
                    }

                    signals.updateTasks();
                    if (cb) cb(true);
                } else {
                    signals.showMessage(qsTr("Cannot update task: %1").arg(o.message));
                    if (cb) cb(false);
                }
            });

        } else {
            // Create task
            Rpc.call("/tasks/user", "post", task, function (ok, o) {
                if (ok) {
                    if (type === "habit") {
                        prepareTask(o);
                        data.tasksOrder.habits.unshift(o.id);
                        data.habits.unshift(o);
                    } else if (type === "daily" || type === "todo") {
                        prepareTask(o);
                        data.tasksOrder[type + "s"].unshift(o.id);
                        data.tasks.push(o);
                    }

                    signals.updateTasks();
                    if (cb) cb(true);
                } else if (cb) {
                    signals.showMessage(qsTr("Cannot create new task: %1").arg(o.message));
                    if (cb) cb(false);
                }
            });
        }
    }

    deleteTask = function (taskId, cb) {
        function taskFinder(item) { return item.id === taskId; }
        Rpc.call("/tasks/:id", "delete", { id: taskId }, function (ok, o) {
            if (ok) {
                [data.habits, data.tasks].forEach(function (list) {
                    var idx = list.find(taskFinder);
                    if (idx > -1) list.splice(idx, 1)
                })

                signals.updateTasks();
                if (cb) cb(true);
            } else {
                signals.showMessage(qsTr("Cannot delete task: %1").arg(o.message));
                if (cb) cb(false);
            }
        });
    }

})()
