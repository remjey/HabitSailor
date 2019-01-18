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

function filterObject(props, o) {
    var r = {};
    props.forEach(function (prop) {
        r[prop] = o[prop];
    });
    return r;
}

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

function sclone(o) {
    // This is a pretty bad cloning facility but it suits our needs (for now)

    if (typeof(o) != "object" || o === null || o instanceof Boolean || o instanceof Function || o instanceof Number) {
        // Copy simple, unmutable types
        return o;
    }

    // Now handle more complex objects
    var r = o;
    if (o instanceof Date) {
        r = new Date(o);
    } else if (o instanceof Array) {
        r = [];
        o.forEach(function (i) {
            return sclone(i);
        });
    } else {
        r = {};
        for (var i in o) {
            r[i] = sclone(o[i]);
        }
    }
    return r;
}

function md(text) {
    var lines = text.split(/\n/)
    var out = "";
    var cl = "", clt = "";

    function commit(nclt) {
        var tcl = cl.replace(/&<>/g, function (c) {
            switch (c) {
            case "&": return "&amp;";
            case "<": return "&lt;";
            case ">": return "&gt;";
            }
        });
        tcl = tcl.replace(/(^|[^\\~])~~(|.*?[^\\~])~~/g, "$1<s>$2</s>");
        tcl = tcl.replace(/(^|[^\\*])\*\*(|.*?[^\\*])\*\*/g, "$1<b>$2</b>");
        tcl = tcl.replace(/(^|[^\\_])\_\_(|.*?[^\\_])\_\_/g, "$1<b>$2</b>");
        tcl = tcl.replace(/(^|[^\\*])\*(|.*?[^\\*])\*/g, "$1<i>$2</i>");
        tcl = tcl.replace(/(^|[^\\_])\_(|.*?[^\\_])\_/g, "$1<i>$2</i>");
        tcl = tcl.replace(/(^|[^\\`])\`(|.*?[^\\`])\`/g, "$1<font size=\"2\"><code>$2</code></font>");
        tcl = tcl.replace(/\\([*_~#])/g, "$1")
        if (clt.match(/h[1-6]/)) out += "<" + clt + ">" + tcl + "</" + clt + ">";
        if (clt == "p") out += "<p>" + tcl + "</p>";
        if (clt == "li") out += "<li>" + tcl + "</li>";
        if (clt != "li" && nclt === "li") out += "<ul>";
        if (clt == "li" && nclt !== "li") out += "</ul>";
        clt = nclt;
        cl = "";
    }

    for (var i = 0; i < lines.length; ++i) {
        var line = lines[i].trim();
        var m;
        if ((m = line.match(/^(#+) (.+)/))) {
            commit("h" + Math.max(2, Math.min(m[1].length + 1, 5)));
            cl = m[2];
        } else if (line.substr(0, 2) === "* " || line.substr(0, 2) === "- ") {
            commit("li");
            cl = line.substr(2).trim();
        } else if (line === "") {
            commit("empty-line");
        } else {
            if (clt !== "p") commit("p");
            cl += line + " ";
        }
    }
    commit("end");

    return out;
}
