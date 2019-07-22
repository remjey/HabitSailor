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
            // FIXME this version update code doesn’t scale!!! FIXME
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
            Signals.showMessage(qsTr("Bad or no response from server: %1").arg(o.message));
            if (cb) cb(false);
        });
        cs.autofail = true;
        var questsData;
        cs.push("/user", "get", {}, function (ok, r) {
            _inboxEnabled = !r.inbox.optOut;
            _newMessages = _inboxEnabled ? r.inbox.newMessages : 0;
            _sleeping = r.preferences.sleep;
            _dateFormat = r.preferences.dateFormat;
            _lastCron = new Date(r.lastCron);
            _needsCron = r.needsCron;
            _tasksOrder = r.tasksOrder;
            _balance = r.balance;
            _name = r.profile.name;
            _stats = r.stats;
            _equipped = r.items.gear.equipped;
            _party = r.party._id || "";
            _avatarInfo = _extractAvatarInfo(r);
            _avatarParts = _makeAvatarParts(_avatarInfo);
            _classSelected = r.flags.classSelected && !r.preferences.disableClasses;
            _skillsAvailable = r.stats.lvl >= 10 && _classSelected;
            _questBossProgress = (r.party && r.party.quest && r.party.quest.progress) ? (r.party.quest.progress.up || 0) : 0;
            _unallocatedStatPoints = _classSelected ? (r.stats.points || 0) : 0;
            questsData = r.items.quests;
            if (!_habiticaContent) {
                cs.autofail = false;
                cs.insert("/content?language=:lang", "get", { lang: r.preferences.language }, function (ok, r, xhr) {
                    if (ok) {
                        print("Habitica content updated");
                        _habiticaContent = r;
                        _configSet("habiticaContent", JSON.stringify(r));
                        var etag = xhr.getResponseHeader("ETag");
                        if (etag) _configSet("habiticaContentEtag", etag);
                    } else if (r.httpStatus === 304) {
                        print("Habitica content has not changed since last retrieval");
                        _habiticaContent = JSON.parse(_configGet("habiticaContent"));
                    } else {
                        print("Failed to retrieve Habitica content, trying to used cached content anyway.")
                        var cachedContent = _configGet("habiticaContent");
                        if (cachedContent) {
                            _habiticaContent = JSON.parse(cachedContent);
                        } else {
                            Signals.showMessage(qsTr("Could not load Habitica content: %1").arg(r.message));
                            return false;
                        }
                    }
                    cs.autofail = true;
                    return true;
                }, _configGet("habiticaContentEtag") ? { headers: { "If-None-Match": _configGet("habiticaContentEtag") }} : undefined);
            }
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
            return true;
        });
        cs.push(function () {
            var skillsData = _habiticaContent.spells[_stats.class || "warrior"];
            _skills = [];
            for (var id in skillsData) {
                var skill = skillsData[id];
                if (skill.lvl > _stats.lvl) continue;
                if (["self", "task", "party", "tasks"].indexOf(skill.target) == -1) continue;
                skill = Utils.sclone(skill);
                skill.iconSource = _pictureBaseUrl + "skills/shop_" + id + ".png";
                _skills.push(skill);
            }

            _quests = [];
            for (var key in questsData) {
                if (!(questsData[key] > 0)) continue;
                var q = _makeQuestObject(key);
                if (q) _quests.push(q);
            }

            _updateStats();

            Signals.updateStats();
            Signals.updateTasks();
            Signals.updateNewMessages();
            if (cb) cb(true);
            return true;
        });
        cs.run();
    }

    function updateMessages(cb) {
        _rpc.call("/inbox/messages", "get", {}, function (ok, r) {
            if (!ok) {
                Signals.showMessage(qsTr("Cannot update messages: %1").arg(r.message));
                if (cb) cb(false);
                return;
            }
            _inbox = {}
            var markMessagesUnread = _newMessages;
            for (var i = 0; i < r.length; i++) {
                var msg = _addMessageToInbox(r[i]);
                if (!msg.mine && markMessagesUnread > 0) {
                    penpal.unread++;
                    msg.unread = true;
                    markMessagesUnread--;
                }
            }
            _rpc.call("/user/mark-pms-read", "post", {}, function (ok, r) {
                if (ok) {
                    _newMessages = 0;
                    Signals.updateNewMessages();
                }
            });
            if (cb) cb(true);
        });
    }

    function postMessage(userId, text, cb) {
        _rpc.call("/members/send-private-message", "post", { message: text, toUserId: userId }, function (ok, o) {
            if (ok) {
                var msg = Utils.sclone(_addMessageToInbox(o.message, true));
                if (cb) cb(true, msg);
            } else {
                Signals.showMessage(qsTr("Cannot post private message: %1").arg(o.message))
                if (cb) cb(false);
            }
        });
        // Return a fake object for displaying while waiting for the real thing
        return {
            id: "",
            mine: true,
            date: new Date(),
            rawText: text,
            text: Utils.md(text),
            unread: false,
        };
    }

    function getMemberAvatar(uuid, cb) {
        if (_avatarsCache[uuid] && _avatarsCache[uuid].expires > Date.now()) {
            cb(_avatarsCache[uuid].parts, true);
            return true;
        } else {
            _rpc.call("/members/:uuid", "get", { uuid: uuid }, function (ok, o) {
                if (ok) {
                    var parts = _makeAvatarParts(_extractAvatarInfo(o));
                    _avatarsCache[uuid] = {
                        parts: parts,
                        expires: Date.now() + 600000,
                    };
                    cb(parts, false);
                } else {
                    _avatarsCache[uuid] = {
                        parts: null,
                        expires: Date.now() + 600000,
                    };
                    cb(null, false);
                }
            });
            return false;
        }
    }

    function startQuest(key, cb) {
        _rpc.call("/groups/party/quests/invite/:questKey", "post", { questKey: key }, function (ok, o) {
            if (ok) {
                Signals.questStarted(key, _transformQuestData(o))
            } else {
                Signals.showMessage(qsTr("Cannot start quest: %1").arg(o.message))
            }
            if (cb) cb(ok);
        });
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

    function getMyId() { return _myId; }
    function getName() { return _name; }
    function getLevel() { return _stats.lvl; }
    function getHp() { return _stats.hp; }
    function getHpMax() { return _stats.maxHealth; }
    function getMp() { return _stats.mp; }
    function getMpMax() { return _stats.maxMP; }
    function getXp() { return _stats.exp; }
    function getXpNext() { return _stats.toNextLevel; }
    function getStats() { return Utils.filterObject([ "int", "con", "per", "str", "total" ], _stats, true); }
    function getGold() { return _stats.gp; }
    function getGems() { return _balance * 4; }
    function hasParty() { return !!_party; }
    function hasInbox() { return _inboxEnabled; }
    function getDisplayUnallocatedStatPoints() { return !!_displayUnallocatedStatPoints; }
    function getUnallocatedStatPoints() { return _unallocatedStatPoints; }
    function hasNewMessages() { return _newMessages; }
    function hasNewPartyMessages() { return _newPartyMessages; }

    function isSleeping() { return _sleeping; }

    function getPenpals() {
        var r = [];
        for (var ppu in _inbox) {
            var pp = _inbox[ppu];
            r.push({
                       userId: pp.userId,
                       name: pp.name,
                       avatar: pp.avatar,
                       unread: pp.unread,
                   });
        }
        return r;
    }

    function getMessages(uuid) {
        var r = [];
        if (!_inbox[uuid]) return r;
        _inbox[uuid].msgs.forEach(function (o) {
            r.push(Utils.sclone(o));
        });
        return r;
    }

    function listSkills() {
        if (_skillsAvailable) return Utils.sclone(_skills);
        else return [];
    }

    function listQuests() {
        return Utils.sclone(_quests);
    }

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

    function getGroupData(gid, cb) {
        if (gid === "party") gid = _party;
        _rpc.call("/groups/:gid", "get", { gid: gid }, function (ok, o) {
            if (ok) {
                var r = {
                    id: o._id,
                    name: o.name,
                    chat: [],
                    leader:  (o.leader && o.leader.id ? o.leader.id : null),
                    memberCount: o.memberCount,
                };
                for (var i = 0; i < o.chat.length && i < 200; ++i) {
                    r.chat.push(_transformGroupMessage(o.chat[i]));
                }
                r.quest = _transformQuestData(o.quest);

                if (cb) cb(true, r);

                // Always mark as seen because we don’t know when to do it precisely.
                _rpc.call("/groups/:gid/chat/seen", "post-no-body", { gid: gid }, function (ok, o) {
                    if (ok) {
                        _newPartyMessages = false;
                        Signals.updateNewMessages();
                    } else {
                        Signals.showMessage(qsTr("Cannot set group read: %1").arg(o.message));
                    }
                });
            } else {
                Signals.showMessage(qsTr("Cannot get chat messages: %1").arg(o.message))
                if (cb) cb(false);
            }
        });
    }

    /* If mode is an positive integer, try to load at least mode members
      If mode is 0, load all members
      If mode is an uuid, load some members whose uuid is strictly superior to mode */
    function getGroupMembers(gid, mode, cb) {
        var cs = _rpc.callSeq(function (o) {
            Signals.showMessage(qsTr("Cannot load members of group: %1").arg(o.message))
            if (cb) cb(false);
        });
        cs.autofail = true;

        var r = [];
        var membersRpcCb = function (ok, o) {
            if (o.length === 0) {
                if (cb) cb(true, r);
            } else {
                o.forEach(function (op) {
                    r.push({
                               id: op.id,
                               inboxEnabled: !op.inbox.optOut,
                               name: op.profile.name,
                               parts: _makeAvatarParts(_extractAvatarInfo(op)),
                               hp: op.stats.hp,
                               hpMax: op.stats.maxHealth,
                               mp: op.stats.mp,
                               mpMax: op.stats.maxMP,
                               xp: op.stats.exp,
                               xpNext: op.stats.toNextLevel,
                               level: op.stats.lvl,
                    });
                });
                if (typeof(mode) == "number" && mode > 0 && r.length >= mode
                        || typeof(mode) == "string")
                    cb(true, r)
                else
                    cs.push("/groups/:gid/members?includeAllPublicFields=true&lastId=:lastId",
                            "get", { gid: gid, lastId: r[r.length - 1].id }, membersRpcCb);
            }
            return true;
        };

        cs.push("/groups/:gid/members?includeAllPublicFields=true"
                + (typeof(mode) == "string" ? "&lastId=:lastId" : ""),
                "get", { gid: gid, lastId: mode },
                membersRpcCb);
        cs.run();
    }

    function questAction(gid, action, cb) {
        switch (action) {
        default: throw "invalid quest action";
        case "abort":
        case "accept":
        case "cancel":
        case "force-start":
        case "leave":
        case "reject":
        }

        _rpc.call("/groups/:gid/quests/:action", "post-no-body", { gid: gid, action: action }, function (ok, o) {
            if (ok) {
                if (cb) cb(true, _transformQuestData(o));
            } else {
                Signals.showMessage(qsTr("Could not update quest: %1").arg(o.message))
                if (cb) cb(false);
            }
        });
    }

    function hideUnallocatedStatPoints() {
        _rpc.call("/notifications/:nid/read", "post-no-body", { nid: _displayUnallocatedStatPoints });
    }

    function allocateStatPoints(stats, cb) {
        _rpc.call("/user/allocate-bulk", "post", { stats: stats }, function (ok, o, xhr) {
            if (ok) {
                xhr.processNotificationsNow();
                _partialStatsUpdate(o);
            } else {
                Signals.showMessage(qsTr("Cannot allocate stat points: %1").arg(o.message));
            }
            if (cb) cb(ok);
        });
    }

    function useSkill(id, target, cb) {
        var url, data;
        if (target) {
            url = "/user/class/cast/:spellId?targetId=:targetId";
            data = { spellId: id, targetId: target };
        } else {
            url = "/user/class/cast/:spellId";
            data = { spellId: id };
        }
        _rpc.call(url, "post-no-body", data, function (ok, r) {
            if (ok) {
                _partialStatsUpdate(r.user);
                if (r.task) {
                    _prepareTask(r.task);
                    [ _habits, _tasks ].every(function (tasks) {
                        return tasks.every(function (itask) {
                            if (itask.id === r.task.id) {
                                itask.value = r.task.value;
                                itask.color = r.task.color;
                                return false;
                            }
                            return true;
                        });
                    });
                }
                if (cb) cb(ok, r);
            } else {
                Signals.showMessage(qsTr("Cannot use skill: %1").arg(r.message))
                if (cb) cb(ok);
            }
        });
    }

    function postChatMessage(gid, msg, cb) {
        _rpc.call("/groups/:gid/chat", "post", { gid: gid, message: msg }, function (ok, o) {
            if (ok) {
                if (cb) cb(true, _transformGroupMessage(o.message));
            } else {
                Signals.showMessage(qsTr("Cannot post chat message: %1").arg(o.message))
                if (cb) cb(false);
            }
        });
        return {
            name: getName(),
            rawText: msg,
            text: Utils.md(msg),
            fromType: "me",
        };
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
                         _myId = r.id;
                         _setupRpc();
                         success();
                     } else {
                         error(Rpc.Service.err(r));
                     }
                 });
    }

    function logout() {
        _configSet("apiUrl", null);
        _configSet("apiUser", null);
        _configSet("apiKey", null);
        _myId = "";
        Signals.logout();
    }

    function habitClick(tid, orientation, cb) {
        var habit;
        if (_habits.every(function (item) { return item.id !== tid || !(habit = item); })) return;

        if (_stats.hp === 0) { _remindDead(); return; }

        _rpc.call("/tasks/:tid/score/:dir", "post-no-body", { tid: tid, dir: orientation }, function (ok, o) {
            if (ok) {
                habit.value += o.delta;
                habit.color = Utils.colorForValue(habit.value);
                _partialStatsUpdate(o);
                if (orientation === "up") habit.counterUp++;
                else habit.counterDown++;
                if (cb)
                    cb(true, habit.color, habit.counterUp, habit.counterDown);
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
            } else {
                Signals.showMessage(qsTr("Cannot buy custom reward: %1").arg(o.message))
                if (cb) cb(false);
            }
        });
    }

    function toggleSleep(cb) {
        _rpc.call("/user/sleep", "post-no-body", {}, function (ok, o) {
            if (ok) {
                _sleeping = o;
                _avatarInfo.sleep = o;
                _avatarParts = _makeAvatarParts(_avatarInfo);
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
                _partialStatsUpdate(o);
                if (cb) cb(true);
            } else {
                Signals.showMessage(qsTr("Cannot buy Health Potion: %1").arg(o.message));
                if (cb) cb(false);
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
                    task.repeat = Utils.sclone(Utils.repeatNever);
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

    function getAvatarParts() {
        return Utils.sclone(_avatarParts);
    }

    /**** Private Functions and Data ****/

    property var _db
    property var _rpc: new Rpc.Service()
    property var _configCache: ({})
    property var _configDefaults: ({ apiUrl: "https://habitica.com", })

    property string _myId: ""
    property string _dateFormat: "dd/MM/YYYY"
    property date _lastCron: new Date()
    property bool _needsCron: false
    property bool _sleeping
    property var _tasksOrder
    property real _balance // gems
    property string _name
    property var _stats
    property var _equipped
    property var _habits
    property var _tasks
    property var _rewards
    property bool _inboxEnabled: false
    property var _inbox: ({})
    property var _avatarInfo
    property var _avatarParts
    property string _party: ""
    property var _habiticaContent: null
    property int _newMessages: 0
    property bool _newPartyMessages: false
    property var _avatarsCache: ({})
    property bool _skillsAvailable: false
    property var _skills: []
    property var _quests: []
    property real _questBossProgress: 0
    property int _unallocatedStatPoints: 0
    property string _displayUnallocatedStatPoints: ""
    property bool _classSelected: false

    function _setupRpc() {
        if (_configGet("apiUser")) {
            _rpc.apiUrl = _configGet("apiUrl");
            _rpc.apiUser = _configGet("apiUser");
            _rpc.apiKey = _configGet("apiKey");
            _myId = _configGet("apiUser");
        }
        _rpc.notificationsCallback = _notificationsCallback;
    }

    function _notificationsCallback(notifs) {
        var newPartyMessages = false;
        _displayUnallocatedStatPoints = "";
        notifs.forEach(function (n) {
            if (n.type === "NEW_CHAT_MESSAGE" && n.data.group.id === _party) {
                newPartyMessages = true;
            } else if (n.type === "UNALLOCATED_STATS_POINTS") {
                _displayUnallocatedStatPoints = n.id;
            }
        });
        if (_newPartyMessages != newPartyMessages) {
            _newPartyMessages = newPartyMessages;
            Signals.updateNewMessages();
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

    function _updateStats() {
        _stats.total = {};
        [ "str", "int", "con", "per" ].forEach(function (statk) {
            _stats.total[statk] = _stats[statk] + _stats.lvl / 2;
            Object.keys(_equipped).forEach(function (eqk) {
                var item = _habiticaContent.gear.flat[_equipped[eqk]];
                if (item) {
                    _stats.total[statk] += item[statk];
                    if (item.klass === _stats.class && _classAttrs[_stats.class].indexOf(statk) !== -1) {
                        _stats.total[statk] += item[statk] / 2;
                    }
                }
            });
        });
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
        if (typeof(b) == "undefined") {
            list.push(name + " " + Math.round(100 * a) / 100);
        } else {
            list.push(
                        name + " " + ((b > a) ? "+" : "")
                        + (Math.round(100 * (b - a)) / 100));
        }
    }

    function _remindDead() {
        Signals.showMessage(qsTr("You must first refill your health from the profile page before you can do this!"));
    }

    function _partialStatsUpdate(o) {
        var party = o.party;
        var stats = o.stats ? o.stats : o;
        var msgs = [];
        var lvlChange = stats.hasOwnProperty("lvl") && stats.lvl !== _stats.lvl;
        [{p:"lvl", n:qsTr("Level")},
        {p:"hp", n:qsTr("Health")},
        {p:"mp", n:qsTr("Mana")},
        {p:"exp", n:qsTr("Experience")},
        {p:"gp", n:qsTr("Gold")}].forEach(function (item) {
            if (stats.hasOwnProperty(item.p)) {
                if (item.p !== "exp" || !lvlChange)
                    _addStatDiff(msgs, item.n, _stats[item.p], stats[item.p]);
                _stats[item.p] = stats[item.p];
            }
        });
        _unallocatedStatPoints = _classSelected ? (stats.points || 0) : 0;
        [ "int", "con", "per", "str" ].forEach(function (k) { _stats[k] = stats[k]; });
        _updateStats();
        if (party && party.quest && party.quest.progress) {
            _questBossProgress = (party.quest.progress.up || 0);
            _addStatDiff(msgs, qsTr("Total boss damage"), party.quest.progress.up);
        }
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

    function _addMessageToInbox(cmsg, unshift) {
        var penpal = _inbox[cmsg.uuid]
        if (!penpal) {
            penpal = {
                userId: cmsg.uuid,
                name: cmsg.user,
                avatar: null,
                unread: 0,
                msgs: [],
            };
            _inbox[cmsg.uuid] = penpal;
        }
        if (!penpal.avatar && !cmsg.sent && cmsg.userStyles) penpal.avatar = _makeAvatarParts(_extractAvatarInfo(cmsg.userStyles));
        var msg = _transformPrivateMessage(cmsg);
        penpal.msgs[unshift ? "unshift" : "push"](msg);
        return msg;
    }

    function _extractAvatarInfo(o) {
        var costume = (o.preferences.costume ? o.items.gear.costume : o.items.gear.equipped);
        var r = {
            background: o.preferences.background,
            sleep: o.preferences.sleep,
            pet: o.items.currentPet,
            mount: o.items.currentMount,
            class: o.stats.class || "warrior",
            size: o.preferences.size,
            hairColor: o.preferences.hair.color,
            gear: {},
            body: {},
            hair: {},
        };
        [ "armor", "back", "body", "eyewear", "head", "headAccessory", "shield", "weapon" ].forEach(function (part) {
            r.gear[part] = costume[part];
        });
        [ "chair", "shirt", "skin" ].forEach(function (part) {
            r.body[part] = o.preferences[part];
        });
        [ "bangs", "base", "mustache", "beard", "flower" ].forEach(function (part) {
            r.hair[part] = o.preferences.hair[part];
        });
        return r;
    }

    function _makeAvatarParts(r) {
        if (!r) return {};
        var ad = {
            background: _avatarBgUrl(r.background),
            zzz: _avatarZzzUrl(r.sleep),
            pet: _avatarPetUrl(r.pet),
            mountBody: _avatarMountUrl(r.mount, "body"),
            mountHead: _avatarMountUrl(r.mount, "head"),
        };
        var part;
        for (part in r.gear) {
            ad[part] = _avatarGearUrl(r.gear[part], r.class, r.size);
        }
        for (part in r.body) {
            ad[part] = _avatarBodyUrl(part, r.body[part], r.size, r.sleep);
        }
        for (part in r.hair) {
            ad[part] = _avatarHairUrl(part, r.hair[part], r.hairColor);
        }
        return ad;
    }

    function _avatarPetUrl(name) {
        if (!name || name === "none") return false;
        return _pictureBaseUrl + "stable/pets/Pet-" + name + ".png";
    }

    function _avatarMountUrl(name, type) {
        if (!name || name === "none") return false;
        return _pictureBaseUrl + "stable/mounts/" + type + "/Mount_"
                + type[0].toUpperCase() + type.substr(1) + "_" + name + ".png";
    }

    function _avatarBgUrl(name) {
        if (!name || name === "none") return false;
        return _pictureBaseUrl + "backgrounds/background_" + name + ".png";
    }

    function _avatarZzzUrl(sleeping) {
        if (!sleeping) return false;
        else return _pictureBaseUrl + "misc/zzz.png"
    }

    function _avatarHairUrl(name, value, color) {
        if (value === 0) return false;
        var base = _pictureBaseUrl + "customize/";
        if ((name === "beard" || name === "mustache") && !color.match(/^p.*2$/)) {
            base += "beards/";
        } else if (name === "flower") {
            base += "flowers/";
        } else {
            base += "hair/";
        }
        base += "hair_" + name + "_" + value;
        if (name !== "flower") base += "_" + color;
        return base + ".png";
    }

    function _avatarGearUrl(name, clazz, bodyType) {
        if (!name) return false;
        var ne = name.split("_");

        if (ne[1] === "base") {
            if (ne[2] === "0") return false;
            ne[1] = clazz;
        }

        var base = _pictureBaseUrl + "gear/";
        if (ne[1] === "armoire") {
            base += "armoire/";
        } else if (ne[1] === "special" && _isEventGear(ne[2])) {
            base += "events/" + _isEventGear(ne[2]) + "/";
        } else if (ne[1] === "mystery") {
            base += "events/mystery_" + ne[2] + "/";
        } else {
            base += ne[0] + "/";
        }
        if (ne[0] === "armor") base += bodyType + "_";
        return base + name + ".png";
    }

    function _avatarBodyUrl(type, name, bodyType, sleeping) {
        if (!name || name === "none") return false;

        var base = _pictureBaseUrl + "customize/";
        if (type === "skin") base += "skin/";
        else base += type + "s/";
        if (type === "shirt") base += bodyType + "_";
        base += type + "_" + name;
        if (type === "skin" && sleeping) base += "_sleep";
        return base + ".png";
    }

    function _isEventGear(s) {
        var r = false;
        _eventNamePrefixes.some(function (p) {
            if (s.substr(0, p.length) === p) {
                r = p;
                return true;
            }
        });
        return r;
    }

    function _transformPrivateMessage(omsg) {
        return {
            id: omsg.id,
            mine: omsg.sent,
            date: new Date(omsg.timestamp),
            rawText: omsg.text,
            text: Utils.md(omsg.text),
            unread: false,
        };
    }

    function _transformGroupMessage(omsg) {
        var rmsg = {
            name: omsg.user || "(no name)",
            rawText: omsg.text || "",
            text: Utils.md(omsg.text || ""),
        };
        if (omsg.uuid === "system") rmsg.fromType = "system";
        else if (omsg.uuid === _myId) rmsg.fromType = "me";
        else rmsg.fromType = "friend";
        return rmsg;
    }

    function _makeQuestObject(key) {
        var qc = _habiticaContent.quests[key];
        if (!qc) return false;
        var q = {
            key: key,
            name: qc.text,
            desc: qc.notes,
            iconSource: _pictureBaseUrl + "quests/scrolls/inventory_quest_scroll_" + qc.key + ".png",
            pictureSource: _pictureBaseUrl + "quests/bosses/quest_" + qc.key + ".png",
            value: qc.value,
            drop: qc.drop || {},
            type: "other",
            maxHp: 0,
            str: 0.0,
            collect: [],
        };
        if (qc.boss) {
            q.type = "boss";
            q.maxHp = qc.boss.hp;
            q.str = qc.boss.str;
        } else if (qc.collect) {
            q.type = "collect";
            for (var ckey in qc.collect) {
                var co = qc.collect[ckey];
                var rc = {
                    key: ckey,
                    name: co.text,
                    max: co.count,
                };
                q.collect.push(rc);
            }
            q.collect.sort(function (a, b) { return a.name.localeCompare(b.name); });
        }
        q.rewards = [];
        if (qc.drop) {
            if (qc.drop.gp) q.rewards.push({
                                               iconSource: _pictureGoldUrl,
                                               iconZoom: -1,
                                               text: qsTr("%1 Gold").arg(qc.drop.gp),
                                           });
            if (qc.drop.exp) q.rewards.push({
                                                iconSource: _pictureExperienceUrl,
                                                iconZoom: -1,
                                                text: qsTr("%1 Experience points").arg(qc.drop.gp),
                                            });
            (qc.drop.items || []).forEach(function (item) {
                var r = {
                    key: item.key,
                    iconSource: "",
                    iconMargin: 0,
                    text: item.text
                };
                switch (item.type) {
                case "pets":
                    r.iconSource = _pictureBaseUrl + "stable/pets/Pet-" + item.key + ".png";
                    break;
                case "mounts":
                    r.iconSource = _pictureBaseUrl + "stable/mounts/icon/Mount_Icon_" + item.key + ".png";
                    break;
                case "food":
                    r.iconSource = _pictureBaseUrl + "stable/food/Pet_Food_" + item.key + ".png";
                    r.iconZoom = 1;
                    break;
                case "eggs":
                    r.iconSource = _pictureBaseUrl + "stable/eggs/Pet_Egg_" + item.key + ".png";
                    r.iconZoom = 1;
                    break;
                case "quests":
                    r.iconSource = _pictureBaseUrl + "quests/scrolls/inventory_quest_scroll_" + item.key + ".png";
                    break;
                case "gear":
                    r.iconSource = _pictureBaseUrl + "gear/" + item.key.match(/^[^_]+/)[0] + "/shop/shop_" + item.key + ".png";
                    r.iconZoom = 1;
                    break;
                case "hatchingPotions":
                    r.iconSource = _pictureBaseUrl + "stable/potions/Pet_HatchingPotion_" + item.key + ".png";
                    r.iconZoom = 1;
                    break;
                }
                q.rewards.push(r);
            });
        }
        return q;
    }

    function _transformQuestData(quest) {
        if (!quest || !quest.key) return null;
        var qc = _habiticaContent.quests[quest.key];
        var r = {
            key: quest.key,
            name: qc.text,
            iconSource: _pictureBaseUrl + "/quests/bosses/quest_" + quest.key + ".png",
            active: quest.active,
            members: quest.members, // Map of (memberId(string) -> memberOfQuest(bool))
            leader: quest.leader,
        }

        if (quest.active) {
            if (qc.boss) {
                r.type = "boss";
                r.maxHp = qc.boss.hp;
                r.hp = Math.ceil(quest.progress.hp);
                r.progress = Math.ceil(_questBossProgress);
            } else if (qc.collect) {
                r.type = "collect";
                r.collect = [];
                for (var key in qc.collect) {
                    var oc = qc.collect[key];
                    var rc = {
                        key: key,
                        name: oc.text,
                        max: oc.count,
                        count: quest.progress.collect[key],
                    };
                    r.collect.push(rc);
                }
                r.collect.sort(function (a, b) { return a.name.localeCompare(b.name); });
            } else {
                r.type = "other";
            }
        }
        return r;
    }

    property string _pictureBaseUrl: "https://raw.githubusercontent.com/HabitRPG/habitica/release/website/raw_sprites/spritesmith/";

    property string _pictureGoldUrl: "https://raw.githubusercontent.com/HabitRPG/habitica/release/website/client/assets/svg/gold.svg";
    property string _pictureExperienceUrl: "https://raw.githubusercontent.com/HabitRPG/habitica/release/website/client/assets/svg/experience.svg";

    property var _eventNamePrefixes: [
        "birthday", "fall", "gaymerx", "spring", "summer", "takeThis", "winter", "wondercon",
    ]

    property var _classAttrs: ({
                                   "warrior": [ "str", "con" ],
                                   "wizard": [ "int", "per" ],
                                   "healer": [ "con", "int" ],
                                   "rogue": [ "per", "str" ],
                                   "special": [],
                                   "armoire": [],
                                   "base": [],
                                   "mystery": [],
                               })

}

