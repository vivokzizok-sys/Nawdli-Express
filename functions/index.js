const admin = require("firebase-admin");
const {HttpsError, onCall} = require("firebase-functions/v2/https");

admin.initializeApp();
const db = admin.firestore();

function cleanString(value) {
  return typeof value === "string" ? value.trim() : "";
}

async function assertCanSendNotification({
  callerId,
  toUserId,
  orderId,
  type,
}) {
  const callerSnap = await db.collection("users").doc(callerId).get();
  if (!callerSnap.exists) {
    throw new HttpsError("permission-denied", "Caller profile not found");
  }

  const caller = callerSnap.data() || {};
  if (caller.isApproved !== true) {
    throw new HttpsError("permission-denied", "Caller is not approved");
  }

  if (caller.role === "admin") {
    return;
  }

  if (!orderId) {
    throw new HttpsError("permission-denied", "orderId is required");
  }

  const orderSnap = await db.collection("orders").doc(orderId).get();
  if (!orderSnap.exists) {
    throw new HttpsError("not-found", "Order not found");
  }

  const order = orderSnap.data() || {};
  const participantIds = new Set(
    [order.clientId, order.driverId, order.storeId]
      .filter((id) => typeof id === "string" && id.trim() !== ""),
  );

  if (!participantIds.has(toUserId)) {
    throw new HttpsError("permission-denied", "Recipient is not on order");
  }

  if (participantIds.has(callerId)) {
    return;
  }

  if (type === "bid_received" && order.clientId === toUserId) {
    const bidSnap = await orderSnap.ref.collection("bids").doc(callerId).get();
    if (bidSnap.exists) {
      return;
    }
  }

  throw new HttpsError("permission-denied", "Caller cannot notify recipient");
}

exports.sendNotification = onCall(async (request) => {
  if (!request.auth) {
    throw new HttpsError("unauthenticated", "Authentication required");
  }

  const data = request.data || {};
  const toUserId = cleanString(data.toUserId);
  const title = cleanString(data.title);
  const body = cleanString(data.body);
  const orderId = cleanString(data.orderId);
  const type = cleanString(data.type);

  if (!toUserId) {
    throw new HttpsError("invalid-argument", "toUserId is required");
  }
  if (!title) {
    throw new HttpsError("invalid-argument", "title is required");
  }
  if (!body) {
    throw new HttpsError("invalid-argument", "body is required");
  }

  try {
    await assertCanSendNotification({
      callerId: request.auth.uid,
      toUserId,
      orderId,
      type,
    });

    const userSnap = await db.collection("users").doc(toUserId).get();

    if (!userSnap.exists) {
      throw new HttpsError("not-found", "User not found");
    }

    const tokens = userSnap.get("fcmTokens");
    const validTokens = Array.isArray(tokens)
      ? tokens.filter((token) => typeof token === "string" && token.length > 0)
      : [];

    if (validTokens.length === 0) {
      throw new HttpsError("not-found", "No tokens available");
    }

    const response = await admin.messaging().sendEachForMulticast({
      tokens: validTokens,
      notification: {
        title,
        body,
      },
      android: {
        priority: "high",
        notification: {
          channelId: "nawdli_express_alerts_system_v1",
          sound: "default",
        },
      },
      data: {
        title,
        body,
        ...(orderId ? {orderId} : {}),
        ...(type ? {type} : {}),
      },
    });

    const failedTokens = [];
    response.responses.forEach((result, index) => {
      if (!result.success) {
        failedTokens.push({
          token: validTokens[index],
          error: result.error ? result.error.message : "Unknown error",
        });
      }
    });

    return {
      success: response.failureCount === 0,
      successCount: response.successCount,
      failureCount: response.failureCount,
      failedTokens,
    };
  } catch (error) {
    if (error instanceof HttpsError) {
      throw error;
    }
    throw new HttpsError("internal", error.message || "Notification failed");
  }
});
