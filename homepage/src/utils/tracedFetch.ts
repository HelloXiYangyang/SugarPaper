/*
 * Copyright (C) 2026 HelloXiYangyang
 * SPDX-License-Identifier: GPL-3.0-or-later
 */

export default async function tracedFetch(uri: string, init?: RequestInit) {
  return fetch(uri, init);
}
