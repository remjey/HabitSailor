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

function Service() {}

function formatPath(path, data) {
    return path.replace(/:(:|[a-zA-Z_0-9]+\b)/g, function (match, varname) {
        if (varname === "::") return ":";
        var r = data[varname];
        if (r !== undefined && r !== null) return r.toString();
        return "";
    });
}

Service.defaultErrorList = { 0: qsTr("Invalid URL"), 400: qsTr("Bad request"), 401: qsTr("Unauthorized or bad login and password") };
Service.prototype.apiUrl = null;
Service.prototype.apiKey = null;
Service.prototype.apiUser = null;

Service.prototype.call = function (path, method, data, onload, debug) {

    var xhr = new XMLHttpRequest();
    var fullpath = formatPath(this.apiUrl + "/api/v3" + path, data);
    var noBody = method === "get" || method === "delete"
    if (method === "post-no-body") {
        method = "post";
        noBody = true;
    }
    print("XHR Query: " + method + " " + fullpath)
    if (debug) print("XHR Query Data: " + JSON.stringify(data, null, 2));
    xhr.open(method, fullpath);
    if (this.apiKey && this.apiUser) {
        xhr.setRequestHeader("x-api-key", this.apiKey);
        xhr.setRequestHeader("x-api-user", this.apiUser);
    }
    xhr.onreadystatechange = function () {
        if (xhr.readyState == 4) {
            if (debug) {
                print("XHR Status: ", xhr.status);
                print("XHR Response: ", xhr.responseText);
            }
            var o;
            try {
                if (typeof(xhr.responseText) == "string")
                    o = JSON.parse(xhr.responseText);
            } catch (e) {}
            var ok = false;
            if (typeof(o) != "object") {
                o = {
                    success: false,
                    error: "_InvalidData",
                    message: qsTr("Invalid data or no data was received from server")
                };
            }
            o.httpStatus = xhr.status;
            if (o.success) {
                ok = true;
                o = o.data;
            } else if (!o.hasOwnProperty("message")) {
                o.message = Service.err(o);
            }
            onload(ok, o);
        }
    }
    xhr.setRequestHeader("Content-Type", "application/json");
    if (method === "post" || method === "get" || method === "put" || method === "delete")
        xhr.send(noBody ? "" : JSON.stringify(data));
    else
        throw qsTr("Invalid method for rpc call") // TODO notify callback instead of throwing
}

Service.err = function (r, errorList) {
    errorList = errorList || Service.defaultErrorList;
    var error = null, errorMessage = null;
    if (r && r.hasOwnProperty("error")) {
        error = r.error;
        errorMessage = r.message;
        if (errorList.hasOwnProperty(error)) return errorList[error];
    }
    if (errorMessage) return errorMessage;
    if (error) return qsTr("Unexplained error: %1 (status: %2)").arg(error).arg(r.httpStatus);
    if (errorList.hasOwnProperty(r.httpStatus)) return errorList[r.httpStatus];
    return qsTr("Unknown error, status: %1").arg(r.httpStatus);
}

Service.prototype.callSeq = function (onfail) {
    return new CallSeq(this, onfail);
}

function CallSeq(service, onfail) {
    this.service = service
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
    this.service.call(c.path, c.method, c.data, (function (ok, r) {
        if ((!this.autofail || ok) && c.onload(ok, r))
            return this.run();
        this.index = 0;
        if (this.onfail) this.onfail(r);
    }).bind(this));
}

