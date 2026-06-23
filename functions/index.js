const functions = require("firebase-functions");
const admin = require("firebase-admin");
admin.initializeApp();

const db = admin.firestore();

// ── Trend score calculation ────────────────────────────────
exports.updateTrendScore = functions.firestore
  .document("posts/{postId}")
  .onUpdate(async (change, context) => {
    const after = change.after.data();
    const reactions = after.reactions || {};
    const totalReactions = Object.values(reactions).reduce((a, b) => a + b, 0);
    const commentCount = after.commentCount || 0;
    const createdAt = after.createdAt?.toDate() || new Date();
    const ageHours = (Date.now() - createdAt.getTime()) / 3600000;
    const score = (totalReactions * 2 + commentCount) / Math.pow(ageHours + 2, 1.5);
    return change.after.ref.update({ trendScore: score });
  });

// ── Content moderation on new post ────────────────────────
exports.moderatePost = functions.firestore
  .document("posts/{postId}")
  .onCreate(async (snap, context) => {
    const post = snap.data();
    const content = post.content || "";
    const banned = ["spam", "hate", "abuse"];
    const hasBanned = banned.some(w => content.toLowerCase().includes(w));
    if (hasBanned) {
      await snap.ref.update({ status: "under_review" });
      await db.collection("moderation_queue").add({
        postId: snap.id,
        reason: "profanity_filter",
        content,
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
      });
    }
  });

// ── Three-strike system ────────────────────────────────────
exports.processReport = functions.firestore
  .document("reports/{reportId}")
  .onCreate(async (snap, context) => {
    const report = snap.data();
    const postId = report.postId;
    const reports = await db.collection("reports").where("postId", "==", postId).get();
    if (reports.size >= 5) {
      await db.collection("posts").doc(postId).update({ status: "under_review" });
    }
  });

// ── Apply moderation strike ───────────────────────────────
exports.applyStrike = functions.https.onCall(async (data, context) => {
  if (!context.auth) throw new functions.https.HttpsError("unauthenticated", "Must be signed in");
  const { userId, reason } = data;
  const userRef = db.collection("users").doc(userId);
  const userDoc = await userRef.get();
  if (!userDoc.exists) throw new functions.https.HttpsError("not-found", "User not found");
  const currentStrikes = userDoc.data().strikeCount || 0;
  const newStrikes = currentStrikes + 1;
  const update = { strikeCount: newStrikes };
  if (newStrikes === 2) {
    update.isMuted = true;
    update.muteEndsAt = admin.firestore.Timestamp.fromDate(new Date(Date.now() + 60 * 60 * 1000));
  } else if (newStrikes >= 3) {
    update.isBanned = true;
  }
  await userRef.update(update);
  return { strikes: newStrikes };
});

// ── Auto-unmute scheduled job ─────────────────────────────
exports.checkMutes = functions.pubsub
  .schedule("every 5 minutes")
  .onRun(async () => {
    const now = admin.firestore.Timestamp.now();
    const mutedUsers = await db.collection("users")
      .where("isMuted", "==", true)
      .where("muteEndsAt", "<=", now)
      .get();
    const batch = db.batch();
    mutedUsers.docs.forEach(doc => batch.update(doc.ref, { isMuted: false, muteEndsAt: null }));
    await batch.commit();
    functions.logger.info(`Unmuted ${mutedUsers.size} users`);
  });

// ── Notify on new comment ─────────────────────────────────
exports.notifyOnComment = functions.firestore
  .document("comments/{commentId}")
  .onCreate(async (snap, context) => {
    const comment = snap.data();
    const postDoc = await db.collection("posts").doc(comment.postId).get();
    if (!postDoc.exists) return;
    const post = postDoc.data();
    const targetId = comment.parentId
      ? (await db.collection("comments").doc(comment.parentId).get()).data()?.authorId
      : post.authorId;
    if (!targetId || targetId === comment.authorId) return;
    const userDoc = await db.collection("users").doc(targetId).get();
    if (!userDoc.exists) return;
    const fcmToken = userDoc.data().fcmToken;

    // Write in-app notification
    await db.collection("notifications").add({
      userId: targetId,
      type: comment.parentId ? "newReply" : "newComment",
      title: comment.parentId ? "Someone replied to your comment 💬" : "New comment on your Whispr 💬",
      body: comment.content.substring(0, 80),
      postId: comment.postId,
      isRead: false,
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
    });

    // Push notification if token available
    if (fcmToken) {
      await admin.messaging().send({
        token: fcmToken,
        notification: {
          title: comment.parentId ? "Someone replied 💬" : "New comment on your Whispr 💬",
          body: comment.content.substring(0, 80),
        },
        data: { postId: comment.postId },
        android: { priority: "normal" },
        apns: { payload: { aps: { badge: 1 } } },
      });
    }
  });

// ── Notify on reaction ────────────────────────────────────
exports.notifyOnReaction = functions.firestore
  .document("reactions/{reactionId}")
  .onCreate(async (snap, context) => {
    const reaction = snap.data();
    const postDoc = await db.collection("posts").doc(reaction.postId).get();
    if (!postDoc.exists) return;
    const post = postDoc.data();
    if (post.authorId === reaction.userId) return; // Don't notify self

    const emojis = { fire: "🔥", heart: "❤️", laugh: "😂", sad: "😢", shock: "😱", down: "👎" };
    const emoji = emojis[reaction.reactionType] || "🔥";

    await db.collection("notifications").add({
      userId: post.authorId,
      type: "reaction",
      title: `Someone reacted ${emoji} to your Whispr`,
      body: post.content.substring(0, 60),
      postId: reaction.postId,
      isRead: false,
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
    });
  });

// ── GDPR: cascade delete on user deletion ────────────────
exports.onUserDeleted = functions.firestore
  .document("users/{userId}")
  .onUpdate(async (change, context) => {
    const before = change.before.data();
    const after = change.after.data();
    // Trigger only when deleted flag is newly set to true
    if (before.deleted === after.deleted) return;
    if (!after.deleted) return;

    const uid = context.params.userId;
    functions.logger.info(`GDPR delete cascade for user ${uid}`);

    // Delete posts (soft-delete)
    const posts = await db.collection("posts").where("authorId", "==", uid).get();
    const batch1 = db.batch();
    posts.docs.forEach(d => batch1.update(d.ref, { status: "removed", content: "[deleted]" }));
    await batch1.commit();

    // Delete comments
    const comments = await db.collection("comments").where("authorId", "==", uid).get();
    const batch2 = db.batch();
    comments.docs.forEach(d => batch2.update(d.ref, { content: "[deleted]" }));
    await batch2.commit();

    // Delete reactions
    const reactions = await db.collection("reactions").where("userId", "==", uid).get();
    const batch3 = db.batch();
    reactions.docs.forEach(d => batch3.delete(d.ref));
    await batch3.commit();

    // Delete notifications
    const notifs = await db.collection("notifications").where("userId", "==", uid).get();
    const batch4 = db.batch();
    notifs.docs.forEach(d => batch4.delete(d.ref));
    await batch4.commit();

    // Finally delete the user document
    await change.after.ref.delete();

    // Delete Firebase Auth user
    await admin.auth().deleteUser(uid);
    functions.logger.info(`GDPR delete complete for user ${uid}`);
  });
