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
