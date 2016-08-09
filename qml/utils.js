.pragma library

String.prototype.repeat = function (n) {
    var r = "";
    for (var i = 0; i < n; i++) r = r + this;
    return r;
}

function zeroPad(zeroes, value) {
    var svalue = value.toString();
    return "0".repeat(zeroes - svalue.length) + svalue;
}
