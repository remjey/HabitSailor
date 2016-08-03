.pragma library
.import "rpc.js" as Rpc
.import QtQuick.LocalStorage 2.0 as Sql

var db;
var configCache = {};
var configDefaults = {
    apiUrl: "https://habitica.com",
};
var data = {};

var setupRpc = function () {
    if (configGet("apiUser")) {
        Rpc.setUrl(configGet("apiUrl"));
        Rpc.setUser(configGet("apiUser"));
        Rpc.setKey(configGet("apiKey"));
    }
}

var colorForValue = function (value) {
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
        return "#84d168"; // "#d9ead3"
    } else if (value < 10) {
        return "#68bac9"; // "#d0e0e3";
    } else {
        return "#5a8add"; // "#c9daf8";
    }
}

var sortTasks = function(ids, tasks) {
    var r = [];
    for (var i in ids) {
        for (var j in tasks) {
            if (tasks[j].id === ids[i]) r.push(tasks[j]);
        }
    }
    return r;
}

function init() {
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

function isLogged() {
    return !!(configGet("apiUser") && configGet("apiKey"));
}

function update(cb) {
    var cs = new Rpc.CallSeq(function () { cb(false); });
    cs.autofail = true;
    cs.push("/user", "get", {}, function (ok, r) {
        data.tasksOrder = r.tasksOrder;
        data.balance = r.balance;
        data.name = r.profile.name;
        data.stats = r.stats;
        cb(true);
        return true;
    });
    cs.push("/tasks/user", "get", {}, function (ok, r) {
        data.habits = [];
        for (var i in r) {
            var item = r[i];
            item.color = colorForValue(item.value);
            switch (item.type) {
            case "habit": data.habits.push(item); break;
            //case "todo": data.todos.push(item); break;
            //case "daily": data.dailies.push(item); break;
            }
        }
        data.habits = sortTasks(data.tasksOrder.habits, data.habits)
        return true;
    });
    cs.run();
}

function getName() { return data.name; }
function getLevel() { return data.stats.lvl; }
function getHp() { return data.stats.hp; }
function getHpMax() { return data.stats.maxHealth; }
function getMp() { return data.stats.mp; }
function getMpMax() { return data.stats.maxMP; }
function getXp() { return data.stats.exp; }
function getXpNext() { return data.stats.toNextLevel; }
function getGold() { return Math.floor(parseFloat(data.stats.gp)); }
function getGems() { return Math.floor(parseFloat(data.balance) * 4); }

function listHabits() { return data.habits; }

function getProfilePictureUrl() {
    return configGet("apiUrl") + "/export/avatar-" + configGet("apiUser") + ".png"
}

function login(url, login, password, success, error) {
    url = url || configDefaults.apiUrl;
    Rpc.setUrl(url);
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

function logout() {
    configSet("apiUrl", null);
    configSet("apiUser", null);
    configSet("apiKey", null);
}
