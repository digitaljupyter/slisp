# Copyright 2022 Kai Daniel Gonzalez. All rights reserved.
# Use of this source code is governed by a BSD-style
# license that can be found in the LICENSE file.
meson build
sudo ninja install -C build
bash copy-success.sh
