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
