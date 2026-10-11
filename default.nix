# SPDX-FileCopyrightText: 2023-2026 Dom 'shymega' Rodriguez <shymega@shymega.org.uk>
#
# SPDX-License-Identifier: Apache-2.0
{system ? builtins.currentSystem, ...}: (builtins.getFlake (toString ./.)).legacyPackages.${system}
