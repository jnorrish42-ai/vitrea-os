# Vitrea: per-user settings that have to be in place before Plasma starts.
# Sourced by startplasma at every login; each step only runs once (see /usr/lib/vitrea/user-setup).
if [ -x /usr/lib/vitrea/user-setup ]; then
    timeout 20 /usr/lib/vitrea/user-setup >/dev/null 2>&1 || true
fi
