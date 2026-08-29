pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Services.Notifications

QtObject {
    id: root

    // =========================================================
    // Notification State
    // =========================================================

    property var activeNotifications: []
    readonly property var visibleNotifications: activeNotifications
    readonly property bool hasActiveNotification: activeNotifications.length > 0

    property bool isNotificationHovered: false
    property int notificationTick: 0

    signal notificationPushed(var item)
    signal allDismissed()

    // =========================================================
    // Icon Resolution
    // =========================================================

    function getNotifIcon(iconName, appName, desktopEntry) {
        if (iconName && iconName !== "") {
            if (iconName.startsWith("/") || iconName.startsWith("file://") || iconName.startsWith("image://")) {
                return iconName;
            }

            let path = Quickshell.iconPath(iconName, true);
            if (path !== "")
                return path;

            let nonSym = iconName.replace(/-symbolic$/, "");
            if (Quickshell.hasThemeIcon(nonSym))
                return Quickshell.iconPath(nonSym, true);
        }

        if (desktopEntry && desktopEntry !== "") {
            let cleanEntry = desktopEntry.replace(/\.desktop$/, "");
            let path = Quickshell.iconPath(cleanEntry, true);
            if (path !== "")
                return path;

            if (Quickshell.hasThemeIcon(cleanEntry))
                return Quickshell.iconPath(cleanEntry, true);
        }

        if (appName && appName !== "") {
            let lower = appName.toLowerCase().replace(/\s+/g, "-");
            if (Quickshell.hasThemeIcon(lower))
                return Quickshell.iconPath(lower, true);
        }

        return "";
    }

    // =========================================================
    // Notification Server
    // =========================================================

    property var server: NotificationServer {
        actionsSupported: true
        bodySupported: true
        bodyMarkupSupported: true
        imageSupported: true

        onNotification: notif => {
            if (!notif)
                return;

            notif.tracked = true;
            root.pushNotification(notif);
        }
    }

    // =========================================================
    // Timers
    // =========================================================

    property var expiryTimer: Timer {
        interval: 200
        repeat: true
        running: root.activeNotifications.length > 0 && !root.isNotificationHovered

        onTriggered: {
            root.expireDueNotifications();
        }
    }

    property var progressTimer: Timer {
        interval: 40
        repeat: true
        running: root.activeNotifications.length > 0 && !root.isNotificationHovered

        onTriggered: {
            root.notificationTick++;
        }
    }

    // =========================================================
    // Methods
    // =========================================================

    function pushNotification(notif) {
        if (!notif)
            return;

        const timeout = notif.urgency === NotificationUrgency.Critical ? 10000 : (notif.expireTimeout > 0 ? Math.round(notif.expireTimeout * 1000) : 5500);
        const id = notif.id || (Date.now() + Math.random());
        const now = Date.now();

        const item = {
            id: id,
            obj: notif,
            appName: notif.appName || "",
            summary: notif.summary || "",
            body: notif.body || "",
            appIcon: notif.appIcon || "",
            desktopEntry: notif.desktopEntry || "",
            image: notif.image || "",
            urgency: notif.urgency,
            timeout: timeout,
            expiresAt: now + timeout
        };

        let next = [item];
        for (let old of activeNotifications) {
            if (old.id === id)
                continue;
            next.push(old);
        }

        activeNotifications = next;
        notificationPushed(item);
    }

    function expireDueNotifications() {
        if (activeNotifications.length === 0)
            return;

        if (isNotificationHovered)
            return;

        const now = Date.now();
        let next = [];
        let changed = false;

        for (let item of activeNotifications) {
            if (item.expiresAt <= now) {
                if (item.obj && item.obj.tracked)
                    item.obj.expire();

                changed = true;
                continue;
            }

            next.push(item);
        }

        if (changed) {
            activeNotifications = next;
        }
    }

    function dismissNotification(id) {
        const item = activeNotifications.find(n => n.id === id);
        if (!item)
            return;

        if (item.obj && item.obj.tracked)
            item.obj.dismiss();

        activeNotifications = activeNotifications.filter(n => n.id !== id);
        if (activeNotifications.length === 0) {
            allDismissed();
        }
    }

    function dismissAllNotifications() {
        for (let item of activeNotifications) {
            if (item.obj && item.obj.tracked)
                item.obj.dismiss();
        }

        activeNotifications = [];
        allDismissed();
    }
}
