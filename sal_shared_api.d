// Copyright 2022 Kai Daniel Gonzalez. All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.

// Salmon Implementation

import std.stdio;
import std.string;
import sal_auxlib;
import std.path;
import std.conv;
import core.stdc.stdlib;

void err(string msg, int lineno = 0, string file = "") {
    writeln("\033[;1m" ~ file ~ ":" ~ to!string(lineno) ~ ": \033[31;1merror:\033[0m " ~ msg);
}

void note(string msg, int lineno = 0, string file = "") {
    writeln("\033[;1m" ~ file ~ ":" ~ to!string(lineno) ~ ": \033[36mnote:\033[0m " ~ msg);
}

void deprecate(string msg, int lineno = 0, string file = "") {
    writeln("\033[;1m" ~ file ~ ":" ~ to!string(lineno) ~ ": \033[33;1mdeprecated:\033[0m " ~ msg);
}

enum SalType {
    nil,
    str,
    number,
    any,
    func,
    builtin,
    list,
    pair,
    error,
    boolean
}

/* WWW: throwaway value, use SalmonState */
class SalmonInfo {
public:
    string[] aA;
    string[] raw;
    SalType rvaluetype = SalType.nil; /* return value */
    string rvalue = "nil";
    /* + whatever else I need */
    void returnValue(string value, SalType type) {
        rvalue = value;
        rvaluetype = type;
    }

    SalmonEnvironment environ = new SalmonEnvironment();
}

/* value: type */

string[] valuesToList(SalmonValue[] l, SalmonEnvironment env) {
    /** 
   * Converts `l` to a `SalmonValue[]`
   */
    string[] n = [];
    int iterator = 0;

    foreach (SalmonValue s; l) {
        n ~= s.v;
        iterator += 1;
    }

    return n;
}

class SalmonSettings {
public:
    bool handlePath = true; /* if set to true, it will handle the path automatically, otherwise you'll need to specify them yourself. */
    bool setBuiltins = true; /* do not set this to false unless you're wanting to define the functions yourself */
}

class SalmonFunction {
public:
    string run;
    string returns;
    string[string] parameters;
    string[] template_params;
}

class SalmonEnvironment {
public:
    int function(SalmonSub)[string] env_funcs;
    SalmonValue[string] env_vars;
    string[][string] env_lists;
    string[string] env_definitions;
    SalmonValue function(string[], SalmonEnvironment)[string] pluginKeywords;

    SalmonEnvironment copy() {
        auto en = new SalmonEnvironment();
        en.env_funcs = this.env_funcs;
        en.env_lists = this.env_lists;
        en.env_definitions = this.env_definitions;
        en.env_vars = this.env_vars;
        return en;
    }

    void unload_class(SalmonClass s) {
        auto classFuncs = s.get_functions();
        foreach (string fn; keys(classFuncs)) {
            this.env_funcs[s.get_name() ~ ":" ~ fn] = classFuncs[fn];
        }
    }

    SalmonSettings settings = new SalmonSettings();

    SalmonFunction[string] env_userdefined;
}

/* @optional_environment from issue #1 */
SalType checkSalmonType(string s, SalmonEnvironment optional_environment = new SalmonEnvironment()) {
    s = s.strip;
    if (s == "true" || s == "false") {
        return SalType.boolean;
    }

    if (s in optional_environment.env_userdefined) {
        return SalType.func;
    }

    if (s == "nil")
        return SalType.nil;

    try {
        s.to!float;
        return SalType.number;
    } catch (Exception) {
        if (s.startsWith('"'))
            return SalType.str;

        return SalType.any;
    }
}

string parse_string(string n) {
    n = replace(n, "\\033", "\033");
    if (!startsWith(n.strip, '"'))
        return "nil";

    int s = 0;
    string b = "";
    string b2 = "";

    foreach (char k; n) {
        if (k == '"' && s == 0) {
            s = 1;
            b = "";
        } else if (k == '\\' && s == 1) {
            s = 2;
        } else if (k == '"' && s == 2) {
            b ~= '"';
            s = 1;
        } else if (k == '"' && s == 1) {
            break;
        } else if (k == '[' && s == 3) {
            s = 4;
        } else if (k == 'm' && s == 4) {
            b ~= "\033[" ~ b2 ~ "m";
            s = 1;
        } else {
            if (s == 2) {
                switch (k) {
                case 'n':
                    b ~= '\n';
                    s = 1;
                    break;
                case 't':
                    b ~= '\t';
                    s = 1;
                    break;
                case 'e':
                    s = 3;
                    break;
                default:
                    if (k != '0') {
                        err("unknown escape sequence, `" ~ k ~ "`.");
                        exit(11);
                    }
                    b ~= k;
                    s = 1;
                    break;
                }
            } else {
                if (s >= 4) {
                    b2 ~= k;
                } else {
                    b ~= k;
                }
            }
        }
    }
    return b;
}

/* this is the value you should use for adding code */
class SalmonState {
public:
    string CODE = "";
}

/* A helper class to unload <prefix>: functions into the environment */
class SalmonClass {
    private string name;
    private int function(SalmonSub)[string] stuff;

    public void add_function(string asName, int function(SalmonSub) s) {
        stuff[asName] = s;
    }

    public void set_name(string asName) {
        name = asName;
    }

    public int function(SalmonSub)[string] get_functions() {
        return this.stuff;
    }

    public string get_name() {
        return this.name;
    }
}

/* return the argument at the position @p */
string sal_argument_at(SalmonInfo s, int p) {
    return s.aA[p];
}

void salmon_push_code(SalmonState s, string code) {
    s.CODE = code; /* push the code to the state */
}

SalmonState newState() {
    return new SalmonState();
}
