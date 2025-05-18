const functions = require('firebase-functions');
const admin = require('firebase-admin');
admin.initializeApp();

exports.sendPushNotification = functions.https.onCall(async (data, context) => {
  const { token, title, body, chatId } = data;

  const message = {
    token: token,
    notification: {
      title: title,
      body: body,
    },
    data: {
      chatId: chatId,
    },
  };

  try {
    const response = await admin.messaging().send(message);
    return { success: true, response };
  } catch (error) {
    return { success: false, error: error.message };
  }
});
