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

    // Expiration Timer: ticks while active and unhovered
    property var expiryTimer: Timer {
        interval: 200
        repeat: true
        running: root.activeNotifications.length > 0 && !root.isNotificationHovered

        onTriggered: {
            root.expireDueNotifications();
        }
    }

    // Progress Bar Ticker: increments notificationTick to re-evaluate remainingProgress
    property var progressTimer: Timer {
        interval: 40
        repeat: true
        running: root.activeNotifications.length > 0 && !root.isNotificationHovered

        onTriggered: {
            root.notificationTick++;
        }
    }

    // Hover Pause Extension: extends expiresAt while hovered so user retains full remaining time on exit
    property var hoverExtendTimer: Timer {
        interval: 100
        repeat: true
        running: root.activeNotifications.length > 0 && root.isNotificationHovered

        onTriggered: {
            for (let item of root.activeNotifications) {
                item.expiresAt += 100;
            }
        }
    }

    // =========================================================
    // Methods
    // =========================================================

    function pushNotification(notif) {
        if (!notif)
            return;

        let rawTimeout = notif.expireTimeout;
        let timeout = 5500;

        if (notif.urgency === NotificationUrgency.Critical) {
            timeout = 10000;
        } else if (rawTimeout > 0) {
            // If rawTimeout < 100 it is in seconds, if >= 100 it is already in milliseconds
            timeout = rawTimeout < 100 ? Math.round(rawTimeout * 1000) : Math.round(rawTimeout);
        }

        const id = notif.id || (Date.now() + Math.random());
        const now = Date.now();
        const appName = notif.appName || "";
        const summary = notif.summary || "";
        const body = notif.body || "";
        const appIcon = notif.appIcon || "";
        const desktopEntry = notif.desktopEntry || "";
        const image = notif.image || "";
        const urgency = notif.urgency;

        const item = {
            id: id,
            obj: notif,
            appName: appName,
            summary: summary,
            body: body,
            appIcon: appIcon,
            desktopEntry: desktopEntry,
            image: image,
            urgency: urgency,
            timeout: timeout,
            expiresAt: now + timeout
        };

        // Check if there is an existing notification with the same summary & appName (e.g. status toggles like Wheel Mode) or same ID
        let existingIndex = activeNotifications.findIndex(old => {
            if (old.id === id)
                return true;
            if (appName !== "" && summary !== "" && old.appName === appName && old.summary === summary)
                return true;
            return false;
        });

        let next = [];
        if (existingIndex !== -1) {
            // Update in-place to prevent duplicate card spam and reset countdown
            for (let i = 0; i < activeNotifications.length; i++) {
                if (i === existingIndex) {
                    next.push(item);
                } else {
                    next.push(activeNotifications[i]);
                }
            }
        } else {
            next = [item];
            for (let old of activeNotifications) {
                next.push(old);
            }
        }

        activeNotifications = next;
        notificationPushed(item);
    }

    function expireDueNotifications() {
        if (activeNotifications.length === 0) {
            expiryTimer.stop();
            return;
        }

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
            if (next.length === 0) {
                expiryTimer.stop();
                allDismissed();
            }
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
            expiryTimer.stop();
            allDismissed();
        }
    }

    function dismissAllNotifications() {
        for (let item of activeNotifications) {
            if (item.obj && item.obj.tracked)
                item.obj.dismiss();
        }

        activeNotifications = [];
        expiryTimer.stop();
        allDismissed();
    }
}
