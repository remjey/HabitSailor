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

pragma Singleton

import QtQuick 2.0
import QtQuick.LocalStorage 2.0 as Sql
import "rpc.js" as Rpc
import "utils.js" as Utils
import "."

QtObject {

    /**** Public Functions ****/

    function formatDate(date) {
        return date.format(_dateFormat);
    }

    function getLastCronDate() {
        return _lastCron;
    }

    function getNeedsCron() {
        return _needsCron;
    }

    function init() {
        _db = Sql.LocalStorage.openDatabaseSync("HabitSailor", "", "HabitSailor", 1000000);
        print("DB: version: " + _db.version)
        if (_db.version === "") {
            _db.changeVersion(_db.version, "0.0.1", function (tx) {
                print("DB: updating to 0.0.1")
                tx.executeSql("create table config (k text primary key, v text)");
            });
        }
        _db.readTransaction(function (tx) {
            var r = tx.executeSql("select k, v from config");
            for (var i = 0; i < r.rows.length; i++) {
                _configCache[r.rows.item(i).k] = r.rows.item(i).v;
            }
        })
        _setupRpc();
        Signals.start();
    }

    function isLogged() {
        return !!(_configGet("apiUser") && _configGet("apiKey"));
    }

    function update(cb) {
        var cs = _rpc.callSeq(function (o) {
            Signals.showMessage(qsTr("Bad or no response from server: %1").arg(o.message))
            if (cb) cb(false);
        });
        cs.autofail = true;
        cs.push("/user", "get", {}, function (ok, r) {
            _sleeping = r.preferences.sleep;
            _dateFormat = r.preferences.dateFormat;
            _lastCron = new Date(r.lastCron);
            _needsCron = r.needsCron;
            _tasksOrder = r.tasksOrder;
            _balance = r.balance;
            _name = r.profile.name;
            _stats = r.stats;
            return true;
        });
        cs.push("/tasks/user", "get", {}, function (ok, r) {
            _habits = [];
            _tasks = [];
            _rewards = [];
            r.forEach(function (item) {
                item = _prepareTask(item);
                switch (item.type) {
                case "habit":
                    _habits.push(item);
                    break;
                case "todo":
                case "daily":
                    _tasks.push(item);
                    break;
                case "reward":
                    _rewards.push(item);
                    break;
                }
            });
            _habits = Utils.sortTasks(_tasksOrder.habits, _habits)
            _rewards = Utils.sortTasks(_tasksOrder.rewards, _rewards)

            Signals.updateStats();
            Signals.updateTasks();
            if (cb) cb(true);
            return true;
        });
        cs.run();
    }

    function cron(cb) {
        _rpc.call("/cron", "post", {},
                  function (ok, o) {
                      if (ok) {
                          update(cb);
                      } else {
                          Signals.showMessage(qsTr("Impossible to run cron: %1").arg(o.message))
                          if (cb) cb(false);
                      }
                  });
    }

    function getName() { return _name; }
    function getLevel() { return _stats.lvl; }
    function getHp() { return _stats.hp; }
    function getHpMax() { return _stats.maxHealth; }
    function getMp() { return _stats.mp; }
    function getMpMax() { return _stats.maxMP; }
    function getXp() { return _stats.exp; }
    function getXpNext() { return _stats.toNextLevel; }
    function getGold() { return _stats.gp; }
    function getGems() { return _balance * 4; }

    function isSleeping() { return _sleeping; }

    function listHabits() { return _habits.map(_filterTask); }
    function listRewards() { return _rewards.map(_filterReward); }
    function listTodos() {
        return Utils.sortTasks(
                    _tasksOrder.todos,
                    _tasks.filter(function (item) { return item.type === "todo"; }))
        .map(_filterTask);
    }
    function listDailies() {
        return Utils.sortTasks(
                    _tasksOrder.dailys, // Yes this is dailys
                    _tasks.filter(function (item) { return item.type === "daily"; }))
        .map(_filterTask);
    }

    function getProfilePictureUrl() {
        return _configGet("apiUrl") + "/export/avatar-" + _configGet("apiUser") + ".png"
    }

    function login(url, login, password, success, error) {
        url = url || _configDefaults.apiUrl;
        _rpc.apiUrl = url;
        _rpc.call("/user/auth/local/login", "post",
                 { username: login, password: password },
                 function (ok, r) {
                     if (ok) {
                         _configSet("apiUrl", url);
                         _configSet("apiUser", r.id);
                         _configSet("apiKey", r.apiToken);
                         _setupRpc();
                         success();
                     } else {
                         error(_rpc.err(r));
                     }
                 });
    }

    function logout() {
        _configSet("apiUrl", null);
        _configSet("apiUser", null);
        _configSet("apiKey", null);
        Signals.logout();
    }

    function habitClick(tid, orientation, cb) {
        var habit;
        if (_habits.every(function (item) { return item.id !== tid || !(habit = item); })) return;

        if (_stats.hp === 0) { _remindDead(); return; }

        _rpc.call("/tasks/:tid/score/:dir", "post-no-body", { tid: tid, dir: orientation }, function (ok, o) {
            if (ok) {
                habit.value += o.delta;
                _partialStatsUpdate(o);
                if (orientation == "up") habit.counterUp++;
                else habit.counterDown++;
                if (cb)
                    cb(true, Utils.colorForValue(habit.value), habit.counterUp, habit.counterDown);
            } else if (cb) {
                Signals.showMessage(qsTr("Cannot update habit: %1").arg(o.message))
                cb(false);
            }
        });
    }

    function customRewardClick(tid, cb) {
        var reward;
        if (_rewards.every(function (item) { return item.id !== tid || !(reward = item); })) return;

        if (_stats.gp < reward.value) {
            Signals.showMessage(qsTr("Not enough gold to buy this custom reward!"));
            if (cb) cb(false);
            return;
        }

        _rpc.call("/tasks/:tid/score/down", "post-no-body", { tid: tid }, function (ok, o) {
            if (ok) {
                _partialStatsUpdate(o);
                if (cb) cb(true);
            } else if (cb) {
                Signals.showMessage(qsTr("Cannot buy custom reward: %1").arg(o.message))
                if (cb) cb(false);
            }
        });
    }

    function toggleSleep(cb) {
        _rpc.call("/user/sleep", "post-no-body", {}, function (ok, o) {
            if (ok) {
                _sleeping = o;
                Signals.updateStats();
                if (cb) cb(true, o);
            } else {
                Signals.showMessage(qsTr("Cannot toggle sleeping status: %1").arg(o.message))
                if (cb) cb(false);
            }
        });
    }

    function revive(cb) {
        if (_stats.hp !== 0) return;
        _rpc.call("/user/revive", "post-no-body", {}, function (ok, o) {
            if (ok) {
                update(cb);
            } else {
                Signals.showMessage(qsTr("Cannot refill health: %1").arg(o.message))
                if (cb) cb(false);
            }
        });
    }

    function buyHealthPotion(cb) {
        if (_stats.hp === 0) { _remindDead(); return; }
        _rpc.call("/user/buy-health-potion", "post-no-body", {}, function (ok, o) {
            if (ok) {
                _partialStatsUpdate(o)
                if (cb) cb(true)
            } else {
                Signals.showMessage(qsTr("Cannot buy Health Potion: %1").arg(o.message))
                if (cb) cb(false)
            }
        });
    }

    function setSubtask(taskId, subtaskId, cb) {
        // TODO everywhere: call cb(false) when fun returns because of bad args
        var task;
        if (_tasks.every(function (item) { return item.id !== taskId || !(task = item); })) return;
        var clitem;
        if (task.checklist.every(function (item) { return item.id !== subtaskId || !(clitem = item); })) return;

        // TODO take checked and enforce this value instead of returning the value on the server
        _rpc.call("/tasks/:taskId/checklist/:subtaskId/score", "post-no-body",
                 { taskId: taskId, subtaskId: subtaskId },
                 function (ok, o) {
                     if (!ok) {
                         Signals.showMessage(qsTr("Cannot update subtask: %1").arg(o.message))
                         if (cb) cb(false);
                         return;
                     }
                     var previousCompletedValue = clitem.completed
                     o.checklist.every(function (item) {
                         return item.id !== subtaskId || ((clitem.completed = item.completed) && false);
                     });
                     cb(true, clitem.completed);
                     if (clitem.completed !== previousCompletedValue)
                         Signals.setSubtask(taskId, subtaskId, clitem.completed);
                 });
    }

    function setTask(taskId, checked, cb) {
        var task, taskIndex;
        var taskNotFound = _tasks.every(function (item, itemIndex) {
            if (item.id === taskId) {
                task = item;
                taskIndex = itemIndex;
                return false;
            }
            return true;
        });
        if (taskNotFound) return;

        _rpc.call("/tasks/:tid/score/:dir", "post-no-body", { tid: taskId, dir: checked ? "up" : "down" }, function (ok, o) {
            if (ok) {
                if (task.type === "todo") _tasks.splice(taskIndex, 1);
                else task.completed = checked
                _partialStatsUpdate(o);
                Signals.setTask(taskId, checked);
                if (cb) cb(true);
            } else {
                Signals.showMessage(qsTr("Cannot update task: %1").arg(o.message));
                if (cb) cb(false);
            }
        });
    }

    function getTaskForEdit(taskId) {
        function taskFinder(item) { return item.id === taskId; }
        var task = _habits.findItem(taskFinder) || _tasks.findItem(taskFinder) || _rewards.findItem(taskFinder);
        var r = {
            type: task.type,
            title: task.text,
            notes: task.notes,
            difficulty: Utils.taskPriorities.find(function (o) { return o === task.priority; }, 1),
            up: !!task.up,
            down: !!task.down,
            startDate: new Date(task.startDate || 0),
            dueDate: (task.date ? new Date(task.date) : null),
            checklist: task.checklist || [],
            repeatType: "daily",
            everyX: 1,
            weekDays: Utils.repeatEveryDay,
            value: task.value || 0,
        }

        if (task.type === "daily") {
            r.weekDays = task.repeat;
            r.everyX = task.everyX;
            if (task.frequency === "daily") {
                if (r.everyX === 0) {
                    r.repeatType = "never";
                    r.everyX = 1;
                } else {
                    r.repeatType = "daily";
                }
            } else if (task.frequency === "monthly") {
                r.repeatType = "monthly"
                r.monthlyWeekDay = task.weeksOfMonth && task.weeksOfMonth.length > 0;
            } else if (task.frequency === "yearly") {
                r.repeatType = "yearly";
            } else if (task.frequency === "weekly") {
                r.repeatType = "weekly";
            } else {
                r.repeatType = "never";
                r.everyX = 1;
                r.repeat = Utils.repeatNever;
            }
        }
        return r;
    }

    function saveTask(type, o, cb) {
        var task = {
            id: o.id,
            type: type,
            text: o.title,
            notes: o.notes,
            priority: Utils.taskPriorities[o.difficulty],
        };

        if (type === "reward") {
            task.value = o.value;
        } else if (type === "habit") {
            task.up = o.up;
            task.down = o.down;
        } else if (type === "daily") {
            task.startDate = o.startDate;
            task.everyX = o.everyX;
            if (o.repeatType === "never") {
                task.frequency = "daily";
                task.everyX = 0;
                task.repeat = Utils.repeatNever;
            } else {
                task.frequency = o.repeatType;
                task.everyX = o.everyX;
                if (o.repeatType === "monthly" && o.monthlyWeekDay) {
                    task.repeat = Object.sclone(Utils.repeatNever);
                    task.repeat[Utils.weekDays[task.startDate.getDay()]] = true;
                    task.weeksOfMonth = [Math.floor((task.startDate.getDate() - 1) / 7)];
                } else {
                    task.repeat = o.weekDays;
                }
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
            // Save existing task
            _rpc.call("/tasks/:id", "put", task, function (ok, o) {
                if (ok) {
                    o = _prepareTask(o);
                    // TODO code copy
                    if (type === "habit") {
                        _habits.some(function (item, i) {
                            return item.id === o.id && (_habits[i] = o);
                        });
                    } else if (type === "daily" || type === "todo") {
                        _tasks.some(function (item, i) {
                            return item.id === o.id && (_tasks[i] = o);
                        });
                    } else if (type === "reward") {
                        _rewards.some(function (item, i) {
                            return item.id === o.id && (_rewards[i] = o);
                        });
                    }

                    Signals.updateTasks();
                    if (cb) cb(true);
                } else {
                    Signals.showMessage(qsTr("Cannot update task: %1").arg(o.message));
                    if (cb) cb(false);
                }
            });

        } else {
            // Create task
            _rpc.call("/tasks/user", "post", task, function (ok, o) {
                if (ok) {
                    o = _prepareTask(o);
                    if (type === "habit") {
                        _tasksOrder.habits.unshift(o.id);
                        _habits.unshift(o);
                    } else if (type === "daily" || type === "todo") {
                        _tasksOrder[type + "s"].unshift(o.id);
                        _tasks.push(o);
                    } else if (type === "reward") {
                        _tasksOrder.rewards.unshift(o.id);
                        _rewards.unshift(o);
                    }

                    Signals.updateTasks();
                    if (cb) cb(true);
                } else if (cb) {
                    Signals.showMessage(qsTr("Cannot create new task: %1").arg(o.message));
                    if (cb) cb(false);
                }
            });
        }
    }

    function deleteTask(taskId, cb) {
        function taskFinder(item) { return item.id === taskId; }
        _rpc.call("/tasks/:id", "delete", { id: taskId }, function (ok, o) {
            if (ok) {
                [_habits, _tasks, _rewards].forEach(function (list) {
                    var idx = list.find(taskFinder);
                    if (idx > -1) list.splice(idx, 1)
                })

                Signals.updateTasks();
                if (cb) cb(true);
            } else {
                Signals.showMessage(qsTr("Cannot delete task: %1").arg(o.message));
                if (cb) cb(false);
            }
        });
    }

    /**** Private Functions and Data ****/

    property var _db
    property var _rpc: new Rpc.Service()
    property var _configCache: ({})
    property var _configDefaults: ({ apiUrl: "https://habitica.com", })

    property string _dateFormat: "dd/MM/YYYY"
    property date _lastCron: new Date()
    property bool _needsCron: false
    property bool _sleeping
    property var _tasksOrder
    property real _balance // gems
    property string _name
    property var _stats
    property var _habits
    property var _tasks
    property var _rewards

    function _setupRpc() {
        if (_configGet("apiUser")) {
            _rpc.apiUrl = _configGet("apiUrl");
            _rpc.apiUser = _configGet("apiUser");
            _rpc.apiKey = _configGet("apiKey");
        }
    }

    function _configGet(key) {
        return _configCache[key];
    }

    function _configSet(key, value, tx) {
        if (_configCache[key] !== value) {
            _configCache[key] = value;
            _db.transaction(function (tx) {
                tx.executeSql("insert or replace into config (k, v) values (?, ?)", [ key, value ]);
            });
        }
    }

    function _prepareTask(item) {
        item.color = Utils.colorForValue(item.value);
        item.missedDueDate = false;
        switch (item.type) {
        case "daily":
            if (item.startDate) {
                var startDate = new Date(item.startDate);
                if (startDate.getTime() > getLastCronDate().getTime())
                    item.startDateFormatted = startDate.format(_dateFormat);
            } else {
                item.startDateFormatted = false;
            }
            break;
        case "todo":
            if (item.date) {
                var dueDate = new Date(item.date);
                item.missedDueDate = item.date && dueDate.getTime() < _lastCron.getTime();
                item.dueDateFormatted = dueDate.format(_dateFormat);
            }
            item.isDue = true;
            break;
        default:
            item.isDue = true;
        }
        return item;
    }

    function _filterReward(item) {
        return Utils.filterObject([
                                      "id", "type", "text", "notes",
                                      "value",
                                  ], item);
    }

    function _filterTask(item) {
        return Utils.filterObject([
                                      "id", "type", "priority", "text", "notes",
                                      "up", "down",
                                      "completed",
                                      "checklist",
                                      "missedDueDate", "dueDateFormatted",
                                      "isDue", "startDateFormatted",
                                      "color",
                                      "counterUp", "counterDown",
                                  ], item);
    }

    function _addStatDiff(list, name, a, b) {
        if (a === b) return;
        list.push(name + " " + ((b > a) ? "+" : "") + (Math.round(100 * (b - a)) / 100));
    }

    function _remindDead() {
        Signals.showMessage(qsTr("You must first refill your health from the profile page before you can do this!"));
    }

    function _partialStatsUpdate(stats) {
        var msgs = [];
        var lvlChange = stats.hasOwnProperty("lvl") && stats.lvl !== _stats.lvl;
        [{p:"lvl", n:qsTr("Level")},
        {p:"hp", n:qsTr("Health")},
        {p:"mp", n:qsTr("Mana")},
        {p:"exp", n:qsTr("Experience")},
        {p:"gp", n:qsTr("Gold")}].every(function (item) {
            if (stats.hasOwnProperty(item.p)) {
                if (item.p !== "exp" || !lvlChange)
                    _addStatDiff(msgs, item.n, _stats[item.p], stats[item.p]);
                _stats[item.p] = stats[item.p];
            }
            return true;
        });
        if (_stats.hp === 0) {
            Signals.showMessage(qsTr("Sorry, you ran out of health... Refill your health on the profile page to continue!"));
        } else {
            if (msgs.length > 0) Signals.showMessage(msgs.join(" ∙ "));
        }
        if (lvlChange) {
            update();
        } else {
            Signals.updateStats();
        }
    }

}
