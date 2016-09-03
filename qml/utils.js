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

var weekDays = [ "su", "m", "t", "w", "th", "f", "s", ]
var taskPriorities = [ 0.1, 1, 1.5, 2 ];
var repeatEveryDay = { m: true, t: true, w: true, th: true, f: true, s: true, su: true };
var repeatNever = { m: false, t: false, w: false, th: false, f: false, s: false, su: false };

function compareWeekdays(model, subject) {
    for (var i in model) {
        if (subject[i] !== model[i]) return false;
    }
    return true;
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

Date.prototype.format = function (format) {
    var date = this;
    var replacements = {
        "MM": (date.getMonth() + 1).zeroPad(2),
        "yyyy": date.getFullYear(),
        "dd": date.getDate().zeroPad(2),
    }
    return format.replace(/dd|MM|yyyy/g, function (r) { return replacements[r]; });
}

String.prototype.repeat = function (n) {
    var r = "";
    for (var i = 0; i < n; i++) r = r + this;
    return r;
}

Number.prototype.zeroPad = function (zeroes) {
    var svalue = this.toString();
    return "0".repeat(zeroes - svalue.length) + svalue;
}

Array.prototype.find = function (fun, defaultValue) {
    for (var i = 0; i < this.length; i++) {
        if (fun(this[i], i)) return i;
    }
    return defaultValue || -1;
}

Array.prototype.findItem = function (fun, defaultValue) {
    var i = this.find(fun);
    if (i >= 0) return this[i];
    return defaultValue;
}
