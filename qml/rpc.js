.pragma library

var defaultErrorList = { 0: "Invalid URL", 400: "Bad request", 401: "Unauthorized or bad credentials" };

var apiUrl = null;
var apiKey = null;
var apiUser = null;

function setUrl(url) { apiUrl = url; }
function setKey(key) { apiKey = key; }
function setUser(user) { apiUser = user; }


function populatePath(path, data) {
    return path.replace(/:([a-zA-Z_0-9]+)\b/, function (match, varname) {
        var r = data[varname];
        if (typeof(r) == "string") return r;
        return "";
    });
}

function call(path, method, data, onload) {
    var xhr = new XMLHttpRequest();
    var fullpath = apiUrl + "/api/v3" + path;
    if (method === "get") fullpath = populatePath(fullpath, data);
    print("XHR Query: " + method + " " + fullpath)
    xhr.open(method, fullpath);
    if (apiKey && apiUser) {
        xhr.setRequestHeader("x-api-key", apiKey);
        xhr.setRequestHeader("x-api-user", apiUser);
    }
    xhr.onreadystatechange = function () {
        if (xhr.readyState == 4) {
            print("XHR Status: ", xhr.status);
            print("XHR Response: ", xhr.responseText);
            var o;
            try {
                if (typeof(xhr.responseText) == "string")
                    o = JSON.parse(xhr.responseText);
            } catch (e) {}
            var ok = false;
            if (typeof(o) != "object") {
                o = { error: "_InvalidData", message: "Invalid data or no data was received from server" };
            } else if (o.success) {
                ok = true;
                o = o.data;
            }
            o.httpStatus = xhr.status;
            onload(ok, o);
        }
    }
    xhr.setRequestHeader("Content-Type", "application/json");
    if (method === "post")
        xhr.send(JSON.stringify(data));
    else if (method === "get")
        xhr.send();
    else
        throw "Invalid method for rpc call"
}

function CallSeq(onfail) {
    this.onfail = onfail;
    this.autofail = false;
    this.list = [];
    this.index = 0;
}
CallSeq.prototype.push = function (path, method, data, onload) {
    this.list.push({ path: path, method: method, data: data, onload: onload });
    return this;
}
CallSeq.prototype.run = function () {
    if (this.index >= this.list.length) return;
    var c = this.list[this.index];
    this.index++;
    var me = this;
    call(c.path, c.method, c.data, function (ok, r) {
        if ((!this.autofail || ok) && c.onload(ok, r))
            return me.run();
        me.index = 0;
        if (me.onfail) me.onfail();
    });
}

function err(r, errorList) {
    errorList = errorList || defaultErrorList;
    var error = null, errorMessage = null;
    print(r);
    if (r) print(r.hasOwnProperty("error"));
    if (r && r.hasOwnProperty("error")) {
        print("ssss")
        error = r.error;
        errorMessage = r.message;
        if (errorList.hasOwnProperty(error)) return errorList[error];
    }
    if (errorMessage) return errorMessage;
    if (error) return "Unexplained error: " + error + " (status: " + r.httpStatus + ")";
    if (errorList.hasOwnProperty(r.httpStatus)) return errorList[r.httpStatus];
    return "Unknown error, status: " + r.httpStatus;
}
