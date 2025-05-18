const admin = require("firebase-admin");
const serviceAccount = require("./serviceAccountKey.json");

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount),
});

const deviceToken = "d-y_W0C7TGG-aeEM6ZSquF:APA91bE1tytzjD0g9CKPbMT0k4v2NzFdhISABuLBCLyPArFn1-CMw5o0T4U6mv1C8P5s4zpOgcHNrRvUL9qWjtA0iKGYQzxxzrePYbuHgHbjg2OMcnO2PmA"; // Replace with actual device token

const message = {
  notification: {
    title: "🎉 Hello from StitchUp",
    body: "This is a test push notification!",
  },
  token: deviceToken,
};

admin.messaging().send(message)
  .then((response) => {
    console.log("✅ Successfully sent message:", response);
  })
  .catch((error) => {
    console.error("❌ Error sending message:", error);
  });
