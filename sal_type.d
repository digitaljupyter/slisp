// Copyright 2022 Kai Daniel Gonzalez. All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.

module sal_type;

import std.stdio;
import sal_shared_api;
import sal_auxlib;
import salinterp;

SalmonValue sal_construct_value(string n, SalmonEnvironment env) {
    auto s = newState();
    salmon_push_code(s, n);
    SalmonValue na = execute_salmon(s, true, env);

    return na;
}
