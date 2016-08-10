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
        getGold, getGems;
var listHabits, listTodos, listDailies;
var getProfilePictureUrl;

// Mutate local and remote data
var habitClick;
var setTask, setSubtask;
var revive;
var buyHealthPotion;

// Signals
var signals = Qt.createQmlObject("\
    import QtQuick 2.0;
    QtObject {
        signal start()
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
        // Stolen from HabitRPG/common/script/libs/taskClasses.js
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
        for (var i in ids) {
            for (var j in tasks) {
                if (tasks[j].id === ids[i]) r.push(tasks[j]);
            }
        }
        return r;
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

    update = function (cb) {
        var cs = new Rpc.CallSeq(function (o) {
            signals.showMessage("Bad or no response frome server: " + o.message)
            if (cb) cb(false);
        });
        cs.autofail = true;
        cs.push("/user", "get", {}, function (ok, r) {
            data.dateFormat = r.preferences.dateFormat;
            data.lastCron = new Date(r.lastCron);
            data.tasksOrder = r.tasksOrder;
            data.balance = r.balance;
            data.name = r.profile.name;
            data.stats = r.stats;
            signals.updateStats();
            return true;
        });
        cs.push("/tasks/user", "get", {}, function (ok, r) {
            data.habits = [];
            data.tasks = [];
            data.rewards = [];
            for (var i in r) {
                var item = r[i];
                item.color = colorForValue(item.value);
                item.activeToday = true;
                item.missedDueDate = false;
                switch (item.type) {
                case "habit":
                    data.habits.push(item); break;
                case "todo":
                    if (item.date) {
                        var dueDate = new Date(item.date);
                        item.missedDueDate = item.date && dueDate.getTime() < data.lastCron.getTime();
                        item.dueDateFormatted = dueDate.format(data.dateFormat);
                    }
                    data.tasks.push(item); break;
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

                    data.tasks.push(item); break;
                case "reward":
                    data.rewards.push(item); break;
                }
            }
            data.habits = sortTasks(data.tasksOrder.habits, data.habits)
            data.rewards = sortTasks(data.tasksOrder.rewards, data.rewards)
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
    }

    function addStatDiff(list, name, a, b) {
        if (a === b) return;
        list.push(name + " " + ((b > a) ? "+" : "") + (Math.round(100 * (b - a)) / 100));
    }

    function remindDead() {
        signals.showMessage("You must first refill your health from the profile page before you can do this!");
    }

    function partialStatsUpdate(stats) {
        var msgs = [];
        var lvlChange = stats.hasOwnProperty("lvl") && stats.lvl !== data.stats.lvl;
        [{p:"lvl", n:"Level"}, {p:"hp", n:"Health"}, {p:"mp", n:"Mana"}, {p:"exp", n:"Experience"}, {p:"gp", n:"Gold"}].every(function (item) {
            if (stats.hasOwnProperty(item.p)) {
                if (item.p !== "exp" || !lvlChange)
                    addStatDiff(msgs, item.n, data.stats[item.p], stats[item.p]);
                data.stats[item.p] = stats[item.p];
            }
            return true;
        });
        if (data.stats.hp === 0) {
            signals.showMessage("Sorry, you ran out of health… Refill your health on the profile page to continue!");
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
                signals.showMessage("Cannot update habit: " + o.message)
                cb(false);
            }
        });
    }

    revive = function (cb) {
        if (data.stats.hp !== 0) return;
        Rpc.call("/user/revive", "post-no-body", {}, function (ok, o) {
            if (ok) {
                update(cb);
            } else {
                signals.showMessage("Cannot refill health: " + o.message)
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
                signals.showMessage("Cannot buy Health Potion: " + o.message)
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
                         signals.showMessage("Cannot update subtask: " + o.message)
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
            } else if (cb) {
                signals.showMessage("Cannot update task: " + o.message)
                if (cb) cb(false);
            }
        });
    }

})()
