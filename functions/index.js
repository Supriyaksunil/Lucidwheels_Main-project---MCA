const admin = require("firebase-admin");
const {onCall, HttpsError} = require("firebase-functions/v2/https");
const {logger} = require("firebase-functions");

admin.initializeApp();

exports.sendEmergencyNotification = onCall(async (request) => {
  const data = request.data || {};
  const tokens = Array.isArray(data.tokens)
    ? data.tokens.filter(
        (token) => typeof token === "string" && token.trim().length > 0,
      )
    : [];
  const alertId =
    typeof data.alertId === "string" && data.alertId.trim().length > 0
      ? data.alertId.trim()
      : `emergency-${Date.now()}`;
  const lat = Number(data.lat);
  const lng = Number(data.lng);
  const driverId = typeof data.driverId === "string" ? data.driverId.trim() : "";
  const driverName =
    typeof data.driverName === "string" && data.driverName.trim().length > 0
      ? data.driverName.trim()
      : "Driver";
  const reason =
    typeof data.reason === "string" && data.reason.trim().length > 0
      ? data.reason.trim()
      : "Possible emergency detected by LucidWheels.";
  const triggeredAt =
    typeof data.triggeredAt === "string" && data.triggeredAt.trim().length > 0
      ? data.triggeredAt.trim()
      : new Date().toISOString();

  if (!tokens.length) {
    return {sentCount: 0, failureCount: 0};
  }

  if (!Number.isFinite(lat) || !Number.isFinite(lng)) {
    throw new HttpsError(
      "invalid-argument",
      "Valid latitude and longitude are required.",
    );
  }

  const uniqueTokens = [...new Set(tokens.map((token) => token.trim()))];
  const locationUrl = `https://maps.google.com/?q=${lat},${lng}`;
  const messageText = `Emergency detected for ${driverName}`;

  const message = {
    tokens: uniqueTokens,
    notification: {
      title: messageText,
      body: reason,
    },
    data: {
      type: "emergency_alert",
      alertId,
      driverId,
      driverName,
      message: messageText,
      reason,
      lat: String(lat),
      lng: String(lng),
      mapUrl: locationUrl,
      triggeredAt,
    },
    android: {
      priority: "high",
      notification: {
        channelId: "high_importance_channel",
        priority: "max",
        defaultSound: true,
      },
    },
    apns: {
      payload: {
        aps: {
          sound: "default",
          contentAvailable: true,
        },
      },
    },
  };

  const response = await admin.messaging().sendEachForMulticast(message);

  if (response.failureCount > 0) {
    response.responses.forEach((result, index) => {
      if (!result.success) {
        logger.error("Emergency notification failed", {
          token: uniqueTokens[index],
          error: result.error,
        });
      }
    });
  }

  return {
    sentCount: response.successCount,
    failureCount: response.failureCount,
  };
});
